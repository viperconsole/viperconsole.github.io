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

-- ################################## GLOBALS ##################################

g_mouse_x = 0
g_mouse_y = 0
g_screen = {}

-- ################################## CONSTANTS ##################################

local const = {
    LIGHT_THRESHOLD1 = 0.5,
    LIGHT_THRESHOLD2 = 0.75,

    LAYER_BACKGROUND = 0,
    LAYER_STARS = 1,
    LAYER_ENTITIES = 2,
    LAYER_GUI = 3,
    LAYER_SHIP_MODELS = 4,
    LAYER_PLANET_TEXTURE = 5,
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

    -- text alignment
    ALIGN_CENTER = 0,
    ALIGN_RIGHT = 1,
    ALIGN_LEFT = 2
}

-- ################################## PLANETS ##################################

local planet = {}

function planet_update(this)
    this.rot = this.rot + 0.0001
end

function compute_spans(p)
end

function planet.generate(PALETTE)
    local radius = random(gfx.SCREEN_HEIGHT // 3, gfx.SCREEN_HEIGHT // 2)
    t = elapsed()
    local p = {
        typ = const.E_PLANET,
        x = random(0, gfx.SCREEN_WIDTH),
        y = random(0, gfx.SCREEN_HEIGHT),
        radius = radius,
        rot = 0,
        tex_width = min(gfx.SCREEN_WIDTH, flr(const.PI2 * radius)),
        tex_height = min(gfx.SCREEN_HEIGHT, radius * 2)
    }
    compute_spans(p)
    print("compute spans: " .. (elapsed() - t) .. "s")
    p.render = planet_render
    p.update = planet_update
    return p
end

function distance(x0, y0, x1, y1)
    return sqrt((x1 - x0) * (x1 - x0) + (y1 - y0) * (y1 - y0))
end

function smoothstep(a, b, x)
    local t = clamp((x - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)
end

function planet_render(this)
    local x0 = this.x - this.radius
    local y0 = this.y - this.radius
    local x1 = this.x + this.radius
    local y1 = this.y + this.radius
    local xstart = max(x0, 0)
    local xend = min(x1, gfx.SCREEN_WIDTH - 1)
    local ystart = max(y0, 0)
    local yend = min(y1, gfx.SCREEN_HEIGHT - 1)
    local rad2 = this.radius * this.radius
    local sprite = {}
    local cols = {7, 6, 5, 12, 11, 4}
    local light = {
        x = 0,
        y = 0
    } -- TODO
    local lightdist = distance(light.x, light.y, this.x, this.y)
    local minlight = max(1, lightdist - this.radius)
    local lightdiv = 1 / (lightdist + this.radius - minlight)
    for y = ystart, yend do
        local dy = y - this.y
        local dy2 = dy * dy
        for x = xstart, xend do
            local dx = x - this.x
            local r2 = dy2 + dx * dx
            if r2 < rad2 then
                local dith = (x + y) % 2 == 0 and 1 or 0
                local z = max(1, sqrt(rad2 - r2 * 0.9))
                local xsphere = (dx + dith) / z
                local ysphere = (dy + dith) / z
                local d_light = 1 - (distance(x + dith, y + dith, light.x, light.y) - minlight) * lightdiv
                -- d_light = smoothstep(-0.3, 1.2, 1 - d_light)
                local tex = clamp((fbm2(xsphere + this.rot, ysphere + 20) + 1) * 0.5, 0, 1)
                local color = tex ^ 0.8 * 6
                color = clamp(color, 1, 6)
                d_light = clamp(flr(d_light * 2) / 2 + 0.5, 0, 1)
                local c = PALETTE[cols[flr(color)]]
                -- local c = PALETTE[cols[clamp(flr(d_light * 10.0), 1, 6)]]
                local r = max(1 / 255, c.r * d_light)
                local g = max(1 / 255, c.g * d_light)
                local b = max(1 / 255, c.b * d_light)
                table.insert(sprite, gfx.to_rgb24(r, g, b))
            else
                table.insert(sprite, 0)
            end
        end
    end
    gfx.blit_pixels(xstart, ystart, xend - xstart + 1, sprite)
end

-- ################################## SECTOR ##################################

local sector = {}

local function update_sector(s)
    for _, e in pairs(s.entities) do
        if e.update ~= nil then
            e:update()
        end
    end
end

local function render_sector(s)
    gfx.set_active_layer(const.LAYER_ENTITIES)
    for _, e in pairs(s.entities) do
        e:render()
    end
end

function sector.generate(seed, PALETTE, planet)
    math.randomseed(seed)
    local entities = {}
    table.insert(entities, planet.generate(PALETTE))
    return {
        entities = entities,
        update = update_sector,
        render = render_sector
    }
end

-- ################################## GUI ##################################

local gui = {}

function render_label(lab)
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

function render_bkgnd(x, y, len, len2, col)
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
        render = render_label,
        update = no_update
    }
end

function render_button(this)
    local tx = compute_x(this.x, #this.msg * 6, this.align)
    local bx = compute_x(this.x, const.BUTTON_WIDTH, this.align)
    local fcoef = ease_out_cubic(this.focus, 0, 1, 1)
    local col_coef = 0.7 + fcoef * 0.3
    render_bkgnd(bx, this.y, const.BUTTON_WIDTH, fcoef * 10, col_coef)
    local col = PALETTE[6]
    local fcolr = PALETTE[7].r - col.r
    local fcolg = PALETTE[7].g - col.g
    local fcolb = PALETTE[7].b - col.b
    gfx.print(this.msg, tx, this.y, col.r + fcoef * fcolr, col.g + fcoef * fcolg, col.b + fcoef * fcolb)
end

function update_button(this)
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
        render = render_button,
        update = update_button
    }
end

-- ################################## CONFIGURATION  ##################################

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
}}

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
}}

HULLS = {{
    x = 96,
    y = 0,
    w = 37,
    h = 33,
    class = 0
}}

-- NA16 color palette by Nauris
PALETTE = {col(0, 0, 0), col(140, 143, 174), col(88, 69, 99), col(62, 33, 55), col(154, 99, 72), col(215, 155, 125),
           col(245, 237, 186), col(192, 199, 65), col(100, 125, 52), col(228, 148, 58), col(157, 48, 59),
           col(210, 100, 113), col(112, 55, 127), col(126, 196, 193), col(52, 133, 157), col(23, 67, 75),
           col(31, 14, 28), col(255, 255, 255)}

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
    gfx.print(msg, x, y, PALETTE[col].r, PALETTE[col].g, PALETTE[col].b)
end

function gprint_center(msg, x, y, col)
    gprint(msg, flr(x - #msg * 3), y, col)
end

function gprint_right(msg, x, y, col)
    gprint(msg, flr(x - #msg * 6), y, col)
end

function clerp(coef, c1, c2)
    local p1 = PALETTE[c1]
    local p2 = PALETTE[c2]
    return {
        r = p1.r + coef * (p2.r - p1.r),
        g = p1.g + coef * (p2.g - p1.g),
        b = p1.b + coef * (p2.b - p1.b)
    }
end

function inside(px, py, x, y, w, h)
    return px >= x and py >= y and px < x + w and py < y + h
end

function no_update(this)
end

function no_render(this)
end

-- ################################## SHIP ##################################
function update_player_ship(this)
end

function render_ship(this)
    gfx.set_sprite_layer(const.LAYER_SHIP_MODELS)
    gfx.blit(this.sx, this.sy, this.sw, this.sh, flr(this.x - this.sw / 2), flr(this.y), 0, 0, false, false, 1, 1, 1)
    gfx.set_sprite_layer(const.LAYER_SPRITES)
end

function gen_ship(hull_num, engine_num, shield_num, x, y)
    gfx.set_active_layer(const.LAYER_SHIP_MODELS)
    local hull = HULLS[hull_num]
    local engine = ENGINES[engine_num]
    local shield = SHIELDS[shield_num]
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
        render = render_ship,
        update = update_player_ship
    }
end

function gen_random_ship()
    local h = random(1, #HULLS)
    local e = random(1, #ENGINES)
    local s = random(1, #SHIELDS)
    return gen_ship(h, e, s, gfx.SCREEN_WIDTH / 3, gfx.SCREEN_HEIGHT * 0.8)
end

-- ################################## STARFIELD ##################################

function gen_starfield()
end

-- ################################## TITLE SCREEN ##################################

function init_title()
    gfx.set_active_layer(const.LAYER_BACKGROUND)
    local br = 31 / 255
    local bg = 14 / 255
    local bb = 28 / 255
    local sr = PALETTE[7].r - br
    local sg = PALETTE[7].g - bg
    local sb = PALETTE[7].b - bb
    gfx.clear(br, bg, bb)
    local pr = PALETTE[11].r - br
    local pg = PALETTE[11].g - bg
    local pb = PALETTE[11].b - bb
    local wcoef = 2 / gfx.SCREEN_WIDTH
    local hcoef = 2 / gfx.SCREEN_HEIGHT
    for x = 0, gfx.SCREEN_WIDTH // 2 do
        for y = 0, gfx.SCREEN_HEIGHT // 2 do
            local coef = clamp(fbm2(x * wcoef, y * hcoef), 0, 1)
            gfx.rectangle(x * 2, y * 2, 2, 2, br + coef * pr, bg + coef * pg, bb + coef * pb)
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

function build_title_ui(g)
    local x = gfx.SCREEN_WIDTH // 2
    table.insert(g, gui.gen_label("Cryon", x, gfx.SCREEN_HEIGHT * (1 - 1 / 1.618), 7, const.ALIGN_CENTER))
    table.insert(g, gui.gen_label("0.1.0", gfx.SCREEN_WIDTH - 2, gfx.SCREEN_HEIGHT - 8, 12, const.ALIGN_RIGHT))
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
    g_screen.render = no_render
    local seed = flr(elapsed() * 10000000)
    print(string.format("sector seed %d", seed))
    g_screen.sector = sector.generate(seed, PALETTE, planet)
    g_screen.gui = {}
    build_title_ui(g_screen.gui)
    gfx.show_layer(const.LAYER_STARS)
    gfx.set_layer_operation(const.LAYER_STARS, gfx.LAYEROP_ADD)
    gfx.show_layer(const.LAYER_ENTITIES)
    gfx.show_layer(const.LAYER_GUI)
    table.insert(g_screen.sector.entities, gen_random_ship())
    init_title()
    gfx.set_mouse_cursor(const.LAYER_SPRITES, 0, 36, 6, 6)
    gfx.set_active_layer(const.LAYER_BACKGROUND)
end

function update()
    g_mouse_x = inp.mouse_x()
    g_mouse_y = inp.mouse_y()
    g_screen.sector:update()
    for _, g in pairs(g_screen.gui) do
        g:update()
    end
end

function render()
    gfx.set_active_layer(const.LAYER_BACKGROUND)
    g_screen.sector:render()
    gfx.set_active_layer(const.LAYER_GUI)
    gfx.clear(0, 0, 0)
    for _, g in pairs(g_screen.gui) do
        g:render()
    end
    g_screen.render()
    gfx.print("" .. gfx.fps() .. " fps", 0, gfx.SCREEN_HEIGHT - 8, 1, 1, 1)
end
