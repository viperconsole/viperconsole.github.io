var my_font
func init() :
	V.gfx.set_spritesheet(await V.gfx.load_img("tutos/tuto03.png"))
	V.gfx.set_spritesheet_layout(Vector2i(75,70))
	my_font=V.gfx.set_font(
		Vector2i(16, 16),
		Rect2i(0, 224, 320, 48),
		"ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,'!?-+()\":",
		Vector2i(1,0),
		PackedByteArray([16,16,16,16,16,16,16,16,7]))

var t : float = 0.0
func update() :
	t += 0.25

func draw() :
	var sprite = fmod(t, 15.0)
	V.gfx.clear()
	V.gfx.blit_sprite(sprite,Vector2(155,42))
	V.gfx.print(my_font, "HELLO, THIS IS AN OLD SCHOOL SCROLLER ! THANKS FOR WATCHING !...",
		Vector2(floor(100 - t * 3.5), 112))