# LibChroMacro

LibChroMacro is a library for World of Warcraft that can add syntax highlighting to edit boxes containing macros.

## Getting started

### Dependencies

* [LibStub](https://www.wowace.com/projects/libstub)

### Embedding

```yaml
externals:
  Libs/LibStub: https://repos.curseforge.com/wow/libstub/trunk
  Libs/LibChroMacro:
    url: https://github.com/Snakybo/LibChroMacro

move-folders:
  <ADDON>/Libs/LibChroMacro/LibChroMacro: <ADDON>/Libs/LibChroMacro
```

Replace `<ADDON>` for your addon name, and simply add the libraries to your TOC file.

### Usage

```lua
local LibChroMacro = LibStub("LibChroMacro")
local colored = LibChroMacro:Colorize("#showtooltip\n/cast [@mouseover,help] Flash Heal")
```

It's also possible to specify a custom color table as second argument for `Colorize`.

### Editbox

The library ships with an AceGUI-3.0 edit box template, which automatically adds syntax highlighting.

```lua
local widget = AceGUI:Create("ChroMacroEditBox")
widget:SetText(text)
widget:SetNumLines(8)
```

The `SetText` and `GetText` methods both support plaintext strings, `SetText` will color it automatically, and `GetText` will strip color codes, returning a plaintext string.

## API

See [API.md](API.md) for the full API reference.
