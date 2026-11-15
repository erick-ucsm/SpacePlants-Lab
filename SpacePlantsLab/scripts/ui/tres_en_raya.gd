extends Control

signal terminado(resultado: String)

const LINEAS := [[0, 1, 2], [3, 4, 5], [6, 7, 8], [0, 3, 6], [1, 4, 7], [2, 5, 8], [0, 4, 8], [2, 4, 6]]
const PROB_BLOQUEO := 0.8
const PROB_ESTRATEGIA := 0.6

@onready var titulo: Label = %TituloMinijuego
@onready var estado: Label = %EstadoMinijuego
@onready var tablero: GridContainer = %Tablero
@onready var btn_accion: Button = %BtnAccionMinijuego

var celdas: Array[String] = []
var botones: Array[Button] = []
var turno_jugador := true
var resultado := ""
var jugando := false
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	for b in tablero.get_children():
		var boton := b as Button
		botones.append(boton)
		boton.pressed.connect(_on_celda.bind(botones.size() - 1))
	btn_accion.pressed.connect(_on_accion)
	hide()


func abrir(nombre_variable: String, texto_recarga: String) -> void:
	titulo.text = "%s: %s" % [texto_recarga, nombre_variable]
	estado.text = tr("Tú eres X. Gana para recargar al máximo.\nEmpate = recarga parcial. Derrota = sin recarga.")
	celdas.clear()
	for i in 9:
		celdas.append("")
		botones[i].text = ""
		botones[i].disabled = false
	turno_jugador = true
	resultado = ""
	jugando = true
	btn_accion.text = tr("Salir (abandonar)")
	btn_accion.disabled = false
	show()


func _on_celda(i: int) -> void:
	if not jugando or not turno_jugador or celdas[i] != "":
		return
	_marcar(i, "X")
	if _revisar_fin():
		return
	turno_jugador = false
	estado.text = tr("La computadora está pensando...")
	await get_tree().create_timer(0.45).timeout
	if not jugando:
		return
	_marcar(_movimiento_cpu(), "O")
	if _revisar_fin():
		return
	turno_jugador = true
	estado.text = tr("Tu turno.")


func _marcar(i: int, ficha: String) -> void:
	celdas[i] = ficha
	botones[i].text = ficha
	botones[i].disabled = true
	botones[i].add_theme_color_override("font_disabled_color", Color(0.4, 0.85, 1) if ficha == "X" else Color(1, 0.55, 0.45))


func _ganador() -> String:
	for l in LINEAS:
		if celdas[l[0]] != "" and celdas[l[0]] == celdas[l[1]] and celdas[l[1]] == celdas[l[2]]:
			return celdas[l[0]]
	if not celdas.has(""):
		return "empate"
	return ""


func _revisar_fin() -> bool:
	var g := _ganador()
	if g == "":
		return false
	jugando = false
	for b in botones:
		b.disabled = true
	match g:
		"X":
			resultado = "victoria"
			estado.text = tr("¡Ganaste! Recarga completa.")
		"O":
			resultado = "derrota"
			estado.text = tr("Perdiste. No hay recarga y el sistema se bloquea 6 horas.")
		_:
			resultado = "empate"
			estado.text = tr("Empate. Recarga parcial.")
	btn_accion.text = tr("Aceptar")
	btn_accion.disabled = false
	return true


func _jugada_que_completa(ficha: String) -> int:
	for l in LINEAS:
		var cuenta := 0
		var libre := -1
		for i in l:
			if celdas[i] == ficha:
				cuenta += 1
			elif celdas[i] == "":
				libre = i
		if cuenta == 2 and libre != -1:
			return libre
	return -1


func _libres() -> Array[int]:
	var lista: Array[int] = []
	for i in 9:
		if celdas[i] == "":
			lista.append(i)
	return lista


func _movimiento_cpu() -> int:
	var ganar := _jugada_que_completa("O")
	if ganar != -1:
		return ganar
	var bloquear := _jugada_que_completa("X")
	if bloquear != -1 and rng.randf() < PROB_BLOQUEO:
		return bloquear
	var libres := _libres()
	if rng.randf() < PROB_ESTRATEGIA:
		if celdas[4] == "":
			return 4
		var esquinas: Array[int] = []
		for i in [0, 2, 6, 8]:
			if celdas[i] == "":
				esquinas.append(i)
		if not esquinas.is_empty():
			return esquinas[rng.randi_range(0, esquinas.size() - 1)]
	return libres[rng.randi_range(0, libres.size() - 1)]


func _on_accion() -> void:
	hide()
	if jugando:
		jugando = false
		terminado.emit("abandono")
	else:
		terminado.emit(resultado)
