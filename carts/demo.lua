


pix={}
local LW <const> = 192
local LH <const>  = 112
local LAYER_PIX <const> = 10
local LAYER_FADE2WHITE <const> = 11
fx=1
t=0
remt=0
tick=0
remticks=0
first=true
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
local CIRCLE_NUM <const> = 50
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

function update_fx_moire()
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

function darken_screen(zoom)
    gfx.set_active_layer(2)
    gfx.set_sprite_layer(0)
    gfx.blit(0,0,gfx.SCREEN_WIDTH,gfx.SCREEN_HEIGHT,-zoom,-zoom,240,240,250,nil,gfx.SCREEN_WIDTH+zoom*2,gfx.SCREEN_HEIGHT+zoom*2)
    gfx.set_active_layer(0)
    gfx.set_sprite_layer(2)
    gfx.blit(0,0,gfx.SCREEN_WIDTH,gfx.SCREEN_HEIGHT,0,0)
    gfx.set_sprite_layer(LAYER_PIX)
end

function update_fx_tunnel()
    for j=1,#tun do
        if tun[j] then
            tun[j][3] = tun[j][3] + 1.5
        end
    end
    local coef = t < 5 and ease_in_out_cubic(t,0.1,0.4,5) or 0.5
    local coef2 = t < 10 and ease_in_out_cubic(t,0.1,0.4,10) or 0.5
    local cx = LW/2 *(1 + coef*math.cos(t*5))
    local cy = LH/2 *(1 + coef2*math.cos(t*3))
    if #tun < CIRCLE_NUM then
        table.insert(tun,{cx,cy,BASE_RAD})
        curtun = #tun
    elseif remticks > CIRCLE_NUM then
        curtun = (curtun % #tun) + 1
        tun[curtun][1]=cx
        tun[curtun][2]=cy
        tun[curtun][3]=BASE_RAD
    else
        curtun = (curtun % #tun) + 1
        tun[curtun]=nil
    end
    fill_pix(0,0,0)
    for i=0,50 do
        local angle=i*3.14/25
        local c=math.cos(angle)
        local s=math.sin(angle)
        local index=curtun
        for j=1,#tun do
            local cur=tun[index]
            if cur then
                local cx=cur[1]
                local r=cur[3]
                local x=cx+c*r
                if x >= 0 and x < LW then
                    local cy=cur[2]
                    local y=cy+s*r
                    if y >= 0 and y < LH then
                        pix[math.floor(x)+math.floor(y)*LW] = COLS[index%COLNUM+1]
                    end
                end
            end
            index = (index % #tun) + 1
        end
    end
    gfx.set_active_layer(LAYER_PIX)
    gfx.clear(0,0,1)
    gfx.blit_pixels(0,0,LW,pix)
    gfx.set_active_layer(0)
end

function render_fx_moire()
    gfx.blit(0,0,LW,LH,0,0,255,255,255,nil,gfx.SCREEN_WIDTH,gfx.SCREEN_HEIGHT)
end

function render_fx_tunnel()
    gfx.blit(0,0,LW,LH,0,0,255,255,255,nil,gfx.SCREEN_WIDTH,gfx.SCREEN_HEIGHT)
end

local UPDATES <const> = {update_fx_tunnel,update_fx_moire,nil}
local RENDERS <const> = {render_fx_tunnel,render_fx_moire,nil}
local TRANS <const> = {nil,"fade2white",nil}
local TIMES <const> = {15,17,1000}

function update()
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

function render()
    gfx.clear()
    if RENDERS[fx] then
        RENDERS[fx]()
    end
    local trans=TRANS[fx]
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