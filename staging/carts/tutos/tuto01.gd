func draw() :
	V.gfx.clear()
	var x : float = 50 * sin(V.elapsed())
	V.gfx.rectangle(Rect2(140+x, 80, 50, 40), Color8(255, 128, 0))
	V.gfx.line(Vector2(140, 121), Vector2(240, 121), Color.WHITE)
	V.gfx.triangle(Vector2(200 + x, 120), Vector2(220 + x, 80), Vector2(240 + x, 120), Color8(128, 0, 255))
