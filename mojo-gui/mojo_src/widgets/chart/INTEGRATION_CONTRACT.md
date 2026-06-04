# INTEGRATION CONTRACT (authoritative — set by team-lead)

All builders code against THIS. It is designed so imports flow ONE WAY (no cycles):

```
model  ◄── scales
model  ◄── transforms
model, theme  ◄── renderers          (renderers does NOT import engine)
model, scales, renderers, theme, config  ◄── engine
model, engine, theme, config  ◄── builder
everything  ◄── chart_demo (root, absolute imports)
```

## theme.mojo  (builder-theme-demo)
`struct ChartTheme(ImplicitlyCopyable, Movable)` with `ColorInt` fields:
`background, grid, axis, text, bull, bear, wick, crosshair, line, area_fill, baseline`.
Presets: `fn dark()->ChartTheme`, `light()`, `midnight()`, `classic()`, `high_contrast()`.
Imports only `..rendering_int` (for ColorInt). No engine/renderers imports.

## config.mojo  (builder-theme-demo)
`struct ChartConfig(ImplicitlyCopyable, Movable)`: `show_grid: Bool, show_crosshair: Bool,
show_axes: Bool, bar_spacing: Int32, price_scale_mode: Int32`. `struct CrosshairConfig(...)`.

## renderers.mojo  (builder-renderers) — decoupled via RenderView
Define the shared view struct HERE (engine builds it and passes it in):
```mojo
struct RenderView(ImplicitlyCopyable, Movable):
    var area_x: Int32
    var area_y: Int32
    var area_w: Int32
    var area_h: Int32
    var first_idx: Int        # index of first visible bar
    var bars_visible: Int
    var bar_width: Int32      # pixel width per bar slot
    var price_min: Float64
    var price_max: Float64
    var theme: ChartTheme
    # helpers renderers use:
    fn x_for(self, i: Int) -> Int32        # area_x + (i-first_idx)*bar_width + bar_width//2
    fn y_for(self, price: Float64) -> Int32 # area_y + Int32((price_max-price)/(price_max-price_min)*Float64(area_h))
```
Public entry the engine calls:
```mojo
fn draw_series(ctx: RenderingContextInt, view: RenderView, bars: List[Bar], ct: ChartType)
```
which dispatches on `ct` to the per-type fns (candles/ohlc/line/area/heikin/renko/kagi/...).
Renderers imports: `..rendering_int`, `.model`, `.theme`, and `.transforms` (for renko/kagi/etc).

## engine.mojo  (builder-engine) — ChartInt COMPOSES (never inherits)
Exact public API (builder.mojo + demo depend on these names):
```mojo
struct ChartInt(...):   # own fields: x,y,width,height: Int32; visible: Bool; bars: List[Bar];
                        # chart_type: ChartType; theme: ChartTheme; config: ChartConfig;
                        # first_idx: Int; bars_visible: Int; bar_width: Int32; symbol_label,
                        # timeframe_label: String; crosshair_x, crosshair_y: Int32
    fn __init__(out self, x: Int32, y: Int32, width: Int32, height: Int32)
    fn set_bars(mut self, var bars: List[Bar])
    fn set_chart_type(mut self, ct: ChartType)
    fn set_theme(mut self, theme: ChartTheme)
    fn set_config(mut self, cfg: ChartConfig)
    fn set_symbol_label(mut self, s: String)
    fn set_timeframe_label(mut self, s: String)
    fn set_visible_bars(mut self, n: Int)
    fn handle_mouse_event(mut self, e: MouseEventInt) -> Bool   # pan on drag, zoom changes bars_visible
    fn handle_key_event(mut self, e: KeyEventInt) -> Bool
    fn render(self, ctx: RenderingContextInt)   # draws bg, grid, axes, builds RenderView -> draw_series(), crosshair
    fn update(mut self)
fn create_chart_int(x: Int32, y: Int32, width: Int32, height: Int32) -> ChartInt
```
In `render`, compute visible price_min/price_max via auto-fit (or scales.mojo PriceScale), make a
`RenderView`, call `renderers.draw_series(ctx, view, self.bars, self.chart_type)`, then draw axes/crosshair.

## builder.mojo  (builder-theme-demo)
`struct ChartBuilder` fluent: `with_symbol(String)`, `with_timeframe(Timeframe)`, `with_theme(ChartTheme)`,
`with_chart_type(ChartType)`, `with_visible_candles(Int)`, `build() -> ChartInt`.
`build()` does: `var c = create_chart_int(0,0,W,H); c.set_theme(...); c.set_chart_type(...);
c.set_visible_bars(...); c.set_symbol_label(...); return c^`. Presets `new()/extended()/price_chart()`.

## studies.mojo (already written) / drawings.mojo
Indicator overlays draw via their own `LinearMap` (already in studies.mojo) OR accept a RenderView —
bug-fixer reconciles. drawings.mojo: `Drawing` interface + registry + TrendLine/HorizontalLine/
Rectangle/FibRetracement with begin/drag/commit + hit_test, coords in (bar_index, price), mapped at draw.

## VERIFICATION METHOD (measured facts, Mojo 0.26.2 nightly — bug-fixer read this)
- A package file that uses relative imports (`from .model`, `from ..rendering_int`) CANNOT be
  built directly: `pixi run mojo build mojo_src/widgets/chart/<x>.mojo` → "cannot import relative
  to a top-level package". This is expected; it is NOT a bug in the file.
- Building a relative-import-free module directly (model.mojo) elaborates ALL its methods; a clean
  module ends with "module does not contain a 'main' function" (that message == success for a lib).
- Importing a module from a root harness only elaborates the methods actually USED → latent errors
  (e.g. a missing `^` on a `List` move) stay hidden until that method is called. model.mojo:226 was
  exactly this — fixed to `kept^`.
- AUTHORITATIVE GATE (bug-fixer owns): a ROOT harness with ABSOLUTE imports that CONSTRUCTS and
  CALLS each module's key methods, built from repo root:
  `pixi run mojo build mojo-gui/chart_demo.mojo -o /tmp/chart_demo_check` (compile-only; never run —
  GPU busy). chart_demo must actually build a ChartInt, set bars, set each ChartType, and call render
  paths so every module is elaborated. Add a `_check_all.mojo` root harness if chart_demo doesn't
  exercise studies/drawings.
