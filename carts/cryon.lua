-- ################################## UTILITIES ##################################
flr = math.floor
sqrt = math.sqrt
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
        r = r,
        g = g,
        b = b
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
    gfx.print(font, msg, x, y, conf.PALETTE[col].r, conf.PALETTE[col].g, conf.PALETTE[col].b)
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

function wrap(input, max)
    while input >= max do
        input = input - max
    end
    while input < 0 do
        input = input + max
    end
    return input
end
-- ################################## 2D vector toolkit ##################################
function vec(x,y)
    return {x=(x or 0),y=(y or 0)}
end
function vadd(a,b)
    return {x=a.x+b.x,y=a.y+b.y}
end
function vsub(a,b)
    return {x=a.x-b.x,y=a.y-b.y}
end
function vmul(a,b)
    return {x=a.x*b.x,y=a.y*b.y}
end
function vscale(a,s)
    return {x=a.x * s,y=a.y * s}
end
function vlen(a)
    return sqrt(a.x*a.x + a.y*a.y)
end
function vlen2(a)
    return a.x*a.x + a.y*a.y
end
function vnorm(a)
    local l=vlen(a)
    return l == 0 and a or vscale(a, 1/l)
end
function vorth(a)
    return {x=a.y,y=-a.x}
end
function vrot(v, angle, o)
    local x, y = v.x, v.y
    local ox, oy = o.x, o.y
    local ca=cos(angle)
    local sa=sin(angle)
    return vec(ca * (x - ox) - sa * (y - oy) + ox, sa * (x - ox) + ca * (y - oy) + oy)
end

-- ################################## GLOBALS ##################################

g_mouse_x = 0
g_mouse_y = 0
g_screen = {}

-- ################################## CONSTANTS ##################################

const = {
    SCREEN_DIAG=sqrt(gfx.SCREEN_WIDTH*gfx.SCREEN_WIDTH+gfx.SCREEN_HEIGHT*gfx.SCREEN_HEIGHT),
    LIGHT_THRESHOLD1 = 0.5,
    LIGHT_THRESHOLD2 = 0.75,
    LAYER_BACKGROUND = 0,
    LAYER_STARS = 1,
    LAYER_BACKGROUND_OFF = 2,
    LAYER_ENTITIES = 3,
    LAYER_TRAILS = 5,
    LAYER_GUI = 6,
    LAYER_SHIP_MODELS = 7,
    LAYER_SPRITES = 8,
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
    E_FRAME = 7,
    E_IMAGE = 8,
    -- gui events
    EVT_NEWGAME = 1,
    EVT_OPTION = 2,
    EVT_QUIT = 3,
    -- text alignment
    ALIGN_CENTER = 0,
    ALIGN_RIGHT = 1,
    ALIGN_LEFT = 2,
    -- trail conf
    TRAIL_SEG_LEN = 5
}

-- ################################## TRAILS ##################################
Trail = {}

function Trail:new()
    local x = random(0, gfx.SCREEN_WIDTH)
    local y = gfx.SCREEN_HEIGHT * 0.5
    local t = {
        typ = const.E_TRAIL,
        x = x,
        y = y,
        angle = random() * const.PI2,
        vangle = (random() - 0.5) * 0.01,
        speed = random(1, 5) * 0.1,
        seg_length = 0,
        fade_in = 0,
        length = random(5, 15),
        trail = { {
            x = x,
            y = y
        } },
        color = random(1, 18)
    }
    setmetatable(t,self)
    self.__index=self
    -- pre-generate the tail
    while #t.trail ~= t.length do
        t:update()
    end
    t.fade_in = 0
    return t
end

function Trail:update()
    self.seg_length = self.seg_length + self.speed
    self.fade_in = min(1, self.fade_in + 0.004)
    if self.seg_length > const.TRAIL_SEG_LEN then
        table.insert(self.trail, {
            x = self.x,
            y = self.y
        })
        if #self.trail > self.length then
            table.remove(self.trail, 1)
        end
        self.seg_length = 0
        if random(0, 100) < 10 then
            self.vangle = (random() - 0.5) * 0.01
        end
        if self.x < -const.TRAIL_SEG_LEN * self.length or self.x > gfx.SCREEN_WIDTH + const.TRAIL_SEG_LEN * self.length or self.y <
            -const.TRAIL_SEG_LEN * self.length or self.y > gfx.SCREEN_WIDTH + const.TRAIL_SEG_LEN * self.length then
            return true
        end
    end
    self.x = self.x + cos(self.angle) * self.speed
    self.y = self.y + sin(self.angle) * self.speed
    self.angle = self.angle + self.vangle
end

function Trail:render()
    local x = self.x
    local y = self.y
    local col = conf.PALETTE[self.color]
    local seg_part = self.seg_length / const.TRAIL_SEG_LEN
    local fcoef = ease_in_cubic(self.fade_in, 0, 1, 1)
    local col_coef = fcoef
    for i = #self.trail, 1, -1 do
        local p = self.trail[i]
        gfx.line(x, y, p.x, p.y, col.r * col_coef, col.g * col_coef, col.b * col_coef)
        x = p.x
        y = p.y
        col_coef = fcoef * ease_in_cubic(i - 1, 0.0, 1.0, #self.trail - 1 + seg_part)
    end
end

-- ################################## DUST ##################################
Dust = {}

function Dust:new()
    local d={
        parts={}
    }
    for i=1,50 do
        local part=vec(math.random(0,gfx.SCREEN_WIDTH),math.random(0,gfx.SCREEN_WIDTH))
        table.insert(d.parts,part)
    end
    setmetatable(d,self)
    self.__index=self
    return d
end

function Dust:update()
    for i=1,#self.parts do
        local p=self.parts[i]
        if p.s then
            p.old = {x=p.s.x,y=p.s.y}
        end
        if p.x < cam.x - gfx.SCREEN_WIDTH*0.5 then
            p.x = p.x + gfx.SCREEN_WIDTH
            p.old=nil
        elseif p.x > cam.x + gfx.SCREEN_WIDTH*0.5 then
            p.x = p.x - gfx.SCREEN_WIDTH
            p.old=nil
        end
        if p.y < cam.y - gfx.SCREEN_WIDTH*0.5 then
            p.y = p.y + gfx.SCREEN_WIDTH
            p.old=nil
        elseif p.y > cam.y + gfx.SCREEN_WIDTH*0.5 then
            p.y = p.y - gfx.SCREEN_WIDTH
            p.old=nil
        end
        p.s = w2s(p)
        if not p.old then
            p.old = p.s
        end
    end
end

function Dust:render()
    local old=gfx.set_active_layer(const.LAYER_TRAILS)
    for i=1,#self.parts do
        local p=self.parts[i]
        local len=vlen2(vsub(p.s,p.old))
        local rgb=len*255/60
        if rgb>1 then
            gfx.line(p.old.x,p.old.y,p.s.x,p.s.y,rgb,rgb,rgb)
        end
    end
    gfx.set_active_layer(old)
end

-- ################################## PLANETS ##################################
Planet = {}
function Planet:update()
    self.rot = self.rot + 0.0001
    self.tick = (self.tick + 1)%3
    if self.tick == 0 then
        self.sprite = {}
        local cols = { 7, 6, 5, 12, 11, 4 }
        local i = 1
        for y = self.lut.ystart, self.lut.yend do
            for x = self.lut.xstart, self.lut.xend do
                local pix = self.lut.pixel_data[i]
                if pix.black then
                    table.insert(self.sprite, 0)
                else
                    local tex = clamp((fbm2(pix.xsphere * 0.3 + self.rot, pix.ysphere * 0.3 + 20) + 1) * 0.5, 0, 1)
                    local color = tex ^ 0.8 * 6
                    color = clamp(color, 1, 6)
                    local c = conf.PALETTE[cols[flr(color)]]
                    local r = max(1, c.r * pix.light)
                    local g = max(1, c.g * pix.light)
                    local b = max(1, c.b * pix.light)
                    table.insert(self.sprite, gfx.to_rgb24(r, g, b))
                end
                i = i + 1
            end
        end
    end
end

function Planet:compute_lut(light)
    local x0 = self.x - self.radius
    local y0 = self.y - self.radius
    local x1 = self.x + self.radius
    local y1 = self.y + self.radius
    local xstart = max(x0, 0)
    local xend = min(x1, gfx.SCREEN_WIDTH - 1)
    local ystart = max(y0, 0)
    local yend = min(y1, gfx.SCREEN_HEIGHT - 1)
    local rad2 = self.radius * self.radius
    local lightdist = distance(light.x, light.y, self.x, self.y)
    local minlight = max(1, lightdist - self.radius)
    local lightdiv = 1 / (lightdist + self.radius - minlight)
    local data = {}
    for y = ystart, yend do
        local dy = y - self.y
        local dy2 = dy * dy
        for x = xstart, xend do
            local dx = x - self.x
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
    self.lut = {
        xstart = xstart,
        xend = xend,
        ystart = ystart,
        yend = yend,
        rad2 = rad2,
        pixel_data = data
    }
end

function Planet:new(light)
    local radius = random(gfx.SCREEN_HEIGHT // 3, gfx.SCREEN_HEIGHT // 2)
    local p = {
        typ = const.E_PLANET,
        x = random(0, gfx.SCREEN_WIDTH),
        y = random(0, gfx.SCREEN_HEIGHT),
        radius = radius,
        rot = 0,
        tex_width = min(gfx.SCREEN_WIDTH, flr(const.PI2 * radius)),
        tex_height = min(gfx.SCREEN_HEIGHT, radius * 2),
        tick = 0
    }
    setmetatable(p,self)
    self.__index=self
    p:compute_lut(light)
    return p
end

function Planet:render()
    if self.sprite then
        gfx.blit_pixels(self.lut.xstart, self.lut.ystart, self.lut.xend - self.lut.xstart + 1, self.sprite)
    end
end

-- ################################## SECTOR ##################################
Sector = {}
function Sector:update()
    for i = #self.entities, 1, -1 do
        local e = self.entities[i]
        if e.update ~= nil then
            if e:update() ~= nil then
                table.remove(self.entities, i)
                s.trail_count = self.trail_count - 1
                self:spawn_trail()
            end
        end
    end
end

function Sector:render()
    gfx.set_active_layer(const.LAYER_TRAILS)
    gfx.clear()
    gfx.set_active_layer(const.LAYER_ENTITIES)
    gfx.clear()
    for _, e in pairs(self.entities) do
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

function Sector:spawn_trail()
    local start = self.trail_count == 0 and 1 or 0
    local count = random(start, 3 - self.trail_count)
    if count > 0 then
        for _ = 1, count do
            table.insert(self.entities, Trail:new())
            self.trail_count = self.trail_count + 1
        end
    end
end

function Sector:new(seed, planet, light)
    math.randomseed(seed)
    local entities = {}
    local light = {
        x = random(0, gfx.SCREEN_WIDTH),
        y = 0 -- random(0, gfx.SCREEN_HEIGHT)
    }
    table.insert(entities, Planet:new(light))
    local s = {
        entities = entities,
        light = light,
        trail_count = 0
    }
    setmetatable(s,self)
    self.__index = self
    s:spawn_trail()

    return s
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

function gui.render_button_bkgnd(x, y, len, len2, col)
    gfx.blit(6, 36, 6, 18, x - 6, y - 6, col, col, col)
    gfx.blit(12, 36, 6, 18, x, y - 6, col, col, col, nil, len, 0)
    if len2 > 0 then
        gfx.blit(24, 36, 6, 18, x + len, y - 6, col, col, col)
        if len2 > 6 then
            gfx.blit(30, 36, 6, 18, x + len + 6, y - 6, col, col, col)
        end
    end
    gfx.blit(18, 36, 6, 18, round(x + len + len2), y - 6, col, col, col)
end

function gui.gen_frame(x, y, w, h)
    return {
        typ = const.E_FRAME,
        x = x,
        y = y,
        w = w,
        h = h,
        render = gui.render_frame
    }
end

function gui.gen_image(sx, sy, sw, sh, dx, dy)
    return {
        typ = const.E_IMAGE,
        sx = sx,
        sy = sy,
        sw = sw,
        sh = sh,
        dx = dx,
        dy = dy,
        render = gui.render_image
    }
end

function gui.gen_label(msg, x, y, col, align)
    return {
        typ = const.E_LABEL,
        msg = msg,
        x = flr(x),
        y = flr(y),
        col = col,
        align = align,
        render = gui.render_label
    }
end

function gui.render_image(img)
    gfx.blit(img.sx, img.sy, img.sw, img.sh, img.dx, img.dy)
end

function gui.render_button(this)
    local tx = compute_x(this.x, #this.msg * 6, this.align)
    local bx = compute_x(this.x, const.BUTTON_WIDTH, this.align)
    local fcoef = ease_out_cubic(this.focus, 0, 1, 1)
    local col_coef = 180 + fcoef * 75
    gui.render_button_bkgnd(bx, this.y, const.BUTTON_WIDTH, fcoef * 10, col_coef)
    local col = conf.PALETTE[6]
    local fcolr = conf.PALETTE[7].r - col.r
    local fcolg = conf.PALETTE[7].g - col.g
    local fcolb = conf.PALETTE[7].b - col.b
    gfx.print(font, this.msg, tx, this.y + 1, col.r + fcoef * fcolr, col.g + fcoef * fcolg, col.b + fcoef * fcolb)
end

function gui.update_button(this)
    local tx = compute_x(this.x, const.BUTTON_WIDTH, this.align)
    if inside(g_mouse_x, g_mouse_y, tx - 6, this.y - 6, const.BUTTON_WIDTH + 12, 18) then
        if this.focus < 1.0 then
            this.focus = min(1, this.focus + 1 / 20)
        end
        if inp.action1() or inp.mouse_button_pressed(inp.MOUSE_LEFT) then
            return this.evt
        end
    else
        if this.focus > 0.0 then
            this.focus = max(0, this.focus - 1 / 10)
        end
    end
end

function gui.render_frame(f)
    gfx.blit(42, 37, 15, 1, f.x, f.y, 255, 255, 255, nil, f.w, 1)
    gfx.blit(42, 53, 15, 1, f.x, f.y + f.h - 1, 255, 255, 255, nil, f.w, 1)
    gfx.blit(42, 38, 1, 15, f.x, f.y + 1, 255, 255, 255, nil, 1, f.h - 2)
    gfx.blit(54, 38, 3, 15, f.x + f.w - 1, f.y + 1, 255, 255, 255, nil, 3, f.h - 2)
    gfx.blit(43, 38, 11, 15, f.x + 1, f.y + 1, 255, 255, 255, nil, f.w - 2, f.h - 2)
end

function gui.gen_button(msg, x, y, align, evt)
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
        update = gui.update_button,
        evt = evt
    }
end

-- ################################## CONFIGURATION  ##################################
conf = {
    ENGINES = { {
        x = 0,
        y = 19,
        w = 1,
        h = 2,
        class = 0,
        spd = 0.1,
        man = 1,
        cost = 1
    }, {
        x = 1,
        y = 19,
        w = 1,
        h = 2,
        class = 0,
        spd = 0.2,
        man = 1,
        cost = 2
    }, {
        x = 2,
        y = 19,
        w = 2,
        h = 2,
        class = 0,
        spd = 0.15,
        man = 1.4,
        cost = 2
    } },
    SHIELDS = { {
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
    } },
    HULLS = { {
        x = 96,
        y = 0,
        w = 37,
        h = 33,
        class = 0,
        mass = 10
    } },
    SPRITE = {
        x = 0,
        y = 55,
        w = 57,
        h = 30
    },
    -- NA16 color palette by Nauris
    PALETTE = { col(0, 0, 0), col(140, 143, 174), col(88, 69, 99), col(62, 33, 55), col(154, 99, 72), col(215, 155, 125),
        col(245, 237, 186), col(192, 199, 65), col(100, 125, 52), col(228, 148, 58), col(157, 48, 59),
        col(210, 100, 113), col(112, 55, 127), col(126, 196, 193), col(52, 133, 157), col(23, 67, 75),
        col(31, 14, 28), col(255, 255, 255) },
    COL_WHITE = 18
}
-- ################################## CAMERA ##################################
cam = vec()
cam_angle = -const.PI/2
cam_scale = 1

function w2s(p)
    local p = vscale(vsub(p, cam), cam_scale)
    p = vadd(vrot(p, -cam_angle - const.PI*0.5, vec(0, 0)),vec(gfx.SCREEN_WIDTH*0.5,gfx.SCREEN_HEIGHT-30))
    return p
end
Radar={}
function Radar:render()
    local old=gfx.set_active_layer(const.LAYER_TRAILS)
    gfx.blit(280,182,92,42,280,182)
    gfx.set_active_layer(old)
end
-- ################################## SHIP ##################################

Ship = {}
function Ship:update()
    if self.is_player then
        self:set_player_control()
    end

    if self.left > 0.2 then
        self.angle = self.angle - self.left*0.02*self.man
    elseif self.right > 0.2 then
        self.angle = self.angle + self.right*0.02*self.man
    end
    self.dir={x=cos(self.angle),y=sin(self.angle)}
    if self.up > 0.2 then
        self.acc = clamp(self.acc + 0.1,0,self.max_acc)
    elseif self.down > 0.2 then
        self.acc = clamp(self.acc - 0.1,-self.max_acc*0.3,0)
    else
        self.acc=0
    end
    self.spd = vadd(self.spd, vscale(self.dir,self.acc))
    self.spd = vscale(self.spd, 0.98)
    self.pos = vadd(self.pos, self.spd)

    -- camera tracking
    if self.is_player then
        local target_angle = self.angle
        local diff = (target_angle - cam_angle) % const.PI2
        if diff < 0 then
            diff = diff + const.PI2
        end
        local dist = ((2 * diff) % const.PI2) - diff
        cam_angle = cam_angle + dist * 0.05
        --print(string.format("pos %3f,%3f s %1.2f,%1.2f sa %1.2f ta %1.2f ca %1.2f", self.pos.x,self.pos.y,self.spd.x,self.spd.y,self.angle,target_angle,cam_angle))

        local cam_target = self.pos
        cam = vadd(cam, vscale(vsub(cam_target,cam), 0.3))
        -- cam shaking
        local amount=ease_in_cubic(abs(self.acc),0,0.5,self.max_acc)
        local rx=math.random() * amount
        local ry=math.random() * amount
        cam = vadd(cam, vec(rx,ry))
    end
end

function Ship:set_player_control()
    self.up = inp.key(inp.KEY_W) and 1 or inp.up()
    self.down = inp.key(inp.KEY_S) and 1 or inp.down()
    self.left = inp.key(inp.KEY_A) and 1 or inp.left()
    self.right = inp.key(inp.KEY_D) and 1 or inp.right()
end

function Ship:render()
    local old_layer = gfx.set_sprite_layer(const.LAYER_SHIP_MODELS)
    local screen_pos = w2s(self.pos)
    gfx.blit(self.sx, self.sy, self.sw, self.sh,
        screen_pos.x, screen_pos.y,
        255,255,255, cam_angle-self.angle)
    gfx.set_sprite_layer(old_layer)
    if self.is_player then
        local old_act=gfx.set_active_layer(const.LAYER_BACKGROUND)
        local old_spr=gfx.set_sprite_layer(const.LAYER_BACKGROUND_OFF)
        gfx.clear()
        gfx.blit(0,0,const.SCREEN_DIAG,const.SCREEN_DIAG,gfx.SCREEN_WIDTH/2,gfx.SCREEN_HEIGHT/2,255,255,255,cam_angle)
        gfx.set_active_layer(old_act)
        gfx.set_sprite_layer(old_spr)
    end
end

function Ship:new(hull_num, engine_num, shield_num, x, y)
    gfx.set_active_layer(const.LAYER_SHIP_MODELS)
    local hull = conf.HULLS[hull_num]
    local engine = conf.ENGINES[engine_num]
    local shield = conf.SHIELDS[shield_num]
    local w = hull.w
    local h = hull.h
    gfx.rectangle(0, 0, w, h, 0, 0, 0)
    gfx.blit(engine.x, engine.y, engine.w, engine.h, (w - engine.w) / 2, h - engine.h)
    gfx.blit(hull.x, hull.y, hull.w, hull.h, 0, 0)
    gfx.blit(shield.x, shield.y, shield.w, shield.h, (w - shield.w) / 2, (h - shield.h) / 2)
    local s={
        typ = const.E_SHIP,
        pos=vec(x,y),
        angle = -const.PI * 0.5,
        acc=0,
        spd = vec(),
        sx = 0,
        sy = 0,
        sw = w,
        sh = h,
        max_acc = engine.spd,
        man = engine.man,
        lif = shield.lif,
        rel = shield.rel
    }
    setmetatable(s,self)
    self.__index = self
    return s
end

function Ship:generate_random()
    local h = random(1, #conf.HULLS)
    local e = random(1, #conf.ENGINES)
    local s = random(1, #conf.SHIELDS)
    return Ship:new(h, e, s, gfx.SCREEN_WIDTH / 3, gfx.SCREEN_HEIGHT * 0.8)
end

-- ################################## STARFIELD ##################################

starfield = {}
function starfield.new()
end
-- ################################## EVENTS ##################################
Event = {}
function Event:execute(evt)
    if evt == const.EVT_NEWGAME then
        screen_sector:init(0)
    end
end


-- ################################## SCREEN ##################################
Screen = {}

function Screen:new()
    local s={
        entities = {},
        gui = {}
    }
    setmetatable(s,self)
    self.__index = self
    return s
end

function Screen:update()
    for _, e in pairs(self.entities) do
        if e.update ~= nil then
            e:update()
        end
    end
    for _, g in pairs(self.gui) do
        if g.update ~= nil then
            local evt = g:update()
            if evt ~= nil then
                Event:execute(evt)
            end
        end
    end
end

function Screen:render()
    gfx.set_active_layer(const.LAYER_TRAILS)
    gfx.clear()
    gfx.set_active_layer(const.LAYER_ENTITIES)
    gfx.clear()
    for _, e in pairs(self.entities) do
        if e.render ~= nil then
            e:render()
        end
    end
    gfx.set_active_layer(const.LAYER_GUI)
    gfx.clear()
    for _, g in pairs(self.gui) do
        if g.render ~= nil then
            g:render()
        end
    end
end

-- ################################## SECTOR GAME SCREEN ##################################
screen_sector = {}
function screen_sector.init(id)
    g_screen = Screen:new()
    -- gfx.set_active_layer(const.LAYER_BACKGROUND)
    -- gfx.clear()
    gfx.set_active_layer(const.LAYER_ENTITIES)
    gfx.clear()
    local ship=Ship:generate_random()
    ship.x=gfx.SCREEN_WIDTH/2
    ship.y=gfx.SCREEN_HEIGHT-20
    ship.is_player=true
    table.insert(g_screen.entities, Radar)
    table.insert(g_screen.entities, ship)
    table.insert(g_screen.entities,Dust:new())
end

-- ################################## TITLE SCREEN ##################################

screen_title = {}
function screen_title.init()
    gfx.set_active_layer(const.LAYER_BACKGROUND_OFF)
    gfx.set_layer_size(const.LAYER_BACKGROUND_OFF,const.SCREEN_DIAG,const.SCREEN_DIAG)
    local br = 31
    local bg = 14
    local bb = 28
    local sr = conf.PALETTE[7].r - br
    local sg = conf.PALETTE[7].g - bg
    local sb = conf.PALETTE[7].b - bb
    gfx.clear(br, bg, bb)
    local pr = conf.PALETTE[11].r - br
    local pg = conf.PALETTE[11].g - bg
    local pb = conf.PALETTE[11].b - bb
    local wcoef = 2 / gfx.SCREEN_WIDTH
    local hcoef = 2 / gfx.SCREEN_HEIGHT
    -- background nebula
    local cols={}
    for x = 0, const.SCREEN_DIAG do
        table.insert(cols,{})
        local row=cols[#cols]
        for y = 0, const.SCREEN_DIAG do
            local dith = (x + y) % 2 == 0 and 2 or 0
            local coef = clamp(fbm2((x + dith) * wcoef, (y + dith) * hcoef), 0, 1)
            coef = flr(coef * 5) / 5
            local col={r=br + coef * pr,g=bg + coef * pg,b=bb + coef * pb}
            table.insert(row,col)
            gfx.rectangle(x, y, 1, 1, col.r, col.g, col.b)
        end
    end
    -- starfield
    for i = 0, gfx.SCREEN_WIDTH * gfx.SCREEN_HEIGHT // 10 do
        local x = random()
        local y = random()
        if noise2(2 * x + 10, 2 * y + 10) <= random() then
            local coef = random()
            coef = coef ^ 5
            local size = random() * 0.8 + 0.1
            local col={r=br + coef * sr,g=bg + coef * sg,b=bb + coef * sb}
            local px=flr(x * const.SCREEN_DIAG)
            local py=flr(y * const.SCREEN_DIAG)
            local bcol=cols[px+1][py+1]
            col.r = col.r+bcol.r
            col.g = col.g+bcol.g
            col.b = col.b+bcol.b
            gfx.rectangle(px, py, size, size, col.r,col.g,col.b)
        end
    end
    gfx.set_active_layer(const.LAYER_BACKGROUND)
    gfx.set_sprite_layer(const.LAYER_BACKGROUND_OFF)
    gfx.blit(0,0,gfx.SCREEN_WIDTH,gfx.SCREEN_HEIGHT,0,0)
    gfx.set_sprite_layer(const.LAYER_SPRITES)
end

function screen_title.build_ui(g)
    local x = gfx.SCREEN_WIDTH // 2
    table.insert(g,
        gui.gen_image(0, 152, 208, 72, gfx.SCREEN_WIDTH * 0.5 - 104, gfx.SCREEN_HEIGHT * (1 - 1 / 1.618) - 38))
    table.insert(g, gui.gen_label("v0.1.0", gfx.SCREEN_WIDTH - 2, gfx.SCREEN_HEIGHT - 8, 12, const.ALIGN_RIGHT))
    local y = gfx.SCREEN_HEIGHT / 1.618
    table.insert(g, gui.gen_frame(x - 32, y, 60, 50))
    table.insert(g, gui.gen_button("New game", x, y, const.ALIGN_CENTER, const.EVT_NEWGAME))
    y = y + 20
    table.insert(g, gui.gen_button("Options", x, y, const.ALIGN_CENTER, const.EVT_OPTION))
    y = y + 20
    table.insert(g, gui.gen_button("Quit", x, y, const.ALIGN_CENTER, const.EVT_QUIT))
end

-- ################################## MAIN LOOP ##################################

function init()
    gfx.load_img(const.LAYER_SPRITES, "cryon/cryon_spr.png","sprites")
    gfx.set_sprite_layer(const.LAYER_SPRITES)
    font=gfx.set_font(const.LAYER_SPRITES, 0, 0, 96, 36, 6, 6,
        " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~",
        0, 0,
        { 3, 1, 3, 5, 5, 5, 4, 1, 2, 2, 3, 3, 1, 3, 1, 3, 5, 1, 5, 5, 5, 5, 5, 5, 5, 5, 1, 1, 3, 3, 3, 5, 5, 5, 5, 5, 5,
            5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 3, 3, 3, 3, 5, 2, 5, 5, 5, 5, 5, 5, 5, 5,
            1,
            3, 4, 3, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 4, 5, 5, 2, 1, 2, 4 })
    gfx.show_layer(const.LAYER_STARS)
    gfx.set_layer_operation(const.LAYER_STARS, gfx.LAYEROP_ADD)
    gfx.show_layer(const.LAYER_TRAILS)
    gfx.set_layer_operation(const.LAYER_TRAILS, gfx.LAYEROP_ADD)
    gfx.show_layer(const.LAYER_ENTITIES)
    gfx.show_layer(const.LAYER_GUI)
    gfx.set_mouse_cursor(const.LAYER_SPRITES, 0, 36, 6, 6)

    -- g_screen = Screen:new()
    -- local seed = flr(elapsed() * 10000000)
    -- seed=78408
    -- print(string.format("sector seed %d", seed))
    -- table.insert(g_screen.entities, Sector:new(seed, planet))
    -- table.insert(g_screen.entities, Ship:generate_random())
    -- screen_title.build_ui(g_screen.gui)
    screen_title.init()
    screen_sector.init(0)
    gfx.set_active_layer(const.LAYER_BACKGROUND)
end

function update()
    g_mouse_x, g_mouse_y = inp.mouse_pos()
    g_screen:update()
end

function render()
    g_screen:render()
    gprint_right("" .. string.format("%d", gfx.fps()) .. " fps", gfx.SCREEN_WIDTH - 1, 1,
        conf.COL_WHITE)
end
