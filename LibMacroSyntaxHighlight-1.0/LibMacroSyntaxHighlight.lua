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
	error("LibMacroSyntaxHighlight-1.0 requires LibStub")
end

--- @class LibMacroSyntaxHighlight-1.0
local LibMacroSyntaxHighlight = LibStub:NewLibrary("LibMacroSyntaxHighlight-1.0", 2)

--- @class LibMacroSyntaxHighlight-1.0.Token
--- @field public str string
--- @field public type LibMacroSyntaxHighlight-1.0.TokenType
--- @field public from integer
--- @field public to integer

--- @alias LibMacroSyntaxHighlight-1.0.ColorTable { [LibMacroSyntaxHighlight-1.0.TokenType]: string }

--- @class LibMacroSyntaxHighlight-1.0.State
--- @field public inCommand boolean?
--- @field public inConditions boolean?
--- @field public expectUnit boolean?

if LibMacroSyntaxHighlight == nil then
	return
end

--- @enum LibMacroSyntaxHighlight-1.0.TokenType
LibMacroSyntaxHighlight.TokenType = {
	NUMBER = 1,
	WHITESPACE = 2,
	LINEBREAK = 3,
	SEMICOLON = 4,
	COLON = 5,
	LEFT_BRACKET = 6,
	RIGHT_BRACKET = 7,
	COMMA = 8,
	SLASH = 9,
	SPELL_NAME = 10,
	SLASH_COMMAND = 11,
	CONDITION = 12,
	TARGET_UNIT = 13,
	META = 14,
	EQUALS = 15,
	UNKNOWN = 16,
}

local TokenType = LibMacroSyntaxHighlight.TokenType

--- @type LibMacroSyntaxHighlight-1.0.ColorTable
local defaultColorTable = {
	[TokenType.NUMBER] = "ffb5cea8",
	[TokenType.SEMICOLON] = "ffdcdcaa",
	[TokenType.COLON] = "ffffffff",
	[TokenType.LEFT_BRACKET] = "ffffffff",
	[TokenType.RIGHT_BRACKET] = "ffffffff",
	[TokenType.COMMA] = "ffffffff",
	[TokenType.SLASH] = "ffffffff",
	[TokenType.SPELL_NAME] = "ffce9178",
	[TokenType.SLASH_COMMAND] = "ffdcdcaa",
	[TokenType.CONDITION] = "ff9cdcfe",
	[TokenType.TARGET_UNIT] = "ff4ec9b0",
	[TokenType.META] = "ffffffff",
	[TokenType.EQUALS] = "ffffffff",
}

local bytes = {
	LINEBREAK_UNIX = string.byte("\n"),
	LINEBREAK_MAC = string.byte("\r"),
	WHITESPACE = string.byte(" "),
	TAB = string.byte("\t"),
	LEFT_BRACKET = string.byte("["),
	RIGHT_BRACKET = string.byte("]"),
	COMMA = string.byte(","),
	SEMICOLON = string.byte(";"),
	COLON = string.byte(":"),
	SLASH = string.byte("/"),
	EQUALS = string.byte("="),
	AT = string.byte("@"),
	META = string.byte("#"),
	PIPE = string.byte("|"),
	COLOR_START_L = string.byte("c"),
	COLOR_START_U = string.byte("C"),
	COLOR_END_L = string.byte("r"),
	COLOR_END_U = string.byte("R"),
}

local linebreaks = {
	[bytes.LINEBREAK_UNIX] = true,
	[bytes.LINEBREAK_MAC] = true,
}

local whitespace = {
	[bytes.WHITESPACE] = true,
	[bytes.TAB] = true,
}

local wordDelimiters = {
	[bytes.LINEBREAK_UNIX] = true,
	[bytes.LINEBREAK_MAC] = true,
	[bytes.WHITESPACE] = true,
	[bytes.TAB] = true,
	[bytes.LEFT_BRACKET] = true,
	[bytes.RIGHT_BRACKET] = true,
	[bytes.COMMA] = true,
	[bytes.SEMICOLON] = true,
	[bytes.COLON] = true,
	[bytes.SLASH] = true,
	[bytes.EQUALS] = true,
	[bytes.AT] = true,
}

local spellDelimiters = {
	[bytes.LINEBREAK_UNIX] = true,
	[bytes.LINEBREAK_MAC] = true,
	[bytes.LEFT_BRACKET] = true,
	[bytes.RIGHT_BRACKET] = true,
	[bytes.COMMA] = true,
	[bytes.SEMICOLON] = true,
}

--- @param text string
--- @param position integer
--- @return boolean
local function IsStartOfLine(text, position)
	if position == 1 then
		return true
	end

	return linebreaks[string.byte(text, position - 1)] == true
end

--- @param text string
--- @param position integer
--- @param delimiters table<integer, boolean>
--- @return integer
local function ReadUntil(text, position, delimiters)
	repeat
		position = position + 1
		local byte = string.byte(text, position)
	until byte == nil or delimiters[byte]

	return position
end

--- @param text string
--- @param position integer
--- @param set table<integer, boolean>
--- @return integer
local function ReadWhile(text, position, set)
	repeat
		position = position + 1
		local byte = string.byte(text, position)
	until byte == nil or not set[byte]

	return position
end

--- @param text string
--- @param position integer
--- @return integer
local function ReadSpellName(text, position)
	local nextPosition = ReadUntil(text, position, spellDelimiters)

	while nextPosition - 1 > position and whitespace[string.byte(text, nextPosition - 1)] do
		nextPosition = nextPosition - 1
	end

	return nextPosition
end

--- @param text string
--- @param position integer
--- @param state LibMacroSyntaxHighlight-1.0.State
--- @return LibMacroSyntaxHighlight-1.0.TokenType
--- @return integer
local function ReadCondition(text, position, state)
	local byte = string.byte(text, position)

	if byte == bytes.COLON then
		return TokenType.COLON, position + 1
	elseif byte == bytes.SLASH then
		return TokenType.SLASH, position + 1
	elseif byte == bytes.EQUALS then
		state.expectUnit = true
		return TokenType.EQUALS, position + 1
	elseif byte == bytes.AT then
		return TokenType.TARGET_UNIT, ReadUntil(text, position, wordDelimiters)
	end

	local nextPosition = ReadUntil(text, position, wordDelimiters)

	if state.expectUnit then
		state.expectUnit = nil
		return TokenType.TARGET_UNIT, nextPosition
	end

	if string.find(string.sub(text, position, nextPosition - 1), "^%d+$") then
		return TokenType.NUMBER, nextPosition
	end

	return TokenType.CONDITION, nextPosition
end

--- @param text string
--- @param position integer
--- @param state LibMacroSyntaxHighlight-1.0.State
--- @return LibMacroSyntaxHighlight-1.0.TokenType?
--- @return integer?
local function GetNextToken(text, position, state)
	local byte = string.byte(text, position)
	if byte == nil then
		return nil
	end

	if linebreaks[byte] then
		state.inCommand = nil
		state.inConditions = nil
		state.expectUnit = nil
		return TokenType.LINEBREAK, position + 1
	end

	if whitespace[byte] then
		return TokenType.WHITESPACE, ReadWhile(text, position, whitespace)
	end

	if IsStartOfLine(text, position) then
		if byte == bytes.SLASH then
			state.inCommand = true
			return TokenType.SLASH_COMMAND, ReadUntil(text, position, wordDelimiters)
		elseif byte == bytes.META then
			state.inCommand = true
			return TokenType.META, ReadUntil(text, position, wordDelimiters)
		end
	end

	if not state.inCommand then
		return TokenType.UNKNOWN, ReadUntil(text, position, linebreaks)
	end

	if byte == bytes.LEFT_BRACKET then
		state.inConditions = true
		state.expectUnit = nil
		return TokenType.LEFT_BRACKET, position + 1
	elseif byte == bytes.RIGHT_BRACKET then
		state.inConditions = nil
		state.expectUnit = nil
		return TokenType.RIGHT_BRACKET, position + 1
	elseif byte == bytes.COMMA then
		state.expectUnit = nil
		return TokenType.COMMA, position + 1
	elseif byte == bytes.SEMICOLON then
		state.inConditions = nil
		state.expectUnit = nil
		return TokenType.SEMICOLON, position + 1
	end

	if state.inConditions then
		return ReadCondition(text, position, state)
	end

	return TokenType.SPELL_NAME, ReadSpellName(text, position)
end

--- Convert a plaintext string to a list of raw tokens.
---
--- This method is generally not needed, as it's used internally by the library, but for debugging purposes it's helpful.
---
--- @param text string
--- @return LibMacroSyntaxHighlight-1.0.Token[]
function LibMacroSyntaxHighlight:Tokenize(text)
	if type(text) ~= "string" then
		error("bad argument #1 to 'Tokenize', expected string but got " .. type(text), 2)
	end

	--- @type LibMacroSyntaxHighlight-1.0.State
	local state = {}

	--- @type LibMacroSyntaxHighlight-1.0.Token[]
	local result = {}

	local currentPosition = 1

	while true do
		local tokenType, nextPosition = GetNextToken(text, currentPosition, state)
		if tokenType == nil or nextPosition == nil then
			break
		end

		result[#result + 1] = {
			str = string.sub(text, currentPosition, nextPosition - 1),
			type = tokenType,
			from = currentPosition,
			to = nextPosition - 1
		}

		currentPosition = nextPosition
	end

	return result
end

--- Colorize a plaintext string.
---
--- This method accepts a plaintext macro string and applies color escape sequences based on the provided color table, or the default color table if none is
--- provided.
---
--- @param text string
--- @param colorTable LibMacroSyntaxHighlight-1.0.ColorTable?
--- @param cursor integer?
--- @return string colored
--- @return integer? cursor
function LibMacroSyntaxHighlight:Colorize(text, colorTable, cursor)
	if type(text) ~= "string" then
		error("bad argument #1 to 'Colorize', expected string but got " .. type(text), 2)
	end

	if colorTable ~= nil and type(colorTable) ~= "table" then
		error("bad argument #2 to 'Colorize', expected table or nil but got " .. type(colorTable), 2)
	end

	if cursor ~= nil and type(cursor) ~= "number" then
		error("bad argument #3 to 'Colorize', expected number or nil but got " .. type(cursor), 2)
	end

	if cursor ~= nil then
		cursor = math.max(0, math.min(cursor, #text))
	end

	if #text == 0 then
		return text, cursor
	end

	colorTable = colorTable or defaultColorTable

	--- @type string[]
	local result = {}

	--- @type string[]
	local group = {}

	--- @type string?
	local groupColor = nil

	local rawOffset = 0
	local coloredOffset = 0

	--- @type integer?
	local mappedCursor = nil

	local function Flush()
		if #group == 0 then
			return
		end

		local str = table.concat(group)
		local prefix = groupColor ~= nil and "|c" .. groupColor or ""
		local suffix = groupColor ~= nil and "|r" or ""

		if cursor ~= nil and mappedCursor == nil then
			if cursor <= rawOffset then
				mappedCursor = coloredOffset
			elseif cursor < rawOffset + #str then
				mappedCursor = coloredOffset + #prefix + cursor - rawOffset
			end
		end

		result[#result + 1] = prefix .. str .. suffix
		rawOffset = rawOffset + #str
		coloredOffset = coloredOffset + #prefix + #str + #suffix
		group = {}
	end

	for _, token in ipairs(self:Tokenize(text)) do
		local color = colorTable[token.type]

		if color ~= groupColor and not (color == nil and token.type == TokenType.WHITESPACE) then
			Flush()
			groupColor = color
		end

		group[#group + 1] = token.str
	end

	Flush()

	if cursor ~= nil and mappedCursor == nil then
		mappedCursor = coloredOffset
	end

	return table.concat(result), mappedCursor
end

--- Strip all unescaped color code sequences from a string, this does preserve escaped color code sequences.
---
--- Optionally accepts a `cursor` parameter, which indicates the cursor position within the colored text, if specified, this will return the corresponding
--- cursor position in the plaintext string.
---
--- @param text string
--- @param cursor integer?
--- @return string stripped
--- @return integer? cursor
function LibMacroSyntaxHighlight:StripColors(text, cursor)
	if type(text) ~= "string" then
		error("bad argument #1 to 'StripColors', expected string but got " .. type(text), 2)
	end

	if cursor ~= nil and type(cursor) ~= "number" then
		error("bad argument #2 to 'StripColors', expected number or nil but got " .. type(cursor), 2)
	end

	--- @type string[]
	local result = {}

	local position = 1
	local copyFrom = 1
	local removedBeforeCursor = 0

	while true do
		local pipe = string.find(text, "|", position, true)
		if pipe == nil then
			break
		end

		local nextByte = string.byte(text, pipe + 1)
		local codeLength = nil

		if nextByte == bytes.PIPE then
			position = pipe + 2
		elseif (nextByte == bytes.COLOR_START_L or nextByte == bytes.COLOR_START_U) and string.find(text, "^%x%x%x%x%x%x%x%x", pipe + 2) then
			codeLength = 10
		elseif nextByte == bytes.COLOR_END_L or nextByte == bytes.COLOR_END_U then
			codeLength = 2
		else
			position = pipe + 1
		end

		if codeLength ~= nil then
			local codeOffset = pipe - 1

			if cursor ~= nil and cursor > codeOffset then
				removedBeforeCursor = removedBeforeCursor + math.min(codeLength, cursor - codeOffset)
			end

			result[#result + 1] = string.sub(text, copyFrom, pipe - 1)
			position = pipe + codeLength
			copyFrom = position
		end
	end

	result[#result + 1] = string.sub(text, copyFrom)

	return table.concat(result), cursor ~= nil and cursor - removedBeforeCursor or nil
end

--- @return LibMacroSyntaxHighlight-1.0.ColorTable
function LibMacroSyntaxHighlight:GetDefaultColorTable()
	local result = {}

	for k, v in pairs(defaultColorTable) do
		result[k] = v
	end

	return result
end
