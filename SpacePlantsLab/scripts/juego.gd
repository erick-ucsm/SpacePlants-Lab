extends Node

const RUTA_RECORD := "user://record.cfg"

const ESCENA_MENU := "res://scenes/menu.tscn"
const ESCENA_SELECCION := "res://scenes/seleccion.tscn"
const ESCENA_RESUMEN := "res://scenes/resumen.tscn"
const ESCENA_SIMULACION := "res://scenes/simulacion.tscn"

var selecciones: Dictionary = {}
var paso_actual: int = 0
var velocidad_inicial: int = 1

var misiones_jugadas: int = 0
var cosechas_exitosas: int = 0
var mejor_vida: float = 0.0


func _ready() -> void:
	cargar_record()


func nueva_partida() -> void:
	selecciones.clear()
	paso_actual = 0
	ir_a(ESCENA_SELECCION)


func ir_a(escena: String) -> void:
	get_tree().change_scene_to_file.call_deferred(escena)


func semilla() -> String:
	return selecciones.get("semilla", "")


func componentes_elegidos() -> Array[String]:
	var lista: Array[String] = []
	for id in Datos.BASE_KIT:
		lista.append(id)
	for paso in Datos.PASOS:
		if paso["id"] == "semilla":
			continue
		if selecciones.has(paso["id"]):
			lista.append(selecciones[paso["id"]])
	return lista


func tiene(componente_id: String) -> bool:
	return componentes_elegidos().has(componente_id)


func masa_total() -> float:
	var total := 0.0
	for id in componentes_elegidos():
		total += Datos.masa_de(id)
	return total


func potencia_led() -> float:
	if not tiene("panel_led"):
		return 0.0
	return Datos.potencia_de("panel_led") * (0.7 if tiene("atenuador_pwm") else 1.0)


func potencia_otros() -> float:
	var total := 0.0
	for id in componentes_elegidos():
		if id != "panel_led":
			total += Datos.potencia_de(id)
	return total


func consumo_total() -> float:
	return potencia_led() + potencia_otros()


func evaluacion() -> Dictionary:
	var verdes: Array[String] = []
	var rojos: Array[String] = []
	var p := semilla()
	for paso in Datos.PASOS:
		if paso["id"] == "semilla" or not selecciones.has(paso["id"]):
			continue
		var id: String = selecciones[paso["id"]]
		var r := Datos.recomendacion(id, p)
		var linea := "%s: %s" % [Datos.COMPONENTES[id]["nombre"], r[1]]
		if r[0] == "verde":
			verdes.append(linea)
		elif r[0] == "rojo":
			rojos.append(linea)
	var base: int = Datos.planta(p)["dificultad"]
	var puntos := float(base) + 1.2 * rojos.size() - 0.4 * mini(verdes.size(), 5)
	var nivel := "Fácil"
	if puntos > 4.5:
		nivel = "Difícil"
	elif puntos > 2.5:
		nivel = "Media"
	return {"nivel": nivel, "puntos": puntos, "verdes": verdes, "rojos": rojos}


func seleccion_completa() -> bool:
	for paso in Datos.PASOS:
		if not selecciones.has(paso["id"]):
			return false
	return true


func registrar_resultado(exito: bool, vida: float) -> void:
	misiones_jugadas += 1
	if exito:
		cosechas_exitosas += 1
		mejor_vida = maxf(mejor_vida, vida)
	guardar_record()


func borrar_record() -> void:
	misiones_jugadas = 0
	cosechas_exitosas = 0
	mejor_vida = 0.0
	guardar_record()


func guardar_record() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("record", "misiones", misiones_jugadas)
	cfg.set_value("record", "cosechas", cosechas_exitosas)
	cfg.set_value("record", "mejor_vida", mejor_vida)
	cfg.set_value("ajustes", "velocidad_inicial", velocidad_inicial)
	cfg.save(RUTA_RECORD)


func cargar_record() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(RUTA_RECORD) != OK:
		return
	misiones_jugadas = cfg.get_value("record", "misiones", 0)
	cosechas_exitosas = cfg.get_value("record", "cosechas", 0)
	mejor_vida = cfg.get_value("record", "mejor_vida", 0.0)
	velocidad_inicial = cfg.get_value("ajustes", "velocidad_inicial", 1)
