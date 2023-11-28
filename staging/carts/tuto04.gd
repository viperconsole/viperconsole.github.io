func init() :
    # oaks woods assets by Brullov
    for i in range(1,5) :
        # load each layer image
        var img_id=await V.gfx.load_img("tutos/tuto4_%d.png" % i)
        # set it as current spritesheet
        V.gfx.set_spritesheet(img_id) 
        # resize the layer to fit the image. The layer will wrap around to fill the screen
        var img_size = V.gfx.get_image_size(img_id)
        V.gfx.set_layer_size_v(i,img_size)
        # enable the layer
        V.gfx.show_layer(i)
        # blit the image on the layer
        V.gfx.set_active_layer(i)
        V.gfx.blit()

func update() :
    var t : float = V.elapsed()*0.05
    for i in range(1,5) :
        # scroll the layers, the closer it is, the fastest it scrolls
        V.gfx.set_layer_offset_v(i, Vector2.RIGHT * t * i)

