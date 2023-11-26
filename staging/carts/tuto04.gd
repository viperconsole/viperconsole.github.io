func init() :
    for i in range(1,5) :
        var img_id=await V.gfx.load_img("tutos/tuto4_%d.png" % i)
        V.gfx.set_spritesheet(img_id) # oaks woods assets by Brullov
        var img_size = V.gfx.get_image_size(img_id)
        V.gfx.set_layer_size_v(i-1,img_size)
        V.gfx.show_layer(i-1)

func update() :
    var t : float = V.elapsed()*0.05
    for i in range(0,4) :
        V.gfx.set_layer_offset_v(i, Vector2.RIGHT * t * (i+1))

func draw() :
    for i in range(0,4) :
        V.gfx.set_active_layer(i)
        V.gfx.clear()
        V.gfx.set_spritesheet(i)
        V.gfx.blit()
