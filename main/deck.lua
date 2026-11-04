--- The pool of card faces a table is dealt from.
--
-- Every animation in /main/uncompressed/cards.atlas except "back" is one face.
-- A table picks unique faces and pairs each of them up.
local M = {}

local FACES = {
    "clubs_02", "clubs_03", "clubs_04", "clubs_05", "clubs_06", "clubs_07",
    "clubs_08", "clubs_09", "clubs_10", "clubs_A", "clubs_J", "clubs_K",
    "clubs_Q",
    "diamonds_02", "diamonds_03", "diamonds_04", "diamonds_05", "diamonds_06",
    "diamonds_07", "diamonds_08", "diamonds_09", "diamonds_10", "diamonds_A",
    "diamonds_J", "diamonds_K", "diamonds_Q",
    "hearts_02", "hearts_03", "hearts_04", "hearts_05", "hearts_06",
    "hearts_07", "hearts_08", "hearts_09", "hearts_10", "hearts_A",
    "hearts_J", "hearts_K", "hearts_Q",
    "spades_02", "spades_03", "spades_04", "spades_05", "spades_06",
    "spades_07", "spades_08", "spades_09", "spades_10", "spades_A",
    "spades_J", "spades_K", "spades_Q",
}

---@return integer
function M.count()
    return #FACES
end

--- Pick `count` distinct faces in random order. Each face is used once per table.
---@param count integer
---@return string[]
function M.pick(count)
    local wanted = math.min(count, #FACES)
    local pool = {}
    for i = 1, #FACES do
        pool[i] = FACES[i]
    end
    for i = 1, wanted do
        local j = math.random(i, #pool)
        pool[i], pool[j] = pool[j], pool[i]
    end
    local picked = {}
    for i = 1, wanted do
        picked[i] = pool[i]
    end
    return picked
end

return M
