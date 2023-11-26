func init() :
	V.gfx.set_spritesheet(await V.gfx.load_img("tutos/tuto02.png"))
	V.gfx.set_spritesheet_layout(Vector2i(75,70))

var t : float = 0.0

func update() :
	t += 0.25

func draw() :
	var sprite_num : float = fmod(t, 15.0)
	V.gfx.clear()
	V.gfx.blit_sprite(sprite_num as int,Vector2(155,42))
