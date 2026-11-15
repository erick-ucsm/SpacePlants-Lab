extends "res://scripts/ui/minijuegos/minijuego_base.gd"

const N := 3
const MEZCLA := 24
const MINIMO_EMPATE := 5

var tablero: Control
var fichas: Array = []
var posiciones: Array[int] = []
var vacio: int = N * N - 1
var lado: float = 100.0
var movimientos: int = 0
var nave: Dictionary


func duracion() -> float:
	return 120.0


func _preparar() -> void:
	nave = Idioma.traducir(elegir(DM.NAVES))
	subtitulo.text = tr("Rompecabezas deslizante 3×3: ordena la imagen de %s. Haz clic en una pieza junto al espacio vacío para moverla.") % nave["nombre"]
	var textura: Texture2D = load(nave["imagen"])
	info_imagen.texture = textura
	info.text = tr("[b]%s[/b]\n\n[color=#7fd4ff][b]Lanzamiento:[/b][/color] %s\n\n[color=#7fd4ff][b]Misión:[/b][/color] %s\n\n[color=#7fd4ff][b]Logro principal:[/b][/color] %s\n\n[color=#7fd4ff][b]Historia:[/b][/color] %s") % [nave["nombre"], nave["lanzamiento"], nave["mision"], nave["logro"], nave["historia"]]
	estado.text = tr("Gana: completa la imagen antes de que acabe el tiempo. Empate: %d piezas o más en su lugar.") % MINIMO_EMPATE

	lado = floorf(minf(area.size.x, area.size.y) / N) - 2.0
	tablero = Control.new()
	tablero.size = Vector2(lado * N, lado * N)
	tablero.position = (area.size - tablero.size) * 0.5
	area.add_child(tablero)
	var fondo := ColorRect.new()
	fondo.color = Color(0.05, 0.07, 0.12)
	fondo.size = tablero.size
	tablero.add_child(fondo)

	fichas.clear()
	posiciones.clear()
	var t := float(textura.get_width()) / N
	for i in N * N:
		posiciones.append(i)
		if i == N * N - 1:
			fichas.append(null)
			continue
		var atlas := AtlasTexture.new()
		atlas.atlas = textura
		atlas.region = Rect2((i % N) * t, (i / N) * t, t, t)
		var b := TextureButton.new()
		b.texture_normal = atlas
		b.ignore_texture_size = true
		b.stretch_mode = TextureButton.STRETCH_SCALE
		b.size = Vector2(lado - 2, lado - 2)
		b.pressed.connect(_on_ficha.bind(i))
		var numero := Label.new()
		numero.text = str(i + 1)
		numero.position = Vector2(4, 0)
		numero.add_theme_font_size_override("font_size", 13)
		b.add_child(numero)
		tablero.add_child(b)
		fichas.append(b)
	vacio = N * N - 1
	_mezclar()
	movimientos = 0
	_colocar(false)


func _mezclar() -> void:
	var anterior := -1
	for k in MEZCLA:
		var vecinos := _vecinos(vacio)
		vecinos.erase(anterior)
		var celda: int = elegir(vecinos)
		var pieza := posiciones.find(celda)
		posiciones[pieza] = vacio
		anterior = vacio
		vacio = celda
	if _correctas() == N * N - 1:
		_mezclar()


func _vecinos(celda: int) -> Array:
	var r: Array = []
	var x := celda % N
	var y := celda / N
	if x > 0: r.append(celda - 1)
	if x < N - 1: r.append(celda + 1)
	if y > 0: r.append(celda - N)
	if y < N - 1: r.append(celda + N)
	return r


func _colocar(animar: bool) -> void:
	for i in N * N - 1:
		var b: TextureButton = fichas[i]
		var destino := Vector2((posiciones[i] % N) * lado + 1, (posiciones[i] / N) * lado + 1)
		if animar:
			create_tween().tween_property(b, "position", destino, 0.08)
		else:
			b.position = destino


func _on_ficha(i: int) -> void:
	if not jugando:
		return
	var celda := posiciones[i]
	if not _vecinos(celda).has(vacio):
		return
	marcar_inicio()
	posiciones[i] = vacio
	vacio = celda
	movimientos += 1
	_colocar(true)
	estado.text = tr("Movimientos: %d · Piezas en su lugar: %d de %d") % [movimientos, _correctas(), N * N - 1]
	if _correctas() == N * N - 1:
		terminar("victoria", tr("Armaste %s en %d movimientos.") % [nave["nombre"], movimientos])


func _correctas() -> int:
	var c := 0
	for i in N * N - 1:
		if posiciones[i] == i:
			c += 1
	return c


func _tiempo_agotado() -> void:
	var c := _correctas()
	if c >= MINIMO_EMPATE:
		terminar("empate", tr("Se acabó el tiempo con %d piezas en su lugar.") % c)
	else:
		terminar("derrota", tr("Se acabó el tiempo con solo %d piezas en su lugar.") % c)
