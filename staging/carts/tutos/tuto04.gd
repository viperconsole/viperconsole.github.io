func init() :
    # oaks woods assets by Brullov
    for i in range(1,5) :
        # load each layer image
        await V.gfx.load_img("tuto4_%d.png" % i)
    for i in range(1,5) :
        var img_id = i-1 # img_id starts at 0
        # set it as current spritesheet
        V.gfx.set_spritesheet(img_id) 
        # resize the layer to fit the image. 
        # If the image is smaller than the screen, the layer will wrap around to fill the screen
        var img_size = V.gfx.get_image_size(img_id)
        V.gfx.set_layer_size_v(i,img_size)
        # blit the image on the layer
        V.gfx.set_active_layer(i)
        V.gfx.blit_region()

func update() :
    var t : float = V.elapsed()*0.05
    for i in range(1,5) :
        # scroll the layers, the closer it is, the fastest it scrolls
        V.gfx.set_layer_offset_v(i, Vector2.RIGHT * t * i)

