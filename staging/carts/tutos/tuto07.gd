# we use an image 50% smaller than screen because computing it is CPU intensive
const IMG_WIDTH=192
const IMG_HEIGHT=112
var pix_data: PackedByteArray = PackedByteArray()

func init():
	# fill the image with black
	for i in range(0,IMG_WIDTH*IMG_HEIGHT) :
		pix_data.append(0)
		pix_data.append(0)
		pix_data.append(0)
	
func update():
	# fill the image with some varying colors
	var t=cos(V.elapsed()*0.1)
	var off=0
	for i in range(0,IMG_WIDTH*IMG_HEIGHT) :
		var x= i % IMG_WIDTH
		var y = i/IMG_WIDTH
        # don't use "as int", it's very slow
		pix_data[off] = 255*cos(t*x*0.1) 
		pix_data[off+1] = 255*sin(t*y*0.1) 
		pix_data[off+2] = 255*cos(2*t*x*y)
		off+=3

func draw():
	V.gfx.clear()
	# blit the image, scaling it to fill the whole screen
	V.gfx.blit_pixels(Vector2(0,0),IMG_WIDTH,pix_data, Vector2(V.gfx.SCREEN_WIDTH, V.gfx.SCREEN_HEIGHT))
