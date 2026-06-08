-- 2048 board logic

local DEFAULT_N = 4

-- ---------------------------------------------------------------------------
-- Slide helpers
-- ---------------------------------------------------------------------------

-- Slide a 1-D array of tiles leftward: compact, merge, pad with zeros.
-- Returns new array and score gained from merges.
local function slideLeft(row, n)
    -- Compact: remove zeros
    local compacted = {}
    for i = 1, n do
        if row[i] ~= 0 then compacted[#compacted + 1] = row[i] end
    end
    -- Merge adjacent equal pairs
    local merged = {}
    local score  = 0
    local i = 1
    while i <= #compacted do
        if i < #compacted and compacted[i] == compacted[i + 1] then
            local val = compacted[i] * 2
            merged[#merged + 1] = val
            score = score + val
            i = i + 2
        else
            merged[#merged + 1] = compacted[i]
            i = i + 1
        end
    end
    -- Pad with zeros to length n
    while #merged < n do merged[#merged + 1] = 0 end
    return merged, score
end

-- Extract column c from a 2-D grid (grid[r][c]) as a 1-D array
local function getCol(grid, c, n)
    local col = {}
    for r = 1, n do col[r] = grid[r][c] end
    return col
end

-- Write a 1-D array back into column c
local function setCol(grid, c, col, n)
    for r = 1, n do grid[r][c] = col[r] end
end

-- Reverse a 1-D array
local function rev(arr)
    local out = {}
    local len = #arr
    for i = 1, len do out[i] = arr[len - i + 1] end
    return out
end

-- Deep copy a 2-D grid
local function copyGrid(src, n)
    local out = {}
    for r = 1, n do
        out[r] = {}
        for c = 1, n do out[r][c] = src[r][c] end
    end
    return out
end

-- ---------------------------------------------------------------------------
-- Game2048Board
-- ---------------------------------------------------------------------------

local Game2048Board = {}
Game2048Board.__index = Game2048Board

function Game2048Board:new(opts)
    opts = opts or {}
    local n   = opts.n or DEFAULT_N
    local obj = setmetatable({
        n          = n,
        grid       = nil,
        score      = 0,
        prev_grid  = nil,
        prev_score = nil,
        game_over  = false,
        win        = false,
        win_shown  = false,   -- flag so we only announce 2048 once
    }, self)
    obj:_initGrid()
    obj:_spawnTile()
    obj:_spawnTile()
    return obj
end

function Game2048Board:_initGrid()
    local n = self.n
    self.grid = {}
    for r = 1, n do
        self.grid[r] = {}
        for c = 1, n do self.grid[r][c] = 0 end
    end
end

function Game2048Board:_spawnTile()
    local empties = {}
    local n = self.n
    for r = 1, n do
        for c = 1, n do
            if self.grid[r][c] == 0 then
                empties[#empties + 1] = { r, c }
            end
        end
    end
    if #empties == 0 then return end
    local pick = empties[math.random(#empties)]
    self.grid[pick[1]][pick[2]] = (math.random() < 0.9) and 2 or 4
end

-- Apply a slide in the given direction.
-- direction: "left", "right", "up", "down"
-- Returns true if anything moved (allowing a new tile to spawn).
function Game2048Board:slide(direction)
    if self.game_over then return false end

    -- Save undo snapshot
    self.prev_grid  = copyGrid(self.grid, self.n)
    self.prev_score = self.score

    local n     = self.n
    local moved = false
    local score_gain = 0

    if direction == "left" then
        for r = 1, n do
            local new, gain = slideLeft(self.grid[r], n)
            for c = 1, n do
                if new[c] ~= self.grid[r][c] then moved = true end
                self.grid[r][c] = new[c]
            end
            score_gain = score_gain + gain
        end

    elseif direction == "right" then
        for r = 1, n do
            local reversed = rev(self.grid[r])
            local new, gain = slideLeft(reversed, n)
            new = rev(new)
            for c = 1, n do
                if new[c] ~= self.grid[r][c] then moved = true end
                self.grid[r][c] = new[c]
            end
            score_gain = score_gain + gain
        end

    elseif direction == "up" then
        for c = 1, n do
            local col = getCol(self.grid, c, n)
            local new, gain = slideLeft(col, n)
            for r = 1, n do
                if new[r] ~= self.grid[r][c] then moved = true end
            end
            setCol(self.grid, c, new, n)
            score_gain = score_gain + gain
        end

    elseif direction == "down" then
        for c = 1, n do
            local col = rev(getCol(self.grid, c, n))
            local new, gain = slideLeft(col, n)
            new = rev(new)
            for r = 1, n do
                if new[r] ~= self.grid[r][c] then moved = true end
            end
            setCol(self.grid, c, new, n)
            score_gain = score_gain + gain
        end
    end

    if not moved then
        self.prev_grid  = nil
        self.prev_score = nil
        return false
    end

    self.score = self.score + score_gain

    -- Check win (2048 tile)
    if not self.win_shown then
        for r = 1, n do
            for c = 1, n do
                if self.grid[r][c] >= 2048 then
                    self.win      = true
                    self.win_shown = true
                end
            end
        end
    end

    self:_spawnTile()

    -- Check game over (no moves available)
    if not self:_hasMoves() then
        self.game_over = true
    end

    return true
end

function Game2048Board:_hasMoves()
    local n = self.n
    for r = 1, n do
        for c = 1, n do
            if self.grid[r][c] == 0 then return true end
            if c < n and self.grid[r][c] == self.grid[r][c + 1] then return true end
            if r < n and self.grid[r][c] == self.grid[r + 1][c] then return true end
        end
    end
    return false
end

function Game2048Board:canUndo()
    return self.prev_grid ~= nil
end

function Game2048Board:undo()
    if not self.prev_grid then return false end
    self.grid      = self.prev_grid
    self.score     = self.prev_score
    self.prev_grid  = nil
    self.prev_score = nil
    self.game_over  = false
    return true
end

function Game2048Board:getMaxTile()
    local max = 0
    local n = self.n
    for r = 1, n do
        for c = 1, n do
            if self.grid[r][c] > max then max = self.grid[r][c] end
        end
    end
    return max
end

-- ---------------------------------------------------------------------------
-- Persistence
-- ---------------------------------------------------------------------------

function Game2048Board:serialize()
    local n = self.n
    return {
        n          = n,
        grid       = copyGrid(self.grid, n),
        score      = self.score,
        game_over  = self.game_over,
        win        = self.win,
        win_shown  = self.win_shown,
    }
end

function Game2048Board:load(data)
    if type(data) ~= "table" or not data.grid then return false end
    local n = data.n or DEFAULT_N
    self.n         = n
    self.grid      = copyGrid(data.grid, n)
    self.score     = data.score     or 0
    self.game_over = data.game_over or false
    self.win       = data.win       or false
    self.win_shown = data.win_shown or false
    self.prev_grid  = nil
    self.prev_score = nil
    return true
end

return Game2048Board
