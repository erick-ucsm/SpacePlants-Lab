extends "res://scripts/ui/minijuegos/minijuego_base.gd"

const CartaMemoria = preload("res://scripts/ui/minijuegos/carta_memoria.gd")
const COLUMNAS := 4
const FILAS := 3
const MINIMO_EMPATE := 4
const PAREJAS := 6

var generacion: Dictionary
var cartas: Array = []
var elegidas: Array = []
var parejas: int = 0
var intentos: int = 0
var bloqueado: bool = false
var descubiertas: Array[String] = []


func duracion() -> float:
	return 90.0


func _preparar() -> void:
	generacion = Idioma.traducir(elegir(DM.GENERACIONES))
	subtitulo.text = tr("Memoria: encuentra las %d parejas de personajes de la generación \"%s\".") % [PAREJAS, generacion["nombre"]]
	info_imagen.visible = false
	descubiertas.clear()
	_mostrar_info()
	estado.text = tr("Gana: encuentra las %d parejas antes de que acabe el tiempo. Empate: %d parejas o más.") % [PAREJAS, MINIMO_EMPATE]
	parejas = 0
	intentos = 0
	elegidas.clear()
	bloqueado = false

	var elegidos: Array = generacion["personas"].duplicate()
	elegidos.shuffle()
	elegidos = elegidos.slice(0, PAREJAS)
	var mazo: Array = []
	for p in elegidos:
		mazo.append(p)
		mazo.append(p)
	for i in range(mazo.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = mazo[i]
		mazo[i] = mazo[j]
		mazo[j] = tmp

	var sep := 8.0
	var ancho := floorf((area.size.x - sep * (COLUMNAS - 1)) / COLUMNAS)
	var alto := floorf((area.size.y - sep * (FILAS - 1)) / FILAS)
	ancho = minf(ancho, alto * 0.8)
	var total := Vector2(ancho * COLUMNAS + sep * (COLUMNAS - 1), alto * FILAS + sep * (FILAS - 1))
	var origen := (area.size - total) * 0.5
	cartas.clear()
	for i in mazo.size():
		var c: Control = CartaMemoria.new()
		c.persona = mazo[i]
		c.color_generacion = generacion["color"]
		c.position = origen + Vector2((i % COLUMNAS) * (ancho + sep), (i / COLUMNAS) * (alto + sep))
		c.size = Vector2(ancho, alto)
		c.elegida.connect(_on_carta)
		area.add_child(c)
		cartas.append(c)


func _mostrar_info() -> void:
	var t := "[b]%s[/b]\n[i]%s[/i]\n\n" % [generacion["nombre"], generacion["descripcion"]]
	if descubiertas.is_empty():
		t += tr("Cada vez que encuentres una pareja aparecerá aquí quién es, qué hizo y por qué la NASA lo reconoce.")
	for id in descubiertas:
		for p in generacion["personas"]:
			if p["id"] == id:
				t += "[color=#7cf29a][b]%s[/b][/color]\n%s\n[color=#9fb3c8]%s[/color]\n\n" % [p["nombre"], p["logro"], p["por_que"]]
	info.text = t
	info.scroll_to_line(info.get_line_count())


func _on_carta(carta) -> void:
	if not jugando or bloqueado or elegidas.has(carta):
		return
	marcar_inicio()
	carta.voltear(true)
	elegidas.append(carta)
	if elegidas.size() < 2:
		return
	intentos += 1
	var a = elegidas[0]
	var b = elegidas[1]
	if a.persona["id"] == b.persona["id"]:
		a.encontrada = true
		b.encontrada = true
		parejas += 1
		descubiertas.append(a.persona["id"])
		_mostrar_info()
		elegidas.clear()
		estado.text = tr("Parejas: %d de %d · Intentos: %d") % [parejas, PAREJAS, intentos]
		if parejas == PAREJAS:
			terminar("victoria", tr("Encontraste las %d parejas en %d intentos.") % [PAREJAS, intentos])
	else:
		bloqueado = true
		estado.text = tr("Parejas: %d de %d · Intentos: %d") % [parejas, PAREJAS, intentos]
		await get_tree().create_timer(0.8).timeout
		a.voltear(false)
		b.voltear(false)
		elegidas.clear()
		bloqueado = false


func _tiempo_agotado() -> void:
	if parejas >= MINIMO_EMPATE:
		terminar("empate", tr("Se acabó el tiempo con %d parejas.") % parejas)
	else:
		terminar("derrota", tr("Se acabó el tiempo con solo %d parejas.") % parejas)
