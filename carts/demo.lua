


pix={}
local LW <const> = 192
local LH <const>  = 112
local LAYER_PIX <const> = 10
local LAYER_FADE2WHITE <const> = 11
fx=3
t=0
remt=0
tick=0
remticks=0
first=true
pause=false
trans=nil
----------------------
-- moire
----------------------
local c1x = LW/2
local c1y = LH/2
local c2x = LW/2
local c2y = LH/2
local COLS= {}
local SLICE <const> = 1600
local COLNUM <const> = 8
----------------------
-- tunnel
----------------------
local BASE_RAD <const> = 25
local CIRCLE_NUM <const> = 60
local tun={}
local curtun=1

function init()
    gfx.set_layer_size(LAYER_PIX,LW,LH)
    gfx.set_sprite_layer(LAYER_PIX)
    gfx.set_layer_operation(LAYER_FADE2WHITE,gfx.LAYEROP_ADD)
    for i=1,COLNUM do
        local rg=math.min(255,i*256/COLNUM)
        local b=math.min(255,20+i*256/COLNUM)
        COLS[i]=gfx.to_rgb24(rg,rg,b)
    end
end

function update_moire()
    if first then
        for p=0,LW*LH-1 do
            pix[p]=COLS[1]
        end
    end
    local p=0
    local c=math.cos(t*1.3)
    local s=math.sin(t*1.3)
    local c2=math.cos((t+1.5)*1.8)
    local s2=math.sin((t+1.5)*1.8)
    c1x = LW/2*(1 + 0.5*c)
    c1y = LH/2*(1 + 0.5*s)
    c2x = LW/2*(1 + 0.5*c2)
    c2y = LH/2*(1 + 0.5*s2)
    local distort = t < 7 and 0 or t < 8 and ease_in_out_cubic(t-7,0,1.0,1) or 1.0
    for y=0,LH-1 do
        local ycoef=(1+math.cos(6*y/LH+t)*distort)
        local dy=(c1y-y)*(c1y-y)*ycoef
        local dy2=(c2y-y)*(c2y-y)
        for x=0,LW-1 do
            local xcoef=(1+math.cos(3*x/LW+2*t)*distort)
            local dx=(c1x-x)*(c1x-x)*xcoef
            local dx2=(c2x-x)*(c2x-x)
            local rgb2 = (dx2 + dy2) % SLICE
            rgb2 = rgb2 < SLICE/2 and 0 or 1
            local rgb1 = (dx + dy + t*3000) % SLICE
            if rgb2 == 1 then
                rgb1=SLICE-rgb1
            end
            local rgb = math.max(1,COLNUM*rgb1/SLICE)
            pix[p]=COLS[math.floor(rgb)]
            p=p+1
        end
    end
    gfx.set_active_layer(LAYER_PIX)
    gfx.blit_pixels(0,0,LW,pix)
    gfx.set_active_layer(0)
end

function fill_pix(r,g,b)
    col=gfx.to_rgb24(r,g,b)
    for p=0,LW*LH-1 do
        pix[p]=col
    end
end

function update_tunnel()
    for j=1,#tun do
        if tun[j] then
            tun[j][3] = tun[j][3] + 1.5
        end
    end
    local coef = t < 8 and t*0.4/8 or 0.4
    local coef2 = t < 10 and t*0.05 or 0.5
    local cx = LW/2 *(1 + coef*math.cos(t*5))
    local cy = LH/2 *(1 + coef2*math.cos(t*3))
    if remticks < CIRCLE_NUM * 2 then
        if #tun > 0 then
            curtun = (curtun % #tun) + 1
            tun[curtun]=nil
        end
    elseif #tun < CIRCLE_NUM then
        table.insert(tun,{cx,cy,BASE_RAD})
        curtun = #tun
    else
        curtun = (curtun % #tun) + 1
        tun[curtun][1]=cx
        tun[curtun][2]=cy
        tun[curtun][3]=BASE_RAD
    end
    fill_pix(0,0,0)
    if #tun > 0 then
        for i=0,50 do
            local angle=i*3.14/25
            local c=math.cos(angle)
            local s=math.sin(angle)
            local index=(curtun % #tun) + 1
            local lastx,lasty=0,0
            for j=1,#tun do
                local cur=tun[index]
                if cur then
                    local cx=cur[1]
                    local r=cur[3]
                    local x=cx+c*r
                    local cy=cur[2]
                    local y=cy+s*r
                    if x >= 0 and x < LW then
                        if y >= 0 and y < LH then
                            local oldrad = (lastx-cx)*(lastx-cx)+(lasty-cy)*(lasty-cy)
                            if r*r < oldrad then
                                pix[math.floor(x)+math.floor(y)*LW] = COLS[index%COLNUM+1]
                            end
                        end
                    end
                    lastx=x
                    lasty=y
                end
                index = (index % #tun) + 1
            end
        end
    end
    gfx.set_active_layer(LAYER_PIX)
    gfx.clear(0,0,1)
    gfx.blit_pixels(0,0,LW,pix)
    gfx.set_active_layer(0)
end

function render_4hits()
    local hit = t*2 % 1
    local rgb = hit < 0.2 and hit * 255 / 0.2 or 1
    gfx.clear(rgb,rgb,rgb)
    for i=0,3 do
        if t*2 < i+1 and t*2 >= i then
            local t0=i+1-t*2
            gfx.rectangle(i*gfx.SCREEN_WIDTH/4,gfx.SCREEN_HEIGHT*(1-t0),gfx.SCREEN_WIDTH/4,gfx.SCREEN_HEIGHT*t0,255,255,255)
        elseif t*2 < i then
            gfx.rectangle(i*gfx.SCREEN_WIDTH/4,0,gfx.SCREEN_WIDTH/4,gfx.SCREEN_HEIGHT,255,255,255)
        end
    end
end

function update_checkerboard()
    local p=1
    local angle1 = t
    local angle2 = t*3
    local angle3 = t*2
    local angle4 = t*1.5
    if t < 6 then
        angle2 = angle1+math.cos(t*50)*0.1
        angle3 = angle1+math.sin(t*40)*0.1
        angle4 = angle1+math.cos((t+5)*60)*0.1
    elseif t > 18 then
        local acc=1+(t-18)/20
        angle1 = t*acc
        angle2 = t*3*acc
        angle3 = t*2*acc
        angle4 = t*1.5*acc
    end
    local zoom = t < 8 and 1 or t < 12 and ease_in_out_cubic(t-8,1,-0.8,4) or t < 16 and ease_in_out_cubic(t-12,0.2,1.8,4) or 1+math.sin(t-16)*0.2
    local c1=math.cos(angle1)
    local s1=math.sin(angle1)
    local c2=math.cos(angle2)
    local s2=math.sin(angle2)
    local c3=math.cos(angle3)
    local s3=math.sin(angle3)
    local c4=math.cos(angle4)
    local s4=math.sin(angle4)
    local hit = t*0.5 % 1
    local rgb = hit < 0.2 and (0.2-hit) * 8 / 0.2 or 0
    for y=0,LH-1 do
        local ly=LH/2-y
        for x=0,LW-1 do
            local lx=LW/2-x
            local rx = zoom*lx * c1 - zoom*ly * s1
            local rx2 = zoom*(lx+10) * c2 - zoom*ly * s2
            local rx3 = zoom*(lx+20) * c3 - zoom*ly * s3
            local rx4 = zoom*(lx+30) * c4 - zoom*ly * s4
            local p1=math.abs(rx//10) < 7 and rx%10 <5 and 1 or 0
            local p2=math.abs(rx2//10) < 7 and rx2%10 < 5 and 1 or 0
            local p3=math.abs(rx3//10) < 7 and rx3%10 < 5 and 1 or 0
            local p4=math.abs(rx4//10) < 7 and rx4%10 < 5 and 1 or 0
            local col = math.min(COLNUM, math.max(1,(p1 + p2 + p3 + p4 )*2+rgb))
            pix[p]=COLS[math.floor(col)]
            p=p+1
        end
    end
    gfx.set_active_layer(LAYER_PIX)
    gfx.blit_pixels(0,0,LW,pix)
    gfx.set_active_layer(0)
end

function render_moire()
    local x = (trans=="panRight" and remt < 1.0) and (1.0-remt)*gfx.SCREEN_WIDTH or 0
    gfx.blit(0,0,LW,LH,x,0,255,255,255,nil,gfx.SCREEN_WIDTH,gfx.SCREEN_HEIGHT)
end

function render_tunnel()
    gfx.blit(0,0,LW,LH,0,0,255,255,255,nil,gfx.SCREEN_WIDTH,gfx.SCREEN_HEIGHT)
end

local UPDATES <const> = {update_tunnel,update_moire,nil,update_checkerboard,nil}
local RENDERS <const> = {render_tunnel,render_moire,render_4hits,render_moire,nil}
local TRANS <const> = {nil,"fade2white",nil,"panRight",nil}
local TIMES <const> = {15,17,2,28,1000}

function update()
    if inp.key_pressed(inp.KEY_SPACE) then
        pause = not pause
    end
    if not pause then
        t=t + 1/60
        tick=tick+1
        if t >= TIMES[fx] then
            t=0
            tick=0
            first=true
            fx=fx+1
            gfx.clear()
            gfx.hide_layer(LAYER_FADE2WHITE)
        end
        remticks=TIMES[fx]*60-tick
        remt = TIMES[fx]-t
        if UPDATES[fx] then
            UPDATES[fx]()
        end
        first=false
    end
end

function render()
    gfx.clear()
    trans=TRANS[fx]
    if RENDERS[fx] then
        RENDERS[fx]()
    end
    if trans and remt < 0.5 then
        if trans == "fade2white" then
            gfx.show_layer(LAYER_FADE2WHITE)
            gfx.set_active_layer(LAYER_FADE2WHITE)
            local rgb=math.min(255,math.floor((0.5-remt)*512))
            gfx.clear(rgb,rgb,rgb)
            gfx.set_active_layer(0)
        end
    end
    gfx.print(gfx.FONT_5X7, string.format("%.2f",t),20,5,1,1,1)
    gfx.print(gfx.FONT_5X7, string.format("%.2f",t),22,7,1,1,1)
    gfx.print(gfx.FONT_5X7, string.format("%.2f",t),21,6,255,255,255)
end