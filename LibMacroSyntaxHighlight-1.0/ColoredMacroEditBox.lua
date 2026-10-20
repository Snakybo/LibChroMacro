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

--- @diagnostic disable-next-line: duplicate-doc-alias
--- @alias AceGUIWidgetType
--- | "ColoredMacroEditBox"

local Type, Version = "ColoredMacroEditBox", 1

--- @type AceGUI-3.0
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)

--- @type LibMacroSyntaxHighlight-1.0
local LibMacroSyntaxHighlight = LibStub and LibStub("LibMacroSyntaxHighlight-1.0", true)

if AceGUI == nil or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then
	return
end

if LibMacroSyntaxHighlight == nil then
	return
end

local DEBOUNCE_DURATION = 0.05

--[[-----------------------------------------------------------------------------
Scripts
-------------------------------------------------------------------------------]]

--- @param frame Button
local function Button_OnClick(frame)
	--- @type ColoredMacroEditBox
	--- @diagnostic disable-next-line: undefined-field
	local self = frame.obj

	--- @diagnostic disable-next-line: invisible
	self.editBox:ClearFocus()
	if not self:Fire("OnEnterPressed", self:GetText()) then
		--- @diagnostic disable-next-line: invisible
		self.button:Disable()
	end
end

--- @param frame EditBox
--- @param userInput boolean
local function EditBox_OnTextChanged(frame, userInput)
	if not userInput then
		return
	end

	--- @type ColoredMacroEditBox
	--- @diagnostic disable-next-line: undefined-field
	local self = frame.obj

	self:Fire("OnTextChanged", self:GetText())

	--- @diagnostic disable-next-line: invisible
	self.button:Enable()

	self:Update(false)
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]

--- @class ColoredMacroEditBox : AceGUIMultiLineEditBox
local Widget = {}

function Widget:OnAcquire()
	self:BaseOnAcquire()

	self.colorTable = LibMacroSyntaxHighlight:GetDefaultColorTable() --- @private
	self.debounce = nil --- @private
	self.lastColored = nil --- @private

	self.editBox:SetMaxBytes(0)
	self.editBox:SetCountInvisibleLetters(false)

	self:SetMaxLetters(255)
	self:SetLabelColor(NORMAL_FONT_COLOR)
end

--- @param immediate boolean?
function Widget:Update(immediate)
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

	local text, cursor = LibMacroSyntaxHighlight:StripColors(colored, self.editBox:GetCursorPosition())
	local newColored, newCursor = LibMacroSyntaxHighlight:Colorize(text, self.colorTable, cursor)

	if newColored ~= colored then
		self.lastColored = newColored

		self.editBox:SetText(newColored)
		self.editBox:SetCursorPosition(newCursor --[[@as integer]])
		self.button:Enable()
	end
end

--- @param text string
function Widget:SetText(text)
	local colored = LibMacroSyntaxHighlight:Colorize(text, self.colorTable)

	self.lastColored = colored
	self.editBox:SetText(colored)
end

--- @return string
function Widget:GetText()
	local colored = self.editBox:GetText()
	local plain = LibMacroSyntaxHighlight:StripColors(colored)

	return plain
end

--- @param position integer
function Widget:SetCursorPosition(position)
	self.editBox:SetCursorPosition(self:ToColoredPosition(position))
end

--- @return integer
function Widget:GetCursorPosition()
	local _, cursor = LibMacroSyntaxHighlight:StripColors(self.editBox:GetText(), self.editBox:GetCursorPosition())
	return cursor --[[@as integer]]
end

--- @param from integer?
--- @param to integer?
function Widget:HighlightText(from, to)
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

--- @param colorTable LibMacroSyntaxHighlight-1.0.ColorTable?
function Widget:SetColorTable(colorTable)
	self.colorTable = colorTable or LibMacroSyntaxHighlight:GetDefaultColorTable()
end

--- @param color ColorMixin
function Widget:SetLabelColor(color)
	self.label:SetTextColor(color:GetRGBA())
end

--- @private
--- @param position integer
--- @return integer
function Widget:ToColoredPosition(position)
	if position == nil or position < 0 then
		return position or 0
	end

	local text = self:GetText()
	local _, cursor = LibMacroSyntaxHighlight:Colorize(text, self.colorTable, position)

	return cursor --[[@as integer]]
end

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]

local function Constructor()
	--- @class ColoredMacroEditBox
	local widget = AceGUI:Create("MultiLineEditBox") --[[@as AceGUIMultiLineEditBox]]
	widget.type = Type

	widget.button:SetScript("OnClick", Button_OnClick)
	widget.editBox:SetScript("OnTextChanged", EditBox_OnTextChanged)

	widget.BaseOnAcquire = widget.OnAcquire --- @private

	for method, func in pairs(Widget) do
		widget[method] = func
	end

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
