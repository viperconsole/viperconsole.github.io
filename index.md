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

Viper uses [rhai](https://github.com/jonathandturner/rhai).
Three interfaces are exposed by the viper console :

* `gfx` : the graphics API
* `snd` : the sound API
* `inp` : the input API

Following rhai functions are called by the console :

* `fn init()` : called once during the cartridge boot.
    * this is where images should be loaded with `gfx_load_img`
* `fn update()` : called 60 times per second
    * this is where you should update your variables
* `fn render()` : called every frame
    * render what can change every frame. Framerate is supposed to be 60fps but it could be lower depending on what your program is doing and the target system specs. Time dependant variables should be modified in the update function, not the render function.

## <a name="h2"></a>2. Graphics API (gfx)

### <a name="h2.1"></a>2.1. Architecture

The viper screen size is 384x224 pixels. Top left coordinate is 0,0. bottom right coordinate is 383,223.

The graphics engine stores twelve pixel buffers. By default, all layers have a size of 384x224 and only layer 0 is displayed. Layers 1 to 11 can be used to store spritesheets. But you can decide to display other layers on screen using `gfx_show_layer`.

* Layer 0 is the background layer.
* Layer 1 is on top of layer 0.
* Layer 2 is on top of layer 1, etc...
* Black color (0,0,0) is transparent on layers 1 to 11.

You can also change the size of a layer with `gfx_set_layer_size`. If this layer is displayed on screen, you can set the coordinate of the top-left screen pixel in that layer using `gfx_set_layer_offset`.

Each layer applies a color operation between its color and the underlying color. You can change the color operation of a layer with `gfx_set_layer_operation` :

* `GFX_LAYEROP_SET` : new pixel color = layer pixel color (default)
* `GFX_LAYEROP_ADD` : new pixel color = current pixel color + layer pixel color
* `GFX_LAYEROP_AVERAGE` : new pixel color = (current pixel color + layer pixel color)/2
* `GFX_LAYEROP_SUBTRACT` : new pixel color = current pixel color - layer pixel color
* `GFX_LAYEROP_MULTIPLY` : new pixel color = current pixel color * layer pixel color

Example :

`gfx_set_layer_operation(1, GFX_LAYEROP_ADD);`

When you're using rendering functions (gfx_rectangle, gfx_blit, ...), you're drawing on the active layer.
You can set current active layer with `gfx_set_active_layer`, even if it's not shown on screen.

### <a name="h2.2"></a>2.2. Drawing API

Most drawing functions take a (r,g,b) color as last parameter. Each component value should be between 0.0 and 1.0.

* `activatePixelBuffer(buffer)`
    * set current drawing pixel buffer.
    * buffer values : `LAYER[0]`, ..., `LAYER[7]`, `SPRITESHEET[0]`, `SPRITESHEET[1]`

* `loadImg(source, [buffer])`
    * load an image in a buffer (default: current pixel buffer)
    * this is supposed to work with 512x256 images
    * buffer values : `LAYER[0]`, ..., `LAYER[7]`, `SPRITESHEET[0]`, `SPRITESHEET[1]`

    source is an URL :

    * local file : `'myimage.png'`
    * remote file : `'http://someserver.com/myimage.png'`
    * data URL : `'data:image/png; ...'`

    To convert an image into data url, simply drag and drop it on the console screen.

* `layerOffset(x,y, [buffer])`
    * set a layer scrolling offset (default : current pixel buffer. use buffer==-1 to scroll all layers).
    * buffer values : `LAYER[0]`, ..., `LAYER[7]`

* `layerOperation(layerOp, [buffer])`
    * set layer operation.
    * layerOp values : `SET`/`ADD`/`AVERAGE`/`SUBTRACT`/`MULTIPLY`.
    * buffer values : `LAYER[0]`, ..., `LAYER[7]`

* `color(r,g,b)`
    * set current drawing color.
    * `r,g,b` range: 0-255

* `clear([r,g,b])`
    * fill current layer with color `r,g,b`
    * default : current drawing color

* `pixel(x,y, [r,g,b])`
    * set color of pixel `x,y`
    * default: current drawing color

* `line(x1,y1, x2,y2, [r,g,b])`
    * draw a line

* `triangle(x1,y1, x2,y2, x3,y3, [r,g,b])`
    * fill a triangle

* `rectangle(x,y, w,h, [r,g,b])`
    * fill a rectangle

### <a name="h2.3"></a>2.3. Font drawing API
* `activateFont(buffer, x,y, width,height, charWidth,charHeight, [charset])`
    * define a region of a pixel buffer as a bitmap font to use
    * charset is a string representing the characters in the bitmap font.
    * if charset is not set, the ascii table is expected.
    * `gfx.SPRITESHEET[1]` is preloaded with a default font on region 0,0,512,32 that contains the ascii table as 8x8 characters

* `cursor(x,y)`
    * set current text drawing position in pixels

* `print(str, [x,y, [r,g,b] ])`
    * print string txt at position `x,y`
    * default: cursor pos

### <a name="h2.4"></a>2.4. Sprite API

You select a spritesheet with activateSpritesheet (default is `SPRITESHEET[0]`). `sprite()`/`blitSprite()` uses it as a source. The destination is the current active layer.
Source and destination cannot be the same pixel buffer.
Sprite size is 8x8. Each 512x256 spritesheet can contain 64x32 8x8 sprites.

* `activateSpritesheet(buffer: PixelBufferId)`
    * define the current source for sprite blitting operations

* `sprite(num, x,y, [w=1,h=1, [flags] ])`
    * draw sprite `num` (0 = top left in the spritesheet) at position `x,y` on current pixel buffer.
    * If `w,h` is defined, draw a wxh sprite zone
    * `flags` :
        * `gfx.FLIP_H` : flip horizontally
        * `gfx.FLIP_V` : flip vertically
        * can be combined : `gfx.FLIP_H + gfx.FLIP_V`

* `blitSprite(sx,sy, sw,sh, dx,dy, [dw,dh, [flags]])`
    * blit a rectangular zone from current spritesheet to the active pixel buffer
    * `sx,sy` : top left pixel position in the spritesheet
    * `sw,sh` : rectangular zone size in the spritesheet in pixels
    * `dx,dy` : destination on active pixel buffer
    * `dw,dh` : destination size in pixel (default = sw,sh). The sprite will be stretched to fill dw,dh
    * `flags` : same as sprite()

### <a name="h2.5"></a>2.5. Tile map
***in beta***

## <a name="h3"></a>3. Sound API (snd)

### <a name="h3.1"></a>3.1. Instrument API
***in beta***

Instrument properties:

* oscillator parameters
    * `overtone` : amount of overtone
    * `overtoneRatio` : 0 = octave below, 1 = fifth above
    * `sawGain` : amount of sawtooth waveform (0-1)
    * `squareGain` : amount of square waveform (0-1)
    * `pulseWidth` : width of the square pulse : 0 = half period, 1 = 90% period
    * `triangleGain` : amount of triangle waveform (0-1)
    * `noiseGain` : amount of noise (0-1) ***not implemented***
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
* `keyPressed(key)` : return true if key was pressed during last frame
* `keyReleased(key)` : return true if key was released during last frame

### <a name="h4.2"></a>4.2. Mouse API

List of button values :

* 0: Main button pressed, usually the left button or the un-initialized state
* 1: Auxiliary button pressed, usually the wheel button or the middle button (if present)
* 2: Secondary button pressed, usually the right button
* 3: Fourth button, typically the Browser Back button
* 4: Fifth button, typically the Browser Forward button

Functions :

* `mouseButton(num)` : return true if mouse button num is pressed.
* `mouseButtonPressed(num)` : return true if mouse button num was pressed during last frame
* `mouseButtonReleased(num)` : return true if mouse button num was released during last frame
* `mousePos()`: return an object with x,y fields containing the mouse position

### <a name="h4.3"></a>4.3. Gamepad API
***in beta***

Available button types :

* `BTN_A`
* `BTN_B`
* `BTN_C` (X on XBOX gamepad)
* `BTN_D` (Y on XBOX gamepad)

Available axis types :

* `AXIS_UP_DOWN` (-1 is UP)
* `AXIS_LEFT_RIGHT` (-1 is LEFT)

Functions :

* `button(type, [playerNum])` : return true if button type is pressed for player playerNum
* `axis(type, [playerNum])` : return the axis value (between -1 and 1) for player playerNum

Example :

```
inp:button(inp.BTN_A,1) -- return player 1 status for button A
```
