local LAYER_FONTS <const> = 1
local LAYER_PINBALL_L1 <const> = 2
local FONT_ZONE_H <const> = 32
local TABLE_HEIGHT <const> = 452
local BALL_FRICTION <const> = 0.01
local BALL_GRAVITY <const> = 0.2
local BALL_RADIUS <const> = 6
local SPRING_BOUNCE <const> = 0.8
local SPRING_LENGTH <const> = 38
local SPRING_POS <const> = 408
local WALL_BOUNCE <const> = 0.8
local FLIPPER_BOUNCE <const> = 0.9
local FLIPPER_ANGLE_SPEED <const> = 0.07 * math.pi * 2
local FLIPPER_MAX_ANGLE <const> = 0.17 * math.pi * 2
local FLIPPER_ANGLE_FIX <const> = 0.035 * math.pi * 2
local BUMPER_BOUNCE <const> = 1.5
local TIME_COEF <const> = 0.8
local RBUMPER_RADIUS <const> = 17
local RBUMPER_BASE_SCORE <const> = 130
debug_colliders=true
pause=false

function v2d(x,y)
    return {x=x,y=y}
end
function v2d_add(a,b)
    return v2d(a.x+b.x,a.y+b.y)
end
function v2d_sub(a,b)
    return v2d(a.x-b.x,a.y-b.y)
end
function v2d_clone(v)
    return {x=v.x,y=v.y}
end
function v2d_scale(v,f)
    v.x = v.x*f
    v.y = v.y*f
end
function v2d_len2(v)
    return v.x*v.x+v.y*v.y
end
function v2d_len(v)
    local l=v.x*v.x+v.y*v.y
    return math.sqrt(l)
end
function v2d_norm(v)
    local l=v2d_len(v)
    l = l==0 and 1 or l
    return v2d(v.x/l,v.y/l)
end
function v2d_perpendicular(v)
    return v2d(-v.y,v.x)
end
function v2d_dot(a,b)
    return a.x*b.x+a.y*b.y
end
function v2d_rotate(v, origin, ang)
    local cs=math.cos(ang)
    local sn=math.sin(ang)
    local v=v2d_sub(v,origin)
    return v2d_add(v2d(v.x*cs+v.y*sn,v.y*cs-v.x*sn),origin)
end
function clamp(v,min,max)
    return v < min and min or v > max and max or v
end
function sign(val)
	return val > 0 and 1 or (val < 0 and -1 or 0)
end

function inp_lflip_pressed()
    return inp.action1_pressed() or inp.pad_button_pressed(1,inp.XBOX360_LB)
end

function inp_rflip_pressed()
    return inp.action2_pressed() or inp.pad_button_pressed(1,inp.XBOX360_RB)
end


function inp_lflip()
    return inp.action1() or inp.pad_button(1,inp.XBOX360_LB)
end

function inp_rflip()
    return inp.action2() or inp.pad_button(1,inp.XBOX360_RB)
end

function init_title()
    cam=0
    mode.cam_spd=1
    mode.layout_w,mode.layout_h = gfx.get_layer_size(LAYER_PINBALL_L1)
    MAX_CAM=mode.layout_h-gfx.SCREEN_HEIGHT
    mode.msg={
        {msg="HORROR",font=fonts.big},
        {msg="MANSION",font=fonts.big}
    }
    init_pinball()
end

function update_title()
    cam = cam + mode.cam_spd
    if mode.cam_spd == 1 and cam == MAX_CAM then
        mode.cam_spd = -1
    elseif mode.cam_spd == -1 and cam == 0 then
        mode.cam_spd = 1
    end
    if mode.scroller < 19*16 then
        mode.scroller = mode.scroller+2
    elseif t < 5 then
        mode.blink = (mode.blink + 0.2)%2
    elseif t < 10 then
        mode.blink=0
        mode.msg={{msg="PRESS",font=fonts.big},{msg="START",font=fonts.big}}
    elseif t < 13 then
        mode.blink = (mode.blink + 0.2)%2
    elseif t < 17 then
        mode.blink=0
        mode.msg={{msg="HIGH",font=fonts.big},{msg="SCORES",font=fonts.big}}
    elseif t<20 then
        mode.blink = (mode.blink + 0.2)%2
    elseif t < 20+#scores * 3 then
        mode.blink=0
        local i=(t-20)//3+1
        mode.msg[1].msg=string.format("%d %s",i,scores[i].name)
        mode.msg[2].msg=tostring(scores[i].score)
    end
    if t > 3 then
        if inp_lflip_pressed() or inp_rflip_pressed() or inp.pad_button_pressed(1,inp.XBOX360_START) then
            mode=modes.ready
        end
    end
end

function render_title()
    render_msg()
    render_pinball()
end

function init_ready()
    mode.msg={
        {msg="1 PLAYER",font=fonts.big},
        {msg="C ADD",font=fonts.smol},
        {msg="X REMOVE",font=fonts.smol},
    }
end

function update_ready()
    if t < 1 then
        mode.blink = (mode.blink + 0.2)%2
    else
        mode.blink=0
    end
    if inp_lflip_pressed() and mode.credits > 1 then
        mode.credits=mode.credits-1
        mode.msg[1].msg=string.format("%d PLAYER",mode.credits)
        t=0
    end
    if inp_rflip_pressed() or inp.pad_button_pressed(1,inp.XBOX360_START) then
        mode.credits=mode.credits+1
        mode.msg[1].msg=string.format("%d PLAYER",mode.credits)
        t=0
    end
    update_pinball()
end

function init_game()
    mode.msg={
        {msg="       0",font=fonts.big},
        {msg="PLAYER 1",font=fonts.smol},
        {msg="BALLS  3",font=fonts.smol},
    }
    mode.old_score=0
    mode.old_pnum=1
    mode.old_balls=3
    players={}
    for i=1,modes.ready.credits do
        table.insert(players, {
            num=i,
            score=0,
            rem_balls=3
        })
    end
    player=players[1]
end

function update_game()
    if player.score ~= mode.old_score then
        mode.msg[1].msg=string.format("%8.0f",player.score)
    end
    if player.num ~= mode.old_pnum then
        mode.msg[2].msg=string.format("PLAYER %.0f",player.num)
    end
    if player.rem_balls ~= mode.old_balls then
        mode.msg[3].msg=string.format("BALLS  %.0f",player.rem_balls)
    end
    mode.old_score=player.score
    mode.old_pnum=player.num
    mode.old_balls=player.rem_balls
    update_pinball()
end

function render_game()
    render_msg()
    render_pinball()
end

function render_msg()
    gfx.set_sprite_layer(LAYER_PINBALL_L1)
    gfx.blit(gfx.SCREEN_WIDTH-96,0,96,224,gfx.SCREEN_WIDTH-96,0)
    gfx.set_sprite_layer(LAYER_FONTS)
    gfx.print(fonts.big.id, "        ", gfx.SCREEN_WIDTH-96,0)
    gfx.print(fonts.big.id, "        ", gfx.SCREEN_WIDTH-96,32)
    if mode.blink < 1 then
        local y=0
        for i=1,#mode.msg do
            local m=mode.msg[i]
            if m and m.msg then
                local dx=(96-12*#m.msg)/2
                gfx.print(m.font.id, m.msg, gfx.SCREEN_WIDTH-96+dx,y)
                y=y+m.font.h
            end
        end
    end
end
function cbk_rbumper(c)
    pinball.rbump_timer=15
end
function cbk_lbumper(c)
    pinball.lbump_timer=15
end
function cbk_round_bumper(c)
    c.timer=15
    player.score = player.score + RBUMPER_BASE_SCORE
end
function cbk_target(c)
    c.lit=true
end
function init_pinball()
    pinball={
        colliders={},
        spring=0,
        spring_col=nil,
        balls={},
        ready_ball=nil,
        lflipper=nil,
        rflipper=nil,
    }
    pinball.spring_col=add_wall_collider("spring",285,SPRING_POS,272,SPRING_POS,SPRING_BOUNCE)
    add_ball(279,SPRING_POS-BALL_RADIUS)
    local walls={{ name="outer wall",
        84,451,0,405,0,312,18,283,19,275,4,261,3,255,30,209,31,200,2,99,2,52,9,35,20,22,35,11,51,4,
        66,2,181,2,234,4,246,7,257,12,266,19,274,29,279,43,281,59,283,78,284,103
    },{ name="outer wall2",
        268,95,241,195,241,201,255,214,255,219,249,226,249,232,258,262,259,272,253,281,
        248,286,250,294,267,307,269,312,269,400,265,406,189,451
    },{ name="right gutter",
        251,325,250,378,240,390,188,415
    },{ name="left gutter",
        81,415,21,382,18,374,18,323
    }, { name="left bumper",bounce=BUMPER_BOUNCE,callback=cbk_lbumper,
        65,375,46,322,42,320,38,322,36,363,40,369,63,382,66,382,65,375
    }, { name="right bumper",bounce=BUMPER_BOUNCE,callback=cbk_rbumper,
        223,322,201,377,203,381,208,383,231,368,233,364,233,324,230,320,225,319,223,322
    }, { name="island 1",
        225,67,220,103,223,111,227,121,231,121,233,117,234,106,256,51,256,39,241,22,225,16,222,18,218,33,215,41,217,44,221,46,225,55,225,67
    }, { name="island 2",
        217,140,195,114,163,120,160,123,160,164,163,169,172,136,201,144,197,178,198,182,206,184,219,148,217,140
    }, { name="island 3",
        56,22,49,27,35,36,24,54,23,79,28,102,45,142,62,183,64,185,70,183,71,180,58,83,54,33,59,23,56,22
    }, { name="island 4",
        100,0,113,8,117,20,113,28,103,33,79,44,74,49,77,68,
        -- tower exit
        90,119,92,121,137,108,141,122,96,135,95,138,
        104,174,153,191,155,187,145,177,144,171,144,107,150,94,160,61,
        160,23,155,18,141,19,140,82,134,92,122,100,111,102
    }, { name="island 4.1",
           111,83,116,83,121,79,122,75,122,20,128,8,135,2,145,0
    }, { name="tower door",
        160,22,160,1
    }, { name="tower ramp",level=2,
        111,102,98,100,86,91,81,79,82,67,89,53,102,46,116,45,125,49,135,59,140,73,
        140,116,136,124,128,124,123,119,123,70,116,63,109,63,103,67,101,74,106,81,111,83,
    }
    }
    for i=1,#walls do
        local w=walls[i]
        for j=0,#w/2-2 do
            local p=j*2+1
            add_wall_collider(w.name, w[p],w[p+1],w[p+2],w[p+3],WALL_BOUNCE,w.bounce or 0,w.callback,w.level)
        end
    end
    pinball.rbumpers={}
    table.insert(pinball.rbumpers,add_round_collider("round bumper 1",157,79,RBUMPER_RADIUS,BUMPER_BOUNCE,cbk_round_bumper))
    table.insert(pinball.rbumpers,add_round_collider("round bumper 2",179,114,RBUMPER_RADIUS,BUMPER_BOUNCE,cbk_round_bumper))
    table.insert(pinball.rbumpers,add_round_collider("round bumper 3",219,83,RBUMPER_RADIUS,BUMPER_BOUNCE,cbk_round_bumper))
    -- tower key pins
    add_round_collider("key_pin1.1",178,38,2.5,0)
    add_round_collider("key_pin1.2",178,46,2.5,0)
    add_round_collider("key_pin2.1",197,38,2.5,0)
    add_round_collider("key_pin2.2",197,46,2.5,0)
    -- nightmare targets
    pinball.targets={}
    add_target("N",{15,256,19,247},17,250)
    add_target("I",{21,242,26,233},24,236)
    add_target("G",{29,229,34,220},32,222)
    add_target("H",{65,191,74,187},67,190)
    add_target("T",{114,182,124,185},112,185)
    add_target("M",{131,187,141,190},129,190)
    add_target("A",{194,187,204,190},192,191)
    add_target("R",{244,240,249,250},234,244)
    add_target("E",{250,258,255,268},238,260)
    add_round_collider("central pin",134,443,2.5,0)
    pinball.rollover={}
    add_rollover_detector(169,42,369,296,14,14,163,47)
    add_rollover_detector(188,42,369,312,14,14,183,47)
    add_rollover_detector(206,45,369,328,14,14,202,51)
    pinball.launch_block=add_collider("launch block",{v2d(280,49),v2d(268,95)},WALL_BOUNCE,0,collide_polygon)
    pinball.launch_block.disabled=true
    pinball.lflipper=add_collider("left flipper",{v2d(42,24),v2d(6,0),v2d(4,0),v2d(0,9),v2d(38,28),v2d(41,27),v2d(42,24)},FLIPPER_BOUNCE,0,collide_flipper)
    pinball.rflipper=add_collider("right flipper",{v2d(6,0),v2d(42,24),v2d(41,27),v2d(38,28),v2d(0,9),v2d(4,0),v2d(6,0)},FLIPPER_BOUNCE,0,collide_flipper)
    pinball.lflipper.base_collider={}
    pinball.rflipper.base_collider={}
    for i=1,#pinball.lflipper do
        table.insert(pinball.lflipper.base_collider,v2d_clone(pinball.lflipper[i]))
        table.insert(pinball.rflipper.base_collider,v2d_clone(pinball.rflipper[i]))
    end
    pinball.lflipper.pos=v2d(81,421)
    pinball.lflipper.origin=v2d(6,6)
    pinball.lflipper.angle=0
    pinball.rflipper.pos=v2d(188,421)
    pinball.rflipper.origin=v2d(6,6)
    pinball.rflipper.hflip=true
    pinball.rflipper.angle=0
end
function update_spring()
    local spring_spd=0
    if inp.key(inp.KEY_DOWN) or inp.pad_button(1,inp.XBOX360_A) then
        pinball.spring = math.min(22,pinball.spring+0.5)
    elseif pinball.spring > 0 then
        spring_spd = pinball.spring
        pinball.spring=0
    end
    local spring_y=SPRING_POS + pinball.spring
    pinball.spring_col[1].y=spring_y
    pinball.spring_col[2].y=spring_y
    return spring_y,spring_spd
end
function update_pinball()
    local spring_y,spring_spd=update_spring()
    if pinball.ready_ball then
        local b=pinball.ready_ball
        if spring_spd > 0 then
            if b.pos.y >= spring_y-BALL_RADIUS then
                b.pos.y = spring_y-BALL_RADIUS
                b.spd.y = -spring_spd
            end
        elseif pinball.launch_block.collide(b,pinball.launch_block) then
            pinball.ready_ball=nil
            pinball.launch_block.disabled=false
            if mode == modes.ready then
                mode=modes.game
            end
        end
    end

    update_flipper(pinball.lflipper,inp_lflip,inp_lflip_pressed,-1)
    update_flipper(pinball.rflipper,inp_rflip,inp_rflip_pressed,1)
    if pinball.rbump_timer then
        pinball.rbump_timer = pinball.rbump_timer > 1 and pinball.rbump_timer-1 or nil
    end
    if pinball.lbump_timer then
        pinball.lbump_timer = pinball.lbump_timer > 1 and pinball.lbump_timer-1 or nil
    end
    for i=1,#pinball.rbumpers do
        local b=pinball.rbumpers[i]
        if b.timer then
            b.timer = b.timer > 1 and b.timer-1 or nil
        end
    end
    local lowest_ball=nil
    for i=1,#pinball.balls do
        local b=pinball.balls[i]
        update_ball(b)
        for i=1,#pinball.rollover do
            local c=pinball.rollover[i]
            local collide=c.collide(b,c)
            if not collide and c.collides then
                c.lit=true
            end
            c.collides=collide
        end
        if pinball.ready_ball == nil and b.pos.y > TABLE_HEIGHT + BALL_RADIUS then
            -- ball is lost
            b.pos.x=279
            b.pos.y=SPRING_POS-BALL_RADIUS
            b.spd.x=0
            b.spd.y=0
            pinball.ready_ball=b
            pinball.launch_block.disabled=true
            player.rem_balls = player.rem_balls - 1
            local steps=0
            repeat
                local next_player=(player.num % #players) + 1
                player=players[next_player]
                steps=steps+1
            until player.rem_balls > 0 or steps==#players
            if player.rem_balls == 0 then
                -- game over
                mode=modes.title
            end
        end
        if lowest_ball == nil or b.pos.y > lowest_ball.pos.y then
            lowest_ball = b
        end
    end
    local target=lowest_ball.pos.y-gfx.SCREEN_HEIGHT/2
    local cam_target=MAX_CAM * clamp(target/MAX_CAM,0,1)
    cam = cam + (cam_target-cam)*0.3
end
function render_pinball()
    gfx.set_sprite_layer(LAYER_PINBALL_L1)
    -- level 1
    gfx.blit(0,cam,gfx.SCREEN_WIDTH-96,gfx.SCREEN_HEIGHT,0,0)
    render_flipper(pinball.lflipper)
    render_flipper(pinball.rflipper)
    render_spring(pinball.spring)
    for i=1,#pinball.rollover do
        local r=pinball.rollover[i]
        if r.lit then
            local s=r.sprite
            gfx.blit(s.x,s.y,s.w,s.h,r.sprite_pos.x,r.sprite_pos.y-cam)
        end
    end
    for i=1,#pinball.targets do
        local t=pinball.targets[i]
        if t.lit then
            gfx.blit(355,295+(i-1)*14,14,14,t.sprite_pos.x,t.sprite_pos.y-cam)
        end
    end
    -- level 1 balls
    for i=1,#pinball.balls do
        if pinball.balls[i].level==1 then
            render_ball(pinball.balls[i])
        end
    end
    -- tower ramp
    gfx.blit(337,342,18,79,122,47-cam)
    -- level 2 balls
    for i=1,#pinball.balls do
        if pinball.balls[i].level==2 then
            render_ball(pinball.balls[i])
        end
    end
    -- level 2
    for i=1,#pinball.rbumpers do
        local b=pinball.rbumpers[i]
        if b.timer then
            gfx.blit(321,308,34,34,b.p.x-RBUMPER_RADIUS,b.p.y-RBUMPER_RADIUS-cam)
        end
    end
    gfx.blit(288,446,15,6,272,443-cam)
    gfx.blit(288,371,14,75,272,49-cam)
    if pinball.rbump_timer then
        gfx.blit(303,396,28,56,204,325-cam)
    end
    if pinball.lbump_timer then
        gfx.blit(303,342,22,54,42,325-cam)
    end
    if not pinball.tower_open then
        -- tower door
        gfx.blit(288,353,7,18,154,3-cam)
    end
    gfx.set_sprite_layer(LAYER_FONTS)
    if debug_colliders then
        for i=1,#pinball.colliders do
            local c=pinball.colliders[i]
            for i=2,#c do
                local p1=world_pos(c,i-1)
                local p2=world_pos(c,i)
                gfx.line(p1.x,p1.y-cam,p2.x,p2.y-cam,c.disabled and 0 or 255,0,c.disabled and 255 or 0)
                local v=v2d_norm(v2d_perpendicular(v2d_sub(p2,p1)))
                gfx.line(p1.x,p1.y-cam,p1.x+v.x*3,p1.y+v.y*3-cam,0,255,0)
            end
        end
    end
end

function update_flipper(flipper,inp_fn,inp_pressed_fn,keydir)
    if flipper.cooldown then
        flipper.cooldown = flipper.cooldown>1 and flipper.cooldown-1 or nil
    end
    if inp_fn() then
        flipper.moving = flipper.angle < FLIPPER_MAX_ANGLE and 1 or 0
    else
        flipper.moving = flipper.angle > 0 and -1/3 or 0
    end
    if flipper.moving ~= 0 then
        flipper.angle = clamp(flipper.angle + flipper.moving * FLIPPER_ANGLE_SPEED,0,FLIPPER_MAX_ANGLE)
        local ang=flipper.angle
        for i=1,#flipper do
            flipper[i] = v2d_rotate(flipper.base_collider[i],flipper.origin,ang)
        end
    end
    if inp_pressed_fn() then
        for i=1,#pinball.rollover do
            local next=(i%#pinball.rollover) + 1
            if keydir == -1 then
                pinball.rollover[i].nlit = pinball.rollover[next].lit
            else
                pinball.rollover[next].nlit = pinball.rollover[i].lit
            end
        end
        for i=1,#pinball.rollover do
            pinball.rollover[i].lit = pinball.rollover[i].nlit
        end
    end
end
flipper_sprites={
    {x=288,y=263,w=43,h=29},
    {x=331,y=263,w=46,h=20},
    {x=331,y=283,w=48,h=12},
    {x=331,y=263,w=46,h=20},
    {x=288,y=263,w=43,h=29},
}
function render_flipper(flipper)
    local spr=clamp(5*flipper.angle//FLIPPER_MAX_ANGLE+1,1,5)
    local s=flipper_sprites[spr]
    local pos=flipper.pos
    local origin=flipper.origin
    local y=pos.y-cam-origin.y
    local hflip=flipper.hflip
    local vflip=spr > 3
    if vflip then
        y=y-s.h+2*origin.y
    end
    if y < gfx.SCREEN_HEIGHT then
        gfx.blit(s.x,s.y,s.w,s.h,hflip and pos.x-s.w +origin.x or pos.x-origin.x,y,nil,nil,nil,nil,nil,nil,hflip,vflip)
    end
end

function render_spring(pos)
    local y=SPRING_POS-cam+pos
    if y < gfx.SCREEN_HEIGHT then
        gfx.blit(300,225,6,SPRING_LENGTH,276,y)
        local s=pos*5//22
        gfx.blit(306+s*8,233+s*4,8,30-s*4,275,y+8,nil,nil,nil,nil,nil,30-pos)
        gfx.blit(275,TABLE_HEIGHT-8,8,8,275,TABLE_HEIGHT-8-cam)
    end
end
function render_ball(b)
    local y=b.pos.y-BALL_RADIUS-cam
    if y < gfx.SCREEN_HEIGHT and y > -12 then
        gfx.blit(288,225,12,12,b.pos.x-BALL_RADIUS,y)
    end
end
function add_target(name,wall,sx,sy)
    local col=add_collider(name,{v2d(wall[1],wall[2]),v2d(wall[3],wall[4])},WALL_BOUNCE,0,collide_polygon,cbk_target)
    col.sprite_pos={x=sx,y=sy}
    col.lit=false
    table.insert(pinball.targets,col)
end
function add_rollover_detector(x,y,sx,sy,sw,sh,px,py)
    local col=add_round_collider("rollover",x,y,1,0)
    col.disabled=true
    col.cbk=nil
    col.sprite={x=sx,y=sy,w=sw,h=sh}
    col.sprite_pos={x=px,y=py}
    col.lit=false
    col.is_colliding=false
    table.insert(pinball.rollover,col)
end
function add_round_collider(name,x,y,r,bounce,cbk)
    local col={
        p=v2d(x,y),
        r=r,
        bounce=bounce,
        bounce_coef=WALL_BOUNCE,
        collide=collide_rbumper,
        cbk=cbk,
        level=1
    }
    table.insert(pinball.colliders,col)
    return col
end
function add_wall_collider(name, x1,y1,x2,y2,bounce_coef, bounce, cbk,level)
    return add_collider(name, {v2d(x1,y1),v2d(x2,y2)},bounce_coef,bounce,collide_polygon,cbk,level)
end
function add_collider(name,points,bounce_coef, bounce, collide_fn, cbk, level)
    local col=points
    col.name=name
    col.collide=collide_fn
    col.bounce_coef=bounce_coef
    col.bounce = bounce or 0
    col.cbk=cbk
    col.level = level or 1
    table.insert(pinball.colliders,col)
    return col
end
function add_ball(x,y)
    local pos=v2d(x,y)
    table.insert(pinball.balls,{pos=pos,old_pos=v2d_clone(pos),spd=v2d(0,0),spd_mag=0,level=1})
    if #pinball.balls == 1 then
        pinball.ready_ball=pinball.balls[1]
    end
end
function update_ball(b)
    v2d_scale(b.spd, 1-BALL_FRICTION*TIME_COEF)
    b.spd.y = b.spd.y + BALL_GRAVITY*TIME_COEF
    b.spd_mag=v2d_len(b.spd)
    local spd=math.min(2,b.spd_mag)
    local rem_spd=b.spd_mag
    local collides=false
    while spd > 0 and not collides do
        b.old_pos.x=b.pos.x
        b.old_pos.y=b.pos.y
        b.pos.x = b.pos.x + b.spd.x*spd/b.spd_mag*TIME_COEF
        b.pos.y = b.pos.y + b.spd.y*spd/b.spd_mag*TIME_COEF
        if debug_colliders then
            print(string.format("    ball pos %.0f %.0f spd %.0f %.0f",b.pos.x,b.pos.y,b.spd.x,b.spd.y))
        end

        rem_spd = rem_spd - spd
        spd=math.min(2,rem_spd)
        for i=1,#pinball.colliders do
            local c=pinball.colliders[i]
            if not c.disabled and c.level == b.level then
                local idx,inter,n,spd=c.collide(b,c)
                if inter then
                    if idx==1 and c.cbk then
                        c.cbk(c)
                    end
                    collides=true
                    -- bounce
                    if spd then
                        b.spd=v2d_add(b.spd,spd)
                        if debug_colliders then
                            print(string.format("COLL %s new speed %.0f,%.0f",c.name, b.spd.x,b.spd.y))
                        end
                    else
                        local sn=v2d_clone(n)
                        v2d_scale(sn, 2*c.bounce_coef*v2d_dot(b.spd,n))
                        local new_spd=v2d_sub(b.spd,sn)
                        if c.bounce > 0 then
                            v2d_scale(n,c.bounce)
                            new_spd=v2d_add(new_spd,n)
                        end
                        if debug_colliders then
                            print(string.format("COLL %s n %.0f %.0f sn %.0f %.0f spd %.0f,%.0f -> %.1f,%.1f",c.name,n.x,n.y,sn.x,sn.y,b.spd.x,b.spd.y,new_spd.x,new_spd.y))
                        end
                        b.spd=new_spd
                    end
                    b.pos.x=inter.x+n.x * BALL_RADIUS+b.spd.x * TIME_COEF
                    b.pos.y=inter.y+n.y * BALL_RADIUS+b.spd.y * TIME_COEF
                    if debug_colliders then
                        print(string.format(">ball pos %.0f %.0f",b.pos.x,b.pos.y))
                    end
                end
            end
        end
    end
end
function collide_rbumper(ball,col)
    local dist=v2d_sub(ball.pos,col.p)
    local l=v2d_len2(dist)
    if l > (BALL_RADIUS+col.r)^2 then
        return
    end
    local n=v2d_norm(dist)
    local ivec=v2d_clone(n)
    v2d_scale(ivec,col.r)
    local inter=v2d_add(col.p,ivec)
    return 1,inter,n
end
function collide_flipper(ball,flipper_col)
    if flipper_col.cooldown then
        return nil
    end
    if (flipper_col.moving == 0) then
        return collide_polygon(ball,flipper_col)
    end
    for i=2,#flipper_col do
        local p1=world_pos(flipper_col,i-1)
        local p2=world_pos(flipper_col,i)
        local inter,n=collide_sphere(ball,p1,p2)
        if n then
            local spd_mag = 0.1 * flipper_col.moving * v2d_len(v2d_sub(flipper_col.origin, ball.pos)) * math.sin(FLIPPER_ANGLE_SPEED)
            local real_angle=flipper_col.angle - FLIPPER_ANGLE_FIX - FLIPPER_MAX_ANGLE/2
            local spd_vec = v2d(
                (flipper_col.hflip and spd_mag or -spd_mag) * math.sin(real_angle),
                -spd_mag * math.cos(real_angle))
            flipper_col.cooldown=4
            return i-1,inter,n,spd_vec
        end
    end
end
function collide_polygon(ball,poly)
    local ballv=v2d_sub(ball.pos,ball.old_pos)
    local vlen=v2d_len2(ballv)
    local ballv=vlen > 0.1 and v2d_norm(ballv) or ballv
    v2d_scale(ballv,BALL_RADIUS)
    local ballp2=v2d_add(ball.pos,ballv)
    for i=2,#poly do
        local p1=world_pos(poly,i-1)
        local p2=world_pos(poly,i)
        if vlen > 0.1 then
            local inter=collide_line(ball.old_pos, ballp2, p1, p2)
            if inter then
                local wall_line=v2d_sub(p2,p1)
                local n=v2d_perpendicular(v2d_norm(wall_line))
                return i-1,inter,n
            end
        end
        local inter,n=collide_sphere(ball,p1,p2)
        if n then
            return i-1,inter,n
        end
    end
end
function world_pos(poly,i)
    local p=poly[i]
    if poly.hflip then
        p=v2d(-p.x,p.y)
    end
    if poly.origin then
        if poly.hflip then
            p=v2d(p.x+poly.origin.x,p.y-poly.origin.y)
        else
            p=v2d_sub(p,poly.origin)
        end
    end
    if poly.pos then
        p=v2d_add(p,poly.pos)
    end
    return p
end
function collide_sphere(ball,p1,p2)
    -- adapted from https://github.com/mreinstein/collision-2d/blob/main/src/ray-sphere-overlap.js
    local dp=v2d_sub(p2,p1)
    local a=v2d_len2(dp)
    local b=2*v2d_dot(dp,v2d_sub(p1,ball.pos))
    local c=v2d_len2(ball.pos) + v2d_len2(p1) - 2*v2d_dot(p1,ball.pos) - BALL_RADIUS*BALL_RADIUS
    local bb4ac = b*b-4*a*c
    if bb4ac < 0 then
        return
    end
    bb4ac=math.sqrt(bb4ac)
    local c1=(bb4ac-b)/(2*a)
    local c2=(-bb4ac-b)/(2*a)
    local coef=-1
    if c1 >= 0 and c1 <= 1 then
        if c2 >= 0 and c2 <= 1 then
            coef=(c1+c2)*0.5
        else
            coef=c1
        end
    elseif c2 >=0 and c2 <= 1 then
        coef=c2
    end
    if coef == -1 then
        return
    end
    local inter=v2d(p1.x+dp.x*coef,p1.y+dp.y*coef)
    if debug_colliders then
        print(string.format("collide_sphere : sphere at %.0f %.0f collides with %.0f %.0f - %.0f %.0f at %.0f %.0f",
            ball.pos.x,ball.pos.y,
            p1.x,p1.y,p2.x,p2.y,
            inter.x,inter.y
        ))
    end
    local wall_line=v2d_sub(p2,p1)
    local n=v2d_perpendicular(v2d_norm(wall_line))
    return inter,n
end

function calc_inf_line_abc(p1, p2)
    local a = p2.y - p1.y
    local b = p1.x - p2.x
    local c = (p2.x * p1.y) - (p1.x * p2.y)
    return a, b, c
end
function side_of_line(v1, v2, p)
    return (p.x - v1.x) * (v2.y - v1.y) - (p.y - v1.y) * (v2.x - v1.x)
end
function collide_line(p1,p2,q1,q2)
    if side_of_line(q1,q2,p2)<= 0 then
        return nil
    end
    local a1,b1,c1=calc_inf_line_abc(p1,p2)
    local a2,b2,c2=calc_inf_line_abc(q1,q2)
    local d1 = (a1 * q1.x) + (b1 * q1.y) + c1
    local d2 = (a1 * q2.x) + (b1 * q2.y) + c1
    if sign(d1) == sign(d2) then
        return nil
    end
    local d1 = (a2 * p1.x) + (b2 * p1.y) + c2
    local d2 = (a2 * p2.x) + (b2 * p2.y) + c2
    if sign(d1) == sign(d2) then
        return nil
    end

    local coef=d1/(d2-d1)
    local inter=v2d(p1.x+b1*coef,p1.y-a1*coef)
    if debug_colliders then
        print(string.format("collide_line : %.0f %.0f - %.0f %.0f collides with %.0f %.0f - %.0f %.0f at %.0f %.0f",
            p1.x,p1.y,p2.x,p2.y,
            q1.x,q1.y,q2.x,q2.y,
            inter.x,inter.y
        ))
    end
    return inter
end

function init_dbgphys()
    mode.msg={
        {msg="DEBUG",font=fonts.big}
    }
end

function update_dbgphys()
    local mx,my=inp.mouse_pos()
    local ball=pinball.balls[1]
    ball.old_pos.x=ball.pos.x
    ball.old_pos.y=ball.pos.y
    ball.pos.x=mx
    ball.pos.y=my+cam
    mode.wall=nil
    mode.inter=nil
    mode.spd=nil
    update_flipper(pinball.lflipper,inp_lflip)
    update_flipper(pinball.rflipper,inp_rflip)
    for i=1,#pinball.colliders do
        local c=pinball.colliders[i]
        local wall,inter,spd=c.collide(ball,c)
        if wall then
            mode.wall=wall
            mode.inter=inter
            mode.spd=spd
        end
    end
end

function render_dbgphys()
    render_msg()
    render_pinball()
    if mode.wall then
        local w=mode.wall
        local p1=w[1]
        local p2=w[2]
        gfx.line(p1.x,p1.y-cam,p2.x,p2.y-cam,255,255,0)
        gfx.disk(mode.inter.x,mode.inter.y-cam,2,2,0,0,255)
    end
    local ball=pinball.balls[1]
    gfx.print(gfx.FONT_5X7,string.format("ball pos %.1f %.1f",ball.pos.x,ball.pos.y),5,5)
end

function init()
    gfx.load_img(LAYER_FONTS,"pinball/fonts.png")
    gfx.load_img(LAYER_PINBALL_L1,"pinball/pinball2_43.png")
    gfx.show_mouse_cursor(false)
    fonts={
        big={id=gfx.set_font(LAYER_FONTS,0,0,288,64,12,32," ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890,"),h=32},
        smol={id=gfx.set_font(LAYER_FONTS,0,64,384,32,12,16,"ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"),h=16},
        huge={id=gfx.set_font(LAYER_FONTS,0,96,384,32,16,32,"1234567890X"),h=32},
        medium={id=gfx.set_font(LAYER_FONTS,0,128,384,15,16,15,"1234567890"),h=15}
    }
    modes={
        title={
            init=init_title,
            update=update_title,
            render=render_title,
            cam_spd=1,
            layout_w=0,
            layout_h=0,
            scroller=0,
            blink=0,
        },
        ready={
            init=init_ready,
            update=update_ready,
            render=render_game,
            credits=1,
        },
        game={
            init=init_game,
            update=update_game,
            render=render_game,
            credits=1,
        },
        debug_phys={
            init=init_dbgphys,
            update=update_dbgphys,
            render=render_dbgphys
        }
    }
    scores={
        {name="AAA",score=600000},
        {name="BBB",score=500000},
        {name="CCC",score=400000},
        {name="DDD",score=300000},
        {name="EEE",score=200000},
        {name="FFF",score=100000},
    }
    mode=modes.title
    cam=0
    t=0
    mode.init()
end

function update()
    t=t+1/60
    local step=false
    if inp.key_pressed(inp.KEY_ESCAPE) then
        pause=not pause
    elseif inp.key_pressed(inp.KEY_END) then
        step=true
    elseif inp.key_pressed(inp.KEY_F1) then
        if mode==modes.debug_phys then
            mode=modes.ready
        else
            mode=modes.debug_phys
            mode.blink=0
            mode.init()
        end
    end
    if not pause or step then
        local old_mode=mode
        mode.update()
        if mode ~= old_mode then
            t=0
            mode.blink=0
            mode.init()
        end
    end
end

function render()
    mode.render()
end