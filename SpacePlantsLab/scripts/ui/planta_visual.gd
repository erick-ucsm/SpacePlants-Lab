extends Control

const ROSA := Color(1.0, 0.35, 0.85)
const AGUA := Color(0.35, 0.65, 0.95, 0.85)
const MECHA := Color(0.9, 0.85, 0.7)
const BOLSA := Color(0.93, 0.93, 0.9)
const MARCHITO := Color(0.62, 0.56, 0.25)
const SECO := Color(0.38, 0.27, 0.15)

var especie: String = "lechuga_romana"
var progreso: float = 0.0
var vida: float = 100.0
var muerta: bool = false
var luz_activa: bool = false
var luz_natural: bool = false
var nivel_agua: float = 100.0
var humedad: float = 60.0
var riego: String = "mecha_absorbente"
var intro: float = 1.0
var regando: float = 0.0

var _marchitez_muerte: float = 0.0
var _tiempo: float = 0.0
var _bolitas: Array = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 1234
	for i in 260:
		_bolitas.append([Vector2(r.randf_range(0.03, 0.97), r.randf_range(0.06, 0.94)), r.randf_range(0.01, 0.016), r.randf_range(-0.08, 0.08)])


func _process(delta: float) -> void:
	_tiempo += delta
	if muerta and _marchitez_muerte < 1.0:
		_marchitez_muerte = minf(_marchitez_muerte + delta * 0.6, 1.0)
	regando = maxf(regando - delta, 0.0)
	queue_redraw()


func iniciar_intro() -> void:
	intro = 0.0
	var t := create_tween()
	t.tween_property(self, "intro", 1.0, 4.5)


func agua_llega() -> bool:
	return riego in ["mecha_absorbente", "bomba_peristaltica", "riego_inmersion"]


func marchitez() -> float:
	return maxf(clampf((75.0 - vida) / 75.0, 0.0, 1.0), _marchitez_muerte)


func tono(base: Color, w: float) -> Color:
	if w < 0.5:
		return base.lerp(MARCHITO, w * 2.0)
	return MARCHITO.lerp(SECO, (w - 0.5) * 2.0)


func _draw() -> void:
	var w := size.x
	var h := size.y
	var y_sustrato := h * 0.6
	var y_fondo_sustrato := h * 0.8
	var y_tanque := h * 0.85
	var caja := Rect2(w * 0.1, y_sustrato, w * 0.8, y_fondo_sustrato - y_sustrato)

	var fase_agua := clampf((intro - 0.12) / 0.45, 0.0, 1.0) if agua_llega() else 0.0
	var fase_led := clampf((intro - 0.62) / 0.2, 0.0, 1.0)
	var led_on := luz_activa and fase_led > 0.0
	if fase_led > 0.0 and fase_led < 1.0:
		led_on = luz_activa and fmod(_tiempo * 9.0, 1.0) > 0.35

	_dibujar_luz(w, h, y_sustrato, led_on)
	_dibujar_tanque(w, h, y_tanque)
	_dibujar_riego(w, h, caja, y_tanque, fase_agua)
	_dibujar_sustrato(caja, fase_agua)
	if intro > 0.8:
		var aparicion := clampf((intro - 0.8) / 0.2, 0.0, 1.0)
		_dibujar_planta(Vector2(w * 0.5, y_sustrato + 2.0), y_sustrato - h * 0.1, caja, aparicion)
	if intro < 1.0 and intro > 0.15 and not agua_llega():
		var f := get_theme_default_font()
		draw_string(f, Vector2(w * 0.12, y_tanque - 6.0), tr("El agua no llega a la planta"), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 0.45, 0.4))


func _dibujar_luz(w: float, h: float, y_sustrato: float, encendida: bool) -> void:
	if luz_natural:
		var c := Color(1, 0.95, 0.7) if encendida else Color(0.4, 0.4, 0.45)
		draw_circle(Vector2(w * 0.5, h * 0.03), w * 0.07, c)
		if encendida:
			draw_colored_polygon(PackedVector2Array([Vector2(w * 0.43, h * 0.05), Vector2(w * 0.57, h * 0.05), Vector2(w * 0.85, y_sustrato), Vector2(w * 0.15, y_sustrato)]), Color(1, 0.95, 0.7, 0.12))
		return
	var barra := Rect2(w * 0.08, 0.0, w * 0.84, h * 0.045)
	draw_rect(barra, Color(0.25, 0.27, 0.3))
	for i in 18:
		var x := barra.position.x + (i + 0.5) * barra.size.x / 18.0
		var col := (Color(1, 0.25, 0.3) if i % 3 != 2 else Color(0.35, 0.45, 1.0)) if encendida else Color(0.45, 0.45, 0.5)
		draw_circle(Vector2(x, barra.position.y + barra.size.y * 0.55), 2.6, col)
	if encendida:
		var p := PackedVector2Array([Vector2(w * 0.08, h * 0.045), Vector2(w * 0.92, h * 0.045), Vector2(w * 0.98, y_sustrato), Vector2(w * 0.02, y_sustrato)])
		var cs := PackedColorArray([Color(ROSA, 0.3), Color(ROSA, 0.3), Color(ROSA, 0.04), Color(ROSA, 0.04)])
		draw_polygon(p, cs)


func _dibujar_tanque(w: float, h: float, y: float) -> void:
	var r := Rect2(w * 0.08, y, w * 0.84, h * 0.14)
	draw_rect(r, Color(0.88, 0.9, 0.93, 1.0))
	var lleno := clampf(nivel_agua / 100.0, 0.0, 1.0) * clampf(intro / 0.12, 0.0, 1.0)
	var alto := r.size.y * 0.85 * lleno
	if alto > 0.5:
		var ola := sin(_tiempo * 2.0) * 1.5
		draw_rect(Rect2(r.position.x + 3, r.end.y - 3 - alto + ola * 0.3, r.size.x - 6, alto), AGUA)
	draw_rect(r, Color(0.55, 0.6, 0.65), false, 2.0)


func _dibujar_riego(w: float, h: float, caja: Rect2, y_tanque: float, fase: float) -> void:
	match riego:
		"mecha_absorbente":
			for i in 3:
				var x := caja.position.x + caja.size.x * (0.25 + 0.25 * i)
				var arriba := caja.end.y - 4.0
				var abajo := y_tanque + h * 0.11
				draw_rect(Rect2(x - 6, arriba, 12, abajo - arriba), MECHA)
				var mojado := (abajo - arriba) * fase if nivel_agua > 0.0 or intro < 1.0 else 0.0
				if mojado > 0.0:
					draw_rect(Rect2(x - 4, abajo - mojado, 8, mojado), Color(AGUA, 0.7))
		"bomba_peristaltica", "riego_inmersion":
			var bomba := Rect2(w * 0.82, y_tanque - h * 0.07, w * 0.12, h * 0.07)
			var tubo := PackedVector2Array([Vector2(w * 0.85, y_tanque + h * 0.08), Vector2(w * 0.85, bomba.end.y), Vector2(w * 0.88, bomba.position.y), Vector2(w * 0.88, caja.position.y + caja.size.y * 0.5), Vector2(caja.end.x - 8, caja.position.y + caja.size.y * 0.5)])
			draw_polyline(tubo, Color(0.75, 0.85, 0.95), 4.0)
			var activo := fase > 0.0 and fase < 1.0 or regando > 0.0
			if activo:
				for k in 6:
					var t := fmod(_tiempo * 1.5 + k / 6.0, 1.0)
					draw_circle(_punto_en(tubo, t), 2.5, AGUA)
			draw_rect(bomba, Color(0.55, 0.6, 0.68))
			draw_circle(bomba.get_center(), bomba.size.y * 0.3, Color(0.3, 0.33, 0.38))
		"electrovalvula":
			var x2 := w * 0.86
			draw_line(Vector2(x2, y_tanque + h * 0.08), Vector2(x2, caja.position.y + caja.size.y * 0.5), Color(0.75, 0.85, 0.95), 4.0)
			var c := Vector2(x2, y_tanque - h * 0.05)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-9, -8), c + Vector2(0, 0), c + Vector2(-9, 8)]), Color(0.5, 0.55, 0.6))
			draw_colored_polygon(PackedVector2Array([c + Vector2(9, -8), c + Vector2(9, 8), c + Vector2(0, 0)]), Color(0.5, 0.55, 0.6))
			draw_line(c + Vector2(-10, -10), c + Vector2(10, 10), Color(1, 0.3, 0.3), 3.0)
			draw_line(c + Vector2(10, -10), c + Vector2(-10, 10), Color(1, 0.3, 0.3), 3.0)


func _punto_en(linea: PackedVector2Array, t: float) -> Vector2:
	var total := 0.0
	for i in linea.size() - 1:
		total += linea[i].distance_to(linea[i + 1])
	var objetivo := total * t
	for i in linea.size() - 1:
		var d := linea[i].distance_to(linea[i + 1])
		if objetivo <= d:
			return linea[i].lerp(linea[i + 1], objetivo / d)
		objetivo -= d
	return linea[linea.size() - 1]


func _dibujar_sustrato(caja: Rect2, fase_agua: float) -> void:
	draw_rect(caja.grow(3.0), BOLSA)
	var humedo := clampf(humedad / 100.0, 0.0, 1.0) * fase_agua if intro < 1.0 else clampf(humedad / 100.0, 0.0, 1.0)
	var fondo := Color(0.55, 0.33, 0.17).darkened(0.35 * humedo)
	draw_rect(caja, fondo)
	for b in _bolitas:
		var p := caja.position + Vector2(b[0].x * caja.size.x, b[0].y * caja.size.y)
		var r: float = b[1] * caja.size.x
		var c := Color(0.78 + b[2], 0.45 + b[2], 0.22).darkened(0.3 * humedo)
		draw_circle(p, r, c)
		draw_circle(p - Vector2(r * 0.3, r * 0.3), r * 0.35, c.lightened(0.25))
	if progreso > 0.03 and intro > 0.8:
		var largo := caja.size.y * clampf(progreso * 1.6, 0.1, 0.95)
		var raiz := Color(0.95, 0.9, 0.78, 0.9)
		var origen := Vector2(caja.get_center().x, caja.position.y)
		for i in 7:
			var ang := deg_to_rad(90.0 + (i - 3) * 16.0)
			var fin := origen + Vector2.from_angle(ang) * largo * (0.6 + 0.4 * ((i * 37) % 10) / 10.0)
			var medio := origen.lerp(fin, 0.5) + Vector2(sin(i * 2.1) * 6.0, 0)
			draw_polyline(PackedVector2Array([origen, medio, fin]), raiz, 1.4)


func _dibujar_planta(base: Vector2, alto_max: float, caja: Rect2, aparicion: float) -> void:
	var g := smoothstep(0.0, 1.0, progreso) * aparicion
	var w := marchitez()
	_rng.seed = hash(especie)
	if progreso < 0.05:
		var t := progreso / 0.05 * aparicion
		draw_line(base, base + Vector2(0, -8.0 * t), tono(Color(0.5, 0.8, 0.4), w), 2.0)
		_hoja(base + Vector2(0, -8.0 * t), -150.0, 9.0 * t, 0.45, 0.0, "ovada", tono(Color(0.5, 0.82, 0.4), w), 0.0)
		_hoja(base + Vector2(0, -8.0 * t), -30.0, 9.0 * t, 0.45, 0.0, "ovada", tono(Color(0.5, 0.82, 0.4), w), 0.0)
		return
	var balanceo := sin(_tiempo * 1.3) * 2.5 * (1.0 - w)
	match especie:
		"lechuga_romana": _lechuga(base, alto_max, g, w, balanceo)
		"mizuna": _mizuna(base, alto_max, g, w, balanceo)
		"kale": _kale(base, alto_max, g, w, balanceo)
		"rabano": _rabano(base, alto_max, g, w, balanceo, caja)
		"chile": _chile(base, alto_max, g, w, balanceo)


func _lechuga(base: Vector2, alto: float, g: float, w: float, bal: float) -> void:
	var n := 4 + int(g * 12.0)
	var granate := tono(Color(0.48, 0.07, 0.18), w)
	for i in n:
		var k := float(n - 1 - i) / maxf(n - 1, 1)
		var lado := -1.0 if i % 2 == 0 else 1.0
		var ang := -90.0 + lado * (4.0 + 26.0 * k) + lado * w * 55.0 + bal
		var largo := alto * (0.3 + 0.7 * g) * (0.75 + 0.25 * (1.0 - k)) * _rng.randf_range(0.9, 1.05) * (1.0 - w * 0.25)
		_hoja(base, ang, largo, 0.3, lado * (0.1 + w * 0.9), "obovada", granate.darkened(0.1 * k), 0.03, tono(Color(0.55, 0.7, 0.35), w))


func _mizuna(base: Vector2, alto: float, g: float, w: float, bal: float) -> void:
	var n := 6 + int(g * 20.0)
	var verde := tono(Color(0.5, 0.82, 0.32), w)
	for i in n:
		var k := _rng.randf()
		var lado := -1.0 if i % 2 == 0 else 1.0
		var ang := -90.0 + lado * (5.0 + 70.0 * k) + lado * w * 40.0 + bal
		var largo := alto * (0.3 + 0.65 * g) * _rng.randf_range(0.75, 1.0) * (1.0 - w * 0.3)
		_hoja(base, ang, largo, 0.16, lado * (0.3 + w), "aserrada", verde.darkened(_rng.randf_range(0.0, 0.15)), 0.0, tono(Color(0.85, 0.9, 0.75), w))


func _kale(base: Vector2, alto: float, g: float, w: float, bal: float) -> void:
	var n := 3 + int(g * 8.0)
	var verde := tono(Color(0.3, 0.5, 0.45), w)
	var morado := tono(Color(0.52, 0.22, 0.48), w)
	for i in n:
		var k := float(n - 1 - i) / maxf(n - 1, 1)
		var lado := -1.0 if i % 2 == 0 else 1.0
		var ang := deg_to_rad(-90.0 + lado * (10.0 + 50.0 * k) + lado * w * 50.0 + bal)
		var largo := alto * (0.35 + 0.65 * g) * (0.8 + 0.2 * (1.0 - k)) * (1.0 - w * 0.25)
		var fin_peciolo := base + Vector2.from_angle(ang) * largo * 0.3
		draw_line(base, fin_peciolo, morado, 2.5)
		_hoja(fin_peciolo, rad_to_deg(ang), largo * 0.75, 0.55, lado * (0.2 + w * 0.8), "rizada", verde, 0.0, morado)


func _rabano(base: Vector2, alto: float, g: float, w: float, bal: float, caja: Rect2) -> void:
	var radio := caja.size.x * 0.11 * clampf((g - 0.25) / 0.75, 0.0, 1.0) * (1.0 - w * 0.3)
	if radio > 1.0:
		var rojo := tono(Color(0.85, 0.12, 0.28), w * 0.7)
		var centro := base + Vector2(0, radio * 0.35)
		draw_colored_polygon(PackedVector2Array([centro + Vector2(-radio * 0.3, radio * 0.7), centro + Vector2(radio * 0.3, radio * 0.7), centro + Vector2(0, radio * 1.9)]), Color(0.95, 0.92, 0.88))
		draw_circle(centro, radio, rojo)
		draw_circle(centro + Vector2(-radio * 0.35, -radio * 0.35), radio * 0.3, rojo.lightened(0.3))
	var n := 3 + int(g * 7.0)
	var verde := tono(Color(0.33, 0.62, 0.28), w)
	for i in n:
		var k := float(n - 1 - i) / maxf(n - 1, 1)
		var lado := -1.0 if i % 2 == 0 else 1.0
		var ang := -90.0 + lado * (12.0 + 50.0 * k) + lado * w * 50.0 + bal
		var largo := alto * (0.25 + 0.55 * g) * (0.8 + 0.2 * (1.0 - k)) * (1.0 - w * 0.25)
		_hoja(base, ang, largo, 0.38, lado * (0.2 + w), "lobulada", verde, 0.0, tono(Color(0.75, 0.3, 0.35), w))


func _chile(base: Vector2, alto: float, g: float, w: float, bal: float) -> void:
	var verde := tono(Color(0.18, 0.48, 0.2), w)
	var tallo := tono(Color(0.3, 0.5, 0.25), w)
	var altura := alto * (0.15 + 0.85 * g) * (1.0 - w * 0.2)
	var caida := w * 40.0
	var puntos := PackedVector2Array()
	for i in 11:
		var u := i / 10.0
		puntos.append(base + Vector2(bal * u + caida * u * u, -altura * u + caida * 0.3 * u * u))
	draw_polyline(puntos, tallo, 3.5)
	var ramas: Array = []
	for j in 3:
		var h_rama := 0.35 + 0.2 * j
		if g < h_rama - 0.15:
			continue
		var p0 := puntos[int(h_rama * 10)]
		for lado in [-1.0, 1.0]:
			var ang := deg_to_rad(-90.0 + lado * (40.0 + w * 50.0))
			var largo := altura * 0.35 * clampf((g - h_rama + 0.15) / 0.4, 0.2, 1.0)
			var p1 := p0 + Vector2.from_angle(ang) * largo
			draw_line(p0, p1, tallo, 2.2)
			ramas.append(p1)
			_hoja(p0.lerp(p1, 0.6), rad_to_deg(ang) + lado * 35.0, largo * 0.55, 0.36, lado * (0.2 + w), "lanceolada", verde, 0.0, verde.darkened(0.2))
	for i in range(2, 10, 2):
		var lado2 := -1.0 if (i / 2) % 2 == 0 else 1.0
		_hoja(puntos[i], -90.0 + lado2 * (60.0 + w * 50.0), altura * 0.22, 0.38, lado2 * (0.2 + w), "lanceolada", verde, 0.0, verde.darkened(0.2))
	_hoja(puntos[10], -90.0 + bal * 2.0, altura * 0.15, 0.4, 0.0, "lanceolada", verde, 0.0, verde.darkened(0.2))
	for idx in ramas.size():
		var p: Vector2 = ramas[idx]
		if g > 0.45 and g < 0.85:
			for pe in 5:
				draw_circle(p + Vector2.from_angle(pe * TAU / 5.0) * 3.0, 2.5, tono(Color(0.97, 0.97, 0.93), w))
			draw_circle(p, 1.5, Color(0.9, 0.8, 0.3))
		if g > 0.6:
			var maduro := clampf((g - 0.85) / 0.15, 0.0, 1.0)
			var color_fruto := tono(Color(0.2, 0.62, 0.18).lerp(Color(0.82, 0.1, 0.08), maduro), w * 0.6)
			var largo_fruto := altura * 0.22 * clampf((g - 0.6) / 0.25, 0.3, 1.0)
			var dir := Vector2(0.15 * (1 if idx % 2 == 0 else -1), 1.0).normalized()
			var perp := dir.orthogonal()
			var forma := PackedVector2Array()
			for s in 9:
				var u := s / 8.0
				forma.append(p + dir * largo_fruto * u + perp * largo_fruto * 0.16 * sin(PI * pow(u, 0.6)) * (1.0 - u * 0.5))
			for s in range(7, 0, -1):
				var u2 := s / 8.0
				forma.append(p + dir * largo_fruto * u2 - perp * largo_fruto * 0.16 * sin(PI * pow(u2, 0.6)) * (1.0 - u2 * 0.5))
			draw_colored_polygon(forma, color_fruto)
			draw_line(p - dir * 3.0, p + dir * 2.0, tallo, 2.0)


func _ancho_perfil(perfil: String, u: float) -> float:
	match perfil:
		"obovada":
			return pow(sin(PI * pow(u, 0.75)), 0.8) * (0.6 + 0.4 * u)
		"aserrada":
			return sin(PI * u) * (0.45 + 0.55 * absf(sin(u * 30.0)))
		"rizada":
			return sin(PI * pow(u, 0.85)) * (0.85 + 0.15 * sin(u * 45.0))
		"lobulada":
			return sin(PI * pow(u, 0.7)) * (0.6 + 0.4 * absf(sin(u * 14.0))) * (0.5 + 0.5 * u)
		"lanceolada":
			return sin(PI * pow(u, 0.55))
	return sin(PI * u)


func _hoja(origen: Vector2, angulo_deg: float, largo: float, ancho: float, curva: float, perfil: String, color: Color, ondas: float, color_base: Color = Color(0, 0, 0, 0)) -> void:
	if largo < 1.0:
		return
	var pasos := 16
	var centro := PackedVector2Array()
	var normales: Array[Vector2] = []
	var ang := deg_to_rad(angulo_deg)
	var p := origen
	var paso := largo / pasos
	for i in pasos + 1:
		centro.append(p)
		var dir := Vector2.from_angle(ang)
		normales.append(dir.orthogonal())
		p += dir * paso
		ang += curva * 0.06
	var izq := PackedVector2Array()
	var der := PackedVector2Array()
	for i in pasos + 1:
		var u := float(i) / pasos
		var a := _ancho_perfil(perfil, u) * largo * ancho * 0.5
		if ondas > 0.0:
			a *= 1.0 + ondas * sin(u * 22.0)
		izq.append(centro[i] + normales[i] * a)
		der.append(centro[i] - normales[i] * a)
	var poli := PackedVector2Array()
	poli.append_array(izq)
	for i in range(der.size() - 1, -1, -1):
		poli.append(der[i])
	if poli.size() >= 3:
		draw_colored_polygon(poli, color)
		var contorno := poli.duplicate()
		contorno.append(poli[0])
		draw_polyline(contorno, color.darkened(0.35), 1.0, true)
	if color_base.a > 0.0:
		var base_poli := PackedVector2Array()
		var corte := int(pasos * 0.3)
		for i in corte + 1:
			base_poli.append(centro[i] + normales[i] * _ancho_perfil(perfil, float(i) / pasos) * largo * ancho * 0.18)
		for i in range(corte, -1, -1):
			base_poli.append(centro[i] - normales[i] * _ancho_perfil(perfil, float(i) / pasos) * largo * ancho * 0.18)
		if base_poli.size() >= 3:
			draw_colored_polygon(base_poli, color_base)
		draw_polyline(centro.slice(0, int(pasos * 0.85)), color_base.lerp(color, 0.3), 1.2)
	else:
		draw_polyline(centro.slice(0, int(pasos * 0.85)), color.darkened(0.25), 1.0)
