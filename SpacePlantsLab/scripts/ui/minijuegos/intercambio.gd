extends "res://scripts/ui/minijuegos/minijuego_base.gd"

const N := 3
const MINIMO_EMPATE := 6

var tablero: Control
var piezas: Array = []
var orden: Array[int] = []
var seleccion: int = -1
var lado: float = 100.0
var cambios: int = 0
var lugar: Dictionary
var textura: Texture2D


func duracion() -> float:
	return 90.0


func _preparar() -> void:
	lugar = Idioma.traducir(elegir(DM.LUGARES_TEMPERATURA))
	subtitulo.text = tr("Rompecabezas de intercambio 3×3: Temperaturas extremas del Sistema Solar. Haz clic en dos piezas para cambiarlas de lugar.")
	textura = load(lugar["imagen"])
	info_imagen.texture = textura
	info.text = tr("[b]%s[/b]\n\n[color=#ff9f6b][b]Temperatura:[/b][/color] %s\n\n[color=#7fd4ff][b]Misión de la NASA:[/b][/color] %s\n\n[color=#7fd4ff][b]Dato:[/b][/color] %s\n\n[color=#7cf29a][b]¿Y las plantas?[/b][/color] %s") % [lugar["nombre"], lugar["temperatura"], lugar["mision"], lugar["dato"], lugar["planta"]]
	estado.text = tr("Gana: arma la imagen antes de que acabe el tiempo. Empate: %d piezas o más en su lugar.") % MINIMO_EMPATE
	lado = floorf(minf(area.size.x, area.size.y) / N) - 2.0
	tablero = Control.new()
	tablero.size = Vector2(lado * N, lado * N)
	tablero.position = (area.size - tablero.size) * 0.5
	area.add_child(tablero)
	orden.clear()
	for i in N * N:
		orden.append(i)
	while true:
		for i in range(orden.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var tmp := orden[i]
			orden[i] = orden[j]
			orden[j] = tmp
		if _correctas() <= 2:
			break
	piezas.clear()
	var t := float(textura.get_width()) / N
	for celda in N * N:
		var b := TextureButton.new()
		b.ignore_texture_size = true
		b.stretch_mode = TextureButton.STRETCH_SCALE
		b.size = Vector2(lado - 2, lado - 2)
		b.position = Vector2((celda % N) * lado + 1, (celda / N) * lado + 1)
		b.pressed.connect(_on_pieza.bind(celda))
		var numero := Label.new()
		numero.name = "Numero"
		numero.position = Vector2(4, 0)
		numero.add_theme_font_size_override("font_size", 13)
		b.add_child(numero)
		tablero.add_child(b)
		piezas.append(b)
	seleccion = -1
	cambios = 0
	_pintar()


func _pintar() -> void:
	var t := float(textura.get_width()) / N
	for celda in N * N:
		var trozo := orden[celda]
		var atlas := AtlasTexture.new()
		atlas.atlas = textura
		atlas.region = Rect2((trozo % N) * t, (trozo / N) * t, t, t)
		var b: TextureButton = piezas[celda]
		b.texture_normal = atlas
		b.get_node("Numero").text = str(trozo + 1)
		b.modulate = Color(1.3, 1.3, 0.8) if celda == seleccion else Color.WHITE


func _on_pieza(celda: int) -> void:
	if not jugando:
		return
	marcar_inicio()
	if seleccion == -1:
		seleccion = celda
	elif seleccion == celda:
		seleccion = -1
	else:
		var tmp := orden[seleccion]
		orden[seleccion] = orden[celda]
		orden[celda] = tmp
		seleccion = -1
		cambios += 1
		estado.text = tr("Cambios: %d · Piezas en su lugar: %d de %d") % [cambios, _correctas(), N * N]
		if _correctas() == N * N:
			_pintar()
			terminar("victoria", tr("Armaste la imagen de %s en %d cambios.") % [lugar["nombre"], cambios])
			return
	_pintar()


func _correctas() -> int:
	var c := 0
	for i in orden.size():
		if orden[i] == i:
			c += 1
	return c


func _tiempo_agotado() -> void:
	var c := _correctas()
	if c >= MINIMO_EMPATE:
		terminar("empate", tr("Se acabó el tiempo con %d piezas en su lugar.") % c)
	else:
		terminar("derrota", tr("Se acabó el tiempo con solo %d piezas en su lugar.") % c)
