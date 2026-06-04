# egui-charts → MojoGUI port spec (chart_int addon)

You are porting the Rust crate `egui-charts` (132K LOC, read-only reference at
`/tmp/egui-charts-ref/src/`) into a native MojoGUI widget package at
`/home/alex/MojoGUI-UI/mojo-gui/mojo_src/widgets/chart/`.

This is **phase 1: the working core**. We are NOT porting `ui/`, `ui_kit/`,
`scripting/`, `backtest/`, `icons/`, RON tokens, eframe/wasm glue — those have no
MojoGUI equivalent. Track anything skipped in `PORT_STATUS.md`.

## Ground truth: how MojoGUI works (do not invent APIs)

Rendering FFI (integer coords) is `mojo_src/rendering_int.mojo` →
`struct RenderingContextInt` with ONLY these draw primitives:
- `set_color(r,g,b,a: Int32)`
- `draw_rectangle(x,y,w,h)` / `draw_filled_rectangle(x,y,w,h)`
- `draw_circle(x,y,radius,segments)` / `draw_filled_circle(...)`
- `draw_line(x1,y1,x2,y2,thickness)`
- `draw_text(text,x,y,size)` / `get_text_width(text,size)` / `get_text_height(...)`
- input: `get_mouse_x/y`, `get_mouse_button_state(b)`, `get_key_state(k)`
There is NO native polyline/polygon/gradient/bezier — compose from lines/rects.
Bezier is done by sampling line segments (see `node_graph_int.mojo::_draw_bezier`).

Widget base is `mojo_src/widget_int.mojo`:
- `trait WidgetInt` methods: get_bounds/set_bounds/is_visible/set_visible/
  contains_point/handle_mouse_event/handle_key_event/render/update
- `struct BaseWidgetInt(x,y,width,height,...)`, `struct MouseEventInt`,
  `struct KeyEventInt`, helpers `ColorInt/PointInt/SizeInt/RectInt`.

**Reference template (study it first): `mojo_src/widgets/node_graph_int.mojo`.**
It is a `BaseWidgetInt` with pan/zoom (offset_x/offset_y/scale),
`screen_to_world`/`world_to_screen`, `handle_mouse_event`, `_draw_grid`, and a
`create_node_graph_int(...)` factory. The chart engine mirrors this exactly.

## Syntax convention — MATCH THE COMPILER, NOT A STYLE GUIDE
The existing widgets in THIS repo use `inout self` (21× in node_graph_int.mojo,
zero `mut self`). Mojo 0.26 prefers `mut`/`out`. **Use whatever `pixi run mojo`
accepts.** The bug-fixer owns the final word after compiling. When in doubt,
copy the exact patterns from a file that the demo is documented to run
(`node_graph_int.mojo`, run via `pixi run mojo node_graph_demo.mojo`).

Build/verify command (from `mojo-gui/`): `pixi run mojo <demo>.mojo`.

## File layout (each agent owns its file(s); avoid cross-edits)
```
chart/
  model.mojo        Bar/BarData, Symbol, Timeframe, ChartType(+category), OHLC accessors   [FOUNDATION]
  scales.mojo       PriceScale (normal/log/pct), TimeScale, auto-fit, price/time formatters
  transforms.mojo   renko, kagi, line_break, point_figure, range_bar, heikin_ashi (faithful algos)
  engine.mojo       ChartInt(BaseWidgetInt): pan/zoom, hit-test, crosshair, grid, axes, viewport→price/time map
  renderers.mojo    one draw fn per ChartType (all 20): candles, ohlc bars, hollow, line, area, baseline, step, heikin, renko, kagi, line_break, p&f, high_low, range ...
  studies.mojo      Indicator trait + IndicatorRegistry + SMA, EMA, RSI, MACD, BollingerBands
  drawings.mojo     Drawing trait + registry + TrendLine, HorizontalLine, Rectangle, FibRetracement (+ lifecycle: begin/drag/commit, hit-test)
  theme.mojo        ChartTheme presets: dark/light/midnight/classic/high_contrast (ColorInt fields)
  config.mojo       ChartConfig, CrosshairConfig, axis/grid options
  builder.mojo      ChartBuilder fluent API + TradingChart facade (with_symbol/timeframe/theme/type/...build())
chart_demo.mojo     (in mojo-gui/ root) demo: build sample OHLCV, cycle chart types, run window loop
PORT_STATUS.md      what's ported vs deferred, per egui-charts module
```

## Faithfulness rules
- Port the **algorithms** exactly (renko brick logic, kagi reversal, RSI/EMA
  math, fib levels). Read the real `.rs` file before writing each one.
- Map `f64` prices → keep as `Float64` in model/math; convert to `Int32` pixels
  only at draw time via the scales. Do NOT round prices early.
- Keep Rust names where reasonable (ChartType variants, Indicator names) so the
  port is recognizable.
- Every public type gets a doc comment citing its source `.rs` file.

## Reference source map (read these)
- model:      /tmp/egui-charts-ref/src/model/{bar,chart_type,timeframe,symbol,renko,kagi,line_break,point_figure,range_bar}.rs
- scales:     /tmp/egui-charts-ref/src/scales/{pricescale,timescale_marks,price_formatter,time_formatter}.rs
- chart eng:  /tmp/egui-charts-ref/src/chart/{mod,pan_zoom,builder,state}.rs , chart/coords/*, chart/series/*
- renderers:  /tmp/egui-charts-ref/src/chart/renderers/*
- studies:    /tmp/egui-charts-ref/src/studies/*  (registry + indicator trait)
- drawings:   /tmp/egui-charts-ref/src/drawings/* (tool trait + lifecycle)
- theme:      /tmp/egui-charts-ref/src/theme/*

## Definition of done (phase 1)
`pixi run mojo chart_demo.mojo` compiles and opens a window rendering at least
candlestick + line + area + heikin + renko, with pan/zoom + crosshair, themed.

## VERIFIED CONVENTIONS (from builder-foundation)

These were established by compiling `chart_smoke.mojo` against the real toolchain.
**Compiler: Mojo 0.26.2.0.dev2026012806 (nightly).** Follow these exactly — the
older widgets in this repo (e.g. `node_graph_int.mojo`) DO NOT compile under this
nightly and must not be copied verbatim.

### Build command (always build-only, never run — GPU/display is busy)
Run from the **repo root** (`/home/alex/MojoGUI-UI`); `pixi run` sets cwd there:
```
pixi run mojo build mojo-gui/<file>.mojo -o /tmp/<out>
```
No `-I` include flag is needed. `chart_smoke.mojo` builds clean (zero errors/warnings).

### Importing model types (and any sibling chart module)
The package is made importable by **empty `__init__.mojo` marker files** that already
exist at all three levels: `mojo_src/`, `mojo_src/widgets/`, `mojo_src/widgets/chart/`.
Do not delete them. Each new chart module is reachable two ways:

- From a file **outside** the package (the demo/harness in `mojo-gui/` root) use the
  **absolute** path:
  ```mojo
  from mojo_src.widgets.chart.model import Bar, BarData, Symbol, Timeframe, ChartType
  ```
- From a file **inside** `chart/` (engine, renderers, scales, ...) use a **relative**
  sibling import:
  ```mojo
  from .model import Bar, BarData, ChartType, CT_CANDLES
  ```
- To reach the rendering/widget bases from inside `chart/`, go up one package level
  (same idiom node_graph used): `from ..rendering_int import RenderingContextInt, ColorInt`
  and `from ..widget_int import BaseWidgetInt, MouseEventInt, KeyEventInt`.

### Self / argument conventions (MATCH THE COMPILER)
- `__init__(out self, ...)` — use `out self`, **NOT** `inout self`. `inout self` is a
  hard parse error ("expected ')'").
- Mutating methods: `fn foo(mut self, ...)`. Read-only methods: `fn foo(self, ...)`.
- Owned-by-value argument: `fn __init__(out self, var bars: List[Bar])` then move with
  `self.bars = bars^`. The keyword is `var` — `owned` is deprecated.

### Struct traits / copy semantics (this bit out the foundation build)
- Plain value structs that get stored in and read back out of a `List` (indexing
  `lst[i]` copies) MUST derive **`(ImplicitlyCopyable, Movable)`**. `Bar`, `Symbol`,
  `Timeframe`, `ChartType`, `ChartTypeParams` all do.
- A struct that **owns a `List[...]`** (like `BarData`) CANNOT be `ImplicitlyCopyable`
  (`List` itself isn't implicitly copyable). Derive **`(Copyable, Movable)`** instead,
  and when you need a copy call `.copy()` explicitly; when returning/handing off a local
  `List` or such a struct, transfer with `^` (e.g. `return v^`, `BarData(ha^)`).
- A `List[T]` value is moved with `^` or copied with `.copy()` — a bare `return v` of a
  `List` is an error.

### Mojo-vs-Rust gotchas already handled in `model.mojo`
- `comptime` replaces `alias` (the nightly deprecates `alias`).
- Rust **payload enums have no Mojo equivalent**: enums are Int32 `comptime` constants
  (`CT_*`, `TF_*`, `CTC_*`) plus a thin wrapper struct exposing the Rust helper methods.
  `Timeframe::Custom(u64)` is `TF_CUSTOM` + a `custom_seconds` field; build it with
  `Timeframe.custom(seconds)`.
- `f64::INFINITY` → `inf[DType.float64]()` (from `math import inf`).
- Rust `Option<f64>` aggregations (`min_price`/`max_price`/...) return `Float64` and yield
  `0.0` on empty data — **guard with `BarData.is_empty()`**. Documented divergence.
- `Bar.time` is `Int64` Unix-epoch **milliseconds** (Rust used `DateTime<Utc>`); prices/
  volume are `Float64` and are never rounded in the model.

### What `model.mojo` exports (use these names verbatim)
- Types: `Bar`, `BarData`, `Symbol`, `Timeframe`, `ChartType`, `ChartTypeParams`.
- Bar OHLC helpers: `is_bullish/is_bearish/is_doji`, `body_height/range/upper_wick/
  lower_wick`, `body_top/body_bottom`, `typical_price/weighted_close/midpoint/avg_price`
  plus aliases `hl2/hlc3/ohlc4`, `body_percentage/wick_ratio/change/change_percent`.
- BarData: `push/len/is_empty/clear/push_with_limit/trim_to_limit`,
  `min_price/max_price/max_volume/total_volume/avg_volume`, `to_heikin_ashi/to_regular`.
- ChartType helpers: `name/description/category/uses_ohlc/supports_volume/
  requires_parameters/is_time_independent/transforms_data`.
- Free fns: `all_chart_types()`, `chart_type_category_name(cat)`,
  `_format_custom_seconds(secs)`.
- Constants: `CT_BARS..CT_SESSION_VOLUME` (20, declaration order), `CHART_TYPE_COUNT=20`,
  `CTC_STANDARD..CTC_ADVANCED`, `TF_MS100..TF_MONTH1` + `TF_CUSTOM`,
  `MAX_BARS=10000`, `MAX_VISIBLE_BARS=2000`.

### CRITICAL for the engine builder (Task #4)
**You cannot inherit from `BaseWidgetInt`.** `struct X(BaseWidgetInt)` is a hard error
("inheriting from structs is not allowed") in this nightly. node_graph_int.mojo does
this and does not compile. Instead either (a) declare the widget's own `x/y/width/
height/visible/enabled` fields directly, or (b) hold a `BaseWidgetInt` as a field and
delegate. The chart engine must compose, not inherit.
