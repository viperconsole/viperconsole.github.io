local M = {
    LAYER_BACKGROUND = 0,
    LAYER_STARS = 1,
    LAYER_ENTITIES = 2,
    LAYER_GUI = 3,
    LAYER_SHIP_MODELS = 4,
    LAYER_PLANET_TEXTURE = 5,
    LAYER_SPRITES = 6,

    PI = math.pi,
    PI2 = 2 * math.pi,
    BUTTON_WIDTH = 60,

    -- entity types
    E_PLANET = 1,
    E_STARFIELD = 2,
    E_LABEL = 3,
    E_BUTTON = 4,
    E_SHIP = 5,

    -- text alignment
    ALIGN_CENTER = 0,
    ALIGN_RIGHT = 1,
    ALIGN_LEFT = 2
}

return M