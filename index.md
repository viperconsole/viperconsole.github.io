# VIPER developer manual
## Summary

* [1. Language](#h1)
* [2. Graphics API (gfx)](#h2)
    * [2.1. Architecture](#h2.1)
    * [2.2. Drawing API](#h2.2)
    * [2.3. Font API](#h2.3)
    * [2.4. Sprite API](#h2.4)
    * [2.5. Spritesheets](#h2.5)
* [3. Sound API (snd)](#h3)
    * [3.1. Instrument API](#h3.1)
    * [3.2. Pattern API](#h3.2)
    * [3.3. Song API](#h3.3)
    * [3.4. Midi API](#h3.4)
* [4. Input API (inp)](#h4)
    * [4.1. Keyboard API](#h4.1)
    * [4.2. Mouse API](#h4.2)
    * [4.3. Gamepad API](#h4.3)
    * [4.4. Generic input API](#h4.4)

## <a name="h1"></a>1. Language

Viper uses lua as scripting language.

The following functions are called by the console :

* `function init()` : called once during the cartridge boot.
    * this is where images should be loaded with `gfx.load_img`
* `function update()` : called 60 times per second
    * this is where you should update your variables and anything that is time dependant
* `function render()` : called every frame
    * render one game frame. framerate might vary from one computer to another

Those functions are available globally:
* `atan2(dy,dx)` : arc tangent between -PI and PI
* `noise1(x)` : 1D simplex noise
* `noise2(x,y)` : 2D simplex noise
* `noise3(x,y,z)` : 3D simplex noise
* `fbm1(x)` : 1D fractional brownian motion
* `fbm2(x,y)` : 2D fractional brownian motion
* `fbm3(x,y,z)` : 3D fractional brownian motion
* `ease_in_cubic(t,value,delta,duration)` : cubic tweening function. t goes from 0 to duration, result from value to value+delta
* `ease_out_cubic(t,value,delta,duration)` : cubic tweening function. t goes from 0 to duration, result from value to value+delta
* `ease_in_out_cubic(t,value,delta,duration)` : cubic tweening function. t goes from 0 to duration, result from value to value+delta
* `print(message)` : display a debug screen on stdout(native) or js console (web)
* `elapsed()` : floating point number of seconds elapsed since the game started
* `lerp_angle(from,to,amount)` : linearly interpolates between two angles (in radians) by a normalized value.

Three interfaces are exposed by the viper console :

* `gfx` : the graphics API
* `snd` : the sound API
* `inp` : the input API

Each API might expose values and methods.

## <a name="h2"></a>2. Graphics API (gfx)

### <a name="h2.1"></a>2.1. Architecture

The viper screen size is 384x224 pixels. You can get those values with `gfx.SCREEN_WIDTH` and `gfx.SCREEN_HEIGHT`. The graphics engine can display on screen any number of transparent layers. Viper doesn't use alpha blending, but a transparent key color that can be changed with `gfx.set_transparent_color` (default is pure black).

All colors are expressed with integer component between 0 and 255. All coordinates are floats but for a pixel perfect result, you should truncate them to integers. But smooth movement can be achieved using float coordinates.

Each layer can be resized with `gfx.set_layer_size` and moved with `gfx.set_layer_offset`.
You can hide and show layers with `gfx.show_layer` and `gfx.hide_layer`. By default, only one layer (layer 0) is displayed.

The console renders the layers in increasing id order (first layer 0, then 1 on top of it and so on).

Layers can be used to overlay graphics on screen or store bitmap fonts/sprite sheets offscreen. You can copy an image from a layer to another with `gfx.set_sprite_layer`, `gfx.set_active_layer` and `gfx.blit`. You can load an image in the current active layer with `gfx.load_img`.

Each visible layer applies a color operation between its color and the underlying color :

* `gfx.LAYEROP_SET` : new pixel color = layer pixel color (default)
* `gfx.LAYEROP_ADD` : new pixel color = current pixel color + layer pixel color
* `gfx.LAYEROP_AVERAGE` : new pixel color = (current pixel color + layer pixel color)/2
* `gfx.LAYEROP_SUBTRACT` : new pixel color = current pixel color - layer pixel color
* `gfx.LAYEROP_MULTIPLY` : new pixel color = current pixel color * layer pixel color

Example :

`gfx.set_layer_operation(1, gfx.LAYEROP_ADD)`

You can draw on any layer by activating it with `gfx.set_active_layer(id)`.

You can get the number of frames rendered during the last second with :
`gfx.fps()`

### <a name="h2.2"></a>2.2. Drawing API

* `set_active_layer(id)`
    * set current drawing layer.
    * id is an arbitrary integer value. Visible layers are rendered in ascending id order.

* `load_img(layer, filepath, [resource_name])`
    * load an image in a layer.
    * warning ! the layer is resized to match the image size.

    filepath is an URL :

    * local file : `'myimage.png'`
    * remote file : `'http://someserver.com/myimage.png'`
    * TODO data URL : `'data:image/png; ...'`

    TODO To convert an image into data url, simply drag and drop it on the console screen.

    If resource_name is defined and not empty, this image can be overriden by the player by running the console with res parameters. This makes it easy for users to mod the game graphics by replacing a named resource with another image.

* `set_layer_size(id, w, h)`
    * resize a layer (w,h in pixels).

* `get_layer_size(id)`
    * return the layer size in pixels

Example :

```lua
    local w,h = gfx.get_layer_size(0)
```

* `set_layer_offset(id, x, y)`
    * set a layer scrolling offset.
    TODO use id -1 to scroll all visible layers (screen shake effect)

* `set_rowscroll(id,[start_row],[end_row],[start_value],[end_value])`
    * apply an horizontal skew effect to the layer, moving each row by a specific offset.
    * `id` : id of the layer. if no other parameter is set, the rowscroll is disabled for this layer
    * `start_row,end_row` : range of row where we want to change the offsets
    * `start_value,end_value` : offset value is interpolated between these values (or constant if end_value is nil)

* `set_colscroll(id,[start_col],[end_col],[start_value],[end_value])`
    * apply a vertical skew effect to the layer, moving each column by a specific offset.
    * `id` : id of the layer. if no other parameter is set, the colscroll is disabled for this layer
    * `start_col,end_col` : range of columns where we want to change the offsets
    * `start_value,end_value` : offset value is interpolated between these values (or constant if end_value is nil)

* `clear_scroll(id)`
    * disable all rows/columns scroll for this layer

Example :

```lua
gfx.set_rowscroll(0,180,223,0,40)
```
Sets a rowscroll offset for rows 180 to 223. The offset ranges from 0 for row 180 to 40 for row 223

* `set_layer_operation(id, layer_op)`
    * set the layer color operation.
    * layer_op values : `gfx.LAYEROP_SET`/`gfx.LAYEROP_ADD`/`gfx.LAYEROP_AVERAGE`/`gfx.LAYEROP_SUBTRACT`/`gfx.LAYEROP_MULTIPLY`.

* `clear([r,g,b])`
    * fill the active layer with the color `r,g,b`. If the color is not defined, use the transparent color (default black).

* `blit_pixels(x,y, width, rgb)`
    * set pixel colors on current layer.
    * x,y is the position on the layer
    * width is the width of the sprite
    * rgb is an array of colors with format rgb24 (0xRRGGBB). You can use `gfx.to_rgb24(r,g,b)` to get this value

    Example :

    `gfx.blit_pixels(0,0,1,{255})` would blit a single blue pixel at position 0,0 (255 = 0x0000FF => r=0,g=0,b=255)

    Another way to write it :

    `gfx.blit_pixels(0,0,1,{gfx.to_rgb24(0,0,255)})`

    Note that this function is far slower than the `gfx.blit` function which is fully running on the GPU.

* `line(x1,y1, x2,y2, r,g,b)`
    * draw a line

* `triangle(x1,y1, x2,y2, x3,y3, r,g,b)`
    * fill a triangle

* `rectangle(x,y, w,h, r,g,b)`
    * fill a rectangle

* `circle(x,y, radius_x, [radius_y], r,g,b)`
    * draw a circle/ellipse

* `disk(x,y, radius_x, [radius_y], r,g,b)`
    * fill a circle/ellipse

### <a name="h2.3"></a>2.3. Font API
* You define a bitmap font with `set_font` by defining a rectangular zone inside a layer, and the character size :
* `set_font(id, x,y,w,h, char_width,char_height, [charset], [spacing_h],[spacing_v], [chars_width])`
    * `id` id of the layer containing the characters sprites
    * `x,y,w,h` define a region of a layer as a bitmap font to use with `gfx.print`
    * `char_width,char_height` if the size of a character in this bitmap (in case of non-monotype font, use the chars_width parameter)
    * `charset` is a string representing the characters in the bitmap font.
    * if `charset` is not set, the ascii table order is expected.
    * `spacing_h,spacing_v` additional horizontal and vertical spacing between characters when drawing text (default 0,0)
    * `chars_width` is an array containing the width of each character.
    * if `chars_width` is not set, this is a mono font and every character's width is `char_width`
    * The function returns a number representing this font. You can use this number to print text.
    * The console is preloaded with three fonts :
        * `gfx.FONT_8X8` : the default mono font that contains the complete 128 ascii table characters.
        * `gfx.FONT_5X7` : a smaller non-mono font that contains the 93 ascii characters from `!` to `~`.
        * `gfx.FONT_4X6` : a very small mono font that contains the 93 ascii characters from `!` to `~`.

* `print(font, text, x,y, [r],[g],[b])`
    * print the text at position `x,y` using a specific font
    * `r,g,b` : multiply the font's character sprites with this color (default white)

    Example : print hello at position 0,0 in white

    `gfx.print(gfx.FONT_8X8, "hello", 0,0)`

### <a name="h2.4"></a>2.4. Sprite API

You select a spritesheet with `set_sprite_layer` (default is `gfx.SYSTEM_LAYER`). `gfx.blit` uses it as a source. The destination is the current active layer.
Source and destination cannot be the same layer.

* `set_sprite_layer(id)`
    * define the current source for sprite blitting operations

* `blit(sx,sy,sw,sh, dx,dy, [r,g,b], [angle], [dw],[dh], [hflip],[vflip])`
    * blit a rectangular zone from the current sprite layer to the active layer
    * warning : using angle = 0 or angle = nil does not produce the same result. See dx,dy description below
    * `sx,sy` : top left pixel position in the spritesheet
    * `sw,sh` : rectangular zone size in the spritesheet in pixels
    * `dx,dy` : destination on active pixel buffer (top left position if angle==nil, else center position)
    * `r,g,b` : multiply the sprite colors with this color (default white)
    * `angle` : an optional rotation angle in radians
    * `dw,dh` : destination size in pixel (if 0,0, or nil,nil, uses the source size). The sprite will be stretched to fill dw,dh
    * `hflip, vflip` : whether to flip the sprite horizontally or vertically (default false)

* `blit_col(sx,sy,sw,sh, dx,dy, [r,g,b], [angle], [dw],[dh], [hflip],[vflip])`
    * blit a rectangular zone from the current sprite layer to the active layer replacing all non transparent pixels with r,g,b.
    * warning : using angle = 0 or angle = nil does not produce the same result. See dx,dy description below
    * This function is useful for example if you want to blit a sprite with all white pixels for a hit effect, or to black for drop shadow effects.
    * `sx,sy` : top left pixel position in the spritesheet
    * `sw,sh` : rectangular zone size in the spritesheet in pixels
    * `dx,dy` : destination on active pixel buffer (top left position if angle==nil, else center position)
    * `r,g,b` : replace all sprite's pixels with this color (default white)
    * `angle` : an optional rotation angle in radians
    * `dw,dh` : destination size in pixel (if 0,0, or nil,nil, uses the source size). The sprite will be stretched to fill dw,dh
    * `hflip, vflip` : whether to flip the sprite horizontally or vertically (default false)

### <a name="h2.5"></a>2.5. Spritesheets
You can define a spritesheet on any layer using the `gfx.set_spritesheet` function.
* `set_spritesheet(layer, sprite_w, sprite_h, [off_x], [off_y], [grid_width])`
    * return the id of a spritesheet that can be used to easily blit sprites
    * `layer` the layer containing the sprites
    * `sprite_w, sprite_h` : the size of a sprite in pixels
    * `off_x, off_y` : the top-left position of the sprite grid in the layer (default 0,0)
    * `grid_width` : in case the spritesheet doesn't use all the layer width, how many sprites are in a row

You can then blit a sprite from this layer using `gfx.blit_sprite` :
* `blit_sprite(spritesheet_id, sprite_num, dx, dy, [r,g,b], [angle], [dw],[dh], [hflip],[vflip])`
    * blit a sprite from a predefined spritesheet to the active layer.
    * warning : using angle = 0 or angle = nil does not produce the same result. See dx,dy description below
    * `spritesheet_id` : id returned by the `set_spritesheet` function
    * `sprite_num` : number of the sprite in the grid (0 = top-left, row-first order)
    * `dx,dy` : destination on active pixel buffer (the sprite's top left position if angle==nil, else center position)
    * `r,g,b` : multiply the sprite colors with this color (default white)
    * `angle` : an optional rotation angle in radians
    * `dw,dh` : destination size in pixel (if 0,0, or nil,nil, uses the sprite size). The sprite will be stretched to fill dw,dh
    * `hflip, vflip` : whether to flip the sprite horizontally or vertically (default false)

Example :

```lua
-- define layer 1 as a grid of 32x32 pixels sprites
spritesheet_id = gfx.set_spritesheet(1, 32, 32)
-- blit the top left sprite (#0) on the current layer at position 10,10
gfx.blit_sprite(spritesheet_id, 0, 10, 10)
```

## <a name="h3"></a>3. Sound API (snd)
The viper has 6 channels that each can play stereo sound at 48kHz with float32 samples.

### <a name="h3.1"></a>3.1. Instrument API
You can create any number of instruments that produce sound.
Instrument can either use additive synthesis by using various oscillators or read samples from .wav files.

Oscillator instrument properties:

* oscillator parameters
    * `OVERTONE` : amount of overtone
    * `OVERTONE_RATIO` : 0 = octave below, 1 = fifth above
    * `SAW` : amount of sawtooth waveform (0.0-1.0)
    * `ULTRASAW` : amount of ultrasaw in the saw waveform (0.0-1.0)
    * `SQUARE` : amount of square waveform (0.0-1.0)
    * `PULSE` : width of the square pulse should be in `]0..1[` interval
    * `TRIANGLE` : amount of triangle waveform (0.0-1.0)
    * `METALIZER` : amount of metalizer in the triangle waveform (0.0-1.0)
    * `NOISE` : amount of noise (0.0-1.0)
    * `NOISE_COLOR` : from white (0.0) to pink (1.0) noise
* filter parameters
    * `FILTER_BAND` : type of filter (`LOWPASS`, `BANDPASS`, `HIGHPASS`, `NOTCH`)
    * `FILTER_DISTO` : amount of distortion (0-200)
    * `FILTER_GAIN`: lowshelf filter boost in Db (-40, 40)
    * `FILTER_CUTOFF`: upper limit of frequencies getting a boost (0-8000)
* lfo parameters
    * `LFO_AMOUNT` : amplitude of the lfo waveform (0-1)
    * `LFO_RATE` : frequency of the lfo waveform (0-8000)
    * `LFO_SHAPE`: type of waveform (`SAW`, `SQUARE`, `TRIANGLE`)
    * `LFO_PITCH` : whether the lfo affects the notes pitch (0 or 1)
    * `LFO_FILTER`: whether the lfo affects the filter cutoff (0 or 1)
    * `LFO_PULSE`: whether the lfo affects the pulse width (0 or 1)
    * `LFO_METALIZER`: whether the lfo affects the metalizer amount (0 or 1)
    * `LFO_OVERTONE`: whether the lfo affects the overtone amount (0 or 1)
    * `LFO_ULTRASAW`: whether the lfo affects the ultrasaw amount (0 or 1)
* envelop parameters
    * `ATTACK` : duration of attack phase
    * `DECAY` : duration of decay phase
    * `SUSTAIN` : duration of sustain phase
    * `RELEASE` : duration of release phase

   By default, envelop is altering the note volume. But it can also be used to alter other parameters :

    * `ENV_AMOUNT` : scale the effect of the envelop on the parameter
    * `ENV_PITCH` : amount of envelop altering the note pitch
    * `ENV_FILTER` : amount of envelop altering the note pitch
    * `ENV_METALIZER` : amount of envelop altering the metalizer parameter of the oscillator
    * `ENV_OVERTONE` : amount of envelop altering the overtone parameter of the oscillator
    * `ENV_PULSE` : amount of envelop altering the pulse width of the oscillator
    * `ENV_ULTRASAW` : amount of envelop altering the utrasaw parameter of the oscillator

Sample instrument properties :

* base parameters
   * `FILE` : path to the .wav file
   * `FREQ` : base frequency of the sound in the file

*  looping
   * `LOOP_START` : sample index where to start the loop
   * `LOOP_END` : sample index where to end the loop

* envelop
   * `ATTACK` : duration of attack phase
   * `DECAY` : duration of decay phase
   * `SUSTAIN` : duration of sustain phase
   * `RELEASE` : duration of release phase

* `new_instrument(description)` : create a new instrument, return a numerical id for the instrument that can be used in the song patterns (the first is 0 then it is incremented for each new instrument).

   For oscillator instruments, the description starts with the `INST` keyword followed with a list of parameters. It should end with the `NAM` parameter with the instrument name.
   Example:

   ```
    triangle_id = snd.new_instrument("INST OVERTONE 1.0 TRIANGLE 1.0 METALIZER 0.85 NAM triangle")
    pulse_id = snd.new_instrument("INST OVERTONE 1.0 SQUARE 0.5 PULSE 0.5 TRIANGLE 1.0 METALIZER 1.0 OVERTONE_RATIO 0.5 NAM pulse")
   ```

   For sample instruments, the description starts with the `SAMPLE`keywords followed with a list of parameters.
   Example :

   ```
   snare_id = snd.new_instrument("SAMPLE FILE musics/samples/snare.wav FREQ 17000")
   ```

* `set_instrument(id, new_description)` : update the parameters of instrument id from a new description
* `play_note(instrument_id, frequency, lvolume, [rvolume], [channel])` : start playing a note on a channel (between 0 and 5). If channel is not defined, any free channel will be used. volume is between 0 and 1
* `set_channel_volume(channel, lvolume, [rvolume])` : change the volume of a channel without interrupting the oscillator/sample
* `set_channel_balance(channel, balance)` : alternative way to change the volume of a channel, balance is between -1 (left) and 1 (right)
* `set_channel_freq(channel, freq)` : change the frequency of a channel without interrupting the oscillator/sample
* `stop_channel(channel)` : mute the channel
* `reserve_channel(channel)` : mark a channel so that it's not used except if explicitely adressed in play_note, play_pattern or play_music
* `release_channel(channel)` : release a channel so that it can be used by play_note, play_pattern or play_music when the channel are not specified

### <a name="h3.2"></a>3.2. Pattern API
A pattern is a list of notes that plays at a specific rate.

* `new_pattern(description)` : register a new pattern and returns its id (0, then incremented for each new pattern).

The description starts with the `PAT` keyword followed by the notes duration (or speed at which the pattern plays the notes). The duration is divided by 120. For example :
* 01 => each note duration is 1/120 second
* 02 => each note duration is 1/60 second
* 04 => each note duration is 1/30 second

Then it's followed by a list of notes.
Example :

```
new_pattern("PAT 02 F.2070 G.2070 D.3070 C.4070")
```

The note format is [note] [octave] [instrument_id] [volume] [fx] with :
* note : C. C# D. D# E. F. F# G. G# A. A# B.
* octave : between 0 and 8
* volume : hexadecimal between 1 (lowest) and F (highest)
* fx : special sound effect between 0 and 5 :
   * 0 : no effect
   * 1 : slide
   * 2 : vibrato
   * 3 : drop
   * 4 : fade in
   * 5 : fade out

You can add a silence by filling the note format with 6 dots : `......`
Example :

```
new_pattern("PAT 16 C#3915 ...... ...... C#3915 D#3835")
```

* `set_pattern(id, new_description)` : update a pattern
* `play_pattern(id, [channel])` : play the pattern on a channel. If channel is not defined, any free channel will be used.

### <a name="h3.3"></a>3.3. Song API
A song is an ordered list of patterns to play on one or several of the 6 available channels.

* `new_music(desc)` : create a new music from a description. return an id (0, then incremented for each new music)

The description is a multi-line string.
* The first line contains the song's name using the `NAM` parameter.
* The second line contain the list of patterns used by the song using the `PATLIST`parameter (you can select only a part of all the patterns created).
* The last line contain the actual sequence of patterns. Each sequence display which pattern to play on each channel. Unused channels contains a dot.

Example :
```
MUSIC_TITLE = [[NAM title screen
PATLIST 56 57 58 59 60
SEQ 024... 134...]]
snd.new_music(MUSIC_TITLE)
```

Here the song is named "title screen". It uses 5 patterns number 56, 57, 58, 59 and 60.
* The first sequence plays pattern 0 (56) on channel 1, 2 (58) on channel 2, 4 (60) on channel 3.
* The second sequence plays pattern 1 (57) on channel 1, 3 (59) on channel 2, 4 (60) on channel 3.
* The last 3 channels are not used and can be used to play other sound effects (using the `play_pattern` function while the music is playing.

* `play_music(id, channel_mask)` : play a music. The channel_mask defines the channels to be used to play the music patterns. There must be enough channel to play all the simultaneous patterns in a sequence.

For example with the previous song, which requires 3 channels, you can use the binary mask 111 = 7. This would result in the song using the channels 0,1,2.

### <a name="h3.4"></a>3.4. Midi API
TODO

## <a name="h4"></a>4. Input API (inp)

### <a name="h4.1"></a>4.1. Keyboard API

* `key(key)` : return true if key is pressed.
* `key_pressed(key)` : return true if key was pressed during last frame
* `key_released(key)` : return true if key was released during last frame

The value for the `key` scan codes are :
* `inp.KEY_0`..`inp.KEY_9` : upper digits
* `inp.KEY_A`..`inp.KEY_Z` : letters (this returns KEY_Q when you press A on an AZERTY keyboard)
* `inp.KEY_F1`..`inp.KEY_F10` : function keys

Arrow keys : (also triggered by numeric keypad if numlock is disabled)
* `inp.KEY_UP`
* `inp.KEY_DOWN`
* `inp.KEY_LEFT`
* `inp.KEY_RIGHT`

Special keys :
* `inp.KEY_TAB`
* `inp.KEY_SPACE`
* `inp.KEY_BACKSPACE`
* `inp.KEY_ENTER`
* `inp.KEY_ESCAPE`
* `inp.KEY_PRINTSCREEN`
* `inp.KEY_SCROLLLOCK`
* `inp.KEY_PAUSE`
* `inp.KEY_INSERT`
* `inp.KEY_HOME`
* `inp.KEY_DELETE`
* `inp.KEY_END`
* `inp.KEY_PAGEDOWN`
* `inp.KEY_PAGEUP`
* `inp.KEY_CTRL`
* `inp.KEY_LSHIFT`
* `inp.KEY_RALT`
* `inp.KEY_RSHIFT`

### <a name="h4.2"></a>4.2. Mouse API

List of button values :

* 0: Main button pressed, usually the left button or the un-initialized state
* 1: Auxiliary button pressed, usually the wheel button or the middle button (if present)
* 2: Secondary button pressed, usually the right button
* 3: Fourth button, typically the Browser Back button
* 4: Fifth button, typically the Browser Forward button

Functions :

* `mouse_button(num)` : return true if mouse button num is pressed.

    You can use any button number or the predefined constants :
    * `inp.MOUSE_LEFT`
    * `inp.MOUSE_MIDDLE`
    * `inp.MOUSE_RIGHT`

* `mouse_button_pressed(num)` : return true if mouse button num was pressed since the last game tick
* `mouse_button_released(num)` : return true if mouse button num was released since the last game tick
* `mouse_pos()`: return the mouse position in pixels

Example :

```
local mousex,mousey = inp.mouse_pos()
```

Note : you can show/hide the mouse cursor with the gfx API :

* `show_mouse_cursor(onoff)`

Example :

```lua
gfx.show_mouse_cursor(false)
```

### <a name="h4.3"></a>4.3. Gamepad API
***in beta***

In the following functions, `player_num` value is :
* `0` : the keyboard (arrows for directions and X,C,V,Z,Escape,Enter corresponding to A,X,B,Y,Select,Start on the controller)
* `1` to `8` : up to 8 controllers support

This makes it possible to use the same API whether the player is using the keyboard or the controller.

Functions :

* `pad_button(player_num, num)` : return true if button num for player player_num is pressed
* `pad_button_pressed(player_num, num)` : return true if button num for player player_num was pressed since the last game tick

    You can use these constants for the num value :
    * `inp.XBOX360_A`
    * `inp.XBOX360_B`
    * `inp.XBOX360_X`
    * `inp.XBOX360_Y`
    * `inp.XBOX360_LB`
    * `inp.XBOX360_RB`
    * `inp.XBOX360_SELECT`
    * `inp.XBOX360_START`
    * `inp.XBOX360_LS`
    * `inp.XBOX360_RS`
* `pad_ls(player_num)` : return the left analog stick axis values (between -1 and 1) for player player_num

    Example :
    `local x,y = inp.pad_ls(1)`

* `set_ls_neutral_zone(value)` : sets the left analog stick neutral zone (between 0 and 1)
* `pad_rs(player_num)` : return the right analog stick axis values (between -1 and 1) for player player_num
* `set_rs_neutral_zone(value)` : sets the right analog stick neutral zone (between 0 and 1)
* `pad_lt(player_num)` : return the left trigger value (between -1 and 1) for player player_num
* `pad_rt(player_num)` : return the right trigger value (between -1 and 1) for player player_num

### <a name="h4.4"></a>4.4. Generic input API

If you want to support both keyboard and controller at the same time in a single player game, you can use these generic functions instead :

* `inp.action1()` returns true if the controller A button or keyboard X key are pressed
* `inp.action2()` returns true if the controller X button or keyboard C key are pressed
* `inp.action3()` returns true if the controller B button or keyboard V key are pressed
* `inp.action4()` returns true if the controller Y button or keyboard Z key are pressed

The same functions with the _pressed suffix exist to check if the button was pressed since the last game tick. They all return a boolean.
* `inp.action1_pressed()`
* `inp.action2_pressed()`
* `inp.action3_pressed()`
* `inp.action4_pressed()`

Those last function will check controller #1 and keyboard if the player is not defined, else only the controller #player (0=keyboard, 1-8=controller)
* `inp.up([player])` value between 0 and 1
* `inp.down([player])` value between 0 and 1
* `inp.left([player])` value between 0 and 1
* `inp.right([player])` value between 0 and 1
* `inp.up_pressed([player])`
* `inp.down_pressed([player])`
* `inp.left_pressed([player])`
* `inp.right_pressed([player])`

