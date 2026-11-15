extends "res://scripts/ui/minijuegos/minijuego_base.gd"

const META_VICTORIA := 18
const META_EMPATE := 11
const PROB_ASTRONAUTA := 0.15
const SUELO := Color(0.62, 0.62, 0.64)
const VERDE := Color(0.45, 0.85, 0.3)

var campo: Control
var btn_comenzar: Button
var crateres: Array = []
var puntos: int = 0
var golpes: int = 0
var errores: int = 0
var espera: float = 0.0
var transcurrido: float = 0.0
var martillo_t: float = 0.0
var raton := Vector2.ZERO
var flotantes: Array = []
var estrellas: Array = []


func duracion() -> float:
	return 30.0


func _preparar() -> void:
	subtitulo.text = tr("¡Golpea a los alienígenas que salen de los cráteres de la Luna! NO golpees a los astronautas (−2 puntos).")
	info_imagen.visible = false
	info.text = Idioma.t(DM.INFO_ALIENIGENAS)
	estado.text = tr("Gana: %d puntos o más en 30 segundos. Empate: %d a %d puntos.") % [META_VICTORIA, META_EMPATE, META_VICTORIA - 1]
	puntos = 0
	golpes = 0
	errores = 0
	espera = 0.6
	transcurrido = 0.0
	flotantes.clear()
	campo = Control.new()
	campo.size = area.size
	campo.mouse_filter = Control.MOUSE_FILTER_STOP
	campo.draw.connect(_dibujar)
	campo.gui_input.connect(_entrada)
	area.add_child(campo)
	estrellas.clear()
	for i in 90:
		estrellas.append(Vector2(rng.randf() * campo.size.x, rng.randf() * campo.size.y * 0.33))
	crateres.clear()
	var filas := [[0.47, [0.27, 0.5, 0.73], 0.72], [0.65, [0.2, 0.5, 0.8], 0.86], [0.85, [0.16, 0.5, 0.84], 1.0]]
	for f in filas:
		for x in f[1]:
			crateres.append({"pos": Vector2(x * campo.size.x, f[0] * campo.size.y), "escala": f[2], "tipo": "", "t": 0.0, "dur": 1.0, "golpeado": -1.0})
	btn_comenzar = Button.new()
	btn_comenzar.text = tr("¡Comenzar!")
	btn_comenzar.custom_minimum_size = Vector2(220, 60)
	btn_comenzar.add_theme_font_size_override("font_size", 26)
	btn_comenzar.position = (campo.size - Vector2(220, 60)) * 0.5
	btn_comenzar.pressed.connect(_comenzar)
	campo.add_child(btn_comenzar)


func _comenzar() -> void:
	btn_comenzar.queue_free()
	marcar_inicio()


func _actualizar(delta: float) -> void:
	martillo_t = maxf(martillo_t - delta, 0.0)
	for f in flotantes:
		f["t"] += delta
	flotantes = flotantes.filter(func(f): return f["t"] < 0.8)
	if empezado:
		transcurrido += delta
		var progreso := clampf(transcurrido / duracion(), 0.0, 1.0)
		for c in crateres:
			if c["tipo"] != "":
				c["t"] += delta
				if c["t"] >= c["dur"]:
					c["tipo"] = ""
		espera -= delta
		if espera <= 0.0:
			espera = lerpf(0.8, 0.5, progreso)
			var libres := crateres.filter(func(c): return c["tipo"] == "")
			if not libres.is_empty():
				var c: Dictionary = elegir(libres)
				c["tipo"] = "astronauta" if rng.randf() < PROB_ASTRONAUTA else "alien"
				c["t"] = 0.0
				c["dur"] = lerpf(1.25, 0.8, progreso)
				c["golpeado"] = -1.0
	campo.queue_redraw()


func _altura(c: Dictionary) -> float:
	if c["tipo"] == "":
		return 0.0
	var t: float = c["t"]
	var d: float = c["dur"]
	if c["golpeado"] >= 0.0:
		return clampf(1.0 - (t - c["golpeado"]) / 0.25, 0.0, 1.0)
	return clampf(minf(t / 0.15, (d - t) / 0.15), 0.0, 1.0)


func _entrada(evento: InputEvent) -> void:
	if evento is InputEventMouseMotion:
		raton = evento.position
	if not (evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT):
		return
	raton = evento.position
	if not empezado or not jugando:
		return
	martillo_t = 0.15
	for c in crateres:
		if c["tipo"] == "" or c["golpeado"] >= 0.0 or _altura(c) < 0.4:
			continue
		var centro := _centro_personaje(c)
		if raton.distance_to(centro) < 46.0 * c["escala"]:
			c["golpeado"] = c["t"]
			c["dur"] = c["t"] + 0.3
			if c["tipo"] == "alien":
				puntos += 1
				golpes += 1
				flotantes.append({"pos": centro, "texto": "+1", "color": Color(0.5, 1, 0.5), "t": 0.0})
			else:
				puntos -= 2
				errores += 1
				flotantes.append({"pos": centro, "texto": "−2", "color": Color(1, 0.4, 0.4), "t": 0.0})
			estado.text = tr("Puntos: %d (meta %d) · Alienígenas: %d · Astronautas golpeados: %d") % [puntos, META_VICTORIA, golpes, errores]
			return


func _centro_personaje(c: Dictionary) -> Vector2:
	var e: float = c["escala"]
	return c["pos"] + Vector2(0, -50.0 * e * _altura(c) + 10.0 * e)


func _tiempo_agotado() -> void:
	for c in crateres:
		c["tipo"] = ""
	campo.queue_redraw()
	if puntos >= META_VICTORIA:
		terminar("victoria", tr("¡%d puntos! Defendiste la base lunar.") % puntos)
	elif puntos >= META_EMPATE:
		terminar("empate", tr("%d puntos: casi lo logras.") % puntos)
	else:
		terminar("derrota", tr("Solo %d puntos.") % puntos)


func _dibujar() -> void:
	var w := campo.size.x
	var h := campo.size.y
	campo.draw_rect(Rect2(0, 0, w, h), Color(0.02, 0.03, 0.09))
	for s in estrellas:
		campo.draw_circle(s, 1.2, Color(1, 1, 1, 0.8))
	var tierra := Vector2(w * 0.82, h * 0.15)
	campo.draw_circle(tierra, h * 0.1, Color(0.2, 0.45, 0.9))
	campo.draw_circle(tierra + Vector2(-h * 0.03, -h * 0.02), h * 0.045, Color(0.3, 0.65, 0.3))
	campo.draw_circle(tierra + Vector2(h * 0.04, h * 0.04), h * 0.025, Color(0.95, 0.95, 1, 0.85))
	var suelo := PackedVector2Array()
	for i in 21:
		var x := w * i / 20.0
		suelo.append(Vector2(x, h * 0.33 - sin(float(i) / 20.0 * PI) * h * 0.04))
	suelo.append(Vector2(w, h))
	suelo.append(Vector2(0, h))
	campo.draw_colored_polygon(suelo, SUELO)
	for c in crateres:
		_dibujar_crater(c)
	if empezado and jugando:
		_dibujar_hud(w)
	for f in flotantes:
		var font := campo.get_theme_default_font()
		campo.draw_string(font, f["pos"] + Vector2(-12, -40 - f["t"] * 50), f["texto"], HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(f["color"], 1.0 - f["t"] / 0.8))
	if campo.get_rect().has_point(raton) and jugando and empezado:
		_dibujar_martillo(raton)


func _dibujar_hud(w: float) -> void:
	var font := campo.get_theme_default_font()
	campo.draw_rect(Rect2(12, 10, 230, 34), Color(0, 0, 0, 0.5))
	campo.draw_string(font, Vector2(22, 34), tr("Puntos: %d / %d") % [puntos, META_VICTORIA], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
	var p := clampf(float(puntos) / META_VICTORIA, 0.0, 1.0)
	campo.draw_rect(Rect2(12, 48, 230, 10), Color(0.15, 0.15, 0.2))
	campo.draw_rect(Rect2(12, 48, 230 * p, 10), Color(1, 0.8, 0.2))


func _elipse(c: Vector2, rx: float, ry: float, desde: float, hasta: float, pasos: int) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in pasos + 1:
		var a := lerpf(desde, hasta, float(i) / pasos)
		p.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return p


func _dibujar_crater(c: Dictionary) -> void:
	var e: float = c["escala"]
	var pos: Vector2 = c["pos"]
	var rx := 78.0 * e
	var ry := 26.0 * e
	campo.draw_colored_polygon(_elipse(pos + Vector2(0, -4 * e), rx * 1.18, ry * 1.5, 0, TAU, 32), SUELO.darkened(0.25))
	campo.draw_colored_polygon(_elipse(pos, rx, ry, 0, TAU, 32), Color(0.12, 0.12, 0.14))
	var alt := _altura(c)
	if c["tipo"] != "" and alt > 0.0:
		var centro := _centro_personaje(c)
		if c["tipo"] == "alien":
			_dibujar_alien(centro, e, c["golpeado"] >= 0.0)
		else:
			_dibujar_astronauta(centro, e, c["golpeado"] >= 0.0)
		var mascara := _elipse(pos, rx, ry, PI, 0, 20)
		mascara.append(pos + Vector2(rx, 120 * e))
		mascara.append(pos + Vector2(-rx, 120 * e))
		campo.draw_colored_polygon(mascara, SUELO)
	campo.draw_polyline(_elipse(pos, rx, ry, 0, TAU, 32), Color(0.85, 0.85, 0.88), 3.0 * e)


func _dibujar_alien(c: Vector2, e: float, golpeado: bool) -> void:
	var verde := VERDE if not golpeado else VERDE.darkened(0.3)
	campo.draw_colored_polygon(_elipse(c + Vector2(0, 38 * e), 30 * e, 28 * e, 0, TAU, 20), verde.darkened(0.1))
	for lado in [-1.0, 1.0]:
		var base := c + Vector2(lado * 14 * e, -26 * e)
		var punta := c + Vector2(lado * 24 * e, -50 * e)
		campo.draw_line(base, punta, verde.darkened(0.2), 3.0 * e)
		campo.draw_circle(punta, 6 * e, verde.lightened(0.2))
	campo.draw_circle(c, 32 * e, verde)
	if golpeado:
		for lado in [-1.0, 1.0]:
			var o := c + Vector2(lado * 12 * e, -4 * e)
			campo.draw_line(o + Vector2(-6, -6) * e, o + Vector2(6, 6) * e, Color.BLACK, 3.0 * e)
			campo.draw_line(o + Vector2(6, -6) * e, o + Vector2(-6, 6) * e, Color.BLACK, 3.0 * e)
		for k in 3:
			campo.draw_circle(c + Vector2.from_angle(k * TAU / 3.0 + Time.get_ticks_msec() / 200.0) * 38 * e + Vector2(0, -30 * e), 4 * e, Color(1, 0.95, 0.3))
	else:
		for lado in [-1.0, 1.0]:
			var o := c + Vector2(lado * 12 * e, -4 * e)
			campo.draw_circle(o, 10 * e, Color.WHITE)
			campo.draw_circle(o + Vector2(lado * 2, 2) * e, 5 * e, Color(0.1, 0.1, 0.15))
			campo.draw_circle(o + Vector2(lado * 2 - 2, -1) * e, 1.8 * e, Color.WHITE)
		campo.draw_arc(c + Vector2(0, 12 * e), 10 * e, 0.3, PI - 0.3, 12, Color(0.15, 0.3, 0.1), 3.0 * e)


func _dibujar_astronauta(c: Vector2, e: float, golpeado: bool) -> void:
	campo.draw_colored_polygon(_elipse(c + Vector2(0, 40 * e), 30 * e, 26 * e, 0, TAU, 20), Color(0.92, 0.92, 0.95))
	campo.draw_rect(Rect2(c + Vector2(-8, 30) * e, Vector2(16, 10) * e), Color(0.25, 0.45, 0.9))
	campo.draw_circle(c, 30 * e, Color(0.97, 0.97, 1))
	campo.draw_colored_polygon(_elipse(c + Vector2(0, 2 * e), 21 * e, 16 * e, 0, TAU, 20), Color(0.95, 0.7, 0.2) if not golpeado else Color(0.6, 0.3, 0.2))
	campo.draw_circle(c + Vector2(-8, -6) * e, 4 * e, Color(1, 1, 1, 0.7))
	if golpeado:
		campo.draw_line(c + Vector2(-14, -10) * e, c + Vector2(10, 12) * e, Color(0.2, 0.1, 0.1), 2.0 * e)


func _dibujar_martillo(p: Vector2) -> void:
	var giro := -0.9 if martillo_t > 0.0 else 0.0
	var dir := Vector2.from_angle(-PI * 0.25 + giro)
	var mango_fin := p + Vector2(40, 40).rotated(giro)
	campo.draw_line(p + Vector2(6, 6).rotated(giro), mango_fin, Color(0.55, 0.35, 0.18), 7.0)
	var cabeza_centro := p + Vector2(4, 4).rotated(giro)
	var eje := dir.orthogonal()
	var poli := PackedVector2Array([cabeza_centro + eje * 22 + dir * 11, cabeza_centro + eje * 22 - dir * 11, cabeza_centro - eje * 22 - dir * 11, cabeza_centro - eje * 22 + dir * 11])
	campo.draw_colored_polygon(poli, Color(0.65, 0.42, 0.22))
	campo.draw_polyline(poli + PackedVector2Array([poli[0]]), Color(0.35, 0.2, 0.1), 2.0)
