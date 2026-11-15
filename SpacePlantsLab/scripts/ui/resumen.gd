extends Control

const ModeloCultivo = preload("res://scripts/modelo_cultivo.gd")
const COLORES := {"verde": Color(0.35, 0.95, 0.45), "rojo": Color(1.0, 0.4, 0.35), "neutro": Color(0.85, 0.87, 0.92)}
const COLORES_NIVEL := {"Fácil": Color(0.45, 0.95, 0.55), "Media": Color(1.0, 0.85, 0.35), "Difícil": Color(1.0, 0.45, 0.4)}

@onready var lista: GridContainer = %ListaComponentes
@onready var icono_semilla: TextureRect = %IconoSemilla
@onready var nombre_semilla: Label = %NombreSemilla
@onready var texto_analisis: RichTextLabel = %TextoAnalisis
@onready var btn_menu: Button = %BtnMenu
@onready var btn_anterior: Button = %BtnAnterior
@onready var btn_lanzar: Button = %BtnLanzar

var popup: PanelContainer
var titulo_popup: Label
var cuerpo_popup: RichTextLabel


func _ready() -> void:
	btn_menu.pressed.connect(func(): Juego.ir_a(Juego.ESCENA_MENU))
	btn_anterior.pressed.connect(_on_anterior)
	btn_lanzar.pressed.connect(_mostrar_popup)

	var s := Juego.semilla()
	var p := Datos.planta(s)
	icono_semilla.texture = Datos.cargar_textura(Datos.icono_semilla(s))
	nombre_semilla.text = tr("%s · %s (%d/5) · %d días") % [p["nombre"], p["etiqueta"], p["dificultad"], p["dias"]]

	for id in Juego.componentes_elegidos():
		lista.add_child(_crear_item(id, s))

	var masa := Juego.masa_total()
	var excedido := masa > Datos.MASA_MAXIMA_KG
	var t := tr("[b]Masa de lanzamiento:[/b] %.1f / %.1f kg\n") % [masa, Datos.MASA_MAXIMA_KG]
	t += tr("[b]Consumo eléctrico:[/b] %s con LEDs encendidos · %s con LEDs apagados\n\n") % [Datos.texto_potencia(Juego.consumo_total()), Datos.texto_potencia(Juego.potencia_otros())]
	if excedido:
		t += tr("[color=#ff8a80][b]¡Demasiado pesado![/b] El cohete no puede lanzar más de %.0f kg. Regresa y cambia algún componente por uno más ligero.[/color]\n\n") % Datos.MASA_MAXIMA_KG
	if Juego.potencia_otros() > 30.0:
		t += tr("[color=#ffd27f]Tus componentes gastan mucha energía aunque la luz esté apagada: la batería durará poco.[/color]\n\n")
	t += tr("[b]Lo que verás en el panel de control:[/b]\n")
	var modelo := ModeloCultivo.new(Juego.componentes_elegidos(), s, Juego.potencia_led(), Juego.potencia_otros(), 0)
	for v in Datos.ORDEN_VARIABLES:
		var nombre: String = Datos.VARIABLES[v]["nombre"]
		var visto := tr("valor exacto") if modelo.es_exacto(v) else (tr("??? (a ciegas)") if v == "humedad" else tr("solo estado aproximado"))
		t += "• %s: %s\n" % [nombre, visto]
	t += tr("• Riego: %s\n") % (tr("automático") if not modelo.riego_manual() and modelo.agua_llega() else (tr("manual (botón Regar)") if modelo.agua_llega() else tr("[color=#ff8a80]el agua NO llegará a la planta[/color]")))
	t += tr("• Luz: %s\n") % (tr("automática 16/8 con temporizador") if modelo.luz_automatica() else (tr("natural (no controlable)") if not modelo.tiene("panel_led") else tr("manual: tú enciendes y apagas los LEDs")))
	texto_analisis.text = t
	btn_lanzar.disabled = excedido
	_crear_popup()


func _crear_item(id: String, planta_id: String) -> Control:
	var r := Datos.recomendacion(id, planta_id)
	var caja := VBoxContainer.new()
	caja.custom_minimum_size = Vector2(110, 0)
	var marco := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0, 0, 0, 0)
	estilo.border_color = COLORES[r[0]] if not Datos.BASE_KIT.has(id) else Color(0.5, 0.55, 0.6)
	estilo.set_border_width_all(3 if r[0] != "neutro" else 1)
	estilo.set_corner_radius_all(6)
	marco.add_theme_stylebox_override("panel", estilo)
	var icono := TextureRect.new()
	icono.texture = Datos.cargar_textura(Datos.icono_componente(id))
	icono.custom_minimum_size = Vector2(72, 72)
	icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icono.tooltip_text = r[1] if r[1] != "" else Datos.COMPONENTES[id]["efecto"]
	marco.add_child(icono)
	caja.add_child(marco)
	var nombre := Label.new()
	nombre.text = "%s\n%s · %s" % [Datos.COMPONENTES[id]["nombre"], Datos.texto_masa(Datos.masa_de(id)), Datos.texto_potencia(Datos.potencia_de(id))]
	nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nombre.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nombre.add_theme_font_size_override("font_size", 11)
	caja.add_child(nombre)
	return caja


func _crear_popup() -> void:
	var oscuro := ColorRect.new()
	oscuro.name = "Oscuro"
	oscuro.color = Color(0, 0, 0, 0.6)
	oscuro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	popup = PanelContainer.new()
	popup.theme_type_variation = &"PanelBorde"
	popup.anchor_left = 0.5
	popup.anchor_right = 0.5
	popup.anchor_top = 0.5
	popup.anchor_bottom = 0.5
	popup.offset_left = -370
	popup.offset_right = 370
	popup.offset_top = -250
	popup.offset_bottom = 250
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	popup.add_child(v)
	var titulo := Label.new()
	titulo.name = "TituloDificultad"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 26)
	v.add_child(titulo)
	titulo_popup = titulo
	var cuerpo := RichTextLabel.new()
	cuerpo.name = "CuerpoDificultad"
	cuerpo.bbcode_enabled = true
	cuerpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(cuerpo)
	cuerpo_popup = cuerpo
	var botones := HBoxContainer.new()
	botones.alignment = BoxContainer.ALIGNMENT_CENTER
	botones.add_theme_constant_override("separation", 20)
	var aceptar := Button.new()
	aceptar.text = tr("Aceptar")
	aceptar.custom_minimum_size = Vector2(180, 46)
	aceptar.pressed.connect(func(): Juego.ir_a(Juego.ESCENA_SIMULACION))
	var reiniciar := Button.new()
	reiniciar.text = tr("Reiniciar")
	reiniciar.custom_minimum_size = Vector2(180, 46)
	reiniciar.pressed.connect(Juego.nueva_partida)
	botones.add_child(aceptar)
	botones.add_child(reiniciar)
	v.add_child(botones)
	var capa := Control.new()
	capa.name = "CapaPopup"
	capa.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	capa.add_child(oscuro)
	capa.add_child(popup)
	add_child(capa)
	capa.hide()


func _mostrar_popup() -> void:
	var ev := Juego.evaluacion()
	var p := Datos.planta(Juego.semilla())
	var titulo := titulo_popup
	var cuerpo := cuerpo_popup
	titulo.text = tr("Nivel de Dificultad de la Misión: %s") % tr(ev["nivel"])
	titulo.add_theme_color_override("font_color", COLORES_NIVEL[ev["nivel"]])
	var t := tr("Elegiste [b]%s[/b] (dificultad %s, %d/5). %s ") % [p["nombre"], p["etiqueta"].to_lower(), p["dificultad"], p["resumen"]]
	if p["dias"] >= 60:
		t += tr("Necesita un ciclo largo de %d días: más tiempo para que algo salga mal.") % p["dias"]
	else:
		t += tr("Su ciclo es de %d días.") % p["dias"]
	t += "\n\n"
	if ev["rojos"].is_empty():
		t += tr("[color=#7cf29a]Ningún componente es perjudicial para esta planta.[/color]\n")
	else:
		t += tr("[color=#ff8a80][b]Componentes que aumentan el riesgo de estrés:[/b][/color]\n")
		for linea in ev["rojos"]:
			t += "• %s\n" % linea
	if not ev["verdes"].is_empty():
		t += tr("\n[color=#7cf29a][b]Buenas elecciones:[/b][/color]\n")
		for linea in ev["verdes"]:
			t += "• %s\n" % linea
	t += tr("\n[b]Consumo:[/b] %s con LEDs · [b]Masa:[/b] %.1f kg") % [Datos.texto_potencia(Juego.consumo_total()), Juego.masa_total()]
	cuerpo.text = t
	popup.get_parent().show()


func _on_anterior() -> void:
	Juego.paso_actual = Datos.PASOS.size() - 1
	Juego.ir_a(Juego.ESCENA_SELECCION)
