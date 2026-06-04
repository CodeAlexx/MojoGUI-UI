"""
Chart scales — faithful port of egui-charts `src/scales/`.

Ported from:
  - /tmp/egui-charts-ref/src/scales/pricescale.rs        -> PriceScale (+ modes/margins)
  - /tmp/egui-charts-ref/src/scales/pricescale_marks.rs  -> PriceMarkGenerator, PriceMark
  - /tmp/egui-charts-ref/src/scales/timescale_marks.rs   -> TimeMarkGenerator, TimeMark
  - /tmp/egui-charts-ref/src/scales/price_formatter.rs   -> Default/Percentage/Currency/Volume/Scientific formatters
  - /tmp/egui-charts-ref/src/scales/time_formatter.rs    -> DefaultTimeFormatter

Conventions (see PORT_SPEC.md "VERIFIED CONVENTIONS", Mojo 0.26.2 nightly):
  - Prices are Float64 everywhere; we only convert to Int32 at the pixel boundary
    (`price_to_pixel_y` / `pixel_y_to_price`, `index_to_pixel_x` / `pixel_x_to_index`).
  - `__init__(out self, ...)`, mutating methods take `mut self`. `inout self` is a
    hard parse error under this nightly.
  - Rust enums are Int32 `comptime` constants (`PS_*`, `TMT_*`) plus thin wrappers,
    matching `model.mojo`.
  - Rust `Option<f64> first_val`/`Option<PriceRange> manual_range` become a value
    plus a `*_set` Bool flag (no cheap Optional idiom in the widget code).

The Rust time-mark generator leans on `chrono` for calendar math.  `Bar.time` here
is a Unix-epoch **millisecond** Int64 (see model.mojo), so this port decomposes the
timestamp into Y/M/D/h/m/s with a self-contained civil-date routine
(`_civil_from_days`) instead of pulling in a date library.  The interval-selection
ladder (`_calculate_optimal_interval`) and label hierarchy are ported verbatim.
"""

from math import floor, ceil
# log/log10/exp routed through the pure-Mojo mathx versions (no libm) so the
# FFI-linked chart demos LINK — math.log10 pulls `log10@GLIBC` which fails to
# resolve in chart_demo/chart_all_demo (same class as the sincos issue).
from .mathx import cln as log, clog10 as log10, cexp as exp
from .model import Bar, BarData, Timeframe


# =============================================================================
# PriceScaleMode — port of pricescale.rs  (enum PriceScaleMode)
# =============================================================================

comptime PS_NORMAL: Int32 = 0
"""Linear price scale (`PriceScaleMode::Normal`, the Rust default)."""
comptime PS_LOGARITHMIC: Int32 = 1
"""Logarithmic price scale (`PriceScaleMode::Logarithmic`)."""
comptime PS_PERCENTAGE: Int32 = 2
"""Percentage-change-from-first-value scale (`PriceScaleMode::Percentage`)."""
comptime PS_INDEXED_TO_100: Int32 = 3
"""Rebased-to-100 scale (`PriceScaleMode::IndexedTo100`)."""


fn price_scale_mode_name(mode: Int32) -> String:
    """Display name for a price-scale mode (port of `PriceScaleMode::Display`)."""
    if mode == PS_NORMAL:         return String("Normal")
    if mode == PS_LOGARITHMIC:    return String("Logarithmic")
    if mode == PS_PERCENTAGE:     return String("Percentage")
    if mode == PS_INDEXED_TO_100: return String("Indexed to 100")
    return String("Normal")


# Natural-log base used by the Rust log mode (`E.ln()`); ln(e) == 1.0.
comptime _LN_E: Float64 = 1.0


# =============================================================================
# PriceScale — port of pricescale.rs  (struct PriceScale)
# =============================================================================
# The Rust scale tracks a pixel `height` and maps the visible price range onto
# `[0, height]` with the Y axis inverted (top = 0).  We keep the identical math
# in `price_to_coord` / `coord_to_price` (coord is a 0..height offset) and add a
# pixel-boundary wrapper that folds in the viewport `top_y` and rounds to Int32.

struct PriceScale(ImplicitlyCopyable, Movable):
    """Price (Y) axis engine (port of `PriceScale` in pricescale.rs).

    Maps Float64 prices onto a vertical pixel viewport in one of four modes
    (`PS_NORMAL`/`PS_LOGARITHMIC`/`PS_PERCENTAGE`/`PS_INDEXED_TO_100`).  Auto-fits
    the price range to the visible data with top/bottom margins.
    """

    var mode: Int32
    """One of the `PS_*` constants (default `PS_NORMAL`)."""
    var auto_scale: Bool
    """Whether `auto_scale()` fits the range to data (default True)."""
    var invert_scale: Bool
    """Invert the axis: higher prices map to higher Y (default False)."""
    var margin_top: Float64
    """Top margin as a fraction of the data range (default 0.2)."""
    var margin_bottom: Float64
    """Bottom margin as a fraction of the data range (default 0.1)."""

    var range_min: Float64
    """Current price-range minimum (original price units)."""
    var range_max: Float64
    """Current price-range maximum (original price units)."""
    var height: Float64
    """Viewport height in pixels."""

    var first_val: Float64
    """First visible value for Percentage/IndexedTo100 modes."""
    var first_val_set: Bool
    """Whether `first_val` has been set (Rust `Option<f64>`)."""

    var manual_min: Float64
    """Manual range minimum (used when `auto_scale` is False)."""
    var manual_max: Float64
    """Manual range maximum (used when `auto_scale` is False)."""
    var manual_set: Bool
    """Whether a manual range override is active (Rust `Option<PriceRange>`)."""

    fn __init__(out self, height: Float64 = 100.0):
        """Creates a price scale with default options (port of `PriceScale::new`)."""
        self.mode = PS_NORMAL
        self.auto_scale = True
        self.invert_scale = False
        self.margin_top = 0.2
        self.margin_bottom = 0.1
        self.range_min = 0.0
        self.range_max = 100.0
        self.height = height
        self.first_val = 0.0
        self.first_val_set = False
        self.manual_min = 0.0
        self.manual_max = 0.0
        self.manual_set = False

    # ----- Mutators (pricescale.rs setters) --------------------------------

    fn set_height(mut self, height: Float64):
        """Set the pixel height (call on resize; port of `set_height`)."""
        self.height = height

    fn set_mode(mut self, mode: Int32):
        """Set the scaling mode (one of the `PS_*` constants)."""
        self.mode = mode

    fn set_first_val(mut self, value: Float64):
        """Set the first visible value (port of `set_first_val`)."""
        self.first_val = value
        self.first_val_set = True

    fn set_manual_range(mut self, min: Float64, max: Float64):
        """Set a manual price range, disabling auto-scale (port of `set_manual_range`)."""
        self.manual_min = min
        self.manual_max = max
        self.manual_set = True
        self.auto_scale = False

    fn reset_auto_scale(mut self):
        """Re-enable auto-scaling (port of `reset_auto_scale`)."""
        self.manual_set = False
        self.auto_scale = True

    fn auto_scale_to(mut self, data_min: Float64, data_max: Float64):
        """Auto-fit the range to `[data_min, data_max]` with margins.

        Port of `PriceScale::auto_scale`.  When auto-scale is off and a manual
        range is set, the manual range is used verbatim.
        """
        if not self.auto_scale:
            if self.manual_set:
                self.range_min = self.manual_min
                self.range_max = self.manual_max
                return

        var rng = _max_f64(data_max - data_min, 1e-12)
        var top_margin = rng * self.margin_top
        var bottom_margin = rng * self.margin_bottom
        self.range_min = data_min - bottom_margin
        self.range_max = data_max + top_margin

    fn auto_scale_from_bars(mut self, data: BarData):
        """Convenience: auto-fit to the visible bar low/high (uses model accessors).

        Mirrors the chart engine's typical call site: it feeds `BarData.min_price`
        / `max_price` into `auto_scale`.  No-op for empty data.
        """
        if data.is_empty():
            return
        var lo = data.min_price()
        var hi = data.max_price()
        # Seed the percentage/indexed baseline with the first close, matching the
        # Rust engine which sets `first_val` to the first visible value.
        if not self.first_val_set and len(data.bars) > 0:
            self.set_first_val(data.bars[0].close)
        self.auto_scale_to(lo, hi)

    # ----- Range accessors -------------------------------------------------

    fn range_length(self) -> Float64:
        """Range size (`max - min`) clamped to 1e-12 (port of `PriceRange::length`)."""
        return _max_f64(self.range_max - self.range_min, 1e-12)

    # ----- price <-> coord (0..height), the Rust core ----------------------

    fn price_to_coord(self, price: Float64) -> Float64:
        """Convert a price to a Y coord in `[0, height]` (port of `price_to_coord`).

        Returns a Float64 pixel offset measured from the top of the viewport.
        """
        var normalized = self._normalize_price(price)
        var ratio = self._price_to_ratio(normalized)

        var y: Float64
        if self.invert_scale:
            y = ratio * self.height
        else:
            y = (1.0 - ratio) * self.height
        return _clamp_f64(y, 0.0, self.height)

    fn coord_to_price(self, y: Float64) -> Float64:
        """Convert a Y coord in `[0, height]` back to a price (port of `coord_to_price`)."""
        # A zero-height scale has no inverse; treat every coord as the range bottom.
        if abs(self.height) < 1e-12:
            return self._denormalize_price(self._ratio_to_price(0.0))

        var ratio: Float64
        if self.invert_scale:
            ratio = y / self.height
        else:
            ratio = 1.0 - y / self.height
        var normalized = self._ratio_to_price(ratio)
        return self._denormalize_price(normalized)

    # ----- price <-> absolute pixel Y (the integer boundary) ---------------

    fn price_to_pixel_y(self, price: Float64, top_y: Int32) -> Int32:
        """Map a price to an absolute pixel Y, given the viewport top edge.

        This is the only place a price becomes an `Int32`; `top_y` is the pixel
        Y of the top of the price viewport.
        """
        var coord = self.price_to_coord(price)
        return top_y + Int32(_round_half(coord))

    fn pixel_y_to_price(self, pixel_y: Int32, top_y: Int32) -> Float64:
        """Inverse of `price_to_pixel_y`: absolute pixel Y back to a price."""
        var coord = Float64(Int(pixel_y) - Int(top_y))
        return self.coord_to_price(coord)

    # ----- Mode transformations (pricescale.rs internals) ------------------

    fn _normalize_price(self, price: Float64) -> Float64:
        """price -> normalized, per current mode (port of `normalize_price`)."""
        if self.mode == PS_NORMAL:
            return price
        if self.mode == PS_LOGARITHMIC:
            return self._price_to_log(price)
        if self.mode == PS_PERCENTAGE:
            if self.first_val_set:
                return self._price_to_percent(price, self.first_val)
            return price
        # PS_INDEXED_TO_100
        if self.first_val_set:
            return self._price_to_idxed(price, self.first_val)
        return price

    fn _denormalize_price(self, normalized: Float64) -> Float64:
        """normalized -> price, per current mode (port of `denormalize_price`)."""
        if self.mode == PS_NORMAL:
            return normalized
        if self.mode == PS_LOGARITHMIC:
            return self._log_to_price(normalized)
        if self.mode == PS_PERCENTAGE:
            if self.first_val_set:
                return self._percent_to_price(normalized, self.first_val)
            return normalized
        # PS_INDEXED_TO_100
        if self.first_val_set:
            return self._indexed_to_price(normalized, self.first_val)
        return normalized

    fn _price_to_ratio(self, normalized_price: Float64) -> Float64:
        """normalized price -> ratio in [0,1] (port of `price_to_ratio`)."""
        var normalized_range: Float64
        var normalized_min: Float64

        if self.mode == PS_NORMAL:
            normalized_range = self.range_length()
            normalized_min = self.range_min
        elif self.mode == PS_LOGARITHMIC:
            normalized_range = (self._price_to_log(self.range_max)
                                - self._price_to_log(self.range_min))
            normalized_min = self._price_to_log(self.range_min)
        elif self.mode == PS_PERCENTAGE:
            if self.first_val_set:
                normalized_range = (self._price_to_percent(self.range_max, self.first_val)
                                    - self._price_to_percent(self.range_min, self.first_val))
                normalized_min = self._price_to_percent(self.range_min, self.first_val)
            else:
                normalized_range = self.range_length()
                normalized_min = self.range_min
        else:  # PS_INDEXED_TO_100
            if self.first_val_set:
                normalized_range = (self._price_to_idxed(self.range_max, self.first_val)
                                    - self._price_to_idxed(self.range_min, self.first_val))
                normalized_min = self._price_to_idxed(self.range_min, self.first_val)
            else:
                normalized_range = self.range_length()
                normalized_min = self.range_min

        var denom = _max_f64(normalized_range, 1e-12)
        return _clamp_f64((normalized_price - normalized_min) / denom, 0.0, 1.0)

    fn _ratio_to_price(self, ratio: Float64) -> Float64:
        """ratio in [0,1] -> normalized price (port of `ratio_to_price`)."""
        var r = _clamp_f64(ratio, 0.0, 1.0)

        if self.mode == PS_NORMAL:
            return self.range_min + r * self.range_length()
        if self.mode == PS_LOGARITHMIC:
            var log_min = self._price_to_log(self.range_min)
            var log_max = self._price_to_log(self.range_max)
            return log_min + r * (log_max - log_min)
        if self.mode == PS_PERCENTAGE:
            if self.first_val_set:
                var pmin = self._price_to_percent(self.range_min, self.first_val)
                var pmax = self._price_to_percent(self.range_max, self.first_val)
                return pmin + r * (pmax - pmin)
            return self.range_min + r * self.range_length()
        # PS_INDEXED_TO_100
        if self.first_val_set:
            var imin = self._price_to_idxed(self.range_min, self.first_val)
            var imax = self._price_to_idxed(self.range_max, self.first_val)
            return imin + r * (imax - imin)
        return self.range_min + r * self.range_length()

    # ----- Mode-specific transforms (pricescale.rs) ------------------------

    fn _price_to_log(self, price: Float64) -> Float64:
        """price -> log(price) (port of `price_to_log`; non-positive -> 0)."""
        if price <= 0.0:
            return 0.0
        return log(price) / _LN_E

    fn _log_to_price(self, log_price: Float64) -> Float64:
        """log(price) -> price (port of `log_to_price`)."""
        return exp(log_price)

    fn _price_to_percent(self, price: Float64, first_val: Float64) -> Float64:
        """price -> % change from first value (port of `price_to_percent`)."""
        if first_val == 0.0:
            return 0.0
        return ((price - first_val) / abs(first_val)) * 100.0

    fn _percent_to_price(self, percent: Float64, first_val: Float64) -> Float64:
        """% -> price (port of `percent_to_price`)."""
        return first_val + (first_val * percent / 100.0)

    fn _price_to_idxed(self, price: Float64, first_val: Float64) -> Float64:
        """price -> indexed-to-100 (port of `price_to_idxed`)."""
        if first_val == 0.0:
            return 100.0
        return (price / first_val) * 100.0

    fn _indexed_to_price(self, indexed: Float64, first_val: Float64) -> Float64:
        """indexed -> price (port of `indexed_to_price`)."""
        return (indexed / 100.0) * first_val


# =============================================================================
# TimeScale — bar index / timestamp <-> pixel X
# =============================================================================
# egui-charts handles the X axis in its pan/zoom + coords modules (chart/coords);
# the scale modules only generate marks.  This is the X-axis companion to
# PriceScale: a linear bar-index axis with a `bar_spacing` (pixels per bar) and a
# pixel `offset` (pan).  Timestamps are mapped through the dataset's first bar
# time and the timeframe duration, mirroring the engine's index<->time logic.

struct TimeScale(ImplicitlyCopyable, Movable):
    """Time (X) axis engine — maps bar index / timestamp to pixel X.

    A bar at integer index `i` is centered at `offset + (i + 0.5) * bar_spacing`
    pixels from the viewport left edge.  `bar_spacing` is the per-bar pixel width
    (zoom); panning shifts `offset`.  Timestamp mapping uses `first_time` (epoch
    ms of bar 0) and `ms_per_bar` (the timeframe duration).
    """

    var bar_spacing: Float64
    """Pixels per bar (zoom level); must stay positive."""
    var offset: Float64
    """Horizontal pan offset in pixels (left edge of bar 0's slot)."""
    var first_time: Int64
    """Epoch-ms timestamp of bar index 0 (for timestamp mapping)."""
    var ms_per_bar: Int64
    """Milliseconds per bar (timeframe duration); 0 if unknown."""

    fn __init__(out self, bar_spacing: Float64 = 8.0):
        """Creates a time scale with the given per-bar pixel width."""
        self.bar_spacing = _max_f64(bar_spacing, 1e-6)
        self.offset = 0.0
        self.first_time = 0
        self.ms_per_bar = 0

    fn set_bar_spacing(mut self, spacing: Float64):
        """Set the per-bar pixel width (zoom), clamped positive."""
        self.bar_spacing = _max_f64(spacing, 1e-6)

    fn set_offset(mut self, offset: Float64):
        """Set the horizontal pan offset in pixels."""
        self.offset = offset

    fn pan_by(mut self, delta_px: Float64):
        """Pan the axis horizontally by `delta_px` pixels."""
        self.offset += delta_px

    fn zoom_by(mut self, factor: Float64):
        """Multiply the per-bar width by `factor` (clamped positive)."""
        self.bar_spacing = _max_f64(self.bar_spacing * factor, 1e-6)

    fn configure_time(mut self, first_time: Int64, tf: Timeframe):
        """Bind timestamp mapping to a dataset's first bar time and timeframe."""
        self.first_time = first_time
        self.ms_per_bar = tf.duration_ms()

    # ----- index <-> pixel X (Float core) ----------------------------------

    fn index_to_coord(self, index: Float64) -> Float64:
        """Bar index (fractional ok) -> pixel X offset from the viewport left."""
        return self.offset + (index + 0.5) * self.bar_spacing

    fn coord_to_index(self, x: Float64) -> Float64:
        """Pixel X offset -> fractional bar index (inverse of `index_to_coord`)."""
        return (x - self.offset) / self.bar_spacing - 0.5

    # ----- index <-> absolute pixel X (the integer boundary) ---------------

    fn index_to_pixel_x(self, index: Int32, left_x: Int32) -> Int32:
        """Map a bar index to an absolute pixel X (center of the bar slot)."""
        var coord = self.index_to_coord(Float64(Int(index)))
        return left_x + Int32(_round_half(coord))

    fn pixel_x_to_index(self, pixel_x: Int32, left_x: Int32) -> Int32:
        """Inverse: absolute pixel X back to the nearest bar index."""
        var coord = Float64(Int(pixel_x) - Int(left_x))
        return Int32(_round_half(self.coord_to_index(coord)))

    # ----- timestamp <-> index ---------------------------------------------

    fn time_to_index(self, time_ms: Int64) -> Float64:
        """Epoch-ms timestamp -> fractional bar index via `first_time`/`ms_per_bar`."""
        if self.ms_per_bar == 0:
            return 0.0
        return Float64(Int(time_ms) - Int(self.first_time)) / Float64(Int(self.ms_per_bar))

    fn index_to_time(self, index: Float64) -> Int64:
        """Fractional bar index -> epoch-ms timestamp (inverse of `time_to_index`)."""
        return self.first_time + Int64(_round_half(index * Float64(Int(self.ms_per_bar))))

    fn time_to_pixel_x(self, time_ms: Int64, left_x: Int32) -> Int32:
        """Epoch-ms timestamp -> absolute pixel X."""
        var coord = self.index_to_coord(self.time_to_index(time_ms))
        return left_x + Int32(_round_half(coord))


# =============================================================================
# PriceMark / PriceMarkGenerator — port of pricescale_marks.rs
# =============================================================================

struct PriceMark(ImplicitlyCopyable, Movable):
    """A single Y-axis price tick (port of `PriceMark`)."""

    var price: Float64
    """The price value of this mark."""
    var label: String
    """Formatted label text."""
    var y_coord: Float64
    """Y coord in pixels (within the supplied rect)."""
    var weight: Int32
    """Render weight (higher = rounder number, kept first when crowded)."""

    fn __init__(out self, price: Float64, label: String, y_coord: Float64, weight: Int32):
        self.price = price
        self.label = label
        self.y_coord = y_coord
        self.weight = weight


struct PriceMarkGenerator(ImplicitlyCopyable, Movable):
    """Smart price-axis tick generator (port of `PriceMarkGenerator`).

    Uses the Heckbert "nice numbers" algorithm to place ticks at round price
    intervals, for both linear and logarithmic scales.
    """

    var min_spacing: Float64
    """Minimum pixel spacing between marks (default 30)."""
    var max_marks: Int
    """Maximum number of marks (default 20)."""
    var target_density: Float64
    """Target marks per 100 pixels (default 3.0)."""
    var min_price_step: Float64
    """Minimum price step; 0 means unset (Rust `Option<f64>`)."""
    var min_price_step_set: Bool
    """Whether `min_price_step` is active."""

    fn __init__(out self):
        """Default config (port of `PriceMarkGeneratorConfig::default`)."""
        self.min_spacing = 30.0
        self.max_marks = 20
        self.target_density = 3.0
        self.min_price_step = 0.0
        self.min_price_step_set = False

    fn generate_marks(self, min_price: Float64, max_price: Float64,
                      height_pixels: Float64, scale_mode: Int32,
                      rect_min_y: Float64, rect_max_y: Float64) -> List[PriceMark]:
        """Generate price marks for a range and display height (port of `generate_marks`)."""
        if min_price >= max_price or height_pixels <= 0.0:
            return List[PriceMark]()

        if scale_mode == PS_LOGARITHMIC:
            return self._generate_log_marks(min_price, max_price, height_pixels,
                                            rect_min_y, rect_max_y)
        # Normal / Percentage / IndexedTo100 all use linear spacing here; the
        # formatter handles the percentage/indexed label transformation.
        return self._generate_linear_marks(min_price, max_price, height_pixels,
                                            rect_min_y, rect_max_y)

    fn _generate_linear_marks(self, min_price: Float64, max_price: Float64,
                              height_pixels: Float64, rect_min_y: Float64,
                              rect_max_y: Float64) -> List[PriceMark]:
        """Marks for a linear scale (port of `generate_linear_marks`)."""
        # NaN guard (skeptic #11): a NaN bound poisons every comparison below
        # (NaN is its own only non-equal value), so bail to empty marks.
        if min_price != min_price or max_price != max_price:
            return List[PriceMark]()
        var price_range = max_price - min_price
        # Guard zero/tiny range (Rust: f64::EPSILON * 1000.0).
        if price_range != price_range or price_range <= 2.220446049250313e-13:
            return List[PriceMark]()

        var target_marks = _min_f64(
            _max_f64(height_pixels / 100.0 * self.target_density, 3.0),
            Float64(self.max_marks))

        var raw_step = price_range / target_marks
        var nice_step = self._calculate_nice_step(raw_step)
        if nice_step <= 0.0:
            return List[PriceMark]()

        var start_price = floor(min_price / nice_step) * nice_step

        var marks = List[PriceMark]()
        var curr_price = start_price
        var max_iterations = self.max_marks * 10
        var iterations = 0

        while curr_price <= max_price and iterations < max_iterations:
            if curr_price >= min_price:
                var ratio = (curr_price - min_price) / price_range
                var y = rect_max_y - (ratio * (rect_max_y - rect_min_y))
                var precision = self._calculate_precision(curr_price, nice_step)
                var label = self._format_price(curr_price, precision)
                var weight = self._calculate_weight(curr_price, nice_step)
                marks.append(PriceMark(curr_price, label, y, weight))
            curr_price += nice_step
            iterations += 1

        return self._apply_spacing_constraints(marks^, height_pixels)

    fn _generate_log_marks(self, min_price: Float64, max_price: Float64,
                           height_pixels: Float64, rect_min_y: Float64,
                           rect_max_y: Float64) -> List[PriceMark]:
        """Marks for a logarithmic scale (port of `generate_log_marks`)."""
        # NaN guard (skeptic #11): NaN bounds make the <=/>= checks unreliable.
        if min_price != min_price or max_price != max_price:
            return List[PriceMark]()
        if (min_price <= 0.0 or max_price <= 0.0 or min_price >= max_price):
            return List[PriceMark]()

        var log_min = log(min_price)
        var log_max = log(max_price)
        var log_range = log_max - log_min
        if log_range <= 2.220446049250313e-16:
            return List[PriceMark]()

        var min_order = Int(floor(log10(min_price)))
        var max_order = Int(ceil(log10(max_price)))

        var marks = List[PriceMark]()
        var multipliers = List[Float64]()
        multipliers.append(1.0)
        multipliers.append(2.0)
        multipliers.append(5.0)

        for order in range(min_order, max_order + 1):
            var base = _powi10(order)
            for mi in range(len(multipliers)):
                var multiplier = multipliers[mi]
                var price = base * multiplier
                if price >= min_price and price <= max_price:
                    var log_price = log(price)
                    var ratio = (log_price - log_min) / log_range
                    var y = rect_max_y - (ratio * (rect_max_y - rect_min_y))
                    var precision = self._calculate_precision(price, base)
                    var label = self._format_price(price, precision)
                    var weight: Int32 = 60
                    if multiplier == 1.0:
                        weight = 100
                    elif multiplier == 5.0:
                        weight = 80
                    marks.append(PriceMark(price, label, y, weight))

        return self._apply_spacing_constraints(marks^, height_pixels)

    fn _calculate_nice_step(self, raw_step: Float64) -> Float64:
        """Heckbert "nice" step (port of `calculate_nice_step`)."""
        if raw_step <= 0.0:
            return 1.0
        if self.min_price_step_set and raw_step < self.min_price_step:
            return self.min_price_step

        var exponent = floor(log10(raw_step))
        var fraction = raw_step / _powf10(exponent)

        var nice_fraction: Float64
        if fraction <= 1.0:
            nice_fraction = 1.0
        elif fraction <= 2.0:
            nice_fraction = 2.0
        elif fraction <= 5.0:
            nice_fraction = 5.0
        else:
            nice_fraction = 10.0
        return nice_fraction * _powf10(exponent)

    fn _calculate_precision(self, price: Float64, step: Float64) -> Int:
        """Decimal precision for a price/step (port of `calculate_precision`)."""
        if price == 0.0:
            return 2
        if step <= 0.0001:
            return 8
        if step <= 0.001:
            return 6
        if step <= 0.01:
            return 4
        if step <= 0.1:
            return 3
        if step <= 1.0:
            return 2
        if step <= 10.0:
            return 1
        return 0

    fn _format_price(self, price: Float64, precision: Int) -> String:
        """Fixed-precision price label (port of `format_price`)."""
        return format_fixed(price, precision)

    fn _calculate_weight(self, price: Float64, step: Float64) -> Int32:
        """Weight a mark by roundness (port of `calculate_weight`)."""
        var step_10 = step * 10.0
        var step_5 = step * 5.0
        var step_2 = step * 2.0
        var tolerance = step * 0.01
        if abs(_fmod(price, step_10)) < tolerance:
            return 100
        if abs(_fmod(price, step_5)) < tolerance:
            return 80
        if abs(_fmod(price, step_2)) < tolerance:
            return 60
        return 40

    fn _apply_spacing_constraints(self, var marks: List[PriceMark],
                                  height_pixels: Float64) -> List[PriceMark]:
        """Drop crowded low-weight marks (port of `apply_spacing_constraints`)."""
        if len(marks) == 0:
            return marks^

        var pixels_per_mark = height_pixels / Float64(len(marks))

        if pixels_per_mark < self.min_spacing:
            # Sort by weight desc, then price asc.
            _sort_price_marks_weight_desc(marks)

            var filtered = List[PriceMark]()
            filtered.append(marks[0])
            for i in range(1, len(marks)):
                var ok = True
                for j in range(len(filtered)):
                    if abs(filtered[j].y_coord - marks[i].y_coord) < self.min_spacing:
                        ok = False
                        break
                if ok:
                    filtered.append(marks[i])
            _sort_price_marks_price_asc(filtered)
            marks = filtered^

        if len(marks) > self.max_marks:
            _sort_price_marks_weight_desc(marks)
            var truncated = List[PriceMark]()
            for i in range(self.max_marks):
                truncated.append(marks[i])
            _sort_price_marks_price_asc(truncated)
            marks = truncated^

        return marks^


# =============================================================================
# TimeMark / TimeMarkGenerator — port of timescale_marks.rs
# =============================================================================
# Tick-mark types (timescale_marks.rs `enum TickMarkType`).

comptime TMT_YEAR: Int32 = 0
comptime TMT_MONTH: Int32 = 1
comptime TMT_DAY_OF_MONTH: Int32 = 2
comptime TMT_TIME: Int32 = 3
comptime TMT_TIME_WITH_SECONDS: Int32 = 4

# Tick-mark weights (timescale_marks.rs `TickMarkWeight` constants).
comptime TMW_YEAR: Int32 = 100
comptime TMW_MONTH: Int32 = 80
comptime TMW_WEEK: Int32 = 70
comptime TMW_DAY: Int32 = 60
comptime TMW_HOUR_4: Int32 = 50
comptime TMW_HOUR: Int32 = 40
comptime TMW_MIN_30: Int32 = 35
comptime TMW_MIN_15: Int32 = 30
comptime TMW_MIN_5: Int32 = 25
comptime TMW_MINUTE: Int32 = 20
comptime TMW_SEC_10: Int32 = 15
comptime TMW_SECOND: Int32 = 10
comptime TMW_SUBSECOND: Int32 = 5


struct TimeMark(ImplicitlyCopyable, Movable):
    """A single X-axis time tick (port of `TickMark`)."""

    var time_ms: Int64
    """Epoch-ms timestamp of this mark."""
    var mark_type: Int32
    """One of the `TMT_*` constants."""
    var weight: Int32
    """One of the `TMW_*` constants (importance)."""
    var label: String
    """Formatted label text."""
    var index: Int
    """Index of the closest bar in the data series."""

    fn __init__(out self, time_ms: Int64, mark_type: Int32, weight: Int32,
                label: String, index: Int):
        self.time_ms = time_ms
        self.mark_type = mark_type
        self.weight = weight
        self.label = label
        self.index = index


struct TimeMarkGenerator(ImplicitlyCopyable, Movable):
    """Smart time-axis tick generator (port of `TickMarkGenerator`).

    Places labels at hierarchical calendar boundaries (year > month > week > day
    > hour > minute > second) and drops low-weight marks first when crowded.
    The Rust generator uses `chrono`; here calendar fields come from
    `_civil_from_days` on an epoch-ms Int64.
    """

    var min_spacing: Float64
    """Minimum pixel spacing between marks (default 50)."""
    var max_marks: Int
    """Maximum number of marks (default 50)."""
    var show_subseconds: Bool
    """Whether to show seconds in `TimeWithSeconds` labels (default True)."""
    var use_24_hour: Bool
    """24-hour vs 12-hour clock (default True)."""
    var target_density: Float64
    """Target marks per 100 pixels (default 2.0)."""

    fn __init__(out self):
        """Default config (port of `TickMarkGeneratorConfig::default`)."""
        self.min_spacing = 50.0
        self.max_marks = 50
        self.show_subseconds = True
        self.use_24_hour = True
        self.target_density = 2.0

    fn generate_marks(self, start_time_ms: Int64, end_time_ms: Int64,
                      width_pixels: Float64,
                      bar_times: List[Int64]) -> List[TimeMark]:
        """Generate time marks for a range and width (port of `generate_marks`).

        `bar_times` are the epoch-ms timestamps of the visible bars (index i is
        bar i); each mark's `index` is set to the closest bar.
        """
        if len(bar_times) == 0 or width_pixels <= 0.0:
            return List[TimeMark]()

        var time_span_ms = end_time_ms - start_time_ms
        var interval_ms = self._calculate_optimal_interval(time_span_ms, width_pixels)

        var mtw = self._determine_mark_type_and_weight(interval_ms)
        var primary_type = mtw[0]
        var weight_threshold = mtw[1]

        var marks = self._generate_candidate_marks(start_time_ms, end_time_ms,
                                                   interval_ms, primary_type)

        # Filter by weight threshold.
        var kept = List[TimeMark]()
        for i in range(len(marks)):
            if marks[i].weight >= weight_threshold:
                kept.append(marks[i])

        kept = self._map_marks_to_bars(kept^, bar_times)
        kept = self._apply_spacing_constraints(kept^, width_pixels)

        if len(kept) > self.max_marks:
            kept = self._reduce_marks_cnt(kept^, self.max_marks)
        return kept^

    fn _calculate_optimal_interval(self, time_span_ms: Int64,
                                   width_pixels: Float64) -> Int64:
        """Snap to a nice interval (port of `calculate_optimal_interval`)."""
        var target_marks = _max_f64(width_pixels / 100.0 * self.target_density, 2.0)
        var seconds_per_mark = (Float64(Int(time_span_ms)) / 1000.0) / target_marks

        var seconds: Float64
        if seconds_per_mark < 1.0:
            if seconds_per_mark < 0.25:
                seconds = 0.1
            elif seconds_per_mark < 0.5:
                seconds = 0.25
            else:
                seconds = 0.5
        elif seconds_per_mark < 60.0:
            if seconds_per_mark < 2.0:
                seconds = 1.0
            elif seconds_per_mark < 5.0:
                seconds = 2.0
            elif seconds_per_mark < 10.0:
                seconds = 5.0
            elif seconds_per_mark < 15.0:
                seconds = 10.0
            elif seconds_per_mark < 30.0:
                seconds = 15.0
            else:
                seconds = 30.0
        elif seconds_per_mark < 3600.0:
            var minutes = seconds_per_mark / 60.0
            if minutes < 2.0:
                seconds = 60.0
            elif minutes < 5.0:
                seconds = 120.0
            elif minutes < 10.0:
                seconds = 300.0
            elif minutes < 15.0:
                seconds = 600.0
            elif minutes < 30.0:
                seconds = 900.0
            else:
                seconds = 1800.0
        elif seconds_per_mark < 86400.0:
            var hours = seconds_per_mark / 3600.0
            if hours < 2.0:
                seconds = 3600.0
            elif hours < 4.0:
                seconds = 7200.0
            elif hours < 6.0:
                seconds = 14400.0
            elif hours < 12.0:
                seconds = 21600.0
            else:
                seconds = 43200.0
        elif seconds_per_mark < 2592000.0:
            var days = seconds_per_mark / 86400.0
            if days < 2.0:
                seconds = 86400.0
            elif days < 7.0:
                seconds = 172800.0
            else:
                seconds = 604800.0
        else:
            var days = seconds_per_mark / 86400.0
            if days < 90.0:
                seconds = 2592000.0
            elif days < 180.0:
                seconds = 7776000.0
            elif days < 365.0:
                seconds = 15552000.0
            else:
                seconds = 31536000.0

        return Int64(seconds * 1000.0)

    fn _determine_mark_type_and_weight(self, interval_ms: Int64) -> Tuple[Int32, Int32]:
        """Mark type + min weight threshold (port of `determine_mark_type_and_weight`)."""
        var seconds = Int(interval_ms) // 1000
        if seconds < 1:
            return (TMT_TIME_WITH_SECONDS, TMW_SUBSECOND)
        if seconds < 60:
            return (TMT_TIME_WITH_SECONDS, TMW_SECOND)
        if seconds < 3600:
            return (TMT_TIME, TMW_MINUTE)
        if seconds < 86400:
            return (TMT_TIME, TMW_HOUR)
        if seconds < 2592000:
            return (TMT_DAY_OF_MONTH, TMW_DAY)
        if seconds < 31536000:
            return (TMT_MONTH, TMW_MONTH)
        return (TMT_YEAR, TMW_YEAR)

    fn _generate_candidate_marks(self, start_time_ms: Int64, end_time_ms: Int64,
                                 interval_ms: Int64,
                                 primary_type: Int32) -> List[TimeMark]:
        """Candidate marks at boundaries (port of `generate_candidate_marks`)."""
        var marks = List[TimeMark]()
        if interval_ms <= 0:
            return marks^
        var current = self._round_time_to_boundary(start_time_ms, interval_ms)
        while current <= end_time_ms:
            var cw = self._classify_time_boundary(current, primary_type)
            var mark_type = cw[0]
            var weight = cw[1]
            var label = self._format_time_label(current, mark_type)
            marks.append(TimeMark(current, mark_type, weight, label, 0))
            current += interval_ms
        return marks^

    fn _round_time_to_boundary(self, time_ms: Int64, interval_ms: Int64) -> Int64:
        """Round down to the interval's natural boundary (port of `round_time_to_boundary`)."""
        var seconds = Int(interval_ms) // 1000
        if seconds < 1:
            # Sub-second: round to the millisecond interval.
            if interval_ms == 0:
                return time_ms
            return (time_ms // interval_ms) * interval_ms

        var c = _civil_from_ms(time_ms)
        if seconds < 60:
            # Round down to the whole second.
            return _ms_from_civil(c.year, c.month, c.day, c.hour, c.minute, c.second)
        if seconds < 3600:
            return _ms_from_civil(c.year, c.month, c.day, c.hour, c.minute, 0)
        if seconds < 86400:
            return _ms_from_civil(c.year, c.month, c.day, c.hour, 0, 0)
        # Days or more: round down to the day.
        return _ms_from_civil(c.year, c.month, c.day, 0, 0, 0)

    fn _classify_time_boundary(self, time_ms: Int64,
                               primary_type: Int32) -> Tuple[Int32, Int32]:
        """Classify a boundary + weight (port of `classify_time_boundary`)."""
        var c = _civil_from_ms(time_ms)

        # Year boundary.
        if (c.month == 1 and c.day == 1 and c.hour == 0
                and c.minute == 0 and c.second == 0):
            return (TMT_YEAR, TMW_YEAR)
        # Month boundary.
        if c.day == 1 and c.hour == 0 and c.minute == 0 and c.second == 0:
            return (TMT_MONTH, TMW_MONTH)
        # Week boundary (Monday). weekday: 0 = Monday.
        if (_weekday_from_ms(time_ms) == 0 and c.hour == 0
                and c.minute == 0 and c.second == 0):
            return (TMT_DAY_OF_MONTH, TMW_WEEK)
        # Day boundary.
        if c.hour == 0 and c.minute == 0 and c.second == 0:
            return (TMT_DAY_OF_MONTH, TMW_DAY)

        # If primary type is day-level or higher, do not downgrade to time-of-day.
        var is_day_or_higher = (primary_type == TMT_YEAR
                                or primary_type == TMT_MONTH
                                or primary_type == TMT_DAY_OF_MONTH)
        if is_day_or_higher:
            return (TMT_DAY_OF_MONTH, TMW_DAY)

        # Time-level primary types (intraday data) below here.
        if c.hour % 4 == 0 and c.minute == 0 and c.second == 0:
            return (TMT_TIME, TMW_HOUR_4)
        if c.minute == 0 and c.second == 0:
            return (TMT_TIME, TMW_HOUR)
        if c.minute % 30 == 0 and c.second == 0:
            return (TMT_TIME, TMW_MIN_30)
        if c.minute % 15 == 0 and c.second == 0:
            return (TMT_TIME, TMW_MIN_15)
        if c.minute % 5 == 0 and c.second == 0:
            return (TMT_TIME, TMW_MIN_5)
        if c.second == 0:
            return (TMT_TIME, TMW_MINUTE)
        if c.second % 10 == 0:
            return (TMT_TIME_WITH_SECONDS, TMW_SEC_10)
        return (primary_type, TMW_SECOND)

    fn _format_time_label(self, time_ms: Int64, mark_type: Int32) -> String:
        """Format a label for a mark type (port of `DefaultTimeFormatter::format`)."""
        return format_time(time_ms, mark_type, self.use_24_hour, self.show_subseconds)

    fn _map_marks_to_bars(self, var marks: List[TimeMark],
                          bar_times: List[Int64]) -> List[TimeMark]:
        """Set each mark's `index` to the closest bar (port of `map_marks_to_bars`)."""
        for i in range(len(marks)):
            var best_index = 0
            var best_diff = _abs_i64(bar_times[0] - marks[i].time_ms)
            for b in range(1, len(bar_times)):
                var diff = _abs_i64(bar_times[b] - marks[i].time_ms)
                if diff < best_diff:
                    best_diff = diff
                    best_index = b
            marks[i].index = best_index
        return marks^

    fn _apply_spacing_constraints(self, var marks: List[TimeMark],
                                  width_pixels: Float64) -> List[TimeMark]:
        """Drop crowded low-weight marks (port of `apply_spacing_constraints`)."""
        if len(marks) == 0:
            return marks^

        var pixels_per_mark = width_pixels / Float64(len(marks))
        if pixels_per_mark < self.min_spacing:
            # Compute min time difference BEFORE sorting (Rust formula).
            var min_time = marks[0].time_ms
            var max_time = marks[0].time_ms
            for i in range(1, len(marks)):
                if marks[i].time_ms < min_time:
                    min_time = marks[i].time_ms
                if marks[i].time_ms > max_time:
                    max_time = marks[i].time_ms
            var time_span = Float64(Int(max_time) - Int(min_time)) / 1000.0
            var min_time_diff_ms = Int64(
                (self.min_spacing * (time_span / width_pixels)) ) * 1000

            _sort_time_marks_weight_desc(marks)

            var filtered = List[TimeMark]()
            filtered.append(marks[0])
            for i in range(1, len(marks)):
                var ok = True
                for j in range(len(filtered)):
                    if _abs_i64(filtered[j].time_ms - marks[i].time_ms) < min_time_diff_ms:
                        ok = False
                        break
                if ok:
                    filtered.append(marks[i])
            _sort_time_marks_time_asc(filtered)
            marks = filtered^
        return marks^

    fn _reduce_marks_cnt(self, var marks: List[TimeMark],
                         max_marks: Int) -> List[TimeMark]:
        """Keep the highest-weight marks (port of `reduce_marks_cnt`)."""
        if len(marks) <= max_marks:
            return marks^
        _sort_time_marks_weight_desc(marks)
        var truncated = List[TimeMark]()
        for i in range(max_marks):
            truncated.append(marks[i])
        _sort_time_marks_time_asc(truncated)
        return truncated^


# =============================================================================
# Price formatters — port of price_formatter.rs
# =============================================================================

fn format_default_price(price: Float64, precision: Int = 2,
                        min_precision: Int = 0) -> String:
    """Default price formatter (port of `DefaultPriceFormatter::format`).

    With `min_precision == 0` (auto), trailing zeros and a trailing point are
    trimmed; otherwise the value is rendered at fixed precision.
    """
    if min_precision > 0:
        return format_fixed(price, precision)
    var formatted = format_fixed(price, precision)
    return _trim_trailing_zeros(formatted)


fn format_percentage(price: Float64, precision: Int = 2,
                     base_val: Float64 = 100.0) -> String:
    """Percentage price formatter (port of `PercentageFormatter::format`).

    `((price / base) * 100) - 100`, signed, with a `%` suffix.  A zero base
    yields a neutral `+0.00%`.
    """
    if abs(base_val) < 2.220446049250313e-16:
        return _signed_fixed(0.0, precision) + "%"
    var percentage = ((price / base_val) * 100.0) - 100.0
    return _signed_fixed(percentage, precision) + "%"


fn format_currency(price: Float64, symbol: String, precision: Int,
                   symbol_before: Bool, add_space: Bool,
                   thousands_sep: String) -> String:
    """Currency formatter (port of `CurrencyFormatter::format`).

    Pass an empty `thousands_sep` to skip grouping.
    """
    var val_str: String
    if len(thousands_sep) > 0:
        val_str = _format_with_separator(price, precision, thousands_sep)
    else:
        val_str = format_fixed(price, precision)
    var space = String(" ") if add_space else String("")
    if symbol_before:
        return symbol + space + val_str
    return val_str + space + symbol


fn format_currency_usd(price: Float64) -> String:
    """USD currency label (port of `CurrencyFormatter::usd`)."""
    return format_currency(price, String("$"), 2, True, False, String(","))


fn format_currency_eur(price: Float64) -> String:
    """EUR currency label (port of `CurrencyFormatter::eur`)."""
    return format_currency(price, String("€"), 2, False, True, String("."))


fn format_currency_btc(price: Float64) -> String:
    """BTC currency label (port of `CurrencyFormatter::btc`)."""
    return format_currency(price, String("₿"), 8, False, True, String(","))


fn format_volume(value: Float64, precision: Int = 2) -> String:
    """Volume formatter with K/M/B suffixes (port of `VolumeFormatter::format`)."""
    var abs_val = abs(value)
    if abs_val >= 1_000_000_000.0:
        return format_fixed(value / 1_000_000_000.0, precision) + "B"
    if abs_val >= 1_000_000.0:
        return format_fixed(value / 1_000_000.0, precision) + "M"
    if abs_val >= 1_000.0:
        return format_fixed(value / 1_000.0, precision) + "K"
    return format_fixed(value, precision)


# =============================================================================
# Time formatter — port of time_formatter.rs (DefaultTimeFormatter)
# =============================================================================

fn format_time(time_ms: Int64, mark_type: Int32, use_24_hour: Bool = True,
               show_seconds: Bool = True) -> String:
    """Format a timestamp by mark type (port of `DefaultTimeFormatter::format`).

    Year -> "2024", Month -> "Jun", DayOfMonth -> "Jun 15", Time -> "14:30" /
    "02:30 PM", TimeWithSeconds -> "14:30:45" / "02:30:45 PM".
    """
    var c = _civil_from_ms(time_ms)

    if mark_type == TMT_YEAR:
        return String(c.year)
    if mark_type == TMT_MONTH:
        return _MONTH_ABBR(c.month)
    if mark_type == TMT_DAY_OF_MONTH:
        return _MONTH_ABBR(c.month) + " " + _pad2(c.day)
    if mark_type == TMT_TIME:
        if use_24_hour:
            return _pad2(c.hour) + ":" + _pad2(c.minute)
        return _hour12(c.hour) + ":" + _pad2(c.minute) + " " + _ampm(c.hour)
    # TMT_TIME_WITH_SECONDS
    if not show_seconds:
        return format_time(time_ms, TMT_TIME, use_24_hour, show_seconds)
    if use_24_hour:
        return _pad2(c.hour) + ":" + _pad2(c.minute) + ":" + _pad2(c.second)
    return (_hour12(c.hour) + ":" + _pad2(c.minute) + ":" + _pad2(c.second)
            + " " + _ampm(c.hour))


# =============================================================================
# Numeric helpers (no Rust analog — Mojo std gaps)
# =============================================================================

fn _max_f64(a: Float64, b: Float64) -> Float64:
    return a if a > b else b


fn _min_f64(a: Float64, b: Float64) -> Float64:
    return a if a < b else b


fn _clamp_f64(v: Float64, lo: Float64, hi: Float64) -> Float64:
    if v < lo:
        return lo
    if v > hi:
        return hi
    return v


fn _round_half(x: Float64) -> Float64:
    """Round-half-away-from-zero (matches Mojo `round`)."""
    return round(x)


fn _abs_i64(x: Int64) -> Int64:
    return -x if x < 0 else x


fn _fmod(a: Float64, b: Float64) -> Float64:
    """Floating remainder `a - floor(a/b)*b` (Rust's `%` semantics for the
    positive moduli used here)."""
    if b == 0.0:
        return 0.0
    return a - floor(a / b) * b


fn _powi10(n: Int) -> Float64:
    """10**n for an integer exponent (handles negatives)."""
    var result: Float64 = 1.0
    if n >= 0:
        for _ in range(n):
            result *= 10.0
    else:
        for _ in range(-n):
            result /= 10.0
    return result


fn _powf10(exponent: Float64) -> Float64:
    """10**exponent for a (whole) Float64 exponent via `_powi10`."""
    return _powi10(Int(exponent))


fn format_fixed(value: Float64, precision: Int) -> String:
    """Format `value` with exactly `precision` decimals (Rust `{:.prec$}`).

    Rounds half-away-from-zero like Rust's formatter and always emits the full
    fractional width (e.g. `format_fixed(123.0, 2) == "123.00"`).
    """
    var neg = value < 0.0
    var v = -value if neg else value

    # Scale, round, then split into integer / fractional digits.
    var scale = _powi10(precision)
    var scaled = round(v * scale)
    var scaled_i = Int(scaled)

    var sign = String("-") if (neg and scaled_i != 0) else String("")

    if precision <= 0:
        return sign + String(scaled_i)

    var divisor = Int(scale)
    var int_part = scaled_i // divisor
    var frac_part = scaled_i % divisor

    # Left-pad the fractional digits to `precision` width.
    var frac_str = String(frac_part)
    var pad = precision - len(frac_str)
    var zeros = String("")
    for _ in range(pad):
        zeros += "0"
    return sign + String(int_part) + "." + zeros + frac_str


fn _signed_fixed(value: Float64, precision: Int) -> String:
    """`format_fixed` with an explicit leading `+` for non-negatives (Rust `{:+}`)."""
    if value < 0.0:
        return format_fixed(value, precision)
    return "+" + format_fixed(value, precision)


fn _trim_trailing_zeros(s: String) -> String:
    """Trim trailing zeros and a dangling point (Rust auto-precision trim)."""
    if s.find(".") < 0:
        return s
    return String(s.rstrip("0").rstrip("."))


fn _format_with_separator(price: Float64, precision: Int,
                          separator: String) -> String:
    """Group the integer part with `separator` every 3 digits (port of
    `format_with_separator`)."""
    var formatted = format_fixed(price, precision)
    var dot = formatted.find(".")
    var integer: String
    var decimal: String
    if dot < 0:
        integer = formatted
        decimal = String("")
    else:
        integer = String(formatted[0:dot])
        decimal = String(formatted[dot + 1:len(formatted)])

    # Preserve a leading '-' so grouping counts only digits.
    var sign = String("")
    var digits = integer
    if len(integer) > 0 and integer[0:1] == "-":
        sign = String("-")
        digits = String(integer[1:len(integer)])

    # Insert separators from the right, every 3 digits.
    var grouped = String("")
    var count = 0
    var i = len(digits) - 1
    while i >= 0:
        if count > 0 and count % 3 == 0:
            grouped = separator + grouped
        grouped = digits[i:i + 1] + grouped
        count += 1
        i -= 1

    var int_with_sep = sign + grouped
    if len(decimal) == 0:
        return int_with_sep
    return int_with_sep + "." + decimal


# =============================================================================
# Calendar helpers — civil date from epoch ms (no chrono)
# =============================================================================
# Based on Howard Hinnant's days<->civil algorithms (public domain), used here
# to recover Y/M/D/h/m/s from a Unix-epoch millisecond count for label rendering.

struct _Civil(ImplicitlyCopyable, Movable):
    """Decomposed UTC date/time (year, month 1-12, day 1-31, h/m/s)."""
    var year: Int
    var month: Int
    var day: Int
    var hour: Int
    var minute: Int
    var second: Int

    fn __init__(out self, year: Int, month: Int, day: Int,
                hour: Int, minute: Int, second: Int):
        self.year = year
        self.month = month
        self.day = day
        self.hour = hour
        self.minute = minute
        self.second = second


fn _floordiv(a: Int, b: Int) -> Int:
    """Floor division (Mojo `//` already floors for Ints; explicit for clarity)."""
    var q = a // b
    return q


fn _floormod(a: Int, b: Int) -> Int:
    """Non-negative modulo for any sign of `a`."""
    var m = a % b
    if m < 0:
        m += b
    return m


fn _civil_from_days(z_in: Int) -> Tuple[Int, Int, Int]:
    """Days since 1970-01-01 -> (year, month, day) (Hinnant `civil_from_days`)."""
    var z = z_in + 719468
    var era = _floordiv(z if z >= 0 else z - 146096, 146097)
    var doe = z - era * 146097                       # [0, 146096]
    var yoe = (doe - doe // 1460 + doe // 36524 - doe // 146096) // 365  # [0, 399]
    var y = yoe + era * 400
    var doy = doe - (365 * yoe + yoe // 4 - yoe // 100)                  # [0, 365]
    var mp = (5 * doy + 2) // 153                     # [0, 11]
    var d = doy - (153 * mp + 2) // 5 + 1             # [1, 31]
    var m = mp + 3 if mp < 10 else mp - 9            # [1, 12]
    var year = y + 1 if m <= 2 else y
    return (year, m, d)


fn _days_from_civil(year: Int, month: Int, day: Int) -> Int:
    """(year, month, day) -> days since 1970-01-01 (Hinnant `days_from_civil`)."""
    var y = year - 1 if month <= 2 else year
    var era = _floordiv(y if y >= 0 else y - 399, 400)
    var yoe = y - era * 400                            # [0, 399]
    var mp = month + 9 if month <= 2 else month - 3   # [0, 11]
    var doy = (153 * mp + 2) // 5 + day - 1            # [0, 365]
    var doe = yoe * 365 + yoe // 4 - yoe // 100 + doy  # [0, 146096]
    return era * 146097 + doe - 719468


fn _civil_from_ms(time_ms: Int64) -> _Civil:
    """Epoch-ms -> decomposed UTC date/time."""
    var total_secs = _floordiv(Int(time_ms), 1000)
    var days = _floordiv(total_secs, 86400)
    var secs_of_day = _floormod(total_secs, 86400)
    var hour = secs_of_day // 3600
    var minute = (secs_of_day % 3600) // 60
    var second = secs_of_day % 60
    var ymd = _civil_from_days(days)
    return _Civil(ymd[0], ymd[1], ymd[2], hour, minute, second)


fn _ms_from_civil(year: Int, month: Int, day: Int,
                  hour: Int, minute: Int, second: Int) -> Int64:
    """Decomposed UTC date/time -> epoch-ms."""
    var days = _days_from_civil(year, month, day)
    var secs = days * 86400 + hour * 3600 + minute * 60 + second
    return Int64(secs) * 1000


fn _weekday_from_ms(time_ms: Int64) -> Int:
    """Weekday with Monday == 0 (Rust `num_days_from_monday`)."""
    var total_secs = _floordiv(Int(time_ms), 1000)
    var days = _floordiv(total_secs, 86400)
    # 1970-01-01 was a Thursday (=3 with Monday=0).
    return _floormod(days + 3, 7)


fn _MONTH_ABBR(month: Int) -> String:
    """Three-letter month abbreviation (`%b`)."""
    if month == 1:  return String("Jan")
    if month == 2:  return String("Feb")
    if month == 3:  return String("Mar")
    if month == 4:  return String("Apr")
    if month == 5:  return String("May")
    if month == 6:  return String("Jun")
    if month == 7:  return String("Jul")
    if month == 8:  return String("Aug")
    if month == 9:  return String("Sep")
    if month == 10: return String("Oct")
    if month == 11: return String("Nov")
    if month == 12: return String("Dec")
    return String("???")


fn _pad2(n: Int) -> String:
    """Zero-pad an integer to two digits."""
    if n < 10 and n >= 0:
        return "0" + String(n)
    return String(n)


fn _hour12(hour24: Int) -> String:
    """24-hour value -> zero-padded 12-hour value (`%I`)."""
    var h = hour24 % 12
    if h == 0:
        h = 12
    return _pad2(h)


fn _ampm(hour24: Int) -> String:
    """AM/PM marker for a 24-hour value (`%p`)."""
    return String("PM") if hour24 >= 12 else String("AM")


# =============================================================================
# Sort helpers (insertion sort; lists are small — <= max_marks)
# =============================================================================

fn _sort_price_marks_weight_desc(mut marks: List[PriceMark]):
    """Sort marks by weight desc, then price asc (Rust `sort_by` comparator)."""
    for i in range(1, len(marks)):
        var key = marks[i]
        var j = i - 1
        while j >= 0 and _pm_weight_then_price_gt(marks[j], key):
            marks[j + 1] = marks[j]
            j -= 1
        marks[j + 1] = key


fn _pm_weight_then_price_gt(a: PriceMark, b: PriceMark) -> Bool:
    """True if `a` should sort after `b` for weight-desc/price-asc ordering."""
    if a.weight != b.weight:
        return a.weight < b.weight        # higher weight first
    return a.price > b.price              # lower price first


fn _sort_price_marks_price_asc(mut marks: List[PriceMark]):
    """Sort marks by price ascending."""
    for i in range(1, len(marks)):
        var key = marks[i]
        var j = i - 1
        while j >= 0 and marks[j].price > key.price:
            marks[j + 1] = marks[j]
            j -= 1
        marks[j + 1] = key


fn _sort_time_marks_weight_desc(mut marks: List[TimeMark]):
    """Sort marks by weight desc, then time asc (Rust `sort_by` comparator)."""
    for i in range(1, len(marks)):
        var key = marks[i]
        var j = i - 1
        while j >= 0 and _tm_weight_then_time_gt(marks[j], key):
            marks[j + 1] = marks[j]
            j -= 1
        marks[j + 1] = key


fn _tm_weight_then_time_gt(a: TimeMark, b: TimeMark) -> Bool:
    """True if `a` should sort after `b` for weight-desc/time-asc ordering."""
    if a.weight != b.weight:
        return a.weight < b.weight
    return a.time_ms > b.time_ms


fn _sort_time_marks_time_asc(mut marks: List[TimeMark]):
    """Sort marks by time ascending."""
    for i in range(1, len(marks)):
        var key = marks[i]
        var j = i - 1
        while j >= 0 and marks[j].time_ms > key.time_ms:
            marks[j + 1] = marks[j]
            j -= 1
        marks[j + 1] = key
