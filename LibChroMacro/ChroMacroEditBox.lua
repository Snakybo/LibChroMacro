-- MIT License
--
-- Copyright (c) 2026 Kevin Krol
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

if LibStub == nil then
	return
end

local Type, Version = "ChroMacroEditBox", 1

local AceGUI = LibStub("AceGUI-3.0", true)
local LibChroMacro = LibStub("LibChroMacro", true)

if AceGUI == nil or LibChroMacro == nil or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then
	return
end

local DEBOUNCE_DURATION = 0.05

--- @alias AceGUIWidgetType
--- | "ChroMacroEditBox"

--- @class ChroMacroEditBox : AceGUIMultiLineEditBox
--- @field protected colorTable LibChroMacro.ColorTable
--- @field protected debounce FunctionContainer?
--- @field protected lastColored string?
local ChroMacroEditBox = {}

--- @protected
function ChroMacroEditBox:OnAcquire()
	self:BaseOnAcquire()

	self.colorTable = LibChroMacro:GetDefaultColorTable()
	self.debounce = nil
	self.lastColored = nil

	self.editBox:SetMaxBytes(0)
	self.editBox:SetCountInvisibleLetters(false)

	self:SetMaxLetters(255)
	self:SetLabelColor(NORMAL_FONT_COLOR)
end

--- @param immediate boolean?
function ChroMacroEditBox:Update(immediate)
	if immediate == false then
		if self.debounce ~= nil then
			self.debounce:Cancel()
		end

		self.debounce = C_Timer.NewTimer(DEBOUNCE_DURATION, function()
			self.debounce = nil
			self:Update(true)
		end)
		return
	end

	local colored = self.editBox:GetText()
	if colored == self.lastColored then
		return
	end

	local text, cursor = LibChroMacro:StripColors(colored, self.editBox:GetCursorPosition())
	local newColored, newCursor = LibChroMacro:Colorize(text, self.colorTable, cursor)

	if newColored ~= colored then
		self.lastColored = newColored

		self.editBox:SetText(newColored)
		self.editBox:SetCursorPosition(newCursor --[[@as integer]])
		self.button:Enable()
	end
end

--- @param text string
function ChroMacroEditBox:SetText(text)
	local colored = LibChroMacro:Colorize(text, self.colorTable)

	self.lastColored = colored
	self.editBox:SetText(colored)
end

--- @return string
function ChroMacroEditBox:GetText()
	local colored = self.editBox:GetText()
	local plain = LibChroMacro:StripColors(colored)

	return plain
end

--- @param position integer
function ChroMacroEditBox:SetCursorPosition(position)
	self.editBox:SetCursorPosition(self:ToColoredPosition(position))
end

--- @return integer
function ChroMacroEditBox:GetCursorPosition()
	local _, cursor = LibChroMacro:StripColors(self.editBox:GetText(), self.editBox:GetCursorPosition())
	return cursor --[[@as integer]]
end

--- @param from integer?
--- @param to integer?
function ChroMacroEditBox:HighlightText(from, to)
	if from == nil and to == nil then
		self.editBox:HighlightText()
		return
	end

	from = from or 0
	to = to or 0

	if to < from then
		to = from
	end

	local coloredFrom = self:ToColoredPosition(from)
	local coloredTo = self:ToColoredPosition(to)

	self.editBox:HighlightText(coloredFrom, coloredTo)
end

--- @param colorTable LibChroMacro.ColorTable?
function ChroMacroEditBox:SetColorTable(colorTable)
	self.colorTable = colorTable or LibChroMacro:GetDefaultColorTable()
end

--- @param color ColorMixin
function ChroMacroEditBox:SetLabelColor(color)
	self.label:SetTextColor(color:GetRGBA())
end

--- @protected
--- @param position integer
--- @return integer
function ChroMacroEditBox:ToColoredPosition(position)
	if position == nil or position < 0 then
		return position or 0
	end

	local text = self:GetText()
	local _, cursor = LibChroMacro:Colorize(text, self.colorTable, position)

	return cursor --[[@as integer]]
end

--- @protected
--- @param frame Button&{ obj: ChroMacroEditBox }
function ChroMacroEditBox.Button_OnClick(frame)
	local self = frame.obj

	self.editBox:ClearFocus()
	if not self:Fire("OnEnterPressed", self:GetText()) then
		self.button:Disable()
	end
end

--- @protected
--- @param frame EditBox&{ obj: ChroMacroEditBox }
--- @param userInput boolean
function ChroMacroEditBox.EditBox_OnTextChanged(frame, userInput)
	if not userInput then
		return
	end

	local self = frame.obj

	self:Fire("OnTextChanged", self:GetText())
	self.button:Enable()
	self:Update(false)
end

--- @private
function ChroMacroEditBox.NewColoredMacroEditBox()
	--- @class ChroMacroEditBox
	local widget = AceGUI:Create("MultiLineEditBox")
	widget.type = Type

	widget.button:SetScript("OnClick", ChroMacroEditBox.Button_OnClick)
	widget.editBox:SetScript("OnTextChanged", ChroMacroEditBox.EditBox_OnTextChanged)

	--- @private
	widget.BaseOnAcquire = widget.OnAcquire

	for method, func in pairs(ChroMacroEditBox) do
		if method ~= "NewColoredMacroEditBox" then
			widget[method] = func
		end
	end

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, ChroMacroEditBox.NewColoredMacroEditBox, Version)
