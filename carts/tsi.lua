-- they started it
-- (c) joe trewin
-- http:--fistfulofsquid.com
-- @joeyspacerocks
-- Viper conversion
-- jiceexp
PI = 3.14159
X_OFFSET = 80
Y_OFFSET = 0
SPRITE_PER_ROW = 16
SPRITE_SIZE = 14
SCREEN_SIZE = 16 * SPRITE_SIZE
LAYER_SPRITE = 7
SPRITESHEET_SIZE = 224

p1 = {}
lrs = {}
als = {}
exp = {}
smoke = {}
shake = 0
stars = {}
powerups = {}
wave = 0
pu_drop_timer = 1600
xlife_timer = 0

max_wave = 20
max_lives = 5
max_missiles = 5

flash = nil
ui_y = 0

wt_max = 200
wave_timer = -1
wave_score = 0
warp = 0

bonus = 0

titles = {}
scrn = {}

math.clamp = function(v, a, b)
    return v < a and a or (v > b and b or v)
end

math.sign = function(v)
    return v > 0 and 1 or v < 0 and -1 or 0
end

col = function(r, g, b)
    return {
        r = r / 255,
        g = g / 255,
        b = b / 255
    }
end

PAL = {col(0, 0, 1), col(29, 43, 83), col(126, 37, 83), col(0, 135, 81), col(171, 82, 54), col(95, 87, 79),
       col(194, 195, 199), col(255, 241, 232), col(255, 0, 77), col(255, 163, 0), col(255, 236, 39), col(0, 228, 54),
       col(41, 173, 255), col(131, 118, 156), col(255, 119, 168), col(255, 204, 170)}

-- -----------------------------
-- -- PICO-8 compatibility layer
-- -----------------------------
function sprc(n, x, y, w, h, c)
    local int_spr = math.floor(n)
    local spritex = (int_spr % SPRITE_PER_ROW) * SPRITE_SIZE
    local spritey = math.floor(int_spr / SPRITE_PER_ROW) * SPRITE_SIZE
    gfx.blit(spritex, spritey, w * SPRITE_SIZE, h * SPRITE_SIZE, math.floor(x + X_OFFSET), math.floor(y + Y_OFFSET), 0,
        0, false, false, PAL[c + 1].r, PAL[c + 1].g, PAL[c + 1].b)
end

function ssprc(n, x, y, w, h)
    local int_spr = math.floor(n)
    local spritex = (int_spr % SPRITE_PER_ROW) * SPRITE_SIZE
    local spritey = math.floor(int_spr / SPRITE_PER_ROW) * SPRITE_SIZE
    gfx.blit(spritex, spritey, SPRITE_SIZE, SPRITE_SIZE, math.floor(x + X_OFFSET), math.floor(y + Y_OFFSET), w, h,
        false, false, 1.2, 1.2, 1.2)
end

function spr(n, x, y, w, h)
    sprc(n, x, y, w, h, 7)
end

function rectfill(x1, y1, x2, y2, col)
    local w = x2 - x1 + 1
    local h = y2 - y1 + 1
    local x = x1 + X_OFFSET
    local y = y1 + Y_OFFSET
    gfx.rectangle(x, y, w, h, PAL[col + 1].r, PAL[col + 1].g, PAL[col + 1].b)
end

function circfill(x, y, r, col)
    gfx.disk(x + X_OFFSET, y + Y_OFFSET, r, PAL[col + 1].r, PAL[col + 1].g, PAL[col + 1].b)
end

function line(x1, y1, x2, y2, col)
    gfx.line(x1 + X_OFFSET, y1 + Y_OFFSET, x2 + X_OFFSET, y2 + Y_OFFSET, PAL[col + 1].r, PAL[col + 1].g, PAL[col + 1].b)
end

function _print(msg, px, py, col)
    local c = math.floor(col + 1)
    gfx.print(msg, math.floor(px + X_OFFSET), math.floor(py + Y_OFFSET), PAL[c].r, PAL[c].g, PAL[c].b)
end

function printc(s, y, c)
    local x = 112 - (#s * 0.5) * 8 - 1
    _print(s, x, y, c)
end

function camera(x, y)
    gfx.set_layer_offset(0, x, y)
end

function rect(x1, y1, x2, y2, col)
    line(x1, y1, x2, y1, col)
    line(x1, y2, x2, y2, col)
    line(x1, y1, x1, y2, col)
    line(x2, y1, x2, y2, col)
end

function pico_atan2(dx, dy)
    local r = atan2(dy, dx) / PI
    return r < 0 and -0.5 * r or 1 - 0.5 * r
end

---------------------------
---- title
---------------------------

function rnd_blob(b)
    local a = math.random() * 2 * PI
    local r = 175 + math.random() * 70
    b.x = math.cos(a) * r + 112
    b.y = math.sin(a) * r + 112
    b.r = math.random() * 17 + 10
    local spd = (math.random() * 15 + 3) / 15
    b.dx = -math.cos(a) * spd
    b.dy = -math.sin(a) * spd
    b.col = 1
    return b
end

function create_blobs()
    titles.blobs = {}
    for i = 1, 160 do
        table.insert(titles.blobs, rnd_blob({}))
    end
end

function trail(p)
    if math.random() > 0.5 then
        local s = {}
        s.x = p1.x + 7
        s.y = p1.y + 20
        if warp > 0 then
            s.ttl = 20
            s.col = 8
            s.dx = (math.floor(math.random() * 8) - 2) * 0.2
            s.dy = (3 + math.random() * 5) * 0.2
        else
            s.ttl = 15
            s.col = 2
            s.dx = (math.floor(math.random() * 5) - 1) * 0.3
            s.dy = (1 + math.random() * 7) * 0.1
        end
        table.insert(smoke, s)
    end
end

function create_laser(p, x, s)
    local l = {}
    l.y = p.y + 14
    l.x = x + math.random() * 2 - 1
    l.sprite = s
    l.update = nil
    l.explode = nil
    l.to_remove = false
    table.insert(lrs, l)
end

function fire_laser(p)
    if p.f_elapsed == 0 then
        if p.twin_lasers then
            create_laser(p, p.x - 2, 16)
            create_laser(p, p.x + 2, 16)
        else
            create_laser(p, p.x, 2)
        end

        snd.play_pattern(0)
        p.f_elapsed = 1
    end
end

function nearest_alien(y, ymax)
    local r = nil
    local ymin = 0
    for _, a in pairs(als) do
        if a.y > ymin and a.y < ymax then
            ymax = a.y
            r = a
        end
    end
    return r
end

function missile_trail(m)
    if math.random() * 4 > 1 then
        local s = {}
        s.x = m.x + 7
        s.y = m.y + 7

        local ang = (m.ang + ((math.random() * 10 - 5) / 20)) * 2 * PI
        s.dx = -math.cos(ang) * 0.175
        s.dy = -math.sin(ang) * 0.175
        s.ttl = 20
        s.col = m.tcol
        table.insert(smoke, s)
    end
end

function explode(x, y, ttl, col)
    local e = {}
    e.x = x
    e.y = y
    e.ttl = ttl
    e.col = col
    table.insert(exp, e)
end

function add_smoke(x, y, amt, c)
    for i = 1, amt do
        local s = {}
        s.x = x
        s.y = y
        s.dx = (math.random() * 10 - 5) * 0.24
        s.dy = (math.random() * 10 - 5) * 0.24
        s.ttl = math.random() * 20 + amt * 8
        s.col = c
        table.insert(smoke, s)
    end
end

function upd_missile(this)
    local dx = this.target.x - this.x
    local dy = this.target.y - this.y
    local tang = pico_atan2(dx, dy)

    local dist = math.sqrt(dx * dx + dy * dy)

    local da = tang - this.ang
    if da ~= 0 then
        local turn
        if dist < 10 then
            turn = 0.03
        elseif dist < 50 then
            turn = 0.01
        else
            turn = 0.005
        end

        local av = turn * math.sign(da)

        if da > 0.5 then
            av = -av
        end

        this.ang = this.ang + av
        if this.ang < 0 then
            this.ang = this.ang + 1
        end
        if this.ang > 1 then
            this.ang = this.ang - 1
        end
    end

    this.x = this.x + math.cos(this.ang * 2 * PI) * this.spd
    this.y = this.y + math.sin(this.ang * 2 * PI) * this.spd
    if this.spd < 2 then
        this.spd = this.spd + 0.1
    end

    missile_trail(this)

    this.timer = this.timer + 1
    if this.timer > 300 then
        explode(this.x, this.y, 4 + math.random() * 4, 10)
        add_smoke(this.x, this.y, 5, 5)
        shake = 10
        this.to_remove = true
        snd.play_pattern(2)
    end
end

function create_missile(x, y, trg)
    local l = {}
    l.x = x
    l.y = y
    l.target = trg
    if trg.x > x then
        l.ang = 0
    else
        l.ang = 0.5
    end
    l.spd = 1.75 * (0.4 + math.random() * 0.5)
    l.timer = 0
    l.sprite = 5
    l.update = upd_missile
    l.draw = nil
    l.ty = nil
    l.to_remove = false
    l.anim = nil
    l.kill = nil
    snd.play_pattern(8)
    return l
end

function add_score(n)
    local s1 = math.floor(p1.score / 30000)
    p1.score = p1.score + n
    local s2 = math.floor(p1.score / 30000)

    if p1.score > 0 and p1.lives < max_lives and s2 > s1 then
        p1.lives = p1.lives + 1
        snd.play_pattern(11)
        xlife_timer = 40
    end
end

function drop_powerup(x, y, sprite, action)
    local pu = {}
    pu.x = x
    pu.y = y
    pu.sprite = sprite
    pu.action = action
    table.insert(powerups, pu)
end

function pua_missile()
    if p1.missiles < max_missiles then
        p1.missiles = p1.missiles + 1
    end
end

function pua_shield()
    p1.shield = p1.max_shields
end

function kill_alien(a, dmg)
    add_smoke(a.x + 4, a.y, 5, 5)
    a.shield = a.shield - dmg

    if a.shield > 0 then
        a.hurt = 10
        snd.play_pattern(10)
    else
        explode(a.x + 4, a.y, 9, 10)
        a.to_remove = true
        shake = 4
        snd.play_pattern(math.random() * 2 + 1)

        if a.kill ~= nil then
            a.kill(a)
        end

        add_score(a.scr)
        wave_score = wave_score + a.scr

        if pu_drop_timer == 0 then
            pu_drop_timer = 600

            local t = math.floor(math.random() * 2)
            if t == 0 then
                drop_powerup(a.x, a.y, 12, pua_missile)
            elseif t == 1 then
                drop_powerup(a.x, a.y, 13, pua_shield)
            end
        end
    end
end

function flash_screen(timer, col)
    flash = {}
    flash.timer = timer
    flash.col = col
end

function missile_explode(this)
    flash_screen(10, 10)
    explode(this.x, this.y, 20, 14)
    explode(this.x + 10, this.y + 10, 10, 7)
    explode(this.x - 5, this.y + 5, 10, 7)
    add_smoke(this.x, this.y, 5, 14)
    shake = 20
    snd.play_pattern(2)

    for _, a in pairs(als) do
        local dx = this.x - a.x
        local dy = this.y - a.y
        if dx * dx + dy * dy < 1000 then
            kill_alien(a, 3)
        end
    end
end

function fire_missile(p)
    if p.missiles > 0 then
        p.missiles = p.missiles - 1

        local x = p.x + 3
        local y = p.y + 4

        local trg = nearest_alien(p.y, 80)
        if trg == nil then
            trg = {}
            trg.x = 40 + math.random() * 48
            trg.y = 40 + math.random() * 30
        end

        local l = create_missile(x, y, trg)
        l.tcol = 2
        l.explode = missile_explode
        l.to_remove = false
        if p.dx > 0 then
            l.ang = 0
        elseif p.dx < 0 then
            l.ang = 0.5
        end

        table.insert(lrs, l)
    end
end

function new_life(p)
    p.lives = p.lives - 1
    p.dead = false
    p.x = 105
    p.y = 178
    p.dx = 0
    p.f_elapsed = 0
    p.inv = 200

    p.shield = p.max_shields
    p.shield_timer = 0
end

function update_stars()
    for _, s in pairs(stars) do
        s.y = s.y + 2 * (s.dy + (warp * 0.3))
        if s.y > 223 then
            s.y = -18
            s.x = math.random() * 223
        end
    end
end

function update_blobs(s, reset)
    for _, b in pairs(titles.blobs) do
        b.x = b.x + b.dx
        b.y = b.y + b.dy

        if b.x + b.r > 0 and b.x - b.r < 223 and b.y + b.r > 0 and b.y - b.r < 223 then
            b.r = b.r * s
        end

        if b.r < 1.5 and reset then
            rnd_blob(b)
        end
    end
end

function hide_titles()
    update_stars()
    update_blobs(0.92, false)

    if titles.ty > -104 then
        titles.ty = titles.ty + (-105 - titles.ty) * 0.12
        titles.oy = titles.oy + (250 - titles.oy) * 0.12
    else
        new_game()
    end
end

function update_titles()
    update_stars()

    if titles.ty < 70 then
        titles.ty = titles.ty + (70 - titles.ty) * 0.12
    end

    if titles.oy > 160 then
        titles.oy = titles.oy + (160 - titles.oy) * 0.12
    end

    if inp.action1_pressed() or inp.action2_pressed() then
        scrn.update = hide_titles
    end

    update_blobs(0.98, true)
end

function draw_stars()
    for _, s in pairs(stars) do
        local sy2 = s.y - (s.dy + warp * 0.3) * 2
        local c = s.col
        if warp == 0 and c == 7 then
            c = 13
        end
        line(s.x, s.y, s.x, sy2, c)
    end
end

function waggle(s, x, y, sx, sy)
    local t = elapsed() * 1.6

    local rx
    local ry
    local cols = {1, 2, 0, 1, 2, 0}
    for i = 1, 6 do
        rx = x + math.cos(t * 0.4 * 2 * PI) * 7
        ry = y + math.sin(t * 0.4 * 2 * PI) * 10
        sprc(s, rx, ry, sx, sy, cols[i])
        t = t + 0.2
    end

    spr(s, math.floor(rx), math.floor(ry), math.floor(sx), math.floor(sy))
end

function draw_pressmsg(s, x, y)
    local c = (math.sin(elapsed() * 2 * PI * 0.8) + 1) * 7 + 1
    _print("press X " .. s, x, y, c)
    _print("press   " .. s, x, y, 14)
end

function draw_titles()
    rectfill(0, 0, 223, 223, 0)
    draw_stars()

    for _, b in pairs(titles.blobs) do
        if b.r > 1.1 then
            circfill(b.x, b.y, b.r, b.col)
        end
    end

    waggle(64, 2, titles.ty, 16, 4)

    draw_pressmsg("to play", 50, titles.oy)
end

function show_titles()
    titles.ty = -105
    titles.oy = 260
    scrn.update = update_titles
    scrn.draw = draw_titles
end

function collide(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 + w1 > x2 and x1 < x2 + w2 and y1 + h1 > y2 and y1 < h2 + y2
end

function bomb_trail(b, col, dy, ttl)
    if math.random() > 0.5 then
        local s = {}
        s.x = b.x + 7
        s.y = b.y + 6
        s.dx = (math.floor(math.random() * 3) - 1) * 0.3 * 1.75
        s.dy = -(1 + math.random() * 4) * dy * 1.75
        s.ttl = 15
        s.col = col
        table.insert(smoke, s)
    end
end

function warp_speed()
    wave_timer = wt_max
    snd.play_pattern(4)
end

WAVES = {{"  0000  ", " 000000 ", "000  000"}, {" 000000 ", "11 11 11", " 000000 ", "  0  0  "},
         {"10000001", " 100001 ", " 100001 ", " 1 11 1 "}, {" 1 11 1 ", "        ", "11 11 11", "        ", "00 00 00"},
         {"  2  2  ", " 000000 ", "10000001", " 111111 "}, {"   22   ", "1      1", "011  110", " 001100 ", "   00   "},
         {"11111111", " 1    1 ", "33333333"}, {"1 1 1 1 ", " 1 1 1 1", "1 1 1 1 ", " 1 1 1 1"},
         {"2  22  2", "00000000", "00000000", "00000000", "00000000"}, {" 11  11 ", "11111111", "11111111", "  3333  "},
         {"00000000", "01100110", "01100110", "00000000"}, {"22000022", "  2002  ", "   00   ", "11100111"},
         {"11111111", "10011001", "10011001", "11111111"}, {"12211221", "1  11  1", "        ", "  3333  "},
         {"  4  4  ", "00000000", "10000001", " 100001 "}, {"  4  4  ", "11111111", "11111111", "00111100"},
         {"   22   ", "24444442", "11111111", "11111111"}, {" 114411 ", "  1441  ", "  1111  ", "   11   ", "   11   "},
         {"01111110", "01444410", "01111110", "00000000", "33333333"}, {"44444444", "44444444", "44444444", "11111111"}}

function create_anim(s)
    local anim = {}
    anim.s = s
    anim.t = 0
    anim.d = 10 + math.floor(math.random() * 4)
    anim.i = 1
    return anim
end

function au_bomb(this)
    this.x = this.x + 1.75 * math.sin(this.y * 0.1 * 2 * PI)
    this.y = this.y + 1.75
    bomb_trail(this, 8, 0.3, 15)
end

function drop_bomb(a)
    local b = {}
    b.x = a.x
    b.y = a.y
    b.sprite = 10
    b.update = au_bomb
    b.shield = 1
    b.hurt = 0
    b.scr = 10
    b.ty = nil
    b.draw = nil
    b.to_remove = false
    b.anim = nil
    b.kill = nil
    table.insert(als, b)
    snd.play_pattern(3)
end

function au_zigzag(this)
    local t = (elapsed() + this.id * 2.1) * 0.03
    this.x = this.x + math.sin(t * 10 * 2 * PI) * 0.1 * 1.75

    if math.sin(t * 20 * 2 * PI) > 0 then
        this.y = this.y + 0.1 * 1.75
        bomb_trail(this, 3, 0.4, 25)
    end

    if this.y > p1.y - 18 then
        this.y = this.y + 5
    else
        this.fire_time = this.fire_time - 1
        if this.fire_time <= 0 then
            drop_bomb(this)
            this.fire_time = 1000
        end
    end
end

function ak_drop_bomb(this)
    if #als ~= 0 and math.random() * 20 < 8 then
        drop_bomb(this)
    end
end

function au_lissajous(this)
    local b = 2
    local t = (this.t + this.id * 0.4) * 0.08
    this.x = (30 + b * 10) * math.sin(2 * PI * (t * 3 + b * 3 + 0.5)) * 1.75 + 112
    this.y = (this.t * 2 + (b * 10) * math.sin(t * b * 2 * 2 * PI) + 30) * 1.75
    this.t = this.t + 1 / 60
end

function ad_pe_laser(this)
    local offx = (math.random() * 3 - 1) * 1.75
    spr(27, this.x + offx, this.y, 1, 1)

    local x = this.x + 6 + offx
    local y1 = this.y + 14
    local y2 = this.ly

    local delta = this.timer

    if delta > 80 then
        line(x, y1, x, y2, 8)
        line(x + 1, y1, x + 1, y2, 8)
    else
        line(x - 1, y1, x - 1, y2, 14)
        line(x, y1, x, y2, 7)
        line(x + 1, y1, x + 1, y2, 7)
        line(x + 2, y1, x + 2, y2, 14)
    end
end

function can_hit_ship(p)
    return p.inv <= 0 and not p.dead
end

function ship_hit(p)
    if p.shield > 0 then
        snd.play_pattern(10)
        p.shield = p.shield - 1
        p.shield_timer = 10
        flash_screen(5, 8)
    else
        explode(p.x + 7, p.y, 16, 7)
        explode(p.x + 7, p.y, 9, 10)
        add_smoke(p.x + 7, p.y, 5, 5)
        p.dead = true
        p.dead_timer = 200
        p.f_elapsed = 0
        snd.play_pattern(5)
        snd.play_pattern(6)
    end
end

function au_pinkeye(this)
    local t1 = (elapsed() + this.id * 74)
    if this.state == 0 then
        if this.y > p1.y - 18 then
            this.y = this.y + 6
        elseif this.y > 8 and math.floor(t1) % 13 == 0 then
            this.state = 1
        else
            local t = (elapsed() + this.id * 2.1) * 0.03
            this.x = this.x + (math.sin(2 * PI * t * 10) * 0.1) * 1.75
            if math.sin(2 * PI * t * 20) > 0 then
                this.y = this.y + 0.175
            end
        end
    elseif this.state == 1 then
        this.ly = this.y + 10
        this.draw = ad_pe_laser
        this.timer = 100
        this.state = 2
        snd.play_pattern(7)
    elseif this.state == 2 then
        if can_hit_ship(p1) and collide(p1.x + 2, p1.y + 7, 7, 14, this.x, this.y, 1, this.ly - this.y) then
            ship_hit(p1)
        end

        this.y = this.y - 0.1
        if this.ly < 224 then
            this.ly = this.ly + 10
            add_smoke(this.x, this.ly - 7, 5, 1)
            add_smoke(this.x, this.ly, 2, 10)
        else
            add_smoke(this.x, this.ly, 2, 10)
        end

        this.timer = this.timer - 1
        if this.timer <= 0 then
            this.state = 0
            this.draw = nil
            -- snd.play_pattern(-1,2)
        end
    end
end

function au_golden(this)
    local t = (elapsed() + this.id * 2.1) * 0.03
    this.x = this.x + math.sin(2 * PI * t * 10) * 0.1 * 1.75

    if math.sin(2 * PI * t * 20) > 0 then
        this.y = this.y + 0.175
        bomb_trail(this, 9, 0.4, 25)
    end

    if this.y > p1.y - 18 then
        this.y = this.y + 5
    else
        this.fire_time = this.fire_time - 1
        if this.fire_time <= 0 then
            local trg = {}
            trg.x = p1.x
            trg.y = p1.y
            local m = create_missile(this.x + 7, this.y + 7, trg)
            m.hurt = 0
            m.shield = 1
            m.tcol = 10
            m.scr = 50
            table.insert(als, m)
            this.fire_time = 1000
        end
    end
end

function next_wave()
    wave = wave + 1
    bonus = 100
    wave_score = 0

    if wave >= 5 then
        p1.twin_lasers = true
    end

    local i = 1
    local WAVE = WAVES[wave % max_wave + 1]
    local wave_count = #WAVE
    for sy = 1, wave_count do
        local LINE = WAVE[sy]
        for sx = 1, 8 do
            local c = LINE:sub(sx, sx)
            if c ~= " " then
                local a = {}
                a.id = i
                a.hurt = 0
                a.x = (sx - 1) * 25 + 20
                a.ty = (sy - 1) * 25 + 20
                a.kill = nil

                if c == "0" then
                    a.sprite = 3
                    a.shield = 1
                    a.anim = create_anim({3, 19})
                    a.update = au_zigzag
                    a.fire_time = math.random() * 800
                    a.scr = 50
                elseif c == "1" then
                    a.sprite = 4
                    a.shield = 2
                    a.anim = create_anim({4, 20})
                    a.update = au_zigzag
                    a.kill = ak_drop_bomb
                    a.fire_time = math.random() * 800
                    a.scr = 100
                elseif c == "3" then
                    a.sprite = 8
                    a.shield = 4
                    a.anim = create_anim({8, 24})
                    a.update = au_lissajous
                    a.t = (a.ty - 60) / 2
                    a.update(a)
                    a.ty = a.y
                    a.scr = 150
                elseif c == "2" then
                    a.sprite = 11
                    a.shield = 6
                    a.state = 0
                    a.update = au_pinkeye
                    a.scr = 200
                    a.anim = nil
                elseif c == "4" then
                    a.sprite = 21
                    a.shield = 8
                    a.update = au_golden
                    a.fire_time = math.random() * 800
                    a.scr = 250
                    a.anim = nil
                end
                a.draw = nil
                a.to_remove = false
                a.y = a.ty - 224 - math.abs(a.x - 112) * 10 - ((224 - a.ty))
                table.insert(als, a)
                i = i + 1
            end
        end
    end
end

function calc_bonus()
    local s = wave_score * (bonus * 0.01)
    return math.floor(s * 0.1) * 5
end

function anim_update(a)
    a.t = a.t + 1
    if a.t > a.d then
        a.t = 0
        a.i = (a.i + 1) % #a.s
    end
    return a.s[a.i + 1]
end

function update_game()
    if not p1.dead then
        trail(p1)

        local pty = 178
        if p1.y > pty then
            p1.y = p1.y - (p1.y - pty) * 0.1
            if p1.y < pty + 1 then
                p1.y = pty
            end
        else
            p1.dx = p1.dx * 0.82

            if inp.right() > 0 and p1.dx < 7 then
                p1.dx = p1.dx + 0.8
            end
            if inp.left() > 0 and p1.dx > -7 then
                p1.dx = p1.dx - 0.8
            end
            if inp.action1() then
                fire_laser(p1)
            end
            if inp.action2_pressed() then
                fire_missile(p1)
            end

            p1.x = math.clamp(p1.x + p1.dx, 0, 210)

            if p1.f_elapsed > 0 then
                p1.f_elapsed = p1.f_elapsed + 1
                if p1.f_elapsed > 10 then
                    p1.f_elapsed = 0
                end
            end
        end

        if p1.shield_timer > 0 then
            p1.shield_timer = p1.shield_timer - 1
        end

        if p1.inv > 0 then
            p1.inv = p1.inv - 1
        end
    else
        if p1.dead_timer == 0 then
            if p1.lives > 0 then
                new_life(p1)
            else
                if inp.action1() then
                    show_titles()
                end
            end
        else
            p1.dead_timer = p1.dead_timer - 1
            if p1.dead_timer > 120 and math.random() * 15 < 2 then
                local ex = p1.x + math.random() * 14
                local ey = p1.y + math.random() * 14
                explode(ex, ey, 7 + math.random() * 7, 10)
                add_smoke(ex, ey, 5, 5)
                shake = p1.dead_timer - 120
            end
        end
    end

    local to_remove = {}
    for i, l in pairs(lrs) do
        if not l.to_remove then
            if l.update ~= nil then
                l.update(l)
            else
                l.y = l.y - 10
                if l.y < 0 then
                    local ey = l.y + math.random() * 35
                    explode(l.x + 7, ey, 5, 9)
                    add_smoke(l.x + 7, ey - 4, 2, 5)
                    l.to_remove = true
                end
            end
        end
        if l.to_remove then
            table.insert(to_remove, i)
        end
    end
    for i = #to_remove, 1, -1 do
        table.remove(lrs, to_remove[i])
    end

    to_remove = {}
    for i, pu in pairs(powerups) do
        if collide(pu.x, pu.y, 14, 14, p1.x, p1.y, 14, 28) then
            pu.action()
            table.insert(to_remove, i)
            flash_screen(10, 14)
            snd.play_pattern(9)
            explode(pu.x + 7, pu.y + 7, 15, 7)
        else
            pu.y = pu.y + 1.2
            pu.x = pu.x + 1.75 * math.sin(pu.y * 0.1 * 2 * PI)
            bomb_trail(pu, 4, 0.4, 25)

            if pu.y > 224 then
                table.insert(to_remove, i)
            end
        end
    end
    for i = #to_remove, 1, -1 do
        table.remove(powerups, to_remove[i])
    end

    if #als == 0 and wave_timer < 0 then
        warp_speed()
    end

    if wave_timer == 0 then
        -- snd.play_pattern(-1,3)
        next_wave()

        wave_timer = -1
        warp = 0
    elseif wave_timer > 0 then
        wave_timer = wave_timer - 1
        if wave_timer < 40 then
            warp = warp - 0.5
        elseif wave_timer > wt_max - 40 then
            warp = warp + 0.5
        end

        if bonus > 0 then
            if wave_timer % 2 == 0 then
                local pre = calc_bonus()
                bonus = bonus - 2
                if bonus < 0 then
                    bonus = 0
                end
                local post = calc_bonus()

                add_score(pre - post)
            end
        end
    end

    local can_hit = can_hit_ship(p1)

    to_remove = {}
    for i, a in pairs(als) do
        if not a.to_remove then
            if a.anim ~= nil then
                a.sprite = anim_update(a.anim)
            end

            local coly = p1.y + 7
            if p1.shield > 0 then
                coly = coly - 18
            end

            if a.ty ~= nil then
                bomb_trail(a, 1, 0.1, 20)

                local dy = a.ty - a.y
                a.y = a.y + dy * 0.05
                if a.y >= a.ty - 1 then
                    a.y = a.ty
                    a.ty = nil
                end
            else
                a.update(a)
                if a.y > 224 then
                    a.to_remove = true
                elseif can_hit and collide(a.x, a.y, 14, 14, p1.x, coly, 14, 21) then
                    kill_alien(a, 1)
                    ship_hit(p1)
                end
            end

            for _, l in pairs(lrs) do
                if collide(l.x + 7, l.y, 4, 4, a.x, a.y, 14, 14) then
                    if l.explode ~= nil then
                        l.explode(l)
                    else
                        kill_alien(a, 1)
                    end
                    l.to_remove = true
                end
            end

            if a.hurt > 0 then
                a.hurt = a.hurt - 1
            end
        end
        if a.to_remove then
            table.insert(to_remove, i)
        end
    end
    for i = #to_remove, 1, -1 do
        table.remove(als, to_remove[i])
    end

    to_remove = {}
    for i, e in pairs(exp) do
        e.ttl = e.ttl - 1
        if e.ttl <= 0 then
            table.insert(to_remove, i)
        end
    end
    for i = #to_remove, 1, -1 do
        table.remove(exp, to_remove[i])
    end

    to_remove = {}
    for i, s in pairs(smoke) do
        s.ttl = s.ttl - 1
        s.x = s.x + s.dx
        s.y = s.y + s.dy
        if s.ttl <= 0 then
            table.insert(to_remove, i)
        end
    end
    for i = #to_remove, 1, -1 do
        table.remove(smoke, to_remove[i])
    end

    if pu_drop_timer > 0 then
        pu_drop_timer = pu_drop_timer - 1
    end

    if xlife_timer > 0 then
        xlife_timer = xlife_timer - 1
    end

    if warp == 0 and bonus > 0 then
        bonus = bonus - 0.1
        if bonus < 0 then
            bonus = 0
        end
    end

    update_stars()
end

function clear_screen(f)
    if f == nil or f.timer < 0 then
        rectfill(0, 0, 223, 223, 0)
    else
        rectfill(0, 0, 223, 223, f.col)
        f.timer = f.timer - 1
    end
end

function ppad(n, l, x, y, col)
    local v = math.abs(n)
    if v == 0 then
        _print("0000000", x, y, 8)
    else
        local s = "" .. v
        l = l - #s
        for i = 1, l do
            _print("0", x, y, 8)
            x = x + 8
        end
        _print(s, x, y, col)
    end
end

function draw_ui()
    if ui_y < 1 then
        ui_y = ui_y + (1 - ui_y) * 0.06
        if ui_y > 0.5 then
            ui_y = 1
        end
    end

    _print("score", 92, ui_y, 12)
    ppad(p1.score, 7, 85, ui_y + 14, 7)

    _print("lives", 8, ui_y, 12)
    local ly = ui_y + 14
    local lx = 24 - p1.lives * 2.5
    for i = 1, p1.lives do
        if i == p1.lives and xlife_timer > 0 then
            if xlife_timer % 8 < 4 then
                sprc(22, lx, ly, 1, 1, 8)
            end
        else
            spr(22, lx, ly, 1, 1)
        end
        lx = lx + 8
    end

    _print("wave", 192, ui_y, 12)
    local swav = "" .. wave
    if wave < 10 then
        _print("0", 200, ui_y + 14, 8)
        _print(swav, 208, ui_y + 14, 7)
    else
        _print(swav, 200, ui_y + 14, 7)
    end

    if bonus >= 20 or bonus % 2 < 1 then
        local bw = 54
        local bx1 = 112 - bw * 0.5
        line(bx1, ui_y + 10, bx1 + bw, ui_y + 10, 1)

        if bonus > 0 then
            local cols = {8, 9, 10, 7}
            local col = cols[math.floor(bonus / 25) + 1]
            local bx2 = bx1 + math.floor(bw * bonus * 0.01)
            line(bx1, ui_y + 10, bx2, ui_y + 10, col)
        end
    end

    local my = 224 - 16
    for i = 1, p1.missiles do
        local x = (ui_y * i) + i * 8
        spr(6, x, my, 1, 1)
    end

    local sx = 210
    for i = 1, p1.shield do
        local x = (-ui_y * i) + sx - i * 8
        spr(7, x, my, 1, 1)
    end
end

function draw_banner(msg, timer, tmax, col)
    local buffer = 50
    local banh = 7

    local d = timer < 22 + buffer and timer - buffer or tmax - timer - buffer

    if d > 0 then
        local h = math.min(banh, (d - 16) * 0.75)

        if d < 16 then
            line(0, 112, d * 7, 112, 8)
            line(223, 112, 223 - d * 7, 112, col)
        else
            rectfill(0, 112 - h, 223, 112 + h, col)
            rect(-1, 112 - h - 2, 224, 112 + h + 2, 7)
        end

        if h >= 2 then
            local x1 = (100 - (timer * 0.5)) * 1.75
            _print(msg, x1, 108, 7)
        end
    end
end

function draw_game()
    clear_screen(flash)
    draw_stars()
    for _, s in pairs(smoke) do
        circfill(s.x, s.y, s.ttl * 0.2, s.col)
    end

    for _, l in pairs(lrs) do
        spr(l.sprite, l.x, l.y, 1, 1)
    end

    local py = p1.y
    if p1.f_elapsed > 0 and p1.f_elapsed < 5 then
        spr(9, p1.x, p1.y - 7, 1, 1)
    end

    if not p1.dead and (p1.inv <= 0 or p1.inv % 6 < 3) then
        if p1.shield_timer > 0 then
            local y = py + 2 + p1.shield_timer * 2
            local r = p1.shield_timer + 15
            circfill(p1.x + 4, y - 2, r, 7)
            circfill(p1.x + 4, y, r, 2)
            circfill(p1.x + 4, y + 10, r * 1.15, 0)
            sprc(1, p1.x, py, 1, 2, 8)
        else
            spr(1, p1.x, py, 1, 2)
        end
    end

    local t = elapsed()
    for _, a in pairs(als) do
        if a.draw == nil then
            if a.hurt > 0 then
                local f = 1 + a.hurt / 10
                local w = 8 * f
                local h = 8 * f
                local x = a.x - (w - 8) * 0.5
                local y = a.y - (h - 8) * 0.5
                ssprc(a.sprite, x, y, w, h)
            else
                spr(a.sprite, a.x, a.y, 1, 1)
            end
        else
            a.draw(a)
        end
    end

    for _, pu in pairs(powerups) do
        spr(pu.sprite, pu.x, pu.y, 1, 1)
    end

    for _, e in pairs(exp) do
        circfill(e.x, e.y, e.ttl * 2, e.col)
    end

    draw_ui()

    if warp > 0 then
        local b = calc_bonus()

        if bonus > 0 then
            printc("+" .. b, 31, 7)
        end

        local nw = wave + 1
        draw_banner("wave " .. nw, wave_timer, wt_max, 8)
    end

    if (shake > 0) then
        camera(math.random() * 4 - 2, math.random() * 4 - 2)
        shake = shake - 1
    else
        camera(0, 0)
    end
    if p1.dead and p1.lives <= 0 then
        waggle(32, 42, 52, 10, 2)
        printc("the galaxy", 105, 12)
        printc("is safe once more..", 113, 12)
        draw_pressmsg("in shame", 57, 128)

        printc("(c) joe trewin", 150, 7)
        printc("http:--fistfulofsquid.com", 158, 7)
        printc("@joeyspacerocks", 166, 7)
        printc("viper port: jice", 182, 7)
    end
end

function new_game()
    scrn.update = update_game
    scrn.draw = draw_game

    shake = 0
    ui_y = -35

    p1.score = 0
    p1.lives = 4
    p1.dead = false
    p1.dead_timer = -1
    p1.missiles = 3
    p1.twin_lasers = false
    p1.max_shields = 2
    p1.dead = false

    new_life(p1)
    p1.y = 1000

    als = {}

    wave = 0
    warp_speed()
end

function create_stars()
    for i = 1, 20 do
        local s = {}
        s.x = math.random() * 223
        s.y = math.random() * 223
        s.dy = 0.5 + math.random()
        if s.dy > 1.45 then
            s.dy = 4
        end
        s.col = s.dy < 1.2 and 1 or 7
        table.insert(stars, s)
    end
end

function init_music()
    for _, sfx in pairs(SFX) do
        snd.new_pattern(sfx)
    end
    snd.new_instrument(INST_TRIANGLE)
    snd.new_instrument(INST_TILTED)
    snd.new_instrument(INST_SAW)
    snd.new_instrument(INST_SQUARE)
    snd.new_instrument(INST_PULSE)
    snd.new_instrument(INST_ORGAN)
    snd.new_instrument(INST_NOISE)
    snd.new_instrument(INST_PHASER)
end

function init()
    inp.set_ls_neutral_zone(0.2)
    gfx.set_layer_size(LAYER_SPRITE, SPRITESHEET_SIZE, SPRITESHEET_SIZE)
    gfx.set_active_layer(LAYER_SPRITE)
    gfx.load_img("sprites", "tsi/tsi.png")
    gfx.set_active_layer(0)
    gfx.set_sprite_layer(LAYER_SPRITE)
    gfx.set_scanline(gfx.SCANLINE_HARD)
    gfx.activate_font(LAYER_SPRITE, 0.0, 139.0, 128.0, 48.0, 8.0, 8.0,
        "@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~¤!\"#$%&'()*+,-./0123456789:;<=>?")
    create_blobs()
    create_stars()
    show_titles()
    init_music()
end

function update()
    scrn.update()
end
function render()
    scrn.draw()
    -- screen border masks
    gfx.rectangle(0, 0, gfx.SCREEN_WIDTH, Y_OFFSET, 0, 0, 0)
    gfx.rectangle(0, Y_OFFSET, X_OFFSET, SCREEN_SIZE, 0, 0, 0)
    gfx.rectangle(X_OFFSET + SCREEN_SIZE, Y_OFFSET, gfx.SCREEN_WIDTH - X_OFFSET - SCREEN_SIZE, SCREEN_SIZE, 0, 0, 0)
    gfx.rectangle(0, Y_OFFSET + SCREEN_SIZE, gfx.SCREEN_WIDTH, gfx.SCREEN_HEIGHT - SCREEN_SIZE - Y_OFFSET, 0, 0, 0)
end

INST_TRIANGLE = "INST OVERTONE 1.0 TRIANGLE 1.0 METALIZER 0.85 NAM triangle"
INST_TILTED = "INST OVERTONE 1.0 TRIANGLE 0.5 SAW 0.1 NAM tilted"
INST_SAW = "INST OVERTONE 1.0 SAW 1.0 ULTRASAW 1.0 NAM saw"
INST_SQUARE = "INST OVERTONE 1.0 SQUARE 0.5 NAM square"
INST_PULSE = "INST OVERTONE 1.0 SQUARE 0.5 PULSE 0.5 TRIANGLE 1.0 METALIZER 1.0 OVERTONE_RATIO 0.5 NAM pulse"
INST_ORGAN = "INST OVERTONE 0.5 TRIANGLE 0.75 NAM organ"
INST_NOISE = "INST NOISE 1.0 NOISE_COLOR 0.2 NAM noise"
INST_PHASER = "INST OVERTONE 0.5 METALIZER 1.0 TRIANGLE 0.7 NAM phaser"

SFX =
    {"PAT 1 G.4070 F#4070 D#4070 C.4070 A.3070 F#3070 F.3070 D.3070 C.3070 A#2070 C.1000 C.1000 C.1000 C.1000 C.1000 C.1000 C.1000 C.1000 C.1000 C.1000 C.1000 C.1000 C.1000 C.1000 C.1000 C.1000 C.1000 C.1000 C.1000 C.1000 C.1000 C.1000 ",
     "PAT 2 F#4640 G#4650 G#4650 G#4650 G.4660 D.4660 A#3650 A#3650 A#3640 A#3640 A#3640 B.4640 F#3640 F.3650 D#3650 D.3650 F#2640 F.2640 A#2650 D.2640 A.2630 G#2630 B.1630 F#2620 F.2620 A.1610 D#2610 F#1600 C.2600 F.1600 A.1600 G#1600 ",
     "PAT 3 A.5640 A.5640 A.5640 A.5650 D#4650 A.5660 A.5660 G#5650 E.5640 C.5640 A.4640 C.4640 E.3640 C#3650 G#2650 F.3650 F.3650 D#2650 C.2650 A#1660 D.2650 A#1650 G.3640 D.2630 A#1630 C.2620 D.2620 E.2620 A.2610 D.3610 F#3610 C.4600 ",
     "PAT 2 A#4350 B.4360 F.5360 C#5350 E.5350 B.4350 A.4350 F#5350 G.5350 G#5350 D.4350 C.4350 A.3340 G#3340 B.2330 C#3340 A.3350 E.3350 E.3360 D.3360 C.3350 A.3340 C#3330 G#2330 C#3320 F#2320 E.4320 E.2320 D#3320 A.4310 F.3310 C#2310 ",
     "PAT 6 G#1570 A.1570 B.1570 C#2570 E.2570 F#2570 G#2570 A#2570 C.3570 C#3570 D#3570 F.3570 G#3570 B.3570 D.4570 F.4570 G.4570 C.1000 C.1000 C.1000 C.1000 C.1000 C.1000 C.1000 C.1000 C.1000 C.1000 C.1000 G.5500 C.1000 C.1000 C.1000 ",
     "PAT 3 E.4670 G.4670 C.5670 F.3670 C.3670 A#4670 D.5670 C.5670 F.4670 D#4650 C#3650 G#2650 B.3650 F#3660 F.3670 D#3670 G#2670 F#2660 A.2640 C.3640 D#3650 E.3640 E.3640 C#3640 B.2640 G#2640 F#2630 E.2620 D.2620 C.2620 C.2610 C#2610 ",
     "PAT 3 G#2070 A#2070 C#3070 F.3070 G#3070 C#4070 F#4070 A.1070 C#2070 F#2070 C.3070 F.3070 A#3070 D.4070 D#4070 B.1070 D#2070 A#2070 G.3070 C#4070 D#4070 A.2170 B.1060 E.2050 G#2040 D#3040 G#3030 C#4030 D.4030 C.2130 B.1120 A.1110 ",
     "PAT 2 B.1770 C.2770 C#2770 D.2770 D#2770 E.2770 E.2770 D#2770 D.2770 C#2770 C#2770 C#2770 D#2770 E.2770 F.2770 G.2770 A#2770 C.3770 C#3770 D#3770 G.3770 A.3770 F.3770 B.2770 F#2770 E.2770 E.2770 D#2770 D#2770 D#2770 D#2770 F.2770 ",
     "PAT 6 G#3770 D.4770 D#4760 B.3760 B.3750 G#3750 A.3750 D#4750 D#4740 G#3740 B.2740 B.2740 C#3740 F#3740 A#2730 C.3730 C.3730 G.2730 C#3720 C#3720 D.3720 G.2710 G.2720 D#3720 E.3720 D.3710 E.3710 C#2710 C.2700 A#1700 A.1700 A.1700 ",
     "PAT 5 A#1770 A.3770 A#4770 A.5770 B.1770 B.3770 A#3770 D.2770 F.4770 E.2770 C#4770 C#4770 G.2770 A#4770 A.2760 E.4760 E.4760 C.3750 C#3750 G#4750 G#5740 E.3740 A#4740 A#4730 A.3730 G#5730 C.4720 C#5720 D#4720 E.4710 F#5710 A#5710 ",
     "PAT 1 G.1070 B.1070 E.2070 F#2070 A#2070 C.3070 C#3070 C#3070 C#3070 B.2070 B.2070 A#2070 A.2070 G#2070 G#2070 G.2070 G.2070 G.2070 F#2070 F.2070 F.2070 E.2070 D#2060 D#2050 D.2050 D.2040 D.2040 D#2030 E.2030 F.2010 F.2010 F.2010 ",
     "PAT 3 A.3575 F#4575 A.4575 A.4575 C#4575 B.2575 G#2575 C#3575 E.3575 G.3575 A#3575 A#3575 F#3575 B.2575 A.2565 G#2565 G#2565 A#2555 D.3555 D.3555 C#3545 A.2545 E.2545 D.2535 C.2535 F.2535 F#2525 D#2525 A#1525 C#2505 E.2505 A#1505 "}
