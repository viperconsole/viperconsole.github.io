-- pico racer 2048
-- by impbox software
--
-- viper port by jice
X_OFFSET = 130
Y_OFFSET = 0
MINIMAP_START = -10
MINIMAP_END = 20
SMOKE_LIFE = 80
DATA_PER_SEGMENT=8
DATA_PER_SECTION=7
LAP_COUNTS = {1, 3, 5, 15}
LAYER_SMOKE=3
LAYER_SHADOW=4
LAYER_CARS=5
LAYER_SHADOW2=6
LAYER_TOP=7
OBJ_TRIBUNE=1
OBJ_TRIBUNE2=2
OBJ_TREE=3
SHADOW_DELTA={x=-10,y=10}
SHADOW_COL={r=162.0/255,g=136.0/255,b=121.0/255} -- correspond to palette 22
cam_pos = {
    x = 0,
    y = 0
}
camera_angle = 0
best_seg_times = {}
best_lap_time = nil
best_lap_driver = nil
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
function btnp(num, player)
    -- TODO
end
function cls()
    local c = PAL[21]
    gfx.set_active_layer(LAYER_TOP)
    gfx.clear(0,0,0)
    gfx.set_active_layer(LAYER_SHADOW)
    gfx.clear(0,0,0)
    gfx.set_active_layer(LAYER_SHADOW2)
    gfx.clear(0,0,0)
    gfx.set_active_layer(LAYER_CARS)
    gfx.clear(0,0,0)
    gfx.set_active_layer(0)
    gfx.clear(c.r, c.g, c.b)
end
function sspr(x, y, w, h, dx, dy, dw, dh, hflip, vflip)
    gfx.blit(x, y, w, h, dx, dy, dw or 0, dh or 0, hflip or false, vflip or false, 1, 1, 1)
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
col = function(r, g, b)
    return {
        r = r / 255,
        g = g / 255,
        b = b / 255
    }
end
-- pico8 palette
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
}
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
    p = vecadd(p, vec(340, 120))
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
    gfx.disk(p.x, p.y, 2, PAL[c].r, PAL[c].g, PAL[c].b)
end

function cam2screen(p)
    p = vecsub(p, cam_pos)
    p = vecadd(rotate_point(p, -camera_angle + 0.25, vec(0, 0)), vec(64, 64))
    return {
        x = p.x * 224 / 128 + X_OFFSET,
        y = p.y * 224 / 128 + Y_OFFSET
    }
end

function draw_tires(p1, p2, p3, p4, col)
    local x = scalev(normalize(vecsub(p3, p1)), 1.5)
    local y = scalev(normalize(vecsub(p2, p1)), 0.7)
    quadfill(vecsub(vecsub(p1, x), y), vecadd(vecsub(p1, x), y), vecsub(vecadd(p1, x), y), vecadd(vecadd(p1, x), y), col)
    quadfill(vecsub(vecsub(p2, x), y), vecadd(vecsub(p2, x), y), vecsub(vecadd(p2, x), y), vecadd(vecadd(p2, x), y), col)
    quadfill(vecsub(vecsub(p3, x), y), vecadd(vecsub(p3, x), y), vecsub(vecadd(p3, x), y), vecadd(vecadd(p3, x), y), col)
    quadfill(vecsub(vecsub(p4, x), y), vecadd(vecsub(p4, x), y), vecsub(vecadd(p4, x), y), vecadd(vecadd(p4, x), y), col)
end

function trifill(p1, p2, p3, pal, transf)
    local col = PAL[flr(pal)]
    if transf == nil or transf==true then
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
    gfx.disk(p.x, p.y, r * 224 / 128, col.r, col.g, col.b)
end
function rectfill(x0, y0, x1, y1, pal)
    local col = PAL[flr(pal)]
    gfx.rectangle(x0, y0, x1 - x0 + 1, y1 - y0 + 1, col.r, col.g, col.b)
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
function gprint(msg, px, py, col)
    local c = math.floor(col)
    gfx.print(msg, math.floor(px), math.floor(py), PAL[c].r, PAL[c].g, PAL[c].b)
end
function sfx(n)
    snd.play_pattern(n)
end

sfx_boost_cooldown = 33
sfx_booster = 41

boost_warning_thresh = 30
boost_critical_thresh = 15

cars = {{
    name = "Easy",
    maxacc = 1.5,
    steer = 0.0225,
    accsqr = 0.1
}, {
    name = "Medium",
    maxacc = 2.1,
    steer = 0.0185,
    accsqr = 0.16
}, {
    name = "Hard",
    maxacc = 2.4,
    steer = 0.0165,
    accsqr = 0.2
}}

teams = {
    ["Williamson"] = {
        color = 1,
        color2 = 10,
        perf = 10,
        short_name = "WIL"
    },
    ["MacLoran"] = {
        color = 7,
        color2 = 8,
        perf = 9,
        short_name = "MCL"
    },
    ["Benettson"] = {
        color = 11,
        color2 = 26,
        perf = 9,
        short_name = "BEN"
    },
    ["Ferrero"] = {
        color = 8,
        color2 = 8,
        perf = 8,
        short_name = "FER"
    },
    ["Leger"] = {
        color = 28,
        color2 = 7,
        perf = 7,
        short_name = "LEG"
    },
    ["Lotusi"] = {
        color = 5,
        color2 = 7,
        perf = 5,
        short_name = "LOT"
    },
    ["Soober"] = {
        color = 16,
        color2 = 16,
        perf = 5,
        short_name = "SOO"
    },
    ["Jardon"] = {
        color = 29,
        color2 = 8,
        perf = 5,
        short_name = "JAR"
    }
}

drivers = {{
    name = "Anton Sanna",
    short_name = "ASA",
    skill = 8,
    team = "MacLoran",
    helmet = 10
}, {
    name = "Alan Presto",
    short_name = "APR",
    skill = 7,
    team = "Williamson",
    helmet = 11
}, {
    name = "Nygel Mansale",
    short_name = "NMA",
    skill = 5,
    team = "Jardon",
    helmet = 12
}, {
    name = "Gege Leyton",
    short_name = "GLE",
    skill = 6,
    team = "Soober",
    helmet = 13
}, {
    name = "Mike Shoemaker",
    short_name = "MSH",
    skill = 6,
    team = "Benettson",
    helmet = 14
}, {
    name = "Pierre Lami",
    short_name = "PLA",
    skill = 5,
    team = "Jardon",
    helmet = 15
}, {
    name = "Richard Petrez",
    short_name = "RPE",
    skill = 5,
    team = "Benettson",
    helmet = 22
}, {
    name = "John HeartBerth",
    short_name = "JHE",
    skill = 4,
    team = "Lotusi",
    helmet = 23
}, {
    name = "Devon Hell",
    short_name = "DHE",
    skill = 6,
    team = "Williamson",
    helmet = 24
}, {
    name = "Martin Blundle",
    short_name = "MBL",
    skill = 5,
    team = "Leger",
    helmet = 25
}, {
    name = "Gerard Bergler",
    short_name = "GBE",
    skill = 5,
    team = "Ferrero",
    helmet = 26
}, {
    name = "Mike Andrett",
    short_name = "MAN",
    skill = 4,
    team = "MacLoran",
    helmet = 27
}, {
    name = "Carl Wandling",
    short_name = "CWA",
    skill = 4,
    team = "Soober",
    helmet = 28
}, {
    name = "Marco Blundelli",
    short_name = "MBL",
    skill = 4,
    team = "Leger",
    helmet = 29
}, {
    name = "Mickael Hakinon",
    short_name = "MHA",
    skill = 5,
    team = "Lotusi",
    helmet = 30
}}

dt = 0.033333
-- globals

particles = {}
smokes = {}
mapsize = 250
function create_spark(segment, pos, speed, grass)
    for _,p in pairs(particles) do
        if not p.enabled then
            p.x=pos.x
            p.y=pos.y
            p.xv = -speed.x + (rnd(2) - 1) / 2
            p.yv = -speed.y + (rnd(2) - 1) / 2
            p.ttl = 30
            p.seg=segment
            p.enabled=true
            p.grass=grass
            return
        end
    end
    local p = {
        x = pos.x,
        y = pos.y,
        xv = -speed.x + (rnd(2) - 1) / 2,
        yv = -speed.y + (rnd(2) - 1) / 2,
        ttl = 30,
        seg=segment,
        grass=grass
    }
    function p:draw()
        line(self.x, self.y, self.x - self.xv, self.y - self.yv, self.grass and 3 or (self.ttl > 20 and 10 or (self.ttl > 10 and 9 or 8)))
    end
    table.insert(particles,p)
end
function create_smoke(segment, pos, speed,color)
    for _,s in pairs(smokes) do
        if not s.enabled then
            s.x=pos.x
            s.y=pos.y
            s.xv = speed.x * 0.3 + (rnd(2) - 1) / 2
            s.yv = speed.y * 0.3 + (rnd(2) - 1) / 2
            s.r = math.random(2, 4)
            s.seg = segment
            s.enabled = true
            s.ttl = SMOKE_LIFE
            s.col=color
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
        col=color
    }
    function p:draw()
        local p = cam2screen(vec(self.x, self.y))
        local rgb = self.ttl / SMOKE_LIFE
        local col=PAL[self.col]
        gfx.disk(p.x, p.y, self.r * (2 - rgb), col.r*rgb, col.g*rgb, col.b*rgb)
    end
    table.insert(smokes,p)
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
        self.decisions = self.decisions + dt * (self.skill + 4 + rnd(6))
        local c = car.controls
        local car = self.car
        if not car.current_segment then
            return
        end
        local s = flr(2 * car.maxacc)
        if self.decisions < 1 then
            return
        end
        local t = car.current_segment + s
        if t < (mapsize * car.race.lap_count) + 10 then
            local v5 = get_vec_from_vecmap(t)
            if v5 then
                local a = to_pico_angle(atan2(v5.y - car.pos.y, v5.x - car.pos.x))
                local diff = a - car.angle
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
                c.accel = abs(diff) < steer * 100
                c.right = diff < -steer / 3
                c.left = diff > steer / 3
                c.brake = abs(diff) > steer
                c.boost = car.boost > 24 - self.riskiness and (abs(diff) < steer / 2 or car.accel < 0.5)
                self.decisions = self.decisions - 1
            end
        else
            c.accel = false
            c.boost = false
            c.brake = true
        end
    end
    return ai
end

function create_car(race)
    c = cars[intro.car]
    local car = {
        race = race,
        vel = vec(),
        angle = 0,
        trails = cbufnew(32),
        current_segment = race.race_mode == MODE_RACE and -3 or -5,
        boost = 100,
        cooldown = 0,
        wrong_way = 0,
        speed = 0,
        accel = 0,
        accsqr = c.accsqr,
        steer = c.steer,
        maxacc = c.maxacc,
        maxboost = c.maxacc * 1.5,
        lost_count = 0,
        last_good_pos = vec(),
        last_good_seg = 1,
        color = 8,
        color2 = 8,
        collision = 0,
        delta_time = 0,
        lap_times = {},
        time = "-----",
        best_time = nil,
        verts={},
        seg_times={},
        ccut_timer=-1
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
            accel = accel * 0.98
        end
        local speed = length(vel)
        -- accelerate
        if controls.left then
            angle = angle + self.steer * 0.3
        end
        if controls.right then
            angle = angle - self.steer * 0.3
        end
        if self.ccut_timer >= 0 then
            self.ccut_timer = self.ccut_timer - 1
        end
        -- brake
        local sb_left
        local sb_right
        if controls.brake then
            if controls.left then
                sb_left = true
            elseif controls.right then
                sb_right = true
            else
                sb_left = true
                sb_right = true
            end
            if sb_left then
                angle = angle + speed * 0.001
            end
            if sb_right then
                angle = angle - speed * 0.001
            end
            vel = scalev(vel, 0.95)
        end
        accel = min(accel, self.boosting and self.maxboost or self.maxacc)
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
                    sfx(sfx_boost_cooldown)
                    sc1 = sfx_boost_cooldown
                end
            elseif self.is_player and (not (sc1 == sfx_booster and sc1timer > 0)) and sc1 ~= 39 and self.boost <=
                boost_critical_thresh then
                sfx(39)
                sc1 = 39
            elseif self.is_player and (not (sc1 == sfx_booster and sc1timer > 0)) and sc1 ~= 37 and self.boost <=
                boost_warning_thresh then
                sfx(37) -- start warning
                sc1 = 37
            elseif self.is_player and (not (sc1 == sfx_booster and sc1timer > 0)) and sc1 ~= 36 and sc1 ~= 37 then
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
            snd.play_note(5 + self.speed * 2, (0.5 + self.accel) * 0.5, 8, 1)
            sc1 = 35
        end

        -- check collisions
        -- get a width enlarged version of this segment to help prevent losing the car
        local current_segment = self.current_segment
        local segpoly = get_segment(current_segment, true)
        local poly

        self.collision = 0
        if segpoly then
            local in_current_segment = point_in_polygon(segpoly, self.pos)
            if in_current_segment then
                self.last_good_pos = self.pos
                self.last_good_seg = current_segment
                self.lost_count = 0
                poly = get_segment(current_segment,false,true)
            else
                -- not found in current segment, try the next
                local segnextpoly = get_segment(current_segment + 1, true)
                if segnextpoly and point_in_polygon(segnextpoly, self.pos) then
                    poly = get_segment(current_segment + 1,false,true)
                    current_segment = current_segment + 1
                    if best_seg_times[current_segment] == nil then
                        best_seg_times[current_segment] = time
                    end
                    self.seg_times[current_segment] = time
                    if current_segment > 0 and current_segment % mapsize == 0
                        and (self.race.race_mode==MODE_TIME_ATTACK or current_segment<=mapsize * self.race.lap_count) then
                        -- new lap
                        local lap_time = time
                        if self.race.race_mode == MODE_RACE then
                            lap_time = lap_time - self.delta_time
                        end
                        table.insert(self.lap_times, lap_time)
                        self.delta_time = self.delta_time + lap_time
                        if best_lap_time == nil or lap_time < best_lap_time then
                            best_lap_time = lap_time
                            self.race.best_lap_timer=100
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
                            car.race_finished=true
                        end
                    end
                    self.wrong_way = 0
                else
                    -- not found in current or next, try the previous one
                    local segprevpoly = get_segment(current_segment - 1, true)
                    if segprevpoly and point_in_polygon(segprevpoly, self.pos) then
                        poly = get_segment(current_segment - 1,false,true)
                        current_segment = current_segment - 1
                        self.wrong_way = self.wrong_way + 1
                    else
                        -- completely lost the player
                        local found=false
                        for seg=0,mapsize-1 do
                            local pseg = self.last_good_seg+seg
                            local seglostpoly=get_segment(pseg, true)
                            if seglostpoly and point_in_polygon(seglostpoly, self.pos) then
                                poly=get_segment(pseg,false,true)
                                current_segment=pseg
                                found=true
                                if current_segment - self.last_good_seg > 2 then
                                    self.ccut_timer=200
                                end
                                break;
                            end
                        end
                        if not found then
                            self.lost_count = self.lost_count + 1
                            -- current_segment+=1 -- try to find the car next frame
                            if self.lost_count > 30 then
                                -- lost for too long, bring them back to the last known good position
                                local v = get_data_from_vecmap(self.last_good_seg)
                                self.pos = copyv(v)
                                self.current_segment = self.last_good_seg - 1
                                self.vel = vec(0, 0)
                                self.angle = v.dir
                                self.wrong_way = 0
                                self.accel = 1
                                self.lost_count = 0
                                self.trails = cbufnew(32)
                                return
                            end
                        end
                    end
                end
            end
            -- check collisions with walls
            if poly then
                local car_poly = {self.verts[1],self.verts[2],self.verts[3]}
                local v = get_data_from_vecmap(current_segment+1)
                local rails={}
                if v.has_rrail then
                    rails[1] = {poly[2], poly[3]}
                end
                if v.has_lrail then
                    rails[#rails+1]={poly[4], poly[1]}
                end
                if #rails > 0 then
                    local rv, pen, point = check_collision(car_poly, rails)
                    if rv then
                        if pen > 5 then
                            pen = 5
                        end
                        vel = vecsub(vel, scalev(rv, pen))
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
        end

        local car_dir = vec(cos(angle), sin(angle))
        self.vel = vecadd(vel, scalev(car_dir, accel))
        self.pos = vecadd(self.pos, scalev(self.vel, 0.3))
        self.vel = scalev(self.vel, 0.9 * (495+self.perf)/500)
        local v=get_data_from_vecmap(self.current_segment)
        local sidepos=dot(vecsub(self.pos,v),v.side)
        local ground_type = sidepos >36 and (v.ltyp & 7) or (sidepos < -36 and (v.rtyp & 7) or 0)
        if self.is_player and speed > 1 and frame%flr(60/speed) == 0 then
            if (v.has_lkerb and sidepos <= 36 and sidepos >= 24)
                or (v.has_rkerb and sidepos >= -36 and sidepos <= -24) then
                -- on kerbs
                sfx(12)
            end
        end
        if ground_type==1 then
            --grass
            local r=rnd(10)
            if r < 4 then
                self.vel=scalev(self.vel,0.9)
                local angle_vel_impact=min(5.0,speed) / 5.0
                local da = math.random(-20,20) * angle_vel_impact
                angle = wrap(angle,1) * (1000+da) / 1000
            end
            if r < speed then
                create_spark(self.current_segment,self.pos,scalev(normalize(self.vel),0.3),true)
            end
        elseif ground_type==2 then
            -- sand
            self.vel=scalev(self.vel,0.8)
            angle = angle + (self.angle-angle) * 0.5
            if speed > 4 then
                create_smoke(current_segment,vecsub(self.pos, scalev(self.vel, 0.5)), self.vel, 4)
            end
        end
        if self.ccut_timer >= 0 then
            self.vel=scalev(self.vel,0.8)
        end
        for i=1,#car_verts do
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
        local player=self.race.player
        if abs(current_segment-player.current_segment) < 10 then
            local caccel = accel/cars[intro.car].maxacc
            local spawn_pos=vecsub(self.pos, scalev(self.vel, 0.5))
            if (self.ccut_timer < 0 and caccel > 0.8 and speed < 10) or (controls.brake and speed < 7 and speed > 2) then
                local col = ground_type==1 and 3 or (ground_type==2 and 4 or 22)
                create_smoke(current_segment, spawn_pos, self.vel, col)
            end
            if speed > 25 and ground_type == 0 and rnd(10) < 4 then
                create_spark(current_segment, spawn_pos, scalev(normalize(self.vel),0.8), false)
            end
        end
        if car.current_segment >= mapsize * car.race.lap_count then
            car.race_finished=true
            car.race.is_finished=true
        end
    end
    function car:draw_minimap()
        local seg = player_lap_seg(self.current_segment)
        local pseg = player.current_segment
        if seg >= pseg + MINIMAP_START and seg < pseg + MINIMAP_END then
            minimap_disk(self.pos, self.color)
        end
    end
    function car:draw()
        if #self.verts == 0 then
            -- happens only before race start, when cars are drawn but not updated
            for i=1,#car_verts do
                self.verts[i] = rotate_point(vecadd(self.pos, car_verts[i]), self.angle, self.pos)
            end
        end
        local angle = self.angle
        local color = self.color
        local v = self.verts
        local a = v[1]
        local b = v[2]
        local c = v[3]
        local boost = self.boost
        linevec(v[6], v[7], 18) -- front suspension
        quadfill(v[8], v[9], v[10], v[11], color) -- front wing
        trifill(a, b, c, color < 16 and (color + 16) or (color - 16)) -- hull
        trifill(v[13], v[14], v[15], self.color2)
        trifill(v[16], v[17], v[18], self.color2)
        -- hull outline
        linevec(a, b, color)
        linevec(b, c, color)
        linevec(c, a, color)
        draw_tires(v[4], v[5], v[6], v[7], 0)
        circfill(v[12].x, v[12].y, 1, self.driver.helmet)
        local circ = rotate_point(vecadd(self.pos, trail_offset), angle, self.pos)
        local outc = 12
        if self.boost and self.boost < 30 then
            outc = self.boost < 15 and 8 or 9
        end
        local cx, cy = circ.x, circ.y
        if self.cooldown > 0 then
            circfill(cx, cy, frame % 8 < 4 and 1 or 0, 8)
        else
            circfill(cx, cy, self.boosting and frame % 2 == 0 and 4 or 2, outc)
            circfill(cx, cy, self.boosting and frame % 2 == 0 and 2 or 1, 7)
        end
        -- shadow
        local sd=scalev(SHADOW_DELTA,0.1)
        local sv={}
        for i=1,#v do
            sv[i] = vecadd(v[i],sd)
        end
        gfx.set_active_layer(LAYER_SHADOW)
        linevec(sv[6],sv[7],22)
        quadfill(sv[8], sv[9], sv[10], sv[11], 22)
        trifill(sv[1], sv[2], sv[3], 22)
        draw_tires(sv[4], sv[5], sv[6], sv[7], 22)
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
    car_verts = {vec(-4, -3), vec(4, 0), vec(-4, 3), -- hull
    vec(-3, -3), vec(-3, 3), vec(2, -3), vec(2, 3), -- tires positions
    vec(4, -3), vec(4, 3), vec(5, -3), vec(5, 3), -- front wing
    vec(0, 0), -- pilot helmet position
    vec(-4, -3), vec(0, -1.5), vec(-4, 0), vec(-4, 3), vec(0, 1.5), vec(-4, 0) -- second color
    }
    for _, sfx in pairs(SFX) do
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
    gfx.set_active_layer(1)
    gfx.set_layer_size(1, 384, 259)
    gfx.load_img("picoracer", "picoracer/picoracer.png")
    gfx.set_sprite_layer(1)
    gfx.show_layer(LAYER_SMOKE) -- smoke fx
    gfx.set_layer_operation(3, gfx.LAYEROP_ADD)
    gfx.show_layer(LAYER_SHADOW) -- shadow
    gfx.set_layer_operation(LAYER_SHADOW, gfx.LAYEROP_MULTIPLY)
    gfx.show_layer(LAYER_CARS)
    gfx.show_layer(LAYER_SHADOW2) -- shadow
    gfx.set_layer_operation(LAYER_SHADOW2, gfx.LAYEROP_MULTIPLY)
    gfx.show_layer(LAYER_TOP) -- roofs & ui
    gfx.set_active_layer(0)
    trail_offset = vec(-6, 0)
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
    if flipflop then
        game_mode:update()
    end
end

-- intro

intro = {}
frame = 0

MODE_RACE = 1
MODE_TIME_ATTACK = 2
MODE_EDITOR = 3

game_modes = {"Race vs AI", "Time Attack", "Track Editor"}

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
    [0] = "Monzana",
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
    sspr(0, 20, 224, 204, 80, 0)
    draw_intro_minimap(-80, -58, 0.015, 6)
    printr("x/c/arrows/esc", 300, 45, 6)

    local c = frame % 16 < 8 and 8 or 9
    printr("Mode", 202, 2, 6)
    printr(game_modes[self.game_mode], 303, 2, self.option == 1 and c or 9)
    printr("Track", 202, 12, 6)
    printr(difficulty_names[difficulty], 304, 12, self.option == 2 and c or 9)
    if self.game_mode < 3 then
        printr("Level", 202, 22, 6)
        printr(cars[self.car].name, 304, 22, self.option == 3 and c or 9)
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
    mdragy = 0,
    sec_pos = nil
}
function mapeditor:init()
    scale = 0.05
    camera_angle = 0.25
    self.sec = #mapsections
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
                print ("1337,")
                for i = 1, #mapsections do
                    local ms = mapsections[i]
                    print(ms[1] .. "," .. ms[2] .. "," .. ms[3] .. ","..ms[4]..","..ms[5]..","..ms[6]..","..ms[7]..",")
                end
                print("0,0,0,0,0,0,0")
                local race = race()
                race:init(difficulty, 2)
                set_game_mode(race)
                return
            elseif selected == 3 then
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
    if inp.mouse_button(inp.MOUSE_LEFT) then
        if not self.drag then
            self.drag = true
            self.mousex = inp.mouse_x()
            self.mousey = inp.mouse_y()
            self.mdragx = 0
            self.mdragy = 0
        else
            self.mdragx = inp.mouse_x() - self.mousex
            self.mdragy = inp.mouse_y() - self.mousey
        end
    elseif self.drag then
        self.mouseoffx = self.mouseoffx + self.mdragx
        self.mouseoffy = self.mouseoffy + self.mdragy
        self.mdragx = 0
        self.mdragy = 0
        self.drag = false
    end
    -- left/right : change section curve
    if inp.left_pressed() then
        cs[2] = cs[2] - (inp.key(inp.KEY_LSHIFT) and 0.1 or 1)
    elseif inp.right_pressed() then
        cs[2] = cs[2] + (inp.key(inp.KEY_LSHIFT) and 0.1 or 1)
        -- up/down : change section length
    elseif inp.up_pressed() then
        cs[1] = cs[1] + 1
    elseif inp.down_pressed() then
        cs[1] = cs[1] - 1
        -- action2 : delete last section
    elseif inp.action2_pressed() then
        if self.sec > 1 then
            if self.sec == #mapsections then
                mapsections[#mapsections] = nil
            else
                table.remove(mapsections, self.sec)
            end
            self.sec = self.sec - 1
        end
        -- action1 : duplicate last section
    elseif inp.action1_pressed() then
        mapsections[#mapsections + 1] = {cs[1], cs[2], cs[3],0,0}
        self.sec = #mapsections
        -- pageup/pagedown : change section width
    elseif inp.key_pressed(inp.KEY_PAGEDOWN) then
        cs[3] = cs[3] - 1
    elseif inp.key_pressed(inp.KEY_PAGEUP) then
        cs[3] = cs[3] + 1
        -- NUMPAD +/- : zoom
    elseif inp.key_pressed(inp.KEY_NUMPADMINUS) then
        scale = scale * 0.9
    elseif inp.key_pressed(inp.KEY_NUMPADPLUS) then
        scale = scale * 1.1
    elseif inp.key_pressed(inp.KEY_HOME) then
        self.sec = self.sec == 1 and #mapsections or self.sec - 1
    elseif inp.key_pressed(inp.KEY_END) then
        self.sec = self.sec == #mapsections and 1 or self.sec + 1
    elseif inp.key_pressed(inp.KEY_ESCAPE) then
        -- test map todo: open menu
        set_game_mode(map_menu(self))
        return
    end
    cs[2] = mid(0, cs[2], 255)
    cs[1] = mid(0, cs[1], 255)
end
function draw_intro_minimap(sx, sy, scale, col)
    local x, y = sx, sy
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
                x = (1 - coef) * x + coef * sx
                y = (1 - coef) * y + coef * sy
            end
            line(lastx, lasty, x, y, #mapsections == i and 3 or col)
            lastx, lasty = x, y
        end
    end
end
function draw_editor_minimap(sx, sy, scale, col, sec)
    local x, y = sx, sy
    local lastx, lasty = x, y
    local dir = 0
    local sec_pos = {{0, 0}}
    for i = 1, #mapsections do
        ms = mapsections[i]
        local last_section = i == #mapsections
        local highlighted = i == sec
        for seg = 1, ms[1] do
            dir = dir + (ms[2] - 128) / 100
            x = x + cos(dir) * 28 * scale
            y = y + sin(dir) * 28 * scale
            if last_section and sec == nil then
                local coef = seg / ms[1]
                x = (1 - coef) * x + coef * sx
                y = (1 - coef) * y + coef * sy
            end
            line(lastx, lasty, x, y, highlighted and 9 or (#mapsections == i and 3 or col))
            lastx, lasty = x, y
        end
        table.insert(sec_pos, {sx - x, sy - y})
    end
    return sec_pos
end

function mapeditor:draw()
    cls()
    self.sec_pos = draw_editor_minimap(30 + self.mapoffx + self.mouseoffx + self.mdragx,
        self.mapoffy - 10 + self.mouseoffy + self.mdragy, scale, 6, self.sec)
    local pos = self.sec_pos[self.sec]
    self.mapoffx = pos[1]
    self.mapoffy = pos[2]
    gprint("section " .. self.sec .. '/' .. #mapsections .. " seg " .. mapsections[self.sec][1], 122, 1, 7)
    gfx.blit(162, 8, 12, 12, 17, 4, 0, 0, false, false, 1, 1, 1)
    gprint("  delete", 17, 5, 7)
    gfx.blit(174, 8, 12, 12, 17, 16, 0, 0, false, false, 1, 1, 1)
    gprint("  add", 17, 17, 7)
    gfx.blit(66, 8, 24, 12, 5, 28, 0, 0, false, false, 1, 1, 1)
    gprint("    length", 1, 29, 7)
    gfx.blit(90, 8, 24, 12, 5, 40, 0, 0, false, false, 1, 1, 1)
    gprint("    curve", 1, 41, 7)
    gfx.blit(138, 8, 24, 12, 5, 52, 0, 0, false, false, 1, 1, 1)
    gprint("    zoom", 1, 53, 7)
    gfx.blit(114, 8, 24, 12, 5, 64, 0, 0, false, false, 1, 1, 1)
    gprint("    width", 1, 65, 7)
    gfx.blit(186, 8, 24, 12, 5, 76, 0, 0, false, false, 1, 1, 1)
    gprint("    section", 1, 77, 7)
    gfx.blit(54, 8, 12, 12, 17, 88, 0, 0, false, false, 1, 1, 1)
    gprint("  menu", 17, 87, 7)
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
        mapsections[1] = {10, 128, 32,0,0,0,0}
    end
end

function race()
    local race = {}
    function race:init(difficulty, race_mode, lap_count)
        self.race_mode = race_mode
        self.lap_count = LAP_COUNTS[lap_count]
        self.live_cars=16
        self.is_finished=false
        self.panel_timer=-1
        self.best_lap_timer=-1
        sc1 = nil
        sc1timer = 0
        camera_angle = 0

        vecmap = {}
        local dir, mx, my = 0, 0, 0
        local lastdir = 0

        -- generate map
        for i, ms in pairs(mapsections) do
            local last_section = i == #mapsections
            -- read length,curve,width from tiledata
            local length = ms[1]
            local curve = ms[2]
            local width = ms[3]
            local ltyp = ms[4]
            local rtyp = ms[5]
            local lskiprail_first = max(0,ms[6])
            local rskiprail_first = max(0,ms[7])
            local lskiprail_last = max(0,-ms[6])
            local rskiprail_last = max(0,-ms[7])

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
                local railcoef=1
                if abs(dir - lastdir) > 0.09 then
                    dir = lerp(lastdir, dir, 0.5)
                    segment_length = 16
                    length = length - 0.5
                    railcoef=0.5
                else
                    segment_length = 32
                    length = length - 1
                end

                mx = mx + cos(dir) * segment_length
                my = my + sin(dir) * segment_length
                local v={
                    x = mx,
                    y = my,
                    w = width,
                    dir = dir,
                    ltyp = ltyp,
                    rtyp = rtyp,
                    has_lrail = (lskiprail_first<= 0 and length >= lskiprail_last),
                    has_rrail = (rskiprail_first<= 0 and length >= rskiprail_last)
                }
                v.front=normalize(#vecmap>0 and vecsub(v,vecmap[#vecmap]) or vec(1,0))
                v.side=perpendicular(v.front)
                -- track borders (including kerbs)
                v.left_track = vecadd(v,scalev(v.side,v.w))
                v.right_track = vecsub(v,scalev(v.side,v.w))
                v.left_inner_rail = vecadd(v.left_track,scalev(v.side,v.ltyp & 7==0 and 4 or 40))
                v.right_inner_rail = vecsub(v.right_track,scalev(v.side,v.rtyp & 7==0 and 4 or 40))
                v.tribune=2
                if v.has_lrail then
                    v.left_outer_rail = vecadd(v.left_inner_rail,scalev(v.side,4))
                end
                if v.has_rrail then
                    v.right_outer_rail = vecsub(v.right_inner_rail,scalev(v.side,4))
                end
                table.insert(vecmap, v)
                lastdir = dir
                lskiprail_first = lskiprail_first - 1*railcoef
                rskiprail_first = rskiprail_first - 1*railcoef
            end
        end
        mapsize = #vecmap
        -- compute kerbs
        for seg,v in pairs(vecmap) do
            local v2=get_data_from_vecmap(seg)
            local curve = abs(v2.dir - v.dir) * 100
            v.has_rkerb = curve > 2 and (v2.dir < v.dir or curve >= 4)
            v.has_lkerb = curve > 2 and (v2.dir > v.dir or curve >= 4)
            local rkerbw = v.has_rkerb and 8 or 0
            local lkerbw = v.has_lkerb and 8 or 0
            v.left_kerb = vecsub(v.left_track, scalev(v.side,lkerbw))
            v.right_kerb = vecadd(v.right_track, scalev(v.side,rkerbw))
        end
        -- distance to turn signs
        local dist=0
        local last_curve=0
        for i=#vecmap-1,1,-1 do
            local v2=vecmap[i+1]
            local v=vecmap[i]
            local curve = abs(v2.dir - v.dir) * 100
            if curve >= 2 then
                dist=0
                last_curve=v2.dir - v.dir
            else
                dist = dist+1
            end
            if dist==5 or dist == 10 or dist ==15 then
                if last_curve < 0 then
                    v.lpanel=dist/5
                elseif last_curve > 0 then
                    v.rpanel=dist/5
                end
            end
        end
        -- keep only signs when all 3 (150,100,50) exists
        local expected=3
        for i=1,#vecmap do
            local v=vecmap[i]
            if v.lpanel ~= nil then
                if v.lpanel == expected then
                    expected=expected - 1
                    if expected==0 then
                        expected=3
                    end
                else
                    v.lpanel=nil
                end
            end
            if v.rpanel ~= nil then
                if v.rpanel == expected then
                    expected=expected - 1
                    if expected==0 then
                        expected=3
                    end
                else
                    v.rpanel=nil
                end
            end
        end

        self:restart()
    end

    function race:restart()
        self.completed = false
        self.time = self.race_mode == MODE_RACE and -4 or 0
        camera_lastpos = vec()
        self.start_timer = self.race_mode == MODE_RACE
        self.record_replay = nil
        self.play_replay_step = 1

        -- spawn cars

        self.objects = {}
        self.ranks = {}
        best_seg_times = {}
        best_lap_time = nil
        best_lap_driver = nil
        if self.race_mode == MODE_TIME_ATTACK and self.play_replay then
            local replay_car = create_car(self)
            table.insert(self.objects, replay_car)
            replay_car.color = 1
            self.replay_car = replay_car
        end

        local p = create_car(self)
        table.insert(self.objects, p)
        self.player = p
        p.is_player = true
        local v = get_data_from_vecmap(p.current_segment)
        p.pos = vecadd(p.pos, scalev(v.side, 15))
        p.angle = v.dir
        p.rank = 1
        camera_angle = v.dir
        p.driver = {
            name = "Player",
            short_name = "PLA",
            is_best = false,
            team = "Ferrero",
            helmet = 0
        }
        table.insert(self.ranks, p)
        p.perf = teams[p.driver.team].perf
        --snd.play_note(17000, v.tribune, 9, 2)

        if self.race_mode == MODE_RACE then
            for i = 1, #drivers do
                local ai_car = create_car(self)
                ai_car.current_segment = -3 - i // 2
                ai_car.driver = drivers[i]
                ai_car.color = teams[ai_car.driver.team].color
                ai_car.color2 = teams[ai_car.driver.team].color2
                ai_car.perf=teams[ai_car.driver.team].perf
                ai_car.driver.is_best = false
                local v = get_data_from_vecmap(ai_car.current_segment)
                ai_car.pos = vecadd(v, scalev(v.side, i % 2 == 0 and 15 or -15))
                if i % 2 == 1 then
                    ai_car.pos = vecadd(ai_car.pos, scalev(v.front,-15))
                end
                ai_car.angle = v.dir
                local oldupdate = ai_car.update
                ai_car.ai = ai_controls(ai_car)
                ai_car.ai.skill = ai_car.driver.skill
                function ai_car:update(completed, time)
                    self.ai:update()
                    oldupdate(self, completed, time)
                end
                table.insert(self.objects, ai_car)
                table.insert(self.ranks, ai_car)
            end
        end
    end

    function race:update()
        frame = frame + 1
        if sc1timer > 0 then
            sc1timer = sc1timer - 1
        end
        if self.best_lap_timer >= 0 then
            self.best_lap_timer = self.best_lap_timer-1
        end

        if self.completed then
            self.completed_countdown = self.completed_countdown - dt
            if self.completed_countdown < 4 and (inp_menu_pressed() or self.live_cars==0) then
                set_game_mode(completed_menu(self))
                return
            end
        elseif inp_menu_pressed() then
            snd.stop_note(1)
            snd.stop_note(2)
            set_game_mode(paused_menu(self))
            return
        end

        -- enter input
        local player = self.player
        if player then
            local controls = player.controls
            if self.completed then
                controls.left=false
                controls.right=false
                controls.boost=false
                controls.brake=true
                controls.accel=false
            else
                controls.left = inp.left() > 0.1
                controls.right = inp.right() > 0.1
                controls.boost = inp_boost()
                controls.accel = inp_accel()
                controls.brake = inp_brake()
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
            self.time = self.time + dt
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
            for _, obj in pairs(self.objects) do
                obj:update(self.completed, self.time)
            end
        end
        if self.race_mode == MODE_TIME_ATTACK and player.current_segment % mapsize == 0 then
            self.time = 0
        end
        -- car to car collision
        for _, obj in pairs(self.objects) do
            for _, obj2 in pairs(self.objects) do
                if obj ~= obj2 and obj ~= self.replay_car and obj2 ~= self.replay_car then
                    if abs(car_lap_seg(obj.current_segment,obj2) - obj2.current_segment) <= 1 then
                        local p1 = {obj.verts[1],obj.verts[2],obj.verts[3]}
                        local p2 = {obj2.verts[1],obj2.verts[2],obj2.verts[3]}
                        for _, point in pairs(p1) do
                            if point_in_polygon(p2, point) then
                                local rv, p, point = check_collision(p1,
                                    {{p2[2], p2[1]}, {p2[3], p2[2]}, {p2[1], p2[3]}})
                                if rv then
                                    if p > 5 then
                                        p = 5
                                    end
                                    p = p * 1.5
                                    obj.vel = vecadd(obj.vel, scalev(rv, p))
                                    obj2.vel = vecsub(obj2.vel, scalev(rv, p))
                                    create_spark(obj.current_segment, point, rv,false)
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
            snd.stop_note(1)
            snd.stop_note(2)
            self.completed = true
            self.completed_countdown = 5
        end

        -- particles
        for _,p in pairs(particles) do
            if p.enabled then
                if abs(player_lap_seg(p.seg) - player.current_segment) > 10 then
                    p.enabled=false
                else
                    p.x = p.x + p.xv
                    p.y = p.y + p.yv
                    p.xv = p.xv * 0.95
                    p.yv = p.yv * 0.95
                    p.ttl = p.ttl - 1
                    if p.ttl < 0 then
                        p.enabled=false
                    end
                end
            end
        end
        for _,p in pairs(smokes) do
            if p.enabled then
                if abs(player_lap_seg(p.seg) - player.current_segment) > 10 then
                    p.enabled=false
                else
                    p.x = p.x + p.xv
                    p.y = p.y + p.yv
                    p.xv = p.xv * 0.95
                    p.yv = p.yv * 0.95
                    p.ttl = p.ttl - 1
                    if p.ttl < 0 then
                        p.enabled=false
                    end
                end
            end
        end
        -- lerp_angle
        local diff=wrap(player.angle-camera_angle,1)
        local dist=wrap(2*diff,1) - diff
        camera_angle = camera_angle + dist * 0.05

        -- car times
        if frame % 100 == 0 then
            table.sort(self.ranks, function(car,car2)
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
            local leader_seg = leader.race_finished and #leader.lap_times*mapsize or leader.current_segment
            self.live_cars=16
            for _, car in pairs(self.objects) do
                if car.race_finished then
                    self.live_cars=self.live_cars-1
                else
                    local lap_behind = ceil((car.current_segment - leader_seg)/mapsize)
                    car.time = lap_behind < 0 and lap_behind.." laps"
                        or (best_seg_times[car.current_segment] and "+" .. format_time(t - best_seg_times[car.current_segment])
                        or "-----")
                end
            end
        end
        if self.panel_timer < 0 and player.current_segment > 0 and player.current_segment % mapsize == 0 and self.race_mode == MODE_RACE then
            self.panel_timer=200
            local placing = 1
            local nplaces = 1
            for _, obj in pairs(self.objects) do
                if obj ~= player then
                    nplaces = nplaces + 1
                    if obj.current_segment > player.current_segment then
                        placing = placing + 1
                    end
                end
            end
            self.panel_placing=placing
            if placing > 1 then
                local prev=self.ranks[placing-1]
                self.panel_prev=prev
                self.panel_prev_time="-"..format_time(self.time-prev.seg_times[player.current_segment])
            end
            if placing < 16 then
                local next=self.ranks[placing+1]
                self.panel_next=next
                self.panel_next_time="+"..format_time(self.time - player.seg_times[next.current_segment])
            end
        end
        local v = get_data_from_vecmap(player.current_segment)
    end

    function race:draw()
        player = self.player
        time = self.time
        gfx.set_active_layer(0)
        cls()
        local tp = cbufget(player.trails, player.trails._size - 8) or player.pos
        local trail = clampv(vecsub(player.pos, tp), 34)
        camera_pos = vecadd(player.pos, trail)
        if player.collision > 0 then
            camera(camera_pos.x + rnd(3) - 2, camera_pos.y + rnd(3) - 2)
        else
            local c = lerpv(camera_lastpos, camera_pos, 1)
            camera(c.x, c.y)
        end

        camera_lastpos = copyv(camera_pos)

        local current_segment = player.current_segment
        -- draw track

        local lastv,lastup,lastup2,lastup3,last_right_rail,lastdown,lastdown3,last_left_rail
        local panels={}
        for seg = current_segment - 20, current_segment + 20 do
            local v = get_data_from_vecmap(seg)
            local has_lrail = v.has_lrail
            local has_rrail = v.has_rrail

            if lastv then
                if onscreen(v) or onscreen(lastv) or onscreen(v.right_inner_rail) or onscreen(v.left_inner_rail)
                    or onscreen(lastv.right_inner_rail) or onscreen(lastv.left_inner_rail) then
                    local ltyp=v.ltyp & 7
                    local rtyp=v.rtyp & 7
                    local rtrack=v.right_track
                    local ltrack=v.left_track
                    local last_rtrack=lastv.right_track
                    local last_ltrack=lastv.left_track
                    local ri_rail=v.right_inner_rail
                    local li_rail=v.left_inner_rail
                    local last_ri_rail=lastv.right_inner_rail
                    local last_li_rail=lastv.left_inner_rail

                    -- edges
                    local track_color = 6
                    if rtyp == 1 then
                        -- grass
                        quadfill(last_rtrack,rtrack,last_ri_rail,ri_rail, 27)
                    elseif rtyp == 2 then
                        -- sand
                        quadfill(last_rtrack,rtrack,last_ri_rail,ri_rail, 15)
                    elseif rtyp == 3 then
                        -- asphalt
                        quadfill(last_rtrack,rtrack,last_ri_rail,ri_rail, 5)
                    end
                    if ltyp == 1 then
                        -- grass
                        quadfill(last_ltrack,ltrack,last_li_rail,li_rail, 27)
                    elseif ltyp == 2 then
                        -- sand
                        quadfill(last_ltrack,ltrack,last_li_rail,li_rail, 15)
                    elseif ltyp == 3 then
                        -- asphalt
                        quadfill(last_ltrack,ltrack,last_li_rail,li_rail, 5)
                    end
                    -- ground
                    local ground = seg % 2 == 0 and 5 or 32
                    quadfill(lastv.right_kerb, lastv.left_kerb, v.right_kerb, v.left_kerb, ground)
                    if seg % mapsize == 0 then
                        linevec(lastv.right_kerb, lastv.left_kerb, 10) -- start/end markers
                    end
                    -- kerbs
                    local midleft = midpoint(ltrack, last_ltrack)
                    local midleft_kerb = midpoint(v.left_kerb, lastv.left_kerb)
                    quadfill(v.left_kerb, ltrack, midleft_kerb, midleft, 7)
                    quadfill(last_ltrack, midleft, lastv.left_kerb, midleft_kerb, 8)
                    local midright = midpoint(rtrack, last_rtrack)
                    local midright_kerb = midpoint(v.right_kerb, lastv.right_kerb)
                    quadfill(v.right_kerb, rtrack, midright_kerb, midright, 7)
                    quadfill(midright_kerb, midright, lastv.right_kerb, last_rtrack, 8)
                    if rtyp == 0 then
                        -- normal crash barriers
                        linevec(last_rtrack, rtrack, track_color)
                    end
                    if ltyp == 0 then
                        -- normal crash barriers
                        linevec(last_ltrack, ltrack, track_color)
                    end
                    if ltyp ~= 0 then
                        linevec(last_ltrack, ltrack, 10)
                    end
                    if rtyp ~= 0 then
                        linevec(last_rtrack, rtrack, 10)
                    end
                    if has_rrail then
                        linevec(last_right_rail, v.right_outer_rail, track_color)
                    end
                    if has_lrail then
                        linevec(last_left_rail, v.left_outer_rail, track_color)
                    end
                    -- starting grid
                    local wseg = wrap(seg, mapsize)
                    if wseg > mapsize - #drivers//2-3 then
                        local side = scalev(v.side, 12)
                        local smallfront = scalev(v.front, -2)
                        local lfront = scalev(v.front, -10)
                        local p = vecadd(vecadd(lastv.right_kerb, side), lfront)
                        if wseg ~= mapsize-1 then
                            local p2 = vecadd(p, side)
                            linevec(p, p2, 7)
                            linevec(p, vecadd(p, smallfront), 7)
                            linevec(p2, vecadd(p2, smallfront), 7)
                        end
                        lfront = scalev(v.front, -24)
                        p = vecadd(vecsub(lastv.left_kerb, side), lfront)
                        if wseg ~= mapsize - #drivers//2-2 then
                            local p2 = vecsub(p, side)
                            linevec(p, p2, 7)
                            linevec(p, vecadd(p, smallfront), 7)
                            linevec(p2, vecadd(p2, smallfront), 7)
                        end
                    end
                    -- track side objects
                    local lobj = v.ltyp//8
                    local robj = v.rtyp//8
                    if lobj == OBJ_TRIBUNE then
                        local p = vecadd(li_rail,scalev(v.side,8))
                        local p2 = vecadd(p,scalev(v.side,10))
                        local p3 = vecadd(p,scalev(v.front,-32))
                        local p4 = vecadd(p2,scalev(v.front,-32))
                        quadfill(p,p2,p3,p4,22)
                        local p2s=cam2screen(vecadd(vecadd(p,scalev(v.side,5)),scalev(v.front,-16)))
                        gfx.blit(224,0,20,60,p2s.x,p2s.y,0,0,false,false,1,1,1,from_pico_angle(camera_angle-v.dir))
                        p=vecadd(p,scalev(v.side,50))
                        p3=vecadd(p3,scalev(v.side,50))
                        gfx.set_active_layer(LAYER_TOP)
                        quadfill(p,p2,p3,p4,seg%2==0 and 20 or 4)
                        gfx.set_active_layer(LAYER_SHADOW2)
                        local sd=SHADOW_DELTA
                        p = vecadd(p,sd)
                        p2 = vecadd(p2,sd)
                        p3 = vecadd(p3,sd)
                        p4 = vecadd(p4,sd)
                        quadfill(p,p2,p3,p4,22)
                        gfx.set_active_layer(0)
                    elseif lobj == OBJ_TRIBUNE2 then
                        local p = vecadd(li_rail,scalev(v.side,8))
                        local p2 = vecadd(p,scalev(v.side,40))
                        local p3 = vecadd(p,scalev(v.front,-32))
                        local p4 = vecadd(p2,scalev(v.front,-32))
                        quadfill(p,p2,p3,p4,22)
                        gfx.set_active_layer(LAYER_CARS)
                        local p2s=cam2screen(vecadd(vecadd(p,scalev(v.side,5)),scalev(v.front,-16)))
                        gfx.blit(244,0,20,60,p2s.x,p2s.y,0,0,false,false,1,1,1,from_pico_angle(camera_angle-v.dir))
                        local p2s=cam2screen(vecadd(vecadd(p,scalev(v.side,15)),scalev(v.front,-16)))
                        gfx.blit(264,0,20,60,p2s.x,p2s.y,0,0,false,false,1,1,1,from_pico_angle(camera_angle-v.dir))
                        local p2s=cam2screen(vecadd(vecadd(p,scalev(v.side,25)),scalev(v.front,-16)))
                        gfx.blit(244,0,20,60,p2s.x,p2s.y,0,0,false,false,1,1,1,from_pico_angle(camera_angle-v.dir))
                        local p2s=cam2screen(vecadd(vecadd(p,scalev(v.side,35)),scalev(v.front,-16)))
                        gfx.blit(264,0,20,60,p2s.x,p2s.y,0,0,false,false,1,1,1,from_pico_angle(camera_angle-v.dir))
                        gfx.set_active_layer(LAYER_SHADOW)
                        local sd=scalev(SHADOW_DELTA,0.1)
                        local r=SHADOW_COL.r
                        local g=SHADOW_COL.g
                        local b=SHADOW_COL.b
                        local p2s=cam2screen(vecadd(vecadd(vecadd(p,scalev(v.side,5)),scalev(v.front,-16)),sd))
                        gfx.blit(284,0,20,60,p2s.x,p2s.y,0,0,false,false,r,g,b,from_pico_angle(camera_angle-v.dir))
                        local p2s=cam2screen(vecadd(vecadd(vecadd(p,scalev(v.side,15)),scalev(v.front,-16)),sd))
                        gfx.blit(304,0,20,60,p2s.x,p2s.y,0,0,false,false,r,g,b,from_pico_angle(camera_angle-v.dir))
                        local p2s=cam2screen(vecadd(vecadd(vecadd(p,scalev(v.side,25)),scalev(v.front,-16)),sd))
                        gfx.blit(284,0,20,60,p2s.x,p2s.y,0,0,false,false,r,g,b,from_pico_angle(camera_angle-v.dir))
                        local p2s=cam2screen(vecadd(vecadd(vecadd(p,scalev(v.side,35)),scalev(v.front,-16)),sd))
                        gfx.blit(304,0,20,60,p2s.x,p2s.y,0,0,false,false,r,g,b,from_pico_angle(camera_angle-v.dir))
                        gfx.set_active_layer(0)
                    end
                    if robj == OBJ_TRIBUNE then
                        local p = vecsub(ri_rail,scalev(v.side,8))
                        local p2 = vecsub(p,scalev(v.side,10))
                        local p3 = vecadd(p,scalev(v.front,-32))
                        local p4 = vecadd(p2,scalev(v.front,-32))
                        quadfill(p,p2,p3,p4,22)
                        local p2s=cam2screen(vecadd(vecsub(p,scalev(v.side,5)),scalev(v.front,-16)))
                        gfx.blit(224,0,20,60,p2s.x,p2s.y,0,0,false,false,1,1,1,from_pico_angle(camera_angle-v.dir))
                        p=vecsub(p,scalev(v.side,50))
                        p3=vecsub(p3,scalev(v.side,50))
                        gfx.set_active_layer(LAYER_TOP)
                        quadfill(p,p2,p3,p4,seg%2==0 and 20 or 4)
                        gfx.set_active_layer(LAYER_SHADOW2)
                        local sd=SHADOW_DELTA
                        p = vecadd(p,sd)
                        p2 = vecadd(p2,sd)
                        p3 = vecadd(p3,sd)
                        p4 = vecadd(p4,sd)
                        quadfill(p,p2,p3,p4,22)
                        gfx.set_active_layer(0)
                    elseif robj == OBJ_TRIBUNE2 then
                        local p = vecsub(ri_rail,scalev(v.side,8))
                        local p2 = vecsub(p,scalev(v.side,40))
                        local p3 = vecadd(p,scalev(v.front,-32))
                        local p4 = vecadd(p2,scalev(v.front,-32))
                        quadfill(p,p2,p3,p4,22)
                        gfx.set_active_layer(LAYER_CARS)
                        local p2s=cam2screen(vecadd(vecsub(p,scalev(v.side,5)),scalev(v.front,-16)))
                        gfx.blit(244,0,20,60,p2s.x,p2s.y,0,0,false,false,1,1,1,from_pico_angle(camera_angle-v.dir))
                        local p2s=cam2screen(vecadd(vecsub(p,scalev(v.side,15)),scalev(v.front,-16)))
                        gfx.blit(264,0,20,60,p2s.x,p2s.y,0,0,false,false,1,1,1,from_pico_angle(camera_angle-v.dir))
                        local p2s=cam2screen(vecadd(vecsub(p,scalev(v.side,25)),scalev(v.front,-16)))
                        gfx.blit(244,0,20,60,p2s.x,p2s.y,0,0,false,false,1,1,1,from_pico_angle(camera_angle-v.dir))
                        local p2s=cam2screen(vecadd(vecsub(p,scalev(v.side,35)),scalev(v.front,-16)))
                        gfx.blit(264,0,20,60,p2s.x,p2s.y,0,0,false,false,1,1,1,from_pico_angle(camera_angle-v.dir))
                        gfx.set_active_layer(LAYER_SHADOW)
                        local sd=scalev(SHADOW_DELTA,0.1)
                        local r=SHADOW_COL.r
                        local g=SHADOW_COL.g
                        local b=SHADOW_COL.b
                        local p2s=cam2screen(vecadd(vecadd(vecsub(p,scalev(v.side,5)),scalev(v.front,-16)),sd))
                        gfx.blit(244,0,20,60,p2s.x,p2s.y,0,0,false,false,1,1,1,from_pico_angle(camera_angle-v.dir))
                        local p2s=cam2screen(vecadd(vecadd(vecsub(p,scalev(v.side,15)),scalev(v.front,-16)),sd))
                        gfx.blit(264,0,20,60,p2s.x,p2s.y,0,0,false,false,1,1,1,from_pico_angle(camera_angle-v.dir))
                        local p2s=cam2screen(vecadd(vecadd(vecsub(p,scalev(v.side,25)),scalev(v.front,-16)),sd))
                        gfx.blit(244,0,20,60,p2s.x,p2s.y,0,0,false,false,1,1,1,from_pico_angle(camera_angle-v.dir))
                        local p2s=cam2screen(vecadd(vecadd(vecsub(p,scalev(v.side,35)),scalev(v.front,-16)),sd))
                        gfx.blit(264,0,20,60,p2s.x,p2s.y,0,0,false,false,1,1,1,from_pico_angle(camera_angle-v.dir))
                        gfx.set_active_layer(0)
                    end

                    if v.lpanel ~= nil then
                        local p=cam2screen(v.left_inner_rail)
                        local y=214+10*v.lpanel
                        panels[#panels+1]={y,p.x,p.y,v.dir}
                    elseif v.rpanel ~= nil then
                        local p=cam2screen(v.right_inner_rail)
                        local y=214+10*v.rpanel
                        panels[#panels+1]={y,p.x,p.y,v.dir}
                    end
                end
            end
            if has_rrail then
                last_right_rail=v.right_outer_rail
            end
            if has_lrail then
                last_left_rail=v.left_outer_rail
            end
            lastv = v
        end

        for i=1,#panels do
            local p=panels[i]
            gfx.blit(91,p[1],24,10,p[2],p[3],0,0,false,false,1,1,1,from_pico_angle(camera_angle-p[4]))
        end
        -- draw objects
        gfx.set_active_layer(LAYER_CARS)
        for _, obj in pairs(self.objects) do
            local oseg=player_lap_seg(obj.current_segment)
            if abs(oseg-player.current_segment) <10 then
                obj:draw()
            end
        end

        for _, p in pairs(particles) do
            if p.enabled then
                p:draw()
            end
        end
        gfx.set_active_layer(LAYER_SMOKE)
        gfx.clear(0, 0, 0)
        if not self.completed then
            for _, p in pairs(smokes) do
                if p.enabled then
                    p:draw()
                end
            end
        end
        -- DEBUG : display segments collision shapes
        -- seg=get_segment(player.current_segment-1,false,true)
        -- quadfill(seg[1],seg[2],seg[4],seg[3],11)
        -- local seg=get_segment(player.current_segment+1,false,true)
        -- quadfill(seg[1],seg[2],seg[4],seg[3],12)
        -- local seg=get_segment(player.current_segment,false,true)
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
            for _, car in pairs(self.objects) do
                car:draw_minimap()
            end
        end

        camera()

        local lap = flr(player.current_segment / mapsize) + 1
        printr(gfx.fps().." fps",gfx.SCREEN_WIDTH-1,1,7)

        -- car dashboard
        if not self.completed then
            gfx.blit(0, 224, 66, 35, gfx.SCREEN_WIDTH - 66, gfx.SCREEN_HEIGHT - 35, 0, 0, false, false, 1, 1, 1)
            printc("" .. flr(player.speed * 10), 370, 210, 28)
            gfx.blit(66, 224, 25 * min(1, player.speed / 15), 8, gfx.SCREEN_WIDTH - 28, gfx.SCREEN_HEIGHT - 23, 0, 0,
                false, false, 1, 1, 1)
            gfx.blit(66, 232, 19 * min(1, (player.accel ^ 3) / (1.5 ^ 3)), 9, gfx.SCREEN_WIDTH - 60,
                gfx.SCREEN_HEIGHT - 22, 0, 0, false, false, 1, 1, 1)

            if player.cooldown > 0 then
                if frame % 4 < 2 then
                    gfx.blit(66, 249, 21 * (1 - player.cooldown / 30), 4, gfx.SCREEN_WIDTH - 61, gfx.SCREEN_HEIGHT - 11,
                        0, 0, false, false, 1, 1, 1)
                end
            else
                local spritey = (player.boost < boost_warning_thresh and frame % 4 < 2) and 245 or 241
                gfx.blit(66, spritey, 21 * (player.boost / 100), 4, gfx.SCREEN_WIDTH - 61, gfx.SCREEN_HEIGHT - 11, 0, 0,
                    false, false, 1, 1, 1)
            end
            if self.race_mode == MODE_RACE and self.panel_timer >= 0 then
                -- stand panel
                local x=gfx.SCREEN_WIDTH-90
                local y=50
                gfx.rectangle(x,y,85,44,0.2,0.2,0.2)
                gprint("P"..self.panel_placing,x+3,y+3,10)
                if self.panel_placing > 1 then
                    gprint(self.panel_prev_time.." "..self.panel_prev.driver.short_name,x+3,y+13,10)
                end
                if self.panel_placing < 16 then
                    gprint(self.panel_next_time.." "..self.panel_next.driver.short_name,x+3,y+23,10)
                end
                gprint("Lap "..lap,x+3,y+33,10)
            end
            if player.ccut_timer >= 0 then
                local x=gfx.SCREEN_WIDTH-92
                gfx.rectangle(x,50,90,60,0.2,0.2,0.2)
                printc("Warning!",x+45,53,8)
                printc("Corner",x+45,63,9)
                printc("cutting",x+45,73,9)
                gfx.blit(115,224,26,16,x+45-13,83,0,0,false,false,1,1,1)
            end
        end
        if self.race_mode==MODE_RACE and self.best_lap_timer >= 0 then
            local x=200
            local y=0
            gfx.rectangle(x,y,100,18,0.2,0.2,0.2)
            printc("Best lap "..best_lap_driver.short_name,x+50,y+1,9)
            printc(format_time(best_lap_time),x+50,y+9,9)
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
                for rank, car in pairs(self.ranks) do
                    gprint(string.format("%2d", rank), 4, y, car.is_player and 7 or 6)
                    gprint(car.driver.short_name, 32, y, car.is_player and 7 or 6)
                    gprint(string.format("%7s", rank == 1 and leader_time or car.time),
                        60, y, car.is_player and 7 or 6)
                    rectfill(21, y, 27, y + 8, car.color)
                    if car.race_finished then
                        gfx.blit(149,0,6,8,57,y,0,0,false,false,1,1,1)
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
            gfx.rectangle(30, 10, gfx.SCREEN_WIDTH - 52, (#drivers + 4) * 10, PAL[17].r, PAL[17].g, PAL[17].b)
            gprint("Classification          Time   Best", 61, 20, 6)
            gfx.line(30, 30, gfx.SCREEN_WIDTH - 22, 30, PAL[6].r, PAL[6].g, PAL[6].b)
            for rank, car in pairs(self.ranks) do
                local y = 26 + rank * 10
                gprint(string.format("%2d %s %15s  %7s", rank, teams[car.driver.team].short_name, car.driver.name,
                    rank == 1 and format_time(car.delta_time) or car.time),
                    53, y, car.is_player and 7 or 22)
                if car.best_time then
                    gprint(format_time(car.best_time), 309, y, car.driver.is_best and 8 or (car.is_player and 7 or 22))
                end
                rectfill(69, y - 1, 75, y + 7, car.color)
                if car.race_finished then
                    gfx.blit(149,0,6,8,233,y,0,0,false,false,1,1,1)
                end
            end
        end
        -- lap times
        if not self.completed and self.race_mode == MODE_RACE then
            if lap > 1 then
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
                gfx.blit(34, 0, 20, 20, 217 + i * 22, 44, 0, 0, false, false, 1, 1, 1)
            end
            for i = lit + 1, 3 do
                gfx.blit(14, 0, 20, 20, 217 + i * 22, 44, 0, 0, false, false, 1, 1, 1)
            end
        end
        if player.collision > 0 or self.completed then
            player.collision = player.collision - 0.1
        end
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
                snd.stop_note(1)
                snd.stop_note(2)
                game:restart()
            elseif selected == 3 then
                snd.stop_note(1)
                snd.stop_note(2)
                set_game_mode(intro)
            end
        end
    end
    function m:draw()
        game:draw()
        rectfill(115, 40, 233, 88, 1)
        gprint("Paused", 120, 44, 7)
        gprint("Continue", 120, 56, selected == 1 and frame % 4 < 2 and 7 or 6)
        gprint("Restart race", 120, 62, selected == 2 and frame % 4 < 2 and 7 or 6)
        gprint("Exit", 120, 70, selected == 3 and frame % 4 < 2 and 7 or 6)
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
    return vec(mid(-max, v.x, max), mid(-max, v.y, max))
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

function player_lap_seg(s1)
    return car_lap_seg(s1,player)
end
function car_lap_seg(s1, s2)
    local pseg=s2.current_segment
    while abs(s1+mapsize - pseg) < abs(s1-pseg) do
        s1 = s1+mapsize
    end
    while abs(s1-mapsize - pseg) < abs(s1-pseg) do
        s1=s1-mapsize
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

function get_vec_from_vecmap(seg)
    seg = wrap(seg, mapsize)
    local v = vecmap[seg+1]
    return vec(v.x,v.y)
end

function get_data_from_vecmap(seg)
    seg = wrap(seg, mapsize)
    return vecmap[seg+1]
end

function get_segment(seg, enlarge, for_collision)
    seg = wrap(seg, mapsize)
    -- returns the 4 points of the segment
    local v = get_data_from_vecmap(seg + 1)
    local lastv = get_data_from_vecmap(seg)
    local lastlastv = get_vec_from_vecmap(seg - 1)

    local front=v.front
    local side = v.side
    local lastfront=lastv.front
    local lastside = lastv.side

    local lastwl = (for_collision and not lastv.has_lrail) and 200 or (lastv.ltyp & 7==0 and lastv.w or lastv.w+40)
    local lastwr = (for_collision and not lastv.has_rrail) and 200 or (lastv.rtyp & 7==0 and lastv.w or lastv.w+40)
    local wl = (for_collision and not v.has_lrail) and 200 or (v.ltyp & 7==0 and v.w or v.w+40)
    local wr = (for_collision and not v.has_rrail) and 200 or (v.rtyp & 7==0 and v.w or v.w+40)
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
    local front_left=vecadd(v, offsetl)
    local front_right=vecsub(v, offsetr)
    local back_left=vecadd(lastv, lastoffsetl)
    local back_right=vecsub(lastv, lastoffsetr)
    if dot(vecsub(front_left,v),lastfront)<dot(vecsub(back_left,v),lastfront) then
        local v=intersection(front_left,front_right, back_left,back_right)
        front_left,back_left=v,v
    end
    if dot(vecsub(front_right,v),lastfront)<dot(vecsub(back_right,v),lastfront) then
        local v=intersection(front_left,front_right, back_left,back_right)
        front_right,back_right=v,v
    end
    return {back_left, back_right, front_right, front_left}
end

-- intersection between segments [ab] and [cd]
function intersection(a,b,c,d)
    local e=(a.x-b.x)*(c.y-d.y)-(a.y-b.y)*(c.x-d.x)
    if e~=0 then
        local i,j = a.x*b.y-a.y*b.x, c.x*d.y-c.y*d.x
        local x=(i*(c.x-d.x)-j*(a.x-b.x))/e
        local y=(i*(c.y-d.y)-j*(a.y-b.y))/e
        return vec(x,y)
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

function vecinv(v)
    return vec(-v.x, -v.y)
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
    for _, point in pairs(points) do
        for _, line in pairs(lines) do
            if side_of_line(line[1], line[2], point.x, point.y) < 0 then
                local rvec = get_normal(line[1], line[2])
                local penetration = distance_from_line(point, line[1], line[2])
                return rvec, penetration, point
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
    [0] = {1337, 10, 128, 32, 9,0,0,0, 4, 128, 32, 1,0,0,0,  10, 128, 32, 9,0,0,0, 2, 128, 32, 1,1,0,0, 4, 128, 32, 17,1,0,0, 4, 128, 32, 1,1,0,-1,
        -- prima variante
        3, 120, 32, 1,1,-1,3, 3, 140, 32, 1,17,3,0,
        -- curva biassono
        2, 126, 32, 1,0,0,0, 2, 126, 32, 17,0,1,0, 2, 126, 32, 1,0,0,0,
        6, 128, 32, 1,0,0,0, 8, 126, 32, 2,0,0,0, 6, 127,32, 2,0,0,0, 9, 128, 32, 0,0,0,0, 1, 128, 32, 1,0,1,0,
        -- seconda variante
        2, 137, 32, 1,3,1,0, 3, 123, 32, 2,3,0,0, 2, 128, 32, 0,16,0,0, 8, 128, 32, 0,0,0,0,
        -- prima curva di lesmo
        9, 125, 32, 2,0,0,0, 8, 128, 32, 1,0,0,0,
        -- seconda curva di lesmo
        4, 123.0, 32, 2,0,0,0,  4, 128, 32, 2,0,0,0, 8, 128, 32, 0,0,0,0,
        -- curva del serraglio
        5, 129, 32, 0,0,0,0, 16, 128, 32, 0,0,0,0,
        -- variante ascari
        5, 131, 32, 1,2,0,0,
        7, 125, 32,2,1,0,0,  6, 131, 32,1,18,0,0,  2, 128, 32,0,0,0,0, 6, 128, 32,0,8,0,0, 21, 128, 32,0,0,0,0, 6, 128, 32,16,0,0,0,  2, 128, 32,8,0,0,0,
        -- curva parabolica
        5, 121.1, 32,3,0,0,0,  7, 127.1, 32,3,0,0,0,  6, 126.8,32, 2,0,0,0, 2, 126.8,32, 10,0,0,0,
        12, 128.0, 32, 8,0,0,0,  0, 0, 0,0,0,0,0},
    {10, 128, 32, 10, 125, 32, 10, 127, 32, 6, 127, 32, 6, 121, 32, 6, 120, 32, 6, 120, 32, 6, 120, 32, 6, 125, 32, 6,
     135, 32, 6, 131, 32, 6, 129, 32, 6, 130, 32, 6, 131, 32, 6, 130, 32, 6, 129, 32, 6, 128, 32, 6, 125, 32, 6, 125,
     32, 6, 124, 32, 6, 124, 32, 6, 123, 32, 6, 121, 32, 6, 127, 32, 6, 136, 32, 6, 128, 32, 6, 128, 32, 6, 126, 32, 6,
     125, 32, 6, 125, 32, 6, 125, 32, 6, 129, 32, 6, 131, 32, 3, 129, 32, 3, 125, 32, 3, 127, 32, 0, 0, 0},
    {10, 128, 32, 10, 129, 32, 10, 129, 32, 10, 138, 32, 10, 138, 32, 10, 124, 32, 10, 125, 32, 10, 127, 32, 10, 129,
     32, 10, 129, 32, 10, 128, 32, 10, 130, 32, 10, 129, 32, 10, 128, 32, 10, 122, 32, 10, 122, 32, 10, 123, 32, 10,
     127, 32, 10, 131, 32, 10, 131, 32, 10, 128, 32, 10, 126, 32, 10, 126, 32, 10, 128, 32, 10, 128, 32, 10, 127, 32,
     10, 122, 32, 10, 135, 32, 10, 121, 32, 10, 129, 32, 10, 130, 32, 10, 130, 32, 9, 129, 32, 4, 126, 32, 2, 124, 32,
     2, 126, 32, 0, 0, 0},
    {10, 128, 32, 10, 128, 32, 10, 132, 32, 10, 130, 32, 10, 121, 32, 10, 132, 32, 10, 134, 32, 10, 136, 32, 10, 122,
     32, 10, 127, 32, 10, 126, 32, 10, 133, 32, 10, 130, 32, 10, 128, 32, 10, 128, 32, 10, 131, 32, 10, 128, 32, 10,
     122, 32, 10, 122, 32, 10, 122, 32, 10, 122, 32, 10, 128, 32, 10, 128, 32, 10, 130, 32, 10, 132, 32, 10, 128, 32,
     10, 126, 32, 10, 129, 32, 10, 126, 32, 10, 126, 32, 10, 128, 32, 10, 128, 32, 10, 127, 32, 10, 123, 32, 10, 129,
     32, 10, 130, 32, 7, 127, 32, 4, 127, 32, 2, 124, 32, 2, 129, 32, 2, 126, 32, 0, 0, 0},
    {10, 128, 32, 6, 136, 32, 3, 131, 32, 3, 113, 32, 3, 124, 32, 3, 125, 32, 3, 126, 32, 3, 138, 32, 3, 137, 32, 3,
     140, 32, 3, 129, 32, 3, 128, 32, 3, 127, 32, 3, 127, 32, 3, 127, 32, 3, 127, 32, 3, 123, 32, 3, 122, 32, 3, 119,
     32, 3, 123, 32, 3, 144, 32, 16, 129, 32, 3, 113, 32, 3, 144, 32, 3, 112, 32, 3, 145, 32, 3, 131, 32, 11, 126, 32,
     11, 125, 32, 5, 129, 32, 5, 138, 32, 5, 138, 32, 5, 138, 32, 5, 138, 32, 5, 123, 32, 5, 127, 32, 2, 131, 32, 2,
     130, 32, 2, 127, 32, 2, 129, 32, 1, 124, 32, 0, 0, 0},
    {10, 127, 32, 10, 128, 32, 3, 120, 32, 3, 128, 32, 3, 128, 32, 3, 133, 32, 3, 133, 32, 3, 129, 32, 3, 131, 32, 3,
     132, 32, 3, 133, 32, 3, 122, 32, 3, 128, 32, 3, 128, 32, 3, 128, 32, 3, 128, 32, 3, 135, 32, 3, 124, 32, 3, 122,
     32, 3, 127, 32, 3, 133, 32, 2, 137, 32, 20, 124, 32, 13, 130, 32, 13, 126, 32, 13, 130, 32, 13, 126, 32, 13, 126,
     32, 8, 128, 32, 8, 131, 32, 8, 130, 32, 8, 126, 32, 8, 124, 32, 8, 127, 32, 8, 129, 32, 8, 128, 32, 8, 127, 32, 8,
     127, 32, 8, 127, 32, 8, 131, 32, 4, 132, 32, 4, 123, 32, 4, 128, 32, 4, 139, 32, 4, 126, 32, 4, 126, 32, 4, 126,
     32, 4, 133, 32, 4, 130, 32, 4, 127, 32, 4, 127, 32, 4, 126, 32, 4, 126, 32, 4, 120, 32, 4, 120, 32, 4, 120, 32, 4,
     120, 32, 4, 120, 32, 4, 123, 32, 4, 128, 32, 4, 130, 32, 4, 130, 32, 4, 131, 32, 4, 130, 32, 4, 129, 32, 3, 128,
     32, 2, 127, 32, 2, 126, 32, 1, 132, 32, 0, 0, 0},
    {10, 127, 32, 8, 129, 32, 8, 129, 32, 3, 118, 32, 3, 140, 32, 3, 134, 32, 3, 132, 32, 3, 120, 32, 3, 123, 32, 3,
     127, 32, 3, 139, 32, 11, 126, 32, 11, 121, 32, 5, 126, 32, 5, 131, 32, 5, 131, 32, 4, 133, 32, 4, 121, 32, 6, 124,
     32, 6, 130, 32, 6, 136, 32, 6, 125, 32, 6, 128, 32, 6, 129, 32, 2, 118, 32, 2, 120, 32, 4, 128, 32, 4, 126, 32, 4,
     125, 32, 4, 134, 32, 4, 127, 32, 4, 122, 32, 4, 129, 32, 4, 140, 32, 10, 127, 32, 10, 127, 32, 10, 130, 32, 10,
     129, 32, 10, 128, 32, 10, 128, 32, 3, 138, 32, 3, 115, 32, 3, 126, 32, 8, 131, 32, 8, 130, 32, 8, 126, 32, 8, 129,
     32, 4, 120, 32, 8, 133, 32, 8, 128, 32, 8, 130, 32, 3, 122, 32, 8, 128, 32, 8, 131, 32, 8, 126, 32, 8, 136, 32, 8,
     136, 32, 8, 136, 32, 8, 136, 32, 8, 128, 32, 8, 126, 32, 8, 123, 32, 8, 137, 32, 8, 119, 32, 8, 137, 32, 16, 124,
     32, 16, 127, 32, 16, 132, 32, 16, 127, 32, 16, 127, 32, 16, 117, 32, 16, 132, 32, 6, 125, 32, 6, 128, 33, 3, 128,
     33, 1, 131, 34, 0, 0, 0},
    {10, 129, 32, 10, 128, 32, 3, 138, 32, 3, 118, 32, 3, 128, 32, 3, 137, 32, 3, 124, 32, 7, 126, 32, 6, 128, 32, 6,
     124, 32, 6, 128, 32, 6, 125, 32, 6, 128, 32, 6, 128, 32, 6, 128, 32, 6, 129, 32, 6, 129, 32, 6, 126, 32, 6, 126,
     32, 6, 127, 32, 6, 129, 32, 6, 128, 32, 2, 114, 32, 5, 128, 32, 2, 139, 32, 8, 128, 32, 11, 122, 32, 11, 122, 32,
     11, 122, 32, 11, 122, 32, 4, 138, 32, 5, 124, 32, 5, 129, 32, 5, 136, 32, 5, 129, 32, 5, 129, 32, 5, 127, 32, 5,
     128, 32, 2, 118, 32, 2, 125, 32, 2, 140, 32, 7, 129, 32, 4, 113, 32, 9, 130, 32, 9, 130, 32, 2, 104, 32, 6, 128,
     32, 6, 132, 32, 6, 132, 32, 6, 131, 32, 6, 137, 32, 6, 137, 32, 6, 137, 32, 6, 137, 32, 6, 137, 32, 6, 137, 32, 6,
     137, 32, 6, 129, 32, 6, 128, 32, 6, 128, 32, 6, 119, 32, 6, 119, 32, 6, 119, 32, 6, 126, 32, 6, 134, 32, 6, 129,
     32, 6, 128, 32, 6, 123, 32, 6, 128, 32, 6, 126, 32, 6, 126, 32, 6, 132, 32, 3, 138, 32, 3, 132, 32, 3, 125, 32, 3,
     125, 32, 2, 130, 33, 1, 127, 33, 0, 127, 33, 0, 0, 0}
}

SFX =
    {"PAT 12 D.2343 D.6615 D.6625 D.6615 D.2343 D.6615 D.6625 D.6615 D.2373 D.5603 D.2603 D.6643 D.2373 D.5603 D.6643 D.6643 D.2373 D.5603 D.2603 D.6643 D.2373 D.5603 D.6643 D.6643 D.2373 D.5603 D.5603 D.6643 D.2373 D.2303 D.6643 D.6643",
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
     "PAT 16 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......"}

-- pico8 instruments
INST_TRIANGLE = "INST OVERTONE 1.0 TRIANGLE 1.0 METALIZER 0.85 NAM triangle"
INST_TILTED = "INST OVERTONE 1.0 TRIANGLE 0.5 SAW 0.1 NAM tilted"
INST_SAW = "INST OVERTONE 1.0 SAW 1.0 ULTRASAW 1.0 NAM saw"
INST_SQUARE = "INST OVERTONE 1.0 SQUARE 0.5 NAM square"
INST_PULSE = "INST OVERTONE 1.0 SQUARE 0.5 PULSE 0.5 TRIANGLE 1.0 METALIZER 1.0 OVERTONE_RATIO 0.5 NAM pulse"
INST_ORGAN = "INST OVERTONE 0.5 TRIANGLE 0.75 NAM organ"
INST_NOISE = "INST NOISE 1.0 NOISE_COLOR 0.2 NAM noise"
INST_PHASER = "INST OVERTONE 0.5 METALIZER 1.0 TRIANGLE 0.7 NAM phaser"
INST_ENGINE = "INST OVERTONE 1.0 METALIZER 1.0 TRIANGLE 1.0 NAM engine"
INST_TRIBUNE="SAMPLE ID 01 FILE picoracer/tribune.wav FREQ 17000 LOOP_START 0 LOOP_END 102013"
