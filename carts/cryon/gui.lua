-- ################################## GUI ##################################
local const=require("www.carts.cryon.constants")
local M={}

local function render_label(lab)
    if lab.align == const.ALIGN_CENTER then
        gprint_center(lab.msg, lab.x + 1, lab.y + 1, 3)
        gprint_center(lab.msg, lab.x, lab.y, lab.col)
    elseif lab.align == const.ALIGN_RIGHT then
        gprint_right(lab.msg, lab.x + 1, lab.y + 1, 3)
        gprint_right(lab.msg, lab.x, lab.y, lab.col)
    else
        gprint(lab.msg, lab.x + 1, lab.y + 1, 3)
        gprint(lab.msg, lab.x, lab.y, lab.col)
    end
end

local function render_bkgnd(x, y, len, len2, col)
    gfx.blit(6, 36, 6, 18, x - 6, y - 6, 0, 0, false, false, col, col, col)
    gfx.blit(12, 36, 6, 18, x, y - 6, len, 0, false, false, col, col, col)
    if len2 > 0 then
        gfx.blit(24, 36, 6, 18, x + len, y - 6, 0, 0, false, false, col, col, col)
        if len2 > 6 then
            gfx.blit(30, 36, 6, 18, x + len + 6, y - 6, 0, 0, false, false, col, col, col)
        end
    end
    gfx.blit(18, 36, 6, 18, round(x + len + len2), y - 6, 0, 0, false, false, col, col, col)
end

function M.gen_label(msg, x, y, col, align)
    return {
        typ= const.E_LABEL,
        msg= msg,
        x= flr(x),
        y= flr(y),
        col= col,
        align= align,
        render= render_label,
        update= no_update,
    }
end

local function render_button(this)
    local tx=compute_x(this.x, #this.msg * 6, this.align)
    local bx=compute_x(this.x, const.BUTTON_WIDTH, this.align)
    local fcoef = ease_out_cubic(this.focus, 0, 1, 1)
    local col_coef = 0.7 + fcoef * 0.3
    render_bkgnd(bx, this.y, const.BUTTON_WIDTH, fcoef * 10, col_coef)
    local col = PALETTE[6]
    local fcolr = PALETTE[7].r - col.r
    local fcolg = PALETTE[7].g - col.g
    local fcolb = PALETTE[7].b - col.b
    gfx.print(this.msg, tx, this.y, col.r + fcoef * fcolr, col.g + fcoef * fcolg, col.b + fcoef * fcolb)
end

local function update_button(this)
    local tx=compute_x(this.x, const.BUTTON_WIDTH, this.align)
    if inside(g_mouse_x, g_mouse_y, tx - 6, this.y - 6, const.BUTTON_WIDTH+12, 18) then
        if this.focus < 1.0 then
            this.focus = min(1, this.focus + 1/20)
        end
    else
        if this.focus > 0.0 then
            this.focus = max(0, this.focus - 1/10)
        end
    end
end

function M.gen_button(msg, x, y, align)
    return {
        typ= const.E_BUTTON,
        msg= msg,
        x= flr(x),
        y= flr(y),
        align= align,
        focus= 0.0,
        pressed= false,
        col= 5,
        render= render_button,
        update= update_button,
    }
end

return M