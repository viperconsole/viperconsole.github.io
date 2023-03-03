-- ~celeste~
-- maddy thorson + noel berry

-- Viper / Oberon conversion
-- jice
PI = 3.14159
SPRITESHEET_LAYER = 8
GAMEPAD_NEUTRAL_ZONE = 0.4
SPRITE_SIZE = 14
SPRITE_PER_ROW = math.floor(512 / SPRITE_SIZE)
SCREEN_SIZE = 16 * SPRITE_SIZE
X_OFFSET = 80
Y_OFFSET = 10
SPEED_COEF = SPRITE_SIZE / 8 + 0.5
CLOUD_COUNT = 16
PARTICLE_COUNT = 24
TILE_2_OBJ = {}
JUMP_BUTTON = 0
DASH_BUTTON = 2

got_fruit = {}
frames = 0
score = 0
deaths = 0
cheat = false
max_djump = 1
start_game = false
start_game_flash = 0
has_dashed = false
has_key = false
objects = {}
roomx = 0
roomy = 0
freeze = 0
cam_offset_x = 0
cam_offset_y = 10
flash_bg = false
new_bg = false
clouds = {}
particles = {}
dead_particles = {}
flipflop = true
seconds = 0
minutes = 0
shake = 0
pause_player = false
will_restart = false
will_next_room = false
delay_restart = 0
sfx_timer = 0
music_timer = 0

math.clamp = function(v, a, b)
	return v < a and a or (v > b and b or v)
end

col = function(r, g, b)
	return { r = r, g = g, b = b }
end

PAL = {
	col(0, 0, 1),
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

function level_index()
	return roomx % 8 + roomy * 8
end

function is_title()
	return level_index() == 31
end

function spr(n, x, y, w, h, hflip, vflip)
	local int_spr = math.floor(n)
	local spritex = (int_spr % SPRITE_PER_ROW) * SPRITE_SIZE
	local spritey = (int_spr // SPRITE_PER_ROW) * SPRITE_SIZE
	gfx.blit(
		spritex,
		spritey,
		w * SPRITE_SIZE,
		h * SPRITE_SIZE,
		math.floor(x + X_OFFSET),
		math.floor(y + Y_OFFSET),
		255, 255, 255, nil,
		nil,
		nil,
		hflip,
		vflip
	)
end

function line(x1, y1, x2, y2, col)
	gfx.line(x1 + X_OFFSET, y1 + Y_OFFSET,
		x2 + X_OFFSET, y2 + Y_OFFSET,
		PAL[col].r, PAL[col].g, PAL[col].b
	)
end

function get_sprite_offset(djump)
	return djump == 2 and 180 or (djump == 0 and 144 or 0)
end

function create_object(obj_type, x, y)
	if obj_type.is_fruit and got_fruit[level_index()] then
		return
	end

	local obj = {
		type = obj_type,
		collideable = true,
		solids = true,
		sprite = 0,
		hflip = false,
		vflip = false,
		x = x,
		y = y,
		dir = 0,
		hitbox = { x = 0, y = 0, w = SPRITE_SIZE, h = SPRITE_SIZE },
		speed = { x = 0, y = 0 },
		rem = { x = 0, y = 0 },
		to_remove = false,
		hair = {},
	}
	if obj_type.init ~= nil then
		obj_type.init(obj)
	end
	table.insert(objects, obj)
end

function rect_fill(x1, y1, x2, y2, col)
	local w = x2 - x1 + 1
	local h = y2 - y1 + 1
	local x = x1 + X_OFFSET
	local y = y1 + Y_OFFSET
	local col = col + 1
	gfx.rectangle(x, y, w, h, PAL[col].r, PAL[col].g, PAL[col].b)
end

function circ_fill(x, y, r, col)
	local col = col + 1
	gfx.disk(x + X_OFFSET, y + Y_OFFSET, r, nil, PAL[col].r, PAL[col].g, PAL[col].b)
end

function create_hair(objz)
	objz.hair = {}
	for i = 0, 4 do
		table.insert(objz.hair, {
			x = objz.x,
			y = objz.y,
			size = math.clamp(4 - i, 2, 4),
		})
	end
end

function update_hair(obj, facing, down)
	local lastx = obj.x + 7 - facing * 2
	local lasty = obj.y + (down and 7 or 5)
	for _, h in pairs(obj.hair) do
		h.x = h.x + (lastx - h.x) / 1.4
		h.y = h.y + (lasty + 0.8 - h.y) / 1.4
		lastx = h.x
		lasty = h.y
	end
end

function draw_hair(obj, sprite_offset)
	local col = sprite_offset == 0 and 8 or (sprite_offset == 180 and 11 or 12)
	for _, h in pairs(obj.hair) do
		circ_fill(h.x, h.y, h.size, col)
	end
end

function obj_collide(obj, type, ox, oy)
	for _, other in pairs(objects) do
		if other.type.name == type and other ~= obj and other.collideable
			and other.x + other.hitbox.x + other.hitbox.w > obj.x + obj.hitbox.x + ox
			and other.y + other.hitbox.y + other.hitbox.h > obj.y + obj.hitbox.y + oy
			and other.x + other.hitbox.x < obj.x + obj.hitbox.x + obj.hitbox.w + ox
			and other.y + other.hitbox.y < obj.y + obj.hitbox.y + obj.hitbox.h + oy then
			return other
		end
	end
	return nil
end

function tile_flag_at(x, y, w, h, flag)
	local minx = math.max(x // SPRITE_SIZE, 0)
	local maxx = math.min((x + w - 1) // SPRITE_SIZE, 15)
	local miny = math.max(y // SPRITE_SIZE, 0)
	local maxy = math.min((y + h - 1) // SPRITE_SIZE, 15)
	for i = minx, maxx do
		for j = miny, maxy do
			local offset = roomx * 16 + i + (roomy * 16 + j) * 128 + 1
			local tile = TILE_MAP[offset] + 1
			if SPRITE_FLAGS[tile] & flag ~= 0 then
				return true
			end
		end
	end
	return false
end

function solid_at(x, y, w, h)
	return tile_flag_at(x, y, w, h, 1 << 0)
end

function ice_at(x, y, w, h)
	return tile_flag_at(x, y, w, h, 1 << 4)
end

function spike_at(x, y, w, h, xspd, yspd)
	for i = math.max(0, x // SPRITE_SIZE), math.min(15, (x + w - 1) // SPRITE_SIZE) do
		for j = math.max(0, y // SPRITE_SIZE), math.min(15, (y + h - 1) // SPRITE_SIZE) do
			local offset = roomx * 16 + i + (roomy * 16 + j) * 128 + 1
			local tile = TILE_MAP[offset]
			if tile == 17 and ((y + h - 1) % SPRITE_SIZE >= SPRITE_SIZE * 6 / 8 or y + h == j * SPRITE_SIZE + SPRITE_SIZE) and yspd >= 0 then
				return true
			elseif tile == 27 and y % SPRITE_SIZE <= 2 * SPRITE_SIZE / 8 and yspd <= 0 then
				return true
			elseif tile == 43 and x % SPRITE_SIZE <= 2 * SPRITE_SIZE / 8 and xspd <= 0 then
				return true
			elseif tile == 59 and ((x + w - 1) % SPRITE_SIZE >= 6 * SPRITE_SIZE / 8 or x + w == i * SPRITE_SIZE + SPRITE_SIZE) and xspd >= 0 then
				return true
			end
		end
	end
	return false
end

function obj_check(obj, type, ox, oy)
	return obj_collide(obj, type, ox, oy) ~= nil
end

function obj_is_solid(obj, ox, oy)
	if oy > 0 and not obj_check(obj, "Platform", ox, 0) and obj_check(obj, "Platform", ox, oy) then
		return true
	end
	return solid_at(obj.x + obj.hitbox.x + ox, obj.y + obj.hitbox.y + oy, obj.hitbox.w, obj.hitbox.h)
		or obj_check(obj, "FallFloor", ox, oy)
		or obj_check(obj, "FakeWall", ox, oy)
end

function appr(val, target, amount)
	if val > target then
		return math.max(val - amount, target)
	else
		return math.min(val + amount, target)
	end
end

function sign(val)
	return val > 0 and 1 or (val < 0 and -1 or 0)
end

function restart_room()
	will_restart = true
	delay_restart = 15
end

function kill_player(obj)
	deaths = deaths + 1
	shake = 10
	snd.play_pattern(0)
	dead_particles = {}
	for dir = 0, 7 do
		angle = dir / 8 * PI * 2
		table.insert(dead_particles, {
			x = obj.x + SPRITE_SIZE / 2,
			y = obj.y + SPRITE_SIZE / 2,
			t = 10,
			spdx = math.sin(angle) * 3 * SPEED_COEF,
			spdy = math.cos(angle) * 3 * SPEED_COEF,
		})
		restart_room()
	end
end

function load_room(x, y)
	has_dashed = false
	has_key = false
	objects = {}
	roomx = x
	roomy = y
	for tx = 0, 15 do
		for ty = 0, 15 do
			offset = roomx * 16 + tx + (roomy * 16 + ty) * 128 + 1
			tile = TILE_MAP[offset]
			if TILE_2_OBJ[tile] ~= nil then
				obj_type = TILE_2_OBJ[tile]
				create_object(obj_type, tx * SPRITE_SIZE, ty * SPRITE_SIZE)
			end
		end
	end
end

Smoke = {
	name = "Smoke",
	is_fruit = false,
	init = function(obj)
		obj.sprite = 29
		obj.speed.y = -0.1
		obj.speed.x = 0.4 + math.random() * 0.2
		obj.x = obj.x + math.random() * 2 - 1
		obj.y = obj.y + math.random() * 2 - 1
		obj.hflip = math.random() >= 0.5
		obj.vflip = math.random() >= 0.5
		obj.solids = false
	end,
	update = function(obj)
		obj.sprite = obj.sprite + 0.2
		if obj.sprite >= 31 then
			obj.to_remove = true
		end
	end,
	draw = nil
}

function next_room()
	if roomx == 2 and roomy == 1 then
		snd.play_music(2, 7)
	elseif roomx == 4 and roomy == 2 then
		snd.play_music(2, 7)
	elseif roomx == 5 and roomy == 3 then
		snd.play_music(2, 7)
	elseif roomx == 3 and roomy == 1 then
		snd.play_music(3, 7)
	end
	if roomx == 7 then
		if roomy == 3 then
			load_room(0, 0)
		else
			load_room(0, roomy + 1)
		end
	else
		load_room(roomx + 1, roomy)
	end
end

function cel_print(msg, px, py, col)
	col = col + 1
	gfx.print(gfx.FONT_8X8, msg, math.floor(px + X_OFFSET), math.floor(py + Y_OFFSET), PAL[col].r, PAL[col].g, PAL[col].b)
end

function break_fall_floor(obj)
	if obj.state == 0 then
		obj.state = 1
		obj.delay = 15
		create_object(Smoke, obj.x, obj.y)
		hit = obj_collide(obj, "Spring", 0, -1)
		if hit then
			hit.hide_in = 15
		end
	end
end

PlayerSpawn = {
	name = "PlayerSpawn",
	is_fruit = false,
	init = function(obj)
		obj.sprite = 3
		obj.target = { x = obj.x, y = obj.y }
		obj.y = 16 * SPRITE_SIZE
		obj.speed.y = -4 * SPEED_COEF
		obj.solids = false
		obj.state = 0
		obj.delay = 0
		create_hair(obj)
		snd.play_pattern(4)
	end,
	update = function(obj)
		update_hair(obj, obj.hflip and -1 or 1, false)
		if obj.state == 0 then
			-- jumping up
			if obj.y < obj.target.y + SPRITE_SIZE * 2 then
				obj.state = 1
				obj.delay = 3
			end
		elseif obj.state == 1 then
			-- falling
			obj.speed.y = obj.speed.y + 0.5 * SPEED_COEF
			if obj.speed.y > 0 and obj.delay > 0 then
				obj.speed.y = 0
				obj.delay = obj.delay - 1
			end
			if obj.speed.y > 0 and obj.y > obj.target.y then
				obj.y = obj.target.y
				obj.speed.x = 0
				obj.speed.y = 0
				obj.state = 2
				obj.delay = 5
				-- smoke
				create_object(Smoke, obj.x, obj.y + SPRITE_SIZE / 2)
				shake = 5
				snd.play_pattern(5)
			end
		elseif obj.state == 2 then
			-- landing
			obj.delay = obj.delay - 1
			obj.sprite = 6
			if obj.delay < 0 then
				obj.to_remove = true
				create_object(Player, obj.x, obj.y)
			end
		end
		obj.dir = get_sprite_offset(max_djump)
	end,
	draw = function(obj)
		draw_hair(obj, obj.dir)
		spr(obj.sprite + obj.dir, obj.x, obj.y, 1, 1, obj.hflip, obj.vflip)
	end,
}

Player = {
	name = "Player",
	is_fruit = false,
	init = function(obj)
		obj.p_jump = false
		obj.p_dash = false
		obj.grace = 0
		obj.jbuffer = 0
		obj.djump = max_djump
		obj.down = false
		obj.dash_time = 0
		obj.dash_effect_time = 0
		obj.dash_target = { x = 0, y = 0 }
		obj.dash_accel = { x = 0, y = 0 }
		obj.spr_off = 0
		obj.was_on_ground = false
		obj.hitbox = { x = 2, y = 3, w = 10, h = 11 }
		create_hair(obj)
	end,
	update = function(obj)
		if pause_player then
			return
		end
		local right = inp.right()
		local left = inp.left()
		if right > 0.6 then
			right = 1
		end
		if left > 0.6 then
			left = 1
		end
		local input = right > 0 and right or (left > 0 and -left or 0)
		if spike_at(obj.x + obj.hitbox.x, obj.y + obj.hitbox.y, obj.hitbox.w, obj.hitbox.h, obj.speed.x, obj.speed.y) then
			obj.to_remove = true
			kill_player(obj)
		end
		obj.down = inp.down() > 0.1
		update_hair(obj, obj.hflip and -1 or 1, obj.down)
		-- bottom death
		if obj.y > SCREEN_SIZE then
			obj.to_remove = true
			kill_player(obj)
		end
		on_ground = obj_is_solid(obj, 0, 1)
		on_ice = ice_at(obj.x + obj.hitbox.x, obj.y + obj.hitbox.y + 1, obj.hitbox.w, obj.hitbox.h)
		-- smoke
		if on_ground and not obj.was_on_ground then
			create_object(Smoke, obj.x, obj.y + SPRITE_SIZE / 2)
		end
		-- jump
		key_jump = inp.action1()
		jump = key_jump and not obj.p_jump
		obj.p_jump = key_jump
		if jump then
			obj.jbuffer = 4
		elseif obj.jbuffer > 0 then
			obj.jbuffer = obj.jbuffer - 1
		end
		-- dash
		key_dash = inp.action2()
		dash = key_dash and not obj.p_dash
		obj.p_dash = key_dash
		if on_ground then
			obj.grace = 6
			if obj.djump < max_djump then
				obj.djump = max_djump
				snd.play_pattern(54)
			end
		elseif obj.grace > 0 then
			obj.grace = obj.grace - 1
		end
		obj.dash_effect_time = obj.dash_effect_time - 1
		maxrun = SPEED_COEF
		if obj.dash_time > 0 then
			create_object(Smoke, obj.x, obj.y)
			obj.dash_time = obj.dash_time - 1
			obj.speed.x = appr(obj.speed.x, obj.dash_target.x, obj.dash_accel.x)
			obj.speed.y = appr(obj.speed.y, obj.dash_target.y, obj.dash_accel.y)
		else
			-- move
			accel = on_ice and 0.05 * SPEED_COEF or (not on_ground and 0.4 * SPEED_COEF or 0.6 * SPEED_COEF)
			deccel = 0.15 * SPEED_COEF
			if math.abs(obj.speed.x) > maxrun then
				obj.speed.x = appr(obj.speed.x, sign(obj.speed.x * maxrun), deccel)
			else
				obj.speed.x = appr(obj.speed.x, input * maxrun, accel)
			end
			-- facing
			if obj.speed.x ~= 0 then
				obj.hflip = obj.speed.x < 0
			end
			-- gravity
			maxfall = 2 * SPEED_COEF
			gravity = 0.21 * SPEED_COEF
			if math.abs(obj.speed.y) <= 0.15 * SPEED_COEF then
				gravity = gravity * 0.5
			end
			-- wall slide
			if input ~= 0 and obj_is_solid(obj, input, 0) and not ice_at(obj.x + obj.hitbox.x + input, obj.y + obj.hitbox.y, obj.hitbox.w, obj.hitbox.h) then
				maxfall = 0.4 * SPEED_COEF
				if math.random() * 10 < 2 then
					create_object(Smoke, obj.x + input * 6 * SPRITE_SIZE / 8, obj.y)
				end
			end
			if not on_ground then
				obj.speed.y = appr(obj.speed.y, maxfall, gravity)
			end
			if obj.jbuffer > 0 then
				if obj.grace > 0 then
					-- normal jump
					snd.play_pattern(1)
					obj.jbuffer = 0
					obj.grace = 0
					obj.speed.y = -2 * SPEED_COEF
					create_object(Smoke, obj.x, obj.y + SPRITE_SIZE / 2)
				else
					-- wall jump
					snd.play_pattern(2)
					wall_dir = obj_is_solid(obj, -3, 0) and -1 or (obj_is_solid(obj, 3, 0) and 1 or 0)
					if wall_dir ~= 0 then
						obj.jbuffer = 0
						obj.speed.y = -2 * SPEED_COEF
						obj.speed.x = -wall_dir * (maxrun + SPEED_COEF)
						if not ice_at(obj.x + obj.hitbox.x + wall_dir * 3, obj.y + obj.hitbox.y, obj.hitbox.w, obj.hitbox.h) then
							create_object(Smoke, obj.x + wall_dir * 6 * SPRITE_SIZE / 8, obj.y)
						end
					end
				end
			end
			-- dash
			d_full = 5
			d_half = d_full * 0.70710678118
			if obj.djump > 0 and dash then
				create_object(Smoke, obj.x, obj.y)
				obj.djump = obj.djump - 1
				obj.dash_time = 4
				has_dashed = true
				obj.dash_effect_time = 10
				local up = inp.up()
				if up > 0.6 then
					up = 1
				end
				v_input = up > 0.0 and -up or (obj.down and 1 or 0)
				if input ~= 0 then
					if v_input ~= 0 then
						obj.speed.x = input * d_half * SPEED_COEF
						obj.speed.y = v_input * d_half * SPEED_COEF
					else
						obj.speed.x = input * d_full * SPEED_COEF
						obj.speed.y = 0
					end
				elseif v_input ~= 0 then
					obj.speed.x = 0
					obj.speed.y = v_input * d_full * SPEED_COEF
				else
					obj.speed.x = (obj.hflip and -1 or 1) * SPEED_COEF
					obj.speed.y = 0
				end
				snd.play_pattern(3)
				freeze = 2
				shake = 6
				obj.dash_target.x = 2 * sign(obj.speed.x) * SPEED_COEF
				obj.dash_target.y = 2 * sign(obj.speed.y) * SPEED_COEF
				obj.dash_accel.x = 1.5 * SPEED_COEF
				obj.dash_accel.y = 1.5 * SPEED_COEF
				if obj.speed.y < 0 then
					obj.dash_target.y = obj.dash_target.y * 0.75
				end
				if obj.speed.y ~= 0 then
					obj.dash_accel.x = obj.dash_accel.x * 0.70710678118
				end
				if obj.speed.x ~= 0 then
					obj.dash_accel.y = obj.dash_accel.y * 0.70710678118
				end
			elseif dash and obj.djump <= 0 then
				snd.play_pattern(9)
				create_object(Smoke, obj.x, obj.y)
			end
		end
		-- animation
		obj.spr_off = obj.spr_off + 0.25
		if not on_ground then
			obj.sprite = obj_is_solid(obj, input, 0) and 5 or 3
		elseif obj.down then
			obj.sprite = 6
		elseif inp.up() > 0.9 then
			obj.sprite = 7
		elseif obj.speed.x == 0 or input == 0 then
			obj.sprite = 1
		else
			obj.sprite = 1 + (obj.spr_off % 4)
		end
		if obj.x < -1 or obj.x > SCREEN_SIZE - SPRITE_SIZE + 1 then
			obj.x = math.clamp(obj.x, -1, SCREEN_SIZE - SPRITE_SIZE + 1)
			obj.speed.x = 0
		end
		-- next level
		if obj.y < -SPRITE_SIZE / 2 and level_index() < 30 then
			will_next_room = true
		end
		obj.was_on_ground = on_ground
	end,
	draw = function(obj)
		sprite_offset = get_sprite_offset(obj.djump)
		draw_hair(obj, sprite_offset)
		spr(obj.sprite + sprite_offset, obj.x, obj.y, 1, 1, obj.hflip, obj.vflip)
	end
}

FakeWall = {
	name = "FakeWall",
	is_fruit = true,
	init = function(obj)
		obj.sprite = 64
	end,
	update = function(obj)
		obj.hitbox = { x = -1, y = -1, w = SPRITE_SIZE * 2 + 2, h = SPRITE_SIZE * 2 + 2 }
		hit = obj_collide(obj, "Player", 0, 0)
		if hit and hit.dash_effect_time > 0 then
			snd.play_pattern(16)
			hit.speed.x = -sign(hit.speed.x) * 1.5
			hit.speed.y = -1.5
			hit.dash_time = -1
			obj.to_remove = true
			create_object(Smoke, obj.x, obj.y)
			create_object(Smoke, obj.x, obj.y + SPRITE_SIZE)
			create_object(Smoke, obj.x + SPRITE_SIZE, obj.y)
			create_object(Smoke, obj.x + SPRITE_SIZE, obj.y + SPRITE_SIZE)
			create_object(Fruit, obj.x + SPRITE_SIZE / 2, obj.y + SPRITE_SIZE / 2)
		end
		obj.hitbox = { x = 0, y = 0, w = SPRITE_SIZE * 2, h = SPRITE_SIZE * 2 }
	end,
	draw = function(obj)
		spr(64, obj.x, obj.y, 1, 1, false, false)
		spr(65, obj.x + SPRITE_SIZE, obj.y, 1, 1, false, false)
		spr(80, obj.x, obj.y + SPRITE_SIZE, 1, 1, false, false)
		spr(81, obj.x + SPRITE_SIZE, obj.y + SPRITE_SIZE, 1, 1, false, false)
	end
}

Fruit = {
	name = "Fruit",
	is_fruit = true,
	init = function(obj)
		obj.sprite = 26
		obj.start = obj.y
		obj.off = 0
	end,
	update = function(obj)
		hit = obj_collide(obj, "Player", 0, 0)
		if hit then
			hit.djump = max_djump
			idx = level_index()
			if not got_fruit[idx] then
				got_fruit[idx] = true
				score = score + 1
			end
			create_object(LifeUp, obj.x, obj.y)
			obj.to_remove = true
			snd.play_pattern(13)
		end
		obj.off = obj.off + 1
		obj.y = obj.start + math.sin(obj.off / 40 * 2.0 * PI) * 2.5
	end,
	draw = nil
}

LifeUp = {
	name = "LifeUp",
	is_fruit = false,
	init = function(obj)
		obj.speed.y = -0.25
		obj.duration = 30
		obj.x = obj.x - 2
		obj.y = obj.y - 4
		obj.flash = 0
		obj.solids = false
	end,
	update = function(obj)
		obj.duration = obj.duration - 1
		if obj.duration <= 0 then
			obj.to_remove = true
		end
	end,
	draw = function(obj)
		obj.flash = obj.flash + 0.5
		cel_print("1000", obj.x - 2, obj.y, 7 + (math.floor(obj.flash) % 2))
	end
}

Spring = {
	name = "Spring",
	is_fruit = false,
	init = function(obj)
		obj.sprite = 18
		obj.hide_in = 0
		obj.hide_for = 0
	end,
	update = function(obj)
		if obj.hide_for > 0 then
			obj.hide_for = obj.hide_for - 1
			if obj.hide_for <= 0 then
				obj.sprite = 18
				obj.delay = 0
			end
		elseif obj.sprite == 18 then
			hit = obj_collide(obj, "Player", 0, 0)
			if hit and hit.speed.y >= 0 then
				obj.sprite = 19
				hit.y = obj.y - SPRITE_SIZE / 2
				hit.speed.x = hit.speed.x * 0.2
				hit.speed.y = -3.2 * SPEED_COEF
				hit.djump = max_djump
				obj.delay = 10
				create_object(Smoke, obj.x, obj.y)
				below = obj_collide(obj, "FallFloor", 0, 1)
				if below then
					if below.state == 0 then
						snd.play_pattern(15)
					end
					break_fall_floor(below)
				end
				snd.play_pattern(8)
			end
		elseif obj.delay > 0 then
			obj.delay = obj.delay - 1
			if obj.delay <= 0 then
				obj.sprite = 18
			end
		end
		if obj.hide_in > 0 then
			obj.hide_in = obj.hide_in - 1
			if obj.hide_in <= 0 then
				obj.hide_for = 60
				obj.sprite = 0
			end
		end
	end,
	draw = nil
}

FlyFruit = {
	name = "FlyFruit",
	is_fruit = true,
	init = function(obj)
		obj.start = obj.y
		obj.fly = false
		obj.stepy = 0.5
		obj.solids = false
		obj.sfx_delay = 8
		obj.sprite = 28
	end,
	update = function(obj)
		-- fly away
		if obj.fly then
			if obj.sfx_delay > 0 then
				obj.sfx_delay = obj.sfx_delay - 1
				if obj.sfx_delay <= 0 then
					sfx_timer = 20
					snd.play_pattern(14)
				end
			end
			obj.speed.y = appr(obj.speed.y, -3.5, 0.25)
			if obj.y < -SPRITE_SIZE * 2 then
				obj.to_remove = true
			end
		else
			-- wait
			if has_dashed then
				obj.fly = true
			end
			obj.stepy = obj.stepy + 0.05
			obj.speed.y = math.sin(obj.stepy * 2.0 * PI) * 0.5
		end
		-- collect
		hit = obj_collide(obj, "Player", 0, 0)
		if hit then
			hit.djump = max_djump
			sfx_timer = 20
			snd.play_pattern(13)
			idx = level_index()
			if not got_fruit[idx] then
				got_fruit[idx] = true
				score = score + 1
			end
			create_object(LifeUp, obj.x, obj.y)
			obj.to_remove = true
		end
	end,
	draw = function(obj)
		off = 0
		if not obj.fly then
			dir = math.sin(obj.stepy * 2 * PI)
			if dir < 0 then
				off = 1 + math.max(0, sign(obj.y - obj.start))
			end
		else
			off = (off + 0.25) % 3
		end
		spr(45 + off, obj.x - 6, obj.y - 2, 1, 1, true, false)
		spr(obj.sprite, obj.x, obj.y, 1, 1, false, false)
		spr(45 + off, obj.x + 6, obj.y - 2, 1, 1, false, false)
	end
}

FallFloor = {
	name = "FallFloor",
	is_fruit = false,
	init = function(obj)
		obj.sprite = 23
		obj.state = 0
		obj.solid = true
	end,
	update = function(obj)
		-- idling
		if obj.state == 0 then
			if obj_check(obj, "Player", 0, -1) or obj_check(obj, "Player", -1, 0) or obj_check(obj, "Player", 1, 0) then
				break_fall_floor(obj)
				snd.play_pattern(15)
			end
		elseif obj.state == 1 then
			obj.delay = obj.delay - 1
			if obj.delay <= 0 then
				obj.state = 2
				obj.delay = 60
				obj.collideable = false
			end
		elseif obj.state == 2 then
			obj.delay = obj.delay - 1
			if obj.delay <= 0 and not obj_check(obj, "Player", 0, 0) then
				obj.state = 0
				obj.collideable = true
				snd.play_pattern(7)
				create_object(Smoke, obj.x, obj.y)
			end
		end
	end,
	draw = function(obj)
		if obj.state ~= 2 then
			if obj.state ~= 1 then
				spr(23, obj.x, obj.y, 1, 1, false, false)
			else
				spr(23 + (15 - obj.delay) / 5, obj.x, obj.y, 1, 1, false, false)
			end
		end
	end
}

Key = {
	name = "Key",
	is_fruit = true,
	init = function(obj)
		obj.sprite = 8
	end,
	update = function(obj)
		was = math.floor(obj.sprite)
		obj.sprite = 9 + (math.sin(frames / 30 * 2 * PI) + 0.5)
		is = math.floor(obj.sprite)
		if is == 10 and is ~= was then
			obj.hflip = not obj.hflip
		end
		if obj_check(obj, "Player", 0, 0) then
			sfx_timer = 10
			snd.play_pattern(23)
			obj.to_remove = true
			has_key = true
		end
	end,
	draw = nil
}

Chest = {
	name = "Chest",
	is_fruit = true,
	init = function(obj)
		obj.sprite = 20
		obj.x = obj.x - 4
		obj.start = obj.x
		obj.timer = 20
	end,
	update = function(obj)
		if has_key then
			obj.timer = obj.timer - 1
			obj.x = obj.start - 1 + math.random() * 3
			if obj.timer <= 0 then
				snd.play_pattern(16)
				sfx_timer = 20
				create_object(Fruit, obj.x, obj.y - 4)
				obj.to_remove = true
			end
		end
	end,
	draw = nil
}

Balloon = {
	name = "Balloon",
	is_fruit = false,
	init = function(obj)
		obj.offset = math.random()
		obj.start = obj.y
		obj.timer = 0
		obj.hitbox = { x = -1, y = -1, w = SPRITE_SIZE * 2, h = SPRITE_SIZE * 2 }
		obj.sprite = 22
	end,
	update = function(obj)
		if obj.sprite == 22 then
			obj.offset = obj.offset + 0.01
			obj.y = obj.start + math.sin(obj.offset * 2 * PI) * 2
			hit = obj_collide(obj, "Player", 0, 0)
			if hit and hit.djump < max_djump then
				create_object(Smoke, obj.x, obj.y)
				hit.djump = max_djump
				obj.sprite = 0
				obj.timer = 60
				snd.play_pattern(6)
			end
		elseif obj.timer > 0 then
			obj.timer = obj.timer - 1
		else
			create_object(Smoke, obj.x, obj.y)
			obj.sprite = 22
			snd.play_pattern(7)
		end
	end,
	draw = function(obj)
		if obj.sprite == 22 then
			spr(13 + (obj.offset * 8) % 3, obj.x, obj.y + 6, 1, 1, false, false)
			spr(obj.sprite, obj.x, obj.y, 1, 1, false, false)
		end
	end
}

function obj_move_x(obj, amount, start)
	if obj.solids then
		stepx = sign(amount)
		for i = start, math.abs(amount) do
			if not obj_is_solid(obj, stepx, 0) then
				obj.x = obj.x + stepx
			else
				obj.speed.x = 0
				obj.rem.x = 0
				break
			end
		end
	else
		obj.x = obj.x + amount
	end
end

function platform_init(obj)
	obj.x = obj.x - SPRITE_SIZE / 2
	obj.solids = false
	obj.hitbox.w = SPRITE_SIZE * 2
	obj.last = obj.x
end

function platform_update(obj)
	obj.speed.x = obj.dir * 0.95
	if obj.x < -2 * SPRITE_SIZE then
		obj.x = SCREEN_SIZE
	elseif obj.x > SCREEN_SIZE then
		obj.x = -2 * SPRITE_SIZE
	end
	if not obj_check(obj, "Player", 0, 0) then
		hit = obj_collide(obj, "Player", 0, -1)
		if hit then
			obj_move_x(hit, obj.x - obj.last, 1)
		end
	end
	obj.last = obj.x
end

function platform_draw(obj)
	spr(11, obj.x, obj.y - 1, 1, 1, false, false)
	spr(12, obj.x + SPRITE_SIZE, obj.y - 1, 1, 1, false, false)
end

RPlatform = {
	name = "Platform",
	is_fruit = false,
	init = function(obj)
		platform_init(obj);
		obj.dir = 1;
	end,
	update = function(obj) platform_update(obj); end,
	draw = function(obj) platform_draw(obj); end
}

LPlatform = {
	name = "Platform",
	is_fruit = false,
	init = function(obj)
		platform_init(obj);
		obj.dir = -1;
	end,
	update = function(obj) platform_update(obj); end,
	draw = function(obj) platform_draw(obj); end
}

BigChest = {
	name = "BigChest",
	is_fruit = false,
	init = function(obj)
		obj.sprite = 96
		obj.state = 0
		obj.hitbox.w = SPRITE_SIZE * 2
	end,
	update = function(obj)
		if obj.state == 0 then
			hit = obj_collide(obj, "Player", 0, SPRITE_SIZE)
			if hit and obj_is_solid(hit, 0, 1) then
				pause_player = true
				hit.speed.x = 0
				hit.speed.y = 0
				obj.state = 1
				snd.play_pattern(37)
				create_object(Smoke, obj.x, obj.y)
				create_object(Smoke, obj.x + SPRITE_SIZE, obj.y)
				obj.timer = 60
				obj.particles = {}
			end
		elseif obj.state == 1 then
			obj.timer = obj.timer - 1
			shake = 5
			flash_bg = true
			if obj.timer <= 45 and #obj.particles < 50 then
				table.insert(obj.particles, {
					x = 1 + math.random() * SPRITE_SIZE * 2,
					y = 0,
					h = 32 + math.random() * 32,
					spd = 8 + math.random() * 8
				})
			end
			if obj.timer < 0 then
				obj.state = 2
				obj.particles = {}
				flash_bg = false
				new_bg = true
				create_object(Orb, obj.x + SPRITE_SIZE / 2, obj.y + SPRITE_SIZE / 2)
				pause_player = false
			end
			for _, p in pairs(obj.particles) do
				p.y = p.y + p.spd
			end
		end
	end,
	draw = function(obj)
		if obj.state == 0 then
			spr(96, obj.x, obj.y, 1, 1, false, false)
			spr(97, obj.x + SPRITE_SIZE, obj.y, 1, 1, false, false)
		elseif obj.state == 1 then
			for _, p in pairs(obj.particles) do
				line(obj.x + p.x, obj.y + SPRITE_SIZE - p.y, obj.x + p.x,
					math.min(obj.y + SPRITE_SIZE - p.y + p.h, obj.y + SPRITE_SIZE), 8)
			end
		end
		spr(112, obj.x, obj.y + SPRITE_SIZE, 1, 1, false, false)
		spr(113, obj.x + SPRITE_SIZE, obj.y + SPRITE_SIZE, 1, 1, false, false)
	end
}

Orb = {
	name = "Orb",
	is_fruit = false,
	init = function(obj)
		obj.speed.y = -4
		obj.solids = false
		obj.particles = {}
	end,
	update = function(obj)
		obj.speed.y = appr(obj.speed.y, 0, 0.5)
		local hit = obj_collide(obj, "Player", 0, 0)
		if hit and obj.speed.y == 0 then
			music_timer = 45
			freeze = 10
			shake = 10
			snd.play_music(4, 7)
			snd.play_pattern(51)
			obj.to_remove = true
			max_djump = 2
			hit.djump = 2
		end
	end,
	draw = function(obj)
		spr(102, obj.x, obj.y, 1, 1, false, false)
		local off = frames / 30
		for i = 0, 7 do
			local x = obj.x + 7 + math.cos((off + i / 8) * 2 * PI) * 9
			local y = obj.y + 7 + math.sin((off + i / 8) * 2 * PI) * 9
			circ_fill(x, y, 2, 7)
		end
	end
}

Flag = {
	name = "Flag",
	is_fruit = false,
	init = function(obj)
		obj.sprite = 118
		obj.x = obj.x + 5
		obj.show = false
	end,
	update = function(obj)
		obj.sprite = 118 + (frames / 5) % 3
		if not obj.show and obj_check(obj, "Player", 0, 0) then
			obj.show = true
			sfx_timer = 30
			snd.play_pattern(55)
		end
	end,
	draw = function(obj)
		spr(obj.sprite, obj.x, obj.y, 1, 1, false, false)
		if obj.show then
			rect_fill(74, 52, 148, 64, 0)
			cel_print("Victory!", 80, 54, 7)
		end
	end
}

TEXT = "-- celeste mountain --#this memorial to those# perished on the climb"

Message = {
	name = "Message",
	is_fruit = false,
	init = function(obj)
		obj.last = 0
		obj.dir = 0
	end,
	update = function(obj)
		if obj_check(obj, "Player", 4, 0) then
			obj.sprite = 1
			if obj.dir < #TEXT then
				obj.dir = obj.dir + 0.5
				if obj.dir >= obj.last + 1 then
					obj.last = obj.last + 1
					snd.play_pattern(35)
				end
			end
		else
			obj.sprite = 0
			obj.last = 0
			obj.dir = 0
		end
	end,
	draw = function(obj)
		if obj.sprite == 1 then
			local x = 24
			local y = 164
			local len = #TEXT
			local max = math.min(math.floor(obj.dir) + 1, len)
			for i = 1, max do
				local ch = TEXT:sub(i, i)
				if ch == "#" then
					x = 24
					y = y + 10
				else
					rect_fill(x - 2, y - 2, x + 9, y + 10, 7)
					cel_print(ch, x, y, 1)
					x = x + 8
				end
			end
		end
	end
}

TILE_2_OBJ[1] = PlayerSpawn
TILE_2_OBJ[8] = Key
TILE_2_OBJ[11] = LPlatform
TILE_2_OBJ[12] = RPlatform
TILE_2_OBJ[18] = Spring
TILE_2_OBJ[20] = Chest
TILE_2_OBJ[22] = Balloon
TILE_2_OBJ[23] = FallFloor
TILE_2_OBJ[26] = Fruit
TILE_2_OBJ[28] = FlyFruit
TILE_2_OBJ[64] = FakeWall
TILE_2_OBJ[86] = Message
TILE_2_OBJ[96] = BigChest
TILE_2_OBJ[118] = Flag

function draw_object(obj)
	if obj.type.draw ~= nil then
		obj.type.draw(obj)
	else
		spr(obj.sprite, math.floor(obj.x), math.floor(obj.y), 1, 1, obj.hflip, obj.vflip)
	end
end

function title_screen()
	got_fruit = {}
	for i = 0, 29 do
		got_fruit[i] = false
	end
	frames = 0
	score = 0
	deaths = 0
	cheat = false
	max_djump = 1
	start_game = false
	start_game_flash = 0
	load_room(7, 3)
end

function init_music()
	for _, sfx in pairs(SFX) do
		snd.new_pattern(sfx)
	end
	snd.new_music(MUSIC_TITLE)
	snd.new_music(MUSIC_FIRST_LEVELS)
	snd.new_music(MUSIC_WIND)
	snd.new_music(MUSIC_SECOND_PART)
	snd.new_music(MUSIC_LAST_PART)
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
	snd.play_music(0, 7)
end

function init()
	init_music()
	inp.set_ls_neutral_zone(0.2)
	for i = 0, CLOUD_COUNT - 1 do
		clouds[i] = {
			x = math.random() * SCREEN_SIZE,
			y = math.random() * SCREEN_SIZE,
			spd = 1 + math.random() * 4,
			w = 32 + math.random() * 32,
		}
	end
	for i = 0, PARTICLE_COUNT - 1 do
		particles[i] = {
			x = math.random() * SCREEN_SIZE,
			y = math.random() * SCREEN_SIZE,
			s = math.floor(math.random() * 5 / 4),
			spdx = 0.25 + math.random() * 5,
			spdy = 0,
			off = math.random(),
			c = 6 + math.floor(0.5 + math.random()),
		}
	end
	gfx.set_scanline(gfx.SCANLINE_HARD)
	gfx.set_layer_size(0, 384, 244)
	gfx.set_layer_size(1, 384, 244)
	gfx.set_layer_size(2, 384, 244)
	gfx.set_layer_size(3, 384, 244)
	gfx.set_layer_size(7, 384, 244)
	gfx.set_layer_offset(0, 0.0, 10.0)
	gfx.set_layer_offset(1, 0.0, 10.0)
	gfx.set_layer_offset(2, 0.0, 10.0)
	gfx.set_layer_offset(3, 0.0, 10.0)
	gfx.set_layer_offset(7, 0.0, 10.0)
	gfx.show_layer(1); -- background
	gfx.show_layer(2); -- main game
	gfx.show_layer(3); -- fade to black layer
	gfx.show_layer(7); -- ui layer
	gfx.set_layer_operation(3, gfx.LAYEROP_MULTIPLY)
	gfx.set_active_layer(3)
	--gfx.set_layer_blur(0, 4)
	--gfx.set_layer_blur(1, 1)
	gfx.clear(255, 255, 255)
	gfx.load_img(SPRITESHEET_LAYER, "celeste/celeste14.png")
	gfx.set_sprite_layer(SPRITESHEET_LAYER)
	gfx.set_active_layer(2)
	title_screen()
end

function map(cx, cy, sx, sy, cw, ch, layer)
	for x = cx, cx + cw - 1 do
		for y = cy, cy + ch - 1 do
			local v = TILE_MAP[x + y * 128 + 1]
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

function obj_move_y(obj, amount)
	if obj.solids then
		stepy = sign(amount)
		for i = 0, math.abs(amount) do
			if not obj_is_solid(obj, 0, stepy) then
				obj.y = obj.y + stepy
			else
				obj.speed.y = 0
				obj.rem.y = 0
				break
			end
		end
	else
		obj.y = obj.y + amount
	end
end

function obj_move(obj)
	obj.rem.x = obj.rem.x + obj.speed.x
	amount = math.floor(obj.rem.x + 0.5)
	obj.rem.x = obj.rem.x - amount
	obj_move_x(obj, amount, 0)

	obj.rem.y = obj.rem.y + obj.speed.y
	amount = math.floor(obj.rem.y + 0.5)
	obj.rem.y = obj.rem.y - amount
	obj_move_y(obj, amount)
end

function begin_game()
	frames = 0
	seconds = 0
	minutes = 0
	music_timer = 0
	start_game = false
	load_room(0, 0)
end

function update()
	flipflop = not flipflop
	if not flipflop then
		return
	end
	-- clouds
	if not is_title() then
		for _, cloud in pairs(clouds) do
			cloud.x = cloud.x + cloud.spd
			if cloud.x > SCREEN_SIZE then
				cloud.x = -cloud.w
				cloud.y = math.random() * (SCREEN_SIZE - SPRITE_SIZE)
			end
		end
	end
	-- particles
	for _, part in pairs(particles) do
		part.x = part.x + part.spdx * 2
		part.y = part.y + math.sin(4 * PI * part.off)
		part.off = part.off + math.min(0.05, part.spdx / 32)
		if part.x > SCREEN_SIZE + SPRITE_SIZE / 2 then
			part.x = -SPRITE_SIZE / 2
			part.y = math.random() * SCREEN_SIZE
		end
	end
	-- dead particles
	for i = #dead_particles, 1, -1 do
		p = dead_particles[i]
		p.x = p.x + p.spdx
		p.y = p.y + p.spdy
		p.t = p.t - 1
		if p.t <= 0 then
			table.remove(dead_particles, i)
		end
	end
	frames = (frames + 1) % 30

	if frames == 0 and level_index() < 30 then
		seconds = (seconds + 1) % 60
		if seconds == 0 then
			minutes = minutes + 1
		end
	end
	if freeze > 0 then
		freeze = freeze - 1
		return
	end
	-- screenshake
	if shake > 0 then
		shake = shake - 1
		if shake > 0 then
			cam_offset_x = math.floor( -2 + math.random() * 5)
			cam_offset_y = math.floor(8 + math.random() * 5)
		else
			cam_offset_x = 0
			cam_offset_y = 10
		end
	end

	-- restart
	if will_restart and delay_restart > 0 then
		delay_restart = delay_restart - 1
		if delay_restart <= 0 then
			will_restart = false
			load_room(roomx, roomy)
		end
	elseif will_next_room then
		will_next_room = false
		next_room()
	end

	-- update objects
	for i = #objects, 1, -1 do
		obj = objects[i]
		if obj.to_remove then
			table.remove(objects, i)
		else
			obj_move(obj)
			obj.type.update(obj)
		end
	end

	-- start game
	if is_title() then
		if not start_game then
			if inp.action1_pressed() or inp.action2_pressed() then
				start_game_flash = 50
				start_game = true
				snd.play_music( -1, 0)
				snd.play_pattern(38)
			end
		end
		if start_game then
			start_game_flash = start_game_flash - 1
			if start_game_flash <= -30 then
				begin_game()
				snd.play_music(1, 7)
			end
		end
	end
end

function draw_level(x, y, col)
	rect_fill( -X_OFFSET, 0, 0, SCREEN_SIZE, 0)
	rect_fill(
		SCREEN_SIZE,
		0,
		SCREEN_SIZE + X_OFFSET,
		SCREEN_SIZE,
		0
	)
	if roomx == 3 and roomy == 1 then
		cel_print("old site", x + X_OFFSET / 2 - 32, y + 4, col)
	elseif level_index() == 30 then
		cel_print("summit", x + X_OFFSET / 2 - 24, y + 4, col)
	else
		level = (1 + level_index()) * 100
		offset = 0
		if level >= 1000 then
			offset = 4
		end
		cel_print(
			tostring(level) .. " m",
			x + X_OFFSET / 2 - 20 - offset,
			y + 4,
			col
		)
	end
end

function draw_time(x, y, col)
	gfx.rectangle(x, y, x + 64, y + 8, 0, 0, 0)
	ss = seconds < 10 and "0" .. tostring(seconds) or tostring(seconds)
	m = minutes % 60
	sm = m < 10 and "0" .. tostring(m) or tostring(m)
	h = minutes // 60
	sh = h < 10 and "0" .. tostring(h) or tostring(h)
	cel_print(tostring(sh) .. ":" .. tostring(sm) .. ":" .. tostring(ss), x + 1, y + 1, col)
end

function draw_ui()
	textcol = cheat and 8 or 7
	draw_level( -X_OFFSET, 4, textcol)
	draw_time( -32 - X_OFFSET / 2, 24, textcol)
	cel_print(
		" x " .. tostring(score),
		30 - X_OFFSET,
		44,
		textcol
	)
	cel_print(
		" x " .. tostring(deaths),
		30 - X_OFFSET,
		62,
		textcol
	)
	spr(26, 16 - X_OFFSET, 40, 1, 1, false, false)
	spr(1, 16 - X_OFFSET, 58, 1, 1, false, false)
end

function render()
	if freeze > 0 then
		return
	end
	local x = roomx * 16
	local y = roomy * 16
	if start_game then
		local l = (start_game_flash + 30) / 80
		gfx.set_active_layer(3)
		gfx.clear(l, l, l)
	elseif not is_title() then
		gfx.hide_layer(3)
	end
	gfx.set_active_layer(0)

	-- screen shake
	gfx.set_layer_offset(0, cam_offset_x, cam_offset_y)
	gfx.set_layer_offset(1, cam_offset_x, cam_offset_y)
	gfx.set_layer_offset(2, cam_offset_x, cam_offset_y)
	-- clear screen
	local bg_col = (flash_bg or start_game) and frames // 5 or (new_bg and 2 or 0)
	rect_fill(0, 0, SCREEN_SIZE, SCREEN_SIZE, bg_col)

	-- clouds
	if not is_title() then
		local bg = new_bg and 14 or 1
		for _, cloud in pairs(clouds) do
			rect_fill(
				cloud.x,
				cloud.y,
				cloud.x + cloud.w,
				cloud.y + 4 + (1 - cloud.w / 64) * 12,
				bg
			)
		end
	end

	gfx.set_active_layer(1)
	gfx.clear()
	map(x, y, 0, 0, 16, 16, 4)
	gfx.set_active_layer(2)
	gfx.clear()

	-- platforms / big chests
	for _, obj in pairs(objects) do
		local type_name = obj.type.name
		if type_name == "Platform" or type_name == "BigChest" then
			draw_object(obj)
		end
	end

	-- terrain
	local off = is_title() and 4 or 0
	map(x, y, off, 0, 16, 16, 2)

	-- objects
	for _, obj in pairs(objects) do
		local type_name = obj.type.name
		if type_name ~= "Platform" and type_name ~= "BigChest" then
			draw_object(obj)
		end
	end

	-- fg terrain
	map(x, y, 0, 0, 16, 16, 8)

	-- particles
	for _, part in pairs(particles) do
		rect_fill(
			part.x,
			part.y,
			part.x + part.s,
			part.y + part.s,
			part.c
		)
	end
	-- dead particles
	for _, part in pairs(dead_particles) do
		local sz = part.t * SPRITE_SIZE / 8 / 5
		rect_fill(
			part.x - sz,
			part.y - sz,
			part.x + sz,
			part.y + sz,
			14 + part.t % 2
		)
	end

	-- screen border masks
	rect_fill( -10, -10, -1, SCREEN_SIZE + 10, 0)
	rect_fill( -10, -10, SCREEN_SIZE + 10, -1, 0)
	rect_fill( -10, SCREEN_SIZE, SCREEN_SIZE + 10, SCREEN_SIZE + 10, 0)
	rect_fill(SCREEN_SIZE, -10, SCREEN_SIZE + 10, SCREEN_SIZE + 10, 0)
	-- credits
	if is_title() then
		cel_print("press x/c", SCREEN_SIZE / 2 - 24, SCREEN_SIZE * 70 / 128, 5)
		cel_print("Maddy Thorson", SCREEN_SIZE / 2 - 39, SCREEN_SIZE * 80 / 128, 5)
		cel_print("Noel Berry", SCREEN_SIZE / 2 - 28, SCREEN_SIZE * 90 / 128, 5)
		cel_print("viper port", SCREEN_SIZE / 2 - 28, SCREEN_SIZE * 110 / 128, 5)
		cel_print("jice", SCREEN_SIZE / 2 - 4, SCREEN_SIZE * 120 / 128, 5)
	else
		gfx.set_active_layer(7)
		draw_ui()
	end
end

TILE_MAP = {
	35, 49, 37, 37, 72, 37, 37, 50, 50, 50, 50, 50, 51, 0, 0, 36, 37, 38, 36, 37, 37, 38, 49, 50, 50, 50, 37, 38, 40, 40,
	40, 36, 37, 37, 37, 37, 37, 37, 50, 51, 40, 56, 40, 40, 49, 37, 37, 37, 50, 50, 50, 50, 51, 0, 0, 0, 49, 50, 50, 50,
	50, 50, 50, 50, 50, 51, 0, 0, 0, 36, 50, 50, 50, 51, 49, 50, 50, 50, 37, 37, 37, 37, 37, 72, 37, 37, 37, 37, 37, 37,
	37, 38, 40, 40, 36, 37, 37, 72, 37, 37, 37, 38, 40, 40, 40, 40, 36, 37, 72, 37, 37, 37, 38, 40, 40, 40, 40, 49, 50,
	50, 50, 37, 72, 37, 37, 37, 37, 37,
	37, 35, 49, 50, 50, 50, 51, 41, 0, 0, 40, 41, 0, 0, 0, 36, 37, 38, 49, 50, 50, 51, 40, 40, 0, 40, 36, 38, 42, 16, 40,
	36, 37, 72, 37, 37, 37, 38, 0, 42, 40, 40, 41, 40, 16, 36, 72, 37, 40, 40, 40, 41, 0, 0, 0, 0, 40, 40, 41, 0, 0, 0,
	0, 0, 40, 16, 0, 0, 0, 55, 40, 41, 0, 0, 0, 0, 42, 40, 49, 72, 37, 37, 37, 37, 37, 72, 37, 37, 50, 50, 50, 51, 40,
	40, 36, 37, 37, 37, 72, 37, 50, 51, 56, 40, 42, 40, 49, 50, 37, 37, 72, 37, 38, 40, 56, 40, 40, 40, 42, 42, 40, 49,
	50, 50, 50, 50, 37, 37,
	37, 37, 35, 32, 16, 40, 56, 0, 0, 0, 42, 0, 0, 0, 61, 36, 37, 37, 35, 32, 16, 40, 41, 41, 0, 40, 36, 38, 0, 58, 56,
	36, 37, 37, 37, 72, 37, 51, 0, 0, 41, 0, 0, 42, 0, 49, 37, 37, 40, 56, 41, 0, 0, 58, 103, 104, 56, 40, 0, 0, 0, 0, 0,
	0, 56, 40, 57, 62, 0, 58, 40, 0, 0, 0, 0, 0, 0, 40, 0, 36, 37, 37, 50, 50, 50, 50, 50, 51, 33, 34, 34, 35, 40, 40,
	36, 37, 37, 37, 50, 51, 40, 40, 40, 41, 0, 0, 42, 40, 49, 50, 37, 37, 38, 40, 40, 40, 40, 41, 0, 0, 42, 40, 40, 40,
	56, 40, 36, 72,
	50, 50, 51, 40, 40, 40, 41, 0, 0, 0, 0, 0, 63, 32, 32, 36, 72, 37, 38, 40, 40, 41, 0, 0, 0, 42, 36, 51, 0, 0, 42, 36,
	37, 50, 37, 37, 38, 0, 0, 0, 0, 0, 0, 0, 0, 0, 49, 37, 41, 0, 0, 0, 0, 33, 34, 35, 40, 40, 0, 0, 0, 0, 0, 0, 42, 40,
	40, 52, 53, 54, 41, 0, 0, 0, 0, 0, 0, 40, 57, 36, 37, 38, 33, 34, 35, 32, 33, 35, 49, 50, 50, 51, 40, 40, 36, 37, 72,
	38, 43, 0, 0, 0, 0, 0, 0, 0, 28, 0, 0, 59, 36, 37, 38, 40, 40, 40, 0, 0, 0, 0, 0, 40, 40, 40, 40, 40, 36, 37,
	35, 64, 40, 56, 40, 41, 58, 40, 57, 0, 0, 0, 52, 53, 34, 37, 37, 72, 38, 41, 0, 0, 0, 0, 0, 0, 48, 0, 0, 0, 0, 36,
	51, 0, 49, 37, 51, 61, 63, 0, 0, 0, 0, 0, 0, 0, 0, 49, 0, 0, 28, 58, 58, 49, 37, 38, 32, 40, 57, 0, 0, 0, 0, 0, 0,
	16, 40, 40, 40, 41, 0, 0, 0, 0, 17, 17, 58, 40, 40, 49, 50, 51, 36, 37, 38, 16, 49, 51, 32, 40, 40, 40, 40, 56, 36,
	37, 37, 38, 43, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 59, 36, 37, 38, 42, 40, 40, 103, 0, 22, 0, 42, 40, 40, 56, 40, 40, 36,
	37,
	38, 58, 40, 40, 40, 16, 40, 41, 0, 0, 0, 0, 0, 0, 49, 37, 37, 50, 51, 0, 0, 0, 0, 17, 0, 0, 55, 0, 0, 0, 62, 36, 0,
	0, 0, 55, 33, 34, 35, 0, 0, 0, 0, 0, 0, 0, 0, 0, 57, 88, 104, 40, 40, 40, 36, 38, 40, 41, 0, 0, 0, 0, 0, 0, 42, 40,
	40, 41, 0, 0, 0, 0, 0, 0, 33, 35, 40, 56, 40, 41, 40, 40, 49, 50, 51, 40, 40, 41, 0, 42, 0, 42, 40, 40, 36, 37, 37,
	51, 43, 12, 0, 0, 0, 17, 17, 0, 0, 0, 12, 59, 49, 72, 38, 17, 40, 16, 0, 0, 0, 0, 104, 40, 40, 40, 40, 40, 36, 37,
	37, 34, 53, 53, 54, 40, 40, 0, 0, 0, 0, 0, 0, 58, 40, 36, 38, 0, 61, 0, 58, 57, 0, 39, 0, 0, 0, 0, 0, 0, 33, 37, 0,
	26, 0, 0, 36, 37, 38, 17, 17, 17, 17, 0, 0, 0, 0, 44, 40, 56, 40, 40, 40, 56, 49, 51, 40, 0, 0, 0, 23, 23, 0, 0, 0,
	42, 0, 0, 0, 0, 17, 17, 0, 0, 36, 38, 16, 40, 41, 0, 40, 40, 27, 27, 27, 40, 40, 0, 0, 0, 0, 0, 42, 33, 37, 72, 38,
	40, 57, 0, 0, 0, 59, 52, 54, 43, 0, 0, 0, 0, 40, 36, 37, 35, 40, 40, 58, 103, 0, 58, 40, 40, 40, 41, 0, 42, 49, 50,
	37, 51, 56, 40, 40, 41, 0, 0, 0, 0, 0, 0, 0, 40, 56, 36, 37, 35, 32, 32, 16, 41, 0, 48, 57, 0, 0, 0, 0, 88, 36, 72,
	0, 0, 0, 58, 49, 50, 50, 53, 53, 53, 54, 103, 88, 0, 0, 60, 40, 40, 40, 40, 16, 40, 33, 35, 41, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 52, 54, 0, 58, 36, 38, 40, 40, 0, 0, 56, 40, 57, 0, 0, 0, 42, 41, 0, 0, 0, 0, 0, 49, 50, 50, 38,
	16, 16, 0, 0, 0, 0, 40, 40, 57, 0, 0, 0, 0, 42, 36, 37, 51, 40, 40, 40, 56, 0, 40, 40, 40, 57, 0, 0, 0, 23, 0,
	38, 0, 0, 42, 40, 0, 0, 0, 0, 58, 40, 58, 40, 40, 40, 36, 37, 37, 34, 35, 40, 57, 0, 55, 40, 88, 57, 0, 104, 40, 49,
	50, 0, 0, 0, 40, 40, 40, 40, 40, 32, 32, 40, 40, 40, 57, 33, 34, 40, 41, 0, 42, 40, 40, 36, 38, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 32, 56, 40, 40, 49, 37, 35, 0, 0, 0, 40, 40, 40, 41, 0, 0, 0, 0, 0, 22, 58, 103, 104, 40, 40, 0,
	51, 56, 40, 11, 0, 0, 0, 16, 56, 40, 0, 0, 11, 0, 0, 49, 51, 40, 40, 40, 40, 40, 104, 40, 40, 40, 40, 0, 0, 0, 23, 0,
	51, 0, 0, 0, 40, 103, 88, 0, 0, 40, 16, 40, 40, 52, 34, 37, 37, 37, 72, 38, 40, 40, 103, 32, 40, 40, 40, 56, 40, 40,
	33, 34, 0, 0, 58, 40, 56, 40, 16, 41, 0, 0, 42, 40, 56, 40, 36, 37, 42, 0, 0, 0, 40, 56, 36, 38, 0, 0, 0, 23, 23, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 39, 40, 40, 42, 40, 49, 51, 57, 0, 0, 40, 41, 0, 0, 0, 0, 0, 0, 0, 0, 42, 40, 40, 40, 41, 0,
	42, 40, 57, 0, 0, 0, 0, 42, 40, 41, 0, 0, 0, 0, 0, 0, 40, 40, 40, 56, 40, 40, 40, 40, 40, 40, 41, 0, 0, 0, 0, 0,
	0, 0, 0, 58, 40, 40, 56, 62, 58, 40, 40, 40, 56, 40, 36, 37, 72, 37, 37, 38, 0, 42, 40, 39, 41, 0, 42, 40, 40, 52,
	50, 37, 0, 0, 0, 42, 40, 40, 40, 0, 0, 0, 0, 40, 16, 40, 36, 37, 0, 0, 0, 0, 42, 40, 36, 38, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 55, 40, 0, 0, 0, 42, 40, 40, 57, 0, 40, 0, 0, 0, 57, 40, 57, 0, 0, 0, 0, 0, 40, 40, 0, 0, 0, 40,
	41, 0, 0, 0, 42, 40, 40, 0, 0, 0, 0, 0, 0, 0, 42, 40, 40, 40, 40, 16, 40, 40, 40, 40, 103, 88, 0, 0, 0, 0,
	0, 0, 0, 40, 56, 40, 40, 33, 35, 40, 0, 0, 42, 40, 36, 37, 50, 50, 37, 38, 0, 58, 40, 48, 0, 0, 0, 0, 42, 40, 40, 36,
	0, 0, 0, 0, 0, 42, 40, 17, 17, 17, 17, 40, 40, 40, 36, 72, 0, 0, 0, 58, 40, 40, 49, 51, 0, 0, 0, 0, 0, 0, 23, 23, 0,
	1, 63, 0, 0, 0, 32, 41, 0, 0, 0, 0, 56, 40, 0, 0, 40, 1, 58, 40, 40, 16, 40, 88, 0, 0, 0, 58, 40, 41, 0, 0, 0, 42,
	40, 12, 0, 0, 0, 58, 56, 12, 0, 0, 0, 0, 0, 12, 0, 0, 42, 40, 40, 40, 40, 40, 41, 40, 40, 41, 0, 0, 0, 58,
	0, 1, 58, 33, 35, 40, 42, 49, 51, 41, 0, 17, 17, 17, 36, 37, 0, 40, 49, 38, 58, 56, 41, 48, 0, 0, 0, 0, 0, 0, 42, 49,
	0, 0, 0, 0, 0, 0, 40, 52, 34, 34, 54, 41, 42, 0, 36, 37, 62, 1, 58, 56, 40, 41, 42, 0, 0, 0, 0, 0, 0, 0, 0, 0, 53,
	53, 53, 54, 0, 0, 32, 0, 0, 0, 0, 61, 42, 40, 103, 20, 34, 34, 35, 40, 40, 40, 40, 40, 57, 0, 88, 40, 56, 40, 61, 0,
	0, 58, 41, 0, 0, 0, 0, 40, 40, 0, 0, 0, 0, 0, 0, 0, 0, 0, 42, 40, 40, 42, 41, 0, 0, 88, 16, 0, 18, 0, 42, 40,
	34, 34, 34, 37, 38, 41, 0, 33, 35, 17, 17, 33, 34, 34, 37, 37, 0, 42, 56, 55, 40, 41, 0, 48, 17, 17, 17, 0, 0, 0, 58,
	40, 0, 1, 63, 0, 0, 0, 42, 40, 36, 38, 41, 0, 0, 0, 36, 37, 34, 34, 34, 35, 41, 0, 0, 0, 0, 0, 0, 0, 23, 23, 0, 0,
	42, 40, 32, 57, 0, 58, 32, 0, 0, 58, 0, 52, 53, 53, 53, 53, 37, 37, 37, 34, 34, 34, 35, 40, 40, 40, 40, 16, 40, 40,
	33, 34, 11, 16, 0, 0, 0, 0, 11, 40, 16, 0, 0, 0, 11, 0, 0, 0, 44, 0, 0, 40, 56, 0, 0, 0, 0, 42, 40, 57, 23, 0, 0, 40,
	37, 72, 37, 37, 38, 17, 17, 36, 37, 34, 34, 37, 37, 37, 72, 37, 0, 1, 42, 40, 40, 103, 63, 36, 34, 34, 35, 0, 0, 0,
	56, 40, 34, 34, 35, 0, 0, 18, 0, 42, 36, 38, 0, 0, 0, 18, 36, 37, 37, 37, 37, 38, 0, 0, 0, 0, 23, 23, 0, 0, 0, 0, 0,
	0, 0, 56, 32, 40, 57, 40, 39, 8, 0, 40, 103, 104, 32, 40, 40, 40, 37, 72, 37, 37, 37, 37, 38, 42, 40, 40, 33, 34, 34,
	34, 37, 37, 58, 40, 1, 61, 0, 0, 0, 104, 40, 57, 0, 0, 0, 0, 0, 0, 60, 1, 104, 40, 40, 0, 23, 23, 23, 0, 58, 40, 0,
	0, 58, 40,
	37, 37, 37, 37, 37, 34, 34, 37, 37, 37, 37, 37, 37, 37, 37, 37, 34, 34, 34, 34, 34, 34, 34, 37, 37, 72, 38, 103, 88,
	104, 40, 40, 37, 72, 38, 0, 0, 39, 0, 0, 36, 38, 0, 0, 0, 33, 37, 37, 37, 37, 72, 38, 23, 23, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 42, 32, 40, 16, 40, 48, 0, 58, 40, 40, 40, 32, 40, 40, 40, 37, 37, 37, 37, 72, 37, 38, 0, 0, 42, 36, 37, 37,
	37, 72, 37, 40, 33, 34, 35, 0, 0, 0, 40, 40, 40, 0, 0, 0, 0, 0, 0, 34, 34, 34, 35, 40, 103, 0, 0, 0, 0, 40, 40, 57,
	0, 40, 56,
	37, 50, 51, 0, 0, 0, 36, 50, 50, 50, 50, 50, 50, 50, 37, 37, 37, 37, 38, 40, 40, 40, 40, 36, 37, 50, 50, 50, 50, 37,
	72, 37, 37, 50, 50, 50, 50, 50, 50, 50, 37, 38, 40, 40, 40, 36, 72, 37, 37, 37, 37, 51, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 82, 37, 37, 50, 50, 50, 50, 51, 49, 50, 50, 50, 50, 51, 40, 41, 0, 38, 40, 41, 40, 103, 0, 0, 0, 0, 0, 40, 40, 49,
	50, 50, 50, 37, 37, 37, 50, 51, 40, 40, 0, 49, 37, 37, 72, 37, 37, 37, 72, 37, 37, 72, 38, 40, 56, 40, 49, 50, 50,
	50, 50, 50, 50, 37, 72,
	38, 40, 40, 0, 0, 0, 48, 64, 42, 40, 40, 40, 40, 40, 36, 37, 37, 72, 38, 40, 56, 40, 40, 49, 51, 56, 40, 41, 0, 49,
	50, 37, 38, 40, 0, 0, 22, 58, 40, 40, 49, 51, 40, 40, 56, 36, 37, 37, 72, 37, 38, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	82, 37, 38, 0, 0, 22, 0, 0, 0, 0, 42, 16, 40, 40, 56, 57, 0, 38, 40, 26, 56, 32, 57, 61, 0, 0, 0, 0, 42, 56, 40, 40,
	40, 37, 37, 38, 40, 40, 40, 41, 0, 59, 36, 37, 50, 50, 50, 50, 50, 50, 50, 50, 51, 40, 40, 40, 40, 40, 40, 16, 40,
	40, 32, 49, 37,
	51, 40, 57, 0, 0, 0, 55, 0, 0, 42, 56, 40, 0, 42, 36, 37, 37, 37, 38, 40, 40, 40, 40, 32, 40, 41, 42, 0, 0, 0, 42,
	49, 51, 40, 17, 17, 17, 40, 40, 40, 0, 0, 40, 0, 42, 49, 37, 37, 37, 37, 38, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 82,
	37, 38, 0, 0, 0, 0, 17, 17, 0, 0, 0, 41, 42, 40, 41, 0, 38, 40, 58, 40, 32, 16, 32, 17, 17, 17, 33, 34, 35, 40, 40,
	16, 37, 37, 38, 40, 56, 40, 0, 0, 59, 36, 38, 43, 0, 42, 42, 56, 40, 40, 40, 40, 40, 41, 0, 42, 40, 0, 40, 40, 56,
	40, 40, 49,
	40, 40, 16, 41, 0, 0, 0, 0, 0, 0, 40, 40, 57, 0, 36, 72, 37, 37, 38, 40, 41, 0, 40, 32, 103, 0, 0, 0, 0, 0, 0, 0, 56,
	16, 33, 34, 35, 40, 56, 41, 0, 58, 16, 41, 0, 42, 36, 37, 50, 50, 51, 103, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 66, 0, 37,
	38, 57, 0, 0, 0, 33, 35, 0, 0, 0, 0, 0, 33, 34, 34, 37, 34, 34, 35, 33, 34, 35, 33, 34, 35, 36, 72, 38, 40, 40, 40,
	50, 50, 51, 40, 40, 40, 0, 0, 59, 49, 51, 43, 0, 0, 0, 40, 16, 40, 41, 0, 0, 0, 0, 0, 41, 0, 42, 40, 40, 40, 41, 0,
	40, 40, 40, 0, 22, 0, 0, 0, 22, 42, 40, 40, 40, 0, 36, 37, 37, 37, 38, 39, 0, 0, 42, 32, 41, 0, 0, 0, 0, 0, 0, 0, 40,
	52, 37, 37, 51, 41, 42, 0, 0, 0, 42, 0, 17, 17, 36, 37, 34, 35, 40, 40, 0, 0, 44, 70, 71, 44, 0, 0, 0, 66, 83, 83,
	37, 38, 40, 0, 0, 58, 36, 38, 0, 0, 22, 0, 0, 36, 37, 37, 37, 37, 72, 38, 49, 50, 51, 49, 50, 51, 36, 37, 38, 32, 40,
	56, 34, 34, 35, 40, 41, 40, 103, 0, 0, 40, 41, 0, 0, 0, 0, 0, 40, 56, 0, 17, 17, 0, 0, 18, 0, 0, 0, 40, 41, 42, 22,
	0,
	40, 56, 40, 0, 0, 0, 0, 0, 0, 0, 58, 40, 41, 0, 36, 37, 72, 37, 38, 55, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 0, 58, 41, 59,
	36, 38, 40, 57, 0, 0, 0, 0, 0, 59, 33, 34, 37, 37, 37, 38, 56, 40, 103, 0, 60, 86, 87, 60, 66, 67, 67, 83, 99, 99,
	50, 51, 40, 57, 0, 40, 36, 38, 17, 17, 17, 17, 17, 36, 37, 37, 37, 72, 37, 38, 32, 27, 27, 27, 27, 27, 36, 37, 38,
	40, 40, 40, 37, 37, 38, 0, 0, 42, 40, 20, 58, 41, 0, 0, 0, 0, 0, 0, 40, 41, 59, 33, 35, 0, 0, 23, 0, 0, 17, 40, 103,
	0, 0, 0,
	40, 40, 40, 103, 88, 0, 0, 0, 88, 104, 40, 56, 0, 0, 49, 50, 50, 50, 51, 32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 39, 40, 40,
	0, 59, 36, 38, 41, 0, 0, 0, 0, 0, 0, 59, 49, 37, 72, 37, 37, 51, 40, 40, 40, 57, 33, 34, 34, 35, 82, 83, 83, 100, 0,
	0, 41, 0, 42, 40, 56, 40, 49, 50, 53, 53, 53, 53, 34, 37, 72, 37, 37, 37, 37, 37, 35, 0, 0, 0, 0, 0, 49, 50, 51, 40,
	16, 40, 72, 37, 38, 17, 17, 17, 52, 53, 54, 17, 17, 17, 17, 0, 0, 0, 0, 0, 59, 49, 51, 17, 17, 17, 17, 17, 39, 40,
	41, 0, 0, 59,
	40, 40, 40, 40, 16, 41, 0, 0, 0, 42, 40, 40, 103, 0, 0, 40, 53, 53, 53, 54, 17, 17, 0, 0, 0, 0, 0, 0, 17, 48, 40, 56,
	0, 59, 49, 51, 0, 0, 0, 0, 0, 0, 0, 42, 40, 49, 50, 37, 38, 42, 40, 40, 16, 40, 36, 37, 37, 38, 98, 99, 100, 0, 0, 0,
	0, 22, 0, 40, 40, 40, 41, 0, 0, 0, 0, 0, 49, 50, 37, 37, 37, 37, 37, 37, 38, 103, 88, 0, 0, 0, 32, 0, 0, 42, 40, 40,
	37, 37, 50, 53, 53, 53, 34, 34, 34, 34, 34, 53, 54, 57, 0, 0, 0, 0, 59, 52, 53, 53, 53, 53, 53, 54, 48, 56, 0, 0, 0,
	23,
	40, 41, 0, 0, 42, 0, 0, 0, 0, 0, 56, 42, 41, 0, 58, 40, 40, 40, 40, 52, 54, 32, 0, 0, 0, 0, 0, 0, 32, 48, 40, 40, 0,
	0, 42, 41, 0, 0, 17, 17, 0, 0, 0, 0, 40, 40, 40, 49, 38, 0, 41, 0, 42, 40, 36, 72, 37, 37, 35, 0, 0, 0, 0, 0, 57, 0,
	58, 40, 41, 0, 0, 0, 0, 0, 0, 0, 0, 40, 49, 50, 37, 37, 72, 37, 38, 56, 41, 0, 0, 0, 23, 0, 0, 88, 104, 40, 50, 51,
	16, 40, 41, 59, 36, 72, 37, 37, 38, 40, 40, 40, 0, 0, 0, 0, 59, 32, 27, 27, 27, 27, 27, 27, 48, 40, 0, 0, 0, 23,
	40, 58, 0, 0, 0, 0, 0, 0, 0, 0, 40, 0, 0, 0, 40, 40, 40, 56, 16, 41, 42, 0, 0, 0, 0, 0, 0, 0, 42, 55, 16, 40, 17, 17,
	17, 17, 17, 17, 33, 54, 0, 0, 0, 0, 42, 40, 56, 11, 38, 0, 0, 0, 0, 33, 37, 37, 37, 37, 38, 0, 28, 0, 0, 0, 40, 40,
	40, 16, 0, 0, 0, 0, 0, 17, 0, 0, 42, 56, 40, 41, 37, 37, 37, 37, 38, 40, 0, 0, 0, 0, 23, 0, 0, 42, 33, 34, 40, 40,
	41, 8, 0, 59, 36, 37, 37, 72, 38, 40, 40, 41, 18, 0, 0, 0, 0, 27, 0, 0, 0, 0, 0, 0, 48, 41, 0, 0, 0, 59,
	56, 41, 0, 0, 0, 0, 0, 0, 0, 58, 16, 41, 0, 0, 40, 56, 40, 40, 40, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 42, 40, 40, 34, 53,
	53, 53, 53, 53, 51, 0, 0, 0, 0, 0, 0, 40, 40, 57, 51, 0, 0, 0, 0, 49, 50, 37, 37, 37, 51, 0, 0, 0, 0, 0, 40, 56, 40,
	41, 0, 0, 0, 0, 59, 32, 43, 0, 104, 40, 40, 0, 50, 50, 50, 50, 51, 41, 0, 0, 0, 0, 0, 0, 0, 0, 49, 37, 40, 40, 0, 0,
	0, 59, 49, 50, 50, 37, 38, 56, 40, 0, 23, 0, 0, 0, 0, 0, 0, 0, 0, 17, 0, 0, 55, 0, 0, 0, 0, 0,
	41, 0, 0, 0, 0, 0, 0, 0, 0, 0, 42, 0, 0, 0, 40, 41, 40, 41, 42, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 40, 42, 51, 40, 56,
	40, 40, 41, 0, 0, 0, 0, 0, 0, 0, 16, 40, 40, 0, 0, 0, 0, 66, 67, 68, 36, 37, 38, 40, 57, 0, 0, 0, 0, 40, 0, 42, 0, 0,
	17, 0, 0, 0, 27, 0, 42, 32, 16, 41, 44, 27, 27, 27, 27, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16, 49, 40, 41, 22, 0, 0, 0,
	27, 27, 27, 49, 51, 40, 16, 103, 0, 0, 0, 0, 0, 17, 0, 0, 58, 39, 0, 0, 27, 0, 0, 0, 0, 0,
	0, 0, 1, 0, 0, 0, 17, 17, 17, 0, 0, 0, 0, 0, 42, 58, 42, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 42, 40, 0, 40, 40, 41,
	0, 42, 0, 0, 0, 0, 0, 0, 0, 0, 40, 40, 40, 0, 0, 0, 0, 82, 83, 84, 36, 72, 38, 40, 40, 0, 0, 0, 0, 41, 0, 0, 0, 59,
	32, 43, 57, 0, 0, 0, 0, 41, 0, 0, 60, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 40, 40, 40, 0, 0, 0, 0, 0, 0, 0, 0,
	27, 27, 42, 40, 41, 0, 0, 1, 0, 0, 39, 57, 0, 56, 48, 0, 0, 0, 0, 0, 0, 0, 0,
	17, 17, 32, 17, 17, 17, 33, 34, 35, 0, 0, 0, 18, 18, 0, 42, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 41, 0, 41, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 42, 103, 104, 40, 41, 0, 0, 63, 1, 0, 82, 83, 84, 36, 37, 38, 40, 16, 103, 58, 57, 0, 1, 63,
	0, 0, 0, 42, 56, 41, 0, 17, 0, 0, 0, 0, 0, 33, 1, 0, 0, 0, 0, 0, 0, 0, 58, 103, 0, 0, 0, 0, 42, 56, 40, 103, 88, 104,
	0, 0, 1, 0, 0, 0, 0, 104, 40, 0, 0, 0, 33, 35, 0, 55, 40, 41, 40, 48, 0, 0, 0, 0, 0, 0, 0, 0,
	34, 34, 34, 34, 34, 35, 36, 72, 38, 17, 17, 17, 32, 32, 17, 17, 0, 39, 57, 0, 0, 23, 23, 0, 0, 0, 23, 23, 0, 0, 0, 0,
	0, 1, 0, 0, 0, 0, 23, 23, 0, 0, 0, 40, 40, 56, 57, 58, 0, 33, 34, 35, 82, 83, 84, 36, 37, 51, 40, 40, 40, 56, 41, 0,
	34, 35, 43, 0, 0, 8, 40, 57, 59, 39, 0, 0, 0, 0, 20, 36, 35, 0, 0, 0, 18, 0, 0, 0, 40, 41, 0, 0, 0, 0, 0, 40, 40, 40,
	16, 40, 103, 0, 23, 23, 23, 23, 23, 40, 40, 57, 0, 0, 49, 51, 57, 39, 16, 18, 40, 55, 0, 0, 0, 0, 0, 0, 0, 0,
	37, 72, 37, 37, 37, 38, 36, 37, 38, 33, 34, 34, 34, 34, 34, 34, 58, 48, 56, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	23, 23, 0, 0, 0, 0, 0, 0, 0, 58, 40, 40, 40, 40, 40, 0, 36, 37, 38, 82, 83, 84, 36, 38, 40, 40, 40, 40, 40, 40, 57,
	37, 38, 43, 0, 0, 58, 40, 16, 59, 48, 0, 0, 0, 33, 34, 37, 38, 0, 0, 0, 39, 0, 0, 58, 40, 0, 0, 0, 0, 0, 0, 40, 40,
	56, 40, 40, 40, 57, 0, 0, 0, 88, 104, 40, 56, 40, 0, 0, 34, 35, 56, 48, 40, 23, 40, 39, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 40, 36, 37, 37, 37, 37, 72, 37, 51, 41, 0, 0, 49, 50, 50, 50, 37, 50, 50, 50, 50, 50, 37, 50,
	0, 0, 0, 0, 0, 0, 0, 0, 59, 32, 0, 0, 49, 50, 50, 37, 37, 38, 0, 42, 40, 56, 36, 37, 37, 50, 50, 50, 50, 50, 50, 50,
	0, 0, 0, 0, 0, 0, 0, 42, 16, 40, 41, 0, 49, 50, 50, 37, 99, 99, 99, 100, 82, 83, 83, 83, 84, 85, 0, 0, 0, 85, 82, 83,
	37, 72, 37, 37, 38, 43, 0, 0, 0, 0, 0, 0, 36, 37, 37, 37, 38, 40, 40, 40, 36, 37, 72, 37, 37, 37, 72, 37, 37, 37, 37,
	37,
	0, 0, 0, 0, 0, 0, 88, 104, 40, 36, 72, 37, 37, 37, 37, 37, 27, 0, 22, 0, 27, 27, 27, 27, 48, 27, 27, 27, 27, 27, 48,
	27, 0, 0, 0, 0, 0, 0, 0, 17, 17, 32, 0, 0, 0, 42, 40, 36, 37, 51, 0, 0, 0, 42, 49, 50, 51, 0, 0, 41, 0, 0, 56, 41, 0,
	0, 0, 0, 0, 0, 17, 0, 0, 42, 0, 0, 0, 42, 40, 49, 0, 0, 0, 0, 98, 99, 99, 99, 100, 85, 0, 0, 0, 85, 82, 83, 37, 37,
	37, 72, 38, 43, 58, 0, 0, 0, 0, 0, 36, 37, 72, 37, 38, 40, 56, 40, 49, 50, 50, 50, 50, 50, 50, 50, 37, 37, 72, 37,
	0, 0, 0, 0, 0, 0, 42, 16, 40, 49, 50, 37, 37, 72, 37, 37, 0, 0, 0, 0, 0, 0, 0, 0, 55, 0, 0, 0, 0, 0, 55, 0, 0, 0, 0,
	0, 0, 0, 59, 52, 53, 54, 0, 20, 0, 0, 16, 49, 38, 43, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 42, 0, 0, 0, 0, 0, 0, 59,
	32, 43, 0, 18, 0, 0, 0, 0, 42, 40, 0, 0, 0, 0, 0, 0, 0, 0, 0, 101, 0, 0, 0, 85, 98, 99, 37, 37, 37, 50, 51, 43, 40,
	41, 0, 17, 17, 32, 36, 37, 37, 37, 38, 16, 41, 0, 40, 41, 0, 0, 0, 0, 42, 40, 49, 37, 37, 37,
	0, 0, 0, 0, 0, 0, 0, 0, 42, 40, 40, 36, 37, 37, 37, 72, 0, 0, 0, 0, 0, 0, 0, 0, 27, 0, 0, 0, 0, 0, 27, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 59, 52, 53, 54, 57, 0, 0, 27, 38, 114, 115, 115, 115, 115, 115, 115, 115, 115, 115, 116, 17, 0, 0, 22, 0,
	0, 0, 17, 0, 0, 27, 0, 59, 32, 43, 0, 0, 0, 22, 40, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 101, 0, 0, 37, 37, 51, 40,
	40, 40, 40, 16, 58, 33, 34, 34, 37, 37, 37, 37, 38, 40, 0, 0, 42, 0, 17, 17, 17, 0, 0, 40, 56, 36, 37, 37,
	0, 0, 0, 0, 0, 0, 0, 57, 58, 40, 40, 36, 37, 37, 37, 37, 0, 0, 22, 0, 0, 17, 0, 0, 0, 0, 0, 17, 0, 0, 0, 0, 17, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 32, 16, 40, 0, 17, 37, 34, 34, 34, 34, 34, 34, 34, 34, 34, 34, 34, 35, 43, 0, 0, 0, 0, 59,
	32, 43, 0, 0, 0, 0, 27, 0, 0, 0, 0, 0, 42, 0, 0, 0, 0, 0, 0, 0, 0, 57, 0, 0, 0, 0, 0, 0, 0, 72, 38, 40, 40, 40, 56,
	40, 40, 40, 49, 50, 50, 37, 72, 37, 37, 38, 41, 0, 0, 0, 17, 66, 67, 68, 0, 0, 42, 40, 36, 37, 72,
	0, 0, 0, 0, 0, 0, 0, 42, 40, 56, 40, 36, 72, 37, 37, 37, 0, 0, 0, 0, 59, 32, 43, 57, 22, 0, 59, 32, 43, 0, 22, 0, 39,
	57, 58, 0, 0, 0, 0, 0, 0, 0, 0, 27, 42, 40, 57, 33, 37, 72, 37, 37, 37, 37, 37, 50, 50, 50, 50, 50, 38, 43, 0, 0, 0,
	0, 0, 27, 0, 0, 0, 17, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 57, 0, 0, 104, 40, 0, 0, 58, 0, 0, 0, 0, 37, 38, 40, 40,
	16, 42, 0, 42, 40, 40, 41, 0, 49, 50, 50, 50, 38, 17, 17, 17, 17, 66, 83, 83, 84, 0, 0, 59, 33, 37, 37, 37,
	0, 0, 0, 0, 0, 0, 0, 0, 40, 40, 40, 49, 50, 50, 50, 50, 40, 0, 0, 58, 0, 27, 58, 40, 57, 0, 0, 27, 0, 0, 0, 0, 55,
	40, 56, 57, 17, 0, 0, 0, 0, 0, 0, 17, 58, 40, 40, 49, 50, 50, 50, 50, 37, 72, 38, 40, 41, 0, 42, 16, 55, 43, 0, 22,
	0, 0, 0, 0, 0, 0, 59, 32, 43, 0, 0, 22, 0, 0, 0, 0, 0, 0, 58, 88, 40, 40, 104, 40, 40, 40, 40, 40, 57, 0, 0, 0, 37,
	38, 56, 40, 41, 0, 0, 0, 0, 42, 0, 0, 0, 0, 0, 0, 37, 34, 34, 34, 35, 98, 99, 99, 100, 0, 0, 59, 36, 37, 37, 37,
	0, 0, 0, 17, 17, 17, 17, 58, 40, 40, 16, 27, 27, 27, 27, 27, 40, 57, 40, 40, 57, 0, 40, 40, 0, 0, 0, 0, 0, 0, 0, 0,
	27, 0, 42, 40, 39, 17, 0, 0, 0, 0, 59, 39, 40, 40, 56, 27, 34, 34, 34, 35, 49, 50, 51, 22, 0, 0, 104, 41, 0, 0, 0, 0,
	0, 1, 0, 0, 0, 0, 0, 27, 0, 0, 0, 0, 0, 0, 0, 0, 104, 57, 40, 40, 40, 40, 16, 41, 0, 0, 42, 16, 40, 58, 103, 104, 37,
	38, 40, 40, 57, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 37, 37, 72, 37, 37, 35, 40, 56, 41, 0, 0, 59, 36, 72, 37, 37,
	0, 0, 104, 33, 34, 34, 35, 40, 56, 40, 40, 57, 0, 0, 0, 0, 40, 40, 40, 40, 40, 56, 40, 41, 0, 0, 0, 0, 0, 0, 22, 0,
	17, 0, 58, 40, 55, 39, 0, 0, 0, 0, 59, 55, 42, 40, 41, 17, 37, 37, 72, 38, 56, 40, 42, 0, 0, 0, 42, 0, 0, 0, 0, 0, 0,
	32, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 0, 22, 40, 40, 40, 42, 56, 40, 40, 0, 0, 0, 0, 0, 40, 40, 40, 40,
	37, 38, 40, 41, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 37, 37, 37, 37, 37, 38, 16, 42, 0, 0, 0, 59, 36, 37, 37, 37,
	0, 0, 16, 49, 50, 37, 37, 34, 53, 53, 53, 54, 0, 0, 0, 0, 40, 56, 0, 42, 40, 40, 40, 16, 57, 57, 0, 0, 17, 0, 0, 0,
	39, 40, 40, 41, 27, 48, 57, 0, 0, 0, 0, 27, 0, 42, 40, 33, 37, 50, 37, 38, 41, 0, 0, 0, 0, 0, 0, 58, 0, 0, 0, 0, 0,
	52, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 54, 43, 0, 40, 40, 41, 0, 40, 40, 41, 0, 96, 97, 0, 58, 40, 56, 40,
	42, 72, 38, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 37, 72, 37, 37, 37, 38, 41, 0, 0, 17, 17, 17, 36, 37, 37, 37,
	0, 0, 42, 40, 40, 49, 50, 38, 27, 27, 27, 27, 0, 0, 0, 0, 41, 0, 0, 0, 0, 42, 40, 40, 40, 40, 57, 59, 39, 43, 0, 0,
	55, 40, 16, 0, 17, 48, 40, 58, 0, 0, 0, 17, 0, 40, 40, 49, 38, 1, 49, 51, 22, 0, 0, 0, 0, 0, 0, 40, 57, 0, 0, 0, 0,
	32, 40, 56, 40, 40, 40, 32, 40, 40, 40, 40, 40, 39, 43, 0, 56, 40, 0, 0, 42, 40, 61, 0, 112, 113, 63, 40, 40, 41, 0,
	0, 37, 38, 0, 0, 0, 0, 0, 0, 57, 0, 0, 0, 0, 0, 0, 0, 37, 37, 37, 37, 72, 38, 0, 0, 59, 33, 34, 35, 49, 37, 72, 37,
	0, 0, 0, 40, 56, 41, 59, 48, 0, 0, 0, 0, 0, 18, 0, 0, 0, 0, 0, 0, 0, 0, 0, 40, 40, 40, 40, 59, 48, 43, 0, 0, 27, 42,
	40, 56, 39, 48, 40, 16, 57, 0, 0, 39, 58, 40, 41, 27, 38, 23, 0, 0, 0, 0, 0, 0, 57, 0, 0, 56, 40, 0, 0, 0, 0, 27, 42,
	40, 40, 16, 40, 27, 42, 40, 56, 42, 40, 55, 43, 0, 40, 40, 57, 0, 0, 40, 33, 34, 35, 33, 34, 35, 40, 0, 0, 58, 50,
	51, 0, 0, 0, 0, 0, 0, 40, 41, 0, 0, 0, 0, 0, 0, 50, 50, 50, 50, 50, 51, 0, 0, 59, 36, 37, 37, 35, 49, 37, 37,
	0, 0, 0, 42, 40, 0, 59, 55, 0, 0, 0, 0, 58, 39, 0, 0, 0, 1, 0, 0, 0, 17, 17, 17, 17, 40, 56, 59, 55, 43, 0, 58, 0, 0,
	40, 40, 55, 48, 41, 0, 40, 56, 0, 55, 40, 56, 0, 17, 38, 57, 0, 0, 0, 0, 0, 0, 40, 0, 0, 40, 40, 41, 0, 0, 0, 0, 0,
	41, 22, 42, 40, 0, 0, 40, 22, 0, 40, 40, 0, 0, 16, 41, 0, 0, 0, 32, 49, 50, 51, 36, 72, 38, 40, 66, 67, 67, 0, 0, 0,
	0, 0, 0, 0, 0, 40, 0, 0, 88, 104, 0, 0, 0, 56, 40, 40, 41, 0, 0, 0, 0, 59, 36, 37, 72, 37, 35, 49, 50,
	0, 0, 1, 0, 40, 0, 0, 40, 0, 0, 0, 42, 40, 48, 0, 0, 34, 34, 35, 17, 17, 33, 53, 53, 54, 16, 40, 40, 41, 0, 0, 56, 0,
	0, 41, 0, 27, 48, 0, 0, 42, 40, 0, 0, 40, 40, 0, 33, 38, 40, 41, 0, 0, 0, 0, 58, 40, 41, 0, 40, 40, 0, 0, 0, 0, 88,
	104, 0, 0, 40, 40, 58, 40, 40, 57, 0, 40, 41, 22, 0, 40, 0, 1, 0, 0, 33, 34, 34, 34, 37, 37, 37, 35, 82, 83, 83, 0,
	0, 0, 63, 1, 0, 0, 58, 40, 0, 0, 42, 16, 0, 0, 0, 40, 41, 0, 0, 0, 0, 57, 0, 59, 36, 37, 37, 37, 37, 34, 34,
	64, 0, 33, 34, 35, 43, 0, 56, 57, 18, 0, 104, 56, 48, 57, 0, 37, 72, 37, 34, 34, 38, 12, 0, 42, 40, 40, 40, 0, 0, 58,
	40, 1, 0, 0, 0, 58, 55, 8, 0, 0, 40, 57, 0, 40, 41, 0, 49, 38, 40, 0, 0, 0, 0, 0, 40, 56, 0, 58, 40, 16, 0, 0, 0, 0,
	42, 40, 40, 40, 41, 42, 40, 40, 56, 40, 40, 40, 0, 0, 0, 67, 67, 67, 67, 68, 36, 37, 72, 37, 37, 37, 37, 38, 82, 83,
	83, 0, 0, 0, 33, 54, 0, 0, 56, 40, 57, 0, 0, 40, 0, 28, 0, 40, 1, 61, 62, 0, 58, 40, 0, 59, 36, 37, 37, 37, 72, 37,
	37,
	33, 35, 36, 37, 38, 43, 104, 40, 40, 39, 40, 40, 16, 48, 40, 0, 37, 37, 37, 37, 72, 38, 0, 0, 0, 40, 40, 41, 0, 0,
	40, 40, 35, 0, 0, 0, 56, 40, 57, 0, 0, 42, 40, 16, 40, 0, 0, 27, 38, 56, 57, 0, 0, 0, 0, 40, 40, 0, 40, 40, 40, 57,
	0, 0, 0, 0, 0, 56, 40, 0, 0, 0, 42, 40, 16, 40, 0, 0, 0, 0, 83, 83, 83, 83, 84, 36, 37, 37, 37, 37, 37, 72, 38, 82,
	83, 83, 0, 0, 0, 48, 66, 68, 0, 40, 40, 40, 0, 0, 40, 57, 0, 0, 34, 34, 34, 35, 16, 40, 56, 57, 59, 36, 37, 37, 37,
	37, 37, 37,
	37, 37, 37, 37, 37, 38, 43, 27, 27, 27, 49, 50, 50, 37, 38, 0, 72, 37, 50, 50, 50, 50, 50, 50, 37, 37, 50, 50, 50,
	51, 40, 40, 37, 37, 37, 37, 37, 37, 37, 37, 37, 37, 72, 37, 50, 51, 43, 40, 50, 50, 50, 50, 50, 37, 38, 40, 40, 0, 0,
	59, 36, 37, 37, 37, 37, 72, 37, 37, 37, 37, 37, 72, 72, 37, 37, 37, 38, 56, 40, 36, 37, 72, 37, 37, 50, 51, 40, 40,
	41, 36, 37, 50, 50, 50, 37, 37, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0,
	37, 37, 37, 72, 37, 38, 43, 0, 0, 0, 27, 27, 27, 36, 38, 0, 50, 51, 40, 103, 0, 0, 0, 40, 36, 51, 43, 42, 40, 16, 40,
	56, 37, 37, 37, 72, 37, 37, 50, 50, 50, 50, 37, 38, 27, 27, 0, 56, 41, 1, 0, 58, 40, 36, 38, 56, 41, 0, 0, 59, 36,
	50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 37, 38, 16, 40, 49, 37, 37, 50, 51, 27, 27, 16, 40, 20, 49,
	51, 56, 40, 40, 36, 72, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0,
	37, 37, 37, 37, 37, 38, 43, 0, 0, 0, 0, 0, 42, 36, 38, 103, 40, 40, 56, 41, 0, 0, 17, 42, 55, 43, 0, 58, 40, 39, 41,
	0, 37, 37, 37, 37, 37, 51, 27, 27, 27, 27, 49, 51, 0, 0, 0, 40, 53, 53, 53, 54, 40, 36, 38, 40, 20, 0, 0, 59, 48, 40,
	42, 42, 26, 40, 41, 0, 42, 40, 56, 40, 40, 16, 40, 36, 38, 0, 42, 56, 37, 38, 27, 27, 0, 0, 56, 33, 35, 43, 0, 0, 8,
	16, 36, 37, 0, 0, 0, 0, 0, 0, 58, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	37, 72, 37, 50, 50, 51, 43, 0, 0, 0, 17, 0, 40, 36, 38, 41, 40, 16, 42, 0, 0, 59, 39, 0, 41, 0, 0, 0, 56, 48, 0, 0,
	50, 50, 37, 37, 38, 43, 0, 0, 0, 0, 59, 39, 0, 0, 58, 40, 40, 40, 56, 40, 40, 36, 37, 34, 35, 43, 0, 59, 55, 41, 8,
	0, 0, 16, 0, 17, 0, 41, 42, 40, 41, 17, 42, 49, 51, 0, 58, 40, 37, 38, 43, 0, 0, 0, 42, 49, 51, 43, 0, 0, 104, 40,
	36, 37, 0, 0, 0, 0, 0, 0, 16, 0, 0, 57, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	37, 37, 38, 33, 34, 35, 43, 0, 58, 103, 39, 43, 42, 36, 38, 56, 40, 41, 0, 0, 0, 59, 48, 0, 0, 0, 0, 58, 40, 48, 0,
	0, 34, 35, 49, 50, 51, 43, 0, 0, 0, 0, 59, 48, 40, 57, 0, 42, 56, 40, 41, 16, 41, 36, 72, 37, 38, 43, 0, 0, 0, 0, 0,
	0, 0, 42, 59, 32, 43, 58, 22, 40, 59, 32, 43, 0, 17, 0, 0, 40, 37, 38, 43, 0, 0, 0, 0, 27, 27, 0, 0, 42, 56, 42, 36,
	37, 0, 0, 0, 0, 58, 0, 40, 0, 0, 56, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 73, 74, 75, 76, 77, 78, 79, 0, 0, 0, 0,
	37, 37, 38, 36, 72, 38, 43, 0, 42, 56, 48, 43, 18, 36, 38, 41, 56, 0, 0, 0, 0, 59, 48, 0, 0, 0, 0, 0, 42, 48, 62, 20,
	37, 37, 34, 34, 35, 43, 0, 0, 0, 0, 59, 48, 41, 0, 0, 0, 40, 41, 0, 0, 0, 36, 37, 37, 38, 43, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 27, 0, 42, 40, 40, 0, 27, 0, 59, 32, 43, 17, 42, 37, 38, 43, 0, 0, 0, 0, 0, 0, 0, 0, 0, 41, 59, 36, 72, 0, 0, 0,
	0, 40, 103, 40, 0, 0, 16, 0, 57, 0, 0, 0, 0, 0, 0, 0, 0, 0, 89, 90, 91, 92, 93, 94, 95, 0, 0, 0, 0,
	50, 50, 51, 49, 50, 38, 43, 18, 0, 40, 48, 43, 23, 49, 51, 0, 40, 57, 88, 104, 57, 59, 48, 17, 17, 17, 17, 17, 17,
	36, 34, 34, 37, 37, 72, 37, 38, 43, 0, 0, 17, 0, 59, 48, 43, 0, 0, 0, 40, 17, 17, 17, 17, 36, 37, 72, 38, 43, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 17, 16, 103, 88, 17, 0, 27, 59, 32, 22, 72, 38, 17, 17, 17, 17, 0, 0, 0, 22, 0, 0, 0,
	59, 49, 37, 0, 0, 0, 0, 40, 56, 40, 118, 0, 40, 103, 40, 0, 0, 0, 0, 0, 0, 0, 0, 0, 105, 106, 107, 108, 109, 110,
	111, 0, 0, 0, 0,
	40, 0, 0, 0, 42, 48, 17, 39, 0, 42, 48, 43, 0, 16, 16, 57, 40, 40, 56, 40, 52, 53, 50, 53, 53, 53, 53, 53, 53, 37,
	37, 72, 37, 37, 37, 37, 38, 43, 0, 59, 39, 0, 59, 48, 43, 0, 0, 0, 40, 52, 53, 53, 53, 50, 50, 37, 38, 43, 0, 0, 17,
	0, 0, 0, 0, 0, 0, 0, 0, 59, 32, 40, 40, 56, 39, 43, 22, 0, 27, 0, 37, 37, 35, 33, 34, 35, 43, 0, 0, 0, 0, 0, 0, 0,
	27, 36, 0, 0, 0, 0, 42, 40, 40, 33, 35, 40, 56, 41, 0, 0, 0, 0, 0, 0, 0, 0, 0, 121, 122, 123, 124, 125, 126, 127, 0,
	0, 0, 0,
	41, 0, 17, 0, 0, 49, 53, 38, 43, 0, 49, 53, 53, 53, 53, 53, 41, 0, 42, 0, 0, 16, 40, 40, 40, 40, 41, 0, 59, 36, 37,
	37, 50, 50, 50, 50, 38, 43, 22, 59, 48, 0, 59, 48, 0, 0, 0, 0, 41, 27, 27, 27, 27, 27, 59, 36, 38, 43, 0, 59, 39, 43,
	0, 0, 0, 17, 0, 0, 0, 0, 27, 42, 40, 40, 55, 43, 0, 0, 0, 0, 50, 50, 51, 49, 50, 51, 43, 0, 0, 17, 17, 0, 0, 0, 59,
	36, 0, 0, 0, 104, 56, 40, 33, 37, 37, 35, 40, 57, 58, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 59, 39, 43, 0, 42, 56, 48, 43, 0, 0, 0, 42, 40, 57, 59, 0, 0, 0, 0, 0, 0, 42, 40, 56, 40, 40, 103, 33, 37, 37, 37,
	27, 27, 27, 27, 55, 43, 0, 59, 48, 57, 59, 48, 22, 0, 0, 0, 0, 0, 0, 0, 0, 0, 59, 36, 38, 43, 23, 59, 48, 43, 0, 0,
	59, 32, 43, 17, 0, 0, 0, 17, 0, 41, 27, 0, 0, 0, 0, 58, 27, 27, 27, 27, 27, 27, 0, 17, 17, 33, 35, 17, 0, 0, 59, 36,
	0, 0, 0, 42, 40, 33, 37, 72, 37, 37, 35, 40, 56, 104, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	8, 59, 48, 43, 0, 0, 40, 48, 17, 17, 17, 17, 0, 40, 56, 59, 17, 17, 17, 17, 17, 0, 0, 40, 41, 0, 41, 40, 36, 37, 72,
	37, 0, 0, 0, 58, 40, 0, 0, 59, 48, 40, 59, 55, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 59, 36, 38, 17, 17, 17, 48, 43, 0, 0, 0,
	27, 59, 32, 43, 0, 59, 39, 43, 0, 0, 0, 0, 0, 0, 40, 43, 1, 0, 0, 0, 0, 59, 33, 34, 37, 50, 54, 43, 0, 59, 49, 88,
	88, 104, 40, 41, 36, 37, 37, 37, 37, 38, 16, 40, 40, 104, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 59, 55, 43, 0, 0, 42, 49, 53, 53, 53, 54, 0, 40, 41, 59, 34, 34, 34, 34, 35, 17, 17, 32, 43, 0, 0, 42, 49, 50, 37,
	37, 0, 0, 0, 16, 56, 41, 0, 59, 48, 40, 40, 40, 0, 0, 0, 0, 17, 17, 17, 17, 57, 0, 17, 36, 37, 34, 34, 34, 51, 43, 0,
	0, 1, 0, 0, 27, 0, 0, 59, 48, 43, 0, 0, 0, 0, 88, 104, 40, 43, 23, 0, 0, 0, 0, 59, 36, 37, 51, 27, 27, 0, 0, 0, 27,
	40, 16, 40, 56, 0, 49, 50, 37, 37, 72, 38, 41, 0, 42, 40, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	57, 0, 27, 0, 0, 0, 0, 27, 27, 27, 27, 27, 0, 42, 0, 59, 50, 50, 50, 50, 50, 53, 54, 27, 0, 0, 0, 0, 27, 27, 49, 37,
	0, 0, 0, 0, 40, 0, 0, 59, 48, 40, 56, 41, 0, 0, 0, 0, 34, 34, 34, 35, 40, 56, 52, 50, 50, 50, 50, 51, 43, 0, 0, 0,
	35, 57, 0, 0, 0, 0, 59, 55, 43, 0, 0, 0, 0, 42, 16, 40, 17, 17, 17, 17, 0, 0, 59, 49, 51, 27, 0, 58, 0, 22, 0, 0, 0,
	42, 40, 57, 63, 33, 35, 36, 37, 50, 51, 32, 0, 0, 40, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	40, 41, 0, 0, 1, 0, 20, 0, 0, 0, 0, 0, 0, 0, 0, 59, 57, 1, 61, 0, 0, 42, 40, 0, 0, 0, 0, 0, 0, 0, 40, 36, 0, 0, 0,
	104, 40, 103, 0, 59, 48, 0, 42, 40, 103, 0, 0, 0, 37, 37, 37, 38, 0, 40, 40, 0, 58, 16, 40, 42, 0, 22, 0, 58, 38, 40,
	0, 0, 0, 0, 0, 27, 0, 0, 0, 57, 58, 40, 56, 40, 34, 34, 34, 35, 43, 0, 0, 27, 27, 0, 0, 56, 0, 0, 0, 104, 0, 0, 33,
	34, 34, 37, 38, 49, 51, 33, 34, 35, 40, 57, 40, 103, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	16, 103, 88, 58, 33, 34, 35, 17, 17, 17, 17, 17, 0, 18, 0, 59, 34, 34, 35, 57, 0, 16, 40, 57, 0, 0, 0, 0, 8, 58, 16,
	49, 1, 0, 58, 56, 40, 41, 0, 59, 55, 0, 0, 56, 41, 0, 0, 0, 37, 72, 37, 38, 0, 42, 40, 40, 40, 56, 41, 0, 0, 0, 0,
	40, 38, 56, 57, 18, 0, 0, 0, 0, 0, 0, 58, 40, 40, 40, 40, 16, 37, 72, 37, 38, 43, 22, 0, 0, 57, 0, 0, 40, 58, 0, 58,
	40, 1, 0, 49, 37, 37, 72, 37, 34, 34, 37, 37, 37, 35, 16, 56, 40, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	40, 56, 40, 40, 36, 37, 37, 34, 34, 34, 34, 35, 0, 23, 0, 59, 37, 37, 38, 40, 58, 40, 56, 40, 0, 0, 0, 0, 0, 56, 40,
	40, 35, 0, 16, 40, 40, 0, 0, 0, 56, 0, 0, 40, 16, 0, 0, 0, 37, 37, 37, 38, 23, 23, 40, 56, 40, 0, 0, 0, 0, 0, 58, 40,
	38, 40, 16, 39, 57, 0, 0, 0, 0, 42, 40, 40, 56, 40, 40, 40, 37, 37, 72, 38, 43, 0, 0, 58, 56, 0, 58, 40, 16, 40, 56,
	40, 33, 34, 35, 36, 37, 37, 37, 37, 37, 37, 72, 37, 37, 34, 34, 35, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
}

SPRITE_FLAGS = {
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	4, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0,
	3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 2, 2, 0, 0, 0,
	3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 2, 2, 2, 2, 2,
	0, 0, 19, 19, 19, 19, 2, 2, 3, 2, 2, 2, 2, 2, 0, 2,
	0, 0, 19, 19, 19, 19, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2,
	0, 0, 19, 19, 19, 19, 0, 4, 4, 2, 2, 2, 2, 2, 2, 2,
	0, 0, 19, 19, 19, 19, 0, 0, 0, 2, 2, 2, 2, 2, 2, 2,
}

SFX = {
	"PAT 02 F#5370 B.3470 B.4370 F.3470 F#4370 B.2470 D#4370 G.2470 B.3370 F.2470 F#3370 D.2470 D.3360 C.2460 A#2350 G#1440 F#2330 F.1420",
	"PAT 02 F.2070 G.2070 D.3070 C.4070",
	"PAT 03 C#2070 E.2070 A#2070 A#3070",
	"PAT 02 F#1420 G#1420 A.1420 B.1420 A#3440 F#4450 C.6650 B.5650 B.5650 A.5650 F#5650 D.5650 A.4650 E.4650 C.4640 A.3640 F.3640 D.3640 A#2630 F.2630 D.2630 B.1620 G.1620 F.1610 D#1610",
	"PAT 04 D#2070 F#3070 F#2070 A#3070 B.2070 D.4070 D#3060 G#4060 A.3050 C#5050 D#4040 F#5040 G.4030 A#5030 C.5020 D.6020 F.5010",
	"PAT 03 A.1770 A.1770 A.1760 A.1750 G#1740 G.1730 F#1720 F.1715",
	"PAT 03 C.4170 D.2170 A.4170 A#2170 E.5170 G#3160 B.5160 E.4150 D#6140 B.4120 E.4110 F.3110 E.2110 D#1110",
	"PAT 02 E.2110 F#2110 G#2110 A#2110 D.3120 G#3120 D.4130 D.5140 D.5140",
	"PAT 03 G.1070 A#1070 D.2070 E.2070 A#2070 A#3070 B.4070 B.4060 G#4060 G#4050 B.4050 B.4040 G#4040 G#4030 B.4020 B.4010",
	"PAT 03 F.1110 G.1130 D#6640 D#6640 D#6630 D#6620 D#6610 D#6615",
	-- 10
	"PAT 16 C#3915 ...... C#3915 ...... D#3835 C#3915 ...... ...... C#3915 ...... ...... ...... D#3835 ...... C#3915 ...... C#3915 ...... C#3915 ...... D#3835 C#3915 ...... ...... C#3915 ...... ...... ...... D#3835 ...... C#3915 D#3835",
	"PAT 32 F.3040 F.3040 F.3030 F.3020 C.3040 C.3040 C.3030 C.3020 D#3030 D#3020 A#3040 A#3046 G.3035 G.3030 A#2040 A#2040 F.3040 F.3040 C.0001 G.2061 C.3030 C.3030 ...... G.3061 C.4050 A#3020 A#2040 G.2020 F.3040 D#3022 C.3040 C.3040",
	"PAT 16 G.1070 G.1060 G.1050 ...... G.1070 G.1060 D#1051 D#2070 A#1070 A#1060 A#1050 ...... A#1070 A#1060 F.1050 F.1040 D#1070 D#1060 ...... D#1050 D.2070 C.2060 F.2050 A#2070 A#2060 D#2071 F.1050 A#1070 F.1050 D#1051 A#1070 A#1060",
	"PAT 04 C.2550 E.3560 E.2570 B.3570 C#3570 G#4570 A.3570 G.5570 E.4570 B.5570 G#4570 D.6560 C#5550 D.6540 C#5530 D.6530 C#5520 D#6520 C#5520 D#6520 C#5510 D#6510 C#5510 D#6510 C#5510 D#6510 C#5510",
	"PAT 04 C.4740 G.4760 D.4770 F.3770 A.2770 A.2770 C#3770 E.3750 B.2730",
	"PAT 03 A.1645 D.2655 F#1655 A#1655 C#2655 F.1655 F.2655 G.1655 C.2655 E.1655 A.1655 F.2645 G#1635 C#2615",
	"PAT 16 G.3375 C.3375 D#4375",
	"PAT 16 F.4534 F.4534 F.4574 F.3540 A#3570 A#3560 C.3570 C.3570 C.3560 ...... C.3570 C.3560 ...... A#2570 A#2572 A#2562 D#4514 D#4534 D#4554 D#4574 G.3570 G.3560 ...... G.2520 D#3551 F.5530 C.5560 C.4540 F.4570 F.4560 A#3570 A#3560",
	"PAT 16 A#1070 A#1050 D#2071 D#2050 A#1060 A#1040 F.2070 F.2050 ...... ...... F.2070 F.2050 G.1060 G.1040 ...... ...... A#1070 A#1050 D#2070 D#2050 A#1060 A#1040 G.2071 G.2050 ...... ...... G.2070 G.2050 D#2070 D#2050 ...... ......",
	"PAT 32 A#3040 A#3030 A#3020 D#3011 C.4040 C.4030 D#4050 G.3020 G.4040 A#3020 D#4050 A#3020 F.4040 F.4030 F.4020 A#2010 A#3040 A#3030 G.4030 D#3030 C.4042 C.4032 D#4040 C.3030 F.3040 F.3030 G.3052 G.3042 G.3030 F.3021 F.3040 F.3030",
	-- 20
	"PAT 08 C#3915 C#3915 D#3835 ...... ...... ...... D#3835 ...... E.3840 ...... ...... ...... D#3835 ...... C#1775 ...... C#1770 C#1775 ...... ...... D#3835 ...... D#3835 ...... E.3840 ...... ...... ...... D#3835 ...... ...... ......",
	"PAT 32 A#1140 A#1130 A#1120 F.2130 F.2120 F.2110 D#3140 D#3130 C.3152 C.3142 C.3132 G.2140 G.2140 G.2130 G.2120 G.2110 D#2140 D#2130 D#2120 F.2130 F.2120 F.2110 A#2142 A#2132 G.2150 G.2140 G.2130 G.2120 G.2110 G.2110 G.2110 ......",
	"PAT 16 A#4750 G.5750 A#4730 G.5730 A#4720 G.5720 A#4710 G.5710 A#3750 G.4750 A#3730 G.4730 F.3750 C.4750 F.3730 C.4730 G.3750 D#4750 G.3730 D#4730 G.3720 D#4720 F.4750 C.5750 F.4730 C.5730 F.4720 C.5720 F.4710 C.5710 F.4710 C.5710",
	"PAT 06 C.3770 F.5770 F.5770 F.5760 F.5750 F.5740 F.5730 F.5720 F.5710",
	"PAT 24 F.4450 F.5710 F.4440 F.5710 F.4430 G.5710 F.4420 G.5710 A#3450 F.5710 A#3440 D#4450 C.6710 D#4440 C.6710 D#4420 A#4450 F.5710 A#4440 F.5710 A#4430 G.5710 A#4420 G.5710 A#4410 C.4440 G.4450 F.5710 F.4450 C.6710 F.4440 C.6710",
	"PAT 24 F.1570 F.1570 F.1570 F.1570 F.1570 ...... F.1570 G.1570 A#1570 A#1570 A#1570 ...... A#1570 ...... A#1570 D#1570 F.1570 F.1570 F.1570 ...... F.1570 F.1570 F.1570 ...... A#1570 G.1570 C.2570 C.2570 D#2570 ...... A#1570 G.1570",
	"PAT 12 B.2935 ...... B.2925 ...... B.2915 ...... ...... ...... D#3840 D#3830 D#3820 D#3810 D#3810 ...... D#2915 ......",
	"PAT 12 C.4450 C.5710 G.4450 C.5710 C.4440 ...... G.4440 ...... C.4420 A#5710 G.4420 A#5710 C.4410 F.5710 G.4410 F.5710 F.3450 D#5710 C.4450 C.6710 F.3440 G.5710 C.4440 ...... F.3420 ...... C.4420 A#4710 F.3410 A#4710 C.4410 ......",
	"PAT 24 C.2570 C.2560 C.2550 ...... F.2570 F.2560 F.2550 ...... C.2570 C.2560 D#2571 D#2560 G.2570 G.2560 A#1570 A#1560 C.2570 C.2560 C.2550 ...... D#2570 D#2560 D#2550 ...... A#1570 A#1560 A#1550 ...... F.2570 F.2560 A#1570 A#1560",
	"PAT 24 C.2570 C.2560 C.2550 ...... F.2570 F.2560 F.2550 ...... C.2570 C.2560 D#2571 D#2560 G.2570 G.2560 D#2570 D#2560 C.2570 C.2570 C.2560 C.2560 C.2550 C.2530 ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
	-- 30
	"PAT 12 C.4771 C.4770 C.4762 C.4752 A#5010 A#5010 C.3752 A#5010 F.5010 F.5010 C.3752 F.5010 C.3750 ...... ...... ...... A#3771 A#3772 A#3762 ...... G.3771 G.3772 G.3762 ...... A#3771 A#3772 A#3762 ...... D#4771 D#4772 D#4762 ......",
	"PAT 12 C.4771 C.4770 C.4762 C.4752 A#5010 A#5010 C.3750 A#5010 F.5010 F.5010 C.3750 F.5010 C.3750 ...... ...... ...... G.3771 G.3770 G.3762 G.3752 ...... ...... C.3751 ...... A#3771 A#3770 A#3762 A#3752 G.5012 G.5012 G.5012 ......",
	"PAT 12 C.4771 C.4770 C.4772 C.4772 C.4762 C.4752 C.4742 C.4732 C.4722 C.4712 ...... ...... ...... ...... ...... ...... ...... ...... A#4010 A#4010 F.5010 F.5010 D#5011 D#5010 G.4010 G.4010 G.4010 ...... C.5010 C.5012 C.5012 C.5012",
	"PAT 12 C.2332 C.2332 C.2322 C.2322 C.2312 C.2312 C.2312 ...... C.2332 C.2332 C.2322 C.2322 C.2312 C.2312 C.2312 ...... G.1332 G.1332 G.1322 G.1322 G.1312 G.1312 G.1312 ...... A#1332 A#1332 A#1322 A#1322 A#1312 A#1312 A#1312 ......",
	"PAT 12 C.2330 C.2330 C.2320 C.2320 C.2310 C.2310 C.2310 ...... C.2330 C.2330 C.2320 C.2320 C.2310 C.2310 C.2310 ...... A#1330 A#1320 G.2330 G.2320 G.1330 G.1320 G.1310 ...... A#1330 A#1320 A#1310 ...... D#2330 D#2320 D#2310 ......",
	"PAT 04 D#5625",
	"PAT 12 C.2330 C.2330 C.2330 C.2320 C.2320 C.2320 C.2310 C.2310 C.2310 C.2310 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... A#1331 A#1330 D#1321 D#1320",
	"PAT 16 C.2350 C.2340 C.2330 C.2320 D#2350 D#2340 D#2330 D#2320 C.3350 C.3340 G.2350 C.2340 C.3350 G.2350 A#2340 F.3360 A#3370 A#3370 A#3360 A#3350 A#3340 A#3320",
	"PAT 12 C.4275 G.4275 C.5275 C.4265 G.4265 C.5265 C.4255 G.4255 C.5255 C.4245 G.4245 C.5245 C.4235 G.4235 C.5235 C.4235 G.4225 C.5225 C.4215 G.4215 C.5215",
	"PAT 16 D#3835 C#1075 C#1075 D#3835 C#1075 D#3835 F.3855 C#1075 C#1075 D#3835 C#1075 D#3835 D.3855 D#3835 C#1075 D#3835",
	-- 40
	"PAT 16 A#2270 A#2270 G.3271 G.3270 G.3270 G.3270 C.3171 C.3270 G.2271 G.2270 F.3271 F.3270 A#2271 A#2270 A#2270 A#2270 D#3271 D#3270 D#3270 D#3270 ...... ...... ...... ......",
	"PAT 08 C.4575 C.5575 C.4545 C.5545 D#3565 D#4565 G.3575 G.4575 G.3545 G.4545 G.3535 G.4535 G.3525 G.4525 G.3515 G.4515 D#3575 D#4575 D#3545 D#4545 D#3535 D#4535 F.3575 F.4575 F.3545 F.4545 F.3535 F.4535 G.3575 G.4575 G.3545 G.4545",
	"PAT 32 C.2265 C.2265 C.2255 C.2255 C.2245 C.2245 C.2235 A#1231 D#2265 D#2265 D#2255 D#2255 D#2245 D#2245 D#2235 A#2231 G.2265 G.2265 G.2255 G.2255 G.2245 G.2245 G.2235 G.2235 G.2225 G.1240 A#2270 G.2261 G.2250 G.2242 D#2260 D#2250",
	"PAT 16 G.1275 G.1265 G.1255 G.1245 D#2265 D#2255 C.2275 C.2265 C.2255 C.2245 C.2235 C.2225 G.1275 G.1265 G.1255 G.1245 G.1275 G.1265 G.1255 G.1245 C.2265 C.2255 F.2275 F.2265 F.2255 F.2245 G.2265 G.2255 A#2275 A#2265 A#2255 A#2245",
	"PAT 08 G.2570 G.4570 G.3540 G.4540 C.3550 C.4550 D#3570 D#4570 D#3540 D#4540 C.3570 C.4570 C.3540 C.4540 C.3530 C.4530 D#3570 D#4570 D#3540 D#4540 F.3530 F.4530 F.3520 F.4520 G.3570 G.4570 G.3540 G.4540 G.3530 G.4530 D#3550 D#4550",
	"PAT 16 F.2275 F.2265 F.2255 F.2245 G.2265 G.2255 C.3275 C.3265 C.3255 C.3245 F.3265 F.3255 D#2265 C.3245 G.2275 A#2255 D#2275 D#2265 D#2255 D#2245 F.2265 F.2255 A#2275 A#2265 A#2255 A#2245 D#3265 D#3255 A#3275 G.3245 C.3265 G.2235",
	"PAT 16 C#1075 D.3855 C#1075 D#3835 D.3855 D#3835 C#1075 D#3835 C#1075 D#3835 D.3855 C#1075 D.3855 D#3835 C#1075 D#3835",
	"PAT 16 C#1075 C#1075 C#1075 D#3835 D.3855 D#3835 D#3835 C#1075 C#1075 D#3835 C#1075 D#3835 D.3855 D#3835 D.3855 D#3835",
	"PAT 32 F.4040 F.4040 F.4030 G.4031 F.4024 G.4021 F.4014 G.4011 D#5044 C.5041 A#4044 A#4020 C.5044 C.5030 G.4041 G.4030 A#4044 A#4040 A#4030 C.5031 A#4024 C.5021 A#4024 C.5021 G.4044 A#4041 G.4034 A#4021 G.4044 G.4040 F.4031 F.4022",
	"PAT 08 C.4515 C.4515 C.4525 C.4525 C.4535 C.4535 C.4545 C.4545 C.4555 C.4555 C.4565 C.4565 C.4575 ...... C.4575 ...... C.4565 ...... C.4565 ...... C.4555 ...... C.4555 ...... C.4545 ...... C.4535 ...... C.4525 ...... C.4515 ......",
	-- 50
	"PAT 08 G.3515 G.3515 G.3525 G.3525 G.3535 G.3535 G.3545 G.3545 G.3555 G.3555 G.3565 G.3565 G.3575 ...... G.3575 ...... G.3565 ...... G.3565 ...... G.3555 ...... G.3555 ...... G.3545 ...... G.3535 ...... G.3525 ...... G.3515 ......",
	"PAT 05 D#1730 F.1731 G.1741 C.2741 G.2751 D#3761 C.4370 C.5371 D#4570 A#4571 C.4370 C.5371 D#4570 A#4571 C.4360 C.5361 D#4560 A#4561 C.4350 C.5351 D#4550 A#4551 C.4340 C.5341 D#4540 A#4541 C.4330 C.5331 D#4520 A#4521 C.4310 C.5311",
	"PAT 32 C.2275 C.2265 C.2255 C.2245 C.2235 A#1265 A#1255 A#1245 D#2275 D#2265 D#2255 D#2245 D#2235 C.2265 C.2255 C.2245 C.2275 C.2265 C.2255 C.2245 C.2235 A#1265 A#1255 A#1245 D#2275 D#2265 D#2255 D#2245 D#2235 F.2265 F.2255 F.2245",
	"PAT 32 G.2275 G.2265 G.2255 G.2245 G.2235 F.2265 F.2255 F.2245 A#2275 A#2265 A#2255 A#2245 A#2235 G.2265 G.2255 G.2245 G.2275 G.2265 G.2255 G.2245 G.2235 D#2265 D#2255 D#2245 C.2250 F.2231 A#2265 D#2245 A#2272 A#2252 C.2270 C.2255",
	"PAT 03 G.3330 G.4330 A#3530 F.4530 G.3320 G.4320 A#3520 F.4520 G.3310 G.4310 A#3510 F.4510",
	"PAT 11 F.4355  F.4345 C.5370 C.5360 C.5355",
	"PAT 16 C.6575 C.6545 C.6535 C.6525 C.6515 C.6515 G.5555 G.5545 A#5575 A#5555 A#5545 A#5535 A#5525 A#5525 A#5515 A#5515 F.5575 F.5555 F.5545 F.5545 F.5535 F.5535 F.5525 F.5525 F.5515 F.5515 D#5575 D#5555 D#5545 D#5535 D#5525 D#5515",
	"PAT 16 F.5575 F.5555 F.5545 F.5535 F.5525 F.5525 F.5515 F.5515 G.5555 G.5535 D#5575 D#5555 D#5545 D#5535 D#5525 D#5525 A#5575 A#5545 A#5535 A#5525 A#5515 A#5515 D#5575 D#5555 D#5545 D#5545 D#5535 D#5535 D#5525 D#5525 D#5515 D#5515",
	"PAT 16 C.2060 C.2030 C.2050 C.2030 C.2050 C.2030 C.2010 ...... C.2060 C.2030 C.2050 C.2030 C.2050 C.2030 C.2010 ...... F.2060 F.2030 F.2050 F.2030 F.2010 ...... A#1060 A#1030 A#1050 A#1030 A#1050 A#1030 A#1050 A#1030 A#1010",
	"PAT 16 F.1060 F.1030 F.1050 F.1030 F.1010 ...... G.1060 G.1030 G.1050 G.1030 G.1010 ...... D#2060 D#2030 D#2010 ...... C.2060 C.2030 C.2050 C.2030 C.2050 C.2030 C.2050 C.2030 C.2050 C.2030 C.2010 ...... C.2060 C.2030 C.2010",
	-- 60
	"PAT 16 D#3820 D#3810 ...... D#3810 D#3820 D#3810 D#3820 D#3810 ...... D#3810 D#3820 D#3810 D#3820 ...... D#3820 D#3810 D#3820 D#3810 D#3820 D#3810 ...... D#3810 D#3820 D#3810 D#3820 D#3810 D#3820 D#3810 ...... D#3810 D#3820 D#3820",
	"PAT 16 D.5611 D.5611 D.5611 D.5611 C#5611 C#5611 C.5611 A#4611 F#4611 C#4611 D#3611 G.2611 D#2611 C#2611 C.2611 C.2611 C.2611 C.2611 C.2611 D#2611 G#2611 F.3611 C.4611 F#4611 A#4611 C.5611 C#5611 D#5611 D#5611 E.5611 E.5611 E.5610",
	"PAT 64 C.5245 ...... C.5235 D#5225 G.4235 ...... C.5225 ...... ...... C.5225 ...... ...... C.5215 ...... ...... C.5215 G.4245 ...... G.4235 D#4225 F.4235 ...... G.4225 ...... ...... G.4225 ...... ...... G.4215 ...... ...... G.4215",
	""
}

MUSIC_FIRST_LEVELS = [[NAM first levels
PATLIST 10 11 12 17 18 19 20 21 22
SEQ 07.... 082... 082... 012... 456... 082... 082... 034...]]

MUSIC_TITLE = [[NAM title screen
PATLIST 56 57 58 59 60
SEQ 024... 134...]]

MUSIC_WIND = [[NAM windy theme
PATLIST 61 62
SEQ 0..... 0..... 0..... 01....]]

MUSIC_SECOND_PART = [[NAM second part
PATLIST 39 41 42 43 44 45 46 47 48 49 50 52 53
SEQ 012... 012... 317... 347... 317... 347... 568... 09B... 0AC...]]

MUSIC_LAST_PART = [[NAM last part
PATLIST 24 25 26 27 28 29 30 31 32 33 34 36
SEQ 012... 012... 342... 352... 792... 792... 6A2... 8B2...]]

INST_TRIANGLE = "INST OVERTONE 1.0 TRIANGLE 1.0 METALIZER 0.85 NAM triangle"
INST_TILTED = "INST OVERTONE 1.0 TRIANGLE 0.5 SAW 0.1 NAM tilted"
INST_SAW = "INST OVERTONE 1.0 SAW 1.0 ULTRASAW 1.0 NAM saw"
INST_SQUARE = "INST OVERTONE 1.0 SQUARE 0.5 NAM square"
INST_PULSE = "INST OVERTONE 1.0 SQUARE 0.5 PULSE 0.5 TRIANGLE 1.0 METALIZER 1.0 OVERTONE_RATIO 0.5 NAM pulse"
INST_ORGAN = "INST OVERTONE 0.5 TRIANGLE 0.75 NAM organ"
INST_NOISE = "INST NOISE 1.0 NOISE_COLOR 0.2 NAM noise"
INST_PHASER = "INST OVERTONE 0.5 METALIZER 1.0 TRIANGLE 0.7 NAM phaser"
INST_SNARE = "SAMPLE ID 01 FILE celeste/11_ZN.wav FREQ 17000"
INST_KICK = "SAMPLE ID 02 FILE celeste/10_HALLBD1.wav FREQ 15000"

--SPRITES="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAgAAAAEACAIAAABK8lkwAAAABGdBTUEAALGPC/xhBQAAAAlwSFlzAAAOvgAADr4B6kKxwAAAABl0RVh0U29mdHdhcmUAcGFpbnQubmV0IDQuMC4xOdTWsmQAAB16SURBVHhe7Z1PqHfdddff/Gteo21CcZpRDWlMRR2YWREspVTS1vjWCEXjpBMHggPRke8klECDIBbsIBapHdQ2KIiTDoSCGThIwZFIBy0ZtNiQTqRChq/rd77rrLvO2vvs3z6/f/c+9/l8+PJy9l7fvfb+7bPPOve5z33u+86z88E7PzOW+95APvjTz7byWMOkLZjy/N8/kUozd4pBqMt--9b/8KtzzDjNs2f7R3--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--tw7P/KuQsb--NZ/K7Xb5LE5yljJYy+N2Kmz8gEviTf9BWDa80e/pOQK6XqGyObtCbK/zF5onbo2SkHPtV4qndls8iwvmENb+qLoV/BDaoe/IS+AX/nlX1Lz53/ui6dvAX3v93/+T/6p/3y2vQNWvvFv/lWp3ZKHz1FGhTz80oidOisf8DKw0q/qHxcvhDiUUtnDGZUMkmd/LPOzF1sp6EflWRbKUzSQmXUYulI2UUJFblrodto98qtEOLty00qJZrljoYSK3LRQQkVuWniq4KrdF+uxL4DuWJ267uxlOtniBeCo9IdWzFaO1k3k2a+guwnXEjulPYpmKx/wAmi/sVVO+TOibcwq23goGvLsj6XMrhXqulAWWQr6UXmWhfIUDZRL3p6Us3R2VZxqGns7EM6BXoLzqXbfRNsXwOCE3AOdupnZZYtvATn/5S8/VX+7XjFbOVo3kWe/lHttrHbNpD2KZisf8Nzs/bVGHPHnRdtYFHtY+qWI7hlMnv2xlNm1Ql0XyiJLQT8qz7JQnqKBcrHbk3KWzq6KU83BDoRzoJfgfJtfAN--7nc+9ckf8i7jR971d4D9d/07ADP82R--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"
