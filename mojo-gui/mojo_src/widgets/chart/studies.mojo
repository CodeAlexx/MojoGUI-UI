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
comptime IND_WMA: Int32 = 5
"""Weighted Moving Average (wma.rs)."""
comptime IND_HMA: Int32 = 6
"""Hull Moving Average (hma.rs)."""
comptime IND_VWMA: Int32 = 7
"""Volume-Weighted Moving Average (vwma.rs)."""
comptime IND_ATR: Int32 = 8
"""Average True Range, Wilder smoothing (atr.rs)."""
comptime IND_ADX: Int32 = 9
"""Average Directional Index — ADX/+DI/-DI (adx.rs)."""
comptime IND_STOCH: Int32 = 10
"""Stochastic Oscillator — %K/%D (stochastic.rs)."""
comptime IND_WILLR: Int32 = 11
"""Williams %R (williams_r.rs)."""
comptime IND_CCI: Int32 = 12
"""Commodity Channel Index (cci.rs)."""
comptime IND_ROC: Int32 = 13
"""Rate of Change (roc.rs)."""
comptime IND_OBV: Int32 = 14
"""On-Balance Volume (obv.rs)."""
comptime IND_VWAP: Int32 = 15
"""Volume-Weighted Average Price (vwap.rs)."""
comptime IND_MFI: Int32 = 16
"""Money Flow Index (mfi.rs)."""
comptime IND_AROON: Int32 = 17
"""Aroon — up/down (aroon.rs)."""
comptime IND_DONCHIAN: Int32 = 18
"""Donchian Channels — middle/upper/lower (donchian.rs)."""
comptime IND_KELTNER: Int32 = 19
"""Keltner Channels — middle/upper/lower (keltner.rs)."""


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

    fn push_pair(mut self, a: Float64, b: Float64):
        """Append a 2-line value (Rust `IndicatorValue::Multiple` of len 2).

        Used by 2-line indicators (Stochastic %K/%D, Aroon up/down).  Extra
        columns (if any) are zero-filled.
        """
        self.data.append(a)
        self.data.append(b)
        for _ in range(2, self.line_cnt):
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

    @staticmethod
    fn wma(period: Int) -> Indicator:
        """WMA(period) (port of `WMA::new`)."""
        return Indicator(IND_WMA, period)

    @staticmethod
    fn hma(period: Int) -> Indicator:
        """HMA(period) (port of `HMA::new`)."""
        return Indicator(IND_HMA, period)

    @staticmethod
    fn vwma(period: Int) -> Indicator:
        """VWMA(period) (port of `VWMA::new`)."""
        return Indicator(IND_VWMA, period)

    @staticmethod
    fn atr(period: Int) -> Indicator:
        """ATR(period) Wilder smoothing (port of `ATR::new`)."""
        return Indicator(IND_ATR, period)

    @staticmethod
    fn adx(period: Int) -> Indicator:
        """ADX(period) -> ADX/+DI/-DI (port of `ADX::new`)."""
        return Indicator(IND_ADX, period)

    @staticmethod
    fn stochastic(k_period: Int, k_smooth: Int, d_period: Int) -> Indicator:
        """Stochastic(k_period, k_smooth, d_period) -> %K/%D (port of `Stochastic::new`).

        Reuses `period`=k_period, `slow_period`=k_smooth, `signal_period`=d_period.
        """
        return Indicator(IND_STOCH, k_period, k_smooth, d_period)

    @staticmethod
    fn williams_r(period: Int) -> Indicator:
        """Williams %R(period) (port of `WilliamsR::new`)."""
        return Indicator(IND_WILLR, period)

    @staticmethod
    fn cci(period: Int) -> Indicator:
        """CCI(period) (port of `CCI::new`)."""
        return Indicator(IND_CCI, period)

    @staticmethod
    fn roc(period: Int) -> Indicator:
        """Rate of Change(period) (port of `RateOfChange::new`)."""
        return Indicator(IND_ROC, period)

    @staticmethod
    fn obv() -> Indicator:
        """On-Balance Volume (port of `OnBalanceVolume::new`)."""
        return Indicator(IND_OBV, 0)

    @staticmethod
    fn vwap(reset_on_session: Bool = False) -> Indicator:
        """VWAP (port of `VolumeWeightedAvgPrice::new`).

        `reset_on_session` (stored in `signal_period`: 1=on, 0=off) matches the
        Rust field; the Rust `Default` leaves it off (cumulative VWAP).
        """
        var r = 1 if reset_on_session else 0
        return Indicator(IND_VWAP, 0, 0, r)

    @staticmethod
    fn keltner(ema_period: Int, atr_period: Int, multiplier: Float64) -> Indicator:
        """Keltner Channels(ema_period, atr_period, multiplier) -> middle/upper/lower
        (port of `KeltnerChannels::new`).

        Reuses `period`=ema_period, `slow_period`=atr_period, `std_dev`=multiplier.
        """
        return Indicator(IND_KELTNER, ema_period, atr_period, 0, multiplier)

    @staticmethod
    fn mfi(period: Int) -> Indicator:
        """Money Flow Index(period) (port of `MoneyFlowIndex::new`)."""
        return Indicator(IND_MFI, period)

    @staticmethod
    fn aroon(period: Int) -> Indicator:
        """Aroon(period) -> up/down (port of `Aroon::new`)."""
        return Indicator(IND_AROON, period)

    @staticmethod
    fn donchian(period: Int) -> Indicator:
        """Donchian Channels(period) -> middle/upper/lower (port of `DonchianChannels::new`)."""
        return Indicator(IND_DONCHIAN, period)

    # ----- Trait metadata (port of name/desc/is_overlay/line_cnt/...) --------

    fn name(self) -> String:
        """Short display name (port of `Indicator::name`)."""
        if self.kind == IND_SMA:    return String("SMA")
        if self.kind == IND_EMA:    return String("EMA")
        if self.kind == IND_RSI:    return String("RSI")
        if self.kind == IND_MACD:   return String("MACD")
        if self.kind == IND_BBANDS: return String("BB")
        if self.kind == IND_WMA:    return String("WMA")
        if self.kind == IND_HMA:    return String("HMA")
        if self.kind == IND_VWMA:   return String("VWMA")
        if self.kind == IND_ATR:    return String("ATR")
        if self.kind == IND_ADX:    return String("ADX")
        if self.kind == IND_STOCH:  return String("Stochastic")
        if self.kind == IND_WILLR:  return String("Williams %R")
        if self.kind == IND_CCI:    return String("CCI")
        if self.kind == IND_ROC:    return String("ROC")
        if self.kind == IND_OBV:    return String("OBV")
        if self.kind == IND_VWAP:   return String("VWAP")
        if self.kind == IND_MFI:    return String("MFI")
        if self.kind == IND_AROON:  return String("Aroon")
        if self.kind == IND_DONCHIAN: return String("Donchian")
        if self.kind == IND_KELTNER:  return String("Keltner")
        return String("?")

    fn desc(self) -> String:
        """Human-readable description (port of `Indicator::desc`)."""
        if self.kind == IND_SMA:    return String("Simple Moving Avg - Avg price over N periods")
        if self.kind == IND_EMA:    return String("Exponential Moving Avg - Weighted avg giving more importance to recent prices")
        if self.kind == IND_RSI:    return String("Relative Strength Index - Momentum oscillator (0-100)")
        if self.kind == IND_MACD:   return String("MACD - Trend-following momentum indicator")
        if self.kind == IND_BBANDS: return String("Bollinger Bands - Volatility indicator with upper and lower bands")
        if self.kind == IND_WMA:    return String("Weighted Moving Avg - Gives more weight to recent prices")
        if self.kind == IND_HMA:    return String("Hull Moving Avg - Fast and smooth moving avg")
        if self.kind == IND_VWMA:   return String("Volume Weighted Moving Avg - MA weighted by volume")
        if self.kind == IND_ATR:    return String("Avg True Range - Volatility indicator")
        if self.kind == IND_ADX:    return String("Avg Directional Index - Trend strength indicator")
        if self.kind == IND_STOCH:  return String("Stochastic Oscillator - Momentum oscillator (0-100)")
        if self.kind == IND_WILLR:  return String("Williams %R - Momentum oscillator (-100 to 0)")
        if self.kind == IND_CCI:    return String("Commodity Channel Index - Cyclical trend indicator")
        if self.kind == IND_ROC:    return String("Rate of Change - Momentum oscillator (percentage)")
        if self.kind == IND_OBV:    return String("On Balance Volume - Cumulative volume indicator")
        if self.kind == IND_VWAP:   return String("Volume Weighted Avg Price - Trading benchmark indicator")
        if self.kind == IND_MFI:    return String("Money Flow Index - Volume-weighted RSI (0-100)")
        if self.kind == IND_AROON:  return String("Aroon - Trend identification indicator")
        if self.kind == IND_DONCHIAN: return String("Donchian Channels - Breakout indicator")
        if self.kind == IND_KELTNER:  return String("Keltner Channels - Volatility-based envelope")
        return String("")

    fn is_overlay(self) -> Bool:
        """Whether drawn on the price chart vs a sub-pane (port of each
        indicator's `is_overlay`).

        Overlays (price chart): SMA, EMA, BB, WMA, HMA, VWMA, VWAP, Donchian,
        Keltner.  Sub-pane oscillators/volume: RSI, MACD, ATR, ADX, Stochastic,
        Williams %R, CCI, ROC, OBV, MFI, Aroon.
        """
        if (self.kind == IND_RSI or self.kind == IND_MACD
                or self.kind == IND_ATR or self.kind == IND_ADX
                or self.kind == IND_STOCH or self.kind == IND_WILLR
                or self.kind == IND_CCI or self.kind == IND_ROC
                or self.kind == IND_OBV or self.kind == IND_MFI
                or self.kind == IND_AROON):
            return False
        return True

    fn line_cnt(self) -> Int:
        """Number of plotted lines (port of `Indicator::line_cnt`)."""
        if (self.kind == IND_MACD or self.kind == IND_BBANDS
                or self.kind == IND_ADX or self.kind == IND_DONCHIAN
                or self.kind == IND_KELTNER):
            return 3
        if self.kind == IND_STOCH or self.kind == IND_AROON:
            return 2
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
        elif self.kind == IND_WMA:
            v.append(String("WMA(") + String(self.period) + ")")
        elif self.kind == IND_HMA:
            v.append(String("HMA(") + String(self.period) + ")")
        elif self.kind == IND_VWMA:
            v.append(String("VWMA(") + String(self.period) + ")")
        elif self.kind == IND_ATR:
            v.append(String("ATR(") + String(self.period) + ")")
        elif self.kind == IND_ADX:
            v.append(String("ADX(") + String(self.period) + ")")
            v.append(String("+DI"))
            v.append(String("-DI"))
        elif self.kind == IND_STOCH:
            v.append(String("%K(") + String(self.period) + "," + String(self.slow_period)
                     + "," + String(self.signal_period) + ")")
            v.append(String("%D"))
        elif self.kind == IND_WILLR:
            v.append(String("%R(") + String(self.period) + ")")
        elif self.kind == IND_CCI:
            v.append(String("CCI(") + String(self.period) + ")")
        elif self.kind == IND_ROC:
            v.append(String("ROC(") + String(self.period) + ")")
        elif self.kind == IND_OBV:
            v.append(String("OBV"))
        elif self.kind == IND_VWAP:
            v.append(String("VWAP"))
        elif self.kind == IND_MFI:
            v.append(String("MFI(") + String(self.period) + ")")
        elif self.kind == IND_AROON:
            v.append(String("Aroon Up(") + String(self.period) + ")")
            v.append(String("Aroon Down(") + String(self.period) + ")")
        elif self.kind == IND_DONCHIAN:
            # Output order is [middle, upper, lower] (matches calculate()).
            v.append(String("Middle(") + String(self.period) + ")")
            v.append(String("Upper"))
            v.append(String("Lower"))
        elif self.kind == IND_KELTNER:
            # Output order is [middle, upper, lower] (matches calculate()).
            v.append(String("EMA(") + String(self.period) + ")")
            v.append(String("Upper(") + String(self.std_dev) + "x ATR)")
            v.append(String("Lower(") + String(self.std_dev) + "x ATR)")
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
        if self.kind == IND_WMA:    return _calc_wma(bars, self.period)
        if self.kind == IND_HMA:    return _calc_hma(bars, self.period)
        if self.kind == IND_VWMA:   return _calc_vwma(bars, self.period)
        if self.kind == IND_ATR:    return _calc_atr(bars, self.period)
        if self.kind == IND_ADX:    return _calc_adx(bars, self.period)
        if self.kind == IND_STOCH:  return _calc_stochastic(bars, self.period, self.slow_period, self.signal_period)
        if self.kind == IND_WILLR:  return _calc_williams_r(bars, self.period)
        if self.kind == IND_CCI:    return _calc_cci(bars, self.period)
        if self.kind == IND_ROC:    return _calc_roc(bars, self.period)
        if self.kind == IND_OBV:    return _calc_obv(bars)
        if self.kind == IND_VWAP:   return _calc_vwap(bars, self.signal_period == 1)
        if self.kind == IND_MFI:    return _calc_mfi(bars, self.period)
        if self.kind == IND_AROON:  return _calc_aroon(bars, self.period)
        if self.kind == IND_DONCHIAN: return _calc_donchian(bars, self.period)
        if self.kind == IND_KELTNER:  return _calc_keltner(bars, self.period, self.slow_period, self.std_dev)
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


# -----------------------------------------------------------------------------
# Shared helpers (port of the per-indicator inline helpers)
# -----------------------------------------------------------------------------

fn _highest_high(data: List[Bar], i: Int, period: Int) -> Float64:
    """Highest `high` over the `period` bars ending at `i` (inclusive)."""
    var start = i + 1 - period
    var h = data[start].high
    for j in range(start + 1, i + 1):
        if data[j].high > h:
            h = data[j].high
    return h


fn _lowest_low(data: List[Bar], i: Int, period: Int) -> Float64:
    """Lowest `low` over the `period` bars ending at `i` (inclusive)."""
    var start = i + 1 - period
    var l = data[start].low
    for j in range(start + 1, i + 1):
        if data[j].low < l:
            l = data[j].low
    return l


fn _true_range(bar: Bar, prev_close: Float64) -> Float64:
    """True range (port of the shared `true_range`): max(hl, |hc|, |lc|)."""
    var hl = bar.high - bar.low
    var hc = abs(bar.high - prev_close)
    var lc = abs(bar.low - prev_close)
    return max(hl, max(hc, lc))


fn _wma_over(closes: List[Float64], period: Int) -> List[Float64]:
    """WMA of a value series (port of `HMA::calculate_wma`).

    Returns one value per input element; positions before the warmup boundary
    are returned as 0.0 and flagged invalid by the parallel `_wma_valid` mask
    computed alongside it.  Used by HMA's three-stage pipeline.
    """
    var n = len(closes)
    var out = List[Float64]()
    for _ in range(n):
        out.append(0.0)
    if n == 0 or period == 0:
        return out^
    var weight_sum = Float64((period * (period + 1)) // 2)
    for i in range(period - 1, n):
        var weighted_sum: Float64 = 0.0
        for j in range(period):
            var weight = Float64(period - j)
            weighted_sum += closes[i - j] * weight
        out[i] = weighted_sum / weight_sum
    return out^


# =============================================================================
# Math — ported builtins (extended batch)
# =============================================================================

fn _calc_wma(data: List[Bar], period: Int) -> IndicatorSeries:
    """Weighted moving average (verbatim port of `WMA::calculate`)."""
    var out = IndicatorSeries(1)
    var n = len(data)
    if n == 0:
        return out^
    var weight_sum = Float64((period * (period + 1)) // 2)
    for i in range(n):
        if i < period - 1:
            out.push_none()
        else:
            var weighted_sum: Float64 = 0.0
            for j in range(period):
                var weight = Float64(period - j)
                weighted_sum += data[i - j].close * weight
            out.push_single(weighted_sum / weight_sum)
    return out^


fn _calc_hma(data: List[Bar], period: Int) -> IndicatorSeries:
    """Hull moving average (verbatim port of `HMA::calculate`).

    HMA = WMA( 2*WMA(close, p/2) - WMA(close, p), sqrt(p) ).  Warmup ends at
    `period + sqrt_period - 1` bars, matching the Rust `min_period` gate.
    """
    var out = IndicatorSeries(1)
    var n = len(data)
    if n == 0:
        return out^
    var half_period = max(period // 2, 1)
    var sqrt_period = max(Int(sqrt(Float64(period))), 1)

    var closes = List[Float64]()
    for i in range(n):
        closes.append(data[i].close)

    var wma_half = _wma_over(closes, half_period)
    var wma_full = _wma_over(closes, period)

    # raw_hma valid only where both component WMAs are valid (i.e. past warmup).
    var raw = List[Float64]()
    var raw_valid = List[Bool]()
    for i in range(n):
        var hv = i >= half_period - 1
        var fv = i >= period - 1
        if hv and fv:
            raw.append(2.0 * wma_half[i] - wma_full[i])
            raw_valid.append(True)
        else:
            raw.append(0.0)
            raw_valid.append(False)

    # Final WMA over raw_hma, sqrt_period window — only over valid entries.
    var hma = List[Float64]()
    for _ in range(n):
        hma.append(0.0)
    var weight_sum = Float64((sqrt_period * (sqrt_period + 1)) // 2)
    for i in range(sqrt_period - 1, n):
        var all_valid = True
        var weighted_sum: Float64 = 0.0
        for j in range(sqrt_period):
            if not raw_valid[i - j]:
                all_valid = False
                break
            weighted_sum += raw[i - j] * Float64(sqrt_period - j)
        if all_valid:
            hma[i] = weighted_sum / weight_sum

    var min_period = period + sqrt_period - 1
    for i in range(n):
        if i < min_period - 1:
            out.push_none()
        else:
            out.push_single(hma[i])
    return out^


fn _calc_vwma(data: List[Bar], period: Int) -> IndicatorSeries:
    """Volume-weighted moving average (verbatim port of `VWMA::calculate`)."""
    var out = IndicatorSeries(1)
    var n = len(data)
    if n < period:
        return out^
    for i in range(n):
        if i < period - 1:
            out.push_none()
        else:
            var start = i + 1 - period
            var pv: Float64 = 0.0
            var vol: Float64 = 0.0
            for j in range(start, i + 1):
                pv += data[j].close * data[j].volume
                vol += data[j].volume
            if vol > 0.0:
                out.push_single(pv / vol)
            else:
                var csum: Float64 = 0.0
                for j in range(start, i + 1):
                    csum += data[j].close
                out.push_single(csum / Float64(period))
    return out^


fn _calc_atr(data: List[Bar], period: Int) -> IndicatorSeries:
    """Average true range, Wilder smoothing (verbatim port of `ATR::calculate`)."""
    var out = IndicatorSeries(1)
    var n = len(data)
    if n < 2:
        for _ in range(n):
            out.push_none()
        return out^

    var tr = List[Float64]()
    tr.append(data[0].high - data[0].low)
    for i in range(1, n):
        tr.append(_true_range(data[i], data[i - 1].close))

    var multiplier = 1.0 / Float64(period)
    var prev_atr: Float64 = 0.0
    for i in range(n):
        if i < period - 1:
            out.push_none()
        elif i == period - 1:
            var sum: Float64 = 0.0
            for j in range(i + 1):
                sum += tr[j]
            prev_atr = sum / Float64(period)
            out.push_single(prev_atr)
        else:
            prev_atr = prev_atr + multiplier * (tr[i] - prev_atr)
            out.push_single(prev_atr)
    return out^


fn _calc_adx(data: List[Bar], period: Int) -> IndicatorSeries:
    """Average Directional Index -> [ADX, +DI, -DI] (verbatim port of `ADX::calculate`).

    Wilder smoothing `prev - prev/period + current`; the initial ADX averages
    DX over `dx[period .. 2*period-1)` (exclusive upper, as in the Rust source).
    """
    var out = IndicatorSeries(3)
    var n = len(data)
    if n < period * 2:
        for _ in range(n):
            out.push_none()
        return out^

    var plus_dm = List[Float64]()
    var minus_dm = List[Float64]()
    var tr = List[Float64]()
    plus_dm.append(0.0)
    minus_dm.append(0.0)
    tr.append(data[0].high - data[0].low)
    for i in range(1, n):
        var up_move = data[i].high - data[i - 1].high
        var down_move = data[i - 1].low - data[i].low
        if up_move > down_move and up_move > 0.0:
            plus_dm.append(up_move)
        else:
            plus_dm.append(0.0)
        if down_move > up_move and down_move > 0.0:
            minus_dm.append(down_move)
        else:
            minus_dm.append(0.0)
        tr.append(_true_range(data[i], data[i - 1].close))

    var s_plus = List[Float64]()
    var s_minus = List[Float64]()
    var s_tr = List[Float64]()
    for _ in range(n):
        s_plus.append(0.0)
        s_minus.append(0.0)
        s_tr.append(0.0)

    var sum_plus: Float64 = 0.0
    var sum_minus: Float64 = 0.0
    var sum_tr: Float64 = 0.0
    for i in range(1, period + 1):
        sum_plus += plus_dm[i]
        sum_minus += minus_dm[i]
        sum_tr += tr[i]
    s_plus[period] = sum_plus
    s_minus[period] = sum_minus
    s_tr[period] = sum_tr

    var pf = Float64(period)
    for i in range(period + 1, n):
        s_plus[i] = s_plus[i - 1] - (s_plus[i - 1] / pf) + plus_dm[i]
        s_minus[i] = s_minus[i - 1] - (s_minus[i - 1] / pf) + minus_dm[i]
        s_tr[i] = s_tr[i - 1] - (s_tr[i - 1] / pf) + tr[i]

    var plus_di = List[Float64]()
    var minus_di = List[Float64]()
    var dx = List[Float64]()
    for _ in range(n):
        plus_di.append(0.0)
        minus_di.append(0.0)
        dx.append(0.0)
    for i in range(period, n):
        if abs(s_tr[i]) > 1e-10:
            plus_di[i] = 100.0 * s_plus[i] / s_tr[i]
            minus_di[i] = 100.0 * s_minus[i] / s_tr[i]
        var di_sum = plus_di[i] + minus_di[i]
        if abs(di_sum) > 1e-10:
            dx[i] = 100.0 * abs(plus_di[i] - minus_di[i]) / di_sum

    var adx = List[Float64]()
    for _ in range(n):
        adx.append(0.0)
    var adx_start = period * 2 - 1
    if adx_start < n:
        var initial_sum: Float64 = 0.0
        for i in range(period, adx_start):  # exclusive upper, matches Rust.
            initial_sum += dx[i]
        adx[adx_start] = initial_sum / pf
        for i in range(adx_start + 1, n):
            adx[i] = (adx[i - 1] * Float64(period - 1) + dx[i]) / pf

    for i in range(n):
        if i < period * 2 - 1:
            out.push_none()
        else:
            out.push_triple(adx[i], plus_di[i], minus_di[i])
    return out^


fn _calc_stochastic(data: List[Bar], k_period: Int, k_smooth: Int,
                    d_period: Int) -> IndicatorSeries:
    """Stochastic oscillator -> [%K, %D] (verbatim port of `Stochastic::calculate`).

    raw %K is `100*(close-LL)/(HH-LL)` clamped [0,100]; %K is the SMA over
    `k_smooth`; %D is the SMA of %K over `d_period`.
    """
    var out = IndicatorSeries(2)
    var n = len(data)
    var min_period = k_period + k_smooth - 1
    if n < min_period:
        for _ in range(n):
            out.push_none()
        return out^

    # raw %K with validity (NaN-free model via parallel mask).
    var raw_k = List[Float64]()
    var raw_v = List[Bool]()
    for i in range(n):
        if i < k_period - 1:
            raw_k.append(0.0)
            raw_v.append(False)
        else:
            var hh = _highest_high(data, i, k_period)
            var ll = _lowest_low(data, i, k_period)
            var rng = hh - ll
            if abs(rng) < 1e-10:
                raw_k.append(50.0)
            else:
                var k = 100.0 * (data[i].close - ll) / rng
                if k < 0.0: k = 0.0
                elif k > 100.0: k = 100.0
                raw_k.append(k)
            raw_v.append(True)

    var smooth_k = List[Float64]()
    var smooth_v = List[Bool]()
    for i in range(n):
        if i < k_period + k_smooth - 2 or not raw_v[i]:
            smooth_k.append(0.0)
            smooth_v.append(False)
        else:
            var start = i - k_smooth + 1
            var s: Float64 = 0.0
            var cnt = 0
            for j in range(start, i + 1):
                if raw_v[j]:
                    s += raw_k[j]
                    cnt += 1
            if cnt >= k_smooth:
                smooth_k.append(s / Float64(cnt))
                smooth_v.append(True)
            else:
                smooth_k.append(0.0)
                smooth_v.append(False)

    var d_vals = List[Float64]()
    var d_v = List[Bool]()
    for i in range(n):
        if i < k_period + k_smooth + d_period - 3 or not smooth_v[i]:
            d_vals.append(0.0)
            d_v.append(False)
        else:
            var start = i - d_period + 1
            var s: Float64 = 0.0
            var cnt = 0
            for j in range(start, i + 1):
                if smooth_v[j]:
                    s += smooth_k[j]
                    cnt += 1
            if cnt >= d_period:
                d_vals.append(s / Float64(cnt))
                d_v.append(True)
            else:
                d_vals.append(0.0)
                d_v.append(False)

    for i in range(n):
        if not smooth_v[i] or not d_v[i]:
            out.push_none()
        else:
            out.push_pair(smooth_k[i], d_vals[i])
    return out^


fn _calc_williams_r(data: List[Bar], period: Int) -> IndicatorSeries:
    """Williams %R (verbatim port of `WilliamsR::calculate`)."""
    var out = IndicatorSeries(1)
    var n = len(data)
    if n < period:
        for _ in range(n):
            out.push_none()
        return out^
    for i in range(n):
        if i < period - 1:
            out.push_none()
        else:
            var hh = _highest_high(data, i, period)
            var ll = _lowest_low(data, i, period)
            var rng = hh - ll
            if abs(rng) < 1e-10:
                out.push_single(-50.0)
            else:
                var r = (hh - data[i].close) / rng * -100.0
                if r < -100.0: r = -100.0
                elif r > 0.0: r = 0.0
                out.push_single(r)
    return out^


fn _calc_cci(data: List[Bar], period: Int) -> IndicatorSeries:
    """Commodity Channel Index (verbatim port of `CCI::calculate`).

    Typical price = HLC3; Lambert's constant 0.015 as in the source.
    """
    var out = IndicatorSeries(1)
    var n = len(data)
    if n < period:
        for _ in range(n):
            out.push_none()
        return out^
    var tp = List[Float64]()
    for i in range(n):
        tp.append(data[i].hlc3())
    for i in range(n):
        if i + 1 < period:
            out.push_none()
        else:
            var start = i + 1 - period
            var sma: Float64 = 0.0
            for j in range(start, i + 1):
                sma += tp[j]
            sma = sma / Float64(period)
            var mean_dev: Float64 = 0.0
            for j in range(start, i + 1):
                mean_dev += abs(tp[j] - sma)
            mean_dev = mean_dev / Float64(period)
            if abs(mean_dev) < 1e-10:
                out.push_single(0.0)
            else:
                out.push_single((tp[i] - sma) / (0.015 * mean_dev))
    return out^


fn _calc_roc(data: List[Bar], period: Int) -> IndicatorSeries:
    """Rate of Change, percentage (verbatim port of `RateOfChange::calculate`)."""
    var out = IndicatorSeries(1)
    var n = len(data)
    if n <= period:
        for _ in range(n):
            out.push_none()
        return out^
    for i in range(n):
        if i < period:
            out.push_none()
        else:
            var prev_close = data[i - period].close
            if abs(prev_close) < 1e-10:
                out.push_single(0.0)
            else:
                out.push_single(((data[i].close - prev_close) / prev_close) * 100.0)
    return out^


fn _calc_obv(data: List[Bar]) -> IndicatorSeries:
    """On-Balance Volume (verbatim port of `OnBalanceVolume::calculate`).

    Seeds OBV with the first bar's volume, then adds/subtracts volume on
    up/down closes (unchanged close leaves OBV flat).
    """
    var out = IndicatorSeries(1)
    var n = len(data)
    if n == 0:
        return out^
    var obv = data[0].volume
    out.push_single(obv)
    for i in range(1, n):
        if data[i].close > data[i - 1].close:
            obv += data[i].volume
        elif data[i].close < data[i - 1].close:
            obv -= data[i].volume
        out.push_single(obv)
    return out^


fn _calc_vwap(data: List[Bar], reset_on_session: Bool) -> IndicatorSeries:
    """Volume-Weighted Average Price (verbatim port of `VolumeWeightedAvgPrice::calculate`).

    Typical price = HLC3.  When `reset_on_session` is true the cumulative sums
    reset on a day boundary; the Rust day check (`date_naive() != ...`) is
    reproduced via the UTC day index `time // 86_400_000` (Bar.time is epoch
    ms).  The Rust `Default` leaves reset off (a single cumulative VWAP).
    """
    var out = IndicatorSeries(1)
    var n = len(data)
    if n == 0:
        return out^
    var cum_tp_vol: Float64 = 0.0
    var cum_vol: Float64 = 0.0
    for i in range(n):
        if reset_on_session and i > 0:
            var day = data[i].time // 86_400_000
            var prev_day = data[i - 1].time // 86_400_000
            if day != prev_day:
                cum_tp_vol = 0.0
                cum_vol = 0.0
        var tp = data[i].hlc3()
        cum_tp_vol += tp * data[i].volume
        cum_vol += data[i].volume
        if abs(cum_vol) < 1e-10:
            out.push_single(tp)
        else:
            out.push_single(cum_tp_vol / cum_vol)
    return out^


fn _calc_mfi(data: List[Bar], period: Int) -> IndicatorSeries:
    """Money Flow Index (verbatim port of `MoneyFlowIndex::calculate`).

    Volume-weighted RSI: positive/negative money flow over `period`, clamped
    [0,100].  Typical price = HLC3.
    """
    var out = IndicatorSeries(1)
    var n = len(data)
    if n < period + 1:
        for _ in range(n):
            out.push_none()
        return out^
    var tp = List[Float64]()
    for i in range(n):
        tp.append(data[i].hlc3())
    var pos = List[Float64]()
    var neg = List[Float64]()
    pos.append(0.0)
    neg.append(0.0)
    for i in range(1, n):
        var rmf = tp[i] * data[i].volume
        if tp[i] > tp[i - 1]:
            pos.append(rmf)
            neg.append(0.0)
        elif tp[i] < tp[i - 1]:
            pos.append(0.0)
            neg.append(rmf)
        else:
            pos.append(0.0)
            neg.append(0.0)
    for i in range(n):
        if i < period:
            out.push_none()
        else:
            var start = i + 1 - period
            var ps: Float64 = 0.0
            var ns: Float64 = 0.0
            for j in range(start, i + 1):
                ps += pos[j]
                ns += neg[j]
            var mfi: Float64
            if abs(ns) < 1e-10:
                mfi = 100.0
            elif abs(ps) < 1e-10:
                mfi = 0.0
            else:
                var ratio = ps / ns
                mfi = 100.0 - (100.0 / (1.0 + ratio))
            if mfi < 0.0: mfi = 0.0
            elif mfi > 100.0: mfi = 100.0
            out.push_single(mfi)
    return out^


fn _calc_aroon(data: List[Bar], period: Int) -> IndicatorSeries:
    """Aroon -> [up, down] (verbatim port of `Aroon::calculate`).

    Uses a `period`-bar lookback ending at `i` (window length `period+1`):
    days since the highest high / lowest low map to 0-100.
    """
    var out = IndicatorSeries(2)
    var n = len(data)
    if n == 0:
        return out^
    for i in range(n):
        if i < period:
            out.push_none()
        else:
            var start = i - period
            var highest_idx = start
            var lowest_idx = start
            var highest = data[start].high
            var lowest = data[start].low
            for j in range(start + 1, i + 1):
                if data[j].high >= highest:
                    highest = data[j].high
                    highest_idx = j
                if data[j].low <= lowest:
                    lowest = data[j].low
                    lowest_idx = j
            var days_high = i - highest_idx
            var days_low = i - lowest_idx
            var aroon_up = (Float64(period - days_high) / Float64(period)) * 100.0
            var aroon_down = (Float64(period - days_low) / Float64(period)) * 100.0
            out.push_pair(aroon_up, aroon_down)
    return out^


fn _calc_donchian(data: List[Bar], period: Int) -> IndicatorSeries:
    """Donchian Channels -> [middle, upper, lower] (verbatim port of
    `DonchianChannels::calculate`).  Output order is middle/upper/lower."""
    var out = IndicatorSeries(3)
    var n = len(data)
    if n < period:
        for _ in range(n):
            out.push_none()
        return out^
    for i in range(n):
        if i < period - 1:
            out.push_none()
        else:
            var upper = _highest_high(data, i, period)
            var lower = _lowest_low(data, i, period)
            var middle = (upper + lower) / 2.0
            out.push_triple(middle, upper, lower)
    return out^


fn _calc_keltner(data: List[Bar], ema_period: Int, atr_period: Int,
                 multiplier: Float64) -> IndicatorSeries:
    """Keltner Channels -> [middle, upper, lower] (verbatim port of
    `KeltnerChannels::calculate`).

    Middle = EMA(close, ema_period) seeded with an SMA; band = multiplier *
    ATR(atr_period) with Wilder smoothing.  Output order is middle/upper/lower.
    """
    var out = IndicatorSeries(3)
    var n = len(data)
    var min_period = max(ema_period, atr_period)
    if n < min_period:
        for _ in range(n):
            out.push_none()
        return out^

    var ema = List[Float64]()
    for _ in range(n):
        ema.append(0.0)
    var mult = 2.0 / (Float64(ema_period) + 1.0)
    var init_sum: Float64 = 0.0
    for i in range(ema_period):
        init_sum += data[i].close
    ema[ema_period - 1] = init_sum / Float64(ema_period)
    for i in range(ema_period, n):
        ema[i] = (data[i].close - ema[i - 1]) * mult + ema[i - 1]

    var tr = List[Float64]()
    tr.append(data[0].high - data[0].low)
    for i in range(1, n):
        tr.append(_true_range(data[i], data[i - 1].close))

    var atr = List[Float64]()
    for _ in range(n):
        atr.append(0.0)
    var atr_mult = 1.0 / Float64(atr_period)
    if atr_period <= n:
        var init_atr: Float64 = 0.0
        for i in range(atr_period):
            init_atr += tr[i]
        atr[atr_period - 1] = init_atr / Float64(atr_period)
        for i in range(atr_period, n):
            atr[i] = atr[i - 1] + atr_mult * (tr[i] - atr[i - 1])

    for i in range(n):
        if i < min_period - 1:
            out.push_none()
        else:
            var middle = ema[i]
            var band = multiplier * atr[i]
            out.push_triple(middle, middle + band, middle - band)
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
        self.names.append(String("WMA"))
        self.names.append(String("HMA"))
        self.names.append(String("VWMA"))
        self.names.append(String("ATR"))
        self.names.append(String("ADX"))
        self.names.append(String("Stochastic"))
        self.names.append(String("Williams %R"))
        self.names.append(String("CCI"))
        self.names.append(String("ROC"))
        self.names.append(String("OBV"))
        self.names.append(String("VWAP"))
        self.names.append(String("MFI"))
        self.names.append(String("Aroon"))
        self.names.append(String("Donchian"))
        self.names.append(String("Keltner"))

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
        # Extended batch — each uses its Rust `Default` parameters.
        if name == "WMA":        return Indicator.wma(20)
        if name == "HMA":        return Indicator.hma(20)
        if name == "VWMA":       return Indicator.vwma(20)
        if name == "ATR":        return Indicator.atr(14)
        if name == "ADX":        return Indicator.adx(14)
        if name == "Stochastic": return Indicator.stochastic(14, 3, 3)
        if name == "Williams %R": return Indicator.williams_r(14)
        if name == "CCI":        return Indicator.cci(20)
        if name == "ROC":        return Indicator.roc(14)
        if name == "OBV":        return Indicator.obv()
        if name == "VWAP":       return Indicator.vwap()
        if name == "MFI":        return Indicator.mfi(14)
        if name == "Aroon":      return Indicator.aroon(25)
        if name == "Donchian":   return Indicator.donchian(20)
        if name == "Keltner":    return Indicator.keltner(20, 10, 2.0)
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
