extends Control

signal elegida(carta)

var persona: Dictionary = {}
var color_generacion: Color = Color(0.3, 0.5, 0.9)
var boca_arriba: bool = false
var encontrada: bool = false
var foto: Texture2D
var _giro: float = 1.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var ruta := "res://assets/minijuegos/personajes/%s.png" % persona.get("id", "")
	if ResourceLoader.exists(ruta):
		foto = load(ruta)


func _gui_input(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT:
		if not boca_arriba and not encontrada:
			elegida.emit(self)


func voltear(arriba: bool) -> void:
	if boca_arriba == arriba:
		return
	var t := create_tween()
	t.tween_property(self, "_giro", 0.0, 0.1)
	t.tween_callback(func(): boca_arriba = arriba)
	t.tween_property(self, "_giro", 1.0, 0.1)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var w := size.x * _giro
	var r := Rect2((size.x - w) * 0.5, 0, w, size.y)
	if w < 2.0:
		return
	if not boca_arriba:
		draw_rect(r, Color(0.08, 0.2, 0.45))
		draw_rect(r.grow(-4), Color(0.12, 0.3, 0.62), false, 2.0)
		var c := r.get_center()
		draw_circle(c, minf(w, size.y) * 0.22, Color(0.05, 0.12, 0.3))
		_estrella(c, minf(w, size.y) * 0.16, Color(1, 1, 1))
		draw_arc(c, minf(w, size.y) * 0.3, -0.4, 2.6, 24, Color(0.85, 0.2, 0.2), 3.0)
		return
	draw_rect(r, Color(0.96, 0.96, 0.98))
	var marco := color_generacion
	if encontrada:
		marco = Color(0.3, 0.85, 0.4)
	draw_rect(r, marco, false, 4.0)
	var retrato := Rect2(r.position.x + 7, 7, w - 14, size.y * 0.72 - 7)
	if _giro > 0.6:
		var fuente := get_theme_default_font()
		draw_multiline_string(fuente, Vector2(r.position.x + 4, size.y * 0.72 + 18), persona.get("nombre", ""), HORIZONTAL_ALIGNMENT_CENTER, w - 8, 13, 2, Color(0.1, 0.1, 0.15))
	if foto != null:
		var tw := float(foto.get_width())
		var th := float(foto.get_height())
		var esc := maxf(retrato.size.x / tw, retrato.size.y / th)
		var region := Rect2(0, 0, retrato.size.x / esc, retrato.size.y / esc)
		region.position.x = (tw - region.size.x) * 0.5
		region.position.y = (th - region.size.y) * 0.2
		draw_texture_rect_region(foto, retrato, region)
		draw_rect(retrato, Color(0, 0, 0, 0.25), false, 1.0)
		return
	draw_rect(retrato, color_generacion.lightened(0.55))
	var cx := retrato.get_center().x
	var base_y := retrato.end.y
	var cabeza := retrato.size.y * 0.2
	var cuerpo := color_generacion.darkened(0.25)
	draw_colored_polygon(PackedVector2Array([Vector2(cx - cabeza * 2.0, base_y), Vector2(cx - cabeza * 1.6, base_y - cabeza * 1.4), Vector2(cx + cabeza * 1.6, base_y - cabeza * 1.4), Vector2(cx + cabeza * 2.0, base_y)]), cuerpo)
	var centro_cabeza := Vector2(cx, base_y - cabeza * 2.4)
	draw_circle(centro_cabeza, cabeza, color_generacion.darkened(0.45))
	match persona.get("rol", ""):
		"astronauta":
			draw_arc(centro_cabeza, cabeza * 1.35, 0, TAU, 32, Color.WHITE, cabeza * 0.35)
			draw_circle(centro_cabeza + Vector2(0, -cabeza * 0.1), cabeza * 0.75, Color(0.95, 0.75, 0.3, 0.55))
		"cientifico", "cientifica":
			draw_colored_polygon(PackedVector2Array([Vector2(cx - cabeza * 0.5, base_y - cabeza * 1.4), Vector2(cx, base_y), Vector2(cx + cabeza * 0.5, base_y - cabeza * 1.4)]), Color.WHITE)
		"ingeniero", "ingeniera":
			draw_arc(centro_cabeza, cabeza * 1.1, PI, TAU, 16, Color(0.15, 0.15, 0.2), 3.0)
			draw_circle(centro_cabeza + Vector2(cabeza * 1.1, 0), cabeza * 0.25, Color(0.15, 0.15, 0.2))
		"matematica":
			draw_arc(centro_cabeza + Vector2(-cabeza * 0.4, 0), cabeza * 0.25, 0, TAU, 12, Color.WHITE, 2.0)
			draw_arc(centro_cabeza + Vector2(cabeza * 0.4, 0), cabeza * 0.25, 0, TAU, 12, Color.WHITE, 2.0)
		"administrador":
			draw_colored_polygon(PackedVector2Array([Vector2(cx - 4, base_y - cabeza * 1.4), Vector2(cx + 4, base_y - cabeza * 1.4), Vector2(cx, base_y)]), Color(0.75, 0.15, 0.15))
		"educadora":
			draw_rect(Rect2(cx + cabeza * 1.2, base_y - cabeza * 1.2, cabeza * 0.9, cabeza * 0.7), Color(0.85, 0.3, 0.25))
	var f := get_theme_default_font()
	var iniciales := ""
	for parte in persona.get("nombre", "").split(" "):
		if parte.length() > 0 and parte[0] == parte[0].to_upper() and parte[0] != ".":
			iniciales += parte[0]
	draw_string(f, retrato.position + Vector2(4, 14), iniciales.substr(0, 3), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color_generacion.darkened(0.5))


func _estrella(c: Vector2, r: float, color: Color) -> void:
	var p := PackedVector2Array()
	for i in 10:
		var a := -PI / 2 + i * PI / 5
		var rr := r if i % 2 == 0 else r * 0.45
		p.append(c + Vector2.from_angle(a) * rr)
	draw_colored_polygon(p, color)
