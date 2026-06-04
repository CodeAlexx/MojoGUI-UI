"""
Chart visual configuration — faithful port of egui-charts `src/config/`.

Ported from:
  - /tmp/egui-charts-ref/src/config/chart.rs       -> ChartConfig (visual options)
  - /tmp/egui-charts-ref/src/config/crosshair.rs   -> CrosshairOptions -> CrosshairConfig
  - /tmp/egui-charts-ref/src/scales/pricescale.rs  -> PriceScaleMode constants

Field set is fixed by INTEGRATION_CONTRACT.md.  The Rust `ChartConfig` carries
~60 fields (session breaks, watermark, realtime button, indicator-label
toggles, per-axis widths, ...) with no MojoGUI equivalent in phase 1; this port
keeps the minimal visual surface the engine consumes (grid / crosshair / axes
toggles, bar spacing, price-scale mode) plus a `CrosshairConfig`.  Deferred
fields are tracked in PORT_STATUS.md.

Conventions: `out self` init with Rust `Default`-equivalent values; `comptime`
constants for the C-like enums; `ImplicitlyCopyable, Movable`.
"""


# =============================================================================
# PriceScaleMode — port of scales/pricescale.rs  (enum PriceScaleMode)
# =============================================================================

comptime PS_NORMAL: Int32 = 0          # default — linear price range
comptime PS_LOGARITHMIC: Int32 = 1     # logarithmic price range
comptime PS_PERCENTAGE: Int32 = 2      # first visible value is 0%
comptime PS_INDEXED_TO_100: Int32 = 3  # like percentage, first value is 100


fn price_scale_mode_name(mode: Int32) -> String:
    """Display label for a price-scale mode (port of `PriceScaleMode::Display`)."""
    if mode == PS_NORMAL:          return String("Normal")
    if mode == PS_LOGARITHMIC:     return String("Logarithmic")
    if mode == PS_PERCENTAGE:      return String("Percentage")
    if mode == PS_INDEXED_TO_100:  return String("Indexed to 100")
    return String("Normal")


# =============================================================================
# CrosshairMode / CrosshairStyle / CrosshairLineStyle — config/crosshair.rs
# =============================================================================

comptime CH_MODE_NORMAL: Int32 = 0     # default — follows mouse exactly
comptime CH_MODE_MAGNET: Int32 = 1     # snaps to nearest OHLC point

comptime CH_STYLE_FULL: Int32 = 0      # default — vertical + horizontal lines
comptime CH_STYLE_DOT: Int32 = 1       # only a dot at the intersection
comptime CH_STYLE_ARROW: Int32 = 2     # no crosshair, just the cursor

comptime CH_LINE_SOLID: Int32 = 0
comptime CH_LINE_DASHED: Int32 = 1     # default
comptime CH_LINE_DOTTED: Int32 = 2


struct CrosshairConfig(ImplicitlyCopyable, Movable):
    """Crosshair cursor overlay options (port of `CrosshairOptions` in
    config/crosshair.rs).

    Colors are intentionally NOT stored here — in Rust they come from the
    resolved theme (`crosshair_line`, `crosshair_label_bg`), which the engine
    reads from `ChartTheme`.  This struct holds behavior/visibility and line
    widths only.  Defaults match the Rust `Default` impl.
    """

    var mode: Int32
    """Crosshair mode (`CH_MODE_*`). Default Normal."""
    var style: Int32
    """Visual style (`CH_STYLE_*`). Default Full."""
    var line_style: Int32
    """Line style (`CH_LINE_*`). Default Dashed."""
    var vert_line_visible: Bool
    """Show the vertical crosshair line. Default true."""
    var horz_line_visible: Bool
    """Show the horizontal crosshair line. Default true."""
    var vert_line_width: Int32
    """Vertical line thickness in pixels. Default 1."""
    var horz_line_width: Int32
    """Horizontal line thickness in pixels. Default 1."""
    var label_visible: Bool
    """Show the price/time labels at the crosshair edges. Default true."""

    fn __init__(out self):
        """Creates crosshair options with Rust `Default` values."""
        self.mode = CH_MODE_NORMAL
        self.style = CH_STYLE_FULL
        self.line_style = CH_LINE_DASHED
        self.vert_line_visible = True
        self.horz_line_visible = True
        self.vert_line_width = 1
        self.horz_line_width = 1
        self.label_visible = True


# =============================================================================
# ChartConfig — port of config/chart.rs  (struct ChartConfig)
# =============================================================================

struct ChartConfig(ImplicitlyCopyable, Movable):
    """Configuration for chart visual appearance (port of `ChartConfig` in
    config/chart.rs), reduced to the INTEGRATION_CONTRACT.md field set.

    Theme colors live in `ChartTheme`; this struct stores visibility toggles,
    the default bar spacing (pixel pitch between bar centers), and the active
    price-scale mode.  Defaults follow the Rust dark-theme `Default` impl.
    """

    var show_grid: Bool
    """Master grid toggle (Rust `show_grid`). Default true."""
    var show_crosshair: Bool
    """Master crosshair toggle (drives `CrosshairConfig` visibility). Default true."""
    var show_axes: Bool
    """Master axis toggle — true when either price axis is shown
    (Rust tracks `show_right_axis`/`show_left_axis` separately). Default true."""
    var bar_spacing: Int32
    """Default horizontal pitch between bar centers, in pixels.

    Rust derives spacing from `visible_candles` and chart width at layout time;
    kept here so the engine has a concrete default pitch before the first
    auto-fit.  Default 8.
    """
    var price_scale_mode: Int32
    """Active price-scale mode (`PS_*`, Rust `right_axis_scale_mode`). Default Normal."""

    var baseline: Float64
    """Reference value for Baseline charts (port of `BaselineSeriesOptions::baseline`,
    series/baseline.rs:31). The color split is `value >= baseline`. Default 0.0."""

    var crosshair: CrosshairConfig
    """Crosshair behavior/visibility options (Rust `ChartOptions.crosshair`)."""

    fn __init__(out self):
        """Creates a ChartConfig with Rust `Default` values (config/chart.rs)."""
        self.show_grid = True
        self.show_crosshair = True
        self.show_axes = True
        self.bar_spacing = 8
        self.price_scale_mode = PS_NORMAL
        self.baseline = 0.0
        self.crosshair = CrosshairConfig()
