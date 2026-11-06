--- The pool of card faces a table is dealt from.
--
-- A table picks distinct **ranks**, so the same number or letter never appears
-- twice on one table (two 5s of different suits would read as one rank). Each
-- picked face is then paired up by cards.spawn. Suits may repeat; ranks may not.
local M = {}

local rng = require("main.rng")

local SUITS = { "clubs", "diamonds", "hearts", "spades" }
local RANKS = {
    "02", "03", "04", "05", "06", "07", "08", "09", "10", "A", "J", "K", "Q",
}

---@return integer
function M.count()
    return #SUITS * #RANKS
end

--- Pick `count` faces with distinct ranks, in random order.
---@param count integer
---@param stream rng.Stream
---@return string[]
function M.pick(count, stream)
    local wanted = math.min(count, #RANKS)
    local ranks = {}
    for i = 1, #RANKS do
        ranks[i] = RANKS[i]
    end
    for i = 1, wanted do
        local j = i + rng.int(stream, #ranks - i + 1) - 1
        ranks[i], ranks[j] = ranks[j], ranks[i]
    end
    local picked = {}
    for i = 1, wanted do
        picked[i] = SUITS[rng.int(stream, #SUITS)] .. "_" .. ranks[i]
    end
    return picked
end

return M
