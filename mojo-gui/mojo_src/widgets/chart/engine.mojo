"""
ChartInt — the core charting widget (pan / zoom / crosshair / grid / axes).

Port of egui-charts `src/chart/` engine, modeled structurally on the repo's
`node_graph_int.mojo` (pan/zoom + coordinate mapping + `_draw_grid` + factory),
but rewritten for the **Mojo 0.26.2 nightly** conventions verified by
builder-foundation (see chart/PORT_SPEC.md "VERIFIED CONVENTIONS"):

  - `out self` / `mut self` (never `inout self`).
  - `comptime` instead of `alias`.
  - **No struct inheritance** — `struct X(BaseWidgetInt)` is a hard error in this
    nightly, so ChartInt *composes* its own `x/y/width/height/visible/enabled`
    fields directly instead of inheriting `BaseWidgetInt`.
  - Every `RenderingContextInt` draw call returns `Bool`; results are discarded
    with `_ =`.

Ported from:
  - /tmp/egui-charts-ref/src/chart/pan_zoom.rs      -> drag-pan / wheel-zoom logic
  - /tmp/egui-charts-ref/src/chart/coords/mod.rs    -> idx<->x / price<->y formulas
  - /tmp/egui-charts-ref/src/chart/helpers.rs       -> y_to_price / apply_price_zoom
  - /tmp/egui-charts-ref/src/chart/state.rs         -> interaction state fields
  - /tmp/egui-charts-ref/src/scales/pricescale.rs   -> auto-fit price domain

Coordinate mapping is implemented **inline** here for now (see the canonical
formula from coords/mod.rs reproduced in `bar_index_to_x`).  When `scales.mojo`
lands it should expose `PriceScale`/`TimeScale` with these method names so the
inline math can be swapped out:
  - TimeScale:  `idx_to_x(idx) -> Float64`, `x_to_idx(x) -> Int`,
                `bar_spacing() -> Float64`, `right_offset() -> Float64`,
                `set_right_offset(v)`, `set_bar_spacing(v)`.
  - PriceScale: `price_to_coord(price) -> Float64`, `coord_to_price(y) -> Float64`,
                `auto_scale(data_min, data_max)`, `set_manual_range(min, max)`.
Every such spot is tagged `# TODO use scales.mojo`.

The per-ChartType series drawing (candles/line/area/...) is owned by
`renderers.mojo` (builder-renderers).  ChartInt draws only grid/axes/crosshair
and then delegates series drawing through `_draw_series`, which builds a
contract `RenderView` (geometry + price/index map + theme) and calls
`draw_series`.  ChartInt does NOT duplicate any renderer.
"""

from ...rendering_int import RenderingContextInt, ColorInt, PointInt, SizeInt, RectInt
from ...widget_int import MouseEventInt, KeyEventInt
from .model import Bar, BarData, ChartType, CT_CANDLES
from .renderers import draw_series, RenderView
from .theme import ChartTheme
from .config import ChartConfig
from .scales import PriceMarkGenerator, PriceMark

# Mouse buttons (match widget_constants.mojo / GLFW).
comptime MB_LEFT: Int32 = 0
comptime MB_RIGHT: Int32 = 1
comptime MB_MIDDLE: Int32 = 2

# Key codes used for keyboard pan/zoom (GLFW codes, see widget_constants.mojo).
comptime KEY_LEFT: Int32 = 263
comptime KEY_RIGHT: Int32 = 262
comptime KEY_EQUAL: Int32 = 61       # '=' / '+' : zoom in
comptime KEY_MINUS: Int32 = 45       # '-'       : zoom out
comptime KEY_R: Int32 = 82           # 'R'       : reset / auto-scale + jump latest
comptime KEY_G: Int32 = 71           # 'G'       : toggle grid
comptime KEY_C: Int32 = 67           # 'C'       : toggle crosshair

# Bar-spacing limits in pixels (port of ChartOptions.time_scale min/max_bar_spacing).
comptime MIN_BAR_SPACING: Float64 = 1.0
comptime MAX_BAR_SPACING: Float64 = 100.0
comptime DEFAULT_BAR_SPACING: Float64 = 8.0
comptime DEFAULT_RIGHT_OFFSET: Float64 = 2.5
"""Bars of empty whitespace kept at the right edge after a reset (port of the
Rust default right_offset; skeptic #7 — reset_view used to slam to 0.0)."""

# Axis gutter sizes in pixels (price labels on the right, time labels at bottom).
comptime PRICE_AXIS_WIDTH: Int32 = 60
comptime TIME_AXIS_HEIGHT: Int32 = 22


struct ChartInt(Copyable, Movable):
    """Core chart widget: pan, zoom, hit-test, crosshair, grid and axes.

    Composes its own bounds/visibility (cannot inherit `BaseWidgetInt` under the
    current nightly).  Holds the bar data, the active `ChartType`, the viewport
    (time + price) state, and crosshair state.

    Declared `(Copyable, Movable)` — `ColorInt` (from `rendering_int.mojo`) is
    `ImplicitlyCopyable, Movable` and the owned `BarData` is `Copyable, Movable`,
    so the conformances synthesize.  It cannot be `ImplicitlyCopyable` because
    `BarData` owns a `List` (not implicitly copyable); copies are explicit.  The
    builder/`create_chart_int` move a freshly-built `ChartInt` out with `^`.
    """

    # ----- Widget bounds (replacing BaseWidgetInt inheritance) -------------
    var id: Int32
    var x: Int32
    var y: Int32
    var width: Int32
    var height: Int32
    var visible: Bool
    var enabled: Bool

    # ----- Data + chart type ----------------------------------------------
    var data: BarData
    """The OHLCV series being charted."""
    var chart_type: ChartType
    """Active visualization type (one of the CT_* constants)."""
    var theme: ChartTheme
    """Active resolved color theme (handed to renderers via `RenderView`).

    Kept in addition to the unpacked palette fields below so the engine can hand
    a full `ChartTheme` to `draw_series`; `set_theme`/`set_theme_colors` keep the
    two representations in sync."""
    var baseline_value: Float64
    """Reference value for Baseline charts (from `ChartConfig.baseline`, default
    0.0); passed into the `RenderView` so the baseline renderer splits color at
    `value >= baseline` rather than the first visible value (skeptic #5)."""

    # ----- Time-axis view state (port of TimeScale fields) -----------------
    # We track `right_offset` in fractional bar units and `bar_spacing` in
    # pixels, exactly like the Rust TimeScale.  `right_offset` is how many bars
    # past the last bar the right edge sits (positive = empty margin on right).
    var bar_spacing: Float64
    """Horizontal spacing between consecutive bars, in pixels."""
    var right_offset: Float64
    """Right-edge offset in bar units past the last bar (scroll position)."""

    # ----- Price-axis view state (port of PriceScale auto-scale) -----------
    var price_auto: Bool
    """When true, the price domain auto-fits the visible bars each frame."""
    var price_min: Float64
    """Current bottom-of-chart price (valid when `price_auto` is false)."""
    var price_max: Float64
    """Current top-of-chart price (valid when `price_auto` is false)."""

    # ----- Interaction state (port of chart/state.rs scroll_* fields) ------
    var dragging: Bool
    var drag_button: Int32
    var drag_start_x: Int32
    var drag_start_y: Int32
    var drag_start_offset: Float64
    var drag_start_pmin: Float64
    var drag_start_pmax: Float64

    # ----- Crosshair state -------------------------------------------------
    var show_crosshair: Bool
    var crosshair_active: Bool
    var crosshair_x: Int32
    var crosshair_y: Int32

    # ----- Grid toggle -----------------------------------------------------
    var show_grid: Bool

    # ----- Colors (overridable by theme.mojo via the setters below) --------
    var background_color: ColorInt
    var grid_color: ColorInt
    var axis_color: ColorInt
    var text_color: ColorInt
    var crosshair_color: ColorInt
    var bull_color: ColorInt
    var bear_color: ColorInt

    # ----- Legend labels (set by builder via the contract setters) ---------
    var symbol_label: String
    """Trading-symbol legend text (e.g. "BTCUSDT"); empty when unset."""
    var timeframe_label: String
    """Timeframe legend text (e.g. "1h"); empty when unset."""

    fn __init__(out self, x: Int32, y: Int32, width: Int32, height: Int32):
        self.id = 0
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.visible = True
        self.enabled = True

        self.data = BarData()
        self.chart_type = ChartType(CT_CANDLES)
        self.theme = ChartTheme.dark()
        self.baseline_value = 0.0

        self.bar_spacing = DEFAULT_BAR_SPACING
        self.right_offset = 0.0

        self.price_auto = True
        self.price_min = 0.0
        self.price_max = 1.0

        self.dragging = False
        self.drag_button = -1
        self.drag_start_x = 0
        self.drag_start_y = 0
        self.drag_start_offset = 0.0
        self.drag_start_pmin = 0.0
        self.drag_start_pmax = 1.0

        self.show_crosshair = True
        self.crosshair_active = False
        self.crosshair_x = 0
        self.crosshair_y = 0

        self.show_grid = True

        # Default dark theme (theme.mojo can override via set_theme_colors).
        self.background_color = ColorInt(22, 26, 33, 255)
        self.grid_color = ColorInt(40, 46, 56, 255)
        self.axis_color = ColorInt(70, 78, 92, 255)
        self.text_color = ColorInt(200, 208, 220, 255)
        self.crosshair_color = ColorInt(130, 140, 160, 200)
        self.bull_color = ColorInt(38, 166, 130, 255)
        self.bear_color = ColorInt(220, 70, 90, 255)

        self.symbol_label = String("")
        self.timeframe_label = String("")

    # =====================================================================
    # Data / configuration
    # =====================================================================

    fn set_data(mut self, data: BarData):
        """Replace the chart's bar data (copies; BarData isn't implicitly copyable)."""
        self.data = data.copy()

    fn add_bar(mut self, bar: Bar):
        """Append a single bar to the dataset."""
        self.data.push(bar)

    fn set_chart_type(mut self, ct: ChartType):
        """Set the active chart type."""
        self.chart_type = ct

    fn set_theme_colors(mut self, background: ColorInt, grid: ColorInt,
                        axis: ColorInt, text: ColorInt, crosshair: ColorInt,
                        bull: ColorInt, bear: ColorInt):
        """Apply a theme's palette (called by theme.mojo / builder.mojo)."""
        self.background_color = background
        self.grid_color = grid
        self.axis_color = axis
        self.text_color = text
        self.crosshair_color = crosshair
        self.bull_color = bull
        self.bear_color = bear

    # =====================================================================
    # INTEGRATION_CONTRACT setters (consumed by builder.mojo / demo)
    # =====================================================================
    # The engine's native palette/data API is `set_theme_colors` + `set_data`;
    # these thin shims map the contract's higher-level types onto it so the
    # builder can stay theme/config-aware without the engine duplicating fields.

    fn set_bars(mut self, var bars: List[Bar]):
        """Replace the chart data from an owned `List[Bar]` (contract name).

        Mirrors `set_data` but takes ownership of a bare list (what the contract
        and harness hand in); moves each bar into a fresh `BarData`.
        """
        var d = BarData()
        for i in range(len(bars)):
            d.push(bars[i])
        self.data = d^

    fn set_theme(mut self, theme: ChartTheme):
        """Apply a `ChartTheme`: store it and unpack onto the engine palette."""
        self.theme = theme
        self.set_theme_colors(theme.background, theme.grid, theme.axis,
                              theme.text, theme.crosshair, theme.bull,
                              theme.bear)

    fn set_config(mut self, cfg: ChartConfig):
        """Apply the contract `ChartConfig` visibility toggles + baseline value."""
        self.show_grid = cfg.show_grid
        self.show_crosshair = cfg.show_crosshair
        self.baseline_value = cfg.baseline

    fn set_visible_bars(mut self, n: Int):
        """Set the initial viewport bar count (contract `set_visible_bars`).

        The engine has no explicit visible-bar field; it derives the view from
        `bar_spacing`.  Convert `n` to a pixel pitch so ~`n` bars fill the plot
        width, matching the Rust `set_visible_bars` behavior.
        """
        if n > 0:
            var pitch = Float64(self.plot_width()) / Float64(n)
            if pitch < MIN_BAR_SPACING:
                pitch = MIN_BAR_SPACING
            if pitch > MAX_BAR_SPACING:
                pitch = MAX_BAR_SPACING
            self.bar_spacing = pitch

    fn set_symbol_label(mut self, s: String):
        """Set the symbol legend label (contract `set_symbol_label`)."""
        self.symbol_label = s

    fn set_timeframe_label(mut self, s: String):
        """Set the timeframe legend label (contract `set_timeframe_label`)."""
        self.timeframe_label = s

    # =====================================================================
    # Plot rectangle helpers (chart area excludes the axis gutters)
    # =====================================================================

    fn plot_x(self) -> Int32:
        """Left edge of the price/bar plotting area."""
        return self.x

    fn plot_y(self) -> Int32:
        """Top edge of the plotting area."""
        return self.y

    fn plot_width(self) -> Int32:
        """Width of the plotting area (full width minus the right price gutter)."""
        var w = self.width - PRICE_AXIS_WIDTH
        return w if w > 1 else 1

    fn plot_height(self) -> Int32:
        """Height of the plotting area (full height minus the bottom time gutter)."""
        var h = self.height - TIME_AXIS_HEIGHT
        return h if h > 1 else 1

    fn plot_right(self) -> Int32:
        """Right edge x of the plotting area (start of the price gutter)."""
        return self.x + self.plot_width()

    fn plot_bottom(self) -> Int32:
        """Bottom edge y of the plotting area (start of the time gutter)."""
        return self.y + self.plot_height()

    # =====================================================================
    # Coordinate mapping  (# TODO use scales.mojo: TimeScale / PriceScale)
    # =====================================================================
    # Canonical formula, faithful to coords/mod.rs::ChartMapping:
    #   delta_from_right = base_idx + right_offset - bar_idx
    #   x = rect.min.x + rect.width - (delta_from_right + 0.5) * bar_spacing - 1
    # Here `base_idx` is the last bar index (len - 1); `right_offset` mirrors the
    # Rust field of the same name.

    fn _base_idx(self) -> Float64:
        """Index of the last bar (anchor for x mapping); 0 if empty."""
        var n = self.data.len()
        if n == 0:
            return 0.0
        return Float64(n - 1)

    fn bar_index_to_x(self, bar_idx: Int) -> Int32:
        """Map a bar index to its center X pixel (port of `ChartMapping::idx_to_x`).

        # TODO use scales.mojo -> TimeScale.idx_to_x(bar_idx).
        """
        var delta_from_right = self._base_idx() + self.right_offset - Float64(bar_idx)
        var relative_x = Float64(self.plot_width()) - (delta_from_right + 0.5) * self.bar_spacing - 1.0
        return self.plot_x() + Int32(relative_x)

    fn x_to_bar_index(self, x: Int32) -> Int:
        """Map an X pixel to the nearest bar index (port of `ChartMapping::x_to_idx`).

        # TODO use scales.mojo -> TimeScale.x_to_idx(x).
        """
        if self.bar_spacing < 1e-9:
            return Int(self._base_idx())
        var relative_x = Float64(x - self.plot_x())
        var delta_from_right = (Float64(self.plot_width()) - relative_x - 1.0) / self.bar_spacing - 0.5
        var bar_idx = self._base_idx() + self.right_offset - delta_from_right
        # round to nearest
        return Int(bar_idx + 0.5) if bar_idx >= 0.0 else Int(bar_idx - 0.5)

    fn price_to_y(self, price: Float64) -> Int32:
        """Map a price to its Y pixel (top = price_max, bottom = price_min).

        Inverse of `y_to_price`; faithful to helpers.rs linear mapping.
        # TODO use scales.mojo -> PriceScale.price_to_coord(price).
        """
        var pmin = self.price_min
        var pmax = self.price_max
        var rng = pmax - pmin
        if rng < 1e-12:
            rng = 1e-12
        var ratio = (price - pmin) / rng          # 0 at bottom, 1 at top
        var h = Float64(self.plot_height())
        # y grows downward: top (ratio=1) -> plot_y, bottom (ratio=0) -> plot_bottom
        var y = Float64(self.plot_bottom()) - ratio * h
        return Int32(y)

    fn y_to_price(self, y: Int32) -> Float64:
        """Map a Y pixel to a price (port of `helpers::y_to_price`).

        # TODO use scales.mojo -> PriceScale.coord_to_price(y).
        """
        var h = Float64(self.plot_height())
        if h < 1.0:
            h = 1.0
        var ratio = (Float64(self.plot_bottom()) - Float64(y)) / h
        if ratio < 0.0:
            ratio = 0.0
        if ratio > 1.0:
            ratio = 1.0
        return self.price_min + ratio * (self.price_max - self.price_min)

    # =====================================================================
    # Visible range + price auto-fit (port of pricescale.rs::auto_scale)
    # =====================================================================

    fn first_visible_index(self) -> Int:
        """Index of the leftmost (partially) visible bar, clamped to data."""
        var idx = self.x_to_bar_index(self.plot_x())
        if idx < 0:
            return 0
        var n = self.data.len()
        if idx >= n:
            return n - 1 if n > 0 else 0
        return idx

    fn last_visible_index(self) -> Int:
        """Index of the rightmost (partially) visible bar, clamped to data."""
        var idx = self.x_to_bar_index(self.plot_right())
        var n = self.data.len()
        if idx >= n:
            return n - 1 if n > 0 else 0
        if idx < 0:
            return 0
        return idx

    fn bars_visible(self) -> Int:
        """Approximate count of bars across the plotting area."""
        if self.bar_spacing < 1e-9:
            return 0
        return Int(Float64(self.plot_width()) / self.bar_spacing)

    fn auto_fit_price(mut self):
        """Recompute `price_min`/`price_max` from the visible bars' high/low.

        Faithful to `PriceScale::auto_scale`: pad the [data_min, data_max] range
        by a small fraction so wicks are not flush against the chart edges.  Only
        runs when `price_auto` is enabled.
        """
        if not self.price_auto:
            return
        var n = self.data.len()
        if n == 0:
            self.price_min = 0.0
            self.price_max = 1.0
            return

        var lo = self.first_visible_index()
        var hi = self.last_visible_index()
        if hi < lo:
            var t = lo
            lo = hi
            hi = t

        var dmin = self.data.bars[lo].low
        var dmax = self.data.bars[lo].high
        for i in range(lo, hi + 1):
            var b = self.data.bars[i]
            if b.low < dmin:
                dmin = b.low
            if b.high > dmax:
                dmax = b.high

        var rng = dmax - dmin
        if rng < 1e-9:
            # Degenerate (flat) range: pad around the single value.
            rng = abs(dmax) if dmax != 0.0 else 1.0
        # Asymmetric margins faithful to pricescale.rs:227-230 (skeptic #6):
        #   price_min = data_min - range*bottom(0.1); price_max = data_max + range*top(0.2)
        # Matches scales.PriceScale.margin_top/margin_bottom defaults.
        self.price_min = dmin - rng * 0.1
        self.price_max = dmax + rng * 0.2

    # =====================================================================
    # Pan / zoom primitives (port of pan_zoom.rs)
    # =====================================================================

    fn pan_by_pixels(mut self, dx_pixels: Int32):
        """Pan horizontally by a pixel delta (port of drag-pan time-axis branch).

        `drag_in_bars = dx / bar_spacing`; `new_offset = start_offset - drag_in_bars`.
        Positive `dx` (drag right) reveals older bars on the left.
        """
        if self.bar_spacing < 1e-9:
            return
        var drag_in_bars = Float64(dx_pixels) / self.bar_spacing
        self.right_offset = self.right_offset - drag_in_bars

    fn zoom_time(mut self, zoom_scale: Float64, anchor_x: Int32):
        """Zoom the time axis about `anchor_x` (port of `TimeScale::zoom`).

        `zoom_scale` in [-0.5, 0.5]; positive zooms in (bars spread out).  The
        bar under `anchor_x` is kept fixed by adjusting `right_offset`.
        # TODO use scales.mojo -> TimeScale.zoom(...).
        """
        var old_spacing = self.bar_spacing
        if old_spacing < 1e-9:
            old_spacing = MIN_BAR_SPACING

        # Bar (fractional) currently under the anchor, before zoom.
        var rel_x = Float64(anchor_x - self.plot_x())
        var delta_from_right = (Float64(self.plot_width()) - rel_x - 1.0) / old_spacing - 0.5
        var anchor_idx = self._base_idx() + self.right_offset - delta_from_right

        # Faithful to timescale.rs:281 `old + zoom_scale*(old/10)` — the /10
        # keeps the wheel from being 10x too sensitive (skeptic finding #1).
        var new_spacing = old_spacing + zoom_scale * (old_spacing / 10.0)
        if new_spacing < MIN_BAR_SPACING:
            new_spacing = MIN_BAR_SPACING
        if new_spacing > MAX_BAR_SPACING:
            new_spacing = MAX_BAR_SPACING
        self.bar_spacing = new_spacing

        # Recompute right_offset so `anchor_idx` stays under `anchor_x`.
        var new_delta = (Float64(self.plot_width()) - rel_x - 1.0) / new_spacing - 0.5
        self.right_offset = anchor_idx - self._base_idx() + new_delta

    fn zoom_price(mut self, delta_y: Float64, anchor_y: Int32):
        """Zoom the price axis about the price under `anchor_y`.

        Port of `helpers::apply_price_zoom`: exponential response, range clamped
        to 5%..2000% of the original.  Disables auto-fit so the manual range
        sticks (matches Rust pushing a manual price range).
        """
        var pmin = self.price_min
        var pmax = self.price_max
        var rng = pmax - pmin
        if rng < 1e-12:
            rng = 1e-12

        var anchor = self.y_to_price(anchor_y)
        # scale = exp(-delta_y / height); positive delta_y -> zoom out.
        var h = Float64(self.plot_height())
        if h < 1.0:
            h = 1.0
        var scale = _exp(-delta_y / h)
        var new_range = rng / scale
        if new_range < rng * 0.05:
            new_range = rng * 0.05
        if new_range > rng * 20.0:
            new_range = rng * 20.0

        var t = (anchor - pmin) / rng
        if t < 0.0:
            t = 0.0
        if t > 1.0:
            t = 1.0
        self.price_min = anchor - t * new_range
        self.price_max = self.price_min + new_range
        self.price_auto = False

    fn reset_view(mut self):
        """Jump to the latest bar, reset spacing, and re-enable price auto-fit.

        Port of double-click reset: `jump_to_latest` + re-enable auto-scale.
        Keeps `DEFAULT_RIGHT_OFFSET` bars of right-edge whitespace (skeptic #7).
        """
        self.right_offset = DEFAULT_RIGHT_OFFSET
        self.bar_spacing = DEFAULT_BAR_SPACING
        self.price_auto = True
        self.auto_fit_price()

    # =====================================================================
    # Event handling
    # =====================================================================

    fn contains_point(self, px: Int32, py: Int32) -> Bool:
        """True if a pixel is within the full widget bounds."""
        return (px >= self.x and px < self.x + self.width
                and py >= self.y and py < self.y + self.height)

    fn on_mouse_move(mut self, px: Int32, py: Int32):
        """Continuous pointer-move hook (the demo loop polls mouse each frame).

        Updates the crosshair and applies any in-progress drag.  `MouseEventInt`
        carries no move event, so the demo/builder calls this every frame with
        the current mouse position (see node_graph_demo's poll loop).
        """
        # Crosshair tracks the pointer while it is over the plotting area.
        if (self.show_crosshair and px >= self.plot_x() and px < self.plot_right()
                and py >= self.plot_y() and py < self.plot_bottom()):
            self.crosshair_active = True
            self.crosshair_x = px
            self.crosshair_y = py
        else:
            self.crosshair_active = False

        if not self.dragging:
            return

        if self.drag_button == MB_LEFT:
            # Left-drag pans time; if the drag started over the price gutter,
            # also rescale price (handled by drag_start in price space).
            var dx = px - self.drag_start_x
            self.right_offset = self.drag_start_offset - Float64(dx) / _nz(self.bar_spacing)
        elif self.drag_button == MB_RIGHT:
            # Right-drag rescales the price axis vertically (vertical zoom).
            var dy = py - self.drag_start_y
            self.price_auto = False
            var span = self.drag_start_pmax - self.drag_start_pmin
            # Drag down -> compress range (zoom in); drag up -> expand.
            var factor = _exp(Float64(dy) / _nz(Float64(self.plot_height())))
            var new_span = span * factor
            var mid = (self.drag_start_pmin + self.drag_start_pmax) * 0.5
            self.price_min = mid - new_span * 0.5
            self.price_max = mid + new_span * 0.5

    fn handle_mouse_event(mut self, event: MouseEventInt) -> Bool:
        """Handle a mouse button press/release (WidgetInt-style).

        `MouseEventInt` here is `(x, y, button, pressed)` — there is no move or
        scroll event, so continuous drag + crosshair live in `on_mouse_move`, and
        wheel zoom is exposed via `zoom_time`/`zoom_price` for the loop to call.
        """
        if not self.enabled or not self.visible:
            return False

        if event.pressed:
            if not self.contains_point(event.x, event.y):
                return False
            self.dragging = True
            self.drag_button = event.button
            self.drag_start_x = event.x
            self.drag_start_y = event.y
            self.drag_start_offset = self.right_offset
            self.drag_start_pmin = self.price_min
            self.drag_start_pmax = self.price_max
            return True
        else:
            # Button released.
            if self.dragging:
                self.dragging = False
                self.drag_button = -1
                return True
            return False

    fn handle_key_event(mut self, event: KeyEventInt) -> Bool:
        """Handle keyboard pan/zoom (WidgetInt-style).

        `KeyEventInt` is `(key_code, pressed)`.  Arrows pan one bar; +/- zoom the
        time axis about the chart center; R resets, G toggles grid, C toggles
        crosshair.
        """
        if not event.pressed:
            return False

        var center_x = self.plot_x() + self.plot_width() // 2

        if event.key_code == KEY_LEFT:
            self.right_offset = self.right_offset - 1.0
            return True
        if event.key_code == KEY_RIGHT:
            self.right_offset = self.right_offset + 1.0
            return True
        if event.key_code == KEY_EQUAL:
            self.zoom_time(0.25, center_x)
            return True
        if event.key_code == KEY_MINUS:
            self.zoom_time(-0.25, center_x)
            return True
        if event.key_code == KEY_R:
            self.reset_view()
            return True
        if event.key_code == KEY_G:
            self.show_grid = not self.show_grid
            return True
        if event.key_code == KEY_C:
            self.show_crosshair = not self.show_crosshair
            if not self.show_crosshair:
                self.crosshair_active = False
            return True
        return False

    fn update(mut self):
        """Per-frame update: keep the price domain fitted to the viewport."""
        self.auto_fit_price()

    # =====================================================================
    # Rendering
    # =====================================================================

    fn render(self, ctx: RenderingContextInt):
        """Render the full chart (background, grid, series, axes, crosshair)."""
        self.draw(ctx)

    fn draw(self, ctx: RenderingContextInt):
        """Draw background, grid, series (delegated), axes, then crosshair."""
        if not self.visible:
            return

        # Background.
        _ = ctx.set_color(self.background_color.r, self.background_color.g,
                          self.background_color.b, self.background_color.a)
        _ = ctx.draw_filled_rectangle(self.x, self.y, self.width, self.height)

        if self.show_grid:
            self._draw_grid(ctx)

        # Series drawing is owned by renderers.mojo; ChartInt only provides the
        # hook + viewport.  See _draw_series.
        self._draw_series(ctx)

        self._draw_axes(ctx)

        if self.show_crosshair and self.crosshair_active:
            self._draw_crosshair(ctx)

    fn _draw_series(self, ctx: RenderingContextInt):
        """RENDERERS-HOOK: delegate per-ChartType drawing to `renderers.mojo`.

        Builds a contract `RenderView` describing the current viewport and hands
        the visible bar slice to `draw_series` (the dispatch in renderers.mojo).

        Coordinate reconciliation (important — read before changing):
        renderers map `x = view.x_for(i) = area_x + (i - first_idx)*bar_width +
        bar_width//2` for the bar at local index `i` of the passed `bars`.  We
        pass the *visible slice* as `bars` (so renderers see indices 0..count),
        set `first_idx = 0`, `bar_width = round(bar_spacing)`, and set `area_x =
        bar_index_to_x(lo) - bar_width//2` so local index 0 lands on the global
        `lo` bar's center — i.e. the renderer x's line up with engine pan/zoom.

        Transform-output types (Renko/Kagi/LineBreak/Range/PnF) run their
        transform internally in renderers (renderers owns `transforms` per the
        contract), so the raw visible slice is always the correct input.
        """
        var n = self.data.len()
        if n == 0:
            return

        var lo = self.first_visible_index()
        var hi = self.last_visible_index()
        if hi < lo:
            var t = lo
            lo = hi
            hi = t

        # Visible slice as a fresh List[Bar] (renderers index it 0-based locally).
        var visible = List[Bar]()
        for i in range(lo, hi + 1):
            visible.append(self.data.bars[i])

        # Pixel pitch per bar slot (>=1px); the contract RenderView uses one
        # integer bar_width for both spacing and the x_for stride.
        var bar_w = Int32(self.bar_spacing)
        if bar_w < 1:
            bar_w = 1

        # Calibrate area_x so renderers' local index 0 lands on the engine's
        # global `lo` bar center (x_for adds bar_width//2 back).
        var area_x = self.bar_index_to_x(lo) - bar_w // 2

        var view = RenderView(
            area_x, self.plot_y(), self.plot_width(), self.plot_height(),
            0, len(visible), bar_w,
            self.price_min, self.price_max,
            self.theme, self.baseline_value,
        )

        draw_series(ctx, view, visible, self.chart_type)

    fn _draw_grid(self, ctx: RenderingContextInt):
        """Draw the background price/time grid (port of rendering grid pass).

        Vertical lines at visible bar boundaries (spaced so labels stay legible);
        horizontal lines at the same price levels used by the price axis.
        """
        _ = ctx.set_color(self.grid_color.r, self.grid_color.g,
                          self.grid_color.b, self.grid_color.a)

        # Vertical grid lines: step in pixels so they don't crowd at small spacing.
        var step = Int32(self.bar_spacing)
        # Aim for ~60px between gridlines.
        var mult: Int32 = 1
        while step * mult < 60 and mult < 1000:
            mult += 1
        var px_step = step * mult
        if px_step < 20:
            px_step = 60

        var gx = self.plot_x()
        while gx < self.plot_right():
            _ = ctx.draw_line(gx, self.plot_y(), gx, self.plot_bottom(), 1)
            gx += px_step

        # Horizontal grid lines at nice-number price levels (skeptic #8) via the
        # ported PriceMarkGenerator, instead of a fixed 5-way split.  Falls back
        # to a 5-division split if the generator yields nothing (degenerate range).
        var gen = PriceMarkGenerator()
        var marks = gen.generate_marks(
            self.price_min, self.price_max, Float64(self.plot_height()),
            0,  # PS_NORMAL — engine price_to_y is linear
            Float64(self.plot_y()), Float64(self.plot_bottom()),
        )
        if len(marks) > 0:
            for i in range(len(marks)):
                var yy = Int32(marks[i].y_coord)
                _ = ctx.draw_line(self.plot_x(), yy, self.plot_right(), yy, 1)
        else:
            var divisions: Int32 = 5
            for i in range(divisions + 1):
                var yy = self.plot_y() + (self.plot_height() * i) // divisions
                _ = ctx.draw_line(self.plot_x(), yy, self.plot_right(), yy, 1)

    fn _draw_axes(self, ctx: RenderingContextInt):
        """Draw the price axis (right) and time axis (bottom) with labels."""
        # Axis frame lines.
        _ = ctx.set_color(self.axis_color.r, self.axis_color.g,
                          self.axis_color.b, self.axis_color.a)
        # Right (price) gutter divider.
        _ = ctx.draw_line(self.plot_right(), self.plot_y(),
                          self.plot_right(), self.plot_bottom(), 1)
        # Bottom (time) gutter divider.
        _ = ctx.draw_line(self.plot_x(), self.plot_bottom(),
                          self.plot_right(), self.plot_bottom(), 1)

        # ----- Price labels on the right gutter at nice-number levels -----
        # Uses the ported PriceMarkGenerator (skeptic #8) so labels land on round
        # prices and align with the horizontal gridlines.  Falls back to a fixed
        # 5-division split for a degenerate range.
        _ = ctx.set_color(self.text_color.r, self.text_color.g,
                          self.text_color.b, self.text_color.a)
        var gen = PriceMarkGenerator()
        var pmarks = gen.generate_marks(
            self.price_min, self.price_max, Float64(self.plot_height()),
            0,  # PS_NORMAL
            Float64(self.plot_y()), Float64(self.plot_bottom()),
        )
        if len(pmarks) > 0:
            for i in range(len(pmarks)):
                var yy = Int32(pmarks[i].y_coord)
                # Keep labels inside the plot vertically.
                var ty = yy - 6
                if ty < self.plot_y():
                    ty = self.plot_y() + 1
                if ty > self.plot_bottom() - 12:
                    ty = self.plot_bottom() - 12
                _ = ctx.draw_text(pmarks[i].label, self.plot_right() + 4, ty, 10)
        else:
            var divisions: Int32 = 5
            for i in range(divisions + 1):
                var yy = self.plot_y() + (self.plot_height() * i) // divisions
                var ratio = 1.0 - Float64(i) / Float64(divisions)
                var price = self.price_min + ratio * (self.price_max - self.price_min)
                var label = _format_price(price)
                var ty = yy - 6
                if i == 0:
                    ty = yy + 1
                if i == divisions:
                    ty = yy - 12
                _ = ctx.draw_text(label, self.plot_right() + 4, ty, 10)

        # ----- Time labels along the bottom gutter -------------------------
        var n = self.data.len()
        if n > 0:
            var lo = self.first_visible_index()
            var hi = self.last_visible_index()
            if hi < lo:
                var t = lo
                lo = hi
                hi = t
            # Up to 6 evenly spaced index ticks across the visible range.
            var ticks: Int = 6
            for k in range(ticks + 1):
                var idx = lo + (hi - lo) * k // ticks
                if idx < 0 or idx >= n:
                    continue
                var tx = self.bar_index_to_x(idx)
                if tx < self.plot_x() or tx > self.plot_right():
                    continue
                var tlabel = _format_time(self.data.bars[idx].time)
                _ = ctx.set_color(self.text_color.r, self.text_color.g,
                                  self.text_color.b, self.text_color.a)
                # Center the label under the tick (approx 6px/char at size 10).
                var half = Int32(len(tlabel) * 3)
                _ = ctx.draw_text(tlabel, tx - half, self.plot_bottom() + 4, 10)

    fn _draw_crosshair(self, ctx: RenderingContextInt):
        """Draw the crosshair lines and the price/time readout labels."""
        var cx = self.crosshair_x
        var cy = self.crosshair_y

        _ = ctx.set_color(self.crosshair_color.r, self.crosshair_color.g,
                          self.crosshair_color.b, self.crosshair_color.a)
        # Vertical line through the plotting area.
        _ = ctx.draw_line(cx, self.plot_y(), cx, self.plot_bottom(), 1)
        # Horizontal line through the plotting area.
        _ = ctx.draw_line(self.plot_x(), cy, self.plot_right(), cy, 1)

        # Price readout on the right gutter at the crosshair height.
        var price = self.y_to_price(cy)
        var plabel = _format_price(price)
        _ = ctx.set_color(self.text_color.r, self.text_color.g,
                          self.text_color.b, self.text_color.a)
        # Small filled chip behind the price label for legibility.
        _ = ctx.set_color(self.axis_color.r, self.axis_color.g,
                          self.axis_color.b, 255)
        _ = ctx.draw_filled_rectangle(self.plot_right() + 1, cy - 7, PRICE_AXIS_WIDTH - 2, 14)
        _ = ctx.set_color(self.text_color.r, self.text_color.g,
                          self.text_color.b, self.text_color.a)
        _ = ctx.draw_text(plabel, self.plot_right() + 4, cy - 6, 10)

        # Time readout on the bottom gutter under the crosshair.
        var n = self.data.len()
        if n > 0:
            var idx = self.x_to_bar_index(cx)
            if idx < 0:
                idx = 0
            if idx >= n:
                idx = n - 1
            var tlabel = _format_time(self.data.bars[idx].time)
            var half = Int32(len(tlabel) * 3)
            _ = ctx.set_color(self.axis_color.r, self.axis_color.g,
                              self.axis_color.b, 255)
            _ = ctx.draw_filled_rectangle(cx - half - 2, self.plot_bottom() + 1,
                                          half * 2 + 4, 14)
            _ = ctx.set_color(self.text_color.r, self.text_color.g,
                              self.text_color.b, self.text_color.a)
            _ = ctx.draw_text(tlabel, cx - half, self.plot_bottom() + 3, 10)


# =========================================================================
# Small numeric/format helpers (kept inline; no external deps)
# =========================================================================

fn _nz(v: Float64) -> Float64:
    """Return `v`, guarding against a zero divisor."""
    if v > -1e-9 and v < 1e-9:
        return 1e-9
    return v


fn _exp(x: Float64) -> Float64:
    """e**x via a clamped Taylor-ish range-reduction (no math import needed here).

    Used only for zoom feel; precision is non-critical.  Range-reduces by
    repeated squaring of e**(x/2^k) computed from a short series.
    """
    var v = x
    # Clamp to avoid overflow on extreme drags.
    if v > 20.0:
        v = 20.0
    if v < -20.0:
        v = -20.0
    var neg = v < 0.0
    if neg:
        v = -v
    # Range reduce: e**v = (e**(v/8))**8.
    var r = v / 8.0
    # 6-term Taylor series for e**r (r <= 2.5 -> good accuracy).
    var term = 1.0
    var sum = 1.0
    for i in range(1, 8):
        term = term * r / Float64(i)
        sum += term
    # Square three times -> raise to the 8th power.
    sum = sum * sum
    sum = sum * sum
    sum = sum * sum
    if neg:
        return 1.0 / sum
    return sum


fn _format_price(price: Float64) -> String:
    """Format a price with 2 decimals (placeholder for scales.mojo formatter).

    # TODO use scales.mojo -> price_formatter.format(price).
    """
    var p = price
    var sign = String("")
    if p < 0.0:
        sign = String("-")
        p = -p
    # Round to 2 decimals.
    var scaled = Int64(p * 100.0 + 0.5)
    var whole = scaled // 100
    var frac = scaled % 100
    var frac_str = String(frac)
    if frac < 10:
        frac_str = String("0") + frac_str
    return sign + String(whole) + "." + frac_str


fn _format_time(time_ms: Int64) -> String:
    """Format a bar timestamp (ms) into HH:MM (placeholder).

    Derives hour/minute from the epoch-ms value modulo a day.  A real
    calendar-aware formatter lives in scales.mojo.
    # TODO use scales.mojo -> time_formatter.format(time_ms, timeframe).
    """
    if time_ms <= 0:
        return String("--:--")
    var secs = time_ms // 1000
    var mins_total = secs // 60
    var minute = mins_total % 60
    var hour = (mins_total // 60) % 24
    var hh = String(hour)
    if hour < 10:
        hh = String("0") + hh
    var mm = String(minute)
    if minute < 10:
        mm = String("0") + mm
    return hh + ":" + mm


fn create_chart_int(x: Int32, y: Int32, width: Int32, height: Int32) -> ChartInt:
    """Factory: create a ChartInt with the given bounds (port of `create_*` idiom)."""
    return ChartInt(x, y, width, height)
