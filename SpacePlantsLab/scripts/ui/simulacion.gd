extends Control

const ModeloCultivo = preload("res://scripts/modelo_cultivo.gd")
const MINIJUEGOS := {
	"agua": preload("res://scripts/ui/minijuegos/deslizante.gd"),
	"humedad": preload("res://scripts/ui/minijuegos/memoria.gd"),
	"temperatura": preload("res://scripts/ui/minijuegos/intercambio.gd"),
	"oxigeno": preload("res://scripts/ui/minijuegos/alienigenas.gd"),
}

const COLORES_ESTADO := {
	"OPTIMO": Color(0.45, 0.95, 0.55),
	"RECARGAR": Color(1.0, 0.85, 0.35),
	"BAJO": Color(1.0, 0.6, 0.3),
	"CRITICO": Color(1.0, 0.35, 0.3),
	"EXCESO": Color(0.85, 0.45, 1.0),
	"DESCONOCIDO": Color(0.75, 0.78, 0.85),
}
const TEXTO_ESTADO := {
	"OPTIMO": "ÓPTIMO",
	"RECARGAR": "RECARGAR PRONTO",
	"BAJO": "BAJO",
	"CRITICO": "CRÍTICO",
	"EXCESO": "EXCESO",
	"DESCONOCIDO": "???",
}
const COLORES_LOG := {
	"info": "#cfd8e3",
	"bien": "#7cf29a",
	"aviso": "#ffd96b",
	"peligro": "#ff7a6b",
	"evento": "#d59bff",
}

@onready var label_tiempo: Label = %LabelTiempo
@onready var btn_salir: Button = %BtnSalir
@onready var btn_menos: Button = %BtnMenos
@onready var btn_mas: Button = %BtnMas
@onready var label_velocidad: Label = %LabelVelocidad
@onready var btn_cosechar: Button = %BtnCosechar
@onready var info_planta: RichTextLabel = %InfoPlanta
@onready var registro: RichTextLabel = %Registro
@onready var lista_variables: VBoxContainer = %ListaVariables
@onready var label_consumo: Label = %LabelConsumo
@onready var consejos: RichTextLabel = %Consejos
@onready var planta: Control = %PlantaVisual
@onready var label_etapa: Label = %LabelEtapa
@onready var barra_vida: ProgressBar = %BarraVida
@onready var label_vida: Label = %LabelVida
@onready var minijuego: Control = %Minijuego
@onready var panel_resultado: Control = %PanelResultado
@onready var titulo_resultado: Label = %TituloResultado
@onready var texto_resultado: RichTextLabel = %TextoResultado
@onready var btn_resultado_menu: Button = %BtnResultadoMenu
@onready var btn_reintentar: Button = %BtnReintentar
@onready var panel_confirmar: Control = %PanelConfirmar
@onready var texto_confirmar: Label = %TextoConfirmar
@onready var btn_confirmar_si: Button = %BtnConfirmarSi
@onready var btn_confirmar_no: Button = %BtnConfirmarNo

var modelo: ModeloCultivo
var datos_planta: Dictionary
var indice_velocidad: int = 1
var pausado: bool = true
var en_intro: bool = true
var variable_en_minijuego: String = ""
var filas: Dictionary = {}
var _accion_confirmar: Callable
var _ultimo_dia_reportado: int = 0
var _acumulador_consejos: float = 0.0
var _estilo_vida: StyleBoxFlat
var minijuegos_por_variable: Dictionary = {}


func _ready() -> void:
	if not Juego.seleccion_completa():
		_seleccion_por_defecto()
	datos_planta = Datos.planta(Juego.semilla())
	modelo = ModeloCultivo.new(Juego.componentes_elegidos(), Juego.semilla(), Juego.potencia_led(), Juego.potencia_otros())
	modelo.mensaje.connect(_agregar_log)
	modelo.terminado.connect(_on_terminado)
	indice_velocidad = clampi(Juego.velocidad_inicial, 0, Datos.VELOCIDADES.size() - 1)

	btn_salir.pressed.connect(_confirmar.bind(tr("¿Abandonar la misión y volver al menú?"), func(): Juego.ir_a(Juego.ESCENA_MENU)))
	btn_menos.pressed.connect(_cambiar_velocidad.bind(-1))
	btn_mas.pressed.connect(_cambiar_velocidad.bind(1))
	btn_cosechar.pressed.connect(_on_cosechar)
	btn_resultado_menu.pressed.connect(func(): Juego.ir_a(Juego.ESCENA_MENU))
	btn_reintentar.pressed.connect(func(): Juego.ir_a(Juego.ESCENA_SIMULACION))
	btn_confirmar_si.pressed.connect(_on_confirmar_si)
	btn_confirmar_no.pressed.connect(_on_confirmar_no)
	minijuego.terminado.connect(_on_minijuego_terminado)
	minijuegos_por_variable["luz"] = minijuego
	var indice := panel_resultado.get_index()
	for v in MINIJUEGOS:
		var mj: Control = MINIJUEGOS[v].new()
		mj.name = "Minijuego_" + v
		add_child(mj)
		move_child(mj, indice)
		mj.terminado.connect(_on_minijuego_terminado)
		minijuegos_por_variable[v] = mj

	_estilo_vida = barra_vida.get_theme_stylebox("fill").duplicate()
	barra_vida.add_theme_stylebox_override("fill", _estilo_vida)

	planta.especie = Juego.semilla()
	planta.riego = modelo.tipo_riego()
	planta.luz_natural = modelo.tiene("tubo_luz_natural")

	label_tiempo.add_theme_font_size_override("font_size", 16)
	panel_resultado.hide()
	panel_confirmar.hide()
	_crear_filas()
	_llenar_info()
	label_consumo.text = tr("Medidor de energía: %s con LEDs encendidos · %s apagados · masa del módulo %s") % [
		Datos.texto_potencia(Juego.consumo_total()), Datos.texto_potencia(Juego.potencia_otros()), Datos.texto_masa(Juego.masa_total())]
	_actualizar_velocidad()
	_actualizar_ui()
	_actualizar_consejos()
	_animacion_inicio()


func _seleccion_por_defecto() -> void:
	for paso in Datos.PASOS:
		if not Juego.selecciones.has(paso["id"]):
			Juego.selecciones[paso["id"]] = paso["opciones"][0]


func _animacion_inicio() -> void:
	en_intro = true
	pausado = true
	planta.iniciar_intro()
	_agregar_log(tr("Preparando el módulo de cultivo..."), "info")
	await get_tree().create_timer(0.8).timeout
	if modelo.agua_llega():
		var via := tr("la mecha absorbente") if modelo.tiene("mecha_absorbente") else tr("la bomba y las tuberías")
		_agregar_log(tr("El agua sube del depósito al sustrato por %s.") % via, "bien")
	else:
		_agregar_log(tr("El agua NO llega a la planta: sin mecha ni bomba no hay riego en microgravedad [peligro]"), "peligro")
	await get_tree().create_timer(1.9).timeout
	if modelo.tiene("panel_led"):
		_agregar_log(tr("Se encienden los LED rojos y azules (fotoperiodo 16 h luz / 8 h oscuridad)."), "bien")
	else:
		_agregar_log(tr("El tubo de luz natural depende de la luz exterior."), "aviso")
	await get_tree().create_timer(1.9).timeout
	_agregar_log(tr("Misión iniciada: semilla de %s plantada en arcillita.") % datos_planta["nombre"].to_lower(), "bien")
	en_intro = false
	pausado = false


func _process(delta: float) -> void:
	if pausado or modelo.terminado_flag:
		return
	modelo.avanzar(delta * Datos.VELOCIDADES[indice_velocidad] / Datos.SEGUNDOS_REALES_POR_DIA)
	var d := int(modelo.dia)
	if d > _ultimo_dia_reportado and not modelo.terminado_flag:
		_ultimo_dia_reportado = d
		_reporte_diario(d)
	_actualizar_ui()
	_acumulador_consejos += delta
	if _acumulador_consejos > 0.5:
		_acumulador_consejos = 0.0
		_actualizar_consejos()


func _boton(texto: String, ancho: float) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(ancho, 30)
	b.add_theme_font_size_override("font_size", 13)
	return b


func _crear_filas() -> void:
	for v in Datos.ORDEN_VARIABLES:
		var caja := VBoxContainer.new()
		caja.add_theme_constant_override("separation", 2)
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 4)
		var etiqueta := Label.new()
		etiqueta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		etiqueta.add_theme_font_size_override("font_size", 14)
		etiqueta.clip_text = true
		fila.add_child(etiqueta)
		var extra: Button = null
		var principal: Button
		match v:
			"humedad":
				principal = _boton(tr("Regar"), 82)
				principal.pressed.connect(_abrir_minijuego.bind(v))
				principal.tooltip_text = tr("Riego con la bomba: gana la memoria de personajes de la NASA.") if modelo.riego_manual() else tr("Tu riego es automático; puedes regar extra ganando la memoria (+10 %).")
			_:
				principal = _boton(tr("Recargar"), 82)
				principal.pressed.connect(_abrir_minijuego.bind(v))
				principal.tooltip_text = tr("%s: gana el 3 en raya.") % Datos.VARIABLES[v]["recarga"]
		if v == "luz":
			extra = _boton(tr("Apagar"), 70)
			extra.pressed.connect(_on_alternar_luz)
			extra.tooltip_text = tr("Enciende o apaga los LEDs (fotoperiodo 16 h luz / 8 h oscuridad).")
			fila.add_child(extra)
		fila.add_child(principal)
		caja.add_child(fila)
		var barra := ProgressBar.new()
		barra.max_value = 100.0 if v in ["luz", "agua", "humedad"] else ModeloCultivo.NIVEL_MAXIMO
		barra.show_percentage = false
		barra.custom_minimum_size = Vector2(0, 8)
		var estilo := StyleBoxFlat.new()
		estilo.set_corner_radius_all(3)
		barra.add_theme_stylebox_override("fill", estilo)
		caja.add_child(barra)
		lista_variables.add_child(caja)
		filas[v] = {"etiqueta": etiqueta, "boton": principal, "extra": extra, "barra": barra, "estilo": estilo}


func _llenar_info() -> void:
	var t := tr("[b]%s[/b] %s\n[color=#9fb3c8]Dificultad %s (%d/5) · %d días[/color]\n\n") % [datos_planta["nombre"], datos_planta["variedad"], datos_planta["etiqueta"], datos_planta["dificultad"], datos_planta["dias"]]
	t += "%s\n\n" % datos_planta["historia"]
	t += tr("[color=#e0a46a][b]Sustrato:[/b][/color] %s\n\n") % Datos.SUSTRATO
	t += tr("[b]Rango ideal:[/b] humedad del sustrato %d-%d %% · temperatura %d-%d °C · luz %d-%d µmol/m²/s\n\n") % [
		datos_planta["humedad"][0], datos_planta["humedad"][1], datos_planta["temperatura"][0], datos_planta["temperatura"][1], datos_planta["par"][0], datos_planta["par"][1]]
	t += tr("[color=#7fd4ff][b]Cómo ganar:[/b][/color] %s\n\n") % Datos.COMO_GANAR
	var nombres: Array[String] = []
	for id in Juego.componentes_elegidos():
		nombres.append(Datos.COMPONENTES[id]["nombre"])
	t += tr("[b]Tu módulo:[/b] ") + ", ".join(nombres) + "."
	info_planta.text = t


func formato_tiempo(dia: float, con_segundos: bool = true) -> String:
	var total := int(dia * 86400.0)
	var d := total / 86400
	var h := (total % 86400) / 3600
	var m := (total % 3600) / 60
	var s := total % 60
	if con_segundos:
		return "%02d:%02d:%02d:%02d" % [d, h, m, s]
	return "%02d:%02d:%02d" % [d, h, m]


func _texto_valor(v: String) -> String:
	var nombre: String = Datos.VARIABLES[v]["nombre"]
	var e := modelo.estado_visible(v)
	if not modelo.es_exacto(v):
		return "%s: %s" % [nombre, tr(TEXTO_ESTADO[e])]
	match v:
		"luz":
			var estado_led := "LED ON" if modelo.luz_encendida() and modelo.nivel["luz"] > 0.0 else "LED OFF"
			if modelo.tiene("tubo_luz_natural"):
				estado_led = tr("Sol") if modelo.luz_activa() else tr("sin Sol")
			var t := tr("Batería %d %% · %s") % [int(modelo.nivel["luz"]), estado_led]
			if modelo.tiene("sensor_par"):
				t += " · %d PAR" % int(modelo.par_actual())
			return t
		"agua":
			return tr("Depósito: %d %%") % int(modelo.nivel["agua"])
		"humedad":
			return tr("Humedad sustrato: %d %%") % int(modelo.nivel["humedad"])
		"temperatura":
			return tr("Temperatura: %.1f °C") % modelo.valor_fisico(v)
		"oxigeno":
			return tr("Oxígeno: %.1f %% O₂") % modelo.valor_fisico(v)
	return nombre


func _actualizar_ui() -> void:
	var fase := tr("LUZ") if modelo.es_fase_luz() else tr("OSCURIDAD")
	label_tiempo.text = tr("Tiempo %s · %s %s") % [formato_tiempo(modelo.dia), fase, _hhmm(modelo.horas_para_cambio())]

	for v in Datos.ORDEN_VARIABLES:
		var f: Dictionary = filas[v]
		var e := modelo.estado_visible(v)
		var color: Color = COLORES_ESTADO[e]
		f["etiqueta"].text = _texto_valor(v)
		f["etiqueta"].modulate = color
		var exacto := modelo.es_exacto(v)
		f["barra"].visible = exacto
		if exacto:
			f["barra"].value = modelo.nivel[v]
			f["estilo"].bg_color = color
		var boton: Button = f["boton"]
		var texto_normal := tr("Regar") if v == "humedad" else tr("Recargar")
		if modelo.terminado_flag:
			boton.disabled = true
			boton.text = texto_normal
		elif modelo.puede_recargar(v):
			boton.disabled = false
			boton.text = texto_normal
		else:
			boton.disabled = true
			boton.text = tr("Bloq. %dh") % ceili((modelo.bloqueo_hasta[v] - modelo.dia) * 24.0)
		if f["extra"] != null:
			var extra: Button = f["extra"]
			if modelo.luz_automatica():
				extra.text = "Auto"
				extra.disabled = true
				extra.tooltip_text = "El temporizador enciende y apaga la luz automáticamente (16/8)."
			elif not modelo.tiene("panel_led"):
				extra.text = "Natural"
				extra.disabled = true
			else:
				extra.text = tr("Apagar") if modelo.luz_manual else tr("Encender")
				extra.disabled = modelo.terminado_flag

	barra_vida.value = modelo.vida
	label_vida.text = tr("Vida de la planta: %d %%") % int(modelo.vida)
	_estilo_vida.bg_color = Color(1, 0.3, 0.3).lerp(Color(0.3, 0.95, 0.85), modelo.vida / 100.0)

	planta.progreso = clampf(modelo.dia / modelo.dias_cosecha, 0.0, 1.0)
	planta.vida = modelo.vida
	planta.luz_activa = modelo.luz_activa()
	planta.nivel_agua = modelo.nivel["agua"]
	planta.humedad = modelo.nivel["humedad"]

	if modelo.dia >= modelo.dias_cosecha:
		label_etapa.text = tr("Día %d completado · ¡Lista para cosechar!") % int(modelo.dias_cosecha)
	else:
		label_etapa.text = tr("Día %d de %d · %s") % [int(modelo.dia) + 1, int(modelo.dias_cosecha), _etapa()]
	var listo := modelo.dia >= modelo.dias_cosecha
	btn_cosechar.modulate = Color(0.6, 1, 0.6) if listo else Color.WHITE
	btn_cosechar.text = tr("¡COSECHAR!") if listo else tr("Cosechar")


func _hhmm(horas: float) -> String:
	var m := int(horas * 60.0)
	return "(%02d:%02d)" % [m / 60, m % 60]


func _etapa() -> String:
	var p := modelo.dia / modelo.dias_cosecha
	if p < 0.1: return tr("Germinación")
	if p < 0.3: return tr("Plántula")
	if Juego.semilla() == "chile":
		if p < 0.45: return tr("Crecimiento")
		if p < 0.6: return tr("Floración")
		if p < 0.85: return tr("Frutos verdes")
		return tr("Frutos madurando")
	if Juego.semilla() == "rabano" and p >= 0.5:
		return tr("Engorde de la raíz")
	if p < 0.7: return tr("Crecimiento")
	return tr("Maduración")


func _reporte_diario(d: int) -> void:
	var v := modelo.vida
	if v >= 80.0:
		_agregar_log(tr("Día %d: la planta está en buen estado (%d %%).") % [d, int(v)], "bien")
	elif v >= 50.0:
		_agregar_log(tr("Día %d: la planta muestra estrés (%d %%).") % [d, int(v)], "aviso")
	else:
		_agregar_log(tr("Día %d: la planta está en peligro (%d %%).") % [d, int(v)], "peligro")
	if d == int(modelo.dias_cosecha):
		_agregar_log(tr("¡La planta está lista! Tienes %d día(s) para cosechar.") % int(modelo.ventana), "aviso")


func _agregar_log(texto: String, tipo: String = "info") -> void:
	var color: String = COLORES_LOG.get(tipo, COLORES_LOG["info"])
	var dia: float = modelo.dia if modelo != null else 0.0
	registro.append_text("[color=#8aa0b8]%s[/color] [color=%s]%s[/color]\n" % [formato_tiempo(dia, false), color, texto])


func _actualizar_consejos() -> void:
	var t := ""
	if modelo.dia >= modelo.dias_cosecha:
		t += tr("[color=#7cf29a][b]¡Ya puedes cosechar![/b] Pulsa COSECHAR antes del día %d.[/color]\n\n") % int(modelo.dias_cosecha + modelo.ventana)
	var urgentes: Array[String] = []
	for v in Datos.ORDEN_VARIABLES:
		var e := modelo.estado_visible(v)
		if e in ["BAJO", "CRITICO", "RECARGAR"]:
			urgentes.append(Datos.VARIABLES[v]["nombre"])
		elif e == "EXCESO":
			if v == "humedad":
				t += tr("• [color=#d59bff]Sustrato demasiado húmedo:[/color] deja de regar hasta que baje.\n")
			else:
				t += tr("• [color=#d59bff]%s por encima del límite:[/color] espera a que baje.\n") % Datos.VARIABLES[v]["nombre"]
	if not urgentes.is_empty():
		t += tr("• [color=#ffd96b]Atiende pronto: %s.[/color]\n") % ", ".join(urgentes)
	if modelo.luz_controlable():
		if modelo.es_fase_luz() and not modelo.luz_manual:
			t += tr("• [color=#ff7a6b]Es horario de LUZ y tus LEDs están apagados: ¡enciéndelos![/color]\n")
		elif not modelo.es_fase_luz() and modelo.luz_manual:
			t += tr("• [color=#ffd96b]Es horario de OSCURIDAD: apaga los LEDs para que la planta descanse y ahorres batería.[/color]\n")
	t += "\n[b]%s[/b]\n%s\n" % [Datos.FOTOPERIODO, Datos.FOTOPERIODO_SIMPLE]
	t += tr("\n[b]Riego para %s:[/b] humedad del sustrato %d-%d %%. Regar de más causa estrés por exceso de agua (le pasó a la NASA).\n") % [datos_planta["nombre"].to_lower(), datos_planta["humedad"][0], datos_planta["humedad"][1]]
	if not modelo.es_exacto("humedad"):
		t += tr("• Sin sensor de humedad del sustrato riegas a ciegas (???): fíjate en el color y la postura de las hojas.\n")
	t += tr("\n[b]Duración aproximada de cada recarga:[/b]\n")
	for v in ["luz", "agua", "humedad", "temperatura", "oxigeno"]:
		if v == "agua" and not modelo.tiene("mecha_absorbente"):
			continue
		if v == "humedad" and not modelo.riego_manual():
			continue
		t += tr("• %s: unos %d días\n") % [Datos.VARIABLES[v]["nombre"], maxi(1, int(modelo.dias_estimados(v)))]
	t += tr("\n[b]Minijuegos:[/b] Luz = 3 en raya · Agua = rompecabezas deslizante de naves · Humedad = memoria de personajes · Temperatura = rompecabezas de temperaturas extremas · Oxígeno = golpea al alienígena.\n")
	t += tr("\n[b]Relaciones entre variables:[/b]\n• Con luz la planta toma más agua y produce oxígeno.\n• Los LEDs calientan un poco el módulo.\n")
	consejos.text = t


func _cambiar_velocidad(cambio: int) -> void:
	indice_velocidad = clampi(indice_velocidad + cambio, 0, Datos.VELOCIDADES.size() - 1)
	_actualizar_velocidad()


func _actualizar_velocidad() -> void:
	var v: float = Datos.VELOCIDADES[indice_velocidad]
	label_velocidad.text = tr("Velocidad x%s") % str(v)
	btn_menos.disabled = indice_velocidad == 0
	btn_mas.disabled = indice_velocidad == Datos.VELOCIDADES.size() - 1


func _on_alternar_luz() -> void:
	modelo.alternar_luz()
	_actualizar_ui()
	_actualizar_consejos()


func _abrir_minijuego(v: String) -> void:
	if en_intro or modelo.terminado_flag or not modelo.puede_recargar(v):
		return
	pausado = true
	variable_en_minijuego = v
	minijuegos_por_variable[v].abrir(Datos.VARIABLES[v]["nombre"], Datos.VARIABLES[v]["recarga"])


func _on_minijuego_terminado(resultado: String) -> void:
	if variable_en_minijuego == "":
		pausado = false
		return
	if resultado == "abandono":
		_agregar_log(tr("Abandonaste el minijuego de %s: no se recargó (sin castigo).") % Datos.VARIABLES[variable_en_minijuego]["nombre"], "info")
	elif resultado != "cancelado":
		modelo.recargar(variable_en_minijuego, resultado)
		if variable_en_minijuego == "humedad" and resultado != "derrota" and modelo.tiene("bomba_peristaltica"):
			planta.regando = 2.0
	variable_en_minijuego = ""
	pausado = false
	_actualizar_ui()
	_actualizar_consejos()


func _on_cosechar() -> void:
	if modelo.terminado_flag or en_intro:
		return
	if modelo.dia < modelo.dias_cosecha:
		_confirmar(tr("La planta aún no está lista (día %d de %d). Si cosechas ahora PIERDES. ¿Cosechar de todos modos?") % [int(modelo.dia) + 1, int(modelo.dias_cosecha)], modelo.cosechar)
	else:
		modelo.cosechar()


func _confirmar(texto: String, accion: Callable) -> void:
	pausado = true
	texto_confirmar.text = texto
	_accion_confirmar = accion
	panel_confirmar.show()


func _on_confirmar_si() -> void:
	panel_confirmar.hide()
	pausado = en_intro
	if _accion_confirmar.is_valid():
		_accion_confirmar.call()


func _on_confirmar_no() -> void:
	panel_confirmar.hide()
	pausado = en_intro


func _on_terminado(exito: bool, motivo: String) -> void:
	_actualizar_ui()
	if not exito:
		planta.muerta = true
	Juego.registrar_resultado(exito, modelo.vida)
	_agregar_log(motivo, "bien" if exito else "peligro")

	titulo_resultado.text = tr("¡MISIÓN CUMPLIDA!") if exito else tr("MISIÓN FALLIDA")
	titulo_resultado.modulate = Color(0.5, 1, 0.6) if exito else Color(1, 0.5, 0.45)
	var t := "%s\n\n" % motivo
	t += tr("[b]Planta:[/b] %s   ·   [b]Vida final:[/b] %d %%   ·   [b]Vida mínima:[/b] %d %%   ·   [b]Día:[/b] %.1f de %d\n") % [datos_planta["nombre"], int(modelo.vida), int(modelo.vida_minima), modelo.dia, int(modelo.dias_cosecha)]
	t += tr("[b]Calificación del manejo:[/b] %s   ·   [b]Horas sin luz en horario de luz:[/b] %d h\n\n") % [modelo.calificacion(), int(modelo.horas_sin_luz)]
	t += tr("[table=4][cell][b]Variable   [/b][/cell][cell][b]Tiempo en rango   [/b][/cell][cell][b]Tiempo en exceso   [/b][/cell][cell][b]Recargas / riegos[/b][/cell]")
	for v in Datos.ORDEN_VARIABLES:
		var exceso: float = 100.0 * modelo.tiempo_exceso[v] / maxf(modelo.dia, 0.001)
		var n: int = modelo.riegos if v == "humedad" else modelo.recargas[v]
		t += "[cell]%s[/cell][cell]%d %%[/cell][cell]%d %%[/cell][cell]%d[/cell]" % [Datos.VARIABLES[v]["nombre"], int(modelo.porcentaje_en_rango(v)), int(exceso), n]
	t += "[/table]\n\n"
	t += tr("[b]Minijuegos:[/b] %d ganados · %d empates · %d perdidos   ·   [b]Eventos:[/b] %d\n") % [modelo.minijuegos["victoria"], modelo.minijuegos["empate"], modelo.minijuegos["derrota"], modelo.eventos_ocurridos]
	t += tr("[b]Plantas cosechadas en total:[/b] %d") % Juego.cosechas_exitosas
	texto_resultado.text = t
	btn_reintentar.visible = not exito
	btn_resultado_menu.text = tr("Ir al menú") if exito else tr("Menú (otra planta u otras herramientas)")
	for mj in minijuegos_por_variable.values():
		mj.hide()
	panel_confirmar.hide()
	panel_resultado.show()
