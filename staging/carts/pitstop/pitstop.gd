class_name P
# inspired by pico racer 2048
# by impbox software
const AIR_RESISTANCE : float = 0.036
const BRAKE_COEF : float = 0.5
const CAR_BASE_MASS : float = 505
const COLLISION_COEF : float = 1.5/3
const ASPIRATION_COEF : float = 1.5
# impact of tyre wear on maxacc
const TYRE_WEAR_ACC_IMPACT : float = 0.03
# impact of tyre wear on BRAKE_COEF
const TYRE_WEAR_BRAKE_IMPACT : float = 0.3
# impact of tyre wear on steer
const TYRE_WEAR_STEER_IMPACT : float = 0.002
# wear level where performances start to decrease
const TYRE_WEAR_THRESHOLD : float = 0.5
# 1993 regulation : max fuel 220 liters = 146kg. average consumption 3.5liter/km = 2.3kg/km
const FUEL_MASS_PER_KM : float = 2.3
const TEAM_PERF_COEF : float = 1.0
const X_OFFSET : float = 130
const MINIMAP_START : int = -10
const MINIMAP_END : int = 20
const SMOKE_LIFE : int = 80
const DATA_PER_SEGMENT : int = 8
const DATA_PER_SECTION : int = 7
const LAYER_SMOKE : int = 3
const LAYER_SHADOW : int = 4
const LAYER_CARS : int = 5
const LAYER_SHADOW2 : int = 6
const LAYER_TOP : int = 7
const OBJ_TRIBUNE : int = 1
const OBJ_TRIBUNE2 : int = 2
const OBJ_TREE : int = 3
const OBJ_BRIDGE : int = 4
const OBJ_BRIDGE2 : int = 5
const OBJ_PIT : int = 6
const OBJ_PIT_LINE : int = 7
const OBJ_PIT_LINE_START : int = 8
const OBJ_PIT_LINE_END : int = 9
const OBJ_PIT_ENTRY1 : int = 10
const OBJ_PIT_ENTRY2 : int = 11
const OBJ_PIT_ENTRY3 : int = 12
const OBJ_PIT_EXIT1 : int = 13
const OBJ_PIT_EXIT2 : int = 14
const OBJ_PIT_EXIT3 : int = 15
const OBJ_COUNT : int = 16
const SHADOW_DELTA : Vector2 = Vector2(-10, 10)
const TRAIL_OFFSET : Vector2 = Vector2( -6, 0)
const MINIMAP_RACE_OFFSET : Vector2 = Vector2(340, 120)
const MINIMAP_EDITOR_OFFSET : Vector2 = Vector2(340, 200 )
const TYRE_TYPE : Array[String] = [ "soft", "medium", "hard", "inter", "wet" ]
# how many segments to heat the tyres ?
const TYRE_HEAT : Array[int] = [ 100, 175, 250, 50, 50 ]
# how many segment before the tyre might get flat
const TYRE_LIFE : Array[int] = [ 250*10, 250*15, 250*20, 250*20, 250*25 ]
# base impact on speed,acceleration,steering
const TYRE_PERF : Array[float] = [ 1.1, 1.0, 0.9, 0.8, 0.7 ]
const TYRE_COL : Array[int] = [ 8, 10, 7, 11, 28 ]
class RaceConf :
	var track: int
	var lap_count: int
	var difficulty : int
	func _init(ptrack: int, plap_count: int, pdifficulty: int) :
		self.track = ptrack
		self.lap_count = plap_count
		self.difficulty = pdifficulty
static var DEFAULT_QUICK_RACE_CONF : RaceConf = RaceConf.new(1,5,2)
static var quick_race_conf: RaceConf = DEFAULT_QUICK_RACE_CONF

const COUNTRY_BRASIL : int = 0
const COUNTRY_SOUTH_AFRICA : int = 1
const COUNTRY_ITALY : int = 2
const COUNTRY_SPAIN : int = 3
const COUNTRY_CANADA : int = 4
const COUNTRY_FRANCE : int = 5
const COUNTRY_HUNGARY : int = 6
const COUNTRY_PORTUGAL : int = 7
const COUNTRY_JAPAN : int = 8
const COUNTRY_AUSTRALIA : int = 9
const COUNTRY_UK : int = 10
const COUNTRY_US : int = 11
const COUNTRY_AUSTRIA : int = 12
const COUNTRY_FINLAND : int = 13
const COUNTRY_BELGIUM : int = 14
const COUNTRY_IRELAND : int = 15
const COUNTRY_SWITZERLAND : int = 16
const COUNTRY_NETHERLAND : int = 17
const COUNTRY_MONACO : int = 18
const COUNTRY_NORWAY : int = 19
const COUNTRY_SWEDEN : int = 20
const COUNTRY_SCOTLAND : int = 21
const CARS = [ {
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
} ]
const TRACK_DATA = [
	# Kyalami
	{
		name="Interlochs", # Interlagos
		country = COUNTRY_SCOTLAND
	},
	# Donington
	# Imola
	# Barcelona
	# Monaco
	# Montreal
	# Magny-Cours
	# Silverstone
	# Hockeheim
	# Hungaroring
	# Spa-Francorchamps
	{
		name="Manzana", # Monza
		country = COUNTRY_SPAIN
	}
	# Estoril
	# Suzuka
	# Adelaide
]

const PANEL_CAR_STATUS : int = 1
static var ui_panels=[null,PANEL_CAR_STATUS]
static var panel : int = 0
# car tracked by camera. null = player
static var tracked : int = -1
## the car being tracked by the camera
static var cam_car = null
static var minimap_offset : Vector2 = MINIMAP_RACE_OFFSET
static var cam_pos : Vector2 = Vector2.ZERO
static var cam_target_pos : Vector2 = Vector2.ZERO
static var camera_lastpos : Vector2 = Vector2.ZERO
static var camera_angle : float = 0.0
static var camera_scale :float = 1.0
static var best_seg_times : Array[float] = []
static var best_lap_time : float = 0.0
static var best_lap_driver = null
static var mlb_pressed : bool = false
static var frame : int = 0
# used to update game only 30x/s instead of 60
static var flipflop : bool = true

static func inp_brake():
	# controller X or keyboard C
	return V.inp.action2()

static func inp_accel():
	# controller A or keyboard X
	return V.inp.action1()

static func inp_menu_pressed():
	return V.inp.pad_button_pressed(1, V.inp.XBOX360_SELECT) or V.inp.key_pressed(V.inp.KEY_ESCAPE)

# pico8 palette
const PAL = [
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
	Color8(11, 51, 16),
	Color8(17, 29, 53),
	Color8(66, 33, 54),
	Color8(18, 83, 89),
	Color8(116, 47, 41),
	Color8(73, 51, 59),
	Color8(162, 136, 121),
	Color8(243, 239, 125),
	Color8(190, 18, 80),
	Color8(255, 108, 36),
	Color8(168, 231, 46),
	Color8(9, 181, 67),
	Color8(6, 90, 181),
	Color8(117, 70, 101),
	Color8(255, 110, 89),
	Color8(255, 157, 129),
	Color8(92, 84, 76),
	Color8(255,255,255)
]

const SHADOW_COL : int = 22
const UI_BACKGROUND_COLOR : Color = Color8(50,50,50)

static func cls():
	var c = PAL[21]
	V.gfx.set_active_layer(LAYER_TOP)
	V.gfx.clear(Color.TRANSPARENT)
	V.gfx.set_active_layer(LAYER_SHADOW)
	V.gfx.clear(Color.WHITE)
	V.gfx.set_active_layer(LAYER_SHADOW2)
	V.gfx.clear(Color.WHITE)
	V.gfx.set_active_layer(LAYER_CARS)
	V.gfx.clear(Color.TRANSPARENT)
	V.gfx.set_active_layer(0)
	V.gfx.clear(c)

static func pico_cos(v: float) -> float :
	return cos(from_pico_angle(v))

static func pico_sin(v: float) -> float :
	return sin(from_pico_angle(v))

static func from_pico_angle(v: float) -> float :
	return -v * 2.0 * PI if v < 0.5  else (1.0 - v) * 2.0 * PI

static func to_pico_angle(a: float) -> float :
	var ra = a / PI
	var picoa = -ra * 0.5 if ra < 0 else 1.0 - ra * 0.5
	return picoa

static func lerp_pico_angle(a : float,b : float,c : float) -> float :
	var diff : float = fposmod(b - a, 1.0)
	var dist : float = fposmod(2 * diff, 1.0) - diff
	return a + dist * c

static func rnd(n : float = 1.0) -> float :
	return randf() * n

static func line(x1 : float, y1 : float, x2 : float, y2 : float, col_index : float) :
	var col : Color = PAL[col_index as int]
	var p1 = cam2screen(Vector2(x1, y1))
	var p2 = cam2screen(Vector2(x2, y2))
	V.gfx.line(p1, p2, col)

static func world2minimap(p: Vector2) -> Vector2 :
	p -= cam_pos
	p = rotate_point(p, -camera_angle + 0.25, Vector2.ZERO)
	p *= 0.05
	p += minimap_offset
	return p

static func minimap_line(p1 : Vector2, p2 : Vector2, color_index : float) :
	p1 = world2minimap(p1)
	p2 = world2minimap(p2)
	var col=PAL[color_index as int]
	V.gfx.line(p1, p2, col)

static func minimap_circle(p : Vector2, color_index : float) :
	p = world2minimap(p)
	var col=PAL[color_index as int]
	V.gfx.circle(Vector2(p.x+0.5, p.y), 2.0, 0.0, col)

static func cam2screen(p : Vector2) -> Vector2 :
	p = (p - cam_pos) * camera_scale
	p = rotate_point(p, -camera_angle + 0.25, Vector2.ZERO) +  Vector2(64, 64)
	return Vector2(p.x * 224 / 128 + X_OFFSET, p.y * 224 / 128)

static func draw_tyres(p1 : Vector2, p2 : Vector2, p3 : Vector2, p4 : Vector2, col_index : float) :
	var x = (p3 - p1).normalized()
	var y = (p2 - p1).normalized() * 0.7
	var p1px = p1 + x
	var p1mx = p1 - x
	quadfill(p1mx - y, p1mx + y, p1px - y, p1px + y, col_index)
	var p2px = p2 + x
	var p2mx = p2 - x
	quadfill(p2mx - y, p2mx + y, p2px - y, p2px + y, col_index)
	var p3px = p3 + x
	var p3mx = p3 - x
	quadfill(p3mx - y, p3mx + y, p3px - y, p3px + y, col_index)
	var p4px = p4 + x
	var p4mx = p4 - x
	quadfill(p4mx - y, p4mx + y, p4px - y, p4px + y, col_index)

static func trifill(p1 : Vector2, p2 : Vector2, p3 : Vector2, color_index : float, transf: bool = true) :
	var col = PAL[color_index as int]
	if transf :
		p1 = cam2screen(p1)
		p2 = cam2screen(p2)
		p3 = cam2screen(p3)
	V.gfx.triangle(p1, p2, p3, col)

static func quadfill(p1 : Vector2, p2 : Vector2, p3 : Vector2, p4 : Vector2, color_index : float, transf: bool = true) :
	trifill(p1, p2, p3, color_index, transf)
	trifill(p2, p3, p4, color_index, transf)

static func circfill(x : float, y : float, r : float, color_index: float) :
	var col = PAL[color_index as int]
	var p = cam2screen(Vector2(x, y))
	V.gfx.circle(p, r * 224 / 128, null, col)

static func rectfill(x0 : float, y0 : float, x1 : float, y1 : float, color_index : float) :
	var col = PAL[color_index as int]
	V.gfx.rectangle(Rect2(x0, y0, x1 - x0 + 1, y1 - y0 + 1), col)

static func rect(x0 : float, y0 : float, w : float, h : float, color_index : float) :
	var col = PAL[color_index as int]
	V.gfx.line(Vector2(x0, y0), Vector2(x0 + w - 1, y0), col)
	V.gfx.line(Vector2(x0, y0 + h - 1), Vector2(x0 + w - 1, y0 + h - 1), col)
	V.gfx.line(Vector2(x0 + w - 1, y0), Vector2(x0 + w - 1, y0 + h - 1), col)
	V.gfx.line(Vector2(x0, y0), Vector2(x0, y0 + h - 1), col)

static func mid(x : float, y : float, z : float) :
	if (x <= y and y <= z) or (z <= y and y <= x) :
		return y
	elif (y <= x and x <= z) or (z <= x and x <= y) :
		return x
	else:
		return z

static func gblit_region(x : float, y : float, w : float, h : float, p : Vector2, col_index : int, dir : float) :
	p = cam2screen(p)
	var col=PAL[col_index]
	V.gfx.blit_region(p, Vector2(x, y), Vector2(w, h), col, from_pico_angle(camera_angle - dir), Vector2(w * camera_scale, h * camera_scale))

static func gblit_col(x : float, y : float, w : float, h : float, p: Vector2, col_index : int, dir : float) :
	p = cam2screen(p)
	var col=PAL[col_index]
	V.gfx.blit_col(p, Vector2(x, y), Vector2(w, h), col, from_pico_angle(camera_angle - dir), Vector2(w * camera_scale, h * camera_scale))

static func gprint(msg : String, px : float, py : float, col_index : float) :
	var col = PAL[col_index as int]
	V.gfx.print(V.gfx.FONT_8X8, msg, Vector2(floor(px), floor(py)), col)

const GEOFF_COL1_SELECTED=Color8(147,14,1)
const GEOFF_COL1=Color8(42,78,112)
const GEOFF_COL2_SELECTED=Color8(254,25,0)
const GEOFF_COL2=Color8(131,147,162)
static func geoff_print(msg : String,x : float,y : float,selected : bool) :
	V.gfx.print(V.gfx.FONT_8X8, msg, Vector2(floor(x)-1, floor(y)-1), GEOFF_COL1_SELECTED if selected else GEOFF_COL1)
	V.gfx.print(V.gfx.FONT_8X8, msg, Vector2(floor(x)+1, floor(y)+1), GEOFF_COL2_SELECTED if selected else GEOFF_COL2)
	V.gfx.print(V.gfx.FONT_8X8, msg, Vector2(floor(x), floor(y)), Color.WHITE)

const G_MENU_W : float = 176.0
static var G_MENU_X : float = (V.gfx.SCREEN_WIDTH-G_MENU_W) * 0.5
const G_MENU_H : float = 14.0
const GEOFF_COL3_SELECTED=Color8(212,19,0)
const GEOFF_COL3=Color8(96,113,132)
static func geoff_menu_item(msg: String, y : float, selected: bool) :
	V.gfx.rectangle(Rect2(G_MENU_X,y,G_MENU_W,G_MENU_H), GEOFF_COL3_SELECTED if selected else GEOFF_COL3)
	V.gfx.line(Vector2(G_MENU_X,y+G_MENU_H),Vector2(G_MENU_X+G_MENU_W,y+G_MENU_H), GEOFF_COL1)
	V.gfx.line(Vector2(G_MENU_X+G_MENU_W,y),Vector2(G_MENU_X+G_MENU_W,y+G_MENU_H), GEOFF_COL1)
	V.gfx.line(Vector2(G_MENU_X,y),Vector2(G_MENU_X+G_MENU_W,y), GEOFF_COL2)
	V.gfx.line(Vector2(G_MENU_X,y),Vector2(G_MENU_X,y+G_MENU_H), GEOFF_COL2)
	geoff_print(msg,G_MENU_X + G_MENU_W/2 - msg.length() * 4, y+3, selected)

static func geoff_frame(x : float,y : float,w : float,h : float) :
	V.gfx.rectangle(Rect2(x,y,w,h), Color8(28,63,98))
	for fy in range (1,floor(h/8)+1) :
		V.gfx.blit_region(Vector2(x,y+fy*8-8),Vector2(155,0),Vector2(4,8))
		V.gfx.blit_region(Vector2(x+w-4,y+fy*8-8),Vector2(155,0),Vector2(4,8),Color.WHITE,0.0,Vector2.ZERO,true, true)
	for fx in range (1,floor(w/8)+1) :
		V.gfx.blit_region(Vector2(x+fx*8-8,y),Vector2( 159,0),Vector2(8,4))
		V.gfx.blit_region(Vector2(x+fx*8-8,y+h-4),Vector2(159,0),Vector2(8,4),Color.WHITE,0.0,Vector2.ZERO,false,true)

const TEAMS = [
	{
		name="Williamson",
		color = 1,
		color2 = 10,
		perf = 5,
		short_name = "WIL",
		pit=1,
		country = COUNTRY_UK
	},
	{
		name="MacLoran",
		color = 7,
		color2 = 8,
		perf = 4,
		short_name = "MCL",
		pit=2,
		country = COUNTRY_UK
	},
	{
		name = "Benettson",
		color = 11,
		color2 = 26,
		perf = 4,
		short_name = "BEN",
		pit=3,
		country = COUNTRY_UK
	},
	{
		name = "Ferrero",
		color = 8,
		color2 = 24,
		perf = 3,
		short_name = "FER",
		pit=4,
		country = COUNTRY_ITALY
	},
	{
		name="Leger",
		color = 28,
		color2 = 7,
		perf = 2,
		short_name = "LEG",
		pit=5,
		country = COUNTRY_FRANCE
	},
	{
		name="Lotusi",
		color = 5,
		color2 = 7,
		perf = 0,
		short_name = "LOT",
		pit=6,
		country = COUNTRY_ITALY
	},
	{
		name = "Soober",
		color = 16,
		color2 = 16,
		perf = 0,
		short_name = "SOO",
		pit=7,
		country = COUNTRY_SWITZERLAND
	},
	{
		name="Jardon",
		color = 29,
		color2 = 8,
		perf = 0,
		short_name = "JAR",
		pit=8,
		country = COUNTRY_IRELAND
	}
]

static func find_team_id(name) -> int:
	var i: int = 0
	for team in TEAMS :
		if team.name == name :
			return i
		i+=1
	return -1

static var DRIVERS = [ {
	name = "Anton Sanna",
	short_name = "ASA",
	skill = 8,
	team = find_team_id("MacLoran"),
	helmet = 10,
	country = COUNTRY_AUSTRIA
}, {
	name = "Alan Presto",
	short_name = "APR",
	skill = 7,
	team = find_team_id("Williamson"),
	helmet = 11,
	country = COUNTRY_ITALY
}, {
	name = "Naijeru Manseru",
	short_name = "NMA",
	skill = 5,
	team = find_team_id("Jardon"),
	helmet = 12,
	country = COUNTRY_JAPAN
}, {
	name = "Gege Leyton",
	short_name = "GLE",
	skill = 6,
	team = find_team_id("Soober"),
	helmet = 13,
	country = COUNTRY_UK
}, {
	name = "Mike Shoemaker",
	short_name = "MSH",
	skill = 6,
	team = find_team_id("Benettson"),
	helmet = 14,
	country = COUNTRY_US
}, {
	name = "Pierre Lami",
	short_name = "PLA",
	skill = 5,
	team = find_team_id("Jardon"),
	helmet = 15,
	country = COUNTRY_FRANCE
}, {
	name = "Richard Petrez",
	short_name = "RPE",
	skill = 5,
	team = find_team_id("Benettson"),
	helmet = 22,
	country = COUNTRY_IRELAND
}, {
	name = "John HeartBerth",
	short_name = "JHE",
	skill = 4,
	team = find_team_id("Lotusi"),
	helmet = 23,
	country=COUNTRY_UK
}, {
	name = "Devon Hell",
	short_name = "DHE",
	skill = 6,
	team = find_team_id("Williamson"),
	helmet = 24,
	country = COUNTRY_UK
}, {
	name = "Markus Blunberg",
	short_name = "MBL",
	skill = 5,
	team = find_team_id("Leger"),
	helmet = 25,
	country=COUNTRY_FINLAND
}, {
	name = "Gerardo Bergini",
	short_name = "GBE",
	skill = 5,
	team = find_team_id("Ferrero"),
	helmet = 26,
	country = COUNTRY_ITALY
}, {
	name = "Mike Andrett",
	short_name = "MAN",
	skill = 4,
	team = find_team_id("MacLoran"),
	helmet = 27,
	country = COUNTRY_UK
}, {
	name = "Carlos Wandling",
	short_name = "CWA",
	skill = 4,
	team = find_team_id("Soober"),
	helmet = 28,
	country = COUNTRY_BRASIL
}, {
	name = "Marco Brundli",
	short_name = "MBL",
	skill = 4,
	team = find_team_id("Leger"),
	helmet = 29,
	country = COUNTRY_ITALY
}, {
	name = "Michael Hakenberg",
	short_name = "MHA",
	skill = 5,
	team = find_team_id("Lotusi"),
	helmet = 30,
	country=COUNTRY_AUSTRIA
} ]

const DT : float = 1.0/30.0 # 1/30th of a second

class GameMode:
	func init() :
		pass
	func update() :
		pass
	func draw():
		pass

static var game_mode = null

static func draw_particle(p):
	line(p.x, p.y, p.x - p.xv, p.y - p.yv,
		3 if p.grass else (10 if p.ttl > 20 else (9 if p.ttl > 10 else 8)))

class Particle:
	var x : float = 0.0
	var y : float = 0.0
	var xv : float = 0.0
	var yv : float = 0.0
	var ttl : int = 0
	var seg : int = 0
	var enabled : bool = true
	var grass : bool = false
	func draw():
		P.draw_particle(self)

static func draw_smoke(p):
	var draw_pos : Vector2 = cam2screen(Vector2(p.x, p.y))
	var rgb : float = p.ttl as float / SMOKE_LIFE
	var col : Color = rgb * PAL[p.col]
	V.gfx.circle(draw_pos, p.r * (2 - rgb), null, col)

class Smoke extends Particle :
	var r : float = 0.0
	func draw():
		P.draw_smoke(self)

static var particles = []
static var smokes = []
static var mapsize : int = 250
static func create_spark(segment : int, pos : Vector2, speed : Vector2, grass : bool) :
	for p in particles :
		if not p.enabled :
			p.x = pos.x
			p.y = pos.y
			p.xv = -speed.x + (rnd(2) - 1) / 2
			p.yv = -speed.y + (rnd(2) - 1) / 2
			p.ttl = 30
			p.seg = segment
			p.enabled = true
			p.grass = grass
			return
	var p = Particle.new()
	p.x = pos.x
	p.y = pos.y
	p.xv = -speed.x + (rnd(2) - 1) / 2
	p.yv = -speed.y + (rnd(2) - 1) / 2
	p.ttl = 30
	p.seg = segment
	p.grass = grass
	particles.append(p)

static func create_smoke(segment : int, pos : Vector2, speed : Vector2, color : int) :
	for s in smokes :
		if not s.enabled :
			s.x = pos.x
			s.y = pos.y
			s.xv = speed.x * 0.3 + (rnd(2) - 1) / 2
			s.yv = speed.y * 0.3 + (rnd(2) - 1) / 2
			s.r = randi_range(2,4)
			s.seg = segment
			s.enabled = true
			s.ttl = SMOKE_LIFE
			s.col = color
			return
	var p = Smoke.new()
	p.x = pos.x
	p.y = pos.y
	p.xv = speed.x * 0.3 + (rnd(2) - 1) / 2
	p.yv = speed.y * 0.3 + (rnd(2) - 1) / 2
	p.ttl = SMOKE_LIFE
	p.r = randi_range(2,4)
	p.seg = segment
	p.enabled = true
	p.col = color
	smokes.append(p)

static func update_ai(ai):
	ai.decisions = ai.decisions + DT * (ai.skill + 4 + rnd(6))
	if ai.decisions < 1 :
		return
	var car = ai.car
	var c = car.controls
	if car.current_segment == -1 :
		return
	var e = 6
	var s = 6
	var t = car.current_segment + e
	if posmod(t,mapsize) == car.race.first_pit and car.race.pits[car.driver.team] == null :
		# do /we need to change tyres ?
		var max_wear=0
		for i in range(0,4) :
			max_wear=max(max_wear,car.tyre_wear[i]/TYRE_LIFE[car.tyre_type])
		print("car %s max wear %.2f" % [car.driver.name,max_wear])
		if max_wear > 0.95 + rnd()*0.1*ai.riskiness :
			var team_pit=TEAMS[car.driver.team].pit
			car.pit = team_pit
			print ("PIT!!")
	if t < (mapsize * car.race.lap_count) + 10 :
		var diff=0
		for seg in range(car.current_segment+s,car.current_segment+e+1) :
			var v5 = car.race.get_vec_from_vecmap(seg)
			if v5 :
				var ta = to_pico_angle(atan2(v5.y - car.pos.y, v5.x - car.pos.x)) - car.angle
				if abs(ta) > abs(diff) :
					diff=ta
		while diff > 0.5 :
			diff = diff - 1
		while diff < -0.5 :
			diff = diff + 1
		if abs(diff) > 0.02 and rnd(50) > 40 + ai.skill :
			ai.decisions = 0
		var steer = car.steer
		var speed=car.vel.length()*14
		c.accel = abs(diff) < steer * 10
		c.right = 12*diff < -steer
		c.left = 12*diff > steer
		c.brake = speed*speed*abs(diff)/100000 > steer
		# if car == cam_car :
		#     print(string.format("%s L%d|%3d %f %.4f %.4f %s%s%s%s",
		#         car.driver.short_name,car.current_segment//mapsize+1,car.current_segment,steer,speed*speed*abs(diff)/30000,steer*3,
		#         c.accel and '^' or ' ',c.brake and 'v' or ' ',c.left and '<' or ' ',c.right and '>' or ' '))
		# end
		ai.decisions = ai.decisions - 1
	else :
		c.accel = false
		c.brake = true

class Ai :
	var decisions : float = 0.0
	var target_seg : int = 1
	var riskiness : float = 0.0
	var car : Car
	func update():
		P.update_ai(self)
	func _init(pcar : Car, pdecisions: float, priskiness: float) :
		self.car=pcar
		self.decisions = pdecisions
		self.riskiness = priskiness

static func car_update(car: Car, completed : bool, time : float) :
	var angle: float = car.angle
	var vel: Vector2 = car.vel
	var accel: float = car.accel
	var controls = car.controls
	if controls.accel :
		accel = accel + car.accsqr * 0.3
	else :
		accel = accel * 0.95
	var speed : float = vel.length()
	# accelerate
	var maxacc : float = car.maxacc
	var wear_coef : float = clamp((car.global_wear - TYRE_WEAR_THRESHOLD) / (1.0 - TYRE_WEAR_THRESHOLD),0.0,1.0)
	maxacc = maxacc - TYRE_WEAR_ACC_IMPACT * wear_coef
	var MAX_ANGLE : float=10 if speed < 7 and accel >= maxacc and (controls.left or controls.right) else 3
	var angle_speed : float = speed/5.0 if speed < 5.0 else 1.0+(MAX_ANGLE-1.0)*(speed-5.0)/5.0 if speed < 10.0 else  MAX_ANGLE-(speed-10.0)*(MAX_ANGLE-1.0)/10.0 if speed < 20.0 else 1.0
	# if car.is_player :
	#     print(string.format("acc %.1f speed %.1f aspeed %.2f",accel,speed,angle_speed))
	# end
	var steer : float = car.steer - wear_coef * TYRE_WEAR_STEER_IMPACT
	if not car.pit or car.pitstop_timer <= 0 :
		if controls.left :
			angle = angle + angle_speed * steer * 0.3
		if controls.right :
			angle = angle - angle_speed * steer * 0.3
	if car.ccut_timer >= 0 :
		car.ccut_timer = car.ccut_timer - 1
	# if tracked==null and car.is_player :
	#     print(string.format("%s %4d steer %.3f maxacc %.2f wear %.0f%%",
	#         car.driver.short_name,car.current_segment,steer,maxacc,wear_coef*100))
	# end

	# brake
	if controls.brake :
		if speed > 0.2 and speed < 1 :
			var dangle=min(0.1/speed,0.03)
			if controls.left :
				angle = angle + dangle
			elif controls.right :
				angle = angle - dangle
		var brake_speed=max(0,speed - BRAKE_COEF + wear_coef * TYRE_WEAR_BRAKE_IMPACT)
		vel = Vector2.ZERO if brake_speed == 0 else vel.normalized() * brake_speed
		speed= brake_speed
	accel = min(accel, maxacc)
	if car.is_player and not completed :
		# engine noise
		var sgear : float = pow(car.speed*14/328,0.75) * 8
		car.gear = floor(clamp(sgear,1,7))
		var rpm : float = sgear-car.gear # between 0 and 1
		car.rpm=clamp(rpm,0,1)
		var base_freq : float = 290 if car.gear == 1 else 340
		var max_freq : float = 550-base_freq  if car.controls.accel else 480-base_freq
		var freq : float = min(base_freq + max_freq * rpm, 580)
		var volume : float = 0.5 + 0.5*car.accel/car.maxacc * 0.5
		if car.freq > 0.0 :
			V.snd.set_channel_freq(1,freq)
			V.snd.set_channel_volume(1,volume)
		else :
			V.snd.play_sound(8, freq, volume, volume, 1)
		car.freq=freq

	# check collisions
	# get a width enlarged version of this segment to help prevent losing the car
	var current_segment : int = car.current_segment
	var old_segment : int = current_segment
	var v : TrackSection = car.race.get_data_from_vecmap(current_segment)
	var nextv : TrackSection = car.race.get_data_from_vecmap(current_segment + 2)
	var pos : float = (car.pos - v.pos).dot(v.side)
	var team_pit : int = TEAMS[car.driver.team].pit
	if (v.rtyp / 8) as int == OBJ_PIT_ENTRY3 and pos < -32 :
		if car.pit == 0 :
			car.race.tyre = 0
		car.pit = -team_pit
		car.race.pits[team_pit] = PitCrewData.new()
	elif (v.ltyp / 8) as int == OBJ_PIT_ENTRY3 and pos > 32 :
		if car.pit == 0:
			car.race.tyre = 0
		car.pit = team_pit
		car.race.pits[team_pit] = PitCrewData.new()
	elif (nextv.rtyp / 8) as int == OBJ_PIT_EXIT1 and pos < -32 :
		if car.pit == 0 :
			car.race.tyre = 0
		car.pit = 0
		car.pit_done = false
		car.pitstop_timer = 0
		car.race.pits[team_pit] = null
	elif (nextv.ltyp / 8) as int == OBJ_PIT_EXIT1 and pos > 32 :
		if car.pit == 0 :
			car.race.tyre = 0
		car.pit = 0
		car.pit_done = false
		car.pitstop_timer = 0
		car.race.pits[team_pit] = null
	var segpoly = get_segment(car.race, current_segment, true)
	var poly

	car.collision = 0
	if segpoly != null :
		var in_current_segment : bool = point_in_polygon(segpoly, car.pos)
		if in_current_segment :
			car.last_good_pos = car.pos
			car.last_good_seg = current_segment
			car.lost_count = 0
			poly = get_segment(car.race, current_segment, false, true)
		else :
			# not found in current segment, try the next
			var segnextpoly = get_segment(car.race, current_segment + 1, true)
			if segnextpoly and point_in_polygon(segnextpoly, car.pos) :
				poly = get_segment(car.race, current_segment + 1, false, true)
				current_segment = current_segment + 1
				if best_seg_times[current_segment] == 0.0 :
					best_seg_times[current_segment] = time
				car.seg_times[current_segment] = time
				if car.is_player :
					var track_data=car.race.get_data_from_vecmap(current_segment + 1)
					V.snd.set_channel_volume(2, track_data.ltribune, track_data.rtribune)
				if current_segment > 0 and current_segment % mapsize == 0 \
					and (car.race.mode == RaceMode.TIME_ATTACK or current_segment <= mapsize * car.race.lap_count) :
					# new lap
					var lap_time = time
					if car.race.mode == RaceMode.RACE :
						lap_time = lap_time - car.delta_time
					elif car.race.mode == RaceMode.TIME_ATTACK :
						# reset car mass and tyre wear after each lap in time attack mode
						car.mass = CAR_BASE_MASS + FUEL_MASS_PER_KM
						car.tyre_wear[1]=0
						car.tyre_wear[2]=0
						car.tyre_wear[3]=0
						car.tyre_wear[4]=0
					car.lap_times.append(lap_time)
					car.delta_time = car.delta_time + lap_time
					if best_lap_time == 0.0 or lap_time < best_lap_time :
						best_lap_time = lap_time
						car.race.best_lap_timer = 100
						if best_lap_driver != null :
							best_lap_driver.is_best = false
						best_lap_driver = car.driver
						car.driver.is_best = true
					if car.best_time == 0.0 or lap_time < car.best_time :
						car.best_time = lap_time
						car.play_replay = car.record_replay
					if car.race.is_finished :
						car.race_finished = true
				car.wrong_way = 0
			else :
				# not found in current or next, try the previous one
				var segprevpoly = get_segment(car.race, current_segment - 1, true)
				if segprevpoly and point_in_polygon(segprevpoly, car.pos) :
					poly = get_segment(car.race, current_segment - 1, false, true)
					current_segment = current_segment - 1
					car.wrong_way = car.wrong_way + 1
				else :
					# completely lost the car
					current_segment = find_segment_from_pos(car.race, car.pos, car.last_good_seg)
					if current_segment == null :
						car.lost_count = car.lost_count + 1
						# current_segment+=1 # try to find the car next frame
						if car.lost_count > 30 :
							# lost for too long, bring them back to the last known good position
							var track_data = car.race.get_data_from_vecmap(car.last_good_seg)
							car.pos = Vector2(track_data.x,track_data.y)
							car.current_segment = car.last_good_seg - 1
							current_segment = car.current_segment
							car.vel = Vector2.ZERO
							car.angle = track_data.dir
							car.wrong_way = 0
							car.accel = 1.0
							car.lost_count = 0
							car.trails = CircBuf.new(32)
							return
					else :
						poly = get_segment(car.race, current_segment, false, true)
						if current_segment - car.last_good_seg > 2 :
							car.ccut_timer = 100
		# check collisions with walls
		if poly :
			var car_poly = [car.verts[1], car.verts[2], car.verts[3] ]
			var rails
			if car.pit and car.pit < 0  :
				var p = v.right_inner_rail - v.side * 6
				var p2 = v.right_inner_rail + v.front * 33
				var width = 48 if ((v.rtyp / 8) as int == OBJ_PIT or (nextv.rtyp / 8) as int == OBJ_PIT) else 20
				var p3 = p - v.side * width
				var p4 = p2 - v.side * width
				rails = [ [ p2, p ], [ p3, p4 ] ]
			elif car.pit and car.pit > 0 :
				var p = v.left_inner_rail + v.side * 6
				var p2 = v.left_inner_rail + v.front * 33
				var width = 48 if ((v.ltyp / 8) as int == OBJ_PIT or (nextv.ltyp / 8) as int == OBJ_PIT) else 20
				var p3 = p + v.side * width
				var p4 = p2 + v.side * width
				rails = [ [  p2, p ], [ p3, p4 ] ]
			else :
				rails = [ [  poly[2], poly[3] ], [ poly[4], poly[1] ] ]
			var coll = check_collision(car_poly, rails)
			if coll.rv :
				if coll.pen > 5 :
					coll.pen = 5
				vel = vel - coll.rv * (coll.pen * COLLISION_COEF)
				accel = accel * (1.0 - (coll.pen / 10))
				create_spark(car.current_segment, coll.point, coll.rv, false)
				car.collision = car.collision + coll.pen
				if car.is_player :
					if coll.pen > 2 :
						V.snd.play_pattern(3)
					else :
						V.snd.play_pattern(4)
	if old_segment != current_segment :
		# fuel consumption
		car.mass = car.mass - FUEL_MASS_PER_KM / mapsize
		# tyre wear
		var more = car.controls.brake or car.controls.accel
		var global_wear=0
		for i in range (0,4) :
			var wear : float = 0.5
			if car.controls.brake :
				wear = 1.25 if  i<3 else 1.0
			elif car.controls.accel :
				wear = 1.0 if i<3 else 0.75
			if car.controls.left :
				wear += 0.25
				if i%2 == 1 :
					wear += 0.5
			elif car.controls.right :
				wear = 0.25
				if i%2 == 0 :
					wear += 0.5
			car.tyre_wear[i] = car.tyre_wear[i] + (1.5*wear if more else wear)
			global_wear += car.tyre_wear[i]
		car.global_wear = global_wear / (4*TYRE_LIFE[car.tyre_type])
		#print(string.format("tyres %.1f %.1f   %.1f %.1f",car.tyre_wear[1],car.tyre_wear[2],car.tyre_wear[3],car.tyre_wear[4]))

	var track_data = car.race.get_data_from_vecmap(car.current_segment)
	var sidepos : float = (car.pos - Vector2(track_data.x,track_data.y)).dot(track_data.side)
	var ground_type : int = (track_data.ltyp & 7) if sidepos > 32 else (track_data.rtyp & 7) if sidepos < -32 else 0

	var car_dir = Vector2(pico_cos(angle), pico_sin(angle))
	car.vel = vel + car_dir * (accel * CAR_BASE_MASS / car.mass)
	if ground_type == 0 or ground_type == 3 :
		# less slide on asphalt
		var no_slide = car_dir * car.vel.length()
		car.vel = car.vel.lerp(no_slide,0.12)
	car.pos = car.pos + car.vel * 0.3
	# aspiration
	var has_aspiration = false
	if car.pit == 0 and car.is_player :
		for other_car in car.race.cars :
			var seg = posmod(car.current_segment, mapsize)
			var car_seg = posmod(other_car.current_segment, mapsize)
			if other_car != car and car_seg - seg <= 3 and car_seg - seg > 0 :
				var perp = car_dir.orthogonal()
				var dist = (other_car.pos - car.pos).dot(perp)
				if abs(dist) <= 10 :
					has_aspiration = true
					break
		if has_aspiration :
			car.asp = min(3.5,car.asp + 0.1)
		else :
			car.asp = max(0,car.asp - 0.04)
	if speed > 0.1 :
		if car.pit :
			speed=min(speed,70/14) # max 70km/h in pit
		else :
			var aspiration_amount = 1-car.asp*ASPIRATION_COEF/100
			var team_perf = 1 - car.perf * TEAM_PERF_COEF / 100
			speed = speed - AIR_RESISTANCE * aspiration_amount * team_perf * (speed*speed) * 0.01
		car.vel = car.vel.normalized() * speed

	var ground_type_inner = (v.ltyp & 7) if sidepos > 36 else (v.rtyp & 7) if sidepos < -36 else 0
	if car.is_player and speed > 1 and frame % floor(60 / speed) == 0 :
		if (v.has_lkerb and sidepos <= 36 and sidepos >= 24) \
			or (v.has_rkerb and sidepos >= -36 and sidepos <= -24) :
			# on kerbs
			V.snd.play_pattern(2)
	if ground_type == 1 :
		#grass
		var r = rnd(10)
		if r < 4 and ground_type_inner == 1 :
			car.vel = car.vel * 0.95
			var angle_vel_impact : float = min(5.0, speed) / 5.0
			var da : float = (rnd(40)-20.0) * angle_vel_impact
			angle = fposmod(angle, 1.0) * (1000 + da) / 1000
		if r < speed :
			create_spark(car.current_segment, car.pos, car.vel.normalized() * 0.3, true)
	elif ground_type == 2 :
		# sand
		if ground_type_inner == 2 :
			car.vel *= 0.95
			angle += (car.angle - angle) * 0.5
		if speed > 2 :
			create_smoke(current_segment, car.pos - car.vel * 0.5, car.vel, 4)
	if car.ccut_timer >= 0 :
		car.vel = car.vel * 0.97
	for i in range(0,car.car_verts.size()) :
		car.verts[i] = rotate_point(car.pos + car.car_verts[i], angle, car.pos)

	if car.is_player :
		car.trails.push(rotate_point(car.pos + TRAIL_OFFSET, angle, car.pos))
		car.screech = max(0,car.screech-0.05)

	# update car attrs
	car.accel = accel
	car.speed = speed # used for showing speedo
	car.angle = angle
	car.current_segment = current_segment
	if abs(current_segment - cam_car.current_segment) < 10 :
		var spawn_pos = car.pos - car.vel * 0.5
		if car.pit == 0 :
			var caccel = accel / CARS[car.race.difficulty].maxacc
			if (car.ccut_timer < 0 and speed > 1 and caccel / speed > 0.07) or (controls.brake and speed < 9 and speed > 2) :
				var col = 3 if ground_type == 1 else 4 if ground_type == 2 else 22
				create_smoke(current_segment, spawn_pos, car.vel, col)
				if car.is_player and (ground_type==0 or ground_type==4) :
					car.screech = min(0.6,car.screech + 0.075)
		if speed > 25 and ground_type == 0 and rnd(10) < 4 :
			create_spark(current_segment, spawn_pos, car.vel.normalized() * 0.8, false)
	if car.current_segment >= mapsize * car.race.lap_count :
		car.race_finished = true
		car.race.is_finished = true
	if car.is_player :
		V.snd.set_channel_volume(3,car.screech)
	if car.pit != 0:
		if car.is_player :
			if car.pitstop_timer== 0 :
				camera_scale=lerp_pico_angle(camera_scale,0.5,0.05)
		# pit stop
		var pit_seg=2*(car.driver.team-1) + car.race.first_pit
		if pit_seg > mapsize :
			pit_seg -= mapsize
		var cur_seg= car.current_segment -((car.current_segment/mapsize) as int)*mapsize
		print("pos %.0f %.0f firstpit %d pitseg %d curseg %d" % [car.pos.x,car.pos.y,car.race.first_pit,pit_seg,cur_seg])
		if not car.pit_done \
			and car.pitstop_timer == 0 :
			var track_data2=car.race.get_data_from_vecmap(pit_seg)
			var vpit = Vector2(track_data2.x,track_data2.y) - (track_data2.side * 80) - track_data2.front *10
			var dist = car.pos - vpit
			var dy = dist.dot(track_data2.front)
			var dx = dist.dot(track_data2.side)
			print("%.0f %.0f",[dx,dy])
			if dy >= -10 and dy < -5 :
				# car approach
				var coef=-(dy+10)/5*dx
				car.race.pits[car.driver.team].front=Vector2(coef,0)
				car.race.pits[car.driver.team].fr=Vector2(coef,0)
				car.race.pits[car.driver.team].fl=Vector2(coef,0)
				car.race.pits[car.driver.team].rr=Vector2(coef,0)
				car.race.pits[car.driver.team].rl=Vector2(coef,0)
				# fix car orientation
				car.angle = lerp_pico_angle(car.angle, -1, 0.1)
			elif dy >= -5 and dy <= 0 :
				# fix car orientation
				car.angle = lerp_pico_angle(car.angle, -1, 0.3)

				# final approach : crew track x position
				var coef=-2*(dy+5)/5
				car.race.pits[car.driver.team].front=Vector2(-dx,0)
				car.race.pits[car.driver.team].fr=Vector2(coef-dx,0)
				car.race.pits[car.driver.team].fl=Vector2(-dx-coef,0)
				car.race.pits[car.driver.team].rr=Vector2(coef-dx,0)
				car.race.pits[car.driver.team].rl=Vector2(-dx-coef,0)
			if abs(dx) <= 4 and abs(dy) <= 2 :
				car.pitstop_timer = 3.0 + pow(rnd(),2.0) * 5.0
				car.pitstop_delay = car.pitstop_timer
				V.snd.play_sound(11,440,1) #wheel gun
		if car.pitstop_timer > 0 :
			car.vel=Vector2.ZERO
			car.accel = 0
			car.pitstop_timer -= DT
			if car.pitstop_timer <= 0.5 :
				if car.pitstop_timer+DT > 0.5 :
					V.snd.play_sound(11,440,1) #second wheel gun
				# anticipate frontman's depart
				var frontman = car.race.pits[car.driver.team].front
				frontman.x = frontman.x +0.2
				frontman.y = car.pitstop_timer-0.5
			if car.pitstop_timer <= 0 :
				# put some fresh tyres
				car.pit_done=true
				car.tyre_type = car.race.tyre+1
				var heat = -TYRE_HEAT[car.tyre_type+1]
				car.tyre_wear[0] = heat
				car.tyre_wear[1] = heat
				car.tyre_wear[2] = heat
				car.tyre_wear[3] = heat
		elif car.pit_done :
			car.pitstop_timer -= DT
			# move the front man away
			var frontman = car.race.pits[car.driver.team].front
			frontman.x=min(10,frontman.x + 0.3)
			frontman.y = max(-3,frontman.y - 0.1)
			if car.pitstop_timer > -0.7 :
				car.race.pits[car.driver.team].fr.x=car.race.pits[car.driver.team].fr.x+0.15
				car.race.pits[car.driver.team].rr.x=car.race.pits[car.driver.team].rr.x+0.1
				car.race.pits[car.driver.team].fl.x=car.race.pits[car.driver.team].fl.x-0.15
				car.race.pits[car.driver.team].rl.x=car.race.pits[car.driver.team].rl.x-0.1
			if car.pitstop_timer > -1.0 :
				# help the player exit the pit
				car.angle = lerp_pico_angle(car.angle, -0.92, 0.2 * pow(-car.pitstop_timer,3.0))

static func car_draw_minimap(car:Car, pcam_car: Car) :
	var seg = car_lap_seg(car.current_segment, pcam_car)
	var pseg = pcam_car.current_segment
	if seg >= pseg + MINIMAP_START and seg < pseg + MINIMAP_END :
		minimap_circle(car.pos, car.color)

static func car_draw(car: Car) :
	if car.verts.is_empty() :
		# happens only before race start, when cars are drawn but not updated
		for vertex in car.car_verts :
			car.verts.append(rotate_point(car.pos + vertex, car.angle, car.pos))
	var color = car.color
	var v = car.verts
	linevec(v[5], v[6], 18) # front suspension
	quadfill(v[7], v[8], v[9], v[11], color) # front wing
	trifill(v[22],v[23],v[24],color, true) # hull
	quadfill(v[25],v[26],v[27],v[29],color) # hull
	trifill(v[12], v[13], v[14], car.color2, true)
	trifill(v[15], v[16], v[17], car.color2, true)
	draw_tyres(v[3], v[4], v[5], v[7], 0)
	circfill(v[11].x, v[11].y, 1, car.driver.helmet)
	quadfill(v[18], v[19], v[20], v[21], color) # rear wing
	# shadow
	var sd = SHADOW_DELTA * 0.075
	var sv = []
	for i in range(0, v.size()) :
		sv.append(v[i] + sd)
	V.gfx.set_active_layer(LAYER_SHADOW)
	linevec(sv[5], sv[6], 22)
	quadfill(sv[7], sv[8], sv[9], sv[10], 22)
	trifill(sv[22],sv[23],sv[24],22, true)
	quadfill(sv[25],sv[26],sv[27],sv[28],22)
	draw_tyres(sv[3], sv[4], sv[5], sv[6], 22)
	quadfill(sv[18], sv[19], sv[20], sv[21], 22)
	V.gfx.set_active_layer(LAYER_SHADOW2)
	trifill(v[11],midpoint(v[18],v[19]), sv[11],22, true)
	V.gfx.set_active_layer(LAYER_CARS)

static func car_draw_trails(car: Car) :
	# trails
	var lastp
	for i in range (0, car.trails._size) :
		var p = car.trails.get_at(-i)
		if not p :
			break
		if lastp :
			linevec(lastp, p, 7 if i > car.trails._size - 4 else 1 if i < 12 else 12)
		lastp = p

class Controls:
	var left: bool
	var right: bool
	var brake: bool
	var accel: bool

class Car:
	var race : Race
	var is_player: bool = false
	## position in the race
	var rank : int
	var gear: int
	var rpm : float
	var screech: float = 0.0
	var pos: Vector2
	var vel : Vector2 = Vector2.ZERO
	var angle : float = 0.0
	var trails : CircBuf
	var current_segment : int = -1
	var cooldown : int = 0
	var wrong_way : int = 0
	var speed : float = 0.0
	var accel : float = 0.0
	# aspiration
	var asp : float = 0.0
	var pitstop_timer : float = 0.0
	var accsqr : float
	var steer : float = 0.0
	var maxacc : float
	var lost_count : int = 0
	var last_good_pos : Vector2 = Vector2.ZERO
	var last_good_seg : int = 1
	var color : int = 8
	var color2 : int = 24
	var collision : float = 0.0
	var delta_time : float = 0.0
	var lap_times: Array[float] = []
	var time : String = "##-"
	var best_time : float = 0.0
	var verts: Array[Vector2] = [] # TODO Packed ?
	var seg_times : Array[float] = []
	var ccut_timer : int = -1
	var mass : float = CAR_BASE_MASS
	var tyre_type : int = 2 # TODO : use enum
	var tyre_wear : Array[float] = []
	var global_wear: float = 0.0
	## engine rpm fx frequency
	var freq : float = 0.0
	var pit : int = 0
	var pit_done : bool = false
	var controls: Controls
	func update(completed : bool, ptime : float):
		P.car_update(self, completed, ptime)
	func draw_minimap(cam_car: Car):
		P.car_draw_minimap(self, cam_car)
	func draw():
		P.car_draw(self)

static func ai_update(ai_car: AiCar, completed : bool, time : float):
	ai_car.ai.update.call(ai_car.ai)
	car_update(ai_car, completed, time)

class AiCar extends Car :
	var ai : Ai
	func update(completed : bool, ptime : float):
		P.ai_update(self, completed, ptime)

static func create_car(race, is_ai: bool = false) :
	var car_template = CARS[race.difficulty]
	var tyre_type = randi_range(0,1) # soft or medium
	var tyre_heat = TYRE_HEAT[tyre_type] if race.mode == RaceMode.RACE else 0
	var car = AiCar.new() if is_ai else Car.new()
	car.race = race
	car.trails = CircBuf.new(32)
	car.current_segment = -1 if race.mode == RaceMode.RACE else -5
	car.accsqr = car_template.accsqr
	car.steer = car_template.steer
	car.maxacc = car_template.maxacc
	car.tyre_type=tyre_type # 1 = soft 2=medium 3=hard 4=inter 5=wet
	for i in range(0,4):
		car.tyre_wear.append(tyre_heat) # all tyres start cold
	car.controls = Controls.new()
	car.pos = Vector2(race.get_vec_from_vecmap(car.current_segment))
	return car

static func set_game_mode(m) :
	game_mode = m

static var car_verts : Array[Vector2]

static func init() :
	car_verts = [ Vector2( -9, -2.5), Vector2(7, 0), Vector2( -9, 2.6), # collision shape
		Vector2( -7, -3), Vector2(-7, 3), Vector2(3, -3), Vector2(3, 3), # tires positions
		Vector2(5, -2.5), Vector2(5, 2.6), Vector2(7, -2.5), Vector2(7, 2.6), # front wing
		Vector2(-1, 0), # pilot helmet position
		Vector2( -3, -2.5), Vector2(-7, -3), Vector2( -9, 0), Vector2( -7, 3), Vector2(-3, 2.6), Vector2( -9, 0), # second color
		Vector2( -9, -2.5), Vector2( -9, 2.5), Vector2( -11, -2.5), Vector2( -11, 2.5), # rear wing
		Vector2(-3,-2.5),Vector2(7,0),Vector2(-3,2.6),Vector2(-3,-2.5),Vector2( -9, -3),Vector2(-3,2.6),Vector2(-9, 3) # hull
	]
	for car_vert in car_verts :
		car_vert.x *= 0.8
		car_vert *= 0.8
	# compute tracks length in km
	var track_id=0
	for data in TRACK_DATA :
		data.length = TRACKS[track_id].size() * 15.8
		track_id += 1
	for sfx in SFX :
		V.snd.new_pattern(sfx)
	V.snd.reserve_channel(1) # reserved for engine sound
	V.snd.reserve_channel(2) # reserved for tribunes
	V.snd.reserve_channel(3) # reserved for tyre screech
	V.snd.new_instrument(INST_TRIANGLE)
	V.snd.new_instrument(INST_TILTED)
	V.snd.new_instrument(INST_SAW)
	V.snd.new_instrument(INST_SQUARE)
	V.snd.new_instrument(INST_PULSE)
	V.snd.new_instrument(INST_ORGAN)
	V.snd.new_instrument(INST_NOISE)
	V.snd.new_instrument(INST_PHASER)
	V.snd.new_instrument(INST_ENGINE)
	V.snd.new_instrument(INST_TRIBUNE)
	V.snd.new_instrument(INST_TYRE)
	V.snd.new_instrument(INST_PIT)
	V.gfx.set_spritesheet(await V.gfx.load_img("pitstop_spr.png"))
	V.gfx.show_layer(LAYER_SMOKE) # smoke fx
	V.gfx.set_layer_operation(LAYER_SMOKE, V.gfx.LAYEROP_ADD)
	V.gfx.show_layer(LAYER_SHADOW) # shadow
	V.gfx.set_layer_operation(LAYER_SHADOW, V.gfx.LAYEROP_MULTIPLY)
	V.gfx.show_layer(LAYER_CARS)
	V.gfx.show_layer(LAYER_SHADOW2) # shadow
	V.gfx.set_layer_operation(LAYER_SHADOW2, V.gfx.LAYEROP_MULTIPLY)
	V.gfx.show_layer(LAYER_TOP) # roofs & ui
	V.gfx.show_mouse_cursor(false)
	intro.init.call()
	set_game_mode(intro)
	# TODO db API
#	quick_race_conf=load_table("pitstop.db","quick_race_conf")
#	if quick_race_conf == null :
#		print("NO QUICK RACE CONF")
#		quick_race_conf = DEFAULT_QUICK_RACE_CONF
#		save_table("pitstop.db","quick_race_conf", quick_race_conf)
#	else :
	print("QUICK RACE CONF : %d" % quick_race_conf.lap_count)

static func draw() :
	game_mode.draw.call(game_mode)

static func update() :
	# original game updates at 30fps, viper is 60fps
	# update only every 2 ticks
	flipflop = not flipflop
	# : not lose press events
	mlb_pressed = (flipflop and mlb_pressed) or V.inp.mouse_button(V.inp.MOUSE_LEFT)
	if flipflop or game_mode.get("mode") == null :
		game_mode.update.call(game_mode)
		mlb_pressed = false

# intro
class IntroMenu :
	var init = func():
		# music(0)
		P.camera_angle = 0.25
	var update = func(_o) :
		P.frame += 1
		P.update_menu()
	func draw(_o) :
		P.cls()
		V.gfx.blit_region(Vector2.ZERO, Vector2(0, 106), Vector2(224, 118), Color.WHITE, 0.0, 
			Vector2(V.gfx.SCREEN_WIDTH,V.gfx.SCREEN_HEIGHT))
		V.gfx.blit_region(Vector2(80, 10), Vector2(0, 62), Vector2(224, 44))
		P.draw_menu(P.cur_menu)

static var intro = IntroMenu.new()

enum RaceMode {RACE, TIME_ATTACK, EDITOR, QUICK_RACE}

const MAIN_MENU = [
	{name="Quick Race", mode=RaceMode.QUICK_RACE},
	{name="Practise any Circuit", mode=RaceMode.TIME_ATTACK},
	{name="Non-Championship Race", mode=RaceMode.RACE},
	{name="Championship Season",mode=RaceMode.RACE},
	{name="Game Option Menu"},
	{name="Track Editor",mode=RaceMode.EDITOR},
	{name="Driver/Team Selection"},
]

static var cur_menu=MAIN_MENU
static var cur_menu_item=0

static func draw_menu(menu) :
	var y=74
	geoff_frame(G_MENU_X-8,y,G_MENU_W+16,12+16*menu.size())
	y=y+7
	for i in range(0,menu.size()) :
		geoff_menu_item(menu[i].name, y, i == cur_menu_item)
		y=y+16

static func update_menu() :
	if V.inp.down_pressed() :
		cur_menu_item = (cur_menu_item +1) % cur_menu.size()
	elif V.inp.up_pressed() :
		cur_menu_item = (cur_menu_item + cur_menu.size()-1) % cur_menu.size()
	if V.inp.action1_pressed() :
		var mode : RaceMode = cur_menu[cur_menu_item].mode
		var track_num=0
		var lap_count=5
		var difficulty=2
		if mode == RaceMode.EDITOR :
			mapeditor.init_track(track_num)
			set_game_mode(mapeditor)
		elif mode == RaceMode.RACE or mode == RaceMode.TIME_ATTACK or mode == RaceMode.QUICK_RACE :
			var race = Race.new()
			if mode == RaceMode.QUICK_RACE :
				track_num = quick_race_conf.track
				lap_count = quick_race_conf.lap_count
				difficulty = quick_race_conf.difficulty
				mode = RaceMode.RACE
			race.init_race(track_num, mode, lap_count, difficulty)
			set_game_mode(race)

static var mapsections: Array

static func mapeditor_init(ed:MapEditor, track_num) :
	ed.scale = 0.05
	cam_pos=Vector2.ZERO
	ed.sec = mapsections.size()
	V.gfx.show_mouse_cursor(true)
	ed.race = Race.new()
	ed.race.init(1, RaceMode.EDITOR, 1, 1)
	camera_angle = 0.25
	ed.display = 0
	ed.track_num = track_num
	load_map(track_num)

static func map_editor_update(ed:MapEditor) :
	var cs = mapsections[ed.sec]
	var mouse_pos = V.inp.mouse_pos()
	var mx=mouse_pos.x
	var my=mouse_pos.y
	if ed.display == 1 :
		cam_pos = cam_pos + (cam_target_pos - cam_pos) * 0.2
	if V.inp.mouse_button(V.inp.MOUSE_LEFT) :
		if not ed.drag :
			ed.drag = true
			ed.mousex = mx
			ed.mousey = my
			ed.mdragx = 0
			ed.mdragy = 0
		else :
			ed.mdragx = mx - ed.mousex
			ed.mdragy = my - ed.mousey
	elif ed.drag :
		ed.mouseoffx = ed.mouseoffx + ed.mdragx
		ed.mouseoffy = ed.mouseoffy + ed.mdragy
		ed.mdragx = 0
		ed.mdragy = 0
		ed.drag = false
	if mlb_pressed :
		if inside_rect(mx, my, V.gfx.SCREEN_WIDTH / 2 - 32, 19, 16, 16) :
			# change left terrain type
			var ltyp = cs[4] & 7
			ltyp = (ltyp + 1) % 4
			cs[4] = (cs[4] & ( ~7)) + ltyp
			ed.race.generate_track()
		elif inside_rect(mx, my, V.gfx.SCREEN_WIDTH / 2 + 16, 19, 16, 16) :
			# change right terrain type
			var ltyp = cs[5] & 7
			ltyp = (ltyp + 1) % 4
			cs[5] = (cs[5] & ( ~7)) + ltyp
			ed.race.generate_track()
		elif inside_rect(mx, my, V.gfx.SCREEN_WIDTH - 150, 19, 32, 8) :
			# change left object type
			var lobj = (cs[4] / 8) as int
			lobj = (lobj + 1) % OBJ_COUNT
			# while lobj >= OBJ_PIT_LINE_START :
			#     lobj = (lobj + 1) % OBJ_COUNT
			# end
			cs[4] = (cs[4] & 7) + lobj * 8
			ed.race.generate_track()
		elif inside_rect(mx, my, V.gfx.SCREEN_WIDTH - 150, 28, 32, 8) :
			# change right object type
			var robj = (cs[5] / 8) as int
			robj = (robj + 1) % OBJ_COUNT
			# while robj >= OBJ_PIT_LINE_START or robj == OBJ_BRIDGE or robj == OBJ_BRIDGE2 :
			#     robj = (robj + 1) % OBJ_COUNT
			# end
			cs[5] = (cs[5] & 7) + robj * 8
			ed.race.generate_track()
	# left/right : change section curve
	if V.inp.right_pressed() :
		cs[2] = cs[2] - (0.1 if V.inp.key(V.inp.KEY_LSHIFT) else 1.0)
		ed.race.generate_track()
	elif V.inp.left_pressed() :
		cs[2] = cs[2] + (0.1 if V.inp.key(V.inp.KEY_LSHIFT) else 1.0)
		ed.race.generate_track()
		# up/down : change section length
	elif V.inp.up_pressed() :
		cs[1] = cs[1] + 1
		ed.race.generate_track()
	elif V.inp.down_pressed() :
		cs[1] = cs[1] - 1
		ed.race.generate_track()
		# action2 : delete last section
	elif V.inp.action2_pressed() :
		if ed.sec > 1 :
			if ed.sec == mapsections.size()-1 :
				mapsections.append(null)
			else:
				mapsections.remove_at(ed.sec)
			ed.sec -= 1
			ed.race.generate_track()
		# action1 : duplicate last section
	elif V.inp.action1_pressed() :
		ed.sec = mapsections.size()
		mapsections.append([ cs[0], cs[1], cs[2], 0, 0, 0, 0 ])
		ed.race.generate_track()
		# pageup/pagedown : change section width
	elif V.inp.key_pressed(V.inp.KEY_PAGEDOWN) :
		cs[2] -= 1
		ed.race.generate_track()
	elif V.inp.key_pressed(V.inp.KEY_PAGEUP) :
		cs[2] += 1
		ed.race.generate_track()
		# NUMPAD +/- : zoom
	elif V.inp.key_pressed(V.inp.KEY_NUMPADMINUS) :
		if ed.display == 0 :
			ed.scale *= 0.9
		else :
			camera_scale *= 0.9
	elif V.inp.key_pressed(V.inp.KEY_NUMPADPLUS) :
		if ed.display == 0 :
			ed.scale *= 1.1
		else :
			camera_scale *= 1.1
	elif V.inp.key_pressed(V.inp.KEY_HOME) :
		ed.sec = (ed.sec + mapsections.size()-1) % mapsections.size()
		var seg = ed.race.get_segment_from_section(ed.sec)
		ed.race.player.pos = ed.race.get_vec_from_vecmap(seg)
		ed.race.player.current_segment = seg
		if ed.display == 1 :
			cam_target_pos = ed.race.player.pos
	elif V.inp.key_pressed(V.inp.KEY_END) :
		ed.sec = (ed.sec + 1) % mapsections.size()
		var seg = ed.race.get_segment_from_section(ed.sec)
		ed.race.player.pos = ed.race.get_vec_from_vecmap(seg)
		ed.race.player.current_segment = seg
		if ed.display == 1 :
			cam_target_pos = ed.race.player.pos
	elif V.inp.key_pressed(V.inp.KEY_ESCAPE) :
		# test map todo: open menu
		set_game_mode(MapMenu.new(ed))
		return
	elif V.inp.key_pressed(V.inp.KEY_TAB) :
		ed.display = 1 - ed.display
		if ed.display == 0 :
			camera_scale = 1
			minimap_offset = MINIMAP_RACE_OFFSET
			cam_pos = Vector2.ZERO
		else :
			camera_scale = 0.2
			minimap_offset = MINIMAP_EDITOR_OFFSET
			var seg = ed.race.get_segment_from_section(ed.sec)
			ed.race.player.pos = ed.race.get_vec_from_vecmap(seg)
			ed.race.player.current_segment = seg
			cam_pos = ed.race.player.pos
			cam_target_pos = cam_pos

static func mapeditor_draw(ed:MapEditor) :
	cls()
	var seg_range
	if ed.display == 0 :
		var sec_pos = draw_editor_minimap(ed.mapoffx + ed.mouseoffx + ed.mdragx - 65,
			ed.mapoffy - 20 + ed.mouseoffy + ed.mdragy, ed.scale, 6, ed.sec)
		ed.mapoffx = -sec_pos.x
		ed.mapoffy = -sec_pos.y
	else :
		var back = cam_pos
		cam_pos = cam_pos - Vector2(ed.mouseoffx, ed.mouseoffy) - Vector2(ed.mdragx, ed.mdragy)
		seg_range = ed.race.draw.call(ed.race)
		cam_pos = back
	if seg_range != null :
		printc("sec %d/%d seg %d-%d" % [ed.sec,mapsections.size(),seg_range.x,seg_range.y], V.gfx.SCREEN_WIDTH / 2, 1, 7)
	else:
		printc("sec %d/%d" % [ed.sec,mapsections.size()], V.gfx.SCREEN_WIDTH / 2, 1, 7)
	var sec = mapsections[ed.sec]
	var sec_len = sec[0]
	var sec_dir = sec[1]
	var sec_width = sec[2]
	var ltyp = sec[3] & 3
	var rtyp = sec[4] & 3
	var cols = [21, 27, 15, 5 ]
	var lcol = PAL[cols[ltyp + 1]]
	var rcol = PAL[cols[rtyp + 1]]
	var lobj = (sec[3] / 8) as int
	var robj = (sec[4] / 8) as int
	var lrail = sec[5]
	var rrail = sec[6]
	var objs = [ "", "tribune1", "tribune2", "tree", "bridge", "bridge2", "pit", "pit line", "pit start", "pit end", "pit ent1", "pit ent2", "pit ent3", "pit ex1", "pit ex2", "pit ex3" ]
	printc("len %d dir %d w %d" % [sec_len, sec_dir, sec_width], V.gfx.SCREEN_WIDTH / 2, 10, 7)
	printr("rail l %d r %d" % [lrail, rrail], V.gfx.SCREEN_WIDTH - 1, 10, 7)
	var mouse_pos = V.inp.mouse_pos()
	var mx = mouse_pos.x
	var my = mouse_pos.y
	gprint("lobj %s" % objs[lobj], V.gfx.SCREEN_WIDTH - 150, 19, 10 if inside_rect(mx, my, V.gfx.SCREEN_WIDTH - 150, 19, 32, 8) else 7)
	gprint("robj %s" % objs[robj], V.gfx.SCREEN_WIDTH - 150, 28, 10 if inside_rect(mx, my, V.gfx.SCREEN_WIDTH - 150, 28, 32, 8) else 7)

	V.gfx.rectangle(Rect2(V.gfx.SCREEN_WIDTH / 2 - 32, 19, 16, 16), lcol)
	rect(V.gfx.SCREEN_WIDTH / 2 - 32, 19, 16, 16, inside_rect(mx, my, V.gfx.SCREEN_WIDTH / 2 - 32, 19, 16, 16) and 10 or 7)
	V.gfx.rectangle(Rect2(V.gfx.SCREEN_WIDTH / 2 + 16, 19, 16, 16), rcol)
	rect(V.gfx.SCREEN_WIDTH / 2 + 16, 19, 16, 16, inside_rect(mx, my, V.gfx.SCREEN_WIDTH / 2 + 16, 19, 16, 16) and 10 or 7)
	var y = 3
	if ed.display == 0 :
		V.gfx.blit_region(Vector2(17, y), Vector2(162, 8), Vector2(12, 12))
		gprint("  delete", 17, y + 2, 7)
		y = y + 12
		V.gfx.blit_region(Vector2(17, y), Vector2(174, 8), Vector2(12, 12))
		gprint("  add", 17, y + 2, 7)
		y = y + 12
		V.gfx.blit_region(Vector2(5, y), Vector2(66, 8), Vector2(24, 12))
		gprint("    length", 1, y + 2, 7)
		y = y + 12
		V.gfx.blit_region(Vector2(5, y), Vector2(90, 8), Vector2(24, 12))
		gprint("    curve", 1, y + 2, 7)
		y = y + 12
		V.gfx.blit_region(Vector2(5, y), Vector2(138, 8), Vector2(24, 12))
		gprint("    zoom", 1, y + 2, 7)
		y = y + 12
		V.gfx.blit_region(Vector2(5, y), Vector2(114, 8), Vector2(24, 12))
		gprint("    width", 1, y + 2, 7)
		y = y + 12
	V.gfx.blit_region(Vector2(5, y), Vector2(186, 8), Vector2(24, 12))
	gprint("    section", 1, y + 2, 7)
	y = y + 12
	V.gfx.blit_region(Vector2(17, y), Vector2(54, 8), Vector2(12, 12))
	gprint("  menu", 17, y + 2, 7)
	y = y + 12
	V.gfx.blit_region(Vector2(17, y), Vector2(210, 8), Vector2(12, 12))
	gprint("  display", 17, y + 2, 7)

class MapEditor extends GameMode :
	var sec : int = 0
	var mapoffx : float = 0.0
	var mapoffy : float = 0.0
	var mousex : float = 0.0
	var mousey : float = 0.0
	var drag:bool = false
	var mouseoffx : float = 0.0
	var mouseoffy : float = 0.0
	var mdragx : float = 0.0
	var mdragy : float = 0.0   
	var scale : float = 1.0
	func init_track(track_num: int) :
		P.mapeditor_init(self, track_num)
	func update():
		P.mapeditor_update(self)
	func draw():
		P.mapeditor_draw(self)
				
static var mapeditor = MapEditor.new()

static func mapmenu_update(menu: MapMenu):
	frame += 1
	if V.inp.up_pressed() :
		menu.selected -= 1
	if V.inp.down_pressed() :
		menu.selected += 1
	menu.selected = max(min(menu.selected, 3), 1)
	if V.inp.action1_pressed() :
		if menu.selected == 1 :
			set_game_mode(menu.game)
		elif menu.selected == 2 :
			camera_scale = 1
			minimap_offset = MINIMAP_RACE_OFFSET
			print("1337,")
			for ms in menu.mapsections :
				print("%d,%d,%d,%d,%d,%d",ms[0],ms[1], ms[2], ms[3],ms[4],ms[5],ms[6])
			print("0,0,0,0,0,0,0")
			var race = Race.new()
			race.init.call(race,menu.game.track_num, 2, 1, 1)
			V.gfx.show_mouse_cursor(false)
			set_game_mode(race)
			return
		elif menu.selected == 3 :
			camera_scale = 1
			minimap_offset = MINIMAP_RACE_OFFSET
			camera_angle = 0.25
			V.gfx.show_mouse_cursor(false)
			set_game_mode(intro)

static func mapmenu_draw(menu: MapMenu):
	menu.game.draw.call(menu.game)
	rectfill(115, 40, 223, 98, 1)
	gprint("Editor", 120, 44, 7)
	gprint("Continue", 120, 56, 7 if menu.selected == 1 and frame % 4 < 2 else 6)
	gprint("Test track", 120, 68, 7 if menu.selected == 2 and frame % 4 < 2 else 6)
	gprint("Exit", 120, 80, 7 if menu.selected == 3 and frame % 4 < 2 else 6)


class MapMenu extends GameMode:
	var selected : int = -1
	var game: GameMode
	func _init(pgame: GameMode):
		self.game=pgame
	func update():
		P.mapmenu_update(self)
	func draw():
		P.mapmenu_draw(self)

static func compute_minimap_offset(scale: float) -> Vector2 :
	var x : float = 0.0
	var y : float = 0.0
	var minx : float = 0.0
	var miny : float = 0.0
	var dir: float = 0.0
	for ms in mapsections :
		for seg in range(0,ms[0]) :
			dir = dir + (ms[1] - 128) / 100.0
			x = x + pico_cos(dir) * 28 * scale
			y = y + pico_sin(dir) * 28 * scale
			minx = min(minx, x)
			miny = min(miny, y)
	return Vector2(minx, miny)

static func draw_intro_minimap(sx : float, sy: float, scale : float, col : int) :
	var offset : Vector2 = compute_minimap_offset(scale)
	var dx = sx - offset.x
	var dy = sy - offset.y
	var x : float = 0.0
	var y : float = 0.0
	var lastx = x
	var lasty = y
	var dir  : float = 0.0
	var i : int = 0
	for ms in mapsections :
		var last_section : bool = i == mapsections.size()
		for seg in range(0,ms[0]) :
			dir = dir + (ms[1] - 128) / 100.0
			x = x + pico_cos(dir) * 28 * scale
			y = y + pico_sin(dir) * 28 * scale
			if last_section :
				var coef = seg / ms[0]
				x = (1 - coef) * x
				y = (1 - coef) * y
			line(lastx + dx, lasty + dy, x + dx, y + dy, 3 if last_section else col)
			lastx = x
			lasty = y
		i+=1

static func draw_editor_minimap(sx : float, sy : float, scale : float, col : int, sec : int) -> Vector2 :
	var offset : Vector2 = compute_minimap_offset(scale)
	var dx = sx - offset.x
	var dy = sy - offset.y
	var x : float = 0.0
	var y : float = 0.0
	var lastx = x
	var lasty = y
	var dir : float = 0.0
	var sec_x : float = 0.0
	var sec_y : float = 0.0
	var i : int = 0
	for ms in mapsections :
		var highlighted : bool = i == sec
		var last_section : bool = i == mapsections.size()
		for seg in range(0,ms[0]) :
			dir = dir + (ms[1] - 128) / 100.0
			x = x + pico_cos(dir) * 28 * scale
			y = y + pico_sin(dir) * 28 * scale
			line(lastx + dx, lasty + dy, x + dx, y + dy, 9 if highlighted else 3 if last_section else col)
			lastx = x
			lasty = y
		if highlighted :
			sec_x = x
			sec_y = y
		i+=1
	return Vector2(sec_x, sec_y)


static func load_map(track_num) :
	var start = 1
	mapsections = []
	while true :
		var ms = []
		ms.append(TRACKS[track_num][start])
		ms.append(TRACKS[track_num][start + 1])
		ms.append(TRACKS[track_num][start + 2])
		ms.append(TRACKS[track_num][start + 3])
		ms.append(TRACKS[track_num][start + 4])
		ms.append(TRACKS[track_num][start + 5])
		ms.append(TRACKS[track_num][start + 6])
		if ms[0] == 0 :
			break
		mapsections.append(ms)
		start += DATA_PER_SECTION
	if mapsections.is_empty() :
		mapsections.append( [10, 128, 32, 0, 0, 0, 0 ])

class TreeSprite:
	var typ: int
	var p: Vector2
	func _init(ptyp:int, pp:Vector2):
		self.typ=ptyp
		self.p=pp

class TrackSection:
	var pos : Vector2
	## vector pointing in the track main direction
	var front: Vector2
	## vector pointing to the right of the track
	var side: Vector2
	## left track border including kerbs
	var left_track: Vector2
	## right track border including kerbs
	var right_track: Vector2
	## amount of tribune noise on the left
	var ltribune: float
	## remaining sound from previous sections
	var forward_ltribune : float = 0.0
	## amount of tribune noise on the right
	var rtribune: float
	## remaining sound from previous sections
	var forward_rtribune : float = 0.0
	## kerb on right side ? 0 = none 1 = normal, 2 = short
	var has_rkerb : int
	## right kerb position
	var right_kerb : Vector2
	## kerb on left side ? 0 = none 1 = normal, 2 = short
	var has_lkerb : int
	## left kerb position
	var left_kerb : Vector2
	## if there a sign announcing a left corner? 0 = none 1,2,3 = 50, 100, 150m
	var lpanel : int = 0
	## if there a sign announcing a right corner? 0 = none 1,2,3 = 50, 100, 150m
	var rpanel : int = 0
	## position of left inner rail
	var left_inner_rail : Vector2
	## position of left outer rail
	var left_outer_rail: Vector2
	## position of right inner rail
	var right_inner_rail : Vector2
	## position of right outer rail
	var right_outer_rail : Vector2
	var w : int
	var dir : float
	var ltyp : int
	var rtyp : int
	var has_lrail : bool
	var has_rrail : bool
	var section : int
	var segment_length : int
	var ltrees: Array[TreeSprite]
	var rtrees: Array[TreeSprite]

static func race_generate_track(race: Race):
	race.vecmap.clear()
	var dir = 0
	var mx = 0
	var my = 0
	var lastdir = 0

	randomize()
	# generate map
	var i: int = 0
	for ms in mapsections :
		var last_section : bool = i == mapsections.size()
		# read length,curve,width from tiledata
		var length = ms[0]
		var curve = ms[1]
		var width = ms[2]
		var ltyp = ms[3]
		var rtyp = ms[4]
		var lskiprail_first = max(0, ms[5])
		var rskiprail_first = max(0, ms[6])
		var lskiprail_last = max(0, -ms[5])
		var rskiprail_last = max(0, -ms[6])
		var segment_length
		if length == 0 :
			break
		if last_section :
			# fine tune curve to join smoothly the first and last segment
			var bestcurve = 0
			var mindist = 1000
			for curve_dt in range(-90, 91) :
				var newcurve = curve + curve_dt / 100.0
				var l : float = length
				var d : float = dir
				var ld = lastdir
				var nmx : float = mx
				var nmy : float = my
				while l > 0 :
					d = d + (newcurve - 128) / 100.0
					if abs(d - ld) > 0.09 :
						d = lerp(ld, d, 0.5)
						segment_length = 16
						l = l - 0.5
					else :
						segment_length = 32
						l = l - 1
					nmx += pico_cos(d) * segment_length
					nmy += pico_sin(d) * segment_length
				var dist = sqrt(nmx * nmx + nmy * nmy)
				if dist < mindist :
					mindist = dist
					bestcurve = newcurve
			curve = bestcurve
		while length > 0 :
			dir = dir + (curve - 128) / 100.0
			var railcoef = 1
			if abs(dir - lastdir) > 0.09 :
				dir = lerp(lastdir, dir, 0.5)
				segment_length = 16
				length = length - 0.5
				railcoef = 0.5
			else:
				segment_length = 32
				length = length - 1

			mx += pico_cos(dir) * segment_length
			my += pico_sin(dir) * segment_length
			var v : TrackSection = TrackSection.new()
			v.pos = Vector2(mx,my)
			v.w = width
			v.dir = dir
			v.ltyp = ltyp
			v.rtyp = rtyp
			v.has_lrail = (lskiprail_first <= 0 and length >= lskiprail_last)
			v.has_rrail = (rskiprail_first <= 0 and length >= rskiprail_last)
			v.section = i
			v.segment_length = segment_length
			if (ltyp / 8) as int == OBJ_TREE :
				v.ltrees = []
				var tree_count = randi_range(8,18)
				for i2 in range(0,tree_count) :
					v.ltrees.append(TreeSprite.new(randi_range(1,3), Vector2((randi()%41) -50, randi()%33 )))
			if (rtyp / 8) as int == OBJ_TREE :
				v.rtrees = []
				var tree_count = randi_range(8,18)
				for i3 in range(0,tree_count) :
					v.rtrees.append(TreeSprite.new(randi_range(1,3), Vector2((randi()%41) -50, randi()%33 )))
			v.front = (v.pos - race.vecmap[-1].pos).normalized() if not race.vecmap.is_empty() else  Vector2(1, 0)
			v.side = v.front.orthogonal()
			# track borders (including kerbs)
			v.left_track = v.pos + v.side * v.w
			v.right_track = v.pos - v.side * v.w
			var ltribune = (ltyp/8) as int ==OBJ_TRIBUNE or (ltyp/8) as int == OBJ_TRIBUNE2
			var rtribune = (rtyp/8) as int ==OBJ_TRIBUNE or (rtyp/8) as int == OBJ_TRIBUNE2
			v.ltribune =  0.2 if ltribune else 0.0 #tribune sound level TODO
			v.rtribune =  0.2 if rtribune else 0.0 #tribune sound level TODO
			if ltribune and ltyp&7 != 0 :
				v.ltribune *= 0.5
			if rtribune and rtyp&7 != 0 :
				v.rtribune *= 0.5
			race.vecmap.append(v)
			lastdir = dir
			lskiprail_first = lskiprail_first - 1 * railcoef
			rskiprail_first = rskiprail_first - 1 * railcoef
	mapsize = race.vecmap.size()
	# compute kerbs
	var seg:int = 0
	for v in race.vecmap :
		var v2 = race.get_data_from_vecmap(seg)
		var curve : float = abs(v2.dir - v.dir) * 100.0
		var maybe_kerb : bool = seg != 0 and seg != race.vecmap.size()-1 and curve > 2
		if maybe_kerb :
			v.has_rkerb = 1 if (curve >= 4 or v2.dir < v.dir) else 0
			v.has_lkerb = 1 if (curve >= 4 or v2.dir > v.dir) else 0
			if v.segment_length == 16 :
				if v2.dir < v.dir :
					v.has_rkerb = 2
				else:
					v.has_lkerb = 2
		var rkerbw = 8 if v.has_rkerb else 0
		var lkerbw = 8 if v.has_lkerb else 0
		v.left_kerb = v.left_track - v.side * lkerbw
		v.right_kerb = v.right_track - v.side * rkerbw
		seg+=1
	var ltrib = 0
	var rtrib = 0
	for i2 in range(0,race.vecmap.size()+7) :
		var j = i2 % race.vecmap.size()
		var v=race.vecmap[j]
		# smooth tribune sound volume
		if v.ltribune > 0 :
			ltrib=v.ltribune
		else:
			ltrib = max(0,ltrib - 0.03)
			v.forward_ltribune=ltrib
		if v.rtribune > 0 :
			rtrib=v.rtribune
		else:
			rtrib = max(0,rtrib - 0.03)
			v.forward_rtribune=rtrib
	var trib=0
	for i3 in range (race.vecmap.size()+7,0,-1) :
		var j = i3 % race.vecmap.size()
		var v=race.vecmap[j]
		if max(v.ltribune,v.forward_ltribune) > 0 :
			ltrib=max(trib,max(v.ltribune,v.forward_ltribune))
		else:
			ltrib = max(0,ltrib - 0.03)
		v.ltribune = ltrib
		v.forward_ltribune=0.0
		if max(v.rtribune,v.forward_rtribune) > 0 :
			rtrib=max(rtrib,max(v.rtribune,v.forward_rtribune))
		else:
			rtrib = max(0,rtrib - 0.03)
		v.rtribune = rtrib
		v.forward_rtribune=0.0
	# distance to turn signs
	var dist : int = 0
	var last_curve : float = 0
	for i4 in range(race.vecmap.size()-2,-1,-1) :
		var v2 = race.vecmap[i4+1]
		var v = race.vecmap[i4]
		var curve : float = abs(v2.dir - v.dir) * 100.0
		if curve >= 2 :
			dist = 0
			last_curve = v2.dir - v.dir
		else:
			dist = dist + 1
		if dist == 5 or dist == 10 or dist == 15 :
			if last_curve < 0 :
				v.lpanel = dist / 5
			elif last_curve > 0 :
				v.rpanel = dist / 5
		# build pit line entry/exit
		if (v2.ltyp / 8) as int == OBJ_PIT_LINE and (v.ltyp / 8) as int < OBJ_PIT :
			for j in range (i - 3, i) :
				race.vecmap[j].ltyp = (OBJ_PIT_ENTRY1 + j - i + 2) * 8
				race.vecmap[j].has_lrail = false
		if (v2.rtyp / 8) as int == OBJ_PIT_LINE and (v.rtyp / 8) as int < OBJ_PIT :
			for j  in range (i - 3, i) :
				race.vecmap[j].rtyp = (OBJ_PIT_ENTRY1 + j - i + 2) * 8
				race.vecmap[j].has_rrail = false
		if (v2.ltyp / 8) as int < OBJ_PIT and (v.ltyp / 8) as int == OBJ_PIT_LINE :
			for j in range (i, i + 3) :
				race.vecmap[j].ltyp = (OBJ_PIT_EXIT1 + j - i - 1) * 8
				race.vecmap[j - 1].has_lrail = false
		if (v2.rtyp / 8) as int < OBJ_PIT and (v.rtyp / 8) as int == OBJ_PIT_LINE :
			for j in range (i, i + 3) :
				race.vecmap[j].rtyp = (OBJ_PIT_EXIT1 + j - i - 1) * 8
				race.vecmap[j - 1].has_rrail = false
		# convert last OBJ_PIT_LINE into OBJ_PIT_LINE_END
		# and first OBJ_PIT_LINE into OBJ_PIT_LINE_START
		if (v2.ltyp / 8) as int == OBJ_PIT and (v.ltyp / 8) as int == OBJ_PIT_LINE :
			v.ltyp = v.ltyp + 16
		elif (v2.ltyp / 8) as int == OBJ_PIT_LINE and (v.ltyp / 8) as int == OBJ_PIT :
			v2.ltyp = v2.ltyp + 8
		if (v2.rtyp / 8) as int == OBJ_PIT and (v.rtyp / 8) as int == OBJ_PIT_LINE :
			v.rtyp = v.rtyp + 16
		elif (v2.rtyp / 8) as int == OBJ_PIT_LINE and (v.rtyp / 8) as int == OBJ_PIT :
			v2.rtyp = v2.rtyp + 8
	# keep only signs when all 3 (150,100,50) exist
	var expected = 3
	for i5 in range (0,race.vecmap.size()) :
		var seg2 : int = (i5+race.vecmap.size()/2) % mapsize
		var v = race.vecmap[seg2]
		if (v.rtyp / 8) as int == OBJ_PIT or  (v.ltyp / 8) as int == OBJ_PIT :
			race.first_pit=seg2
			break
	for v in race.vecmap :
		if v.lpanel :
			if v.lpanel == expected :
				expected = expected - 1
				if expected == 0 :
					expected = 3
			else:
				v.lpanel = 0
		if v.rpanel :
			if v.rpanel == expected :
				expected = expected - 1
				if expected == 0 :
					expected = 3
			else:
				v.rpanel = 0
		# also compute rails
		v.left_inner_rail = v.left_track + v.side * (4 if v.ltyp & 7 == 0 else 40)
		v.right_inner_rail = v.right_track - v.side * (4 if v.rtyp & 7 == 0 else 40)
		if v.has_lrail :
			v.left_outer_rail = v.left_inner_rail + v.side * 4
		if v.has_rrail :
			v.right_outer_rail = v.right_inner_rail - v.side * 4

static func race_init(race: Race, track_num : int, mode : RaceMode, lap_count : int, difficulty: int) :
	race.mode = mode
	race.lap_count = lap_count
	race.live_cars = 16
	race.is_finished = false
	race.panel_timer = -1
	race.best_lap_timer = -1
	race.difficulty = difficulty
	camera_angle = 0
	load_map(track_num)
	race.generate_track()
	race.restart()

static func race_restart(race: Race) :
	race.completed = false
	race.time = -4 if race.mode == RaceMode.RACE else 0
	camera_lastpos = Vector2.ZERO
	tracked=-1
	race.start_timer = race.mode == RaceMode.RACE
	race.record_replay = []
	race.replay_frame = 1

	# spawn cars

	race.cars = []
	race.ranks = []
	race.pits = []
	race.pits.resize(TEAMS.size())
	race.pits.fill(null)
	best_seg_times = []
	best_lap_time = 0.0
	best_lap_driver = null
	if race.mode == RaceMode.TIME_ATTACK and race.play_replay :
		var replay_car = create_car(race)
		race.cars.append(replay_car)
		replay_car.color = 1
		race.replay_car = replay_car

	var p = create_car(race)
	race.cars.append(p)
	race.player = p
	cam_car=p
	p.is_player = true
	var v = race.get_data_from_vecmap(p.current_segment)
	p.pos = p.pos + 14 * v.side - 6 * v.front
	p.angle = v.dir
	p.rank = 1
	p.gear = 0
	p.rpm = 0
	p.screech = 0
	p.maxacc = p.maxacc
	p.mass = p.mass + FUEL_MASS_PER_KM * race.lap_count
	camera_angle = v.dir
	p.driver = {
		name = "Player",
		short_name = "PLA",
		is_best = false,
		team = find_team_id("Ferrero"),
		helmet = 0
	}
	race.ranks.append(p)
	p.perf = TEAMS[p.driver.team].perf
	if race.mode != RaceMode.EDITOR :
		V.snd.play_sound(9, 440, v.ltribune, v.rtribune, 2) # tribune sound
		V.snd.play_sound(10,440,0,0,3) # muted tyre screech sound

	if race.mode == RaceMode.RACE :
		for i in range(0,DRIVERS.size()) :
			var ai_car = create_car(race)
			ai_car.maxacc = ai_car.maxacc - CARS[race.difficulty].player_adv
			ai_car.mass = ai_car.mass + FUEL_MASS_PER_KM * race.lap_count
			ai_car.current_segment = -1 - (i+1) / 2
			ai_car.driver = DRIVERS[i]
			ai_car.color = TEAMS[ai_car.driver.team].color
			ai_car.color2 = TEAMS[ai_car.driver.team].color2
			ai_car.perf = TEAMS[ai_car.driver.team].perf
			ai_car.driver.is_best = false
			ai_car.pos = v + (14 if i%2 == 0 else -14) * v.side - 6 * v.front
			if i % 2 == 1 :
				ai_car.pos = ai_car.pos - 14 * v.front
			ai_car.angle = v.dir
			ai_car.ai = Ai.new(ai_car,rnd(5) + 3, rnd())
			ai_car.ai.skill = ai_car.driver.skill
			race.cars.append(ai_car)
			race.ranks.append(ai_car)
	else:
		# quick pitstop test
		# p.pit=-4
		# self.tyre=1
		# p.pos = Vector2(-160,57)
		# self.pits[p.driver.team] = {}
		pass

static func race_draw_tribune(_race: Race, li_rail:Vector2, side : Vector2, front : Vector2, dir : float, roof_type : bool):
	var p = li_rail + side * 8
	var p2 = p + side * 10
	var p3 = p - 32 * front
	var p4 = p2 - 32 *front
	quadfill(p, p2, p3, p4, 22)
	var p2s = p + 5 * side -16 * front
	gblit_region(224, 0, 20, 60, p2s, 33, dir)
	p += 50 * side
	p3 += 50 * side
	V.gfx.set_active_layer(LAYER_TOP)
	quadfill(p, p2, p3, p4, 20 if roof_type else 4)
	V.gfx.set_active_layer(LAYER_SHADOW2)
	var sd = SHADOW_DELTA
	p += sd
	p2 += sd
	p3 += sd
	p4 += sd
	quadfill(p, p2, p3, p4, 22)
	V.gfx.set_active_layer(0)

static func race_draw_tribune2(_race: Race, li_rail: Vector2, side: Vector2, front: Vector2, dir: float):
	var p = li_rail + 8 * side
	var p2 = p + 40 * side
	var p3 = p - 32 * front
	var p4 = p2 - 32 * front
	V.gfx.set_active_layer(LAYER_CARS)
	quadfill(p, p2, p3, p4, 22)
	V.gfx.set_active_layer(LAYER_SHADOW)
	p2 += SHADOW_DELTA
	p4 += SHADOW_DELTA
	quadfill(p, p2, p3, p4, 22)
	V.gfx.set_active_layer(LAYER_TOP)
	var p2s = p + 5 * side - 16 * front
	gblit_region(244, 0, 20, 60, p2s, 33, dir)
	p2s = p + 15 *side - 16 * front
	gblit_region(264, 0, 20, 60, p2s, 33, dir)
	p2s = p + 25 * side - 16 * front
	gblit_region(244, 0, 20, 60, p2s, 33, dir)
	p2s = p + 35 * side - 16 * front
	gblit_region(264, 0, 20, 60, p2s, 33, dir)
	V.gfx.set_active_layer(LAYER_SHADOW2)
	var sd = SHADOW_DELTA * 0.1
	p2s = p + 5 * side - 16 * front + sd
	gblit_col(244, 0, 20, 60, p2s, SHADOW_COL, dir)
	p2s = p + 15 * side - 16 * front + sd
	gblit_col(264, 0, 20, 60, p2s, SHADOW_COL, dir)
	p2s = p + 25 * side - 16 * front + sd
	gblit_col(244, 0, 20, 60, p2s, SHADOW_COL, dir)
	p2s = p + 35 * side - 16 * front + sd
	gblit_col(264, 0, 20, 60, p2s, SHADOW_COL, dir)
	V.gfx.set_active_layer(0)

static func race_draw_tree(_race: Race, trees, li_rail:Vector2, last_li_rail:Vector2, side:Vector2, last_side:Vector2, front:Vector2, dir: float):
	var p = li_rail + side
	var p2 = last_li_rail + last_side
	var p3 = p + 56 * side
	var p4 = p2 + 56 * last_side
	quadfill(p, p2, p3, p4, 27)
	V.gfx.set_active_layer(LAYER_TOP)
	for tree in trees :
		var typ = tree.typ
		var tree_pos = tree.p
		var tree_pos2 = li_rail - side * tree_pos.x - front * tree_pos.y
		if typ == 1 :
			gblit_region(224, 60, 20, 20, tree_pos2, 33, dir)
		elif typ == 2 :
			gblit_region(224, 80, 30, 30, tree_pos2, 33, dir)
		elif typ == 3 :
			gblit_region(224, 110, 40, 40, tree_pos2, 33, dir)
	V.gfx.set_active_layer(LAYER_SHADOW2)
	for tree in trees :
		var typ = tree.typ
		var tree_pos = tree.p
		var tree_pos2 = li_rail - side * tree_pos.x - front * tree_pos.y + SHADOW_DELTA
		if typ == 1 :
			gblit_col(224, 60, 20, 20, tree_pos2, SHADOW_COL, dir)
		elif typ == 2 :
			gblit_col(224, 80, 30, 30, tree_pos2, SHADOW_COL, dir)
		elif typ == 3 :
			gblit_col(224, 110, 40, 40, tree_pos2, SHADOW_COL, dir)
	V.gfx.set_active_layer(0)

static func race_draw_pit(race:Race, ri_rail: Vector2, side: Vector2, front: Vector2, ground_type: bool, seg: int, dir: float) :
	var p = ri_rail - 24 * side
	var p2 = p - 8 * side
	var p3 = p - 33 * front
	var p4 = p2 - 33 * front
	linevec(p, p3, 10)
	var perp = -4 * side
	p = p2 + perp
	p3 = p4 + perp
	seg=posmod(seg,mapsize)
	var pit_seg=2*(race.player.driver.team-1) + race.first_pit
	quadfill(p2, p4, p, p3, 8 if seg==pit_seg else 7 if ground_type else 28)
	perp *= 4
	p2 = p + perp
	p4 = p3 + perp
	perp *= 0.125
	var perp2 = -6 * front
	quadfill(p, p3, p2, p4, 22)
	var lp = p + perp + perp2
	var lp2 = p2 - perp + perp2
	perp2 = -2 * front
	var lp3 = lp + perp2
	var lp4 = lp2 + perp2
	linevec(lp, lp3, 7)
	linevec(lp, lp2, 7)
	linevec(lp2, lp4, 7)
	V.gfx.set_active_layer(LAYER_TOP)
	var team : int = ((seg-race.first_pit)/2) as int +1
	if race.pits[team] and not ground_type :
		race.draw_pit_crew(ri_rail,side,front,team,dir)
	perp = -32 * side
	p = p2 + perp
	p3 = p4 + perp
	quadfill(p, p3, p2, p4, 13)
	V.gfx.set_active_layer(LAYER_SHADOW2)
	p -= SHADOW_DELTA
	p2 -= SHADOW_DELTA
	p3 -= SHADOW_DELTA
	p4 -= SHADOW_DELTA
	quadfill(p, p3, p2, p4, 22)
	V.gfx.set_active_layer(0)

static func race_draw_pitline(race: Race, ri_rail: Vector2, side: Vector2, front: Vector2):
	var p = ri_rail - 24 *side
	var p2 = p - 32 * side
	var p3 = p - 33 * front
	var p4 = p2 - 33 * front
	quadfill(p2, p4, p, p3, 27)
	race.draw_rail(p, p3)

static func race_draw_pitline_start(race: Race, ri_rail: Vector2, side: Vector2, front: Vector2):
	var p = ri_rail - 24 * side
	var p2 = p - 32 * side
	var p3 = p - 33 * front
	var p4 = p2 - 33 * front
	trifill(p, p2, p4, 27, true)
	linevec(p, p3, 10)
	race.draw_rail(p, p4)

static func race_draw_pitline_end(race: Race, ri_rail: Vector2, side: Vector2, front: Vector2):
	var p = ri_rail- 24 * side
	var p2 = p - 32 * side
	var p3 = p - 33 * front
	var p4 = p2 - 33 * front
	trifill(p2, p3, p4, 27, true)
	linevec(p, p3, 10)
	race.draw_rail(p2, p3)

static func race_draw_pit_entry(race: Race, ri_rail: Vector2, side: Vector2, front: Vector2, seg: int):
	var p = ri_rail - side * (4 + 7 * (seg + 1))
	var p2 = ri_rail -33 * front + side *( 4 + 7 * seg)
	var p3 = ri_rail - 56 * side
	var p4 = p3 - 33 * front
	quadfill(p, p2, p3, p4, 27)
	race.draw_rail(p, p2)

static func race_draw_pit_exit(race: Race,ri_rail: Vector2, side: Vector2, front: Vector2, seg: int):
	var p = ri_rail - side * ( 4 + 7 * (2 - seg))
	var p2 = ri_rail + 33 * front - side *( 4 + 7 * (3 - seg))
	var p3 = ri_rail -56 * side
	var p4 = p3 - 33 *front
	quadfill(p, p2, p3, p4, 27)
	race.draw_rail(p, p2)

static func race_draw_pit_guy(_race: Race,p: Vector2,c1: int,c2: int,dir: float,side: Vector2, front: Vector2,sx: float,sy: float,sw: float,sh: float,delta: Vector2):
	var dx : float = (sx-323)*0.75 + (delta.x if delta != null else 0.0)
	var dy : float = (sy-224)*0.75 + (delta.y if delta != null else 0.0)
	p -= side * dx + front * dy
	gblit_region(sx,sy,sw,sh,p,c1,dir)
	gblit_region(sx+22,sy,sw,sh,p,33,dir)
	gblit_region(sx,sy+26,sw,sh,p,c2,dir)

static func race_draw_pit_crew(race: Race,ri_rail: Vector2, side: Vector2, front: Vector2, team: int, dir: float):
	var c1: int = TEAMS[team].color
	var c2: int = TEAMS[team].color2
	var pit_info = race.pits[team]
	var p=ri_rail - 38 * side - 5 * front
	race.draw_pit_guy(p,c1,c2,dir,side,front,331,224,5,7,pit_info.front) # front man
	race.draw_pit_guy(p,c1,c2,dir,side,front,323,229,5,9,pit_info.fl) # front left wheel squad
	race.draw_pit_guy(p,c1,c2,dir,side,front,340,229,5,9,pit_info.fr) # front right wheel squad
	race.draw_pit_guy(p,c1,c2,dir,side,front,323,241,5,9,pit_info.rl) # rear left wheel squad
	race.draw_pit_guy(p,c1,c2,dir,side,front,340,241,5,9,pit_info.rr) # rear right wheel squad

static func race_draw_rail(_race: Race, p1: Vector2, p2: Vector2):
	var side = (p2-p1).normalized().orthogonal()
	var p3 = p1 + side
	var p4 = p2 + side
	quadfill(p1, p2, p3, p4, 22)
	V.gfx.set_active_layer(LAYER_SHADOW)
	var sd = SHADOW_DELTA * 0.5
	quadfill(p3, p4, p3 + sd, p4 + sd, 22)
	V.gfx.set_active_layer(0)

static func race_update(race:Race):
	frame += 1
	if race.best_lap_timer >= 0 :
		race.best_lap_timer -= 1

	if race.completed :
		race.completed_countdown -= DT
		if race.completed_countdown < 4 and (inp_menu_pressed() or race.live_cars == 0) :
			set_game_mode(CompletedMenu.new(race))
			return
	elif inp_menu_pressed() :
		V.snd.stop_channel(1)
		race.player.freq=0.0
		V.snd.stop_channel(2)
		V.snd.stop_channel(3)
		set_game_mode(PauseMenu.new(race))
		return

	# enter input
	var player = race.player
	if player :
		var controls = player.controls
		if race.completed :
			controls.left = false
			controls.right = false
			controls.brake = true
			controls.accel = false
		else:
			controls.left = V.inp.left() > 0.1
			controls.right = V.inp.right() > 0.1
			controls.accel = inp_accel()
			controls.brake = inp_brake()
		if player.pit :
			if not player.pit_done and player.pitstop_timer == 0 :
				if V.inp.up_pressed() :
					race.tyre = (race.tyre + 1) % 5
				elif V.inp.down_pressed() :
					race.tyre = (race.tyre + 4) % 5
		elif race.mode != RaceMode.EDITOR :
			if V.inp.up_pressed() :
				panel = posmod(panel-1, ui_panels.size())
			elif V.inp.down_pressed() :
				panel = (panel +1) % ui_panels.size()

	# replay playback
	var replay = race.play_replay
	if replay and race.replay_car :
		if race.replay_frame == 0 :
			race.replay_car.pos = replay[0].pos
			race.replay_car.angle = replay[0].angle
			race.replay_frame = 1
		if race.start_timer :
			if race.replay_frame == 1 :
				var rc = race.replay_car
				rc.vel = replay[0].vel
				rc.accel = replay[0].accel
			var v = replay[race.replay_frame]
			if v :
				var c = race.replay_car.controls
				c.left = (v & 1) != 0
				c.right = (v & 2) != 0
				c.accel = (v & 4) != 0
				c.brake = (v & 8) != 0
				race.replay_frame += 1

	if player.current_segment == 0 and not race.start_timer and race.mode == RaceMode.TIME_ATTACK :
		race.start_timer = true
		race.record_replay = []
		race.record_replay.append(ReplayFrame.new(Vector2(player.pos),Vector2(player.vel),player.angle,player.accel))
	if race.start_timer :
		var before = floor(race.time)
		race.time = race.time + DT
		if race.time < 0 :
			camera_scale = V.ease_in_out_cubic(4 + race.time, 0.5, 0.5, 4.0)
		if race.time < 1.0 :
			var after = floor(race.time)
			if after != before :
				V.snd.play_pattern(1 if after == 0 else 0)

	if race.panel_timer >= 0 :
		race.panel_timer -= 1

	# record replay
	if race.record_replay :
		var c = player.controls
		var v = (1 if c.left else 0) + (2 if c.right else 0) + (4 if c.accel else 0) + (8 if c.brake else 0)
		race.record_replay.append(v)

	if race.mode == RaceMode.TIME_ATTACK or race.time > 0 :
		for car in race.cars :
			car.update(race.completed, race.time)
	if race.mode == RaceMode.TIME_ATTACK and player.current_segment % mapsize == 0 and race.time > 20 :
		race.time = 0
	# car to car collision
	for obj in race.cars :
		for obj2 in race.cars :
			if obj != obj2 and obj != race.replay_car and obj2 != race.replay_car :
				if abs(car_lap_seg(obj.current_segment, obj2) - obj2.current_segment) <= 1 :
					var p1 = [ obj.verts[0], obj.verts[1], obj.verts[2] ]
					var p2 = [ obj2.verts[0], obj2.verts[1], obj2.verts[2] ]
					for point in p1 :
						if point_in_polygon(p2, point) :
							var coll : Collision = check_collision(p1,[Segment.new(p2[1], p2[0]), Segment.new(p2[2], p2[1]), Segment.new(p2[0], p2[2])])
							if coll.rvec :
								if coll.pen > 5 :
									coll.pen = 5
								coll.pen *= COLLISION_COEF
								obj.vel += coll.rvec * coll.pen
								obj2.vel -= coll.rvec * coll.pen
								create_spark(obj.current_segment, point, coll.rvec, false)
								obj.collision += floor(coll.pen)
								obj2.collision += floor(coll.pen)
								if obj.is_player or obj2.is_player :
									if coll.pen > 2 :
										V.snd.play_pattern(3)
									else:
										V.snd.play_pattern(4)

	if not race.completed and race.mode == RaceMode.RACE and player.race_finished :
		# completed
		V.snd.stop_channel(1)
		race.player.freq=0.0
		V.snd.stop_channel(2)
		V.snd.stop_channel(3)
		race.completed = true
		race.completed_countdown = 5

	# particles
	for p in particles :
		if p.enabled :
			if abs(car_lap_seg(p.seg, cam_car) - cam_car.current_segment) > 10 :
				p.enabled = false
			else:
				p.x = p.x + p.xv
				p.y = p.y + p.yv
				p.xv = p.xv * 0.95
				p.yv = p.yv * 0.95
				p.ttl = p.ttl - 1
				if p.ttl < 0 :
					p.enabled = false
	for p in smokes :
		if p.enabled :
			if abs(car_lap_seg(p.seg, cam_car) - cam_car.current_segment) > 10 :
				p.enabled = false
			else:
				p.x = p.x + p.xv
				p.y = p.y + p.yv
				p.xv = p.xv * 0.95
				p.yv = p.yv * 0.95
				p.ttl = p.ttl - 1
				if p.ttl < 0 :
					p.enabled = false
	# lerp_angle
	camera_angle = lerp_pico_angle(camera_angle, cam_car.angle, 0.05)

	# car times
	if frame % 100 == 0 :
		race.ranks.sort_custom(func(car, car2) :
			var seg = car.lap_times.size() * mapsize if car.race_finished else car.current_segment
			var seg2 = car2.lap_times.size() * mapsize if car2.race_finished else car2.current_segment
			if seg > seg2 :
				return true
			if seg < seg2 :
				return false
			if car.race_finished :
				return car.delta_time < car2.delta_time
			return false
		)
		var t = race.time
		var leader = race.ranks[1]
		var leader_seg = leader.lap_times.size() * mapsize if leader.race_finished else leader.current_segment
		race.live_cars = 16
		for car in race.cars :
			if car.race_finished :
				race.live_cars = race.live_cars - 1
			else:
				var lap_behind = ceil((car.current_segment - leader_seg) / mapsize)
				car.time = "%d laps" % lap_behind if lap_behind < 0 else \
					"+%s" % format_time(t - best_seg_times[car.current_segment])  if best_seg_times[car.current_segment] else \
					"##-"
	if race.panel_timer < 0 and player.current_segment > 0 \
		and player.current_segment % mapsize == 0 and race.mode == RaceMode.RACE :
		race.panel_timer = 200
		var placing = 1
		for obj in race.cars :
			if obj != player :
				if obj.current_segment > player.current_segment :
					placing += 1
		race.panel_placing = placing
		if placing > 1 :
			var prev = race.ranks[placing - 1]
			race.panel_prev = prev
			race.panel_prev_time = "-%s" % format_time(race.time - prev.seg_times[player.current_segment])
		if placing < 16 :
			var next = race.ranks[placing + 1]
			race.panel_next = next
			race.panel_next_time = "+%s" % format_time(race.time - player.seg_times[next.current_segment])
	if race.time >= 0 :
		var target = 1.5 - 0.8 * (race.player.speed / 23)
		camera_scale += (target - camera_scale) * 0.02
	if V.inp.key_pressed(V.inp.KEY_PAGEUP) :
		if tracked==-1 :
			tracked=1
		else:
			tracked=posmod(tracked-1, race.ranks.size())
		cam_car = race.ranks[tracked]
	elif V.inp.key_pressed(V.inp.KEY_PAGEDOWN) :
		if tracked==-1 :
			tracked=race.ranks.size()-1
		else:
			tracked=(tracked+1) % race.ranks.size()
		cam_car = race.ranks[tracked]
	elif V.inp.key_pressed(V.inp.KEY_HOME) :
		tracked=-1 # go back to tracking the player
		cam_car = race.player

static func race_draw(race: Race) :
	var player = race.player
	var time = race.time
	V.gfx.set_active_layer(0)
	cls()
	var tp = player.trails.get(player.trails._size - 8) 
	if tp == null :
		tp = player.pos
	var trail = min((player.pos - tp), Vector2(34,34))
	if race.mode != RaceMode.EDITOR :
		var camera_pos = cam_car.pos + trail
		if cam_car.collision > 0 :
			cam_pos = Vector2(camera_pos.x + rnd(3) - 2, camera_pos.y + rnd(3) - 2)
		else:
			cam_pos = camera_pos
		camera_lastpos = Vector2(camera_pos)
	var current_segment = cam_car.current_segment
	var player_sec = race.get_data_from_vecmap(current_segment).section
	# draw track

	var lastv : TrackSection
	var last_right_rail : Vector2
	var has_last_right_rail : bool
	var last_left_rail : Vector2
	var has_last_left_rail : bool
	var panels = []
	var minseg: int
	var maxseg: int
	var has_lrail: bool
	var has_rrail: bool
	for seg in range(current_segment - 20, current_segment + 21) :
		var v : TrackSection = race.get_data_from_vecmap(seg)
		var nextv  : TrackSection  = race.get_data_from_vecmap(seg + 1)
		if has_rrail and lastv :
			if ((v.rtyp / 8) as int >= OBJ_PIT_ENTRY1 and (v.rtyp / 8) as int <= OBJ_PIT_ENTRY2) or (nextv.rtyp / 8) as int >= OBJ_PIT_EXIT1 :
				has_last_right_rail = false
			else:
				last_right_rail = lastv.right_outer_rail
				has_last_right_rail = true
		if has_lrail and lastv :
			if ((v.ltyp / 8) as int >= OBJ_PIT_ENTRY1 and (v.ltyp / 8) as int <= OBJ_PIT_ENTRY2) or (nextv.ltyp / 8) as int >= OBJ_PIT_EXIT1 :
				has_last_left_rail = false
			else:
				last_left_rail = lastv.left_outer_rail
				has_last_left_rail = true
		has_lrail = v.has_lrail
		has_rrail = v.has_rrail

		if lastv :
			if onscreen(v) or onscreen(lastv) or onscreen(v.right_inner_rail) or onscreen(v.left_inner_rail) \
				or onscreen(lastv.right_inner_rail) or onscreen(lastv.left_inner_rail) :
				var ltyp = v.ltyp & 7
				var rtyp = v.rtyp & 7
				var rtrack = v.right_track
				var ltrack = v.left_track
				var last_rtrack = lastv.right_track
				var last_ltrack = lastv.left_track
				var ri_rail = v.right_inner_rail
				var li_rail = v.left_inner_rail
				var last_ri_rail = lastv.right_inner_rail
				var last_li_rail = lastv.left_inner_rail
				var last_rtyp = lastv.rtyp & 7
				var last_ltyp = lastv.ltyp & 7
				# edges
				if rtyp == 1 or rtyp == 0 and last_rtyp == 1 :
					# grass
					quadfill(last_rtrack, rtrack, last_ri_rail, ri_rail, 27)
				elif rtyp == 2 or rtyp == 0 and last_rtyp == 2 :
					# sand
					quadfill(last_rtrack, rtrack, last_ri_rail, ri_rail, 15)
				elif rtyp == 3 or rtyp == 0 and last_rtyp == 3 :
					# asphalt
					quadfill(last_rtrack, rtrack, last_ri_rail, ri_rail, 5)
				if ltyp == 1 or ltyp == 0 and last_ltyp == 1 :
					# grass
					quadfill(last_ltrack, ltrack, last_li_rail, li_rail, 27)
				elif ltyp == 2 or ltyp == 0 and last_ltyp == 2 :
					# sand
					quadfill(last_ltrack, ltrack, last_li_rail, li_rail, 15)
				elif ltyp == 3 or ltyp == 0 and last_ltyp == 3 :
					# asphalt
					quadfill(last_ltrack, ltrack, last_li_rail, li_rail, 5)
				# ground
				var ground = seg % 2 == 0 and 5 or 32
				quadfill(lastv.right_kerb, lastv.left_kerb, v.right_kerb, v.left_kerb, ground)
				# kerbs
				if v.has_lkerb or lastv.has_lkerb :
					if v.has_lkerb == 1 or lastv.has_lkerb == 1 :
						var midleft = midpoint(ltrack, last_ltrack)
						var midleft_kerb = midpoint(v.left_kerb, lastv.left_kerb)
						quadfill(v.left_kerb, ltrack, midleft_kerb, midleft, 7)
						quadfill(last_ltrack, midleft, lastv.left_kerb, midleft_kerb, 8)
					else:
						quadfill(v.left_kerb, ltrack, lastv.left_kerb, last_ltrack, seg % 2 == 0 and 7 or 8)
				if v.has_rkerb or lastv.has_rkerb :
					if v.has_rkerb == 1 or lastv.has_rkerb == 1 :
						var midright = midpoint(rtrack, last_rtrack)
						var midright_kerb = midpoint(v.right_kerb, lastv.right_kerb)
						quadfill(v.right_kerb, rtrack, midright_kerb, midright, 7)
						quadfill(midright_kerb, midright, lastv.right_kerb, last_rtrack, 8)
					else:
						quadfill(v.right_kerb, rtrack, lastv.right_kerb, last_rtrack, seg % 2 == 0 and 7 or 8)
				if rtyp == 0 and (v.rtyp / 8) as int < OBJ_PIT_ENTRY1 :
					# normal crash barriers
					linevec(last_rtrack, rtrack, 6)
				if ltyp == 0 and (v.ltyp / 8) as int < OBJ_PIT_ENTRY1 :
					# normal crash barriers
					linevec(last_ltrack, ltrack, 6)
				if ltyp != 0 :
					linevec(last_ltrack, ltrack, 10)
				if rtyp != 0 :
					linevec(last_rtrack, rtrack, 10)
				if has_rrail and has_last_right_rail :
					race.draw_rail(last_right_rail, v.right_outer_rail)
				if has_lrail and has_last_left_rail :
					race.draw_rail(last_left_rail, v.left_outer_rail)
				# starting line
				if seg % mapsize == 0 :
					var startling_line_pos = cam2screen(v.pos - 6 * v.front)
					V.gfx.blit_region(startling_line_pos, Vector2(162, 254), Vector2(110, 6), Color.WHITE,
						from_pico_angle(camera_angle - v.dir), Vector2(110 * camera_scale, 6 * camera_scale))
				# starting grid
				var wseg = posmod(seg, mapsize)
				if wseg > mapsize - DRIVERS.size() / 2 - 2 :
					var side = 12 * v.side
					var smallfront = -12 * v.front
					var lfront = 31 * v.front
					var p = lastv.left_kerb - side + lfront
					var p2 = p - side
					linevec(p, p2, 7)
					linevec(p, p + smallfront, 7)
					linevec(p2, p2 + smallfront, 7)
					lfront = 17 * v.front
					p = lastv.right_kerb + side + lfront
					p2 = p + side
					linevec(p, p2, 7)
					linevec(p, p + smallfront, 7)
					linevec(p2, p2 + smallfront, 7)
				# track side objects
				var lobj = (v.ltyp / 8) as int
				var robj = (v.rtyp / 8) as int
				if lobj == OBJ_TRIBUNE :
					race.draw_tribune(li_rail, v.side, v.front, v.dir, seg % 2 == 0)
				elif lobj == OBJ_TRIBUNE2 :
					race.draw_tribune2(li_rail, v.side, v.front, v.dir)
				elif lobj == OBJ_TREE :
					race.draw_tree(v.ltrees, li_rail, lastv.left_inner_rail, v.side, lastv.side, v.front, v.dir)
				elif lobj == OBJ_BRIDGE :
					V.gfx.set_active_layer(LAYER_TOP)
					gblit_region(141, 224, 182, 30, v.pos, 33, v.dir)
					V.gfx.set_active_layer(LAYER_SHADOW2)
					var bridge_shadow_pos = v.pos + SHADOW_DELTA
					gblit_col(141, 224, 182, 30, bridge_shadow_pos, SHADOW_COL, v.dir)
					V.gfx.set_active_layer(0)
				elif lobj == OBJ_BRIDGE2 :
					var p2 = v.pos -48 * v.side
					gblit_region(141, 224, 8, 30, p2, 33, v.dir)
					var p3 = v.pos + 48 * v.side
					gblit_region(315, 224, 8, 30, p3, 33, v.dir)
					V.gfx.set_active_layer(LAYER_TOP)
					gblit_region(141, 260, 182, 11, v.pos, 33, v.dir)
					V.gfx.set_active_layer(LAYER_SHADOW2)
					var bridge2_pos = v.pos + SHADOW_DELTA
					p2 += SHADOW_DELTA
					p3 += SHADOW_DELTA
					gblit_col(141, 260, 182, 11, bridge2_pos, SHADOW_COL, v.dir)
					gblit_col(141, 224, 8, 30, p2, SHADOW_COL, v.dir)
					gblit_col(315, 224, 8, 30, p3, SHADOW_COL, v.dir)
					V.gfx.set_active_layer(0)
				elif lobj == OBJ_PIT :
					race.draw_pit(li_rail, -v.side, v.front, seg % 2 == 0, seg, v.dir)
				elif lobj == OBJ_PIT_LINE :
					race.draw_pitline(li_rail, - v.side, v.front)
				elif lobj == OBJ_PIT_LINE_START :
					race.draw_pitline_start(li_rail, - v.side, v.front)
				elif lobj == OBJ_PIT_LINE_END :
					race.draw_pitline_end(li_rail, - v.side, v.front)
				if robj == OBJ_TRIBUNE :
					race.draw_tribune(ri_rail, - v.side, v.front, v.dir, seg % 2 == 0)
				elif robj == OBJ_TRIBUNE2 :
					race.draw_tribune2(ri_rail, - v.side, v.front, v.dir)
				elif robj == OBJ_TREE :
					race.draw_tree(v.rtrees, ri_rail, lastv.right_inner_rail, -v.side, -lastv.side, v.front, v.dir)
				elif robj == OBJ_PIT :
					race.draw_pit(ri_rail, v.side, v.front, seg % 2 == 0, seg, v.dir)
				elif robj == OBJ_PIT_LINE :
					race.draw_pitline(ri_rail, v.side, v.front)
				elif robj == OBJ_PIT_LINE_START :
					race.draw_pitline_start(ri_rail, v.side, v.front)
				elif robj == OBJ_PIT_LINE_END :
					race.draw_pitline_end(ri_rail, v.side, v.front)
				elif robj >= OBJ_PIT_ENTRY1 and robj <= OBJ_PIT_ENTRY3 :
					race.draw_pit_entry(ri_rail, v.side, v.front, robj - OBJ_PIT_ENTRY1)
				elif robj >= OBJ_PIT_EXIT1 and robj <= OBJ_PIT_EXIT3 :
					race.draw_pit_exit(ri_rail, v.side, v.front, robj - OBJ_PIT_EXIT1)

				if v.lpanel :
					var p = v.left_inner_rail
					var y = 214 + 10 * v.lpanel
					panels.append({ y = y, p = p, dir = v.dir })
				elif v.rpanel :
					var p = v.right_inner_rail
					var y = 214 + 10 * v.rpanel
					panels.append({ y = y, p = p, dir = v.dir })
				if race.mode == RaceMode.EDITOR and v.section == player_sec :
					# highlight current section in map editor
					V.gfx.set_active_layer(LAYER_TOP)
					linevec(lastv.right_kerb, lastv.left_kerb, 10)
					linevec(v.right_kerb, v.left_kerb, 10)
					linevec(lastv.right_kerb, v.right_kerb, 10)
					linevec(lastv.left_kerb, v.left_kerb, 10)
					V.gfx.set_active_layer(0)
					minseg = min(minseg, seg) if minseg != null else seg
					maxseg = max(maxseg, seg) if maxseg != null else seg
		lastv = v

	for p in panels :
		gblit_region(91, p.y, 24, 10, p.p, 33, p.dir)
	# draw cars
	V.gfx.set_active_layer(LAYER_CARS)
	for obj in race.cars :
		var oseg = car_lap_seg(obj.current_segment, cam_car)
		if abs(oseg - cam_car.current_segment) < 10 :
			obj.draw()

	for p in particles :
		if p.enabled :
			p.draw()
	V.gfx.set_active_layer(LAYER_SMOKE)
	V.gfx.clear()
	if not race.completed :
		for p in smokes :
			if p.enabled :
				p.draw()

	# DEBUG : display segments collision shapes
	# seg=get_segment(cam_car.current_segment-1,false,true)
	# quadfill(seg[1],seg[2],seg[4],seg[3],11)
	# var seg=get_segment(cam_car.current_segment+1,false,true)
	# quadfill(seg[1],seg[2],seg[4],seg[3],12)
	# var seg=get_segment(cam_car.current_segment,false,true)
	# quadfill(seg[1],seg[2],seg[4],seg[3],8)
	V.gfx.set_active_layer(LAYER_TOP)
	# draw_minimap
	if not race.completed :
		var lastv2 = null
		for seg in range(current_segment + MINIMAP_START, current_segment + MINIMAP_END+1) :
			var v = race.get_vec_from_vecmap(seg)
			if lastv2 != null :
				minimap_line(lastv2, v, 7)
			lastv2 = v
		for car in race.cars :
			car.draw_minimap(cam_car)

	var lap = floor(player.current_segment / race.mapsize) + 1
	printr("%d fps" % V.gfx.fps(), V.gfx.SCREEN_WIDTH - 1, 1, 7)

	# car dashboard
	var tyre_col : Array[Color] = []
	var tyre_wear=[]
	if not race.completed and race.mode != RaceMode.EDITOR :
		var x=V.gfx.SCREEN_WIDTH-66
		var y=V.gfx.SCREEN_HEIGHT-35
		V.gfx.blit_region(Vector2(x, y), Vector2(0, 224), Vector2(66, 35))
		# speed indicator
		printc("%d" % player.speed * 14, 370, 210, 28)
		# gear
		printc("N" if player.gear == 0 else "%d" % player.gear, V.gfx.SCREEN_WIDTH-32,V.gfx.SCREEN_HEIGHT-31,28)
		# rpm
		V.gfx.blit_region(Vector2(V.gfx.SCREEN_WIDTH - 28, V.gfx.SCREEN_HEIGHT - 23), Vector2(66, 224), 
			Vector2(25 * min(1, player.speed / 22), 8))
		if player.freq :
			V.gfx.blit_region(Vector2(V.gfx.SCREEN_WIDTH - 60, V.gfx.SCREEN_HEIGHT - 22), Vector2(66, 232), 
				Vector2(19 * player.rpm, 9))
		# car status
		# front wing
		V.gfx.line(Vector2(x+31,y+25),Vector2(x+35,y+25), Color8(0,228,54))
		# rear wing
		V.gfx.line(Vector2(x+31,y+33),Vector2(x+35,y+33), Color8(0,228,54))
		# tires
		for i in range(0,4) :
			var tx = x + (30 if i%2==0 else 35)
			var ty = y + (27 if i < 2 else 30)
			var col: Color = Color.WHITE
			if player.tyre_wear[i] <= 0 :
				var coef = -player.tyre_wear[i]/TYRE_HEAT[player.tyre_type]
				col.r=0
				col.g=228
				col.b=54+(201*coef)
				tyre_wear.append(100)
			else:
				var coef = player.tyre_wear[i] / TYRE_LIFE[player.tyre_type]
				if coef <= 0.5 :
					# from green to orange
					var ccoef=coef*2
					col.r=255*ccoef
					col.g=228 + (163-228)*ccoef
					col.b=54 -54*ccoef
				elif coef <= 1 :
					# from orange to red
					var ccoef=(coef-0.5)*2
					col.r=255
					col.g=163-163*ccoef
					col.b=77*ccoef
				else:
					# above 1, blinking red
					var black=frame%10 < 5
					col.r = 8 if black else 255
					col.g = 13 if black else 0
					col.b = 25 if black else 77
				tyre_wear.append(max(0,floor((1-coef)*100)))
			V.gfx.line(Vector2(tx,ty),Vector2(tx,ty+2), col)
			tyre_col.append(col)
		# engine
		V.gfx.rectangle(Rect2(x+32,y+30,2,2), Color8(0,228,54))

		# fuel
		var fuel = clamp((race.player.mass - CAR_BASE_MASS) / (FUEL_MASS_PER_KM * race.lap_count),0,1)
		if fuel > 0.1 or frame % 4 < 2 :
			V.gfx.blit_region(Vector2(V.gfx.SCREEN_WIDTH - 61, V.gfx.SCREEN_HEIGHT - 8), Vector2(66, 241), Vector2(21 * fuel, 4))
		if race.mode == RaceMode.RACE and race.panel_timer >= 0 :
			# stand panel
			var panelx = V.gfx.SCREEN_WIDTH - 90
			var panely = 50
			V.gfx.rectangle(Rect2(panelx, panely, 85, 44), UI_BACKGROUND_COLOR)
			gprint("P%d" % race.panel_placing, panelx + 3, panely + 3, 10)
			if race.panel_placing > 1 :
				gprint("%s %s" % [race.panel_prev_time,race.panel_prev.driver.short_name], panelx + 3, panely + 13, 10)
			if race.panel_placing < 16 :
				gprint("%s %s" % [race.panel_next_time, race.panel_next.driver.short_name], panelx + 3, panely + 23, 10)
			gprint("Lap %d" % lap, panelx + 3, panely + 33, 10)
		if player.ccut_timer >= 0 :
			var ccutx = V.gfx.SCREEN_WIDTH - 92
			V.gfx.rectangle(Rect2(ccutx, 50, 90, 60), UI_BACKGROUND_COLOR)
			printc("Warning!", ccutx + 45, 53, 8)
			printc("Corner", ccutx + 45, 63, 9)
			printc("cutting", ccutx + 45, 73, 9)
			V.gfx.blit_region(Vector2(ccutx + 45 - 13, 83), Vector2(115, 224), Vector2(26, 16))
	if race.mode == RaceMode.RACE and race.best_lap_timer >= 0 :
		var x = 200
		var y = 0
		V.gfx.rectangle(Rect2(x, y, 100, 18), UI_BACKGROUND_COLOR)
		printc("Best lap %s" % best_lap_driver.short_name, x + 50, y + 1, 9)
		printc(format_time(best_lap_time), x + 50, y + 9, 9)
	# pit stop panel
	if player.pit :
		if not player.pit_done and player.pitstop_timer==0 :
			var x = V.gfx.SCREEN_WIDTH - 110
			V.gfx.rectangle(Rect2(x, 50, 108, 75), UI_BACKGROUND_COLOR)
			printc("Choose tyre", x + 55, 52, 7)
			V.gfx.blit_region(Vector2(x + 55 - 12, 62), Vector2(66, 8), Vector2(24, 12))
			var tx = 0 if race.tyre < 2 else 1 if race.tyre < 4 else 2
			V.gfx.blit_region(Vector2(x + 42, 76), Vector2(224, 192), Vector2(32, 32))
			V.gfx.blit_region(Vector2(x + 38, 76), Vector2(256 + tx * 27, 192), Vector2(27, 32))
			rect(x + 37, 75, 36, 34, 9)
			printc(TYRE_TYPE[race.tyre], x + 55, 114, TYRE_COL[race.tyre])
		else:
			# pitstop timer
			var x = V.gfx.SCREEN_WIDTH - 110
			V.gfx.rectangle(Rect2(x, 50, 108, 50), UI_BACKGROUND_COLOR)
			printc("Pit stop", x+55,60,7)
			if player.pitstop_timer >-0.5 :
				printc(player.pitstop_timer>0.5 and "BRAKE" or "1ST GEAR", x+55,70, 8 if player.pitstop_timer>0.5 else 9)
			printc(format_time(player.pitstop_timer>0 and player.pitstop_delay - player.pitstop_timer or player.pitstop_delay),x+55,83,8)
	elif not race.completed and panel == PANEL_CAR_STATUS :
		var x = V.gfx.SCREEN_WIDTH - 66
		var y = 105
		V.gfx.rectangle(Rect2(x, y, 66, 75), UI_BACKGROUND_COLOR)
		V.gfx.blit_region(Vector2(x+34-15,y+4),Vector2(326,0),Vector2(29,63))
		V.gfx.blit_region(Vector2(x+34-15,y+13),Vector2(355,14),Vector2(7,9),tyre_col[0])
		V.gfx.blit_region(Vector2(x+41,y+13),Vector2(377,14),Vector2(7,9),tyre_col[1])
		V.gfx.blit_region(Vector2(x+34-14,y+52),Vector2(356,48),Vector2(6,8),tyre_col[2])
		V.gfx.blit_region(Vector2(x+41,y+52),Vector2(377,48),Vector2(6,8),tyre_col[3])
		V.gfx.blit_region(Vector2(x+34-8,y+58),Vector2(362,55),Vector2(15,8))
		V.gfx.blit_region(Vector2(x+34-10,y+4),Vector2(360,0),Vector2(19,14))
		V.gfx.print(V.gfx.FONT_4X6, "%3d%%" % tyre_wear[0],Vector2(x+2,y+13))
		V.gfx.print(V.gfx.FONT_4X6, "%3d%%" % tyre_wear[1],Vector2(V.gfx.SCREEN_WIDTH -17,y+13))
		V.gfx.print(V.gfx.FONT_4X6, "%3d%%" % tyre_wear[2],Vector2(x+2,y+52))
		V.gfx.print(V.gfx.FONT_4X6, "%3d%%" % tyre_wear[3],Vector2(V.gfx.SCREEN_WIDTH -17,y+52))

	# ranking board
	var y = 1
	if not race.completed :
		if race.mode == RaceMode.RACE :
			V.gfx.rectangle(Rect2(0, 0, 120, V.gfx.SCREEN_HEIGHT), PAL[17])
			gprint("Lap %d/%d" % [lap,race.lap_count], 12, y, 9)
			V.gfx.line(Vector2(0, y + 9), Vector2(120, y + 9), PAL[6])
			y = y + 11;
			var leader_time = format_time(time > 0 and time or 0)
			var rank=1
			for car in race.ranks :
				gprint("%2d" % rank, 1, y, 7 if car.is_player else 6)
				rectfill(17, y, 23, y + 8, car.color)
				gprint(car.driver.short_name, 26, y, 7 if car.is_player else 6)
				gprint(TYRE_TYPE[car.tyre_type].substr(1,1),50,y,TYRE_COL[car.tyre_type])
				gprint("%7s" % (leader_time if rank == 1 else car.time), 56, y, car.is_player and 7 or 6)
				if car.race_finished :
					V.gfx.blit_region(Vector2(113, y), Vector2(149, 0), Vector2(6, 8))
				y = y + 9
				rank += 1
			V.gfx.line(Vector2(0, y), Vector2(120, y), PAL[6])
			y = y + 3
		elif race.mode == RaceMode.TIME_ATTACK :
			V.gfx.rectangle(Rect2(0, 0, 120, 100), PAL[17])
			gprint("%2d %6s" % [lap, format_time(max(0,time))], 20, y, 9)
			y = y + 10
			for i in range(player.lap_times.size()-1,-1,-1) :
				var t = player.lap_times[i]
				if y > 73 :
					break
				gprint("%2d %6s" % [i, format_time(t)], 20, y, 9)
				y = y + 10
			if player.best_time > 0.0 :
				gprint("Best %6s" % format_time(player.best_time), 4, y, 8)
	else:
		# race results
		V.gfx.rectangle(Rect2(30, 10, V.gfx.SCREEN_WIDTH - 52, (DRIVERS.size() + 4) * 10), PAL[17])
		gprint("Classification          Time   Best", 61, 20, 6)
		V.gfx.line(Vector2(30, 30), Vector2(V.gfx.SCREEN_WIDTH - 22, 30), PAL[6])
		var rank = 1
		for car in race.ranks :
			var cy = 26 + rank * 10
			gprint("%2d %s %15s  %7s" % [rank, TEAMS[car.driver.team].short_name, car.driver.name, \
				format_time(car.delta_time) if rank == 1  else car.time],
				53, cy, 7 if car.is_player else 22)
			if car.best_time > 0.0 :
				gprint(format_time(car.best_time), 309, cy, car.driver.is_best and 8 or (car.is_player and 7 or 22))
			rectfill(69, cy - 1, 75, cy + 7, car.color)
			if car.race_finished :
				V.gfx.blit_region(Vector2(233, cy), Vector2(149, 0), Vector2(6, 8))
			rank += 1
	# lap times
	if not race.completed and race.mode == RaceMode.RACE :
		if lap > 1 and player.lap_times[lap - 1] :
			var is_personal_best = player.lap_times[lap - 1] == player.best_time
			if lap > race.lap_count or time < player.lap_times[lap - 1] + 5 :
				if lap > race.lap_count or frame % 10 > 2 :
					gprint("Lap   %s" % format_time(player.lap_times[lap - 1]), 4, y,
						player.driver.is_best and 8 or (is_personal_best and 3 or 7))
				y = y + 18
			else:
				gprint("Lap   %s" % format_time(time > 0 and time - player.delta_time or 0), 4, y, 7)
				y = y + 9
				gprint("Prev  %s" % format_time(player.lap_times[lap - 1]), 4, y,
					player.lap_times[lap - 1] == best_lap_time and 8 or (is_personal_best and 3 or 7))
				y = y + 9
		else:
			gprint("Lap   %s" % format_time(time > 0 and time - player.delta_time or 0), 4, y, 7)
			y = y + 9
		if player.best_time > 0.0 :
			gprint("PBest %s" % format_time(player.best_time), 4, y, player.driver.is_best and 8 or 3)
			y = y + 9
		if best_lap_time > 0.0 :
			gprint("RBest %s" % format_time(best_lap_time), 4, y, 7)
			y = y + 9
			gprint(best_lap_driver.name, 4, y, 7)
		if player.wrong_way > 4 :
			gprint("Wrong way!", 152, 104, 8)

	# starting lights
	if time < 0 :
		var count = -floor(time)
		var lit = 5 - count
		for i in range(1,lit) :
			V.gfx.blit_region(Vector2(217 + i * 22, 44), Vector2(34, 0), Vector2(20, 20))
		for i in range(lit + 1, 4) :
			V.gfx.blit_region(Vector2(217 + i * 22, 44), Vector2(14, 0), Vector2(20, 20))
	if player.collision > 0 or race.completed :
		player.collision -= 0.1
	return Vector2i(minseg, maxseg)

class ReplayFrame:
	var pos: Vector2
	var vel: Vector2
	var angle: float
	var accel: float
	func _init(ppos:Vector2, pvel:Vector2, pangle:float, paccel: float):
		self.pos=ppos
		self.vel=pvel
		self.angle=pangle
		self.accel=paccel

class PitCrewData:
	var front: Vector2
	var fl: Vector2
	var fr: Vector2
	var rl: Vector2
	var rr: Vector2

class Race extends GameMode :
	var vecmap : Array[TrackSection] = []
	var mapsize : int
	var lap_count : int
	var live_cars : int
	## race is finished (a car crossed the finish line)
	var is_finished: bool
	## the player finished the race
	var completed: bool
	## time since race start
	var time : float
	var panel_timer: int
	var best_lap_timer : int
	var start_timer : bool
	var difficulty : int
	## ghost replay data on time attack
	var record_replay : Array[ReplayFrame]
	## which frame are we replaing
	var replay_frame: int
	## first segment containing the pit entry lane
	var first_pit : int
	var cars: Array[Car]
	var player: Car
	var ranks: Array
	var pits: Array[PitCrewData]
	var mode : RaceMode
	func init_race(ptrack_num : int, prace_mode : int, plap_count : int, pdifficulty):
		P.race_init(self, ptrack_num, prace_mode, plap_count, pdifficulty)
	func update():
		P.race_update(self)
	func draw():
		P.race_draw(self)
	func generate_track():
		P.race_generate_track(self)
	func restart():
		P.race_restart(self)
	func get_segment_from_section(sec: int) -> int :
		for i in range(0,self.vecmap.size()) :
			if self.vecmap[i].section == sec :
				return i
		return -1
	func get_vec_from_vecmap(seg: int) -> Vector2:
		seg = posmod(seg, self.mapsize)
		var v = self.vecmap[seg + 1]
		return Vector2(v.pos)
	func get_data_from_vecmap(seg) -> TrackSection:
		seg = posmod(seg, self.mapsize)
		return self.vecmap[seg]

static func rotate_point(v: Vector2, pico_angle: float, o: Vector2) -> Vector2 :
	return Vector2(
		pico_cos(pico_angle) * (v.x - o.x) - pico_sin(pico_angle) * (v.y - o.y) + o.x, 
		pico_sin(pico_angle) * (v.x - o.x) + pico_cos(pico_angle) * (v.y - o.y) + o.y)

## circular buffer
class CircBuf:
	var start : int = 0
	var end : int = 0
	var size : int
	var data: Array[Variant] = []
	func _init(psize: int):
		self.size=psize
		for i in range(0,psize):
			data.append(null)
	func push(value: Variant):
		# add a value to the end of a circular buffer
		data[end] = value
		end = (end + 1) % size
		if end == start :
			start = (start + 1) % size
	func pop() -> Variant :
		# remove a value from the start of the circular buffer, and return it
		var v = data[start]
		start = start + 1 % size
		return v
	func get_at(index: int) -> Variant : 
		# return a value from the circular buffer by index. 0 = start, -1 = end
		return data[posmod(index, size)]

static func pausemenu_update(menu: PauseMenu):
	frame += 1
	if V.inp.up_pressed() :
		menu.selected -= 1
	if V.inp.down_pressed() :
		menu.selected += 1
	menu.selected = clamp(menu.selected, 1, 3)
	if V.inp.action1_pressed() :
		if menu.selected == 1 :
			set_game_mode(menu.game)
		elif menu.selected == 2 :
			set_game_mode(menu.game)
			V.snd.stop_channel(1)
			menu.game.player.freq=0.0
			V.snd.stop_channel(2)
			V.snd.stop_channel(3)
			menu.game.restart()
		elif menu.selected == 3 :
			V.snd.stop_channel(1)
			menu.game.player.freq=0.0
			V.snd.stop_channel(2)
			V.snd.stop_channel(3)
			camera_angle = 0.25
			set_game_mode(intro)

static func pausemenu_draw(menu: PauseMenu) :
	menu.game.draw.call(menu.game)
	rectfill(115, 40, 233, 88, 1)
	gprint("Paused", 120, 44, 7)
	gprint("Continue", 120, 56, 7 if menu.selected == 1 and frame % 4 < 2 else 6)
	gprint("Restart race", 120, 66, 7 if menu.selected == 2 and frame % 4 < 2 else 6)
	gprint("Exit", 120, 76, 7 if menu.selected == 3 and frame % 4 < 2 else 6)

class PauseMenu extends GameMode:
	var selected: int = 1
	var game: GameMode
	func _init(pgame: GameMode):
		self.game=pgame
	func update():
		P.pausemenu_update(self)
	func draw():
		P.pausemenu_draw(self)

static func compmenu_update(menu : CompletedMenu):
	frame += 1
	if not V.inp.action1() :
		menu.ready = true
	if V.inp.up_pressed() :
		menu.selected -= 1
	if V.inp.down_pressed() :
		menu.selected += 1
	menu.selected = clamp(menu.selected, 1, 2)
	if menu.ready and V.inp.action1_pressed() :
		if menu.selected == 1 :
			set_game_mode(menu.game)
			menu.game.restart()
		else:
			camera_angle = 0.25
			set_game_mode(intro)

static func compmenu_draw(menu : CompletedMenu):
	menu.game.draw.call(menu.game)
	gprint("Retry", 53, 204, 8 if menu.selected == 1 and frame % 16 < 8 else 6)
	gprint("Exit", 53, 214, 8 if menu.selected == 2 and frame % 16 < 8 else 6)


class CompletedMenu extends GameMode :
	var selected: int = 1
	var game: GameMode
	func _init(pgame: GameMode):
		self.game=pgame
	func update():
		P.compmenu_update(self)
	func draw():
		P.compmenu_draw(self)

static func displace_point(p: Vector2, o: Vector2, factor: float) -> Vector2:
	return p + (p - o) * factor

static func displace_line(a: Vector2, b: Vector2, o: Vector2, factor: float, col: int) :
	a = displace_point(a, o, factor)
	b = displace_point(b, o, factor)
	linevec(a, b, col)

static func linevec(a: Vector2, b: Vector2, col: int):
	line(a.x, a.y, b.x, b.y, col)

static func format_time(t):
	return "%02d:%02d" % [t,(t - floor(t)) * 100]

static func printr(text, x, y, c):
	var l = text.length()
	gprint(text, x - l * 8, y, c)

static func printc(text, x, y, c):
	var l = text.length()
	gprint(text, x - l * 4, y, c)

static func onscreen(p):
	p = cam2screen(p)
	return p.x >= -30 and p.x <= V.gfx.SCREEN_WIDTH + 30 and p.y >= -30 and p.y <= V.gfx.SCREEN_HEIGHT + 30

static func inside_rect(x, y, rx, ry, rw, rh):
	return x >= rx and y >= ry and x < rx + rw and y < ry + rh


static func side_of_line(v1, v2, px, py):
	return (px - v1.x) * (v2.y - v1.y) - (py - v1.y) * (v2.x - v1.x)

static func car_lap_seg(s1, s2):
	var pseg = s2.current_segment
	while abs(s1 + mapsize - pseg) < abs(s1 - pseg) :
		s1 = s1 + mapsize
	while abs(s1 - mapsize - pseg) < abs(s1 - pseg) :
		s1 = s1 - mapsize
	return s1

static func find_segment_from_pos(race: Race, pos, last_good_seg):
	for seg in range(0, mapsize - 2) :
		var pseg = last_good_seg + seg if last_good_seg != null else seg + 1
		var seglostpoly = get_segment(race, pseg, true)
		if seglostpoly and point_in_polygon(seglostpoly, pos) :
			return pseg

static func get_segment(race: Race, seg : int, enlarge : bool, for_collision: bool = false) -> Array[IntersectionData] :
	seg = posmod(seg, mapsize)
	# returns the 4 points of the segment
	var nextv = race.get_data_from_vecmap(seg + 2)
	var v = race.get_data_from_vecmap(seg + 1)
	var lastv = race.get_data_from_vecmap(seg)

	var front = v.front
	var side = v.side
	var lastfront = lastv.front
	var lastside = lastv.side

	var lastwl = lastv.ltyp & 7 == 0 and lastv.w + 4 or lastv.w + 40
	var lastwr = lastv.rtyp & 7 == 0 and lastv.w + 4 or lastv.w + 40
	var wl = v.ltyp & 7 == 0 and v.w + 4 or v.w + 40
	var wr = v.rtyp & 7 == 0 and v.w + 4 or v.w + 40
	if for_collision :
		var lpit_entry
		var rpit_entry
		if not lastv.has_lrail :
			if (v.ltyp / 8) as int >= OBJ_PIT_EXIT1 :
				lastwl = lastv.w + 10 + 7 * (3 - ((v.ltyp / 8) as int - OBJ_PIT_EXIT1))
			elif (lastv.ltyp / 8) as int >= OBJ_PIT_ENTRY1 :
				lpit_entry = (lastv.ltyp / 8) as int - OBJ_PIT_ENTRY1
				lastwl = lastv.w + 16 + 7 * lpit_entry
			else:
				lastwl = 200
		if not lastv.has_rrail :
			if (v.rtyp / 8) as int >= OBJ_PIT_EXIT1 :
				lastwr = lastv.w + 10 + 7 * (3 - ((v.rtyp / 8) as int - OBJ_PIT_EXIT1))
			elif (lastv.rtyp / 8) as int >= OBJ_PIT_ENTRY1 :
				rpit_entry = (lastv.rtyp / 8) as int - OBJ_PIT_ENTRY1
				lastwr = lastv.w + 16 + 7 * rpit_entry
			else:
				lastwr = 200
		if not v.has_lrail :
			if (nextv.ltyp / 8) as int == OBJ_PIT_EXIT1 :
				lastwl = lastv.w + 31
				wl = lastwl
			elif (v.ltyp / 8) as int >= OBJ_PIT_EXIT1 :
				wl = v.w + 10 + 7 * (2 - ((v.ltyp / 8) as int - OBJ_PIT_EXIT1))
			elif (v.ltyp / 8) as int >= OBJ_PIT_ENTRY1 :
				wl = v.w + 16 + 7 * ((v.ltyp / 8) as int - OBJ_PIT_ENTRY1)
			else:
				wl = 200
		elif lpit_entry == 2 :
			wl = lastwl
		if not v.has_rrail :
			if (nextv.rtyp / 8) as int == OBJ_PIT_EXIT1 :
				lastwr = lastv.w + 31
				wr = lastwr
			elif (v.rtyp / 8) as int >= OBJ_PIT_EXIT1 :
				wr = v.w + 10 + 7 * (2 - ((v.rtyp / 8) as int - OBJ_PIT_EXIT1))
			elif (v.rtyp / 8) as int >= OBJ_PIT_ENTRY1 :
				wr = v.w + 16 + 7 * ((v.rtyp / 8) as int - OBJ_PIT_ENTRY1)
			else:
				wr = 200
		elif rpit_entry == 2 :
			wr = lastwr
	if enlarge :
		lastwl = lastwl * 2.5
		lastwr = lastwr * 2.5
		wl = wl * 2.5
		wr = wr * 2.5
	var lastoffsetl = lastside * lastwl
	var lastoffsetr = lastside * lastwr
	var offsetl = side * wl
	var offsetr = side * wr
	var front_left : IntersectionData = v + offsetl
	var front_right : IntersectionData = v - offsetr
	var back_left : IntersectionData = lastv + lastoffsetl
	var back_right : IntersectionData = lastv - lastoffsetr
	if (front_left - v).dot( lastfront) < (back_left - v).dot(lastfront) :
		var v2 = intersection(front_left.point, front_right.point, back_left.point, back_right.point)
		front_left = v2
		back_left = v2
	if (front_right - v).dot(lastfront) < (back_right - v).dot(lastfront) :
		var v3 = intersection(front_left.point, front_right.point, back_left.point, back_right.point)
		front_right = v3
		back_right = v3
	return [ back_left, back_right, front_right, front_left ]

class IntersectionData:
	var point: Vector2
	func _init(x:float, y:float): 
		self.point=Vector2(x,y)

# intersection between segments [ab] and [cd]
static func intersection(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> IntersectionData:
	var e = (a.x - b.x) * (c.y - d.y) - (a.y - b.y) * (c.x - d.x)
	if e != 0 :
		var i = a.x * b.y - a.y * b.x
		var j = c.x * d.y - c.y * d.x
		var x = (i * (c.x - d.x) - j * (a.x - b.x)) / e
		var y = (i * (c.y - d.y) - j * (a.y - b.y)) / e
		return IntersectionData.new(x, y)
	return null

static func midpoint(a: Vector2, b: Vector2) -> Vector2:
	return Vector2((a.x + b.x) / 2, (a.y + b.y) / 2)

static func get_normal(a: Vector2, b: Vector2) -> Vector2:
	return (a-b).orthogonal().normalized()

static func distance_from_line2(p: Vector2, v: Vector2, w: Vector2) -> float :
	var l2 = v.distance_squared_to(w)
	if (l2 == 0) :
		return p.distance_squared_to(v)
	var t = ((p.x - v.x) * (w.x - v.x) + (p.y - v.y) * (w.y - v.y)) / l2
	if t < 0 :
		return p.distance_squared_to(v)
	elif t > 1 :
		return p.distance_squared_to(w)
	return p.distance_squared_to(Vector2(v.x + t * (w.x - v.x), v.y + t * (w.y - v.y)))

static func distance_from_line(p, v, w) -> float :
	return sqrt(distance_from_line2(p, v, w))

static func point_in_polygon(pgon:Array[Vector2], t:Vector2) -> bool :
	var yflag0
	var yflag1
	var inside_flag: bool
	var vtx0
	var vtx1

	var numverts = pgon.size()

	vtx0 = pgon[numverts-1]
	vtx1 = pgon[0]

	# get test bit for above/below x axis
	yflag0 = (vtx0.y >= t.y)
	inside_flag = false

	for i in range(1, numverts) :
		yflag1 = (vtx1.y >= t.y)

		if yflag0 != yflag1 :
			if ((vtx1.y - t.y) * (vtx0.x - vtx1.x) >= (vtx1.x - t.x) * (vtx0.y - vtx1.y)) == yflag1 :
				inside_flag = not inside_flag
		# move to the next pair of vertices, retaining info as possible.
		yflag0 = yflag1
		vtx0 = vtx1
		vtx1 = pgon[i]

	return inside_flag

class Collision:
	var rvec: Vector2
	var pen : float
	var point : Vector2
	func _init(prvec:Vector2, ppen:float, ppoint:Vector2) :
		self.rvec=prvec
		self.pen=ppen
		self.point=ppoint

class Segment :
	var a: Vector2
	var b: Vector2
	func _init(pa:Vector2, pb:Vector2) :
		self.a = pa
		self.b = pb

static func check_collision(points: Array[Vector2], segments: Array[Segment]) -> Collision :
	if segments != null :
		for point in points :
			for seg in segments :
				if side_of_line(seg.a, seg.b, point.x, point.y) < 0 :
					var rvec = get_normal(seg.a, seg.b)
					var penetration = distance_from_line(point, seg.a, seg.b)
					return Collision.new(rvec, penetration, point)
	return null

const TRACKS = [
	############
	# Interlochs
	############
	[1337,
	12,128,28,48,8,0,0,
	1,128,28,32,0,0,0,
	# S : Senna
	4,130,28,0,3,0,0, 3,137.4,28,0,3,0,0, 2,126,28,0,3,0,0, 2,118.6,28,0,3,0,0, 4,129.5,28,0,0,0,0,
	# curva : sol
	8,130.9,28,0,1,0,0,
	# reta oposta
	25,128.0,28,24,1,0,0,
	# subida : lago
	4,135.0,28,24,3,0,0, 3,128.0,28,24,3,0,0, 6,130.6,28,1,3,0,0, 12,128.0,28,1,3,0,0,
	# ferradura
	4,125.0,28,3,1,0,0, 4,122.0,28,3,1,0,0, 3,128.0,28,3,1,0,0, 3,126.0,28,3,1,0,0,
	# laranja
	2,115.9,28,3,1,0,0, 3,126.5,28,1,1,0,0,
	# pinheirinho
	7,134.6,28,1,1,0,0, 4,128.0,28,1,1,0,0, 4,124.6,28,1,1,0,0,
	# cotovelo
	3,115.4,28,1,1,0,0, 4,128.0,28,1,1,0,0,
	# mergulho
	7,131.8,28,1,3,0,0, 7,127.8,28,1,1,0,0,
	# juncao
	3,138.1,28,1,3,0,0, 4,128.0,28,1,1,0,0, 2,132.7,28,1,1,0,0, 6,128.0,28,1,1,0,0,
	# subida : boxes
	7,130.3,28,1,16,0,0, 7,128.0,28,24,16,0,0,
	# arquibancadas
	6,129.3,28,1,16,0,0, 10,128.0,28,0,16,0,0,
	0,0,0,0,0,0,0],
	############
	# Manzana
	############
	[ 1337, 4, 128, 32, 25, 48, 0, 0, 2, 128, 32, 9, 48, 0, 0, 6, 128, 32, 9, 56, 0, 0, 4, 128, 32, 1, 1, 0, 0, 4, 128, 32, 17, 25, 0, 0, 2, 128, 32, 25, 25, 0, 0, 2, 128, 32, 1, 1, 0, -1,
	# prima variante
	3, 120, 32, 1, 1, -1, 3, 3, 140, 32, 1, 17, 3, 0,
	# curva biassono
	2, 126, 32, 1, 0, 0, 0, 2, 126, 32, 17, 24, 1, 0, 2, 126, 32, 25, 24, 0, 0,
	6, 128, 32, 25, 24, 0, 0, 8, 126, 32, 26, 24, 0, 0, 6, 127, 32, 26, 24, 0, 0, 6, 128, 32, 0, 24, 0, 0, 1, 128, 32, 32, 24, 0, 0, 2, 128, 32, 0, 24, 0, 0, 1, 128, 32, 25, 24, 1, 0,
	# seconda variante
	2, 137, 32, 25, 27, 1, 0, 3, 123, 32, 26, 27, 0, 0, 2, 128, 32, 24, 16, 0, 0, 8, 128, 32, 24, 24, 0, 0,
	# prima curva di lesmo
	9, 125, 32, 26, 24, 0, 0, 8, 128, 32, 25, 24, 0, 0,
	# seconda curva di lesmo
	4, 123.0, 32, 26, 24, 0, 0, 4, 128, 32, 26, 24, 0, 0, 8, 128, 32, 24, 24, 0, 0,
	# curva del serraglio
	5, 129, 32, 24, 24, 0, 0, 16, 128, 32, 24, 24, 0, 0,
	# variante ascari
	5, 131, 32, 25, 26, 0, 0,
	7, 125, 32, 26, 25, 0, 0, 6, 131, 32, 25, 18, 0, 0, 2, 128, 32, 0, 0, 0, 0, 6, 128, 32, 0, 8, 0, 0, 9, 128, 32, 0, 0, 0, 0, 1, 128, 32, 32, 0, 0, 0, 7, 128, 32, 0, 0, 0, 0, 1, 128, 32, 32, 0, 0, 0, 1, 128, 32, 0, 0, 0, 0,
	2, 128, 32, 24, 24, 0, 0, 6, 128, 32, 16, 24, 0, 0, 2, 128, 32, 8, 0, 0, 0,
	# curva parabolica
	5, 121.1, 32, 27, 0, 0, 0, 7, 127.1, 32, 27, 0, 0, 0, 6, 126.8, 32, 26, 24, 0, 0, 2, 126.8, 32, 10, 24, 0, 0,
	6, 128.0, 32, 10, 24, 0, 0, 5, 128.0, 32, 9, 56, 0, 0, 1, 128.0, 32, 41, 56, 0, 0, 10, 128, 32, 9, 48, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
]

const SFX = [
	# starting light
	"16 A.20F5",
	# race start
	"16 A.40F5",
	# kerb
	"4 F.08F3 ......",
	# big hit
	"3 C.6650 G.5650 D#5650 C.5640 E.4630 C#3620 F#2620 G#1610 C#3610 C#1310",
	# small hit
	"3 D#6650 C.6610 D#4610 D.2413"
]

# pico8 instruments
const INST_TRIANGLE ={TYPE="Oscillator",OVERTONE=1.0,TRIANGLE=1.0,METALIZER=0.85,NAME="triangle"}
const INST_TILTED ={TYPE="Oscillator",OVERTONE=1.0,TRIANGLE=0.5,SAW=0.1,NAME= "tilted"}
const INST_SAW ={TYPE="Oscillator",OVERTONE=1.0,SAW=1.0,ULTRASAW=1.0,NAME="saw"}
const INST_SQUARE ={TYPE="Oscillator",OVERTONE=1.0,SQUARE=0.5,NAME="square"}
const INST_PULSE ={TYPE="Oscillator",OVERTONE=1.0,SQUARE=0.5,PULSE=0.5,TRIANGLE=1.0,METALIZER=1.0,OVERTONE_RATIO=0.5,NAME="pulse"}
const INST_ORGAN ={TYPE="Oscillator",OVERTONE=0.5,TRIANGLE=0.75,NAME="organ"}
const INST_NOISE ={TYPE="Oscillator", NOISE=1.0,NOISE_COLOR=0.2,NAME="noise"}
const INST_PHASER ={TYPE="Oscillator",OVERTONE=0.5,METALIZER=1.0,TRIANGLE=0.7,NAME="phaser"}
# samples
const INST_ENGINE = {TYPE="Sample",ID=1,FILE="high_rpm16.wav", FREQ=554, LOOP_START=0}
const INST_TRIBUNE = {TYPE="Sample",ID=2,FILE="tribune.wav", FREQ=440, LOOP_START=0}
const INST_TYRE = {TYPE="Sample",ID=3,FILE="screech.wav", FREQ= 440, LOOP_START= 0}
const INST_PIT = {TYPE="Sample",ID=4,FILE="pit.wav", FREQ= 440}
