# LibMacroSyntaxHighlight-1.0

A library to add syntax highlighting to World of Warcraft macros.

## Usage

```lua
local LibMacroSyntaxHighlight = LibStub("LibMacroSyntaxHighlight-1.0")
local colored = LibMacroSyntaxHighlight:Colorize("#showtooltip\n/cast [@mouseover,help] Flash Heal")
```

It's also possible to specify a custom color table as second argument for `Colorize`.

## Editbox

The library ships with an AceGUI-3.0 edit box template, which automatically adds syntax highlighting.

```lua
local widget = AceGUI:Create("ColoredMacroEditBox")
widget:SetText(text)
widget:SetNumLines(8)
```

The `SetText` and `GetText` methods both support plaintext strings, `SetText` will color it automatically, and `GetText` will strip color codes, returning a plaintext string.
