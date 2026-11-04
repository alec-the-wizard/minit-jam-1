--- Cards: dealing, flipping, bouncing off walls and each other.
--
-- Every card is a game object spawned from the card factory. This module owns
-- the whole simulation so the game script only has to react to events:
--   * the first face-up card waits for a second one,
--   * a matching pair is held for a beat and then deleted,
--   * a mismatch is shown for a moment and then flipped back down.
--
-- A card's body is the whole sprite, so the wall and card collision tests use
-- the sprite rectangle as-is.
local field = require("main.field")

local M = {}

--- A half flip takes 0.20 s.
local FLIP_SPEED = math.pi / 0.20
--- Random extra delay before each card of a dealt table turns over.
local PEEK_STAGGER = 0.25
local SPAWN_POP_TIME = 0.20
local SPAWN_POP_FROM = 0.55
local MATCH_HOLD = 0.38
local MISS_HOLD = 0.85
--- Keep the edge-on frame from collapsing the sprite completely.
local MIN_FLIP_SCALE = 0.02
--- Extra tap area around the card body, in units, to be kind to fingers.
local TAP_SLOP_UNITS = 0.08

---@class cards.Card
---@field id hash
---@field sprite url
---@field face string atlas animation id of the card face
---@field image string|nil animation currently played
---@field x number
---@field y number
---@field vx number
---@field vy number
---@field hw number
---@field hh number
---@field base_w number
---@field base_h number
---@field pop number
---@field pop_t number
---@field flip number 0 = face down, pi = face up
---@field flip_target number
---@field phase string "peek"|"hiding"|"hidden"|"up"|"wrong"|"matched"|"revealed"
---@field timer number
---@field moving boolean

---@class cards.World
---@field unit number
---@field speed number units per second along each axis
---@field metrics field.Metrics
---@field factory url
---@field reveal number seconds a fresh table stays face up
---@field cards cards.Card[]
---@field picked cards.Card[]
---@field busy boolean
---@field judge boolean
---@field unlock_timer number|nil
---@field on_pair fun(a: cards.Card, b: cards.Card)
---@field on_miss fun(a: cards.Card, b: cards.Card)
---@field on_bounce fun(x: number, y: number)

---@param world table
---@return cards.World
function M.new(world)
    return {
        unit = world.unit,
        speed = world.speed,
        metrics = world.metrics,
        factory = world.factory,
        reveal = world.reveal,
        cards = {},
        picked = {},
        busy = false,
        judge = false,
        on_pair = world.on_pair,
        on_miss = world.on_miss,
        on_bounce = world.on_bounce,
    }
end

local function set_image(card, image)
    if card.image == image then
        return
    end
    card.image = image
    sprite.play_flipbook(card.sprite, image)
end

local function apply_transform(card)
    local height = card.base_h * card.pop
    local width = card.base_w * card.pop * math.max(MIN_FLIP_SCALE, math.abs(math.cos(card.flip)))
    go.set_position(vmath.vector3(card.x, card.y, 0), card.id)
    go.set_scale(vmath.vector3(width, height, 1), card.id)
end

local function start_moving(world, card)
    local speed = world.speed * world.unit
    card.vx = (math.random(2) == 1 and 1 or -1) * speed
    card.vy = (math.random(2) == 1 and 1 or -1) * speed
    card.moving = true
end

local function bounce_walls(world, card)
    local m = world.metrics
    local hit = false
    if card.x - card.hw < m.left then
        card.x = m.left + card.hw
        card.vx = math.abs(card.vx)
        hit = true
    elseif card.x + card.hw > m.right then
        card.x = m.right - card.hw
        card.vx = -math.abs(card.vx)
        hit = true
    end
    if card.y - card.hh < m.bottom then
        card.y = m.bottom + card.hh
        card.vy = math.abs(card.vy)
        hit = true
    elseif card.y + card.hh > m.top then
        card.y = m.top - card.hh
        card.vy = -math.abs(card.vy)
        hit = true
    end
    if hit then
        world.on_bounce(card.x, card.y)
    end
end

--- Two cards of the same mass meeting: push them apart and swap the velocity
--- along the axis they overlapped on the least. Both stay on a diagonal.
local function separate(world, a, b)
    local dx = b.x - a.x
    local dy = b.y - a.y
    local overlap_x = (a.hw + b.hw) - math.abs(dx)
    local overlap_y = (a.hh + b.hh) - math.abs(dy)
    if overlap_x <= 0 or overlap_y <= 0 then
        return
    end

    if overlap_x < overlap_y then
        local dir = dx >= 0 and 1 or -1
        local push = overlap_x * 0.5
        a.x = a.x - dir * push
        b.x = b.x + dir * push
        a.vx, b.vx = b.vx, a.vx
    else
        local dir = dy >= 0 and 1 or -1
        local push = overlap_y * 0.5
        a.y = a.y - dir * push
        b.y = b.y + dir * push
        a.vy, b.vy = b.vy, a.vy
    end
    world.on_bounce((a.x + b.x) * 0.5, (a.y + b.y) * 0.5)
end

local function advance(world, card, dt)
    if card.pop < 1 then
        card.pop_t = card.pop_t + dt
        local p = math.min(1, card.pop_t / SPAWN_POP_TIME)
        card.pop = SPAWN_POP_FROM + (1 - SPAWN_POP_FROM) * (1 - (1 - p) * (1 - p))
    end

    if card.phase == "peek" or card.phase == "wrong" then
        card.timer = card.timer - dt
        if card.timer <= 0 then
            card.phase = "hiding"
            card.flip_target = 0
        end
    end

    if card.flip ~= card.flip_target then
        local step = FLIP_SPEED * dt
        if card.flip < card.flip_target then
            card.flip = math.min(card.flip_target, card.flip + step)
        else
            card.flip = math.max(card.flip_target, card.flip - step)
        end
        -- The artwork swaps while the card is edge-on, like a real flip.
        set_image(card, card.flip >= math.pi * 0.5 and card.face or "back")
        if card.flip == card.flip_target and card.flip_target == 0 then
            card.phase = "hidden"
            if not card.moving then
                start_moving(world, card)
            end
        end
    end

    if card.moving then
        card.x = card.x + card.vx * dt
        card.y = card.y + card.vy * dt
        bounce_walls(world, card)
    end
end

local function judge(world)
    local a = world.picked[1]
    local b = world.picked[2]
    if not a or not b then
        world.judge = false
        return
    end
    if a.flip < math.pi or b.flip < math.pi then
        return
    end

    world.judge = false
    world.picked = {}
    if a.face == b.face then
        a.phase, a.timer = "matched", MATCH_HOLD
        b.phase, b.timer = "matched", MATCH_HOLD
        a.moving, b.moving = false, false
        a.vx, a.vy, b.vx, b.vy = 0, 0, 0, 0
        world.busy = false
        world.on_pair(a, b)
    else
        a.phase, a.timer = "wrong", MISS_HOLD
        b.phase, b.timer = "wrong", MISS_HOLD
        world.unlock_timer = MISS_HOLD
        world.on_miss(a, b)
    end
end

---@param world cards.World
---@param faces string[]
function M.spawn(world, faces)
    local entries = {}
    for _, face in ipairs(faces) do
        entries[#entries + 1] = face
        entries[#entries + 1] = face
    end
    for i = #entries, 2, -1 do
        local j = math.random(i)
        entries[i], entries[j] = entries[j], entries[i]
    end

    local m = world.metrics
    local spots = field.pick_cells(m, #entries)
    local base_w = m.card_w / m.art_w
    local base_h = m.card_h / m.art_h

    for i, face in ipairs(entries) do
        local spot = spots[i]
        local id = factory.create(world.factory, vmath.vector3(spot.x, spot.y, 0))
        local card = {
            id = id,
            sprite = msg.url(nil, id, "sprite"),
            face = face,
            image = nil,
            x = spot.x,
            y = spot.y,
            vx = 0,
            vy = 0,
            hw = m.half_w,
            hh = m.half_h,
            base_w = base_w,
            base_h = base_h,
            pop = SPAWN_POP_FROM,
            pop_t = 0,
            flip = math.pi,
            flip_target = math.pi,
            phase = "peek",
            timer = world.reveal + math.random() * PEEK_STAGGER,
            moving = false,
        }
        set_image(card, face)
        apply_transform(card)
        world.cards[#world.cards + 1] = card
    end
end

---@param world cards.World
---@return integer
function M.count(world)
    return #world.cards
end

--- The card under a point, if any.
---@param world cards.World
---@param x number
---@param y number
---@return cards.Card|nil
function M.card_at(world, x, y)
    local slop = TAP_SLOP_UNITS * world.unit
    local list = world.cards
    for i = #list, 1, -1 do
        local card = list[i]
        if card.phase ~= "matched"
            and x >= card.x - card.hw - slop and x <= card.x + card.hw + slop
            and y >= card.y - card.hh - slop and y <= card.y + card.hh + slop then
            return card
        end
    end
    return nil
end

--- Try to reveal the card under a point.
---@param world cards.World
---@param x number
---@param y number
---@return cards.Card|nil the card that was turned over
function M.pick(world, x, y)
    if world.busy then
        return nil
    end
    local card = M.card_at(world, x, y)
    if not card or card.phase ~= "hidden" then
        return nil
    end

    card.phase = "up"
    card.flip_target = math.pi
    world.picked[#world.picked + 1] = card
    if #world.picked == 2 then
        world.busy = true
        world.judge = true
    end
    return card
end

--- Cut the opening reveal short: every card still peeking flips down at once.
---@param world cards.World
---@return boolean whether any card was still peeking
function M.skip_peek(world)
    local skipped = false
    for _, card in ipairs(world.cards) do
        if card.phase == "peek" then
            card.timer = 0
            skipped = true
        end
    end
    return skipped
end

--- Whether the opening reveal is over and the table has settled face down.
---@param world cards.World
---@return boolean
function M.dealt(world)
    for _, card in ipairs(world.cards) do
        if card.phase == "peek" or card.phase == "hiding" then
            return false
        end
    end
    return true
end

--- Turn every remaining card face up and stop the table (end of round).
---@param world cards.World
function M.reveal_all(world)
    world.busy = true
    for _, card in ipairs(world.cards) do
        card.moving = false
        card.vx, card.vy = 0, 0
        card.flip_target = math.pi
        if card.phase ~= "matched" then
            card.phase = "revealed"
        end
    end
end

---@param world cards.World
---@param dt number
function M.update(world, dt)
    local list = world.cards

    for i = #list, 1, -1 do
        local card = list[i]
        if card.phase == "matched" then
            card.timer = card.timer - dt
            if card.timer <= 0 then
                go.delete(card.id)
                table.remove(list, i)
            end
        else
            advance(world, card, dt)
        end
    end

    for i = 1, #list do
        local a = list[i]
        if a.moving then
            for j = i + 1, #list do
                local b = list[j]
                if b.moving then
                    separate(world, a, b)
                end
            end
        end
    end

    for _, card in ipairs(list) do
        apply_transform(card)
    end

    if world.unlock_timer then
        world.unlock_timer = world.unlock_timer - dt
        if world.unlock_timer <= 0 then
            world.unlock_timer = nil
            world.busy = false
        end
    end

    if world.judge then
        judge(world)
    end
end

--- Move the cards onto a new viewport without disturbing the round.
---@param world cards.World
---@param metrics field.Metrics
---@param unit number
function M.reflow(world, metrics, unit)
    local old = world.metrics
    local stretch_x = metrics.width / math.max(1, old.width)
    local stretch_y = metrics.height / math.max(1, old.height)
    local speed_scale = unit / world.unit

    for _, card in ipairs(world.cards) do
        card.x = metrics.left + (card.x - old.left) * stretch_x
        card.y = metrics.bottom + (card.y - old.bottom) * stretch_y
        card.hw = metrics.half_w
        card.hh = metrics.half_h
        card.base_w = metrics.card_w / metrics.art_w
        card.base_h = metrics.card_h / metrics.art_h
        card.vx = card.vx * speed_scale
        card.vy = card.vy * speed_scale
        card.x = math.max(metrics.left + card.hw, math.min(metrics.right - card.hw, card.x))
        card.y = math.max(metrics.bottom + card.hh, math.min(metrics.top - card.hh, card.y))
        apply_transform(card)
    end

    world.metrics = metrics
    world.unit = unit
end

--- Change the speed used the next time a card starts moving.
---@param world cards.World
---@param speed number units per second along each axis
function M.set_speed(world, speed)
    world.speed = speed
end

return M
