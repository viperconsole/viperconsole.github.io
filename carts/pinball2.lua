local LAYER_FONTS <const> = 1
local LAYER_PINBALL_L1 <const> = 2
local FONT_ZONE_H <const> = 32
local TABLE_HEIGHT <const> = 452
local BALL_FRICTION <const> = 0.992
local BALL_GRAVITY <const> = 0.2
local BALL_RADIUS <const> = 6
local SPRING_BOUNCE <const> = 0.8
local SPRING_LENGTH <const> = 38
local SPRING_POS <const> = 408
local WALL_BOUNCE <const> = 0.8
local FLIPPER_BOUNCE <const> = 0.9
local FLIPPER_ANGLE_SPEED <const> = 0.07 * math.pi * 2
local FLIPPER_MAX_ANGLE <const> = 0.16 * math.pi * 2
local FLIPPER_ANGLE_FIX <const> = 0.035 * math.pi * 2
local BUMPER_BOUNCE <const> = 1.5
debug_colliders=true

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
    if inp_lflip_pressed() or inp_rflip_pressed() or inp.pad_button_pressed(1,inp.XBOX360_START) then
        mode=modes.ready
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
    if cam < MAX_CAM then
        cam = cam+(MAX_CAM-cam)*0.1
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

function render_ready()
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
    pinball.spring_col=add_wall_collider(285,SPRING_POS,272,SPRING_POS,SPRING_BOUNCE)
    add_ball(279,SPRING_POS-BALL_RADIUS)
    local walls={{ -- outer wall
        84,451,0,405,0,302,4,294,13,286,16,279,16,212,19,202,28,191,30,187,28,192,17,164,
        2,99,2,52,9,35,20,22,35,11,51,4,66,2,181,2,234,4,246,7,257,12,266,19,274,29,279,43,281,59,283,78,284,103
    },{ -- outer wall, bottom right part
        268,95,241,195,241,201,255,214,255,219,249,226,249,232,258,262,259,272,253,281,
        248,286,250,294,267,307,269,312,269,400,265,406,184,451
    },{ -- right gutter
        185,418,240,388,250,376,251,323
    },{ --  left gutter
        18,323,18,374,21,382,80,418
    }, { -- left bumper
        {x=65,bounce=BUMPER_BOUNCE},375,46,322,42,320,38,322,36,363,40,369,63,382,66,382,65,375
    }, { -- right bumper
        {x=223,bounce=BUMPER_BOUNCE},322,201,377,203,381,208,383,231,368,233,364,233,324,230,320,225,319,223,322
    }}
    for i=1,#walls do
        local w=walls[i]
        for j=0,#w/2-2 do
            local p=j*2+1
            if type(w[p]) == "table" then
                add_wall_collider(w[p].x,w[p+1],w[p+2],w[p+3],WALL_BOUNCE,w[p].bounce)
            else
                add_wall_collider(w[p],w[p+1],w[p+2],w[p+3],WALL_BOUNCE,0)
            end
        end
    end
    pinball.lflipper=add_collider({v2d(7,0),v2d(40,23),v2d(39,26),v2d(35,26),v2d(1,10),v2d(0,4),v2d(7,0)},FLIPPER_BOUNCE,0,collide_flipper)
    pinball.rflipper=add_collider({v2d(7,0),v2d(40,23),v2d(39,26),v2d(35,26),v2d(1,10),v2d(0,4),v2d(7,0)},FLIPPER_BOUNCE,0,collide_flipper)
    pinball.lflipper.base_collider={}
    pinball.rflipper.base_collider={}
    for i=1,#pinball.lflipper do
        table.insert(pinball.lflipper.base_collider,v2d_clone(pinball.lflipper[i]))
        table.insert(pinball.rflipper.base_collider,v2d_clone(pinball.rflipper[i]))
    end
    pinball.lflipper.pos=v2d(82,425)
    pinball.lflipper.origin=v2d(6,6)
    pinball.lflipper.angle=0
    pinball.rflipper.pos=v2d(187,425)
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
    if pinball.ready_ball and spring_spd > 0 then
        local b=pinball.ready_ball
        if b.pos.y >= spring_y-BALL_RADIUS then
            b.pos.y = spring_y-BALL_RADIUS
            b.spd.y = -spring_spd
        end
    end
    update_flipper(pinball.lflipper,inp_lflip)
    update_flipper(pinball.rflipper,inp_rflip)
    local lowest_ball=nil
    for i=1,#pinball.balls do
        local b=pinball.balls[i]
        update_ball(b)
        if b.pos.y > TABLE_HEIGHT + BALL_RADIUS then
            b.pos.x=279
            b.pos.y=SPRING_POS-BALL_RADIUS
            b.spd.x=0
            b.spd.y=0
        end
        if lowest_ball == nil or b.pos.y > lowest_ball.pos.y then
            lowest_ball = b
        end
    end
    local target=lowest_ball.pos.y-gfx.SCREEN_HEIGHT/2
    local cam_target=MAX_CAM * clamp(target/MAX_CAM,0,1)
    cam = cam + (cam_target-cam)*0.5
end
function render_pinball()
    gfx.set_sprite_layer(LAYER_PINBALL_L1)
    gfx.blit(0,cam,gfx.SCREEN_WIDTH-96,gfx.SCREEN_HEIGHT,0,0)
    gfx.set_sprite_layer(LAYER_FONTS)
    render_flipper(pinball.lflipper)
    render_flipper(pinball.rflipper)
    render_spring(pinball.spring)
    for i=1,#pinball.balls do
        render_ball(pinball.balls[i])
    end
    gfx.set_sprite_layer(LAYER_PINBALL_L1)
    gfx.blit(288,446,15,6,272,443-cam)
    gfx.blit(288,371,14,75,272,49-cam)
    gfx.set_sprite_layer(LAYER_FONTS)
    if debug_colliders then
        for i=1,#pinball.colliders do
            local c=pinball.colliders[i]
            for i=2,#c do
                local p1=world_pos(c,i-1)
                local p2=world_pos(c,i)
                gfx.line(p1.x,p1.y-cam,p2.x,p2.y-cam,255,0,0)
            end
        end
    end
end

function update_flipper(flipper,inp_fn)
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
end
flipper_sprites={
    {x=0,y=143,w=40,h=27},
    {x=40,y=143,w=43,h=19},
    {x=83,y=143,w=44,h=12},
    {x=40,y=143,w=43,h=19},
    {x=0,y=143,w=40,h=27},
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
        gfx.blit(115,160,6,SPRING_LENGTH,276,y)
        local s=pos*5//22
        gfx.blit(121+s*8,168+s*4,8,30-s*4,275,y+8,nil,nil,nil,nil,nil,30-pos)
        gfx.set_sprite_layer(LAYER_PINBALL_L1)
        gfx.blit(275,TABLE_HEIGHT-8,8,8,275,TABLE_HEIGHT-8-cam)
        gfx.set_sprite_layer(LAYER_FONTS)
    end
end
function render_ball(b)
    local y=b.pos.y-BALL_RADIUS-cam
    if y < gfx.SCREEN_HEIGHT and y > -12 then
        gfx.blit(0,170,12,12,b.pos.x-BALL_RADIUS,y)
    end
end

function add_wall_collider(x1,y1,x2,y2,bounce_coef, bounce)
    return add_collider({v2d(x1,y1),v2d(x2,y2)},bounce_coef,bounce,collide_polygon)
end
function add_collider(points,bounce_coef, bounce, collide_fn)
    local col=points
    col.collide=collide_fn
    col.bounce_coef=bounce_coef
    col.bounce = bounce or 0
    table.insert(pinball.colliders,col)
    return col
end
function add_ball(x,y)
    local pos=v2d(x,y)
    table.insert(pinball.balls,{pos=pos,old_pos=v2d_clone(pos),spd=v2d(0,0),spd_mag=0})
    if #pinball.balls == 1 then
        pinball.ready_ball=pinball.balls[1]
    end
end
function update_ball(b)
    v2d_scale(b.spd, BALL_FRICTION)
    b.spd.y = b.spd.y + BALL_GRAVITY
    b.spd_mag=v2d_len(b.spd)
    local spd=math.min(4,b.spd_mag)
    local rem_spd=b.spd_mag
    while spd > 0 do
        b.old_pos.x=b.pos.x
        b.old_pos.y=b.pos.y
        b.pos.x = b.pos.x + b.spd.x*spd/b.spd_mag
        b.pos.y = b.pos.y + b.spd.y*spd/b.spd_mag
        rem_spd = rem_spd - spd
        spd=math.min(4,rem_spd)
        for i=1,#pinball.colliders do
            local c=pinball.colliders[i]
            local wall,inter,spd=c.collide(b,c)
            if wall then
                -- fix ball position
                local wall_line=v2d_sub(wall[2],wall[1])
                local n=v2d_perpendicular(v2d_norm(wall_line))
                b.pos.x=inter.x+n.x * (BALL_RADIUS-1)
                b.pos.y=inter.y+n.y * (BALL_RADIUS-1)
                -- bounce
                if spd then
                    b.spd=v2d_add(b.spd,spd)
                    --print("FLIPPER COLL "..b.spd.x.." "..b.spd.y)
                else
                    local sn=v2d_clone(n)
                    v2d_scale(sn, 2*c.bounce_coef*v2d_dot(b.spd,n))
                    local new_spd=v2d_sub(b.spd,sn)
                    if c.bounce > 0 then
                        v2d_scale(n,c.bounce)
                        new_spd=v2d_add(new_spd,n)
                    end
                    print(string.format("WALL COLL n %.0f %.0f sn %.0f %.0f spd %.0f,%.0f -> %.0f,%.0f",n.x,n.y,sn.x,sn.y,b.spd.x,b.spd.y,new_spd.x,new_spd.y))
                    print(string.format(">ball pos %.0f %.0f",b.pos.x,b.pos.y))
                    b.spd=new_spd
                end
                return
            end
        end
    end
    print(string.format("ball pos %.0f %.0f spd %.0f %.0f",b.pos.x,b.pos.y,b.spd.x,b.spd.y))
end
function collide_flipper(ball,flipper_col)
    if flipper_col.moving == 0 or flipper_col.cooldown then
        return collide_polygon(ball,flipper_col)
    end
    for i=2,#flipper_col do
        local p1=world_pos(flipper_col,i-1)
        local p2=world_pos(flipper_col,i)
        local wall,inter=collide_sphere(ball,p1,p2)
        if wall then
            local spd_mag = 0.1 * flipper_col.moving * v2d_len(v2d_sub(flipper_col.origin, ball.pos)) * math.sin(FLIPPER_ANGLE_SPEED)
            local real_angle=flipper_col.angle - FLIPPER_ANGLE_FIX - FLIPPER_MAX_ANGLE/2
            local spd_vec = v2d(
                (flipper_col.hflip and spd_mag or -spd_mag) * math.sin(real_angle),
                -spd_mag * math.cos(real_angle))
            flipper_col.cooldown=4
            return wall,inter,spd_vec
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
        local inter=collide_line(ball.old_pos, ballp2, p1, p2)
        if inter then
            return {p1,p2},inter
        end
        return collide_sphere(ball,p1,p2)
    end
end
function world_pos(poly, i)
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
    local closest = closest_point_to_sphere(ball.pos,p1,p2)
    local dist2 = v2d_len2(v2d_sub(closest,ball.pos))
    if dist2 <= BALL_RADIUS*BALL_RADIUS then
        print(string.format("%.0f %.0f sphere collides with %.0f %.0f - %.0f %.0f at %.0f %.0f",
            ball.pos.x,ball.pos.y,
            p1.x,p1.y,p2.x,p2.y,
            closest.x,closest.y
        ))
        return {p1, p2},closest
    end
end
function closest_point_to_sphere(sph,p1,p2)
    local l = v2d_sub(p1,sph)
    local wall=v2d_sub(p2,p1)
    local len2=v2d_len2(wall)
    local nwall=v2d_norm(wall)
    local dot = v2d_dot(l,nwall)
    v2d_scale(nwall,dot)
    return dot < 0 and p1 or dot > len2 and p2 or v2d_add(p1,nwall)
end
function calc_inf_line_abc(p1, p2)
    local a = p2.y - p1.y
    local b = p1.x - p2.x
    local c = (p2.x * p1.y) - (p1.x * p2.y)
    return a, b, c
end
function collide_line(p1,p2,q1,q2)
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
    print(string.format("%.0f %.0f - %.0f %.0f collides with %.0f %.0f - %.0f %.0f at %.0f %.0f",
        p1.x,p1.y,p2.x,p2.y,
        q1.x,q1.y,q2.x,q2.y,
        inter.x,inter.y
    ))
    return inter
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
            render=render_ready,
            credits=1,
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
    local old_mode=mode
    mode.update()
    if mode ~= old_mode then
        mode.blink=0
        mode.init()
    end
end

function render()
    mode.render()
end