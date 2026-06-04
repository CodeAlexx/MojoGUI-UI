"""
Chart builder — faithful port of egui-charts `src/chart/builder.rs`.

Ported from:
  - /tmp/egui-charts-ref/src/chart/builder.rs  -> ChartBuilder (fluent API)

`ChartBuilder` is a fluent builder that accumulates symbol / timeframe / theme /
chart-type / config / visible-candle count, then `build()` constructs and
returns a configured `ChartInt` (the engine widget, owned by engine.mojo).  The
Rust builder also wires a `DataSource`, `IndicatorRegistry` and `DrawingManager`
into a `TradingChart` wrapper; those subsystems are deferred in phase 1, so
`build()` here returns the bare `ChartInt` and bars are fed separately via
`ChartInt.set_bars`.

API and `build()` body follow INTEGRATION_CONTRACT.md exactly:
  build(): create_chart_int(0,0,W,H); set_theme(...); set_config(...);
           set_chart_type(...); set_visible_bars(...); set_symbol_label(...);
           set_timeframe_label(...); return c^

Conventions: `out self` init with Rust `Default`-equivalent values; fluent
setters take `mut self` and mutate in place (Mojo cannot chain a moved `self`
like Rust's `#[must_use]` builders), so the style is "mutate then build".
"""

from .model import (
    Timeframe, TF_MIN1,
    ChartType, CT_CANDLES, CT_LINE,
)
from .theme import ChartTheme
from .config import ChartConfig
from .engine import ChartInt, create_chart_int


# =============================================================================
# ChartBuilder — port of chart/builder.rs  (struct ChartBuilder)
# =============================================================================

comptime DEFAULT_VISIBLE_CANDLES: Int = 100
"""Rust `ChartBuilder::new` default visible-candle count (builder.rs:102)."""

comptime PRICE_CHART_VISIBLE_CANDLES: Int = 50
"""Rust `ChartBuilder::price_chart` view window (builder.rs:258)."""

# Default widget bounds used by build().  Rust's build() takes no geometry
# (egui lays the widget out); a MojoGUI BaseWidgetInt needs concrete bounds, so
# a sensible default canvas is used and the host can resize the widget after.
comptime DEFAULT_CHART_W: Int32 = 1000
comptime DEFAULT_CHART_H: Int32 = 664


struct ChartBuilder(ImplicitlyCopyable, Movable):
    """Fluent builder for a configured `ChartInt` (port of `ChartBuilder`).

    Use a constructor preset (`new`, `extended`, `price_chart`) then chain the
    `with_*` setters before calling `build()`.

    Faithful to the Rust constructor presets:
      - `new()`        : Candles, dark theme, 100 visible candles, grid on.
      - `extended()`   : `new()` + drawing tools + indicators (deferred → flags).
      - `price_chart()`: Line, no grid, no crosshair, 50 visible candles.
    """

    var symbol: String
    """Trading symbol label (Rust `Option<String>`, default "BTCUSDT")."""
    var timeframe: Timeframe
    """Bar aggregation timeframe (Rust default `Timeframe::Min1`)."""
    var theme: ChartTheme
    """Visual theme (Rust default `Theme::dark()`)."""
    var chart_type: ChartType
    """Chart visualization type (Rust default `ChartType::Candles`)."""
    var config: ChartConfig
    """Visual configuration (Rust `ChartConfig::default()`)."""
    var visible_candles: Int
    """Bars visible in the initial viewport (Rust default 100)."""
    var with_drawings: Bool
    """Whether to enable the drawing-tools subsystem (deferred in phase 1)."""
    var with_indicators: Bool
    """Whether to attach an indicator registry (deferred in phase 1)."""

    fn __init__(out self):
        """Create a builder with `ChartBuilder::new` defaults (builder.rs:91)."""
        self.symbol = String("BTCUSDT")
        self.timeframe = Timeframe(TF_MIN1)
        self.theme = ChartTheme.dark()
        self.chart_type = ChartType(CT_CANDLES)
        self.config = ChartConfig()
        self.visible_candles = DEFAULT_VISIBLE_CANDLES
        self.with_drawings = False
        self.with_indicators = False

    # ----- Constructor presets (builder.rs) --------------------------------

    @staticmethod
    fn new() -> ChartBuilder:
        """Sensible defaults (port of `ChartBuilder::new`)."""
        return ChartBuilder()

    @staticmethod
    fn extended() -> ChartBuilder:
        """Full trading terminal: drawing tools + indicators
        (port of `ChartBuilder::extended`, builder.rs:119).

        The drawing/indicator subsystems are deferred in phase 1, so this sets
        the request flags; the bug-fixer wires them later.
        """
        var b = ChartBuilder.new()
        b.with_drawings = True
        b.with_indicators = True
        return b

    @staticmethod
    fn price_chart() -> ChartBuilder:
        """Minimal sparkline / dashboard chart (port of `ChartBuilder::price_chart`,
        builder.rs:236): Line type, no grid, no crosshair, 50 visible candles."""
        var b = ChartBuilder.new()
        b.chart_type = ChartType(CT_LINE)
        b.config.show_grid = False
        b.config.show_crosshair = False
        b.config.crosshair.vert_line_visible = False
        b.config.crosshair.horz_line_visible = False
        b.config.crosshair.label_visible = False
        b.visible_candles = PRICE_CHART_VISIBLE_CANDLES
        return b

    @staticmethod
    fn options_chart() -> ChartBuilder:
        """Non-time-based pricing display (port of `ChartBuilder::options_chart`,
        builder.rs:165): Line type."""
        var b = ChartBuilder.new()
        b.chart_type = ChartType(CT_LINE)
        return b

    # ----- Fluent setters (builder.rs `with_*`) ----------------------------
    # Mojo cannot return a moved `self` for chaining; callers mutate in place.

    fn with_symbol(mut self, symbol: String):
        """Set the trading symbol (port of `with_symbol`, default "BTCUSDT")."""
        self.symbol = symbol

    fn with_timeframe(mut self, timeframe: Timeframe):
        """Set the bar timeframe (port of `with_timeframe`)."""
        self.timeframe = timeframe

    fn with_theme(mut self, theme: ChartTheme):
        """Set the visual theme (port of `with_theme`, default dark)."""
        self.theme = theme

    fn with_chart_type(mut self, chart_type: ChartType):
        """Set the chart visualization type (port of `with_chart_type`)."""
        self.chart_type = chart_type

    fn with_type(mut self, chart_type: ChartType):
        """Alias for `with_chart_type` (convenience name from the task spec)."""
        self.chart_type = chart_type

    fn with_config(mut self, config: ChartConfig):
        """Override the whole `ChartConfig` (port of `with_config`)."""
        self.config = config

    fn with_visible_candles(mut self, count: Int):
        """Set the initial viewport bar count (port of `with_visible_candles`)."""
        self.visible_candles = count

    fn with_right_price_scale(mut self, visible: Bool, mode: Int32):
        """Configure the right (primary) price scale (port of
        `with_right_price_scale`).  Maps onto the contract's single
        `price_scale_mode` + `show_axes`."""
        self.config.show_axes = visible
        self.config.price_scale_mode = mode

    # ----- build (builder.rs `build`) --------------------------------------

    fn build(self) -> ChartInt:
        """Consume the builder and produce a configured `ChartInt`
        (port of `ChartBuilder::build`, builder.rs:513).

        Body follows INTEGRATION_CONTRACT.md: build the widget at the default
        canvas, then apply theme / config / chart-type / visible-bars / labels
        via the engine's `set_*` methods.
        """
        var c = create_chart_int(0, 0, DEFAULT_CHART_W, DEFAULT_CHART_H)
        c.set_theme(self.theme)
        c.set_config(self.config)
        c.set_chart_type(self.chart_type)
        c.set_visible_bars(self.visible_candles)
        c.set_symbol_label(self.symbol)
        c.set_timeframe_label(self.timeframe.as_str())
        return c^
