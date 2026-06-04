"""
Per-ChartType draw functions — faithful port of egui-charts
`src/chart/rendering/candles/*` (the directory name is historical; it renders
every `ChartType` variant).

Ported from:
  - /tmp/egui-charts-ref/src/chart/rendering/candles/mod.rs          -> draw_series dispatch (render_chart_type)
  - /tmp/egui-charts-ref/src/chart/rendering/candles/candlestick.rs  -> candles / ohlc bars / hollow / heikin / volume candles
  - /tmp/egui-charts-ref/src/chart/rendering/candles/line.rs         -> line / line+markers / step line
  - /tmp/egui-charts-ref/src/chart/rendering/candles/area.rs         -> area / hlc area / baseline
  - /tmp/egui-charts-ref/src/chart/rendering/candles/range.rs        -> high-low / range bars
  - /tmp/egui-charts-ref/src/chart/rendering/candles/japanese.rs     -> renko / kagi / line break / point & figure
  - /tmp/egui-charts-ref/src/chart/rendering/candles/advanced.rs     -> volume footprint / session volume (placeholders)
  - /tmp/egui-charts-ref/src/chart/renderers/{candle,bar,volume,context}.rs -> StyleColors / BarRenderParams / LinearPriceMap
  - /tmp/egui-charts-ref/src/model/price_source.rs                   -> PriceSource

Drawing uses ONLY `RenderingContextInt` primitives (set_color / draw_line /
draw_(filled_)rectangle / draw_(filled_)circle / draw_text).  There is no
native polyline/polygon/gradient: polylines are drawn as line segments and area
fills as a run of adjacent thin filled-rectangle columns (each column flattened
to its average height), matching the visual of egui's `convex_polygon` quads
without a polygon primitive.

Coordinate mapping (per the team INTEGRATION_CONTRACT `RenderView`):
  - `view.x_for(i)`     bar index -> center X
  - `view.y_for(price)` price     -> Y
The engine builds the `RenderView` (price_min/max via auto-fit, the visible
window, bar_width and theme) and calls `draw_series(ctx, view, bars, ct)`.

Faithfulness notes / Mojo divergences:
  - Rust `f32` pixels are computed in `Float64` and rounded to `Int32` only at
    the FFI boundary, so intermediate geometry is never lost.  Prices stay f64.
  - The Japanese/Range chart types are *data transforms*: this module calls
    `transforms.to_renko_bricks` / `to_kagi_lines` / `to_line_break_lines` /
    `to_pnf_columns` / `to_range_bars_from_ohlc` exactly as the Rust renderer
    does, then draws the resulting blocks/lines.  Heikin-Ashi uses
    `transforms.to_heikin_ashi`.
"""

from ...rendering_int import RenderingContextInt, ColorInt
from .model import (
    Bar,
    ChartType,
    CT_BARS,
    CT_CANDLES,
    CT_HOLLOW_CANDLES,
    CT_VOLUME_CANDLES,
    CT_LINE,
    CT_LINE_WITH_MARKERS,
    CT_STEP_LINE,
    CT_AREA,
    CT_HLC_AREA,
    CT_BASELINE,
    CT_HIGH_LOW,
    CT_RANGE,
    CT_RENKO,
    CT_KAGI,
    CT_LINE_BREAK,
    CT_HEIKIN,
    CT_POINT_AND_FIGURE,
    CT_VOLUME_FOOTPRINT,
    CT_TIME_PRICE_OPPORTUNITY,
    CT_SESSION_VOLUME,
)
from .theme import ChartTheme
from .transforms import (
    RenkoConfig,
    to_renko_bricks,
    KagiConfig,
    to_kagi_lines,
    KAGI_THICK,
    LineBreakConfig,
    to_line_break_lines,
    PointFigureConfig,
    to_pnf_columns,
    PNF_UP,
    RangeBarConfig,
    to_range_bars_from_ohlc,
    to_heikin_ashi,
)


# =============================================================================
# PriceSource — port of model/price_source.rs (enum PriceSource)
# =============================================================================

comptime PS_OPEN: Int32 = 0
comptime PS_HIGH: Int32 = 1
comptime PS_LOW: Int32 = 2
comptime PS_CLOSE: Int32 = 3            # Rust #[default]
comptime PS_HL2: Int32 = 4
comptime PS_HLC3: Int32 = 5
comptime PS_OHLC4: Int32 = 6


fn price_source_compute(source: Int32, open: Float64, high: Float64,
                        low: Float64, close: Float64) -> Float64:
    """Compute a price value from OHLC (port of `PriceSource::compute`)."""
    if source == PS_OPEN:  return open
    if source == PS_HIGH:  return high
    if source == PS_LOW:   return low
    if source == PS_HL2:   return (high + low) / 2.0
    if source == PS_HLC3:  return (high + low + close) / 3.0
    if source == PS_OHLC4: return (open + high + low + close) / 4.0
    return close            # PS_CLOSE (default)


# =============================================================================
# RenderView — shared view struct (owned here per INTEGRATION_CONTRACT)
# =============================================================================

struct RenderView(ImplicitlyCopyable, Movable):
    """Pixel geometry + price/index→pixel mapping for one render pass.

    The engine constructs this each frame (visible window, bar width, price
    bounds, theme) and passes it to `draw_series`.  `x_for`/`y_for` are the only
    coordinate helpers the renderers use; the formulas are fixed by the contract.
    """

    var area_x: Int32
    """Left edge of the price drawing rect (px)."""
    var area_y: Int32
    """Top edge of the price drawing rect (px)."""
    var area_w: Int32
    """Width of the price drawing rect (px)."""
    var area_h: Int32
    """Height of the price drawing rect (px)."""
    var first_idx: Int
    """Index of the first visible bar within `bars`."""
    var bars_visible: Int
    """Number of bars in the visible window."""
    var bar_width: Int32
    """Pixel width per bar slot."""
    var price_min: Float64
    """Lower bound of the visible price window."""
    var price_max: Float64
    """Upper bound of the visible price window."""
    var theme: ChartTheme
    """Resolved colors for this frame (from the engine's active preset)."""

    fn __init__(out self, area_x: Int32, area_y: Int32, area_w: Int32,
                area_h: Int32, first_idx: Int, bars_visible: Int,
                bar_width: Int32, price_min: Float64, price_max: Float64,
                theme: ChartTheme):
        self.area_x = area_x
        self.area_y = area_y
        self.area_w = area_w
        self.area_h = area_h
        self.first_idx = first_idx
        self.bars_visible = bars_visible
        self.bar_width = bar_width
        self.price_min = price_min
        self.price_max = price_max
        self.theme = theme

    fn x_for(self, i: Int) -> Int32:
        """Bar index -> center X (contract formula)."""
        return self.area_x + Int32(i - self.first_idx) * self.bar_width + self.bar_width // 2

    fn y_for(self, price: Float64) -> Int32:
        """Price -> Y (contract formula).

        A flat price window (`price_max == price_min`) would divide by zero, so
        it is floored to a tiny span and the price lands near the top edge.
        """
        var span = self.price_max - self.price_min
        if span < 1e-12:
            span = 1e-12
        return self.area_y + Int32((self.price_max - price) / span * Float64(self.area_h))

    fn bottom_y(self) -> Int32:
        """Y of the bottom edge of the price rect."""
        return self.area_y + self.area_h


# =============================================================================
# Internal helpers
# =============================================================================

comptime _MAX_ELEMENTS: Int = 2000          # japanese.rs MAX_ELEMENTS
comptime _MAX_BOXES_PER_COLUMN: Int = 500    # japanese.rs MAX_BOXES_PER_COLUMN
comptime _MIN_BODY_HEIGHT: Int32 = 1         # helpers.rs candle.min_body_height
comptime _AREA_ALPHA: Int32 = 50             # area.rs AREA_ALPHA
comptime _HLC_AREA_ALPHA: Int32 = 30         # area.rs HLC_AREA_ALPHA
comptime _BASELINE_FILL_ALPHA: Int32 = 30    # area.rs BASELINE_FILL_ALPHA
comptime _VOLUME_ALPHA: Int32 = 66           # volume.rs ~26% opacity


fn _round_i32(v: Float64) -> Int32:
    """Round a Float64 pixel coordinate to Int32 (nearest, ties away from 0)."""
    if v >= 0.0:
        return Int32(v + 0.5)
    return Int32(v - 0.5)


fn _alpha(c: ColorInt, a: Int32) -> ColorInt:
    """Fresh copy of a color with a new alpha (egui `from_rgba_unmultiplied`).

    Always constructs a NEW `ColorInt` rather than reassigning an existing one:
    `ColorInt` is only safely produced by construction in this nightly.
    """
    return ColorInt(c.r, c.g, c.b, a)


fn _gamma(c: ColorInt, num: Int32, den: Int32) -> ColorInt:
    """Approximate egui `gamma_multiply(num/den)` by scaling RGB (alpha kept)."""
    return ColorInt(c.r * num // den, c.g * num // den, c.b * num // den, c.a)


fn _pick(is_up: Bool, up: ColorInt, down: ColorInt) -> ColorInt:
    """Pick bullish/bearish color, returning a freshly-constructed value."""
    if is_up:
        return ColorInt(up.r, up.g, up.b, up.a)
    return ColorInt(down.r, down.g, down.b, down.a)


fn _set(ctx: RenderingContextInt, c: ColorInt):
    """Set the current draw color from a ColorInt."""
    _ = ctx.set_color(c.r, c.g, c.b, c.a)


fn _vline(ctx: RenderingContextInt, x: Int32, y1: Int32, y2: Int32,
          thickness: Int32):
    """Vertical line segment helper."""
    _ = ctx.draw_line(x, y1, x, y2, thickness)


fn _filled_rect_minmax(ctx: RenderingContextInt, x0: Int32, y0: Int32,
                       x1: Int32, y1: Int32):
    """Filled rectangle from two corners (egui `Rect::from_min_max`)."""
    var left = min(x0, x1)
    var top = min(y0, y1)
    var w = abs(x1 - x0)
    var h = abs(y1 - y0)
    if w < 1:
        w = 1
    if h < 1:
        h = 1
    _ = ctx.draw_filled_rectangle(left, top, w, h)


fn _stroke_rect_minmax(ctx: RenderingContextInt, x0: Int32, y0: Int32,
                       x1: Int32, y1: Int32):
    """Rectangle outline from two corners."""
    var left = min(x0, x1)
    var top = min(y0, y1)
    var w = abs(x1 - x0)
    var h = abs(y1 - y0)
    if w < 1:
        w = 1
    if h < 1:
        h = 1
    _ = ctx.draw_rectangle(left, top, w, h)


fn _area_column(ctx: RenderingContextInt, x0: Int32, y0: Int32, x1: Int32,
                y1: Int32, baseline_y: Int32):
    """Fill one trapezoid column of an area chart as a filled rect.

    Rust draws a quad `[(x0,y0),(x1,y1),(x1,base),(x0,base)]`; without a polygon
    primitive each adjacent-pair column is approximated by a rectangle from x0..x1
    whose top is the average of the two segment endpoints.  Caller sets the color.
    """
    var top = _round_i32((Float64(y0) + Float64(y1)) / 2.0)
    var left = min(x0, x1)
    var w = abs(x1 - x0)
    if w < 1:
        w = 1
    var h = baseline_y - top
    if h <= 0:
        return
    _ = ctx.draw_filled_rectangle(left, top, w, h)


fn _draw_wicks(ctx: RenderingContextInt, x: Int32, y_high: Int32, y_low: Int32,
               body_top: Int32, body_bottom: Int32, color: ColorInt):
    """Draw upper + lower wicks (port of helpers.rs `draw_wicks`)."""
    _set(ctx, color)
    _vline(ctx, x, y_high, body_top, 1)      # upper wick
    _vline(ctx, x, body_bottom, y_low, 1)    # lower wick


fn _body_filled(ctx: RenderingContextInt, x: Int32, bar_width: Int32,
                body_top: Int32, body_bottom: Int32, color: ColorInt):
    """Draw a filled candle body, min `_MIN_BODY_HEIGHT` tall (helpers.rs)."""
    var half = bar_width // 2
    if half < 1:
        half = 1
    var bottom = body_bottom
    if bottom < body_top + _MIN_BODY_HEIGHT:
        bottom = body_top + _MIN_BODY_HEIGHT
    _set(ctx, color)
    _filled_rect_minmax(ctx, x - half, body_top, x + half, bottom)


fn _body_hollow(ctx: RenderingContextInt, x: Int32, bar_width: Int32,
                body_top: Int32, body_bottom: Int32, color: ColorInt):
    """Draw a hollow candle body outline (port of helpers.rs `draw_body_hollow`)."""
    var half = bar_width // 2
    if half < 1:
        half = 1
    _set(ctx, color)
    _stroke_rect_minmax(ctx, x - half, body_top, x + half, body_bottom)


fn _draw_brick(ctx: RenderingContextInt, x0: Int32, y0: Int32, x1: Int32,
               y1: Int32, color: ColorInt):
    """Filled brick + darker border (port of helpers.rs `draw_brick`)."""
    _set(ctx, color)
    _filled_rect_minmax(ctx, x0, y0, x1, y1)
    _set(ctx, _gamma(color, 7, 10))   # border = gamma_multiply(0.7)
    _stroke_rect_minmax(ctx, x0, y0, x1, y1)


fn _polyline(ctx: RenderingContextInt, xs: List[Int32], ys: List[Int32],
             thickness: Int32, color: ColorInt):
    """Draw a polyline as connected segments (egui `Shape::line`)."""
    var n = len(xs)
    if n < 2:
        return
    _set(ctx, color)
    for i in range(n - 1):
        _ = ctx.draw_line(xs[i], ys[i], xs[i + 1], ys[i + 1], thickness)


# =============================================================================
# Candle family — port of candlestick.rs + renderers/candle.rs + bar.rs
# =============================================================================

fn draw_candles(ctx: RenderingContextInt, view: RenderView, bars: List[Bar]):
    """Candlestick chart (port of `render_candles` -> `render_candle`)."""
    var n = len(bars)
    for i in range(n):
        var bar = bars[i]
        var is_bull = bar.is_bullish()
        var x = view.x_for(i)
        var body_color = _pick(is_bull, view.theme.bull, view.theme.bear)
        var wick_color = ColorInt(view.theme.wick.r, view.theme.wick.g,
                                  view.theme.wick.b, view.theme.wick.a)

        var y_high = view.y_for(bar.high)
        var y_low = view.y_for(bar.low)
        var y_open = view.y_for(bar.open)
        var y_close = view.y_for(bar.close)
        var body_top = min(y_open, y_close)
        var body_bottom = max(y_open, y_close)

        _set(ctx, wick_color)
        _vline(ctx, x, y_high, y_low, 1)     # full high-low wick (candle.rs)
        _body_filled(ctx, x, view.bar_width, body_top, body_bottom, body_color)


fn draw_ohlc_bars(ctx: RenderingContextInt, view: RenderView, bars: List[Bar]):
    """OHLC bar chart (port of `render_ohlc_bars` -> `render_ohlc_bar`).

    Vertical high-low line, left tick at the open, right tick at the close.
    """
    var n = len(bars)
    for i in range(n):
        var bar = bars[i]
        var x = view.x_for(i)
        var color = _pick(bar.is_bullish(), view.theme.bull, view.theme.bear)

        var y_high = view.y_for(bar.high)
        var y_low = view.y_for(bar.low)
        var y_open = view.y_for(bar.open)
        var y_close = view.y_for(bar.close)
        var tick = view.bar_width // 2
        if tick < 1:
            tick = 1

        _set(ctx, color)
        _vline(ctx, x, y_high, y_low, 1)
        _ = ctx.draw_line(x - tick, y_open, x, y_open, 1)       # open tick (left)
        _ = ctx.draw_line(x, y_close, x + tick, y_close, 1)     # close tick (right)


fn draw_hollow_candles(ctx: RenderingContextInt, view: RenderView,
                       bars: List[Bar]):
    """Hollow candles (port of `render_hollow_candles`).

    Hollow body when `close > open`, filled otherwise; wicks always drawn.
    """
    var n = len(bars)
    for i in range(n):
        var bar = bars[i]
        var is_bull = bar.is_bullish()
        var x = view.x_for(i)
        var color = _pick(is_bull, view.theme.bull, view.theme.bear)

        var y_high = view.y_for(bar.high)
        var y_low = view.y_for(bar.low)
        var y_open = view.y_for(bar.open)
        var y_close = view.y_for(bar.close)
        var body_top = min(y_open, y_close)
        var body_bottom = max(y_open, y_close)

        _draw_wicks(ctx, x, y_high, y_low, body_top, body_bottom, color)
        if bar.close > bar.open:
            _body_hollow(ctx, x, view.bar_width, body_top, body_bottom, color)
        else:
            _body_filled(ctx, x, view.bar_width, body_top, body_bottom, color)


fn draw_volume_candles(ctx: RenderingContextInt, view: RenderView,
                       bars: List[Bar]):
    """Volume candles (port of `render_volume_candles`).

    Body width scales with volume from 30% to 100% of `view.bar_width`.
    """
    var n = len(bars)
    var max_volume: Float64 = 0.0
    for i in range(n):
        if bars[i].volume > max_volume:
            max_volume = bars[i].volume

    for i in range(n):
        var bar = bars[i]
        var is_bull = bar.is_bullish()
        var x = view.x_for(i)
        var color = _pick(is_bull, view.theme.bull, view.theme.bear)

        var y_high = view.y_for(bar.high)
        var y_low = view.y_for(bar.low)
        var y_open = view.y_for(bar.open)
        var y_close = view.y_for(bar.close)
        var body_top = min(y_open, y_close)
        var body_bottom = max(y_open, y_close)

        var ratio: Float64 = 1.0
        if max_volume > 0.0:
            ratio = bar.volume / max_volume
            if ratio < 0.3:
                ratio = 0.3
            if ratio > 1.0:
                ratio = 1.0
        var vw = _round_i32(Float64(view.bar_width) * ratio)
        if vw < 1:
            vw = 1

        _draw_wicks(ctx, x, y_high, y_low, body_top, body_bottom, color)
        _body_filled(ctx, x, vw, body_top, body_bottom, color)


fn draw_heikin_ashi(ctx: RenderingContextInt, view: RenderView,
                    bars: List[Bar]):
    """Heikin-Ashi candles (port of `render_heikin_ashi`).

    Transforms the visible bars to the HA series (`transforms.to_heikin_ashi`),
    then draws plain filled candles colored bull/bear by `close >= open`.
    """
    var ha = to_heikin_ashi(bars)
    var n = len(ha)
    for i in range(n):
        var bar = ha[i]
        var x = view.x_for(i)
        var color = _pick(bar.close >= bar.open, view.theme.bull,
                          view.theme.bear)

        var y_high = view.y_for(bar.high)
        var y_low = view.y_for(bar.low)
        var y_open = view.y_for(bar.open)
        var y_close = view.y_for(bar.close)
        var body_top = min(y_open, y_close)
        var body_bottom = max(y_open, y_close)

        _draw_wicks(ctx, x, y_high, y_low, body_top, body_bottom, color)
        _body_filled(ctx, x, view.bar_width, body_top, body_bottom, color)


fn draw_volume_histogram(ctx: RenderingContextInt, view: RenderView,
                         bars: List[Bar], vol_area_y: Int32, vol_area_h: Int32):
    """Volume sub-panel histogram (port of renderers/volume.rs `render_volume_bar`).

    Semi-transparent (~26% alpha) bars in the volume sub-rect.  Called by the
    engine for a volume panel; not part of the per-ChartType dispatch.
    """
    var n = len(bars)
    var max_volume: Float64 = 0.0
    for i in range(n):
        if bars[i].volume > max_volume:
            max_volume = bars[i].volume
    if max_volume <= 0.0:
        return

    var bottom = vol_area_y + vol_area_h
    var half = view.bar_width // 2
    if half < 1:
        half = 1
    for i in range(n):
        var bar = bars[i]
        var x = view.x_for(i)
        var base = _pick(bar.is_bullish(), view.theme.bull, view.theme.bear)
        var color = _alpha(base, _VOLUME_ALPHA)
        var h = _round_i32(bar.volume / max_volume * Float64(vol_area_h))
        if h < 1:
            h = 1
        _set(ctx, color)
        _ = ctx.draw_filled_rectangle(x - half, bottom - h, view.bar_width, h)


# =============================================================================
# Line family — port of line.rs
# =============================================================================

fn draw_line(ctx: RenderingContextInt, view: RenderView, bars: List[Bar],
             price_source: Int32 = PS_CLOSE):
    """Line chart (port of `render_line`).  Stroke uses the theme line color."""
    var n = len(bars)
    var xs = List[Int32]()
    var ys = List[Int32]()
    for i in range(n):
        var bar = bars[i]
        var v = price_source_compute(price_source, bar.open, bar.high, bar.low, bar.close)
        xs.append(view.x_for(i))
        ys.append(view.y_for(v))
    _polyline(ctx, xs, ys, 2, view.theme.line)


fn draw_line_with_markers(ctx: RenderingContextInt, view: RenderView,
                          bars: List[Bar], price_source: Int32 = PS_CLOSE):
    """Line with circular markers (port of `render_line_with_markers`)."""
    var n = len(bars)
    var xs = List[Int32]()
    var ys = List[Int32]()
    for i in range(n):
        var bar = bars[i]
        var v = price_source_compute(price_source, bar.open, bar.high, bar.low, bar.close)
        xs.append(view.x_for(i))
        ys.append(view.y_for(v))

    _polyline(ctx, xs, ys, 2, view.theme.line)

    var marker_radius: Int32 = 3        # line.rs marker_radius = 3.0
    for i in range(len(xs)):
        _set(ctx, view.theme.line)
        _ = ctx.draw_filled_circle(xs[i], ys[i], marker_radius)
        _set(ctx, view.theme.text)   # ring color (line.rs)
        _ = ctx.draw_circle(xs[i], ys[i], marker_radius)


fn draw_step_line(ctx: RenderingContextInt, view: RenderView, bars: List[Bar],
                  price_source: Int32 = PS_CLOSE):
    """Step line (port of `render_step_line`).

    Horizontal step to the new X at the previous Y, then vertical to the new Y.
    """
    var n = len(bars)
    if n == 0:
        return
    var xs = List[Int32]()
    var ys = List[Int32]()
    var have_prev = False
    var prev_y: Int32 = 0
    for i in range(n):
        var bar = bars[i]
        var v = price_source_compute(price_source, bar.open, bar.high, bar.low, bar.close)
        var x = view.x_for(i)
        var y = view.y_for(v)
        if have_prev:
            xs.append(x)        # horizontal step first (x, prev_y)
            ys.append(prev_y)
        xs.append(x)            # then vertical to (x, y)
        ys.append(y)
        prev_y = y
        have_prev = True
    _polyline(ctx, xs, ys, 2, view.theme.line)


# =============================================================================
# Area family — port of area.rs
# =============================================================================

fn draw_area(ctx: RenderingContextInt, view: RenderView, bars: List[Bar],
             price_source: Int32 = PS_CLOSE):
    """Area chart (port of `render_area`).

    Fill under the line down to the rect bottom (alpha `_AREA_ALPHA`), then the
    line on top.  Fill is built from adjacent trapezoid columns (no polygon).
    """
    var n = len(bars)
    if n < 2:
        return
    var xs = List[Int32]()
    var ys = List[Int32]()
    for i in range(n):
        var bar = bars[i]
        var v = price_source_compute(price_source, bar.open, bar.high, bar.low, bar.close)
        xs.append(view.x_for(i))
        ys.append(view.y_for(v))

    var baseline_y = view.bottom_y()
    # Theme `area_fill` is the resolved Rust `bullish_fill` (already alpha ~50).
    var fill = ColorInt(view.theme.area_fill.r, view.theme.area_fill.g,
                        view.theme.area_fill.b, view.theme.area_fill.a)
    _set(ctx, fill)
    for i in range(len(xs) - 1):
        _area_column(ctx, xs[i], ys[i], xs[i + 1], ys[i + 1], baseline_y)

    _polyline(ctx, xs, ys, 2, view.theme.line)


fn draw_hlc_area(ctx: RenderingContextInt, view: RenderView, bars: List[Bar],
                 price_source: Int32 = PS_CLOSE):
    """HLC area (port of `render_hlc_area`).

    Fill the high-low band (alpha `_HLC_AREA_ALPHA`) as adjacent quad columns,
    then draw the close (price-source) line on top in the bullish color.
    """
    var n = len(bars)
    if n < 2:
        return
    var xs = List[Int32]()
    var y_high = List[Int32]()
    var y_low = List[Int32]()
    var y_close = List[Int32]()
    for i in range(n):
        var bar = bars[i]
        var v = price_source_compute(price_source, bar.open, bar.high, bar.low, bar.close)
        xs.append(view.x_for(i))
        y_high.append(view.y_for(bar.high))
        y_low.append(view.y_for(bar.low))
        y_close.append(view.y_for(v))

    var fill = _alpha(view.theme.bull, _HLC_AREA_ALPHA)
    _set(ctx, fill)
    for i in range(len(xs) - 1):
        var top = _round_i32((Float64(y_high[i]) + Float64(y_high[i + 1])) / 2.0)
        var bot = _round_i32((Float64(y_low[i]) + Float64(y_low[i + 1])) / 2.0)
        _filled_rect_minmax(ctx, xs[i], top, xs[i + 1], bot)

    _polyline(ctx, xs, y_close, 2, view.theme.bull)


fn draw_baseline(ctx: RenderingContextInt, view: RenderView, bars: List[Bar],
                 price_source: Int32 = PS_CLOSE):
    """Baseline chart (port of `render_baseline`).

    Baseline = first visible bar's price-source value.  Segments are colored
    bull/bear by whether their end value is >= the baseline, with a faint fill.
    """
    var n = len(bars)
    if n == 0:
        return
    var first = bars[0]
    var baseline = price_source_compute(price_source, first.open, first.high, first.low, first.close)
    var baseline_y = view.y_for(baseline)

    # Baseline reference line across the price rect (theme baseline color).
    _set(ctx, view.theme.baseline)
    _ = ctx.draw_line(view.area_x, baseline_y, view.area_x + view.area_w, baseline_y, 1)

    for i in range(1, n):
        var pbar = bars[i - 1]
        var cbar = bars[i]
        var px = view.x_for(i - 1)
        var cx = view.x_for(i)
        var pv = price_source_compute(price_source, pbar.open, pbar.high, pbar.low, pbar.close)
        var cv = price_source_compute(price_source, cbar.open, cbar.high, cbar.low, cbar.close)
        var py = view.y_for(pv)
        var cy = view.y_for(cv)
        var color = _pick(cv >= baseline, view.theme.bull, view.theme.bear)

        var fill = _alpha(color, _BASELINE_FILL_ALPHA)
        _set(ctx, fill)
        _area_column(ctx, px, py, cx, cy, baseline_y)

        _set(ctx, color)
        _ = ctx.draw_line(px, py, cx, cy, 2)


# =============================================================================
# Range family — port of range.rs
# =============================================================================

fn draw_high_low(ctx: RenderingContextInt, view: RenderView, bars: List[Bar]):
    """High-Low chart (port of `render_high_low`).

    A thin filled rect (width `bar_width/2`) spanning each bar's high→low.
    """
    var n = len(bars)
    var quarter = view.bar_width // 4
    if quarter < 1:
        quarter = 1
    for i in range(n):
        var bar = bars[i]
        var x = view.x_for(i)
        var y_high = view.y_for(bar.high)
        var y_low = view.y_for(bar.low)
        var color = _pick(bar.close > bar.open, view.theme.bull, view.theme.bear)
        _set(ctx, color)
        _filled_rect_minmax(ctx, x - quarter, y_high, x + quarter, y_low)


fn draw_range_bars(ctx: RenderingContextInt, view: RenderView, bars: List[Bar]):
    """Range bars (port of `render_range_bars`).

    Transforms the bars to range bars (`transforms.to_range_bars_from_ohlc`),
    then draws each as a filled open→close body of width `bar_width`.  Range
    bars are price-driven, so they are laid out evenly across the price rect.
    """
    var rb = to_range_bars_from_ohlc(bars, RangeBarConfig())
    var count = len(rb)
    if count == 0:
        return
    if count > _MAX_ELEMENTS:
        count = _MAX_ELEMENTS
    var spacing_f = Float64(view.area_w) / Float64(count)
    var half = view.bar_width // 2
    if half < 1:
        half = 1
    for i in range(count):
        var bar = rb[i]
        var xf = Float64(view.area_x) + (Float64(i) + 0.5) * spacing_f
        var x = _round_i32(xf)
        var y_open = view.y_for(bar.open)
        var y_close = view.y_for(bar.close)
        var color = _pick(bar.close > bar.open, view.theme.bull, view.theme.bear)
        _set(ctx, color)
        _filled_rect_minmax(ctx, x - half, y_open, x + half, y_close)


# =============================================================================
# Japanese family — port of japanese.rs
# =============================================================================

fn _calc_spacing(width: Int32, count: Int, bar_width: Int32) -> Int32:
    """Even element spacing capped at bar_width (port of `calc_spacing`)."""
    if count > 1:
        var s = width // Int32(count)
        if s < bar_width:
            return s
        return bar_width
    return bar_width


fn draw_renko(ctx: RenderingContextInt, view: RenderView, bars: List[Bar]):
    """Renko chart (port of `render_renko`).

    Transforms to bricks (`transforms.to_renko_bricks`) and lays them out evenly
    across the price rect, one filled block each (time-independent).
    """
    var bricks = to_renko_bricks(bars, RenkoConfig())
    var count = len(bricks)
    if count == 0:
        return
    if count > _MAX_ELEMENTS:
        count = _MAX_ELEMENTS
    var spacing = _calc_spacing(view.area_w, count, view.bar_width)
    var bw = _round_i32(Float64(spacing) * 0.85)
    if bw < 3:
        bw = 3
    var half = bw // 2

    for i in range(count):
        var bar = bricks[i].to_bar()
        var xf = Float64(view.area_x) + (Float64(i) + 0.5) * Float64(spacing)
        var x = _round_i32(xf)
        if x < view.area_x or x > view.area_x + view.area_w:
            continue
        var color = _pick(bar.close > bar.open, view.theme.bull, view.theme.bear)
        var y_open = view.y_for(bar.open)
        var y_close = view.y_for(bar.close)
        var top = min(y_open, y_close)
        var bottom = max(y_open, y_close)
        if bottom - top < 2:
            bottom = top + 2
        _draw_brick(ctx, x - half, top, x + half, bottom, color)


fn draw_kagi(ctx: RenderingContextInt, view: RenderView, bars: List[Bar]):
    """Kagi chart (port of `render_kagi`).

    Transforms to Kagi lines (`transforms.to_kagi_lines`).  Consecutive points
    are connected with an L-shaped shoulder; thick (yang) segments use the
    bullish color and 3px, thin (yin) use the bearish color and 2px.
    """
    var lines = to_kagi_lines(bars, KagiConfig())
    var count = len(lines)
    if count == 0:
        return
    if count > _MAX_ELEMENTS:
        count = _MAX_ELEMENTS
    var spacing_f = Float64(view.area_w) / Float64(count)
    if spacing_f < 2.0:
        spacing_f = 2.0

    var px = List[Int32]()
    var py = List[Int32]()
    var pthick = List[Int32]()
    for i in range(count):
        var seg = lines[i]
        var xf = Float64(view.area_x) + (Float64(i) + 0.5) * spacing_f
        var x = _round_i32(xf)
        if x < view.area_x or x > view.area_x + view.area_w:
            continue
        var y_start = view.y_for(seg.start_price)
        var y_end = view.y_for(seg.end_price)
        if len(px) == 0:
            px.append(x)
            py.append(y_start)
            pthick.append(seg.thickness)
        px.append(x)
        py.append(y_end)
        pthick.append(seg.thickness)

    for i in range(len(px) - 1):
        var x1 = px[i]
        var y1 = py[i]
        var x2 = px[i + 1]
        var y2 = py[i + 1]
        var is_thick = pthick[i] == KAGI_THICK
        var color = _pick(is_thick, view.theme.bull, view.theme.bear)
        var thickness: Int32
        if is_thick:
            thickness = 3
        else:
            thickness = 2
        _set(ctx, color)
        if abs(x1 - x2) < 1 or abs(y1 - y2) < 1:
            _ = ctx.draw_line(x1, y1, x2, y2, thickness)
        else:
            _ = ctx.draw_line(x1, y1, x2, y1, thickness)    # vertical to shoulder
            _ = ctx.draw_line(x2, y1, x2, y2, thickness)    # then horizontal


fn draw_line_break(ctx: RenderingContextInt, view: RenderView, bars: List[Bar]):
    """Line Break / Three Line Break (port of `render_line_break`).

    Transforms to line-break lines (`transforms.to_line_break_lines`); each
    line's open/close gives the block extent.  Blocks are evenly spaced bricks.
    """
    var lines = to_line_break_lines(bars, LineBreakConfig())
    var count = len(lines)
    if count == 0:
        return
    if count > _MAX_ELEMENTS:
        count = _MAX_ELEMENTS
    var spacing_f = Float64(view.area_w) / Float64(count)
    var aw = _round_i32(spacing_f * 0.85)
    if aw > view.bar_width:
        aw = view.bar_width
    if aw < 3:
        aw = 3
    var half = aw // 2

    for i in range(count):
        var line = lines[i]
        var xf = Float64(view.area_x) + (Float64(i) + 0.5) * spacing_f
        var x = _round_i32(xf)
        if x < view.area_x or x > view.area_x + view.area_w:
            continue
        var color = _pick(line.is_bullish(), view.theme.bull, view.theme.bear)
        var y_open = view.y_for(line.open)
        var y_close = view.y_for(line.close)
        var top = min(y_open, y_close)
        var bottom = max(y_open, y_close)
        if bottom - top < 2:
            bottom = top + 2
        _draw_brick(ctx, x - half, top, x + half, bottom, color)


fn _x_symbol(ctx: RenderingContextInt, cx: Int32, cy: Int32, half: Int32,
             color: ColorInt):
    """X glyph for P&F up columns (port of helpers.rs `draw_x_symbol`)."""
    _set(ctx, color)
    _ = ctx.draw_line(cx - half, cy - half, cx + half, cy + half, 3)
    _ = ctx.draw_line(cx - half, cy + half, cx + half, cy - half, 3)


fn _o_symbol(ctx: RenderingContextInt, cx: Int32, cy: Int32, radius: Int32,
             color: ColorInt):
    """O glyph for P&F down columns (port of helpers.rs `draw_o_symbol`)."""
    _set(ctx, color)
    _ = ctx.draw_circle(cx, cy, radius)


fn draw_point_and_figure(ctx: RenderingContextInt, view: RenderView,
                         bars: List[Bar]):
    """Point & Figure chart (port of `render_point_and_figure`).

    Transforms to P&F columns (`transforms.to_pnf_columns`).  Up columns stack X
    glyphs (bullish), down columns stack O glyphs (bearish), every box step.
    """
    var config = PointFigureConfig()
    var columns = to_pnf_columns(bars, config)
    var count = len(columns)
    if count == 0:
        return
    if count > 1000:
        count = 1000
    var spacing_f = Float64(view.area_w) / Float64(count)
    var sym = spacing_f * 0.7
    var cap = Float64(view.bar_width) * 0.8
    if sym > cap:
        sym = cap
    if sym < 4.0:
        sym = 4.0
    var half = _round_i32(sym / 2.0)
    if half < 2:
        half = 2
    var top_y = view.area_y
    var bot_y = view.area_y + view.area_h

    for i in range(count):
        var col = columns[i]
        var box_size = col.box_size
        if box_size <= 0.0:
            continue
        var xf = Float64(view.area_x) + (Float64(i) + 0.5) * spacing_f
        var x = _round_i32(xf)
        if x < view.area_x or x > view.area_x + view.area_w:
            continue

        var box_count = 0
        if col.direction == PNF_UP:
            var price = col.start_price
            while price <= col.end_price and box_count < _MAX_BOXES_PER_COLUMN:
                var y = view.y_for(price)
                if y >= top_y and y <= bot_y:
                    _x_symbol(ctx, x, y, half, view.theme.bull)
                price += box_size
                box_count += 1
        else:
            var price = col.start_price
            while price >= col.end_price and box_count < _MAX_BOXES_PER_COLUMN:
                var y = view.y_for(price)
                if y >= top_y and y <= bot_y:
                    _o_symbol(ctx, x, y, half, view.theme.bear)
                price -= box_size
                box_count += 1


# =============================================================================
# Advanced family — port of advanced.rs / tpo.rs (PLACEHOLDERS)
# =============================================================================
# These need tick/order-flow data for a faithful implementation.  The Rust crate
# itself ships them as OHLCV approximations (`*_placeholder` / `render_live_tpo`).

fn draw_volume_footprint(ctx: RenderingContextInt, view: RenderView,
                         bars: List[Bar]):
    """Volume footprint placeholder (port of `render_volume_footprint_placeholder`).

    Per bar: translucent upper (buyer) + lower (seller) halves over the high-low
    band, plus a Point-of-Control line.  TODO: a real footprint needs tick
    volume-at-price; this is the OHLCV approximation the Rust crate also ships.
    """
    var n = len(bars)
    var half_w = _round_i32(Float64(view.bar_width) * 0.4)
    if half_w < 1:
        half_w = 1
    for i in range(n):
        var bar = bars[i]
        var x = view.x_for(i)
        var y_high = view.y_for(bar.high)
        var y_low = view.y_for(bar.low)
        var y_mid = (y_high + y_low) // 2
        var is_bull = bar.close > bar.open
        var color = _pick(is_bull, view.theme.bull, view.theme.bear)

        _set(ctx, _gamma(view.theme.bull, 6, 10))   # upper (buyers)
        _filled_rect_minmax(ctx, x - half_w, y_high, x + half_w, y_mid)
        _set(ctx, _gamma(view.theme.bear, 6, 10))   # lower (sellers)
        _filled_rect_minmax(ctx, x - half_w, y_mid, x + half_w, y_low)

        var poc_y: Int32
        if is_bull:
            poc_y = y_mid - _round_i32(Float64(y_mid - y_high) * 0.3)
        else:
            poc_y = y_mid + _round_i32(Float64(y_low - y_mid) * 0.3)
        _set(ctx, color)
        _ = ctx.draw_line(x - half_w, poc_y, x + half_w, poc_y, 2)


fn draw_session_volume(ctx: RenderingContextInt, view: RenderView,
                       bars: List[Bar]):
    """Session volume placeholder (port of `render_session_volume_placeholder`).

    Groups bars into fixed 10-bar sessions and draws a volume-scaled profile
    block per session.  TODO: real session volume needs exchange session
    boundaries; this uses fixed chunks like the Rust crate.
    """
    comptime SESSION_SIZE: Int = 10
    var n = len(bars)
    if n == 0:
        return
    var s = 0
    while s < n:
        var e = s + SESSION_SIZE
        if e > n:
            e = n
        var s_high = bars[s].high
        var s_low = bars[s].low
        var s_vol: Float64 = 0.0
        for j in range(s, e):
            if bars[j].high > s_high:
                s_high = bars[j].high
            if bars[j].low < s_low:
                s_low = bars[j].low
            s_vol += bars[j].volume
        var last = bars[e - 1]
        var color = _pick(last.close > last.open, view.theme.bull, view.theme.bear)

        var first_x = view.x_for(s)
        var y_high = view.y_for(s_high)
        var y_low = view.y_for(s_low)
        var profile_w = _round_i32(s_vol / 1.0e6)
        if profile_w < 5:
            profile_w = 5

        _set(ctx, _alpha(color, 60))
        _filled_rect_minmax(ctx, first_x, y_high, first_x + profile_w, y_low)
        _set(ctx, _gamma(color, 8, 10))
        _stroke_rect_minmax(ctx, first_x, y_high, first_x + profile_w, y_low)
        s = e


fn draw_tpo(ctx: RenderingContextInt, view: RenderView, bars: List[Bar]):
    """TPO / Market Profile placeholder (port of `tpo::render_live_tpo`, minimal).

    TODO: the faithful TPO bins price into rows and stacks a letter per period
    that traded in each row (439-line tpo.rs).  This minimal stand-in draws each
    bar's high-low extent as a faint band so the type is not blank; the full
    row-binning port is deferred (see PORT_STATUS.md).
    """
    var n = len(bars)
    var half = view.bar_width // 2
    if half < 1:
        half = 1
    for i in range(n):
        var bar = bars[i]
        var x = view.x_for(i)
        var y_high = view.y_for(bar.high)
        var y_low = view.y_for(bar.low)
        _set(ctx, _alpha(view.theme.bull, 40))
        _filled_rect_minmax(ctx, x - half, y_high, x + half, y_low)


# =============================================================================
# Dispatch — port of mod.rs `render_chart_type`
# =============================================================================

fn draw_series(ctx: RenderingContextInt, view: RenderView, bars: List[Bar],
               ct: ChartType):
    """Dispatch to the renderer for chart type `ct` (port of `render_chart_type`).

    The Japanese/Range types run their transform internally (renderers owns the
    `transforms` dependency per the integration contract), so the engine always
    passes the raw visible `bars`.  Line/area types default to the Close source.
    """
    var id = ct.id
    if id == CT_CANDLES:
        draw_candles(ctx, view, bars)
    elif id == CT_BARS:
        draw_ohlc_bars(ctx, view, bars)
    elif id == CT_HOLLOW_CANDLES:
        draw_hollow_candles(ctx, view, bars)
    elif id == CT_VOLUME_CANDLES:
        draw_volume_candles(ctx, view, bars)
    elif id == CT_HEIKIN:
        draw_heikin_ashi(ctx, view, bars)
    elif id == CT_LINE:
        draw_line(ctx, view, bars, PS_CLOSE)
    elif id == CT_LINE_WITH_MARKERS:
        draw_line_with_markers(ctx, view, bars, PS_CLOSE)
    elif id == CT_STEP_LINE:
        draw_step_line(ctx, view, bars, PS_CLOSE)
    elif id == CT_AREA:
        draw_area(ctx, view, bars, PS_CLOSE)
    elif id == CT_HLC_AREA:
        draw_hlc_area(ctx, view, bars, PS_CLOSE)
    elif id == CT_BASELINE:
        draw_baseline(ctx, view, bars, PS_CLOSE)
    elif id == CT_HIGH_LOW:
        draw_high_low(ctx, view, bars)
    elif id == CT_RANGE:
        draw_range_bars(ctx, view, bars)
    elif id == CT_RENKO:
        draw_renko(ctx, view, bars)
    elif id == CT_KAGI:
        draw_kagi(ctx, view, bars)
    elif id == CT_LINE_BREAK:
        draw_line_break(ctx, view, bars)
    elif id == CT_POINT_AND_FIGURE:
        draw_point_and_figure(ctx, view, bars)
    elif id == CT_VOLUME_FOOTPRINT:
        draw_volume_footprint(ctx, view, bars)
    elif id == CT_TIME_PRICE_OPPORTUNITY:
        draw_tpo(ctx, view, bars)
    elif id == CT_SESSION_VOLUME:
        draw_session_volume(ctx, view, bars)
    else:
        draw_candles(ctx, view, bars)
