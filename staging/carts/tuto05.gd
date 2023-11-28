func init():
	# load an image and blit it on default layer
	var img = await V.gfx.load_img("tutos/tuto05.png")
	V.gfx.set_spritesheet(img) # background from high seas havoc
	# the image is bigger than the screen so resize the layer so it fits
	V.gfx.set_layer_size_v(1, V.gfx.get_image_size(img))
	V.gfx.blit()

var t : float = 0

func update():
	t = t + 0.25
	# scroll the big clouds faster (rows 0 to 60)
	V.gfx.set_rowscroll(0,60,t*2)
	# scroll the medium clouds a bit slower (rows 61 to 95)
	V.gfx.set_rowscroll(61,95,t*1.5)
	# scroll the bottow of the sky and the land even slower (rows 96 to 155)
	V.gfx.set_rowscroll(96,155,t)
	# scroll the sea gradually from t to 10*t (rows 156 to 223)
	V.gfx.set_rowscroll(156,223,t, t*10)
