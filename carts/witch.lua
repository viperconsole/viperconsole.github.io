--by matthieu le gallic
--& dustin van wyk

-- pico8 compatibility layer
local X_OFFSET <const> = 80
local Y_OFFSET <const> = 10
local SPRITE_SIZE <const> = 8
local SPRITE_PER_ROW <const> = math.floor(128 / SPRITE_SIZE)
col = function(r, g, b)
    return { r = r, g = g, b = b }
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
    col(255, 204, 170),
}

function sfx(n)
    snd.play_pattern(n)
end

function music(n,fade_len,channel_mask)
    snd.play_music(0,15)
end

function picosin(v)
    return math.sin(from_pico_angle(v))
end

function picocos(v)
    return math.cos(from_pico_angle(v))
end

function from_pico_angle(v)
    return v < 0.5 and -v * 2 * math.pi or (1 - v) * 2 * math.pi
end

function reload()
    TILE_MAP={}
    for _,i in ipairs(TILE_MAP_ROM) do
        table.insert(TILE_MAP,i)
    end
end

function mget(x,y)
    return TILE_MAP[math.floor(x) + math.floor(y) * 128 + 1] or 0
end

function mset(x,y,v)
    TILE_MAP[x+y*128+1] = v
end

function fget(n,b)
    return SPRITE_FLAGS[n+1] & (1<<b) > 0
end

function del(t,o)
    for i=1,#t do
        if t[i] == o then
            table.remove(t,i)
            break
        end
    end
end

function sgn(f)
    return f < 0 and -1 or f > 0 and 1 or 0
end

function rectfill(x0, y0, x1, y1, pal)
    local col = PAL[pal]
    local x0 = x0 + X_OFFSET
    local x1 = x1 + X_OFFSET
    local y0 = y0 + Y_OFFSET
    local y1 = y1 + Y_OFFSET
    gfx.rectangle(x0, y0, x1 - x0 + 1, y1 - y0 + 1, col.r, col.g, col.b)
end

function line(x1, y1, x2, y2, col)
    gfx.line(x1 + X_OFFSET, y1 + Y_OFFSET, x2 + X_OFFSET, y2 + Y_OFFSET, PAL[col].r, PAL[col].g, PAL[col].b)
end

function sprcol(n, x, y, w, h, col, hflip, vflip)
    local int_spr = math.floor(n)
    local spritex = (int_spr % SPRITE_PER_ROW) * SPRITE_SIZE
    local spritey = (int_spr // SPRITE_PER_ROW) * SPRITE_SIZE
    if h==nil then
        col=w
        w=1
        h=1
    end
    local c=PAL[col]
    gfx.blit_col(
        spritex,
        spritey,
        w * SPRITE_SIZE,
        h * SPRITE_SIZE,
        math.floor(x + X_OFFSET),
        math.floor(y + Y_OFFSET),
        c.r, c.g, c.b,
        nil,nil,nil,
        hflip,vflip
    )
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

function map(cx, cy, sx, sy, cw, ch, layer)
    cx=math.floor(cx)
    cy=math.floor(cy)
    for x = cx, cx + cw - 1 do
        for y = cy, cy + ch - 1 do
            local v = TILE_MAP[x + y * 128 + 1]
            if v~=nil then
                if SPRITE_FLAGS[v + 1] & layer ~= 0 then
                    local spritex = (v % SPRITE_PER_ROW) * SPRITE_SIZE
                    local spritey = (v // SPRITE_PER_ROW) * SPRITE_SIZE
                    gfx.blit(spritex, spritey, SPRITE_SIZE, SPRITE_SIZE,
                        sx + X_OFFSET + (x - cx) * SPRITE_SIZE,
                        sy + Y_OFFSET + (y - cy) * SPRITE_SIZE
                    )
                end
            end
        end
    end
end

function gprint(msg, px, py, col)
    local c = PAL[math.floor(col)]
    gfx.print(gfx.FONT_4X6, msg, math.floor(px) + X_OFFSET, math.floor(py) + Y_OFFSET, c.r, c.g, c.b)
end

function pal(a, b)
end

function palt(a, b)
end

function btnp(num)
    if num == 2 then
        return inp.up_pressed()
    elseif num == 3 then
        return inp.down_pressed()
    elseif num == 4 then
        return inp.action1_pressed()
    elseif num == 5 then
        return inp.action2_pressed()
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
        return inp.action2()
    elseif num == 5 then
        return inp.action1()
    end
end

--
--player entity
--
player =
{
    hitbox = { x = 5, y = 6, w = 6, h = 8 },
    init = function(this)
        this.x = -48
        this.y = 56
        this.life = lifemax
        this.pow = 0
        this.powtimer = 0
        this.rapidtime = 5
        this.rbubl = 0
        this.rapid = 0
        this.movespd = 2
        this.anim = 0
        this.move = false
        this.hurt = 0
        bosslife = -1

        --reload map (restore enemies)
        --useful for respawns
        reload()

        --music
        music(16 * (lvl % 2))
    end,
    hit = function(this)
        if this.hurt == 0 then
            this.life = this.life - 1
            this.hurt = 60
            sfx(13)

            --death
            if this.life == 0 then
                this.move = false
                lives = lives - 1
                deaths = deaths + 1

                --fade out music
                if lives == 0 then
                    music(-1, 1000)
                end

                --prepare game over screen
                choice = 0
            end
        end
    end,
    update = function(this)
        --animation
        this.anim = (this.anim + 0.25) % 8

        --rapid fire timers
        this.rapid = tick(this.rapid)
        this.rbubl = tick(this.rbubl)

        --powerup timer
        this.powtimer = tick(this.powtimer)
        this.pow = this.pow * math.min(1, this.powtimer)

        --shield timer
        this.hurt = tick(this.hurt)

        --respawn
        if this.life == 0 and this.hurt == 0 then
            this.x = 16
            this.y = 56

            while collmap(player) do
                this.y = math.floor(math.random()*122) - 6
            end

            --respawn
            if lives ~= 0 then
                this.move = true
                this.life = lifemax
                this.hurt = 60
            else
                --stop camera
                camspd = 0

                this.hurt = 1

                --update game over screen

                if btnp(2) or btnp(3) then
                    choice = 1 - choice
                end

                if btnp(4) or btnp(5) then
                    --restart level
                    enemies = {}
                    bullets = {}
                    lvlx = 0
                    camx = 0
                    sublvl = 0
                    lives = livesmax
                    score = 0

                    if choice == 1 then
                        --exit to main menu
                        sfx(13)
                        lvl = 0
                        screen = 0
                    else
                        sfx(12)
                        player:init()
                    end
                end
            end
        end

        --movement
        if this.move then
            if btn(0) then
                this.x = this.x - this.movespd
                while collmap(this) do
                    this.x = this.x + 1
                end
            end

            if btn(1) then
                this.x = this.x + this.movespd
                while collmap(this) do
                    this.x = this.x - 1
                end
            end

            if btn(2) then
                this.y = this.y - this.movespd
                while collmap(this) do
                    this.y = this.y + 1
                end
            end

            if btn(3) then
                this.y = this.y + this.movespd
                while collmap(this) do
                    this.y = this.y - 1
                end
            end
            this.x = clamp(this.x, -this.hitbox.x, 128 - this.hitbox.w - this.hitbox.x)
            this.y = clamp(this.y, -this.hitbox.y, 128 - this.hitbox.h - this.hitbox.y)
            --shoot
            if btn(4) and not btn(5)
                and this.rapid == 0 then
                addbullet(this.x + 10, this.y + 4, 6, 0, 0)
                if this.pow > 1 then
                    addbullet(this.x + 10, this.y + 2, 6, -2, 0, 0)
                    addbullet(this.x + 10, this.y + 6, 6, 2, 0, 0)
                end
                this.rapid = this.rapidtime
                addpart(this.x + 14, this.y + 5, 0, 0, 34, 1)
            end

            --bubble
            if btn(5) and this.rbubl == 0 then
                addbullet(this.x + 12, this.y + 10, 1, 0, 2)
                this.rbubl = this.rapidtime * 2
            end
        end

        --global variables
        xp = this.x + this.hitbox.x
        yp = this.y + this.hitbox.y
    end,
    draw = function(this)
        if this.life > 0 then
            local arm = 0

            if this.move and btn(4)
                and not btn(5) then
                arm = 1
            end

            drawwitch(this.x, this.y, 1, this.anim, arm, this.hurt > 0 and this.anim % 2 < 1 and 7 or nil)
        else
            --fall after dying
            spr(1, this.x - (60 - this.hurt), this.y + (20 - this.hurt / 3) ^ 2, 2, 2)
        end
    end
}

--
--bullet entity
--
bullet = {
    init = function(this)
        this.hitbox = { x = 1, y = 1, w = 5, h = 5 }
        if this.bultype == 1 then
            this.hitbox = { x = 2, y = 2, w = 3, h = 3 }
        end
    end,
    update = function(this)
        this.x = this.x + this.hspd
        this.y = this.y + this.vspd

        --bubble float
        if this.bultype == 2 then
            if this.y < water - 8 then
                this.vspd = this.vspd + 0.2
            else
                this.vspd = math.max(-1.5, this.vspd - 4)
            end
        end

        --collision with walls
        if collmap(this) or this.x < -4 or this.x > 124 or this.y < -4 or this.y > 124 then
            del(bullets, this)
        end

        --collision with player
        if this.bultype == 1 and collcheck(this.x + 2, this.y + 2, 3, 3, xp, yp, wp, hp) then
            player:hit()
        end
    end,
    draw = function(this)
        local sprite = { 32 + player.pow % 2, 38, 5 + player.anim % 2 }

        spr(sprite[this.bultype + 1], this.x, this.y)
    end
}

--
--particle entity
--
part = {
    --anim is offset by 1 frame
    --because it starts before the
    --object is drawn

    update = function(this)
        this.hspd = this.hspd * this.fric
        this.vspd = this.vspd * this.fric
        this.x = this.x + this.hspd
        this.y = this.y + this.vspd
        this.anim = this.anim + this.animspd
        if this.anim >= this.animmax + this.animspd then
            del(parts, this)
        end
    end,
    draw = function(this)
        spr(this.sprite + this.anim - this.animspd, this.x, this.y)
    end
}

--add a bullet
function addbullet(_x, _y, _hspd, _vspd, _bultype)
    local t = {
        x = _x,
        y = _y,
        hspd = _hspd,
        vspd = _vspd,
        bultype = _bultype
    }
    table.insert(bullets, t)
    bullet.init(t)
    return t
end

--add a particle
function addpart(_x, _y, _hspd, _vspd, _spr, _animspd)
    local t = {
        x = _x,
        y = _y,
        hspd = _hspd,
        vspd = _vspd,
        sprite = _spr,
        anim = 0,
        animspd = _animspd,
        animmax = 2,
        fric = 1
    }
    table.insert(parts, t)
    return t
end

--move bullet towards point
function movetowards(t, x2, y2, spd)
    t.hspd = spd * trigcos(t.x, t.y, x2, y2)
    t.vspd = spd * trigsin(t.x, t.y, x2, y2)
end

--add an enemy
function addenemy(_x, _y, _type)
    local t = {
        x = _x,
        y = _y,
        typ = _type
    }
    table.insert(enemies, t)
    _type.init(t)
    return t
end

--check for collision
function collcheck(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 + w1 > x2 and y1 + h1 > y2 and x2 + w2 > x1 and y2 + h2 > y1
end

--collision with map
function collmap(this,hitbox)
    local i, x, y, w, h, m, hit, arg
    hit = hitbox or this.hitbox

    x = (this.x + hit.x + camx) / 8
    y = (this.y + hit.y + 128 * lvl) / 8
    w = (hit.w) / 8
    h = (hit.h) / 8

    for i = 0, 8 do
        if i == 4 then i = i + 1 end
        m = mget(x + w * (i % 3) / 2, y + h * math.floor(i / 3) / 2)
        if fget(m, 0) and not fget(m, 1) then
            return true
        end
    end
end

--distance
function dist(x1, y1, x2, y2)
    return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
end

function trigcos(x1, y1, x2, y2)
    return (x2 - x1) / dist(x1, y1, x2, y2)
end

function trigsin(x1, y1, x2, y2)
    return (y2 - y1) / dist(x1, y1, x2, y2)
end

function clamp(x, a, b)
    return math.min(math.max(x, a), b)
end

function tick(t)
    return math.max(0, t - 1)
end

--print centered text
function printcnt(str, x, y, col)
    gprint(str, x - #str * 2, y - 3, col)
end

--change transparent color
function transcol(c)
    palt(0, false)
    palt(c, true)
end

--draw moon
function drawmoon(x, y)
    spr(16, x, y)
    spr(16, x + 8, y, 1, 1, true, false)
    spr(16, x, y + 8, 1, 1, false, true)
    spr(16, x + 8, y + 8, 1, 1, true, true)
end

--draw witch (player,final boss)
function drawwitch(x, y, xscale, anim, arm, col, fr)
    local i = 2 * math.floor(anim % 2)
    local y2 = y + picocos(anim / 8) + 0.5
    local hflip = xscale == -1
    local sproff = fr and 133 or hflip and 129 or 0

    if col then
        sprcol(1 + i + sproff, x, y2, 2, 1, col, hflip, false)
        sprcol(17 + i + sproff, x + 4 - 4 * xscale, y2 + 8, 1, 1, col, hflip, false)

        sprcol(18 + 2 * arm + sproff, x + 4 + 4 * xscale, y2 + 8, 1, 1, col, hflip, false)
    else
        spr(1 + i + sproff, x, y2, 2, 1, hflip, false)
        spr(17 + i + sproff, x + 4 - 4 * xscale, y2 + 8, 1, 1, hflip, false)

        spr(18 + 2 * arm + sproff, x + 4 + 4 * xscale, y2 + 8, 1, 1, hflip, false)
    end
end

--begin boss battle
function beginbattle(this)
    this.life = this.lifemax
    this.atk = 0
    this.t = this.tmax
    bosslife = this.life
    bosslifemax = this.lifemax
end

function cheat()
    lvlx = 3 * 127
    camx = 8 * (127 - 16)
    sublvl = 4
end

--function cheat2()
-- enemies[1].life=1
--end
-->8
--enemies

--enemy entity
enemy = {
    die = function(this)
        local i, obj

        for i = 0, 7 do
            obj = addpart(this.x, this.y, 4 * picocos(i / 8), 4 * picosin(i / 8), 36, 0.25)
            obj.fric = 0.75
        end

        if camspd > 0 then
            score = score + math.floor(this.typ.pts * multiplier / 10)
            scoretimer = 45
            multiplier = math.min(50, multiplier + 2)
        end
        del(enemies, this)

        sfx(10)
    end,
    update = function(this)
        --enemy-specific code
        this.typ.update(this)

        if this.anim ~= -1 then
            this.anim = (this.anim + 1) % this.animmax
        end

        local x1, y1, w1, h1

        x1 = this.x + this.typ.hitbox.x
        y1 = this.y + this.typ.hitbox.y
        w1 = this.typ.hitbox.w
        h1 = this.typ.hitbox.h

        if this.life >= 0 then
            --collision checking
            local i=1
            while i <= #bullets do
                local obj=bullets[i]
                if obj.bultype ~= 1 then
                    local x2, y2, h2, w2
                    x2 = obj.x + obj.hitbox.x
                    y2 = obj.y + obj.hitbox.y
                    w2 = obj.hitbox.w
                    h2 = obj.hitbox.h

                    if collcheck(x1, y1, w1, h1, x2, y2, w2, h2) then
                        if player.life > 0 then
                            if player.pow == 1 or obj.bultype == 2
                            then
                                this.life = this.life - 2
                            else
                                this.life = this.life - 1
                            end
                        end

                        if this.life <= 0 then
                            if this.typ.die ~= -1 then
                                this.typ.die(this)
                            else
                                enemy.die(this)
                            end
                        else
                            addpart(obj.x, obj.y, 0, 0, 34 - obj.bultype * 6.5, 0.25)
                            this.flash = 4
                            sfx(11)
                        end
                        del(bullets, obj)
                    else
                        i=i+1
                    end --end if(collcheck)
                else
                    i=i+1
                end
            end
        end --end of bullet  collision check

        --collision with player
        if collcheck(x1, y1, h1, w1, xp, yp, wp, hp) then
            player:hit()
        end
    end,
    draw = function(this)
        this.typ.draw(this)
        if this.flash > 0 then
            this.flash = this.flash - 1
        end
    end
}

--bat
bat = {
    hitbox = { x = 2, y = 2, w = 4, h = 4 },
    die = -1,
    pts = 5,
    init = function(this)
        this.flash = -1
        this.life = 1
        this.y0 = this.y
        this.anim = (this.x / 2) % 32
        this.animmax = 32
    end,
    update = function(this)
        this.y = this.y0 + 3 * (picocos(this.anim / 32))
        this.x = this.x - camspd
        if (this.x < -8) then
            del(enemies, this)
        end
    end,
    draw = function(this)
        if this.flash > 0 then
            sprcol(48 + (this.anim / 4) % 2, this.x, this.y,7)
        else
            spr(48 + (this.anim / 4) % 2, this.x, this.y)
        end
    end
}

--frog
frog = {
    hitbox = { x = 1, y = 1, w = 6, h = 6 },
    die = -1,
    pts = 10,
    init = function(this)
        this.flash = 0
        this.life = 2
        this.anim = -1
        this.y0 = this.y
        this.t = math.floor(math.random()*90)

        --floor detection
        local i
        i = this.y // 8
        while fget(mget((this.x + camx) // 8, i + 16 * lvl), 0) == false do
            i = i + 1
        end

        this.y0 = i * 8 - 8
    end,
    update = function(this)
        local shoot = false

        this.x = this.x - camspd
        this.t = (this.t - 1) % 90
        if this.t > 30 then
            this.y = this.y0 + 64 * picosin((this.t - 30) / 120)
        else
            this.y = this.y0
        end

        --collision with ceiling
        if this.t > 60 and collmap(this, frog.hitbox) then
            this.t = 60 - (this.t - 60)
            shoot = true
        end

        --shoot
        if this.t == 60 or shoot then
            movetowards(addbullet(this.x - 4, this.y, 0, 0, 1), player.x + 4, player.y + 4, 2)
            shoot = false
        end

        if this.x < -8 then
            del(enemies, this)
        end
    end,
    draw = function(this)
        local img = 0
        if (this.t > 30) then img = 1 end

        transcol(1)
        if this.flash > 0 then
            sprcol(50 + img, this.x, this.y,7)
        else
            spr(50 + img, this.x, this.y)
        end
    end
}

caul = {
    hitbox = { x = 0, y = 0, w = 8, h = 8 },
    die = -1,
    pts = 10,
    init = function(this)
        this.anim = 0
        this.animmax = 8
        this.life = 5
        this.flash = 0
        this.t = 0

        --floor detection
        local i = this.y / 8
        while fget(mget((this.x + camx) / 8, i + 16 * lvl), 0) == false do
            i = i + 1
        end

        this.y = i * 8 - 8
    end,
    update = function(this)
        this.t = (this.t - 1) % 20
        this.x = this.x - camspd
        --shoot
        if this.t == 0 then
            local t, rdir
            t = addenemy(this.x, this.y - 4, fire)
            rdir = 0.125 + math.random()*0.25
            t.hspd = -camspd + 2 * picocos(rdir)
            t.vspd = 2 * picosin(rdir)
        end
    end,
    draw = function(this)
        if this.flash > 0 then
            sprcol(52, this.x, this.y, 7)
        else
            if this.anim >= 4 then
                spr(128, this.x, this.y)
            else
                spr(52, this.x, this.y)
            end
        end
    end
}

fire = {
    hitbox = { x = 1, y = 1, w = 6, h = 6 },
    init = function(this)
        this.flash = -1
        this.life = -1
        this.anim = 0
        this.animmax = 8
    end,
    update = function(this)
        this.x = this.x + this.hspd
        this.y = this.y + this.vspd

        if collmap(this, fire.hitbox) or not collcheck(this.x, this.y, 8, 8, 0, 0, 128, 128) then
            del(enemies, this)
        end
    end,
    draw = function(this)
        if this.flash > 0 then
            sprcol(53 + this.anim / 4, this.x, this.y, 7)
        else
            spr(53 + this.anim / 4, this.x, this.y)
        end
    end
}

ghost = {
    hitbox = { x = 1, y = 1, w = 5, h = 6 },
    die = -1,
    pts = 5,
    init = function(this)
        this.life = 1
        this.flash = -1
        this.anim = -1
        this.hspd = -camspd
        this.vspd = 2 * sgn(64 - this.y)
    end,
    update = function(this)
        this.x = this.x + this.hspd
        this.y = this.y + this.vspd

        if this.vspd < 0 and this.y < player.y + 4
            or this.vspd > 0 and this.y > player.y + 4 then
            this.vspd = 0
            this.hspd = -3 * math.max(1, camspd)
        end

        if this.x < -8 then
            del(enemies, this)
        end
    end,
    draw = function(this)
        if this.flash > 0 then
            sprcol(55, this.x, this.y, 7)
        else
            spr(55, this.x, this.y)
        end
    end
}

squid = {
    hitbox = { x = 1, y = 1, w = 6, h = 6 },
    die = -1,
    pts = 10,
    init = function(this)
        this.flash = 0
        this.life = 2
        this.anim = 0
        this.animmax = 32
        this.hspd = -camspd
        this.y = this.y + 64
        this.shot = false
    end,
    update = function(this)
        this.x = this.x - camspd
        this.y = this.y - (32 - this.anim) / 16

        if this.x < -8 or this.y < -8 then
            del(enemies, this)
        end

        if this.y < 48 and not this.shot then
            movetowards(addbullet(this.x, this.y, 0, 0, 1), player.x + 4, player.y + 4, 2)
            this.shot = true
        end
    end,
    draw = function(this)
        if this.flash > 0 then
            sprcol(57 - math.floor(this.anim / 24), this.x, this.y, 7)
        else
            spr(57 - math.floor(this.anim / 24), this.x, this.y)
        end
    end
}

fish =
{
    hitbox = { x = 0, y = 2, w = 8, h = 5 },
    die = -1,
    pts = 5,
    init = function(this)
        this.flash = -1
        this.life = 1
        this.anim = -1
        this.vspd = 0
        this.y0 = this.y
        this.y = this.y0 + math.random()*(water - 12 - this.y0)
        this.vspd = math.sqrt(this.y - this.y0) * 0.6
    end,
    update = function(this)
        this.vspd = this.vspd + 0.2
        this.x = this.x - 2 + camspd
        this.y = this.y + this.vspd

        if this.y >= water - 12 and this.vspd > 0 then
            this.y = this.y - this.vspd
            this.vspd = -this.vspd
        end
    end,
    draw = function(this)
        if this.flash > 0 then
            sprcol(58.5 + 0.5 * sgn(this.vspd), this.x, this.y, 7)
        else
            spr(58.5 + 0.5 * sgn(this.vspd), this.x, this.y)
        end
    end
}

urchin = {
    hitbox = { x = 1, y = 1, w = 6, h = 6 },
    init = function(this)
        this.life = -1
        this.flash = -1
        this.anim = -1
    end,
    update = function(this)
        this.x = this.x - camspd
        this.y = water - 6
        if this.x < -8 then
            del(enemies, this)
        end
    end,
    draw = function(this)
        if this.flash > 0 then
            sprcol(60, this.x, this.y, 7)
        else
            spr(60, this.x, this.y)
        end
    end
}

ship = {
    hitbox = { x = 1, y = 1, w = 6, h = 6 },
    die = -1,
    pts = 30,
    init = function(this)
        this.life = 12
        this.flash = 0
        this.anim = -1
    end,
    update = function(this)
        this.x = this.x - camspd - 0.5
        this.y = water - 12
        if this.x < -8 then
            del(enemies, this)
        end

        if lvlx % 4 == 0 then
            movetowards(addbullet(this.x, this.y, 0, 0, 1), player.x + 4, player.y + 4, 2)
        end
    end,
    draw = function(this)
        if this.flash > 0 then
            sprcol(61, this.x, this.y + 0.5 + picosin(lvlx / 4), 7)
        else
            spr(61, this.x, this.y + 0.5 + picosin(lvlx / 4))
        end
    end
}

torpedo = {
    hitbox = { x = 0, y = 1, w = 7, h = 5 },
    die = -1,
    init = function(this)
        this.anim = -1
        this.life = 2
        this.flash = 0
        this.hspd = 0
        this.vspd = 0
    end,
    update = function(this)
        this.hspd = this.hspd - 0.1
        this.vspd = this.vspd - 0.2 * this.hspd * sgn(player.y - this.y + 4)
        this.vspd = clamp(this.vspd, 0.2 * this.hspd, -0.2 * this.hspd)
        this.x = this.x + this.hspd
        this.y = this.y + this.vspd
        if this.x < -8 then
            del(enemies, this)
        end
    end,
    draw = function(this)
        if this.flash > 0 then
            sprcol(62, this.x, this.y, 7)
        else
            spr(62, this.x, this.y)
        end
    end
}

spike = {
    hitbox = { x = 1, y = 1, w = 5, h = 5 },
    init = function(this)
        this.life = -1
        this.flash = -1
        this.anim = -1
        this.vspd = -1
        if this.y < 64 then
            this.vspd = 1
        end
    end,
    update = function(this)
        this.x = this.x - camspd
        this.y = this.y + this.vspd
        if collmap(this, spike.hitbox)
            or this.y < 0 or this.y > water - 8
            or this.y > 120 then
            this.y = this.y - this.vspd
            this.vspd = -this.vspd
        end
    end,
    draw = function(this)
        spr(63, this.x, this.y)
    end
}

lavaball = {
    hitbox = { x = 2, y = 2, w = 13, h = 13 },
    init = function(this)
        this.life = -1
        this.anim = 0
        this.animmax = 30
        this.flash = -1
        this.height = water - 8 - this.y
        this.y = water + 4 + math.random()*8
        this.vspd = -0.5
    end,
    update = function(this)
        this.x = this.x - camspd
        this.y = this.y + this.vspd

        if this.vspd ~= 0 and this.y <= water - 8 then
            this.vspd = 0
            this.anim = 0
        end

        if this.y <= water - 8 then
            this.y = water - 8 + this.height * picosin(this.anim * 0.25 / 30)

            --explode
            if this.anim >= 29 then
                local i, s, c, t
                for i = 0, 7 do
                    s = picosin(0.125 * i)
                    c = picocos(0.125 * i)
                    t = addenemy(this.x + 4 + 4 * c, this.y + 4 + 4 * s, fire)
                    t.hspd = 2 * c - camspd
                    t.vspd = 2 * s
                end

                del(enemies, this)

                sfx(10)
            end
        end
    end,
    draw = function(this)
        drawmoon(this.x, this.y)
    end
}

witch = {
    hitbox = { x = 2, y = 0, w = 3, h = 7 },
    die = -1,
    pts = 30,
    init = function(this)
        this.life = 5
        this.anim = 0
        this.animmax = 32
        this.flash = -1
        this.vspd = 1 - 2 * math.floor(math.random()*2)
        this.y0 = this.y
    end,
    update = function(this)
        this.x = this.x - camspd / 2
        this.y = this.y + this.vspd

        --bullets
        if this.anim > 24 and this.anim % 2 == 0 then
            movetowards(addbullet(this.x - 4, this.y, 0, 0, 1), player.x + 4, player.y + 4, 3)
        end

        --revert vertical speed
        if this.y < 0 or this.y > 120 or math.abs(this.y - this.y0) > 16 then
            this.y = this.y - this.vspd
            this.vspd = -this.vspd
        end

        --outside the screen
        if this.x < -8 then
            del(enemies, this)
        end
    end,
    draw = function(this)
        if this.flash > 0 then
            sprcol(43, this.x, this.y, 7)
        else
            spr(43, this.x, this.y)
        end
    end
}

dragon = {
    hitbox = { x = 1, y = 1, w = 5, h = 5 },
    die = -1,
    pts = 5,
    init = function(this)
        this.balls = false
        this.btype = 0
        this.y0 = this.y
        this.anim = -1
        this.flash = 0
        this.life = 2
        this.offset = math.random()
    end,
    update = function(this)
        --create balls
        if not this.balls and this.btype == 0 then
            local i, t

            --head is invincible
            this.life = -1

            --add balls
            for i = 0, 11 do
                t = addenemy(this.x + 6 + 4 * i, this.y, dragon)
                t.btype = 1
                t.offset = this.offset
            end

            this.balls = true
        end

        this.x = this.x - 1 + math.max(1, camspd)
        this.y = this.y0 + 16 * picosin(this.x / 100 + this.offset)
    end,
    draw = function(this)
        if this.flash > 0 then
            sprcol(44 + this.btype, this.x, this.y,7)
        else
            spr(44 + this.btype, this.x, this.y)
        end
    end
}

bubble = {
    hitbox = { x = 2, y = 2, w = 12, h = 12 },
    die = -1,
    pts = 30,
    init = function(this)
        this.life = 10
        this.anim = math.floor(math.random()*120)
        this.animmax = 120
        this.y0 = this.y
        this.flash = 0
        this.angle = 0
    end,
    update = function(this)
        --move left
        this.x = this.x - camspd / 2

        --float
        this.y = this.y0 + 16 * picosin(this.anim / 60)

        --rotation
        this.angle = this.anim / 30

        --outside the screen
        if this.x < -16 then
            del(enemies, this)
        end

        --bullets
        if this.anim % 40 == 10 then
            local i, a, c, s
            for i = 0, 3 do
                a = i / 4 + this.angle
                c = picocos(a)
                s = picosin(a)
                addbullet(this.x + 4 + 4 * c,
                    this.y + 4 + 4 * s,
                    1.5 * c - camspd,
                    1.5 * s,
                    1)
            end
        end
    end,
    draw = function(this)
        local i

        for i = 0, 3 do
            spr(5 + math.floor(this.anim / 4) % 2,
                this.x + 4 + 4 * picocos(i / 4 + this.angle),
                this.y + 4 + 4 * picosin(i / 4 + this.angle))
        end
    end
}
-->8
--bosses
boss = {
    die = function(this)
        this.flash = this.flash + this.t % 2

        --explosions
        if this.t % 5 == 0 then
            sfx(10)
            addpart(this.x - 4 + math.random()*16, this.y - 4 + math.random()*16, 0, 0, 36, 0.375)
        end

        --start level outro
        if this.t < -60 then
            --boss disappears
            del(enemies, this)

            --score
            score = score + 2000

            --begin outro
            lvlcomp = true

            --remove hud life bar
            bosslife = -1
            bosslifemax = -1
        end
    end,
    update = function(this)
        --timer
        this.t = this.t - 1

        --hud life bar
        bosslife = this.life

        --boss intro
        if this.life > -2 then
            --move into the screen
            if this.t < 0 then
                if this._spr == 11 then
                    --frog boss moves upwards
                    this.y = this.y - 0.5
                    if this.y == 80 then
                        beginbattle(this)
                    end
                else
                    --other bosses move left
                    this.x = this.x - 1
                    if this.x == 104 then
                        beginbattle(this)
                    end
                end
            else
                --change attacks
                if this.t == 0 then
                    this.atk = (this.atk + 1) % this.atkmax
                    this.t = this.tmax
                end

                --main attack code
                this.atkf[this.atk + 1](this)

                --defeated
                if this.life <= 0 and this.t > 0 then
                    this.t = -1
                    this.life = -2
                    --fade out music
                    music(-1, 1000)

                    --player is invincible
                    player.hurt = 120
                end
            end
        else
            --defeat animation
            boss.die(this)
        end
    end,
    draw = function(this)
        --final boss has its
        --own draw code
        if lvl < 3 then
            if this.flash > 0 then
                sprcol(this._spr, this.x, this.y, 2, 2, 7)
            else
                spr(this._spr, this.x, this.y, 2, 2)
            end
        end

        --level outro
        if this.life < -1 then
            local dx = math.max(0, 80 + this.t * 3)
            printcnt("STAGE " .. lvl + 1, 64 + dx, 60, 7)
            printcnt("CLEAR", 64 + dx, 68, 7)
        end
    end
}

bghost = {
    hitbox = { x = 1, y = 1, w = 14, h = 14 },
    die = function(this)
        boss.die(this)
    end,
    init = function(this)
        this.x = 160
        this.y = 56
        this.life = -1
        this.lifemax = 100
        this.flash = 0
        this.atk = -1
        this.atkmax = 2
        this.t = -1
        this.tmax = 120
        this.anim = -1
        this._spr = 7

        this.atkf = {}

        this.atkf[1] = function(this)
            --attack 1
            this.y = 56 + 40 * picosin(this.t / 60)
            if this.t % 20 == 10 then
                addbullet(this.x - 4, this.y + 4, -4, 0, 1)
            end
        end

        this.atkf[2] = function(this)
            --attack 2
            if this.t % 40 == 35 then
                local i, y0
                y0 = 2 * math.floor(math.random()*2) - 1

                --spawn ghosts
                for i = 0, 4 do
                    addenemy(32 + 22 * (this.t - 20) / 40, 60 + y0 * (68 + i * 12), ghost)
                end
            end

            --bullets
            if this.t % 45 == 40 then
                movetowards(addbullet(this.x - 4, this.y + 4, 0, 0, 1), player.x + 4, player.y + 4, 1)
            end
        end
    end,
    update = function(this)
        boss.update(this)
    end,
    draw = function(this)
        boss.draw(this)
    end
}

bship = {
    hitbox = { x = 1, y = 1, w = 14, h = 14 },
    die = function(this)
        boss.die(this)
    end,
    init = function(this)
        this.x = 160
        this.y = 48
        this.life = -1
        this.lifemax = 175
        this.flash = 0
        this.atk = -1
        this.atkmax = 1
        this.t = -1
        this.tmax = 200
        this.anim = -1
        this._spr = 9

        this.atkf = {}

        this.atkf[1] = function(this)
            water = 64 + 48 * picosin(this.t / 200)
            this.y = water - 20 + 0.5 + 2 * picosin(this.t / 40)

            local i

            --each attack happens 5 times
            for i = -2, 2 do
                --bullets
                if this.t == 1 + (199 + i * 20) % 200 then
                    addbullet(this.x, this.y + 8, -3, 0, 1)
                    addbullet(this.x, this.y + 6, -3, -1.5, 1)
                    addbullet(this.x, this.y + 4, -3, -3, 1)
                end

                --torpedoes
                if this.t == 100 + i * 20 then
                    addenemy(this.x + 4, this.y + 16, torpedo)
                end
            end

            --spawn squids
            if this.t == 150 then
                for i = 0, 2 do
                    addenemy(32 + 24 * i, 128 + math.floor(math.random()*32), squid)
                end
            end
        end
    end,
    update = function(this)
        if this.t < 0 and this.life > -2 then
            water = math.min(64, water + 0.5)
            this.y = water - 20
        end

        boss.update(this)
    end,
    draw = function(this)
        boss.draw(this)
    end
}

bfrog = {
    hitbox = { x = 0, y = 3, w = 31, h = 28 },
    die = function(this)
        boss.die(this)
    end,
    init = function(this)
        this.x = 48
        this.y = 128
        this.life = -1
        this.lifemax = 150
        this.flash = 0
        this.atk = -1
        this.atkmax = 2
        this.t = -1
        this.tmax = 180
        this.anim = -1
        this._spr = 11

        this.atkf = {}

        this.atkf[1] = function(this)
            --move left and right
            this.x = 48 + 44 * picosin(this.t / 90)
            this.y = 80

            --bullets
            if this.t % 15 == 7 then
                addbullet(this.x + 8, this.y, -1, -2, 1)
                addbullet(this.x + 16, this.y, 1, -2, 1)
            end
        end

        this.atkf[2] = function(this)
            --move down then up
            this.x = 48
            this.y = this.y + 0.5 * sgn(this.t - 90)

            if this.t == 130 then
                local i

                --spawn 3 lava balls
                for i = -0.5, 1.5 do
                    addenemy(56 + i * 24, 16 + math.random()*32, lavaball)
                end
            end
        end
    end,
    update = function(this)
        if water < 96 then
            water = water + 0.5
        end

        boss.update(this)
    end,
    draw = function(this)
        if this.flash > 0 then
            sprcol(11, this.x, this.y, 2, 2, 7)
            sprcol(11, this.x + 16, this.y, 2, 2, 7, true, false)
        else
            spr(11, this.x, this.y, 2, 2)
            spr(11, this.x + 16, this.y, 2, 2, true, false)
        end
        boss.draw(this)
    end
}

bwitch = {
    hitbox = { x = -4, y = -4, w = 23, h = 23 },
    die = function(this)
        --save position for ending
        lvlcompx = this.x
        lvlcompy = this.y
        boss.die(this)
    end,
    init = function(this)
        this.x = 160
        this.y = 56
        this.anim = 0
        this.animmax = 32
        this.life = -1
        this.lifemax = 200
        this.flash = 0
        this._spr = 0
        this.atk = -1
        this.atkmax = 3
        this.t = -1
        this.tmax = 240

        this.atkf = {}

        local i

        --attack 1
        this.atkf[1] = function(this)
            this.y = 56 + 48 * picosin(this.t / 80)

            if this.t % 15 == 5 then
                for i = 0.5, 7.5 do
                    addbullet(this.x + 4 + 16 * picocos(i / 8)
                    , this.y + 4 + 16 * picosin(i / 8)
                    , -4, 0, 1)
                end
            end
        end

        --attack 2
        this.atkf[2] = function(this)
            this.x = 56 + 48 * picocos(this.t / 80)

            if this.t % 180 < 60 then
                this.y = this.y - 1
            else
                this.y = this.y + 1
            end

            --spawn dragon
            if this.t % 120 == 60 then
                addenemy(128, 16 + math.random()*88, dragon)
            end
        end

        --attack 3
        this.atkf[3] = function(this)
            if this.t % 11 == 1 and this.t > 60 then
                local bhspd, bvspd

                for i = 0, 7 do
                    bhspd = picocos(this.anim / 64 + i / 8)
                    bvspd = picosin(this.anim / 64 + i / 8)

                    addbullet(this.x + 4 + 16 * bhspd, this.y + 4 + 16 * bvspd, bhspd * 0.75, bvspd * 0.75, 1)
                end
            end
        end
    end,
    update = function(this)
        boss.update(this)
    end,
    draw = function(this)
        local i = 2 * math.floor(this.anim % 2)
        local y2 = this.y + math.floor(picocos(this.anim / 32) + 0.5)

        drawwitch(this.x, this.y, -1, this.anim / 4, 0, this.flash > 0 and 7 or nil)

        --skulls
        for i = 0, 7 do
            spr(46, this.x + 4 + 16 * picocos(this.anim / 64 + i / 8)
            , this.y + 4 + 16 * picosin(this.anim / 64 + i / 8))
        end

        boss.draw(this)
    end
}
-->8
--items

item = {
    update = function(this)
        this.x = this.x - camspd

        if this.x < -8 then
            del(items, this)
        end

        this.anim = (this.anim + 0.125) % 8

        if collcheck(this.x + 1, this.y + 2, 6, 4, xp, yp, wp, hp) then
            player.pow = this.pow + 1
            player.powtimer = 180
            del(items, this)

            sfx(12)
        end
    end,
    draw = function(this)
        if this.anim % 4 > 3 then
            sprcol(39 + this.pow, this.x, this.y + math.floor(0.5 + picosin(this.anim / 4)),7)
        else
            spr(39 + this.pow, this.x, this.y + math.floor(0.5 + picosin(this.anim / 4)))
        end
    end
}
-->8
--_init
function init()
    reload()
    gfx.show_mouse_cursor(false)
	snd.new_instrument(INST_TRIANGLE)
	snd.new_instrument(INST_TILTED)
	snd.new_instrument(INST_SAW)
	snd.new_instrument(INST_SQUARE)
	snd.new_instrument(INST_PULSE)
	snd.new_instrument(INST_ORGAN)
	snd.new_instrument(INST_NOISE)
	snd.new_instrument(INST_PHASER)
	for _, sfx in pairs(SFX) do
		snd.new_pattern(sfx)
	end
    snd.new_music(MUSIC)
    gfx.load_img(1, "witch/witch.png")
    gfx.set_sprite_layer(1)
    --maximum hp
    lifemax = 5

    --init player and metatables
    --player:init()
    bullets = {}
    parts = {}
    enemies = {}
    items = {}

    --camera
    camx = 0
    camspd = 0

    --level
    lvl = 0
    lvlx = 0
    sublvl = 0

    --score
    score = 0
    multiplier = 1
    scoretimer = 0

    --level transitions
    lvlcomp = false
    lvlcompx = 0
    lvlcompy = 0

    --water height
    water = 136

    --number of lives
    lives = 3
    livesmax = 3

    --death count
    deaths = 0

    --ending info
    endanim = 0

    --title screen and ending
    screen = 0

    --menu choice
    choice = 1

    --copy of player coordinates
    xp = 0
    yp = 0
    wp = 6
    hp = 8

    --hud boss life bar
    bosslife = -1
    bosslifemax = -1

    --enemy type lookup table
    etype = {
        id = { 48, 50, 52, 56, 58, 60, 61, 63,
            16, 43, 44, 5 },
        typ = { bat, frog, caul, squid, fish,
            urchin, ship, spike,
            lavaball, witch, dragon,
            bubble }
    }
end

-->8
--_update
flipflop = true
function update()
    flipflop = not flipflop
    if not flipflop then
        -- only update 30 times per second
        return
    end
    --title screen
    if screen == 0 then
        endanim = (endanim + 1) % 256

        if btnp(2) then
            choice = (choice - 1) % 3
        end

        if btnp(3) then
            choice = (choice + 1) % 3
        end

        if btnp(4) or btnp(5) then
            if choice == 0 then
                livesmax = -1
            elseif choice == 1 then
                livesmax = 3
            else
                livesmax = 1
            end

            sfx(12)

            screen = 1

            lives = livesmax
            player:init()

            endanim = 0
        end
    else
        --update game

        --update player
        player:update()

        --score multiplier
        if scoretimer > 0 then
            scoretimer = scoretimer - 1
        else
            multiplier = 10
        end

        --update bullets
        local i=1
        while i <= #bullets do
            local old=#bullets
            bullet.update(bullets[i])
            if #bullets==old then
                i=i+1
            end
        end

        --update enemies
        local i=1
        while i <= #enemies do
            local old=#enemies
            enemy.update(enemies[i])
            if #enemies==old then
                i=i+1
            end
        end

        --update items
        i=1
        while i <= #items do
            local old=#items
            item.update(items[i])
            if #items==old then
                i=i+1
            end
        end

        --update particles
        i=1
        while i <= #parts do
            local old=#parts
            part.update(parts[i])
            if #parts==old then
                i=i+1
            end
        end

        --read map for objects
        local i, j, m, t, mx, my, addy

        for i = 0, 15 do
            mx = math.min(127, math.floor(lvlx / 3))
            my = lvl * 16 + i
            m = mget(mx, my)
            addy = 8 * i

            --lookup table
            for j = 1, #etype.id do
                if m == etype.id[j] then
                    addenemy(128, addy, etype.typ[j])
                    mset(mx, my, 0)
                end
            end

            --add 5 bats
            if m == 49 then
                for j = 0, 4 do
                    addenemy(128 + j * 12, addy, bat)
                end
                mset(mx, my, 0)
            end

            --add ghosts
            if m == 55 then
                local gdir
                if i > 7 then
                    gdir = 1
                else
                    gdir = -1
                end

                for j = 0, 4 do
                    addenemy(128, 60 + gdir * (68 + j * 12), ghost)
                end

                mset(mx, my, 0)
            end

            --add items
            if m == 39 or m == 40 then
                local t = { x = 128, y = 8 * i, anim = 0 }
                t.pow = m - 39
                table.insert(items, t)
                mset(mx, my, 0)
            end
        end --end of enemy placement

        --move camera to the right
        lvlx = lvlx + math.min(1, camspd) / 8

        camx = camx + camspd

        --level sections
        if sublvl == 0 then
            camx = camx % 256
            if lvlx > 128 then
                sublvl = 1
            end
        end

        if sublvl == 1 and camx > 512 then
            sublvl = 2
        end

        if sublvl == 2 then
            camx = 512 + (camx - 512) % 256
            if lvlx > 280 then
                sublvl = 3
            end
        end

        if sublvl == 3 and camx >= 896 then
            sublvl = 4
        end

        if sublvl == 4 then
            camx = 896
        end

        --level music fades out
        if lvlx == 372 then
            music(-1, 1000)
        end

        --boss music fades in
        if lvlx == 378 then
            music(34, 1000)
        end

        --begin boss battle
        if camspd > 0 and lvlx >= 381 then
            local lvlboss = { bghost, bship, bfrog, bwitch }
            --stop camera
            camspd = 0
            --spawn boss
            addenemy(0, 0, lvlboss[lvl + 1])
        end

        --water
        if lvl == 1 then
            --level 2
            if lvlx < 72 then
                water = 112
            elseif lvlx <= 88 then
                water = clamp(112 - lvlx + 72, 96, 112)
            elseif lvlx <= 152 then
                water = clamp(96 - lvlx + 120, 64, 96)
            elseif lvlx <= 242 then
                water = clamp(64 + 2 * lvlx - 420, 64, 96)
            elseif lvlx <= 300 then
                water = clamp(96 - 2 * lvlx + 504, 64, 96)
            elseif lvlx < 381 then
                water = 64 + math.floor(32 * picosin(lvlx / 20))
            end
        elseif lvl == 2 then
            --level 3
            if lvlx < 180 then
                water = 112
            elseif lvlx <= 192 then
                water = clamp(112 - 3 * lvlx + 540, 80, 112)
            elseif lvlx <= 272 then
                water = clamp(80 + 2 * lvlx - 464, 80, 112)
            elseif lvlx <= 312 then
                water = clamp(112 - 2 * lvlx + 576, 80, 112)
            end
        else
            --levels 1 and 4 (no water)
            water = 136
        end

        --level 4 speed increase
        if lvl == 3 and lvlx == 177 then
            camspd = 2
        end

        --push player back
        while collmap(player) do
            player.x = player.x - 1
        end

        --player crushed
        if player.move and player.x < -player.hitbox.x then
            player.life = 1
            player.hurt = 0
            player:hit()
        end

        --lava damage
        if lvl == 2 and yp + hp >= water then
            player:hit()
        end

        --level intro
        if screen == 1 and camspd == 0
            and lvlx == 0 then
            player.x = player.x + 0.1 * (24 - player.x)
            if player.x >= 16 then
                camspd = 1
                player.move = true
                player.x = math.floor(player.x)
            end
        end

        --level outro
        if lvlcomp then
            player.move = false

            if lvl < 3 then
                --level to level transition

                if lvlcompx == 0 then
                    lvlcompx = player.x
                end

                player.x = player.x + math.max(0.5, 0.1 * (player.x - lvlcompx))

                --go to next level
                if player.x - lvlcompx > 128 then
                    enemies = {}
                    bullets = {}
                    lvlx = 0
                    camx = 0
                    lvl = lvl + 1
                    sublvl = 0
                    lvlcomp = false
                    lvlcompx = 0
                    lives = livesmax
                    player:init()
                end
            end
        end --end of level outro
    end --end of main game update
end

-->8
--_draw
function render()
    rectfill(0, 0, 128, 128, 0)

    local i

    if lvl == 0 then
        --level 1 background

        if lvlx < 180 then
            rectfill(0, 0, 128, 27, 1)

            --draw moon
            drawmoon(104, 8)

            rectfill(0, 36, 128, 128, 0)

            --draw clouds
            for i = 0, 8 do
                spr(70, -(lvlx * 2 % 16) + i * 16, 28, 2, 1)
            end

            rectfill(128 - math.max(0, camx - 284), 0, 128, 128, 0)
        else
            --cavern background

            for i = 0, 2 do
                spr(86, -(lvlx * 3 % 72 + 16) + i * 72, 12, 2, 2)
                spr(86, -((lvlx * 3 + 36) % 72 + 16) + i * 72, 100, 2, 2, false, true)
                spr(118, -(lvlx * 2 % 68 + 8) + i * 68, 36)
                spr(118, -((lvlx * 2 + 34) % 68 + 8) + i * 68, 84, 1, 1, false, true)
            end
        end
    elseif lvl == 1 then
        --level 2 background
        local wy = math.floor(28 + (112 - water) / 3)

        rectfill(0, 0, 128, wy, 1)

        rectfill(0, 26, 128, 64, 2)
        line(0, 27, 128, 27, 1)
        rectfill(0, 40, 128, 64, 8)
        line(0, 41, 128, 41, 2)

        rectfill(0, wy + 8, 128, 128, 0)

        drawmoon(104, 8)

        for i = 0, 16 do
            sprcol(119, i * 8 - (lvlx * 3) % 8, wy, 0)
        end

    elseif lvl == 2 then
        --level 3 background
        local j

        --small pillars
        for i = 0, 3 do
            for j = 0, 5 do
                spr(98, -(lvlx * 2 % 48 + 8) + i * 48,
                    40 + j * 8, 1, 1)
            end
        end

        --large pillars
        for i = 0, 2 do

            for j = 0, 9 do
                spr(99, -(lvlx * 4 % 72) + i * 72,
                    24 + j * 8, 2, 1)
            end
        end
    else
        --level 4 background

        --palette gradients
        local colors = {
            { 0, 1, 2, 13, 12 },
            { 1, 2, 5, 3,  13 },
            { 1, 2, 5, 3,  14 },
            { 2, 5, 3, 14, 15 }
        }

        local colid = math.floor(clamp(lvlx - 168, 1, 5))

        rectfill(0, 0, 128, 128, colors[1][colid])

        --color gradients
        rectfill(0, 0, 128, 9, colors[4][colid])
        rectfill(0, 10, 128, 19, colors[3][colid])
        line(0, 11, 128, 11, colors[4][colid])
        line(0, 21, 128, 21, colors[3][colid])

        rectfill(0, 117, 128, 128, colors[2][colid])
        line(0, 115, 128, 115, colors[2][colid])

        --clouds
        pal(13, colors[2][colid])

        local dx

        for j = 0, 1 do
            for i = 0, 2 do
                dx = -(lvlx * 3 % 96 + 48 * j) + i * 96

                spr(13, dx, 24 + 64 * j, 3, 2)
            end
        end

        pal()
    end

    --frog boss is behind the lava
    if lvl == 2 then
        for i=1,#enemies do
            local obj=enemies[i]
            if obj.typ == bfrog then
                enemy.draw(obj)
            end
        end
    end

    --draw water
    if lvl ~= 0 and water < 136 then
        --lava in level 3
        local sprnum= lvl == 2 and 129 or 119
        for i = 0, 16 do
            spr(sprnum, -(lvlx * 6 % 8) + 8 * i,math.floor(water - 8))
            rectfill(0, math.floor(water), 128, 128, lvl == 2 and 8 or 3)
        end
    end

    local cx = -(camx % 8)

    --draw map
    map(camx / 8, lvl * 16, cx, 0, 17, 16, 1)

    --draw scenery
    map(camx / 8, lvl * 16, cx, 0, 17, 16, 4)

    --
    --title screen and main menu
    --

    if screen == 0 then
        local menutxt = { "CASUAL",
            "NORMAL",
            "HARD" }
        local menuspr = { 41, 47, 46 }
        local menucol
        local menucred = { "FLYTRAP STUDIO",
            "Music : DUSTIN VAN WYK" }

        --print difficulty options
        for i = 1, 3 do
            if choice == i - 1 then
                menucol = 7
            else
                menucol = 6
            end

            printcnt(menutxt[i], 64, 72 + 8 * i, menucol)
        end --end of for loop

        for i = -1, 1, 2 do
            spr(menuspr[choice + 1], 60 + 20 * i, 76 + 8 * choice, 1, 1, i < 0, false)
        end

        --title logo
        local dy2 = 0.5 + 2 * picosin(endanim / 64 + 0.125)

        --"loves"
        palt(12, true)
        palt(13, true)
        palt(1, true)
        palt(4, true)
        palt(9, true)
        palt(10, true)
        spr(90, 40, 40 + math.floor(dy2), 6, 2)
        pal()

        --"witch"
        palt(14, true)
        palt(8, true)
        spr(74, 40, math.floor(32 + 0.5 + 2 * picosin(endanim / 64)), 6, 2)

        --"bullets"
        spr(106, 40, math.floor(48 + 0.5 + 2 * picosin(endanim / 64 + 0.25)), 6, 2)
        pal()

        --hearts
        spr(41 + (endanim / 8) % 2, 30, 60 + dy2)
        spr(42 - math.floor(endanim / 8) % 2, 92, 28 + dy2)

        --witch
        drawwitch(192 - endanim, 8, -1, endanim / 4, 0, 0)

        --credits
        printcnt(menucred[1 + math.floor(endanim / 64) % 2], 64, 124, 7)
        gprint("1.1", 116, 122, 6)
    end --end of title screen


    --
    --player, in-game objects, hud
    --

    if screen == 1 then
        --draw player
        player:draw()

        --draw bullets
        for i=1,#bullets do
            bullet.draw(bullets[i])
        end

        --draw enemies
        for i=1,#enemies do
            local obj=enemies[i]
            --frog boss isn't drawn now
            if obj.typ ~= bfrog then
                enemy.draw(obj)
            end
        end

        --draw items
        for i=1,#items do
            item.draw(items[i])
        end

        --draw particles
        for i=1,#parts do
            part.draw(parts[i])
        end

        --
        --draw hud
        --

        --level 1 tutorial
        if lvl == 0 and lvlx < 21
            and camspd > 0
            and math.floor(lvlx / 2) % 2 == 0 then
            printcnt("Press C", 88, 12, 7)
            spr(33, 84, 18)
            printcnt("Press X", 40, 12, 7)
            spr(5, 36, 18)
        end

        --hearts
        for i = 0, lifemax - 1 do
            if i >= player.life then
                sprcol(42, 6 * i, 0, 0)
            else
                spr(42, 6 * i, 0)
            end
        end

        pal()

        --draw lives
        if lives > 0 then
            spr(47, 0, 7)
            gprint(lives, 10, 9, 7)
            pal()
        end

        --score
        gprint(score, 128 - 4 * #tostring(score),
            1, 7)
        for i = #tostring(score) + 1, 6 do
            gprint(0, 128 - 4 * i, 1,7)
        end

        if multiplier > 10 then
            gprint("*" .. multiplier / 10,
                124 - 4 * #tostring(multiplier / 10),
                7,
                5 + 3 * math.floor(multiplier / 50) + 3 * scoretimer / 45.1)
        end

        --boss life bar
        if bosslife > -1 then
            rectfill(14, 124, 14 + bosslife / bosslifemax * 100, 125, 12)
        end

        --level intro
        if lvlx < 9 then
            local dy = 16 * math.max(lvlx - 7, 0) ^ 2 + (16 - player.x) * (1 - camspd)
            printcnt("STAGE " .. lvl + 1, 64, 60 - dy, 7)
            printcnt("START", 64, 68 + dy, 7)
        end

        --level outro
        if lvlcomp and lvl < 3 and player.x - lvlcompx < 32 then
            printcnt("STAGE " .. lvl + 1, 64, 60, 7)
            printcnt("CLEAR", 64, 68, 7)
        end

        --game over screen
        if lives == 0 and camspd == 0 then
            printcnt("Game Over", 64, 32, 7)
            printcnt("Continue", 64, 88, 7 - choice)
            printcnt("Give Up", 64, 96, 6 + choice)

            if choice == 1 then
                transcol(1)
            end

            for i = -1, 1, 2 do
                spr(47 - choice, 60 + 20 * i, 84 + 8 * choice, 1, 1, i < 0, false)
            end

            pal()
        end
    end

    --ending
    if lvlcomp and lvl == 3 then
        endanim = endanim + 1

        if screen == 1 then
            --ending part 1

            local scale = -1

            --start ending music
            if endanim == 120 then
                music(44)
            end

            --update first
            if endanim > 120 then
                --player moves to the right
                player.x = player.x + 2

                --other witch follows behind
                if player.x > lvlcompx + 8 then
                    lvlcompx = lvlcompx + 2
                    scale = 1
                end
            end


            --draw afterwards

            --friendly witch
            drawwitch(lvlcompx, lvlcompy, scale, player.anim + 2, 0, nil, true)

            --hearts
            if endanim >= 60 and endanim < 90 then
                spr(41, player.x + 4, player.y - endanim / 2 + 26)
                spr(41, lvlcompx + 4, lvlcompy - endanim / 2 + 26)
            end

            --transition to part 2
            rectfill(916 - 4 * endanim, 0, 129, 128, 0)

            --go to part 2
            if endanim == 229 then
                screen = 2
                endanim = 0
            end
        else
            --ending part 2

            local endtxt = {
                "Congratulations",
                "Game by Matthieu Le Gallic",
                "Music composed by Dustin Van Wyk",
                "pico music by Matthieu Le Gallic",
                "Score : " .. score .. "   Deaths : " .. deaths,
                "Congratulations"
            }

            rectfill(0, 0, 128, 128, 13)

            rectfill(0, 109, 128, 120, 14)
            line(0, 107, 128, 107, 14)
            rectfill(0, 121, 128, 128, 15)
            line(0, 119, 128, 119, 15)

            --clouds
            pal(13, 14)

            local j

            for i = 0, 3 do
                --drawing 2 clouds gives the
                --illusion of a bigger cloud
                for j = 0, 1 do
                    spr(13, i * 96 - endanim % 96 - 24 - j * 7, 0, 3, 2)
                end
                spr(13, i * 64 - (endanim / 2) % 64 - 24, 16, 3, 2)
            end

            drawwitch(44, 52, 1, endanim / 4, 0)
            drawwitch(68, 60, 1, endanim / 4 + 1, 0,nil,true)


            if endanim > 32 then
                endanim = 32 + (endanim - 32) % 1920

                local textoffset = math.floor((endanim - 32) / 192) % 5

                --draw text
                for i = 0, 5 do
                    if (endanim - 32) % 192 < 128 then
                        --text doesn't move
                        printcnt(endtxt[i + 1], 64 + 128 * (i - textoffset), 92, 7)
                    else
                        --scrolling text
                        local dx = 2 * ((endanim - 32) % 192 - 128)
                        printcnt(endtxt[i + 1], 64 + 128 * (i - textoffset) - dx, 92, 7)
                    end
                end
            end


            --transition from part 1
            rectfill(-1, 0, 128 - 4 * endanim, 128, 0)
        end
    end
    gfx.rectangle(0,0,X_OFFSET,224,0,0,1)
    gfx.rectangle(X_OFFSET+128,0,384,224,0,0,1)
    gfx.rectangle(0,0,384,Y_OFFSET,0,0,1)
    gfx.rectangle(0,Y_OFFSET+128,384,224,0,0,1)
end

SPRITE_FLAGS = {
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    1, 1, 3, 3, 3, 3, 0, 0, 4, 4, 0, 0, 0, 0, 0, 0,
    1, 1, 3, 3, 3, 3, 0, 0, 4, 4, 0, 0, 0, 0, 0, 0,
    1, 1, 0, 0, 0, 4, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0,
    1, 1, 3, 3, 3, 3, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
}

TILE_MAP_ROM = {
    -- upper
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
    64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 69, 0, 0, 0, 0, 0, 68, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
    64, 64,
    64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 69, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 68, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
    64, 69, 0, 104, 0, 0, 0, 0, 0, 0, 104, 0, 0, 0, 0, 0, 0, 0, 0, 0, 104, 0, 0, 0, 0, 0, 0, 104, 68, 64, 64, 64,
    64, 69, 0, 104, 0, 0, 0, 0, 0, 0, 104, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 68, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
    64, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 68, 64, 64,
    64, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 48, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 104, 0, 68, 64, 64, 64, 64, 64, 64, 64,
    69, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 49, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 64, 64,
    69, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 55, 0, 55, 0, 55, 0, 55, 0, 55, 0, 55, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 48, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 49, 0, 0, 0,
    0, 0, 0, 0, 48, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 68, 64, 64, 64, 64, 64, 64,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 64, 64,
    0, 0, 0, 0, 49, 0, 0, 0, 0, 0, 0, 55, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 49, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 48, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 39, 0, 0, 0, 0, 0, 0, 0, 49, 0, 0, 0, 50, 0, 0, 0, 0, 0, 64, 64, 64, 64, 64, 69,
    0, 50, 0, 0, 0, 0, 66, 64, 64, 64, 64, 67, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 68, 69,
    0, 0, 0, 0, 0, 0, 66, 64, 64, 64, 64, 67, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 49, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 49, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 48, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 66, 64, 67, 0, 0, 0, 0, 64, 64, 64, 69, 0, 0,
    49, 0, 0, 0, 66, 64, 64, 64, 64, 64, 64, 64, 67, 0, 0, 0, 0, 0, 0, 0, 0, 0, 55, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 55, 66, 64, 64, 64, 64, 64, 64, 64, 67, 0, 0, 0, 40, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 49, 0, 0, 0, 0, 0, 48, 0, 0, 48, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 49,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 49, 0, 0, 0, 0, 0, 0, 0, 66, 64, 64, 64, 0, 0, 0, 0, 64, 64, 69, 0, 0, 0,
    0, 0, 0, 0, 68, 64, 64, 64, 64, 64, 64, 64, 69, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 68, 64, 64, 64, 64, 64, 64, 64, 69, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 49, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 48, 0, 0, 0, 0, 0, 0, 0, 0, 49, 0, 0, 0, 0, 0, 0,
    0, 0, 48, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 64, 64, 64, 64, 0, 0, 0, 0, 68, 69, 0, 0, 0, 0,
    0, 0, 0, 0, 49, 68, 64, 64, 64, 64, 69, 0, 0, 0, 0, 0, 0, 0, 0, 0, 66, 64, 64, 64, 64, 67, 49, 0, 0, 0, 0, 0,
    55, 0, 0, 0, 0, 68, 64, 64, 64, 64, 69, 0, 0, 49, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 48, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 66, 64, 64, 64, 64, 0, 0, 0, 0, 48, 0, 0, 0, 52, 66,
    67, 0, 0, 0, 0, 0, 0, 104, 0, 0, 55, 0, 0, 0, 0, 0, 0, 0, 66, 64, 64, 64, 64, 64, 64, 64, 67, 0, 0, 0, 0, 66,
    67, 0, 0, 0, 0, 0, 55, 104, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 40, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 48, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 52, 0, 0, 64, 64, 64, 64, 64, 67, 0, 50, 0, 0, 0, 0, 0, 66, 64,
    64, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 68, 64, 64, 64, 64, 64, 64, 64, 69, 0, 0, 0, 0, 64,
    64, 49, 0, 0, 0, 0, 0, 49, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 49, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 50, 0, 0, 0, 0, 0, 72, 72, 50, 0, 73, 0, 0, 52, 0, 0, 0, 0, 50, 0, 73, 0, 0, 52,
    0, 0, 0, 0, 50, 0, 0, 0, 0, 52, 0, 0, 0, 0, 72, 72, 66, 64, 64, 64, 64, 64, 64, 0, 0, 0, 0, 0, 0, 0, 64, 64,
    64, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 68, 64, 64, 64, 64, 69, 0, 0, 0, 0, 0, 66, 64,
    64, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 66, 65, 65, 65, 65, 65, 65, 65, 67, 0, 72, 72, 72, 0, 66, 65, 65, 65, 67, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 66, 65, 65, 65, 64, 64, 64, 64, 64, 64, 64, 67, 0, 0, 0, 0, 0, 66, 64, 64,
    64, 67, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 40, 0, 0, 0, 55, 104, 0, 0, 50, 0, 0, 0, 0, 64, 64,
    64, 67, 0, 0, 0, 0, 0, 0, 0, 0, 0, 55, 0, 0, 0, 0, 0, 0, 55, 0, 55, 0, 55, 0, 55, 0, 55, 0, 55, 0, 0, 0,
    0, 72, 72, 72, 73, 0, 72, 72, 0, 73, 0, 66, 64, 64, 64, 64, 64, 64, 64, 64, 64, 65, 65, 65, 65, 65, 64, 64, 64, 64,
    64, 67,
    0, 72, 72, 72, 73, 0, 72, 72, 0, 73, 0, 66, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 65, 65, 65, 65, 65, 64,
    64, 64,
    64, 64, 0, 0, 0, 0, 0, 0, 0, 0, 0, 49, 0, 0, 0, 0, 0, 50, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 66, 64, 64,
    64, 64, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
    64, 64, 64,
    65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
    64, 64, 64,
    64, 64, 67, 0, 72, 72, 72, 0, 0, 72, 72, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 72, 72, 0, 72, 72, 72, 0, 66, 64, 64, 64,
    64, 64, 67, 0, 72, 72, 72, 0, 0, 72, 72, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
    64, 64, 64,
    64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
    64, 64, 64,
    64, 64, 64, 65, 65, 65, 65, 65, 65, 65, 65, 65, 67, 0, 0, 0, 0, 0, 66, 65, 65, 65, 65, 65, 65, 65, 65, 65, 64, 64,
    64, 64,
    64, 64, 64, 65, 65, 65, 65, 65, 65, 65, 65, 65, 67, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 58, 0, 58, 0, 58, 84, 80, 80, 80, 80, 80, 80, 85, 0, 0, 0, 0, 0, 0, 0,
    0, 84, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 85, 0, 0, 0, 0, 0, 0, 84, 80, 80, 80, 80, 80, 80, 80, 80, 85,
    0,
    0, 84, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 85, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    58, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 56, 0, 58, 0, 0, 80, 80, 80, 80, 80, 85, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 85, 0, 0, 0, 0, 0, 0, 0, 0, 80, 80, 80, 80, 80, 80, 80, 80, 0, 0,
    0, 0, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 85, 0, 0, 0, 0, 0, 0, 0, 0, 58, 0, 0, 0, 58, 0, 58, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 58, 0, 0, 0, 0, 58, 0, 0, 0, 58, 0, 58, 0, 56, 58, 0, 80, 80, 80, 80, 80, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 80, 80, 80, 80, 80, 80, 80, 85, 0, 0, 104, 0, 0, 0, 0, 0, 0, 0, 0, 0, 84, 80, 80, 80, 80, 80, 80, 80, 0, 0,
    0, 0, 80, 80, 80, 80, 80, 80, 80, 85, 0, 0, 104, 0, 0, 0, 0, 0, 0, 0, 0, 58, 0, 0, 58, 0, 0, 0, 0, 58, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 58, 0,
    0, 0, 0, 0, 58, 0, 0, 0, 0, 0, 0, 56, 0, 0, 58, 0, 0, 58, 80, 80, 80, 80, 80, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 80, 80, 80, 80, 80, 80, 80, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 104, 84, 80, 80, 80, 80, 0, 0,
    0, 0, 80, 80, 80, 80, 80, 80, 80, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 56, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 58, 40, 0, 0, 58, 0, 0, 58, 0, 56, 80, 80, 80, 80, 80, 0, 0, 0, 52, 0, 0, 0, 0, 0,
    55, 0, 84, 80, 80, 80, 80, 80, 85, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 80, 80, 80, 80, 0, 0,
    0, 0, 84, 80, 80, 80, 80, 80, 85, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 56, 56, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 58, 0, 0, 0, 58, 0, 0, 0, 0, 0, 58, 0, 56, 58, 56, 58, 0, 84, 80, 80, 80, 80, 0, 0, 0, 0, 0, 0, 0, 0, 58,
    58, 58, 0, 0, 104, 0, 0, 104, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 80, 80, 80, 80, 0, 0,
    0, 58, 58, 0, 104, 0, 0, 104, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 61, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 58,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 58, 0, 58, 0, 58, 0, 80, 80, 80, 80, 0, 0, 0, 0, 81, 81, 81, 83, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 58, 0, 0, 0, 0, 0, 56, 0, 0, 0, 0, 0, 80, 80, 80, 80, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 60, 60, 0, 60, 0, 60, 0, 60, 60, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 49, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 58, 0, 0, 0, 0, 0, 0, 0, 56, 0, 0, 0, 56, 0, 56, 0, 80, 80, 80, 80, 0, 56, 0, 0, 80, 80, 80, 80, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 58, 0, 0, 0, 0, 0, 0, 56, 0, 0, 84, 80, 80, 85, 56, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 56, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 84, 80, 80, 85, 0, 0, 0, 0, 80, 80, 80, 80, 0,
    0, 0, 0, 0, 0, 56, 56, 0, 0, 0, 0, 0, 0, 0, 0, 58, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 104, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 56, 0, 56, 0, 56, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 56, 0, 50, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 50, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 104, 0, 0, 39, 0, 0, 80, 80, 80, 80, 60,
    0, 60, 60, 0, 56, 60, 60, 0, 0, 0, 50, 50, 0, 0, 0, 0, 61, 0, 0, 60, 0, 60, 60, 0, 60, 0, 0, 61, 56, 56, 0, 56,
    0, 0, 0, 0, 61, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 50, 50, 0, 0, 0, 52, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 52, 0, 0, 56, 56, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 52, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 56, 0, 56, 0, 0, 0, 0, 80, 80, 80, 80, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 56, 0, 0, 0, 0, 56, 56, 0, 0, 0, 82, 81, 81, 81, 81, 83, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 56, 0, 82, 80, 80, 80, 80, 0,
    0, 0, 0, 56, 0, 0, 56, 0, 0, 0, 0, 0, 82, 81, 81, 81, 81, 81, 83, 0, 0, 0, 0, 0, 0, 0, 0, 56, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 82, 81, 81, 81, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 56, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 82, 80, 80, 80, 80, 80, 80, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 39, 0, 0, 56, 0, 56, 0, 0, 80, 80, 80, 80, 80, 0,
    0, 0, 0, 0, 56, 56, 0, 0, 89, 0, 88, 0, 80, 80, 80, 80, 80, 80, 80, 0, 0, 0, 0, 0, 56, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 89, 0, 88, 0, 80, 80, 80, 80, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    81, 81, 81, 81, 83, 0, 0, 0, 0, 0, 56, 0, 0, 0, 0, 0, 0, 0, 80, 80, 80, 80, 80, 80, 80, 0, 0, 0, 0, 0, 0, 82,
    81, 81, 81, 81, 83, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 56, 0, 0, 0, 80, 80, 80, 80, 80, 0,
    0, 0, 0, 0, 0, 0, 82, 81, 81, 81, 81, 81, 80, 80, 80, 80, 80, 80, 80, 0, 89, 0, 88, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 82, 81, 81, 81, 81, 81, 80, 80, 80, 80, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    80, 80, 80, 80, 80, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 80, 80, 80, 80, 80, 80, 80, 0, 0, 0, 0, 0, 0, 80,
    80, 80, 80, 80, 80, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 56, 0, 0, 56, 0, 0, 80, 80, 80, 80, 80, 0,
    0, 0, 0, 56, 0, 0, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 81, 81, 81, 81, 83, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    80, 80, 80, 80, 80, 83, 0, 88, 0, 88, 88, 0, 88, 0, 88, 0, 0, 82, 80, 80, 80, 80, 80, 80, 80, 83, 0, 88, 0, 88, 82,
    80,
    80, 80, 80, 80, 80, 83, 0, 88, 0, 88, 88, 0, 88, 0, 88, 0, 0, 0, 0, 0, 0, 56, 0, 0, 56, 82, 80, 80, 80, 80, 80, 83,
    0, 88, 0, 88, 56, 82, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 83, 0, 88, 0, 88, 0,
    88, 0,
    0, 88, 0, 88, 0, 82, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,

    -- lower
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 96, 97, 96, 97, 96, 97,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 97, 96, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 96, 97, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 63, 0, 0, 0, 0, 0, 0, 0, 0, 0, 63, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 97, 96, 97, 96, 97, 96,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 96, 97, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 97, 96, 0, 0, 0, 0, 0, 49, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16, 0, 0, 0, 0, 0, 0, 0, 0, 96, 97, 96, 97, 96, 97,
    0, 0, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16, 0, 0, 0, 0, 0, 0, 0, 0, 16, 0, 0, 0, 0, 0, 97, 96, 0, 0,
    0, 0, 0, 0, 0, 52, 0, 0, 63, 0, 0, 0, 0, 0, 0, 0, 0, 0, 96, 97, 0, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0,
    0, 0, 0, 0, 16, 0, 0, 0, 0, 0, 0, 0, 0, 63, 0, 0, 0, 0, 0, 0, 0, 0, 0, 63, 0, 0, 49, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 97, 96, 97, 96, 97, 96,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 97, 96, 97, 96, 97, 96, 97, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 63, 0, 0, 97, 96, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 49, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 96, 97, 96, 97, 96, 97,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16, 0, 0, 0, 96, 97, 96, 97, 96, 97, 96, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 96, 97, 0, 0, 0, 0, 0, 0, 0, 0, 96, 97, 48, 0, 0, 0, 0, 0, 0, 0, 96, 97, 96, 97,
    0, 0, 0, 0, 0, 16, 0, 0, 96, 97, 0, 0, 5, 0, 63, 0, 0, 0, 0, 0, 0, 0, 5, 0, 63, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 63, 0, 101, 0, 0, 101, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 97, 96, 0, 0, 0, 16, 101, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 97, 96, 0, 0, 0, 0, 0, 0, 0, 0, 97, 96, 0, 48, 0, 48, 0, 0, 0, 0, 97, 96, 97, 96,
    0, 0, 0, 0, 0, 0, 0, 0, 97, 96, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 49, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16, 0, 0, 0, 0, 0, 0, 0, 101, 0, 0, 101, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 49, 0, 0, 0, 0, 0, 49, 0, 96, 97, 0, 0, 0, 0, 101, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 96, 97, 0, 0, 0, 0, 0, 63, 0, 0, 48, 101, 0, 0, 0, 0, 0, 0, 0, 0, 101, 0, 0, 101,
    0, 0, 0, 0, 0, 0, 0, 0, 96, 97, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 63, 0, 0, 0, 0, 50, 52, 0, 0, 0, 63, 63, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 101, 0, 0, 101, 0,
    0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 97, 96, 0, 0, 0, 0, 101, 0, 0,
    0, 49, 0, 0, 50, 50, 0, 0, 97, 96, 49, 0, 0, 0, 0, 0, 0, 0, 0, 101, 48, 0, 48, 0, 0, 0, 50, 0, 101, 0, 0, 101,
    0, 0, 0, 0, 0, 0, 0, 0, 97, 96, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 49, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 63, 101, 0, 0, 101, 52,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 50, 0, 0, 0, 0, 0, 16, 0, 0, 0, 0, 0, 0, 96, 97, 0, 0, 0, 96, 97, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 96, 97, 0, 0, 0, 0, 0, 0, 0, 0, 0, 101, 0, 0, 0, 48, 0, 0, 0, 0, 101, 0, 0, 101,
    0, 0, 0, 0, 0, 0, 0, 0, 96, 97, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 101, 0, 0, 101, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 49, 0, 0, 0, 0, 97, 96, 0, 0, 0, 97, 96, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 97, 96, 0, 0, 0, 0, 0, 0, 0, 48, 0, 101, 0, 48, 0, 0, 0, 0, 0, 0, 101, 0, 0, 101,
    0, 0, 0, 0, 0, 0, 0, 0, 97, 96, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16, 0, 0, 0, 0, 0, 101, 16, 0, 101, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 101, 0, 0, 0, 0, 96, 97, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 96, 97, 0, 0, 0, 0, 0, 0, 0, 0, 96, 97, 0, 0, 0, 0, 0, 0, 0, 0, 97, 96, 97, 96,
    0, 0, 0, 0, 0, 0, 0, 0, 96, 97, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 96, 97, 96, 97, 96, 97,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 101, 0, 0, 0, 0, 97, 96, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 97, 96, 0, 0, 0, 0, 0, 0, 0, 0, 97, 96, 0, 0, 0, 0, 0, 0, 0, 0, 96, 97, 96, 97,
    0, 0, 0, 0, 0, 0, 0, 0, 97, 96, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 97, 96, 97, 96, 97, 96,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 101, 0, 0, 0, 0, 96, 97, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 101, 101, 0, 0, 0, 0, 0, 40, 0, 0, 96, 97, 0, 0, 0, 0, 0, 0, 0, 0, 101, 0, 0, 101,
    0, 0, 0, 0, 0, 0, 0, 0, 101, 101, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 96, 97, 96, 97, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 96, 97, 96, 97, 96, 97,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 96, 97, 96, 97, 0, 0, 0, 0, 0, 0, 0, 0, 101, 0, 0, 0, 0, 97, 96, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 101, 101, 0, 0, 0, 0, 0, 0, 0, 0, 97, 96, 0, 0, 0, 0, 0, 0, 0, 0, 101, 0, 0, 101,
    0, 0, 0, 0, 0, 0, 0, 0, 101, 101, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 97, 96, 97, 96, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 97, 96, 97, 96, 97, 96,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 97, 96, 97, 96, 0, 0, 0, 0, 0, 0, 0, 0, 101, 0, 0, 0, 0, 96, 97, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 101, 101, 0, 0, 0, 0, 0, 0, 0, 0, 96, 97, 0, 0, 0, 0, 0, 0, 0, 0, 101, 0, 0, 101,
    0, 0, 0, 0, 0, 0, 0, 0, 101, 101, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 101, 0, 0, 101, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 96, 97, 96, 97, 96, 97,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 101, 0, 0, 101, 0, 0, 0, 0, 0, 0, 0, 0, 101, 0, 0, 0, 0, 97, 96, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 101, 101, 0, 0, 0, 0, 0, 0, 0, 0, 97, 96, 0, 0, 0, 0, 0, 0, 0, 0, 101, 0, 0, 101,
    0, 0, 0, 0, 0, 0, 0, 0, 101, 101, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 114, 120, 120, 120, 120, 115, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 114, 120, 120, 120, 120, 115, 0, 0, 39, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 116, 112, 112, 112, 112, 112, 112, 112, 117, 0, 63, 63, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 44, 0, 0, 0,
    0, 0, 0, 0, 0, 116, 121, 112, 112, 112, 112, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 116, 121, 112, 112, 112, 112, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 116, 121, 112, 112, 112, 121, 117, 0, 63, 0, 0, 0, 44, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 56, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 116, 121, 121, 117, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 116, 121, 121, 117, 0, 0, 52, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 49, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 43, 0, 0, 0, 0, 0, 0, 63, 0, 0, 0, 0, 0, 0, 0, 116, 121, 117, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 56, 0, 0, 0, 44, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 114, 120, 120, 115, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 39, 0, 0, 0, 0, 0, 44, 0, 0, 0, 0, 0, 56, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 56, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 114, 112, 112, 112, 112, 120, 120, 115, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 63, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 56, 0, 0, 0, 0, 0, 63, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 56, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 116, 121, 121, 112, 112, 112, 112, 112, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 43, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 63, 0, 114, 120, 115, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 56, 56, 0, 0, 63, 0, 63, 0, 0, 0,
    0, 0, 0, 114, 120, 115, 0, 0, 0, 0, 0, 0, 0, 56, 0, 0, 0, 0, 0, 44, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 43, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 56, 0, 56, 0, 0, 116, 121, 121, 121, 117, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 114, 120, 112, 112, 112, 120, 115, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    40, 114, 120, 112, 112, 112, 120, 115, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 52, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 43, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    114, 112, 112, 112, 112, 112, 112, 112, 115, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 56, 0, 0, 56, 0, 0, 0, 0, 0, 0, 0,
    114, 112, 112, 112, 112, 112, 112, 112, 115, 0, 39, 0, 56, 0, 56, 0, 39, 0, 0, 0, 0, 0, 0, 0, 44, 0, 0, 44, 0, 0, 0,
    0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 56, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 44, 0, 0, 44, 0, 0, 0, 0, 50, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 43, 0,
    116, 112, 112, 112, 112, 112, 112, 112, 117, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 56, 0, 0, 0, 0, 0, 0, 0, 0, 44,
    116, 112, 112, 112, 112, 112, 112, 112, 117, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 44, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 49, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 43, 0, 0, 0, 0, 0, 56, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 116, 121, 112, 112, 112, 121, 117, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 56, 56, 0, 0, 0, 0, 0, 0, 0,
    0, 116, 121, 112, 112, 112, 121, 117, 0, 0, 0, 0, 0, 56, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 114, 120, 120, 120, 115, 0, 0, 56, 0, 0, 0, 0, 0, 0, 0, 50, 50, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 114, 120, 120, 120, 115, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 63, 0, 116, 121, 117, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 56, 0, 0, 0, 0, 63, 0, 63, 0, 0, 0,
    0, 0, 0, 116, 121, 117, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 44, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 49, 0, 0, 0, 0, 0, 0, 0, 116, 112, 112, 112, 112, 120, 120, 115, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 116, 112, 112, 112, 112, 120, 115, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 63, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 56, 0, 0, 0, 0, 63, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 56, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 116, 121, 112, 112, 112, 112, 117, 56, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 116, 121, 112, 112, 112, 117, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 39, 0, 0, 0, 0, 0, 44, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 56, 56, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 114, 120, 120, 115, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 116, 121, 121, 117, 0, 0, 56, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 114, 120, 120, 115, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 116, 121, 117, 0, 0, 0, 0, 0, 0, 0, 0, 0, 49, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 43, 0, 0, 0, 0, 0, 0, 63, 0, 0, 0, 0, 0, 0, 0, 114, 120, 115, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 44, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    120, 112, 112, 112, 112, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 56, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 114,
    120, 112, 112, 112, 112, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 114, 120, 112, 112, 112, 120, 115, 0, 63, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 44, 0, 0, 0,
    121, 121, 121, 121, 117, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 116,
    121, 121, 121, 121, 117, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 114, 112, 112, 112, 112, 112, 112, 112, 115, 0, 63, 63, 0, 44, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 56, 56, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
}

SFX={
	"PAT 12 C.3050 D.2500 C.2500 B.1500 G#1500 F#1500 E.1500 C.1500 C.1500 C.1500 C.1500 C.1500 C.1500 C.1500 C.1500 C.1500 C.1500 C.1500 C.1500 C.1500 C.1500 C.1500 C.1500 C.1500 C.1500 C.1500 C.1500 C.1500 C.1500 C.1500 C.1500 C.1500",
	"PAT 12 C.3150 C.1500 C.1500 C.1500 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
	"PAT 16 C.1070 C.1070 C.2000 D.2000 C.2000 ...... F.1070 F.1070 C.2000 C.2000 G.1070 G.1075 D.1070 D.1070 E.2000 E.2000 ...... ...... G.1070 G.1070 C.2000 C.2000 C.1070 C.1070 ...... ...... ...... ...... ...... ...... ...... ......",
	"PAT 21 F#2530 A#2550 F#2535 F#2530 A#2530 D#2000 A#2530 G#2530 F.2530 G#2530 ...... G#2530 B.3500 F.2530 G#2530 F.3500 G#2530 D#3530 G#3500 G#2530 D#3530 ...... G#2530 D#3500 D#2530 C#2530 ...... C#2530 ...... D#2530 C#2530 ......",
	"PAT 21 G#3500 ...... ...... ...... C#4500 C#5750 A#4750 ...... G#4750 G#4731 G#4711 G#3500 ...... G#4750 F.4750 G#3500 D#4750 D#4731 D#4711 ...... ...... A#3700 ...... A#3750 ...... G#3750 ...... C#4750 ...... D#4750 C#4750 C#4700",
	"PAT 21 G#3500 ...... ...... ...... C#4500 F#4750 F.4750 ...... D#4750 D#4731 D#4711 G#3500 ...... F.4750 D#4750 G#3500 C#4750 C#4731 C#4711 C#4700 C#4700 A#3700 ...... C#4750 ...... G#3750 ...... F.4750 ...... D#4750 C#4750 C#4700",
	"PAT 21 C.1700 C.1700 C.1700 C.1700 C.1700 C.1700 C.1700 C.1700 C.1700 C.1700 C.1700 C.1700 C.1700 C.1700 C.1700 C.1700 C#5710 C.1700 C#5720 C.1700 C#5730 C.1700 C#5740 C.1700 C#5750 C.1700 F.4750 D#4750 C.1700 F.4750 D#4750 C.1700",
	"PAT 21 G#3500 ...... ...... ...... C#4500 F#4750 F.4750 ...... D#4750 D#4731 D#4711 G#3500 ...... F.4750 D#4750 G#3500 C#4750 C#4731 C#4711 ...... ...... G#3750 A#3750 ...... C#4750 C#4700 ...... C#4750 ...... D#4750 C#4750 ......",
	"PAT 16 D.4040 D.4021 D#4040 D#4000 D.4040 D.4000 C.4040 C.4000 F.4040 D#4040 F.4040 D#4040 C.4042 C.4042 C.4042 C.4042 C.4045 ...... B.3042 B.3042 B.3042 B.3045 B.3040 C.4040 ...... ...... ...... ...... ...... ...... ...... ......",
	"PAT 16 C.2130 C.2100 G#2130 G.2130 G#2130 C.2100 F.2130 C.2100 G#2130 C.2100 F.2130 C.2100 D#2130 C.2100 G.2130 F.2130 G.2130 C.2100 D#2130 C.2100 G.2130 C.2100 D#2130 C.1100 C.3100 C.1100 G.3100 C.3100 G.3100 C.1100 F.3100 C.1100",
	"PAT 2 F.3640 A#2060 A#2640 G#2060 C.2640 F#2060 F#1640 D.2050 D#1630 B.1050 D.1630 G.1040 D.1620 E.1040 D.1620 D.1030 D.1610 D.1030 C.2600 B.1600 A#1600 A.1600 G#1600 G.1600 F.1600 D#1600 D.1600 D.1600 E.1600 C.1600 C.1600 C.1600",
	"PAT 2 A#1640 C.2060 A#1630 D#2050 A#1610 A.2030 A#1610 C#5000 C.2000 A#1000 A.1000 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
	"PAT 3 F.2050 C#1050 D#3050 C#1050 G.3050 D#1050 B.3050 G#1050 G#4050 D.2050 A.5050 D.2020 B.4020 D.2000 A.5000 D.2000 B.4000 ...... A.5000 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
	"PAT 3 E.5220 A#3220 C.3220 E.2220 A#1220 F#1040 E.1040 D#1040 D#1040 D#1040 D#1040 C.1200 C.1200 C.1200 C.1200 C.1200 C.1200 C.1200 C.1200 C.1200 C.1200 C.1200 C.1200 C.1200 C.1200 C.1200 C.1200 C.1200 C.1200 C.1200 C.1200 C.1200",
	"PAT 12 G.1070 G.1075 ...... ...... D.1070 D.1075 ...... ...... G.1070 G.1075 ...... ...... D.1070 D.1075 C#5700 A.4700 F#1070 F#1075 ...... ...... C#1070 C#1075 ...... G#4700 F#1070 F#1075 ...... ...... C#1070 C#1075 ...... F.4700",
	"PAT 12 G.1070 G.1075 ...... ...... D.2070 D.2075 ...... ...... G.1070 G.1075 ...... ...... D.1070 D.1075 ...... ...... G.1070 G.1075 ...... ...... D.2070 D.2075 ...... ...... D.1070 D.1075 C#5500 F#4500 F#4500 C#4500 C#4500 F#4500",
	"PAT 16 C.3130 C.1100 G.3130 C.3130 G.3130 C.1100 F.3130 C.1100 C.4130 C.1100 G.3130 C.1100 D#3130 C.1100 G.3130 D#3130 G.3130 C.1100 D.3130 C.1100 G.3130 C.1100 B.2130 C.1100 C.3100 C.1100 G.3100 C.3100 G.3100 C.1100 F.3100 C.1100",
	"PAT 16 ...... C.4000 D.5000 C.5000 ...... ...... ...... ...... C.5040 D.5040 C.5040 ...... G#4040 ...... G.4040 ...... G#4040 ...... G.4042 G.4042 G.4042 ...... C.4040 D.4040 ...... ...... ...... ...... ...... ...... ...... ......",
	"PAT 12 C.3270 C.3270 C.3270 C.3270 C.3270 C.3270 C.3270 C.3270 C.3270 C.3270 C.3270 C.3270 C.3270 C.3270 C.3270 C.3270 C.3270 C.3270 C.3270 C.3270 C.3270 C.3270 C.3270 C.3270 C.3270 C.3270 C.3270 C.3270 C.3270 C.3270 C.3270 C.3270",
	"PAT 16 D#4040 D#4021 D.4040 ...... D#4040 ...... D.4040 ...... G.4040 G.4040 F.4040 ...... D#4042 D#4042 D#4042 D#4042 F.4040 F.4045 D.4042 D.4042 F.4150 D#4150 D.4150 D#4150 ...... ...... ...... ...... ...... ...... ...... ......",
	"PAT 16 C.3053 C.3100 C.2625 D.2635 C.2645 F.1100 C.3053 ...... C.2644 C.2645 E.2645 E.2605 C.3053 D.1100 E.2625 F.2635 E.2645 ...... C.3053 G.1100 C.2644 C.2645 E.2645 E.2600 ...... ...... ...... ...... ...... ...... ...... ......",
	"PAT 16 C.3130 C.1100 G.3130 C.3130 G.3130 C.1100 F.3130 C.1100 C.4130 C.1100 G.3130 C.1100 D#3130 C.1100 G.3130 D#3130 G.3130 C.1100 D.3130 C.1100 G.3130 C.1100 B.2130 C.1100 C.3100 C.1100 G.3100 C.3100 G.3100 C.1100 F.3100 C.1100",
	"PAT 16 C.4150 C.4100 ...... ...... ...... ...... ...... ...... C.5040 B.4040 C.5040 C.1500 G#4040 ...... G.4040 ...... G#4040 ...... G.4042 G.4042 G.4042 C.1500 C.4040 D.4040 ...... ...... ...... ...... ...... ...... ...... ......",
	"PAT 16 D#4040 D#4021 D.4040 ...... C.4040 ...... D.4042 D.4042 D.4042 ...... B.3040 ...... C.4042 C.4042 C.4042 C.4042 D.4040 D.4045 B.3042 B.3042 B.3042 B.3042 ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
	"PAT 16 C.4050 C.4001 G.4720 C.1700 G.4720 C.1700 F.4720 C.1700 G#4720 C.1700 C.1700 C.1700 C.1700 C.1700 F.4720 C.1700 F.4720 C.1700 D#4720 C.1700 G.4720 C.1700 C.1700 C.1700 C.1700 C.1700 C.1700 C.1700 C.1700 C.1700 C.1700 C.1700",
	"PAT 16 ...... ...... G.4720 ...... G.4720 ...... F.4720 ...... G#4720 ...... ...... ...... D.4720 ...... D#4720 ...... F.4720 ...... B.3720 ...... G.4720 ...... D.4720 ...... ...... ...... ...... ...... ...... ...... ...... ......",
	"PAT 16 G#2130 C.2100 D#3130 G#2130 D#3130 C.2100 G#2130 C.2100 D#3130 C.3100 G.3130 C.3100 G.2130 C.2100 D.3130 G.2130 D.3130 C.3100 G.2130 C.2100 D.3130 C.3100 G.3130 C.1100 C.3100 C.1100 G.3100 C.3100 G.3100 C.1100 F.3100 C.1100",
	"PAT 16 D#4040 D#4021 D.4040 ...... C.4040 ...... D.4042 D.4042 D.4042 ...... B.3040 ...... C.4042 C.4042 C.4042 C.4042 D.4040 D.4045 B.3042 B.3042 B.3042 B.3042 F.4040 G.4040 ...... ...... ...... ...... ...... ...... ...... ......",
	"PAT 16 G#4042 G#4042 G#4042 ...... G.4040 ...... F.4042 F.4042 F.4042 ...... D#4040 F.4040 G.4042 G.4042 G.4042 ...... F.4040 ...... D#4042 D#4042 D#4042 D#4042 D#4045 ...... ...... ...... ...... ...... ...... ...... ...... ......",
	"PAT 16 F.4042 F.4042 F.4042 F.4042 F.4045 ...... D#4042 D#4042 D#4042 D#4045 F.4040 D#4040 D.4060 ...... C.4060 ...... D.4060 ...... C.4030 C.4033 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
	"PAT 16 C.1150 C.1145 C.2600 D.2600 C.2600 ...... F.1150 F.1145 C.2600 C.2600 G.1150 G.1155 D.1150 D.1145 E.2600 E.2600 ...... ...... G.1150 G.1145 C.2600 C.2600 C.1150 C.1155 ...... ...... ...... ...... ...... ...... ...... ......",
	"PAT 12 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
	"PAT 16 D.4042 D.4042 D.4042 D.4042 D.4045 ...... C.4042 C.4042 C.4042 C.4045 D#4040 D#4045 D.4042 D.4042 D.4042 D.4042 D.4045 ...... C.4042 C.4042 C.4042 C.4045 D.4040 D#4040 ...... ...... ...... ...... ...... ...... ...... ......",
	"PAT 12 D.4730 D.4730 D.4721 D.4725 C.1700 C.1700 C.1700 C.1700 F#4730 F#4730 F#4721 F#4725 C.3700 C.3700 C.3700 C.3700 E.4730 E.4730 E.4721 E.4725 G.4700 G.4700 C.1700 C.1700 G.4730 G.4730 G.4721 G.4725 C.3700 C.3700 C.3700 C.3700",
	"PAT 12 C#4730 C#4730 C#4721 C#4725 F#4700 F#4700 C.1700 C.1700 E.4730 E.4730 E.4721 E.4725 G.4700 G.4700 C.1700 C.1700 A.3730 A.3730 A.3721 A.3725 E.4700 E.4700 C.1700 C.1700 C#4730 C#4730 C#4721 C#4725 C#4700 C#4700 C.1700 C.1700",
	"PAT 12 B.3100 C.1100 C.1100 C.1100 C.1100 C.1100 F#4130 E.4130 D.4130 C.1100 B.3130 C.1100 A.3130 C.1100 B.3130 C.1100 A.3130 A.3130 A.3121 A.3111 F#3130 C.1100 D.4130 C.1100 B.3130 B.3130 B.3121 B.3111 A.3130 A.3121 G.3130 F#3130",
	"PAT 12 G.3130 G.3130 G.3121 G.3111 F#3130 F#3130 F#3121 F#3111 E.3130 E.3130 E.3121 E.3111 D.3130 D.3130 D.3121 D.4134 E.3130 E.3130 E.3121 F#4134 F#3130 F#3130 F#3121 D.4134 G.3130 G.3130 G.3121 C#4134 A.3130 A.3130 A.3121 B.3134",
	"PAT 12 B.3130 B.3130 B.3121 B.3111 C.1100 C.1100 F#4130 E.4130 D.4130 C.1100 B.3130 C.1100 A.3130 C.1100 B.3130 C.1100 A.3130 A.3130 A.3121 A.3111 D.4130 D.4100 G.4130 G.4100 F#4130 F#4130 F#4121 F#4111 E.4130 E.4130 E.4121 E.4111",
	"PAT 12 D.4130 D.4130 D.4121 D.4111 C#4130 C#4130 C#4121 C#4111 B.3130 B.3130 B.3121 B.3111 A.3130 A.3130 A.3121 A.3111 F#3130 F#3130 F#3121 F#3111 G.3130 G.3130 G.3121 G.3111 A.3130 A.3130 A.3121 A.3111 C#4130 C#4130 C#4121 C#4111",
	"PAT 12 C.3043 ...... D.2635 C.2635 E.3043 C.2005 C.2635 ...... C.3043 ...... D.2635 C.2635 E.3043 C.2005 C.2635 ...... C.3043 ...... D.2635 C.2635 E.3043 C.2005 C.2635 ...... C.3043 ...... D.2635 C.2635 E.3043 D.2635 C.2635 ......",
	"PAT 12 B.2565 C.1500 F#3565 F#3565 B.2565 C.1500 F#3565 C.1500 B.2565 C.1500 F#3565 F#3565 B.2565 C.1500 F#3565 C.1500 E.3565 C.1505 G.3565 G.3565 B.2565 C.1500 G.3565 C.1500 E.3565 C.1505 G.3565 G.3565 B.2565 C.1500 G.3565 C.1500",
	"PAT 12 A.2565 C.1500 E.3565 E.3565 A.2565 C.1500 E.3565 C.1500 A.2565 C.1500 E.3565 E.3565 A.2565 C.1500 E.3565 C.1500 F#2565 C.1500 C#3565 C#3565 F#2565 C.1500 C#3565 C.1500 A.2565 C.1500 E.3565 E.3565 A.2565 C.1500 E.3565 C.1500",
	"PAT 12 B.1070 B.1075 ...... ...... F#1070 F#1075 ...... ...... B.1070 B.1075 ...... ...... F#1070 F#1075 ...... ...... B.1070 B.1075 ...... ...... G.1070 G.1075 ...... ...... B.1070 B.1075 ...... ...... G.1070 G.1075 ...... ......",
	"PAT 12 A.1070 A.1075 ...... ...... E.1070 E.1075 ...... ...... A.1070 A.1075 ...... ...... E.1070 E.1075 ...... ...... F#1070 F#1075 ...... ...... F#1070 F#1075 ...... ...... A.1070 A.1075 ...... ...... A#1070 A#1075 ...... ......",
	"PAT 12 G.4130 G.4130 G.4121 G.4121 G.4111 G.4111 F#4130 F#4135 E.4130 E.4130 E.4121 E.4121 E.4111 E.4115 D.4130 E.4130 F#4130 F#4130 F#4121 F#4121 F#4111 F#4111 E.4130 E.4135 D.4130 D.4130 D.4121 D.4120 C#4130 C#4130 C#4130 C#4135",
	"PAT 12 B.3130 B.3130 B.3130 B.3130 B.3121 B.3121 B.3111 B.3111 C#4130 C#4130 C#4130 C#4130 C#4121 C#4121 C#4111 C#4111 D.4130 D.4130 D.4130 D.4130 D.4121 D.4121 D.4111 D.4111 E.4130 E.4135 ...... ...... ...... ...... ...... ......",
	"PAT 12 D.4130 D.4130 D.4121 D.4111 C#4130 C#4130 C#4121 C#4111 B.3130 B.3130 B.3121 B.3111 A.3130 A.3130 A.3121 B.3134 F#3130 F#3130 F#3121 E.4134 G.3130 G.3130 G.3121 D.4134 A.3130 A.3130 A.3121 F#4134 C#4130 C#4130 E.4130 F#4130",
	"PAT 12 G.2565 C.1500 D.3565 D.3565 G.2565 C.1500 D.3565 C.1500 G.2565 C.1500 D.3565 D.3565 G.2565 C.1500 D.3565 C.1500 F#2565 C.1505 C#3565 C#3565 F#2565 C.1500 C#3565 C.1500 F#2565 C.1505 C#3565 C#3565 F#2565 C.1500 C#3565 C.1500",
	"PAT 12 G#2565 C.1500 D.3565 D.3565 G#2565 C.1500 D.3565 C.1500 G#2565 C.1500 D.3565 D.3565 G#2565 C.1500 D.3565 C.1500 G#2565 C.1500 D.3565 D.3565 G#2565 C.1500 D.3565 C.1500 G#2560 G#2565 E.4500 C.1500 C.1500 C.1500 C.1500 C.1500",
	"PAT 16 B.2130 C.2100 F.3130 E.3130 F.3130 C.2100 B.2130 C.2100 F.3130 C.2100 B.2130 C.2100 C.3130 C.2100 G.3130 F#3130 G.3130 C.2100 C.3130 C.2100 G.3130 C.2100 C.3130 C.1100 C.3100 C.1100 G.3100 C.3100 G.3100 C.1100 F.3100 C.1100",
	"PAT 16 B.2130 C.3100 F.3130 E.3130 F.3130 C.2100 B.2130 C.2000 F.3130 C.3100 B.2130 C.3100 D.3140 C.3100 C.3140 C.3100 D.3140 C.3100 C.3130 C.3133 C.1100 G.3100 C.3100 G.3100 C.1100 ...... ...... ...... ...... ...... ...... ......",
	"PAT 16 A#1070 A#1000 ...... A#1070 ...... A#1075 A#1070 A#1000 ...... A#1070 ...... A#1075 C.2070 C.2000 C.2000 C.2070 C.2000 C.2075 C.2070 C.2000 C.2000 C.2070 C.2070 C.3000 ...... ...... ...... ...... ...... ...... ...... ......",
	"PAT 16 G.3540 G.3545 C.4500 A.3540 A.3545 C.4500 A#3540 A#3531 A#3535 A#4500 C.1500 F.5500 F.4540 E.4540 D.4540 E.4540 D.4540 C.4540 D.4540 D.4531 D.4521 A#3540 A#3531 A#3521 C.1500 C.1500 C.1500 C.1500 C.1500 C.1500 C.1500 C.1500",
	"PAT 16 G.3540 G.3531 G.3535 C.4500 A.3540 A#3540 A.3540 A.3545 A.4500 F.3540 F.3545 F.4500 G.3540 F.3540 E.3540 E.3531 E.3521 E.3511 C.1500 C.1500 C.1500 D.3540 D.3545 C.1500 C.1500 C.1500 C.1500 C.1500 C.1500 C.1500 C.1500 C.1500",
	"PAT 16 A#1070 ...... C.2000 A#1070 ...... A#1075 A#1070 ...... ...... A#1070 ...... A#1075 G.1070 ...... ...... G.1070 ...... G.1075 G.1070 ...... ...... G.1070 G.1070 G.2000 ...... ...... ...... ...... ...... ...... ...... ......",
	"PAT 16 A#1070 A#2000 ...... A#1070 ...... A#1075 A#1070 A#2000 ...... A#1070 ...... A#1075 A#1070 A#1000 ...... A#1070 ...... A#1075 A#1070 A#1000 ...... A.1070 A.1070 A.1075 ...... ...... ...... ...... ...... ...... ...... ......",
	"PAT 16 G.2635 C.1600 C.1600 D.2635 C.2635 D.2635 C.2635 C.1600 C.1600 D.2635 C.2635 D.2635 C.2635 C.1605 C.1605 D.2635 C.2635 D.2635 C.2635 C.1605 C.4600 G.2635 C.1600 C.1600 C.1600 C.1600 C.1600 C.1600 C.1600 C.1600 C.1600 C.1600",
	"PAT 16 F.5740 F.5731 F.5721 F.5711 F.5700 F.5700 E.5740 E.5731 E.5721 E.5711 E.5700 ...... D.5740 D.5731 D.5721 D.5711 ...... ...... C.5740 C.5731 C.5721 C.5711 ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
	"PAT 16 A.4740 A.4731 A.4721 A.4711 ...... ...... G.4740 G.4731 G.4735 G.4740 ...... D.5740 C.5740 C.5731 C.5721 C.5711 C.5711 C.5715 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
	"PAT 21 F.3530 F.3500 F#3500 G#3530 ...... D#2000 D#2000 ...... F.3530 F#3500 ...... G#3530 ...... ...... ...... ...... F.3530 F.3500 F#3500 G#3530 ...... ...... A#3530 ...... F.3530 F#3500 ...... G#3530 ...... C#3530 G#3530 ......",
	"PAT 21 C#4750 ...... ...... ...... C#4500 F.4750 F#4750 ...... G#4750 G#4731 G#4711 G#3500 ...... A#4750 G#4750 G#3500 F.4750 F.4731 F.4711 ...... ...... ...... ...... D#4750 ...... F.4750 ...... D#4750 ...... F.4750 D#4750 C#4750",
	"PAT 21 C#4700 ...... ...... ...... C#4500 F.4750 F#4750 ...... G#4750 G#4731 G#4711 ...... ...... C#5750 A#4750 ...... G#4750 G#4731 G#4711 ...... ...... ...... ...... C#4750 C#4750 G#3750 G#3700 F.4750 ...... D#4750 C#4750 ......",
	"PAT 21 C.2625 ...... C.2600 D.2625 ...... C.2615 D.2625 ...... C.2625 ...... C.2600 D.2625 ...... C.2615 D.2625 ...... C.2625 ...... C.2600 D.2625 ...... C.2615 D.2625 ...... C.2625 ...... C.2600 D.2625 ...... C.2615 D.2625 ......",
	"PAT 21 C#2050 F.3000 F#3000 D#2050 ...... D#2000 D#2000 ...... F.2050 F#3000 ...... D#2050 ...... ...... ...... ...... C#2050 F.3000 F#3000 D#2050 ...... ...... A#3000 ...... F.2050 F#3000 ...... D#2050 ...... C#3000 G#3000 ......",
}

PATTERNS={
18,16,-1,20,
18,16,-1,20,
18,16,17,20,
18,16,19,20,
18,16,22,20,
18,16,23,20,
18,16,24,20,
18,16,25,20,
18,16,17,20,
18,16,19,20,
18,16,22,20,
18,16,27,20,
31,26,28,20,
31,49,8,20,
31,26,32,20,
31,50,29,20,
42,33,40,39,
43,34,41,39,
42,33,40,39,
43,34,41,39,
42,35,40,39,
43,36,41,39,
42,37,40,39,
43,38,41,39,
42,33,40,39,
43,34,41,39,
42,33,40,39,
43,34,41,39,
40,35,42,39,
43,36,41,39,
42,37,40,39,
43,46,41,39,
14,44,47,39,
15,45,48,39,
31,55,-1,56,
31,55,-1,56,
31,51,52,56,
31,54,53,56,
31,51,52,56,
31,54,53,56,
31,51,57,56,
31,54,58,56,
31,51,57,56,
31,54,58,56,
59,-1,62,63,
59,6,62,63,
59,60,62,63,
59,61,62,63,
59,60,62,63,
59,61,62,63,
3,4,62,-1,
3,5,62,-1,
3,4,62,-1,
3,7,62,-1,
-1,-1,-1,-1,
-1,-1,-1,-1,
-1,-1,-1,-1,
-1,-1,-1,-1,
-1,-1,-1,-1,
-1,-1,-1,-1,
-1,-1,-1,-1,
-1,-1,-1,-1,
-1,-1,-1,-1,
-1,-1,-1,-1,
}

INST_TRIANGLE = "INST OVERTONE 1.0 TRIANGLE 1.0 METALIZER 0.85 NAM triangle"
INST_TILTED = "INST OVERTONE 1.0 TRIANGLE 0.5 SAW 0.1 NAM tilted"
INST_SAW = "INST OVERTONE 1.0 SAW 1.0 ULTRASAW 1.0 NAM saw"
INST_SQUARE = "INST OVERTONE 1.0 SQUARE 0.5 NAM square"
INST_PULSE = "INST OVERTONE 1.0 SQUARE 0.5 PULSE 0.5 TRIANGLE 1.0 METALIZER 1.0 OVERTONE_RATIO 0.5 NAM pulse"
INST_ORGAN = "INST OVERTONE 0.5 TRIANGLE 0.75 NAM organ"
INST_NOISE = "INST NOISE 1.0 NOISE_COLOR 0.2 NAM noise"
INST_PHASER = "INST OVERTONE 0.5 METALIZER 1.0 TRIANGLE 0.7 NAM phaser"

MUSIC = [[NAM music
PATLIST 3 4 5 6 7 8 14 15 16 17 18 19 20 22 23 24 25 26 27 28 29 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63
SEQ2 0a08..0c.... 0a08..0c.... 0a08090c.... 0a080b0c.... 0a080d0c.... 0a080e0c.... 0a080f0c.... 0a08100c.... 0a08090c.... 0a080b0c.... 0a080d0c.... 0a08120c.... 1511130c.... 1527050c.... 1511160c.... 1528140c.... 20171e1d.... 21181f1d.... 20171e1d.... 21181f1d.... 20191e1d.... 211a1f1d.... 201b1e1d.... 211c1f1d.... 20171e1d.... 21181f1d.... 20171e1d.... 21181f1d.... 1e19201d.... 211a1f1d.... 201b1e1d.... 21241f1d.... 0622251d.... 0723261d.... 152d..2e.... 152d..2e.... 15292a2e.... 152c2b2e.... 15292a2e.... 152c2b2e.... 15292f2e.... 152c302e.... 15292f2e.... 152c302e.... 31..3435.... 31033435.... 31323435.... 31333435.... 31323435.... 31333435.... 000134...... 000234...... 000134...... 000434...... ............ ............ ............ ............ ............ ............ ............ ............ ............ ............
]]
