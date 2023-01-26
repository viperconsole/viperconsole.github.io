-- ################################## UTILITIES ##################################
flr = math.floor
sqrt = math.sqrt
atan2 = math.atan
max = math.max
min = math.min

clamp = function(v, mi, ma)
    return v < mi and mi or (v > ma and ma or v)
end
asin = math.asin
abs = math.abs
round = function(v)
    return math.floor(v + 0.5)
end
random = math.random
cos = math.cos
sin = math.sin

function col(r, g, b)
    return {
        r = r / 255,
        g = g / 255,
        b = b / 255
    }
end

function distance(x0, y0, x1, y1)
    return sqrt((x1 - x0) * (x1 - x0) + (y1 - y0) * (y1 - y0))
end
function compute_x(x, len, align)
    if align == const.ALIGN_CENTER then
        return flr(x - len * 0.5)
    elseif align == const.ALIGN_RIGHT then
        return flr(x - len)
    else
        return x
    end
end

function gprint(msg, x, y, col)
    gfx.print(msg, x, y, conf.PALETTE[col].r, conf.PALETTE[col].g, conf.PALETTE[col].b)
end

function gprint_center(msg, x, y, col)
    gprint(msg, flr(x - #msg * 3), y, col)
end

function gprint_right(msg, x, y, col)
    gprint(msg, flr(x - #msg * 6), y, col)
end

function clerp(coef, c1, c2)
    local p1 = conf.PALETTE[c1]
    local p2 = conf.PALETTE[c2]
    return {
        r = p1.r + coef * (p2.r - p1.r),
        g = p1.g + coef * (p2.g - p1.g),
        b = p1.b + coef * (p2.b - p1.b)
    }
end

function inside(px, py, x, y, w, h)
    return px >= x and py >= y and px < x + w and py < y + h
end

timer = {
    t = elapsed()
}
function timer.step(msg)
    print(msg .. ": " .. string.format("%.2f", elapsed() - timer.t) .. " s")
    timer.t = elapsed()
end

-- ################################## GLOBALS ##################################

g_mouse_x = 0
g_mouse_y = 0
g_screen = {}

-- ################################## CONSTANTS ##################################

const = {
    LIGHT_THRESHOLD1 = 0.5,
    LIGHT_THRESHOLD2 = 0.75,

    LAYER_BACKGROUND = 0,
    LAYER_STARS = 1,
    LAYER_ENTITIES = 2,
    LAYER_TRAILS = 3,
    LAYER_GUI = 4,
    LAYER_SHIP_MODELS = 5,
    LAYER_SPRITES = 6,

    PI = math.pi,
    PI2 = 2 * math.pi,
    BUTTON_WIDTH = 60,

    -- entity types
    E_PLANET = 1,
    E_STARFIELD = 2,
    E_LABEL = 3,
    E_BUTTON = 4,
    E_SHIP = 5,
    E_TRAIL = 6,

    -- text alignment
    ALIGN_CENTER = 0,
    ALIGN_RIGHT = 1,
    ALIGN_LEFT = 2,

    -- trail conf
    TRAIL_SEG_LEN = 5
}

-- ################################## TRAILS ##################################
trail = {}

function trail.generate()
    local x = random(0, gfx.SCREEN_WIDTH)
    local y = gfx.SCREEN_HEIGHT * 0.5
    local t = {
        typ = const.E_TRAIL,
        x = x,
        y = y,
        angle = const.PI * 0.5,
        vangle = (random() - 0.5) * 0.01,
        speed = random(2, 5) * 0.1,
        seg_length = 0,
        fade_in = 6.0,
        length = random(5, 15),
        trail = {{
            x = x,
            y = y
        }},
        color = random(1, 18),
        update = trail.update,
        render = trail.render
    }
    while #t.trail ~= t.length do
        trail.update(t)
    end
    return t
end

function trail.update(t)
    t.seg_length = t.seg_length + t.speed
    t.fade_in = max(0, t.fade_in - 0.01)
    if t.seg_length > const.TRAIL_SEG_LEN then
        table.insert(t.trail, {
            x = t.x,
            y = t.y
        })
        if #t.trail > t.length then
            table.remove(t.trail, 1)
        end
        t.seg_length = 0
        if random(0, 100) < 10 then
            t.vangle = (random() - 0.5) * 0.01
        end
        if t.x < -const.TRAIL_SEG_LEN * t.length or t.x > gfx.SCREEN_WIDTH + const.TRAIL_SEG_LEN * t.length or t.y <
            -const.TRAIL_SEG_LEN * t.length or t.y > gfx.SCREEN_WIDTH + const.TRAIL_SEG_LEN * t.length then
            return true
        end
    end
    t.x = t.x + cos(t.angle) * t.speed
    t.y = t.y + sin(t.angle) * t.speed
    t.angle = t.angle + t.vangle
end

function trail.render(t)
    local x = t.x
    local y = t.y
    local col = conf.PALETTE[t.color]
    local seg_part = t.seg_length / const.TRAIL_SEG_LEN
    local col_coef = ease_in_cubic(max(0, #t.trail - 1 - t.fade_in), 0.0, 1.0, #t.trail - 1 + seg_part)
    for i = #t.trail, 1, -1 do
        local p = t.trail[i]
        gfx.line(x, y, p.x, p.y, col.r * col_coef, col.g * col_coef, col.b * col_coef)
        x = p.x
        y = p.y
        col_coef = ease_in_cubic(max(0, i - 1 - t.fade_in), 0.0, 1.0, #t.trail - 1 + seg_part)
    end
end

-- ################################## PLANETS ##################################
planet = {}
function planet.update(this)
    this.rot = this.rot + 0.0001
end

function planet.compute_lut(p, light)
    local x0 = p.x - p.radius
    local y0 = p.y - p.radius
    local x1 = p.x + p.radius
    local y1 = p.y + p.radius
    local xstart = max(x0, 0)
    local xend = min(x1, gfx.SCREEN_WIDTH - 1)
    local ystart = max(y0, 0)
    local yend = min(y1, gfx.SCREEN_HEIGHT - 1)
    local rad2 = p.radius * p.radius
    local lightdist = distance(light.x, light.y, p.x, p.y)
    local minlight = max(1, lightdist - p.radius)
    local lightdiv = 1 / (lightdist + p.radius - minlight)
    local data = {}
    for y = ystart, yend do
        local dy = y - p.y
        local dy2 = dy * dy
        for x = xstart, xend do
            local dx = x - p.x
            local r2 = dy2 + dx * dx
            local pixel_data = {}
            if r2 < rad2 then
                local dith = (x + y) % 2 == 0 and 2 or 0
                local z = max(1, sqrt(rad2 - r2 * 0.9))
                local xsphere = (dx + dith) / z
                local ysphere = (dy + dith) / z
                local d_light = 1 - (distance(x + dith, y + dith, light.x, light.y) - minlight) * lightdiv
                d_light = clamp(flr(d_light * 2) / 2 + 0.5, 0, 1)
                pixel_data.xsphere = xsphere
                pixel_data.ysphere = ysphere
                pixel_data.light = d_light
                pixel_data.black = false
            else
                pixel_data.black = true
            end
            table.insert(data, pixel_data)
        end
    end
    p.lut = {
        xstart = xstart,
        xend = xend,
        ystart = ystart,
        yend = yend,
        rad2 = rad2,
        pixel_data = data
    }
end

function planet.generate(light)
    local radius = random(gfx.SCREEN_HEIGHT // 3, gfx.SCREEN_HEIGHT // 2)
    local p = {
        typ = const.E_PLANET,
        x = random(0, gfx.SCREEN_WIDTH),
        y = random(0, gfx.SCREEN_HEIGHT),
        radius = radius,
        rot = 0,
        tex_width = min(gfx.SCREEN_WIDTH, flr(const.PI2 * radius)),
        tex_height = min(gfx.SCREEN_HEIGHT, radius * 2)
    }
    planet.compute_lut(p, light)
    p.render = planet.render
    p.update = planet.update
    return p
end

function planet.render(this)
    local sprite = {}
    local cols = {7, 6, 5, 12, 11, 4}
    local i = 1
    for y = this.lut.ystart, this.lut.yend do
        for x = this.lut.xstart, this.lut.xend do
            local pix = this.lut.pixel_data[i]
            if pix.black then
                table.insert(sprite, 0)
            else
                local tex = clamp((fbm2(pix.xsphere * 0.3 + this.rot, pix.ysphere * 0.3 + 20) + 1) * 0.5, 0, 1)
                local color = tex ^ 0.8 * 6
                color = clamp(color, 1, 6)
                local c = conf.PALETTE[cols[flr(color)]]
                local r = max(1 / 255, c.r * pix.light)
                local g = max(1 / 255, c.g * pix.light)
                local b = max(1 / 255, c.b * pix.light)
                table.insert(sprite, gfx.to_rgb24(r, g, b))
            end
            i = i + 1
        end
    end
    gfx.blit_pixels(this.lut.xstart, this.lut.ystart, this.lut.xend - this.lut.xstart + 1, sprite)
end

-- ################################## SECTOR ##################################
sector = {}
function sector.update(s)
    for i = #s.entities, 1, -1 do
        local e = s.entities[i]
        if e.update ~= nil then
            if e:update() ~= nil then
                table.remove(s.entities, i)
                sector.spawn_trail(s)
            end
        end
    end
end

function sector.render(s)
    gfx.set_active_layer(const.LAYER_TRAILS)
    gfx.clear(0, 0, 0)
    gfx.set_active_layer(const.LAYER_ENTITIES)
    gfx.clear(0, 0, 0)
    for _, e in pairs(s.entities) do
        if e.render ~= nil then
            if e.typ == const.E_TRAIL then
                gfx.set_active_layer(const.LAYER_TRAILS)
            end
            e:render()
            if e.typ == const.E_TRAIL then
                gfx.set_active_layer(const.LAYER_ENTITIES)
            end
        end
    end
end

function sector.spawn_trail(s)
    table.insert(s.entities, trail.generate())
end

function sector.generate(seed, planet, light)
    math.randomseed(seed)
    local entities = {}
    light = {
        x = random(0, gfx.SCREEN_WIDTH),
        y = 0 -- random(0, gfx.SCREEN_HEIGHT)
    }
    table.insert(entities, planet.generate(light))
    table.insert(entities, trail.generate())
    table.insert(entities, trail.generate())

    return {
        entities = entities,
        update = sector.update,
        render = sector.render
    }
end

-- ################################## GUI ##################################

gui = {}

function gui.render_label(lab)
    if lab.align == const.ALIGN_CENTER then
        gprint_center(lab.msg, lab.x + 1, lab.y + 1, 3)
        gprint_center(lab.msg, lab.x, lab.y, lab.col)
    elseif lab.align == const.ALIGN_RIGHT then
        gprint_right(lab.msg, lab.x + 1, lab.y + 1, 3)
        gprint_right(lab.msg, lab.x, lab.y, lab.col)
    else
        gprint(lab.msg, lab.x + 1, lab.y + 1, 3)
        gprint(lab.msg, lab.x, lab.y, lab.col)
    end
end

function gui.render_bkgnd(x, y, len, len2, col)
    gfx.blit(6, 36, 6, 18, x - 6, y - 6, 0, 0, false, false, col, col, col)
    gfx.blit(12, 36, 6, 18, x, y - 6, len, 0, false, false, col, col, col)
    if len2 > 0 then
        gfx.blit(24, 36, 6, 18, x + len, y - 6, 0, 0, false, false, col, col, col)
        if len2 > 6 then
            gfx.blit(30, 36, 6, 18, x + len + 6, y - 6, 0, 0, false, false, col, col, col)
        end
    end
    gfx.blit(18, 36, 6, 18, round(x + len + len2), y - 6, 0, 0, false, false, col, col, col)
end

function gui.gen_label(msg, x, y, col, align)
    return {
        typ = const.E_LABEL,
        msg = msg,
        x = flr(x),
        y = flr(y),
        col = col,
        align = align,
        render = gui.render_label,
        update = nil
    }
end

function gui.render_button(this)
    local tx = compute_x(this.x, #this.msg * 6, this.align)
    local bx = compute_x(this.x, const.BUTTON_WIDTH, this.align)
    local fcoef = ease_out_cubic(this.focus, 0, 1, 1)
    local col_coef = 0.7 + fcoef * 0.3
    gui.render_bkgnd(bx, this.y, const.BUTTON_WIDTH, fcoef * 10, col_coef)
    local col = conf.PALETTE[6]
    local fcolr = conf.PALETTE[7].r - col.r
    local fcolg = conf.PALETTE[7].g - col.g
    local fcolb = conf.PALETTE[7].b - col.b
    gfx.print(this.msg, tx, this.y, col.r + fcoef * fcolr, col.g + fcoef * fcolg, col.b + fcoef * fcolb)
end

function gui.update_button(this)
    local tx = compute_x(this.x, const.BUTTON_WIDTH, this.align)
    if inside(g_mouse_x, g_mouse_y, tx - 6, this.y - 6, const.BUTTON_WIDTH + 12, 18) then
        if this.focus < 1.0 then
            this.focus = min(1, this.focus + 1 / 20)
        end
    else
        if this.focus > 0.0 then
            this.focus = max(0, this.focus - 1 / 10)
        end
    end
end

function gui.gen_button(msg, x, y, align)
    return {
        typ = const.E_BUTTON,
        msg = msg,
        x = flr(x),
        y = flr(y),
        align = align,
        focus = 0.0,
        pressed = false,
        col = 5,
        render = gui.render_button,
        update = gui.update_button
    }
end

-- ################################## CONFIGURATION  ##################################
conf = {
    ENGINES = {{
        x = 0,
        y = 19,
        w = 1,
        h = 2,
        class = 0,
        spd = 1,
        man = 1,
        cost = 1
    }, {
        x = 1,
        y = 19,
        w = 1,
        h = 2,
        class = 0,
        spd = 2,
        man = 1,
        cost = 2
    }, {
        x = 2,
        y = 19,
        w = 2,
        h = 2,
        class = 0,
        spd = 1,
        man = 2,
        cost = 2
    }},

    SHIELDS = {{
        x = 0,
        y = 18,
        w = 1,
        h = 1,
        class = 0,
        lif = 1,
        rel = 1,
        cost = 1
    }, {
        x = 1,
        y = 18,
        w = 1,
        h = 1,
        class = 0,
        lif = 1,
        rel = 2,
        cost = 2
    }, {
        x = 2,
        y = 18,
        w = 2,
        h = 1,
        class = 0,
        lif = 2,
        rel = 1,
        cost = 2
    }},

    HULLS = {{
        x = 96,
        y = 0,
        w = 37,
        h = 33,
        class = 0
    }},
    -- NA16 color palette by Nauris
    PALETTE = {col(0, 0, 0), col(140, 143, 174), col(88, 69, 99), col(62, 33, 55), col(154, 99, 72), col(215, 155, 125),
               col(245, 237, 186), col(192, 199, 65), col(100, 125, 52), col(228, 148, 58), col(157, 48, 59),
               col(210, 100, 113), col(112, 55, 127), col(126, 196, 193), col(52, 133, 157), col(23, 67, 75),
               col(31, 14, 28), col(255, 255, 255)},
    COL_WHITE = 18
}

-- ################################## SHIP ##################################

ship = {}
function ship.update_player(this)
end

function ship.render(this)
    gfx.set_sprite_layer(const.LAYER_SHIP_MODELS)
    gfx.blit(this.sx, this.sy, this.sw, this.sh, flr(this.x - this.sw / 2), flr(this.y), 0, 0, false, false, 1, 1, 1)
    gfx.set_sprite_layer(const.LAYER_SPRITES)
end

function ship.generate(hull_num, engine_num, shield_num, x, y)
    gfx.set_active_layer(const.LAYER_SHIP_MODELS)
    local hull = conf.HULLS[hull_num]
    local engine = conf.ENGINES[engine_num]
    local shield = conf.SHIELDS[shield_num]
    local w = hull.w * 6
    local h = hull.h * 6
    gfx.rectangle(0, 0, w, h, 0, 0, 0)
    gfx.blit(engine.x * 6, engine.y * 6, engine.w * 6, engine.h * 6, w / 2 - engine.w * 3, h - engine.h * 6, 0, 0,
        false, false, 1, 1, 1)
    gfx.blit(hull.x, hull.y, hull.w, hull.h, 0, 0, 0, 0, false, false, 1, 1, 1)
    gfx.blit(shield.x * 6, shield.y * 6, shield.w * 6, shield.h * 6, w / 2 - shield.w * 3, h / 2 - shield.h * 3, 0, 0,
        false, false, 1, 1, 1)
    return {
        typ = const.E_SHIP,
        x = x,
        y = y,
        sx = 0,
        sy = 0,
        sw = w,
        sh = h,
        spd = engine.spd,
        man = engine.man,
        lif = shield.lif,
        rel = shield.rel,
        render = ship.render,
        update = ship.update_player
    }
end

function ship.generate_random()
    local h = random(1, #conf.HULLS)
    local e = random(1, #conf.ENGINES)
    local s = random(1, #conf.SHIELDS)
    return ship.generate(h, e, s, gfx.SCREEN_WIDTH / 3, gfx.SCREEN_HEIGHT * 0.8)
end

-- ################################## STARFIELD ##################################

starfield = {}
function starfield.generate()
end

-- ################################## TITLE SCREEN ##################################
title_screen = {}
function title_screen.init()
    gfx.set_active_layer(const.LAYER_BACKGROUND)
    local br = 31 / 255
    local bg = 14 / 255
    local bb = 28 / 255
    local sr = conf.PALETTE[7].r - br
    local sg = conf.PALETTE[7].g - bg
    local sb = conf.PALETTE[7].b - bb
    gfx.clear(br, bg, bb)
    local pr = conf.PALETTE[11].r - br
    local pg = conf.PALETTE[11].g - bg
    local pb = conf.PALETTE[11].b - bb
    local wcoef = 2 / gfx.SCREEN_WIDTH
    local hcoef = 2 / gfx.SCREEN_HEIGHT
    for x = 0, gfx.SCREEN_WIDTH do
        for y = 0, gfx.SCREEN_HEIGHT do
            local dith = (x + y) % 2 == 0 and 2 or 0
            local coef = clamp(fbm2((x + dith) * wcoef, (y + dith) * hcoef), 0, 1)
            coef = flr(coef * 5) / 5
            gfx.rectangle(x, y, 1, 1, br + coef * pr, bg + coef * pg, bb + coef * pb)
        end
    end
    gfx.set_active_layer(const.LAYER_STARS)
    for i = 0, gfx.SCREEN_WIDTH * gfx.SCREEN_HEIGHT // 10 do
        local x = random()
        local y = random()
        if noise2(2 * x + 10, 2 * y + 10) <= random() then
            local coef = random()
            coef = coef ^ 5
            local size = random() * 0.8 + 0.1
            gfx.rectangle(x * gfx.SCREEN_WIDTH, y * gfx.SCREEN_HEIGHT, size, size, br + coef * sr, bg + coef * sg,
                bb + coef * sb)
        end
    end
end

function title_screen.build_ui(g)
    local x = gfx.SCREEN_WIDTH // 2
    table.insert(g, gui.gen_label("Cryon", x, gfx.SCREEN_HEIGHT * (1 - 1 / 1.618), 7, const.ALIGN_CENTER))
    table.insert(g, gui.gen_label("v0.1.0", gfx.SCREEN_WIDTH - 2, gfx.SCREEN_HEIGHT - 8, 12, const.ALIGN_RIGHT))
    local y = gfx.SCREEN_HEIGHT / 1.618
    table.insert(g, gui.gen_button("New game", x, y, const.ALIGN_CENTER))
    y = y + 20
    table.insert(g, gui.gen_button("Options", x, y, const.ALIGN_CENTER))
    y = y + 20
    table.insert(g, gui.gen_button("Quit", x, y, const.ALIGN_CENTER))
end

-- ################################## MAIN LOOP ##################################

function init()
    gfx.set_active_layer(const.LAYER_SPRITES)
    gfx.load_img("sprites", "cryon/cryon_spr.png")
    gfx.set_sprite_layer(const.LAYER_SPRITES)
    gfx.activate_font(const.LAYER_SPRITES, 0, 0, 96, 36, 6, 6,
        " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~")
    gfx.set_scanline(gfx.SCANLINE_HARD)
    g_screen.render = nil
    local seed = flr(elapsed() * 10000000)
    print(string.format("sector seed %d", seed))
    g_screen.sector = sector.generate(seed, planet)
    g_screen.gui = {}
    title_screen.build_ui(g_screen.gui)
    gfx.show_layer(const.LAYER_STARS)
    gfx.set_layer_operation(const.LAYER_STARS, gfx.LAYEROP_ADD)
    gfx.show_layer(const.LAYER_TRAILS)
    gfx.set_layer_operation(const.LAYER_TRAILS, gfx.LAYEROP_ADD)
    gfx.show_layer(const.LAYER_ENTITIES)
    gfx.show_layer(const.LAYER_GUI)
    table.insert(g_screen.sector.entities, ship.generate_random())
    title_screen.init()
    gfx.set_mouse_cursor(const.LAYER_SPRITES, 0, 36, 6, 6)
    gfx.set_active_layer(const.LAYER_BACKGROUND)
end

function update()
    g_mouse_x = inp.mouse_x()
    g_mouse_y = inp.mouse_y()
    g_screen.sector:update()
    for _, g in pairs(g_screen.gui) do
        if g.update ~= nil then
            g:update()
        end
    end
end

function render()
    gfx.set_active_layer(const.LAYER_BACKGROUND)
    g_screen.sector:render()
    gfx.set_active_layer(const.LAYER_GUI)
    gfx.clear(0, 0, 0)
    for _, g in pairs(g_screen.gui) do
        if g.render ~= nil then
            g:render()
        end
    end
    if g_screen.render ~= nil then
        g_screen.render()
    end
    gprint_right("" .. string.format("%d", gfx.fps()) .. " fps", gfx.SCREEN_WIDTH - 1, gfx.SCREEN_HEIGHT - 15,
        conf.COL_WHITE)
end