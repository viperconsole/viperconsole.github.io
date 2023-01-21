local const=require("www.carts.cryon.constants")
local M={}
-- ################################## SECTOR ##################################

local function update_sector(s)
    for _,e in pairs(s.entities) do
        e:update()
    end
end

local function render_sector(s)
    gfx.set_active_layer(const.LAYER_ENTITIES)
    for _,e in pairs(s.entities) do
        e:render()
    end
end

function M.generate(seed, PALETTE, planet)
    math.randomseed(seed)
    local entities = {}
    table.insert(entities,planet.generate(PALETTE))
    return { entities= entities, update=update_sector,render=render_sector }
end

return M