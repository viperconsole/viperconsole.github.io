-- inspired by pico racer 2048
-- by impbox software
local AIR_RESISTANCE <const> = 0.036
local BRAKE_COEF <const> = 0.5
local CAR_BASE_MASS <const> = 505
local COLLISION_COEF <const> = 1.5/3
local ASPIRATION_COEF <const> = 1.5
-- impact of tyre wear on maxacc
local TYRE_WEAR_ACC_IMPACT <const> = 0.03
-- impact of tyre wear on BRAKE_COEF
local TYRE_WEAR_BRAKE_IMPACT <const> = 0.3
-- impact of tyre wear on steer
local TYRE_WEAR_STEER_IMPACT <const> = 0.002
-- wear level where performances start to decrease
local TYRE_WEAR_THRESHOLD <const> = 0.5
-- 1993 regulation : max fuel 220 liters = 146kg. average consumption 3.5liter/km = 2.3kg/km
local FUEL_MASS_PER_KM <const> = 2.3
local TEAM_PERF_COEF <const> = 1.0
local X_OFFSET <const> = 130
local MINIMAP_START <const> = -10
local MINIMAP_END <const> = 20
local SMOKE_LIFE <const> = 80
local DATA_PER_SEGMENT <const> = 8
local DATA_PER_SECTION <const> = 7
local LAP_COUNTS <const> = { 1, 3, 5, 15 }
local LAYER_SMOKE <const> = 3
local LAYER_SHADOW <const> = 4
local LAYER_CARS <const> = 5
local LAYER_SHADOW2 <const> = 6
local LAYER_TOP <const> = 7
local OBJ_TRIBUNE <const> = 1
local OBJ_TRIBUNE2 <const> = 2
local OBJ_TREE <const> = 3
local OBJ_BRIDGE <const> = 4
local OBJ_BRIDGE2 <const> = 5
local OBJ_PIT <const> = 6
local OBJ_PIT_LINE <const> = 7
local OBJ_PIT_LINE_START <const> = 8
local OBJ_PIT_LINE_END <const> = 9
local OBJ_PIT_ENTRY1 <const> = 10
local OBJ_PIT_ENTRY2 <const> = 11
local OBJ_PIT_ENTRY3 <const> = 12
local OBJ_PIT_EXIT1 <const> = 13
local OBJ_PIT_EXIT2 <const> = 14
local OBJ_PIT_EXIT3 <const> = 15
local OBJ_COUNT <const> = 16
local SHADOW_DELTA <const> = { x = -10, y = 10 }
local MINIMAP_RACE_OFFSET <const> = { x = 340, y = 120 }
local MINIMAP_EDITOR_OFFSET <const> = { x = 340, y = 200 }
local TYRE_TYPE <const> = { "soft", "medium", "hard", "inter", "wet" }
-- how many segments to heat the tyres ?
local TYRE_HEAT <const> = { 100, 175, 250, 50, 50}
-- how many segment before the tyre might get flat
local TYRE_LIFE <const> = { 250*10, 250*15, 250*20, 250*20, 250*25}
-- base impact on speed,acceleration,steering
local TYRE_PERF <const> = { 1.1, 1.0, 0.9, 0.8, 0.7}
local TYRE_COL <const> = { 8, 10, 7, 11, 28 }
local CARS <const> = { {
    name = "Easy",
    maxacc = 0.2,
    steer = 0.0225,
    accsqr = 0.05,
    player_adv = 0.04
}, {
    name = "Medium",
    maxacc = 0.2,
    steer = 0.0185,
    accsqr = 0.05,
    player_adv = 0.02
}, {
    name = "Hard",
    maxacc = 0.2,
    steer = 0.0165,
    accsqr = 0.05,
    player_adv = 0
} }
local PANEL_CAR_STATUS <const> = 1
panels={nil,PANEL_CAR_STATUS}
panel=0
-- car tracked by camera. nil = player
tracked=nil
cam_car=nil
minimap_offset = MINIMAP_RACE_OFFSET
cam_pos = {
    x = 0,
    y = 0
}
camera_angle = 0
camera_scale = 1
best_seg_times = {}
best_lap_time = nil
best_lap_driver = nil
mlb_pressed = false
function camera(x, y)
    cam_pos.x = x or 0
    cam_pos.y = y or 0
end

function inp_brake()
    -- controller X or keyboard C
    return inp.action2()
end

function inp_accel()
    -- controller A or keyboard X
    return inp.action1()
end

function inp_boost()
    return inp.pad_button(1, inp.XBOX360_RB) or inp.key(inp.KEY_UP)
end

function inp_menu_pressed()
    return inp.pad_button_pressed(1, inp.XBOX360_SELECT) or inp.key_pressed(inp.KEY_ESCAPE)
end

col = function(r, g, b)
    return {
        r = r,
        g = g,
        b = b
    }
end
-- pico8 palette
local PAL <const> = {
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
    col(11, 51, 16),
    col(17, 29, 53),
    col(66, 33, 54),
    col(18, 83, 89),
    col(116, 47, 41),
    col(73, 51, 59),
    col(162, 136, 121),
    col(243, 239, 125),
    col(190, 18, 80),
    col(255, 108, 36),
    col(168, 231, 46),
    col(9, 181, 67),
    col(6, 90, 181),
    col(117, 70, 101),
    col(255, 110, 89),
    col(255, 157, 129),
    col(92, 84, 76),
    col(255,255,255)
}
local SHADOW_COL <const> = 22

function cls()
    local c = PAL[21]
    gfx.set_active_layer(LAYER_TOP)
    gfx.clear()
    gfx.set_active_layer(LAYER_SHADOW)
    gfx.clear()
    gfx.set_active_layer(LAYER_SHADOW2)
    gfx.clear()
    gfx.set_active_layer(LAYER_CARS)
    gfx.clear()
    gfx.set_active_layer(0)
    gfx.clear(c.r, c.g, c.b)
end

cos = function(v)
    return math.cos(from_pico_angle(v))
end
sin = function(v)
    return math.sin(from_pico_angle(v))
end
from_pico_angle = function(v)
    return v < 0.5 and -v * 2 * math.pi or (1 - v) * 2 * math.pi
end
to_pico_angle = function(a)
    local ra = a / math.pi
    local picoa = ra < 0 and -ra / 2 or 1 - ra / 2
    return picoa
end
rnd = function(n)
    return math.random() * n
end
abs = math.abs
sqrt = math.sqrt
flr = math.floor
ceil = math.ceil
min = math.min
max = math.max

function line(x1, y1, x2, y2, col)
    local c = flr(col)
    local p1 = cam2screen(vec(x1, y1))
    local p2 = cam2screen(vec(x2, y2))
    gfx.line(p1.x, p1.y, p2.x, p2.y, PAL[c].r, PAL[c].g, PAL[c].b)
end

function world2minimap(p)
    p = vecsub(p, cam_pos)
    p = rotate_point(p, -camera_angle + 0.25, vec(0, 0))
    p = scalev(p, 0.05)
    p = vecadd(p, minimap_offset)
    return p
end

function minimap_line(p1, p2, c)
    p1 = world2minimap(p1)
    p2 = world2minimap(p2)
    c = flr(c)
    gfx.line(p1.x, p1.y, p2.x, p2.y, PAL[c].r, PAL[c].g, PAL[c].b)
end

function minimap_disk(p, c)
    p = world2minimap(p)
    c = flr(c)
    gfx.disk(p.x+0.5, p.y, 2, nil, PAL[c].r, PAL[c].g, PAL[c].b)
end

function cam2screen(p)
    p = scalev(vecsub(p, cam_pos), camera_scale)
    p = vecadd(rotate_point(p, -camera_angle + 0.25, vec(0, 0)), vec(64, 64))
    return {
        x = p.x * 224 / 128 + X_OFFSET,
        y = p.y * 224 / 128
    }
end

function draw_tyres(p1, p2, p3, p4, col)
    local x = scalev(normalize(vecsub(p3, p1)), 1)
    local y = scalev(normalize(vecsub(p2, p1)), 0.7)
    local p1px = vecadd(p1, x)
    local p1mx = vecsub(p1, x)
    quadfill(vecsub(p1mx, y), vecadd(p1mx, y), vecsub(p1px, y), vecadd(p1px, y), col)
    local p2px = vecadd(p2, x)
    local p2mx = vecsub(p2, x)
    quadfill(vecsub(p2mx, y), vecadd(p2mx, y), vecsub(p2px, y), vecadd(p2px, y), col)
    local p3px = vecadd(p3, x)
    local p3mx = vecsub(p3, x)
    quadfill(vecsub(p3mx, y), vecadd(p3mx, y), vecsub(p3px, y), vecadd(p3px, y), col)
    local p4px = vecadd(p4, x)
    local p4mx = vecsub(p4, x)
    quadfill(vecsub(p4mx, y), vecadd(p4mx, y), vecsub(p4px, y), vecadd(p4px, y), col)
end

function trifill(p1, p2, p3, pal, transf)
    local col = PAL[flr(pal)]
    if transf == nil or transf == true then
        p1 = cam2screen(p1)
        p2 = cam2screen(p2)
        p3 = cam2screen(p3)
    end
    gfx.triangle(p1.x, p1.y, p2.x, p2.y, p3.x, p3.y, col.r, col.g, col.b)
end

function quadfill(p1, p2, p3, p4, pal, transf)
    trifill(p1, p2, p3, pal, transf)
    trifill(p2, p3, p4, pal, transf)
end

function circfill(x, y, r, pal)
    local col = PAL[flr(pal)]
    local p = cam2screen(vec(x, y))
    gfx.disk(p.x, p.y, r * 224 / 128, nil, col.r, col.g, col.b)
end

function rectfill(x0, y0, x1, y1, pal)
    local col = PAL[flr(pal)]
    gfx.rectangle(x0, y0, x1 - x0 + 1, y1 - y0 + 1, col.r, col.g, col.b)
end

function rect(x0, y0, w, h, pal)
    local col = PAL[flr(pal)]
    gfx.line(x0, y0, x0 + w - 1, y0, col.r, col.g, col.b)
    gfx.line(x0, y0 + h - 1, x0 + w - 1, y0 + h - 1, col.r, col.g, col.b)
    gfx.line(x0 + w - 1, y0, x0 + w - 1, y0 + h - 1, col.r, col.g, col.b)
    gfx.line(x0, y0, x0, y0 + h - 1, col.r, col.g, col.b)
end

function mid(x, y, z)
    if (x <= y and y <= z) or (z <= y and y <= x) then
        return y
    elseif (y <= x and x <= z) or (z <= x and x <= y) then
        return x
    else
        return z
    end
end

function gblit(x, y, w, h, p, col, dir)
    local p = cam2screen(p)
    local c=PAL[col]
    gfx.blit(x, y, w, h, p.x, p.y, c.r, c.g, c.b, from_pico_angle(camera_angle - dir), w * camera_scale, h * camera_scale)
end

function gblit_col(x, y, w, h, p, col, dir)
    local p = cam2screen(p)
    local c=PAL[col]
    gfx.blit_col(x, y, w, h, p.x, p.y, c.r, c.g, c.b, from_pico_angle(camera_angle - dir), w * camera_scale, h * camera_scale)
end

function gprint(msg, px, py, col)
    local c = math.floor(col)
    gfx.print(gfx.FONT_8X8, msg, math.floor(px), math.floor(py), PAL[c].r, PAL[c].g, PAL[c].b)
end

function sfx(n)
    snd.play_pattern(n)
end

local SFX_BOOST_COOLDOWN <const> = 33
local SFX_BOOSTER <const> = 41

local BOOST_WARNING_THRESH <const> = 30
local BOOST_CRITICAL_THRESH <const> = 15


local TEAMS <const> = {
    {
        name="Williamson",
        color = 1,
        color2 = 10,
        perf = 5,
        short_name = "WIL",
        pit=1
    },
    {
        name="MacLoran",
        color = 7,
        color2 = 8,
        perf = 4,
        short_name = "MCL",
        pit=2
    },
    {
        name = "Benettson",
        color = 11,
        color2 = 26,
        perf = 4,
        short_name = "BEN",
        pit=3
    },
    {
        name = "Ferrero",
        color = 8,
        color2 = 24,
        perf = 3,
        short_name = "FER",
        pit=4
    },
    {
        name="Leger",
        color = 28,
        color2 = 7,
        perf = 2,
        short_name = "LEG",
        pit=5
    },
    {
        name="Lotusi",
        color = 5,
        color2 = 7,
        perf = 0,
        short_name = "LOT",
        pit=6
    },
    {
        name = "Soober",
        color = 16,
        color2 = 16,
        perf = 0,
        short_name = "SOO",
        pit=7
    },
    {
        name="Jardon",
        color = 29,
        color2 = 8,
        perf = 0,
        short_name = "JAR",
        pit=8
    }
}

function find_team_id(name)
    for i = 1,#TEAMS do
        if TEAMS[i].name==name then
            return i
        end
    end
end

local DRIVERS <const> = { {
    name = "Anton Sanna",
    short_name = "ASA",
    skill = 8,
    team = find_team_id("MacLoran"),
    helmet = 10
}, {
    name = "Alan Presto",
    short_name = "APR",
    skill = 7,
    team = find_team_id("Williamson"),
    helmet = 11
}, {
    name = "Nygel Mansale",
    short_name = "NMA",
    skill = 5,
    team = find_team_id("Jardon"),
    helmet = 12
}, {
    name = "Gege Leyton",
    short_name = "GLE",
    skill = 6,
    team = find_team_id("Soober"),
    helmet = 13
}, {
    name = "Mike Shoemaker",
    short_name = "MSH",
    skill = 6,
    team = find_team_id("Benettson"),
    helmet = 14
}, {
    name = "Pierre Lami",
    short_name = "PLA",
    skill = 5,
    team = find_team_id("Jardon"),
    helmet = 15
}, {
    name = "Richard Petrez",
    short_name = "RPE",
    skill = 5,
    team = find_team_id("Benettson"),
    helmet = 22
}, {
    name = "John HeartBerth",
    short_name = "JHE",
    skill = 4,
    team = find_team_id("Lotusi"),
    helmet = 23
}, {
    name = "Devon Hell",
    short_name = "DHE",
    skill = 6,
    team = find_team_id("Williamson"),
    helmet = 24
}, {
    name = "Martin Blundle",
    short_name = "MBL",
    skill = 5,
    team = find_team_id("Leger"),
    helmet = 25
}, {
    name = "Gerard Bergler",
    short_name = "GBE",
    skill = 5,
    team = find_team_id("Ferrero"),
    helmet = 26
}, {
    name = "Mike Andrett",
    short_name = "MAN",
    skill = 4,
    team = find_team_id("MacLoran"),
    helmet = 27
}, {
    name = "Carl Wandling",
    short_name = "CWA",
    skill = 4,
    team = find_team_id("Soober"),
    helmet = 28
}, {
    name = "Marco Blundelli",
    short_name = "MBL",
    skill = 4,
    team = find_team_id("Leger"),
    helmet = 29
}, {
    name = "Mickael Hakinon",
    short_name = "MHA",
    skill = 5,
    team = find_team_id("Lotusi"),
    helmet = 30
} }

local DT <const> = 0.033333 -- 1/30th of a second

particles = {}
smokes = {}
mapsize = 250
function create_spark(segment, pos, speed, grass)
    for i=1,#particles do
        local p=particles[i]
        if not p.enabled then
            p.x = pos.x
            p.y = pos.y
            p.xv = -speed.x + (rnd(2) - 1) / 2
            p.yv = -speed.y + (rnd(2) - 1) / 2
            p.ttl = 30
            p.seg = segment
            p.enabled = true
            p.grass = grass
            return
        end
    end
    local p = {
        x = pos.x,
        y = pos.y,
        xv = -speed.x + (rnd(2) - 1) / 2,
        yv = -speed.y + (rnd(2) - 1) / 2,
        ttl = 30,
        seg = segment,
        grass = grass
    }
    function p:draw()
        line(self.x, self.y, self.x - self.xv, self.y - self.yv,
            self.grass and 3 or (self.ttl > 20 and 10 or (self.ttl > 10 and 9 or 8)))
    end

    table.insert(particles, p)
end

function create_smoke(segment, pos, speed, color)
    for i=1,#smokes do
        local s=smokes[i]
        if not s.enabled then
            s.x = pos.x
            s.y = pos.y
            s.xv = speed.x * 0.3 + (rnd(2) - 1) / 2
            s.yv = speed.y * 0.3 + (rnd(2) - 1) / 2
            s.r = math.random(2, 4)
            s.seg = segment
            s.enabled = true
            s.ttl = SMOKE_LIFE
            s.col = color
            return
        end
    end
    local p = {
        x = pos.x,
        y = pos.y,
        xv = speed.x * 0.3 + (rnd(2) - 1) / 2,
        yv = speed.y * 0.3 + (rnd(2) - 1) / 2,
        ttl = SMOKE_LIFE,
        r = math.random(2, 4),
        seg = segment,
        enabled = true,
        col = color
    }
    function p:draw()
        local p = cam2screen(vec(self.x, self.y))
        local rgb = self.ttl / SMOKE_LIFE
        local col = PAL[self.col]
        gfx.disk(p.x, p.y, self.r * (2 - rgb), nil, col.r * rgb, col.g * rgb, col.b * rgb)
    end

    table.insert(smokes, p)
end

function ai_controls(car)
    -- look ahead 5 segments
    local ai = {
        decisions = rnd(5) + 3,
        target_seg = 1,
        riskiness = rnd(23) + 1
    }
    ai.car = car
    function ai:update()
        self.decisions = self.decisions + DT * (self.skill + 4 + rnd(6))
        if self.decisions < 1 then
            return
        end
        local c = car.controls
        local car = self.car
        if not car.current_segment then
            return
        end
        local e = 6
        local s = 6
        local t = car.current_segment + e
        if t < (mapsize * car.race.lap_count) + 10 then
            local diff=0
            for t=car.current_segment+s,car.current_segment+e do
                local v5 = get_vec_from_vecmap(t)
                if v5 then
                    local ta = to_pico_angle(atan2(v5.y - car.pos.y, v5.x - car.pos.x)) - car.angle
                    if abs(ta) > abs(diff) then
                        diff=ta
                    end
                end
            end
            while diff > 0.5 do
                diff = diff - 1
            end
            while diff < -0.5 do
                diff = diff + 1
            end
            if abs(diff) > 0.02 and rnd(50) > 40 + self.skill then
                self.decisions = 0
            end
            local steer = car.steer
            local speed=length(car.vel)*14
            c.accel = abs(diff) < steer * 10
            c.right = 12*diff < -steer
            c.left = 12*diff > steer
            c.brake = speed*speed*abs(diff)/100000 > steer
            -- if car == cam_car then
            --     print(string.format("%s L%d|%3d %f %.4f %.4f %s%s%s%s",
            --         car.driver.short_name,car.current_segment//mapsize+1,car.current_segment,steer,speed*speed*abs(diff)/30000,steer*3,
            --         c.accel and '^' or ' ',c.brake and 'v' or ' ',c.left and '<' or ' ',c.right and '>' or ' '))
            -- end
            c.boost = false --car.boost > 24 - self.riskiness and (abs(diff) < steer / 2 or car.accel < 0.5)
            self.decisions = self.decisions - 1
        else
            c.accel = false
            c.boost = false
            c.brake = true
        end
    end

    return ai
end

function create_car(race)
    c = CARS[intro.car]
    local tyre_type = 1
    local tyre_heat=TYRE_HEAT[tyre_type]
    local car = {
        race = race,
        vel = vec(),
        angle = 0,
        trails = cbufnew(32),
        current_segment = race.race_mode == MODE_RACE and -1 or -5,
        boost = 100,
        cooldown = 0,
        wrong_way = 0,
        speed = 0,
        accel = 0,
        asp = 0,
        accsqr = c.accsqr,
        steer = c.steer,
        maxacc = c.maxacc,
        maxboost = c.maxacc * 1.5,
        lost_count = 0,
        last_good_pos = vec(),
        last_good_seg = 1,
        color = 8,
        color2 = 24,
        collision = 0,
        delta_time = 0,
        lap_times = {},
        time = "-----",
        best_time = nil,
        verts = {},
        seg_times = {},
        ccut_timer = -1,
        mass=CAR_BASE_MASS,
        tyre_type=tyre_type, -- 1 = soft 2=medium 3=hard 4=inter 5=wet
        tyre_wear={-tyre_heat,-tyre_heat,-tyre_heat,-tyre_heat}, -- <0 = cold
        global_wear = 0
    }
    car.controls = {}
    car.pos = copyv(get_vec_from_vecmap(car.current_segment))
    function car:update(completed, time)

        local angle = self.angle
        local pos = self.pos
        local vel = self.vel
        local accel = self.accel
        local controls = self.controls
        if controls.accel then
            accel = accel + self.accsqr * 0.3
        else
            accel = accel * 0.95
        end
        local speed = length(vel)
        -- accelerate
        local maxacc = self.maxacc
        local wear_coef = clamp((self.global_wear - TYRE_WEAR_THRESHOLD) / (1 - TYRE_WEAR_THRESHOLD),0,1)
        maxacc = maxacc - TYRE_WEAR_ACC_IMPACT * wear_coef
        local MAX_ANGLE=(speed < 7 and accel >= maxacc and (controls.left or controls.right)) and 10 or 3
        local angle_speed = speed < 5 and speed/5 or speed < 10 and 1+(MAX_ANGLE-1)*(speed-5)/5 or speed < 20 and MAX_ANGLE-(speed-10)*(MAX_ANGLE-1)/10 or 1
        -- if self.is_player then
        --     print(string.format("acc %.1f speed %.1f aspeed %.2f",accel,speed,angle_speed))
        -- end
        local steer=self.steer - wear_coef * TYRE_WEAR_STEER_IMPACT
        if controls.left then
            angle = angle + angle_speed * steer * 0.3
        end
        if controls.right then
            angle = angle - angle_speed * steer * 0.3
        end
        if self.ccut_timer >= 0 then
            self.ccut_timer = self.ccut_timer - 1
        end
        -- if tracked==nil and self.is_player then
        --     print(string.format("%s %4d steer %.3f maxacc %.2f wear %.0f%%",
        --         self.driver.short_name,self.current_segment,steer,maxacc,wear_coef*100))
        -- end

        -- brake
        local sb_left
        local sb_right
        if controls.brake then
            if speed > 0.2 and speed < 1 then
                local dangle=min(0.1/speed,0.03)
                if controls.left then
                    angle = angle + dangle
                elseif controls.right then
                    angle = angle - dangle
                end
            end
            local brake_speed=max(0,speed - BRAKE_COEF + wear_coef * TYRE_WEAR_BRAKE_IMPACT)
            vel = brake_speed == 0 and vec(0,0) or scalev(normalize(vel), brake_speed)
            speed= brake_speed
        end
        accel = min(accel, self.boosting and self.maxboost or maxacc)
        -- boosting

        if controls.boost and self.boost > 0 and self.cooldown <= 0 then
            self.boosting = true
            self.boost = self.boost - 1
            self.boost = max(self.boost, 0)
            accel = accel + self.accsqr * 0.3

            if self.boost == 0 then -- activate cooldown
                self.cooldown = 25
                accel = accel * 0.5
                if self.is_player then
                    sfx(SFX_BOOST_COOLDOWN)
                    sc1 = SFX_BOOST_COOLDOWN
                end
            elseif self.is_player and (not (sc1 == SFX_BOOSTER and sc1timer > 0)) and sc1 ~= 39 and self.boost <=
                BOOST_CRITICAL_THRESH then
                sfx(39)
                sc1 = 39
            elseif self.is_player and (not (sc1 == SFX_BOOSTER and sc1timer > 0)) and sc1 ~= 37 and self.boost <=
                BOOST_WARNING_THRESH then
                sfx(37) -- start warning
                sc1 = 37
            elseif self.is_player and (not (sc1 == SFX_BOOSTER and sc1timer > 0)) and sc1 ~= 36 and sc1 ~= 37 then
                sfx(36)
                sc1 = 36
            end
        else
            self.boosting = false
            if self.cooldown > 0 then
                self.cooldown = self.cooldown - 0.25
                self.cooldown = max(self.cooldown, 0)
                if self.is_player and self.cooldown == 0 then
                    sfx(34) -- restore power
                    sc1 = 34
                end
                self.boost = self.boost + 0.125
            else
                self.boost = self.boost + 0.25
                self.boost = min(self.boost, 100)
            end
        end
        if self.is_player and not completed then
            -- engine noise
            local sgear = (self.speed*14/328)^0.75 * 8
            self.gear = flr(clamp(sgear,1,7))
            local rpm = sgear-self.gear -- between 0 and 1
            local base_freq=self.gear == 1 and 290 or 340
            local max_freq = self.controls.accel and 550-base_freq or 520-base_freq
            local freq = base_freq + max_freq * rpm
            local volume = 0.5 + 0.5*self.accel/self.maxacc
            if false and self.freq then
                snd.set_channel_freq(1,freq)
                snd.set_channel_volume(1,volume)
            else
                snd.play_note(8, freq, volume, volume, 1)
            end
            self.freq=freq
            sc1 = 35
        end

        -- check collisions
        -- get a width enlarged version of this segment to help prevent losing the car
        local current_segment = self.current_segment
        local old_segment=current_segment
        local v = get_data_from_vecmap(current_segment)
        local nextv = get_data_from_vecmap(current_segment + 2)
        local pos = dot(vecsub(self.pos, v), v.side)
        local team_pit=TEAMS[self.driver.team].pit
        if v.rtyp // 8 == OBJ_PIT_ENTRY3 and pos < -32 then
            if not self.pit then
                self.race.tyre = 0
            end
            self.pit = -team_pit
            self.race.pits[team_pit] = true
        elseif v.ltyp // 8 == OBJ_PIT_ENTRY3 and pos > 32 then
            if not self.pit then
                self.race.tyre = 0
            end
            self.pit = team_pit
            self.race.pits[team_pit] = true
        elseif nextv.rtyp // 8 == OBJ_PIT_EXIT1 and pos < -32 then
            if not self.pit then
                self.race.tyre = 0
            end
            self.pit = nil
            self.race.pits[team_pit] = false
        elseif nextv.ltyp // 8 == OBJ_PIT_EXIT1 and pos > 32 then
            if not self.pit then
                self.race.tyre = 0
            end
            self.pit = nil
            self.race.pits[team_pit] = false
        end
        local segpoly = get_segment(current_segment, true)
        local poly

        self.collision = 0
        if segpoly then
            local in_current_segment = point_in_polygon(segpoly, self.pos)
            if in_current_segment then
                self.last_good_pos = self.pos
                self.last_good_seg = current_segment
                self.lost_count = 0
                poly = get_segment(current_segment, false, true)
            else
                -- not found in current segment, try the next
                local segnextpoly = get_segment(current_segment + 1, true)
                if segnextpoly and point_in_polygon(segnextpoly, self.pos) then
                    poly = get_segment(current_segment + 1, false, true)
                    current_segment = current_segment + 1
                    if best_seg_times[current_segment] == nil then
                        best_seg_times[current_segment] = time
                    end
                    self.seg_times[current_segment] = time
                    snd.set_channel_volume(2, get_data_from_vecmap(current_segment + 1).tribune)
                    if current_segment > 0 and current_segment % mapsize == 0
                        and (self.race.race_mode == MODE_TIME_ATTACK or current_segment <= mapsize * self.race.lap_count) then
                        -- new lap
                        local lap_time = time
                        if self.race.race_mode == MODE_RACE then
                            lap_time = lap_time - self.delta_time
                        end
                        table.insert(self.lap_times, lap_time)
                        self.delta_time = self.delta_time + lap_time
                        if best_lap_time == nil or lap_time < best_lap_time then
                            best_lap_time = lap_time
                            self.race.best_lap_timer = 100
                            if best_lap_driver ~= nil then
                                best_lap_driver.is_best = false
                            end
                            best_lap_driver = self.driver
                            self.driver.is_best = true
                        end
                        if self.best_time == nil or lap_time < self.best_time then
                            self.best_time = lap_time
                            self.play_replay = self.record_replay
                        end
                        if car.race.is_finished then
                            car.race_finished = true
                        end
                    end
                    self.wrong_way = 0
                else
                    -- not found in current or next, try the previous one
                    local segprevpoly = get_segment(current_segment - 1, true)
                    if segprevpoly and point_in_polygon(segprevpoly, self.pos) then
                        poly = get_segment(current_segment - 1, false, true)
                        current_segment = current_segment - 1
                        self.wrong_way = self.wrong_way + 1
                    else
                        -- completely lost the car
                        current_segment = find_segment_from_pos(self.pos, self.last_good_seg)
                        if current_segment == nil then
                            self.lost_count = self.lost_count + 1
                            -- current_segment+=1 -- try to find the car next frame
                            if self.lost_count > 30 then
                                -- lost for too long, bring them back to the last known good position
                                local v = get_data_from_vecmap(self.last_good_seg)
                                self.pos = copyv(v)
                                self.current_segment = self.last_good_seg - 1
                                current_segment = self.current_segment
                                self.vel = vec(0, 0)
                                self.angle = v.dir
                                self.wrong_way = 0
                                self.accel = 1
                                self.lost_count = 0
                                self.trails = cbufnew(32)
                                return
                            end
                        else
                            poly = get_segment(current_segment, false, true)
                            if current_segment - self.last_good_seg > 2 then
                                self.ccut_timer = 100
                            end
                        end
                    end
                end
            end
            -- check collisions with walls
            if poly then
                local car_poly = { self.verts[1], self.verts[2], self.verts[3] }
                local rails
                if self.pit and self.pit < 0  then
                    local p = vecsub(v.right_inner_rail, scalev(v.side, 6))
                    local p2 = vecadd(v.right_inner_rail, scalev(v.front, 33))
                    local width = (v.rtyp // 8 == OBJ_PIT or nextv.rtyp // 8 == OBJ_PIT) and 48 or 20
                    local p3 = vecsub(p, scalev(v.side, width))
                    local p4 = vecsub(p2, scalev(v.side, width))
                    rails = { { p2, p }, { p3, p4 } }
                elseif self.pit and self.pit > 0 then
                    local p = vecadd(v.left_inner_rail, scalev(v.side, 6))
                    local p2 = vecadd(v.left_inner_rail, scalev(v.front, 33))
                    local width = (v.ltyp // 8 == OBJ_PIT or nextv.ltyp // 8 == OBJ_PIT) and 48 or 20
                    local p3 = vecadd(p, scalev(v.side, width))
                    local p4 = vecadd(p2, scalev(v.side, width))
                    rails = { { p2, p }, { p3, p4 } }
                else
                    rails = { { poly[2], poly[3] }, { poly[4], poly[1] } }
                end
                local rv, pen, point = check_collision(car_poly, rails)
                if rv then
                    if pen > 5 then
                        pen = 5
                    end
                    vel = vecsub(vel, scalev(rv, pen * COLLISION_COEF))
                    accel = accel * (1.0 - (pen / 10))
                    create_spark(self.current_segment, point, rv, false)
                    self.collision = self.collision + pen
                    if self.is_player then
                        if pen > 2 then
                            sfx(38)
                            sc1 = 38
                        else
                            sfx(40)
                            sc1 = 40
                        end
                    end
                end
            end
        end
        if old_segment ~= current_segment then
            -- fuel consumption
            self.mass = self.mass - FUEL_MASS_PER_KM / mapsize
            local base_wear = self.controls.brake and 1.25 or self.controls.accel and 0.75 or 0.5
            -- tyre wear
            local more = self.controls.brake or self.controls.accel
            local global_wear=0
            for i=1,4 do
                local wear = self.controls.brake and (i<3 and 1.25 or 1)
                    or self.controls.accel and (i<3 and 1 or 0.75)
                    or 0.5
                if self.controls.left then
                    wear=wear + (i%2 == 1 and 0.25 or 0.75)
                elseif self.controls.right then
                    wear=wear + (i%2 == 0 and 0.25 or 0.75)
                end
                self.tyre_wear[i] = self.tyre_wear[i] + (more and 1.5*wear or wear)
                global_wear = global_wear + self.tyre_wear[i]
            end
            self.global_wear = global_wear / (4*TYRE_LIFE[self.tyre_type])
            --print(string.format("tyres %.1f %.1f   %.1f %.1f",self.tyre_wear[1],self.tyre_wear[2],self.tyre_wear[3],self.tyre_wear[4]))
        end

        local v = get_data_from_vecmap(self.current_segment)
        local sidepos = dot(vecsub(self.pos, v), v.side)
        local ground_type = sidepos > 32 and (v.ltyp & 7) or (sidepos < -32 and (v.rtyp & 7) or 0)

        local car_dir = vec(cos(angle), sin(angle))
        self.vel = vecadd(vel, scalev(car_dir, accel * CAR_BASE_MASS / self.mass))
        if ground_type == 0 or ground_type == 3 then
            -- less slide on asphalt
            local no_slide = scalev(car_dir,length(self.vel))
            self.vel = lerpv(self.vel,no_slide,0.12)
        end
        self.pos = vecadd(self.pos, scalev(self.vel, 0.3))
        -- aspiration
        local asp = false
        if self.pit == nil and self.is_player then
            for i = 1, #self.race.cars do
                local car = self.race.cars[i]
                local seg = wrap(self.current_segment, mapsize)
                local car_seg = wrap(car.current_segment, mapsize)
                if car ~= self and car_seg - seg <= 3 and car_seg - seg > 0 then
                    local perp = perpendicular(car_dir)
                    local dist = dot(vecsub(car.pos, self.pos), perp)
                    if abs(dist) <= 10 then
                        asp = true
                        break
                    end
                end
            end
            if asp then
                self.asp = min(3.5,self.asp + 0.1)
            else
                self.asp = max(0,self.asp - 0.04)
            end
        end
        local speed=length(self.vel)
        if speed > 0.1 then
            if self.pit then
                speed=min(speed,70/14) -- max 70km/h in pit
            else
                local asp = 1-self.asp*ASPIRATION_COEF/100
                local team_perf = 1 - self.perf * TEAM_PERF_COEF / 100
                speed = speed - AIR_RESISTANCE * asp * team_perf * (speed*speed) * 0.01
            end
            self.vel = scalev(normalize(self.vel),speed)
        end
        local ground_type_inner = sidepos > 36 and (v.ltyp & 7) or (sidepos < -36 and (v.rtyp & 7) or 0)
        if self.is_player and speed > 1 and frame % flr(60 / speed) == 0 then
            if (v.has_lkerb and sidepos <= 36 and sidepos >= 24)
                or (v.has_rkerb and sidepos >= -36 and sidepos <= -24) then
                -- on kerbs
                sfx(12)
            end
        end
        if ground_type == 1 then
            --grass
            local r = rnd(10)
            if r < 4 and ground_type_inner == 1 then
                self.vel = scalev(self.vel, 0.95)
                local angle_vel_impact = min(5.0, speed) / 5.0
                local da = math.random( -20, 20) * angle_vel_impact
                angle = wrap(angle, 1) * (1000 + da) / 1000
            end
            if r < speed then
                create_spark(self.current_segment, self.pos, scalev(normalize(self.vel), 0.3), true)
            end
        elseif ground_type == 2 then
            -- sand
            if ground_type_inner == 2 then
                self.vel = scalev(self.vel, 0.95)
                angle = angle + (self.angle - angle) * 0.5
            end
            if speed > 2 then
                create_smoke(current_segment, vecsub(self.pos, scalev(self.vel, 0.5)), self.vel, 4)
            end
        end
        if self.ccut_timer >= 0 then
            self.vel = scalev(self.vel, 0.97)
        end
        for i = 1, #car_verts do
            self.verts[i] = rotate_point(vecadd(self.pos, car_verts[i]), angle, self.pos)
        end

        if self.is_player then
            cbufpush(self.trails, rotate_point(vecadd(self.pos, trail_offset), angle, self.pos))
        end

        -- update self attrs
        self.accel = accel
        self.speed = speed -- used for showing speedo
        self.angle = angle
        self.current_segment = current_segment
        if abs(current_segment - cam_car.current_segment) < 10 then
            local spawn_pos = vecsub(self.pos, scalev(self.vel, 0.5))
            if not self.pit then
                local caccel = accel / CARS[intro.car].maxacc
                if (self.ccut_timer < 0 and speed > 1 and caccel / speed > 0.07) or (controls.brake and speed < 9 and speed > 2) then
                    local col = ground_type == 1 and 3 or (ground_type == 2 and 4 or 22)
                    create_smoke(current_segment, spawn_pos, self.vel, col)
                end
            end
            if speed > 25 and ground_type == 0 and rnd(10) < 4 then
                create_spark(current_segment, spawn_pos, scalev(normalize(self.vel), 0.8), false)
            end
        end
        if car.current_segment >= mapsize * car.race.lap_count then
            car.race_finished = true
            car.race.is_finished = true
        end
    end

    function car:draw_minimap(cam_car)
        local seg = car_lap_seg(self.current_segment, cam_car)
        local pseg = cam_car.current_segment
        if seg >= pseg + MINIMAP_START and seg < pseg + MINIMAP_END then
            minimap_disk(self.pos, self.color)
        end
    end

    function car:draw()
        if #self.verts == 0 then
            -- happens only before race start, when cars are drawn but not updated
            for i = 1, #car_verts do
                self.verts[i] = rotate_point(vecadd(self.pos, car_verts[i]), self.angle, self.pos)
            end
        end
        local angle = self.angle
        local color = self.color
        local v = self.verts
        local boost = self.boost
        linevec(v[6], v[7], 18) -- front suspension
        quadfill(v[8], v[9], v[10], v[11], color) -- front wing
        trifill(v[23],v[24],v[25],color) -- hull
        quadfill(v[26],v[27],v[28],v[29],color) -- hull
        trifill(v[13], v[14], v[15], self.color2)
        trifill(v[16], v[17], v[18], self.color2)
        draw_tyres(v[4], v[5], v[6], v[7], 0)
        circfill(v[12].x, v[12].y, 1, self.driver.helmet)
        quadfill(v[19], v[20], v[21], v[22], color) -- rear wing
        -- shadow
        local sd = scalev(SHADOW_DELTA, 0.075)
        local sv = {}
        for i = 1, #v do
            sv[i] = vecadd(v[i], sd)
        end
        gfx.set_active_layer(LAYER_SHADOW)
        linevec(sv[6], sv[7], 22)
        quadfill(sv[8], sv[9], sv[10], sv[11], 22)
        trifill(sv[23],sv[24],sv[25],22)
        quadfill(sv[26],sv[27],sv[28],sv[29],22)
        draw_tyres(sv[4], sv[5], sv[6], sv[7], 22)
        quadfill(sv[19], sv[20], sv[21], sv[22], 22)
        gfx.set_active_layer(LAYER_SHADOW2)
        trifill(v[12],midpoint(v[19],v[20]), sv[12],22)
        gfx.set_active_layer(LAYER_CARS)
    end

    function car:draw_trails()
        -- trails
        local lastp
        for i = 0, self.trails._size - 1 do
            local p = cbufget(self.trails, -i)
            if not p then
                break
            end
            if lastp then
                linevec(lastp, p, i > self.trails._size - 4 and 7 or (i < 12 and 1 or 12))
            end
            lastp = p
        end
    end

    return car
end

function set_game_mode(m)
    game_mode = m
end

function init()
    car_verts = { vec( -9, -2.5), vec(7, 0), vec( -9, 2.6), -- collision shape
        vec( -7, -3), vec(-7, 3), vec(3, -3), vec(3, 3), -- tires positions
        vec(5, -2.5), vec(5, 2.6), vec(7, -2.5), vec(7, 2.6), -- front wing
        vec(-1, 0), -- pilot helmet position
        vec( -3, -2.5), vec(-7, -3), vec( -9, 0), vec( -7, 3), vec(-3, 2.6), vec( -9, 0), -- second color
        vec( -9, -2.5), vec( -9, 2.5), vec( -11, -2.5), vec( -11, 2.5), -- rear wing
        vec(-3,-2.5),vec(7,0),vec(-3,2.6),vec(-3,-2.5),vec( -9, -3),vec(-3,2.6),vec(-9, 3) -- hull
    }
    for i=1,#car_verts do
        car_verts[i].x = car_verts[i].x*0.8
        car_verts[i] = scalev(car_verts[i],0.8)
    end
    for _, sfx in ipairs(SFX) do
        snd.new_pattern(sfx)
    end
    snd.reserve_channel(1) -- reserved for engine sound
    snd.reserve_channel(2) -- reserved for tribunes
    snd.new_instrument(INST_TRIANGLE)
    snd.new_instrument(INST_TILTED)
    snd.new_instrument(INST_SAW)
    snd.new_instrument(INST_SQUARE)
    snd.new_instrument(INST_PULSE)
    snd.new_instrument(INST_ORGAN)
    snd.new_instrument(INST_NOISE)
    snd.new_instrument(INST_PHASER)
    snd.new_instrument(INST_ENGINE)
    snd.new_instrument(INST_TRIBUNE)
    gfx.load_img(1, "pitstop/pitstop.png","sprites")
    gfx.set_sprite_layer(1)
    gfx.show_layer(LAYER_SMOKE) -- smoke fx
    gfx.set_layer_operation(3, gfx.LAYEROP_ADD)
    gfx.show_layer(LAYER_SHADOW) -- shadow
    gfx.set_layer_operation(LAYER_SHADOW, gfx.LAYEROP_MULTIPLY)
    gfx.show_layer(LAYER_CARS)
    gfx.show_layer(LAYER_SHADOW2) -- shadow
    gfx.set_layer_operation(LAYER_SHADOW2, gfx.LAYEROP_MULTIPLY)
    gfx.show_layer(LAYER_TOP) -- roofs & ui
    gfx.show_mouse_cursor(false)
    trail_offset = vec( -6, 0)
    intro:init()
    set_game_mode(intro)
end

function render()
    game_mode:draw()
end

flipflop = true
function update()
    -- original game updates at 30fps, viper is 60fps
    -- update only every 2 ticks
    flipflop = not flipflop
    -- do not lose press events
    mlb_pressed = (flipflop and mlb_pressed) or inp.mouse_button_pressed(inp.MOUSE_LEFT)
    if flipflop then
        game_mode:update()
        mlb_pressed = false
    end
end

-- intro

intro = {}
frame = 0

MODE_RACE = 1
MODE_TIME_ATTACK = 2
MODE_EDITOR = 3

game_modes = { "Race vs AI", "Time Attack", "Track Editor" }

function intro:init()
    -- music(0)
    difficulty = 0
    camera_angle = 0.25
    load_map()
    self.game_mode = 1
    self.car = 1
    self.option = 1
    self.lap_count = 1
end

function intro:update()
    frame = frame + 1

    if not inp.action1() then
        self.ready = true
    end

    if self.ready and inp.action1_pressed() then
        if self.game_mode == MODE_EDITOR then
            mapeditor:init()
            set_game_mode(mapeditor)
        else
            local race = race()
            race:init(difficulty, self.game_mode, self.lap_count)
            set_game_mode(race)
        end
    end

    if self.option == 1 then
        if inp.left_pressed() then
            self.game_mode = self.game_mode - 1
        end
        if inp.right_pressed() then
            self.game_mode = self.game_mode + 1
        end
    elseif self.option == 2 then
        if inp.left_pressed() then
            difficulty = mid(0, difficulty - 1, 7)
            load_map()
        end
        if inp.right_pressed() then
            difficulty = mid(0, difficulty + 1, 7)
            load_map()
        end
    elseif self.option == 3 then
        if inp.left_pressed() then
            self.car = self.car - 1
        end
        if inp.right_pressed() then
            self.car = self.car + 1
        end
    elseif self.option == 4 then
        if inp.left_pressed() then
            self.lap_count = self.lap_count - 1
        end
        if inp.right_pressed() then
            self.lap_count = self.lap_count + 1
        end
    end
    if inp.up_pressed() then
        self.option = self.option - 1
    end
    if inp.down_pressed() then
        self.option = self.option + 1
    end
    self.game_mode = mid(1, self.game_mode, 3)
    self.option = mid(1, self.option, 5 - self.game_mode)
    self.car = mid(1, self.car, 3)
    self.lap_count = mid(1, self.lap_count, #LAP_COUNTS)
end

difficulty_names = {
    [0] = "Manzana",
    "Vancouver",
    "Melbourne",
    "Detroit",
    "Jakarta",
    "Wellington",
    "Hanoi",
    "Osaka"
}

function intro:draw()
    cls()
    gfx.blit(0, 20, 224, 86, 80, 10)
    gfx.blit(0, 106, 224, 118, 80, 100)
    draw_intro_minimap( -95, -62, 0.015, 6)
    printr("x/c/arrows/esc", 300, 45, 6)

    local c = frame % 16 < 8 and 8 or 9
    printr("Mode", 202, 2, 6)
    printr(game_modes[self.game_mode], 303, 2, self.option == 1 and c or 9)
    printr("Track", 202, 12, 6)
    printr(difficulty_names[difficulty], 304, 12, self.option == 2 and c or 9)
    if self.game_mode < 3 then
        printr("Level", 202, 22, 6)
        printr(CARS[self.car].name, 304, 22, self.option == 3 and c or 9)
    end
    if self.game_mode == 1 then
        printr("Laps", 202, 32, 6)
        printr("" .. LAP_COUNTS[self.lap_count], 304, 32, self.option == 4 and c or 9)
    end
end

mapeditor = {
    sec = 0,
    mapoffx = 0,
    mapoffy = 0,
    mousex = 0,
    mousey = 0,
    drag = false,
    mouseoffx = 0,
    mouseoffy = 0,
    mdragx = 0,
    mdragy = 0
}
function mapeditor:init()
    scale = 0.05
    camera()
    self.sec = #mapsections
    gfx.show_mouse_cursor(true)
    self.race = race()
    self.race:init(1, MODE_EDITOR, 1)
    camera_angle = 0.25
    self.display = 0
end

function map_menu(game)
    local selected = 1
    local m = {}
    function m:update()
        frame = frame + 1
        if inp.up_pressed() then
            selected = selected - 1
        end
        if inp.down_pressed() then
            selected = selected + 1
        end
        selected = max(min(selected, 3), 1)
        if inp.action1_pressed() then
            if selected == 1 then
                set_game_mode(game)
            elseif selected == 2 then
                camera_scale = 1
                minimap_offset = MINIMAP_RACE_OFFSET
                print("1337,")
                for i = 1, #mapsections do
                    local ms = mapsections[i]
                    print(ms[1] .. "," .. ms[2] .. "," .. ms[3] .. "," .. ms[4] ..
                    "," .. ms[5] .. "," .. ms[6] .. "," .. ms[7] .. ",")
                end
                print("0,0,0,0,0,0,0")
                local race = race()
                race:init(difficulty, 2)
                gfx.show_mouse_cursor(false)
                set_game_mode(race)
                return
            elseif selected == 3 then
                camera_scale = 1
                minimap_offset = MINIMAP_RACE_OFFSET
                camera_angle = 0.25
                gfx.show_mouse_cursor(false)
                set_game_mode(intro)
            end
        end
    end

    function m:draw()
        game:draw()
        rectfill(115, 40, 223, 98, 1)
        gprint("Editor", 120, 44, 7)
        gprint("Continue", 120, 56, selected == 1 and frame % 4 < 2 and 7 or 6)
        gprint("Test track", 120, 68, selected == 2 and frame % 4 < 2 and 7 or 6)
        gprint("Exit", 120, 80, selected == 3 and frame % 4 < 2 and 7 or 6)
    end

    return m
end

function mapeditor:update()
    local cs = mapsections[self.sec]
    local mx, my = inp.mouse_pos()
    if self.display == 1 then
        cam_pos = vecadd(cam_pos, scalev(vecsub(cam_target_pos, cam_pos), 0.2))
    end
    if inp.mouse_button(inp.MOUSE_LEFT) then
        if not self.drag then
            self.drag = true
            self.mousex = mx
            self.mousey = my
            self.mdragx = 0
            self.mdragy = 0
        else
            self.mdragx = mx - self.mousex
            self.mdragy = my - self.mousey
        end
    elseif self.drag then
        self.mouseoffx = self.mouseoffx + self.mdragx
        self.mouseoffy = self.mouseoffy + self.mdragy
        self.mdragx = 0
        self.mdragy = 0
        self.drag = false
    end
    if mlb_pressed then
        if inside_rect(mx, my, gfx.SCREEN_WIDTH / 2 - 32, 19, 16, 16) then
            -- change left terrain type
            local ltyp = cs[4] & 7
            ltyp = (ltyp + 1) % 4
            cs[4] = (cs[4] & ( ~7)) + ltyp
            self.race:generate_track()
        elseif inside_rect(mx, my, gfx.SCREEN_WIDTH / 2 + 16, 19, 16, 16) then
            -- change right terrain type
            local ltyp = cs[5] & 7
            ltyp = (ltyp + 1) % 4
            cs[5] = (cs[5] & ( ~7)) + ltyp
            self.race:generate_track()
        elseif inside_rect(mx, my, gfx.SCREEN_WIDTH - 150, 19, 32, 8) then
            -- change left object type
            local lobj = cs[4] // 8
            lobj = (lobj + 1) % OBJ_COUNT
            while lobj >= OBJ_PIT_LINE_START do
                lobj = (lobj + 1) % OBJ_COUNT
            end
            cs[4] = (cs[4] & 7) + lobj * 8
            self.race:generate_track()
        elseif inside_rect(mx, my, gfx.SCREEN_WIDTH - 150, 28, 32, 8) then
            -- change right object type
            local robj = cs[5] // 8
            robj = (robj + 1) % OBJ_COUNT
            while robj >= OBJ_PIT_LINE_START or robj == OBJ_BRIDGE or robj == OBJ_BRIDGE2 do
                robj = (robj + 1) % OBJ_COUNT
            end
            cs[5] = (cs[5] & 7) + robj * 8
            self.race:generate_track()
        end
    end
    -- left/right : change section curve
    if inp.right_pressed() then
        cs[2] = cs[2] - (inp.key(inp.KEY_LSHIFT) and 0.1 or 1)
        self.race:generate_track()
    elseif inp.left_pressed() then
        cs[2] = cs[2] + (inp.key(inp.KEY_LSHIFT) and 0.1 or 1)
        self.race:generate_track()
        -- up/down : change section length
    elseif inp.up_pressed() then
        cs[1] = cs[1] + 1
        self.race:generate_track()
    elseif inp.down_pressed() then
        cs[1] = cs[1] - 1
        self.race:generate_track()
        -- action2 : delete last section
    elseif inp.action2_pressed() then
        if self.sec > 1 then
            if self.sec == #mapsections then
                mapsections[#mapsections] = nil
            else
                table.remove(mapsections, self.sec)
            end
            self.sec = self.sec - 1
            self.race:generate_track()
        end
        -- action1 : duplicate last section
    elseif inp.action1_pressed() then
        mapsections[#mapsections + 1] = { cs[1], cs[2], cs[3], 0, 0, 0, 0 }
        self.sec = #mapsections
        self.race:generate_track()
        -- pageup/pagedown : change section width
    elseif inp.key_pressed(inp.KEY_PAGEDOWN) then
        cs[3] = cs[3] - 1
        self.race:generate_track()
    elseif inp.key_pressed(inp.KEY_PAGEUP) then
        cs[3] = cs[3] + 1
        self.race:generate_track()
        -- NUMPAD +/- : zoom
    elseif inp.key_pressed(inp.KEY_NUMPADMINUS) then
        if self.display == 0 then
            scale = scale * 0.9
        else
            camera_scale = camera_scale * 0.9
        end
    elseif inp.key_pressed(inp.KEY_NUMPADPLUS) then
        if self.display == 0 then
            scale = scale * 1.1
        else
            camera_scale = camera_scale * 1.1
        end
    elseif inp.key_pressed(inp.KEY_HOME) then
        self.sec = self.sec == 1 and #mapsections or self.sec - 1
        local seg = get_segment_from_section(self.sec)
        self.race.player.pos = get_vec_from_vecmap(seg)
        self.race.player.current_segment = seg
        if self.display == 1 then
            cam_target_pos = self.race.player.pos
        end
    elseif inp.key_pressed(inp.KEY_END) then
        self.sec = self.sec == #mapsections and 1 or self.sec + 1
        local seg = get_segment_from_section(self.sec)
        self.race.player.pos = get_vec_from_vecmap(seg)
        self.race.player.current_segment = seg
        if self.display == 1 then
            cam_target_pos = self.race.player.pos
        end
    elseif inp.key_pressed(inp.KEY_ESCAPE) then
        -- test map todo: open menu
        set_game_mode(map_menu(self))
        return
    elseif inp.key_pressed(inp.KEY_TAB) then
        self.display = 1 - self.display
        if self.display == 0 then
            camera_scale = 1
            minimap_offset = MINIMAP_RACE_OFFSET
            camera()
        else
            camera_scale = 0.2
            minimap_offset = MINIMAP_EDITOR_OFFSET
            local seg = get_segment_from_section(self.sec)
            self.race.player.pos = get_vec_from_vecmap(seg)
            self.race.player.current_segment = seg
            cam_pos = self.race.player.pos
            cam_target_pos = cam_pos
        end
    end
end

function compute_minimap_offset(scale)
    local x, y, minx, miny = 0, 0, 0, 0
    local dir = 0
    for i = 1, #mapsections do
        local ms = mapsections[i]
        local last_section = i == #mapsections
        for seg = 1, ms[1] do
            dir = dir + (ms[2] - 128) / 100
            x = x + cos(dir) * 28 * scale
            y = y + sin(dir) * 28 * scale
            minx = min(minx, x)
            miny = min(miny, y)
        end
    end
    return minx, miny
end

function draw_intro_minimap(sx, sy, scale, col)
    local minx, miny = compute_minimap_offset(scale)
    local dx = sx - minx
    local dy = sy - miny
    local x, y = 0, 0
    local lastx, lasty = x, y
    local dir = 0
    for i = 1, #mapsections do
        local ms = mapsections[i]
        local last_section = i == #mapsections
        for seg = 1, ms[1] do
            dir = dir + (ms[2] - 128) / 100
            x = x + cos(dir) * 28 * scale
            y = y + sin(dir) * 28 * scale
            if last_section then
                local coef = seg / ms[1]
                x = (1 - coef) * x
                y = (1 - coef) * y
            end
            line(lastx + dx, lasty + dy, x + dx, y + dy, #mapsections == i and 3 or col)
            lastx, lasty = x, y
        end
    end
end

function draw_editor_minimap(sx, sy, scale, col, sec)
    local minx, miny = compute_minimap_offset(scale)
    local dx = sx - minx
    local dy = sy - miny
    local x, y = 0, 0
    local lastx, lasty = x, y
    local dir = 0
    local sec_x, sec_y = 0, 0
    for i = 1, #mapsections do
        ms = mapsections[i]
        local highlighted = i == sec
        for seg = 1, ms[1] do
            dir = dir + (ms[2] - 128) / 100
            x = x + cos(dir) * 28 * scale
            y = y + sin(dir) * 28 * scale
            line(lastx + dx, lasty + dy, x + dx, y + dy, highlighted and 9 or (#mapsections == i and 3 or col))
            lastx, lasty = x, y
        end
        if i == sec then
            sec_x, sec_y = x, y
        end
    end
    return sec_x, sec_y
end

function mapeditor:draw()
    cls()
    local minseg, maxseg
    if self.display == 0 then
        local sec_x, sec_y = draw_editor_minimap(self.mapoffx + self.mouseoffx + self.mdragx - 65,
            self.mapoffy - 20 + self.mouseoffy + self.mdragy, scale, 6, self.sec)
        self.mapoffx = -sec_x
        self.mapoffy = -sec_y
    else
        local back = cam_pos
        cam_pos = vecsub(vecsub(cam_pos, vec(self.mouseoffx, self.mouseoffy)), vec(self.mdragx, self.mdragy))
        minseg, maxseg = self.race:draw()
        cam_pos = back
    end
    if minseg then
        printc("sec " .. self.sec .. '/' .. #mapsections .. " seg " .. minseg .. "-" .. maxseg, gfx.SCREEN_WIDTH / 2, 1,
            7)
    else
        printc("sec " .. self.sec .. '/' .. #mapsections, gfx.SCREEN_WIDTH / 2, 1, 7)
    end
    local sec = mapsections[self.sec]
    local sec_len, sec_dir, sec_width = sec[1], sec[2], sec[3]
    local ltyp = sec[4] & 3
    local rtyp = sec[5] & 3
    local cols = { 21, 27, 15, 5 }
    local lcol = PAL[cols[ltyp + 1]]
    local rcol = PAL[cols[rtyp + 1]]
    local lobj = sec[4] // 8
    local robj = sec[5] // 8
    local lrail = sec[6]
    local rrail = sec[7]
    local objs = { [0] = "", "tribune1", "tribune2", "tree", "bridge", "bridge2", "pit", "pit line" }
    printc("len " .. sec_len .. " dir " .. sec_dir .. " w " .. sec_width, gfx.SCREEN_WIDTH / 2, 10, 7)
    printr("rail l " .. lrail .. " r " .. rrail, gfx.SCREEN_WIDTH - 1, 10, 7)
    local mx, my = inp.mouse_pos()
    gprint("lobj " .. objs[lobj], gfx.SCREEN_WIDTH - 150, 19, inside_rect(mx, my, gfx.SCREEN_WIDTH - 150, 19, 32, 8) and
    10 or 7)
    gprint("robj " .. objs[robj], gfx.SCREEN_WIDTH - 150, 28, inside_rect(mx, my, gfx.SCREEN_WIDTH - 150, 28, 32, 8) and
    10 or 7)

    gfx.rectangle(gfx.SCREEN_WIDTH / 2 - 32, 19, 16, 16, lcol.r, lcol.g, lcol.b)
    rect(gfx.SCREEN_WIDTH / 2 - 32, 19, 16, 16, inside_rect(mx, my, gfx.SCREEN_WIDTH / 2 - 32, 19, 16, 16) and 10 or 7)
    gfx.rectangle(gfx.SCREEN_WIDTH / 2 + 16, 19, 16, 16, rcol.r, rcol.g, rcol.b)
    rect(gfx.SCREEN_WIDTH / 2 + 16, 19, 16, 16, inside_rect(mx, my, gfx.SCREEN_WIDTH / 2 + 16, 19, 16, 16) and 10 or 7)
    local y = 3
    if self.display == 0 then
        gfx.blit(162, 8, 12, 12, 17, y)
        gprint("  delete", 17, y + 2, 7)
        y = y + 12
        gfx.blit(174, 8, 12, 12, 17, y)
        gprint("  add", 17, y + 2, 7)
        y = y + 12
        gfx.blit(66, 8, 24, 12, 5, y)
        gprint("    length", 1, y + 2, 7)
        y = y + 12
        gfx.blit(90, 8, 24, 12, 5, y)
        gprint("    curve", 1, y + 2, 7)
        y = y + 12
        gfx.blit(138, 8, 24, 12, 5, y)
        gprint("    zoom", 1, y + 2, 7)
        y = y + 12
        gfx.blit(114, 8, 24, 12, 5, y)
        gprint("    width", 1, y + 2, 7)
        y = y + 12
    end
    gfx.blit(186, 8, 24, 12, 5, y)
    gprint("    section", 1, y + 2, 7)
    y = y + 12
    gfx.blit(54, 8, 12, 12, 17, y)
    gprint("  menu", 17, y + 2, 7)
    y = y + 12
    gfx.blit(210, 8, 12, 12, 17, y)
    gprint("  display", 17, y + 2, 7)
end

function load_map()
    local newfmt = TRACKS[difficulty][1] == 1337
    local start = newfmt and 2 or 1
    mapsections = {}
    while true do
        local ms = {}
        ms[1] = TRACKS[difficulty][start]
        ms[2] = TRACKS[difficulty][start + 1]
        ms[3] = TRACKS[difficulty][start + 2]
        if newfmt then
            ms[4] = TRACKS[difficulty][start + 3]
            ms[5] = TRACKS[difficulty][start + 4]
            ms[6] = TRACKS[difficulty][start + 5]
            ms[7] = TRACKS[difficulty][start + 6]
        end
        if ms[1] == 0 then
            break
        end
        mapsections[#mapsections + 1] = ms
        start = start + (newfmt and DATA_PER_SECTION or 3)
    end
    if #mapsections == 0 then
        mapsections[1] = { 10, 128, 32, 0, 0, 0, 0 }
    end
end

function race()
    local race = {}
    function race:generate_track()
        vecmap = {}
        local dir, mx, my = 0, 0, 0
        local lastdir = 0

        math.randomseed(0xdeadbeef)
        -- generate map
        for i, ms in ipairs(mapsections) do
            local last_section = i == #mapsections
            -- read length,curve,width from tiledata
            local length = ms[1]
            local curve = ms[2]
            local width = ms[3]
            local ltyp = ms[4]
            local rtyp = ms[5]
            local lskiprail_first = max(0, ms[6])
            local rskiprail_first = max(0, ms[7])
            local lskiprail_last = max(0, -ms[6])
            local rskiprail_last = max(0, -ms[7])
            local segment_length
            if length == 0 then
                break
            end
            if last_section then
                -- fine tune curve to join smoothly the first and last segment
                local bestcurve = 0
                local mindist = 1000
                for curve_dt = -90, 90 do
                    local newcurve = curve + curve_dt / 100
                    local l = length
                    local d = dir
                    local ld = lastdir
                    local nmx = mx
                    local nmy = my
                    while l > 0 do
                        d = d + (newcurve - 128) / 100
                        if abs(d - ld) > 0.09 then
                            d = lerp(ld, d, 0.5)
                            segment_length = 16
                            l = l - 0.5
                        else
                            segment_length = 32
                            l = l - 1
                        end
                        nmx = nmx + cos(d) * segment_length
                        nmy = nmy + sin(d) * segment_length
                    end
                    local dist = sqrt(nmx * nmx + nmy * nmy)
                    if dist < mindist then
                        mindist = dist
                        bestcurve = newcurve
                    end
                end
                curve = bestcurve
            end
            while length > 0 do
                dir = dir + (curve - 128) / 100
                local railcoef = 1
                if abs(dir - lastdir) > 0.09 then
                    dir = lerp(lastdir, dir, 0.5)
                    segment_length = 16
                    length = length - 0.5
                    railcoef = 0.5
                else
                    segment_length = 32
                    length = length - 1
                end

                mx = mx + cos(dir) * segment_length
                my = my + sin(dir) * segment_length
                local v = {
                    x = mx,
                    y = my,
                    w = width,
                    dir = dir,
                    ltyp = ltyp,
                    rtyp = rtyp,
                    has_lrail = (lskiprail_first <= 0 and length >= lskiprail_last),
                    has_rrail = (rskiprail_first <= 0 and length >= rskiprail_last),
                    section = i,
                    segment_length = segment_length
                }
                if ltyp // 8 == OBJ_TREE then
                    v.ltrees = {}
                    local tree_count = math.random(8, 18)
                    for _ = 1, tree_count do
                        table.insert(v.ltrees,
                            { typ = math.random(1, 3), p = { x = math.random( -40, 0) - 10, y = math.random(0, 32) } })
                    end
                end
                if rtyp // 8 == OBJ_TREE then
                    v.rtrees = {}
                    local tree_count = math.random(8, 18)
                    for _ = 1, tree_count do
                        table.insert(v.rtrees,
                            { typ = math.random(1, 3), p = { x = math.random( -40, 0) - 10, y = math.random(0, 32) } })
                    end
                end
                v.front = normalize(#vecmap > 0 and vecsub(v, vecmap[#vecmap]) or vec(1, 0))
                v.side = perpendicular(v.front)
                -- track borders (including kerbs)
                v.left_track = vecadd(v, scalev(v.side, v.w))
                v.right_track = vecsub(v, scalev(v.side, v.w))
                local ltribune = ltyp//8 ==OBJ_TRIBUNE or ltyp//8==OBJ_TRIBUNE2
                local rtribune = rtyp//8==OBJ_TRIBUNE or rtyp//8==OBJ_TRIBUNE2
                local tribune = ltribune or rtribune
                v.tribune =  tribune and 0.2 or 0.0 --tribune sound level TODO
                if (ltribune and ltyp&7 ~= 0) or (rtribune and rtyp&7~=0) then
                    v.tribune = v.tribune* 0.5
                end
                table.insert(vecmap, v)
                lastdir = dir
                lskiprail_first = lskiprail_first - 1 * railcoef
                rskiprail_first = rskiprail_first - 1 * railcoef
            end
        end
        mapsize = #vecmap
        -- compute kerbs
        for seg, v in ipairs(vecmap) do
            local v2 = get_data_from_vecmap(seg)
            local curve = abs(v2.dir - v.dir) * 100
            local maybe_kerb = seg ~= 1 and seg ~= #vecmap and curve > 2
            if maybe_kerb then
                v.has_rkerb = (curve >= 4 or v2.dir < v.dir) and 1 or nil
                v.has_lkerb = (curve >= 4 or v2.dir > v.dir) and 1 or nil
                if v.segment_length == 16 then
                    if v2.dir < v.dir then
                        v.has_rkerb = 2
                    else
                        v.has_lkerb = 2
                    end
                end
            end
            local rkerbw = v.has_rkerb and 8 or 0
            local lkerbw = v.has_lkerb and 8 or 0
            v.left_kerb = vecsub(v.left_track, scalev(v.side, lkerbw))
            v.right_kerb = vecadd(v.right_track, scalev(v.side, rkerbw))
        end
        local trib=0
        for i=1,#vecmap+7 do
            local j = i > #vecmap and i-#vecmap or i
            local v=vecmap[j]
            -- smooth tribune sound volume
            if v.tribune > 0 then
                trib=v.tribune
            else
                trib = max(0,trib - 0.03)
                v.forward_tribune=trib
            end
        end
        trib=0
        for i=#vecmap+7,1,-1 do
            local j = i > #vecmap and i-#vecmap or i
            local v=vecmap[j]
            if max(v.tribune,v.forward_tribune or 0) > 0 then
                trib=max(trib,max(v.tribune,v.forward_tribune or 0))
            else
                trib = max(0,trib - 0.03)
            end
            v.tribune = trib
            v.forward_tribune=nil
        end
        -- distance to turn signs
        local dist = 0
        local last_curve = 0
        for i = #vecmap - 1, 1, -1 do
            local v2 = vecmap[i + 1]
            local v = vecmap[i]
            local curve = abs(v2.dir - v.dir) * 100
            if curve >= 2 then
                dist = 0
                last_curve = v2.dir - v.dir
            else
                dist = dist + 1
            end
            if dist == 5 or dist == 10 or dist == 15 then
                if last_curve < 0 then
                    v.lpanel = dist / 5
                elseif last_curve > 0 then
                    v.rpanel = dist / 5
                end
            end
            -- build pit line entry/exit
            if v2.ltyp // 8 == OBJ_PIT_LINE and v.ltyp // 8 < OBJ_PIT then
                for j = i - 2, i do
                    vecmap[j].ltyp = (OBJ_PIT_ENTRY1 + j - i + 2) * 8
                    vecmap[j].has_lrail = false
                end
            end
            if v2.rtyp // 8 == OBJ_PIT_LINE and v.rtyp // 8 < OBJ_PIT then
                for j = i - 2, i do
                    vecmap[j].rtyp = (OBJ_PIT_ENTRY1 + j - i + 2) * 8
                    vecmap[j].has_rrail = false
                end
            end
            if v2.ltyp // 8 < OBJ_PIT and v.ltyp // 8 == OBJ_PIT_LINE then
                for j = i + 1, i + 3 do
                    vecmap[j].ltyp = (OBJ_PIT_EXIT1 + j - i - 1) * 8
                    vecmap[j - 1].has_lrail = false
                end
            end
            if v2.rtyp // 8 < OBJ_PIT and v.rtyp // 8 == OBJ_PIT_LINE then
                for j = i + 1, i + 3 do
                    vecmap[j].rtyp = (OBJ_PIT_EXIT1 + j - i - 1) * 8
                    vecmap[j - 1].has_rrail = false
                end
            end
            -- convert last OBJ_PIT_LINE into OBJ_PIT_LINE_END
            -- and first OBJ_PIT_LINE into OBJ_PIT_LINE_START
            if v2.ltyp // 8 == OBJ_PIT and v.ltyp // 8 == OBJ_PIT_LINE then
                v.ltyp = v.ltyp + 16
            elseif v2.ltyp // 8 == OBJ_PIT_LINE and v.ltyp // 8 == OBJ_PIT then
                v2.ltyp = v2.ltyp + 8
            end
            if v2.rtyp // 8 == OBJ_PIT and v.rtyp // 8 == OBJ_PIT_LINE then
                v.rtyp = v.rtyp + 16
            elseif v2.rtyp // 8 == OBJ_PIT_LINE and v.rtyp // 8 == OBJ_PIT then
                v2.rtyp = v2.rtyp + 8
            end
        end
        -- keep only signs when all 3 (150,100,50) exist
        local expected = 3
        self.first_pit=nil
        for i = 1, #vecmap do
            local seg = wrap(i+#vecmap//2, mapsize)
            local v = vecmap[seg+1]
            if v.rtyp//8 == OBJ_PIT or v.ltyp//8 == OBJ_PIT then
                self.first_pit=seg+1
                break
            end
        end
        for i = 1, #vecmap do
            local v = vecmap[i]
            if v.lpanel ~= nil then
                if v.lpanel == expected then
                    expected = expected - 1
                    if expected == 0 then
                        expected = 3
                    end
                else
                    v.lpanel = nil
                end
            end
            if v.rpanel ~= nil then
                if v.rpanel == expected then
                    expected = expected - 1
                    if expected == 0 then
                        expected = 3
                    end
                else
                    v.rpanel = nil
                end
            end
            -- also compute rails
            v.left_inner_rail = vecadd(v.left_track, scalev(v.side, v.ltyp & 7 == 0 and 4 or 40))
            v.right_inner_rail = vecsub(v.right_track, scalev(v.side, v.rtyp & 7 == 0 and 4 or 40))
            if v.has_lrail then
                v.left_outer_rail = vecadd(v.left_inner_rail, scalev(v.side, 4))
            end
            if v.has_rrail then
                v.right_outer_rail = vecsub(v.right_inner_rail, scalev(v.side, 4))
            end
        end
    end

    function race:init(difficulty, race_mode, lap_count)
        self.race_mode = race_mode
        self.lap_count = LAP_COUNTS[lap_count]
        self.live_cars = 16
        self.is_finished = false
        self.panel_timer = -1
        self.best_lap_timer = -1
        sc1 = nil
        sc1timer = 0
        camera_angle = 0

        self:generate_track()
        self:restart()
    end

    function race:restart()
        self.completed = false
        self.time = self.race_mode == MODE_RACE and -4 or 0
        camera_lastpos = vec()
        tracked=nil
        self.start_timer = self.race_mode == MODE_RACE
        self.record_replay = nil
        self.play_replay_step = 1

        -- spawn cars

        self.cars = {}
        self.ranks = {}
        self.pits = {}
        best_seg_times = {}
        best_lap_time = nil
        best_lap_driver = nil
        if self.race_mode == MODE_TIME_ATTACK and self.play_replay then
            local replay_car = create_car(self)
            table.insert(self.cars, replay_car)
            replay_car.color = 1
            self.replay_car = replay_car
        end

        local p = create_car(self)
        table.insert(self.cars, p)
        self.player = p
        cam_car=p
        p.is_player = true
        local v = get_data_from_vecmap(p.current_segment)
        p.pos = vecadd(vecadd(p.pos, scalev(v.side, 14)), scalev(v.front, -6))
        p.angle = v.dir
        p.rank = 1
        p.gear = 0
        p.maxacc = p.maxacc
        p.mass = p.mass + FUEL_MASS_PER_KM * self.lap_count
        camera_angle = v.dir
        p.driver = {
            name = "Player",
            short_name = "PLA",
            is_best = false,
            team = find_team_id("Ferrero"),
            helmet = 0
        }
        table.insert(self.ranks, p)
        p.perf = TEAMS[p.driver.team].perf
        snd.play_note(9, 440, v.tribune, v.tribune, 2)

        if self.race_mode == MODE_RACE then
            for i = 1, #DRIVERS do
                local ai_car = create_car(self)
                ai_car.maxacc = ai_car.maxacc - CARS[intro.car].player_adv
                ai_car.mass = ai_car.mass + FUEL_MASS_PER_KM * self.lap_count
                ai_car.current_segment = -1 - i // 2
                ai_car.driver = DRIVERS[i]
                ai_car.color = TEAMS[ai_car.driver.team].color
                ai_car.color2 = TEAMS[ai_car.driver.team].color2
                ai_car.perf = TEAMS[ai_car.driver.team].perf
                ai_car.driver.is_best = false
                local v = get_data_from_vecmap(ai_car.current_segment)
                ai_car.pos = vecadd(vecadd(v, scalev(v.side, i % 2 == 0 and 14 or -14)), scalev(v.front, -6))
                if i % 2 == 1 then
                    ai_car.pos = vecadd(ai_car.pos, scalev(v.front, -14))
                end
                ai_car.angle = v.dir
                local oldupdate = ai_car.update
                ai_car.ai = ai_controls(ai_car)
                ai_car.ai.skill = ai_car.driver.skill
                function ai_car:update(completed, time)
                    self.ai:update()
                    oldupdate(self, completed, time)
                end

                table.insert(self.cars, ai_car)
                table.insert(self.ranks, ai_car)
            end
        end
    end

    function race:draw_tribune(li_rail, side, front, dir, flipflop)
        local p = vecadd(li_rail, scalev(side, 8))
        local p2 = vecadd(p, scalev(side, 10))
        local p3 = vecadd(p, scalev(front, -32))
        local p4 = vecadd(p2, scalev(front, -32))
        quadfill(p, p2, p3, p4, 22)
        local p2s = vecadd(vecadd(p, scalev(side, 5)), scalev(front, -16))
        gblit(224, 0, 20, 60, p2s, 33, dir)
        p = vecadd(p, scalev(side, 50))
        p3 = vecadd(p3, scalev(side, 50))
        gfx.set_active_layer(LAYER_TOP)
        quadfill(p, p2, p3, p4, flipflop and 20 or 4)
        gfx.set_active_layer(LAYER_SHADOW2)
        local sd = SHADOW_DELTA
        p = vecadd(p, sd)
        p2 = vecadd(p2, sd)
        p3 = vecadd(p3, sd)
        p4 = vecadd(p4, sd)
        quadfill(p, p2, p3, p4, 22)
        gfx.set_active_layer(0)
    end

    function race:draw_tribune2(li_rail, side, front, dir)
        local p = vecadd(li_rail, scalev(side, 8))
        local p2 = vecadd(p, scalev(side, 40))
        local p3 = vecadd(p, scalev(front, -32))
        local p4 = vecadd(p2, scalev(front, -32))
        gfx.set_active_layer(LAYER_CARS)
        quadfill(p, p2, p3, p4, 22)
        gfx.set_active_layer(LAYER_SHADOW)
        p2 = vecadd(p2, SHADOW_DELTA)
        p4 = vecadd(p4, SHADOW_DELTA)
        quadfill(p, p2, p3, p4, 22)
        gfx.set_active_layer(LAYER_TOP)
        local p2s = vecadd(vecadd(p, scalev(side, 5)), scalev(front, -16))
        gblit(244, 0, 20, 60, p2s, 33, dir)
        local p2s = vecadd(vecadd(p, scalev(side, 15)), scalev(front, -16))
        gblit(264, 0, 20, 60, p2s, 33, dir)
        local p2s = vecadd(vecadd(p, scalev(side, 25)), scalev(front, -16))
        gblit(244, 0, 20, 60, p2s, 33, dir)
        local p2s = vecadd(vecadd(p, scalev(side, 35)), scalev(front, -16))
        gblit(264, 0, 20, 60, p2s, 33, dir)
        gfx.set_active_layer(LAYER_SHADOW2)
        local sd = scalev(SHADOW_DELTA, 0.1)
        local p2s = vecadd(vecadd(vecadd(p, scalev(side, 5)), scalev(front, -16)), sd)
        gblit_col(244, 0, 20, 60, p2s, SHADOW_COL, dir)
        local p2s = vecadd(vecadd(vecadd(p, scalev(side, 15)), scalev(front, -16)), sd)
        gblit_col(264, 0, 20, 60, p2s, SHADOW_COL, dir)
        local p2s = vecadd(vecadd(vecadd(p, scalev(side, 25)), scalev(front, -16)), sd)
        gblit_col(244, 0, 20, 60, p2s, SHADOW_COL, dir)
        local p2s = vecadd(vecadd(vecadd(p, scalev(side, 35)), scalev(front, -16)), sd)
        gblit_col(264, 0, 20, 60, p2s, SHADOW_COL, dir)
        gfx.set_active_layer(0)
    end

    function race:draw_tree(trees, li_rail, last_li_rail, side, last_side, front, dir)
        local p = vecadd(li_rail, side)
        local p2 = vecadd(last_li_rail, last_side)
        local p3 = vecadd(p, scalev(side, 56))
        local p4 = vecadd(p2, scalev(last_side, 56))
        quadfill(p, p2, p3, p4, 27)
        gfx.set_active_layer(LAYER_TOP)
        for i = 1, #trees do
            local typ = trees[i].typ
            local tree_pos = trees[i].p
            local p = vecsub(vecsub(li_rail, scalev(side, tree_pos.x)), scalev(front, tree_pos.y))
            if typ == 1 then
                gblit(224, 60, 20, 20, p, 33, dir)
            elseif typ == 2 then
                gblit(224, 80, 30, 30, p, 33, dir)
            elseif typ == 3 then
                gblit(224, 110, 40, 40, p, 33, dir)
            end
        end
        gfx.set_active_layer(LAYER_SHADOW2)
        for i = 1, #trees do
            local typ = trees[i].typ
            local tree_pos = trees[i].p
            local p = vecadd(vecsub(vecsub(li_rail, scalev(side, tree_pos.x)), scalev(front, tree_pos.y)), SHADOW_DELTA)
            if typ == 1 then
                gblit_col(224, 60, 20, 20, p, SHADOW_COL, dir)
            elseif typ == 2 then
                gblit_col(224, 80, 30, 30, p, SHADOW_COL, dir)
            elseif typ == 3 then
                gblit_col(224, 110, 40, 40, p, SHADOW_COL, dir)
            end
        end
        gfx.set_active_layer(0)
    end

    function race:draw_pit(ri_rail, side, front, flipflop, seg, dir)
        local p = vecsub(ri_rail, scalev(side, 24))
        local p2 = vecsub(p, scalev(side, 8))
        local p3 = vecadd(p, scalev(front, -33))
        local p4 = vecadd(p2, scalev(front, -33))
        linevec(p, p3, 10)
        local perp = scalev(side, -4)
        p = vecadd(p2, perp)
        p3 = vecadd(p4, perp)
        quadfill(p2, p4, p, p3, flipflop and 7 or 28)
        perp = scalev(perp, 4)
        p2 = vecadd(p, perp)
        p4 = vecadd(p3, perp)
        perp = scalev(perp, 0.125)
        local perp2 = scalev(front, -6)
        quadfill(p, p3, p2, p4, 22)
        local lp = vecadd(vecadd(p, perp), perp2)
        local lp2 = vecadd(vecsub(p2, perp), perp2)
        perp2 = scalev(front, -2)
        local lp3 = vecadd(lp, perp2)
        local lp4 = vecadd(lp2, perp2)
        linevec(lp, lp3, 7)
        linevec(lp, lp2, 7)
        linevec(lp2, lp4, 7)
        gfx.set_active_layer(LAYER_TOP)
        perp = scalev(side, -32)
        p = vecadd(p2, perp)
        p3 = vecadd(p4, perp)
        quadfill(p, p3, p2, p4, 13)
        local team=(wrap(seg,mapsize)-self.first_pit)//2+1
        if self.pits[team] and not flipflop then
            self:draw_pit_crew(ri_rail,side,front,team,dir)
        end
        gfx.set_active_layer(LAYER_SHADOW2)
        p = vecsub(p, SHADOW_DELTA)
        p2 = vecsub(p2, SHADOW_DELTA)
        p3 = vecsub(p3, SHADOW_DELTA)
        p4 = vecsub(p4, SHADOW_DELTA)
        quadfill(p, p3, p2, p4, 22)
        gfx.set_active_layer(0)
    end

    function race:draw_pitline(ri_rail, side, front)
        local p = vecsub(ri_rail, scalev(side, 24))
        local p2 = vecsub(p, scalev(side, 32))
        local p3 = vecadd(p, scalev(front, -33))
        local p4 = vecadd(p2, scalev(front, -33))
        quadfill(p2, p4, p, p3, 27)
        self:draw_rail(p, p3)
    end

    function race:draw_pitline_start(ri_rail, side, front)
        local p = vecsub(ri_rail, scalev(side, 24))
        local p2 = vecsub(p, scalev(side, 32))
        local p3 = vecadd(p, scalev(front, -33))
        local p4 = vecadd(p2, scalev(front, -33))
        trifill(p, p2, p4, 27)
        linevec(p, p3, 10)
        self:draw_rail(p, p4)
    end

    function race:draw_pitline_end(ri_rail, side, front)
        local p = vecsub(ri_rail, scalev(side, 24))
        local p2 = vecsub(p, scalev(side, 32))
        local p3 = vecadd(p, scalev(front, -33))
        local p4 = vecadd(p2, scalev(front, -33))
        trifill(p2, p3, p4, 27)
        linevec(p, p3, 10)
        self:draw_rail(p2, p3)
    end

    function race:draw_pit_entry(ri_rail, side, front, seg)
        local p = vecsub(ri_rail, scalev(side, 4 + 7 * (seg + 1)))
        local p2 = vecsub(vecadd(ri_rail, scalev(front, -33)), scalev(side, 4 + 7 * seg))
        local p3 = vecsub(ri_rail, scalev(side, 56))
        local p4 = vecadd(p3, scalev(front, -33))
        quadfill(p, p2, p3, p4, 27)
        self:draw_rail(p, p2)
    end

    function race:draw_pit_exit(ri_rail, side, front, seg)
        local p = vecsub(ri_rail, scalev(side, 4 + 7 * (2 - seg)))
        local p2 = vecsub(vecadd(ri_rail, scalev(front, -33)), scalev(side, 4 + 7 * (3 - seg)))
        local p3 = vecsub(ri_rail, scalev(side, 56))
        local p4 = vecadd(p3, scalev(front, -33))
        quadfill(p, p2, p3, p4, 27)
        self:draw_rail(p, p2)
    end

    function race:draw_pit_crew(ri_rail, side, front, team, dir)
        local c1=TEAMS[team].color
        local c2=TEAMS[team].color2
        local p=vecsub(vecsub(ri_rail, scalev(side, 44)),scalev(front,10))
        gblit(323,224,22,26,p,c1,dir)
        gblit(345,224,22,26,p,33,dir)
        gblit(323,250,22,26,p,c2,dir)
    end

    function race:draw_rail(p1, p2)
        local side = perpendicular(normalize(vecsub(p2, p1)))
        local p3 = vecadd(p1, side)
        local p4 = vecadd(p2, side)
        quadfill(p1, p2, p3, p4, 22)
        gfx.set_active_layer(LAYER_SHADOW)
        local sd = scalev(SHADOW_DELTA, 0.5)
        quadfill(p3, p4, vecadd(p3, sd), vecadd(p4, sd), 22)
        gfx.set_active_layer(0)
    end

    function race:update()
        frame = frame + 1
        if sc1timer > 0 then
            sc1timer = sc1timer - 1
        end
        if self.best_lap_timer >= 0 then
            self.best_lap_timer = self.best_lap_timer - 1
        end

        if self.completed then
            self.completed_countdown = self.completed_countdown - DT
            if self.completed_countdown < 4 and (inp_menu_pressed() or self.live_cars == 0) then
                set_game_mode(completed_menu(self))
                return
            end
        elseif inp_menu_pressed() then
            snd.stop_channel(1)
            self.player.freq=nil
            snd.stop_channel(2)
            set_game_mode(paused_menu(self))
            return
        end

        -- enter input
        local player = self.player
        if player then
            local controls = player.controls
            if self.completed then
                controls.left = false
                controls.right = false
                controls.boost = false
                controls.brake = true
                controls.accel = false
            else
                controls.left = inp.left() > 0.1
                controls.right = inp.right() > 0.1
                controls.boost = false --inp_boost()
                controls.accel = inp_accel()
                controls.brake = inp_brake()
            end
            if player.pit then
                if inp.up_pressed() then
                    self.tyre = (self.tyre + 1) % 5
                elseif inp.down_pressed() then
                    self.tyre = (self.tyre + 4) % 5
                end
            elseif self.race_mode ~= MODE_EDITOR then
                if inp.up_pressed() then
                    panel = (panel-2+#panels) % #panels + 1
                elseif inp.down_pressed() then
                    panel = (panel % #panels) + 1
                end
            end
        end

        -- replay playback
        local replay = self.play_replay
        if replay and self.replay_car then
            if self.play_replay_step == 1 then
                self.replay_car.pos = replay[1].pos
                self.replay_car.angle = replay[1].angle
                self.play_replay_step = 2
            end
            if self.start_timer then
                if self.play_replay_step == 2 then
                    local rc = self.replay_car
                    rc.vel = replay[1].vel
                    rc.accel = replay[1].accel
                    rc.boost = replay[1].boost
                end
                local v = replay[self.play_replay_step]
                if v then
                    local c = self.replay_car.controls
                    c.left = (v & 1) ~= 0
                    c.right = (v & 2) ~= 0
                    c.accel = (v & 4) ~= 0
                    c.brake = (v & 8) ~= 0
                    c.boost = (v & 16) ~= 0
                    self.play_replay_step = self.play_replay_step + 1
                end
            end
        end

        if player.current_segment == 0 and not self.start_timer and self.race_mode == MODE_TIME_ATTACK then
            self.start_timer = true
            self.record_replay = {}
            table.insert(self.record_replay, {
                pos = copyv(player.pos),
                vel = copyv(player.vel),
                angle = player.angle,
                accel = player.accel,
                boost = player.boost
            })
        end
        if self.start_timer then
            local before = flr(self.time)
            self.time = self.time + DT
            if self.time < 0 then
                camera_scale = ease_in_out_cubic(4 + self.time, 0.6, 0.5, 4.0)
            else
                camera_scale = 1
            end
            if self.time < 1.0 then
                local after = flr(self.time)
                if after ~= before then
                    sfx(after == 0 and 11 or 10)
                end
            end
        end

        if self.panel_timer >= 0 then
            self.panel_timer = self.panel_timer - 1
        end

        -- record replay
        if self.record_replay then
            local c = player.controls
            local v = (c.left and 1 or 0) + (c.right and 2 or 0) + (c.accel and 4 or 0) + (c.brake and 8 or 0) +
                (c.boost and 16 or 0)
            table.insert(self.record_replay, v)
        end

        if self.race_mode == MODE_TIME_ATTACK or self.time > 0 then
            for i=1,#self.cars do
                self.cars[i]:update(self.completed, self.time)
            end
        end
        if self.race_mode == MODE_TIME_ATTACK and player.current_segment % mapsize == 0 and self.time > 20 then
            self.time = 0
        end
        -- car to car collision
        for i=1,#self.cars do
            local obj=self.cars[i]
            for j=1,#self.cars do
                local obj2=self.cars[j]
                if obj ~= obj2 and obj ~= self.replay_car and obj2 ~= self.replay_car then
                    if abs(car_lap_seg(obj.current_segment, obj2) - obj2.current_segment) <= 1 then
                        local p1 = { obj.verts[1], obj.verts[2], obj.verts[3] }
                        local p2 = { obj2.verts[1], obj2.verts[2], obj2.verts[3] }
                        for i=1,#p1 do
                            local point=p1[i]
                            if point_in_polygon(p2, point) then
                                local rv, p, point = check_collision(p1,
                                    { { p2[2], p2[1] }, { p2[3], p2[2] }, { p2[1], p2[3] } })
                                if rv then
                                    if p > 5 then
                                        p = 5
                                    end
                                    p = p * COLLISION_COEF
                                    obj.vel = vecadd(obj.vel, scalev(rv, p))
                                    obj2.vel = vecsub(obj2.vel, scalev(rv, p))
                                    create_spark(obj.current_segment, point, rv, false)
                                    obj.collision = obj.collision + flr(p)
                                    obj2.collision = obj2.collision + flr(p)
                                    if obj.is_player or obj2.is_player then
                                        if p > 2 then
                                            sfx(38)
                                            sc1 = 38
                                        else
                                            sfx(40)
                                            sc1 = 40
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        if not self.completed and self.race_mode == MODE_RACE and player.race_finished then
            -- completed
            snd.stop_channel(1)
            self.player.freq=nil
            snd.stop_channel(2)
            self.completed = true
            self.completed_countdown = 5
        end

        -- particles
        for i=1,#particles do
            local p=particles[i]
            if p.enabled then
                if abs(car_lap_seg(p.seg, cam_car) - cam_car.current_segment) > 10 then
                    p.enabled = false
                else
                    p.x = p.x + p.xv
                    p.y = p.y + p.yv
                    p.xv = p.xv * 0.95
                    p.yv = p.yv * 0.95
                    p.ttl = p.ttl - 1
                    if p.ttl < 0 then
                        p.enabled = false
                    end
                end
            end
        end
        for i=1,#smokes do
            local p=smokes[i]
            if p.enabled then
                if abs(car_lap_seg(p.seg, cam_car) - cam_car.current_segment) > 10 then
                    p.enabled = false
                else
                    p.x = p.x + p.xv
                    p.y = p.y + p.yv
                    p.xv = p.xv * 0.95
                    p.yv = p.yv * 0.95
                    p.ttl = p.ttl - 1
                    if p.ttl < 0 then
                        p.enabled = false
                    end
                end
            end
        end
        -- lerp_angle
        local diff = wrap(cam_car.angle - camera_angle, 1)
        local dist = wrap(2 * diff, 1) - diff
        camera_angle = camera_angle + dist * 0.05

        -- car times
        if frame % 100 == 0 then
            table.sort(self.ranks, function(car, car2)
                local seg = car.race_finished and #car.lap_times * mapsize or car.current_segment
                local seg2 = car2.race_finished and #car2.lap_times * mapsize or car2.current_segment
                if seg > seg2 then
                    return true
                end
                if seg < seg2 then
                    return false
                end
                if car.race_finished then
                    return car.delta_time < car2.delta_time
                end
                return false
            end)
            t = self.time
            local leader = self.ranks[1]
            local leader_seg = leader.race_finished and #leader.lap_times * mapsize or leader.current_segment
            self.live_cars = 16
            for i=1,#self.cars do
                local car=self.cars[i]
                if car.race_finished then
                    self.live_cars = self.live_cars - 1
                else
                    local lap_behind = ceil((car.current_segment - leader_seg) / mapsize)
                    car.time = lap_behind < 0 and lap_behind .. " laps"
                        or (best_seg_times[car.current_segment] and "+" .. format_time(t - best_seg_times[car.current_segment])
                        or "-----")
                end
            end
        end
        if self.panel_timer < 0 and player.current_segment > 0 and player.current_segment % mapsize == 0 and self.race_mode == MODE_RACE then
            self.panel_timer = 200
            local placing = 1
            local nplaces = 1
            for i=1,#self.cars do
                local obj=self.cars[i]
                if obj ~= player then
                    nplaces = nplaces + 1
                    if obj.current_segment > player.current_segment then
                        placing = placing + 1
                    end
                end
            end
            self.panel_placing = placing
            if placing > 1 then
                local prev = self.ranks[placing - 1]
                self.panel_prev = prev
                self.panel_prev_time = "-" .. format_time(self.time - prev.seg_times[player.current_segment])
            end
            if placing < 16 then
                local next = self.ranks[placing + 1]
                self.panel_next = next
                self.panel_next_time = "+" .. format_time(self.time - player.seg_times[next.current_segment])
            end
        end
        if self.time >= 0 then
            local target = 1.5 - 0.8 * (self.player.speed / 23)
            camera_scale = camera_scale + (target - camera_scale) * 0.2
        end
        if inp.key_pressed(inp.KEY_PAGEUP) then
            if tracked==nil then
                tracked=1
            else
                tracked=(tracked-2+#self.ranks) % #self.ranks +1
            end
            cam_car = self.ranks[tracked]
        elseif inp.key_pressed(inp.KEY_PAGEDOWN) then
            if tracked==nil then
                tracked=#self.ranks
            else
                tracked=(tracked%#self.ranks) + 1
            end
            cam_car = self.ranks[tracked]
        elseif inp.key_pressed(inp.KEY_HOME) then
            tracked=nil -- go back to tracking the player
            cam_car = self.player
        end
    end

    function race:draw()
        local player = self.player
        local time = self.time
        gfx.set_active_layer(0)
        cls()
        local tp = cbufget(player.trails, player.trails._size - 8) or player.pos
        local trail = clampv(vecsub(player.pos, tp), 34)
        if self.race_mode ~= MODE_EDITOR then
            local camera_pos = vecadd(cam_car.pos, trail)
            if cam_car.collision > 0 then
                camera(camera_pos.x + rnd(3) - 2, camera_pos.y + rnd(3) - 2)
            else
                local c = lerpv(camera_lastpos, camera_pos, 1)
                camera(c.x, c.y)
            end

            camera_lastpos = copyv(camera_pos)
        end
        local current_segment = cam_car.current_segment
        local player_sec = get_data_from_vecmap(current_segment).section
        -- draw track

        local lastv, lastup, lastup2, lastup3, last_right_rail, lastdown, lastdown3, last_left_rail
        local panels = {}
        local minseg, maxseg, has_lrail, has_rrail
        for seg = current_segment - 20, current_segment + 20 do
            local v = get_data_from_vecmap(seg)
            local nextv = get_data_from_vecmap(seg + 1)
            if has_rrail and lastv then
                if (v.rtyp // 8 >= OBJ_PIT_ENTRY1 and v.rtyp // 8 <= OBJ_PIT_ENTRY2) or nextv.rtyp // 8 >= OBJ_PIT_EXIT1 then
                    last_right_rail = nil
                else
                    last_right_rail = lastv.right_outer_rail
                end
            end
            if has_lrail and lastv then
                if (v.ltyp // 8 >= OBJ_PIT_ENTRY1 and v.ltyp // 8 <= OBJ_PIT_ENTRY2) or nextv.ltyp // 8 >= OBJ_PIT_EXIT1 then
                    last_left_rail = nil
                else
                    last_left_rail = lastv.left_outer_rail
                end
            end
            has_lrail = v.has_lrail
            has_rrail = v.has_rrail

            if lastv then
                if onscreen(v) or onscreen(lastv) or onscreen(v.right_inner_rail) or onscreen(v.left_inner_rail)
                    or onscreen(lastv.right_inner_rail) or onscreen(lastv.left_inner_rail) then
                    local ltyp = v.ltyp & 7
                    local rtyp = v.rtyp & 7
                    local rtrack = v.right_track
                    local ltrack = v.left_track
                    local last_rtrack = lastv.right_track
                    local last_ltrack = lastv.left_track
                    local ri_rail = v.right_inner_rail
                    local li_rail = v.left_inner_rail
                    local last_ri_rail = lastv.right_inner_rail
                    local last_li_rail = lastv.left_inner_rail
                    local last_rtyp = lastv.rtyp & 7
                    local last_ltyp = lastv.ltyp & 7
                    -- edges
                    if rtyp == 1 or rtyp == 0 and last_rtyp == 1 then
                        -- grass
                        quadfill(last_rtrack, rtrack, last_ri_rail, ri_rail, 27)
                    elseif rtyp == 2 or rtyp == 0 and last_rtyp == 2 then
                        -- sand
                        quadfill(last_rtrack, rtrack, last_ri_rail, ri_rail, 15)
                    elseif rtyp == 3 or rtyp == 0 and last_rtyp == 3 then
                        -- asphalt
                        quadfill(last_rtrack, rtrack, last_ri_rail, ri_rail, 5)
                    end
                    if ltyp == 1 or ltyp == 0 and last_ltyp == 1 then
                        -- grass
                        quadfill(last_ltrack, ltrack, last_li_rail, li_rail, 27)
                    elseif ltyp == 2 or ltyp == 0 and last_ltyp == 2 then
                        -- sand
                        quadfill(last_ltrack, ltrack, last_li_rail, li_rail, 15)
                    elseif ltyp == 3 or ltyp == 0 and last_ltyp == 3 then
                        -- asphalt
                        quadfill(last_ltrack, ltrack, last_li_rail, li_rail, 5)
                    end
                    -- ground
                    local ground = seg % 2 == 0 and 5 or 32
                    quadfill(lastv.right_kerb, lastv.left_kerb, v.right_kerb, v.left_kerb, ground)
                    -- kerbs
                    if v.has_lkerb or lastv.has_lkerb then
                        if v.has_lkerb == 1 or lastv.has_lkerb == 1 then
                            local midleft = midpoint(ltrack, last_ltrack)
                            local midleft_kerb = midpoint(v.left_kerb, lastv.left_kerb)
                            quadfill(v.left_kerb, ltrack, midleft_kerb, midleft, 7)
                            quadfill(last_ltrack, midleft, lastv.left_kerb, midleft_kerb, 8)
                        else
                            quadfill(v.left_kerb, ltrack, lastv.left_kerb, last_ltrack, seg % 2 == 0 and 7 or 8)
                        end
                    end
                    if v.has_rkerb or lastv.has_rkerb then
                        if v.has_rkerb == 1 or lastv.has_rkerb == 1 then
                            local midright = midpoint(rtrack, last_rtrack)
                            local midright_kerb = midpoint(v.right_kerb, lastv.right_kerb)
                            quadfill(v.right_kerb, rtrack, midright_kerb, midright, 7)
                            quadfill(midright_kerb, midright, lastv.right_kerb, last_rtrack, 8)
                        else
                            quadfill(v.right_kerb, rtrack, lastv.right_kerb, last_rtrack, seg % 2 == 0 and 7 or 8)
                        end
                    end
                    if rtyp == 0 and v.rtyp // 8 < OBJ_PIT_ENTRY1 then
                        -- normal crash barriers
                        linevec(last_rtrack, rtrack, 6)
                    end
                    if ltyp == 0 and v.ltyp // 8 < OBJ_PIT_ENTRY1 then
                        -- normal crash barriers
                        linevec(last_ltrack, ltrack, 6)
                    end
                    if ltyp ~= 0 then
                        linevec(last_ltrack, ltrack, 10)
                    end
                    if rtyp ~= 0 then
                        linevec(last_rtrack, rtrack, 10)
                    end
                    if has_rrail and last_right_rail then
                        self:draw_rail(last_right_rail, v.right_outer_rail)
                    end
                    if has_lrail and last_left_rail then
                        self:draw_rail(last_left_rail, v.left_outer_rail)
                    end
                    -- starting line
                    if seg % mapsize == 0 then
                        p = cam2screen(vecadd(v, scalev(v.front, -6)))
                        gfx.blit(162, 254, 110, 6, p.x, p.y, 255, 255, 255,
                            from_pico_angle(camera_angle - v.dir), 110 * camera_scale, 6 * camera_scale)
                    end
                    -- starting grid
                    local wseg = wrap(seg, mapsize)
                    if wseg > mapsize - #DRIVERS // 2 - 2 then
                        local side = scalev(v.side, 12)
                        local smallfront = scalev(v.front, -12)
                        local lfront = scalev(v.front, 31)
                        local p = vecadd(vecsub(lastv.left_kerb, side), lfront)
                        local p2 = vecsub(p, side)
                        linevec(p, p2, 7)
                        linevec(p, vecadd(p, smallfront), 7)
                        linevec(p2, vecadd(p2, smallfront), 7)
                        lfront = scalev(v.front, 17)
                        p = vecadd(vecadd(lastv.right_kerb, side), lfront)
                        p2 = vecadd(p, side)
                        linevec(p, p2, 7)
                        linevec(p, vecadd(p, smallfront), 7)
                        linevec(p2, vecadd(p2, smallfront), 7)
                    end
                    -- track side objects
                    local lobj = v.ltyp // 8
                    local robj = v.rtyp // 8
                    if lobj == OBJ_TRIBUNE then
                        self:draw_tribune(li_rail, v.side, v.front, v.dir, seg % 2 == 0)
                    elseif lobj == OBJ_TRIBUNE2 then
                        self:draw_tribune2(li_rail, v.side, v.front, v.dir)
                    elseif lobj == OBJ_TREE then
                        self:draw_tree(v.ltrees, li_rail, lastv.left_inner_rail, v.side, lastv.side, v.front, v.dir)
                    elseif lobj == OBJ_BRIDGE then
                        gfx.set_active_layer(LAYER_TOP)
                        gblit(141, 224, 182, 30, v, 33, v.dir)
                        gfx.set_active_layer(LAYER_SHADOW2)
                        local p = vecadd(v, SHADOW_DELTA)
                        gblit_col(141, 224, 182, 30, p, SHADOW_COL, v.dir)
                        gfx.set_active_layer(0)
                    elseif lobj == OBJ_BRIDGE2 then
                        local p2 = vecadd(v, scalev(v.side, -48))
                        gblit(141, 224, 8, 30, p2, 33, v.dir)
                        local p3 = vecadd(v, scalev(v.side, 48))
                        gblit(315, 224, 8, 30, p3, 33, v.dir)
                        gfx.set_active_layer(LAYER_TOP)
                        gblit(141, 260, 182, 11, v, 33, v.dir)
                        gfx.set_active_layer(LAYER_SHADOW2)
                        local p = vecadd(v, SHADOW_DELTA)
                        p2 = vecadd(p2, SHADOW_DELTA)
                        p3 = vecadd(p3, SHADOW_DELTA)
                        gblit_col(141, 260, 182, 11, p, SHADOW_COL, v.dir)
                        gblit_col(141, 224, 8, 30, p2, SHADOW_COL, v.dir)
                        gblit_col(315, 224, 8, 30, p3, SHADOW_COL, v.dir)
                        gfx.set_active_layer(0)
                    elseif lobj == OBJ_PIT then
                        self:draw_pit(li_rail, vecinv(v.side), v.front, seg % 2 == 0, seg, v.dir)
                    elseif lobj == OBJ_PIT_LINE then
                        self:draw_pitline(li_rail, vecinv(v.side), v.front)
                    elseif lobj == OBJ_PIT_LINE_START then
                        self:draw_pitline_start(li_rail, vecinv(v.side), v.front)
                    elseif lobj == OBJ_PIT_LINE_END then
                        self:draw_pitline_end(li_rail, vecinv(v.side), v.front)
                    end
                    if robj == OBJ_TRIBUNE then
                        self:draw_tribune(ri_rail, vecinv(v.side), v.front, v.dir, seg % 2 == 0)
                    elseif robj == OBJ_TRIBUNE2 then
                        self:draw_tribune2(ri_rail, vecinv(v.side), v.front, v.dir)
                    elseif robj == OBJ_TREE then
                        self:draw_tree(v.rtrees, ri_rail, lastv.right_inner_rail, vecinv(v.side), vecinv(lastv.side),
                            v.front, v.dir)
                    elseif robj == OBJ_PIT then
                        self:draw_pit(ri_rail, v.side, v.front, seg % 2 == 0, seg, v.dir)
                    elseif robj == OBJ_PIT_LINE then
                        self:draw_pitline(ri_rail, v.side, v.front)
                    elseif robj == OBJ_PIT_LINE_START then
                        self:draw_pitline_start(ri_rail, v.side, v.front)
                    elseif robj == OBJ_PIT_LINE_END then
                        self:draw_pitline_end(ri_rail, v.side, v.front)
                    elseif robj >= OBJ_PIT_ENTRY1 and robj <= OBJ_PIT_ENTRY3 then
                        self:draw_pit_entry(ri_rail, v.side, v.front, robj - OBJ_PIT_ENTRY1)
                    elseif robj >= OBJ_PIT_EXIT1 and robj <= OBJ_PIT_EXIT3 then
                        self:draw_pit_exit(ri_rail, v.side, v.front, robj - OBJ_PIT_EXIT1)
                    end

                    if v.lpanel ~= nil then
                        local p = v.left_inner_rail
                        local y = 214 + 10 * v.lpanel
                        panels[#panels + 1] = { y = y, p = p, dir = v.dir }
                    elseif v.rpanel ~= nil then
                        local p = v.right_inner_rail
                        local y = 214 + 10 * v.rpanel
                        panels[#panels + 1] = { y = y, p = p, dir = v.dir }
                    end
                    if self.race_mode == MODE_EDITOR and v.section == player_sec then
                        -- highlight current section in map editor
                        gfx.set_active_layer(LAYER_TOP)
                        linevec(lastv.right_kerb, lastv.left_kerb, 10)
                        linevec(v.right_kerb, v.left_kerb, 10)
                        linevec(lastv.right_kerb, v.right_kerb, 10)
                        linevec(lastv.left_kerb, v.left_kerb, 10)
                        gfx.set_active_layer(0)
                        minseg = minseg and min(minseg, seg) or seg
                        maxseg = maxseg and max(maxseg, seg) or seg
                    end
                end
            end
            lastv = v
        end

        for i = 1, #panels do
            local p = panels[i]
            gblit(91, p.y, 24, 10, p.p, 33, p.dir)
        end
        -- draw cars
        gfx.set_active_layer(LAYER_CARS)
        for i=1,#self.cars do
            local obj=self.cars[i]
            local oseg = car_lap_seg(obj.current_segment, cam_car)
            if abs(oseg - cam_car.current_segment) < 10 then
                obj:draw()
            end
        end

        for i=1,#particles do
            local p=particles[i]
            if p.enabled then
                p:draw()
            end
        end
        gfx.set_active_layer(LAYER_SMOKE)
        gfx.clear()
        if not self.completed then
            for i=1,#smokes do
                local p=smokes[i]
                if p.enabled then
                    p:draw()
                end
            end
        end

        -- DEBUG : display segments collision shapes
        -- seg=get_segment(cam_car.current_segment-1,false,true)
        -- quadfill(seg[1],seg[2],seg[4],seg[3],11)
        -- local seg=get_segment(cam_car.current_segment+1,false,true)
        -- quadfill(seg[1],seg[2],seg[4],seg[3],12)
        -- local seg=get_segment(cam_car.current_segment,false,true)
        -- quadfill(seg[1],seg[2],seg[4],seg[3],8)
        gfx.set_active_layer(LAYER_TOP)
        -- draw_minimap
        if not self.completed then
            local lastv = nil
            for seg = current_segment + MINIMAP_START, current_segment + MINIMAP_END do
                local v = get_vec_from_vecmap(seg)
                if lastv ~= nil then
                    minimap_line(lastv, v, 7)
                end
                lastv = v
            end
            for i=1,#self.cars do
                self.cars[i]:draw_minimap(cam_car)
            end
        end

        local lap = flr(player.current_segment / mapsize) + 1
        printr(gfx.fps() .. " fps", gfx.SCREEN_WIDTH - 1, 1, 7)

        -- car dashboard
        local tyre_col={}
        local tyre_wear={}
        if not self.completed and self.race_mode ~= MODE_EDITOR then
            local x=gfx.SCREEN_WIDTH-66
            local y=gfx.SCREEN_HEIGHT-35
            gfx.blit(0, 224, 66, 35, x, y)
            -- speed indicator
            printc("" .. flr(player.speed * 14), 370, 210, 28)
            -- gear
            printc(player.gear == 0 and "N" or ""..player.gear, gfx.SCREEN_WIDTH-32,gfx.SCREEN_HEIGHT-31,28)
            -- engine speed
            gfx.blit(66, 224, 25 * min(1, player.speed / 15), 8, gfx.SCREEN_WIDTH - 28, gfx.SCREEN_HEIGHT - 23)
            if player.freq then
                gfx.blit(66, 232, 19 * clamp(player.freq / 50,0,1), 9, gfx.SCREEN_WIDTH - 60, gfx.SCREEN_HEIGHT - 22)
            end
            -- car status
            -- front wing
            gfx.line(x+31,y+25,x+35,y+25, 0,228,54)
            -- rear wing
            gfx.line(x+31,y+33,x+35,y+33, 0,228,54)
            -- tires
            for i=1,4 do
                local tx = x + (i%2==1 and 30 or 35)
                local ty = y + (i < 3 and 27 or 30)
                local tr,tg,tb
                if player.tyre_wear[i] <= 0 then
                    local coef = -player.tyre_wear[i]/TYRE_HEAT[player.tyre_type]
                    tr=0
                    tg=228
                    tb=54+(201*coef)
                    table.insert(tyre_wear,100)
                else
                    local coef = player.tyre_wear[i] / TYRE_LIFE[player.tyre_type]
                    if coef <= 0.5 then
                        -- from green to orange
                        local ccoef=coef*2
                        tr=255*ccoef
                        tg=228 + (163-228)*ccoef
                        tb=54 -54*ccoef
                    elseif coef <= 1 then
                        -- from orange to red
                        local ccoef=(coef-0.5)*2
                        tr=255
                        tg=163-163*ccoef
                        tb=77*ccoef
                    else
                        -- above 1, blinking red
                        local black=frame%10 < 5
                        tr = black and 8 or 255
                        tg = black and 13 or 0
                        tb = black and 25 or 77
                    end
                    table.insert(tyre_wear,max(0,flr((1-coef)*100)))
                end
                gfx.line(tx,ty,tx,ty+2, tr,tg,tb)
                table.insert(tyre_col,{tr,tg,tb})
            end
            -- engine
            gfx.rectangle(x+32,y+30,2,2, 0,228,54)

            -- boost : TODO remove
            if player.cooldown > 0 then
                if frame % 4 < 2 then
                    gfx.blit(66, 249, 21 * (1 - player.cooldown / 30), 4, gfx.SCREEN_WIDTH - 61, gfx.SCREEN_HEIGHT - 11)
                end
            else
                local spritey = (player.boost < BOOST_WARNING_THRESH and frame % 4 < 2) and 245 or 241
                gfx.blit(66, spritey, 21 * (player.boost / 100), 4, gfx.SCREEN_WIDTH - 61, gfx.SCREEN_HEIGHT - 11)
            end
            if self.race_mode == MODE_RACE and self.panel_timer >= 0 then
                -- stand panel
                local x = gfx.SCREEN_WIDTH - 90
                local y = 50
                gfx.rectangle(x, y, 85, 44, 50, 50, 50)
                gprint("P" .. self.panel_placing, x + 3, y + 3, 10)
                if self.panel_placing > 1 then
                    gprint(self.panel_prev_time .. " " .. self.panel_prev.driver.short_name, x + 3, y + 13, 10)
                end
                if self.panel_placing < 16 then
                    gprint(self.panel_next_time .. " " .. self.panel_next.driver.short_name, x + 3, y + 23, 10)
                end
                gprint("Lap " .. lap, x + 3, y + 33, 10)
            end
            if player.ccut_timer >= 0 then
                local x = gfx.SCREEN_WIDTH - 92
                gfx.rectangle(x, 50, 90, 60, 50, 50, 50)
                printc("Warning!", x + 45, 53, 8)
                printc("Corner", x + 45, 63, 9)
                printc("cutting", x + 45, 73, 9)
                gfx.blit(115, 224, 26, 16, x + 45 - 13, 83)
            end
        end
        if self.race_mode == MODE_RACE and self.best_lap_timer >= 0 then
            local x = 200
            local y = 0
            gfx.rectangle(x, y, 100, 18, 50, 50, 50)
            printc("Best lap " .. best_lap_driver.short_name, x + 50, y + 1, 9)
            printc(format_time(best_lap_time), x + 50, y + 9, 9)
        end
        -- pit stop panel
        if player.pit then
            local x = gfx.SCREEN_WIDTH - 110
            gfx.rectangle(x, 50, 108, 75, 50, 50, 50)
            printc("Choose tyre", x + 55, 52, 7)
            gfx.blit(66, 8, 24, 12, x + 55 - 12, 62)
            local tx = self.tyre < 2 and 0 or self.tyre < 4 and 1 or 2
            gfx.blit(224, 192, 32, 32, x + 42, 76)
            gfx.blit(256 + tx * 27, 192, 27, 32, x + 38, 76)
            rect(x + 37, 75, 36, 34, 9)
            printc(TYRE_TYPE[self.tyre + 1], x + 55, 114, TYRE_COL[self.tyre + 1])
        elseif not self.completed and panel == PANEL_CAR_STATUS then
            local x = gfx.SCREEN_WIDTH - 66
            local y = 105
            gfx.rectangle(x, y, 66, 75, 50, 50, 50)
            gfx.blit(326,0,29,63,x+34-15,y+4)
            gfx.blit(355,14,7,9,x+34-15,y+13,tyre_col[1][1],tyre_col[1][2],tyre_col[1][3])
            gfx.blit(377,14,7,9,x+41,y+13,tyre_col[2][1],tyre_col[2][2],tyre_col[2][3])
            gfx.blit(356,48,6,8,x+34-14,y+52,tyre_col[3][1],tyre_col[3][2],tyre_col[3][3])
            gfx.blit(377,48,6,8,x+41,y+52,tyre_col[4][1],tyre_col[4][2],tyre_col[4][3])
            gfx.blit(362,55,15,8,x+34-8,y+58)
            gfx.blit(360,0,19,14,x+34-10,y+4)
            gfx.print(gfx.FONT_4X6, string.format("%3d%%",tyre_wear[1]),x+2,y+13,255,255,255)
            gfx.print(gfx.FONT_4X6, string.format("%3d%%",tyre_wear[2]),gfx.SCREEN_WIDTH -17,y+13,255,255,255)
            gfx.print(gfx.FONT_4X6, string.format("%3d%%",tyre_wear[3]),x+2,y+52,255,255,255)
            gfx.print(gfx.FONT_4X6, string.format("%3d%%",tyre_wear[4]),gfx.SCREEN_WIDTH -17,y+52,255,255,255)
        end

        -- ranking board
        local y = 1
        if not self.completed then
            if self.race_mode == MODE_RACE then
                gfx.rectangle(0, 0, 120, gfx.SCREEN_HEIGHT, PAL[17].r, PAL[17].g, PAL[17].b)
                gprint("Lap " .. lap .. '/' .. self.lap_count, 12, y, 9)
                gfx.line(0, y + 9, 120, y + 9, PAL[6].r, PAL[6].g, PAL[6].b)
                y = y + 11;
                local leader_time = format_time(time > 0 and time or 0)
                for rank, car in ipairs(self.ranks) do
                    gprint(string.format("%2d", rank), 4, y, car.is_player and 7 or 6)
                    gprint(car.driver.short_name, 32, y, car.is_player and 7 or 6)
                    gprint(string.format("%7s", rank == 1 and leader_time or car.time),
                        60, y, car.is_player and 7 or 6)
                    rectfill(21, y, 27, y + 8, car.color)
                    if car.race_finished then
                        gfx.blit(149, 0, 6, 8, 57, y)
                    end
                    y = y + 9
                end
                gfx.line(0, y, 120, y, PAL[6].r, PAL[6].g, PAL[6].b)
                y = y + 3
            elseif self.race_mode == MODE_TIME_ATTACK then
                gfx.rectangle(0, 0, 120, 100, PAL[17].r, PAL[17].g, PAL[17].b)
                gprint(string.format("%2d %6s", lap, format_time(time > 0 and time or 0)), 20, y, 9)
                y = y + 10
                for i = #player.lap_times, 1, -1 do
                    local t = player.lap_times[i]
                    if y > 73 then
                        break
                    end
                    gprint(string.format("%2d %6s", i, format_time(t)), 20, y, 9)
                    y = y + 10
                end
                if player.best_time then
                    gprint(string.format("Best %6s", format_time(player.best_time)), 4, y, 8)
                end
            end
        else
            -- race results
            gfx.rectangle(30, 10, gfx.SCREEN_WIDTH - 52, (#DRIVERS + 4) * 10, PAL[17].r, PAL[17].g, PAL[17].b)
            gprint("Classification          Time   Best", 61, 20, 6)
            gfx.line(30, 30, gfx.SCREEN_WIDTH - 22, 30, PAL[6].r, PAL[6].g, PAL[6].b)
            for rank, car in ipairs(self.ranks) do
                local y = 26 + rank * 10
                gprint(string.format("%2d %s %15s  %7s", rank, TEAMS[car.driver.team].short_name, car.driver.name,
                    rank == 1 and format_time(car.delta_time) or car.time),
                    53, y, car.is_player and 7 or 22)
                if car.best_time then
                    gprint(format_time(car.best_time), 309, y, car.driver.is_best and 8 or (car.is_player and 7 or 22))
                end
                rectfill(69, y - 1, 75, y + 7, car.color)
                if car.race_finished then
                    gfx.blit(149, 0, 6, 8, 233, y)
                end
            end
        end
        -- lap times
        if not self.completed and self.race_mode == MODE_RACE then
            if lap > 1 and player.lap_times[lap - 1] then
                local is_personal_best = player.lap_times[lap - 1] == player.best_time
                if lap > self.lap_count or time < player.lap_times[lap - 1] + 5 then
                    if lap > self.lap_count or frame % 10 > 2 then
                        gprint("Lap   " .. format_time(player.lap_times[lap - 1]), 4, y,
                            player.driver.is_best and 8 or (is_personal_best and 3 or 7))
                    end
                    y = y + 18
                else
                    gprint("Lap   " .. format_time(time > 0 and time - player.delta_time or 0), 4, y, 7)
                    y = y + 9
                    gprint("Prev  " .. format_time(player.lap_times[lap - 1]), 4, y,
                        player.lap_times[lap - 1] == best_lap_time and 8 or (is_personal_best and 3 or 7))
                    y = y + 9
                end
            else
                gprint("Lap   " .. format_time(time > 0 and time - player.delta_time or 0), 4, y, 7)
                y = y + 9
            end
            if player.best_time then
                gprint("PBest " .. format_time(player.best_time), 4, y, player.driver.is_best and 8 or 3)
                y = y + 9
            end
            if best_lap_time then
                gprint("RBest " .. format_time(best_lap_time), 4, y, 7)
                y = y + 9
                gprint(best_lap_driver.name, 4, y, 7)
            end
            if player.wrong_way > 4 then
                gprint("Wrong way!", 152, 104, 8)
            end
        end

        -- starting lights
        if time < 0 then
            local count = -flr(time)
            local lit = 4 - count
            for i = 1, lit do
                gfx.blit(34, 0, 20, 20, 217 + i * 22, 44)
            end
            for i = lit + 1, 3 do
                gfx.blit(14, 0, 20, 20, 217 + i * 22, 44)
            end
        end
        if player.collision > 0 or self.completed then
            player.collision = player.collision - 0.1
        end
        return minseg, maxseg
    end

    return race
end

function copyv(v)
    return vec(v.x, v.y)
end

function vec(x, y)
    return {
        x = x or 0,
        y = y or 0
    }
end

function rotate_point(v, angle, o)
    local x, y = v.x, v.y
    local ox, oy = o.x, o.y
    return vec(cos(angle) * (x - ox) - sin(angle) * (y - oy) + ox, sin(angle) * (x - ox) + cos(angle) * (y - oy) + oy)
end

function cbufnew(size)
    return {
        _start = 0,
        _end = 0,
        _size = size
    }
end

function cbufpush(cb, v)
    -- add a value to the end of a circular buffer
    cb[cb._end] = v
    cb._end = (cb._end + 1) % cb._size
    if cb._end == cb._start then
        cb._start = (cb._start + 1) % cb._size
    end
end

function cbufpop(cb)
    -- remove a value from the start of the circular buffer, and return it
    local v = cb[cb._start]
    cb._start = cb._start + 1 % cb._size
    return v
end

function cbufget(cb, i)
    -- return a value from the circular buffer by index. 0 = start, -1 = end
    if i <= 0 then
        return cb[(cb._end - i) % cb._size]
    else
        return cb[(cb._start + i) % cb._size]
    end
end

function paused_menu(game)
    local selected = 1
    local m = {}
    function m:update()
        frame = frame + 1
        if inp.up_pressed() then
            selected = selected - 1
        end
        if inp.down_pressed() then
            selected = selected + 1
        end
        selected = max(min(selected, 3), 1)
        if inp.action1_pressed() then
            if selected == 1 then
                set_game_mode(game)
            elseif selected == 2 then
                set_game_mode(game)
                snd.stop_channel(1)
                game.player.freq=nil
                snd.stop_channel(2)
                game:restart()
            elseif selected == 3 then
                snd.stop_channel(1)
                game.player.freq=nil
                snd.stop_channel(2)
                camera_angle = 0.25
                set_game_mode(intro)
            end
        end
    end

    function m:draw()
        game:draw()
        rectfill(115, 40, 233, 88, 1)
        gprint("Paused", 120, 44, 7)
        gprint("Continue", 120, 56, selected == 1 and frame % 4 < 2 and 7 or 6)
        gprint("Restart race", 120, 66, selected == 2 and frame % 4 < 2 and 7 or 6)
        gprint("Exit", 120, 76, selected == 3 and frame % 4 < 2 and 7 or 6)
    end

    return m
end

function completed_menu(game)
    local m = {
        selected = 1
    }
    function m:update()
        frame = frame + 1
        if not inp.action1() then
            self.ready = true
        end
        if inp.up_pressed() then
            self.selected = self.selected - 1
        end
        if inp.down_pressed() then
            self.selected = self.selected + 1
        end
        self.selected = clamp(self.selected, 1, 2)
        if self.ready and inp.action1_pressed() then
            if self.selected == 1 then
                set_game_mode(game)
                game:restart()
            else
                camera_angle = 0.25
                set_game_mode(intro)
            end
        end
    end

    function m:draw()
        game:draw()
        gprint("Retry", 53, 204, self.selected == 1 and frame % 16 < 8 and 8 or 6)
        gprint("Exit", 53, 214, self.selected == 2 and frame % 16 < 8 and 8 or 6)
    end

    return m
end

function displace_point(p, o, factor)
    return vecadd(p, scalev(vecsub(p, o), factor))
end

function displace_line(a, b, o, factor, col)
    a = displace_point(a, o, factor)
    b = displace_point(b, o, factor)
    linevec(a, b, col)
end

function linevec(a, b, col)
    line(a.x, a.y, b.x, b.y, col)
end

-- util
function clamp(val, lower, upper)
    return max(lower, min(upper, val))
end

function clampv(v, max)
    return vec(mid( -max, v.x, max), mid( -max, v.y, max))
end

function format_number(n)
    if n < 10 then
        return "0" .. flr(n)
    end
    return n
end

function format_time(t)
    return format_number(flr(t)) .. ":" .. format_number(flr((t - flr(t)) * 100))
end

function printr(text, x, y, c)
    local l = #text
    gprint(text, x - l * 8, y, c)
end

function printc(text, x, y, c)
    local l = #text
    gprint(text, x - l * 4, y, c)
end

function dot(a, b)
    return a.x * b.x + a.y * b.y
end

function onscreen(p)
    p = cam2screen(p)
    return p.x >= -30 and p.x <= gfx.SCREEN_WIDTH + 30 and p.y >= -30 and p.y <= gfx.SCREEN_HEIGHT + 30
end

function inside_rect(x, y, rx, ry, rw, rh)
    return x >= rx and y >= ry and x < rx + rw and y < ry + rh
end

function length(v)
    return sqrt(v.x * v.x + v.y * v.y)
end

function scalev(v, s)
    return vec(v.x * s, v.y * s)
end

function normalize(v)
    local len = length(v)
    return vec(v.x / len, v.y / len)
end

function side_of_line(v1, v2, px, py)
    return (px - v1.x) * (v2.y - v1.y) - (py - v1.y) * (v2.x - v1.x)
end

function car_lap_seg(s1, s2)
    local pseg = s2.current_segment
    while abs(s1 + mapsize - pseg) < abs(s1 - pseg) do
        s1 = s1 + mapsize
    end
    while abs(s1 - mapsize - pseg) < abs(s1 - pseg) do
        s1 = s1 - mapsize
    end
    return s1
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

function get_segment_from_section(sec)
    for i = 1, #vecmap do
        if vecmap[i].section == sec then
            return i
        end
    end
    return -1
end

function get_vec_from_vecmap(seg)
    seg = wrap(seg, mapsize)
    local v = vecmap[seg + 1]
    return vec(v.x, v.y)
end

function find_segment_from_pos(pos, last_good_seg)
    for seg = 0, mapsize - 1 do
        local pseg = last_good_seg and last_good_seg + seg or seg + 1
        local seglostpoly = get_segment(pseg, true)
        if seglostpoly and point_in_polygon(seglostpoly, pos) then
            return pseg
        end
    end
end

function get_data_from_vecmap(seg)
    seg = wrap(seg, mapsize)
    return vecmap[seg + 1]
end

function get_segment(seg, enlarge, for_collision)
    seg = wrap(seg, mapsize)
    -- returns the 4 points of the segment
    local nextv = get_data_from_vecmap(seg + 2)
    local v = get_data_from_vecmap(seg + 1)
    local lastv = get_data_from_vecmap(seg)
    local lastlastv = get_vec_from_vecmap(seg - 1)

    local front = v.front
    local side = v.side
    local lastfront = lastv.front
    local lastside = lastv.side

    local lastwl = lastv.ltyp & 7 == 0 and lastv.w + 4 or lastv.w + 40
    local lastwr = lastv.rtyp & 7 == 0 and lastv.w + 4 or lastv.w + 40
    local wl = v.ltyp & 7 == 0 and v.w + 4 or v.w + 40
    local wr = v.rtyp & 7 == 0 and v.w + 4 or v.w + 40
    if for_collision then
        local lpit_entry, rpit_entry
        if not lastv.has_lrail then
            if v.ltyp // 8 >= OBJ_PIT_EXIT1 then
                lastwl = lastv.w + 10 + 7 * (3 - (v.ltyp // 8 - OBJ_PIT_EXIT1))
            elseif lastv.ltyp // 8 >= OBJ_PIT_ENTRY1 then
                lpit_entry = lastv.ltyp // 8 - OBJ_PIT_ENTRY1
                lastwl = lastv.w + 16 + 7 * lpit_entry
            else
                lastwl = 200
            end
        end
        if not lastv.has_rrail then
            if v.rtyp // 8 >= OBJ_PIT_EXIT1 then
                lastwr = lastv.w + 10 + 7 * (3 - (v.rtyp // 8 - OBJ_PIT_EXIT1))
            elseif lastv.rtyp // 8 >= OBJ_PIT_ENTRY1 then
                rpit_entry = lastv.rtyp // 8 - OBJ_PIT_ENTRY1
                lastwr = lastv.w + 16 + 7 * rpit_entry
            else
                lastwr = 200
            end
        end
        if not v.has_lrail then
            if nextv.ltyp // 8 == OBJ_PIT_EXIT1 then
                lastwl = lastv.w + 31
                wl = lastwl
            elseif v.ltyp // 8 >= OBJ_PIT_EXIT1 then
                wl = v.w + 10 + 7 * (2 - (v.ltyp // 8 - OBJ_PIT_EXIT1))
            elseif v.ltyp // 8 >= OBJ_PIT_ENTRY1 then
                wl = v.w + 16 + 7 * (v.ltyp // 8 - OBJ_PIT_ENTRY1)
            else
                wl = 200
            end
        elseif lpit_entry == 2 then
            wl = lastwl
        end
        if not v.has_rrail then
            if nextv.rtyp // 8 == OBJ_PIT_EXIT1 then
                lastwr = lastv.w + 31
                wr = lastwr
            elseif v.rtyp // 8 >= OBJ_PIT_EXIT1 then
                wr = v.w + 10 + 7 * (2 - (v.rtyp // 8 - OBJ_PIT_EXIT1))
            elseif v.rtyp // 8 >= OBJ_PIT_ENTRY1 then
                wr = v.w + 16 + 7 * (v.rtyp // 8 - OBJ_PIT_ENTRY1)
            else
                wr = 200
            end
        elseif rpit_entry == 2 then
            wr = lastwr
        end
    end
    if enlarge then
        lastwl = lastwl * 2.5
        lastwr = lastwr * 2.5
        wl = wl * 2.5
        wr = wr * 2.5
    end
    local lastoffsetl = scalev(lastside, lastwl)
    local lastoffsetr = scalev(lastside, lastwr)
    local offsetl = scalev(side, wl)
    local offsetr = scalev(side, wr)
    local front_left = vecadd(v, offsetl)
    local front_right = vecsub(v, offsetr)
    local back_left = vecadd(lastv, lastoffsetl)
    local back_right = vecsub(lastv, lastoffsetr)
    if dot(vecsub(front_left, v), lastfront) < dot(vecsub(back_left, v), lastfront) then
        local v = intersection(front_left, front_right, back_left, back_right)
        front_left, back_left = v, v
    end
    if dot(vecsub(front_right, v), lastfront) < dot(vecsub(back_right, v), lastfront) then
        local v = intersection(front_left, front_right, back_left, back_right)
        front_right, back_right = v, v
    end
    return { back_left, back_right, front_right, front_left }
end

-- intersection between segments [ab] and [cd]
function intersection(a, b, c, d)
    local e = (a.x - b.x) * (c.y - d.y) - (a.y - b.y) * (c.x - d.x)
    if e ~= 0 then
        local i, j = a.x * b.y - a.y * b.x, c.x * d.y - c.y * d.x
        local x = (i * (c.x - d.x) - j * (a.x - b.x)) / e
        local y = (i * (c.y - d.y) - j * (a.y - b.y)) / e
        return vec(x, y)
    end
    return nil
end

function perpendicular(v)
    return vec(v.y, -v.x)
end

function vecsub(a, b)
    return vec(a.x - b.x, a.y - b.y)
end

function vecadd(a, b)
    return vec(a.x + b.x, a.y + b.y)
end

function vecinv(a)
    return vec( -a.x, -a.y)
end

function midpoint(a, b)
    return vec((a.x + b.x) / 2, (a.y + b.y) / 2)
end

function get_normal(a, b)
    return normalize(perpendicular(vecsub(a, b)))
end

function distance(a, b)
    return sqrt(distance2(a, b))
end

function distance2(a, b)
    local d = vecsub(a, b)
    return d.x * d.x + d.y * d.y
end

function distance_from_line2(p, v, w)
    local l2 = distance2(v, w)
    if (l2 == 0) then
        return distance2(p, v)
    end
    local t = ((p.x - v.x) * (w.x - v.x) + (p.y - v.y) * (w.y - v.y)) / l2
    if t < 0 then
        return distance2(p, v)
    elseif t > 1 then
        return distance2(p, w)
    end
    return distance2(p, vec(v.x + t * (w.x - v.x), v.y + t * (w.y - v.y)))
end

function distance_from_line(p, v, w)
    return sqrt(distance_from_line2(p, v, w))
end

function point_in_polygon(pgon, t)
    local tx, ty = t.x, t.y
    local i, yflag0, yflag1, inside_flag
    local vtx0, vtx1

    local numverts = #pgon

    vtx0 = pgon[numverts]
    vtx1 = pgon[1]

    -- get test bit for above/below x axis
    yflag0 = (vtx0.y >= ty)
    inside_flag = false

    for i = 2, numverts + 1 do
        yflag1 = (vtx1.y >= ty)

        if yflag0 ~= yflag1 then
            if ((vtx1.y - ty) * (vtx0.x - vtx1.x) >= (vtx1.x - tx) * (vtx0.y - vtx1.y)) == yflag1 then
                inside_flag = not inside_flag
            end
        end

        -- move to the next pair of vertices, retaining info as possible.
        yflag0 = yflag1
        vtx0 = vtx1
        vtx1 = pgon[i]
    end

    return inside_flag
end

function check_collision(points, lines)
    if lines then
        for i=1,#points do
            local point=points[i]
            for j=1,#lines do
                local line=lines[j]
                if side_of_line(line[1], line[2], point.x, point.y) < 0 then
                    local rvec = get_normal(line[1], line[2])
                    local penetration = distance_from_line(point, line[1], line[2])
                    return rvec, penetration, point
                end
            end
        end
    end
    return nil
end

function lerp(a, b, t)
    return (1 - t) * a + t * b
end

function lerpv(a, b, t)
    return vec(lerp(a.x, b.x, t), lerp(a.y, b.y, t))
end

TRACKS = {
    [0] = { 1337, 4, 128, 32, 25, 48, 0, 0, 2, 128, 32, 9, 48, 0, 0, 6, 128, 32, 9, 56, 0, 0, 4, 128, 32, 1, 1, 0, 0, 4, 128, 32, 17, 25, 0, 0, 2, 128, 32, 25, 25, 0, 0, 2, 128, 32, 1, 1, 0, -1,
        -- prima variante
        3, 120, 32, 1, 1, -1, 3, 3, 140, 32, 1, 17, 3, 0,
        -- curva biassono
        2, 126, 32, 1, 0, 0, 0, 2, 126, 32, 17, 24, 1, 0, 2, 126, 32, 25, 24, 0, 0,
        6, 128, 32, 25, 24, 0, 0, 8, 126, 32, 26, 24, 0, 0, 6, 127, 32, 26, 24, 0, 0, 6, 128, 32, 0, 24, 0, 0, 1, 128, 32, 32, 24, 0, 0, 2, 128, 32, 0, 24, 0, 0, 1, 128, 32, 25, 24, 1, 0,
        -- seconda variante
        2, 137, 32, 25, 27, 1, 0, 3, 123, 32, 26, 27, 0, 0, 2, 128, 32, 24, 16, 0, 0, 8, 128, 32, 24, 24, 0, 0,
        -- prima curva di lesmo
        9, 125, 32, 26, 24, 0, 0, 8, 128, 32, 25, 24, 0, 0,
        -- seconda curva di lesmo
        4, 123.0, 32, 26, 24, 0, 0, 4, 128, 32, 26, 24, 0, 0, 8, 128, 32, 24, 24, 0, 0,
        -- curva del serraglio
        5, 129, 32, 24, 24, 0, 0, 16, 128, 32, 24, 24, 0, 0,
        -- variante ascari
        5, 131, 32, 25, 26, 0, 0,
        7, 125, 32, 26, 25, 0, 0, 6, 131, 32, 25, 18, 0, 0, 2, 128, 32, 0, 0, 0, 0, 6, 128, 32, 0, 8, 0, 0, 9, 128, 32, 0, 0, 0, 0, 1, 128, 32, 32, 0, 0, 0, 7, 128, 32, 0, 0, 0, 0, 1, 128, 32, 32, 0, 0, 0, 1, 128, 32, 0, 0, 0, 0,
        2, 128, 32, 24, 24, 0, 0, 6, 128, 32, 16, 24, 0, 0, 2, 128, 32, 8, 0, 0, 0,
        -- curva parabolica
        5, 121.1, 32, 27, 0, 0, 0, 7, 127.1, 32, 27, 0, 0, 0, 6, 126.8, 32, 26, 24, 0, 0, 2, 126.8, 32, 10, 24, 0, 0,
        6, 128.0, 32, 10, 24, 0, 0, 5, 128.0, 32, 9, 56, 0, 0, 1, 128.0, 32, 41, 56, 0, 0, 10, 128, 32, 9, 48, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    { 10, 128, 32, 10, 125, 32, 10, 127, 32, 6, 127, 32, 6, 121, 32, 6, 120, 32, 6, 120, 32, 6, 120, 32, 6, 125, 32, 6,
        135, 32, 6, 131, 32, 6, 129, 32, 6, 130, 32, 6, 131, 32, 6, 130, 32, 6, 129, 32, 6, 128, 32, 6, 125, 32, 6, 125,
        32, 6, 124, 32, 6, 124, 32, 6, 123, 32, 6, 121, 32, 6, 127, 32, 6, 136, 32, 6, 128, 32, 6, 128, 32, 6, 126, 32, 6,
        125, 32, 6, 125, 32, 6, 125, 32, 6, 129, 32, 6, 131, 32, 3, 129, 32, 3, 125, 32, 3, 127, 32, 0, 0, 0 },
    { 10, 128, 32, 10, 129, 32, 10, 129, 32, 10, 138, 32, 10, 138, 32, 10, 124, 32, 10, 125, 32, 10, 127, 32, 10, 129,
        32, 10, 129, 32, 10, 128, 32, 10, 130, 32, 10, 129, 32, 10, 128, 32, 10, 122, 32, 10, 122, 32, 10, 123, 32, 10,
        127, 32, 10, 131, 32, 10, 131, 32, 10, 128, 32, 10, 126, 32, 10, 126, 32, 10, 128, 32, 10, 128, 32, 10, 127, 32,
        10, 122, 32, 10, 135, 32, 10, 121, 32, 10, 129, 32, 10, 130, 32, 10, 130, 32, 9, 129, 32, 4, 126, 32, 2, 124, 32,
        2, 126, 32, 0, 0, 0 },
    { 10, 128, 32, 10, 128, 32, 10, 132, 32, 10, 130, 32, 10, 121, 32, 10, 132, 32, 10, 134, 32, 10, 136, 32, 10, 122,
        32, 10, 127, 32, 10, 126, 32, 10, 133, 32, 10, 130, 32, 10, 128, 32, 10, 128, 32, 10, 131, 32, 10, 128, 32, 10,
        122, 32, 10, 122, 32, 10, 122, 32, 10, 122, 32, 10, 128, 32, 10, 128, 32, 10, 130, 32, 10, 132, 32, 10, 128, 32,
        10, 126, 32, 10, 129, 32, 10, 126, 32, 10, 126, 32, 10, 128, 32, 10, 128, 32, 10, 127, 32, 10, 123, 32, 10, 129,
        32, 10, 130, 32, 7, 127, 32, 4, 127, 32, 2, 124, 32, 2, 129, 32, 2, 126, 32, 0, 0, 0 },
    { 10, 128, 32, 6, 136, 32, 3, 131, 32, 3, 113, 32, 3, 124, 32, 3, 125, 32, 3, 126, 32, 3, 138, 32, 3, 137, 32, 3,
        140, 32, 3, 129, 32, 3, 128, 32, 3, 127, 32, 3, 127, 32, 3, 127, 32, 3, 127, 32, 3, 123, 32, 3, 122, 32, 3, 119,
        32, 3, 123, 32, 3, 144, 32, 16, 129, 32, 3, 113, 32, 3, 144, 32, 3, 112, 32, 3, 145, 32, 3, 131, 32, 11, 126, 32,
        11, 125, 32, 5, 129, 32, 5, 138, 32, 5, 138, 32, 5, 138, 32, 5, 138, 32, 5, 123, 32, 5, 127, 32, 2, 131, 32, 2,
        130, 32, 2, 127, 32, 2, 129, 32, 1, 124, 32, 0, 0, 0 },
    { 10, 127, 32, 10, 128, 32, 3, 120, 32, 3, 128, 32, 3, 128, 32, 3, 133, 32, 3, 133, 32, 3, 129, 32, 3, 131, 32, 3,
        132, 32, 3, 133, 32, 3, 122, 32, 3, 128, 32, 3, 128, 32, 3, 128, 32, 3, 128, 32, 3, 135, 32, 3, 124, 32, 3, 122,
        32, 3, 127, 32, 3, 133, 32, 2, 137, 32, 20, 124, 32, 13, 130, 32, 13, 126, 32, 13, 130, 32, 13, 126, 32, 13, 126,
        32, 8, 128, 32, 8, 131, 32, 8, 130, 32, 8, 126, 32, 8, 124, 32, 8, 127, 32, 8, 129, 32, 8, 128, 32, 8, 127, 32, 8,
        127, 32, 8, 127, 32, 8, 131, 32, 4, 132, 32, 4, 123, 32, 4, 128, 32, 4, 139, 32, 4, 126, 32, 4, 126, 32, 4, 126,
        32, 4, 133, 32, 4, 130, 32, 4, 127, 32, 4, 127, 32, 4, 126, 32, 4, 126, 32, 4, 120, 32, 4, 120, 32, 4, 120, 32, 4,
        120, 32, 4, 120, 32, 4, 123, 32, 4, 128, 32, 4, 130, 32, 4, 130, 32, 4, 131, 32, 4, 130, 32, 4, 129, 32, 3, 128,
        32, 2, 127, 32, 2, 126, 32, 1, 132, 32, 0, 0, 0 },
    { 10, 127, 32, 8, 129, 32, 8, 129, 32, 3, 118, 32, 3, 140, 32, 3, 134, 32, 3, 132, 32, 3, 120, 32, 3, 123, 32, 3,
        127, 32, 3, 139, 32, 11, 126, 32, 11, 121, 32, 5, 126, 32, 5, 131, 32, 5, 131, 32, 4, 133, 32, 4, 121, 32, 6, 124,
        32, 6, 130, 32, 6, 136, 32, 6, 125, 32, 6, 128, 32, 6, 129, 32, 2, 118, 32, 2, 120, 32, 4, 128, 32, 4, 126, 32, 4,
        125, 32, 4, 134, 32, 4, 127, 32, 4, 122, 32, 4, 129, 32, 4, 140, 32, 10, 127, 32, 10, 127, 32, 10, 130, 32, 10,
        129, 32, 10, 128, 32, 10, 128, 32, 3, 138, 32, 3, 115, 32, 3, 126, 32, 8, 131, 32, 8, 130, 32, 8, 126, 32, 8, 129,
        32, 4, 120, 32, 8, 133, 32, 8, 128, 32, 8, 130, 32, 3, 122, 32, 8, 128, 32, 8, 131, 32, 8, 126, 32, 8, 136, 32, 8,
        136, 32, 8, 136, 32, 8, 136, 32, 8, 128, 32, 8, 126, 32, 8, 123, 32, 8, 137, 32, 8, 119, 32, 8, 137, 32, 16, 124,
        32, 16, 127, 32, 16, 132, 32, 16, 127, 32, 16, 127, 32, 16, 117, 32, 16, 132, 32, 6, 125, 32, 6, 128, 33, 3, 128,
        33, 1, 131, 34, 0, 0, 0 },
    { 10, 129, 32, 10, 128, 32, 3, 138, 32, 3, 118, 32, 3, 128, 32, 3, 137, 32, 3, 124, 32, 7, 126, 32, 6, 128, 32, 6,
        124, 32, 6, 128, 32, 6, 125, 32, 6, 128, 32, 6, 128, 32, 6, 128, 32, 6, 129, 32, 6, 129, 32, 6, 126, 32, 6, 126,
        32, 6, 127, 32, 6, 129, 32, 6, 128, 32, 2, 114, 32, 5, 128, 32, 2, 139, 32, 8, 128, 32, 11, 122, 32, 11, 122, 32,
        11, 122, 32, 11, 122, 32, 4, 138, 32, 5, 124, 32, 5, 129, 32, 5, 136, 32, 5, 129, 32, 5, 129, 32, 5, 127, 32, 5,
        128, 32, 2, 118, 32, 2, 125, 32, 2, 140, 32, 7, 129, 32, 4, 113, 32, 9, 130, 32, 9, 130, 32, 2, 104, 32, 6, 128,
        32, 6, 132, 32, 6, 132, 32, 6, 131, 32, 6, 137, 32, 6, 137, 32, 6, 137, 32, 6, 137, 32, 6, 137, 32, 6, 137, 32, 6,
        137, 32, 6, 129, 32, 6, 128, 32, 6, 128, 32, 6, 119, 32, 6, 119, 32, 6, 119, 32, 6, 126, 32, 6, 134, 32, 6, 129,
        32, 6, 128, 32, 6, 123, 32, 6, 128, 32, 6, 126, 32, 6, 126, 32, 6, 132, 32, 3, 138, 32, 3, 132, 32, 3, 125, 32, 3,
        125, 32, 2, 130, 33, 1, 127, 33, 0, 127, 33, 0, 0, 0 }
}

SFX =
{
    "PAT 12 D.2343 D.6615 D.6625 D.6615 D.2343 D.6615 D.6625 D.6615 D.2373 D.5603 D.2603 D.6643 D.2373 D.5603 D.6643 D.6643 D.2373 D.5603 D.2603 D.6643 D.2373 D.5603 D.6643 D.6643 D.2373 D.5603 D.5603 D.6643 D.2373 D.2303 D.6643 D.6643",
    "PAT 24 D.1175 D.1155 D.1125 D.1115 D.2305 D.2305 D.2155 D.2125 F.1175 F.1155 F.1125 F.1115 D.2305 D.2305 A.2155 A.2125 G.2175 G.2155 G.2125 G.2115 G.2105 G.2105 F.2175 F.2155 F.2125 F.2115 D.4605 C.2605 A#2175 A#2155 A#2125 A#2115",
    "PAT 24 D.2040 D.1040 D.2042 D.1042 D.2040 D.1040 D.2042 D.1042 F.2040 F.1040 F.2042 F.1042 E.2040 E.1040 E.2042 E.1042 G.2040 G.1040 G.2042 G.1042 A.2040 A.1040 A.2042 A.1042 A#2040 A#1040 A#2042 A.2042 D.2040 D.1040 D.2042 D.1042",
    "PAT 48 D.2547 F.3537 A.2527 G.2517 D.2547 A.3537 F.2527 G.2517 D.2547 A#3537 G.2527 F.2517 D.2547 E.3537 F.2527 A.2517 D.2547 F.3537 A.2527 G.2517 G.2547 E.3537 F.2527 D.2517 D.2547 A.3537 A#2527 F.2517 A.2547 A#3537 D.2527 C.2517",
    "PAT 24 D.3302 ...... F.3302 ...... D.3302 ...... E.3302 ...... F.3302 ...... D.3302 ...... E.3302 ...... G.3302 ...... D.3302 ...... C.3302 D.3302 C.3302 A.2302 A.3302 C.3302 D.3301 D.3302 F.3302 A.3302 A.3302 G.3301 D.3301 ......",
    "PAT 12 D.3755 F.3755 A.3755 A#3755 D.3755 F.3755 A.3755 D.4755 D.4755 C.4755 D.4755 F.4755 A.4755 G.4755 A.4755 D.4755 D.4755 D.3755 C.4755 C.3755 E.3755 F.3755 A.3755 G.3755 D.4755 D.3755 D.4755 G.4755 F.4755 A.4755 A#4755 A.4755",
    "PAT 12 D.4775 D.3775 D.4775 D.3775 D.4775 D.3775 D.4775 D.3775 D.4775 D.3775 D.4775 D.3775 D.4775 D.4775 D.4775 D.4775 E.4775 E.3775 E.4775 E.3775 D.4775 D.3775 D.4775 D.3775 F.4775 G.3775 G.4775 F.3775 D.4775 E.3775 D.4775 C.3775",
    "PAT 12 D.3775 D.3705 D.2775 F.3705 F.2775 F.3705 F.2775 F.3705 F.3775 ...... F.2775 ...... A.2775 ...... A.2775 ...... A#3775 ...... A.2775 ...... G.2775 ...... F.2775 ...... E.3775 ...... E.2775 ...... D.2775 ...... C.2775 ......",
    "PAT 24 D.1774 D.1772 D.1772 D.1772 D.1772 D.1772 D.1772 D.1772 D.1022 D.1022 D.1022 D.1022 D.1022 D.1022 D.1022 D.1022 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... C.1004",
    "PAT 16 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
    "PAT 16 A.20F5 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
    "PAT 16 A.40F5 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
    "PAT 4 C.08F3 ......",
    "PAT 16 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
    "PAT 16 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
    "PAT 16 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
    "PAT 16 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
    "PAT 16 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
    "PAT 16 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
    "PAT 16 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
    "PAT 16 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
    "PAT 16 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
    "PAT 16 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
    "PAT 16 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
    "PAT 16 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
    "PAT 16 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
    "PAT 16 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
    "PAT 16 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
    "PAT 16 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
    "PAT 16 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
    "PAT 16 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
    "PAT 16 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
    "PAT 16 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
    "PAT 3 D.4170 A#3170 F.3170 C#3170 G#2170 F.2170 D#2170 C.2170 A#1170 G#1170 F#1170 F.1170 E.1170 D#1170 D.1170 C#1170 C#1170",
    "PAT 3 C#1170 C#1170 D#1170 E.1170 F.1170 F#1170 F#1170 G.1170 A.1170 A#1170 B.1170 C#2170 D#2170 F#2170 A.2170 A#2170 C#3170 D#3170 F.3170 F#3170 A.3170 A#3170",
    "PAT 6 D.2610 D.2610 D.2610 D.2610 D.2610 D.2610 D.2610 D.2610",
    "PAT 6 A.3620 A.3620 A.3620 A.3620 A.3620 A.3620 A.3620 A.3620",
    "PAT 6 A.3120 A.3620 A.3620 A.3620 A.3620 A.3620 A.3620 A.3620",
    "PAT 3 C.6650 G.5650 D#5650 C.5640 E.4630 C#3620 F#2620 G#1610 C#3610 C#1310",
    "PAT 6 A.3130 A.3620 A.3130 A.3620 A.3620 A.3620 A.3620 A.3620", "PAT 3 D#6650 C.6610 D#4610 D.2413",
    "PAT 2 G#1600 D.1210 F.1210 A.1220 B.1230 D.2240 F.2240 G.2340 A#2350 G.2250 D#3360 G.3360 C.3260 B.3360 E.4360 E.3260 A.4360 G#5360 D.6360 F#4250 A#3350 G.4340 G.5340 D.6340",
    "PAT 16 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
    "PAT 16 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
    "PAT 16 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
    "PAT 16 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
    "PAT 16 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
    "PAT 16 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
    "PAT 16 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
    "PAT 16 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
    "PAT 16 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
    "PAT 16 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
    "PAT 16 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
    "PAT 16 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
    "PAT 16 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
    "PAT 16 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
    "PAT 16 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
    "PAT 16 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
    "PAT 16 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
    "PAT 16 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
    "PAT 16 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
    "PAT 16 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
    "PAT 16 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
    "PAT 16 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......" }

-- pico8 instruments
INST_TRIANGLE = "INST OVERTONE 1.0 TRIANGLE 1.0 METALIZER 0.85 NAM triangle"
INST_TILTED = "INST OVERTONE 1.0 TRIANGLE 0.5 SAW 0.1 NAM tilted"
INST_SAW = "INST OVERTONE 1.0 SAW 1.0 ULTRASAW 1.0 NAM saw"
INST_SQUARE = "INST OVERTONE 1.0 SQUARE 0.5 NAM square"
INST_PULSE = "INST OVERTONE 1.0 SQUARE 0.5 PULSE 0.5 TRIANGLE 1.0 METALIZER 1.0 OVERTONE_RATIO 0.5 NAM pulse"
INST_ORGAN = "INST OVERTONE 0.5 TRIANGLE 0.75 NAM organ"
INST_NOISE = "INST NOISE 1.0 NOISE_COLOR 0.2 NAM noise"
INST_PHASER = "INST OVERTONE 0.5 METALIZER 1.0 TRIANGLE 0.7 NAM phaser"
--INST_ENGINE = "INST OVERTONE 1.0 METALIZER 1.0 TRIANGLE 1.0 NAM engine"
INST_ENGINE = "SAMPLE ID 01 FILE pitstop/high_rpm16.wav FREQ 554 LOOP_START 0"
INST_TRIBUNE = "SAMPLE ID 02 FILE pitstop/tribune.wav FREQ 440 LOOP_START 0"
