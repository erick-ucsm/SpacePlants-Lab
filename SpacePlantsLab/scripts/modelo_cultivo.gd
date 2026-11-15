extends RefCounted

signal mensaje(texto: String, tipo: String)
signal terminado(exito: bool, motivo: String)

const NIVEL_EXCESO := 110.0
const NIVEL_MAXIMO := 140.0
const RECARGA_IMPRECISA := 80.0
const BLOQUEO_DERROTA := 0.25
const DOSIS_RIEGO := 8.0
const COSTO_RIEGO := 20.0
const OBJETIVO_MECHA := 66.0

var componentes: Array[String] = []
var planta_id: String
var planta: Dictionary
var potencia_led: float
var potencia_otros: float
var escala: float = 1.0
var dias_cosecha: float
var ventana: float

var nivel: Dictionary = {}
var dia: float = 0.0
var tiempo_normalizado: float = 0.0
var vida: float = 100.0
var vida_minima: float = 100.0
var luz_manual: bool = true
var terminado_flag: bool = false
var exito: bool = false
var tanque_o2_usado: bool = false

var tiempo_en_rango: Dictionary = {}
var tiempo_exceso: Dictionary = {}
var recargas: Dictionary = {}
var riegos: int = 0
var minijuegos := {"victoria": 0, "empate": 0, "derrota": 0}
var eventos_ocurridos: int = 0
var bloqueo_hasta: Dictionary = {}
var horas_sin_luz: float = 0.0

var _estado_anterior: Dictionary = {}
var _ultimo_evento: int = 0
var _fase_luz_anterior: bool = true
var _bateria_agotada: bool = false
var _aviso_visual: float = 0.0
var rng := RandomNumberGenerator.new()


func _init(lista: Array[String], id_planta: String, p_led: float, p_otros: float, semilla_rng: int = -1) -> void:
	componentes = lista
	planta_id = id_planta
	planta = Datos.planta(id_planta)
	potencia_led = p_led
	potencia_otros = p_otros
	dias_cosecha = float(planta["dias"])
	ventana = maxf(1.0, dias_cosecha * 0.1)
	escala = pow(Datos.DIAS_REFERENCIA / dias_cosecha, 0.7) if Datos.ESCALAR_CICLOS else 1.0
	if semilla_rng >= 0:
		rng.seed = semilla_rng
	else:
		rng.randomize()
	for v in Datos.ORDEN_VARIABLES:
		nivel[v] = 100.0
		tiempo_en_rango[v] = 0.0
		tiempo_exceso[v] = 0.0
		recargas[v] = 0
		bloqueo_hasta[v] = 0.0
		_estado_anterior[v] = "OPTIMO"
	nivel["humedad"] = rango_humedad()[0] + 3.0 if agua_llega() else 40.0


func tiene(id: String) -> bool:
	return componentes.has(id)


func sens(clave: String) -> float:
	return planta["sensibilidad"].get(clave, 1.0)


func rango_humedad() -> Array:
	return planta["humedad"]


func rango_temperatura() -> Array:
	return planta["temperatura"]


func tipo_riego() -> String:
	for t in ["mecha_absorbente", "bomba_peristaltica", "electrovalvula", "riego_inmersion"]:
		if tiene(t):
			return t
	return ""


func agua_llega() -> bool:
	return tiene("mecha_absorbente") or tiene("bomba_peristaltica") or tiene("riego_inmersion")


func riego_manual() -> bool:
	return tiene("bomba_peristaltica") or tiene("electrovalvula")


func luz_automatica() -> bool:
	return tiene("temporizador_fotoperiodo")


func luz_controlable() -> bool:
	return tiene("panel_led") and not luz_automatica()


func hora() -> float:
	return fmod(dia, 1.0) * 24.0


func es_fase_luz() -> bool:
	return hora() < Datos.HORAS_LUZ


func horas_para_cambio() -> float:
	return (Datos.HORAS_LUZ - hora()) if es_fase_luz() else (24.0 - hora())


func sol_exterior() -> bool:
	return fmod(dia, 4.0) < 2.6 and es_fase_luz()


func luz_encendida() -> bool:
	if not tiene("panel_led"):
		return false
	if luz_automatica():
		return es_fase_luz()
	return luz_manual


func luz_activa() -> bool:
	if tiene("tubo_luz_natural"):
		return sol_exterior()
	return luz_encendida() and nivel["luz"] > 0.0


func par_actual() -> float:
	if not luz_activa():
		return 0.0
	var r: Array = planta["par"]
	return (r[0] + r[1]) * 0.5


func potencia_actual() -> float:
	var p := potencia_otros
	if luz_encendida() and nivel["luz"] > 0.0:
		p += potencia_led
	return p


func umbral(v: String) -> float:
	match v:
		"luz", "agua":
			return 15.0
		"humedad":
			return rango_humedad()[0]
	return 100.0 / (Datos.VARIABLES[v]["dias_recarga"] + 1.0)


func es_exacto(v: String) -> bool:
	match v:
		"luz": return true
		"agua": return tiene("sensor_nivel")
		"humedad": return tiene("sensor_humedad_sustrato")
		"temperatura": return tiene("calentador_kapton")
		"oxigeno": return tiene("sensor_oxigeno")
	return false


func tiene_alerta(v: String) -> bool:
	return es_exacto(v) or (v == "oxigeno" and tiene("sensor_co2"))


func es_precisa(v: String) -> bool:
	match v:
		"temperatura": return tiene("calentador_kapton")
		"oxigeno": return tiene("depurador_co2")
	return true


func puede_recargar(v: String) -> bool:
	return not terminado_flag and dia >= bloqueo_hasta[v]


func estado(v: String) -> String:
	var n: float = nivel[v]
	match v:
		"luz", "agua":
			if n < 5.0: return "CRITICO"
			if n < 15.0: return "BAJO"
			if n < 30.0: return "RECARGAR"
			return "OPTIMO"
		"humedad":
			var r := rango_humedad()
			if n < r[0] - 12.0: return "CRITICO"
			if n < r[0]: return "BAJO"
			if n > r[1]: return "EXCESO"
			if n < r[0] + 2.0: return "RECARGAR"
			return "OPTIMO"
	var u := umbral(v)
	if n > NIVEL_EXCESO: return "EXCESO"
	if n < u * 0.5: return "CRITICO"
	if n < u: return "BAJO"
	if n < u + 12.0: return "RECARGAR"
	return "OPTIMO"


func estado_visible(v: String) -> String:
	if v == "humedad" and not es_exacto(v):
		return "DESCONOCIDO"
	var e := estado(v)
	if e == "RECARGAR" and not tiene_alerta(v):
		return "OPTIMO"
	return e


func valor_fisico(v: String) -> float:
	match v:
		"luz", "agua", "humedad":
			return nivel[v]
		"temperatura":
			var r := rango_temperatura()
			var u := umbral(v)
			return r[0] + (r[1] - r[0]) * (nivel[v] - u) / (100.0 - u)
		"oxigeno":
			var u2 := umbral(v)
			return Datos.OXIGENO_IDEAL[0] + (Datos.OXIGENO_IDEAL[1] - Datos.OXIGENO_IDEAL[0]) * (nivel[v] - u2) / (100.0 - u2)
	return 0.0


func gasto_bateria_por_dia() -> float:
	var f := 0.5
	if tiene("panel_solar"): f *= 0.8
	if tiene("bateria"): f *= 0.9
	return potencia_actual() * f


func dias_estimados(v: String) -> float:
	match v:
		"luz":
			var promedio := potencia_otros + potencia_led * Datos.HORAS_LUZ / 24.0
			var f := 0.5 * (0.8 if tiene("panel_solar") else 1.0) * (0.9 if tiene("bateria") else 1.0)
			return 85.0 / maxf(promedio * f, 0.1) / escala
		"agua":
			return 85.0 / (planta["consumo_agua"] * 2.5 * (0.7 if tiene("condensador_humedad") else 1.0)) / escala
		"humedad":
			var r := rango_humedad()
			return (r[1] - r[0]) / planta["consumo_agua"] / escala
		"temperatura":
			return 3.0 / escala / (0.6 if tiene("aislamiento_mli") else 1.0)
		"oxigeno":
			return 2.0 / escala / (0.7 if tiene("inyector_co2") else 1.0)
	return 0.0


func alternar_luz() -> void:
	if not luz_controlable() or terminado_flag:
		return
	luz_manual = not luz_manual
	mensaje.emit(tr("Luz LED %s manualmente.") % (tr("ENCENDIDA") if luz_manual else tr("APAGADA")), "info")


func regar() -> void:
	if terminado_flag:
		return
	if tiene("electrovalvula"):
		mensaje.emit(tr("La electroválvula se abrió, pero sin bomba no hay presión: en microgravedad el agua no llega."), "peligro")
		return
	if not tiene("bomba_peristaltica"):
		return
	var costo := COSTO_RIEGO * (0.7 if tiene("condensador_humedad") else 1.0)
	if nivel["agua"] < costo:
		mensaje.emit(tr("No hay suficiente agua en el depósito para regar."), "peligro")
		return
	nivel["agua"] -= costo
	nivel["humedad"] = minf(nivel["humedad"] + DOSIS_RIEGO, 100.0)
	riegos += 1
	var texto := tr("Riego con bomba: +%d %% de humedad en el sustrato.") % int(DOSIS_RIEGO)
	if nivel["humedad"] > rango_humedad()[1] and es_exacto("humedad"):
		texto += tr(" ¡Te pasaste del rango!")
	mensaje.emit(texto, "bien")
	_revisar_estados()


func _regar_con_minijuego(resultado: String) -> void:
	if not agua_llega():
		mensaje.emit(tr("Ganaste, pero sin bomba ni mecha no hay presión: en microgravedad el agua no llega a la raíz."), "peligro")
		return
	var antes: float = nivel["humedad"]
	var objetivo: float
	if tiene("bomba_peristaltica"):
		var tope: float = rango_humedad()[1] - 1.0
		objetivo = maxf(antes, tope if resultado == "victoria" else antes + (tope - antes) * 0.5)
	else:
		objetivo = antes + (10.0 if resultado == "victoria" else 5.0)
	objetivo = minf(objetivo, 100.0)
	var costo := (objetivo - antes) * 2.5 * (0.7 if tiene("condensador_humedad") else 1.0)
	if nivel["agua"] < costo:
		if nivel["agua"] <= 0.0:
			mensaje.emit(tr("El depósito está vacío: llénalo antes de regar."), "peligro")
			return
		objetivo = antes + nivel["agua"] / (2.5 * (0.7 if tiene("condensador_humedad") else 1.0))
		costo = nivel["agua"]
		mensaje.emit(tr("No alcanzaba el agua del depósito: riego parcial."), "aviso")
	nivel["agua"] -= costo
	nivel["humedad"] = objetivo
	riegos += 1
	var texto := tr("Riego: sustrato de %d %% a %d %%.") % [int(antes), int(objetivo)]
	if objetivo > rango_humedad()[1]:
		texto += tr(" ¡Te pasaste del rango! (estrés por exceso de agua)")
	mensaje.emit(texto, "bien")
	_revisar_estados()


func avanzar(dias_reales: float) -> void:
	if terminado_flag:
		return
	var restante := dias_reales
	while restante > 0.0 and not terminado_flag:
		var paso := minf(restante, 0.004)
		_paso(paso)
		restante -= paso


func _paso(dt_real: float) -> void:
	var dt := dt_real * escala
	dia += dt_real
	tiempo_normalizado += dt
	var activa := luz_activa()
	var nl := 1.0 if activa else 0.0
	var nt := clampf(nivel["temperatura"] / 100.0, 0.0, 1.3)

	var antes_bateria: float = nivel["luz"]
	nivel["luz"] = maxf(nivel["luz"] - gasto_bateria_por_dia() * dt, 0.0)
	if antes_bateria > 0.0 and nivel["luz"] <= 0.0 and not _bateria_agotada:
		_bateria_agotada = true
		mensaje.emit(tr("¡Batería agotada! Los LEDs se apagaron [peligro]"), "peligro")
	elif nivel["luz"] > 0.0:
		_bateria_agotada = false

	var f_temp := (1.15 - 0.15 * nl) * (0.6 if tiene("aislamiento_mli") else 1.0)
	nivel["temperatura"] = maxf(nivel["temperatura"] - 25.0 * f_temp * dt, 0.0)
	var f_o2 := (1.4 - 0.4 * nl) * (0.7 if tiene("inyector_co2") else 1.0)
	nivel["oxigeno"] = maxf(nivel["oxigeno"] - (100.0 / 3.0) * f_o2 * dt, 0.0)

	var consumo: float = planta["consumo_agua"] * (0.7 + 0.3 * nl) * (0.8 + 0.2 * nt)
	nivel["humedad"] -= consumo * dt
	var factor_deposito := 0.7 if tiene("condensador_humedad") else 1.0
	if tiene("mecha_absorbente") and nivel["agua"] > 0.0:
		var flujo := clampf(4.0 * (OBJETIVO_MECHA - nivel["humedad"]), 0.0, 25.0)
		nivel["humedad"] += flujo * dt
		nivel["agua"] = maxf(nivel["agua"] - flujo * 2.5 * factor_deposito * dt, 0.0)
	elif tiene("riego_inmersion") and nivel["humedad"] < 58.0 and nivel["agua"] >= 25.0:
		nivel["humedad"] = 78.0
		nivel["agua"] -= 25.0 * factor_deposito
		mensaje.emit(tr("Riego por inmersión: la bandeja se inundó (sustrato al 78 %)."), "aviso")
	nivel["humedad"] = clampf(nivel["humedad"], 0.0, 100.0)

	if tiene("tanque_oxigeno") and not tanque_o2_usado and nivel["oxigeno"] < umbral("oxigeno") * 0.5:
		tanque_o2_usado = true
		nivel["oxigeno"] = 70.0
		mensaje.emit(tr("El tanque de reserva liberó oxígeno automáticamente."), "info")

	var dano := 0.0
	var sin_descanso := false
	var fase_luz := es_fase_luz()
	if fase_luz and not activa:
		vida -= 25.0 * sens("luz") * sens("general") * dt_real
		horas_sin_luz += dt_real * 24.0
	else:
		tiempo_en_rango["luz"] += dt_real
	if not fase_luz and activa:
		sin_descanso = true

	if nivel["agua"] >= 15.0 or not agua_llega():
		tiempo_en_rango["agua"] += dt_real

	var m: float = nivel["humedad"]
	var r := rango_humedad()
	if m < r[0]:
		var s := minf(1.0, (r[0] - m) / 25.0)
		dano += (3.0 + 25.0 * pow(s, 1.5)) * sens("humedad")
	elif m > r[1]:
		var s2 := minf(1.0, (m - r[1]) / 20.0)
		dano += (4.0 + 22.0 * s2) * sens("humedad")
		tiempo_exceso["humedad"] += dt_real
	else:
		tiempo_en_rango["humedad"] += dt_real

	for v in ["temperatura", "oxigeno"]:
		var n: float = nivel[v]
		var u := umbral(v)
		var k := sens("temperatura") if v == "temperatura" else 1.0
		if n < u:
			var s3 := (u - n) / u
			dano += (3.0 + 25.0 * pow(s3, 1.5)) * k
		elif n > NIVEL_EXCESO:
			var s4 := clampf((n - NIVEL_EXCESO) / 20.0, 0.0, 1.0)
			dano += (4.0 + 20.0 * s4) * k * (0.5 if tiene("ventilador") else 1.0)
			tiempo_exceso[v] += dt_real
		else:
			tiempo_en_rango[v] += dt_real

	dano *= sens("general")
	if dano > 0.0:
		vida -= dano * dt
	elif not sin_descanso:
		vida += 4.0 * (1.25 if tiene("sensor_co2") else 1.0) * dt
	vida = clampf(vida, 0.0, 100.0)
	vida_minima = minf(vida_minima, vida)

	if fase_luz != _fase_luz_anterior:
		_fase_luz_anterior = fase_luz
		if not luz_controlable():
			pass
		elif fase_luz:
			var t := tr("Comienza el periodo de LUZ (16 h).")
			if luz_controlable() and not luz_manual:
				t += tr(" ¡Enciende los LEDs!")
			mensaje.emit(t, "aviso" if luz_controlable() and not luz_manual else "info")
		else:
			var t2 := tr("Comienza la OSCURIDAD (8 h).")
			if luz_controlable() and luz_manual:
				t2 += tr(" Apaga los LEDs para que la planta descanse y ahorrar batería.")
			mensaje.emit(t2, "aviso" if luz_controlable() and luz_manual else "info")

	_revisar_estados()
	_revisar_eventos()
	_aviso_visual -= dt_real
	if not es_exacto("humedad") and _aviso_visual <= 0.0 and estado("humedad") in ["BAJO", "CRITICO", "EXCESO"]:
		_aviso_visual = 0.5
		mensaje.emit(tr("Señal visual: las hojas se ven estresadas (¿problema de riego?)"), "aviso")

	if vida <= 0.0:
		_terminar(false, tr("La planta murió. Las condiciones del módulo estuvieron fuera de rango demasiado tiempo."))
	elif dia >= dias_cosecha + ventana:
		_terminar(false, tr("Pasó el momento de cosechar. La planta se sobremaduró y se perdió la cosecha."))


func _revisar_estados() -> void:
	for v in Datos.ORDEN_VARIABLES:
		var e := estado_visible(v)
		if e == _estado_anterior[v]:
			continue
		var nombre: String = Datos.VARIABLES[v]["nombre"]
		match e:
			"RECARGAR":
				mensaje.emit(tr("%s: alerta temprana, conviene recargar pronto.") % nombre, "aviso")
			"BAJO":
				mensaje.emit(tr("%s por debajo del rango ideal [peligro]") % nombre, "peligro")
			"CRITICO":
				mensaje.emit(tr("%s en nivel CRÍTICO [peligro]") % nombre, "peligro")
			"EXCESO":
				if v == "humedad":
					mensaje.emit(tr("Estrés por exceso de agua: sustrato demasiado húmedo [peligro]"), "peligro")
				else:
					mensaje.emit(tr("%s por encima del límite [peligro]") % nombre, "peligro")
			"OPTIMO":
				if _estado_anterior[v] in ["BAJO", "CRITICO", "EXCESO"]:
					mensaje.emit(tr("%s de vuelta en rango ideal.") % nombre, "bien")
		_estado_anterior[v] = e


func _revisar_eventos() -> void:
	var d := int(tiempo_normalizado)
	if d <= _ultimo_evento:
		return
	_ultimo_evento = d
	if tiempo_normalizado >= Datos.DIAS_REFERENCIA or rng.randf() > 0.4:
		return
	var posibles: Array[String] = ["fuga", "termica"]
	if tiene("panel_solar"): posibles.append("sombra")
	eventos_ocurridos += 1
	match posibles[rng.randi_range(0, posibles.size() - 1)]:
		"fuga":
			var p := 10.0 if tiene("sensor_presion") else 30.0
			nivel["oxigeno"] = maxf(nivel["oxigeno"] - p, 0.0)
			mensaje.emit(tr("EVENTO: micro-fuga en el módulo (−%d %% oxígeno)%s.") % [int(p), tr(" detectada a tiempo") if p < 30.0 else ""], "evento")
		"termica":
			var p2 := 15.0 if tiene("aislamiento_mli") else 30.0
			nivel["temperatura"] = maxf(nivel["temperatura"] - p2, 0.0)
			mensaje.emit(tr("EVENTO: falla del control térmico (−%d %% temperatura).") % int(p2), "evento")
		"sombra":
			nivel["luz"] = maxf(nivel["luz"] - 25.0, 0.0)
			mensaje.emit(tr("EVENTO: sombra y polvo sobre el panel solar (−25 % batería)."), "evento")


func recargar(v: String, resultado: String) -> void:
	if terminado_flag:
		return
	minijuegos[resultado] += 1
	var nombre: String = Datos.VARIABLES[v]["nombre"]
	if resultado == "derrota":
		bloqueo_hasta[v] = dia + BLOQUEO_DERROTA
		mensaje.emit(tr("Perdiste el minijuego: %s no se recargó. Bloqueado 6 horas.") % nombre, "peligro")
		return
	if v == "humedad":
		_regar_con_minijuego(resultado)
		return
	var antes: float = nivel[v]
	if v in ["luz", "agua"]:
		nivel[v] = 100.0 if resultado == "victoria" else minf(antes + 50.0, 100.0)
	elif es_precisa(v):
		nivel[v] = maxf(antes, 100.0 if resultado == "victoria" else minf(antes + 50.0, 100.0))
	else:
		nivel[v] = minf(antes + (RECARGA_IMPRECISA if resultado == "victoria" else RECARGA_IMPRECISA * 0.5), NIVEL_MAXIMO)
	recargas[v] += 1
	var texto := tr("%s recargado (%s).") % [nombre, tr("completo") if resultado == "victoria" else tr("parcial por empate")]
	if nivel[v] > NIVEL_EXCESO:
		texto += tr(" ¡Cuidado, se pasó del límite!")
	mensaje.emit(texto, "bien")
	_revisar_estados()


func cosechar() -> void:
	if terminado_flag:
		return
	if dia < dias_cosecha:
		_terminar(false, tr("Cosechaste antes de tiempo (día %.1f de %d). La planta aún no estaba lista.") % [dia, int(dias_cosecha)])
	elif vida < Datos.VIDA_MINIMA_COSECHA:
		_terminar(false, tr("La planta llegó al día de cosecha con %d %% de vida. Se necesita más de %d %%.") % [int(vida), int(Datos.VIDA_MINIMA_COSECHA)])
	else:
		_terminar(true, tr("¡Misión cumplida! Cosechaste %s en buen estado.") % planta["nombre"].to_lower())


func _terminar(ok: bool, motivo: String) -> void:
	terminado_flag = true
	exito = ok
	terminado.emit(ok, motivo)


func porcentaje_en_rango(v: String) -> float:
	if dia <= 0.0:
		return 100.0
	return 100.0 * tiempo_en_rango[v] / dia


func calificacion() -> String:
	var suma := 0.0
	for v in Datos.ORDEN_VARIABLES:
		suma += porcentaje_en_rango(v)
	var prom := suma / Datos.ORDEN_VARIABLES.size()
	if prom >= 95.0: return "A+"
	if prom >= 85.0: return "A"
	if prom >= 75.0: return "B"
	if prom >= 60.0: return "C"
	return "D"
