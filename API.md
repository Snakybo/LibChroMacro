# LibChroMacro API

```lua
local LibChroMacro = LibStub("LibChroMacro")
```

* All functions are called with `:` syntax.

## Contents

* [Types](#types)
* [Colorizing](#colorizing)
* [Tokenizing](#tokenizing)
* [Edit box](#edit-box)

## Types

### LibChroMacro.TokenType

An enum of all token types the tokenizer can produce, available as `LibChroMacro.TokenType`.

| Value           | Description                                                           | Default color |
| --------------- | --------------------------------------------------------------------- | ------------- |
| `NUMBER`        | A numeric value inside conditions, e.g. the `1` in `[mod:1]`.         | `ffb5cea8`    |
| `WHITESPACE`    | One or more consecutive spaces or tabs.                               |               |
| `LINEBREAK`     | A single `\n` or `\r` character.                                      |               |
| `SEMICOLON`     | A `;` separating clauses.                                             | `ffdcdcaa`    |
| `COLON`         | A `:` inside conditions.                                              | `ffffffff`    |
| `LEFT_BRACKET`  | A `[` opening a condition block.                                      | `ffffffff`    |
| `RIGHT_BRACKET` | A `]` closing a condition block.                                      | `ffffffff`    |
| `COMMA`         | A `,` separating conditions or arguments.                             | `ffffffff`    |
| `SLASH`         | A `/` inside conditions, e.g. in `[mod:shift/ctrl]`.                  | `ffffffff`    |
| `SPELL_NAME`    | A command argument, such as a spell or item name.                     | `ffce9178`    |
| `SLASH_COMMAND` | A slash command at the start of a line, e.g. `/cast`.                 | `ffdcdcaa`    |
| `CONDITION`     | A condition inside a condition block, e.g. `help` or `mod`.           | `ff9cdcfe`    |
| `TARGET_UNIT`   | A target unit, e.g. `@mouseover` or the `focus` in `target=focus`.    | `ff4ec9b0`    |
| `META`          | A meta command at the start of a line, e.g. `#showtooltip`.           | `ffffffff`    |
| `EQUALS`        | A `=` inside conditions, e.g. in `target=focus`.                      | `ffffffff`    |
| `UNKNOWN`       | Any text on a line that does not start with a slash or meta command.  |               |

### LibChroMacro.ColorTable

```lua
{ [LibChroMacro.TokenType]: string }
```

A table mapping a [`LibChroMacro.TokenType`](#libchromacrotokentype) to an `AARRGGBB` color string. Token types without a color are left uncolored.

### LibChroMacro.Token

| Field  | Type                                               | Description                                                 |
| ------ | -------------------------------------------------- | ----------------------------------------------------------- |
| `str`  | `string`                                           | The raw text of the token.                                  |
| `type` | [`LibChroMacro.TokenType`](#libchromacrotokentype) | The type of the token.                                      |
| `from` | `integer`                                          | The 1-based index of the first byte of the token.           |
| `to`   | `integer`                                          | The 1-based index of the last byte of the token, inclusive. |

## Colorizing

### Colorize

```lua
LibChroMacro:Colorize(text: string, colorTable?: LibChroMacro.ColorTable, cursor?: integer): string, integer?
```

Colorize a plaintext macro string, using the given [color table](#libchromacrocolortable), or the [default color table](#getdefaultcolortable) if none is provided.

Consecutive tokens that share the same color are grouped into a single color escape sequence. Uncolored whitespace is merged into the preceding group.

If `cursor` is provided, it is clamped to the length of `text`, and the second return value is the corresponding cursor position in the colored string. Otherwise the second return value is `nil`.

#### Example

```lua
local LibChroMacro = LibStub("LibChroMacro")
local colored = LibChroMacro:Colorize("#showtooltip\n/cast [@mouseover,help] Flash Heal")
```

Using a custom color table, and mapping a cursor position:

```lua
local LibChroMacro = LibStub("LibChroMacro")

local colorTable = LibChroMacro:GetDefaultColorTable()
colorTable[LibChroMacro.TokenType.SPELL_NAME] = "ff00ff00"

local colored, cursor = LibChroMacro:Colorize("/cast Flash Heal", colorTable, 6)
```

### StripColors

```lua
LibChroMacro:StripColors(text: string, cursor?: integer): string, integer?
```

Strip all color escape sequences (`|cAARRGGBB` and `|r`) from a string. Escaped pipes (`||`) are preserved, so `||cffffffff` is not treated as a color code.

If `cursor` is provided, the second return value is the corresponding cursor position in the stripped string. Otherwise the second return value is `nil`.

This is the inverse of [`Colorize`](#colorize).

#### Example

```lua
local LibChroMacro = LibStub("LibChroMacro")
local colored = LibChroMacro:Colorize("/cast Flash Heal")
local plain = LibChroMacro:StripColors(colored)
print(plain) -- /cast Flash Heal
```

### GetDefaultColorTable

```lua
LibChroMacro:GetDefaultColorTable(): LibChroMacro.ColorTable
```

Get a copy of the default [color table](#libchromacrocolortable). See [`LibChroMacro.TokenType`](#libchromacrotokentype) for the default colors.

This is useful as a starting point for a custom color table.

#### Example

```lua
local LibChroMacro = LibStub("LibChroMacro")
local colorTable = LibChroMacro:GetDefaultColorTable()
colorTable[LibChroMacro.TokenType.CONDITION] = "ffff8000"
```

## Tokenizing

### Tokenize

```lua
LibChroMacro:Tokenize(text: string): LibChroMacro.Token[]
```

Convert a plaintext macro string into a list of [tokens](#libchromacrotoken), in order of appearance.

This is used internally by [`Colorize`](#colorize) and is generally not needed, but it can be helpful for debugging.

#### Example

```lua
local LibChroMacro = LibStub("LibChroMacro")
for _, token in ipairs(LibChroMacro:Tokenize("/cast [mod:shift] Flash Heal")) do
	print(token.type, token.from, token.to, token.str)
end
```

## Edit box

The library ships with an AceGUI-3.0 widget, `ChroMacroEditBox`, which applies syntax highlighting as the user types. The widget is only registered if AceGUI-3.0 is loaded before LibChroMacro.

It extends AceGUI's `MultiLineEditBox`, so all of its methods and callbacks are available. The methods below are added or overridden to work with plaintext, so you never have to deal with color escape sequences yourself.

On acquire, the widget uses the [default color table](#getdefaultcolortable), its max letters is set to `255`, and its label color is set to `NORMAL_FONT_COLOR`.

```lua
local AceGUI = LibStub("AceGUI-3.0")
local widget = AceGUI:Create("ChroMacroEditBox")
```

### Callbacks

| Callback         | Arguments      | Description                                                              |
| ---------------- | -------------- | ------------------------------------------------------------------------ |
| `OnTextChanged`  | `text: string` | Fired when the user changes the text. `text` is the plaintext string.    |
| `OnEnterPressed` | `text: string` | Fired when the accept button is clicked. `text` is the plaintext string. |

### SetText

```lua
ChroMacroEditBox:SetText(text: string)
```

Set the text of the edit box. The text is a plaintext string, and is colorized automatically.

#### Example

```lua
widget:SetText("#showtooltip\n/cast [@mouseover,help] Flash Heal")
```

### GetText

```lua
ChroMacroEditBox:GetText(): string
```

Get the text of the edit box as a plaintext string, with all color escape sequences stripped.

#### Example

```lua
local text = widget:GetText()
```

### SetCursorPosition

```lua
ChroMacroEditBox:SetCursorPosition(position: integer)
```

Set the cursor position, relative to the plaintext string.

#### Example

```lua
widget:SetCursorPosition(#widget:GetText())
```

### GetCursorPosition

```lua
ChroMacroEditBox:GetCursorPosition(): integer
```

Get the cursor position, relative to the plaintext string.

#### Example

```lua
local position = widget:GetCursorPosition()
```

### HighlightText

```lua
ChroMacroEditBox:HighlightText(from?: integer, to?: integer)
```

Highlight a range of text, relative to the plaintext string. If both `from` and `to` are omitted, all text is highlighted.

#### Example

```lua
widget:HighlightText(0, 5)
```

### SetColorTable

```lua
ChroMacroEditBox:SetColorTable(colorTable?: LibChroMacro.ColorTable)
```

Set the [color table](#libchromacrocolortable) used to colorize the text. Passing `nil` restores the [default color table](#getdefaultcolortable).

The new colors are applied the next time the text is set or changed.

#### Example

```lua
local colorTable = LibChroMacro:GetDefaultColorTable()
colorTable[LibChroMacro.TokenType.SPELL_NAME] = "ff00ff00"

widget:SetColorTable(colorTable)
widget:SetText(widget:GetText())
```

### SetLabelColor

```lua
ChroMacroEditBox:SetLabelColor(color: ColorMixin)
```

Set the color of the label.

#### Example

```lua
widget:SetLabelColor(HIGHLIGHT_FONT_COLOR)
```

### Update

```lua
ChroMacroEditBox:Update(immediate?: boolean)
```

Re-colorize the current text, preserving the cursor position. This is called automatically when the user changes the text, so it generally isn't needed.

If `immediate` is `false`, the update is debounced and runs after a short delay. Otherwise it runs immediately.

#### Example

```lua
widget:Update()
```
