# ~celeste~
# maddy thorson + noel berry

# Viper / GDScript conversion
# jice
const SPRITE_SIZE:int = 14
const SPRITE_PER_ROW:int = 512 / SPRITE_SIZE
const SCREEN_SIZE:int = 16 * SPRITE_SIZE
const X_OFFSET:int = 80
const Y_OFFSET:int = 0
const SPEED_COEF:float = SPRITE_SIZE / 8.0 + 0.5
const CLOUD_COUNT:int = 16
const PARTICLE_COUNT:int = 24

const LAYER_CLOUD=1
const LAYER_BACKGROUND=2
const LAYER_LEVEL=3
const LAYER_FADE=4
const LAYER_UI=5

var TILE_2_OBJ = {}

var got_fruit:Array[bool] = []
var frames:int = 0
var score:int = 0
var deaths:int = 0
var cheat:bool = false
var max_djump:int = 1
var start_game:bool = false
var start_game_flash:int = 0
var has_dashed:bool = false
var has_key:bool = false
var objects:Array = []
var roomx:int = 0
var roomy:int = 0
var freeze:int = 0
var cam_offset_x:int = 0
var cam_offset_y:int = 10
var flash_bg:bool = false
var new_bg:bool = false
var clouds:Array = []
var particles:Array = []
var dead_particles:Array = []
var flipflop:bool = true
var seconds:int = 0
var minutes:int = 0
var shake:int = 0
var pause_player:bool = false
var will_restart:bool = false
var will_next_room:bool = false
var delay_restart:int = 0
var sfx_timer:int = 0
var music_timer:int = 0

var PAL:Array[Color] = [
	Color8(0, 0, 1),
	Color8(29, 43, 83),
	Color8(126, 37, 83),
	Color8(0, 135, 81),
	Color8(171, 82, 54),
	Color8(95, 87, 79),
	Color8(194, 195, 199),
	Color8(255, 241, 232),
	Color8(255, 0, 77),
	Color8(255, 163, 0),
	Color8(255, 236, 39),
	Color8(0, 228, 54),
	Color8(41, 173, 255),
	Color8(131, 118, 156),
	Color8(255, 119, 168),
	Color8(255, 204, 170),
]

func level_index() -> int:
	return roomx % 8 + roomy * 8

func is_title() -> bool:
	return level_index() == 31

func spr(n:float, x:float, y:float, w:int, h:int, hflip:bool, vflip:bool) -> void:
	var int_spr:int = int(n)
	var spritex:int = (int_spr % SPRITE_PER_ROW) * SPRITE_SIZE
	var spritey:int = int_spr / SPRITE_PER_ROW * SPRITE_SIZE
	V.gfx.blit_region(
		Vector2(floor(x + X_OFFSET),floor(y + Y_OFFSET)),
		Vector2(spritex,spritey),
		Vector2(w * SPRITE_SIZE,h * SPRITE_SIZE),
		Color8(255, 255, 255),
		Vector2.ZERO,
		hflip,
		vflip
	)

func line(x1, y1, x2, y2, col):
	V.gfx.line(Vector2(x1 + X_OFFSET, y1 + Y_OFFSET),
		Vector2(x2 + X_OFFSET, y2 + Y_OFFSET),
		PAL[col]
	)

func get_sprite_offset(djump):
	return 180 if djump == 2 else 144 if djump == 0 else 0

func create_object(obj_type, x, y):
	if obj_type.is_fruit and got_fruit[level_index()] :
		return
	
	var obj = {
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
		hair = [],
	}
	if obj_type.has("init") :
		obj_type.init.call(obj)
	objects.append(obj)

func rect_fill(x1, y1, x2, y2, col):
	var w = x2 - x1 + 1
	var h = y2 - y1 + 1
	var x = x1 + X_OFFSET
	var y = y1 + Y_OFFSET
	V.gfx.rectangle(Rect2(x, y, w, h), PAL[col])

func circ_fill(x, y, r, col):
	V.gfx.circle(Vector2(x + X_OFFSET, y + Y_OFFSET), r, 0.0, PAL[col])

func create_hair(objz):
	objz.hair = []
	for i in range (0, 5) :
		objz.hair.append({
			x = objz.x,
			y = objz.y,
			size = clamp(4 - i, 2, 4),
		})
	
func update_hair(obj, facing, down):
	var lastx = obj.x + 7 - facing * 2
	var lasty = obj.y + (7 if down else 5)
	for h in obj.hair :
		h.x = h.x + (lastx - h.x) / 1.4
		h.y = h.y + (lasty + 0.8 - h.y) / 1.4
		lastx = h.x
		lasty = h.y
	
func draw_hair(obj, sprite_offset):
	var col = 8 if sprite_offset == 0 else 11 if sprite_offset == 180 else 12
	for h in obj.hair :
		circ_fill(h.x, h.y, h.size, col)
	
func obj_collide(obj, type, ox, oy):
	for other in objects :
		if other.type.name == type and other != obj and other.collideable \
			and other.x + other.hitbox.x + other.hitbox.w > obj.x + obj.hitbox.x + ox \
			and other.y + other.hitbox.y + other.hitbox.h > obj.y + obj.hitbox.y + oy \
			and other.x + other.hitbox.x < obj.x + obj.hitbox.x + obj.hitbox.w + ox \
			and other.y + other.hitbox.y < obj.y + obj.hitbox.y + obj.hitbox.h + oy :
			return other
	return null

func tile_flag_at(x, y, w, h, flag):
	var minx = maxi(floor(x / SPRITE_SIZE), 0)
	var maxx = mini(floor((x + w - 1) / SPRITE_SIZE), 15)
	var miny = maxi(floor(y / SPRITE_SIZE), 0)
	var maxy = mini(floor((y + h - 1) / SPRITE_SIZE), 15)
	for i in range(minx, maxx+1) :
		for j in range (miny, maxy+1) :
			var offset = roomx * 16 + i + (roomy * 16 + j) * 128 
			var tile = TILE_MAP[offset]
			if SPRITE_FLAGS[tile] & flag != 0 :
				return true
	return false

func solid_at(x, y, w, h):
	return tile_flag_at(x, y, w, h, 1 << 0)

func ice_at(x, y, w, h):
	return tile_flag_at(x, y, w, h, 1 << 4)

func spike_at(x, y, w, h, xspd, yspd):
	for i in range (maxi(0, floor(x/ SPRITE_SIZE)), mini(15, floor((x + w - 1) / SPRITE_SIZE) + 1)) :
		for j in range (maxi(0, floor(y / SPRITE_SIZE)), mini(15, floor((y + h - 1) / SPRITE_SIZE) + 1)) :
			var offset = roomx * 16 + i + (roomy * 16 + j) * 128
			var tile = TILE_MAP[offset]
			if tile == 17 and (fmod(y + h - 1,SPRITE_SIZE) >= SPRITE_SIZE * 6 / 8 or y + h == j * SPRITE_SIZE + SPRITE_SIZE) and yspd >= 0 :
				return true
			elif tile == 27 and fmod(y,SPRITE_SIZE) <= 2 * SPRITE_SIZE / 8 and yspd <= 0 :
				return true
			elif tile == 43 and fmod(x,SPRITE_SIZE) <= 2 * SPRITE_SIZE / 8 and xspd <= 0 :
				return true
			elif tile == 59 and (fmod(x + w - 1,SPRITE_SIZE) >= 6 * SPRITE_SIZE / 8 or x + w == i * SPRITE_SIZE + SPRITE_SIZE) and xspd >= 0 :
				return true
	return false

func obj_check(obj, type, ox, oy):
	return obj_collide(obj, type, ox, oy) != null

func obj_is_solid(obj, ox, oy):
	if oy > 0 and not obj_check(obj, "Platform", ox, 0) and obj_check(obj, "Platform", ox, oy) :
		return true
	return solid_at(obj.x + obj.hitbox.x + ox, obj.y + obj.hitbox.y + oy, obj.hitbox.w, obj.hitbox.h) \
		or obj_check(obj, "FallFloor", ox, oy) \
		or obj_check(obj, "FakeWall", ox, oy)

func appr(val, target, amount):
	if val > target :
		return max(val - amount, target)
	else:
		return min(val + amount, target)

func restart_room():
	will_restart = true
	delay_restart = 15

func kill_player(obj):
	deaths = deaths + 1
	shake = 10
	V.snd.play_pattern(0)
	dead_particles = []
	for dir in range (0, 8) :
		var angle = dir / 8 * PI * 2
		dead_particles.append( {
			x = obj.x + SPRITE_SIZE / 2,
			y = obj.y + SPRITE_SIZE / 2,
			t = 10,
			spdx = sin(angle) * 3 * SPEED_COEF,
			spdy = cos(angle) * 3 * SPEED_COEF,
		})
	restart_room()
	
func load_room(x, y):
	has_dashed = false
	has_key = false
	objects = []
	roomx = x
	roomy = y
	for tx in range (0, 16) :
		for ty in range (0, 16) :
			var offset = roomx * 16 + tx + (roomy * 16 + ty) * 128
			var tile = TILE_MAP[offset]
			if TILE_2_OBJ.has(tile) :
				var obj_type = TILE_2_OBJ[tile]
				create_object(obj_type, tx * SPRITE_SIZE, ty * SPRITE_SIZE)
						
var Smoke = {
	name = "Smoke",
	is_fruit = false,
	init = func(obj):
		obj.sprite = 29
		obj.speed.y = -0.1
		obj.speed.x = 0.4 + randf() * 0.2
		obj.x = obj.x + randf() * 2 - 1
		obj.y = obj.y + randf() * 2 - 1
		obj.hflip = randf() >= 0.5
		obj.vflip = randf() >= 0.5
		obj.solids = false,
	update = func(obj):
		obj.sprite = obj.sprite + 0.2
		if obj.sprite >= 31 :
			obj.to_remove = true
}

func next_room():
	if roomx == 2 and roomy == 1 :
		V.snd.play_music(2, 7)
	elif roomx == 4 and roomy == 2 :
		V.snd.play_music(2, 7)
	elif roomx == 5 and roomy == 3 :
		V.snd.play_music(2, 7)
	elif roomx == 3 and roomy == 1 :
		V.snd.play_music(3, 7)
	if roomx == 7 :
		if roomy == 3 :
			load_room(0, 0)
		else:
			load_room(0, roomy + 1)
	else:
		load_room(roomx + 1, roomy)

func cel_print(msg, px, py, col):
	col = col + 1
	V.gfx.print(V.gfx.FONT_8X8, msg, Vector2(floor(px + X_OFFSET), floor(py + Y_OFFSET)), PAL[col])

func break_fall_floor(obj):
	if obj.state == 0 :
		obj.state = 1
		obj.delay = 15
		create_object(Smoke, obj.x, obj.y)
		var hit = obj_collide(obj, "Spring", 0, -1)
		if hit :
			hit.hide_in = 15

var PlayerSpawn = {
	name = "PlayerSpawn",
	is_fruit = false,
	init = func(obj):
		obj.sprite = 3
		obj.target = { x = obj.x, y = obj.y }
		obj.y = 16 * SPRITE_SIZE
		obj.speed.y = -4 * SPEED_COEF
		obj.solids = false
		obj.state = 0
		obj.delay = 0
		create_hair(obj)
		V.snd.play_pattern(4,4),
	update = func(obj):
		update_hair(obj, -1 if obj.hflip else 1, false)
		if obj.state == 0 :
			# jumping up
			if obj.y < obj.target.y + SPRITE_SIZE * 2 :
				obj.state = 1
				obj.delay = 3
		elif obj.state == 1 :
			# falling
			obj.speed.y = obj.speed.y + 0.5 * SPEED_COEF
			if obj.speed.y > 0 and obj.delay > 0 :
				obj.speed.y = 0
				obj.delay = obj.delay - 1
			if obj.speed.y > 0 and obj.y > obj.target.y :
				obj.y = obj.target.y
				obj.speed.x = 0
				obj.speed.y = 0
				obj.state = 2
				obj.delay = 5
				# smoke
				create_object(Smoke, obj.x, obj.y + SPRITE_SIZE / 2)
				shake = 5
				V.snd.play_pattern(5)
		elif obj.state == 2 :
			# landing
			obj.delay = obj.delay - 1
			obj.sprite = 6
			if obj.delay < 0 :
				obj.to_remove = true
				create_object(Player, obj.x, obj.y)
		obj.dir = get_sprite_offset(max_djump),
	draw = func(obj):
		draw_hair(obj, obj.dir)
		spr(obj.sprite + obj.dir, obj.x, obj.y, 1, 1, obj.hflip, obj.vflip)
}

var Player = {
	name = "Player",
	is_fruit = false,
	init = func(obj):
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
		create_hair(obj),
	update = func(obj):
		if pause_player :
			return
		var right = V.inp.right()
		var left = V.inp.left()
		if right > 0.6 :
			right = 1
		if left > 0.6 :
			left = 1
		var input = right if right > 0 else -left if left > 0 else 0
		if spike_at(obj.x + obj.hitbox.x, obj.y + obj.hitbox.y, obj.hitbox.w, obj.hitbox.h, obj.speed.x, obj.speed.y) :
			obj.to_remove = true
			kill_player(obj)
		obj.down = V.inp.down() > 0.1
		update_hair(obj, -1 if obj.hflip else 1, obj.down)
		# bottom death
		if obj.y > SCREEN_SIZE :
			obj.to_remove = true
			kill_player(obj)
		var on_ground = obj_is_solid(obj, 0, 1)
		var on_ice = ice_at(obj.x + obj.hitbox.x, obj.y + obj.hitbox.y + 1, obj.hitbox.w, obj.hitbox.h)
		# smoke
		if on_ground and not obj.was_on_ground :
			create_object(Smoke, obj.x, obj.y + SPRITE_SIZE / 2)
		# jump
		var key_jump = V.inp.action1()
		var jump = key_jump and not obj.p_jump
		obj.p_jump = key_jump
		if jump :
			obj.jbuffer = 4
		elif obj.jbuffer > 0 :
			obj.jbuffer = obj.jbuffer - 1
		# dash
		var key_dash = V.inp.action2()
		var dash = key_dash and not obj.p_dash
		obj.p_dash = key_dash
		if on_ground :
			obj.grace = 6
			if obj.djump < max_djump :
				obj.djump = max_djump
				V.snd.play_pattern(54)
		elif obj.grace > 0 :
			obj.grace = obj.grace - 1
		obj.dash_effect_time = obj.dash_effect_time - 1
		var maxrun = SPEED_COEF
		if obj.dash_time > 0 :
			create_object(Smoke, obj.x, obj.y)
			obj.dash_time = obj.dash_time - 1
			obj.speed.x = appr(obj.speed.x, obj.dash_target.x, obj.dash_accel.x)
			obj.speed.y = appr(obj.speed.y, obj.dash_target.y, obj.dash_accel.y)
		else:
			# move
			var accel = (0.05  if on_ice else 0.4 if not on_ground else 0.6) * SPEED_COEF
			var deccel = 0.15 * SPEED_COEF
			if absf(obj.speed.x) > maxrun :
				obj.speed.x = appr(obj.speed.x, sign(obj.speed.x * maxrun), deccel)
			else:
				obj.speed.x = appr(obj.speed.x, input * maxrun, accel)
			# facing
			if obj.speed.x != 0 :
				obj.hflip = obj.speed.x < 0
			# gravity
			var maxfall = 2 * SPEED_COEF
			var gravity = 0.21 * SPEED_COEF
			if absf(obj.speed.y) <= 0.15 * SPEED_COEF :
				gravity = gravity * 0.5
			# wall slide
			if input != 0 and obj_is_solid(obj, input, 0) and not ice_at(obj.x + obj.hitbox.x + input, obj.y + obj.hitbox.y, obj.hitbox.w, obj.hitbox.h) :
				maxfall = 0.4 * SPEED_COEF
				if randf() * 10 < 2 :
					create_object(Smoke, obj.x + input * 6 * SPRITE_SIZE / 8, obj.y)
			if not on_ground :
				obj.speed.y = appr(obj.speed.y, maxfall, gravity)
			if obj.jbuffer > 0 :
				if obj.grace > 0 :
					# normal jump
					V.snd.play_pattern(1)
					obj.jbuffer = 0
					obj.grace = 0
					obj.speed.y = -2 * SPEED_COEF
					create_object(Smoke, obj.x, obj.y + SPRITE_SIZE / 2)
				else:
					# wall jump
					var wall_dir = -1 if obj_is_solid(obj, -3, 0) else 1 if obj_is_solid(obj, 3, 0) else 0
					if wall_dir != 0 :
						V.snd.play_pattern(2)
						obj.jbuffer = 0
						obj.speed.y = -2 * SPEED_COEF
						obj.speed.x = -wall_dir * (maxrun + SPEED_COEF)
						if not ice_at(obj.x + obj.hitbox.x + wall_dir * 3, obj.y + obj.hitbox.y, obj.hitbox.w, obj.hitbox.h) :
							create_object(Smoke, obj.x + wall_dir * 6 * SPRITE_SIZE / 8, obj.y)
			# dash
			var d_full = 5
			var d_half = d_full * 0.70710678118
			if obj.djump > 0 and dash :
				create_object(Smoke, obj.x, obj.y)
				obj.djump = obj.djump - 1
				obj.dash_time = 4
				has_dashed = true
				obj.dash_effect_time = 10
				var up = V.inp.up()
				if up > 0.6 :
					up = 1
				var v_input = -up if up > 0.0 else 1 if obj.down else 0
				if input != 0 :
					if v_input != 0 :
						obj.speed.x = input * d_half * SPEED_COEF
						obj.speed.y = v_input * d_half * SPEED_COEF
					else:
						obj.speed.x = input * d_full * SPEED_COEF
						obj.speed.y = 0
				elif v_input != 0 :
					obj.speed.x = 0
					obj.speed.y = v_input * d_full * SPEED_COEF
				else:
					obj.speed.x = (-1 if obj.hflip else 1) * SPEED_COEF
					obj.speed.y = 0
				V.snd.play_pattern(3)
				freeze = 2
				shake = 6
				obj.dash_target.x = 2 * sign(obj.speed.x) * SPEED_COEF
				obj.dash_target.y = 2 * sign(obj.speed.y) * SPEED_COEF
				obj.dash_accel.x = 1.5 * SPEED_COEF
				obj.dash_accel.y = 1.5 * SPEED_COEF
				if obj.speed.y < 0 :
					obj.dash_target.y = obj.dash_target.y * 0.75
				if obj.speed.y != 0 :
					obj.dash_accel.x = obj.dash_accel.x * 0.70710678118
				if obj.speed.x != 0 :
					obj.dash_accel.y = obj.dash_accel.y * 0.70710678118
			elif dash and obj.djump <= 0 :
				V.snd.play_pattern(9)
				create_object(Smoke, obj.x, obj.y)
		# animation
		obj.spr_off = obj.spr_off + 0.25
		if not on_ground :
			obj.sprite = 5 if obj_is_solid(obj, input, 0) else 3
		elif obj.down :
			obj.sprite = 6
		elif V.inp.up() > 0.9 :
			obj.sprite = 7
		elif obj.speed.x == 0 or input == 0 :
			obj.sprite = 1
		else:
			obj.sprite = 1 + (int(obj.spr_off) % 4)
		if obj.x < -1 or obj.x > SCREEN_SIZE - SPRITE_SIZE + 1 :
			obj.x = clamp(obj.x, -1, SCREEN_SIZE - SPRITE_SIZE + 1)
			obj.speed.x = 0
		# next level
		if obj.y < -SPRITE_SIZE / 2 and level_index() < 30 :
			will_next_room = true
		obj.was_on_ground = on_ground,
	draw = func(obj):
		var sprite_offset = get_sprite_offset(obj.djump)
		draw_hair(obj, sprite_offset)
		spr(obj.sprite + sprite_offset, obj.x, obj.y, 1, 1, obj.hflip, obj.vflip)
}

var FakeWall = {
	name = "FakeWall",
	is_fruit = true,
	init = func(obj):
		obj.sprite = 64,
	update = func(obj):
		obj.hitbox = { x = -1, y = -1, w = SPRITE_SIZE * 2 + 2, h = SPRITE_SIZE * 2 + 2 }
		var hit = obj_collide(obj, "Player", 0, 0)
		if hit and hit.dash_effect_time > 0 :
			V.snd.play_pattern(16)
			hit.speed.x = -sign(hit.speed.x) * 1.5
			hit.speed.y = -1.5
			hit.dash_time = -1
			obj.to_remove = true
			create_object(Smoke, obj.x, obj.y)
			create_object(Smoke, obj.x, obj.y + SPRITE_SIZE)
			create_object(Smoke, obj.x + SPRITE_SIZE, obj.y)
			create_object(Smoke, obj.x + SPRITE_SIZE, obj.y + SPRITE_SIZE)
			create_object(Fruit, obj.x + SPRITE_SIZE / 2, obj.y + SPRITE_SIZE / 2)
		obj.hitbox = { x = 0, y = 0, w = SPRITE_SIZE * 2, h = SPRITE_SIZE * 2 },
	draw = func(obj):
		spr(64, obj.x, obj.y, 1, 1, false, false)
		spr(65, obj.x + SPRITE_SIZE, obj.y, 1, 1, false, false)
		spr(80, obj.x, obj.y + SPRITE_SIZE, 1, 1, false, false)
		spr(81, obj.x + SPRITE_SIZE, obj.y + SPRITE_SIZE, 1, 1, false, false)
}

var Fruit = {
	name = "Fruit",
	is_fruit = true,
	init = func(obj):
		obj.sprite = 26
		obj.start = obj.y
		obj.off = 0,
	update = func(obj):
		var hit = obj_collide(obj, "Player", 0, 0)
		if hit :
			hit.djump = max_djump
			var idx = level_index()
			if not got_fruit[idx] :
				got_fruit[idx] = true
				score = score + 1
			create_object(LifeUp, obj.x, obj.y)
			obj.to_remove = true
			V.snd.play_pattern(13)
		obj.off = obj.off + 1
		obj.y = obj.start + sin(obj.off / 40 * 2.0 * PI) * 2.5
}

var LifeUp = {
	name = "LifeUp",
	is_fruit = false,
	init = func(obj):
		obj.speed.y = -0.25
		obj.duration = 30
		obj.x = obj.x - 2
		obj.y = obj.y - 4
		obj.flash = 0
		obj.solids = false,
	update = func(obj):
		obj.duration = obj.duration - 1
		if obj.duration <= 0 :
			obj.to_remove = true,
	draw = func(obj):
		obj.flash = obj.flash + 0.5
		cel_print("1000", obj.x - 2, obj.y, 7 + (int(obj.flash) % 2))
}

var Spring = {
	name = "Spring",
	is_fruit = false,
	init = func(obj):
		obj.sprite = 18
		obj.hide_in = 0
		obj.hide_for = 0,
	update = func(obj):
		if obj.hide_for > 0 :
			obj.hide_for = obj.hide_for - 1
			if obj.hide_for <= 0 :
				obj.sprite = 18
				obj.delay = 0
		elif obj.sprite == 18 :
			var hit = obj_collide(obj, "Player", 0, 0)
			if hit and hit.speed.y >= 0 :
				obj.sprite = 19
				hit.y = obj.y - SPRITE_SIZE / 2
				hit.speed.x = hit.speed.x * 0.2
				hit.speed.y = -3.2 * SPEED_COEF
				hit.djump = max_djump
				obj.delay = 10
				create_object(Smoke, obj.x, obj.y)
				var below = obj_collide(obj, "FallFloor", 0, 1)
				if below :
					if below.state == 0 :
						V.snd.play_pattern(15)
					break_fall_floor(below)
				V.snd.play_pattern(8)
		elif obj.delay > 0 :
			obj.delay = obj.delay - 1
			if obj.delay <= 0 :
				obj.sprite = 18
		if obj.hide_in > 0 :
			obj.hide_in = obj.hide_in - 1
			if obj.hide_in <= 0 :
				obj.hide_for = 60
				obj.sprite = 0
}

var FlyFruit = {
	name = "FlyFruit",
	is_fruit = true,
	init = func(obj):
		obj.start = obj.y
		obj.fly = false
		obj.stepy = 0.5
		obj.solids = false
		obj.sfx_delay = 8
		obj.sprite = 28,
	update = func(obj):
		# fly away
		if obj.fly :
			if obj.sfx_delay > 0 :
				obj.sfx_delay = obj.sfx_delay - 1
				if obj.sfx_delay <= 0 :
					sfx_timer = 20
					V.snd.play_pattern(14)
			obj.speed.y = appr(obj.speed.y, -3.5, 0.25)
			if obj.y < -SPRITE_SIZE * 2 :
				obj.to_remove = true
		else:
			# wait
			if has_dashed :
				obj.fly = true
			obj.stepy = obj.stepy + 0.05
			obj.speed.y = sin(obj.stepy * 2.0 * PI) * 0.5
		# collect
		var hit = obj_collide(obj, "Player", 0, 0)
		if hit :
			hit.djump = max_djump
			sfx_timer = 20
			V.snd.play_pattern(13)
			var idx = level_index()
			if not got_fruit[idx] :
				got_fruit[idx] = true
				score = score + 1
			create_object(LifeUp, obj.x, obj.y)
			obj.to_remove = true,
	draw = func(obj):
		var off = 0
		if not obj.fly :
			var dir = sin(obj.stepy * 2 * PI)
			if dir < 0 :
				off = 1 + max(0, sign(obj.y - obj.start))
		else:
			off = fmod(off + 0.25, 3.0)
		spr(45 + off, obj.x - 6, obj.y - 2, 1, 1, true, false)
		spr(obj.sprite, obj.x, obj.y, 1, 1, false, false)
		spr(45 + off, obj.x + 6, obj.y - 2, 1, 1, false, false)
}

var FallFloor = {
	name = "FallFloor",
	is_fruit = false,
	init = func(obj):
		obj.sprite = 23
		obj.state = 0
		obj.solid = true,
	update = func(obj):
		# idling
		if obj.state == 0 :
			if obj_check(obj, "Player", 0, -1) or obj_check(obj, "Player", -1, 0) or obj_check(obj, "Player", 1, 0) :
				break_fall_floor(obj)
				V.snd.play_pattern(15)
		elif obj.state == 1 :
			obj.delay = obj.delay - 1
			if obj.delay <= 0 :
				obj.state = 2
				obj.delay = 60
				obj.collideable = false
		elif obj.state == 2 :
			obj.delay = obj.delay - 1
			if obj.delay <= 0 and not obj_check(obj, "Player", 0, 0) :
				obj.state = 0
				obj.collideable = true
				V.snd.play_pattern(7)
				create_object(Smoke, obj.x, obj.y),
	draw = func(obj):
		if obj.state != 2 :
			if obj.state != 1 :
				spr(23, obj.x, obj.y, 1, 1, false, false)
			else:
				spr(23 + (15 - obj.delay) / 5, obj.x, obj.y, 1, 1, false, false)
}

var Key = {
	name = "Key",
	is_fruit = true,
	init = func(obj):
		obj.sprite = 8,
	update = func(obj):
		var was = floor(obj.sprite)
		obj.sprite = 9 + (sin(frames / 30 * 2 * PI) + 0.5)
		var _is = floor(obj.sprite)
		if _is == 10 and _is != was :
			obj.hflip = not obj.hflip
		if obj_check(obj, "Player", 0, 0) :
			sfx_timer = 10
			V.snd.play_pattern(23)
			obj.to_remove = true
			has_key = true
}

var Chest = {
	name = "Chest",
	is_fruit = true,
	init = func(obj):
		obj.sprite = 20
		obj.x = obj.x - 4
		obj.start = obj.x
		obj.timer = 20,
	update = func(obj):
		if has_key :
			obj.timer = obj.timer - 1
			obj.x = obj.start - 1 + randf() * 3
			if obj.timer <= 0 :
				V.snd.play_pattern(16)
				sfx_timer = 20
				create_object(Fruit, obj.x, obj.y - 4)
				obj.to_remove = true
}

var Balloon = {
	name = "Balloon",
	is_fruit = false,
	init = func(obj):
		obj.offset = randf()
		obj.start = obj.y
		obj.timer = 0
		obj.hitbox = { x = -1, y = -1, w = SPRITE_SIZE * 2, h = SPRITE_SIZE * 2 }
		obj.sprite = 22,
	update = func(obj):
		if obj.sprite == 22 :
			obj.offset = obj.offset + 0.01
			obj.y = obj.start + sin(obj.offset * 2 * PI) * 2
			var hit = obj_collide(obj, "Player", 0, 0)
			if hit and hit.djump < max_djump :
				create_object(Smoke, obj.x, obj.y)
				hit.djump = max_djump
				obj.sprite = 0
				obj.timer = 60
				V.snd.play_pattern(6)
		elif obj.timer > 0 :
			obj.timer = obj.timer - 1
		else:
			create_object(Smoke, obj.x, obj.y)
			obj.sprite = 22
			V.snd.play_pattern(7),
	draw = func(obj):
		if obj.sprite == 22 :
			spr(13 + fmod(obj.offset * 8, 3.0), obj.x, obj.y + 6, 1, 1, false, false)
			spr(obj.sprite, obj.x, obj.y, 1, 1, false, false)
}

func obj_move_x(obj, amount, start):
	if obj.solids :
		var stepx = sign(amount)
		for i in range (start, absf(amount)+1) :
			if not obj_is_solid(obj, stepx, 0) :
				obj.x = obj.x + stepx
			else:
				obj.speed.x = 0
				obj.rem.x = 0
				break
	else:
		obj.x = obj.x + amount

func platform_init(obj):
	obj.x = obj.x - SPRITE_SIZE / 2
	obj.solids = false
	obj.hitbox.w = SPRITE_SIZE * 2
	obj.last = obj.x


func platform_update(obj):
	obj.speed.x = obj.dir * 0.95
	if obj.x < -2 * SPRITE_SIZE :
		obj.x = SCREEN_SIZE
	elif obj.x > SCREEN_SIZE :
		obj.x = -2 * SPRITE_SIZE
	if not obj_check(obj, "Player", 0, 0) :
		var hit = obj_collide(obj, "Player", 0, -1)
		if hit :
			obj_move_x(hit, obj.x - obj.last, 1)
	obj.last = obj.x

func platform_draw(obj):
	spr(11, obj.x, obj.y - 1, 1, 1, false, false)
	spr(12, obj.x + SPRITE_SIZE, obj.y - 1, 1, 1, false, false)

var RPlatform = {
	name = "Platform",
	is_fruit = false,
	init = func(obj):
		platform_init(obj);
		obj.dir = 1;,
	update = func(obj): platform_update(obj) ,
	draw = func(obj): platform_draw(obj)
}

var LPlatform = {
	name = "Platform",
	is_fruit = false,
	init = func(obj):
		platform_init(obj);
		obj.dir = -1;,
	update = func(obj): platform_update(obj) ,
	draw = func(obj): platform_draw(obj) 
}

var BigChest = {
	name = "BigChest",
	is_fruit = false,
	init = func(obj):
		obj.sprite = 96
		obj.state = 0
		obj.hitbox.w = SPRITE_SIZE * 2,
	update = func(obj):
		if obj.state == 0 :
			var hit = obj_collide(obj, "Player", 0, SPRITE_SIZE)
			if hit and obj_is_solid(hit, 0, 1) :
				pause_player = true
				hit.speed.x = 0
				hit.speed.y = 0
				obj.state = 1
				V.snd.play_pattern(37)
				create_object(Smoke, obj.x, obj.y)
				create_object(Smoke, obj.x + SPRITE_SIZE, obj.y)
				obj.timer = 60
				obj.particles = []
		elif obj.state == 1 :
			obj.timer = obj.timer - 1
			shake = 5
			flash_bg = true
			if obj.timer <= 45 and obj.particles.size() < 50 :
				obj.particles.append( {
					x = 1 + randf() * SPRITE_SIZE * 2,
					y = 0,
					h = 32 + randf() * 32,
					spd = 8 + randf() * 8
				})
			if obj.timer < 0 :
				obj.state = 2
				obj.particles = []
				flash_bg = false
				new_bg = true
				create_object(Orb, obj.x + SPRITE_SIZE / 2, obj.y + SPRITE_SIZE / 2)
				pause_player = false
			for p in obj.particles :
				p.y = p.y + p.spd,
	draw = func(obj):
		if obj.state == 0 :
			spr(96, obj.x, obj.y, 1, 1, false, false)
			spr(97, obj.x + SPRITE_SIZE, obj.y, 1, 1, false, false)
		elif obj.state == 1 :
			for p in obj.particles :
				line(obj.x + p.x, obj.y + SPRITE_SIZE - p.y, obj.x + p.x,
					minf(obj.y + SPRITE_SIZE - p.y + p.h, obj.y + SPRITE_SIZE), 7)
		spr(112, obj.x, obj.y + SPRITE_SIZE, 1, 1, false, false)
		spr(113, obj.x + SPRITE_SIZE, obj.y + SPRITE_SIZE, 1, 1, false, false)
}

var Orb = {
	name = "Orb",
	is_fruit = false,
	init = func(obj):
		obj.speed.y = -4
		obj.solids = false
		obj.particles = [],
	update = func(obj):
		obj.speed.y = appr(obj.speed.y, 0, 0.5)
		var hit = obj_collide(obj, "Player", 0, 0)
		if hit and obj.speed.y == 0 :
			music_timer = 45
			freeze = 10
			shake = 10
			V.snd.play_music(4, 7)
			V.snd.play_pattern(51)
			obj.to_remove = true
			max_djump = 2
			hit.djump = 2,
	draw = func(obj):
		spr(102, obj.x, obj.y, 1, 1, false, false)
		var off = frames / 30
		for i in range (0, 8) :
			var x = obj.x + 7 + cos((off + i / 8) * 2 * PI) * 9
			var y = obj.y + 7 + sin((off + i / 8) * 2 * PI) * 9
			circ_fill(x, y, 2, 7)
}

var Flag = {
	name = "Flag",
	is_fruit = false,
	init = func(obj):
		obj.sprite = 118
		obj.x = obj.x + 5
		obj.show = false,
	update = func(obj):
		obj.sprite = 118 + int(frames / 5) % 3
		if not obj.show and obj_check(obj, "Player", 0, 0) :
			obj.show = true
			sfx_timer = 30
			V.snd.play_pattern(55),
	draw = func(obj):
		spr(obj.sprite, obj.x, obj.y, 1, 1, false, false)
		if obj.show :
			rect_fill(74, 52, 148, 64, 0)
			cel_print("Victory!", 80, 54, 7)
}

var TEXT = "# celeste mountain ##this memorial to those# perished on the climb"

var Message = {
	name = "Message",
	is_fruit = false,
	init = func(obj):
		obj.last = 0
		obj.dir = 0,
	update = func(obj):
		if obj_check(obj, "Player", 4, 0) :
			obj.sprite = 1
			if obj.dir < TEXT.length() :
				obj.dir = obj.dir + 0.5
				if obj.dir >= obj.last + 1 :
					obj.last = obj.last + 1
					V.snd.play_pattern(35)
		else:
			obj.sprite = 0
			obj.last = 0
			obj.dir = 0,
	draw = func(obj):
		if obj.sprite == 1 :
			var x = 24
			var y = 164
			var tlen = TEXT.length()
			var tmax = mini(floor(obj.dir) + 1, tlen)
			for i in range (1, tmax+1) :
				var ch = TEXT.substr(i, 1)
				if ch == "#" :
					x = 24
					y = y + 10
				else:
					rect_fill(x - 2, y - 2, x + 9, y + 10, 7)
					cel_print(ch, x, y, 1)
					x = x + 8
}

func draw_object(obj):
	if obj.type.has("draw") :
		obj.type.draw.call(obj)
	else:
		spr(obj.sprite, floor(obj.x), floor(obj.y), 1, 1, obj.hflip, obj.vflip)

func title_screen():
	got_fruit = []
	for i in range (0, 32) :
		got_fruit.append(false)
	frames = 0
	score = 0
	deaths = 0
	cheat = false
	max_djump = 1
	start_game = false
	start_game_flash = 0
	load_room(7, 3)

func init_music():
	for sfx in SFX :
		V.snd.new_pattern(sfx)
	V.snd.new_music(MUSIC_TITLE)
	V.snd.new_music(MUSIC_FIRST_LEVELS)
	V.snd.new_music(MUSIC_WIND)
	V.snd.new_music(MUSIC_SECOND_PART)
	V.snd.new_music(MUSIC_LAST_PART)
	V.snd.new_instrument(INST_TRIANGLE)
	V.snd.new_instrument(INST_TILTED)
	V.snd.new_instrument(INST_SAW)
	V.snd.new_instrument(INST_SQUARE)
	V.snd.new_instrument(INST_PULSE)
	V.snd.new_instrument(INST_ORGAN)
	V.snd.new_instrument(INST_NOISE)
	V.snd.new_instrument(INST_PHASER)
	V.snd.new_instrument(INST_SNARE)
	V.snd.new_instrument(INST_KICK)
#	V.snd.bounce_patterns()
	V.snd.play_music(0, 7)

func init():
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
	init_music()
	V.inp.set_ls_neutral_zone(0.2)
	for i in range  (0, CLOUD_COUNT) :
		clouds.append({
			x = randf() * SCREEN_SIZE,
			y = randf() * SCREEN_SIZE,
			spd = 1 + randf() * 4,
			w = 32 + randf() * 32,
		})
	for i in range (0, PARTICLE_COUNT) :
		particles.append({
			x = randf() * SCREEN_SIZE,
			y = randf() * SCREEN_SIZE,
			s = floor(randf() * 5 / 4),
			spdx = 0.25 + randf() * 5,
			spdy = 0,
			off = randf(),
			c = 6 + floor(0.5 + randf()),
		})
	V.gfx.set_layer_offset(LAYER_CLOUD, 0.0, 10.0)
	V.gfx.set_layer_offset(LAYER_BACKGROUND, 0.0, 10.0)
	V.gfx.set_layer_offset(LAYER_LEVEL, 0.0, 10.0)
	V.gfx.set_layer_offset(LAYER_FADE, 0.0, 10.0)
	V.gfx.set_layer_offset(LAYER_UI, 0.0, 10.0)
	V.gfx.show_layer(LAYER_BACKGROUND); # background
	V.gfx.show_layer(LAYER_LEVEL); # main game
	V.gfx.show_layer(LAYER_FADE); # fade to black layer
	V.gfx.show_layer(LAYER_UI); # ui layer
	#V.gfx.set_layer_operation(LAYER_FADE, V.gfx.LAYEROP_MULTIPLY)
	V.gfx.set_active_layer(LAYER_FADE)
	V.gfx.clear(Color(0,0,0,1))
	V.gfx.set_spritesheet(await V.gfx.load_img("celeste14.png"))
	V.gfx.set_active_layer(LAYER_LEVEL)
	title_screen()

func map(cx, cy, sx, sy, cw, ch, layer):
	for x in range(cx, cx + cw) :
		for y in range (cy, cy + ch) :
			var v = TILE_MAP[x + y * 128]
			if SPRITE_FLAGS[v] & layer != 0 :
				var spritex = (v % SPRITE_PER_ROW) * SPRITE_SIZE
				var spritey = floor(v / SPRITE_PER_ROW) * SPRITE_SIZE
				V.gfx.blit_region(
					Vector2(sx + X_OFFSET + (x - cx) * SPRITE_SIZE, sy + Y_OFFSET + (y - cy) * SPRITE_SIZE), 
					Vector2(spritex, spritey), 
					Vector2(SPRITE_SIZE, SPRITE_SIZE))

func obj_move_y(obj, amount):
	if obj.solids :
		var stepy = sign(amount)
		for i in range (0, absf(amount)+1) :
			if not obj_is_solid(obj, 0, stepy) :
				obj.y = obj.y + stepy
			else:
				obj.speed.y = 0
				obj.rem.y = 0
				break
	else:
		obj.y = obj.y + amount

func obj_move(obj):
	obj.rem.x = obj.rem.x + obj.speed.x
	var amount = floor(obj.rem.x + 0.5)
	obj.rem.x = obj.rem.x - amount
	obj_move_x(obj, amount, 0)

	obj.rem.y = obj.rem.y + obj.speed.y
	amount = floor(obj.rem.y + 0.5)
	obj.rem.y = obj.rem.y - amount
	obj_move_y(obj, amount)

func begin_game():
	frames = 0
	seconds = 0
	minutes = 0
	music_timer = 0
	start_game = false
	load_room(0, 0)

var action_pressed=false

func update():
	flipflop = not flipflop
	if not flipflop :
		action_pressed=V.inp.action1_pressed() or V.inp.action2_pressed()
		return
	else:
		action_pressed=action_pressed or V.inp.action1_pressed() or V.inp.action2_pressed()
	# clouds
	if not is_title() :
		for cloud in clouds:
			cloud.x = cloud.x + cloud.spd
			if cloud.x > SCREEN_SIZE :
				cloud.x = -cloud.w
				cloud.y = randf() * (SCREEN_SIZE - SPRITE_SIZE)
	# particles
	for part in particles :
		part.x = part.x + part.spdx * 2
		part.y = part.y + sin(4 * PI * part.off)
		part.off = part.off + minf(0.05, part.spdx / 32)
		if part.x > SCREEN_SIZE + SPRITE_SIZE / 2 :
			part.x = -SPRITE_SIZE / 2
			part.y = randf() * SCREEN_SIZE
	# dead particles
	for i in range (dead_particles.size()-1, -1, -1) :
		var p = dead_particles[i]
		p.x = p.x + p.spdx
		p.y = p.y + p.spdy
		p.t = p.t - 1
		if p.t <= 0 :
			dead_particles.remove_at(i)
	frames = (frames + 1) % 30

	if frames == 0 and level_index() < 30 :
		seconds = (seconds + 1) % 60
		if seconds == 0 :
			minutes = minutes + 1
	if freeze > 0 :
		freeze = freeze - 1
		return
	# screenshake
	if shake > 0 :
		shake = shake - 1
		if shake > 0 :
			cam_offset_x = floor( -2 + randf() * 5)
			cam_offset_y = floor(8 + randf() * 5)
		else:
			cam_offset_x = 0
			cam_offset_y = 10

	# restart
	if will_restart and delay_restart > 0 :
		delay_restart = delay_restart - 1
		if delay_restart <= 0 :
			will_restart = false
			load_room(roomx, roomy)
	elif will_next_room :
		will_next_room = false
		next_room()

	# update objects
	for i in range(objects.size()-1, -1, -1) :
		var obj = objects[i]
		if obj.to_remove :
			objects.remove_at( i)
		else:
			obj_move(obj)
			obj.type.update.call(obj)

	# start game
	if is_title() :
		if not start_game :
			if action_pressed :
				start_game_flash = 50
				start_game = true
				V.snd.stop_music()
				V.snd.play_pattern(38)
		if start_game :
			start_game_flash = start_game_flash - 1
			if start_game_flash <= -30 :
				begin_game()
				V.snd.play_music(1, 7)

func draw_level(x, y, col):
	rect_fill( -X_OFFSET, 0, 0, SCREEN_SIZE, 0)
	rect_fill(
		SCREEN_SIZE,
		0,
		SCREEN_SIZE + X_OFFSET,
		SCREEN_SIZE,
		0
	)
	if roomx == 3 and roomy == 1 :
		cel_print("old site", x + X_OFFSET / 2 - 32, y + 4, col)
	elif level_index() == 30 :
		cel_print("summit", x + X_OFFSET / 2 - 24, y + 4, col)
	else:
		var level = (1 + level_index()) * 100
		var offset = 0
		if level >= 1000 :
			offset = 4
		cel_print(
			"%d m" % level,
			x + X_OFFSET / 2 - 20 - offset,
			y + 4,
			col
		)

func draw_time(x, y, col):
	V.gfx.rectangle(Rect2(x, y, x + 64, y + 8), Color.BLACK)
	var ss = "0%d" % seconds if seconds < 10 else "%s" % seconds
	var m = minutes % 60
	var sm = "0%d" % m if m < 10 else "%s" % m
	var h = floor(minutes / 60)
	var sh = "0%d" % h if h < 10 else "%" % h
	cel_print("%s:%s:%s" % [sh,sm,ss], x + 1, y + 1, col)

func draw_ui():
	var textcol = 8 if cheat else 7
	draw_level( -X_OFFSET, 4, textcol)
	draw_time( -32 - X_OFFSET / 2, 24, textcol)
	cel_print(
		" x %d"  % score,
		30 - X_OFFSET,
		44,
		textcol
	)
	cel_print(
		" x %d" % deaths,
		30 - X_OFFSET,
		62,
		textcol
	)
	spr(26, 16 - X_OFFSET, 40, 1, 1, false, false)
	spr(1, 16 - X_OFFSET, 58, 1, 1, false, false)

func draw():
	if freeze > 0 :
		return
	var x = roomx * 16
	var y = roomy * 16
	if start_game :
		var l = (start_game_flash + 30) / 80
		V.gfx.set_active_layer(LAYER_FADE)
		V.gfx.clear(Color(0,0,0,l)) # fade out
		V.gfx.set_active_layer(LAYER_UI)
		rect_fill( -X_OFFSET, 0, 0, SCREEN_SIZE, 0)
		rect_fill(
			SCREEN_SIZE,
			0,
			SCREEN_SIZE + X_OFFSET,
			SCREEN_SIZE,
			0
		)
	elif is_title() :
		var alpha=max(0.0, 1.0-V.elapsed())
		V.gfx.set_active_layer(LAYER_FADE)
		V.gfx.clear(Color(0,0,0,alpha)) # fade in
	else :
		V.gfx.hide_layer(LAYER_FADE)
	V.gfx.set_active_layer(LAYER_CLOUD)

	# screen shake
	V.gfx.set_layer_offset(LAYER_CLOUD, cam_offset_x, cam_offset_y)
	V.gfx.set_layer_offset(LAYER_BACKGROUND, cam_offset_x, cam_offset_y)
	V.gfx.set_layer_offset(LAYER_LEVEL, cam_offset_x, cam_offset_y)
	# clear screen
	var bg_col = floor(frames/5) if flash_bg or start_game else 2 if new_bg else 0
	V.gfx.clear(PAL[bg_col])

	# clouds
	if not is_title() :
		var bg = 14 if new_bg else 1
		for cloud in clouds:
			rect_fill(
				cloud.x,
				cloud.y,
				cloud.x + cloud.w,
				cloud.y + 4 + (1 - cloud.w / 64) * 12,
				bg
			)

	V.gfx.set_active_layer(LAYER_BACKGROUND)
	V.gfx.clear(Color.TRANSPARENT)
	map(x, y, 0, 0, 16, 16, 4)
	V.gfx.set_active_layer(LAYER_LEVEL)
	V.gfx.clear(Color.TRANSPARENT)

	# platforms / big chests
	for obj in objects:
		var type_name = obj.type.name
		if type_name == "Platform" or type_name == "BigChest" :
			draw_object(obj)

	# terrain
	var off = 4 if is_title() else 0
	map(x, y, off, 0, 16, 16, 2)

	# objects
	for obj in objects:
		var type_name = obj.type.name
		if type_name != "Platform" and type_name != "BigChest" :
			draw_object(obj)

	# fg terrain
	map(x, y, 0, 0, 16, 16, 8)

	# particles
	for part in particles:
		rect_fill(
			part.x,
			part.y,
			part.x + part.s,
			part.y + part.s,
			part.c
		)
	# dead particles
	for part in dead_particles:
		var sz = part.t * SPRITE_SIZE / 8 / 5
		rect_fill(
			part.x - sz,
			part.y - sz,
			part.x + sz,
			part.y + sz,
			14 + fmod(part.t, 2.0)
		)

	# screen border masks
	rect_fill( -10, -10, -1, SCREEN_SIZE + 10, 0)
	rect_fill( -10, -10, SCREEN_SIZE + 10, -1, 0)
	rect_fill( -10, SCREEN_SIZE, SCREEN_SIZE + 10, SCREEN_SIZE + 10, 0)
	rect_fill(SCREEN_SIZE, -10, SCREEN_SIZE + 10, SCREEN_SIZE + 10, 0)
	# credits
	if is_title() :
		cel_print("press x/c", SCREEN_SIZE / 2 - 24, SCREEN_SIZE * 70 / 128, 5)
		cel_print("Maddy Thorson", SCREEN_SIZE / 2 - 39, SCREEN_SIZE * 80 / 128, 5)
		cel_print("Noel Berry", SCREEN_SIZE / 2 - 28, SCREEN_SIZE * 90 / 128, 5)
		cel_print("viper port", SCREEN_SIZE / 2 - 28, SCREEN_SIZE * 105 / 128, 5)
		cel_print("jice", SCREEN_SIZE / 2 - 4, SCREEN_SIZE * 115 / 128, 5)
	else:
		V.gfx.set_active_layer(LAYER_UI)
		V.gfx.clear(Color.TRANSPARENT)
		draw_ui()

var TILE_MAP = [
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
]

var SPRITE_FLAGS = [
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	4, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0,
	3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 2, 2, 0, 0, 0,
	3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 2, 2, 2, 2, 2,
	0, 0, 19, 19, 19, 19, 2, 2, 3, 2, 2, 2, 2, 2, 0, 2,
	0, 0, 19, 19, 19, 19, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2,
	0, 0, 19, 19, 19, 19, 0, 4, 4, 2, 2, 2, 2, 2, 2, 2,
	0, 0, 19, 19, 19, 19, 0, 0, 0, 2, 2, 2, 2, 2, 2, 2,
]

var SFX = [
	"02 F#5370 B.3470 B.4370 F.3470 F#4370 B.2470 D#4370 G.2470 B.3370 F.2470 F#3370 D.2470 D.3360 C.2460 A#2350 G#1440 F#2330 F.1420",
	"02 F.2070 G.2070 D.3070 C.4070",
	"03 C#2070 E.2070 A#2070 A#3070",
	"02 F#1420 G#1420 A.1420 B.1420 A#3440 F#4450 C.6650 B.5650 B.5650 A.5650 F#5650 D.5650 A.4650 E.4650 C.4640 A.3640 F.3640 D.3640 A#2630 F.2630 D.2630 B.1620 G.1620 F.1610 D#1610",
	"04 D#2070 F#3070 F#2070 A#3070 B.2070 D.4070 D#3060 G#4060 A.3050 C#5050 D#4040 F#5040 G.4030 A#5030 C.5020 D.6020 F.5010",
	"03 A.1770 A.1770 A.1760 A.1750 G#1740 G.1730 F#1720 F.1715",
	"03 C.4170 D.2170 A.4170 A#2170 E.5170 G#3160 B.5160 E.4150 D#6140 B.4120 E.4110 F.3110 E.2110 D#1110",
	"02 E.2110 F#2110 G#2110 A#2110 D.3120 G#3120 D.4130 D.5140 D.5140",
	"03 G.1070 A#1070 D.2070 E.2070 A#2070 A#3070 B.4070 B.4060 G#4060 G#4050 B.4050 B.4040 G#4040 G#4030 B.4020 B.4010",
	"03 F.1110 G.1130 D#6640 D#6640 D#6630 D#6620 D#6610 D#6615",
	# 10
	"16 C#3915 ...... C#3915 ...... D#3835 C#3915 ...... ...... C#3915 ...... ...... ...... D#3835 ...... C#3915 ...... C#3915 ...... C#3915 ...... D#3835 C#3915 ...... ...... C#3915 ...... ...... ...... D#3835 ...... C#3915 D#3835",
	"32 F.3040 F.3040 F.3030 F.3020 C.3040 C.3040 C.3030 C.3020 D#3030 D#3020 A#3040 A#3046 G.3035 G.3030 A#2040 A#2040 F.3040 F.3040 C.0001 G.2061 C.3030 C.3030 ...... G.3061 C.4050 A#3020 A#2040 G.2020 F.3040 D#3022 C.3040 C.3040",
	"16 G.1070 G.1060 G.1050 ...... G.1070 G.1060 D#1051 D#2070 A#1070 A#1060 A#1050 ...... A#1070 A#1060 F.1050 F.1040 D#1070 D#1060 ...... D#1050 D.2070 C.2060 F.2050 A#2070 A#2060 D#2071 F.1050 A#1070 F.1050 D#1051 A#1070 A#1060",
	"04 C.2550 E.3560 E.2570 B.3570 C#3570 G#4570 A.3570 G.5570 E.4570 B.5570 G#4570 D.6560 C#5550 D.6540 C#5530 D.6530 C#5520 D#6520 C#5520 D#6520 C#5510 D#6510 C#5510 D#6510 C#5510 D#6510 C#5510",
	"04 C.4740 G.4760 D.4770 F.3770 A.2770 A.2770 C#3770 E.3750 B.2730",
	"03 A.1645 D.2655 F#1655 A#1655 C#2655 F.1655 F.2655 G.1655 C.2655 E.1655 A.1655 F.2645 G#1635 C#2615",
	"16 G.3375 C.3375 D#4375",
	"16 F.4534 F.4534 F.4574 F.3540 A#3570 A#3560 C.3570 C.3570 C.3560 ...... C.3570 C.3560 ...... A#2570 A#2572 A#2562 D#4514 D#4534 D#4554 D#4574 G.3570 G.3560 ...... G.2520 D#3551 F.5530 C.5560 C.4540 F.4570 F.4560 A#3570 A#3560",
	"16 A#1070 A#1050 D#2071 D#2050 A#1060 A#1040 F.2070 F.2050 ...... ...... F.2070 F.2050 G.1060 G.1040 ...... ...... A#1070 A#1050 D#2070 D#2050 A#1060 A#1040 G.2071 G.2050 ...... ...... G.2070 G.2050 D#2070 D#2050 ...... ......",
	"32 A#3040 A#3030 A#3020 D#3011 C.4040 C.4030 D#4050 G.3020 G.4040 A#3020 D#4050 A#3020 F.4040 F.4030 F.4020 A#2010 A#3040 A#3030 G.4030 D#3030 C.4042 C.4032 D#4040 C.3030 F.3040 F.3030 G.3052 G.3042 G.3030 F.3021 F.3040 F.3030",
	# 20
	"08 C#3915 C#3915 D#3835 ...... ...... ...... D#3835 ...... E.3840 ...... ...... ...... D#3835 ...... C#1775 ...... C#1770 C#1775 ...... ...... D#3835 ...... D#3835 ...... E.3840 ...... ...... ...... D#3835 ...... ...... ......",
	"32 A#1140 A#1130 A#1120 F.2130 F.2120 F.2110 D#3140 D#3130 C.3152 C.3142 C.3132 G.2140 G.2140 G.2130 G.2120 G.2110 D#2140 D#2130 D#2120 F.2130 F.2120 F.2110 A#2142 A#2132 G.2150 G.2140 G.2130 G.2120 G.2110 G.2110 G.2110 ......",
	"16 A#4750 G.5750 A#4730 G.5730 A#4720 G.5720 A#4710 G.5710 A#3750 G.4750 A#3730 G.4730 F.3750 C.4750 F.3730 C.4730 G.3750 D#4750 G.3730 D#4730 G.3720 D#4720 F.4750 C.5750 F.4730 C.5730 F.4720 C.5720 F.4710 C.5710 F.4710 C.5710",
	"06 C.3770 F.5770 F.5770 F.5760 F.5750 F.5740 F.5730 F.5720 F.5710",
	"24 F.4450 F.5710 F.4440 F.5710 F.4430 G.5710 F.4420 G.5710 A#3450 F.5710 A#3440 D#4450 C.6710 D#4440 C.6710 D#4420 A#4450 F.5710 A#4440 F.5710 A#4430 G.5710 A#4420 G.5710 A#4410 C.4440 G.4450 F.5710 F.4450 C.6710 F.4440 C.6710",
	"24 F.1570 F.1570 F.1570 F.1570 F.1570 ...... F.1570 G.1570 A#1570 A#1570 A#1570 ...... A#1570 ...... A#1570 D#1570 F.1570 F.1570 F.1570 ...... F.1570 F.1570 F.1570 ...... A#1570 G.1570 C.2570 C.2570 D#2570 ...... A#1570 G.1570",
	"12 B.2935 ...... B.2925 ...... B.2915 ...... ...... ...... D#3840 D#3830 D#3820 D#3810 D#3810 ...... D#2915 ......",
	"12 C.4450 C.5710 G.4450 C.5710 C.4440 ...... G.4440 ...... C.4420 A#5710 G.4420 A#5710 C.4410 F.5710 G.4410 F.5710 F.3450 D#5710 C.4450 C.6710 F.3440 G.5710 C.4440 ...... F.3420 ...... C.4420 A#4710 F.3410 A#4710 C.4410 ......",
	"24 C.2570 C.2560 C.2550 ...... F.2570 F.2560 F.2550 ...... C.2570 C.2560 D#2571 D#2560 G.2570 G.2560 A#1570 A#1560 C.2570 C.2560 C.2550 ...... D#2570 D#2560 D#2550 ...... A#1570 A#1560 A#1550 ...... F.2570 F.2560 A#1570 A#1560",
	"24 C.2570 C.2560 C.2550 ...... F.2570 F.2560 F.2550 ...... C.2570 C.2560 D#2571 D#2560 G.2570 G.2560 D#2570 D#2560 C.2570 C.2570 C.2560 C.2560 C.2550 C.2530 ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
	# 30
	"12 C.4771 C.4770 C.4762 C.4752 A#5010 A#5010 C.3752 A#5010 F.5010 F.5010 C.3752 F.5010 C.3750 ...... ...... ...... A#3771 A#3772 A#3762 ...... G.3771 G.3772 G.3762 ...... A#3771 A#3772 A#3762 ...... D#4771 D#4772 D#4762 ......",
	"12 C.4771 C.4770 C.4762 C.4752 A#5010 A#5010 C.3750 A#5010 F.5010 F.5010 C.3750 F.5010 C.3750 ...... ...... ...... G.3771 G.3770 G.3762 G.3752 ...... ...... C.3751 ...... A#3771 A#3770 A#3762 A#3752 G.5012 G.5012 G.5012 ......",
	"12 C.4771 C.4770 C.4772 C.4772 C.4762 C.4752 C.4742 C.4732 C.4722 C.4712 ...... ...... ...... ...... ...... ...... ...... ...... A#4010 A#4010 F.5010 F.5010 D#5011 D#5010 G.4010 G.4010 G.4010 ...... C.5010 C.5012 C.5012 C.5012",
	"12 C.2332 C.2332 C.2322 C.2322 C.2312 C.2312 C.2312 ...... C.2332 C.2332 C.2322 C.2322 C.2312 C.2312 C.2312 ...... G.1332 G.1332 G.1322 G.1322 G.1312 G.1312 G.1312 ...... A#1332 A#1332 A#1322 A#1322 A#1312 A#1312 A#1312 ......",
	"12 C.2330 C.2330 C.2320 C.2320 C.2310 C.2310 C.2310 ...... C.2330 C.2330 C.2320 C.2320 C.2310 C.2310 C.2310 ...... A#1330 A#1320 G.2330 G.2320 G.1330 G.1320 G.1310 ...... A#1330 A#1320 A#1310 ...... D#2330 D#2320 D#2310 ......",
	"04 D#5625",
	"12 C.2330 C.2330 C.2330 C.2320 C.2320 C.2320 C.2310 C.2310 C.2310 C.2310 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... A#1331 A#1330 D#1321 D#1320",
	"16 C.2350 C.2340 C.2330 C.2320 D#2350 D#2340 D#2330 D#2320 C.3350 C.3340 G.2350 C.2340 C.3350 G.2350 A#2340 F.3360 A#3370 A#3370 A#3360 A#3350 A#3340 A#3320",
	"12 C.4275 G.4275 C.5275 C.4265 G.4265 C.5265 C.4255 G.4255 C.5255 C.4245 G.4245 C.5245 C.4235 G.4235 C.5235 C.4235 G.4225 C.5225 C.4215 G.4215 C.5215",
	"16 D#3835 C#1075 C#1075 D#3835 C#1075 D#3835 F.3855 C#1075 C#1075 D#3835 C#1075 D#3835 D.3855 D#3835 C#1075 D#3835",
	# 40
	"16 A#2270 A#2270 G.3271 G.3270 G.3270 G.3270 C.3171 C.3270 G.2271 G.2270 F.3271 F.3270 A#2271 A#2270 A#2270 A#2270 D#3271 D#3270 D#3270 D#3270 ...... ...... ...... ......",
	"08 C.4575 C.5575 C.4545 C.5545 D#3565 D#4565 G.3575 G.4575 G.3545 G.4545 G.3535 G.4535 G.3525 G.4525 G.3515 G.4515 D#3575 D#4575 D#3545 D#4545 D#3535 D#4535 F.3575 F.4575 F.3545 F.4545 F.3535 F.4535 G.3575 G.4575 G.3545 G.4545",
	"32 C.2265 C.2265 C.2255 C.2255 C.2245 C.2245 C.2235 A#1231 D#2265 D#2265 D#2255 D#2255 D#2245 D#2245 D#2235 A#2231 G.2265 G.2265 G.2255 G.2255 G.2245 G.2245 G.2235 G.2235 G.2225 G.1240 A#2270 G.2261 G.2250 G.2242 D#2260 D#2250",
	"16 G.1275 G.1265 G.1255 G.1245 D#2265 D#2255 C.2275 C.2265 C.2255 C.2245 C.2235 C.2225 G.1275 G.1265 G.1255 G.1245 G.1275 G.1265 G.1255 G.1245 C.2265 C.2255 F.2275 F.2265 F.2255 F.2245 G.2265 G.2255 A#2275 A#2265 A#2255 A#2245",
	"08 G.2570 G.4570 G.3540 G.4540 C.3550 C.4550 D#3570 D#4570 D#3540 D#4540 C.3570 C.4570 C.3540 C.4540 C.3530 C.4530 D#3570 D#4570 D#3540 D#4540 F.3530 F.4530 F.3520 F.4520 G.3570 G.4570 G.3540 G.4540 G.3530 G.4530 D#3550 D#4550",
	"16 F.2275 F.2265 F.2255 F.2245 G.2265 G.2255 C.3275 C.3265 C.3255 C.3245 F.3265 F.3255 D#2265 C.3245 G.2275 A#2255 D#2275 D#2265 D#2255 D#2245 F.2265 F.2255 A#2275 A#2265 A#2255 A#2245 D#3265 D#3255 A#3275 G.3245 C.3265 G.2235",
	"16 C#1075 D.3855 C#1075 D#3835 D.3855 D#3835 C#1075 D#3835 C#1075 D#3835 D.3855 C#1075 D.3855 D#3835 C#1075 D#3835",
	"16 C#1075 C#1075 C#1075 D#3835 D.3855 D#3835 D#3835 C#1075 C#1075 D#3835 C#1075 D#3835 D.3855 D#3835 D.3855 D#3835",
	"32 F.4040 F.4040 F.4030 G.4031 F.4024 G.4021 F.4014 G.4011 D#5044 C.5041 A#4044 A#4020 C.5044 C.5030 G.4041 G.4030 A#4044 A#4040 A#4030 C.5031 A#4024 C.5021 A#4024 C.5021 G.4044 A#4041 G.4034 A#4021 G.4044 G.4040 F.4031 F.4022",
	"08 C.4515 C.4515 C.4525 C.4525 C.4535 C.4535 C.4545 C.4545 C.4555 C.4555 C.4565 C.4565 C.4575 ...... C.4575 ...... C.4565 ...... C.4565 ...... C.4555 ...... C.4555 ...... C.4545 ...... C.4535 ...... C.4525 ...... C.4515 ......",
	# 50
	"08 G.3515 G.3515 G.3525 G.3525 G.3535 G.3535 G.3545 G.3545 G.3555 G.3555 G.3565 G.3565 G.3575 ...... G.3575 ...... G.3565 ...... G.3565 ...... G.3555 ...... G.3555 ...... G.3545 ...... G.3535 ...... G.3525 ...... G.3515 ......",
	"05 D#1730 F.1731 G.1741 C.2741 G.2751 D#3761 C.4370 C.5371 D#4570 A#4571 C.4370 C.5371 D#4570 A#4571 C.4360 C.5361 D#4560 A#4561 C.4350 C.5351 D#4550 A#4551 C.4340 C.5341 D#4540 A#4541 C.4330 C.5331 D#4520 A#4521 C.4310 C.5311",
	"32 C.2275 C.2265 C.2255 C.2245 C.2235 A#1265 A#1255 A#1245 D#2275 D#2265 D#2255 D#2245 D#2235 C.2265 C.2255 C.2245 C.2275 C.2265 C.2255 C.2245 C.2235 A#1265 A#1255 A#1245 D#2275 D#2265 D#2255 D#2245 D#2235 F.2265 F.2255 F.2245",
	"32 G.2275 G.2265 G.2255 G.2245 G.2235 F.2265 F.2255 F.2245 A#2275 A#2265 A#2255 A#2245 A#2235 G.2265 G.2255 G.2245 G.2275 G.2265 G.2255 G.2245 G.2235 D#2265 D#2255 D#2245 C.2250 F.2231 A#2265 D#2245 A#2272 A#2252 C.2270 C.2255",
	"03 G.3330 G.4330 A#3530 F.4530 G.3320 G.4320 A#3520 F.4520 G.3310 G.4310 A#3510 F.4510",
	"11 F.4355 F.4345 C.5370 C.5360 C.5355",
	"16 C.6575 C.6545 C.6535 C.6525 C.6515 C.6515 G.5555 G.5545 A#5575 A#5555 A#5545 A#5535 A#5525 A#5525 A#5515 A#5515 F.5575 F.5555 F.5545 F.5545 F.5535 F.5535 F.5525 F.5525 F.5515 F.5515 D#5575 D#5555 D#5545 D#5535 D#5525 D#5515",
	"16 F.5575 F.5555 F.5545 F.5535 F.5525 F.5525 F.5515 F.5515 G.5555 G.5535 D#5575 D#5555 D#5545 D#5535 D#5525 D#5525 A#5575 A#5545 A#5535 A#5525 A#5515 A#5515 D#5575 D#5555 D#5545 D#5545 D#5535 D#5535 D#5525 D#5525 D#5515 D#5515",
	"16 C.2060 C.2030 C.2050 C.2030 C.2050 C.2030 C.2010 ...... C.2060 C.2030 C.2050 C.2030 C.2050 C.2030 C.2010 ...... F.2060 F.2030 F.2050 F.2030 F.2010 ...... A#1060 A#1030 A#1050 A#1030 A#1050 A#1030 A#1050 A#1030 A#1010 ......",
	"16 F.1060 F.1030 F.1050 F.1030 F.1010 ...... G.1060 G.1030 G.1050 G.1030 G.1010 ...... D#2060 D#2030 D#2010 ...... C.2060 C.2030 C.2050 C.2030 C.2050 C.2030 C.2050 C.2030 C.2050 C.2030 C.2010 ...... C.2060 C.2030 C.2010 ......",
	# 60
	"16 D#3820 D#3810 ...... D#3810 D#3820 D#3810 D#3820 D#3810 ...... D#3810 D#3820 D#3810 D#3820 ...... D#3820 D#3810 D#3820 D#3810 D#3820 D#3810 ...... D#3810 D#3820 D#3810 D#3820 D#3810 D#3820 D#3810 ...... D#3810 D#3820 D#3820",
	"16 D.5611 D.5611 D.5611 D.5611 C#5611 C#5611 C.5611 A#4611 F#4611 C#4611 D#3611 G.2611 D#2611 C#2611 C.2611 C.2611 C.2611 C.2611 C.2611 D#2611 G#2611 F.3611 C.4611 F#4611 A#4611 C.5611 C#5611 D#5611 D#5611 E.5611 E.5611 E.5610",
	"64 C.5245 ...... C.5235 D#5225 G.4235 ...... C.5225 ...... ...... C.5225 ...... ...... C.5215 ...... ...... C.5215 G.4245 ...... G.4235 D#4225 F.4235 ...... G.4225 ...... ...... G.4225 ...... ...... G.4215 ...... ...... G.4215",
]

const MUSIC_FIRST_LEVELS = {NAME="first levels",
	PATLIST=[10,11,12,17,18,19,20,21,22],
	SEQ=["07....","082...","082...","012...","456...","082...","082...","034..."]}

const MUSIC_TITLE = {NAME="title screen",
PATLIST=[56,57,58,59,60],
SEQ=["024...","134..."]}

const MUSIC_WIND = {NAME="windy theme",
PATLIST=[61,62],
SEQ=["0.....","0.....","0.....","01...."]}

const MUSIC_SECOND_PART = {NAME="second part",
PATLIST=[39,41,42,43,44,45,46,47,48,49,50,52,53],
SEQ=["012...","012...","317...","347...","317...","347...","568...","09B...","0AC..."]}

const MUSIC_LAST_PART = {NAME="last part",
PATLIST=[24,25,26,27,28,29,30,31,32,33,34,36],
SEQ=["012...","012...","342...","352...","792...","792...","6A2...","8B2..."]}

const INST_TRIANGLE ={TYPE="Oscillator",OVERTONE=1.0,TRIANGLE=1.0,METALIZER=0.85,NAME="triangle"}
const INST_TILTED ={TYPE="Oscillator",OVERTONE=1.0,TRIANGLE=0.5,SAW=0.1,NAME= "tilted"}
const INST_SAW ={TYPE="Oscillator",OVERTONE=1.0,SAW=0.75,ULTRASAW=1.0,NAME="saw"}
const INST_SQUARE ={TYPE="Oscillator",OVERTONE=1.0,SQUARE=0.5,NAME="square"}
const INST_PULSE ={TYPE="Oscillator",OVERTONE=1.0,SQUARE=0.5,PULSE=0.5,TRIANGLE=1.0,METALIZER=1.0,OVERTONE_RATIO=0.5,NAME="pulse"}
const INST_ORGAN ={TYPE="Oscillator",OVERTONE=0.5,TRIANGLE=1.0,NAME="organ"}
const INST_NOISE ={TYPE="Oscillator", NOISE=1.0,NOISE_COLOR=0.2,NAME="noise"}
const INST_PHASER ={TYPE="Oscillator",OVERTONE=0.5,METALIZER=1.0,TRIANGLE=0.7,NAME="phaser"}
const INST_SNARE ={TYPE="Sample",ID=1,FILE="11_ZN.wav",FREQ=440}
const INST_KICK ={TYPE="Sample",ID=2,FILE="10_HALLBD1.wav",FREQ=440}
