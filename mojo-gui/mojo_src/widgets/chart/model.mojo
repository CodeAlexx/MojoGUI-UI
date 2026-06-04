"""
Chart domain model — faithful port of egui-charts `src/model/`.

Ported from:
  - /tmp/egui-charts-ref/src/model/bar/bar.rs        -> Bar
  - /tmp/egui-charts-ref/src/model/bar/bar_data.rs   -> BarData
  - /tmp/egui-charts-ref/src/model/symbol.rs         -> Symbol
  - /tmp/egui-charts-ref/src/model/timeframe.rs      -> Timeframe (+ constants/helpers)
  - /tmp/egui-charts-ref/src/model/chart_type.rs     -> ChartType, ChartTypeCategory, ChartTypeParams

Conventions (see PORT_SPEC.md "VERIFIED CONVENTIONS"):
  - Prices are kept as Float64 everywhere; never rounded in the model.
  - `__init__(out self, ...)`, mutating methods take `mut self`.  `inout self` is
    rejected by the current compiler (Mojo 0.26.2 nightly).
  - Rust enums (no payload-carrying variants in Mojo yet) are modelled as Int32
    `comptime` constants plus a thin wrapper struct exposing the Rust helper
    methods.  This mirrors the existing widget code (see node_graph_int.mojo).
"""

from math import inf


# =============================================================================
# Bar — port of model/bar/bar.rs  (struct Bar)
# =============================================================================

struct Bar(ImplicitlyCopyable, Movable):
    """A single OHLCV (Open, High, Low, Close, Volume) bar.

    Port of `Bar` in model/bar/bar.rs.  The Rust type stores `time` as a
    `DateTime<Utc>`; here it is a Unix timestamp in **milliseconds** (Int64) so
    it can be compared and laid out on the time axis without a date library.
    Prices and volume are Float64 to match the Rust `f64` fields exactly.
    """

    var time: Int64
    """Timestamp of the bar (Unix epoch milliseconds, UTC)."""
    var open: Float64
    """Opening price."""
    var high: Float64
    """Highest price during the period."""
    var low: Float64
    """Lowest price during the period."""
    var close: Float64
    """Closing price."""
    var volume: Float64
    """Trading volume."""

    fn __init__(out self, time: Int64, open: Float64, high: Float64,
                low: Float64, close: Float64, volume: Float64):
        """Creates a new bar (port of `Bar::new`)."""
        self.time = time
        self.open = open
        self.high = high
        self.low = low
        self.close = close
        self.volume = volume

    # ----- Direction methods (bar.rs) --------------------------------------

    fn is_bullish(self) -> Bool:
        """Returns true if this is a bullish bar (close > open)."""
        return self.close > self.open

    fn is_bearish(self) -> Bool:
        """Returns true if this is a bearish bar (close < open)."""
        return self.close < self.open

    fn is_doji(self, threshold: Float64) -> Bool:
        """Returns true if open is approximately equal to close.

        `threshold` is the body/range ratio below which the bar is a doji.
        """
        var rng = self.range()
        if rng == 0.0:
            return True
        return abs(self.close - self.open) / rng < threshold

    # ----- Price measurements (bar.rs) -------------------------------------

    fn body_height(self) -> Float64:
        """Body height: |close - open|."""
        return abs(self.close - self.open)

    fn range(self) -> Float64:
        """Total range: high - low."""
        return self.high - self.low

    fn upper_wick(self) -> Float64:
        """Upper wick height: high - max(open, close)."""
        return self.high - max(self.open, self.close)

    fn lower_wick(self) -> Float64:
        """Lower wick height: min(open, close) - low."""
        return min(self.open, self.close) - self.low

    # ----- Derived prices (bar.rs) -----------------------------------------

    fn typical_price(self) -> Float64:
        """Typical price (HLC3): (high + low + close) / 3."""
        return (self.high + self.low + self.close) / 3.0

    fn weighted_close(self) -> Float64:
        """Weighted close: (high + low + 2*close) / 4."""
        return (self.high + self.low + self.close * 2.0) / 4.0

    fn midpoint(self) -> Float64:
        """Midpoint (HL2): (high + low) / 2."""
        return (self.high + self.low) / 2.0

    fn avg_price(self) -> Float64:
        """Average price (OHLC4): (open + high + low + close) / 4."""
        return (self.open + self.high + self.low + self.close) / 4.0

    # Convenience aliases used by renderers (HL2 / HLC3 / OHLC4 naming).
    fn hl2(self) -> Float64:
        """Alias for `midpoint` ((high + low) / 2)."""
        return self.midpoint()

    fn hlc3(self) -> Float64:
        """Alias for `typical_price` ((high + low + close) / 3)."""
        return self.typical_price()

    fn ohlc4(self) -> Float64:
        """Alias for `avg_price` ((open + high + low + close) / 4)."""
        return self.avg_price()

    # ----- Ratios and percentages (bar.rs) ---------------------------------

    fn body_percentage(self) -> Float64:
        """Body as a fraction of total range (0.0..=1.0)."""
        var rng = self.range()
        if rng == 0.0:
            return 0.0
        return self.body_height() / rng

    fn wick_ratio(self) -> Float64:
        """Ratio of upper wick to lower wick; +inf when lower wick is zero."""
        var lower = self.lower_wick()
        if lower == 0.0:
            return inf[DType.float64]()
        return self.upper_wick() / lower

    fn change(self) -> Float64:
        """Price change: close - open."""
        return self.close - self.open

    fn change_percent(self) -> Float64:
        """Percentage change: (close - open) / open * 100."""
        if self.open == 0.0:
            return 0.0
        return (self.close - self.open) / self.open * 100.0

    # ----- Body position helpers (bar.rs) ----------------------------------

    fn body_top(self) -> Float64:
        """Top of the body: max(open, close)."""
        return max(self.open, self.close)

    fn body_bottom(self) -> Float64:
        """Bottom of the body: min(open, close)."""
        return min(self.open, self.close)


# =============================================================================
# BarData — port of model/bar/bar_data.rs  (struct BarData)
# =============================================================================

comptime MAX_BARS: Int = 10_000
"""Maximum bars to keep in memory per chart (model/bar/bar_data.rs)."""

comptime MAX_VISIBLE_BARS: Int = 2_000
"""Maximum bars visible at once (model/bar/bar_data.rs)."""


struct BarData(Copyable, Movable):
    """A collection of bars with aggregation/transform helpers.

    Port of `BarData` in model/bar/bar_data.rs.

    `BarData` owns a `List[Bar]`, so it is `Copyable` (explicit) rather than
    `ImplicitlyCopyable` — copy it with `.copy()` or move it with `^`.
    """

    var bars: List[Bar]
    """The underlying bar sequence (chronological order)."""

    fn __init__(out self):
        """Creates a new empty BarData (port of `BarData::new`)."""
        self.bars = List[Bar]()

    fn __init__(out self, var bars: List[Bar]):
        """Creates BarData from a list of bars (port of `BarData::from_bars`)."""
        self.bars = bars^

    fn push(mut self, bar: Bar):
        """Adds a bar to the dataset."""
        self.bars.append(bar)

    fn len(self) -> Int:
        """Returns the number of bars."""
        return len(self.bars)

    fn is_empty(self) -> Bool:
        """Returns true if there are no bars."""
        return len(self.bars) == 0

    fn clear(mut self):
        """Clear all bars."""
        self.bars.clear()

    fn push_with_limit(mut self, bar: Bar):
        """Push a bar and trim oldest bars when exceeding MAX_BARS."""
        self.bars.append(bar)
        self.trim_to_limit()

    fn trim_to_limit(mut self):
        """Remove oldest bars when exceeding MAX_BARS (port of `trim_to_limit`)."""
        var n = len(self.bars)
        if n > MAX_BARS:
            var excess = n - MAX_BARS
            # drain(0..excess): keep only the most recent MAX_BARS bars.
            var kept = List[Bar]()
            for i in range(excess, n):
                kept.append(self.bars[i])
            self.bars = kept^

    # ----- Aggregation methods (bar_data.rs) -------------------------------
    # Rust returns Option<f64>; with an empty dataset we return 0.0 and callers
    # should guard with `is_empty()` (documented divergence — Mojo has no cheap
    # Optional[Float64] idiom in the existing widget code).

    fn min_price(self) -> Float64:
        """Minimum low across all bars (0.0 if empty — guard with is_empty)."""
        if len(self.bars) == 0:
            return 0.0
        var m = self.bars[0].low
        for i in range(1, len(self.bars)):
            if self.bars[i].low < m:
                m = self.bars[i].low
        return m

    fn max_price(self) -> Float64:
        """Maximum high across all bars (0.0 if empty — guard with is_empty)."""
        if len(self.bars) == 0:
            return 0.0
        var m = self.bars[0].high
        for i in range(1, len(self.bars)):
            if self.bars[i].high > m:
                m = self.bars[i].high
        return m

    fn max_volume(self) -> Float64:
        """Maximum volume across all bars (0.0 if empty)."""
        if len(self.bars) == 0:
            return 0.0
        var m = self.bars[0].volume
        for i in range(1, len(self.bars)):
            if self.bars[i].volume > m:
                m = self.bars[i].volume
        return m

    fn total_volume(self) -> Float64:
        """Sum of volume across all bars."""
        var total: Float64 = 0.0
        for i in range(len(self.bars)):
            total += self.bars[i].volume
        return total

    fn avg_volume(self) -> Float64:
        """Average volume across all bars (0.0 if empty)."""
        if len(self.bars) == 0:
            return 0.0
        return self.total_volume() / Float64(len(self.bars))

    # ----- Transformation methods (bar_data.rs) ----------------------------

    fn to_heikin_ashi(self) -> BarData:
        """Convert regular OHLC bars to Heikin-Ashi bars.

        Faithful port of `BarData::to_heikin_ashi`:
          HA Close = (O + H + L + C) / 4
          HA Open  = (prev HA Open + prev HA Close) / 2
          HA High  = max(High, HA Open, HA Close)
          HA Low   = min(Low,  HA Open, HA Close)
        The first bar seeds HA Open = (open + close) / 2.
        """
        var n = len(self.bars)
        if n == 0:
            return BarData()

        var ha = List[Bar]()

        var first = self.bars[0]
        var prev_ha_open = (first.open + first.close) / 2.0
        var prev_ha_close = (first.open + first.high + first.low + first.close) / 4.0
        ha.append(Bar(first.time, prev_ha_open, first.high, first.low,
                      prev_ha_close, first.volume))

        for i in range(1, n):
            var bar = self.bars[i]
            var ha_close = (bar.open + bar.high + bar.low + bar.close) / 4.0
            var ha_open = (prev_ha_open + prev_ha_close) / 2.0
            var ha_high = max(bar.high, max(ha_open, ha_close))
            var ha_low = min(bar.low, min(ha_open, ha_close))
            ha.append(Bar(bar.time, ha_open, ha_high, ha_low, ha_close, bar.volume))
            prev_ha_open = ha_open
            prev_ha_close = ha_close

        return BarData(ha^)

    fn to_regular(self) -> BarData:
        """Returns a copy of the bar data (API parity with Rust `to_regular`)."""
        return BarData(self.bars.copy())


# =============================================================================
# Symbol — port of model/symbol.rs  (struct Symbol)
# =============================================================================

struct Symbol(ImplicitlyCopyable, Movable):
    """A trading symbol (financial instrument identifier).

    Port of `Symbol` in model/symbol.rs.  Pairs a machine-readable `name`
    (e.g. "BTCUSDT") with a human-readable `display_name`; `active` indicates a
    live data-feed subscription and defaults to true.
    """

    var name: String
    """Machine-readable symbol identifier (e.g. "AAPL", "BTCUSDT")."""
    var display_name: String
    """Human-readable display name (e.g. "Apple Inc.")."""
    var active: Bool
    """Whether this symbol is actively subscribed to a data feed."""

    fn __init__(out self, name: String, display_name: String):
        """Creates a new active symbol (port of `Symbol::new`)."""
        self.name = name
        self.display_name = display_name
        self.active = True


# =============================================================================
# Timeframe — port of model/timeframe.rs  (enum Timeframe)
# =============================================================================
# Rust models presets plus a `Custom(u64 seconds)` payload variant.  Mojo enums
# can't carry payloads, so a preset is an Int32 `comptime` id and `Custom` is
# represented by `TF_CUSTOM` with the seconds stored in the wrapper struct.

comptime TF_MS100: Int32 = 0
comptime TF_MS250: Int32 = 1
comptime TF_MS500: Int32 = 2
comptime TF_SEC1: Int32 = 3
comptime TF_SEC2: Int32 = 4
comptime TF_SEC5: Int32 = 5
comptime TF_SEC10: Int32 = 6
comptime TF_SEC30: Int32 = 7
comptime TF_MIN1: Int32 = 8
comptime TF_MIN5: Int32 = 9
comptime TF_MIN15: Int32 = 10
comptime TF_MIN30: Int32 = 11
comptime TF_HOUR1: Int32 = 12
comptime TF_HOUR4: Int32 = 13
comptime TF_DAY1: Int32 = 14
comptime TF_WEEK1: Int32 = 15
comptime TF_MONTH1: Int32 = 16
comptime TF_CUSTOM: Int32 = 17


struct Timeframe(ImplicitlyCopyable, Movable):
    """Bar aggregation interval (port of `Timeframe` in model/timeframe.rs).

    `kind` is one of the `TF_*` constants.  For `TF_CUSTOM`, `custom_seconds`
    holds the user-defined interval in seconds (matches `Custom(u64)`).
    """

    var kind: Int32
    """One of the `TF_*` preset constants, or `TF_CUSTOM`."""
    var custom_seconds: UInt64
    """Seconds for a `TF_CUSTOM` timeframe (ignored for presets)."""

    fn __init__(out self, kind: Int32 = TF_MIN1):
        """Creates a preset timeframe (default Min1, matching Rust `Default`)."""
        self.kind = kind
        self.custom_seconds = 0

    @staticmethod
    fn custom(seconds: UInt64) -> Timeframe:
        """Creates a custom timeframe (port of `Timeframe::Custom`)."""
        var tf = Timeframe(TF_CUSTOM)
        tf.custom_seconds = seconds
        return tf

    fn is_custom(self) -> Bool:
        """Returns true for a user-defined custom timeframe."""
        return self.kind == TF_CUSTOM

    fn duration_ms(self) -> Int64:
        """Duration in milliseconds (port of `Timeframe::duration_ms`)."""
        if self.kind == TF_MS100:  return 100
        if self.kind == TF_MS250:  return 250
        if self.kind == TF_MS500:  return 500
        if self.kind == TF_SEC1:   return 1_000
        if self.kind == TF_SEC2:   return 2_000
        if self.kind == TF_SEC5:   return 5_000
        if self.kind == TF_SEC10:  return 10_000
        if self.kind == TF_SEC30:  return 30_000
        if self.kind == TF_MIN1:   return 60_000
        if self.kind == TF_MIN5:   return 300_000
        if self.kind == TF_MIN15:  return 900_000
        if self.kind == TF_MIN30:  return 1_800_000
        if self.kind == TF_HOUR1:  return 3_600_000
        if self.kind == TF_HOUR4:  return 14_400_000
        if self.kind == TF_DAY1:   return 86_400_000
        if self.kind == TF_WEEK1:  return 604_800_000
        if self.kind == TF_MONTH1: return 2_592_000_000  # 30-day approximation
        # TF_CUSTOM
        return Int64(self.custom_seconds) * 1000

    fn total_seconds(self) -> UInt64:
        """Number of whole seconds for this timeframe."""
        var ms = self.duration_ms()
        if ms < 0:
            return 0
        return UInt64(ms // 1000)

    fn as_seconds(self) -> Int64:
        """Signed seconds for this timeframe (port of `as_seconds`)."""
        return Int64(self.total_seconds())

    fn to_seconds(self) -> Int64:
        """Alias for `as_seconds` (Rust backward-compat alias)."""
        return self.as_seconds()

    fn seconds(self) -> Int64:
        """Convenience seconds accessor used by the time scale."""
        return self.as_seconds()

    fn as_str(self) -> String:
        """Canonical label for this timeframe (port of `Timeframe::as_str`)."""
        if self.kind == TF_MS100:  return String("100ms")
        if self.kind == TF_MS250:  return String("250ms")
        if self.kind == TF_MS500:  return String("500ms")
        if self.kind == TF_SEC1:   return String("1s")
        if self.kind == TF_SEC2:   return String("2s")
        if self.kind == TF_SEC5:   return String("5s")
        if self.kind == TF_SEC10:  return String("10s")
        if self.kind == TF_SEC30:  return String("30s")
        if self.kind == TF_MIN1:   return String("1min")
        if self.kind == TF_MIN5:   return String("5min")
        if self.kind == TF_MIN15:  return String("15min")
        if self.kind == TF_MIN30:  return String("30min")
        if self.kind == TF_HOUR1:  return String("1h")
        if self.kind == TF_HOUR4:  return String("4h")
        if self.kind == TF_DAY1:   return String("1D")
        if self.kind == TF_WEEK1:  return String("1W")
        if self.kind == TF_MONTH1: return String("1M")
        return _format_custom_seconds(self.custom_seconds)


fn _format_custom_seconds(seconds: UInt64) -> String:
    """Largest clean unit label for a custom interval (port of
    `format_custom_seconds` in timeframe.rs)."""
    if seconds == 0:
        return String("0s")
    if seconds >= 86400 and seconds % 86400 == 0:
        return String(seconds // 86400) + "D"
    if seconds >= 3600 and seconds % 3600 == 0:
        return String(seconds // 3600) + "h"
    if seconds >= 60 and seconds % 60 == 0:
        return String(seconds // 60) + "min"
    return String(seconds) + "s"


# =============================================================================
# ChartType / ChartTypeCategory — port of model/chart_type.rs
# =============================================================================
# 20 variants, modelled as Int32 ids.  Order matches the Rust enum declaration
# (chart_type.rs lines 31-84) so the ids are stable and recognizable.

comptime CT_BARS: Int32 = 0
comptime CT_CANDLES: Int32 = 1            # default
comptime CT_HOLLOW_CANDLES: Int32 = 2
comptime CT_VOLUME_CANDLES: Int32 = 3
comptime CT_LINE: Int32 = 4
comptime CT_LINE_WITH_MARKERS: Int32 = 5
comptime CT_STEP_LINE: Int32 = 6
comptime CT_AREA: Int32 = 7
comptime CT_HLC_AREA: Int32 = 8
comptime CT_BASELINE: Int32 = 9
comptime CT_HIGH_LOW: Int32 = 10
comptime CT_RANGE: Int32 = 11
comptime CT_RENKO: Int32 = 12
comptime CT_KAGI: Int32 = 13
comptime CT_LINE_BREAK: Int32 = 14
comptime CT_HEIKIN: Int32 = 15
comptime CT_POINT_AND_FIGURE: Int32 = 16
comptime CT_VOLUME_FOOTPRINT: Int32 = 17
comptime CT_TIME_PRICE_OPPORTUNITY: Int32 = 18
comptime CT_SESSION_VOLUME: Int32 = 19

comptime CHART_TYPE_COUNT: Int32 = 20
"""Total number of chart types (asserted == 20 in the Rust tests)."""

# Categories (chart_type.rs `enum ChartTypeCategory`).
comptime CTC_STANDARD: Int32 = 0
comptime CTC_LINE_BASED: Int32 = 1
comptime CTC_AREA_BASED: Int32 = 2
comptime CTC_JAPANESE: Int32 = 3
comptime CTC_RANGE_BASED: Int32 = 4
comptime CTC_ADVANCED: Int32 = 5


struct ChartType(ImplicitlyCopyable, Movable):
    """A chart visualization type (port of `ChartType` in chart_type.rs).

    Wraps an Int32 `id` (one of the `CT_*` constants) and exposes the Rust
    helper methods (`name`, `category`, `uses_ohlc`, ...).  The default is
    `Candles`, matching `#[default]` on the Rust enum.
    """

    var id: Int32
    """One of the `CT_*` constants."""

    fn __init__(out self, id: Int32 = CT_CANDLES):
        """Creates a chart type (default Candles, matching Rust `Default`)."""
        self.id = id

    fn name(self) -> String:
        """User-facing display name (port of `ChartType::name`)."""
        if self.id == CT_BARS:                   return String("Bars")
        if self.id == CT_CANDLES:                return String("Candles")
        if self.id == CT_HOLLOW_CANDLES:         return String("Hollow candles")
        if self.id == CT_VOLUME_CANDLES:         return String("Volume candles")
        if self.id == CT_LINE:                   return String("Line")
        if self.id == CT_LINE_WITH_MARKERS:      return String("Line with markers")
        if self.id == CT_STEP_LINE:              return String("Step line")
        if self.id == CT_AREA:                   return String("Area")
        if self.id == CT_HLC_AREA:               return String("HLC area")
        if self.id == CT_BASELINE:               return String("Baseline")
        if self.id == CT_HIGH_LOW:               return String("High-low")
        if self.id == CT_RANGE:                  return String("Range")
        if self.id == CT_RENKO:                  return String("Renko")
        if self.id == CT_KAGI:                   return String("Kagi")
        if self.id == CT_LINE_BREAK:             return String("Line break")
        if self.id == CT_HEIKIN:                 return String("Heikin Ashi")
        if self.id == CT_POINT_AND_FIGURE:       return String("Point & Figure")
        if self.id == CT_VOLUME_FOOTPRINT:       return String("Volume footprint")
        if self.id == CT_TIME_PRICE_OPPORTUNITY: return String("Time Price Opportunity")
        if self.id == CT_SESSION_VOLUME:         return String("Session volume")
        return String("Unknown")

    fn description(self) -> String:
        """Technical tooltip description (port of `ChartType::description`)."""
        if self.id == CT_BARS:                   return String("OHLC bars with tick marks")
        if self.id == CT_CANDLES:                return String("Japanese candlesticks")
        if self.id == CT_HOLLOW_CANDLES:         return String("Hollow when close > open")
        if self.id == CT_VOLUME_CANDLES:         return String("Width based on volume")
        if self.id == CT_LINE:                   return String("Close price line")
        if self.id == CT_LINE_WITH_MARKERS:      return String("Line with data points")
        if self.id == CT_STEP_LINE:              return String("Stepped line chart")
        if self.id == CT_AREA:                   return String("Filled area chart")
        if self.id == CT_HLC_AREA:               return String("High-Low-Close area")
        if self.id == CT_BASELINE:               return String("Baseline comparison")
        if self.id == CT_HIGH_LOW:               return String("High-Low range")
        if self.id == CT_RANGE:                  return String("Range bars")
        if self.id == CT_RENKO:                  return String("Renko bricks")
        if self.id == CT_KAGI:                   return String("Kagi chart")
        if self.id == CT_LINE_BREAK:             return String("Three line break")
        if self.id == CT_HEIKIN:                 return String("Heikin-Ashi candles")
        if self.id == CT_POINT_AND_FIGURE:       return String("X and O chart")
        if self.id == CT_VOLUME_FOOTPRINT:       return String("Order flow analysis")
        if self.id == CT_TIME_PRICE_OPPORTUNITY: return String("TPO / Market Profile")
        if self.id == CT_SESSION_VOLUME:         return String("Volume by session")
        return String("")

    fn category(self) -> Int32:
        """Category this chart type belongs to (port of `ChartType::category`).

        Returns one of the `CTC_*` constants.
        """
        if (self.id == CT_BARS or self.id == CT_CANDLES
                or self.id == CT_HOLLOW_CANDLES or self.id == CT_VOLUME_CANDLES):
            return CTC_STANDARD
        if (self.id == CT_LINE or self.id == CT_LINE_WITH_MARKERS
                or self.id == CT_STEP_LINE):
            return CTC_LINE_BASED
        if (self.id == CT_AREA or self.id == CT_HLC_AREA or self.id == CT_BASELINE):
            return CTC_AREA_BASED
        if (self.id == CT_RENKO or self.id == CT_KAGI or self.id == CT_LINE_BREAK
                or self.id == CT_HEIKIN or self.id == CT_POINT_AND_FIGURE):
            return CTC_JAPANESE
        if (self.id == CT_HIGH_LOW or self.id == CT_RANGE):
            return CTC_RANGE_BASED
        # VolumeFootprint | TimePriceOpportunity | SessionVolume
        return CTC_ADVANCED

    fn uses_ohlc(self) -> Bool:
        """Whether this type uses OHLC data vs a single value
        (port of `ChartType::uses_ohlc`)."""
        if (self.id == CT_LINE or self.id == CT_LINE_WITH_MARKERS
                or self.id == CT_STEP_LINE or self.id == CT_AREA
                or self.id == CT_BASELINE):
            return False
        return True

    fn supports_volume(self) -> Bool:
        """Whether this type supports a volume sub-panel
        (port of `ChartType::supports_volume`)."""
        if (self.id == CT_RENKO or self.id == CT_KAGI
                or self.id == CT_POINT_AND_FIGURE or self.id == CT_RANGE
                or self.id == CT_LINE_BREAK):
            return False
        if (self.id == CT_VOLUME_FOOTPRINT or self.id == CT_SESSION_VOLUME):
            return False
        return True

    fn requires_parameters(self) -> Bool:
        """Whether this type needs extra params (port of `requires_parameters`)."""
        return (self.id == CT_RENKO or self.id == CT_KAGI or self.id == CT_RANGE
                or self.id == CT_POINT_AND_FIGURE or self.id == CT_LINE_BREAK
                or self.id == CT_BASELINE)

    fn is_time_independent(self) -> Bool:
        """Whether this type is time-independent (port of `is_time_independent`)."""
        return (self.id == CT_RENKO or self.id == CT_KAGI or self.id == CT_RANGE
                or self.id == CT_POINT_AND_FIGURE or self.id == CT_LINE_BREAK)

    fn transforms_data(self) -> Bool:
        """Whether this type transforms the input bars (port of `transforms_data`)."""
        return (self.id == CT_RENKO or self.id == CT_KAGI or self.id == CT_RANGE
                or self.id == CT_POINT_AND_FIGURE or self.id == CT_LINE_BREAK
                or self.id == CT_HEIKIN)


fn chart_type_category_name(category: Int32) -> String:
    """Display name for a chart-type category (port of
    `ChartTypeCategory::name`)."""
    if category == CTC_STANDARD:    return String("Standard")
    if category == CTC_LINE_BASED:  return String("Line")
    if category == CTC_AREA_BASED:  return String("Area")
    if category == CTC_JAPANESE:    return String("Japanese")
    if category == CTC_RANGE_BASED: return String("Range")
    if category == CTC_ADVANCED:    return String("Advanced")
    return String("Unknown")


fn all_chart_types() -> List[ChartType]:
    """All chart types in display order (port of `ChartType::all`).

    Note: Rust's `all()` uses a UI-display ordering distinct from the enum
    declaration order; this reproduces that exact display ordering.
    """
    var v = List[ChartType]()
    v.append(ChartType(CT_BARS))
    v.append(ChartType(CT_CANDLES))
    v.append(ChartType(CT_HOLLOW_CANDLES))
    v.append(ChartType(CT_VOLUME_CANDLES))
    v.append(ChartType(CT_LINE))
    v.append(ChartType(CT_LINE_WITH_MARKERS))
    v.append(ChartType(CT_STEP_LINE))
    v.append(ChartType(CT_AREA))
    v.append(ChartType(CT_HLC_AREA))
    v.append(ChartType(CT_BASELINE))
    v.append(ChartType(CT_HIGH_LOW))
    v.append(ChartType(CT_VOLUME_FOOTPRINT))
    v.append(ChartType(CT_TIME_PRICE_OPPORTUNITY))
    v.append(ChartType(CT_SESSION_VOLUME))
    v.append(ChartType(CT_LINE_BREAK))
    v.append(ChartType(CT_KAGI))
    v.append(ChartType(CT_RANGE))
    v.append(ChartType(CT_POINT_AND_FIGURE))
    v.append(ChartType(CT_RENKO))
    v.append(ChartType(CT_HEIKIN))
    return v^


# =============================================================================
# ChartTypeParams — port of model/chart_type.rs  (struct ChartTypeParams)
# =============================================================================

struct ChartTypeParams(ImplicitlyCopyable, Movable):
    """Configuration parameters for chart types that require them.

    Port of `ChartTypeParams` in chart_type.rs.  Defaults match the Rust
    `Default` impl.
    """

    var renko_brick_size: Float64
    """Renko brick size (price units). Default 1.0."""
    var kagi_reversal: Float64
    """Kagi reversal amount (price units or percentage). Default 4.0."""
    var range_size: Float64
    """Range bar size (price units). Default 10.0."""
    var pnf_box_size: Float64
    """Point & Figure box size. Default 1.0."""
    var pnf_reversal: UInt32
    """Point & Figure reversal count. Default 3."""
    var line_break_count: Int
    """Line break line count (typically 3). Default 3."""
    var baseline_price: Float64
    """Baseline price level (0.0 = derive from data). Default 0.0."""

    fn __init__(out self):
        """Creates params with Rust `Default` values."""
        self.renko_brick_size = 1.0
        self.kagi_reversal = 4.0
        self.range_size = 10.0
        self.pnf_box_size = 1.0
        self.pnf_reversal = 3
        self.line_break_count = 3
        self.baseline_price = 0.0

    @staticmethod
    fn with_atr_renko(atr: Float64, multiplier: Float64) -> ChartTypeParams:
        """Create with ATR-based Renko brick size (port of `with_atr_renko`)."""
        var p = ChartTypeParams()
        p.renko_brick_size = atr * multiplier
        return p
