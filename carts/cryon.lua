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
function planet_render(this)
    gfx.set_sprite_layer(const.LAYER_PLANET_TEXTURE)
    local tex_size = this.tex_width
    for _, span in pairs(this.spans) do
        local tx = span.tx + this.rot
        local tlen = span.tlen
        local sx = span.x
        local slen = span.len
        if tx >= tex_size then
            tx = tx - tex_size
        elseif tx + tlen > tex_size then
            local len1 = tex_size - 1 - tx
            local slen1 = round(slen * len1 / tlen)
            gfx.blit(tx, span.ty, len1, 1, sx, span.y, slen1, 1, false, false, 1, 1, 1)
            tx = 0
            slen = slen - slen1
            sx = sx + slen1
            tlen = tlen - len1
        end
        gfx.blit(tx, span.ty, tlen, 1, sx, span.y, slen, 1, false, false, 1, 1, 1)
    end
    -- display planet texture
    -- gfx.blit(0,0,tex_size,tex_size, gfx.SCREEN_WIDTH-tex_size, gfx.SCREEN_HEIGHT-this.tex_height,0,0,false,false,1,1,1)

    gfx.set_sprite_layer(const.LAYER_SPRITES)
end

function planet_update(this)
    this.rot = (this.rot + 0.01) % (this.tex_width)
end

function compute_spans(p)
    local i = 0
    local rad = p.radius
    local starty = round(max(0, p.y - rad))
    local endy = round(min(gfx.SCREEN_HEIGHT - 1, p.y + rad))
    local inv_rad = 1.0 / rad
    local inv_pi = 1.0 / const.PI
    local tex_size_x = p.tex_width
    local tex_size_y = p.tex_height
    p.spans = {}
    for y = starty, endy do
        local s = (y - p.y) * inv_rad
        local v = clamp(0.5 + asin(s) * inv_pi, 0, 1)
        local square_sin = s * s
        local cos2d = sqrt(1 - square_sin)
        local span_half_len = cos2d * rad
        local startx = round(max(0, p.x - span_half_len))
        local endx = round(min(gfx.SCREEN_WIDTH - 1, startx + 2 * span_half_len))
        local start_cos = (p.x - startx) * inv_rad
        local start_z = sqrt(max(0, 1 - square_sin - start_cos * start_cos))
        local start_u = atan2(start_z, start_cos) * inv_pi
        local span_start = startx
        for _, x in pairs({0.05, 0.25, 0.75, 0.95, 1.0}) do
            local curx = round(min(endx, x * span_half_len * 2 - span_half_len + p.x))
            if curx > span_start and curx <= endx then
                local end_cos = (p.x - curx) * inv_rad
                local end_z = sqrt(max(0, 1 - square_sin - end_cos * end_cos))
                local end_u = atan2(end_z, end_cos) * inv_pi
                local span = {
                    x = span_start,
                    y = y,
                    len = curx - span_start + 1,
                    tx = round(start_u * tex_size_x / 2),
                    ty = round(v * tex_size_y),
                    tlen = round(abs(end_u - start_u) * tex_size_x / 2)
                }
                table.insert(p.spans, span)
                span_start = curx
                start_u = end_u
                if span_start > endx then
                    break
                end
            end
        end
    end
end

function planet.generate(PALETTE)
    local px = random(0, gfx.SCREEN_WIDTH)
    local py = random(0, gfx.SCREEN_HEIGHT)
    local radius = random(gfx.SCREEN_HEIGHT // 3, gfx.SCREEN_HEIGHT // 2)
    local cols = {7, 6, 5, 12, 11, 4}
    local numcol = #cols - 1
    local tex_width = min(gfx.SCREEN_WIDTH, flr(const.PI2 * radius))
    local tex_height = min(gfx.SCREEN_HEIGHT, radius * 2)
    gfx.set_active_layer(const.LAYER_PLANET_TEXTURE)
    local tex = {}
    local mn = 1000
    local mx = -1000
    -- generate planet texture
    for y = 0, tex_height - 1 do
        local a1 = asin(1 - y / tex_height * 2)
        local yrad = abs(cos(a1))
        local fy = 3 * y / tex_height
        for x = 0, tex_width - 1 do
            local angle = x * const.PI2 / tex_width
            local fx = fbm3((cos(angle) + 1) * yrad, (sin(angle) + 1) * yrad, fy)
            table.insert(tex, fx)
            mn = min(fx, mn)
            mx = max(fx, mx)
        end
    end
    local i = 1
    local norm_coef = (numcol + 1) / (mx - mn)
    -- render texture on layer LAYER_PLANET_TEXTURE
    for y = 0, tex_height - 1 do
        for x = 0, tex_width - 1 do
            local coef = clamp((tex[i] - mn) * norm_coef, 0, numcol)
            local rcoef = coef - flr(coef)
            local col = rcoef > 0 and clerp(rcoef, cols[flr(coef + 1)], cols[flr(coef + 2)]) or
                            PALETTE[cols[flr(coef + 1)]]
            gfx.rectangle(x, y, 1, 1, col.r, col.g, col.b)
            i = i + 1
        end
    end
    local p = {
        typ = const.E_PLANET,
        x = px,
        y = py,
        radius = radius,
        rot = 0,
        tex_width = tex_width,
        tex_height = tex_height
    }
    compute_spans(p)
    gfx.set_active_layer(const.LAYER_BACKGROUND)
    p.render = planet_render
    p.update = planet_update
    return p
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
    print("render bkgnd");
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
    table.insert(g_screen.sector.entities, gen_random_ship())
    g_screen.gui = {}
    build_title_ui(g_screen.gui)
    init_title()
    gfx.show_layer(const.LAYER_STARS)
    gfx.set_layer_operation(const.LAYER_STARS, gfx.LAYEROP_ADD)
    gfx.show_layer(const.LAYER_ENTITIES)
    gfx.show_layer(const.LAYER_GUI)
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
