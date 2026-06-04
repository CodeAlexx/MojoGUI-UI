# MojoGUI conventions and gotchas

> The patterns, naming rules, and compiler quirks that take three build-fail
> rounds to rediscover each session. Read once, save hours later.
>
> Verified against the Mojo 0.26.2 nightly the repo builds with. When the
> compiler disagrees with anything here, the compiler wins — update this file.

---

## Self / argument conventions

| Use | When | Example |
|---|---|---|
| `out self` | Constructors (`__init__`) | `fn __init__(out self, x: Int32): ...` |
| `mut self` | Methods that mutate the struct | `fn set_active(mut self, i: Int): ...` |
| `self` | Read-only methods | `fn len(self) -> Int: ...` |
| `var x: T` | An **owned** argument the callee takes over | `fn set_bars(mut self, var bars: List[Bar])` |

- **`inout self` is a hard error** on this nightly. Never write it. Old code
  that still has `inout` will not build — convert it to `out`/`mut`/`self`.
- Move an owned value with the transfer operator `^`: `self.bars = bars^`.
- Compile-time constants and type aliases use **`comptime`**, never `alias`:
  `comptime TAB_HEIGHT: Int32 = 24`. `alias` is a hard error.

---

## Copyability — pick the right trait set

Every value type must declare how it copies/moves. The rule depends on whether
the struct *owns* a heap collection:

| Struct shape | Derive | Notes |
|---|---|---|
| Small POD, stored in a `List` (e.g. an item, a node, a split) | `(ImplicitlyCopyable, Movable)` | Copies are implicit and cheap. |
| Owns a `List` (or another non-implicitly-copyable field) | `(Copyable, Movable)` | Copies must be **explicit**. |
| The 4-int render helpers `ColorInt` / `PointInt` / `SizeInt` / `RectInt` | `(ImplicitlyCopyable, Movable)` | Plain 4×`Int32` PODs; pass by value freely. |

- A struct that owns a `List` is **not** implicitly copyable. `return my_list`
  or `return my_struct` (when it owns a List) is a **compile error**:
  `value of type 'X' cannot be implicitly copied`.
  - To return it, **transfer**: `return my_list^`.
  - To duplicate it, **copy explicitly**: `var b = a.copy()` then use `b`.
- Passing an owned List/struct into a `var`-argument method consumes it — use
  `^` at the call site (`area.set_state(state^)`), or `.copy()` if you still
  need it afterwards (`chart.set_bars(bars.copy())`).
- If a struct stores a `ColorInt` (or any value type) **by value**, that value
  type must itself be at least `Movable` — otherwise the owning struct can't
  synthesize its own copy/move. (This is why the render helpers carry the
  trait set above: a widget that holds a `ColorInt` field depends on it.)

---

## No struct inheritance — compose instead

`struct MyWidget(BaseWidgetInt)` is a **hard error**. Mojo structs do not
inherit. Widgets **compose**: declare your own bounds fields and implement the
widget methods directly.

```mojo
struct MyWidgetInt(Copyable, Movable):
    var x: Int32
    var y: Int32
    var width: Int32
    var height: Int32
    var visible: Bool
    # ... widget-specific state ...

    fn __init__(out self, x: Int32, y: Int32, width: Int32, height: Int32):
        self.x = x; self.y = y; self.width = width; self.height = height
        self.visible = True

    fn handle_mouse_event(mut self, e: MouseEventInt) -> Bool: ...
    fn render(self, ctx: RenderingContextInt): ...
```

Match the method names the rest of the codebase uses
(`handle_mouse_event` / `handle_key_event` / `render` / `update`) so a widget
drops into any host loop. There is no base class to override — the "interface"
is the set of method names, by convention.

---

## Multi-value returns — `Tuple[...]`, never a bare literal

A bare tuple literal `return (a, b)` is a **hard error**. Use the explicit
`Tuple` constructor with its element types:

```mojo
fn split(mut self, ...) -> Tuple[Int, Int]:
    return Tuple[Int, Int](parent_index, new_leaf_index)
```

Unpack at the call site with indexing:

```mojo
var r = tree.split_right(root, 0.6, tabs^)   # Tuple[Int, Int]
var new_leaf = r[1]
```

---

## No libm — use the pure-Mojo `mathx` helpers

**Never `from math import cos / sin / tan / log10 / log / exp`** in any code
that ends up in a windowed (FFI) demo. The optimizer fuses `cos`+`sin` into a
single `sincos@GLIBC` call and pulls `log10@GLIBC` / `exp@GLIBC`; those symbols
fail to **link** against the rendering backend and the build dies with
undefined references (visible via `nm -u <bin>`).

Use the pure-Mojo transcendentals in `mojo_src/widgets/chart/mathx.mojo`
instead — they compute the same values with no libm dependency:

| Need | Use (from `mathx`) |
|---|---|
| sine | `csin(x)` |
| cosine | `ccos(x)` |
| tangent | `ctan(x)` |
| natural log | `cln(x)` |
| base-10 log | `clog10(x)` |
| exp | `cexp(x)` |

Import within a sibling package with `from ..chart.mathx import csin, ccos`
(see the import rules below for the dot count).

**Safe to import from `math`:** `floor`, `ceil`, `sqrt`, `inf`. These do not
pull a fused libm symbol and link fine. (`abs`, `min`, `max` are builtins — no
import needed.)

---

## Package imports — dot counts that actually resolve

The widget packages live two directories below the core
(`mojo_src/widgets/<pkg>/`), so the dot count to reach shared modules differs
from a plain `widgets/` file.

| From | Import | Resolves to |
|---|---|---|
| A file **inside** a package (`widgets/chart/engine.mojo`) | `from .model import Bar` | sibling `widgets/chart/model.mojo` |
| A package file → core helpers | `from ...rendering_int import RenderingContextInt, ColorInt, RectInt` | `mojo_src/rendering_int.mojo` (THREE dots) |
| A package file → widget base types | `from ...widget_int import MouseEventInt, KeyEventInt` | `mojo_src/widget_int.mojo` (THREE dots) |
| A package file → a sibling package | `from ..chart.mathx import csin` | `widgets/chart/mathx.mojo` (TWO dots) |
| A **root** demo (`mojo-gui/chart_demo.mojo`) | `from mojo_src.widgets.chart.builder import ChartBuilder` | absolute path |

- **Two dots** = up one level (to `widgets/`); **three dots** = up two levels
  (to `mojo_src/`). A package file using `..rendering_int` (two dots) fails with
  `unable to locate module 'rendering_int'` because that resolves to
  `widgets/rendering_int`, which doesn't exist. It needs three.
- Empty `__init__.mojo` markers in `mojo_src/`, `mojo_src/widgets/`, and each
  package dir are what make the dirs importable. **Don't delete them.**

---

## Build & verify (compile-only; never open a window in CI)

The rendering backend owns a single GPU window. **Compile, don't run** — a run
opens a window and contends for the display.

- Build a demo (and everything it imports) from the **repo root**:
  ```
  pixi run mojo build mojo-gui/<demo>.mojo -o /tmp/<name>_check
  ```
  `EXIT 0` = the whole import graph type-checked and linked. The `pixi` project
  manifest is at the repo root, so the path is always `mojo-gui/<demo>.mojo`
  regardless of your shell's working directory.
- After a build, sanity-check the link surface: `nm -u /tmp/<name>_check` must
  show **zero** `sincos` / `log10` / `exp` GLIBC symbols. Any → a libm import
  sneaked in; replace it with a `mathx` helper.
- **A package file with relative imports cannot be built standalone.**
  `pixi run mojo build mojo-gui/mojo_src/widgets/chart/engine.mojo` fails with
  `cannot import relative to a top-level package`. That is expected, not a bug
  in the file. Verify package internals through a **root harness** with
  absolute imports.
- **Importing a module only elaborates the methods that are actually called.**
  A harness that merely imports a type will miss latent errors (a missing `^`
  on a List move, a bad trait bound) inside methods it never invokes. A
  thorough harness (or a demo) must **construct the type and call its key
  methods** — set data, set each enum variant, drive the render path — so every
  method is elaborated and any latent move/copy error surfaces.

---

## The retained content-rect pattern (layout widgets)

Layout/container widgets (the docking area is the canonical example) own
**layout and interaction** but do **not** draw their children's content. There
is no immediate-mode `ui()` callback. Instead:

1. The widget computes a rect for each visible region and tracks interaction
   (tab clicks, splitter drags, drag-and-drop).
2. After `layout()` / `render()`, the **host** queries the widget for each
   region's body `RectInt` and its active item `id`, then draws the content
   itself with those rects.

A layout widget therefore exposes a small content API — counts, a body-rect
accessor, and an active-id accessor — and the host loop fills each body. This
keeps the widget generic (it knows nothing about what lives inside a panel) and
keeps drawing in the host where the data lives.

---

## Quick self-check before sending a widget/demo

- [ ] No `inout`, no `alias`, no bare `(a, b)` returns.
- [ ] Owned args declared `var`, moved with `^`; List-owning returns use `^`.
- [ ] List-stored structs `(ImplicitlyCopyable, Movable)`; List-owning structs
      `(Copyable, Movable)` with explicit `.copy()` where duplicated.
- [ ] No `from math import cos/sin/tan/log/log10/exp` — `mathx` helpers instead.
- [ ] Package files reach core with `...` (three dots); root demos use absolute
      `from mojo_src.widgets...`.
- [ ] `pixi run mojo build mojo-gui/<demo>.mojo -o /tmp/x` is `EXIT 0` and
      `nm -u` shows no libm symbols.
