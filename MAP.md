# MojoGUI MAP

Wayfinding for a cold start. This file is "where does X live". For the patterns
and compiler quirks, see `mojo-gui/docs/CONVENTIONS.md` (read it once — it saves
hours of build-fail rounds).

MojoGUI is a native, integer-coordinate, retained-mode GUI toolkit written in
Mojo. It renders through a small C backend (`librendering_with_fonts.so`) that
exposes integer draw primitives and mouse/key polling; everything above that —
widgets, layout, charts, docking — is pure Mojo.

## 1. Entry points

- **Render core:** `mojo-gui/mojo_src/rendering_int.mojo` —
  `struct RenderingContextInt`. The only drawing surface: `set_color`,
  `draw_(filled_)rectangle`, `draw_line`, `draw_(filled_)circle`, `draw_text`,
  `get_text_width` / `get_text_height`, plus input polling (`get_mouse_x/y`,
  `get_mouse_button_state`, `get_key_state`, `poll_events`, `should_close_window`)
  and the frame/window lifecycle (`initialize`, `load_default_font`,
  `frame_begin`, `frame_end`, `cleanup`). All coordinates and colors are
  `Int32`. Also defines the value helpers `ColorInt`, `PointInt`, `SizeInt`,
  `RectInt`.
- **Widget base types:** `mojo-gui/mojo_src/widget_int.mojo` — `MouseEventInt`,
  `KeyEventInt`, and the `BaseWidgetInt` helper fields. Widgets **compose** these
  (they do not inherit — see CONVENTIONS.md).
- **A complete worked example:** `mojo-gui/mojo_src/widgets/node_graph_int.mojo`
  is the reference template for a composed widget with pan/zoom, drag, grid, and
  a `create_*` factory. Copy its shape when starting a new widget.
- **Native C backend:** `mojo-gui/c_src/librendering_with_fonts.so` — loaded by
  `RenderingContextInt` at `./c_src/librendering_with_fonts.so` (relative to the
  run directory). Demos pass this path explicitly.

## 2. Layout

### Core (`mojo-gui/mojo_src/`)

| Path | Purpose |
|---|---|
| `rendering_int.mojo` | Integer render context + `ColorInt`/`PointInt`/`SizeInt`/`RectInt`. The drawing surface every widget uses. |
| `widget_int.mojo` | `MouseEventInt`, `KeyEventInt`, `BaseWidgetInt` fields. Widget method conventions. |
| `rendering.mojo`, `widget.mojo` | Float-coordinate predecessors; the `_int` surfaces are the live integer path. |
| `orchestration.mojo` | App-level wiring helpers. |
| `theme_system.mojo`, `theme_state_integration.mojo` | App-wide theming/state. |
| `widgets/` | All widgets — standalone `*_int.mojo` files plus the composite packages below. |

### Widget packages (`mojo-gui/mojo_src/widgets/`)

Each package is a self-contained subsystem. `model.mojo` is always the data
foundation; the other files build on it. Reach core helpers with three dots
(`from ...rendering_int import ...`); siblings with one (`from .model import ...`).

| Package | File | Purpose |
|---|---|---|
| **chart/** | `model.mojo` | Data foundation: `Bar`/`BarData`, `Symbol`, `Timeframe`, `ChartType` (20 types + category). |
| | `scales.mojo` | Price/time scales, auto-fit, value formatters. |
| | `transforms.mojo` | Bar transforms: renko, kagi, line-break, point-and-figure, range bars, Heikin-Ashi. |
| | `engine.mojo` | `ChartInt` widget — pan/zoom, hit-test, crosshair, grid, axes; builds a render view and dispatches to renderers. Factory `create_chart_int(x,y,w,h)`. |
| | `renderers.mojo` | One draw routine per `ChartType` (candles, OHLC, line, area, heikin, renko, …). |
| | `studies.mojo` | Indicator registry + starter set (SMA/EMA/RSI/MACD/Bollinger). |
| | `drawings.mojo` | Drawing-tool registry (trend line, horizontal line, rectangle, Fibonacci) with begin/drag/commit + hit-test. |
| | `theme.mojo` | `ChartTheme` (`ColorInt` palette) + presets `dark/light/midnight/classic/high_contrast`. |
| | `config.mojo` | `ChartConfig` + `CrosshairConfig`; price-scale and crosshair enums. |
| | `builder.mojo` | `ChartBuilder` fluent API → configured `ChartInt`. |
| | `mathx.mojo` | Pure-Mojo transcendentals (`csin/ccos/ctan/cln/clog10/cexp`) — the libm-free math used across the package. |
| **dock/** | `model.mojo` | Docking layout tree: `DockTab`, `LeafNode`, `SplitNode`, `Node`, binary-heap `Tree`, `DockState`; split/merge/active-tab ops. |
| | `style.mojo` | `DockStyle` (`ColorInt` palette + sizes) + presets `dark/light`. |
| | `area.mojo` | `DockAreaInt` widget — recursive layout, tab strips, splitters, drag-to-dock, and the host content-rect API. Factory `create_dock_area_int(x,y,w,h)`. |
| **dnd/** | `dnd.mojo` | Drag-to-reorder list: `DndItem`, `DragDropResponse`, `DndListInt` (rows, drag tracking, reorder on drop). Factory `create_dnd_list_int(x,y,w,h)`. |

### Standalone widgets (`mojo-gui/mojo_src/widgets/*_int.mojo`)

~34 single-file widgets, each a composed `*Int` struct with a `create_*` factory:
buttons, checkbox, combobox, dropdown, slider, spinbox, progressbar, scrollbar,
textlabel, textedit, listbox, listview, treeview, tabcontrol, toolbar, statusbar,
menu, contextmenu, navbar, breadcrumb, searchbox, dialog, filedialog,
colorpicker, datetimepicker, accordion, container, dockpanel, icon, columnheader,
source_editor, node_graph, advanced_widgets.

## 3. Demos — build & run

All demos live in `mojo-gui/` (repo-relative root) and open a window via the C
backend. Run from the repo root:

```
pixi run mojo mojo-gui/<demo>.mojo            # run (opens a window)
pixi run mojo build mojo-gui/<demo>.mojo -o /tmp/x   # compile-only check
```

The backend library is loaded from `./c_src/librendering_with_fonts.so`; run
from a directory where that relative path resolves.

| Demo | Shows |
|---|---|
| `chart_demo.mojo` | A dark-themed `ChartInt` built via `ChartBuilder` over synthetic OHLCV; SPACE/BACKSPACE cycle chart types. |
| `chart_all_demo.mojo` | Broader chart-type / feature showcase. |
| `dock_demo.mojo` | A `DockAreaInt` with several tabs across split leaves; drag tabs to dock/split, drag splitters to resize; host draws each leaf body. |
| `dnd_demo.mojo` | A `DndListInt` of labeled items; drag a row to reorder; header shows the live order and last move. |
| `node_graph_demo.mojo` | Node-graph editor (drag nodes, bezier links) — the template demo. |

Other demos in `mojo-gui/` exercise the standalone widgets (`all_widgets_demo`,
`menu_demo`, `treeview_listview_demo`, `ttf_font_demo`, …).

## 4. Conventions cheatsheet

Full detail in `mojo-gui/docs/CONVENTIONS.md`. The one-liners:

- `out self` (init) · `mut self` (mutators) · `self` (read-only). **No `inout`.**
- `comptime` for constants/aliases. **No `alias`.**
- Owned arg = `var x: T`; move with `^`. List-owning returns use `^` (`return x^`).
- List-stored structs `(ImplicitlyCopyable, Movable)`; List-owning structs
  `(Copyable, Movable)` + explicit `.copy()`. `ColorInt/PointInt/SizeInt/RectInt`
  are `(ImplicitlyCopyable, Movable)`.
- **No struct inheritance** — compose `x/y/width/height/visible` and implement
  the widget methods directly.
- Multi-value return = `Tuple[A,B](a,b)`. A bare `(a,b)` is a hard error.
- **No libm** (`cos/sin/tan/log/log10/exp`) — use `chart/mathx.mojo`
  (`csin/ccos/ctan/cln/clog10/cexp`). `floor/ceil/sqrt/inf` are fine.
- Imports: inside a package `from .model import …`; reach core with **three
  dots** `from ...rendering_int import …`; root demos use absolute
  `from mojo_src.widgets.<pkg>.<mod> import …`. Keep the empty `__init__.mojo`
  markers.
- Verify with `pixi run mojo build … -o /tmp/x` (compile-only); a package file
  can't build standalone — drive it from a root harness/demo that calls its
  methods. Check `nm -u` shows no libm symbols.

## 5. Where the rest of the docs are

- `mojo-gui/docs/CONVENTIONS.md` — patterns, naming, copyability, imports,
  build/verify, gotchas (the companion to this file).
- Each widget package's `model.mojo` is the readable data foundation — start
  there to understand a package, then read its `builder`/`engine`/`area`.
- `mojo-gui/README.md` and the root `*_REPORT.md` / `QUICK_REFERENCE.md` files
  hold older narrative notes.
