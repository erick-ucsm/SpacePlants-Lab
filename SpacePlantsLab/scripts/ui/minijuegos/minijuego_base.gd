extends Control

signal terminado(resultado: String)

const DM = preload("res://scripts/datos_minijuegos.gd")

var titulo: Label
var subtitulo: Label
var reloj: Label
var area: Control
var info: RichTextLabel
var info_imagen: TextureRect
var estado: Label
var boton: Button
var boton_salir: Button

var tiempo_restante: float = 0.0
var jugando: bool = false
var empezado: bool = false
var resultado: String = ""
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_construir_marco()
	hide()
	set_process(false)


func duracion() -> float:
	return 120.0


func _preparar() -> void:
	pass


func _tiempo_agotado() -> void:
	pass


func _actualizar(_delta: float) -> void:
	pass


func _construir_marco() -> void:
	var oscuro := ColorRect.new()
	oscuro.color = Color(0, 0, 0, 0.7)
	oscuro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(oscuro)
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"PanelBorde"
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 30
	panel.offset_top = 22
	panel.offset_right = -30
	panel.offset_bottom = -22
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)

	var cab := HBoxContainer.new()
	v.add_child(cab)
	var textos := VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(textos)
	titulo = Label.new()
	titulo.add_theme_font_size_override("font_size", 24)
	titulo.add_theme_color_override("font_color", Color(0.5, 0.85, 1))
	textos.add_child(titulo)
	subtitulo = Label.new()
	subtitulo.add_theme_font_size_override("font_size", 14)
	subtitulo.add_theme_color_override("font_color", Color(0.78, 0.82, 0.9))
	textos.add_child(subtitulo)
	reloj = Label.new()
	reloj.add_theme_font_size_override("font_size", 26)
	cab.add_child(reloj)

	var cuerpo := HBoxContainer.new()
	cuerpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cuerpo.add_theme_constant_override("separation", 16)
	v.add_child(cuerpo)
	area = Control.new()
	area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	area.clip_contents = true
	cuerpo.add_child(area)
	var lado := PanelContainer.new()
	lado.custom_minimum_size = Vector2(420, 0)
	cuerpo.add_child(lado)
	var vl := VBoxContainer.new()
	vl.add_theme_constant_override("separation", 8)
	lado.add_child(vl)
	info_imagen = TextureRect.new()
	info_imagen.custom_minimum_size = Vector2(0, 150)
	info_imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	info_imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vl.add_child(info_imagen)
	info = RichTextLabel.new()
	info.bbcode_enabled = true
	info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info.add_theme_font_size_override("normal_font_size", 14)
	info.add_theme_font_size_override("bold_font_size", 14)
	vl.add_child(info)

	var pie := HBoxContainer.new()
	pie.add_theme_constant_override("separation", 12)
	v.add_child(pie)
	estado = Label.new()
	estado.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	estado.add_theme_font_size_override("font_size", 16)
	pie.add_child(estado)
	boton_salir = Button.new()
	boton_salir.text = tr("Salir")
	boton_salir.tooltip_text = tr("Abandonar el minijuego: no recarga, pero no hay castigo.")
	boton_salir.custom_minimum_size = Vector2(130, 44)
	boton_salir.add_theme_stylebox_override("normal", _estilo_salir(Color(0.6, 0.18, 0.2)))
	boton_salir.add_theme_stylebox_override("hover", _estilo_salir(Color(0.75, 0.25, 0.27)))
	boton_salir.pressed.connect(_on_salir)
	pie.add_child(boton_salir)
	boton = Button.new()
	boton.custom_minimum_size = Vector2(180, 44)
	boton.pressed.connect(_on_boton)
	pie.add_child(boton)


func _estilo_salir(c: Color) -> StyleBoxFlat:
	var e := StyleBoxFlat.new()
	e.bg_color = c
	e.set_corner_radius_all(6)
	e.content_margin_left = 10
	e.content_margin_right = 10
	return e


func _on_salir() -> void:
	jugando = false
	hide()
	set_process(false)
	terminado.emit("abandono")


func abrir(nombre_variable: String, texto_recarga: String) -> void:
	titulo.text = "%s: %s" % [texto_recarga, nombre_variable]
	resultado = ""
	jugando = true
	empezado = false
	boton.text = tr("Aceptar")
	boton.disabled = true
	boton_salir.visible = true
	info_imagen.texture = null
	info_imagen.visible = true
	estado.modulate = Color.WHITE
	for hijo in area.get_children():
		hijo.queue_free()
	tiempo_restante = duracion()
	show()
	await get_tree().process_frame
	_preparar()
	_mostrar_reloj()
	set_process(true)


func _process(delta: float) -> void:
	if not jugando:
		return
	if empezado:
		tiempo_restante -= delta
		if tiempo_restante <= 0.0:
			tiempo_restante = 0.0
			_mostrar_reloj()
			_tiempo_agotado()
			return
	_mostrar_reloj()
	_actualizar(delta)


func _mostrar_reloj() -> void:
	var s := int(ceil(tiempo_restante))
	reloj.text = "%d:%02d" % [s / 60, s % 60]
	reloj.modulate = Color(1, 0.45, 0.4) if tiempo_restante < 15.0 else Color.WHITE


func marcar_inicio() -> void:
	empezado = true


func terminar(res: String, texto: String) -> void:
	jugando = false
	resultado = res
	var prefijo := {"victoria": tr("¡Ganaste! Recarga completa. "), "empate": tr("Empate: recarga parcial. "), "derrota": tr("Perdiste: no hay recarga y el sistema se bloquea 6 horas. ")}
	estado.text = prefijo.get(res, "") + texto
	estado.modulate = {"victoria": Color(0.5, 1, 0.6), "empate": Color(1, 0.9, 0.5), "derrota": Color(1, 0.55, 0.5)}.get(res, Color.WHITE)
	boton.text = tr("Aceptar")
	boton.disabled = false
	boton_salir.visible = false


func _on_boton() -> void:
	hide()
	set_process(false)
	var r := resultado
	if r == "":
		jugando = false
		r = "cancelado"
	terminado.emit(r)


func elegir(lista: Array) -> Variant:
	return lista[rng.randi_range(0, lista.size() - 1)]
