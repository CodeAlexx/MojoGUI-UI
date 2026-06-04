"""
_check_all.mojo — INTEGRATION ELABORATION HARNESS (bug-fixer, Task #8 Gate B).

Compile-only. NEVER run — no RenderingContextInt window is opened and no FFI
library is loaded; this file exists solely to force the Mojo compiler to
*elaborate* (type-check + codegen) every key method across all 11 chart modules
so latent List-move / copy errors surface at build time (the same class of bug
that hid in model.mojo:226 until a method was actually called).

chart_demo.mojo only exercises engine + renderers + builder + theme + config +
model. This harness additionally constructs and calls:
  - ChartInt over EVERY ChartType (all_chart_types()) + render path elaboration.
  - studies.mojo: IndicatorRegistry + each builtin Indicator.calculate(bars).
  - drawings.mojo: each Drawing begin -> drag -> commit -> hit_test -> draw.
  - scales.mojo: PriceScale auto_scale + PriceMarkGenerator/TimeMarkGenerator.
  - transforms.mojo: renko / kagi / line_break / point_figure / range_bar /
    heikin_ashi (otherwise orphaned — no integrated module imports them yet).

Build (from repo root /home/alex/MojoGUI-UI):
    pixi run mojo build mojo-gui/_check_all.mojo -o /tmp/check_all
"""

from mojo_src.widgets.chart.model import (
    Bar, BarData,
    Timeframe, TF_HOUR1,
    ChartType, all_chart_types,
)
from mojo_src.widgets.chart.theme import ChartTheme
from mojo_src.widgets.chart.builder import ChartBuilder
from mojo_src.widgets.chart.engine import ChartInt, create_chart_int
from mojo_src.widgets.chart.studies import (
    Indicator, IndicatorRegistry, IndicatorSeries, LinearMap,
)
from mojo_src.widgets.chart.drawings import (
    Drawing, DrawingRegistry, ChartPoint,
    DRAW_TRENDLINE, DRAW_HLINE, DRAW_RECT, DRAW_FIB,
    fib_levels,
)
from mojo_src.widgets.chart.scales import (
    PriceScale, TimeScale, PriceMarkGenerator, TimeMarkGenerator,
    PriceMark, TimeMark,
)
from mojo_src.widgets.chart.transforms import (
    RenkoConfig, KagiConfig, LineBreakConfig, PointFigureConfig,
    RangeBarConfig,
    to_renko_bricks, to_kagi_lines, to_line_break_lines, to_pnf_columns,
    to_range_bars_from_ohlc, to_heikin_ashi,
)
from mojo_src.widgets.chart.config import ChartConfig
from mojo_src.widgets.chart.model import CT_CANDLES


fn _sample_bars(count: Int) -> BarData:
    """Deterministic OHLCV bars (same fixed-seed LCG idea as chart_demo)."""
    var data = BarData()
    if count <= 0:
        return data^
    var state: UInt64 = 0x2545F4914F6CDD1D
    var price: Float64 = 100.0
    var time: Int64 = 1_700_000_000_000
    var step_ms: Int64 = 3_600_000
    for _i in range(count):
        state = state * 6364136223846793005 + 1442695040888963407
        var hi = (state >> 32) & 0xFFFFFFFF
        var move = (Float64(hi) / 4294967296.0 - 0.5) * 4.0
        var open = price
        var close = open + move
        if close < 1.0:
            close = 1.0
        var body_top = open if open > close else close
        var body_bottom = open if open < close else close
        var high = body_top + 1.0
        var low = body_bottom - 1.0
        if low < 0.5:
            low = 0.5
        var volume = 1000.0 + Float64(hi % 5000)
        data.push(Bar(time, open, high, low, close, volume))
        price = close
        time += step_ms
    return data^


fn _check_engine_all_types(data: BarData) -> Int:
    """Build a ChartInt and switch it through EVERY ChartType.

    Exercises engine setters + chart-type dispatch elaboration. The render path
    itself needs a RenderingContextInt (FFI) so it is NOT called here (compile-
    only / no window); type-switching + viewport math is what we force-elaborate.
    """
    var chart = create_chart_int(0, 0, 1000, 700)
    chart.set_data(data.copy())
    chart.set_theme_colors(
        ChartTheme.dark().background, ChartTheme.dark().grid,
        ChartTheme.dark().axis, ChartTheme.dark().text,
        ChartTheme.dark().crosshair, ChartTheme.dark().bull,
        ChartTheme.dark().bear,
    )

    var types = all_chart_types()
    var touched: Int = 0
    for i in range(len(types)):
        chart.set_chart_type(types[i])
        chart.auto_fit_price()
        # Exercise the coordinate maps + visible-range math for each type.
        var lo = chart.first_visible_index()
        var hi = chart.last_visible_index()
        _ = chart.bar_index_to_x(lo)
        _ = chart.x_to_bar_index(500)
        _ = chart.price_to_y(100.0)
        _ = chart.y_to_price(350)
        _ = chart.bars_visible()
        if hi >= lo:
            touched += 1

    # Pan / zoom / reset elaboration.
    chart.pan_by_pixels(40)
    chart.zoom_time(1.25, 500)
    chart.zoom_price(20.0, 350)
    chart.reset_view()
    chart.update()
    return touched


fn _check_studies(data: BarData) -> Int:
    """IndicatorRegistry + every builtin indicator.calculate()."""
    var reg = IndicatorRegistry()
    var names = reg.list()
    var produced: Int = 0
    for i in range(len(names)):
        var ind = reg.create(names[i])
        var series = ind.calculate(data.bars)
        produced += series.len()
        _ = ind.name()
        _ = ind.desc()

    # Also build each via the named factories directly and calculate.
    var sma = Indicator.sma(20)
    var ema = Indicator.ema(12)
    var rsi = Indicator.rsi(14)
    var macd = Indicator.macd(12, 26, 9)
    var bb = Indicator.bollinger(20, 2.0)
    produced += sma.calculate(data.bars).len()
    produced += ema.calculate(data.bars).len()
    produced += rsi.calculate(data.bars).len()
    produced += macd.calculate(data.bars).len()
    produced += bb.calculate(data.bars).len()
    return produced


fn _check_drawings() -> Int:
    """Each Drawing: begin -> drag -> commit -> hit_test (begin/drag/commit lifecycle)."""
    var reg = DrawingRegistry()
    var p0 = ChartPoint(2.0, 100.0)
    var p1 = ChartPoint(40.0, 120.0)
    var map = LinearMap(0, 8.0, 90.0, 130.0, 0, 700)

    var committed: Int = 0
    var kinds = List[Int32]()
    kinds.append(DRAW_TRENDLINE)
    kinds.append(DRAW_HLINE)
    kinds.append(DRAW_RECT)
    kinds.append(DRAW_FIB)

    for i in range(len(kinds)):
        var d = Drawing.begin(kinds[i], p0)
        d.drag(p1)
        if d.commit():
            committed += 1
        d.set_color(255, 200, 0, 255)
        _ = d.name()
        _ = d.required_points()
        # hit_test exercises the LinearMap mapping + geometry branches.
        _ = d.hit_test(map.bar_to_x(20), map.price_to_y(110.0), map)

    # Registry begin-by-name path.
    var names = reg.list()
    for i in range(len(names)):
        var d2 = reg.begin(names[i], p0)
        d2.drag(p1)
        _ = d2.commit()
        committed += 1

    _ = len(fib_levels())
    return committed


fn _check_scales(data: BarData) -> Int:
    """PriceScale auto-fit + price/time mark generators."""
    var ps = PriceScale(700.0)
    ps.auto_scale_from_bars(data.copy())
    _ = ps.price_to_coord(100.0)
    _ = ps.range_length()

    var ts = TimeScale(8.0)
    ts.set_offset(0.0)
    _ = ts.index_to_coord(5.0)
    _ = ts.coord_to_index(400.0)

    var pmg = PriceMarkGenerator()
    var pmarks = pmg.generate_marks(90.0, 130.0, 700.0, 0, 0.0, 700.0)

    var bar_times = List[Int64]()
    var n = data.len()
    for i in range(n):
        bar_times.append(data.bars[i].time)
    var t_start: Int64 = bar_times[0] if n > 0 else 0
    var t_end: Int64 = bar_times[n - 1] if n > 0 else 0
    var tmg = TimeMarkGenerator()
    var tmarks = tmg.generate_marks(t_start, t_end, 1000.0, bar_times)

    return len(pmarks) + len(tmarks)


fn _check_transforms(data: BarData) -> Int:
    """renko / kagi / line_break / point_figure / range_bar / heikin_ashi."""
    var bricks = to_renko_bricks(data.bars, RenkoConfig(1.0))
    var kagi = to_kagi_lines(data.bars, KagiConfig(1.0))
    var lb = to_line_break_lines(data.bars, LineBreakConfig(3))
    var pnf = to_pnf_columns(data.bars, PointFigureConfig(1.0, 3, False, 14))
    var rb = to_range_bars_from_ohlc(data.bars, RangeBarConfig(10.0, False, 14))
    var ha = to_heikin_ashi(data.bars)
    return len(bricks) + len(kagi) + len(lb) + len(pnf) + len(rb) + len(ha)


fn _check_builder() -> Int:
    """ChartBuilder presets + fluent setters + build()."""
    var b = ChartBuilder.new()
    b.with_symbol(String("CHKUSD"))
    b.with_timeframe(Timeframe(TF_HOUR1))
    b.with_theme(ChartTheme.midnight())
    b.with_visible_candles(120)
    var c1 = b.build()

    var c2 = ChartBuilder.extended().build()
    var c3 = ChartBuilder.price_chart().build()
    var c4 = ChartBuilder.options_chart().build()
    return Int(c1.width + c2.width + c3.width + c4.width)


fn main() raises:
    var data = _sample_bars(200)

    var t1 = _check_engine_all_types(data)
    var t2 = _check_studies(data)
    var t3 = _check_drawings()
    var t4 = _check_scales(data)
    var t5 = _check_transforms(data)
    var t6 = _check_builder()

    print("ELABORATION HARNESS OK (compile-only).")
    print("engine types touched:", t1)
    print("indicator points produced:", t2)
    print("drawings committed:", t3)
    print("scale marks generated:", t4)
    print("transform rows produced:", t5)
    print("builder width sum:", t6)
