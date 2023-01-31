-- pico racer 2048
-- by impbox software
--
-- viper port by jice

X_OFFSET = 80
Y_OFFSET = 0
cam_pos = {
    x=0,
    y=0
}
function camera(x,y)
    cam_pos.x=x or 0
    cam_pos.y=y or 0
end
function btn(num,player)
    if num == 0 then
        return inp.left(player or 0)
    elseif num == 1 then
        return inp.right(player or 0)
    elseif num == 2 then
        return inp.up(player or 0)
    elseif num == 3 then
        return inp.down(player or 0)
    elseif num == 4 then
        return inp.pad_button(player or 0,0)
    elseif num == 5 then
        return inp.pad_button(player or 0,1)
    end
end
function btnp(num,player)
    if num == 0 then
        return inp.left_pressed(player or 0)
    elseif num == 1 then
        return inp.right_pressed(player or 0)
    elseif num == 2 then
        return inp.up_pressed(player or 0)
    elseif num == 3 then
        return inp.down_pressed(player or 0)
    elseif num == 4 then
        return inp.pad_button_pressed(player or 0,0)
    elseif num == 5 then
        return inp.pad_button_pressed(player or 0,1)
    end
end
function cls()
    gfx.clear(0,0,1/255)
end
function sspr(x, y, w, h, dx, dy, dw, dh, hflip, vflip)
    gfx.blit(x, y, w, h, dx + X_OFFSET,dy + Y_OFFSET,dw or 0,dh or 0, hflip or false,vflip or false,1,1,1)
end
cos= function(v)
    return math.cos(from_pico_angle(v))
end
sin=function(v)
    return math.sin(from_pico_angle(v))
end
from_pico_angle=function(v)
    return v < 0.5 and -v*2*math.pi or (1-v)*2*math.pi
end
to_pico_angle=function(a)
    local ra=a/math.pi
    local picoa= ra < 0 and -ra/2 or 1-ra/2
    return picoa
end
rnd=function(n)
    return math.random()*n
end
abs=math.abs
sqrt=math.sqrt
flr=math.floor
min=math.min
max=math.max
col = function(r, g, b)
    return {
        r = r / 255,
        g = g / 255,
        b = b / 255
    }
end
-- pico8 palette
PAL = {col(0, 0, 1), col(29, 43, 83), col(126, 37, 83), col(0, 135, 81), col(171, 82, 54), col(95, 87, 79),
       col(194, 195, 199), col(255, 241, 232), col(255, 0, 77), col(255, 163, 0), col(255, 236, 39), col(0, 228, 54),
       col(41, 173, 255), col(131, 118, 156), col(255, 119, 168), col(255, 204, 170)}
function line(x1, y1, x2, y2, col)
    local c=flr(col)
    gfx.line((x1-cam_pos.x)*224/128 + X_OFFSET, (y1-cam_pos.y)*224/128 + Y_OFFSET,
        (x2-cam_pos.x)*224/128 + X_OFFSET, (y2-cam_pos.y)*224/128 + Y_OFFSET,
        PAL[c].r, PAL[c].g, PAL[c].b)
end
function circfill(x,y,r,pal)
    local col=PAL[flr(pal)]
    local x = (x-cam_pos.x)*224/128 + X_OFFSET
    local y = (y-cam_pos.y)*224/128 + Y_OFFSET
    gfx.disk(x,y,r*224/128,col.r,col.g,col.b)
end
function rectfill(x0,y0,x1,y1,pal)
    local col=PAL[flr(pal)]
    local x0 = x0 + X_OFFSET
    local x1 = x1 + X_OFFSET
    local y0 = y0 + Y_OFFSET
    local y1 = y1 + Y_OFFSET
    gfx.rectangle(x0, y0, x1-x0+1, y1-y0+1, col.r,col.g,col.b)
end
function mid(x,y,z)
    if (x <= y and y <= z) or (z <= y and y <= x) then
        return y
    elseif (y <= x and x <= z) or (z <= x and x <= y) then
            return x
    else
        return z
    end
end
function gprint(msg, px, py, col)
    local c = math.floor(col + 1)
    gfx.print(msg, math.floor(px + X_OFFSET), math.floor(py + Y_OFFSET), PAL[c].r, PAL[c].g, PAL[c].b)
end
function sfx(n)
    snd.play_pattern(n)
end

TILEMAP = {}

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
    maxacc = 2,
    steer = 0.0185,
    accsqr = 0.15
}, {
    name = "Hard",
    maxacc = 2.5,
    steer = 0.0165,
    accsqr = 0.2
}}

track_colors = {8, 9, 10, 11, 12, 3, 14, 15}
dt = 0.033333
-- globals

particles = {}
mapsize = 250

function ai_controls(car)
    -- look ahead 5 segments
    local ai = {
        decisions = rnd(5) + 3,
        target_seg = 1,
        riskiness = rnd(23) + 1
    }
    ai.car = car
    function ai:update()
        self.decisions = self.decisions + dt * (self.skill + rnd(6))
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
        if t < (mapsize * 3) + 10 then
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
                -- break
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
        current_segment = -3,
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
        collision = 0
    }
    car.controls = {}
    car.pos = copyv(get_vec_from_vecmap(car.current_segment))
    function car:get_poly()
        return fmap(car_verts, function(i)
            return rotate_point(vecadd(self.pos, i), self.angle, self.pos)
        end)
    end
    function car:update()
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
            if self.is_player and
                (sc1 == 37 or sc1 == 39 or sc1 == 36 or ((sc1 == 38 or sc1 == 40) and self.collision <= 0) or
                    (sc1 == 34 and self.boost > 10)) then
                -- engine noise
                sfx(35)
                sc1 = 35
            end
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
                poly = get_segment(current_segment)
            else
                -- not found in current segment, try the next
                local segnextpoly = get_segment(current_segment + 1, true)
                if segnextpoly and point_in_polygon(segnextpoly, self.pos) then
                    poly = get_segment(current_segment + 1)
                    current_segment = current_segment + 1
                    self.wrong_way = 0
                else
                    -- not found in current or next, try the previous one
                    local segprevpoly = get_segment(current_segment - 1, true)
                    if segprevpoly and point_in_polygon(segprevpoly, self.pos) then
                        poly = get_segment(current_segment - 1)
                        current_segment = current_segment - 1
                        self.wrong_way = self.wrong_way + 1
                    else
                        -- completely lost the player
                        self.lost_count = self.lost_count + 1
                        -- current_segment+=1 -- try to find the car next frame
                        if self.lost_count > 30 then
                            -- lost for too long, bring them back to the last known good position
                            local v = get_vec_from_vecmap(self.last_good_seg)
                            self.pos = copyv(v)
                            self.current_segment = self.last_good_seg - 2
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
            -- check collisions with walls
            if poly then
                local car_poly = self:get_poly()
                local rv, pen, point = check_collision(car_poly, {{poly[2], poly[3]}, {poly[4], poly[1]}})
                if rv then
                    if pen > 5 then
                        pen = 5
                    end
                    vel = vecsub(vel, scalev(rv, pen))
                    accel = accel * (1.0 - (pen / 10))
                    table.insert(particles, {
                        x = point.x,
                        y = point.y,
                        xv = -rv.x + (rnd(2) - 1) / 2,
                        yv = -rv.y + (rnd(2) - 1) / 2,
                        ttl = 30
                    })
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
        -- check for boosters under us
        -- if current_segment then
        --	for _,b in pairs(boosters) do
        --		if b.segment <= current_segment+1 and b.segment >= current_segment-1 then
        --			local bx = b.x
        --			local by = b.y
        --			local pa = rotate_point(bx-12,by-12,b.dir,bx,by)
        --			local pb = rotate_point(bx+12,by-12,b.dir,bx,by)
        --			local pc = rotate_point(bx+12,by+12,b.dir,bx,by)
        --			local pd = rotate_point(bx-12,by+12,b.dir,bx,by)
        --			if point_in_polygon({pa,pb,pc,pd},vec(x,y)) then
        --				xv*=1.25
        --				yv*=1.25
        --				if self.is_player then
        --					sfx(sfx_booster)
        --					sc1=sfx_booster
        --					sc1timer=10
        --				end
        --			end
        --		end
        --	end
        -- end

        local car_dir = vec(cos(angle), sin(angle))
        self.vel = vecadd(vel, scalev(car_dir, accel))
        self.pos = vecadd(self.pos, scalev(self.vel, 0.3))
        self.vel = scalev(self.vel, 0.9)

        cbufpush(self.trails, rotate_point(vecadd(self.pos, trail_offset), angle, self.pos))

        -- update self attrs
        self.accel = accel
        self.speed = speed -- used for showing speedo
        self.angle = angle
        self.current_segment = current_segment
    end
    function car:draw()
        local angle = self.angle
        local color = self.color
        local v = fmap(car_verts, function(i)
            return rotate_point(vecadd(self.pos, i), angle, self.pos)
        end)
        local a = v[1]
        local b = v[2]
        local c = v[3]
        local boost = self.boost
        linevec(a, b, color)
        linevec(b, c, color)
        linevec(c, a, color)
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
    car_verts = {vec(-4, -3), vec(4, 0), vec(-4, 3)}
	for _,sfx in pairs(SFX) do
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
    gfx.set_active_layer(1)
    gfx.set_layer_size(1,224,224)
    gfx.load_img("picoracer","picoracer/picoracer.png")
    gfx.set_active_layer(0)
    gfx.set_sprite_layer(1)
    trail_offset = vec(-6, 0)
    intro:init()
    set_game_mode(intro)
end

function render()
    game_mode:draw()
end

flipflop=true
function update()
    -- original game updates at 30fps, viper is 60fps
    -- update only every 2 ticks
    flipflop=not flipflop
    if flipflop then
        game_mode:update()
    end
end

-- intro

intro = {}
frame = 0

game_modes = {"Race vs AI", "Time Attack", "Track Editor"}

function intro:init()
    -- music(0)
    difficulty = 0
    load_map()
    self.game_mode = 1
    self.car = 1
    self.option = 1
end

function intro:update()
    frame = frame + 1

    if not btn(4) then
        self.ready = true
    end

    if self.ready and btnp(4) then
        if self.game_mode == 3 then
            mapeditor:init()
            set_game_mode(mapeditor)
        else
            local race = race()
            race:init(difficulty, self.game_mode)
            set_game_mode(race)
        end
    end

    if self.option == 1 then
        if btnp(0) then
            self.game_mode = self.game_mode - 1
        end
        if btnp(1) then
            self.game_mode = self.game_mode + 1
        end
    elseif self.option == 2 then
        if btnp(0) then
            difficulty = mid(0, difficulty - 1, 7)
            load_map()
        end
        if btnp(1) then
            difficulty = mid(0, difficulty + 1, 7)
            load_map()
        end
    elseif self.option == 3 then
        if btnp(0) then
            self.car = self.car - 1
        end
        if btnp(1) then
            self.car = self.car + 1
        end
    end
    if btnp(2) then
        self.option = self.option - 1
    end
    if btnp(3) then
        self.option = self.option + 1
    end
    self.game_mode = mid(1, self.game_mode, 3)
    self.option = mid(1, self.option, 3)
    self.car = mid(1, self.car, 3)
end

difficulty_names = {
    [0] = "Berlin",
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
    sspr(0, 20, 224, 204, 0, 0)
    draw_minimap(40, 68, 0.025, 6)
    printr("x - accel", 223, 60, 6)
    printr("c - brake", 223, 70, 6)
    printr("up - boost", 223, 80, 6)
    printr("< > - steer", 223, 90, 6)
    printr("tab -  menu", 223, 100, 6)

    local c = frame % 16 < 8 and 8 or 9
    printr("Mode", 223, 2, self.option == 1 and c or 9)
    printr(game_modes[self.game_mode], 223, 12, 6)
    printr("Track", 224, 22, self.option == 2 and c or 9)
    printr(difficulty_names[difficulty], 224, 32, 6)
    printr(cars[self.car].name, 224, 42, self.option == 3 and c or 9)
end

mapeditor = {}
function mapeditor:init()
    scale = 0.05
end

function map_menu(game)
    local selected = 1
    local m = {}
    function m:update()
        frame = frame + 1
        if btnp(2) then
            selected = selected - 1
        end
        if btnp(3) then
            selected = selected + 1
        end
        selected = max(min(selected, 3), 1)
        if btnp(4) then
            if selected == 1 then
                set_game_mode(game)
            elseif selected == 2 then
                local start = 0x2000 + (difficulty * 512)
                local offset = start
                for i = 1, #mapsections do
                    local ms = mapsections[i]
                    poke(offset, ms[1])
                    poke(offset + 1, ms[2])
                    poke(offset + 2, ms[3])
                    offset = offset + 3
                end
                poke(offset, 0)
                poke(offset, 0)
                poke(offset, 0)
                cstore(start, start, 512)
                save("picopout.p8")
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
        rectfill(35, 40, 93, 88, 1)
        gprint("editor", 40, 44, 7)
        gprint("continue", 40, 56, selected == 1 and frame % 4 < 2 and 7 or 6)
        gprint("test track", 40, 62, selected == 2 and frame % 4 < 2 and 7 or 6)
        gprint("exit", 40, 70, selected == 3 and frame % 4 < 2 and 7 or 6)
    end
    return m
end

function mapeditor:update()
    local cs = mapsections[#mapsections]
    if btnp(0) then
        cs[2] = cs[2] - 1
    elseif btnp(1, 0) then
        cs[2] = cs[2] + 1
    elseif btnp(2, 0) then
        cs[1] = cs[1] + 1
    elseif btnp(3, 0) then
        cs[1] = cs[1] - 1
    elseif btnp(4, 0) then
        mapsections[#mapsections] = nil
    elseif btnp(5, 0) then
        mapsections[#mapsections + 1] = {cs[1], cs[2], cs[3]}
    elseif btnp(0, 1) then
        cs[3] = cs[3] - 1
    elseif btnp(1, 1) then
        cs[3] = cs[3] + 1
    elseif btnp(2, 1) then
        scale = scale * 0.9
    elseif btnp(3, 1) then
        scale = scale * 1.1
    elseif btnp(4, 1) then
        -- test map todo: open menu
        set_game_mode(map_menu(self))
        return
    end
    cs[2] = mid(0, cs[2], 255)
    cs[1] = mid(0, cs[1], 255)
end

function draw_minimap(sx, sy, scale, col)
    local x, y = sx, sy
    local lastx, lasty = sx, sy
    local dir = 0
    for i = 1, #mapsections do
        ms = mapsections[i]
        for seg = 1, ms[1] do
            dir = dir + (ms[2] - 128) / 100
            x = x + cos(dir) * 32 * scale
            y = y + sin(dir) * 32 * scale
            line(lastx, lasty, x, y, #mapsections == i and 3 or col)
            lastx, lasty = x, y
        end
    end
end

function mapeditor:draw()
    cls()
    draw_minimap(64, 64, scale, 6)
    gprint(#mapsections .. '/' .. flr(0x1000 / 8 / 3), 2, 2, 7)
end

function load_map()
    local start = (difficulty * 512) + 1
    mapsections = {}
    while true do
        local ms = {}
        ms[1] = TILEMAP[start]
        ms[2] = TILEMAP[start + 1]
        ms[3] = TILEMAP[start + 2]
        if ms[1] == 0 then
            break
        end
        mapsections[#mapsections + 1] = ms
        start = start + 3
    end
    if #mapsections == 0 then
        mapsections[1] = {10, 128, 32}
    end
    print("loaded " .. #mapsections .. " sections")
end

function race()
    local race = {}
    function race:init(difficulty, race_mode)
        self.race_mode = race_mode
        sc1 = nil
        sc1timer = 0

        vecmap = {}
        boosters = {}
        local dir, mx, my = 0, 0, 0
        local lastdir = 0

        -- generate map
        for _,ms in pairs(mapsections) do
            -- read length,curve,width from tiledata
            local length = ms[1]
            local curve = ms[2]
            local width = ms[3]

            if length == 0 then
                break
            end

            while length > 0 do
                dir = dir + (curve - 128) / 100

                if abs(dir - lastdir) > 0.09 then
                    dir = lerp(lastdir, dir, 0.5)
                    segment_length = 16
                    length = length - 0.5
                else
                    segment_length = 32
                    length = length - 1
                end

                mx = mx + cos(dir) * segment_length
                my = my + sin(dir) * segment_length
                table.insert(vecmap, mx)
                table.insert(vecmap, my)
                table.insert(vecmap, width)
                table.insert(vecmap, dir)

                mapsize = mapsize + 1

                lastdir = dir
            end
        end

        mapsize = #vecmap / 4

        self:restart()
    end

    function race:restart()
        self.completed = false
        self.time = self.race_mode == 1 and -3 or 0
        self.previous_best = nil
        camera_lastpos = vec()
        self.start_timer = self.race_mode == 1
        self.record_replay = nil
        self.play_replay_step = 1
        -- spawn cars

        self.objects = {}

        if self.race_mode == 2 and self.play_replay then
            local replay_car = create_car(self)
            table.insert(self.objects, replay_car)
            replay_car.color = 1
            self.replay_car = replay_car
        end

        local p = create_car(self)
        table.insert(self.objects, p)
        self.player = p
        p.is_player = true

        if self.race_mode == 1 then
            for i = 1, 3 do
                local ai_car = create_car(self)
                ai_car.color = rnd(6) + 9
                local v = get_vec_from_vecmap(-3 - i)
                ai_car.pos = copyv(v)
                ai_car.angle = v.dir
                local oldupdate = ai_car.update
                ai_car.ai = ai_controls(ai_car)
                global_ai = ai_car.ai
                global_ai.skill = i + 4
                function ai_car:update()
                    self.ai:update()
                    oldupdate(self)
                end
                table.insert(self.objects, ai_car)
            end
        end

    end

    function race:update()
        frame = frame + 1
        if sc1timer > 0 then
            sc1timer = sc1timer - 1
        end

        if self.completed then
            self.completed_countdown = self.completed_countdown - dt
            if self.completed_countdown < 4 then
                set_game_mode(completed_menu(self))
                return
            end
        end

        if btn(4, 1) then
            set_game_mode(paused_menu(self))
            return
        end

        -- enter input
        local player = self.player
        if player then
            local controls = player.controls
            controls.left = btn(0) > 0.1
            controls.right = btn(1) > 0.1
            controls.boost = btn(2) > 0.1
            controls.accel = btn(4)
            controls.brake = btn(5)
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
                    c.left = band(v, 1) ~= 0
                    c.right = band(v, 2) ~= 0
                    c.accel = band(v, 4) ~= 0
                    c.brake = band(v, 8) ~= 0
                    c.boost = band(v, 16) ~= 0
                    self.play_replay_step = self.play_replay_step + 1
                end
            end
        end

        if player.current_segment == 0 and not self.start_timer and self.race_mode == 2 then
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
            self.time = self.time + dt
        end

        -- record replay
        if self.record_replay then
            local c = player.controls
            local v = (c.left and 1 or 0) + (c.right and 2 or 0) + (c.accel and 4 or 0) + (c.brake and 8 or 0) +
                          (c.boost and 16 or 0)
            table.insert(self.record_replay, v)
        end

        if self.race_mode == 2 or self.time > 0 then
            for _,obj in pairs(self.objects) do
                obj:update()
            end
        end

        -- car to car collision
        for _,obj in pairs(self.objects) do
            for _,obj2 in pairs(self.objects) do
                if obj ~= obj2 and obj ~= self.replay_car and obj2 ~= self.replay_car then
                    if abs(obj.current_segment - obj2.current_segment) <= 1 then
                        local p1 = obj:get_poly()
                        local p2 = obj2:get_poly()
                        for _,point in pairs(p1) do
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
                                    table.insert(particles, {
                                        x = point.x,
                                        y = point.y,
                                        xv = -rv.x + (rnd(2) - 1) / 2,
                                        yv = -rv.y + (rnd(2) - 1) / 2,
                                        ttl = 30
                                    })
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

        if player.current_segment == mapsize * 3 then
            -- completed
            self.completed = true
            self.completed_countdown = 5
            self.start_timer = false
            if (not self.best_time) or self.time < self.best_time then
                if self.best_time then
                    self.previous_best = self.best_time
                end
                self.best_time = self.time
                self.play_replay = self.record_replay
            end
        end

        -- particles
        for i=#particles,1,-1 do
            local p=particles[i]
            p.x = p.x + p.xv
            p.y = p.y + p.yv
            p.xv = p.xv * 0.95
            p.yv = p.yv * 0.95
            p.ttl = p.ttl - 1
            if p.ttl < 0 then
                table.remove(particles, i)
            end
        end

    end

    function race:draw()
        -- local player = global_ai.car
        player = self.player
        time = self.time
        cls()

        local tp = cbufget(player.trails, player.trails._size - 8) or player.pos
        local trail = clampv(vecsub(player.pos, tp), 54)
        camera_pos = vecadd(vecadd(player.pos, trail), vec(-64, -64))
        if player.collision > 0 then
            camera(camera_pos.x + rnd(3) - 2, camera_pos.y + rnd(3) - 2)
        else
            local c = lerpv(camera_lastpos, camera_pos, 1)
            camera(c.x, c.y)
        end

        camera_lastpos = copyv(camera_pos)

        local current_segment = player.current_segment
        -- draw track
        local lastv
        for seg = current_segment - 30, current_segment + 30 do
            local v = get_vec_from_vecmap(seg)
            local diff = perpendicular(normalize(lastv and vecsub(v, lastv) or vec(1, 0)))
            local offset = scalev(diff, v.w)
            up = vecsub(v, offset)
            down = vecadd(v, offset)
            offset = scalev(diff, v.w - 8)
            up2 = vecsub(v, offset)
            down2 = vecadd(v, offset)
            offset = scalev(diff, v.w + 4)
            up3 = vecsub(v, offset)
            down3 = vecadd(v, offset)

            if lastv then
                if onscreen(v) or onscreen(lastv) or onscreen(up) or onscreen(down) then

                    -- linevec(lastv,v,15)
                    -- linevec(vecsub(v,offset),vecadd(v,offset),8)

                    -- inner track
                    local track_color = (seg < current_segment - 10 or seg > current_segment + 10) and 1 or
                                            (seg % 2 == 0 and 13 or 5)
                    if seg > current_segment - 5 and seg < current_segment + 7 then
                        if seg >= current_segment - 2 and seg < current_segment + 7 then
                            linevec(lastup2, up2, track_color) -- mid upper
                            linevec(lastdown2, down2, track_color) -- mid lower
                        end

                        -- look for upcoming turns and draw arrows
                        -- scan foward until we find a turn sharper than 2/100
                        for j = seg + 2, seg + 7 do
                            local v1 = get_vec_from_vecmap(j)
                            local v2 = get_vec_from_vecmap(j + 1)
                            if v1 and v2 and v1.dir and v2.dir then
                                -- find the difference in angle between v and v2
                                local diff = v2.dir - v1.dir
                                while diff > 0.5 do
                                    diff = diff - 1
                                end
                                while diff < -0.5 do
                                    diff = diff + 1
                                end
                                if diff > 0.03 then
                                    -- arrow left
                                    draw_arrow(lastup2, 4, v.dir + 0.25, 9)
                                    break
                                elseif diff < -0.03 then
                                    -- arrow right
                                    draw_arrow(lastdown2, 4, v.dir - 0.25, 9)
                                    -- linevec(lastv,lastdown3,8)
                                    break
                                elseif v2.w < v1.w * 0.75 then
                                    draw_arrow(lastup2, 4, v.dir + 0.25, 8)
                                    draw_arrow(lastdown2, 4, v.dir - 0.25, 8)
                                    break
                                end
                            end
                        end
                    end

                    -- edges
                    local track_color = (seg < current_segment - 10) and 1 or
                                            track_colors[flr((seg / (mapsize / 8))) % 8 + 1]
                    if seg > current_segment + 5 then
                        -- if it's far ahead, draw it above and scaled for parallax effect
                        track_color = 1
                        local segdiff = min((seg - (current_segment + 5)) * 0.01, 1)
                        displace_line(lastup, up, camera_pos, segdiff, track_color)
                        displace_line(lastdown, down, camera_pos, segdiff, track_color)
                    else
                        -- normal track edges
                        linevec(lastup, up, track_color)
                        linevec(lastdown, down, track_color)

                        linevec(lastup3, up3, track_color)
                        linevec(lastdown3, down3, track_color)
                    end

                    -- diagonals
                    if seg >= current_segment - 2 and seg < current_segment + 7 then
                        if seg % mapsize == 0 then
                            linevec(lastup2, lastdown2, time < -1 and 8 or time < 0 and 9 or 11) -- start/end markers
                        else
                            linevec(lastup2, lastdown2, 1) -- normal verticals
                        end
                        linevec(lastdown2, down, 4)
                        linevec(lastup2, up, 4)
                    end
                end
            end
            lastup = up
            lastdown = down
            lastup2 = up2
            lastdown2 = down2
            lastup3 = up3
            lastdown3 = down3
            lastv = v
        end

        for _,b in pairs(boosters) do
            if b.segment >= current_segment - 5 and b.segment <= current_segment + 5 then
                draw_arrow(b, 8, b.dir, 12)
            end
        end

        -- draw objects
        for _,obj in pairs(self.objects) do
            if abs(obj.current_segment - player.current_segment) <= 10 then
                if obj.trails then
                    obj:draw_trails()
                end
            end
        end
        for _,obj in pairs(self.objects) do
            if abs(obj.current_segment - player.current_segment) <= 10 then
                obj:draw()
            end
        end

        for _,p in pairs(particles) do
            line(p.x, p.y, p.x - p.xv, p.y - p.yv, p.ttl > 20 and 10 or (p.ttl > 10 and 9 or 8))
        end

        -- local seg = get_segment(player.current_segment)
        -- linevec(seg[1],seg[2],15)
        -- linevec(seg[2],seg[3],15)
        -- linevec(seg[3],seg[4],15)
        -- linevec(seg[4],seg[1],15)

        camera()

        -- print("mem:"..stat(0),0,0,7)
        -- print("cpu:"..stat(1),0,8,7)

        -- get placing
        local placing = 1
        local nplaces = 1
        for _,obj in pairs(self.objects) do
            if obj ~= player then
                nplaces = nplaces + 1
                if obj.current_segment > player.current_segment then
                    placing = placing + 1
                end
            end
        end
        if self.start_timer then
            player.placing = placing
        end

        gprint((player.placing or '?') .. '/' .. nplaces, 0, 1, 9)
        local lap = flr(player.current_segment / mapsize) + 1
        if lap > 3 then
            gprint("Lap 3/3", 0, 10, 9)
        else
            gprint("Lap " .. lap .. '/3', 0, 10, 9)
        end
        printr("" .. flr(player.speed * 10), 223, 196, 9)
        rectfill(224, 208, 224 - 70 * (player.speed / 15), 214, 9)
        rectfill(224, 215, 224 - 35 * (player.accel), 221, 11)
        if player.cooldown > 0 then
            rectfill(224, 222, 224 - 70 * (player.cooldown / 30), 223, 2)
        else
            local c = 8
            if player.boost < boost_warning_thresh then
                c = player.boost < boost_critical_thresh and (frame % 4 < 2 and 8 or 7) or 8
            end
            rectfill(224, 222, 224 - (player.boost / 100) * 70, 223, c)
        end

        gprint("Time: " .. format_time(time > 0 and time or 0), 224-48, 10, 7)
        if self.best_time then
            gprint("Best: " .. format_time(self.best_time), 224-48, 1, 7)
        end
        -- if player.lost_count > 10 and not self.completed then
        --	print("off course",54,60,8)
        -- end
        if player.wrong_way > 4 then
            gprint("Wrong way!", 72, 104, 8)
        end
        if time < 0 then
            gprint(-flr(time), 60, 20, 8)
        end
        if player.collision > 0 or self.completed then
            -- corrupt screen
            for i = 1, (completed and 100 - ((completed_countdown / 5) * 100) or 10) do
                local source = rnd(flr(0x6000 + 8192))
                local range = flr(rnd(64))
                local dest = 0x6000 + rnd(8192 - range) - 2
                -- TODO
                --memcpy(dest, source, range)
            end
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
        if btnp(2) then
            selected = selected - 1
        end
        if btnp(3) then
            selected = selected + 1
        end
        selected = max(min(selected, 3), 1)
        if btnp(4) then
            if selected == 1 then
                set_game_mode(game)
            elseif selected == 2 then
                set_game_mode(game)
                game:restart()
            elseif selected == 3 then
                set_game_mode(intro)
            end
        end
    end
    function m:draw()
        game:draw()
        rectfill(35, 40, 93, 88, 1)
        gprint("Paused", 40, 44, 7)
        gprint("Continue", 40, 56, selected == 1 and frame % 4 < 2 and 7 or 6)
        gprint("Restart race", 40, 62, selected == 2 and frame % 4 < 2 and 7 or 6)
        gprint("Exit", 40, 70, selected == 3 and frame % 4 < 2 and 7 or 6)
    end
    return m
end

function completed_menu(game)
    local m = {
        selected = 1
    }
    function m:update()
        frame = frame + 1
        if not btn(4) then
            self.ready = true
        end
        if btnp(2) then
            self.selected = self.selected - 1
        end
        if btnp(3) then
            self.selected = self.selected + 1
        end
        self.selected = clamp(self.selected, 1, 2)
        if self.ready and btnp(4) then
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
        gprint(difficulty_names[difficulty] .. ": " .. cars[intro.car].name, 40, 32, 7)
        gprint("Race complete!", 40, 44, 7)
        gprint("Place: " .. player.placing, 40, 56, 7)

        gprint("Time: " .. format_time(game.time), 35, 70, 7)
        gprint("Best: " .. format_time(game.best_time), 35, 80, game.best_time == game.time and frame % 4 < 2 and 8 or 7)
        if game.previous_best then
            gprint("Previous: " .. format_time(game.previous_best), 30, 90, 7)
        end

        gprint("Retry", 44, 102, self.selected == 1 and frame % 16 < 8 and 8 or 6)
        gprint("Exit", 44, 112, self.selected == 2 and frame % 16 < 8 and 8 or 6)
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

function fmap(objs, func)
    local ret = {}
    for _,i in pairs(objs) do
        table.insert(ret, func(i))
    end
    return ret
end

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
    return format_number(flr(t)) .. ":" .. format_number(flr((t - flr(t)) * 60))
end

function printr(text, x, y, c)
    local l = #text
    gprint(text, x - l * 8, y, c)
end

function dot(a, b)
    return a.x * b.x + a.y * b.y
end

function onscreen(p)
    local x = (p.x-camera_pos.x)*224/128 + X_OFFSET
    local y = (p.y-camera_pos.y)*224/128 + Y_OFFSET
    return x >= -20 and x <= gfx.SCREEN_WIDTH+20  and y >= -20 and y <= gfx.SCREEN_HEIGHT+20
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

function wrap(input, max)
    while input > max do
        input = input - max
    end
    while input < 1 do
        input = input + max
    end
    return input
end

function get_vec_from_vecmap(seg)
    seg = wrap(seg, mapsize)
    local i = ((seg - 1) * 4) + 1
    local v = {
        x = vecmap[i],
        y = vecmap[i + 1],
        w = vecmap[i + 2],
        dir = vecmap[i + 3]
    }
    return v
end

function get_segment(seg, enlarge)
    seg = wrap(seg, mapsize)
    -- returns the 4 points of the segment
    local v = get_vec_from_vecmap(seg + 1)
    local lastv = get_vec_from_vecmap(seg)
    local lastlastv = get_vec_from_vecmap(seg - 1)

    local perp = perpendicular(normalize(vecsub(v, lastv)))
    local lastperp = perpendicular(normalize(vecsub(lastv, lastlastv)))

    local lastw = enlarge and lastv.w * 2.5 or lastv.w
    local w = enlarge and v.w * 2.5 or v.w
    local lastoffset = scalev(perp, lastw)
    local offset = scalev(perp, w)
    return {vecadd(lastv, lastoffset), vecsub(lastv, lastoffset), vecsub(v, offset), vecadd(v, offset)}
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
    for _,point in pairs(points) do
        for _,line in pairs(lines) do
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

function draw_arrow(p, size, dir, col)
    local v = {rotate_point(vecadd(p, vec(0, -size)), dir, p), rotate_point(vecadd(p, vec(0, size)), dir, p),
               rotate_point(vecadd(p, vec(size, 0)), dir, p)}
    for i = 1, 3 do
        linevec(v[i], v[(i % 3) + 1], col)
    end
end

TILEMAP = { -- upper
10, 128, 32, 10, 126, 32, 10, 126, 32, 10, 128, 32, 10, 128, 32, 10, 127, 32, 10, 127, 32, 10, 127, 32, 10, 129, 32, 10,
127, 32, 10, 127, 32, 10, 124, 32, 10, 122, 32, 10, 124, 32, 10, 127, 32, 10, 131, 32, 10, 129, 32, 6, 128, 32, 3, 126,
32, 5, 127, 32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 37, 37, 37, 37, 37, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 37, 37, 37, 37, 37, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 128, 32, 10, 125, 32, 10, 127, 32, 6, 127, 32, 6,
121, 32, 6, 120, 32, 6, 120, 32, 6, 120, 32, 6, 125, 32, 6, 135, 32, 6, 131, 32, 6, 129, 32, 6, 130, 32, 6, 131, 32, 6,
130, 32, 6, 129, 32, 6, 128, 32, 6, 125, 32, 6, 125, 32, 6, 124, 32, 6, 124, 32, 6, 123, 32, 6, 121, 32, 6, 127, 32, 6,
136, 32, 6, 128, 32, 6, 128, 32, 6, 126, 32, 6, 125, 32, 6, 125, 32, 6, 125, 32, 6, 129, 32, 6, 131, 32, 3, 129, 32, 3,
125, 32, 3, 127, 32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 37, 37, 37, 37, 37, 37, 37, 2,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
37, 37, 37, 37, 37, 37, 37, 37, 37, 37, 37, 37, 37, 0, 37, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 37, 37, 37, 37, 37, 0, 0, 0, 0, 0, 0, 0, 0, 0, 37, 37, 0, 37, 0, 37, 37, 37,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 128, 32, 10, 129, 32, 10, 129, 32, 10, 138, 32,
10, 138, 32, 10, 124, 32, 10, 125, 32, 10, 127, 32, 10, 129, 32, 10, 129, 32, 10, 128, 32, 10, 130, 32, 10, 129, 32, 10,
128, 32, 10, 122, 32, 10, 122, 32, 10, 123, 32, 10, 127, 32, 10, 131, 32, 10, 131, 32, 10, 128, 32, 10, 126, 32, 10,
126, 32, 10, 128, 32, 10, 128, 32, 10, 127, 32, 10, 122, 32, 10, 135, 32, 10, 121, 32, 10, 129, 32, 10, 130, 32, 10,
130, 32, 9, 129, 32, 4, 126, 32, 2, 124, 32, 2, 126, 32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 37, 37, 37, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 37, 37, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 37, 37, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 37, 37, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 37, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 37, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 128, 32, 10, 128, 32, 10, 132, 32,
10, 130, 32, 10, 121, 32, 10, 132, 32, 10, 134, 32, 10, 136, 32, 10, 122, 32, 10, 127, 32, 10, 126, 32, 10, 133, 32, 10,
130, 32, 10, 128, 32, 10, 128, 32, 10, 131, 32, 10, 128, 32, 10, 122, 32, 10, 122, 32, 10, 122, 32, 10, 122, 32, 10,
128, 32, 10, 128, 32, 10, 130, 32, 10, 132, 32, 10, 128, 32, 10, 126, 32, 10, 129, 32, 10, 126, 32, 10, 126, 32, 10,
128, 32, 10, 128, 32, 10, 127, 32, 10, 123, 32, 10, 129, 32, 10, 130, 32, 7, 127, 32, 4, 127, 32, 2, 124, 32, 2, 129,
32, 2, 126, 32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 37, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 37, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 37, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 37, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 37, 37, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 37, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 128, 32,
6, 136, 32, 3, 131, 32, 3, 113, 32, 3, 124, 32, 3, 125, 32, 3, 126, 32, 3, 138, 32, 3, 137, 32, 3, 140, 32, 3, 129, 32,
3, 128, 32, 3, 127, 32, 3, 127, 32, 3, 127, 32, 3, 127, 32, 3, 123, 32, 3, 122, 32, 3, 119, 32, 3, 123, 32, 3, 144, 32,
16, 129, 32, 3, 113, 32, 3, 144, 32, 3, 112, 32, 3, 145, 32, 3, 131, 32, 11, 126, 32, 11, 125, 32, 5, 129, 32, 5, 138,
32, 5, 138, 32, 5, 138, 32, 5, 138, 32, 5, 123, 32, 5, 127, 32, 2, 131, 32, 2, 130, 32, 2, 127, 32, 2, 129, 32, 1, 124,
32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 37, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 37, 37,
37, 37, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 37, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 37, 37, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 37, 0, 0, 0, 0, 37, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 37, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 37, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 37, 0, 0, 0, 0, 0, 0, 37, 0, 0, 0, 0, 0, 0, 0, 0, 0, 37, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 127, 32,
10, 128, 32, 3, 120, 32, 3, 128, 32, 3, 128, 32, 3, 133, 32, 3, 133, 32, 3, 129, 32, 3, 131, 32, 3, 132, 32, 3, 133, 32,
3, 122, 32, 3, 128, 32, 3, 128, 32, 3, 128, 32, 3, 128, 32, 3, 135, 32, 3, 124, 32, 3, 122, 32, 3, 127, 32, 3, 133, 32,
2, 137, 32, 20, 124, 32, 13, 130, 32, 13, 126, 32, 13, 130, 32, 13, 126, 32, 13, 126, 32, 8, 128, 32, 8, 131, 32, 8,
130, 32, 8, 126, 32, 8, 124, 32, 8, 127, 32, 8, 129, 32, 8, 128, 32, 8, 127, 32, 8, 127, 32, 8, 127, 32, 8, 131, 32, 4,
132, 32, 4, 123, 32, 4, 128, 32, 4, 139, 32, 4, 126, 32, 4, 126, 32, 4, 126, 32, 4, 133, 32, 4, 130, 32, 4, 127, 32, 4,
127, 32, 4, 126, 32, 4, 126, 32, 4, 120, 32, 4, 120, 32, 4, 120, 32, 4, 120, 32, 4, 120, 32, 4, 123, 32, 4, 128, 32, 4,
130, 32, 4, 130, 32, 4, 131, 32, 4, 130, 32, 4, 129, 32, 3, 128, 32, 2, 127, 32, 2, 126, 32, 1, 132, 32, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 37, 37, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 37, 0, 0, 0, 0, 0, 0, 0, 0, 0,
37, 0, 0, 0, 0, 0, 0, 37, 37, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 37, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 37,
37, 0, 0, 0, 0, 0, 0, 0, 0, 0, 37, 0, 0, 0, 0, 0, 0, 37, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 127, 32, 8, 129, 32, 8, 129, 32, 3, 118, 32,
3, 140, 32, 3, 134, 32, 3, 132, 32, 3, 120, 32, 3, 123, 32, 3, 127, 32, 3, 139, 32, 11, 126, 32, 11, 121, 32, 5, 126,
32, 5, 131, 32, 5, 131, 32, 4, 133, 32, 4, 121, 32, 6, 124, 32, 6, 130, 32, 6, 136, 32, 6, 125, 32, 6, 128, 32, 6, 129,
32, 2, 118, 32, 2, 120, 32, 4, 128, 32, 4, 126, 32, 4, 125, 32, 4, 134, 32, 4, 127, 32, 4, 122, 32, 4, 129, 32, 4, 140,
32, 10, 127, 32, 10, 127, 32, 10, 130, 32, 10, 129, 32, 10, 128, 32, 10, 128, 32, 3, 138, 32, 3, 115, 32, 3, 126, 32, 8,
131, 32, 8, 130, 32, 8, 126, 32, 8, 129, 32, 4, 120, 32, 8, 133, 32, 8, 128, 32, 8, 130, 32, 3, 122, 32, 8, 128, 32, 8,
131, 32, 8, 126, 32, 8, 136, 32, 8, 136, 32, 8, 136, 32, 8, 136, 32, 8, 128, 32, 8, 126, 32, 8, 123, 32, 8, 137, 32, 8,
119, 32, 8, 137, 32, 16, 124, 32, 16, 127, 32, 16, 132, 32, 16, 127, 32, 16, 127, 32, 16, 117, 32, 16, 132, 32, 6, 125,
32, 6, 128, 33, 3, 128, 33, 1, 131, 34, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 37, 37, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 37, 0, 0, 0, 0, 0, 0, 0, 37, 0, 0, 0, 0, 0,
0, 0, 0, 0, 37, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 37, 37, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 37, 0, 0, 0, 0,
0, 37, 37, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 37, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 129, 32, 10, 128, 32, 3, 138, 32, 3, 118, 32, 3, 128,
32, 3, 137, 32, 3, 124, 32, 7, 126, 32, 6, 128, 32, 6, 124, 32, 6, 128, 32, 6, 125, 32, 6, 128, 32, 6, 128, 32, 6, 128,
32, 6, 129, 32, 6, 129, 32, 6, 126, 32, 6, 126, 32, 6, 127, 32, 6, 129, 32, 6, 128, 32, 2, 114, 32, 5, 128, 32, 2, 139,
32, 8, 128, 32, 11, 122, 32, 11, 122, 32, 11, 122, 32, 11, 122, 32, 4, 138, 32, 5, 124, 32, 5, 129, 32, 5, 136, 32, 5,
129, 32, 5, 129, 32, 5, 127, 32, 5, 128, 32, 2, 118, 32, 2, 125, 32, 2, 140, 32, 7, 129, 32, 4, 113, 32, 9, 130, 32, 9,
130, 32, 2, 104, 32, 6, 128, 32, 6, 132, 32, 6, 132, 32, 6, 131, 32, 6, 137, 32, 6, 137, 32, 6, 137, 32, 6, 137, 32, 6,
137, 32, 6, 137, 32, 6, 137, 32, 6, 129, 32, 6, 128, 32, 6, 128, 32, 6, 119, 32, 6, 119, 32, 6, 119, 32, 6, 126, 32, 6,
134, 32, 6, 129, 32, 6, 128, 32, 6, 123, 32, 6, 128, 32, 6, 126, 32, 6, 126, 32, 6, 132, 32, 3, 138, 32, 3, 132, 32, 3,
125, 32, 3, 125, 32, 2, 130, 33, 1, 127, 33, 0, 127, 33, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 37, 0, 37, 0, 0, 0, 0, 0, 0, 37, 0, 0, 0, 0, 0, 37, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 37, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 37, 0, 0, 0, 0, 0, 0, 37, 0, 0, 0, 0, 0, 0, 37, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 37, 37, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -- lower
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 157, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153,
153, 153, 153, 153, 153, 153, 153, 153, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 153, 153, 153, 151, 153, 153, 153, 119, 151, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 157, 153, 121, 121, 153, 119, 119,
153, 151, 121, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 153, 153, 121, 151, 153, 153, 121, 153, 151, 121, 153, 153, 153, 153, 153,
153, 153, 153, 153, 153, 153, 153, 153, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
157, 153, 153, 121, 153, 153, 153, 121, 121, 153, 153, 151, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221,
221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 221, 153, 153, 153, 121, 119, 151, 119, 119,
121, 153, 153, 151, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153,
153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153,
153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 154, 153, 153, 153, 153, 154, 154, 153, 153, 153, 153,
170, 153, 169, 153, 153, 169, 153, 169, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153,
153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153,
153, 153, 153, 169, 169, 153, 170, 170, 169, 169, 153, 154, 153, 153, 153, 153, 169, 154, 153, 154, 153, 169, 170, 154,
137, 137, 136, 136, 137, 136, 137, 152, 137, 136, 137, 137, 137, 137, 136, 136, 153, 136, 136, 136, 136, 153, 153, 153,
153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 169, 154, 153, 153, 169,
169, 154, 153, 154, 169, 169, 170, 154, 153, 169, 153, 153, 170, 169, 169, 153, 137, 137, 137, 137, 137, 137, 137, 136,
137, 137, 137, 137, 153, 137, 136, 136, 153, 104, 102, 102, 134, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153,
153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 169, 153, 153, 153, 169, 169, 153, 153, 154, 154, 153, 153, 153,
153, 154, 153, 169, 153, 153, 169, 153, 137, 137, 153, 137, 137, 136, 137, 137, 137, 137, 153, 152, 153, 137, 136, 136,
153, 104, 102, 102, 136, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153,
153, 153, 153, 169, 170, 154, 170, 170, 169, 170, 154, 170, 153, 153, 153, 153, 170, 153, 169, 154, 153, 169, 154, 153,
137, 137, 153, 137, 137, 153, 137, 136, 137, 136, 137, 137, 153, 137, 136, 136, 153, 136, 136, 136, 136, 153, 153, 153,
153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153,
153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153,
153, 153, 153, 153, 153, 153, 153, 153, 153, 104, 102, 102, 136, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153,
153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153,
153, 153, 153, 153, 153, 153, 153, 153, 89, 149, 89, 85, 89, 85, 89, 85, 89, 153, 149, 85, 153, 85, 153, 85, 153, 104,
102, 134, 134, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153,
153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 89, 85,
89, 89, 89, 149, 153, 149, 89, 153, 149, 149, 149, 149, 149, 85, 153, 136, 136, 136, 136, 153, 153, 153, 153, 153, 153,
153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153,
153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 89, 89, 89, 89, 153, 153, 149, 89, 89, 149, 85,
149, 85, 153, 149, 153, 136, 136, 136, 136, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153,
153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153,
153, 153, 153, 153, 89, 85, 89, 85, 89, 153, 153, 149, 89, 85, 149, 149, 149, 149, 149, 85, 149, 136, 136, 136, 136,
153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153,
153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153,
153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153,
153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153,
153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153,
153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153,
153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153,
153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153,
153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153,
153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 153, 136, 136, 136, 136, 136,
136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136,
136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136,
136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 102, 102, 136, 102, 102, 102, 102, 136, 136, 136,
136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136,
136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136,
136, 136, 136, 136, 136, 136, 136, 104, 136, 136, 136, 136, 102, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136,
136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136,
136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136,
136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136,
136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136,
136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136}

SFX={
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
	"PAT 16 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
	"PAT 16 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
	"PAT 3 D.4170 A#3170 F.3170 C#3170 G#2170 F.2170 D#2170 C.2170 A#1170 G#1170 F#1170 F.1170 E.1170 D#1170 D.1170 C#1170 C#1170 C#1100 C#1100 C#1100 F.1100 F.1100 F.1100 F.1100 F.1100 F.1100 F.1100 E.1100 E.1100 ...... ...... ......",
	"PAT 3 C#1170 C#1170 D#1170 E.1170 F.1170 F#1170 F#1170 G.1170 A.1170 A#1170 B.1170 C#2170 D#2170 F#2170 A.2170 A#2170 C#3170 D#3170 F.3170 F#3170 A.3170 A#3170 G.3100 G.3100 G.3100 G.3100 G.3100 G.3100 G.3100 G.3100 G.3100 G#3100",
	"PAT 6 D.2610 D.2610 D.2610 D.2610 D.2610 D.2610 D.2610 D.2610 D.2605 D.2700 D.5000 D.3100 D.3100 D.1700 D.1700 D.1702 D.1702 D.1702 D.1702 D.1702 D.1702 C.1002 C.1002 C.2002 C.2002 C.2002 C.2002 C.1002 C.1002 C.1002 C.1002 C.6002",
	"PAT 6 A.3620 A.3620 A.3620 A.3620 A.3620 A.3620 A.3620 A.3620 E.1602 E.1602 E.1702 E.1702 E.1702 E.1702 E.1702 E.1702 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... C.1003",
	"PAT 6 A.3120 A.3620 A.3620 A.3620 A.3620 A.3620 A.3620 A.3620 D.6600 D.6600 D.6600 D.6600 D.6600 D.6600 D.6600 D.6600 C.6600 C.6600 C.6600 C.6600 C.6600 C.6600 C.6600 C.6600 C.6600 C.1600 C.1600 C.1600 C.1600 C.1600 C.1600 C.1700",
	"PAT 3 C.6650 G.5650 D#5650 C.5640 E.4630 C#3620 F#2620 G#1610 C#3610 C#1310 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
	"PAT 6 A.3130 A.3620 A.3130 A.3620 A.3620 A.3620 A.3620 A.3620 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... C.6000",
	"PAT 3 D#6650 C.6610 D#4610 D.2413 F#2600 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
	"PAT 2 G#1600 D.1210 F.1210 A.1220 B.1230 D.2240 F.2240 G.2340 A#2350 G.2250 D#3360 G.3360 C.3260 B.3360 E.4360 E.3260 A.4360 G#5360 D.6360 F#4250 A#3350 G.4340 G.5340 D.6340 C#4300 F#2300 E.2300 D.2300 C#2300 C.4300 B.3300 C#4600",
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
	"PAT 16 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
}

-- pico8 instruments
INST_TRIANGLE = "INST OVERTONE 1.0 TRIANGLE 1.0 METALIZER 0.85 NAM triangle"
INST_TILTED = "INST OVERTONE 1.0 TRIANGLE 0.5 SAW 0.1 NAM tilted"
INST_SAW = "INST OVERTONE 1.0 SAW 1.0 ULTRASAW 1.0 NAM saw"
INST_SQUARE = "INST OVERTONE 1.0 SQUARE 0.5 NAM square"
INST_PULSE = "INST OVERTONE 1.0 SQUARE 0.5 PULSE 0.5 TRIANGLE 1.0 METALIZER 1.0 OVERTONE_RATIO 0.5 NAM pulse"
INST_ORGAN = "INST OVERTONE 0.5 TRIANGLE 0.75 NAM organ"
INST_NOISE = "INST NOISE 1.0 NOISE_COLOR 0.2 NAM noise"
INST_PHASER = "INST OVERTONE 0.5 METALIZER 1.0 TRIANGLE 0.7 NAM phaser"