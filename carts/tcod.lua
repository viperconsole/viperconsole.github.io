LAYER_SHADOW=1
LAYER_ENTITIES=2
LAYER_SPRITE=7
LAYER_GROUND_SPRITE=6
SPRITESHEET_SIZE=512
GROUND_TILE_SIZE=32

BUTTON_JUMP = 0
BUTTON_HIT = 2
MOUSE_HIT = 0

ANIM_IDLE = 1
ANIM_WALK = 2
ANIM_JUMP = 3
ANIM_HIT = 4

SHEET_WARRIOR = 1
SHEET_GRASS = 2
SHEET_VEGETATION = 3

sheets = {{
        -- WARRIOR
        x=64,
        y=0,
        w=47,
        h=47,
        cols=4,
    }, {
        -- GRASS
        x=0,
        y=0,
        w=GROUND_TILE_SIZE,
        h=GROUND_TILE_SIZE,
        cols=2,
    }, {
        -- VEGETATION
        x= 0,
        y= 288,
        w= GROUND_TILE_SIZE,
        h= GROUND_TILE_SIZE,
        cols= 2,
}}

anims = {{
        -- IDLE
        frames= {0,1,2,3},
        speed= 0.1,
        interruptible= true,
    }, {
        -- WALK
        frames= {12,13,14,15},
        speed= 0.15,
        interruptible= true,
    }, {
        -- JUMP
        frames= {20, 21, 22, 23, 24, 25, 26, 27},
        speed= 0.2,
        interruptible= false,
    }, {
        -- HIT
        frames= {16, 17, 18, 19},
        speed= 0.2,
        interruptible= false,
    }
}

map = {
    tiles={
        0,0,0,2,1,0,0,1,0,2,0,0,
        0,2,0,0,0,0,0,2,0,0,0,0,
        0,0,1,0,0,2,0,0,2,0,1,0,
        2,0,0,0,0,0,1,0,0,0,0,0,
        0,0,0,2,0,0,0,0,0,2,0,0,
        0,0,1,0,0,2,0,0,1,0,0,0,
        0,0,0,0,2,0,1,0,0,0,2,0,
    },
}

function render_sprite(sheet_id, frame, x, y, hflip, vflip, r, g, b)
    local sheet = sheets[sheet_id]
    local fx = frame % sheet.cols
    local fy = frame // sheet.cols
    local sw = sheet.w
    local sh = sheet.h
    local sx = sheet.x + fx * sw
    local sy = sheet.y + fy * sh
    gfx.blit(sx, sy, sw, sh,
        math.floor(x-sw / 2), y-sh,
        0, 0, hflip, vflip, r, g, b)
end

function render_object(this)
    local x = math.floor(this.x + gfx.SCREEN_WIDTH / 2)
    local y = math.floor(this.y + gfx.SCREEN_HEIGHT / 2)
    render_sprite(this.sheet, this.frame, x, y, this.flip, false, 1, 1, 1)
end

function render_character(this)
    local anim = anims[this.anim]
    local frame = anim.frames[math.floor(this.anim_frame) + 1]
    local x = math.floor(this.x + gfx.SCREEN_WIDTH / 2)
    local y = math.floor(this.y + gfx.SCREEN_HEIGHT / 2)
    render_sprite(this.sheet, frame, x, y, this.flip, false, 1, 1, 1)
end

function render_shadow(character)
    local x = math.floor(character.x + gfx.SCREEN_WIDTH / 2)
    local y = math.floor(character.y + gfx.SCREEN_HEIGHT / 2)
    gfx.blit(64, 502, 32, 10,
        x-18, y-8,
        0, 0, character.flip, false, 0.5, 0.5, 0.5)
end

function render_map(m, mx, my)
    mx = mx + GROUND_TILE_SIZE/2
    my = my + GROUND_TILE_SIZE
    for x=0,11 do
        local dx=x * GROUND_TILE_SIZE
        for y=0,6 do
            local dy = y * GROUND_TILE_SIZE
            local tile=m.tiles[x+y*10 + 1]
            render_sprite(SHEET_GRASS, tile, mx+dx, my+dy, false, false, 1,1,1)
        end
    end
end

function set_anim(creature, anim)
    if creature.anim ~= anim then
        creature.anim_frame = 0
        creature.anim = anim
    end
end

function update_hero(this)
    local can_interrupt = anims[this.anim].interruptible
    if (inp.pad_button_pressed(0,BUTTON_JUMP) or inp.pad_button_pressed(1,BUTTON_JUMP)) and can_interrupt then
        set_anim(this, ANIM_JUMP)
        can_interrupt = false
    end
    if (inp.pad_button_pressed(0,BUTTON_HIT) or inp.pad_button_pressed(1,BUTTON_HIT))  and can_interrupt then
        set_anim(this, ANIM_HIT)
        can_interrupt = false
    end
    local right = math.max(inp.right(0),inp.right(1))
    local left = math.max(inp.left(0),inp.left(1))
    if right > 0.0 then
        if can_interrupt then
            set_anim(this, ANIM_WALK)
        end
        this.flip = false
        this.dx = right
    elseif left > 0.0 then
        if can_interrupt then
            set_anim(this, ANIM_WALK)
        end
        this.flip = true
        this.dx = -left
    else
        this.dx = 0
    end
    local up = math.max(inp.up(0),inp.up(1))
    local down = math.max(inp.down(0),inp.down(1))
    if up > 0.0 then
        if can_interrupt then
            set_anim(this, ANIM_WALK)
        end
        this.dy = -up
    elseif down > 0.0 then
        if can_interrupt then
            set_anim(this, ANIM_WALK)
        end
        this.dy = down
    else
        this.dy = 0
    end
    if this.dx == 0 and this.dy == 0 and can_interrupt then
        set_anim(this, ANIM_IDLE)
    end
    if this.dx ~= 0 and this.dy ~= 0 then
        DIAG_FACTOR=1/math.sqrt(2)
        this.dx = this.dx * DIAG_FACTOR
        this.dy = this.dy * DIAG_FACTOR
    end
    local anim = anims[this.anim]
    local anim_len = #anim.frames
    this.anim_frame = this.anim_frame + anim.speed
    if this.anim_frame >= anim_len then
        if anim.interruptible then
            this.anim_frame = this.anim_frame % anim_len
        else
            set_anim(this, ANIM_IDLE)
            this.dx = 0
            this.dy = 0
        end
    end
    this.x = this.x + this.dx * this.speed
    this.y = this.y + this.dy * this.speed
end

function update_noop(this)
end

local hero = {
    x= 0,
    y= 0,
    dx= 0,
    dy= 0,
    speed= 2,
    flip= false,
    anim= ANIM_IDLE,
    sheet= SHEET_WARRIOR,
    anim_frame= 0,
    render= render_character,
    update= update_hero,
}

local grass = {
    x= 64,
    y= 64,
    sheet= SHEET_VEGETATION,
    frame= 0,
    flip= false,
    render= render_object,
    update= update_noop,
}

function init()
    gfx.set_layer_size(LAYER_SPRITE, SPRITESHEET_SIZE, SPRITESHEET_SIZE)
    gfx.set_layer_size(LAYER_GROUND_SPRITE, SPRITESHEET_SIZE, SPRITESHEET_SIZE)
    gfx.set_active_layer(LAYER_SPRITE)
    gfx.load_img("sprites", "carts/tcod/char.png")
    gfx.set_active_layer(0)
    gfx.set_sprite_layer(LAYER_SPRITE)
    gfx.set_scanline(gfx.SCANLINE_HARD)
    gfx.show_layer(LAYER_SHADOW)
    gfx.show_layer(LAYER_ENTITIES)
    gfx.set_layer_operation(1, gfx.LAYEROP_MULTIPLY)
    gfx.set_mouse_cursor(LAYER_SPRITE, 64, 470, 16, 16)
    entities = {hero,grass}
end

local function compare_entity(a,b)
    return a.y < b.y
end

function update()
    for _,entity in pairs(entities) do
        entity:update()
    end
    table.sort(entities, compare_entity)
end

function render()
    gfx.set_active_layer(0)
    gfx.clear(0, 0, 0)
    render_map(map, 0, 0)
    gfx.set_active_layer(LAYER_SHADOW)
    gfx.clear(1, 1, 1)
    for _,entity in pairs(entities) do
        render_shadow(entity)
    end
    gfx.set_active_layer(LAYER_ENTITIES)
    gfx.clear(0, 0, 0)
    for _,entity in pairs(entities) do
        entity:render()
    end
end