
func init():
	# background from 1996 Air Gallet
	# and ship sprite by buko-studios.deviantart.com
	V.gfx.set_spritesheet(await V.gfx.load_img("tuto06.png"))
	V.gfx.blit() # blit background on layer 1
	# layer 2 is our shadow layer
	# draw every pixel in dark gray instead of the original sprite color
	V.gfx.set_layer_blit_col(2,Color.DARK_GRAY)
	# this layer multiply its color with the layer below
	V.gfx.set_layer_operation(2, V.gfx.LAYEROP_MULTIPLY)

# ship sprite position and size in the spritesheet
const SPRITE_POS = Vector2(0,224)
const SPRITE_SIZE = Vector2(32,32)
# ship position
var pos : Vector2
# shadow offset from the ship position
var shadow_offset : Vector2
# wether we display the shadow this frame
var shadow_flipflop = true

func update() :
	# give the ship some movement
	pos.x = 162 + 120 * cos( V.elapsed())
	pos.y = 112 + 90 * sin( 2 * V.elapsed())
	# offset the shadow the further the ship is from screen center
	shadow_offset = (pos - Vector2(162,112))/15
	# make the shadow blink for added vintage effect
	shadow_flipflop =not shadow_flipflop
	if shadow_flipflop :
		V.gfx.show_layer(2)
	else:
		V.gfx.hide_layer(2)

func draw() :
	# draw the shadow (the draw order is not important as layer 2 is always behind layer 3)
	V.gfx.set_active_layer(2)
	V.gfx.clear()
	# draw the shadow sprite
	V.gfx.blit(pos + shadow_offset, SPRITE_POS, SPRITE_SIZE)
	# draw the ship
	V.gfx.set_active_layer(3)
	V.gfx.clear() # clear the layer with transparent color
	V.gfx.blit(pos, SPRITE_POS, SPRITE_SIZE)
