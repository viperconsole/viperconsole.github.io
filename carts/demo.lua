

function v3d_sub(a, b)
	return {a[1] - b[1], a[2] - b[2], a[3] - b[3]}
end

function v3d_add(a, b)
	return {a[1] + b[1], a[2] + b[2], a[3] + b[3]}
end

function v3d_cross(a, b)
	return {a[2] * b[3] - a[3] * b[2], -(a[1] * b[3] - a[3] * b[1]), a[1] * b[2] - a[2] * b[1]}
end

function v3d_dot(a, b)
	return a[1]*b[1]+a[2]*b[2]+a[3]*b[3]
end

function v3d_len2(a)
    return v3d_dot(a,a)
end

function v3d_len(a)
    return math.sqrt(v3d_len2(a))
end

function v3d_norm(a)
    local l=v3d_len(a)
    if l==0 then
        return a
    end
    local invl=1/l
    return {a[1]*invl,a[2]*invl,a[3]*invl}
end

pix={}
local LW <const> = 192
local LH <const>  = 112
local LAYER_ICO1 <const> = 2
local LAYER_ICO2 <const> = 3
local LAYER_ICO3 <const> = 4
local LAYER_ICO4 <const> = 5
local LAYER_PIX <const> = 10
local LAYER_FADE2WHITE <const> = 11
local LAYER_FADE2BLACK <const> = 12
fx=1
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
----------------------
-- checkerboard
----------------------
local bounce=1
local bounce_acc=0
----------------------
-- ico
----------------------
local ico_verts = {}
local ico_tris = {}
local camera_distance = 4
local light_dir = v3d_norm({0.5,-1,-1.5})
local pos1={0,0,0}
local pos2={0,0,0}
local squeeze=1
local squeeze_amount=0
local squeeze_t=0
local acc=0

function init()
    gfx.set_layer_size(LAYER_PIX,LW,LH)
    gfx.set_sprite_layer(LAYER_PIX)
    gfx.set_layer_operation(LAYER_FADE2WHITE,gfx.LAYEROP_ADD)
    gfx.set_layer_operation(LAYER_FADE2BLACK,gfx.LAYEROP_MULTIPLY)
    for layer=LAYER_ICO1,LAYER_ICO4 do
        gfx.set_layer_operation(layer, gfx.LAYEROP_ADD)
        gfx.show_layer(layer)
    end
    gfx.show_mouse_cursor(false)
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

function update_moire2()
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
    gfx.blit(0,0,LW,LH,0,0,255,255*remt/15,255*remt/15,nil,gfx.SCREEN_WIDTH,gfx.SCREEN_HEIGHT)
end

function update_checkerboard()
    if first then
        bounce=1
    end
    if t < 1.8 then
        bounce_acc = bounce_acc +0.002
        bounce = bounce - bounce_acc
        if bounce < 0 then
            bounce=0
            bounce_acc=-0.6 * bounce_acc
            if bounce_acc > -0.003 then
                bounce_acc=0
            end
        end
    end
    local bouncey=math.floor(LH* (1 - bounce*0.3))
    fill_pix(0,0,0)
    for y=bouncey,bouncey+5 do
        for x=0,LW-1 do
            pix[x+y*LW] = COLS[4]
        end
    end
    for y=math.floor(LH*0.7)-1,math.floor(bouncey-1) do
        local ycoef=(y-LH*0.7-1) / (bouncey-1-LH*0.7)
        local xoff = math.floor((1-ycoef)*LW/4)
        local ry=((1-ycoef)*(1-ycoef) * 8) % 2
        local c1=ry <= 1 and 4 or 1
        local c2=ry <= 1 and 1 or 4
        for x = xoff,LW-xoff do
            local rx = ((x-xoff)/(LW-2*xoff)*8) % 2
            local col = rx < 0.95 and c1 or rx > 1.05 and c2 or math.floor(c1+(c2-c1)*(rx-0.95)*10)
            local str=math.abs(rx-ry)
            col=math.min(COLNUM,math.floor(col+(str*10%2)+0.5))
            pix[x+y*LW] = COLS[col]
        end
    end
    gfx.set_active_layer(LAYER_PIX)
    gfx.clear(1,1,1)
    gfx.blit_pixels(0,0,LW,pix)
    gfx.set_active_layer(0)
end


function matrix_rotate_x(a)
	local sa = -math.sin(a * 2 * math.pi)
	local ca = math.cos(a * 2 * math.pi)
	return { { 1, 0, 0 }, { 0, sa, ca }, { 0, ca, -sa } }
end

function matrix_rotate_y(a)
	local sa = -math.sin(a * 2 * math.pi)
	local ca = math.cos(a * 2 * math.pi)
	return { { ca, 0, sa }, { -sa, 0, ca }, { 0, 1, 0 } }
end

function matrix_mul_add_row(m_row, v)
	return m_row[1] * v[1] + m_row[2] * v[2] + m_row[3] * v[3]
end

function matrix_mul_add(m, v)
	return {matrix_mul_add_row(m[1], v), matrix_mul_add_row(m[2], v), matrix_mul_add_row(m[3], v)}
end

function translate_to_view(v,pos,squeezex,squeezey,mx,my)
    local t = matrix_mul_add(mx, matrix_mul_add(my, v))
    t[1] = t[1] * squeezex
    t[2] = t[2] * squeezey
	local t = v3d_add(pos, t)
	t[3] = t[3] + 252; -- camera fov
	return {
		math.floor(t[3] / camera_distance * t[1] + gfx.SCREEN_WIDTH/2 + 0.5),
		math.floor(t[3] / camera_distance * t[2] + gfx.SCREEN_HEIGHT/2 + 0.5),
		t[3],t[1],t[2]}
end

local function compare_tri(t1,t2)
    return t1[7]>t2[7]
end

function render_mesh(verts,tris,pos,squeezex,squeezey,rx,ry,altcol)
    local mx=matrix_rotate_x(rx)
    local my=matrix_rotate_y(ry)
    local tverts={}
    for i=1,#verts do
        tverts[i]=translate_to_view(verts[i],pos,squeezex,squeezey,mx,my)
    end
    for i=1,#tris do
        local t=tris[i]
        local p1=tverts[t[1]]
        local p2=tverts[t[2]]
        local p3=tverts[t[3]]
        t[7]=(p1[3]+p2[3]+p3[3])/3
    end
    table.sort(tris, compare_tri)
    for i=1,#tris do
        local t=tris[i]
        local a=tverts[t[1]]
        local b=tverts[t[2]]
        local c=tverts[t[3]]
        local ab=v3d_sub({b[4],b[5],b[3]},{a[4],a[5],a[3]})
        local ac=v3d_sub({c[4],c[5],c[3]},{a[4],a[5],a[3]})
        local n=v3d_norm(v3d_cross(ab,ac))
        local diffuse = math.max(0.2,v3d_dot(n,light_dir))
        local half = v3d_norm(v3d_add(v3d_norm(a),light_dir))
        local specular = math.max(0,v3d_dot(n,half)) ^ 8
        if altcol then
            gfx.set_active_layer(n[3] > 0 and LAYER_ICO2 or LAYER_ICO1)
            gfx.triangle(a[1],a[2],b[1],b[2],c[1],c[2],(128+127*t[4]/255)*diffuse,0,0)
        else
            gfx.set_active_layer(n[3] > 0 and LAYER_ICO3 or LAYER_ICO4)
            gfx.triangle(a[1],a[2],b[1],b[2],c[1],c[2],t[4]*diffuse+specular*64,t[5]*diffuse+specular*64,t[6]*diffuse+specular*64)
        end
    end
end

function update_ico()
    if first then
        for layer=LAYER_ICO1,LAYER_ICO4 do
            gfx.show_layer(layer)
        end
        ico_verts={
            {-0.5,-0.5,-0.5},
            {0.5,-0.5,-0.5},
            {-0.5,0.5,-0.5},
            {0.5,0.5,-0.5},
            {-0.5,-0.5,0.5},
            {0.5,-0.5,0.5},
            {-0.5,0.5,0.5},
            {0.5,0.5,0.5},
            {0,0,-0.8},
            {0,0,0.8},
            {0,-0.8,0},
            {0,0.8,0},
            {-0.8,0,0},
            {0.8,0,0}
        }
        ico_tris= {
            {1,9,2, 0,0,255},
            {2,9,4, 255,255,255},
            {4,9,3, 0,0,255},
            {3,9,1, 255,255,255},
            {6,10,5, 0,0,255},
            {8,10,6, 255,255,255},
            {7,10,8, 0,0,255},
            {5,10,7, 255,255,255},
            {2,11,1, 255,255,255},
            {6,11,2, 0,0,255},
            {5,11,6, 255,255,255},
            {1,11,5, 0,0,255},
            {3,12,4, 255,255,255},
            {4,12,8, 0,0,255},
            {8,12,7, 255,255,255},
            {7,12,3, 0,0,255},
            {1,13,3, 0,0,255},
            {3,13,7, 255,255,255},
            {7,13,5, 0,0,255},
            {5,13,1, 255,255,255},
            {4,14,2, 0,0,255},
            {8,14,4, 255,255,255},
            {6,14,8, 0,0,255},
            {2,14,6, 255,255,255},
        }
        pos1[2]=-3
    end
    if t < 10 then
        acc=acc+0.001
        pos1[2] = pos1[2]+acc
        if pos1[2] > 0.85 then
            acc=-0.07
            pos1[2]=0.85
            squeeze_amount=0.5
            squeeze_t=t
        end
        squeeze_amount = math.max(0,squeeze_amount-0.01)
        squeeze = 1 - squeeze_amount * math.cos((t-squeeze_t)*15)
    else
        pos1[1] = pos1[1] + (math.sin(t*3) - pos1[1]) * 0.02
        pos1[2] = pos1[2] + (math.cos(t*2) - pos1[2]) * 0.02
        local pos2c = remt > 10 and 0 or (10-remt)*0.1
        pos2[1] = pos2[1] + (math.sin((t-10)*1.5) - pos2[1]) * 0.03 * pos2c
        pos2[2] = pos2[2] + (math.cos((t-10)*2.5) - pos2[2]) * 0.03 * pos2c
        squeeze = squeeze + (1-squeeze) * 0.01
        if remt < 10 then
            local zc = math.min(1,(10-remt)/7)
            pos1[3] = pos1[3] + (200*math.cos(t*4) - pos1[3]) * 0.03 * zc
            pos2[3] = pos2[3] + (200*math.cos((t-17)*4) - pos2[3]) * 0.03 * zc
        end
    end
end

function render_ico()
    local rgb=t < 10 and 255 or t < 11 and (11-t)*255 or 0
    gfx.set_active_layer(0)
    if rgb > 0 then
        gfx.blit(0,0,LW,LH,0,0,rgb,rgb,rgb,nil,gfx.SCREEN_WIDTH,gfx.SCREEN_HEIGHT)
    else
        gfx.clear()
    end
    for layer=LAYER_ICO1,LAYER_ICO4 do
        gfx.set_active_layer(layer)
        gfx.clear(0,0,0)
    end
    if #ico_tris > 0 then
        render_mesh(ico_verts,ico_tris,pos1,1,squeeze,t*0.05, -t*0.5, false)
        if t > 10 then
            zoom= t < 11 and (t-10)*2 or 2
            render_mesh(ico_verts,ico_tris,pos2,zoom,zoom,t*0.1, t*0.3, true)
        end
    end
end

local UPDATES <const> = {update_checkerboard,update_ico,update_tunnel,update_moire,nil,update_moire2,nil}
local RENDERS <const> = {render_moire, render_ico, render_tunnel,render_moire,render_4hits,render_moire,nil}
local TRANS <const> = {nil,"fade2black",nil,"fade2white",nil,"panRight",nil}
local TIMES <const> = {3,27,15,17,2,28,1000}

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
            gfx.hide_layer(LAYER_FADE2BLACK)
            for layer=LAYER_ICO1,LAYER_ICO4 do
                gfx.set_active_layer(layer)
                gfx.clear(0,0,0)
                gfx.hide_layer(layer)
            end
            gfx.set_active_layer(0)
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
    if trans and remt < 1 then
        if trans == "fade2white" then
            gfx.show_layer(LAYER_FADE2WHITE)
            gfx.set_active_layer(LAYER_FADE2WHITE)
            local rgb=math.min(255,math.floor((1-remt)*255))
            gfx.clear(rgb,rgb,rgb)
            gfx.set_active_layer(0)
        elseif trans == "fade2black" then
            gfx.show_layer(LAYER_FADE2BLACK)
            gfx.set_active_layer(LAYER_FADE2BLACK)
            local rgb=math.max(1,math.floor(remt*255))
            gfx.clear(rgb,rgb,rgb)
            gfx.set_active_layer(0)
        end
    end
    local fps=gfx.fps()
    gfx.print(gfx.FONT_5X7, string.format("%3.2f %d fps",t,fps),20,5,1,1,1)
    gfx.print(gfx.FONT_5X7, string.format("%3.2f %d fps",t,fps),22,7,1,1,1)
    gfx.print(gfx.FONT_5X7, string.format("%3.2f %d fps",t,fps),21,6,255,255,255)
end