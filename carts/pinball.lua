-- terra nova pinball
-- ricochet around an alien world
-- terra nova pinball by matt sutton is licensed under a creative commons attribution-noncommercial 4.0 international license.
-- https://creativecommons.org/licenses/by-nc/4.0/legalcode
-- pico8 compat layer
local X_OFFSET<const> = 384//2-64
local Y_OFFSET<const> = 0
local SPRITE_SIZE<const> = 8
local SPRITE_PER_ROW<const> = 128//SPRITE_SIZE


local flr = math.floor
local max = math.max
local min = math.min
local abs = math.abs
local ceil = math.ceil
local sqrt = math.sqrt
local chr = string.char
local sub = string.sub
local tostr = tostring

function sin(v)
    return math.sin(from_pico_angle(v))
end

function cos(v)
    return math.cos(from_pico_angle(v))
end

function from_pico_angle(v)
    return v < 0.5 and -v * 2 * math.pi or (1 - v) * 2 * math.pi
end

col = function(r, g, b)
    return {
        r = r,
        g = g,
        b = b
    }
end

PAL = {
    [0] = col(0, 0, 1),
    col(29, 43, 83),
    col(126, 37, 83),
    col(0, 135, 81),
    col(171, 82, 54),
    col(95, 87, 79),
    col(194, 195, 199),
    col(255, 241, 232),
    col(255, 0, 77),
    col(255, 163, 0),
    col(255, 236, 39),
    col(0, 228, 54),
    col(41, 173, 255),
    col(131, 118, 156),
    col(255, 119, 168),
    col(255, 204, 170)
}

function btnp(num)
    if num == 0 then
        return inp.left_pressed()
    elseif num == 1 then
        return inp.right_pressed()
    elseif num == 2 then
        return inp.up_pressed()
    elseif num == 3 then
        return inp.down_pressed()
    elseif num == 4 then
        return inp.action1_pressed()
    elseif num == 5 then
        return inp.action2_pressed()
    elseif num == inp.KEY_LSHIFT or num == inp.KEY_RSHIFT or num == inp.KEY_LEFT or num == inp.KEY_RIGHT or num == inp.KEY_X or num == inp.KEY_C then
        return inp.key_pressed(num)
    elseif num == inp.XBOX360_LB or num == inp.XBOX360_RB then
        return inp.pad_button_pressed(1,num)
    elseif num == inp.MOUSE_LEFT or num == inp.MOUSE_RIGHT then
        return inp.mouse_button_pressed(num)
    end
end

function btn(num)
    if num == 0 then
        return inp.left() > 0.1
    elseif num == 1 then
        return inp.right() > 0.1
    elseif num == 2 then
        return inp.up() > 0.1
    elseif num == 3 then
        return inp.down() > 0.1
    elseif num == 4 then
        return inp.action1()
    elseif num == 5 then
        return inp.action2()
    elseif num == inp.KEY_LSHIFT or num == inp.KEY_RSHIFT or num == inp.KEY_LEFT or num == inp.KEY_RIGHT or num == inp.KEY_X or num == inp.KEY_C then
        return inp.key(num)
    elseif num == inp.XBOX360_LB or num == inp.XBOX360_RB then
        return inp.pad_button(1,num)
    elseif num == inp.MOUSE_LEFT or num == inp.MOUSE_RIGHT then
        return inp.mouse_button(num)
    end
end

function rectfill(x0, y0, x1, y1, pal)
    local col = PAL[pal and flr(pal) or 6]
    if col == nil then
        print("ERROR unknown PAL "..pal)
    end
    local x0 = x0 + X_OFFSET
    local x1 = x1 + X_OFFSET
    local y0 = y0 + Y_OFFSET
    local y1 = y1 + Y_OFFSET
    gfx.rectangle(x0, y0, x1 - x0 + 1, y1 - y0 + 1, col.r, col.g, col.b)
end

function rect(x0, y0, x1, y1, pal)
    local c = PAL[pal and flr(pal) or 6]
    local x0 = x0 + X_OFFSET
    local x1 = x1 + X_OFFSET
    local y0 = y0 + Y_OFFSET
    local y1 = y1 + Y_OFFSET
    gfx.line(x0,y0,x1,y0,c.r,c.g,c.b)
    gfx.line(x0,y1,x1,y1,c.r,c.g,c.b)
    gfx.line(x0,y0,x0,y1,c.r,c.g,c.b)
    gfx.line(x1,y0,x1,y1,c.r,c.g,c.b)
end

function split(s)
    local t = {}
    for str in string.gmatch(s, "([^,]+)") do
        table.insert(t, str)
    end
    return t
end

function cls()
    gfx.clear(0, 0, 1)
end

function add(t,v,i)
    if i then
        table.insert(t,i,v)
    else
        table.insert(t,v)
    end
end

function del(t,o)
    for i=1,#t do
        if t[i] == o then
            table.remove(t,i)
            break
        end
    end
end

function tonum(b)
    return b and 1 or 0
end

function rnd(x)
    if type(x) == "table" then
        local n = math.random(#x)
        return x[n]
    else
        return math.random() * x
    end
end

function all(t)
    local i = 0
    return function()
        i = i + 1
        return t[i]
    end
end

function foreach(t, f)
    for i=1,#t do
        f(t[i])
    end
end

function music(seq,fade,mask)
    snd.play_music(0,1)
end

function sfx(n)
    snd.play_pattern(n)
end

function pset(x,y,col)
    local c = PAL[col and flr(col) or 6]
    local x = x + X_OFFSET
    local y = y + Y_OFFSET
    gfx.rectangle(x,y,1,1,c.r,c.g,c.b)
end

function gprint(msg, px, py, col)
    local c = PAL[flr(col or 6)]
    gfx.print(gfx.FONT_4X6, msg, flr(px) + X_OFFSET, flr(py) + Y_OFFSET, c.r, c.g, c.b)
end

function spr(n, x, y, w, h, hflip, vflip)
    local int_spr = math.floor(n)
    local spritex = (int_spr % SPRITE_PER_ROW) * SPRITE_SIZE
    local spritey = (int_spr // SPRITE_PER_ROW) * SPRITE_SIZE
    w = w or 1
    h = h or 1
    gfx.blit(
        spritex,
        spritey,
        w * SPRITE_SIZE,
        h * SPRITE_SIZE,
        math.floor(x + X_OFFSET),
        math.floor(y + Y_OFFSET),
        255, 255, 255,
        nil,nil,nil,
        hflip,vflip
    )
end

function sspr(sx, sy, sw, sh, dx, dy, dw, dh, hflip, vflip)
	gfx.blit(sx, sy, sw, sh,
		X_OFFSET + dx, Y_OFFSET + dy, 255, 255, 255, nil, dw, dh, hflip, vflip)
end
function sspr_col(sx, sy, sw, sh, dx, dy, dw, dh, hflip, vflip, col)
    local c=PAL[col]
	gfx.blit_col(sx, sy, sw, sh,
		X_OFFSET + dx, Y_OFFSET + dy, c.r, c.g, c.b, nil, dw, dh, hflip, vflip)
end

function map()
    for x = 0, 15 do
        for y = 0,15 do
            local v = TILE_MAP[x + y * 128 + 1]
            if v~=nil and v ~= 0 then
                local spritex = (v % SPRITE_PER_ROW) * SPRITE_SIZE
                local spritey = (v // SPRITE_PER_ROW) * SPRITE_SIZE
                gfx.blit(spritex, spritey, SPRITE_SIZE, SPRITE_SIZE,
                    X_OFFSET + x * SPRITE_SIZE,
                    Y_OFFSET + y * SPRITE_SIZE
                )
            end
        end
    end
end

function line(x1, y1, x2, y2, col)
    gfx.line(x1 + X_OFFSET, y1 + Y_OFFSET, x2 + X_OFFSET, y2 + Y_OFFSET, PAL[col].r, PAL[col].g, PAL[col].b)
end

function circfill(x, y, r, pal)
	local col = PAL[pal and flr(pal) or 6]
	local x = x + X_OFFSET
	local y = y + Y_OFFSET
	gfx.circle(x, y, r, nil, col.r, col.g, col.b)
end

function circ(x, y, r, pal)
	local col = PAL[pal and flr(pal) or 6]
	local x = x + X_OFFSET
	local y = y + Y_OFFSET
	gfx.disk(x, y, r, nil, col.r, col.g, col.b)
end

-- main
tracker_cols = {5, 13}

col_grads = {split("0,0,5,13,6,7"), split("0,0,5,3,11,11"), split("0,0,2,8,14,15"), split("0,0,4,9,10,10"),
             split("0,0,1,13,12,12")}

function init()
    gfx.show_mouse_cursor(false)
	snd.new_instrument(INST_TRIANGLE)
	snd.new_instrument(INST_TILTED)
	snd.new_instrument(INST_SAW)
	snd.new_instrument(INST_SQUARE)
	snd.new_instrument(INST_PULSE)
	snd.new_instrument(INST_ORGAN)
	snd.new_instrument(INST_NOISE)
	snd.new_instrument(INST_PHASER)
    snd.new_instrument(INST_SNARE)
    snd.new_instrument(INST_KICK)
    for _,pat in ipairs(SFX) do
        snd.new_pattern(pat)
    end
    snd.new_music(MUSIC)
    f = 0
    gfx.load_img(1, "pinball/pinball.png")
    gfx.set_sprite_layer(1)
    gfx.set_layer_operation(2,gfx.LAYEROP_ADD)
    gfx.show_layer(2)
    version = "1.2.0"
    -- TODO
    -- cartdata("xietanu_terranovapinball_v1")
    -- if dget(0) == 0 then
    --     gen_highscores()
    -- end
    read_highscores()

    paddle_controls = {{
        l = inp.KEY_X,
        r = inp.KEY_C,
        ls = "X",
        rs = "C"
    }, {
        l = inp.KEY_LEFT,
        r = inp.KEY_RIGHT,
        ls = "left",
        rs = "right"
    }, {
        l = inp.KEY_LSHIFT,
        r = inp.KEY_RSHIFT,
        ls = "lshift",
        rs = "rshift"
    }, {
        l = inp.MOUSE_LEFT,
        r = inp.MOUSE_RIGHT,
        ls = "lmouse",
        rs = "rmouse"
    }, {
        l = inp.XBOX360_LB,
        r = inp.XBOX360_RB,
        ls = "LB",
        rs = "RB"
    }}

    pc_option = 1

    modes = {
        game = {
            init = init_game,
            update = update_game,
            draw = draw_game
        },
        title = {
            init = init_title,
            update = update_title,
            draw = draw_title
        },
        menu = {
            init = init_menu,
            update = update_menu,
            draw = draw_menu
        },
        launch = {
            init = init_launch,
            update = update_launch,
            draw = draw_game
        },
        game_over = {
            init = init_game_over,
            update = update_game_over,
            draw = draw_game_over
        },
        logo = {
            init = init_logo,
            update = update_title,
            draw = draw_logo
        },
        highscores = {
            init = pass,
            update = update_highscores,
            draw = draw_highscores
        }
    }
    mode = modes.logo
    mode.init()
    music(3, 0, 1)
    --menuitem(4, "music on", toggle_music)
end

function update()
    f = f + 1

    if transitioning then
        update_transition()
    end

    mode.update()
end

function render()
    cls()
    if show_stars then
        for _s in all(stars) do
            pset(_s.x, _s.y, _s.c)
        end
    end
    if show_credits then
        print_version_credits()
    end
    if transitioning then
        draw_transition()
    end
    mode.draw()
    -- pal()
end

function gen_highscores()
    dset(0, 1)
    for i = 1, 40 do
        if i % 4 == 0 then
            dset(i, 13)
        else
            dset(i, 0)
        end
    end
    dset(3, 1)
    for i = 0, 9 do
        dset(6 + i * 4, 900 - i * 100)
    end
end

function read_highscores()
    highscores = {}
    for i = 0, 36, 4 do
        add(highscores, {
            0, --dget(1 + i),
            0, --dget(2 + i),
            0, --dget(3 + i),
            13 --c = dget(4 + i)
        })
    end
end

function write_highscores()
    -- TODO
    -- for i = 0, 9 do
    --     for j = 1, 3 do
    --         dset(i * 4 + j, highscores[i + 1][j])
    --     end
    --     dset(i * 4 + 4, highscores[i + 1].c)
    -- end
end

function toggle_music()
    local music_option
    music_off = not music_off
    if music_off then
        music_option = "music off"
        music(-1, 1000)
    else
        music_option = "music on"
        music(3, 0, 1)
    end
    --menuitem(4)
    --menuitem(4, music_option, toggle_music)
end

-- draw
-- #include draw/draw_collider.p8
function draw_spr(_obj)
    local _spr = _obj.spr_coords
    local col=4
    if _obj.hit > 0 and not transitioning then
        _spr = _obj.hit_spr_coords or _spr
        -- pal(_obj.unlit_col or 8, 9)
        col=9
        _obj.hit = _obj.hit - 1
    elseif _obj.lit and not transitioning then
        -- pal(_obj.unlit_col or 8, 10)
        col=10
    end
    local _off = _obj.origin:plus(_obj.spr_off)
    local _w, _h = _obj.spr_w, _obj.spr_h
    sspr(_spr.x, _spr.y, _w, _h, _off.x, _off.y, _w, _h, _obj.flip_x, _obj.flip_y)
    gfx.set_active_layer(2)
    sspr_col(_spr.x, _spr.y, _w, _h, _off.x, _off.y, _w, _h, _obj.flip_x, _obj.flip_y,col == 4 and 0 or col)
    gfx.set_active_layer(0)
    if not transitioning then
        -- pal()
    end
end

function print_shadow(_text, _x, _y, _col, _s_col)
    -- print text with drop shadow
    for i = -1, 1 do
        for j = -1, 1 do
            gprint(_text, _x + i, _y + j, _s_col)
        end
    end
    gprint(_text, _x, _y, _col)
end

-- modes
function init_game()
    show_stars = false
    got_highscore = 0
    balls = 3
    planet_lights_lit = 0.75

    msg = ""

    msgs = {}
    ongoing_msgs = {}
    launch_msg = {"up/down:", " set power", "C: launch"}

    init_table()

    action_queue = {}

    score = init_long(3)
end

function update_game()
    for _s in all(static_colliders) do
        _s.c = 6
    end

    dt = 1
    for _f in all(flippers) do
        dt = max(dt, update_flipper(_f))
    end

    for pinball in all(pinballs) do
        dt = max(dt, update_pinball_spd_acc(pinball))
        for _t in all(pinball.trackers) do
            _t.l = _t.l - 0.5
            if _t.l < 0 then
                del(pinball.trackers, _t)
            end
        end
    end

    for i = 1, dt do

        for _f in all(flippers) do
            update_flipper_pos(_f, dt)
        end
        for pinball in all(pinballs) do
            if not pinball.captured then
                for _f in all(flippers) do
                    check_collision(pinball, _f)
                end
                update_pinball_pos(pinball, dt)
            end
        end
    end

    update_spinner()

    for _action in all(action_queue) do
        _action.delay = _action.delay - 1
        if _action.delay <= 0 then
            del(action_queue, _action)
            _action.func(_action.args)
        end
    end

    if #pinballs == 0 then
        if balls == 0 and not reset_light.lit then
            evt_end_target_hunt()
            mode = modes.game_over
            mode.init()
            return
        end
        mode = modes.launch
        mode.init()
    end

    if #msgs > 0 then
        msgs[1].t = msgs[1].t - 1
        if msgs[1].t <= 0 then
            del(msgs, msgs[1])
        end
    end

    planet_lights_lit = max(planet_lights_lit - 0.0025, 0.75)
    set_planet_lights()
end

function draw_game()
    draw_backboard()

    draw_table()

    if #msgs > 0 then
        local _m = msgs[1]
        for i = 1, #_m do
            gprint(_m[i], 83, 31 + i * 8, get_frame({10, 7, 12, 7}, _m.t, 15))
        end
    elseif #ongoing_msgs > 0 then
        local _m = ongoing_msgs[#ongoing_msgs]
        for i = 1, #_m do
            gprint(_m[i], 83, 31 + i * 8, 10)
        end
    end
    -- draw colliders
    -- for s in all(static_colliders) do
    --     local c=s.simple_collider
        -- local x1=X_OFFSET+c.x1
        -- local y1=c.y1
        -- local x2=X_OFFSET+c.x2
        -- local y2=c.y2
        -- gfx.line(x1,y1,x2,y1,255,0,0)
        -- gfx.line(x1,y1,x1,y2,255,0,0)
        -- gfx.line(x1,y2,x2,y2,255,0,0)
        -- gfx.line(x2,y1,x2,y2,255,0,0)
        -- c=s.collider
        -- if c then
        --     local oldp
        --     for p in all(c) do
        --         if oldp then
        --             gfx.line(X_OFFSET+oldp.x,oldp.y,X_OFFSET+p.x,p.y,0,255,0)
        --         end
        --         oldp=p
        --     end
        -- end
    -- end
end

function pass()
end

function draw_backboard(_score_col)
    _score_col = _score_col or 10
    rectfill(81, 0, 127, 127, 5)

    rectfill(81, 16, 127, 47, 1)
    spr(112, 80, 18, 6, 2)

    rect(81, 0, 127, 127, 5)
    rect(81, 0, 127, 15, 5)
    rect(81, 36, 127, 63, 5)
    rectfill(82, 1, 126, 14, 0)
    rectfill(82, 37, 126, 62, 0)

    sspr(1, 80, 47, 48, 82, 72)
    sspr(1, 80, 47, 48, 81, 72)

    print_long(score, 84, 2, 5, _score_col)
    gprint("balls:", 84, 9, 10)
    gprint(balls, 122, 9, 10)
end

function init_title()
    show_stars = true
    show_credits = true
    f = 0
    off_y = 0
end

function update_title()
    rotate_stars()
    if btnp(3) or btnp(4) or btnp(5) then
        sfx(16)
        mode = modes.menu
        mode.init()
    end
end

function rotate_stars(_angle)
    stars = rotate_pnts(stars, vec(64, 150 + off_y / 2.5), _angle or -0.0005)
end

function draw_title()
    draw_title_foreground(off_y)

    if off_y == 0 and f % 60 > 20 then
        print_shadow("⬇️", 60, 110, 7, 1)
    end
end

function draw_title_foreground(_y_off)
    spr(112, 40, 30 + _y_off, 6, 2)
    spr(160, 40, 48 + _y_off, 6, 6)
end

function init_menu()
    show_stars = true
    show_credits = false
    f_base = f
    options = {{
        func = function()
            init_transition(modes.game)
        end,
        text = {"start"},
        base_y = 75
    }, {
        text = {"highscores"},
        base_y = 85,
        func = function()
            init_transition(modes.highscores)
        end
    }, {
        text = {"paddle controls:"},
        base_y = 95,
        func = function()
            pc_option = mod(pc_option + 1, #paddle_controls)
        end
    }}
    selected_option = 1
    pad_con = paddle_controls[pc_option]
end

function update_menu()
    off_y = max(-28, -(f - f_base))

    rotate_stars(-0.00025)

    if mode == modes.transition then
        return
    end

    update_menu_items()

    if selected_option == 3 then
        pc_option = mod(pc_option + tonum(btnp(1)) - tonum(btnp(0)), #paddle_controls)
    end

    pad_con = paddle_controls[pc_option]
end

function update_menu_items()
    if btnp(3) then
        selected_option = (selected_option % #options) + 1
        sfx(0)
    elseif btnp(2) then
        selected_option = selected_option-1 == 0 and #options or selected_option-1
        sfx(0)
    end

    if btnp(4) or btnp(5) then
        options[selected_option].func()
        sfx(13)
    end
end

function draw_menu()
    draw_title()
    print_version_credits()

    draw_menu_items(32, 28 + off_y, true)

    local _off_y_m4 = off_y * 4

    sspr(16, 44, 11, 11, 51, 214 + _off_y_m4)
    sspr(16, 44, 11, 11, 66, 214 + _off_y_m4, 11, 11, true)
    print_shadow(pad_con.ls, 52, 228 + _off_y_m4, 12, 1)
    print_shadow(pad_con.rs, 68, 228 + _off_y_m4, 12, 1)
    if selected_option == 3 then
        gprint(chr(22), 40.5 + sin(f / 60), 222.5 + _off_y_m4 + cos(f / 143), 7)
        gprint(chr(23), 84.5 + sin(f / 60), 222.5 + _off_y_m4 + cos(f / 143), 7)
    end
end

function init_launch()
    cur_pinball = create_pinball(vec(74, 75))

    if reset_light.lit then
        add(msgs, {
            "relaunch",
            t = 90
        })
        cur_pinball.spd = vec(0, -3.5)
    else
        balls = balls - 1
    end
    reset_light.lit = not reset_light.lit
    add(ongoing_msgs, launch_msg)
    released = false
    del(always_colliders, launch_block)

    refuel_lights_lit = -1
    light_refuel_lights()

    evt_disable_bonus({kickouts[2]})
    evt_disable_bonus({kickouts[3]})

    reset_drain(left_drain)
    reset_drain(right_drain)
    multiplier = 1
end

function update_launch()
    modes.game.update()

    launcher.origin.y = limit(launcher.origin.y + (tonum(btn(3)) - tonum(btn(2))) / 4, 80, 100)
    if (btn(3) or btn(2)) and f % 7 == 0 then
        sfx(22)
    end
    if cur_pinball.origin.y >= launcher.origin.y then
        cur_pinball.origin.y = launcher.origin.y - 0.51
        cur_pinball.last_pos.y = launcher.origin.y - 0.511
    end
    if btnp(4) or btnp(5) then
        sfx(8)
        if cur_pinball.origin.y > 78 then
            cur_pinball.spd.y = -sqrt(launcher.origin.y - 80)
            cur_pinball.origin.y = 78
        end
        launcher.origin.y = 80
    end
end

function init_game_over()
    end_flash_table(static_over)
    end_flash_table(static_under)
    options = {{
        text = {"play", "again"},
        func = quick_restart,
        base_y = 0
    }, {
        text = {"menu"},
        func = game_over_to_menu,
        base_y = 20
    }}

    selected_option = 1

    for i = 1, 10 do
        if is_bigger_long(score, highscores[i]) then
            score.c = 10
            add(highscores, score, i)
            del(highscores, #highscores)
            write_highscores()
            got_highscore = i
            return
        end
    end
    if got_highscore > 0 then
        sfx(16)
    else
        sfx(31)
    end
end

function update_game_over()
    update_menu_items()
end

function draw_game_over()
    local _fc = get_frame({10, 7, 12, 7}, f, 10)
    draw_table()
    draw_backboard(_fc)

    if f > 10000 then
        f = 0
    end

    local _lb = min(94, f * 2)

    -- TODO?
    --clip(81, 36, 47, _lb)

    rect(81, 36, 127, 36 + _lb, 5)
    rectfill(82, 37, 126, 126, 0)

    gprint("game over!", 84, 39, 10)

    draw_menu_items(90, 51)
    if got_highscore > 0 then
        gprint("new #" .. got_highscore, 84, 114, _fc)
        gprint("highscore!", 84, 120, _fc)
    end
    --clip()
end

function quick_restart()
    mode = modes.game
    mode.init()
end

function game_over_to_menu()
    init_transition(modes.menu)
end

function draw_menu_items(_x, _y_off, _i_multi)
    for i = 1, #options do
        local _o = options[i]
        local _y = _o.base_y
        if _i_multi then
            _y = _y + _y_off * (i * 2)
        else
            _y = _y + _y_off
        end
        if selected_option == i then
            gprint(chr(23), _x - 5.5 + sin(f / 60), _y + (3 * (#_o.text - 1)), 8)
            local _yo = 0
            for _text in all(_o.text) do
                print_shadow(_text, _x, _y + _yo, 7, 8)
                _yo = _yo + 6
            end
        else
            local _yo = 0
            for _text in all(_o.text) do
                gprint(_text, _x, _y + _yo, 7)
                _yo = _yo + 6
            end
        end
    end
end

function init_logo()
    stars = {}
    for i = 1, 400 do
        local star = vec(flr(rnd(400)) - 136, flr(rnd(400)) - 66)
        star.c = rnd(split("12,7,6,5,13,15,1"))
        add(stars, star)
    end

    show_stars = true
    show_credits = true

    off_y = 0

    modes.title.init()
end

function draw_logo()
    local max_col = limit(flr(f / 4) + 1, 0, 6)

    if f == 90 then
        init_transition(modes.title)
    elseif f < 90 then
        -- for grad in all(col_grads) do
        --     for i = 1, 6 do
        --         pal(grad[i], grad[min(i, max_col)])
        --     end
        -- end
    end

    spr(68, 29, 56, 2, 2)

    print_shadow("spaghettieis", 47, 59, 7, 8)
    print_shadow("games", 47, 65, 7, 8)
end

function print_version_credits()
    gprint("v " .. version, 2, 2 + off_y, 13)
    gprint("by matt sutton", 71, 2 + off_y, 13)
    gprint("@xietanu", 95, 10 + off_y, 13)
end

function init_transition(_next_state)
    next_state = _next_state
    transitioning = true
    t = -1

    update_transition()
end

function update_transition()
    t = t + 1
    if t == 30 then
        mode = next_state
        mode.init()
    elseif t >= 60 then
        transitioning = false
        return
    end

    max_col = limit(flr(abs(30 - t) / 4), 0, 6)
end

function draw_transition()
    -- for grad in all(col_grads) do
    --     for i = 1, 6 do
    --         pal(grad[i], grad[min(i, max_col)])
    --     end
    -- end
end

function init_highscores()
    reset_highscores_cnt = 0
end

function update_highscores()
    rotate_stars()
    if btnp(4) then
        init_transition(modes.menu)
    end
    if btn(5) then
        reset_highscores_cnt = reset_highscores_cnt + 0.5
        if reset_highscores_cnt >= 61 then
            gen_highscores()
            read_highscores()
            reset_highscores_cnt = 0
        end
    else
        reset_highscores_cnt = 0
    end
end

function draw_highscores()
    print_shadow("highscores", 44, 3, 7, 8)
    for i = 1, 10 do
        gprint(i .. ".", 35, 10 * i + 2, 12)
        print_long(highscores[i], 50, 10 * i + 2, 5, highscores[i].c)
    end
    print_shadow("X: back", 7, 114, 7, 13)
    if reset_highscores_cnt > 0 then
        rectfill(62, 112, 61 + reset_highscores_cnt, 120, 8)
    end
    print_shadow("hold C: reset", 64, 114, 7, 13)
end

-- components
function init_flippers()
    -- initialize flippers
    flippers = {create_flipper(vec(29.5, 118.5), pad_con.l, false, shift_light_left),
                create_flipper(vec(50.5, 118.5), pad_con.r, true, shift_light_right)}
end

function create_flipper(_origin, _button, _flip_x, _shift_light)
    -- create a flipper
    local _flip = 1
    local _base_angle = 0
    local _spr_off = vec(-1, -5)
    if _flip_x then
        _spr_off.x = -9
        _flip = -_flip
        _base_angle = 0.5
    end
    local _f = {
        origin = _origin,
        simple_collider = create_box_collider(-7 + 5 * _flip, -6, 7 + 5 * _flip, 6),
        collider_base = gen_polygon("-2,-1,-1,-2,9.5,-1,10.5,0,9.5,1,-1,2,-2,1"),
        check_collision = check_collision_with_flipper,
        spr_off = _spr_off,
        angle = 0,
        angle_inc = 0.07,
        button = _button,
        moving = 0,
        bounce_frames = 0,
        c = 12,
        flip_x = _flip_x,
        flip = _flip,
        complete = true,
        shift_light = _shift_light
    }
    _f.collider = _f.collider_base

    return _f
end

function update_flipper(_f)
    -- update flipper each frame
    if btn(_f.button) then
        if _f.angle < 0.09 then
            _f.moving = 1
        else
            _f.moving = 0
        end
    else
        if _f.angle > -0.09 then
            _f.moving = -1 / 3
        else
            _f.moving = 0
        end
    end

    if btnp(_f.button) then
        _f.shift_light(top_rollovers.elements)
        sfx(0)
    end

    return ceil(_f.moving * 5)
end

function update_flipper_pos(_f, _dt)
    -- update the position of the
    -- flipper each time the
    -- physics sim is updated
    if _f.moving ~= 0 then
        _f.angle = limit(_f.angle + _f.moving * _f.angle_inc / _dt, -0.09, 0.09)
        update_flipper_collider(_f)
    end
end

function check_collision_with_flipper(_f, _pin)
    -- check collision with line
    -- segments of flipper
    if _f.moving == 0 then
        check_collision_with_collider(_f, _pin)
        return
    end

    if point_collides_poly(_pin.origin, _f) then
        local _flp_spd = 2 * _f.moving * dist_between_vectors(_f.origin, _pin.origin) * sin(-_f.angle_inc)
        local _flp_spd_vec = vec(_f.flip * _flp_spd * sin(-_f.angle + .035), _flp_spd * cos(_f.angle - .035))
        rollback_pinball_pos(_pin)
        _f.angle = limit(_f.angle - _f.moving * _f.angle_inc / dt, -0.09, 0.09)
        _pin.spd = _pin.spd:plus(_flp_spd_vec)
        update_flipper_collider(_f)
        _f.moving = 0
        update_pinball_pos(_pin, dt)
    end
end

function update_flipper_collider(_f)
    -- update the vertex points
    -- based on the angle of the
    -- flipper.
    local _ang = _f.angle
    if _f.flip_x then
        _ang = 0.5 - _ang
    end
    _f.collider = rotate_pnts(_f.collider_base, vec(0, 0), _ang)
end

function draw_flipper(_f)
    -- draw a flipper
    local i = 4 - flr(4.99 * (_f.angle + 0.09) / 0.18)

    -- if draw_outlines then
    --  draw_collider(_f)
    -- end

    sspr(16, 0 + 11 * i, 11, 11, _f.origin.x + _f.spr_off.x, _f.origin.y + _f.spr_off.y, 11, 11, _f.flip_x)
end

function init_walls()
    -- initialize outer walls

    wall_groups = { -- right side
    "50,127,64,113,64,119,65,122,66,119,66,88,63,85,67,81,63,70,69,60,69,57,67,57,62,61,53,47,53,46,56,43,62,41,68,38,72,34",
    -- left/top side
    "75,27,75,21,71,14,64,7,54,2,48,1,34,1,26,3,18,7,13,12,10,17,9,26,10,37,14,47,9,55,9,58,16,62,16,63,12,81,16,85,13,88,13,119,14,121,15,119,15,113,29,127",
    -- inner curve right
    "61,25,61,22,58,19,54,19,54,14,60,15,66,18,68,21,68,25,66,28,59,34,58,32,61,25", -- inner curve left
    "24,43,18,37,14,28,14,25,17,18,22,13,24,12,24,16,26,16,26,19,20,25,20,33,25,43,24,43",
    -- lower right floating corner
    "48,122,64,106,64,93,63,92,61,94,61,105,53,112,48,117.5,48,122", -- lower left floating corner
    "31,122,15,106,15,93,16,92,18,94,18,105,26,112,31,117.5,31,122", -- narrow walls
    "30,15,31,14,32,15,32,18,31,19,30,18,30,15", "36,15,37,14,38,15,38,18,37,19,36,18,36,15",
    "42,15,43,14,44,15,44,18,43,19,42,18,42,15", "48,15,49,14,50,15,50,18,49,19,48,18,48,15"}
    for wall_group in all(wall_groups) do
        local _pnts = gen_polygon(wall_group)
        local _wall_list = {}
        for i = 2, #_pnts do
            local _poly = {_pnts[i - 1], _pnts[i]}
            add(_wall_list, _poly)
        end
        for wall_col in all(_wall_list) do
            add(static_colliders, {
                origin = vec(0.5, 0.5),
                collider = wall_col,
                simple_collider = gen_simple_collider(wall_col),
                check_collision = check_collision_with_collider
            })
        end
    end
end

function create_pinball(_pos)
    -- create a pinball
    local _p = {
        origin = _pos,
        last_pos = _pos:copy(),
        spd = vec(0, 0),
        spd_mag = 0,
        simple_collider = create_box_collider(-1.5, -1.5, 1.5, 1.5),
        check_collision = check_collision_with_pinball,
        captured = false,
        trackers = {}
    }
    add(pinballs, _p)
    return _p
end

function update_pinball_spd_acc(_pin)
    _pin.spd = _pin.spd:multiplied_by(0.995)
    _pin.spd.y = _pin.spd.y + 0.03
    _pin.spd_mag = _pin.spd:magnitude()

    local _dt = min(ceil(_pin.spd_mag), 4)

    return _dt
end

function update_pinball_pos(_pin, _dt)
    if _pin.captured then
        return
    end

    _pin.last_pos = _pin.origin:copy()

    if _pin.spd_mag > _dt then
        _pin.origin = _pin.origin:plus(_pin.spd:normalize())
    else
        _pin.origin = _pin.origin:plus(_pin.spd:multiplied_by(1 / _dt))
    end

    if _pin.origin.y > 140 or _pin.origin.y < 0 or _pin.origin.x < 2 or _pin.origin.x > 78 then
        del(pinballs, _pin)
        if blastoff_mode then
            evt_add_blastoff_ball()
        end
    else
        for _col_grp in all({collision_regions[flr(_pin.origin.x / 16) + 1][flr(_pin.origin.y / 16) + 1],
                             always_colliders, flippers, pinballs}) do
            for _sc in all(_col_grp) do
                if _pin ~= _sc then
                    check_collision(_pin, _sc)
                end
            end
        end
        if #_pin.trackers == 0 then
            add_tracker(_pin)
        elseif not pos_are_equal(_pin.origin, _pin.trackers[#_pin.trackers]) then
            add_tracker(_pin)
        end
    end
end

function add_tracker(pinball)
    add(pinball.trackers, {
        x = pinball.origin.x,
        y = pinball.origin.y,
        l = 7
    })
end

function rollback_pinball_pos(_pin)
    _pin.origin = _pin.last_pos
end

function draw_pinball(_pin)
    sspr(29, 0, 3, 3, _pin.origin.x - 1, _pin.origin.y - 1)
end

function check_collision_with_pinball(_pin1, _pin2)
    if dist_between_vectors(_pin1.origin, _pin2.origin) <= 3 then
        if not _pin1.captured then
            rollback_pinball_pos(_pin1)
        end
        if not _pin2.captured then
            rollback_pinball_pos(_pin2)
        end

        local perp_vec = _pin1.origin:minus(_pin2.origin):normalize()

        local u1 = perp_vec:dot(_pin1.spd)
        local u2 = perp_vec.x * _pin1.spd.y - perp_vec.y * _pin1.spd.x
        local u3 = perp_vec:dot(_pin2.spd)
        local u4 = perp_vec.x * _pin2.spd.y - perp_vec.y * _pin2.spd.x

        _pin2.spd.x = perp_vec.x * u1 - perp_vec.y * u4
        _pin2.spd.y = perp_vec.y * u1 + perp_vec.x * u4
        _pin1.spd.x = perp_vec.x * u3 - perp_vec.y * u2
        _pin1.spd.y = perp_vec.y * u3 + perp_vec.x * u2

    end
end

function init_round_bumpers()
    -- initialise circular bumpers
    r_bumpers = {create_round_bumper(vec(42, 28), 1), create_round_bumper(vec(51, 34), 4),
                 create_round_bumper(vec(29, 30), 3), create_round_bumper(vec(37, 38), 2)}
    for _rb in all(r_bumpers) do
        add(static_colliders, _rb)
        add(static_over, _rb)
    end
end

function create_round_bumper(_origin, _spr_i)
    -- create a round bumper
    return {
        origin = _origin,
        simple_collider = {
            x1 = -5,
            y1 = -5,
            x2 = 5,
            y2 = 5
        },
        spr_off = vec(-4, -4),
        spr_coords = vec(0, 8 * _spr_i),
        draw = draw_spr,
        spr_w = 8,
        spr_h = 8,
        hit = 0,
        check_collision = check_collision_with_r_bumper
    }
end

function check_collision_with_r_bumper(_b, _pin)
    -- check for collision with the
    -- bumper
    if dist_between_vectors(_b.origin, _pin.origin) <= 4.5 then
        increase_score(751)
        planet_lights_lit = planet_lights_lit + 0.35
        sfx(planet_lights_lit)
        _b.hit = 8
        local normalized_perp_vec = _pin.origin:minus(_b.origin):normalize()
        rollback_pinball_pos(_pin)
        _pin.spd = calc_reflection_vector(_pin.spd, normalized_perp_vec)
        _pin.spd = _pin.spd:plus(normalized_perp_vec:multiplied_by(0.375))
    end
end

function set_planet_lights()
    if planet_lights_lit >= 10 then
        add(ongoing_msgs, planet_msg)
        light_orbit(4)
        add(msgs, {
            "star system",
            "mapping",
            "complete!",
            t = 120
        })
        increase_score(500, 1)
        planet_lights_lit = 0.75
        flash_table(planet_lights, 2, false)
        sfx(10)
        return
    end
    update_prog_light_group(planet_lights, planet_lights_lit)
end

function init_poly_bumpers()
    -- create polyginal bumpers
    spaceship = create_poly_bumper(vec(29, 55), gen_polygon("-1,3,6,0,17,-1,14,2,14,4,17,7,6,6"), vec(0, 48), 16, 7,
        false, vec(32, 48))
    spaceship.collider[1] = vec(-1, 3, 1, 543, false, 13)
    spaceship.collider[2] = vec(6, 0, 1, 543, false, 13)

    local _wall_col = gen_polygon("75,27,72,34")
    launch_block = {
        origin = vec(0.5, 0.5),
        collider = _wall_col,
        simple_collider = gen_simple_collider(_wall_col),
        check_collision = check_collision_with_collider
    }

    left_drain_block = create_poly_bumper(vec(16.5, 110.5), gen_polygon("-1,-5,-1,6"), vec(36, 5), 1, 3)
    right_drain_block = create_poly_bumper(vec(63.5, 110.5), gen_polygon("1,-5,1,6"), vec(36, 5), 1, 3)
    add(always_colliders, left_drain_block)
    add(static_over, left_drain_block)
    add(always_colliders, right_drain_block)
    add(static_over, right_drain_block)

    left_drain = create_poly_bumper(vec(13.5, 112.5), gen_polygon("0,-1,2,1"), vec(32, 5), 3, 4, true)
    left_drain.light = left_drain_light
    left_drain.block = left_drain_block

    right_drain = create_poly_bumper(vec(64.5, 112.5), gen_polygon("2,-1,0,1"), vec(32, 5), 3, 4, false)
    right_drain.light = right_drain_light
    right_drain.block = right_drain_block

    poly_bumpers = { -- spaceship
    spaceship, -- left bumper
    create_poly_bumper(vec(51.5, 95.5), gen_polygon("4,-1,6,1,6,11,1,14,-1,13,2,1"), vec(8, 0), 8, 14, false, vec(40, 4)),
    -- right bumper
    create_poly_bumper(vec(21.5, 95.5), gen_polygon("5,1,8,13,6,14,1,11,1,1,3,-1"), vec(8, 0), 8, 14, true, vec(40, 4)),
    -- right gutter pin
    create_poly_bumper(vec(64.5, 120.5), {vec(0, 0, 2.1, 0, true, 13), vec(2, 0)}, vec(43, 0), 3, 2, false, nil,
        close_right_drain), -- left gutter pin
    create_poly_bumper(vec(13.5, 120.5), {vec(0, 0, 2.1, 0, true, 13), vec(2, 0)}, vec(43, 0), 3, 2, false, nil,
        close_left_drain)}
    poly_bumpers[2].collider[5] = vec(-1, 13, 1, 543, false, 13)
    poly_bumpers[3].collider[1] = vec(5, 1, 1, 543, false, 13)

    add_group_to_board(poly_bumpers, {static_colliders, static_over})
end

function create_poly_bumper(_origin, _collider, _spr, _spr_w, _spr_h, _flip_x, _spr_hit_coords, _action)
    -- create a polyginal bumper
    _spr_w, _spr_h = _spr_w or 1, _spr_h or 1
    return {
        origin = _origin,
        simple_collider = gen_simple_collider(_collider),
        collider = _collider,
        spr_off = vec(0, 0),
        spr_coords = _spr,
        hit_spr_coords = _spr_hit_coords,
        r = 4,
        draw = draw_spr,
        check_collision = check_collision_with_collider,
        spr_w = _spr_w,
        spr_h = _spr_h,
        flip_x = _flip_x,
        complete = true,
        hit = 0,
        c = 7,
        action = _action
    }
end

function close_left_drain()
    reset_drain(left_drain)
    add_to_queue(evt_close_drain, 30, {left_drain})
end

function close_right_drain()
    reset_drain(right_drain)
    add_to_queue(evt_close_drain, 30, {right_drain})
end

function evt_close_drain(_d)
    local _d=_d[1]
    if _d.light.lit then
        add(static_over, _d)
        add(always_colliders, _d)
        del(static_over, _d.block)
        del(always_colliders, _d.block)
        _d.light.lit = false
    end
end

function reset_drain(_d)
    if not _d.light.lit then
        del(static_over, _d)
        del(always_colliders, _d)
        add(static_over, _d.block)
        add(always_colliders, _d.block)
        _d.light.lit = true
    end
end

function init_targets()
    -- initialize targets
    skillshot_target = create_target(vec(24.5, 13.5), gen_polygon("-1,-0.5,2.5,0.5,2.5,4,-1,4"), nil, vec(40, 0), 2, 4)
    skillshot_target.p = nil
    skillshot_target.sfx = nil
    skillshot_target.check_collision = check_collision_with_skillshot
    add(static_colliders, skillshot_target)
    add(static_over, skillshot_target)
    local left_col = gen_polygon("0,-1,3,0,2,5,-1,5")
    left_light_offset = vec(4, 3)
    left_targets = {
        elements = {create_target(vec(12.5, 76.5), left_col, left_light_offset, vec(32, 0), 3, 5),
                    create_target(vec(13.5, 70.5), left_col, left_light_offset, vec(32, 0), 3, 5),
                    create_target(vec(15.5, 63.5), left_col, left_light_offset, vec(32, 0), 3, 5)},
        all_lit_action = left_targets_lit,
        sfx = 15
    }
    add_target_group_to_board(left_targets)

    right_target_poly = gen_polygon("3,5,1.5,5,-0.5,1,1,-1")
    right_light_offset = vec(-3, 3)

    right_targets = {
        elements = {create_target(vec(53.5, 47.5), right_target_poly, right_light_offset, vec(42, 18), 3, 5),
                    create_target(vec(64.5, 74.5), right_target_poly, right_light_offset, vec(42, 18), 3, 5)},
        all_lit_action = right_targets_lit,
        sfx = 15
    }
    add_target_group_to_board(right_targets)

    h_target_poly = gen_polygon("-1,-1,5,-1,4,3,-1,2")
    h_light_offset = vec(0, 4)

    rocket_targets = {
        elements = {create_target(vec(38.5, 61.5), h_target_poly, h_light_offset, vec(32, 18), 5, 3),
                    create_target(vec(32.5, 60.5), h_target_poly, h_light_offset, vec(32, 18), 5, 3)},
        all_lit_action = pass,
        sfx = 15
    }
    add_target_group_to_board(rocket_targets)

end

function add_target_group_to_board(_grp, _draw_layer)
    for _t in all(_grp.elements) do
        _t.group = _grp
        add(static_colliders, _t)
        add(_draw_layer or static_over, _t)
    end
end

function create_target(_origin, _collider, _light_offset, _unlit_spr, _spr_w, _spr_h)
    local _l = {
        origin = _origin,
        simple_collider = gen_simple_collider(_collider),
        check_collision = check_collision_with_target,
        collider = _collider,
        draw = draw_spr,
        hit = 0,
        c = 7,
        lit = false,
        complete = true,
        spr_coords = _unlit_spr,
        hit_spr_coords = _unlit_spr:plus(vec(_spr_w, 0)),
        spr_off = vec(0, 0),
        spr_w = _spr_w,
        spr_h = _spr_h,
        p = 1212,
        sfx = 14
    }
    if _light_offset then
        _l.light = create_light(_origin:plus(_light_offset), nil, draw_dot_light)
        add(static_under, _l.light)
    end
    return _l
end

function check_collision_with_target(_obj, _pin)
    -- action to take if pinball
    -- hits the target
    if check_collision_with_collider(_obj, _pin) then
        _obj.lit = true
        if _obj.group then
            group_elem_lit(_obj.group)
        end
        if _obj.light.flashing then
            target_hunt_cnt = target_hunt_cnt + 1
            update_prog_light_group(pent_lights, target_hunt_cnt)
            add_to_queue(evt_end_target_hunt, 1800, {true})
            if target_hunt_cnt >= 5 then
                evt_end_target_hunt()
                increase_score(500, 1)
                light_orbit(5)
                evt_cycle_lights({pent_lights, 1, 3, 10, true})
            else
                repeat
                    flash_rnd_target()
                until cur_target ~= _obj
            end
        end
    end
end

function check_collision_with_skillshot(_t, _pin)
    if check_collision_with_collider(_t, _pin) and _t.bonus_enabled then
        increase_score(250, 1)
        add(msgs, {
            "skillshot!",
            t = 90
        })
        evt_disable_bonus({_t})
        _t.hit = 7
        sfx(10)
    end
end

function left_targets_lit(_g)
    reset_drain(left_drain)
    rollovers_all_lit(_g)
    sfx(15)
end

function right_targets_lit(_g)
    reset_drain(right_drain)
    rollovers_all_lit(_g)
    sfx(15)
end

function init_spinners()
    -- create spinner
    spinner = {
        origin = vec(11.5, 26.5),
        simple_collider = {
            x1 = -2,
            y1 = -5,
            x2 = 2,
            y2 = 4
        },
        check_collision = check_collision_with_spinner,
        draw = draw_spinner,
        update = update_spinner,
        to_score = 0
    }
    add(static_colliders, spinner)
    add(static_over, spinner)
end

function draw_spinner()
    -- draw spinner animation frame
    local spr_i = 33 + 16 * flr((spinner.to_score / 50) % 4)
    spr(spr_i, spinner.origin.x - 3, spinner.origin.y - 4)
end

function check_collision_with_spinner(_s, _pin)
    -- check collision with spinner
    if spinner.deactivated then
        return
    end
    spinner.to_score = max(spinner.to_score, flr(min(6.123, abs(_pin.spd.y)) * 2000))
    if _pin.spd.y < 0 and not kickouts[2].bonus_enabled then
        sfx(23, 3)
        enable_bonus(kickouts[2], 180)
        evt_cycle_lights({spinner_lights, 1, 3, flr(60 / #spinner_lights)})
    end
    spinner.deactivated = true
    add_to_queue(evt_reactivate, 30, {spinner})
end

function update_spinner()
    -- update spinner each frame
    if spinner.to_score > 0 then
        if f % ceil(10000 / spinner.to_score) == 0 then
            sfx(22)
        end
        local scr_change = min(spinner.to_score, max(10, flr(spinner.to_score * 0.02)))
        spinner.to_score = spinner.to_score - scr_change
        increase_score(scr_change)
    end
end

function init_rollovers()
    -- initialize rollovers
    top_rollovers = {
        elements = {},
        all_lit_action = increase_multi,
        sfx = 25
    }
    for i = 0, 4 do
        add(top_rollovers.elements, create_rollover(28.5 + 6 * i, 15.5))
    end
    bottom_rollovers = {
        elements = {create_rollover(14.5, 95.5, hit_refuel_rollover), create_rollover(20.5, 97.5, hit_refuel_rollover),
                    create_rollover(65.5, 95.5, hit_refuel_rollover), create_rollover(59.5, 97.5, hit_refuel_rollover)},
        all_lit_action = rollovers_all_lit,
        sfx = 27
    }
    add_target_group_to_board(top_rollovers, static_under)
    add_target_group_to_board(bottom_rollovers, static_under)
end

function create_rollover(_x, _y, _action)
    -- create a rollover
    return {
        origin = vec(_x, _y),
        simple_collider = {
            x1 = -2,
            y1 = 0,
            x2 = 2,
            y2 = 3
        },
        draw = draw_spr,
        check_collision = check_collision_with_rollover,
        spr_coords = vec(37, 0),
        spr_w = 3,
        spr_h = 8,
        spr_off = vec(-1, 0),
        unlit_col = 4,
        hit = 0,
        action = _action
    }
end

function evt_set_light(args)
    local _r, _lit=args[1],args[2]
    -- set light status for an element
    _r.lit = _lit
end

function check_collision_with_rollover(_r, _pin)
    -- action to trigger when box
    -- collider is triggered
    if _r.deactivated then
        return
    end
    if not _r.lit then
        sfx(26)
    end
    evt_set_light({_r, true})
    if _r.group then
        group_elem_lit(_r.group)
    end

    _r.deactivated = true
    add_to_queue(evt_reactivate, 20, {_r})
    increase_score(1234)
    if _r.action ~= nil then
        _r.action(_r, _pin)
    end
end

function rollovers_all_lit(_rg)
    -- action for when rollover
    -- group's lights all lit.
    increase_score(50, 1)
    for _r in all(_rg.elements) do
        evt_set_light({_r, false})
    end
end

function hit_refuel_rollover(_r, _pin)
    if _pin.spd.y > 0 then
        light_refuel_lights()
    end
end

function increase_multi(_rg)
    light_orbit(3)
    if multiplier < 4 then
        add(msgs, {
            "multiplier",
            "increased!",
            t = 120
        })
    end
    multiplier = min(4, multiplier + 1)
    rollovers_all_lit(_rg)
end

function group_elem_lit(_grp)
    if _grp.deactivated then
        return
    end
    for _r in all(_grp.elements) do
        if not _r.lit then
            return
        end
    end
    sfx(_grp.sfx)

    flash_table(_grp.elements, 2, false)

    _grp.deactivated = true
    add_to_queue(evt_reactivate, 65, {_grp})

    _grp:all_lit_action()
end

function shift_light_left(_r)
    -- shift lit status to the left
    shift_light(_r, -1)
end

function shift_light(_r, _dir)
    local _cpy = {}
    for i in all(_r) do
        add(_cpy, i.lit or false)
    end
    for i = 1, #_r do
        _r[mod(i + _dir, #_r)].lit = _cpy[i]
    end
end

function shift_light_right(_r)
    -- shift lit status to the right
    shift_light(_r, 1)
end

function add_group_to_board(_grp, _layers)
    for _el in all(_grp) do
        for _l in all(_layers) do
            add(_l, _el)
        end
    end
end

function init_kickouts()
    -- initialise the capture
    -- elements on the board.
    blastoff_msg = {"blast-off!", "multiball!"}
    target_hunt_msg = {"calibrate", "lasers!", "hit targets!"}

    kickouts = { -- target hunt capture
    create_capture(vec(68.5, 58.5), vec(-1, 1), 1111, start_target_hunt), -- escape velocity capture
    create_capture(vec(11.5, 56.5), vec(1, 0), 1111, escape_velocity_action), -- rocket fuel capture
    create_capture(vec(45.5, 58.5), vec(0.4, 0.4), 0, empty_fuel_action)}
    add_group_to_board(kickouts, {static_under, static_colliders})
end

function create_capture(_origin, _eject_vector, _points, _action)
    return {
        origin = _origin,
        simple_collider = create_box_collider(-1.5, -1.5, 1.5, 1.5),
        output_vector = _eject_vector,
        draw = draw_capture,
        check_collision = check_collision_with_capture,
        action = _action,
        p = _points
    }
end

function check_collision_with_capture(_cap, _pin)
    -- action to take when pinball
    -- collides with box collider.
    if _cap.captured_pinball ~= nil or _cap.deactivated then
        return
    end
    _pin.captured = true
    _pin.origin = vec(_cap.origin.x, _cap.origin.y)

    _pin.spd = vec(0, 0)
    _cap.captured_pinball = _pin
    _cap.deactivated = true
    increase_score(_cap.p)
    if _cap.action ~= nil then
        _cap:action()
    end
    add_to_queue(evt_eject_captured, 90, {_cap})
end

function evt_eject_captured(_cap)
    -- eject the ball
    local _cap=_cap[1]
    _cap.captured_pinball.spd = _cap.output_vector:copy()
    _cap.captured_pinball.captured = false
    _cap.captured_pinball = nil
    _cap.bonus_timer = 0
    evt_disable_bonus({_cap})
    add_to_queue(evt_reactivate, 30, {_cap})
end

function draw_capture(_cap)
    local _bc = 0
    if _cap.deactivated then
        _bc = 5
    end
    circfill(_cap.origin.x, _cap.origin.y, 2, _bc)
    _c = 4
    if _cap.lit then
        _c = 10
    end
    circ(_cap.origin.x, _cap.origin.y, 2, _c)
end

function escape_velocity_action(_cap)
    if not _cap.bonus_enabled then
        sfx(24)
        return
    end
    increase_score(50, 1)
    add(msgs, {
        "slingshot!",
        t = 90
    })
    light_orbit(1)
    sfx(10, 3)
end

function empty_fuel_action(_cap)
    -- action for when fuel capture
    -- triggered.
    if blastoff_mode then
        increase_score(50, 1)
        sfx(24)
        return
    end

    increase_score(3 ^ min(5, refuel_lights_lit), 1)
    if refuel_lights_lit >= #refuel_lights then
        light_orbit(2)
        blastoff_mode = true
        kickouts[2].deactivated = true
        reset_light.lit = true
        add(ongoing_msgs, blastoff_msg)
        sfx(29, 1)
        evt_flash({_cap, -99, false})
        evt_cycle_lights({refuel_lights, 1, 30, 10, true})
        evt_add_blastoff_ball()
        add_to_queue(evt_add_blastoff_ball, 60)
        add_to_queue(evt_end_blastoff_mode, 1200)
    elseif refuel_lights_lit > 0 then
        add(msgs, {
            "partial",
            "refuel",
            t = 90
        })
        evt_flash({_cap, 3, false})
        flash_table(refuel_lights, 3, false, true)
        sfx(24)
    else
        sfx(24)
    end
    refuel_lights_lit = 0
end

function evt_add_blastoff_ball()
    local _cap = kickouts[2]
    _p = create_pinball(_cap.origin:copy())
    _p.spd = _cap.output_vector:copy()
end

function evt_end_blastoff_mode()
    local _cap = kickouts[2]
    if not blastoff_mode then
        return
    end
    blastoff_mode = false
    reset_light.lit = false
    evt_reactivate({_cap})
    del(ongoing_msgs, blastoff_msg)
    end_flash(_cap, false)
    end_flash_table(refuel_lights, false)
end

function start_target_hunt()
    add_to_queue(evt_end_target_hunt, 1800, {true})
    sfx(28)
    if not target_hunt then
        add(ongoing_msgs, target_hunt_msg)
        flash_rnd_target()
        target_hunt = true
        target_hunt_cnt = 0
    end
end

function flash_rnd_target()
    if cur_target then
        end_flash(cur_target.light)
        cur_target.sfx = 14
    end
    local _rn = flr(rnd(3))
    local _t = nil
    if _rn == 0 then
        _t = rnd(left_targets.elements)
    elseif _rn == 1 then
        _t = rnd(right_targets.elements)
    else
        _t = rnd(rocket_targets.elements)
    end
    evt_flash({_t.light, -99})
    _t.sfx = 28
    cur_target = _t
end

function evt_end_target_hunt(_timeout)
    if not target_hunt then
        return
    end
    del(ongoing_msgs, target_hunt_msg)
    target_hunt = false
    if _timeout and _timeout[1] then
        sfx(30, 2)
        target_hunt_cnt = 0
        update_prog_light_group(pent_lights, target_hunt_cnt)
    end
    if cur_target then
        end_flash(cur_target.light)
        cur_target.sfx = 14
        cur_target = nil
    end
end
function init_lights()
    -- initialise decorative lights
    refuel_lights_lit = 0

    chevron_light_spr = create_light_spr(vec(32, 9))
    up_chevron_light_spr = create_light_spr(vec(35, 12))
    h_chevron_light_spr = create_light_spr(vec(35, 9))
    small_up_right_chevron_spr = create_light_spr(vec(33, 12), 2, 2)
    big_up_right_chevron_spr = create_light_spr(vec(32, 12))
    orbit_lights = {}
    for i = 1, 5 do
        add(orbit_lights, create_light(vec(27 + i * 4, 93), sub("orbit", i, i), draw_letter_light))
    end

    add_group_to_board(orbit_lights, {static_under})

    pent_lights = {}
    for i = 0, 0.8, 0.2 do
        add(pent_lights, create_light(vec(64.5 - sin(i) * 4, 48.5 - cos(i) * 4), nil, draw_dot_light))
    end
    add_group_to_board(pent_lights, {static_under})

    left_drain_light = create_light(vec(13, 108), chevron_light_spr, draw_spr)
    left_drain_light.lit = true
    add(static_under, left_drain_light)
    right_drain_light = create_light(vec(64, 108), chevron_light_spr, draw_spr)
    right_drain_light.lit = true
    add(static_under, right_drain_light)

    spinner_lights = {create_light(vec(16, 27), up_chevron_light_spr, draw_spr),
                      create_light(vec(16, 24), up_chevron_light_spr, draw_spr),
                      create_light(vec(17, 22), small_up_right_chevron_spr, draw_spr),
                      create_light(vec(18, 20), big_up_right_chevron_spr, draw_spr),
                      create_light(vec(20, 18), big_up_right_chevron_spr, draw_spr)}
    for i = 0, 3 do
        add(spinner_lights, create_light(vec(20 - i, 36 - i * 2), vec(20 - i, 37 - i * 2), draw_line_light), i + 1)
    end

    add_group_to_board(spinner_lights, {static_under})

    refuel_lights = {}
    for i = 0, 3 do
        add(refuel_lights, create_light(vec(47 + i * 3, 57), h_chevron_light_spr, draw_spr))
    end
    add_group_to_board(refuel_lights, {static_under})

    reset_light = create_light(vec(39, 125), nil, draw_dot_light)
    add(static_under, reset_light)

    planet_lights = {}
    for i = 1, 10 do
        local _x = 65 - abs(5.5 - i) / 2
        add(planet_lights, create_light(vec(_x, 29 - i), vec(_x + 1, 29 - i), draw_line_light))
    end
    add_group_to_board(planet_lights, {static_under})
end

function create_light(_origin, _config, _draw, _off_col, _lit_col)
    -- create light object
    local _l = {
        origin = _origin,
        config = _config,
        off_col = _off_col or 4,
        lit_col = _lit_col or 10,
        draw = _draw,
        lit = false,
        spr_off = vec(0, 0)
    }
    if _draw == draw_spr then
        for k, v in pairs(_config) do
            _l[k] = v
        end
    end
    return _l
end

function draw_line_light(_l)
    -- draw a line-like light
    local _c = _l.off_col
    if _l.lit then
        _c = _l.lit_col
    end
    line(_l.origin.x, _l.origin.y, _l.config.x, _l.config.y, _c)
end

function draw_letter_light(_l)
    local _c = _l.off_col
    if _l.lit then
        _c = _l.lit_col
    end
    gprint(_l.config, _l.origin.x, _l.origin.y, _c)
end

function draw_dot_light(_l)
    local _c = _l.off_col
    if _l.lit then
        _c = _l.lit_col
    end
    rect(_l.origin.x, _l.origin.y, _l.origin.x + 1, _l.origin.y + 1, _c)
end

function create_light_spr(_spr_coord, _w, _h)
    return {
        spr_coords = _spr_coord,
        unlit_col = 4,
        spr_w = _w or 3,
        spr_h = _h or 3,
        hit = 0
    }
end

function light_refuel_lights()
    -- action for progressive
    -- lighting of refuel lights.
    -- lights a light each time
    -- it's triggered.
    if #pinballs > 1 then
        return
    end
    refuel_lights_lit = refuel_lights_lit + 1
    if refuel_lights_lit >= #refuel_lights then
        evt_flash({kickouts[3], -99, true})
    end
    update_prog_light_group(refuel_lights, refuel_lights_lit)
end

function update_prog_light_group(_grp, _n)
    for i = 1, #_grp do
        _grp[i].lit = _n >= i
    end
end

function evt_cycle_lights(args)
    local _group, _next_index, _times, _delay, _rev = args[1],args[2],args[3],args[4],args[5]
    _group[mod(_next_index - 1, #_group)].lit = _rev

    if _next_index > #_group * _times then
        if _rev then
            evt_cycle_lights({_group, 2, 1, _delay})
        else
            end_flash_table(_group)
        end
        return
    end

    _group[mod(_next_index, #_group)].lit = not _rev
    add_to_queue(evt_cycle_lights, _delay, {_group, _next_index + 1, _times, _delay, _rev})
end

function light_orbit(i)
    evt_flash({orbit_lights[i], 3, true})
    local _cnt = 0
    for _l in all(orbit_lights) do
        if _l.lit or _l.flashing then
            _cnt = _cnt + 1
        end
    end
    if _cnt == 5 then
        add(msgs, {
            "orbit",
            "achieved!",
            "extra ball!",
            t = 120
        })
        sfx(16)
        increase_score(2500, 1)
        balls = balls + 1
        flash_table(orbit_lights, 3, false)
    end
end

function init_launcher()
    local _col = gen_polygon("-1,-0.5,3,-0.5")
    launcher = {
        origin = vec(73, 78),
        collider = _col,
        simple_collider = gen_simple_collider(_col),
        complete = false,
        check_collision = check_collision_with_collider,
        draw = draw_launcher,
        c = 7
    }
    add(static_under, launcher)
    add(always_colliders, launcher)
end

function draw_launcher(_l)
    line(73, _l.origin.y + 1, 75, _l.origin.y + 1, 4)
    rectfill(73, _l.origin.y + 2, 75, 103, 14)
end

function init_launch_triggers()
    launch_triggers = {create_trigger_area(create_box_collider(71, 22, 78, 27)),
                       create_trigger_area(create_box_collider(65, 22, 71, 37))}
    for _l in all(launch_triggers) do
        add(static_colliders, _l)
    end
end

function create_trigger_area(_simple_collider)
    return {
        origin = vec(0, 0),
        simple_collider = _simple_collider,
        check_collision = exit_launch_mode
    }
end

function exit_launch_mode(_l)
    if mode ~= modes.launch then
        return
    end
    mode = modes.game
    add(always_colliders, launch_block)
    del(ongoing_msgs, launch_msg)
    if reset_light.lit then
        enable_bonus(skillshot_target, 80)
    end
    add_to_queue(evt_set_light, 900, {reset_light, false})
end

function init_table()
    multiplier = 1

    pinballs = {}
    static_colliders = {}
    always_colliders = {}
    static_over = {}
    static_under = {}

    init_walls()
    init_lights()
    init_round_bumpers()
    init_poly_bumpers()
    init_targets()
    init_spinners()
    init_rollovers()
    init_kickouts()
    init_launcher()
    init_launch_triggers()
    init_flippers()

    collision_regions = gen_collision_regions(0, 0, 79, 127, 16)
end

function draw_table()
    map()

    for _sc in all(static_under) do
        _sc:draw()
    end

    for pinball in all(pinballs) do
        for _t in all(pinball.trackers) do
            circfill(_t.x, _t.y, flr(_t.l / 6), tracker_cols[1 + flr(_t.l / 4)])
        end
        draw_pinball(pinball)
    end

    for _sc in all(static_over) do
        _sc:draw()
    end
    foreach(flippers, draw_flipper)

    local _multi_y = 115 - multiplier * 6
    rectfill(9, _multi_y - 1, 10, _multi_y, 10)
end

-- lib
function calc_reflection_vector(_v, _l)
    return _v:minus(calc_bounce_vector(_v, _l))
end

function calc_bounce_vector(_v, _l)
    return _l:multiplied_by(2 * _v:dot(_l))
end

function bounce_off_line(_pin, _l)
    local normalized_perp_vec = perpendicular(normalize(_l):multiplied_by(0.9))
    if _l.only_ref then
        _pin.spd = normalized_perp_vec:multiplied_by(_l.ref_spd)
    else
        _pin.spd = calc_reflection_vector(_pin.spd, normalized_perp_vec)

        if _l.ref_spd then
            _pin.spd = _pin.spd:plus(normalized_perp_vec:multiplied_by(_l.ref_spd))
        end
    end
end

function rotate_pnts(_points, _origin, _angle)
    local _new_points = {}
    for _pnt in all(_points) do
        local _pnt_o = subtract_vectors(_pnt, _origin)
        local _np = add_vectors(_origin, vec(_pnt_o.x * cos(_angle) - _pnt_o.y * sin(_angle),
            _pnt_o.y * cos(_angle) + _pnt_o.x * sin(_angle)))
        _np.c = _pnt.c
        add(_new_points, _np)
    end
    return _new_points
end

function check_collision(_pin, _obj)
    if point_collides_box(_pin.origin, _obj) then
        _obj:check_collision(_pin)
    end
end

function create_box_collider(_x1, _y1, _x2, _y2)
    -- create a simple box collider
    return {
        x1 = _x1,
        y1 = _y1,
        x2 = _x2,
        y2 = _y2
    }
end

function lines_cross(_l1_1, _l1_2, _l2_1, _l2_2)
    local _a1, _b1, _c1 = calc_inf_line_abc(_l1_1, _l1_2)
    local _a2, _b2, _c2 = calc_inf_line_abc(_l2_1, _l2_2)
    local _d1 = (_a1 * _l2_1.x) + (_b1 * _l2_1.y) + _c1
    local _d2 = (_a1 * _l2_2.x) + (_b1 * _l2_2.y) + _c1

    if sign(_d1) == sign(_d2) then
        return false
    end

    local _d1 = (_a2 * _l1_1.x) + (_b2 * _l1_1.y) + _c2
    local _d2 = (_a2 * _l1_2.x) + (_b2 * _l1_2.y) + _c2

    if sign(_d1) == sign(_d2) then
        return false
    end

    return true
end

function calc_inf_line_abc(_l1, _l2)
    local _a = _l2.y - _l1.y
    local _b = _l1.x - _l2.x
    local _c = (_l2.x * _l1.y) - (_l1.x * _l2.y)
    return _a, _b, _c
end

function check_collision_with_collider(_obj, _pin)
    local _crossed_line = pin_entered_poly(_pin, _obj)
    if _crossed_line ~= nil then
        local _sfx = _crossed_line.sfx or _obj.sfx
        if _sfx then
            sfx(_sfx)
        elseif _pin.spd_mag > 2 then
            sfx(12)
        elseif _pin.spd_mag > 0.5 then
            sfx(11)
        end
        local _pnts = _crossed_line.p or _obj.p or 0
        if _pnts > 0 then
            increase_score(_pnts)
            _obj.hit = 7
        end
        if _obj.action ~= nil then
            _obj:action()
        end
        rollback_pinball_pos(_pin)
        bounce_off_line(_pin, _crossed_line)
        return true
    end
end

function pin_entered_poly(_pin, _obj)
    local _pnts, _origin = _obj.collider, _obj.origin
    local _n_pnts = #_pnts
    if not _obj.complete then
        _n_pnts = _n_pnts - 1
    end
    for i = 1, _n_pnts do
        local j = i % #_pnts + 1
        if lines_cross(_pin.origin, _pin.last_pos, _pnts[i]:plus(_origin), _pnts[j]:plus(_origin)) then
            local output = _pnts[i]:minus(_pnts[j])
            output.p = _pnts[i].p
            output.ref_spd = _pnts[i].ref_spd
            output.only_ref = _pnts[i].only_ref
            output.sfx = _pnts[i].sfx
            return output
        end
    end
    return nil
end

function pos_are_equal(_p1, _p2)
    return flr(_p1.x) == flr(_p2.x) and flr(_p1.y) == flr(_p2.y)
end

function gen_simple_collider(_col)
    local _out = {
        x1 = _col[1].x,
        y1 = _col[1].y,
        x2 = _col[1].x,
        y2 = _col[1].y
    }
    for _pnt in all(_col) do
        _out.x1 = min(_out.x1, _pnt.x - 1)
        _out.y1 = min(_out.y1, _pnt.y - 1)
        _out.x2 = max(_out.x2, _pnt.x + 1)
        _out.y2 = max(_out.y2, _pnt.y + 1)
    end
    return _out

end

function gen_collision_regions(_x1, _y1, _x2, _y2, _side_length)
    local _col_regions = {}
    for i = _x1, _x2, _side_length do
        local _col_col = {}
        for j = _y1, _y2, _side_length do
            local _r_x1 = i - 1
            local _r_x2 = i + _side_length + 1
            local _r_y1 = j - 1
            local _r_y2 = j + _side_length + 1
            local _col_row = {}
            for _obj in all(static_colliders) do
                local _col = _obj.simple_collider
                local _org = _obj.origin
                if (_r_x1 <= _col.x2 + _org.x and _r_x2 >= _col.x1 + _org.x and _r_y1 <= _col.y2 + _org.y and _r_y2 >=
                    _col.y1 + _org.y) then
                    add(_col_row, _obj)
                end
            end
            add(_col_col, _col_row)
        end
        add(_col_regions, _col_col)
    end
    return _col_regions
end

function increase_score(_scr, _offset)
    for i = 1, multiplier do
        add_to_long(score, _scr, _offset)
    end
end

function add_to_queue(_func, _delay, _args)
    _args = _args or {}
    for _a in all(action_queue) do
        if _a.func == _func and _a.args[1] == _args[1] then
            _a.delay = _delay
            _a.args = _args
            return
        end
    end
    add(action_queue, {
        func = _func,
        delay = _delay,
        args = _args
    })
end

function evt_reactivate(_r)
    _r[1].deactivated = false
end

function evt_disable_bonus(_o)
    _o[1].bonus_enabled = false
    end_flash(_o[1], false)
end

function enable_bonus(_o, _t)
    _o.bonus_enabled = true
    evt_flash({_o, -99, true})
    add_to_queue(evt_disable_bonus, _t, {_o})
end

function evt_flash(args)
    local _o, _times, _next_state, _rep_call=args[1],args[2],args[3],args[4]
    -- Will end on initialitial _next_state
    if not _o then
        return
    elseif not (_rep_call) then
        _o.flashing = true
    elseif not _o.flashing then
        return
    end

    evt_set_light({_o, _next_state})

    if _times <= 0 and _times > -99 then
        _o.flashing = false
        return
    end

    _times = _times - 0.5
    add_to_queue(evt_flash, 15, {_o, _times, not _next_state, true})
end

function end_flash(_o, _state)
    _o.flashing = false
    evt_set_light({_o, _state})
end

function flash_table(_t, _times, _next_state, _if_lit)
    for _o in all(_t) do
        if not _if_lit or _o.lit then
            evt_flash({_o, _times, _next_state})
        end
    end
end

function end_flash_table(_t, _state)
    for _o in all(_t) do
        end_flash(_o, _state)
    end
end

-- common
function vec(_x, _y, _ref_spd, _pnts, _only_ref, _sfx)
    -- Create a vector object
    return {
        x = tonumber(_x),
        y = tonumber(_y),
        p = _pnts,
        ref_spd = _ref_spd,
        only_ref = _only_ref,
        plus = add_vectors,
        minus = subtract_vectors,
        copy = copy_vec,
        dot = dot_product,
        magnitude = magnitude,
        multiplied_by = multiply_vector,
        normalize = normalize,
        perpendicular = perpendicular,
        sfx = _sfx
    }
end

function copy_vec(_v)
    -- Create a copy of a vector
    return vec(_v.x, _v.y, _v.ref_spd, _v.p, _v.only_ref)
end

function normalize(_v)
    -- Makes magnitude = 1
    return _v:multiplied_by(1 / _v:magnitude())
end

function dot_product(_v1, _v2)
    return _v1.x * _v2.x + _v1.y * _v2.y
end

function perpendicular(_v)
    return vec(-_v.y, _v.x)
end

function multiply_vector(_v, _mul)
    -- Multiple a vector by a scalar.
    return vec(_v.x * _mul, _v.y * _mul)
end

function add_vectors(_v1, _v2)
    return vec(_v1.x + _v2.x, _v1.y + _v2.y)
end

function subtract_vectors(_v1, _v2)
    return vec(_v1.x - _v2.x, _v1.y - _v2.y)
end

function dist_between_vectors(_v1, _v2)
    return sqrt((_v1.x - _v2.x) ^ 2 + (_v1.y - _v2.y) ^ 2)
end

function magnitude(_v)
    return sqrt(_v.x ^ 2 + _v.y ^ 2)
end

function mod(val, modulo)
    -- Mod for 1 based numbers.
    -- 3%3=3. 4%3=1, 1%3=1
    return (val - 1) % modulo + 1
end

function point_collides_box(_p, _box)
    local _box_collider = _box.simple_collider
    local _origin = _box.origin
    return _p.x >= _box_collider.x1 + _origin.x and _p.x <= _box_collider.x2 + _origin.x and _p.y >= _box_collider.y1 +
               _origin.y and _p.y <= _box_collider.y2 + _origin.y
end

function point_collides_poly(_p, _obj)
    local _pnts = {}

    for _pnt in all(_obj.collider) do
        add(_pnts, {
            x = _pnt.x + _obj.origin.x,
            y = _pnt.y + _obj.origin.y
        })
    end

    for i = 1, #_pnts do
        local j = mod(i + 1, #_pnts)
        if not below_line(_p, _pnts[i], _pnts[j]) then
            return false
        end
    end
    return true
end

function below_line(_p, _l1, _l2)
    local v1 = vec(_l2.x - _l1.x, _l2.y - _l1.y)
    local v2 = vec(_p.x - _l1.x, _p.y - _l1.y)
    return v1.x * v2.y - v1.y * v2.x > 0
end

function limit(val, mn, mx)
    -- Limit a value to within a
    -- range
    return min(mx, max(mn, val))
end

function sign(_val)
    return _val < 0 and -1 or _val > 0 and 1 or 0
end

function init_long(_l)
    local _o = {}
    for i = 1, _l do
        add(_o, 0)
    end
    return _o
end

function add_to_long(_long, _to_add, _offset)
    _offset = _offset or 0
    _long[_offset + 1] = _long[_offset + 1] + flr(_to_add)
    for i = _offset + 2, #_long do
        if _long[i - 1] >= 1000 then
            _long[i] = _long[i] + _long[i - 1] // 1000
            _long[i - 1] = _long[i - 1] % 1000
        end
    end
end

function print_long(_long, _x, _y, _zero_col, _col)
    local _n, _c = 1, _zero_col
    for _plc = 1, #_long do
        local _num = _long[#_long - _plc + 1]
        local _check_size = 100
        while _num < _check_size and _check_size >= 1 do
            if _check_size == 1 and _plc == #_long then
                _c = _col
            end
            gprint("0", _x, _y, _c)
            _x = _x + 4
            _check_size = _check_size / 10
        end
        if _num > 0 then
            _c = _col
            gprint(_num, _x, _y, _c)
            _x = _x + 4 * #tostr(_num)
        end
        if _n < #_long then
            gprint(",", _x, _y)
            _x = _x + 3
        end
        _n = _n + 1
    end
end

function is_bigger_long(a, b)
    for i = 3, 1, -1 do
        if a[i] > b[i] then
            return true
        elseif a[i] < b[i] then
            return false
        end
    end
    return false
end

function get_frame(_frames, _f, _spd, _f_start)
    _f_start = _f_start or 0
    return _frames[flr((_f - _f_start) / _spd) % #_frames + 1]
end

function gen_polygon(_pnts_str)
    -- create a list of vertices
    -- by unpacking a string
    local _pnts = split(_pnts_str)
    local _output = {}
    for i = 1, #_pnts, 2 do
        add(_output, vec(_pnts[i], _pnts[i + 1]))
    end
    return _output
end

TILE_MAP={
-- upper
6,7,8,9,10,11,12,13,14,15,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
22,23,24,25,26,27,28,29,30,31,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
38,39,40,41,42,43,44,45,46,47,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
54,55,56,57,58,59,60,61,62,63,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
70,71,72,73,74,75,76,77,78,79,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
86,87,88,89,90,91,92,93,94,95,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
102,103,104,105,106,107,108,109,110,111,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
118,119,120,121,122,123,124,125,126,127,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
134,135,136,137,138,139,140,141,142,143,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
150,151,152,153,154,155,156,157,158,159,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
166,167,168,169,170,171,172,173,174,175,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
182,183,184,185,186,187,188,189,190,191,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
198,199,200,201,202,203,204,205,206,207,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
214,215,216,217,218,219,220,221,222,223,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
230,231,232,233,234,235,236,237,238,239,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
246,247,248,249,250,251,252,253,254,255,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,

-- lower
0,0,0,112,7,0,112,7,112,119,119,0,119,0,0,112,7,112,119,119,0,0,0,0,34,34,34,221,221,253,223,119,
0,5,0,221,16,17,2,0,0,0,0,5,0,0,0,0,0,0,13,13,0,0,0,0,0,112,215,221,7,0,215,221,
0,0,0,112,119,0,112,7,119,119,119,7,119,0,0,112,7,119,119,119,7,0,0,0,34,47,34,221,221,238,221,7,
0,0,0,45,18,17,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,119,221,221,7,0,215,221,
0,0,0,119,119,0,119,112,119,0,112,7,119,0,0,119,112,7,0,112,7,0,0,0,242,47,34,226,238,34,221,7,
0,0,0,17,34,17,1,0,208,0,0,0,0,0,0,0,0,13,0,0,0,0,208,13,0,215,221,221,7,0,215,34,
0,0,0,119,112,7,119,112,7,0,112,7,112,7,112,119,112,119,119,119,7,0,0,0,242,46,34,34,34,210,221,7,
0,0,0,16,33,17,0,0,0,0,33,2,0,0,0,0,0,45,0,0,0,208,29,1,112,215,237,221,7,0,39,34,
0,0,0,119,112,7,119,112,7,0,112,7,112,7,119,7,112,119,119,119,7,0,0,0,34,46,34,34,34,221,221,7,
0,0,0,16,33,17,0,0,0,16,17,33,34,2,0,2,0,16,2,0,0,17,17,0,112,221,45,222,15,0,47,34,
0,0,0,119,0,119,119,112,7,0,119,7,112,119,119,0,112,7,0,112,7,0,0,0,34,226,34,34,210,221,125,0,
0,0,0,17,33,17,0,0,16,17,17,17,17,17,17,33,34,16,2,0,17,17,1,0,119,221,45,34,15,0,47,34,
0,0,112,7,0,119,7,112,119,119,119,0,112,119,7,0,119,0,0,119,0,0,0,0,34,226,34,34,34,221,125,0,
0,0,17,17,17,1,0,16,17,17,17,17,17,17,17,17,17,17,17,17,17,17,0,0,215,221,45,34,15,0,47,34,
0,0,112,7,0,112,7,0,119,119,7,0,0,119,0,0,119,0,0,119,0,0,0,0,34,226,34,34,34,34,125,0,
16,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,0,215,34,34,34,15,0,47,34,
0,0,0,0,119,7,112,119,7,119,0,112,7,0,119,0,112,0,0,7,0,0,0,0,34,34,46,34,34,34,242,17,
17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,241,34,34,34,15,0,47,34,
0,0,0,0,119,7,112,119,7,119,0,112,119,112,119,7,112,0,0,7,0,0,0,0,238,34,46,34,34,34,242,17,
17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,241,34,34,34,15,0,47,34,
0,0,0,112,0,7,0,7,112,0,7,7,112,112,0,7,7,0,112,0,0,0,0,0,226,46,226,34,34,34,31,17,
17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,33,34,34,18,17,17,17,241,34,34,34,15,0,47,34,
0,0,0,112,119,7,0,7,112,0,7,119,119,112,119,7,7,0,112,0,0,0,0,0,34,34,226,34,34,34,31,17,
17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,34,34,34,17,17,47,34,34,15,0,47,34,
0,0,0,112,119,0,112,0,112,0,7,119,7,112,119,7,7,0,112,0,0,0,0,0,34,34,226,46,34,34,31,17,
17,17,17,33,34,34,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,47,34,34,15,0,47,34,
0,0,0,119,0,0,112,0,7,112,112,0,7,7,0,7,7,0,112,0,0,0,0,0,34,34,34,46,34,34,31,17,
17,34,34,18,17,33,34,34,18,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,241,34,34,15,0,47,34,
0,0,0,7,0,112,119,7,7,112,112,119,7,7,112,112,119,7,119,119,0,0,0,0,34,34,34,34,34,34,31,17,
17,17,17,17,17,17,17,17,34,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,241,34,34,15,0,47,34,
0,0,0,7,0,112,119,7,7,112,112,119,0,7,112,112,119,7,119,119,0,0,0,0,34,34,34,34,34,242,17,17,
17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,241,34,34,15,0,47,34,
0,0,0,0,0,0,0,0,0,0,204,204,204,204,0,0,0,0,0,0,0,0,0,0,34,34,34,34,34,242,17,17,
17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,47,34,15,0,239,34,
0,0,0,0,0,0,0,0,204,204,204,17,17,204,204,204,0,0,0,0,0,0,0,0,34,34,34,34,34,242,17,17,
17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,47,34,15,0,47,34,
0,0,0,0,0,0,0,204,17,17,204,17,28,204,17,17,204,0,0,0,0,0,0,0,34,34,34,34,34,242,31,17,
17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,241,47,34,15,0,239,46,
0,0,0,0,0,0,204,204,17,28,193,17,193,204,17,28,204,204,0,0,0,0,0,0,34,34,34,34,34,34,255,17,
17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,255,34,34,15,0,47,34,
0,0,0,0,0,192,28,204,17,204,193,17,28,28,17,17,28,193,12,0,0,0,0,0,34,34,34,34,34,34,242,31,
17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,241,47,34,34,15,0,239,34,
0,0,0,0,192,204,17,193,28,193,193,109,102,28,193,193,28,193,204,12,0,0,0,0,34,34,34,34,34,34,34,255,
17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,33,34,17,17,17,17,17,17,17,255,34,34,34,15,0,47,34,
0,0,0,0,204,193,28,17,28,204,92,125,119,198,204,193,17,204,204,204,0,0,0,0,34,34,34,34,34,34,242,31,
17,17,17,17,17,17,17,17,17,17,17,17,17,17,33,18,33,34,34,17,17,17,17,17,241,47,34,34,15,0,239,46,
0,0,0,192,28,17,204,17,204,28,85,102,119,103,193,204,17,204,28,193,12,0,0,0,221,221,221,221,45,34,255,17,
17,17,17,17,17,17,17,17,17,17,17,17,17,34,34,17,17,17,17,17,17,17,17,17,17,255,34,34,15,0,47,34,
0,0,0,204,17,28,204,204,28,17,221,109,102,103,17,193,28,193,17,193,204,0,0,0,221,221,221,221,221,45,31,17,
17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,241,34,34,15,0,239,34,
0,0,192,204,17,193,204,28,17,17,102,221,109,214,17,17,193,28,17,204,204,12,0,0,125,125,221,221,221,221,31,17,
17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,241,34,34,15,0,47,34,
0,0,192,204,28,17,204,17,17,17,119,214,221,221,17,17,17,204,193,204,204,12,0,0,125,125,221,221,77,212,31,17,
17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,241,34,34,15,0,239,46,
0,0,204,204,199,193,28,17,17,17,113,102,93,21,17,17,17,193,17,124,204,204,0,0,125,119,125,125,77,212,31,17,
17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,241,34,34,15,0,47,34,
0,192,204,204,204,204,17,17,17,119,17,214,85,17,119,17,17,17,204,204,204,204,12,0,221,125,221,215,221,221,31,17,
17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,241,34,34,15,0,239,34,
0,192,204,199,204,28,17,17,119,119,23,170,170,113,119,119,17,17,193,204,124,204,12,0,221,125,125,125,221,221,31,17,
31,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,241,17,241,34,34,15,0,47,34,
0,204,204,204,204,17,17,113,119,126,119,161,26,119,126,119,23,17,17,204,204,204,204,0,221,221,221,221,221,221,31,17,
255,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,255,17,241,34,34,15,0,239,46,
0,204,119,204,28,17,17,119,238,119,126,161,23,231,231,231,126,17,17,193,204,119,204,0,125,119,221,221,221,221,31,17,
255,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,255,17,241,34,34,15,0,47,34,
192,204,119,204,28,17,113,238,238,238,238,113,23,238,238,238,238,23,17,193,204,119,204,12,221,125,221,221,77,212,31,17,
255,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,255,17,241,34,34,15,0,239,34,
192,204,204,204,17,17,231,238,46,46,46,161,26,226,226,226,238,126,17,17,204,204,204,12,221,119,125,125,77,212,31,17,
255,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,255,17,241,34,34,15,0,47,34,
192,124,199,204,17,225,238,238,226,226,226,161,119,33,46,46,238,238,30,17,204,124,199,12,221,125,221,215,221,221,31,17,
255,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,255,17,241,34,34,15,0,239,46,
192,124,199,204,17,225,46,46,46,34,34,161,170,33,34,226,226,226,30,17,204,124,199,12,125,119,125,125,221,221,31,17,
255,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,255,17,241,34,34,15,0,47,34,
204,204,204,28,17,238,18,17,17,17,17,161,167,17,17,17,17,33,238,17,193,204,204,204,221,221,221,221,221,221,31,17,
255,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,255,17,241,34,34,15,0,239,34,
204,199,199,28,17,238,30,153,25,153,17,170,167,145,153,145,153,225,238,17,193,124,124,204,125,119,221,221,221,221,31,17,
255,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,255,17,241,34,34,15,0,47,34,
204,124,204,28,17,238,18,145,17,25,25,119,167,145,145,145,145,33,238,17,193,204,199,204,221,125,221,221,77,212,31,17,
255,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,255,17,241,34,34,15,0,47,34,
204,199,199,28,225,46,33,145,17,25,25,170,119,145,153,145,25,17,226,30,193,124,124,204,125,119,125,125,77,212,31,17,
255,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,255,17,241,34,34,15,0,47,34,
204,204,204,28,225,18,18,145,17,25,25,161,170,145,17,145,145,33,33,30,193,204,204,204,125,221,221,215,221,221,31,17,
255,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,255,17,241,34,34,255,255,47,34,
204,199,199,28,33,46,17,145,17,25,25,161,170,145,17,145,145,17,226,18,193,124,124,204,125,119,125,125,221,221,31,17,
255,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,255,17,241,34,34,34,34,34,34,
204,124,204,28,225,18,17,145,17,25,25,161,167,145,17,145,153,17,33,30,193,204,199,204,221,221,221,221,221,221,31,17,
255,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,255,17,241,34,34,34,34,34,34,
204,199,199,28,33,17,17,17,17,17,17,170,167,17,17,17,17,17,17,18,193,124,124,204,125,215,221,221,221,221,31,17,
241,31,17,17,17,17,17,17,17,17,17,33,18,17,17,17,17,17,17,17,17,17,241,31,17,241,34,39,39,34,34,34,
192,204,204,204,17,17,17,17,17,17,17,170,167,17,17,17,17,17,17,17,204,204,204,12,221,215,221,221,77,212,31,17,
17,255,17,17,17,17,17,17,17,17,33,18,18,17,17,17,17,17,17,17,17,17,255,17,17,241,34,114,39,34,34,34,
192,124,124,204,33,17,17,17,17,17,17,122,119,26,17,17,17,17,17,18,204,199,199,12,221,215,125,125,77,212,31,17,
17,241,255,17,17,17,17,17,17,17,34,17,34,34,17,17,17,17,17,17,17,255,31,17,17,241,34,119,39,34,34,34,
192,204,199,204,17,17,17,17,17,17,17,122,119,170,17,17,17,17,17,17,204,124,204,12,221,215,221,215,221,221,31,17,
21,17,255,31,17,17,17,17,33,34,18,17,17,33,18,17,17,17,17,17,241,255,17,81,17,241,34,34,39,114,119,39,
192,124,124,204,28,17,17,17,170,17,161,122,167,136,26,17,17,17,161,170,202,199,199,12,125,119,125,125,221,221,31,17,
17,17,241,255,17,17,17,17,17,17,17,17,17,17,33,34,17,17,17,17,255,31,17,17,17,241,34,34,119,119,119,119,
0,204,204,204,28,17,17,17,138,24,161,120,167,170,152,17,17,17,161,136,202,204,204,0,221,221,221,221,221,45,95,17,
21,17,17,241,31,17,17,17,17,17,17,17,17,17,17,17,17,17,17,241,31,17,17,81,17,245,34,34,119,119,119,119,
0,204,124,124,170,26,17,17,129,17,170,120,167,136,152,17,17,17,170,136,168,124,204,0,221,221,221,221,45,34,95,21,
17,17,17,17,255,17,17,17,17,17,17,17,17,17,17,17,17,17,17,255,17,17,17,17,81,245,34,98,119,119,119,119,
0,192,204,199,137,170,17,17,17,161,136,122,167,170,154,17,17,161,170,170,170,202,12,0,34,34,34,34,34,34,31,85,
17,17,17,17,241,31,17,17,17,17,17,17,17,17,17,17,17,17,241,31,17,17,17,17,85,241,34,98,119,119,119,119,
0,192,124,124,137,136,26,17,17,170,170,136,119,138,168,170,17,170,153,153,153,153,12,0,34,34,221,34,34,34,31,81,
31,17,17,17,17,255,17,17,17,17,17,17,17,17,17,17,17,17,255,17,17,17,17,241,21,241,34,102,118,119,119,102,
0,0,204,204,153,136,26,17,145,136,168,122,119,138,168,168,170,153,137,136,136,153,0,0,34,34,45,45,34,34,31,17,
255,17,17,17,17,241,31,17,17,17,17,17,17,17,17,17,17,241,31,17,17,17,17,255,17,241,34,102,118,119,103,85,
0,0,192,124,156,137,168,170,145,136,168,168,170,138,136,168,154,137,136,136,136,153,0,0,34,34,221,34,34,34,31,17,
255,31,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,241,255,17,241,34,102,102,117,119,102,
0,0,192,156,137,136,154,169,17,153,136,136,136,138,153,153,136,136,137,136,136,9,0,0,34,34,45,45,34,34,31,17,
47,255,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,255,242,17,241,34,98,86,86,119,119,
0,0,0,156,136,136,168,153,170,170,136,152,137,136,136,136,136,136,153,136,152,9,0,0,34,34,221,45,34,34,31,17,
47,242,31,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,241,47,242,17,241,34,34,82,86,102,119,
0,0,0,144,136,136,154,153,153,169,170,136,136,136,136,136,136,136,152,136,153,0,0,0,34,34,34,34,34,34,31,17,
47,34,255,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,255,34,242,17,241,34,34,34,34,34,34,
0,0,0,144,153,136,170,169,170,154,153,136,136,136,153,137,152,136,152,153,9,0,0,0,34,34,34,34,34,34,31,17,
47,34,242,31,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,241,47,34,242,17,241,34,34,34,34,34,34,
0,0,0,0,153,137,153,170,154,137,136,136,152,136,136,137,153,136,152,153,0,0,0,0,34,34,34,34,34,34,255,255,
47,34,34,255,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,255,34,34,242,255,255,34,34,34,34,114,119,
0,0,0,0,0,137,136,153,153,136,136,153,153,136,136,136,137,136,153,0,0,0,0,0,34,34,34,34,34,34,34,34,
34,34,34,242,31,17,17,17,17,17,17,17,17,17,17,17,17,17,17,241,47,34,34,34,34,34,34,34,34,34,118,119,
0,0,0,0,0,144,136,136,136,136,136,136,136,136,136,152,153,153,9,0,0,0,0,0,34,34,34,34,34,34,34,34,
34,34,34,34,255,17,17,17,17,17,17,17,17,17,17,17,17,17,17,255,34,34,34,34,34,34,34,34,34,34,102,119,
0,0,0,0,0,0,144,153,136,136,137,136,152,136,152,153,153,9,0,0,0,0,0,0,34,34,34,34,34,34,34,34,
34,34,34,34,242,31,17,17,17,17,17,17,17,17,17,17,17,17,241,47,34,34,34,34,34,34,34,34,34,34,98,102,
0,0,0,0,0,0,0,144,153,153,137,152,153,153,153,153,9,0,0,0,0,0,0,0,34,34,34,34,34,34,34,34,
34,34,34,34,34,255,17,17,17,17,17,17,17,17,17,17,17,17,255,34,34,34,34,34,34,34,34,34,34,34,98,34,
0,0,0,0,0,0,0,0,0,144,153,153,153,153,9,0,0,0,0,0,0,0,0,0,34,34,34,34,34,34,34,34,
34,34,34,34,34,242,31,17,17,17,17,17,17,17,17,17,17,241,47,34,34,34,34,34,34,34,34,34,34,34,34,34
}

SFX={
    -- 0
	"PAT 6 C.2532",
	"PAT 5 D#3755",
	"PAT 4 F.3755",
	"PAT 4 G.3755",
	"PAT 4 A#3755",
	"PAT 4 C.4755",
	"PAT 4 D#4755",
	"PAT 4 F.4755",
	"PAT 4 G.4755",
	"PAT 4 A#4755",
    -- 10
	"PAT 6 A#3750 C.4755 ...... D#4750 F.4755 ...... C.4750 D#4755 ...... G.4750 C.5750 ...... ...... ...... ...... ......",
	"PAT 6 C.1513 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
	"PAT 6 E.1533 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
	"PAT 16 G.3537 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
	"PAT 10 F.2315 C.1303 C.1303 C.1303 C.1303 C.1303 C.1303 C.1303 C.1303 C.1303 C.1303 C.1303 C.1303 C.1303 C.1303 C.1303 C.1303 C.1303 C.1303 C.1303 C.1303 C.1303 C.1303 C.1303 C.1303 C.1303 C.1303 C.1303 C.1303 C.1303 C.1303 C.1303",
	"PAT 16 D#3325 C.3322 D#3325 D#3103 G.3325 C.1103 C.1103 C.1103 C.1103 C.1103 C.1103 C.1103 C.1103 C.1103 C.1103 C.1103 C.1103 C.1103 C.1103 C.1103 C.1103 C.1103 C.1103 C.1103 C.1103 C.1103 C.1103 C.1103 C.1103 C.1103 C.1103 C.1103",
	"PAT 16 D#3730 A#3720 A#3510 G.3730 C.4720 C.4510 F.4730 D#4720 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
	"PAT 16 C.2033 ...... C.1625 C.1623 C.3625 ...... C.1625 ...... C.1133 ...... C.1523 C.1003 C.3625 ...... C.1513 ...... C.2033 C.1513 ...... ...... C.3625 ...... C.1513 ...... C.1133 ...... C.1523 C.1003 C.3625 ...... C.1513 ......",
	"PAT 16 ...... ...... C.1130 C.1125 C.1110 C.1130 C.1125 C.1110 C.1130 C.1125 C.1110 D#1130 D#1120 D#1110 C.1135 C.1110 ...... ...... C.1130 C.1125 C.1110 D#1130 D#1120 D#1110 D#1130 D#1120 D#1110 F.1130 F.1125 F.1110 D#1135 D#1110",
	"PAT 16 ...... ...... F.1130 F.1125 F.1110 D#1130 D#1125 D#1110 F.1130 F.1125 F.1110 D#1130 D#1125 D#1110 F.1135 F.1110 ...... ...... F.1130 F.1125 F.1110 D#1130 D#1120 D#1110 C.1130 C.1125 C.1110 D#1130 D#1120 D#1110 C.1135 C.1110",
    -- 20
	"PAT 96 D#3714 D#3710 D#3715 B.2500 A#3714 A#3712 A#3712 A#3715 G.3714 G.3710 G.3715 ...... C.4714 C.4712 C.4712 C.4715 F.4714 F.4710 F.4715 C.4702 D#4714 D#4710 D#4715 ...... C.4714 C.4710 C.4715 ...... F.4714 F.4712 F.4712 F.4715",
	"PAT 96 D#4714 D#4710 D#4715 B.2500 A#3714 A#3712 A#3712 A#3715 C.4714 C.4710 C.4715 ...... G.3714 G.3712 G.3712 G.3715 A#3714 A#3710 A#3715 C.4702 F.3714 F.3710 F.3715 ...... A#3714 A#3710 A#3715 ...... G.3714 G.3712 G.3712 G.3715",
	"PAT 2 D#1612 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
	"PAT 24 C.3734 D#3731 F.3731 G.3731 F.3724 G.3721 A#3721 C.4721 A#3724 C.4721 D#4711 F.4711 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
	"PAT 14 A#2330 G.2333 A#3330 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
	"PAT 8 C.3043 F.3031 D#3043 A#3035 D#3043 G.3031 F.3043 C.4035 F.3043 A#3031 G.3043 D#4035 ...... ...... ...... ......",
	"PAT 8 C.3023 D#3011 D#3015 ...... ...... ...... ...... ......",
	"PAT 8 C.3033 F.3021 ...... D#3033 G.3021 ...... C.3033 A#3031 A#3025 ...... ...... ...... ...... ...... ...... ......",
	"PAT 16 C#5753 D#5743 E.5733 ...... ...... ...... ...... ......",
	"PAT 16 G.4020 G#5020 A#3020 B.4620 A#4621 F#4621 D.4621 A.3621 F.3621 C.3611 B.2611 C.3611 D.3611 E.3611 G#3611 C#4611 F#4611 D.5611 G#5611 D.6611 D#6615 D.5600 E.5600 F#5600 A.5600 C.6600 ...... ...... ...... ...... ...... ......",
    -- 30
	"PAT 16 G.2230 D#2240 C.2230 D#2240 C.2220 A#1211 A#1215 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
	"PAT 16 D#2230 G.2240 F.2230 A#2240 G.2230 D#2240 C.2230 D#2240 C.2220 A#1221 A#1211 G.1221 G.1215 ...... ...... ......"
}

INST_TRIANGLE = "INST OVERTONE 1.0 TRIANGLE 1.0 METALIZER 0.85 NAM triangle"
INST_TILTED = "INST OVERTONE 1.0 TRIANGLE 0.5 SAW 0.1 NAM tilted"
INST_SAW = "INST OVERTONE 1.0 SAW 1.0 ULTRASAW 1.0 NAM saw"
INST_SQUARE = "INST OVERTONE 1.0 SQUARE 0.5 NAM square"
INST_PULSE = "INST OVERTONE 1.0 SQUARE 0.5 PULSE 0.5 TRIANGLE 1.0 METALIZER 1.0 OVERTONE_RATIO 0.5 NAM pulse"
INST_ORGAN = "INST OVERTONE 0.5 TRIANGLE 0.75 NAM organ"
INST_NOISE = "INST NOISE 1.0 NOISE_COLOR 0.2 NAM noise"
INST_PHASER = "INST OVERTONE 0.5 METALIZER 1.0 TRIANGLE 0.7 NAM phaser"
INST_SNARE = "SAMPLE ID 01 FILE celeste/11_ZN.wav FREQ 400"
INST_KICK = "SAMPLE ID 02 FILE celeste/10_HALLBD1.wav FREQ 400"

MUSIC=[[
    NAM music
    PATLIST 16 17 18 19 20 21
    SEQ2 04.......... 05..........
]]

MUSIC2=[[
    NAM music
    PATLIST 16 17 18 19 20 21
    SEQ2 000102...... 0102........ 0103........
]]