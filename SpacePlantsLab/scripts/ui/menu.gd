extends Control

@onready var btn_jugar: Button = %BtnJugar
@onready var btn_ajustes: Button = %BtnAjustes
@onready var label_record: Label = %LabelRecord
@onready var panel_ajustes: Control = %PanelAjustes
@onready var check_pantalla: CheckButton = %CheckPantallaCompleta
@onready var opcion_velocidad: OptionButton = %OpcionVelocidad
@onready var btn_borrar: Button = %BtnBorrarRecord
@onready var btn_cerrar_ajustes: Button = %BtnCerrarAjustes


func _ready() -> void:
	btn_jugar.pressed.connect(Juego.nueva_partida)
	btn_ajustes.pressed.connect(_abrir_ajustes)
	btn_cerrar_ajustes.pressed.connect(func(): panel_ajustes.hide())
	btn_borrar.pressed.connect(_on_borrar)
	check_pantalla.toggled.connect(_on_pantalla_completa)
	opcion_velocidad.item_selected.connect(_on_velocidad)

	_crear_opcion_idioma()
	Idioma.idioma_cambiado.connect(_actualizar_record)
	opcion_velocidad.clear()
	for v in Datos.VELOCIDADES:
		opcion_velocidad.add_item("x%s" % str(v))
	panel_ajustes.hide()
	_actualizar_record()


func _actualizar_record() -> void:
	label_record.text = tr("Plantas cosechadas con éxito: %d\nMisiones jugadas: %d") % [Juego.cosechas_exitosas, Juego.misiones_jugadas]
	if Juego.cosechas_exitosas > 0:
		label_record.text += tr("\nMejor vida al cosechar: %d %%") % int(Juego.mejor_vida)


func _abrir_ajustes() -> void:
	check_pantalla.set_pressed_no_signal(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	opcion_velocidad.select(Juego.velocidad_inicial)
	panel_ajustes.show()


func _on_pantalla_completa(activo: bool) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if activo else DisplayServer.WINDOW_MODE_WINDOWED)


func _on_velocidad(indice: int) -> void:
	Juego.velocidad_inicial = indice
	Juego.guardar_record()


func _on_borrar() -> void:
	Juego.borrar_record()
	_actualizar_record()


var opcion_idioma: OptionButton


func _crear_opcion_idioma() -> void:
	var fila := HBoxContainer.new()
	var etiqueta := Label.new()
	etiqueta.text = "Idioma"
	etiqueta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(etiqueta)
	opcion_idioma = OptionButton.new()
	opcion_idioma.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	var codigos := Idioma.IDIOMAS.keys()
	for i in codigos.size():
		opcion_idioma.add_item(Idioma.IDIOMAS[codigos[i]])
		if codigos[i] == Idioma.idioma:
			opcion_idioma.select(i)
	opcion_idioma.item_selected.connect(func(i): Idioma.cambiar(codigos[i]))
	fila.add_child(opcion_idioma)
	var caja := check_pantalla.get_parent()
	caja.add_child(fila)
	caja.move_child(fila, check_pantalla.get_index())
	panel_ajustes.offset_top -= 30
	panel_ajustes.offset_bottom += 30
