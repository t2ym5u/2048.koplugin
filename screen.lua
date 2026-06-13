local _dir = debug.getinfo(1, "S").source:sub(2):match("(.*[/\\])") or "./"
local function lrequire(name)
    local key = _dir .. name
    if not package.loaded[key] then
        package.loaded[key] = assert(loadfile(_dir .. name .. ".lua"))()
    end
    return package.loaded[key]
end

local ButtonTable     = require("ui/widget/buttontable")
local Device          = require("device")
local FrameContainer  = require("ui/widget/container/framecontainer")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local HorizontalSpan  = require("ui/widget/horizontalspan")
local Size            = require("ui/size")
local UIManager       = require("ui/uimanager")
local VerticalGroup   = require("ui/widget/verticalgroup")
local VerticalSpan    = require("ui/widget/verticalspan")
local _               = require("gettext")
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

Slide all tiles in one direction at a time (up, down, left, right).
When two tiles with the same number collide, they merge into one tile with their combined value.
After each move, a new tile (2 or 4) appears in a random empty cell.
Goal: create a tile with the value 2048.
The game ends when no more moves are possible.

Score: the value of each newly merged tile is added to your score.
]])

local GAME_RULES_FR = [[
2048 — Règles

Faites glisser toutes les tuiles dans une direction. Deux tuiles portant le même chiffre fusionnent en une tuile de valeur double. Après chaque déplacement, une nouvelle tuile (2 ou 4) apparaît dans une case vide. Objectif : créer une tuile valant 2048. La partie se termine quand aucun mouvement n'est plus possible.

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
    local sw           = DeviceScreen:getWidth()
    local is_landscape = self:isLandscape()

    local button_width = is_landscape
        and math.max(math.floor(sw * 0.35), 100)
        or  math.floor(sw * 0.9)

    -- Top bar
    local top_buttons = ButtonTable:new{
        shrink_unneeded_width = true,
        width   = button_width,
        buttons = {{
            { text = _("New"),  callback = function() self:onNewGame() end },
            { id = "size_btn",  text = self:getSizeButtonText(),
              callback = function() self:onCycleSize() end },
            { id = "undo_btn",  text = _("Undo"),
              callback = function() self:onUndo() end },
            self:makeRulesButtonConfig(GAME_RULES_EN, GAME_RULES_FR),
            self:makeCloseButtonConfig(),
        }},
    }
    self.size_btn = top_buttons:getButtonById("size_btn")
    self.undo_btn = top_buttons:getButtonById("undo_btn")
    self:_updateUndoButton()

    -- Board widget
    self.board_widget = Game2048BoardWidget:new{
        board   = self.board,
        onSwipe = function(dir) self:onSlide(dir) end,
    }

    local board_frame = FrameContainer:new{
        padding = Size.padding.large,
        margin  = Size.margin.default,
        self.board_widget,
    }

    -- Arrow buttons (alternative to swipe) — use full portrait width for spacing
    local arrow_width = is_landscape
        and math.max(math.floor(sw * 0.45), 160)
        or  math.floor(sw * 0.95)
    local arrow_buttons = ButtonTable:new{
        shrink_unneeded_width = true,
        width   = arrow_width,
        buttons = {
            {
                { text = "\xE2\x86\x90", callback = function() self:onSlide("left")  end },
                { text = "\xE2\x86\x91", callback = function() self:onSlide("up")    end },
                { text = "\xE2\x86\x93", callback = function() self:onSlide("down")  end },
                { text = "\xE2\x86\x92", callback = function() self:onSlide("right") end },
            },
        },
    }

    if is_landscape then
        local right_panel = VerticalGroup:new{
            align = "center",
            top_buttons,
            VerticalSpan:new{ width = Size.span.vertical_large },
            self.status_text,
            VerticalSpan:new{ width = Size.span.vertical_large },
            arrow_buttons,
        }
        self.layout = HorizontalGroup:new{
            align  = "center",
            board_frame,
            HorizontalSpan:new{ width = Size.span.horizontal_default },
            right_panel,
        }
    else
        self.layout = VerticalGroup:new{
            align = "center",
            VerticalSpan:new{ width = Size.span.vertical_large },
            top_buttons,
            VerticalSpan:new{ width = Size.span.vertical_large },
            board_frame,
            VerticalSpan:new{ width = Size.span.vertical_large },
            self.status_text,
            VerticalSpan:new{ width = Size.span.vertical_large },
            arrow_buttons,
            VerticalSpan:new{ width = Size.span.vertical_large },
        }
    end
    self[1] = self.layout
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
    self.plugin:saveState(self.board:serialize())
end

function Game2048Screen:onUndo()
    if self.board:undo() then
        self._win_announced = false
        self:_updateUndoButton()
        self.board_widget:refresh()
        self:updateStatus()
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
        local max_tile = self.board:getMaxTile()
        if self.board.game_over then
            status = T(_("Game over \xC2\xB7 Score: %1 \xC2\xB7 Best: %2"), self.board.score, best)
        else
            status = T(_("Score: %1 \xC2\xB7 Best: %2 \xC2\xB7 Max: %3"),
                self.board.score, best, max_tile)
        end
    end
    ScreenBase.updateStatus(self, status)
end

-- ---------------------------------------------------------------------------
-- Button text helpers
-- ---------------------------------------------------------------------------

function Game2048Screen:getSizeButtonText()
    local n = self.plugin:getSetting("grid_n", 4)
    return T(_("%1\xC3\x97%2"), n, n)
end

function Game2048Screen:_updateUndoButton()
    if not self.undo_btn then return end
    self.undo_btn:enableDisable(self.board:canUndo())
end

return Game2048Screen
