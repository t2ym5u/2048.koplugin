local _dir = debug.getinfo(1, "S").source:sub(2):match("(.*[/\\])") or "./"
local function lrequire(name)
    local key = _dir .. name
    if not package.loaded[key] then
        package.loaded[key] = assert(loadfile(_dir .. name .. ".lua"))()
    end
    return package.loaded[key]
end

local Device          = require("device")
local FrameContainer  = require("ui/widget/container/framecontainer")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local HorizontalSpan  = require("ui/widget/horizontalspan")
local Size            = require("ui/size")
local UIManager       = require("ui/uimanager")
local VerticalGroup   = require("ui/widget/verticalgroup")
local VerticalSpan    = require("ui/widget/verticalspan")
local _               = require("i18n")
local T               = require("ffi/util").template

local ScreenBase         = require("screen_base")
local Game2048Board      = lrequire("board")
local Game2048BoardWidget = lrequire("board_widget")

local DeviceScreen = Device.screen

-- ---------------------------------------------------------------------------
-- Game2048Screen
-- ---------------------------------------------------------------------------

local GAME_RULES_EN = _([[
2048 — Rules

Slide all tiles in one direction at a time (up, down, left, right): swipe on the board, or tap one of the arrow buttons.
When two tiles with the same number collide, they merge into one tile with their combined value.
After each move, a new tile (2 or 4) appears in a random empty cell.
Goal: create a tile with the value 2048.
The game ends when no more moves are possible.

Score: the value of each newly merged tile is added to your score.
]])

local GAME_RULES_FR = [[
2048 — Règles

Faites glisser toutes les tuiles dans une direction : balayez le plateau ou appuyez sur l'une des flèches. Deux tuiles portant le même chiffre fusionnent en une tuile de valeur double. Après chaque déplacement, une nouvelle tuile (2 ou 4) apparaît dans une case vide. Objectif : créer une tuile valant 2048. La partie se termine quand aucun mouvement n'est plus possible.

Score : la valeur de chaque fusion est ajoutée à votre score.
]]

local Game2048Screen = ScreenBase:extend{}

-- ---------------------------------------------------------------------------
-- Lifecycle
-- ---------------------------------------------------------------------------

function Game2048Screen:init()
    local state = self.plugin:loadState()
    self.board  = Game2048Board:new{ n = self.plugin:getSetting("grid_n", 4) }
    if not self.board:load(state) then
        -- default board already initialised by :new
    end
    ScreenBase.init(self)
end

function Game2048Screen:serializeState()
    return self.board:serialize()
end

-- ---------------------------------------------------------------------------
-- Layout
-- ---------------------------------------------------------------------------

function Game2048Screen:buildLayout()
    local is_landscape = self:isLandscape()

    -- Title bar with Options menu
    local title_bar = self:buildTitleBar(_("2048"), function()
        return {
            { text = _("New game"),            callback = function() self:onNewGame() end },
            { text = self:getSizeButtonText(), callback = function() self:onCycleSize() end },
            { text = _("Undo"),                callback = function() self:onUndo() end },
            self:makeRulesButtonConfig(GAME_RULES_EN, GAME_RULES_FR),
        }
    end)

    -- Arrow buttons (alternative to swipe), one row at the controls width.
    self.status_text:setMaxWidth(self:getControlsWidth())
    local controls = VerticalGroup:new{
        align = "center",
        self.status_text,
        VerticalSpan:new{ width = Size.span.vertical_large },
        self:buildActionBar({
            { text = "\xE2\x86\x91", callback = function() self:onSlide("up") end },
            { text = "\xE2\x86\x93", callback = function() self:onSlide("down") end },
            { text = "\xE2\x86\x90", callback = function() self:onSlide("left") end },
            { text = "\xE2\x86\x92", callback = function() self:onSlide("right") end },
        }),
    }

    -- The widget paints its own grey board behind the tiles, which already
    -- reads as the board's edge: a bordered frame around it drew a second
    -- outline, so the frame only adds the padding here.
    local frame_pad = Size.padding.large
    local budget_w, budget_h = self:getBoardBudget(title_bar, controls)
    self.board_widget = Game2048BoardWidget:new{
        board    = self.board,
        max_size = math.min(budget_w, budget_h) - 2 * frame_pad,
        onSwipe  = function(dir) self:onSlide(dir) end,
    }
    local board_frame = FrameContainer:new{
        padding    = frame_pad,
        margin     = 0,
        bordersize = 0,
        self.board_widget,
    }

    if is_landscape then
        local content = HorizontalGroup:new{
            align = "center",
            board_frame,
            HorizontalSpan:new{ width = self:getGutter() },
            controls,
        }
        self:buildLandscapeLayout(title_bar, content)
    else
        self:buildPortraitLayout(title_bar, board_frame,
            VerticalGroup:new{ align = "center", controls, VerticalSpan:new{ width = self:getGutter() } })
    end
    self:updateStatus()
end

-- ---------------------------------------------------------------------------
-- Game actions
-- ---------------------------------------------------------------------------

function Game2048Screen:onSlide(direction)
    local moved = self.board:slide(direction)
    if not moved then return end
    self:_updateUndoButton()
    self.board_widget:refresh()
    if self.board.win and not self._win_announced then
        self._win_announced = true
        self:updateStatus(_("You reached 2048! Keep going!"))
    elseif self.board.game_over then
        self:updateStatus(_("No moves left. Game over!"))
    else
        self:updateStatus()
    end
    self:refreshActionBar()
    self.plugin:saveState(self.board:serialize())
end

function Game2048Screen:onUndo()
    if self.board:undo() then
        self._win_announced = false
        self:_updateUndoButton()
        self.board_widget:refresh()
        self:updateStatus()
        self:refreshActionBar()
        self.plugin:saveState(self.board:serialize())
    else
        self:updateStatus(_("Nothing to undo."))
    end
end

function Game2048Screen:onNewGame()
    local n = self.plugin:getSetting("grid_n", 4)
    self.board = Game2048Board:new{ n = n }
    self._win_announced = false
    self.plugin:saveState(self.board:serialize())
    self:buildLayout()
    UIManager:setDirty(self, function() return "ui", self.dimen end)
end

-- Reaching 2048 doesn't end the round (play goes on): only a stuck board does.
function Game2048Screen:isRoundOver()
    return self.board.game_over
end

-- Undoing the move that filled the board is a real way out of a loss.
function Game2048Screen:getRoundOverButtons()
    return {
        { text = _("New game"), callback = function() self:onNewGame() end },
        { text = _("Undo"),     callback = function() self:onUndo() end },
    }
end

function Game2048Screen:onCycleSize()
    local sizes = { 3, 4, 5, 6 }
    local cur   = self.plugin:getSetting("grid_n", 4)
    local next_n = sizes[1]
    for i, v in ipairs(sizes) do
        if v == cur then
            next_n = sizes[(i % #sizes) + 1]
            break
        end
    end
    self.plugin:saveSetting("grid_n", next_n)
    if self.size_btn then
        self.size_btn:setText(self:getSizeButtonText(), self.size_btn.width)
    end
    self:onNewGame()
end

-- ---------------------------------------------------------------------------
-- Status bar
-- ---------------------------------------------------------------------------

function Game2048Screen:updateStatus(msg)
    local status
    if msg then
        status = msg
    else
        local best = self.plugin:getSetting("best_score", 0)
        if self.board.score > best then
            self.plugin:saveSetting("best_score", self.board.score)
            best = self.board.score
        end
        local n = self.board.n
        if self.board.game_over then
            status = self:joinStatus(_("Game over"),
                T(_("Score: %1"), self.board.score),
                T(_("Best: %1"), best))
        else
            -- No "Max" tile part: the board already shows it.
            status = self:joinStatus(T("%1\xC3\x97%2", n, n),
                T(_("Score: %1"), self.board.score),
                T(_("Best: %1"), best))
        end
    end
    ScreenBase.updateStatus(self, status)
end

-- ---------------------------------------------------------------------------
-- Button text helpers
-- ---------------------------------------------------------------------------

function Game2048Screen:getSizeButtonText()
    local n = self.plugin:getSetting("grid_n", 4)
    return T(_("Size: %1"), T("%1\xC3\x97%2", n, n))
end

function Game2048Screen:_updateUndoButton()
    if not self.undo_btn then return end
    self.undo_btn:enableDisable(self.board:canUndo())
end

return Game2048Screen
