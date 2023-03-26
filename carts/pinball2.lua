local LAYER_FONTS <const> = 1
local LAYER_PINBALL_L1 <const> = 2
local FONT_ZONE_H <const> = 32
local BALL_FRICTION <const> = 0.995
local BALL_GRAVITY <const> = 0.3

function v2d(x,y)
    return {x=x,y=y}
end
function v2d_clone(v)
    return {x=v.x,y=v.y}
end
function v2d_scale(v,f)
    v.x = v.x*f
    v.y = v.y*f
end
function v2d_len(v)
    local l=v.x*v.x+v.y*v.y
    return math.sqrt(l)
end
function clamp(v,min,max)
    return v < min and min or v > max and max or v
end

function inp_lflip_pressed()
    return inp.action1_pressed() or inp.pad_button_pressed(1,inp.XBOX360_LB)
end

function inp_rflip_pressed()
    return inp.action2_pressed() or inp.pad_button_pressed(1,inp.XBOX360_RB)
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
        ready_ball=nil
    }
    table.spring_col=add_collider(275,446-38,281,446-38)
    add_ball(279,446-38-6)
end
function update_pinball()
    local lowest_ball=nil
    for i=1,#pinball.balls do
        local b=pinball.balls[i]
        update_ball(b)
        if lowest_ball == nil or b.pos.y > lowest_ball.pos.y then
            lowest_ball = b
        end
    end
    local spring_spd=0
    if inp.key(inp.KEY_DOWN) or inp.pad_button(1,inp.XBOX360_A) then
        local old_spring=pinball.spring
        pinball.spring = math.min(22,pinball.spring+0.5)
    elseif pinball.spring > 0 then
        spring_spd = pinball.spring
        pinball.spring=0
    end
    local spring_y=446-38 + pinball.spring
    table.spring_col.y1=spring_y
    table.spring_col.y2=spring_y
    if pinball.ready_ball then
        local b=pinball.ready_ball
        if b.pos.y > spring_y-6 then
            local old_pos=b.pos.y
            b.pos.y = spring_y-6
            b.spd.y=-b.spd.y * 0.4
            if spring_spd > 0 then
                b.spd.y = -spring_spd
            end
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
    render_lflipper()
    render_rflipper()
    render_spring(pinball.spring)
    for i=1,#pinball.balls do
        render_ball(pinball.balls[i])
    end
end

flipper_sprites={
    {x=0,y=143,w=40,h=27},
    {x=40,y=143,w=43,h=19},
    {x=83,y=143,w=44,h=12},
}
function render_lflipper()
    local spr=1 -- TODO
    local s=flipper_sprites[spr]
    local y=419-cam-8
    if y < gfx.SCREEN_HEIGHT then
        gfx.blit(s.x,s.y,s.w,s.h,82-8,y,nil,nil,nil,nil,nil,nil,false,false)
    end
end
function render_rflipper()
    local spr=1 -- TODO
    local s=flipper_sprites[spr]
    local y=419-cam-8
    if y < gfx.SCREEN_HEIGHT then
        gfx.blit(s.x,s.y,s.w,s.h,187-s.w,y,nil,nil,nil,nil,nil,nil,true,false)
    end
end
function render_spring(pos)
    local y=446-38-cam+pos
    if y < gfx.SCREEN_HEIGHT then
        gfx.blit(115,160,6,38,276,y)
        local s=pos*5//22
        gfx.blit(121+s*8,168+s*4,8,30-s*4,275,y+8,nil,nil,nil,nil,nil,30-pos)
        gfx.set_sprite_layer(LAYER_PINBALL_L1)
        gfx.blit(275,452-8,8,8,275,452-8-cam)
        gfx.set_sprite_layer(LAYER_FONTS)
    end
end
function render_ball(b)
    local y=b.pos.y-6-cam
    if y < gfx.SCREEN_HEIGHT and y > -12 then
        gfx.blit(0,170,12,12,b.pos.x-6,y)
    end
end

function add_collider(x1,y1,x2,y2)
    local col={x1=x1,y1=y1,x2=x2,y2=y2}
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
    b.old_pos.x=b.pos.x
    b.old_pos.y=b.pos.y
    b.pos.x = b.pos.x + b.spd.x
    b.pos.y = b.pos.y + b.spd.y
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