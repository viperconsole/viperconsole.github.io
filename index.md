# VIPER developer manual
## Summary

* [1. Language](#h1)
* [2. Graphics API (gfx)](#h2)
    * [2.1. Architecture](#h2.1)
    * [2.2. Drawing API](#h2.2)
    * [2.3. Font drawing API](#h2.3)
    * [2.4. Sprite API](#h2.4)
    * [2.5. Tile map](#h2.5)
* [3. Sound API (snd)](#h3)
    * [3.1. Instrument API](#h3.1)
    * [3.2. Pattern API](#h3.2)
    * [3.3. Song API](#h3.3)
    * [3.4. Midi API](#h3.4)
* [4. Input API (inp)](#h4)
    * [4.1. Keyboard API](#h4.1)
    * [4.2. Mouse API](#h4.2)
    * [4.3. Gamepad API](#h4.3)

## <a name="h1"></a>1. Language

Viper uses its own scripting language.

The following functions are called by the console :

* `fn init()` : called once during the cartridge boot.
    * this is where images should be loaded with `gfx.load_img`
* `fn update()` : called 60 times per second
    * this is where you should update your variables
* `fn render()` : called every frame
    * render what can change every frame

Three interfaces are exposed by the viper console :

* `gfx` : the graphics API
* `snd` : the sound API
* `inp` : the input API

Each API might expose values and methods.

## <a name="h2"></a>2. Graphics API (gfx)

### <a name="h2.1"></a>2.1. Architecture

The viper screen size is 384x224 pixels. You can get those values with `gfx.SCREEN_WIDTH` and `gfx.SCREEN_HEIGHT`. The graphics engine can display on screen any number of transparent layers. Viper doesn't use alpha blending, but a transparent key color that can be changed with `gfx.set_transparent_color(r,g,b)` (default is pure black).

Each layer can be resized with `gfx.set_layer_size(id, w, h)` and moved with `gfx.set_layer_offset(id,x,y)`.
You can hide and show layers with `gfx.show_layer(id)` and `gfx.hide_layer(id)`. By default, only one layer (layer 0) is displayed.

The console renders the layers in increasing id order (first layer 0, then 1 on top of it and so on).

Layers can be used to overlay graphics on screen or store bitmap fonts/sprite sheets offscreen. You can copy an image from a layer to another with `gfx.set_sprite_layer(id)`, `gfx.set_active_layer(id)` and `gfx.blit(sx,sy,sw,sh, dx,dy,dw,dh, hflip, vflip, r,g,b)`. You can load an image in the current active layer with `gfx.load_img(resource_name, filepath)`.

Each visible layer applies a color operation between its color and the underlying color :

* `gfx.LAYEROP_SET` : new pixel color = layer pixel color (default)
* `gfx.LAYEROP_ADD` : new pixel color = current pixel color + layer pixel color
* `gfx.LAYEROP_AVERAGE` : new pixel color = (current pixel color + layer pixel color)/2
* `gfx.LAYEROP_SUBTRACT` : new pixel color = current pixel color - layer pixel color
* `gfx.LAYEROP_MULTIPLY` : new pixel color = current pixel color * layer pixel color

Example :

`gfx.set_layer_operation(1, gfx.LAYEROP_ADD)`

You can draw on any layer by activating it with `gfx.set_active_layer(id)`.

### <a name="h2.2"></a>2.2. Drawing API

* `set_active_layer(id)`
    * set current drawing layer.
    * id is an arbitrary integer value. Visible layers are rendered in ascending id order.

* `load_img(resource_name, filepath)`
    * load an image in the current active layer

    filepath is an URL :

    * local file : `'myimage.png'`
    * remote file : `'http://someserver.com/myimage.png'`
    * data URL : `'data:image/png; ...'`

    TODO To convert an image into data url, simply drag and drop it on the console screen.

    TODO If resource_name is not an empty string `""`, this image can be overriden by the player by running the console with res parameters. This makes it easy for users to mod the game graphics.

* `set_layer_offset(id, x, y)`
    * set a layer scrolling offset.
    TODO use id -1 to scroll all visible layers (screen shake effect)

* `set_layer_operation(id, layer_op)`
    * set the layer color operation.
    * layer_op values : `gfx.SET`/`gfx.ADD`/`gfx.AVERAGE`/`gfx.SUBTRACT`/`gfx.MULTIPLY`.

* `clear(r,g,b)`
    * fill the active layer with the color `r,g,b`

TODO
* `pixel(x,y, r,g,b)`
    * set color of pixel `x,y`

* `line(x1,y1, x2,y2, r,g,b)`
    * draw a line

* `triangle(x1,y1, x2,y2, x3,y3, r,g,b)`
    * fill a triangle

* `rectangle(x,y, w,h, r,g,b)`
    * fill a rectangle

* `circle(x,y, radius, r,g,b)`
    * draw a circle

* `disk(x,y, radius, r,g,b)`
    * fill a disk

### <a name="h2.3"></a>2.3. Font drawing API
* `activate_font(id, x,y, width,height, char_width,char_height, charset)`
    * define a region of a layer as a bitmap font to use with `gfx.gfx_print`
    * charset is a string representing the characters in the bitmap font.
    * if charset is not set, the ascii table is expected.
    * The console is preloaded with a default font that contains the ascii table as 8x8 characters. You can reset to the default font with  `gfx.activate_font(gfx.SYSTEM_LAYER, 0,0,512,32, 8,8, "")`

* `gfx_print(text, x,y, r,g,b)`
    * print the text at position `x,y`

### <a name="h2.4"></a>2.4. Sprite API

You select a spritesheet with `set_sprite_layer` (default is `gfx.SYSTEM_LAYER`). `gfx.blit` uses it as a source. The destination is the current active layer.
Source and destination cannot be the same layer.

* `set_sprite_layer(id)`
    * define the current source for sprite blitting operations

* `blit(sx,sy,sw,sh, dx,dy,dw,dh, hflip,vflip, r,g,b)`
    * blit a rectangular zone from the current sprite layer to the active layer
    * `sx,sy` : top left pixel position in the spritesheet
    * `sw,sh` : rectangular zone size in the spritesheet in pixels
    * `dx,dy` : destination on active pixel buffer
    * `dw,dh` : destination size in pixel (if 0,0, uses the source size). The sprite will be stretched to fill dw,dh
    * `hflip, vflip` : whether to flip the sprite horizontally or vertically
    * `r,g,b` : multiply the sprite colors with this color

### <a name="h2.5"></a>2.5. Tile map
TODO

## <a name="h3"></a>3. Sound API (snd)
***in beta***

### <a name="h3.1"></a>3.1. Instrument API
***in beta***

Instrument properties:

* oscillator parameters
    * `overtone` : amount of overtone
    * `overtoneRatio` : 0 = octave below, 1 = fifth above
    * `sawGain` : amount of sawtooth waveform (0.0-1.0)
    * `ultrasaw` : amount of ultrasaw in the saw waveform (0.0-1.0)
    * `squareGain` : amount of square waveform (0.0-1.0)
    * `pulseWidth` : width of the square pulse : 0 = half period, 1 = 90% period
    * `triangleGain` : amount of triangle waveform (0.0-1.0)
    * `metalizer` : amount of metalizer in the triangle waveform (0.0-1.0)
    * `noiseGain` : amount of noise (0.0-1.0)
* filter parameters
    * `filterType` : type of filter (`LOWPASS`, `BANDPASS`, `HIGHPASS`)
    * `distoLevel` : amount of distortion (0-200)
    * `filterGain`: lowshelf filter boost in Db (-40, 40)
    * `filterCutOffFreq`: upper limit of frequencies getting a boost (0-8000)
* lfo parameters
    * `lfoAmount` : amplitude of the lfo waveform (0-1)
    * `lfoRate` : frequency of the lfo waveform (0-8000)
    * `lfoShape`: type of waveform (`SAWTOOTH`, `SQUARE`, `TRIANGLE`)
        * Example :
        * `myInstrument.lfoShape = snd.SQUARE`
    * `lfoPitch` : whether the lfo affects the notes pitch (0 or 1)
    * `lfoFilter`: whether the lfo affects the filter cutoff (0 or 1)
    * `lfoPulse`: whether the lfo affects the pulse width (0 or 1)
    * `lfoMetalizer`: whether the lfo affects the metalizer amount (0 or 1)
    * `lfoOvertone`: whether the lfo affects the overtone amount (0 or 1)
    * `lfoUltrasaw`: whether the lfo affects the ultrasaw amount (0 or 1)
* general parameters
    * `pitch` : frequency of the note (0-8000)
    * `masterGain` : general volume (0-1)
    * `panning` : left/right speaker balance (-1 to 1)
* methods
    * `start([when])` : start playing the note in `when` seconds (default : now)
    * `stop([when])` : stop playing the note in `when` seconds (default : now)

* `newInstrument()` : return a new instrument


### <a name="h3.2"></a>3.2. Pattern API
***to be implemented***

### <a name="h3.3"></a>3.3. Song API
***to be implemented***

### <a name="h3.4"></a>3.4. Midi API
***in beta***

* `midiDevices()` : returns an array of device names. Mainly used to check if there's a midi device connected
* `midiNote(note, channel)` : return velocity (0-127) of midi `note` (note between 21 (A0) and 108 (C8)).
    * `channel` : midi channel (0-15). Use 16 to catch events for all channels.
    * Return -1 when the key is released, 0 else.
    * Example :
    * frame 1 : midiNote(0) == 127    : note 0 was pressed this frame with full velocity
    * frame 2 : midiNote(0) == 0      : note is still pressed
    * frame 3 : midiNote(0) == 0      : note is still pressed
    * frame 4 : midiNote(0) == -1     : note was released this frame
    * frame 5 : midiNote(0) == 0      : note is still released

* `pitchWheel(num, channel)` : return the value of pitch wheel `num` for `channel`

## <a name="h4"></a>4. Input API (inp)

### <a name="h4.1"></a>4.1. Keyboard API

List of key values [here](https://developer.mozilla.org/fr/docs/Web/API/KeyboardEvent/key/Key_Values)

* `key(key)` : return true if key is pressed.
* `key_pressed(key)` : return true if key was pressed during last frame
* `key_released(key)` : return true if key was released during last frame

### <a name="h4.2"></a>4.2. Mouse API

List of button values :

* 0: Main button pressed, usually the left button or the un-initialized state
* 1: Auxiliary button pressed, usually the wheel button or the middle button (if present)
* 2: Secondary button pressed, usually the right button
* 3: Fourth button, typically the Browser Back button
* 4: Fifth button, typically the Browser Forward button

Functions :

* `mouse_button(num)` : return true if mouse button num is pressed.
* `mouse_button_pressed(num)` : return true if mouse button num was pressed during last frame
* `mouse_button_released(num)` : return true if mouse button num was released during last frame
* `mouse_x()`: return the mouse horizontal position in pixels
* `mouse_y()`: return the mouse vertical position in pixels

### <a name="h4.3"></a>4.3. Gamepad API
***in beta***

Functions :

* `pad_button(player_num, num)` : return true if button num for player player_num is pressed
* `pad_button_pressed(player_num, num)` : return true if button num for player player_num was pressed during last frame
* `pad_axis_x(player_num)` : return the left analog stick horizontal axis value (between -1 and 1) for player player_num
* `pad_axis_y(player_num)` : return the left analog stick vertical axis value (between -1 and 1) for player player_num
* `set_neutral_zone(value)` : sets the analog stick neutral zone (between 0 and 1)

