"""
Technical indicators (studies) — faithful port of egui-charts `src/studies/`.

Ported from:
  - /tmp/egui-charts-ref/src/studies/indicator_trait.rs -> Indicator / IndicatorValue
  - /tmp/egui-charts-ref/src/studies/factory.rs         -> IndicatorRegistry (factory)
  - /tmp/egui-charts-ref/src/studies/builtin/sma.rs     -> SMA(period)
  - /tmp/egui-charts-ref/src/studies/builtin/ema.rs     -> EMA(period)
  - /tmp/egui-charts-ref/src/studies/builtin/rsi.rs     -> RSI(period, Wilder smoothing)
  - /tmp/egui-charts-ref/src/studies/builtin/macd.rs    -> MACD(fast, slow, signal)
  - /tmp/egui-charts-ref/src/studies/builtin/bollinger_bands.rs -> BollingerBands(period, k)

Design notes (how the Rust trait maps onto Mojo):
  - Rust has `trait Indicator` with `Box<dyn Indicator>` and an `enum
    IndicatorValue { Single(f64), Multiple(Vec<f64>), None }`.  Mojo (0.26.2
    nightly) has neither cheap trait objects nor payload-carrying enums, so the
    indicator family is modelled as one `Indicator` struct discriminated by an
    Int32 `kind` (the `IND_*` constants) plus its numeric parameters.  This is
    the same "Int32 id + thin wrapper" pattern model.mojo uses for ChartType.
  - `IndicatorValue` per bar becomes an `IndicatorSeries`: column-major
    `List[Float64]` lines plus a parallel `valid: List[Bool]` mask.  A `False`
    mask entry is the analogue of `IndicatorValue::None` (warmup).  The series
    is always one entry per input bar, matching the Rust output-length contract.
  - Math is ported verbatim from the `.rs` (same seeding, same Wilder
    smoothing, same variance/zero-guards) so the Mojo output agrees bar-for-bar.

Conventions (see PORT_SPEC.md "VERIFIED CONVENTIONS" and model.mojo):
  - Prices/series stay Float64; converted to Int32 pixels only at draw time.
  - `__init__(out self, ...)`, mutating methods take `mut self`.
"""

from math import sqrt
from .model import Bar
# RESOLVED (bug-fixer, Task #8): `from .model import Bar` is the real model Bar
# (verified — no mirror). IndicatorPlot helpers take an explicit LinearMap by
# design (decoupled from engine internals); see LinearMap docstring below.
from ...rendering_int import RenderingContextInt


# =============================================================================
# Indicator kind discriminants (one per ported builtin)
# =============================================================================

comptime IND_SMA: Int32 = 0
"""Simple Moving Average (sma.rs)."""
comptime IND_EMA: Int32 = 1
"""Exponential Moving Average (ema.rs)."""
comptime IND_RSI: Int32 = 2
"""Relative Strength Index (rsi.rs)."""
comptime IND_MACD: Int32 = 3
"""Moving Average Convergence Divergence (macd.rs)."""
comptime IND_BBANDS: Int32 = 4
"""Bollinger Bands (bollinger_bands.rs)."""


# =============================================================================
# IndicatorSeries — port of `IndicatorValue` aligned per-bar output
# =============================================================================

struct IndicatorSeries(Copyable, Movable):
    """Computed indicator output, one entry per input bar.

    Replaces Rust's `Vec<IndicatorValue>`.  Stores `line_cnt` parallel columns
    of Float64 (flattened row-major: `data[bar * line_cnt + line]`) plus a
    per-bar `valid` mask.  `valid[bar] == False` is the analogue of
    `IndicatorValue::None` emitted during the warmup period.
    """

    var line_cnt: Int
    """Number of plotted lines (1 for SMA/EMA/RSI, 3 for MACD/Bollinger)."""
    var data: List[Float64]
    """Row-major values: `data[bar * line_cnt + line]` (0.0 where invalid)."""
    var valid: List[Bool]
    """Per-bar validity mask; `False` == warmup (Rust `IndicatorValue::None`)."""

    fn __init__(out self, line_cnt: Int):
        """Creates an empty series with the given line count."""
        self.line_cnt = line_cnt
        self.data = List[Float64]()
        self.valid = List[Bool]()

    fn len(self) -> Int:
        """Number of bars in the series (== input bar count)."""
        return len(self.valid)

    fn push_none(mut self):
        """Append a warmup bar (Rust `IndicatorValue::None`)."""
        for _ in range(self.line_cnt):
            self.data.append(0.0)
        self.valid.append(False)

    fn push_single(mut self, v: Float64):
        """Append a single-line value (Rust `IndicatorValue::Single`).

        Requires `line_cnt == 1`; extra columns (if any) are zero-filled.
        """
        self.data.append(v)
        for _ in range(1, self.line_cnt):
            self.data.append(0.0)
        self.valid.append(True)

    fn push_triple(mut self, a: Float64, b: Float64, c: Float64):
        """Append a 3-line value (Rust `IndicatorValue::Multiple` of len 3)."""
        self.data.append(a)
        self.data.append(b)
        self.data.append(c)
        for _ in range(3, self.line_cnt):
            self.data.append(0.0)
        self.valid.append(True)

    fn is_valid(self, bar: Int) -> Bool:
        """Whether bar `bar` carries a computed value."""
        if bar < 0 or bar >= len(self.valid):
            return False
        return self.valid[bar]

    fn line(self, bar: Int, line_idx: Int) -> Float64:
        """Value of line `line_idx` at bar `bar` (0.0 if out of range)."""
        var i = bar * self.line_cnt + line_idx
        if i < 0 or i >= len(self.data):
            return 0.0
        return self.data[i]


# =============================================================================
# Indicator — port of `trait Indicator` (discriminated struct)
# =============================================================================

struct Indicator(ImplicitlyCopyable, Movable):
    """A technical indicator (port of the Rust `Indicator` trait family).

    A single struct discriminated by `kind` (an `IND_*` constant).  The four
    parameter slots cover every ported builtin:
      - SMA/EMA/RSI/Bollinger use `period` (and Bollinger `std_dev`).
      - MACD uses `period` (fast), `slow_period`, `signal_period`.
    Call `calculate(bars)` to obtain an `IndicatorSeries`.
    """

    var kind: Int32
    """One of the `IND_*` constants."""
    var period: Int
    """Primary period (SMA/EMA/RSI window, MACD fast, Bollinger SMA period)."""
    var slow_period: Int
    """Slow EMA period (MACD only)."""
    var signal_period: Int
    """Signal-line EMA period (MACD only)."""
    var std_dev: Float64
    """Standard-deviation multiplier K (Bollinger only)."""
    var visible: Bool
    """Whether this indicator should be rendered (Rust `is_visible`)."""

    fn __init__(out self, kind: Int32, period: Int, slow_period: Int = 0,
                signal_period: Int = 0, std_dev: Float64 = 0.0):
        """Low-level constructor; prefer the named factories below."""
        self.kind = kind
        self.period = period
        self.slow_period = slow_period
        self.signal_period = signal_period
        self.std_dev = std_dev
        self.visible = True

    # ----- Named constructors (port of each builtin's `new`) ----------------

    @staticmethod
    fn sma(period: Int) -> Indicator:
        """SMA(period) (port of `SMA::new`)."""
        return Indicator(IND_SMA, period)

    @staticmethod
    fn ema(period: Int) -> Indicator:
        """EMA(period) (port of `EMA::new`)."""
        return Indicator(IND_EMA, period)

    @staticmethod
    fn rsi(period: Int) -> Indicator:
        """RSI(period) with Wilder smoothing (port of `RSI::new`)."""
        return Indicator(IND_RSI, period)

    @staticmethod
    fn macd(fast: Int, slow: Int, signal: Int) -> Indicator:
        """MACD(fast, slow, signal) (port of `MACD::new`)."""
        return Indicator(IND_MACD, fast, slow, signal)

    @staticmethod
    fn bollinger(period: Int, k: Float64) -> Indicator:
        """Bollinger Bands(period, k stddev) (port of `BollingerBands::new`)."""
        return Indicator(IND_BBANDS, period, 0, 0, k)

    # ----- Trait metadata (port of name/desc/is_overlay/line_cnt/...) --------

    fn name(self) -> String:
        """Short display name (port of `Indicator::name`)."""
        if self.kind == IND_SMA:    return String("SMA")
        if self.kind == IND_EMA:    return String("EMA")
        if self.kind == IND_RSI:    return String("RSI")
        if self.kind == IND_MACD:   return String("MACD")
        if self.kind == IND_BBANDS: return String("BB")
        return String("?")

    fn desc(self) -> String:
        """Human-readable description (port of `Indicator::desc`)."""
        if self.kind == IND_SMA:    return String("Simple Moving Avg - Avg price over N periods")
        if self.kind == IND_EMA:    return String("Exponential Moving Avg - Weighted avg giving more importance to recent prices")
        if self.kind == IND_RSI:    return String("Relative Strength Index - Momentum oscillator (0-100)")
        if self.kind == IND_MACD:   return String("MACD - Trend-following momentum indicator")
        if self.kind == IND_BBANDS: return String("Bollinger Bands - Volatility indicator with upper and lower bands")
        return String("")

    fn is_overlay(self) -> Bool:
        """Whether drawn on the price chart vs a sub-pane (port of `is_overlay`).

        SMA/EMA/Bollinger overlay; RSI/MACD use their own pane.
        """
        if self.kind == IND_RSI or self.kind == IND_MACD:
            return False
        return True

    fn line_cnt(self) -> Int:
        """Number of plotted lines (port of `Indicator::line_cnt`)."""
        if self.kind == IND_MACD or self.kind == IND_BBANDS:
            return 3
        return 1

    fn line_names(self) -> List[String]:
        """Legend labels per line (port of `Indicator::line_names`)."""
        var v = List[String]()
        if self.kind == IND_SMA:
            v.append(String("SMA(") + String(self.period) + ")")
        elif self.kind == IND_EMA:
            v.append(String("EMA(") + String(self.period) + ")")
        elif self.kind == IND_RSI:
            v.append(String("RSI(") + String(self.period) + ")")
        elif self.kind == IND_MACD:
            v.append(String("MACD(") + String(self.period) + ","
                     + String(self.slow_period) + "," + String(self.signal_period) + ")")
            v.append(String("Signal"))
            v.append(String("Histogram"))
        elif self.kind == IND_BBANDS:
            var sfx = String("(") + String(self.period) + ", " + String(self.std_dev) + ")"
            v.append(String("BB Upper") + sfx)
            v.append(String("BB Middle") + sfx)
            v.append(String("BB Lower") + sfx)
        else:
            v.append(self.name())
        return v^

    fn is_visible(self) -> Bool:
        """Whether this indicator is currently shown (port of `is_visible`)."""
        return self.visible

    fn set_visible(mut self, visible: Bool):
        """Show or hide this indicator (port of `set_visible`)."""
        self.visible = visible

    # ----- calculate (dispatch to the ported math) --------------------------

    fn calculate(self, bars: List[Bar]) -> IndicatorSeries:
        """Compute the indicator over `bars` (port of `Indicator::calculate`).

        Returns one entry per input bar; warmup bars carry an invalid mask.
        """
        if self.kind == IND_SMA:    return _calc_sma(bars, self.period)
        if self.kind == IND_EMA:    return _calc_ema(bars, self.period)
        if self.kind == IND_RSI:    return _calc_rsi(bars, self.period)
        if self.kind == IND_MACD:   return _calc_macd(bars, self.period, self.slow_period, self.signal_period)
        if self.kind == IND_BBANDS: return _calc_bollinger(bars, self.period, self.std_dev)
        return IndicatorSeries(1)


# =============================================================================
# Math — faithful ports of each builtin's `calculate`
# =============================================================================

fn _calc_sma(data: List[Bar], period: Int) -> IndicatorSeries:
    """Simple moving average (verbatim port of `SMA::calculate`)."""
    var out = IndicatorSeries(1)
    var n = len(data)
    if n < period:
        return out^  # Rust returns empty when data.len() < period.
    for i in range(n):
        if i + 1 < period:
            out.push_none()
        else:
            var start = i + 1 - period
            var sum: Float64 = 0.0
            for j in range(start, i + 1):
                sum += data[j].close
            out.push_single(sum / Float64(period))
    return out^


fn _calc_ema(data: List[Bar], period: Int) -> IndicatorSeries:
    """Exponential moving average (verbatim port of `EMA::calculate`).

    Seeds the series with the first close (no `None` warmup), then smooths from
    the second bar — identical to the EMAs used inside MACD.
    """
    var out = IndicatorSeries(1)
    var n = len(data)
    if n == 0:
        return out^
    var multiplier = 2.0 / (Float64(period) + 1.0)
    var ema = data[0].close
    out.push_single(ema)
    for i in range(1, n):
        ema = (data[i].close - ema) * multiplier + ema
        out.push_single(ema)
    return out^


fn _calc_rsi(data: List[Bar], period: Int) -> IndicatorSeries:
    """Relative Strength Index with Wilder smoothing (port of `RSI::calculate`).

    Initial average gain/loss is the simple mean of the first `period` changes;
    subsequent values use Wilder smoothing `Avg = (Prev*(N-1) + Cur)/N`.  The
    loss denominator is floored at 1e-10 exactly as in the Rust source.
    """
    var out = IndicatorSeries(1)
    var n = len(data)
    if n < period + 1:
        return out^  # Rust returns empty when data.len() < period + 1.

    var gains = List[Float64]()
    var losses = List[Float64]()
    for i in range(1, n):
        var change = data[i].close - data[i - 1].close
        if change > 0.0:
            gains.append(change)
            losses.append(0.0)
        else:
            gains.append(0.0)
            losses.append(-change)

    var avg_gain: Float64 = 0.0
    var avg_loss: Float64 = 0.0
    for i in range(period):
        avg_gain += gains[i]
        avg_loss += losses[i]
    avg_gain = avg_gain / Float64(period)
    avg_loss = avg_loss / Float64(period)

    # `period` leading None entries keep output aligned 1:1 with input bars.
    for _ in range(period):
        out.push_none()

    var denom = avg_loss
    if denom < 1e-10:
        denom = 1e-10
    var rs = avg_gain / denom
    out.push_single(100.0 - (100.0 / (1.0 + rs)))

    for i in range(period, len(gains)):
        avg_gain = (avg_gain * Float64(period - 1) + gains[i]) / Float64(period)
        avg_loss = (avg_loss * Float64(period - 1) + losses[i]) / Float64(period)
        var d = avg_loss
        if d < 1e-10:
            d = 1e-10
        var rs2 = avg_gain / d
        out.push_single(100.0 - (100.0 / (1.0 + rs2)))
    return out^


fn _calc_macd(data: List[Bar], fast_period: Int, slow_period: Int,
              signal_period: Int) -> IndicatorSeries:
    """MACD line / signal / histogram (verbatim port of `MACD::calculate`).

    Output lines are [macd_line, signal_line, histogram].  Both fast and slow
    EMAs seed on `data[0].close`; the signal EMA seeds on `macd_line[0]`.
    """
    var out = IndicatorSeries(3)
    var n = len(data)
    if n < slow_period:
        return out^

    var fast_mult = 2.0 / (Float64(fast_period) + 1.0)
    var fast_ema = data[0].close
    var fast_emas = List[Float64]()
    fast_emas.append(fast_ema)
    for i in range(1, n):
        fast_ema = (data[i].close - fast_ema) * fast_mult + fast_ema
        fast_emas.append(fast_ema)

    var slow_mult = 2.0 / (Float64(slow_period) + 1.0)
    var slow_ema = data[0].close
    var slow_emas = List[Float64]()
    slow_emas.append(slow_ema)
    for i in range(1, n):
        slow_ema = (data[i].close - slow_ema) * slow_mult + slow_ema
        slow_emas.append(slow_ema)

    var macd_line = List[Float64]()
    for i in range(n):
        macd_line.append(fast_emas[i] - slow_emas[i])

    if len(macd_line) < signal_period:
        return out^  # Rust early-returns (leaving values empty).

    var signal_mult = 2.0 / (Float64(signal_period) + 1.0)
    var signal_ema = macd_line[0]
    var signal_line = List[Float64]()
    signal_line.append(signal_ema)
    for i in range(1, len(macd_line)):
        signal_ema = (macd_line[i] - signal_ema) * signal_mult + signal_ema
        signal_line.append(signal_ema)

    for i in range(len(macd_line)):
        var hist = macd_line[i] - signal_line[i]
        out.push_triple(macd_line[i], signal_line[i], hist)
    return out^


fn _calc_bollinger(data: List[Bar], period: Int, std_dev: Float64) -> IndicatorSeries:
    """Bollinger Bands (verbatim port of `BollingerBands::calculate`).

    Lines are [upper, middle(SMA), lower].  Variance is the population variance
    (divided by `period`), matching the Rust implementation exactly.
    """
    var out = IndicatorSeries(3)
    var n = len(data)
    if n < period:
        return out^
    for i in range(n):
        if i < period - 1:
            out.push_none()
        else:
            var start = i + 1 - period
            var sum: Float64 = 0.0
            for j in range(start, i + 1):
                sum += data[j].close
            var sma = sum / Float64(period)
            var variance: Float64 = 0.0
            for j in range(start, i + 1):
                var d = data[j].close - sma
                variance += d * d
            variance = variance / Float64(period)
            var std = sqrt(variance)
            var upper = sma + (std * std_dev)
            var lower = sma - (std * std_dev)
            out.push_triple(upper, sma, lower)
    return out^


# =============================================================================
# IndicatorRegistry — port of `IndicatorFactory` (name -> constructor)
# =============================================================================

struct IndicatorRegistry(Copyable, Movable):
    """Create indicators by canonical name (port of `IndicatorFactory`).

    Pre-loaded with the ported builtins keyed by their `Indicator::name`
    ("SMA", "EMA", "RSI", "MACD", "BB"), each constructed with its conventional
    Rust `Default` parameters (SMA 20, EMA 12, RSI 14, MACD 12/26/9, BB 20/2.0).
    `create(name)` returns the indicator and sets `found=True`; an unknown name
    returns a default SMA with `found=False` (Mojo lacks a cheap `Option`).
    """

    var names: List[String]
    """Registered canonical names (insertion order)."""

    fn __init__(out self):
        """Creates a registry pre-loaded with every ported builtin."""
        self.names = List[String]()
        self.names.append(String("SMA"))
        self.names.append(String("EMA"))
        self.names.append(String("RSI"))
        self.names.append(String("MACD"))
        self.names.append(String("BB"))

    fn has(self, name: String) -> Bool:
        """Whether an indicator with `name` is registered (port of `has`)."""
        for i in range(len(self.names)):
            if self.names[i] == name:
                return True
        return False

    fn count(self) -> Int:
        """Number of registered indicators (port of `count`)."""
        return len(self.names)

    fn list(self) -> List[String]:
        """All registered names (port of `list`)."""
        return self.names.copy()

    fn create(self, name: String) -> Indicator:
        """Construct an indicator by name with default params (port of `create`).

        Defaults mirror each builtin's Rust `Default` impl (SMA 20, EMA 12,
        RSI 14, MACD 12/26/9, BB 20/2.0).  Guard with `has(name)` first: an
        unknown name returns a placeholder SMA(20).  (A `(Indicator, Bool)`
        tuple return is avoided — the current compiler rejects tuple
        construction over these structs in some package-import contexts.)
        """
        if name == "EMA":  return Indicator.ema(12)
        if name == "RSI":  return Indicator.rsi(14)
        if name == "MACD": return Indicator.macd(12, 26, 9)
        if name == "BB":   return Indicator.bollinger(20, 2.0)
        return Indicator.sma(20)  # "SMA" and the unknown-name fallback.


# =============================================================================
# Drawing helpers — plot a computed series as overlay lines / bands
# =============================================================================

struct LinearMap(ImplicitlyCopyable, Movable):
    """Affine price/bar -> pixel mapping used by the indicator draw helpers.

    The chart engine knows the real viewport; until scales.mojo is finalized the
    helpers take this explicit map so they have zero dependency on engine
    internals.  `bar_to_x(i)` is a linear ramp; `price_to_y` inverts price
    (higher price -> smaller y) within the plot rect.

    # RESOLVED (bug-fixer, Task #8): kept as the indicator-overlay mapping by
    # design — studies stay decoupled from engine internals and the contract
    # `RenderView`; callers build a LinearMap from the engine's viewport. The
    # math is the standard linear mapping (matches RenderView.x_for/y_for).
    """

    var x0: Int32
    """Screen x of the first bar (bar index 0)."""
    var bar_step: Float64
    """Horizontal pixels between adjacent bars."""
    var price_min: Float64
    """Price mapped to the bottom of the plot rect."""
    var price_max: Float64
    """Price mapped to the top of the plot rect."""
    var y_top: Int32
    """Screen y of the top edge of the plot rect (maps to price_max)."""
    var y_bottom: Int32
    """Screen y of the bottom edge of the plot rect (maps to price_min)."""

    fn __init__(out self, x0: Int32, bar_step: Float64, price_min: Float64,
                price_max: Float64, y_top: Int32, y_bottom: Int32):
        """Creates a linear map for a plot rectangle."""
        self.x0 = x0
        self.bar_step = bar_step
        self.price_min = price_min
        self.price_max = price_max
        self.y_top = y_top
        self.y_bottom = y_bottom

    fn bar_to_x(self, bar: Int) -> Int32:
        """Screen x for bar index `bar` (centered on the bar column)."""
        return self.x0 + Int32(Float64(bar) * self.bar_step)

    fn price_to_y(self, price: Float64) -> Int32:
        """Screen y for `price` (price_max -> y_top, price_min -> y_bottom)."""
        var span = self.price_max - self.price_min
        if span == 0.0:
            return self.y_top
        var frac = (price - self.price_min) / span
        var h = Float64(self.y_bottom - self.y_top)
        return self.y_bottom - Int32(frac * h)


fn draw_indicator_line(ctx: RenderingContextInt, series: IndicatorSeries,
                       line_idx: Int, map: LinearMap,
                       r: Int32, g: Int32, b: Int32, a: Int32,
                       thickness: Int32 = 1):
    """Plot one line of a computed series as a connected polyline.

    Skips warmup bars (invalid mask) and only joins consecutive valid bars,
    so gaps in the series do not produce spurious connecting segments.  Used
    for SMA/EMA overlays, the RSI/MACD lines, and each Bollinger band.
    """
    _ = ctx.set_color(r, g, b, a)
    var have_prev = False
    var prev_x: Int32 = 0
    var prev_y: Int32 = 0
    for i in range(series.len()):
        if not series.is_valid(i):
            have_prev = False
            continue
        var x = map.bar_to_x(i)
        var y = map.price_to_y(series.line(i, line_idx))
        if have_prev:
            _ = ctx.draw_line(prev_x, prev_y, x, y, thickness)
        prev_x = x
        prev_y = y
        have_prev = True


fn draw_indicator(ctx: RenderingContextInt, ind: Indicator,
                  series: IndicatorSeries, map: LinearMap,
                  r: Int32, g: Int32, b: Int32, a: Int32):
    """Plot every line of an indicator using one base colour.

    Convenience over `draw_indicator_line`: draws all `series.line_cnt`
    lines (e.g. all three Bollinger bands or the MACD/signal lines) with the
    same colour.  Callers wanting per-line colours should loop themselves.
    """
    if not ind.is_visible():
        return
    for li in range(series.line_cnt):
        draw_indicator_line(ctx, series, li, map, r, g, b, a, 1)
