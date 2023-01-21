-- ################################## PLANET ##################################
local const=require("www.carts.cryon.constants")
local M={}
local function planet_render(this)
    gfx.set_sprite_layer(const.LAYER_PLANET_TEXTURE)
    local tex_size=this.tex_width
    for _,span in pairs(this.spans) do
        local tx = span.tx + this.rot
        local tlen = span.tlen
        local sx = span.x
        local slen = span.len
        if tx >= tex_size then
            tx = tx - tex_size
        elseif tx + tlen > tex_size then
            local len1 = tex_size -1 - tx
            local slen1 = round(slen * len1 / tlen)
            gfx.blit(tx, span.ty, len1, 1, sx, span.y, slen1, 1, false, false, 1, 1, 1)
            tx = 0
            slen = slen - slen1
            sx = sx + slen1
            tlen = tlen - len1
        end
        gfx.blit(tx, span.ty, tlen, 1, sx, span.y, slen, 1, false, false, 1, 1, 1)
    end
    -- display planet texture
    --gfx.blit(0,0,tex_size,tex_size, gfx.SCREEN_WIDTH-tex_size, gfx.SCREEN_HEIGHT-this.tex_height,0,0,false,false,1,1,1)

    gfx.set_sprite_layer(const.LAYER_SPRITES)
end

local function planet_update(this)
    this.rot = (this.rot + 0.01) % (this.tex_width)
end

local function compute_spans(p)
    local i = 0
    local rad = p.radius
    local starty = round(max(0, p.y - rad))
    local endy = round(min(gfx.SCREEN_HEIGHT - 1, p.y + rad))
    local inv_rad = 1.0 / rad
    local inv_pi = 1.0/const.PI
    local tex_size_x = p.tex_width
    local tex_size_y = p.tex_height
    p.spans={}
    for y=starty,endy do
        local s = (y - p.y) * inv_rad
        local v = clamp(0.5 + asin(s) * inv_pi, 0, 1)
        local square_sin = s * s
        local cos2d = sqrt(1 - square_sin)
        local span_half_len = cos2d * rad
        local startx = round(max(0, p.x - span_half_len))
        local endx = round(min(gfx.SCREEN_WIDTH - 1, startx + 2*span_half_len))
        local start_cos = (p.x - startx) * inv_rad
        local start_z = sqrt(max(0,1 - square_sin - start_cos * start_cos))
        local start_u = atan2(start_z, start_cos) * inv_pi
        local span_start = startx
        for _,x in pairs({0.05, 0.25, 0.75, 0.95, 1.0}) do
            local curx = round(min(endx, x * span_half_len * 2 - span_half_len + p.x))
            if curx > span_start and curx <= endx then
                local end_cos = (p.x - curx) * inv_rad
                local end_z = sqrt(max(0,1 - square_sin - end_cos * end_cos))
                local end_u = atan2(end_z, end_cos) * inv_pi
                local span = {
                    x= span_start,
                    y=y,
                    len= curx - span_start + 1,
                    tx=round(start_u * tex_size_x/2),
                    ty=round(v * tex_size_y),
                    tlen=round(abs(end_u-start_u) * tex_size_x/2),
                }
                table.insert(p.spans,span)
                span_start = curx
                start_u = end_u
                if span_start > endx then
                    break
                end
            end
        end
    end
end

function M.generate(PALETTE)
    local px = random(0, gfx.SCREEN_WIDTH)
    local py = random(0, gfx.SCREEN_HEIGHT)
    local radius = random(gfx.SCREEN_HEIGHT // 3, gfx.SCREEN_HEIGHT // 2)
    local cols={7,6,5,12,11,4}
    local numcol = #cols-1
    local tex_width = min(gfx.SCREEN_WIDTH, flr(const.PI2 * radius))
    local tex_height = min(gfx.SCREEN_HEIGHT, radius*2)
    gfx.set_active_layer(const.LAYER_PLANET_TEXTURE)
    local tex={}
    local mn=1000
    local mx=-1000
    -- generate planet texture
    for y=0,tex_height-1 do
        local a1 = asin(1-y/tex_height*2)
        local yrad = abs(cos(a1))
        local fy = 3 * y / tex_height
        for x=0,tex_width-1 do
            local angle = x * const.PI2 / tex_width
            local fx = fbm3((cos(angle)+1)*yrad, (sin(angle)+1)*yrad, fy)
            table.insert(tex,fx)
            mn=min(fx,mn)
            mx=max(fx,mx)
        end
    end
    local i=1
    local norm_coef=(numcol+1)/(mx-mn)
    -- render texture on layer LAYER_PLANET_TEXTURE
    for y=0,tex_height-1 do
        for x=0,tex_width-1 do
            local coef = clamp((tex[i]-mn)*norm_coef,0,numcol)
            local rcoef = coef - flr(coef)
            local col = rcoef > 0 and clerp(rcoef, cols[flr(coef+1)], cols[flr(coef+2)]) or PALETTE[cols[flr(coef+1)]]
            gfx.rectangle(x, y, 1, 1, col.r, col.g, col.b)
            i=i+1
        end
    end
    local planet = {
        typ= const.E_PLANET,
        x= px,
        y= py,
        radius= radius,
        rot= 0,
        tex_width= tex_width,
        tex_height= tex_height,
    }
    compute_spans(planet)
    gfx.set_active_layer(const.LAYER_BACKGROUND)
    planet.render = planet_render
    planet.update = planet_update
    return planet
end

return M