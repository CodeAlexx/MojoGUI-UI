# Widget 0.26 migration recipe (internal)

Every `mojo_src/widgets/*_int.mojo` uses pre-0.26 syntax that is a HARD ERROR on
the current Mojo nightly (`inout self`, `struct X(BaseWidgetInt)` struct
inheritance, `self.super().__init__`). Migrate IN PLACE, preserving behavior.
This is a SYNTAX migration, not a redesign — do not change widget logic.

Already-migrated deps you can rely on: `rendering_int`, `widget_int`,
`theme_system`, `theme_state_integration`. `widget_constants` is `alias`-only
(warnings, compiles). `widget_events_int` must be migrated (foundation).

## Per-file steps

### 1. `inout` → `out` / `mut`
- `fn __init__(inout self, …)` → `fn __init__(out self, …)`
- mutating method `fn foo(inout self, …)` → `fn foo(mut self, …)`
- a method marked `inout self` that doesn't mutate → `self`
Grep the file for `inout`; replace every occurrence (default non-init → `mut self`).

### 2. `alias` → `comptime`
`alias NAME = VALUE` → `comptime NAME = VALUE` (module-level constants).

### 3. struct inheritance → inline the base (the big one)
`struct XInt(BaseWidgetInt):` is a HARD ERROR. Change to `struct XInt(WidgetInt):`
(conforming to the *trait* is allowed) and INLINE BaseWidgetInt:

- Add these six fields to the struct (skip any already declared):
```mojo
    var bounds: RectInt
    var visible: Bool
    var enabled: Bool
    var background_color: ColorInt
    var border_color: ColorInt
    var border_width: Int32
```
- Replace `self.super().__init__(x, y, width, height)` in `__init__` with:
```mojo
    self.bounds = RectInt(x, y, width, height)
    self.visible = True
    self.enabled = True
    self.background_color = ColorInt(230, 230, 230, 255)
    self.border_color = ColorInt(128, 128, 128, 255)
    self.border_width = 1
```
  Keep any overrides the widget already does right after (e.g. `self.background_color = theme.widget_background`).
- Add the inherited methods (copy verbatim — needed for WidgetInt conformance + callers):
```mojo
    fn get_bounds(self) -> RectInt: return self.bounds
    fn set_bounds(mut self, bounds: RectInt): self.bounds = bounds
    fn is_visible(self) -> Bool: return self.visible
    fn set_visible(mut self, visible: Bool): self.visible = visible
    fn is_enabled(self) -> Bool: return self.enabled
    fn set_enabled(mut self, enabled: Bool): self.enabled = enabled
    fn contains_point(self, point: PointInt) -> Bool: return self.bounds.contains(point)
    fn render_background(self, ctx: RenderingContextInt):
        if not self.visible: return
        _ = ctx.set_color(self.background_color.r, self.background_color.g, self.background_color.b, self.background_color.a)
        _ = ctx.draw_filled_rectangle(self.bounds.x, self.bounds.y, self.bounds.width, self.bounds.height)
        if self.border_width > 0:
            _ = ctx.set_color(self.border_color.r, self.border_color.g, self.border_color.b, self.border_color.a)
            _ = ctx.draw_rectangle(self.bounds.x, self.bounds.y, self.bounds.width, self.bounds.height)
```
  WidgetInt also needs `handle_mouse_event`/`handle_key_event`/`render`/`update` —
  most widgets already define these; if one is missing, add a minimal stub
  (`handle_*`→`return False`, `update`→`pass`).
  NOTE: if conforming to `WidgetInt` causes trouble for a given widget, plain
  `struct XInt:` (no base/trait) also compiles — the goal is a clean build.

### 4. Only as the compiler demands
- List-stored value structs → `(ImplicitlyCopyable, Movable)`; List-owning →
  `(Copyable, Movable)` + explicit `.copy()`/`^`.
- bare multi-return `(a, b)` → `Tuple[A, B](a, b)`.
- NO libm (`math.cos/sin/log10`) — use `from ..chart.mathx import …` if ever needed (rare for widgets).

### 5. Verify (compile-only, from repo ROOT, no GPU)
Relative-import package files can't build standalone. Use a root harness:
```
mojo-gui/_wcheck_<name>.mojo:
    from mojo_src.widgets.<name>_int import <StructName>
    fn main():
        var w = <StructName>(... minimal ctor args ...)
        print(w.get_bounds().width)   # force elaboration
```
`pixi run mojo build mojo-gui/_wcheck_<name>.mojo -o /tmp/w_<name>` → EXIT 0; delete the harness after.

Dependency order: migrate widgets that OTHER widgets import first — `button_int`,
`icon_int`, `scrollbar_int`, `textedit_int`, `searchbox_int` — then the rest.

---

## VERIFIED REFINEMENTS (builder-foundation) — Mojo 0.26.2 nightly

Both foundation files compile clean (root harness → EXIT 0):
`widget_events_int.mojo` and `progressbar_int.mojo` (the template). Gotchas the
batch agents WILL hit, in addition to steps 1–4:

### A. `theme_system.get_theme()` NOW EXISTS — but it's the FLAT palette
The widgets that do `from ..theme_system import get_theme` (button, checkbox,
progressbar, treeview, listview, textlabel, …) reference ~44 flat color fields
like `theme.progress_fill`, `theme.widget_background`, `theme.button_primary`,
`theme.selection_bg`, `theme.error_color`, `theme.checkbox_mark_color`, etc.
Those did NOT exist before — `theme_system.mojo` only had the nested
`Theme.colors.<x>` (`ThemeColor`) palette. I added a flat `WidgetTheme` struct
(all fields are `ColorInt`) plus `fn get_theme() -> WidgetTheme` to
`theme_system.mojo`. So:
- `var theme = get_theme()` returns a `WidgetTheme`; `self.some_color = theme.<field>`
  assigns a `ColorInt` directly — no conversion needed.
- If a widget references a flat field NOT yet in `WidgetTheme`, ADD it to that
  struct's fields + `__init__` (it already covers the 44 names the 6 importing
  widgets use; new ones are cheap to add). Do NOT invent a second `get_theme`.
- The OLD nested `Theme`/`ThemeColors`/`create_dark_theme`/`create_light_theme`
  API is untouched — widgets using `theme.colors.button_normal` style still work.

### B. struct that is returned-by-value or stored needs explicit copy traits
WidgetInt conformance does NOT make a struct copyable/movable. A widget whose
factory fns build-mutate-return it (e.g. `create_loading_bar_int`) must declare
`struct XInt(WidgetInt, Copyable, Movable):` AND the factory must `return bar^`
(transfer) after mutating a local — a bare `return bar` errors with
"cannot be implicitly copied". The template `ProgressBarInt` does both.

### C. `str(...)` → `String(...)`
`str()` is gone. `str(self.get_percentage())` → `String(self.get_percentage())`.
Grep each file for `str(` and replace.

### D. mixed Int/Int32 in `min`/`max` and `in [...]`
- `min(255, self.color.r + 30)` fails (Int vs Int32). Use `min(Int32(255), …)`.
- `x in [A, B, C]` where `x: Int32` fails ("`Int32` to `Int`"). Replace the
  list-membership with explicit `or` comparisons:
  `(x == A or x == B or x == C)`.

### E. `String` indexing / `ord(s[0])`
`s[0]` (String `__getitem__`) is gone. Use bytes:
`var c = Int(s.as_bytes()[0])`, then compare against `ord("a")` (note: `ord`
takes a String literal `"a"`, not `'a'`). Cast results back with `Int32(...)`
if the field is `Int32`.

### F. event structs that return `Self` from a builder method
`fn with_modifiers(mut self, …) -> Self: … return self` requires the struct to be
`(ImplicitlyCopyable, Movable)` (a plain `Copyable` still errors on the
`return self`). `MouseEventInt`/`KeyEventInt` etc. in `widget_events_int.mojo`
are now `(ImplicitlyCopyable, Movable)`.

### G. `widget_constants.mojo` warnings are EXPECTED noise
It is still `alias`-based (compiles, ~60 deprecation warnings). Any widget that
`from .widget_constants import *` will surface those warnings in its build —
they are NOT errors and NOT your widget's fault. When checking a build, filter
them: `... 2>&1 | grep -i error | grep -v widget_constants`.

### Template diff shape (what every BaseWidgetInt widget needs)
1. `alias` → `comptime` (module constants).
2. `struct XInt(BaseWidgetInt):` → `struct XInt(WidgetInt, Copyable, Movable):`
   (add `Copyable, Movable` only if it's returned-by-value anywhere — most are).
3. Add the 6 inlined fields (`bounds/visible/enabled/background_color/
   border_color/border_width`) at the top of the struct body.
4. `fn __init__(inout self, …)` → `fn __init__(out self, …)`; replace
   `self.super().__init__(x,y,w,h)` with the 6 field assignments (then keep any
   theme overrides the widget already does).
5. Insert the 8 inlined base methods (`get_bounds/set_bounds/is_visible/
   set_visible/is_enabled/set_enabled/contains_point/render_background`) right
   after `__init__`.
6. Every other `inout self` → `mut self`; `str(`→`String(`; apply D/E as the
   compiler complains.
7. Factory `return bar` after mutation → `return bar^`.
