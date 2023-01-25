X_OFFSET=128
Y_OFFSET=40
FONT_WIDTH=6

LAYER_SCREEN=0
LAYER_SPRITESHEET=1

settings = {1,1,2,3}
next_game_state=3
logo_timer=60
musicplaying=false
total_sets_list={"1","3","5"}
chars={}

-- game data
parse_nibble_offset=0

CHARS_INDEX=" -0123456789abcdefghijklmnopqrstuvwxyz,"

PI = math.pi

-- player control type
PLAYER_NONE=0
PLAYER_HUMAN=1
PLAYER_AI=2

BEHIND_POINT=0
BEHIND_LINE=1

DRAW_BALL=0
DRAW_BALL_SHADOW=1
DRAW_PLAYER=2
DRAW_PARTICLE=3
DRAW_LINE=4

MENU_NONE = 0
MENU_GAME_SETTINGS = 1
MENU_READY = 2
MENU_BACK = 3

MSG_NONE=0
MSG_MESSAGE = 1
MSG_SET_SCORE=2
MSG_MATCH_SCORE=3

TIMER_NONE=0
TIMER_CONTINUE=1
TIMER_NEW_GAME=2
TIMER_MAIN_MENU=3

-- PICO-8 compatibility layer

col=function(r,g,b)
    return {r=r/255,g=g/255,b=b/255}
end
PAL = {
    col(0, 0, 1),       --1
    col(29, 43, 83),    --2
    col(126, 37, 83),   --3
    col(0, 135, 81),    --4
    col(171, 82, 54),   --5
    col(95, 87, 79),    --6
    col(194, 195, 199), --7
    col(255, 241, 232), --8
    col(255, 0, 77),    --9
    col(255, 163, 0),   --10
    col(255, 236, 39),  --11
    col(0, 228, 54),    --12
    col(41, 173, 255),  --13
    col(131, 118, 156), --14
    col(255, 119, 168), --15
    col(255, 204, 170), --16
}

math.round=function(v)
    return math.floor(v+0.5)
end

function cls(pal)
    local col = PAL[pal+1]
    gfx.clear(col.r,col.g,col.b)
end

function sspr(sx,sy,sw,sh,dx,dy)
    gfx.blit(math.floor(sx),math.floor(sy),math.floor(sw),math.floor(sh),
        X_OFFSET+math.floor(dx),Y_OFFSET+math.floor(dy),0,0,false,false,1,1,1)
end

function sspr2(sx,sy,sw,sh,dx,dy,dw,dh,hflip,vflip)
    gfx.blit(sx,sy,sw,sh,
        X_OFFSET+dx,Y_OFFSET+dy,dw,dh,hflip,vflip,1,1,1)
end

function rect(x0,y0,x1,y1,pal)
    local col=PAL[pal+1]
    local x0 = x0 + X_OFFSET
    local x1 = x1 + X_OFFSET
    local y0 = y0 + Y_OFFSET
    local y1 = y1 + Y_OFFSET
    gfx.line(x0,y0,x1,y0,col.r,col.g,col.b)
    gfx.line(x1,y0,x1,y1,col.r,col.g,col.b)
    gfx.line(x1,y1,x0,y1,col.r,col.g,col.b)
    gfx.line(x0,y1,x0,y0,col.r,col.g,col.b)
end

function atan2(dx, dy)
    local r = math.atan(dy,dx)* 0.15915494; -- 1/(2PI)
    if r < 0 then
        return -r
    else
        return 1-r
    end
end

function rectfill(x0,y0,x1,y1,pal)
    local col=PAL[pal+1]
    local x0 = x0 + X_OFFSET
    local x1 = x1 + X_OFFSET
    local y0 = y0 + Y_OFFSET
    local y1 = y1 + Y_OFFSET
    gfx.rectangle(x0, y0, x1-x0+1, y1-y0+1, col.r,col.g,col.b)
end

function circfill(x,y,r,pal)
    local col=PAL[pal+1]
    local x = x + X_OFFSET
    local y = y + Y_OFFSET
    gfx.disk(x,y,r,col.r,col.g,col.b)
end

function pico_print(txt,x,y,pal)
    local col=PAL[pal+1]
    local x = x + X_OFFSET
    local y = y + Y_OFFSET
    gfx.print(txt,x,y,col.r,col.g,col.b)
end

function set_small_font()
	gfx.activate_font(LAYER_SPRITESHEET,0,177,57,4, 3,4, "1234567890playercu,")
end

function set_standard_font()
	gfx.activate_font(LAYER_SPRITESHEET, 0, 129, 126, 40, 6, 8,
        "@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~¤!\"#$%&'()*+,-./0123456789:;<=>?")
end

-- 3D MATH
function lerp(a,b,t)
	return a+(b-a)*t
end

function smooth_lerp(a,b,t)
	return lerp(a,b,t*t*(3-2*t))
end

function point_in_rect(p,r_min,r_max)
	return not (p.x < r_min.x or p.x > r_max.x or p.z < r_min.z or p.z > r_max.z)
end

function new_vector3d(px,py,pz)
    return {x=px,y=py,z=pz}
end

function v3d_add(a,b)
    return new_vector3d(a.x+b.x, a.y+b.y, a.z+b.z)
end

function v3d_sub(a,b)
    return new_vector3d(a.x-b.x, a.y-b.y, a.z-b.z)
end

function v3d_mul(a,b)
    return new_vector3d(a.x*b.x, a.y*b.y, a.z*b.z)
end

function v3d_mul_num(a,b)
    return new_vector3d(a.x*b, a.y*b, a.z*b)
end

function v3d_dot(a,b)
	d = v3d_mul(a,b)
	return d.x+d.y+d.z
end

function v3d_cross(a,b)
	return new_vector3d(a.y*b.z-a.z*b.y,-(a.x*b.z-a.z*b.x),a.x*b.y-a.y*b.x)
end

function v3d_normal(a)
	local l = math.sqrt(v3d_dot(a,a))
	if l == 0 then
		return new_vector3d(0,0,0)
    end
    local invl = 1.0/l
	return v3d_mul_num(a,invl)
end

function v3d_lerp(a,b,t)
	return new_vector3d(lerp(a.x,b.x,t),lerp(a.y,b.y,t),lerp(a.z,b.z,t))
end

function v3d_length(a)
	local d = v3d_dot(a,a)

	if d >= 0 then
		return math.sqrt(d)
    end
	return 32761
end

function v3d_distance2d(a,b)
	return v3d_length(new_vector3d(a.x-b.x,0,a.z-b.z))
end

function orient2d_xy(a,b,c)
	return (a.x-c.x) * (b.y-c.y) - (a.y-c.y) * (b.x-c.x)
end

function orient2d_xz(a,b,c)
	return (a.x-c.x) * (b.z-c.z) - (a.z-c.z) * (b.x-c.x)
end

function matrix_rotate_x(a)
    local sa=-math.sin(a*2*PI)
    local ca=math.cos(a*2*PI)
	return {{1,0,0},{0,sa,ca},{0,ca,-sa}}
end

function matrix_rotate_y(a)
    local sa=-math.sin(a*2*PI)
    local ca=math.cos(a*2*PI)
	return {{ca,0,sa},{-sa,0,ca},{0,1,0}}
end

function matrix_mul_add_row(m_row,v)
	return m_row[1]*v.x+m_row[2]*v.y+m_row[3]*v.z
end

function matrix_mul_add(m,v)
	return new_vector3d(matrix_mul_add_row(m[1],v),matrix_mul_add_row(m[2],v),matrix_mul_add_row(m[3],v))
end

function translate_to_view(v)
	local t = matrix_mul_add(mx,matrix_mul_add(my,v3d_add(camera_pos,v)))
	t.z = t.z + 192; -- camera fov
	return new_vector3d(
        math.round(t.z/camera_distance*t.x+64),
        math.round(t.z/camera_distance*t.y+64),
        t.z)
end

function behind_point(p1,p2)
	return p2.pos_scr.z <= p1.pos_scr.z
end

function behind_lines(l,p)
    local pt=l.points[1]
	if pt.p1.x < pt.p2.x then
		return orient2d_xy(pt.p1,pt.p2,p.pos_scr) < 0
    end
	return orient2d_xy(pt.p1,pt.p2,p.pos_scr) > 0
end

function behind(o1,o2)
	if o1.behind_type == BEHIND_POINT then
		return behind_point(o1,o2)
	else
		return behind_lines(o1,o2)
    end
end

function new_polygon(points,pcol)
	local tab = {}
	for i=1,#points,3 do
		table.insert(tab,new_vector3d(points[i],points[i+1],points[i+2]))
    end
	return {
		points_scr = {},
		points_3d = tab,
		col = pcol
	}
end
-- TILE DATA READING
function read_nibble()
    local val=TILE_MAP[parse_nibble_offset//2 + 1]
    if parse_nibble_offset % 2 == 1 then
        val = val & 0xf
    else
        val = (val & 0xf0) >> 4
    end
    parse_nibble_offset = parse_nibble_offset + 1
    return val
end

function read_bool()
    return read_nibble() ~= 0
end

function read_char()
    val = (read_nibble() <<4) + read_nibble()
    if val > 0x80 then
        val = val - 256
    end
    return val
end

function read_float8()
    return read_char() / 16.0
end

function read_v3dchar()
    return new_vector3d(read_char(),read_char(),read_char())
end

function read_v3dchar_div2()
    return new_vector3d(read_char()/2,read_char()/2,read_char()/2)
end

function read_sprite_data()
    local s = {
        width= read_nibble(),
        height= read_nibble(),
        sprites={},
    }
    local sprite_count=read_char()
    for i=1,sprite_count do
        table.insert(s.sprites,{
            x= read_char(),
            y= read_char(),
            offx=read_float8(),
            offy=read_float8(),
            hflip=read_bool(),
        })
    end
    return s
end

function read_anim_data()
	local anim = {
        loop = read_bool(),
        on_finish = read_nibble(),
        frames = {},
    }
    local frame_count= read_nibble()
	for f=1,frame_count do
		local frame = { to_time = read_nibble(), limbs={} }
        local limb_count = read_nibble()
		for l=1,limb_count do
			table.insert(frame.limbs, {
                    model=read_nibble(),
                    pos=new_vector3d(read_float8(),read_float8(),read_float8()),
                    angle=read_float8(),
                    sprite=read_nibble()
                }
            )
        end
		table.insert(anim.frames,frame)
    end
	return anim
end

function read_court_data()
	local d = {}
	for i=0,1 do
		local s = {}
		for j=0,3 do
			table.insert(s,{
				start_pos = read_v3dchar(),
				start_angle = read_float8(),
				move_region = {
                    xmin=read_char(),
                    xmax=read_char(),
                    zmin=read_char(),
                    zmax=read_char()
                },
				valid_hit_region = {
                    min=read_v3dchar(),
                    max=read_v3dchar()
                }
			})
        end
		table.insert(d,s)
    end
	return d
end

function read_line_data()
	local count = read_char()
    local result = {}
	for i=1,count do
		table.insert(result,{
            p1=read_v3dchar_div2(),
            p2=read_v3dchar_div2(),
            pal=read_nibble(),
        })
    end
	return result
end
-- TENNIS
function draw_lines(lines)
	for _,l in pairs(lines.points) do
        local col=PAL[l.pal+1]
		gfx.line(l.p1.x+X_OFFSET,l.p1.y+Y_OFFSET,l.p2.x+X_OFFSET,l.p2.y+Y_OFFSET,
            col.r,col.g,col.b)
    end
end

function draw_polygon(poly)
	local points=poly.points_scr
    local col = PAL[poly.col+1]
    local p0=points[1]
    local p1=points[2]
    local p2=points[3]
    local p3=points[4]
    gfx.triangle(
        X_OFFSET+p0.x,Y_OFFSET+p0.y,
        X_OFFSET+p1.x,Y_OFFSET+p1.y,
        X_OFFSET+p2.x,Y_OFFSET+p2.y,
        col.r,col.g,col.b)
    gfx.triangle(
        X_OFFSET+p0.x,Y_OFFSET+p0.y,
        X_OFFSET+p2.x,Y_OFFSET+p2.y,
        X_OFFSET+p3.x,Y_OFFSET+p3.y,
        col.r,col.g,col.b)
end

function new_sprite_container(sprite_set,x,y,z,pangle)
    return {
        sprites=sprite_set,
        pos= new_vector3d(x,y,z),
        angle= pangle,
        pos_prev=new_vector3d(x,y,z),
        angle_prev= pangle,
    }
end

function add_player(controller)
    setting=inactive_player_settings[1]
	table.remove(inactive_player_settings,1)
    setting.controller = controller
    table.insert(active_player_settings,setting)
	if controller>= 0 then
        for i=1,#inactive_controllers do
            if inactive_controllers[i] == controller then
                return i
            end
        end
    end
    return -1
end

function continue_match()
	service.mode=0
    ball.service=true
	message=MSG_NONE
end

function new_ball(x,y,z)
    ball = {
        name= "ball",
		pos = new_vector3d(x,y,z),
		vel = new_vector3d(0,0,0),
		bounce_pos = new_vector3d(0,0,0),
		bounce_count = 0,
		service = true,
        hit_count= 0,
		on_fire= false,
		behind_type= BEHIND_POINT,
		draw_type= DRAW_BALL,
        has_hit_region=false,
	}
    ball_shadow = {
		pos = new_vector3d(x,0,z),
		behind_type= BEHIND_POINT,
		draw_type= DRAW_BALL_SHADOW,
	}
    particles={}
    particle_colors={{8,8,9,10},{8,9,10,7},{13,14,6,7},{12,12,6,7}}
end

function cycle_pos_data()
	for i=1,2 do
		for j=0,1 do
			local s = server_data[i][1]
            local r = receiver_data[i][1]
            table.remove(server_data[i],1)
            table.insert(server_data[i],s)
            table.remove(receiver_data[i],1)
            table.insert(receiver_data[i],r)
        end
	end
	pos_data_cycled = not pos_data_cycled
end

function new_game(is_demo)
    if is_demo then
		camera_distance=160
        camera_pos=new_vector3d(0,8,0)
        camera_angle_x=-0.065
        no_control_timer=1
        ai_dumbness = 10
    else
		camera_distance=100
        camera_pos=new_vector3d(0,-5,0)
        camera_angle_x=-0.1
        no_control_timer=240
        ai_dumbness = (4-settings[4])*10
        -- TODO
		--menuitem(1,"end match",end_match)
    end

	if pos_data_cycled then
        cycle_pos_data()
    end

	set_score_min=(settings[2]+1)*3
    total_sets=tonumber(total_sets_list[settings[3]])
    camera_angle=0
    camera_lerp_angles={-0.25,0}
    camera_lerp_amount=0
    score_text={"0","15","30","40","adv"}
    court_bounds={new_vector3d(-46,0,-64),new_vector3d(46,0,64)}
    game_score={0,0}
    set_scores={{0,0}}
    match_score={{0,0}}
    players={}
    receiver_data=player_count==2 and singles_data or doubles_data
    team_size=player_count/2
    serving_team = math.random(0,1)
    serving_team_member = 0

	for i=#active_player_settings+1,player_count do
		add_player(-1)
    end

	team_index=0
    team_member_index=0
    player_num=1
    cpu_num=1

	for _,v in pairs(active_player_settings) do
		local player = v.player
		player.court_side=team_index
        player.team=team_index
        player.team_member_index = team_member_index
		if v.controller >= 0 then
			player.control_type = PLAYER_HUMAN
            player.name = string.format("player %d",player_num)
			player_num = player_num + 1
        else
			player.control_type = PLAYER_AI
            player.name = string.format("cpu %d",cpu_num)
			cpu_num = cpu_num + 1
        end
		player.controller=v.controller
        player.mode=2
        player.move_to={}
        player.teammate=nil
        player.power = 0
		player.lob=false
		player.pos_data = team_index==serving_team and server_data[team_index+1][team_member_index+1] or receiver_data[team_index+1][team_member_index+1]
		player.pos = player.pos_data.start_pos
        player.angle = player.pos_data.start_angle

		table.insert(players,v.player)

		team_member_index = team_member_index + 1
		if team_member_index >= team_size then
			team_index = team_index + 1
			team_member_index = 0
        end
    end

	if team_size == 2 then
		players[1].teammate = players[2]
        players[2].teammate = players[1]
        players[3].teammate = players[4]
        players[4].teammate = players[3]
    end

	rotate_camera = player_num == 0 or player_num-1 <= player_count / 2
    service=players[serving_team*team_size+serving_team_member+1]
    change_sides=true
    serve_num=0
    timer_action=TIMER_CONTINUE
    next_game_state = is_demo and 0 or 2
    ai_think_next_frame=false
    ai_think =false
	message=MSG_NONE

	new_ball(0,-100,0)
	ball.vel.z = -service.facing*0.0001
	if not is_demo then
		snd.play_music(-1,15)
		musicplaying=false
    end
end

function draw_player(p, dx, dy)
    -- TODO

	-- pal(2,color_sets[1][p.colors[1]][1])
	-- pal(8,color_sets[1][p.colors[1]][2])
	-- pal(15,color_sets[2][p.colors[2]][1])
	-- pal(5,color_sets[3][p.colors[3]][1])
	-- pal(4,color_sets[3][p.colors[3]][2])
	-- pal(12,color_sets[4][p.colors[4]][1])

	for _,v in pairs(p.sprite_model_sorted) do
		local sp_count = #v.sprites.sprites
        local angle=-camera_angle+1.5+p.angle+v.angle
        local sprite_idx =math.floor(angle*sp_count+0.5) % sp_count
		local sprite = v.sprites.sprites[sprite_idx+1]
		sspr2(sprite.x,sprite.y,v.sprites.width,v.sprites.height,
            v.pos_scr.x+sprite.offx+dx,v.pos_scr.y+sprite.offy+dy,
            v.sprites.width,v.sprites.height,
            sprite.hflip,false)
    end
	--pal()
end

function new_player(x,z,pangle,pcolors,pteam)
    local pfacing = z < 0 and 1 or -1
    return {
        pos= new_vector3d(x,0,z),
        vel= new_vector3d(0,0,0),
        angle= pangle,
        team= pteam,
        move_dir= 1,
        camera_side= 1,
        control_type= PLAYER_NONE,
        behind_type= BEHIND_POINT,
		draw_type= DRAW_PLAYER,
        leg_anim= anims[1],
        leg_anim_time=0,
        arm_anim=anims[6],
        arm_anim_time=0,
        swing_timer= 0,
        power= 0,
		power_shot= false,
        mode= 1,
        move_to={},
        ai_hit_distance=10,
        ai_delay= 0,
        ai_no_hit=0,
        swing_dir=1,
        ball_path_distance=0,
        facing= pfacing,
        colors=pcolors,
        sprite_model= {
			new_sprite_container(sprites[2],0,-3,0,0),
			new_sprite_container(sprites[3],2.5,-4,-1.5,0.125),
			new_sprite_container(sprites[4],-1.25,0,0,0.125),
			new_sprite_container(sprites[4],1.25,0,0,-0.125),
			new_sprite_container(sprites[5],-2.5,-4,-1,0),
			new_sprite_container(sprites[6],2.5,-4,-1,0),
			new_sprite_container(sprites[1],0,2,0,0)
        },
        sprite_model_sorted= {},
    }
end

function init_world()
    parse_nibble_offset=0
    sprites={}
    anims={}
    pos_data_cycled=false
    polys = {new_polygon({-46,0,-64,46,0,-64,46,0,64,-46,0,64},3)}
	for i=1,8 do
		table.insert(sprites,read_sprite_data())
    end
	for i=1,11 do
		table.insert(anims,read_anim_data())
    end
	server_data=read_court_data()
    singles_data=read_court_data()
    doubles_data=read_court_data()
    court_lines=read_line_data()
    net=read_line_data()
    lines_scr= {
		draw_type= DRAW_LINE,
		points={},
	}
    net_scr={
		behind_type= BEHIND_LINE,
		draw_type= DRAW_LINE,
        name="net",
		points={},
	}
    char_count = read_char()
	chars={}
	for i=1,char_count do
		table.insert(chars,{
			x= read_char(),
			y= read_char(),
			w= read_char(),
			h= read_char(),
		})
    end
end

function ready_player(i)
    player_settings[i].ready=true
end

function remove_player(i)
    local player=player_settings[i]
    if player.controller >= 0 then
		table.insert(inactive_controllers,player.controller)
    end
	player.controller=-1
    player.ready=false
    player.menu.selected_index = 0
	local insert_index = 0
	for j=1,#inactive_player_settings do
		insert_index = j
		if inactive_player_settings[j].index > player.index then
			break
        end
    end
    table.insert(inactive_player_settings, insert_index, player)
    table.remove(active_player_settings,i)
end

function draw_ball(o)
	sspr(0,56,5,5,o.pos_scr.x-2,o.pos_scr.y-4)
end

function draw_particle(p)
	local size = (p.time/20)*1.85
	circfill(p.pos_scr.x,p.pos_scr.y,size,particle_colors[p.col][math.floor(p.time/20*(#particle_colors[p.col]-1))+1])
end

function draw_ball_shadow(o)
    -- TODO
end

function draw_big_text(text,x,y)
	local text_data={}
	local width = 1
	for i=1,#text do
		c = string.sub(text,i,i)
		idx = string.find(CHARS_INDEX,c)
		text_data[i] = chars[idx]
		width = width + text_data[i].w-1
    end
	x = x - width/2
	for _,td in pairs(text_data) do
		sspr(td.x,td.y,td.w,td.h,x,y)
		x = x + td.w-1
    end
end

function draw_big_messages(y)
	if message_text ~= "" then
		draw_big_text(message_text,63,y)
		y = y - 13
    end
	if message_reason ~= "" then
		--pal(1,2)
		--pal(5,8)
		--pal(12,9)
		--pal(6,10)
		draw_big_text(message_reason,63,y)
		--pal()
    end
end

function get_game_score_text()
	score1=game_score[service.team + 1]+1
	score2 = game_score[(service.team+1)%2 + 1]+1
	if score1 == 4 and score1 == score2 then
		return "deuce"
	elseif  score1 > 4 then
		return "adv in"
	elseif  score2 > 4 then
		return "adv out"
	else
		return string.format("%d - %d",score_text[score1],score_text[score2])
    end
end

function get_short_name(str)
	return string.format("%c%c",string.sub(str,0,0),string.sub(str,-1,-1))
end

function get_team_name(team_num)
	local team_names = {players[1].name,players[2].name}
	if player_count == 4 then
		team_names[1] = string.format("%s,%s",get_short_name(team_names[1]),get_short_name(team_names[2]))
		team_names[2] = string.format("%s,%s",get_short_name(players[3].name),get_short_name(players[4].name))
    end
	return team_names[team_num]
end

function draw_message()
	if message == MSG_MESSAGE then
		draw_big_messages(43)
		if message_show_score then
			local score_text = get_game_score_text()
			local half_width = (#score_text*FONT_WIDTH)/2
			rectfill(58-half_width,57,66+half_width,65,7)
			pico_print(score_text,63-half_width,58,0)
        end
	elseif message == MSG_MATCH_SCORE then
        draw_big_messages(32)
	elseif message == MSG_SET_SCORE then
        draw_big_messages(32)
    end
end

function draw_object(o)
	if o.draw_type == DRAW_PARTICLE then
		draw_particle(o)
	elseif o.draw_type == DRAW_PLAYER then
		draw_player(o, 0, 0)
	elseif o.draw_type == DRAW_LINE then
		draw_lines(o)
	elseif o.draw_type == DRAW_BALL then
		draw_ball(o)
	elseif o.draw_type == DRAW_BALL_SHADOW then
		draw_ball_shadow(o)
    end
end

function init_player_pool()
	color_sets={
		{{2,14},{8,2},{5,13},{9,13},{9,12},{10,12},{13,7}},
        {{15},{4}},
		{{0,9},{1,9},{0,10},{5,13},{5,14},{4,6},{8,7}},
        {{0},{5},{4},{3},{12},{13},{1}},
    }
    player_count = 2
    inactive_controllers = {1,2,3,4,5,6,7,8,9}
    inactive_player_settings={}
    active_player_settings={}
    player_settings = {}

	for i=1,4 do
        rand_colors = {
            math.floor(math.random(1,#color_sets[1])),
            math.floor(math.random(1,#color_sets[2])),
            math.floor(math.random(1,#color_sets[3])),
            math.floor(math.random(1,#color_sets[4]))
        }
        pmenu = {
			selected_index = 0,
			-- label,type,value_table,value_key,display_values,[special_draw_func]
            items= {
                {label="Ready",value_list=false,data=i, action= MENU_READY, is_color=false},
                {label="Suit ",value_list=true,idx=rand_colors,cur_item=1,values=color_sets[1],action=MENU_NONE, is_color=true},
                {label="Skin ",value_list=true,idx=rand_colors,cur_item=2,values=color_sets[2],action=MENU_NONE, is_color=true},
                {label="Hair ",value_list=true,idx=rand_colors,cur_item=3,values=color_sets[3],action=MENU_NONE, is_color=true},
                {label="Eyes ",value_list=true,idx=rand_colors,cur_item=4,values=color_sets[4],action=MENU_NONE, is_color=true},
                {label="Back out",value_list=false,data=i,action=MENU_BACK, is_color=false}
            }
		}
        setting= {
            ready=false,
            index=i,
            controller=-1,
            selected_option=0,
            colors= rand_colors,
            player=new_player(0,0,0.5,rand_colors,(i-1)%2),
            menu=pmenu,
        }
        table.insert(player_settings,setting)
        table.insert(inactive_player_settings,setting)
	end
end

function init_game_settings()
    player_count=(settings[2])*2
    inactive_controllers={1,2,3,4,5,6,7,8,9}
    inactive_player_settings={}
    active_player_settings={}

    for i=1,#player_settings do
        local v=player_settings[i]
		v.player= new_player(0,0,0.5,v.colors,i%2)
        v.menu.selected_index=0
		table.insert(inactive_player_settings,v)
    end

	--add_player(0)

	camera_distance = 120
    camera_angle = 0
    camera_pos = new_vector3d(0,-8,0)
    next_game_state = 1
	mx = matrix_rotate_x(-0.1)
    my = matrix_rotate_y(camera_angle)
end

function init_main_menu()
    player_count = 2
    new_game(true)
    main_menu = {
        selected_index= 0,
        items= {
            {label="Play",value_list=false,action=MENU_GAME_SETTINGS, is_color=false},
            {label="Type",value_list=true,idx=settings,cur_item=1,values={"Singles","Doubles"},action=MENU_NONE, is_color=false},
            {label="Set score",value_list=true,idx=settings,cur_item=2,values={"3","6"},action=MENU_NONE, is_color=false},
            {label="Sets",value_list=true,idx=settings,cur_item=3,values=total_sets_list,action=MENU_NONE, is_color=false},
            {label="CPU",value_list=true,idx=settings,cur_item=4,values={"Stupid","Easy","Normal","Hard","Pro"},action=MENU_NONE, is_color=false}
        },
    }
    menu_current = main_menu
    next_game_state = 0
    if not musicplaying then
        snd.play_music(0,15)
    end
end

function translate_lines(line_table)
    local scr_table={}
	for _,v in pairs(line_table) do
		table.insert(scr_table,{
			p1=translate_to_view(v.p1),
			p2=translate_to_view(v.p2),
			pal=v.pal
        })
	end
    return scr_table
end

function player_move_to(p,destination,nearness)
	local dist = v3d_distance2d(p.pos,destination) - nearness
	if dist > 0.001 then
		local normal = v3d_normal(v3d_sub(destination,p.pos))
		p.vel = v3d_add(p.vel,v3d_mul_num(normal,0.175))
		if dist < v3d_length(p.vel) then
			p.vel = v3d_mul_num(normal,dist)
        end
		return false
	end
	return true
end

function get_swing_dist(z,cam_dir)
	return 13+(z/120*-cam_dir)*6
end

function calculate_bounce_point()
	local vel = v3d_mul_num(ball.vel,1)
    local pos = v3d_mul_num(ball.pos,1)
	while pos.y < 0 do
		vel.y = vel.y + 0.06
		pos = v3d_add(pos,vel)
    end
	pos.y = 0
	return pos
end

function set_pose(sprite_model,prev_frame,next_frame,t)
	if prev_frame then
		for i=1,#prev_frame.limbs do
			local limb = sprite_model[prev_frame.limbs[i].model]
			limb.pos_prev=prev_frame.limbs[i].pos
            limb.angle_prev=prev_frame.limbs[i].angle
            limb.sprites = sprites[prev_frame.limbs[i].sprite]
        end
	end

	for i=1,#next_frame.limbs do
		local limb = sprite_model[next_frame.limbs[i].model]
		limb.pos = v3d_lerp(limb.pos_prev,next_frame.limbs[i].pos,t)
        limb.angle = lerp(limb.angle_prev,next_frame.limbs[i].angle,t)
		if t >= 0.5 then
			limb.sprites = sprites[next_frame.limbs[i].sprite]
        end
	end
end

function animate_limbs(sprite_model,anim,new_time)
	local prev_frame=nil
    local prev_frame_time = 0
    local last_frame = #anim.frames

	if new_time >= anim.frames[last_frame].to_time then
		if anim.loop then
			new_time = new_time%anim.frames[last_frame].to_time
            prev_frame = anim.frames[last_frame]
        else
			set_pose(sprite_model,anim.frames[last_frame],anim.frames[last_frame],1)
			return {0,anim.on_finish ~= 0 and anim.on_finish or -1}
		end
	end
	for i=1,last_frame do
		if new_time < anim.frames[i].to_time
			and new_time >= prev_frame_time then
				set_pose(sprite_model,prev_frame,anim.frames[i],(new_time-prev_frame_time)/(anim.frames[i].to_time-prev_frame_time))
			break
        end
		prev_frame = anim.frames[i]
        prev_frame_time = anim.frames[i].to_time
	end

	return {new_time,-1}
end

function serve(p)
	new_ball(p.pos.x,-3,p.pos.z + p.facing*6)
	ball.vel.y=-1.1
    ball.vel.z=-p.facing*0.01
    ball.service=false
    p.is_swing_pressed=true
    p.swing_timer =0
	if game_state ~= 0 then
        snd.play_pattern(5)
    end
end

function player_input_ai(p)
	if ai_think then
        p.ai_delay = 0
    end
	if p.ai_delay > 0 then
		p.ai_delay = p.ai_delay - 1
		return
    end
	p.ai_no_hit = math.max(0,p.ai_no_hit-1)
	-- service mode
	if p.mode == 0 then
		p.move_to={
            new_vector3d(
                p.pos_data.move_region.xmin+math.random()*(p.pos_data.move_region.zmin-p.pos_data.move_region.xmin),
                0,
                p.pos_data.move_region.xmax+math.random()*(p.pos_data.move_region.zmax-p.pos_data.move_region.xmax)
            )}
        p.mode = 4
	-- service mode 2
	elseif p.mode == 4 then
		if player_move_to(p,p.move_to[1],2) then
			p.move_to={}
            p.ai_delay=16+math.floor(math.random(1,20))
            p.mode = 3
			serve(p)
        end
	-- service mode 3
	elseif p.mode == 3 then
		p.swing_timer = 30
        p.mode=1
        p.power_shot = math.random()* (ai_dumbness+10) * (serve_num+1) <= 5
        if p.power_shot then
            p.power = 0.25
        end
		serve_num = serve_num + 1
	elseif p.mode == 1 then
		if ai_think then
			if ball.last_hit_player and ball.last_hit_player.team ~= p.team
				and (not p.teammate or math.abs(p.ball_path_distance) <= math.abs(p.teammate.ball_path_distance)) then
				back_dist = math.random()*16
				dest = new_vector3d(
                    ball.bounce_pos.x+ball.vel.x*back_dist+math.random()*ai_dumbness-ai_dumbness/2,
                    0,
                    ball.bounce_pos.z+ball.vel.z*back_dist+math.random()*ai_dumbness-ai_dumbness/2)
				swing_dist = get_swing_dist(dest.z,p.move_dir)
				if ball.has_hit_region and not point_in_rect(ball.bounce_pos,ball.valid_hit_region.min,ball.valid_hit_region.max) then
					dest = v3d_add(p.pos,v3d_mul_num(v3d_sub(dest,p.pos),0.5+math.random()*0.5))
                end
				p.move_to={dest}
                p.ai_hit_distance = swing_dist*0.5+math.random()*swing_dist*0.5+math.random()*ai_dumbness*0.25
                p.ai_delay=math.random()*ai_dumbness*1.5
			end
		end

		if (ball.vel.z > 0) ~= (p.facing > 0) then
			if #p.move_to >= 1 then
				if player_move_to(p,p.move_to[1],1) then
					table.remove(p.move_to,1)
                end
			end

			dist_rate = v3d_distance2d(p.pos,ball.pos) / p.ai_hit_distance
			if p.swing_timer <= 0
				and p.ai_no_hit == 0
				and dist_rate <= 1.0
				and	(ball.has_hit_region == nil or point_in_rect(ball.bounce_pos,ball.valid_hit_region.min,ball.valid_hit_region.max)) then
				p.swing_timer = 30
				p.ai_no_hit = 90
				if math.floor(math.random(0,dist_rate >0.95 and 3 or 15)) == 0 then
					p.lob=true
				elseif p.power > 0 and math.random()<=math.random()*p.power and math.random()*ai_dumbness<8 then
					p.power_shot = true
                end
			end
		end
	end
end

function player_input_keyboard(p)
	local move_speed = 0.175 * p.move_dir
    local kshot=inp.pad_button(p.controller,0)
    local ksmash=inp.pad_button(p.controller,1)
    local klob=inp.pad_button(p.controller,2)
    local any_k = kshot or ksmash or klob
	if kshot or (ksmash and p.power==0) or klob then
		if not p.is_swing_pressed then
			p.power_shot = false
			p.is_swing_pressed = true
			if p.mode == 0 then
				serve(p)
				p.mode = 3
                p.dx=0
                p.dz=0
			elseif p.mode == 3 then
				p.swing_timer=30
				p.mode = 1
                if ksmash then
                    p.power_shot=true
                    p.power=0.25
				end
				serve_num = serve_num + 1
			elseif p.swing_timer <= 0 then
				p.swing_timer = 30
                if klob then
					p.lob=true
				end
                p.dx=0
                p.dz=0
			end
		end
	elseif ksmash then
		if not p.is_swing_pressed and p.power > 0 then
			p.is_swing_pressed=true
			p.swing_timer=30
			p.power_shot = true
        end
	end
    if not any_k then
		p.is_swing_pressed = false
    end
    if p.mode ~= 3 and p.swing_timer <= 0 then
        -- move player
        p.vel.x = p.vel.x - move_speed * inp.left(p.controller)
        p.vel.x = p.vel.x + move_speed * inp.right(p.controller)
        p.vel.z = p.vel.z - move_speed * inp.up(p.controller)
        p.vel.z = p.vel.z + move_speed * inp.down(p.controller)
    else
        -- orient shot
        p.dx = p.dx - inp.left(p.controller)
        p.dx = p.dx + inp.right(p.controller)
        p.dz = p.dz + inp.up(p.controller)
        p.dz = p.dz - inp.down(p.controller)
    end
end

function update_player(p)
	p.facing = p.pos.z < 0 and 1 or -1
    if p.control_type ~= PLAYER_NONE then
		if camera_angle < 0.25 or camera_angle > 0.75 then
			p.move_dir = 1
        else
			p.move_dir = -1
		end
		if (p.pos.z < 0) == (camera_angle < 0.25 or camera_angle > 0.75) then
			p.camera_side = -1
        else
			p.camera_side = 1
		end
		p.ball_path_distance = orient2d_xz(ball.pos,v3d_add(ball.pos,ball.vel),p.pos)

		if p.mode == 2 then
			if #p.move_to >= 1 then
				if player_move_to(p,p.move_to[1],2) then
					table.remove(p.move_to,1)
					if #p.move_to == 0 then
						p.angle = p.pos_data.start_angle
                    end
                else
					normal = v3d_normal(v3d_sub(p.move_to[1],p.pos))
					p.angle = atan2(-normal.z,normal.x)
				end
			end
        else
            if p.control_type == PLAYER_AI then
			    player_input_ai(p)
            else
                player_input_keyboard(p)
            end
		end
		new_pos = v3d_add(p.pos,p.vel)
		if p.mode ~= 2 then
			if p.vel.z < 0 and new_pos.z < p.pos_data.move_region.xmax then
				new_pos.z=p.pos_data.move_region.xmax
                p.vel.z = 0
            end
			if p.vel.z > 0 and new_pos.z > p.pos_data.move_region.zmax then
				new_pos.z = p.pos_data.move_region.zmax
                p.vel.z=0
            end
			if p.vel.x < 0 and new_pos.x < p.pos_data.move_region.xmin then
				new_pos.x = p.pos_data.move_region.xmin
                p.vel.x=0
            end
			if p.vel.x > 0 and new_pos.x > p.pos_data.move_region.zmin then
				new_pos.x = p.pos_data.move_region.zmin
                p.vel.x=0
            end
		end
		-- set animations
		if v3d_length(p.vel) < 0.1 then
			-- not moving
			p.leg_anim = anims[1]
			if p.leg_anim_time > p.leg_anim.frames[#p.leg_anim.frames].to_time then
				p.leg_anim_time = 0
            end
        else
			-- if moving
			move_angle = atan2(-p.vel.z,p.vel.x)-p.angle+0.125
			p.leg_anim = anims[math.floor((move_angle < 0 and move_angle+1 or (move_angle >= 1 and move_angle-1 or move_angle)*4))+2]
		end

		p.pos = new_pos
        p.vel=v3d_mul_num(p.vel,0.8)

		if p.ball_path_distance > 0 or ball.vel.z == 0 or (ball.vel.z > 0) == (p.facing > 0) then
			p.swing_dir = 1
        else
			p.swing_dir = -1
		end

		if p.swing_timer <= 0 then
			if p.mode == 3 then
				if p.arm_anim ~= anims[10] then
					p.arm_anim_time = 0
                end
				p.arm_anim = anims[10]
			elseif p.swing_dir >= 0 or p.mode == 0 or p.mode == 4 then
				if p.arm_anim ~= anims[6] then
					p.arm_anim_time = 0
                end
				p.arm_anim = anims[6]
            else
				if p.arm_anim ~= anims[7] then
					p.arm_anim_time = 0
                end
				p.arm_anim = anims[7]
			end
		end

		if p.swing_timer > 0 then
			-- hit the ball
			if ((p.swing_timer == 30 and ball.hit_count == 0) or p.swing_timer==25) and (ball.vel.z == 0 or (ball.vel.z > 0) ~= (p.facing > 0)) then
				p.arm_anim_time = 0
				if p.arm_anim == anims[10] then
					p.arm_anim = anims[11]
				elseif p.swing_dir < 0 then
					p.arm_anim = anims[9]
                else
					p.arm_anim = anims[8]
				end
				ball_distance = v3d_distance2d(p.pos,ball.pos)
                hit_range = get_swing_dist(p.pos.z,p.move_dir)
				if ball_distance <= hit_range then
                    ball.hit_count = ball.hit_count + 1
					power = 1.3+math.abs(p.pos.z/58)*0.7+(ball_distance/hit_range)*0.2
                    dx = 0
                    dz = 0
					-- 0 : court end 1: at net
					net_proximity = math.max(1-math.abs(p.pos.z/64),0)
                    if p.controller >= 0 then
                        if ball.hit_count == 1 then
                            dx = 0.5 * math.max(-1,math.min(1,p.dx/64))
                            dz = 0.5 * math.max(-1,math.min(1,p.dz/32))
                            dx = dx - p.pos.x*p.move_dir/64
                        else
                            dx = 0.5 * math.max(-1,math.min(1,p.dx/12))
                            if dx > 0 and p.pos.x > 0 then
                                dx = dx * ((32 -p.pos.x)/32)
                            elseif dx < 0 and p.pos.x < 0 then
                                dx = dx * ((32 +p.pos.x)/32)
                            end
                            dz = 0.5 * math.max(-1,math.min(1,p.dz/6))
                        end
                        power = power * (1+0.2*dz)
                        dx = dx * (1 -0.2*math.abs(dz))
                    end
                    direction = (dx + math.abs(ball.pos.x-p.pos.x)/(hit_range*2.5))*-p.swing_dir*p.move_dir*p.camera_side+(-ball.pos.x/64)*1.2
                    vert = (ball.pos.y/18+lerp(0.9,1.0,math.abs(p.pos.z/58)*0.5+(ball_distance/hit_range*0.4)))*-1.25
					if p.lob then
						force=1-net_proximity
						vert =  vert * (1 + 2.5*force)
						power = power * (1 + 0.15*force)
						p.lob=false
                    end
					ball.on_fire = false
					if p.power_shot then
						power = power + p.power*1.65
						direction = direction * ((p.power*0.7-1)*-1)
						ball.pos.y = lerp(-16,-18,p.power)
                        vert = lerp(0.1,-0.15,math.abs(p.pos.z/58))+p.power*0.15
                        ball.on_fire=math.min(math.max(math.round(p.power*4),1),#particle_colors-1)
                        p.arm_anim = anims[11]
						if game_state ~= 0 then
                            snd.play_pattern(6)
                        end
						p.power = -0.25
					elseif p == service and serve_num > 0 then
						vert = ball.pos.y/-18*0.5-0.7
                    end
					if game_state ~= 0 then
                        snd.play_pattern(math.random(2,4))
                    end
					ball.vel=v3d_mul_num(v3d_normal(new_vector3d(direction,vert,p.facing)),power)
                    ball.bounce_count=0
                    ball.last_hit_player=p
                    ball.valid_hit_region=p.pos_data.valid_hit_region
                    ball.has_hit_region=true
                    ai_think_next_frame=true
                    p.power_shot=false
                    service.pos_data = receiver_data[service.court_side+1][service.team_member_index+1]
					ball.bounce_pos = calculate_bounce_point()
					if p ~= service then
                        serve_num = 0
                    end
					if serve_num == 0 or p.power < 0 then
						p.power = math.min(p.power+0.25,1)
                    end
					for _,v in pairs(players) do
						v.ai_no_hit = 0
                    end
				elseif game_state ~= 0 then
                    snd.play_pattern(0)
                end
			end
			p.swing_timer = p.swing_timer - 1
		end

		new_leg_anim=nil
        new_arm_anim = nil
		legs = animate_limbs(p.sprite_model,p.leg_anim,p.leg_anim_time + 1)
        p.leg_anim_time=legs[1]
        if legs[2] ~= -1 then
            new_leg_anim= anims[legs[2]]
        end
		arms = animate_limbs(p.sprite_model,p.arm_anim,p.arm_anim_time + 1)
        p.arm_anim_time=arms[1]
        if arms[2] ~= -1 then
            new_arm_anim=anims[arms[2]]
        end

		if new_leg_anim then
			p.leg_anim = new_leg_anim
        end
		if new_arm_anim then
			p.arm_anim = new_arm_anim
        end
	end
	-- prepare for rendering
	m_player_rotation_x = matrix_rotate_x(0)
    m_player_rotation_y = matrix_rotate_y(-p.angle)
	p.pos_scr=translate_to_view(p.pos)
    p.sprite_model_sorted = {}
    for k,v in pairs(p.sprite_model) do
		v.pos_scr = translate_to_view(v3d_add(p.pos,matrix_mul_add(m_player_rotation_x,matrix_mul_add(m_player_rotation_y,v.pos))))
		v.pos_scr.x = math.round(v.pos_scr.x)
		if k == 7 then
			p.shadow_pos_scr = v.pos_scr
        else
			local insert_i = 1
			for i=1,#p.sprite_model_sorted do
                if v.pos_scr.z <= p.sprite_model_sorted[i].pos_scr.z then
					insert_i = i
					break
				end
			end
			table.insert(p.sprite_model_sorted,insert_i,v)
		end
	end
end

function get_sort_index(o)
	for i,obj in pairs(z_sorted_objects) do
		if behind(obj,o) then
			return i+1
        end
	end
	return #z_sorted_objects+1
end

function end_match(team)
	if team ~= -1 then
		no_control_timer = 480
		message_text = string.format("%s wins",get_team_name(team))
	else
		no_control_timer = 1
    end
	if game_state ~= 2 then
		timer_action = TIMER_NEW_GAME
	else
		musicplaying=true
		timer_action = TIMER_MAIN_MENU
		snd.play_music(0,15)
    end
end

function end_set(team)
	message = MSG_MATCH_SCORE
	no_control_timer = 360

	team_scores = match_score[#match_score]
	scores = #set_scores
	set_score = set_scores[scores]
	if set_score[1] > set_score[2] then
		team_scores[1] = team_scores[1] + 1
	else
		team_scores[2] = team_scores[2] + 1
    end
	match_score[#match_score] = {set_score[1],set_score[2]}
	table.insert(match_score,team_scores)

	if #match_score == total_sets+1 or (total_sets==3 and math.max(team_scores[1],team_scores[2])==2)
		or (total_sets==5 and math.max(team_scores[1],team_scores[2])==3) then
        winner = team_scores[1]>team_scores[2] and 1 or 2
		end_match(winner)
        message_text=string.format("%s match",get_team_name(winner))
	else
	    table.insert(set_scores,{0,0})
    end
end

function end_game(team)
	message = MSG_SET_SCORE
	scores = #set_scores
	set_score = set_scores[scores]
	set_score[team] = set_score[team] + 1
	change_sides=(set_score[1]+set_score[2])%2==1
	no_control_timer = 240
	if math.max(set_score[1],set_score[2]) >= set_score_min then
		score_dif = set_score[1]-set_score[2]

		if score_dif >= 2 or set_score[1] == set_score_min+1 then
			-- team 1 victory
            message_text=string.format("%s set",get_team_name(1))
			end_set(1)
		elseif score_dif <= -2 or set_score[2] == set_score_min+1 then
			-- team 2 victory
            message_text=string.format("%s set",get_team_name(2))
			end_set(2)
        end
	end
	-- switch player service
	serving_team = (serving_team+1)%2
	if serving_team == 1 then
		for _,v in pairs(players) do
			v.team_member_index = (v.team_member_index+1)%team_size
        end
	end

	-- change sides after each odd numbered game
	if (set_score[1]+set_score[2]) % 2 == 1 then
		for _,v in pairs(players) do
			v.court_side = (v.court_side+1)%2
			-- move around the net
			if v.pos.z < 0 then
				v.move_to = {new_vector3d(40,0,-8),new_vector3d(40,0,8)}
			else
				v.move_to = {new_vector3d(-40,0,8),new_vector3d(-40,0,-8)}
            end
			if rotate_camera then
				camera_lerp_angles = camera_angle < 0.5 and {0,0.5} or {0.5,0}
				camera_lerp_amount = 0
            end
		end
	end

	game_score = {0,0}

	if not pos_data_cycled then
		cycle_pos_data()
    end
end

function update_game_score(team,text)
	if no_control_timer <= 0 then
		message_reason=text
		message_text=""
		message_show_score=true
		no_control_timer = 120
		local other_team = (team+1)%2 + 1
        team = team + 1
		for _,v in pairs(players) do
			v.move_to = {}
			v.ai_no_hit = 0
        end

		if ball.bounce_count <= 1 then
			if serve_num == 1 then
				message_reason="fault"
				service.pos_data=server_data[service.court_side+1][service.team_member_index+1]
				message_show_score =false
				message = MSG_MESSAGE
				for _,v in pairs(players) do
					v.angle=v.pos_data.start_angle
					v.move_to={v.pos_data.start_pos}
					v.mode = 2
                end
				return
			elseif serve_num == 2 then
				message_reason = "double fault"
                ball.hit_count=0
            end
		end

        if ball.hit_count == 1 then
    		message_text=string.format("%s ace",get_team_name(team))
        else
		    message_text=string.format("%s point",get_team_name(team))
        end
        ball.hit_count = 0
		message = MSG_MESSAGE
		serve_num=0
		if game_score[team] == 3 then
			if game_score[other_team] == 4 then
				game_score[other_team] = game_score[other_team] - 1
			else
				game_score[team] = game_score[team] + 1
				if game_score[other_team] ~= 3 then
                    message_text=string.format("%s game",get_team_name(team))
					end_game(team)
                end
			end
		elseif game_score[team] == 4 then
			game_score[team] = game_score[team] + 1
            message_text=string.format("%s game",get_team_name(team))
			end_game(team)
		else
			game_score[team] = game_score[team] + 1
        end

		-- players switch between left and right sides
		cycle_pos_data()

		-- move players for service
		for _,v in pairs(players) do
			v.power=0
			v.pos_data = v.team==serving_team and server_data[v.court_side+1][v.team_member_index+1] or receiver_data[v.court_side+1][v.team_member_index+1]
			v.mode = 2
			v.angle = v.pos_data.start_angle
			table.insert(v.move_to,v.pos_data.start_pos)
			if v.team == serving_team and v.team_member_index == serving_team_member then
				service = v
            end
		end

		ball.last_hit_player = nil
	end
end

function update_ball()
	if not ball.service then
		scored = false
		ball.vel.y = ball.vel.y + 0.06

		-- hit net
		if ball.pos.y >= -6
			and (ball.pos.z > 0) ~= (ball.pos.z + ball.vel.z > 0)
			and ball.pos.x >= -32 and ball.pos.x <= 32 then
			ball.pos.z = ball.pos.z - ball.vel.z
			ball.vel = new_vector3d(0,0,0)
			if ball.last_hit_player then
				update_game_score((ball.last_hit_player.team+1)%2,"net")
            end
			scored=true
			ball.on_fire = false
		end

		ball.pos = v3d_add(ball.pos,ball.vel)

		-- bounce
		if ball.pos.y > 0 then
			if game_state ~= 0 and ball.vel.y > 0.23 then
				snd.play_pattern(1)
            end
			ball.vel.y = -ball.vel.y*0.75
			ball.pos.y = -ball.pos.y
			ball.bounce_count = ball.bounce_count + 1
			if ball.last_hit_player then
				if not scored then
					-- second bounce
					if ball.bounce_count >= 2 then
						update_game_score(ball.last_hit_player.team, "")
						scored = true
					-- bounce out of valid court area
					elseif not point_in_rect(ball.pos,ball.valid_hit_region.min,ball.valid_hit_region.max) then
						update_game_score((ball.last_hit_player.team+1)%2,"out")
						scored = true
                    end
				end
			else
				-- failed to hit the ball on serve
				if service.mode == 3 then
					ball.service=true
					service.mode=0
					ball.bounce_count = 0
                end
			end
		end
		-- out of bounds on the full
		if not scored and not point_in_rect(ball.pos,court_bounds[1],court_bounds[2]) then
			if ball.last_hit_player then
				if ball.bounce_count == 1 then
					ball.bounce_count = ball.bounce_count + 1
					update_game_score(ball.last_hit_player.team, "")
				else
					update_game_score((ball.last_hit_player.team+1)%2,"out")
                end
			end
			ball.vel.x=0
			ball.vel.z=0
			ball.on_fire = false
		end
	else
		-- position to service player's hand (requires rotation the bone to the player's angle)
		ball.pos = v3d_add(service.pos,matrix_mul_add(matrix_rotate_x(0),matrix_mul_add(matrix_rotate_y(-service.angle),service.sprite_model[5].pos)))
    end

	ball_shadow.pos.x=ball.pos.x
	ball_shadow.pos.z=ball.pos.z
	ball.pos_scr = translate_to_view(ball.pos)

-- fid+=1
-- if fid%10==0 {
-- print std.str.format6("%1 %2 %3   %4 %5 %6",
--     math.round(ball.pos.x), math.round(ball.pos.y), math.round(ball.pos.z),
--     math.round(ball.pos_scr.x), math.round(ball.pos_scr.y), math.round(ball.pos_scr.z))
-- }

	ball_shadow.pos_scr = translate_to_view(ball_shadow.pos)
	to_remove={}
	for i=1,#particles do
		local v=particles[i]
		v.time = v.time - 1
		if v.time <= 0 then
			table.insert(to_remove,i)
		else
			table.insert(z_sorted_objects,get_sort_index(v),v)
        end
	end
	for i=#to_remove,1,-1 do
        table.remove(particles,i)
    end
	if ball.on_fire then
		p_pos = v3d_sub(ball.pos,new_vector3d(0,2,0))
		for i=0,1 do
			p={
				pos_scr=translate_to_view(v3d_add(p_pos,v3d_mul_num(ball.vel,i/-2))),
				time = 20,
				col=ball.on_fire,
				behind_type= BEHIND_POINT,
				draw_type= DRAW_PARTICLE,
			}
			table.insert(particles,p)
			table.insert(z_sorted_objects,get_sort_index(ball),p)
		end
	end
end

function timer_expired_func()
	if timer_action == TIMER_MAIN_MENU then
		-- TODO
		--menuitem(1)
		init_player_pool()
		init_main_menu()
	elseif timer_action == TIMER_NEW_GAME then
		init_player_pool()
		new_game(true)
		update_game()
	elseif timer_action == TIMER_CONTINUE then
		service.mode=0
		ball.service=true
		message = MSG_NONE
    end
end

function update_game()
	if game_state ~= 2 then
		camera_angle = (camera_angle+0.0025)%1
	elseif camera_lerp_amount < 1 then
		camera_lerp_amount = math.min(camera_lerp_amount+0.005,1)
		camera_angle = smooth_lerp(camera_lerp_angles[1],camera_lerp_angles[2],camera_lerp_amount)
    end

	ai_think = ai_think_next_frame
    ai_think_next_frame=false
    mx=matrix_rotate_x(camera_angle_x)
    my=matrix_rotate_y(camera_angle)

	for poly_i=1,#polys do
        local poly=polys[poly_i]
		for i=1,#poly.points_3d do
            local p =poly.points_3d[i]
			poly.points_scr[i] = translate_to_view(p)
        end
	end

	lines_scr.points = translate_lines(court_lines)
	net_scr.points = translate_lines(net)

	z_sorted_objects = { net_scr }

	for _,v in pairs(players) do
		update_player(v)
		table.insert(z_sorted_objects,get_sort_index(v),v)
    end

	update_ball()
	table.insert(z_sorted_objects,get_sort_index(ball_shadow),ball)

	if no_control_timer > 0 then
		no_control_timer = no_control_timer - 1
		if no_control_timer <= 0 then
			for _,v in pairs(players) do
				v.mode = 1
            end
			timer_expired_func()
		end
	end
end

function update_menu(menu,controller)
    local item = menu.items[menu.selected_index+1]
    local item_count = #menu.items
    if inp.down_pressed(controller) then
        menu.selected_index = (menu.selected_index + 1) % item_count
    elseif inp.up_pressed(controller) then
        menu.selected_index = (menu.selected_index + item_count - 1) % item_count
    end
    if inp.right_pressed(controller) and item.values ~= nil then
        local value_count = #item.values
        item.idx[item.cur_item] = (item.idx[item.cur_item]) % value_count + 1
    elseif inp.left_pressed(controller) and item.values ~= nil then
        local value_count = #item.values
        item.idx[item.cur_item] = (item.idx[item.cur_item]+value_count -2) % value_count + 1
    end
    if inp.pad_button_pressed(controller,0) then
		if item.action == MENU_GAME_SETTINGS then
        	init_game_settings()
		elseif item.action == MENU_READY then
			ready_player(item.data)
		elseif item.action == MENU_BACK then
			remove_player(item.data)
        end
    end
end

function update_game_settings()
    ready_count = 0
    active_count = #active_player_settings
    for _,v in pairs(active_player_settings) do
		update_menu(v.menu,v.controller)
		-- count the number of ready players
		if v.ready then
			ready_count = ready_count + 1
        end
    end
	-- check unassigned controllers for new players (unless a player has left this frame)
	if #active_player_settings == active_count and active_count < player_count and #inactive_player_settings >= 1 then
        to_remove={}
        for _,v in pairs(inactive_controllers) do
			if inp.pad_button_pressed(v-1,0) then
				ic = add_player(v-1)
                if ic >= 0 then
                    table.insert(to_remove,ic)
                end
            end
        end
        for _,ic in pairs(to_remove) do
            table.remove(inactive_controllers,ic)
        end
    end

    -- if active_count==1 and inp.key_pressed(KEY_C) {
    --     add_player(0)
    -- }


	-- if active_player_settings#count() == 0 {
	-- 	init_main_menu()
	-- 	return
    -- } else
    if ready_count > 0 and ready_count == #active_player_settings then
		new_game(false)
		return
    end

	-- rotate player models
    for _,v in pairs(player_settings) do
		v.player.angle = v.player.angle + 0.0125
		if v.player.angle > 1 then
			v.player.angle = v.player.angle - 1
        end
		update_player(v.player)
    end
end

function draw_shadow(spx,spy,spw,sph,x1,y1)
    sspr(spx,spy,spw,sph,x1,y1)
end

function draw_score_board(x,y)
    set_small_font()
    local t0_name = get_team_name(1)
    local t1_name = get_team_name(2)
    local maxlen = math.max(#t0_name,#t1_name)
    local tx=x+maxlen*3+2
    local ty=y
    sspr(57,177,4,4,x-5,ty+1 + serving_team * 6)
    pico_print(t0_name,x,ty+1,7)
    pico_print(t1_name,x,ty+7,7)
    for i=1,#set_scores do
        rectfill(tx,ty,tx+5,ty+11,7)
        s = string.format("%s",set_scores[i][1])
        pico_print(s, tx+1,ty+1, 0)
        s2 = string.format("%d",set_scores[i][2])
        pico_print(s2, tx+1,ty+7, 0)
        tx = tx + 5
    end
    set_standard_font()

    sspr(game_score[1]*13,104,15,6,tx,ty)
    sspr(game_score[2]*13,104,15,6,tx,ty+6)
end

function draw_game()
	for _,v in pairs(polys) do
		draw_polygon(v)
    end

	draw_lines(lines_scr)

	for _,p in pairs(players) do
		if p.shadow_pos_scr then
			sprite = p.sprite_model[7].sprites.sprites[1]
			draw_shadow(sprite.x,sprite.y,
                p.sprite_model[7].sprites.width,p.sprite_model[7].sprites.height,
                p.shadow_pos_scr.x+sprite.offx,p.shadow_pos_scr.y+sprite.offy)
        end
    end

	draw_shadow(8,56,5,4,ball_shadow.pos_scr.x-2,ball_shadow.pos_scr.y-1)

	for _,z in pairs(z_sorted_objects) do
		draw_object(z)
    end

	if game_state == 2 then
        draw_score_board(-50,-38)
		for _,v in pairs(players) do
			local x=0
			local power_x = 2
			local y=-38
			local power_y = y+8
			local name_len = #v.name
			if v.pos_data.start_pos.x*v.move_dir > 0 then
				x = 70
				power_x= 110
			else
                x = 52-name_len*FONT_WIDTH
            end
			if v.camera_side > 0 then
				y=155
				power_y = y-5
            end
			local right = x+(name_len*FONT_WIDTH)
            power_x = x+name_len*4-7
            rectfill(power_x,power_y+1,power_x+15,power_y+2,0)
            rectfill(power_x+1,power_y,power_x+14,power_y+3,0)
			sspr(0,12+v.power*16,16,4,power_x,power_y)
			rectfill(x,y-1,right+2,y+7,0)
			rectfill(x-1,y,right+3,y+6,0)
			pico_print(v.name,x+2,y,color_sets[1][v.colors[1]][2])
		end

		if message ~= MSG_NONE then
			draw_message()
        end
		pico_print("X/  : shot",-120,20,7)
		pico_print("C/  : smash",-120,28,7)
		pico_print("V/  : lob",-120,36,7)
        sspr(63,176,8,8,-108,20)
        sspr(72,176,8,8,-108,28)
        sspr(81,176,8,8,-108,36)
	end
end

function draw_color_range(x,y,selected,r)
	local SIZ=6
	rectfill(x,y,x+#r*SIZ+1,y+SIZ+1,0)
	local cx = x+1
	y = y + 1
	local sets=#r[1]
	for i=1,#r do
		rectfill(cx,y,cx+SIZ-1,y+SIZ-1,r[i][1])
		if sets > 1 then
			rectfill(cx,y,cx+SIZ-1,y+SIZ/2-1,r[i][2])
        end
		cx = cx + SIZ
	end
	rect(x+selected*SIZ,y-1,x+selected*SIZ+SIZ,y+SIZ,7)
end

function draw_menu(menu, x, y)
    local top=y
    local MENU_WIDTH=100
    local item_count = #menu.items
    rectfill(x-2,y-2,x+MENU_WIDTH,y+item_count*10,1)
    for i,item in pairs(menu.items) do
        local txt_col=6
        if menu.selected_index + 1 == i then
			rectfill(x-1,y-1,x+MENU_WIDTH-1,y+9,12)
			txt_col = 7
        end
        pico_print(item.label,x,y+1,txt_col)
		if item.is_color then
			draw_color_range(x+#item.label*FONT_WIDTH,y,item.idx[item.cur_item]-1,item.values)
        elseif item.value_list then
            val = string.format("%s",item.values[item.idx[item.cur_item]])
            len = #val
            pico_print(val,x+MENU_WIDTH-len*FONT_WIDTH,y+1,7)
        end
        y = y + 10
    end
end

function draw_player_settings(x,y,player_setting,index)
    rectfill(x,y+25,x+58,y+34,0)
	if player_setting.controller == -1 then
		pico_print(string.format("CPU%d",index),x+16,y+26,7)
		rectfill(x,y+35,x+58,y+61,5)
		pico_print("Press",x+14,y+38,6)
		pico_print("button",x+11,y+44,6)
		pico_print("to join",x+8,y+50,6)
    else
		pico_print(string.format("Player%d",index),x+3,y+26,7)
		if player_setting.ready then
			rectfill(x,y+32,x+58,y+61,2)
			pico_print("Ready",x+9,y+44,7)
		else
			draw_menu(player_setting.menu,x == 0 and x-42 or x+2,y+37)
        end
    end
	draw_player(player_setting.player,x-32,y-40)
end

function draw_game_settings()
    cls(3)
	x=0
    y=-40
	if player_count < 3 then
		y = 32
    end
	for i=1,player_count do
		draw_player_settings(x,y,player_settings[i],i)
		x = x + 63
		if x > 64 then
			x = 0
			y = y + 96
        end
    end
    y = 40
    pico_print("X/",-120,y,7)
    sspr(63,176,8,8,-108,y)
    pico_print("to join",-94,y,7)
end

function init()
    for _,sfx in pairs(SFX) do
		snd.new_pattern(sfx)
	end
    snd.new_music(MUSIC_TITLE)
	snd.new_instrument(INST_TRIANGLE)
	snd.new_instrument(INST_TILTED)
	snd.new_instrument(INST_SAW)
	snd.new_instrument(INST_SQUARE)
	snd.new_instrument(INST_PULSE)
	snd.new_instrument(INST_ORGAN)
	snd.new_instrument(INST_NOISE)
	snd.new_instrument(INST_PHASER)
    gfx.set_scanline(gfx.SCANLINE_HARD)
    gfx.set_layer_size(LAYER_SPRITESHEET,128,256)
    gfx.set_active_layer(LAYER_SPRITESHEET)
    gfx.load_img("sprites","tennis/spritesheet.png")
    gfx.set_sprite_layer(LAYER_SPRITESHEET)
    set_standard_font()
    gfx.set_active_layer(LAYER_SCREEN)
    snd.play_pattern(7)
end

function update()
    game_state = next_game_state
    if game_state == 0 then
        update_game()
        for i=0,8 do
		    update_menu(main_menu,i)
        end
    elseif game_state == 1 then
        update_game_settings()
    elseif game_state == 2 then
        update_game()
    elseif game_state == 3 then
        logo_timer = logo_timer - 1
        if logo_timer <= 0 then
			init_world()
			init_player_pool()
			init_main_menu()
        end
    end
end

function render()
    if game_state ~= next_game_state then
        return
    end
	cls(1)
    if game_state == 0 then
        cls(13)
        draw_game()
		sspr(0,64,105,40,12,-21)
		draw_menu(main_menu,4,121)
		sspr(0,110,30,12,116,144)
    elseif game_state == 1 then
        draw_game_settings()
    elseif game_state == 2 then
        draw_game()
    elseif game_state == 3 then
        cls(0)
        sspr(72,104,30,22,47,50)
    end
end

SFX={
	"PAT 1 F#2614 D#3621 G.3621 F#3631 D#3631 A#2621 F#2621 D.2611 A#1611 G#1611 F.1611 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
	"PAT 1 D.1714 C#3225 C#2714 F.2711 A.2711 C#3705 C#1005 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... F#2500 ...... ...... ...... ...... ...... ...... ...... ......",
	"PAT 1 D.1611 D#1611 F#1621 G#1621 G#3074 B.3065 A#2731 F#2721 F#2721 G#2715 C#2600 D#1010 D#1010 D.1010 F#3600 G#3600 A#3600 G#3600 F#2600 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
	"PAT 1 E.1611 G#1611 B.1621 D.2621 C#3074 B.3065 C#3731 C#3721 C.3721 B.2715 ...... E.1010 E.1010 C#1010 C#1010 C#1010 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
	"PAT 1 E.1611 A#1611 D#2621 E.2621 F.3074 A#3065 B.2731 A#2721 A#2721 A#2715 E.1600 ...... C#1010 C#1010 D#1010 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
	"PAT 1 B.1714 D.2711 F.2721 G#2721 B.2031 C#3041 D#3525 E.3001 G#4605 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
	"PAT 2 C#1063 F#2071 C#1073 C.4070 C#1043 G.4060 C#1333 B.3031 E.3131 E.1531 B.2321 A#1521 G.2121 C.2521 E.2321 A#1521 C#2121 G.1511 B.1311 E.1511 A.1111 D.1511 G.1311 C#1511 F.1111 G.1511 D#1111 C.2511 D.1111 E.2515 ...... ......",
	"PAT 4 C.5050 C.5041 C.5031 C.5021 G.5050 G.5041 G.5041 G.5031 G.5031 G.5021 G.5021 G.5011 G.5011 G.5011 G.5011 G.5015 ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ......",
	"PAT 10 G.3050 G.3052 G.3042 G.3032 G.3022 G.3012 C.3050 C.3010 C.3050 C.3052 C.3052 C.3042 C.3032 C.3022 G.3050 G.3040 A#3050 A#3050 A#3050 A#3050 A.3051 A.3050 A.3050 A.3050 G.3050 G.3050 F.3051 F.3052 F.3052 F.3052 G.3050 G.3050",
	"PAT 10 G.3042 G.3032 G.3022 G.3012 ...... ...... C.3000 C.3000 C.3000 C.3002 C.3002 C.3002 C.3002 C.3002 C.3002 C.3002 C.3002 C.3002 ...... ...... ...... ...... ...... ...... ...... ...... D.3054 D.3050 F.3051 F.3050 G.3051 G.3050",
	"PAT 10 A.3050 A.3052 A.3042 A.3032 A.3022 A.3012 D.3050 D.3020 D.3050 D.3052 D.3042 D.3032 D.3022 D.3012 A.3050 A.3050 A#3050 A#3050 A#3050 A#3050 A.3051 A.3050 A.3050 A.3050 G.3050 G.3050 F.3051 F.3052 F.3052 F.3052 G.3050 G.3050",
	"PAT 10 G.3052 G.3052 G.3052 G.3052 G.3042 G.3032 G.3022 G.3012 ...... ...... ...... ...... ...... ...... ...... ...... D.3050 D.3050 D.3050 D.3050 F.3050 F.3050 F.3050 F.3050 A#3050 A#3050 A#3050 A#3050 A.3050 A.3050 A.3050 A.3050",
	"PAT 10 C.2073 ...... ...... ...... C.4655 ...... C.2073 C.4605 C.2073 ...... ...... ...... C.4655 ...... C.2073 ...... C.2073 ...... C.2073 ...... C.4655 ...... C.2073 ...... ...... ...... C.2073 ...... C.4655 ...... C.2073 ......",
	"PAT 10 C.1150 C.1150 ...... ...... C.1150 C.1150 ...... ...... G.1150 G.1150 C.1150 C.1150 ...... ...... C.1150 ...... C.1150 C.1150 ...... ...... C.1150 C.1150 A#1150 A#1150 ...... ...... A.1150 A.1150 F.1150 F.1150 ...... ......",
	"PAT 10 C.1150 C.1150 ...... ...... C.1150 C.1150 ...... ...... G.1150 G.1150 C.1150 C.1150 ...... ...... C.1150 ...... C.1150 C.1150 ...... ...... C.1150 ...... C.1150 C.1150 A#1150 A#1150 A.1150 ...... F.1150 F.1150 D.1150 ......",
	"PAT 10 D.1150 D.1150 ...... ...... D.1150 D.1150 ...... ...... A.1150 A.1150 D.1150 D.1150 ...... ...... D.1150 ...... A#1150 ...... A#1150 ...... A.1150 A.1150 A#1150 A#1150 ...... ...... A.1150 A.1150 F.1150 F.1150 ...... ......",
	"PAT 10 C.1150 C.1150 ...... ...... C.1150 C.1150 ...... ...... G.1150 G.1150 C.1150 C.1150 ...... ...... C.1150 ...... C.1150 C.1150 ...... ...... C.1150 ...... C.1150 ...... A#1150 A#1150 A.1150 A.1150 F.1150 F.1150 ...... ......",
	"PAT 10 E.2550 E.2550 E.2550 E.2550 C.2550 C.2550 C.2550 C.2550 G.2550 G.2550 G.2550 G.2550 E.2550 E.2550 E.2550 E.2550 F.2550 F.2550 F.2550 F.2550 C.2550 C.2550 C.2550 C.2550 F.2550 F.2550 F.2550 F.2550 C.2550 C.2550 C.2550 C.2550",
	"PAT 10 E.2550 E.2550 E.2550 E.2550 C.2550 C.2550 C.2550 C.2550 G.2550 G.2550 G.2550 G.2550 E.2550 E.2550 E.2550 E.2550 C.2550 C.2550 C.2550 ...... C.2550 ...... C.2550 ...... F.2550 F.2550 G.2550 G.2550 A.2550 A.2550 A#2550 A#2550",
	"PAT 10 F.2550 F.2550 F.2550 F.2550 D.2550 D.2550 D.2550 D.2550 A.2550 A.2550 A.2550 A.2550 F.2550 F.2550 F.2550 F.2550 C.2550 C.2550 C.2550 C.2550 F.2550 F.2550 F.2550 F.2550 G.2550 G.2550 C.2550 F.2550 A.2550 C.2550 E.2550 G.2550",
	"PAT 10 G.2550 G.2550 G.2550 G.2550 C.2550 C.2550 C.2550 C.2550 G.2550 G.2550 G.2550 G.2550 C.2550 ...... A.1550 A.1550 D.2550 D.2550 A#2550 A#2550 A.2550 A.2550 F.2550 F.2550 A#2550 A#2550 G.2550 G.2550 C.2550 C.2550 F.2550 F.2550",
	"PAT 10 C.2073 ...... ...... ...... C.4655 ...... C.2073 C.4605 C.2073 ...... C.4655 ...... C.2073 ...... C.2073 ...... C.4655 ...... C.2073 ...... C.2073 ...... C.4655 C.4655 C.4655 ...... C.2073 C.2073 C.4655 ...... C.4655 ......",
	"PAT 10 C.4750 C.4751 C.4741 C.4741 C.4731 C.4721 D#4750 D#4750 D#4741 D#4731 C.4750 C.4750 C.4741 C.4731 C.4721 C.4731 F.4750 F.4750 F.4750 F.4750 D#4750 D#4750 D#4750 D#4750 D.4751 D.4750 C.4751 C.4750 A#3750 A#3750 A#3750 A#3750",
	"PAT 10 D.4750 D.4750 D.4750 D.4751 D.4741 D.4735 C.4750 C.4750 C.4750 C.4741 C.4741 C.4741 C.4731 C.4731 C.4721 C.4721 C.4711 C.4715 ...... ...... C.3730 F.3730 A.3720 C.3720 F.3730 A.3735 C.3725 F.3725 A#3730 A#3725 C.4730 C.4725",
	"PAT 10 C.4750 C.4750 C.4741 C.4741 C.4731 C.4721 F.4750 F.4741 F.4731 F.4721 C.4750 C.4741 C.4741 C.4731 C.4731 C.4721 G.4754 G.4750 G.4750 G.4750 F.4750 F.4750 F.4750 F.4750 D#4750 D#4750 D.4750 D.4750 A#3750 A#3750 A#3750 A#3750",
	"PAT 10 C.4750 C.4751 C.4741 C.4741 C.4731 C.4731 C.4721 C.4721 C.4711 C.4715 ...... ...... ...... ...... ...... ...... F.4730 F.4720 F.4730 F.4720 D#4730 D#4720 D#4730 D#4720 D.4730 D.4720 D.4730 D.4720 A#3730 A#3720 A#3730 A#3720",
	"PAT 10 D.1150 D.1150 ...... ...... D.1150 D.1150 A.1150 A.1150 ...... ...... A.1150 A.1150 F.1150 F.1150 ...... ...... A#1150 ...... A.1150 A.1150 A#1150 A#1150 ...... ...... A#1150 A#1150 F.1150 ...... F.1150 F.1150 ...... ......",
	"PAT 10 C.2550 C.2550 C.2550 C.2550 G.2550 G.2550 G.2550 G.2550 C.2550 C.2550 G.2550 G.2550 G.2550 G.2550 C.2550 C.2550 F.2550 F.2550 F.2550 F.2550 D#2550 D#2550 D#2550 D#2550 D.3550 D.3550 C.3550 C.3550 A#2550 A#2550 A#2550 A#2550",
	"PAT 10 D.2550 D.2550 D.2550 D.2550 A.2550 A.2550 A.2550 A.2550 F.2550 F.2550 A.2550 A.2550 A.2550 A.2550 A.2550 A.2550 A#2550 A#2550 A#2550 A#2550 A.2550 A.2550 A.2550 A.2550 F.2550 F.2550 F.2550 F.2550 C.2550 C.2550 C.2550 C.2550",
	"PAT 10 C.2550 C.2550 C.2550 C.2550 F.2550 F.2550 F.2550 F.2550 C.2550 C.2550 F.2550 F.2550 F.2550 F.2550 C.2550 C.2550 G.2550 G.2550 G.2550 G.2550 F.2550 F.2550 F.2550 F.2550 D#3550 D#3550 D.3550 D.3550 A#2550 A#2550 G.2550 G.2550",
	"PAT 10 C.2073 ...... ...... ...... C.4655 ...... C.2073 C.4605 C.4655 ...... C.2073 ...... ...... ...... C.2073 ...... C.4655 ...... ...... ...... C.4655 ...... C.2073 ...... C.2073 ...... C.4655 C.4655 C.4655 ...... C.2073 C.2073",
}

TILE_MAP={
-- upper
199,1,24,56,160,192,7,177,0,2,13,8,128,8,32,208,136,1,2,13,8,128,24,32,208,136,2,2,13,8,128,40,
32,208,136,3,2,13,8,128,56,32,208,136,4,2,13,8,128,72,32,208,136,5,2,13,8,128,88,32,208,136,6,2,
13,8,128,104,32,208,136,7,2,13,8,128,120,32,208,136,8,113,192,3,9,11,0,8,48,144,176,1,3,9,11,0,
24,48,144,176,2,3,9,11,0,40,48,144,176,3,3,9,11,0,56,48,144,176,3,131,0,11,1,48,48,0,176,18,
131,0,11,1,32,48,0,176,17,131,0,11,1,16,48,0,176,16,131,0,11,1,16,48,0,176,17,131,0,11,1,32,
48,0,176,18,131,0,11,1,48,48,0,176,19,131,0,11,1,56,48,144,176,3,3,9,11,0,40,48,144,176,2,3,
9,11,0,24,48,144,176,1,3,9,11,0,8,48,144,176,4,80,224,2,191,14,0,4,43,240,224,0,130,191,14,0,
12,43,240,224,1,2,191,14,0,20,43,240,224,1,130,191,14,0,28,43,240,224,1,130,190,14,1,20,43,224,224,17,
2,190,14,1,12,43,224,224,16,130,190,14,1,4,43,224,224,18,32,18,2,176,0,0,34,1,32,43,240,0,8,129,
196,3,140,9,0,72,56,192,144,5,3,140,9,0,88,56,192,144,6,3,140,9,0,104,56,192,144,7,3,140,9,0,
120,56,192,144,7,131,141,9,1,112,56,208,144,22,131,141,9,1,96,56,208,144,21,131,141,9,1,80,56,208,144,20,
131,141,9,1,80,56,208,144,21,131,141,9,1,96,56,208,144,22,131,141,9,1,112,56,208,144,23,131,141,9,1,120,
56,192,144,7,3,140,9,0,104,56,192,144,6,3,140,9,0,88,56,192,144,5,3,140,9,0,72,56,192,144,8,97,
196,3,43,12,0,72,50,176,192,5,3,43,12,0,88,50,176,192,6,3,43,12,0,104,50,176,192,7,3,43,12,0,
120,50,176,192,7,131,46,12,1,112,50,224,192,22,131,46,12,1,96,50,224,192,21,131,46,12,1,80,50,224,192,20,
131,46,12,1,80,50,224,192,21,131,46,12,1,96,50,224,192,22,131,46,12,1,112,50,224,192,23,131,46,12,1,120,
50,176,192,7,3,43,12,0,104,50,176,192,6,3,43,12,0,88,50,176,192,5,3,43,12,0,72,50,176,192,0,1,
82,63,0,0,0,36,65,0,0,15,228,16,67,35,240,232,0,0,68,16,0,0,0,70,35,240,0,240,0,68,16,0,
16,0,73,35,240,0,0,0,68,16,232,0,0,76,35,240,0,16,0,68,16,0,240,0,65,4,50,63,128,0,0,4,
64,128,0,0,4,98,62,206,128,0,4,65,64,0,0,4,146,62,0,0,0,36,66,0,0,15,228,194,62,192,0,0,
4,65,78,128,0,4,16,67,35,240,0,16,0,68,16,0,240,0,70,35,240,0,0,0,68,16,232,0,0,73,35,240,
0,240,0,68,16,0,16,0,76,35,240,232,0,0,68,16,0,0,0,65,4,50,62,192,0,0,4,65,78,128,0,4,
98,62,0,0,0,36,66,0,0,15,228,146,62,206,128,0,4,65,64,0,0,4,194,63,128,0,0,4,64,128,0,0,
4,0,26,65,0,208,0,0,38,40,192,240,0,98,40,192,232,1,53,216,192,240,0,80,1,164,31,205,0,0,50,110,
12,14,0,6,45,140,14,0,147,94,12,1,128,5,6,67,65,252,208,0,254,38,32,192,8,0,98,32,192,16,255,53,
224,192,216,0,85,65,0,208,0,1,38,40,192,240,0,98,40,192,232,0,53,216,192,240,0,87,65,4,208,0,2,38,
24,192,224,0,98,24,192,216,1,53,216,192,40,0,89,65,2,208,0,3,38,16,192,216,0,98,16,192,208,6,53,216,
192,40,0,80,100,52,31,205,0,0,50,110,12,14,0,6,45,140,14,0,131,94,12,1,128,5,84,31,237,0,0,34,
110,12,13,128,6,46,140,13,0,83,93,140,0,128,5,116,16,13,0,0,18,96,12,14,128,6,32,140,13,128,35,94,
12,14,128,5,148,16,13,0,0,2,97,140,15,0,6,33,140,14,0,19,94,140,13,128,5,0,26,65,0,208,0,0,
38,40,176,0,0,98,32,160,0,4,117,216,192,240,0,80,100,52,31,205,0,15,226,98,11,15,0,6,34,11,14,128,
71,94,12,13,128,5,132,16,13,0,0,18,98,12,13,128,6,34,11,141,0,72,93,140,15,0,5,180,16,77,0,0,
34,98,140,14,0,6,34,140,13,128,40,93,140,2,128,5,244,16,45,0,0,50,97,12,13,128,6,34,140,1,128,19,
93,140,2,128,5,8,0,56,0,0,55,22,56,234,0,232,0,0,0,241,0,34,0,222,6,34,60,226,0,208,30,0,
0,248,0,56,0,234,55,0,56,0,0,232,22,0,0,15,0,34,0,222,6,34,60,226,0,208,30,0,0,248,0,200,
8,234,200,0,201,0,0,9,22,0,24,15,0,222,8,222,196,34,250,226,0,0,30,0,48,8,0,200,8,0,200,22,
201,234,0,0,0,0,24,241,0,222,8,222,196,34,250,226,0,0,30,0,48,10,0,50,0,222,6,34,60,234,0,208,
22,0,0,241,0,34,0,222,6,34,60,234,0,208,22,0,0,246,0,50,0,222,6,34,60,234,0,208,22,0,0,15,
0,34,0,222,6,34,60,234,0,208,22,0,0,246,0,206,8,222,196,34,250,234,0,0,22,0,48,15,0,222,8,222,
196,34,250,234,0,0,22,0,48,10,0,206,8,222,196,34,250,234,0,0,22,0,48,241,0,222,8,222,196,34,250,234,
0,0,22,0,48,10,0,50,0,222,6,34,60,226,0,208,30,0,0,241,0,34,0,222,6,34,60,226,0,208,30,0,
0,246,0,50,0,222,6,34,60,226,0,208,30,0,0,15,0,34,0,222,6,34,60,226,0,208,30,0,0,246,0,206,
8,222,196,34,250,226,0,0,30,0,48,15,0,222,8,222,196,34,250,226,0,0,30,0,48,10,0,206,8,222,196,34,
250,226,0,0,30,0,48,241,0,222,8,222,196,34,250,226,0,0,30,0,48,11,196,0,160,60,0,160,99,192,10,3,
192,6,6,60,0,96,196,0,96,108,64,6,12,64,10,6,214,0,208,42,0,208,109,96,3,2,160,3,6,0,0,208,
0,0,48,96,0,10,16,0,10,102,0,0,95,0,0,90,109,64,10,29,64,5,246,44,0,161,44,0,95,98,108,16,
0,3,240,0,5,193,253,0,63,253,0,92,31,160,3,255,160,5,193,247,0,63,247,0,92,79,80,12,79,240,5,200,
245,0,200,255,0,92,207,80,12,207,240,5,208,245,0,208,255,0,93,79,80,13,79,240,5,216,245,0,216,255,0,93,
207,80,13,207,240,5,224,245,0,224,255,0,94,79,80,14,79,240,5,232,245,0,232,255,0,94,207,80,14,207,240,5,
240,245,0,240,255,0,95,79,80,15,79,240,5,248,245,0,248,255,0,95,207,80,15,207,240,5,0,245,0,0,255,0,
80,79,80,0,79,240,5,8,245,0,8,255,0,80,207,80,0,207,240,5,16,245,0,16,255,0,81,79,80,1,79,240,
5,24,245,0,24,255,0,81,207,80,1,207,240,5,32,245,0,32,255,0,82,79,80,2,79,240,5,40,245,0,40,255,
0,82,207,80,2,207,240,5,48,245,0,48,255,0,83,79,80,3,79,240,5,56,245,0,56,255,0,83,207,80,3,207,
240,5,192,244,0,192,0,0,4,15,64,4,0,0,0,192,244,0,64,244,0,114,114,1,80,80,178,144,176,80,181,176,
0,128,179,240,160,80,180,225,64,128,183,112,160,128,182,49,64,128,182,144,0,128,183,128,0,128,180,113,64,128,181,81,
64,128,183,17,64,128,178,0,0,128,178,112,0,128,183,0,160,128,183,0,0,128,182,128,160,128,181,193,64,128,178,224,
0,128,179,80,0,128,179,192,0,64,180,80,0,112,178,0,160,128,179,240,0,112,180,176,0,160,181,64,0,128,181,176,
0,128,182,161,64,128,179,112,160,128,198,32,0,128,182,144,0,128,180,1,64,128,180,48,160,128,183,129,64,128,180,160,
160,160,179,240,160,128,181,160,160,128,176,112,160,128,177,176,160,80,192,0,0,0,0,0,0,0,0,0,0,0,0,0,
}

INST_TRIANGLE = "INST OVERTONE 1.0 TRIANGLE 1.0 METALIZER 0.85 NAM triangle"
INST_TILTED = "INST OVERTONE 1.0 TRIANGLE 0.5 SAW 0.1 NAM tilted"
INST_SAW = "INST OVERTONE 1.0 SAW 1.0 ULTRASAW 1.0 NAM saw"
INST_SQUARE = "INST OVERTONE 1.0 SQUARE 0.5 NAM square"
INST_PULSE = "INST OVERTONE 1.0 SQUARE 0.5 PULSE 0.5 TRIANGLE 1.0 METALIZER 1.0 OVERTONE_RATIO 0.5 NAM pulse"
INST_ORGAN = "INST OVERTONE 0.5 TRIANGLE 0.75 NAM organ"
INST_NOISE = "INST NOISE 1.0 NOISE_COLOR 0.2 NAM noise"
INST_PHASER = "INST OVERTONE 0.5 METALIZER 1.0 TRIANGLE 0.7 NAM phaser"

MUSIC_TITLE = [[NAM title screen
PATLIST 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30
SEQ2 00040509.... 0104060a.... 0204070b.... 030d080c.... 00040509.... 010d060a.... 0204070b.... 030d080c.... 0e160513.... 0f0d1214.... 10160615.... 110d0813....]]
