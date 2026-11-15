extends Control

const COLOR_ACENTO := "#7fd4ff"
const COLOR_AGREGADO := "#ffd27f"
const COLOR_RECOMENDACION := {
	"verde": Color(0.35, 0.95, 0.45),
	"rojo": Color(1.0, 0.35, 0.3),
	"neutro": Color(0.72, 0.75, 0.82),
}
const TEXTO_RECOMENDACION := {
	"verde": "RECOMENDADO",
	"rojo": "NO RECOMENDADO",
	"neutro": "NEUTRO",
}

@onready var titulo: Label = %Titulo
@onready var instruccion: Label = %Instruccion
@onready var info_titulo: Label = %InfoTitulo
@onready var info_texto: RichTextLabel = %InfoTexto
@onready var opciones: GridContainer = %Opciones
@onready var btn_menu: Button = %BtnMenu
@onready var btn_instrucciones: Button = %BtnInstrucciones
@onready var btn_anterior: Button = %BtnAnterior
@onready var btn_siguiente: Button = %BtnSiguiente
@onready var label_paso: Label = %LabelPaso
@onready var label_masa: Label = %LabelMasa
@onready var barra_masa: ProgressBar = %BarraMasa
@onready var label_energia: Label = %LabelEnergia
@onready var panel_instrucciones: Control = %PanelInstrucciones
@onready var btn_cerrar_instrucciones: Button = %BtnCerrarInstrucciones

var paso: Dictionary


func _ready() -> void:
	btn_menu.pressed.connect(func(): Juego.ir_a(Juego.ESCENA_MENU))
	btn_instrucciones.pressed.connect(func(): panel_instrucciones.visible = not panel_instrucciones.visible)
	btn_cerrar_instrucciones.pressed.connect(func(): panel_instrucciones.hide())
	btn_anterior.pressed.connect(_on_anterior)
	btn_siguiente.pressed.connect(_on_siguiente)
	panel_instrucciones.hide()
	_mostrar_paso()


func _mostrar_paso() -> void:
	paso = Datos.PASOS[Juego.paso_actual]
	titulo.text = paso["titulo"]
	instruccion.text = paso["instruccion"]
	if paso["id"] != "semilla":
		instruccion.text += tr("\nVerde = recomendado · Rojo = no recomendado · Gris = neutro (para %s)") % Datos.planta(Juego.semilla())["nombre"].to_lower()
	label_paso.text = tr("Paso %d de %d") % [Juego.paso_actual + 1, Datos.PASOS.size()]
	btn_anterior.disabled = Juego.paso_actual == 0
	btn_siguiente.disabled = not Juego.selecciones.has(paso["id"])

	for hijo in opciones.get_children():
		hijo.queue_free()

	var lista: Array = paso["opciones"]
	opciones.columns = 3 if lista.size() > 4 else 2
	var lado := 165.0 if lista.size() > 4 else 180.0
	if lista.size() == 4:
		lado = 160.0
	for id in lista:
		opciones.add_child(_crear_tarjeta(id, lado))

	var elegido: String = Juego.selecciones.get(paso["id"], "")
	if elegido != "":
		_mostrar_info(elegido)
	else:
		info_titulo.text = paso["titulo"]
		info_texto.text = tr("Pasa el mouse sobre una opción para ver su información.\nHaz clic para elegirla y avanzar al siguiente paso.")
	_actualizar_presupuesto()


func _crear_tarjeta(id: String, lado: float) -> Button:
	var es_semilla: bool = paso["id"] == "semilla"
	var tarjeta := Button.new()
	tarjeta.theme_type_variation = &"Tarjeta"
	tarjeta.custom_minimum_size = Vector2(lado, lado)
	tarjeta.toggle_mode = true
	tarjeta.button_pressed = Juego.selecciones.get(paso["id"], "") == id
	tarjeta.tooltip_text = ""

	var caja := VBoxContainer.new()
	caja.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
	caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tarjeta.add_child(caja)

	var icono := TextureRect.new()
	icono.texture = Datos.cargar_textura(Datos.icono_semilla(id) if es_semilla else Datos.icono_componente(id))
	icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icono.size_flags_vertical = Control.SIZE_EXPAND_FILL
	icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja.add_child(icono)

	var nombre := Label.new()
	nombre.text = Datos.PLANTAS[id]["nombre"] if es_semilla else Datos.COMPONENTES[id]["nombre"]
	nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nombre.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nombre.add_theme_font_size_override("font_size", 14)
	nombre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja.add_child(nombre)

	var etiqueta := Label.new()
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.add_theme_font_size_override("font_size", 12)
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if es_semilla:
		var p: Dictionary = Datos.PLANTAS[id]
		etiqueta.text = tr("%s (%d/5) · %d días") % [p["etiqueta"], p["dificultad"], p["dias"]]
		etiqueta.add_theme_color_override("font_color", Datos.color_dificultad(p["dificultad"]))
	else:
		var r := Datos.recomendacion(id, Juego.semilla())
		var color: Color = COLOR_RECOMENDACION[r[0]]
		etiqueta.text = tr(TEXTO_RECOMENDACION[r[0]])
		etiqueta.add_theme_color_override("font_color", color)
		_pintar_borde(tarjeta, color, r[0] != "neutro")
	caja.add_child(etiqueta)

	tarjeta.mouse_entered.connect(_mostrar_info.bind(id))
	tarjeta.focus_entered.connect(_mostrar_info.bind(id))
	tarjeta.pressed.connect(_on_elegir.bind(id))
	return tarjeta


func _pintar_borde(tarjeta: Button, color: Color, fuerte: bool) -> void:
	for estado in ["normal", "hover", "pressed", "hover_pressed"]:
		var base := tarjeta.get_theme_stylebox(estado, &"Tarjeta")
		if base is StyleBoxFlat:
			var e: StyleBoxFlat = base.duplicate()
			e.border_color = color if estado != "hover" else color.lightened(0.3)
			e.set_border_width_all(4 if fuerte else 2)
			tarjeta.add_theme_stylebox_override(estado, e)


func _mostrar_info(id: String) -> void:
	if paso["id"] == "semilla":
		var p: Dictionary = Datos.PLANTAS[id]
		info_titulo.text = "%s %s" % [p["nombre"], p["variedad"]]
		var col := Datos.color_dificultad(p["dificultad"]).to_html(false)
		var t1 := tr("[color=#%s][b]Dificultad: %s (%d/5)[/b][/color]   ·   [b]Tiempo de cultivo:[/b] %d días simulados\n[i]%s[/i]\n\n") % [col, p["etiqueta"], p["dificultad"], p["dias"], p["resumen"]]
		t1 += tr("%s\n\n[color=%s][b]En el espacio:[/b][/color] %s\n\n") % [p["descripcion"], COLOR_ACENTO, p["historia"]]
		t1 += tr("[b]Rango ideal:[/b] sustrato %d-%d %% · %d-%d °C · luz %d-%d µmol/m²/s · fotoperiodo 16 h luz / 8 h oscuridad") % [p["humedad"][0], p["humedad"][1], p["temperatura"][0], p["temperatura"][1], p["par"][0], p["par"][1]]
		info_texto.text = t1
		return
	var c: Dictionary = Datos.COMPONENTES[id]
	info_titulo.text = c["nombre"]
	var r := Datos.recomendacion(id, Juego.semilla())
	var col_r: String = COLOR_RECOMENDACION[r[0]].to_html(false)
	var t := tr("[color=#%s][b]%s para %s:[/b] %s[/color]\n\n") % [col_r, tr(TEXTO_RECOMENDACION[r[0]]).capitalize(), Datos.planta(Juego.semilla())["nombre"].to_lower(), r[1]]
	t += tr("%s\n\n[b]Cómo funciona:[/b] %s\n\n[b]Ejemplo real:[/b] %s\n\n") % [c["que_hace"], c["como_funciona"], c["ejemplo"]]
	t += tr("[color=%s][b]En el juego:[/b] %s[/color]\n\n") % [COLOR_ACENTO, c["efecto"]]
	if c.has("por_que"):
		t += tr("[color=%s][b]¿Por qué lo agregamos?[/b] %s[/color]\n\n") % [COLOR_AGREGADO, c["por_que"]]
	t += tr("[b]Masa:[/b] %s    [b]Consumo eléctrico:[/b] %s") % [Datos.texto_masa(c["masa_kg"]), Datos.texto_potencia(c["potencia_w"])]
	if c.has("capacidad"):
		t += tr("    [b]Capacidad:[/b] %s") % c["capacidad"]
	info_texto.text = t


func _on_elegir(id: String) -> void:
	Juego.selecciones[paso["id"]] = id
	_on_siguiente()


func _on_siguiente() -> void:
	if not Juego.selecciones.has(paso["id"]):
		return
	if Juego.paso_actual >= Datos.PASOS.size() - 1:
		Juego.ir_a(Juego.ESCENA_RESUMEN)
		return
	Juego.paso_actual += 1
	_mostrar_paso()


func _on_anterior() -> void:
	if Juego.paso_actual > 0:
		Juego.paso_actual -= 1
		_mostrar_paso()


func _actualizar_presupuesto() -> void:
	var masa := Juego.masa_total()
	barra_masa.max_value = Datos.MASA_MAXIMA_KG
	barra_masa.value = minf(masa, Datos.MASA_MAXIMA_KG)
	label_masa.text = tr("Masa de lanzamiento: %.1f / %.1f kg") % [masa, Datos.MASA_MAXIMA_KG]
	label_masa.modulate = Color(1, 0.5, 0.45) if masa > Datos.MASA_MAXIMA_KG else Color.WHITE
	label_energia.text = tr("Consumo eléctrico: %s (con LEDs encendidos)") % Datos.texto_potencia(Juego.consumo_total())
