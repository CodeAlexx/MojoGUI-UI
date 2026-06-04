"""
Chart data transforms — faithful ports of egui-charts `src/model/` algorithms.

Ported from:
  - /tmp/egui-charts-ref/src/model/renko.rs        -> RenkoBrick, RenkoConfig, to_renko_bricks, renko_atr
  - /tmp/egui-charts-ref/src/model/kagi.rs         -> KagiLine, KagiConfig, to_kagi_lines, kagi_atr
  - /tmp/egui-charts-ref/src/model/line_break.rs   -> LineBreakLine, LineBreakConfig, to_line_break_lines, detect_signal
  - /tmp/egui-charts-ref/src/model/point_figure.rs -> PnfColumn, PointFigureConfig, to_pnf_columns
  - /tmp/egui-charts-ref/src/model/range_bar.rs    -> RangeBar, TickData, RangeBarConfig, to_range_bars_from_*
  - /tmp/egui-charts-ref/src/model/bar/bar_data.rs -> to_heikin_ashi (also lives on BarData in model.mojo)

Conventions (see PORT_SPEC.md and model.mojo):
  - Prices are kept as Float64 everywhere; only the final pixel mapping (in the
    renderers/scales) rounds to Int32.  These transforms never round prices.
  - `__init__(out self, ...)`, mutating methods take `mut self`.
  - Rust enums (RenkoDirection, KagiThickness, ColumnDirection, LineDirection,
    LineBreakSignal) become Int32 `comptime` constants — Mojo has no
    payload-carrying enums.  Each transform line/brick struct keeps the Rust
    field set so renderers can consume it directly, plus a `to_bar()` that
    matches the Rust `to_bar()` impls.
  - Structs stored in a `List` derive `(ImplicitlyCopyable, Movable)`; `List[T]`
    returns are transferred with `^`.  (Verified conventions from the foundation
    build — `inout self` is a hard error on this nightly.)
"""

from math import floor, inf

from .model import Bar


# =============================================================================
# Shared helpers
# =============================================================================

fn _price_min_max(bars: List[Bar]) -> Tuple[Float64, Float64]:
    """(min low, max high) over all bars — port of the `fold` in each transform.

    Mirrors `bars.iter().fold((f64::MAX, f64::MIN), ...)`; returns (0,0) for an
    empty slice (callers guard on emptiness first, as the Rust code does).
    """
    if len(bars) == 0:
        return (0.0, 0.0)
    var lo = bars[0].low
    var hi = bars[0].high
    for i in range(len(bars)):
        if bars[i].low < lo:
            lo = bars[i].low
        if bars[i].high > hi:
            hi = bars[i].high
    return (lo, hi)


fn _atr(bars: List[Bar], period: Int) -> Float64:
    """Average True Range — port of the `calculate_atr` used by renko/kagi.

    (renko.rs / kagi.rs version.)  When fewer bars than `period`, falls back to
    the mean high-low range over all bars.  Otherwise it is the simple mean of
    the last `period` true ranges (TR = max(H-L, |H-prevC|, |L-prevC|)), divided
    by `min(period, true_ranges.len())`.
    """
    var n = len(bars)
    if n < period:
        var sum: Float64 = 0.0
        for i in range(n):
            sum += bars[i].high - bars[i].low
        if n == 0:
            return 0.0
        return sum / Float64(n)

    var true_ranges = List[Float64]()
    for i in range(1, n):
        var high_low = bars[i].high - bars[i].low
        var high_close_prev = abs(bars[i].high - bars[i - 1].close)
        var low_close_prev = abs(bars[i].low - bars[i - 1].close)
        var tr = max(high_low, max(high_close_prev, low_close_prev))
        true_ranges.append(tr)

    var tn = len(true_ranges)
    # skip(true_ranges.len().saturating_sub(period)) -> last `period` values.
    var start = 0
    if tn > period:
        start = tn - period
    var sum: Float64 = 0.0
    for i in range(start, tn):
        sum += true_ranges[i]
    var denom = period
    if tn < denom:
        denom = tn
    if denom == 0:
        return 0.0
    return sum / Float64(denom)


fn _atr_pnf(bars: List[Bar], period: Int) -> Float64:
    """Average True Range — port of the `calculate_atr` used by point_figure.rs
    and range_bar.rs.

    Differs from `_atr` above: returns 1.0 when fewer than 2 bars; when fewer
    than `period` true ranges, returns their plain mean; otherwise the mean of
    the last `period` true ranges divided by `period` (not min(period, len)).
    """
    var n = len(bars)
    if n < 2:
        return 1.0

    var tr_values = List[Float64]()
    for i in range(1, n):
        var high = bars[i].high
        var low = bars[i].low
        var prev_close = bars[i - 1].close
        var tr = max(high - low, max(abs(high - prev_close), abs(low - prev_close)))
        tr_values.append(tr)

    var tn = len(tr_values)
    if tn < period:
        var sum: Float64 = 0.0
        for i in range(tn):
            sum += tr_values[i]
        if tn == 0:
            return 1.0
        return sum / Float64(tn)

    # rev().take(period) -> last `period` values; divided by `period`.
    var start = tn - period
    var sum: Float64 = 0.0
    for i in range(start, tn):
        sum += tr_values[i]
    return sum / Float64(period)


# =============================================================================
# Renko — port of model/renko.rs
# =============================================================================

comptime RENKO_UP: Int32 = 0
"""Bullish brick — price moved up by one brick size (renko.rs `RenkoDirection::Up`)."""
comptime RENKO_DOWN: Int32 = 1
"""Bearish brick — price moved down by one brick size (renko.rs `RenkoDirection::Down`)."""

comptime RENKO_MAX_BRICKS: Int = 10_000
"""Safety cap on brick count (renko.rs `MAX_BRICKS`)."""


struct RenkoBrick(ImplicitlyCopyable, Movable):
    """A single Renko brick (port of `RenkoBrick` in renko.rs).

    `ts` is the timestamp of the source bar that completed the brick (Unix
    epoch milliseconds, matching model.Bar.time).
    """

    var ts: Int64
    """Timestamp of the source bar that completed this brick."""
    var open: Float64
    """Opening price (bottom of an Up brick, top of a Down brick)."""
    var close: Float64
    """Closing price (top of an Up brick, bottom of a Down brick)."""
    var direction: Int32
    """`RENKO_UP` or `RENKO_DOWN`."""

    fn __init__(out self, ts: Int64, open: Float64, close: Float64,
                direction: Int32):
        self.ts = ts
        self.open = open
        self.close = close
        self.direction = direction

    fn to_bar(self) -> Bar:
        """Convert to a Bar for rendering (port of `RenkoBrick::to_bar`)."""
        return Bar(self.ts, self.open, max(self.open, self.close),
                   min(self.open, self.close), self.close, 0.0)


struct RenkoConfig(ImplicitlyCopyable, Movable):
    """Renko transform configuration (port of `RenkoConfig`)."""

    var brick_size: Float64
    """Size of each brick in price units (default 1.0)."""

    fn __init__(out self, brick_size: Float64 = 1.0):
        self.brick_size = brick_size

    @staticmethod
    fn from_atr(bars: List[Bar], period: Int, multiplier: Float64) -> RenkoConfig:
        """Brick size from ATR (port of `RenkoConfig::from_atr`)."""
        return RenkoConfig(_atr(bars, period) * multiplier)


fn to_renko_bricks(bars: List[Bar], config: RenkoConfig) -> List[RenkoBrick]:
    """Transform bars into Renko bricks (faithful port of `to_renko_bricks`).

    A new brick forms each time price moves a full `brick_size` from the running
    `curr_price` (started at the first close floored to a brick boundary).  The
    brick size is auto-bumped to at least `price_range / 200` and at least
    0.0001 to bound the brick count, matching the Rust safety logic.
    """
    var bricks = List[RenkoBrick]()
    if len(bars) == 0:
        return bricks^

    var mm = _price_min_max(bars)
    var price_range = mm[1] - mm[0]

    # Auto-adjust brick size (aim for <=200 bricks); never zero/negative.
    var min_brick_size = price_range / 200.0
    var brick_size = max(max(config.brick_size, min_brick_size), 0.0001)

    # Start at the first close, aligned down to a brick boundary.
    var curr_price = floor(bars[0].close / brick_size) * brick_size

    for bi in range(len(bars)):
        var price = bars[bi].close
        var price_diff = price - curr_price
        var num_bricks = Int(floor(abs(price_diff) / brick_size))

        if num_bricks > 0:
            var direction = RENKO_UP if price_diff > 0.0 else RENKO_DOWN

            # min(num_bricks, MAX_BRICKS - bricks.len())
            var room = RENKO_MAX_BRICKS - len(bricks)
            var bricks_to_create = num_bricks
            if bricks_to_create > room:
                bricks_to_create = room

            for _ in range(bricks_to_create):
                var brick_open = curr_price
                var brick_close: Float64
                if direction == RENKO_UP:
                    brick_close = curr_price + brick_size
                else:
                    brick_close = curr_price - brick_size

                bricks.append(RenkoBrick(bars[bi].time, brick_open, brick_close,
                                         direction))
                curr_price = brick_close

                if len(bricks) >= RENKO_MAX_BRICKS:
                    return bricks^

    return bricks^


# =============================================================================
# Kagi — port of model/kagi.rs
# =============================================================================

comptime KAGI_THIN: Int32 = 0
"""Thin line — downtrend / Yang (kagi.rs `KagiThickness::Thin`)."""
comptime KAGI_THICK: Int32 = 1
"""Thick line — uptrend / Yin (kagi.rs `KagiThickness::Thick`)."""

comptime KAGI_MAX_LINES: Int = 10_000
"""Safety cap on line count (kagi.rs `MAX_LINES`)."""


struct KagiLine(ImplicitlyCopyable, Movable):
    """A single vertical Kagi segment (port of `KagiLine` in kagi.rs)."""

    var ts: Int64
    """Timestamp when this segment was created (source bar)."""
    var start_price: Float64
    """Price at the beginning of this segment."""
    var end_price: Float64
    """Price at the end of this segment."""
    var thickness: Int32
    """`KAGI_THIN` or `KAGI_THICK` (trend state)."""

    fn __init__(out self, ts: Int64, start_price: Float64, end_price: Float64,
                thickness: Int32):
        self.ts = ts
        self.start_price = start_price
        self.end_price = end_price
        self.thickness = thickness

    fn to_bar(self) -> Bar:
        """Convert to a Bar for rendering (port of `KagiLine::to_bar`)."""
        return Bar(self.ts, self.start_price,
                   max(self.start_price, self.end_price),
                   min(self.start_price, self.end_price),
                   self.end_price, 0.0)

    fn is_up(self) -> Bool:
        """True if the segment is moving up (port of `KagiLine::is_up`)."""
        return self.end_price > self.start_price


struct KagiConfig(ImplicitlyCopyable, Movable):
    """Kagi transform configuration (port of `KagiConfig`)."""

    var reversal_amount: Float64
    """Price movement needed to create a new line (default 1.0)."""

    fn __init__(out self, reversal_amount: Float64 = 1.0):
        self.reversal_amount = reversal_amount

    @staticmethod
    fn from_atr(bars: List[Bar], period: Int, multiplier: Float64) -> KagiConfig:
        """Reversal from ATR (port of `KagiConfig::from_atr`)."""
        return KagiConfig(_atr(bars, period) * multiplier)

    @staticmethod
    fn from_percentage(base_price: Float64, percentage: Float64) -> KagiConfig:
        """Reversal as a percentage of price (port of `from_percentage`)."""
        return KagiConfig(base_price * (percentage / 100.0))


fn to_kagi_lines(bars: List[Bar], config: KagiConfig) -> List[KagiLine]:
    """Transform bars into Kagi lines (faithful port of `to_kagi_lines`).

    Tracks a running price and line direction; on a reversal of at least
    `reversal` the current line is committed and a new line starts in the
    opposite direction.  Thickness flips to Thick when a new significant high is
    broken (uptrend) and to Thin when a new significant low is broken
    (downtrend).  `reversal` is bumped to at least `price_range / 500`.
    """
    var lines = List[KagiLine]()
    if len(bars) == 0:
        return lines^

    var mm = _price_min_max(bars)
    var price_range = mm[1] - mm[0]

    var min_reversal = price_range / 500.0
    var reversal = max(max(config.reversal_amount, min_reversal), 0.0001)

    var curr_price = bars[0].close
    var line_start_price = bars[0].close
    var line_direction_up = True
    var last_ts = bars[0].time

    var significant_high = curr_price
    var significant_low = curr_price
    var is_thick = curr_price > line_start_price

    for bi in range(1, len(bars)):
        last_ts = bars[bi].time
        var price = bars[bi].close

        if line_direction_up:
            if price > curr_price:
                # Continue up.
                curr_price = price
                if price > significant_high:
                    significant_high = price
            elif price < (curr_price - reversal):
                # Reversal down: commit current line.
                var th = KAGI_THICK if is_thick else KAGI_THIN
                lines.append(KagiLine(last_ts, line_start_price, curr_price, th))
                if len(lines) >= KAGI_MAX_LINES:
                    return lines^

                line_start_price = curr_price
                curr_price = price
                line_direction_up = False

                if price < significant_low:
                    is_thick = False  # switch to thin (downtrend)
                    significant_low = price
        else:
            if price < curr_price:
                # Continue down.
                curr_price = price
                if price < significant_low:
                    significant_low = price
            elif price > (curr_price + reversal):
                # Reversal up: commit current line.
                var th = KAGI_THICK if is_thick else KAGI_THIN
                lines.append(KagiLine(last_ts, line_start_price, curr_price, th))
                if len(lines) >= KAGI_MAX_LINES:
                    return lines^

                line_start_price = curr_price
                curr_price = price
                line_direction_up = True

                if price > significant_high:
                    is_thick = True  # switch to thick (uptrend)
                    significant_high = price

    # Add final line.
    if line_start_price != curr_price:
        var th = KAGI_THICK if is_thick else KAGI_THIN
        lines.append(KagiLine(last_ts, line_start_price, curr_price, th))

    return lines^


# =============================================================================
# Line Break (Three-Line Break) — port of model/line_break.rs
# =============================================================================

comptime LB_UP: Int32 = 0
"""Up line (line_break.rs `LineDirection::Up`)."""
comptime LB_DOWN: Int32 = 1
"""Down line (line_break.rs `LineDirection::Down`)."""

comptime LB_MAX_LINES: Int = 10_000
"""Safety cap on line count (line_break.rs `MAX_LINES`)."""

# LineBreakSignal (line_break.rs).
comptime LB_SIGNAL_NONE: Int32 = 0
comptime LB_SIGNAL_BULLISH: Int32 = 1
comptime LB_SIGNAL_BEARISH: Int32 = 2
comptime LB_SIGNAL_BULLISH_REVERSAL: Int32 = 3
comptime LB_SIGNAL_BEARISH_REVERSAL: Int32 = 4


struct LineBreakLine(ImplicitlyCopyable, Movable):
    """A single block in a Line Break chart (port of `LineBreakLine`)."""

    var open: Float64
    """Open price (previous line's close)."""
    var close: Float64
    """Close price."""
    var direction: Int32
    """`LB_UP` or `LB_DOWN`."""
    var ts: Int64
    """Timestamp when the line was created."""

    fn __init__(out self, open: Float64, close: Float64, direction: Int32,
                ts: Int64):
        self.open = open
        self.close = close
        self.direction = direction
        self.ts = ts

    fn high(self) -> Float64:
        """High of the line: max(open, close) (port of `high`)."""
        return max(self.open, self.close)

    fn low(self) -> Float64:
        """Low of the line: min(open, close) (port of `low`)."""
        return min(self.open, self.close)

    fn is_bullish(self) -> Bool:
        """True if an up line (port of `is_bullish`)."""
        return self.direction == LB_UP

    fn is_bearish(self) -> Bool:
        """True if a down line (port of `is_bearish`)."""
        return self.direction == LB_DOWN

    fn to_bar(self) -> Bar:
        """Convert to a Bar for rendering (parity with the other transforms)."""
        return Bar(self.ts, self.open, self.high(), self.low(), self.close, 0.0)


struct LineBreakConfig(ImplicitlyCopyable, Movable):
    """Line Break configuration (port of `LineBreakConfig`)."""

    var line_cnt: Int
    """Number of prior lines to look back for a reversal (default 3)."""

    fn __init__(out self, line_cnt: Int = 3):
        self.line_cnt = line_cnt


fn to_line_break_lines(data: List[Bar], config: LineBreakConfig) -> List[LineBreakLine]:
    """Convert bars to Line Break lines (faithful port of `to_line_break_lines`).

    Seeds the first line from bar[0]'s open/close direction.  A continuation
    needs the close to exceed the last line's high (up) or break its low (down);
    a reversal needs the close to break beyond the high/low of the last
    `min(line_cnt, lines.len())` lines.
    """
    var lines = List[LineBreakLine]()
    if len(data) == 0:
        return lines^

    var initial_direction = LB_UP if data[0].close >= data[0].open else LB_DOWN
    lines.append(LineBreakLine(data[0].open, data[0].close, initial_direction,
                               data[0].time))

    for bi in range(1, len(data)):
        if len(lines) == 0 or len(lines) >= LB_MAX_LINES:
            continue

        # last_line snapshot (Rust borrows lines.last()).
        var last_idx = len(lines) - 1
        var last_high = lines[last_idx].high()
        var last_low = lines[last_idx].low()
        var last_close = lines[last_idx].close
        var curr_direction = lines[last_idx].direction
        var bar_close = data[bi].close

        if curr_direction == LB_UP:
            if bar_close > last_high:
                # Continuation up.
                lines.append(LineBreakLine(last_close, bar_close, LB_UP,
                                           data[bi].time))
            else:
                # Reversal: close must break below the low of the last N lines.
                var lookback = config.line_cnt
                if lookback > len(lines):
                    lookback = len(lines)
                var reversal_low = inf[DType.float64]()
                for k in range(len(lines) - lookback, len(lines)):
                    if lines[k].low() < reversal_low:
                        reversal_low = lines[k].low()
                if bar_close < reversal_low:
                    lines.append(LineBreakLine(last_close, bar_close, LB_DOWN,
                                               data[bi].time))
        else:  # LB_DOWN
            if bar_close < last_low:
                # Continuation down.
                lines.append(LineBreakLine(last_close, bar_close, LB_DOWN,
                                           data[bi].time))
            else:
                # Reversal: close must break above the high of the last N lines.
                var lookback = config.line_cnt
                if lookback > len(lines):
                    lookback = len(lines)
                var reversal_high = -inf[DType.float64]()
                for k in range(len(lines) - lookback, len(lines)):
                    if lines[k].high() > reversal_high:
                        reversal_high = lines[k].high()
                if bar_close > reversal_high:
                    lines.append(LineBreakLine(last_close, bar_close, LB_UP,
                                               data[bi].time))

    return lines^


fn detect_signal(lines: List[LineBreakLine]) -> Int32:
    """Classify the last two lines (faithful port of `detect_signal`).

    Returns one of the `LB_SIGNAL_*` constants; `LB_SIGNAL_NONE` when fewer than
    two lines exist.
    """
    if len(lines) < 2:
        return LB_SIGNAL_NONE

    var prev = lines[len(lines) - 2].direction
    var current = lines[len(lines) - 1].direction

    if prev == LB_DOWN and current == LB_UP:
        return LB_SIGNAL_BULLISH_REVERSAL
    if prev == LB_UP and current == LB_DOWN:
        return LB_SIGNAL_BEARISH_REVERSAL
    if prev == LB_UP and current == LB_UP:
        return LB_SIGNAL_BULLISH
    # (Down, Down)
    return LB_SIGNAL_BEARISH


# =============================================================================
# Point & Figure — port of model/point_figure.rs
# =============================================================================

comptime PNF_UP: Int32 = 0
"""Rising column of Xs (point_figure.rs `ColumnDirection::Up`)."""
comptime PNF_DOWN: Int32 = 1
"""Falling column of Os (point_figure.rs `ColumnDirection::Down`)."""

comptime PNF_MAX_COLUMNS: Int = 5_000
"""Safety cap on column count (point_figure.rs `MAX_COLUMNS`)."""


struct PnfColumn(ImplicitlyCopyable, Movable):
    """A single column of Xs/Os in a P&F chart (port of `PnfColumn`)."""

    var start_price: Float64
    """Starting price (bottom for Up, top for Down)."""
    var end_price: Float64
    """Ending price (top for Up, bottom for Down)."""
    var direction: Int32
    """`PNF_UP` or `PNF_DOWN`."""
    var start_time: Int64
    """Timestamp when the column started."""
    var end_time: Int64
    """Timestamp when the column ended."""
    var box_size: Float64
    """Box size used for this column."""
    var box_cnt: Int
    """Number of boxes in this column."""

    fn __init__(out self, start_price: Float64, end_price: Float64,
                direction: Int32, start_time: Int64, end_time: Int64,
                box_size: Float64, box_cnt: Int):
        self.start_price = start_price
        self.end_price = end_price
        self.direction = direction
        self.start_time = start_time
        self.end_time = end_time
        self.box_size = box_size
        self.box_cnt = box_cnt

    fn low(self) -> Float64:
        """Low price of the column (port of `PnfColumn::low`)."""
        return min(self.start_price, self.end_price)

    fn high(self) -> Float64:
        """High price of the column (port of `PnfColumn::high`)."""
        return max(self.start_price, self.end_price)

    fn boxes(self) -> List[Float64]:
        """All box prices in this column (port of `PnfColumn::boxes`)."""
        var prices = List[Float64]()
        var low = self.low()
        var count = Int(_round_half(((self.high() - low) / self.box_size)))
        for i in range(count + 1):
            prices.append(low + (Float64(i) * self.box_size))
        return prices^

    fn contains(self, price: Float64) -> Bool:
        """True if the column spans `price` (port of `PnfColumn::contains`)."""
        return price >= self.low() and price <= self.high()


struct PointFigureConfig(ImplicitlyCopyable, Movable):
    """Point & Figure configuration (port of `PointFigureConfig`)."""

    var box_size: Float64
    """Box size in price units (default 1.0)."""
    var reversal_boxes: Int
    """Number of boxes required for reversal (default 3)."""
    var use_atr: Bool
    """Whether to use ATR for box size (default False)."""
    var atr_period: Int
    """ATR period when using ATR boxes (default 14)."""
    var use_close: Bool
    """Close-only method instead of high/low (default False)."""

    fn __init__(out self, box_size: Float64 = 1.0, reversal_boxes: Int = 3,
                use_atr: Bool = False, atr_period: Int = 14,
                use_close: Bool = False):
        self.box_size = box_size
        self.reversal_boxes = reversal_boxes
        self.use_atr = use_atr
        self.atr_period = atr_period
        self.use_close = use_close

    fn with_atr(self, period: Int) -> PointFigureConfig:
        """ATR-derived box size (port of `with_atr`)."""
        return PointFigureConfig(self.box_size, self.reversal_boxes, True,
                                 period, self.use_close)

    fn with_close_only(self) -> PointFigureConfig:
        """Close-only method (port of `with_close_only`)."""
        return PointFigureConfig(self.box_size, self.reversal_boxes,
                                 self.use_atr, self.atr_period, True)


fn _snap_to_box(price: Float64, box_size: Float64) -> Float64:
    """Snap price down to the nearest box boundary (port of `snap_to_box`)."""
    return floor(price / box_size) * box_size


fn _round_half(x: Float64) -> Float64:
    """Round half away from zero — matches Rust `f64::round`.

    Mojo's `math.round` is round-half-to-even; Rust rounds half away from zero,
    so the P&F box counts must use this to stay faithful.
    """
    if x >= 0.0:
        return floor(x + 0.5)
    return -floor(-x + 0.5)


fn to_pnf_columns(data: List[Bar], config: PointFigureConfig) -> List[PnfColumn]:
    """Convert bars to P&F columns (faithful port of `to_pnf_columns`).

    Each column extends while price makes new boxes in its direction; a new
    column of the opposite direction starts when counter-movement reaches
    `reversal_boxes * box_size`.  Box size is auto-bumped to at least
    `price_range / 500`.  Note the final (active) column is always pushed.
    """
    var columns = List[PnfColumn]()
    if len(data) == 0:
        return columns^

    var mm = _price_min_max(data)
    var price_range = mm[1] - mm[0]

    var base_box_size: Float64
    if config.use_atr and len(data) >= config.atr_period:
        base_box_size = _atr_pnf(data, config.atr_period)
    else:
        base_box_size = config.box_size

    var min_box_size = price_range / 500.0
    var box_size = max(max(base_box_size, min_box_size), 0.0001)

    var reversal_amount = box_size * Float64(config.reversal_boxes)

    var initial_price = data[0].close if config.use_close else data[0].high
    var snapped = _snap_to_box(initial_price, box_size)

    var curr_start_price = snapped
    var curr_end_price = snapped
    var curr_direction = PNF_UP
    var curr_start_time = data[0].time
    var curr_end_time = data[0].time
    var curr_box_cnt = 1

    for bi in range(1, len(data)):
        var high_price: Float64
        var low_price: Float64
        if config.use_close:
            high_price = data[bi].close
            low_price = data[bi].close
        else:
            high_price = data[bi].high
            low_price = data[bi].low

        if curr_direction == PNF_UP:
            # Continuation (new highs).
            var new_high = _snap_to_box(high_price, box_size)
            if new_high > curr_end_price:
                curr_end_price = new_high
                curr_end_time = data[bi].time
                curr_box_cnt = Int(_round_half((curr_end_price - curr_start_price)
                                               / box_size)) + 1

            # Reversal.
            var new_low = _snap_to_box(low_price, box_size)
            if curr_end_price - new_low >= reversal_amount:
                columns.append(PnfColumn(curr_start_price, curr_end_price,
                                         PNF_UP, curr_start_time, curr_end_time,
                                         box_size, curr_box_cnt))
                if len(columns) >= PNF_MAX_COLUMNS:
                    return columns^

                var new_start = curr_end_price - box_size
                var new_box_cnt = Int(_round_half((curr_end_price - box_size - new_low)
                                                  / box_size)) + 1
                curr_start_price = new_start
                curr_end_price = new_low
                curr_direction = PNF_DOWN
                curr_start_time = data[bi].time
                curr_end_time = data[bi].time
                curr_box_cnt = new_box_cnt
        else:  # PNF_DOWN
            # Continuation (new lows).
            var new_low = _snap_to_box(low_price, box_size)
            if new_low < curr_end_price:
                curr_end_price = new_low
                curr_end_time = data[bi].time
                curr_box_cnt = Int(_round_half((curr_start_price - curr_end_price)
                                               / box_size)) + 1

            # Reversal.
            var new_high = _snap_to_box(high_price, box_size)
            if new_high - curr_end_price >= reversal_amount:
                columns.append(PnfColumn(curr_start_price, curr_end_price,
                                         PNF_DOWN, curr_start_time, curr_end_time,
                                         box_size, curr_box_cnt))
                if len(columns) >= PNF_MAX_COLUMNS:
                    return columns^

                var new_start = curr_end_price + box_size
                var new_box_cnt = Int(_round_half((new_high - curr_end_price - box_size)
                                                  / box_size)) + 1
                curr_start_price = new_start
                curr_end_price = new_high
                curr_direction = PNF_UP
                curr_start_time = data[bi].time
                curr_end_time = data[bi].time
                curr_box_cnt = new_box_cnt

    # Always push the final column.
    columns.append(PnfColumn(curr_start_price, curr_end_price, curr_direction,
                             curr_start_time, curr_end_time, box_size,
                             curr_box_cnt))

    return columns^


# =============================================================================
# Range bars — port of model/range_bar.rs
# =============================================================================

comptime RANGE_MAX_BARS: Int = 5_000
"""Safety cap for OHLC-derived range bars (range_bar.rs `MAX_BARS`)."""
comptime RANGE_MAX_ITERATIONS: Int = 100
"""Inner reversal loop cap (range_bar.rs `MAX_ITERATIONS`)."""


struct RangeBar(ImplicitlyCopyable, Movable):
    """A single range bar — fixed price range, variable time (port of `RangeBar`)."""

    var open: Float64
    var high: Float64
    var low: Float64
    var close: Float64
    var volume: Float64
    var start_time: Int64
    """Timestamp when the bar started."""
    var end_time: Int64
    """Timestamp when the bar completed."""
    var range_size: Float64
    """Range size used for this bar."""
    var tick_cnt: Int
    """Number of ticks/source bars folded into this bar."""

    fn __init__(out self, open: Float64, high: Float64, low: Float64,
                close: Float64, volume: Float64, start_time: Int64,
                end_time: Int64, range_size: Float64, tick_cnt: Int):
        self.open = open
        self.high = high
        self.low = low
        self.close = close
        self.volume = volume
        self.start_time = start_time
        self.end_time = end_time
        self.range_size = range_size
        self.tick_cnt = tick_cnt

    fn is_bullish(self) -> Bool:
        """True if close >= open (port of `RangeBar::is_bullish`)."""
        return self.close >= self.open

    fn is_bearish(self) -> Bool:
        """True if close < open (port of `RangeBar::is_bearish`)."""
        return self.close < self.open

    fn range(self) -> Float64:
        """Bar range: high - low (port of `RangeBar::range`)."""
        return self.high - self.low

    fn body(self) -> Float64:
        """Absolute body size (port of `RangeBar::body`)."""
        return abs(self.close - self.open)

    fn to_bar(self) -> Bar:
        """Convert to a standard Bar (port of `RangeBar::to_bar`)."""
        return Bar(self.end_time, self.open, self.high, self.low, self.close,
                   self.volume)


struct TickData(ImplicitlyCopyable, Movable):
    """A minimal tick record for exact range-bar construction (port of `TickData`)."""

    var price: Float64
    """Trade price."""
    var volume: Float64
    """Trade size/volume."""
    var ts: Int64
    """Trade timestamp (Unix epoch milliseconds)."""

    fn __init__(out self, price: Float64, volume: Float64, ts: Int64):
        self.price = price
        self.volume = volume
        self.ts = ts


struct RangeBarConfig(ImplicitlyCopyable, Movable):
    """Range-bar configuration (port of `RangeBarConfig`)."""

    var range_size: Float64
    """Fixed range size in price units (default 10.0)."""
    var use_atr: Bool
    """Whether to use ATR for range size (default False)."""
    var atr_period: Int
    """ATR period when using ATR ranges (default 14)."""
    var atr_multiplier: Float64
    """ATR multiplier (default 1.0)."""

    fn __init__(out self, range_size: Float64 = 10.0, use_atr: Bool = False,
                atr_period: Int = 14, atr_multiplier: Float64 = 1.0):
        self.range_size = range_size
        self.use_atr = use_atr
        self.atr_period = atr_period
        self.atr_multiplier = atr_multiplier

    fn with_atr(self, period: Int, multiplier: Float64) -> RangeBarConfig:
        """Derive range size from ATR (port of `with_atr`)."""
        return RangeBarConfig(self.range_size, True, period, multiplier)


fn to_range_bars_from_ticks(ticks: List[TickData],
                            config: RangeBarConfig) -> List[RangeBar]:
    """Build range bars from raw ticks (exact; faithful port of
    `to_range_bars_from_ticks`).

    Each bar grows tick by tick until its range reaches `range_size`, then it is
    closed exactly at `low + range_size` (up) or `high - range_size` (down) and
    a new bar opens from that close.  The trailing incomplete bar is emitted if
    it has any ticks.
    """
    var bars = List[RangeBar]()
    if len(ticks) == 0:
        return bars^

    var range_size = config.range_size

    var cb_open = ticks[0].price
    var cb_high = ticks[0].price
    var cb_low = ticks[0].price
    var cb_close = ticks[0].price
    var cb_volume = ticks[0].volume
    var cb_start_time = ticks[0].ts
    var cb_end_time = ticks[0].ts
    var cb_tick_cnt = 1

    for ti in range(1, len(ticks)):
        var tick_price = ticks[ti].price
        # Update current bar.
        cb_high = max(cb_high, tick_price)
        cb_low = min(cb_low, tick_price)
        cb_close = tick_price
        cb_volume += ticks[ti].volume
        cb_end_time = ticks[ti].ts
        cb_tick_cnt += 1

        # Range exceeded?
        if (cb_high - cb_low) >= range_size:
            if tick_price >= cb_open:
                # Moving up.
                cb_close = cb_low + range_size
                cb_high = cb_close
            else:
                # Moving down.
                cb_close = cb_high - range_size
                cb_low = cb_close

            bars.append(RangeBar(cb_open, cb_high, cb_low, cb_close, cb_volume,
                                 cb_start_time, cb_end_time, range_size,
                                 cb_tick_cnt))

            # Start new bar from the prior close.
            var prev_close = cb_close
            cb_open = prev_close
            cb_high = max(tick_price, prev_close)
            cb_low = min(tick_price, prev_close)
            cb_close = tick_price
            cb_volume = 0.0
            cb_start_time = ticks[ti].ts
            cb_end_time = ticks[ti].ts
            cb_tick_cnt = 0

    # Add the incomplete bar if it has any ticks.
    if cb_tick_cnt > 0:
        bars.append(RangeBar(cb_open, cb_high, cb_low, cb_close, cb_volume,
                             cb_start_time, cb_end_time, range_size,
                             cb_tick_cnt))

    return bars^


fn to_range_bars_from_ohlc(data: List[Bar],
                           config: RangeBarConfig) -> List[RangeBar]:
    """Approximate range bars from OHLC bars (faithful port of
    `to_range_bars_from_ohlc`).

    Each source bar is fed as the sequence [open, high, low, close]; whenever the
    running range reaches `range_size` the bar is completed (up if
    `high - open >= range_size`, else down) and a new bar opens from that close.
    Range size is auto-bumped to at least `price_range / 200`.
    """
    var bars = List[RangeBar]()
    if len(data) == 0:
        return bars^

    var mm = _price_min_max(data)
    var price_range = mm[1] - mm[0]

    var base_range_size: Float64
    if config.use_atr and len(data) >= config.atr_period:
        base_range_size = _atr_pnf(data, config.atr_period) * config.atr_multiplier
    else:
        base_range_size = config.range_size

    var min_range_size = price_range / 200.0
    var range_size = max(max(base_range_size, min_range_size), 0.0001)

    var cb_open = data[0].open
    var cb_high = data[0].high
    var cb_low = data[0].low
    var cb_close = data[0].close
    var cb_volume = data[0].volume
    var cb_start_time = data[0].time
    var cb_end_time = data[0].time
    var cb_tick_cnt = 1

    for bi in range(1, len(data)):
        if len(bars) >= RANGE_MAX_BARS:
            break

        # Process this bar's range as O,H,L,C in order.
        var prices = List[Float64]()
        prices.append(data[bi].open)
        prices.append(data[bi].high)
        prices.append(data[bi].low)
        prices.append(data[bi].close)

        for pi in range(len(prices)):
            if len(bars) >= RANGE_MAX_BARS:
                break
            var price = prices[pi]
            cb_high = max(cb_high, price)
            cb_low = min(cb_low, price)

            var iterations = 0
            while (cb_high - cb_low) >= range_size and iterations < RANGE_MAX_ITERATIONS:
                iterations += 1

                # Complete the bar (closed up if high broke first).
                if cb_high - cb_open >= range_size:
                    cb_close = cb_low + range_size
                    cb_high = cb_close
                else:
                    cb_close = cb_high - range_size
                    cb_low = cb_close

                cb_end_time = data[bi].time
                bars.append(RangeBar(cb_open, cb_high, cb_low, cb_close,
                                     cb_volume, cb_start_time, cb_end_time,
                                     range_size, cb_tick_cnt))

                if len(bars) >= RANGE_MAX_BARS:
                    return bars^

                # Start new bar from the prior close.
                var prev_close = cb_close
                cb_open = prev_close
                cb_high = max(price, prev_close)
                cb_low = min(price, prev_close)
                cb_close = price
                cb_volume = 0.0
                cb_start_time = data[bi].time
                cb_end_time = data[bi].time
                cb_tick_cnt = 0

        cb_close = data[bi].close
        cb_volume += data[bi].volume
        cb_end_time = data[bi].time
        cb_tick_cnt += 1

    # Add incomplete bar.
    if cb_tick_cnt > 0 and len(bars) < RANGE_MAX_BARS:
        bars.append(RangeBar(cb_open, cb_high, cb_low, cb_close, cb_volume,
                             cb_start_time, cb_end_time, range_size,
                             cb_tick_cnt))

    return bars^


# =============================================================================
# Heikin-Ashi — port of model/bar/bar_data.rs `to_heikin_ashi`
# =============================================================================
# (Also available as `BarData.to_heikin_ashi` in model.mojo; provided here as a
#  free function over a `List[Bar]` for the transforms API surface.)

fn to_heikin_ashi(bars: List[Bar]) -> List[Bar]:
    """Convert OHLC bars to Heikin-Ashi bars (faithful port of
    `BarData::to_heikin_ashi`).

        HA Close = (O + H + L + C) / 4
        HA Open  = (prev HA Open + prev HA Close) / 2
        HA High  = max(High, HA Open, HA Close)
        HA Low   = min(Low,  HA Open, HA Close)

    The first bar seeds HA Open = (open + close) / 2 and
    HA Close = (O + H + L + C) / 4.
    """
    var ha = List[Bar]()
    var n = len(bars)
    if n == 0:
        return ha^

    var prev_ha_open = (bars[0].open + bars[0].close) / 2.0
    var prev_ha_close = (bars[0].open + bars[0].high + bars[0].low
                         + bars[0].close) / 4.0
    ha.append(Bar(bars[0].time, prev_ha_open, bars[0].high, bars[0].low,
                  prev_ha_close, bars[0].volume))

    for i in range(1, n):
        var ha_close = (bars[i].open + bars[i].high + bars[i].low
                        + bars[i].close) / 4.0
        var ha_open = (prev_ha_open + prev_ha_close) / 2.0
        var ha_high = max(bars[i].high, max(ha_open, ha_close))
        var ha_low = min(bars[i].low, min(ha_open, ha_close))
        ha.append(Bar(bars[i].time, ha_open, ha_high, ha_low, ha_close,
                      bars[i].volume))
        prev_ha_open = ha_open
        prev_ha_close = ha_close

    return ha^
