--- Deterministic random numbers for the deal.
--
-- The Minit SDK has no seeded-random helper, and `math.random` is one global
-- stream: the cosmetic pitch calls in the game script would otherwise consume
-- it, so table N would depend on how the player played table N-1. The deal gets
-- its own Park-Miller stream instead, seeded from the Post's `seed` config, so
-- everyone on a Post gets the same tables in the same order.
local M = {}

local A = 16807
local MOD = 2147483647
local Q = 127773  -- MOD / A
local R = 2836    -- MOD % A

---@class rng.Stream
---@field state integer

---@param seed integer
---@return rng.Stream
function M.new(seed)
    local state = math.abs(math.floor(seed)) % MOD
    if state == 0 then
        state = 1
    end
    return { state = state }
end

---@param stream rng.Stream
---@return integer the next state, in [1, MOD - 1]
local function advance(stream)
    local hi = math.floor(stream.state / Q)
    local lo = stream.state - hi * Q
    local value = A * lo - R * hi
    if value <= 0 then
        value = value + MOD
    end
    stream.state = value
    return value
end

--- Uniform integer in [1, count].
---@param stream rng.Stream
---@param count integer
---@return integer
function M.int(stream, count)
    return math.floor(advance(stream) / MOD * count) + 1
end

--- Uniform number in (0, 1).
---@param stream rng.Stream
---@return number
function M.unit(stream)
    return advance(stream) / MOD
end

return M
