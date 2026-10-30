--- Where the cards live: the play area for the current viewport.
--
-- The Minit slot has no design resolution, so every number here is a multiple
-- of `layout.unit` (the viewport is 18 units tall). The card art is a 64x64
-- square with the actual card drawn 42x60 in the middle, so the playable body
-- is a fraction of the sprite and collisions use that body, not the sprite.
local M = {}

local SPRITE_PX = 64
local CARD_W_PX = 42
local CARD_H_PX = 60

--- The card artwork inside the 64x64 sprite.
M.CARD_W_RATIO = CARD_W_PX / SPRITE_PX
M.CARD_H_RATIO = CARD_H_PX / SPRITE_PX

--- Height of the HUD band at the top of the screen. The top wall sits below it,
--- so a card can never reach the labels.
local HUD_UNITS = 2.0
local SIDE_UNITS = 0.35
local BOTTOM_UNITS = 0.35
--- Sprite square size; the card body is ~1.76 x 2.52 units.
local CARD_UNITS = 2.69
--- Space kept between two card bodies when a table is dealt.
local GAP_UNITS = 0.28
--- Share of the spawn cells that may be occupied. Above this the cards spend
--- all their time colliding instead of moving.
local CELL_FILL = 0.35
local MAX_PAIRS = 8

---@class field.Metrics
---@field unit number
---@field left number
---@field right number
---@field bottom number
---@field top number
---@field width number
---@field height number
---@field sprite_size number world pixels of the 64x64 sprite square
---@field card_w number world pixels of the visible card
---@field card_h number world pixels of the visible card
---@field half_w number
---@field half_h number
---@field cell_w number
---@field cell_h number
---@field cols integer
---@field rows integer
---@field cells integer

---@param width number backbuffer pixels
---@param height number backbuffer pixels
---@param unit number
---@return field.Metrics
function M.measure(width, height, unit)
    local metrics = { unit = unit }
    metrics.left = SIDE_UNITS * unit
    metrics.right = width - SIDE_UNITS * unit
    metrics.bottom = BOTTOM_UNITS * unit
    metrics.top = height - HUD_UNITS * unit
    metrics.width = math.max(unit, metrics.right - metrics.left)
    metrics.height = math.max(unit, metrics.top - metrics.bottom)

    metrics.sprite_size = CARD_UNITS * unit
    metrics.card_w = metrics.sprite_size * M.CARD_W_RATIO
    metrics.card_h = metrics.sprite_size * M.CARD_H_RATIO
    metrics.half_w = metrics.card_w * 0.5
    metrics.half_h = metrics.card_h * 0.5

    metrics.cell_w = metrics.card_w + GAP_UNITS * unit
    metrics.cell_h = metrics.card_h + GAP_UNITS * unit
    metrics.cols = math.max(1, math.floor(metrics.width / metrics.cell_w))
    metrics.rows = math.max(1, math.floor(metrics.height / metrics.cell_h))
    metrics.cells = metrics.cols * metrics.rows
    return metrics
end

--- Pairs that fit the table and still leave room to bounce around.
---@param metrics field.Metrics
---@return integer
function M.capacity(metrics)
    local by_room = math.floor(metrics.cells * CELL_FILL * 0.5)
    local by_cells = math.floor(metrics.cells * 0.5) - 1
    return math.max(2, math.min(MAX_PAIRS, by_room, by_cells))
end

--- Distinct, non-overlapping spawn positions, in random order.
---@param metrics field.Metrics
---@param count integer
---@return { x: number, y: number }[]
function M.pick_cells(metrics, count)
    local total = metrics.cells
    local wanted = math.min(count, total)
    local indices = {}
    for i = 1, total do
        indices[i] = i
    end
    for i = 1, wanted do
        local j = math.random(i, total)
        indices[i], indices[j] = indices[j], indices[i]
    end

    local grid_w = metrics.cols * metrics.cell_w
    local grid_h = metrics.rows * metrics.cell_h
    local x0 = metrics.left + (metrics.width - grid_w) * 0.5 + metrics.cell_w * 0.5
    local y0 = metrics.bottom + (metrics.height - grid_h) * 0.5 + metrics.cell_h * 0.5

    local spots = {}
    for i = 1, wanted do
        local index = indices[i] - 1
        local col = index % metrics.cols
        local row = math.floor(index / metrics.cols)
        spots[i] = {
            x = x0 + col * metrics.cell_w,
            y = y0 + row * metrics.cell_h,
        }
    end
    return spots
end

return M
