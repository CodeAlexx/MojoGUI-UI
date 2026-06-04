"""
CHART ALL-IN-ONE DEMO — egui-charts MojoGUI port (phase 1)

A single window that exercises the whole chart addon so you can eyeball it:

  * ALL 20 chart types          — SPACE / BACKSPACE to cycle
  * ALL 5 theme presets         — T to cycle (dark/light/midnight/classic/hi-contrast)
  * ALL 20 indicators           — I cycles through them (price overlay, or an oscillator pane)
  * ALL 14 drawing tools        — D cycles through them (rendered on sample points)
  * Pan / zoom / grid / crosshair — arrow keys pan, +/- zoom, G grid, C crosshair, R reset

Runs at normal resolution (no screen/DPI scaling).

Run (needs a display / GPU):
    pixi run mojo chart_all_demo.mojo
Compile-only check (no window, no GPU):
    pixi run mojo build chart_all_demo.mojo -o /tmp/chart_all_demo

Data is a deterministic seeded random-walk (identical every run; no clock/RNG builtins).
"""

from mojo_src.rendering_int import RenderingContextInt, ColorInt
from mojo_src.widget_int import KeyEventInt
from mojo_src.widgets.chart.model import (
    Bar, BarData,
    Timeframe, TF_HOUR1,
    ChartType, all_chart_types,
)
from mojo_src.widgets.chart.theme import ChartTheme
from mojo_src.widgets.chart.builder import ChartBuilder
from mojo_src.widgets.chart.engine import ChartInt
from mojo_src.widgets.chart.studies import (
    Indicator, IndicatorRegistry, IndicatorSeries, LinearMap, draw_indicator_line,
)
from mojo_src.widgets.chart.drawings import ChartPoint, Drawing, DrawingRegistry


# Window size in actual pixels (normal resolution, no DPI scaling).
comptime WIN_W: Int32 = 1280
comptime WIN_H: Int32 = 800

# GLFW key codes (match the other MojoGUI demos).
comptime KEY_SPACE: Int32 = 32
comptime KEY_BACKSPACE: Int32 = 259
comptime KEY_T: Int32 = 84
comptime KEY_I: Int32 = 73
comptime KEY_D: Int32 = 68
comptime KEY_LEFT: Int32 = 263
comptime KEY_RIGHT: Int32 = 262
comptime KEY_UP: Int32 = 265
comptime KEY_DOWN: Int32 = 264
comptime KEY_G: Int32 = 71
comptime KEY_C: Int32 = 67
comptime KEY_R: Int32 = 82
comptime KEY_DOWN_STATE: Bool = True


# =============================================================================
# Deterministic synthetic OHLCV data — fixed-seed LCG random walk (no builtins).
# =============================================================================

fn _lcg_next(state: UInt64) -> UInt64:
    return state * 6364136223846793005 + 1442695040888963407


fn _unit(state: UInt64) -> Float64:
    var hi = (state >> 32) & 0xFFFFFFFF
    return Float64(hi) / 4294967296.0


fn generate_sample_bars(count: Int) -> BarData:
    var data = BarData()
    if count <= 0:
        return data^
    var state: UInt64 = 0x2545F4914F6CDD1D
    var price: Float64 = 100.0
    var time: Int64 = 1_700_000_000_000
    var step_ms: Int64 = 3_600_000
    for _i in range(count):
        var open = price
        state = _lcg_next(state)
        var move = (_unit(state) - 0.5) * 4.0
        var close = open + move
        if close < 1.0:
            close = 1.0
        state = _lcg_next(state)
        var up_wick = _unit(state) * 1.5
        state = _lcg_next(state)
        var down_wick = _unit(state) * 1.5
        var body_top = open if open > close else close
        var body_bottom = open if open < close else close
        var high = body_top + up_wick
        var low = body_bottom - down_wick
        if low < 0.5:
            low = 0.5
        state = _lcg_next(state)
        var volume = 1000.0 + _unit(state) * 5000.0
        data.push(Bar(time, open, high, low, close, volume))
        price = close
        time += step_ms
    return data^


# =============================================================================
# Theme cycling helper — map a ChartTheme preset onto the engine palette.
# =============================================================================

fn apply_theme(mut chart: ChartInt, th: ChartTheme):
    chart.set_theme(th)


fn theme_for(idx: Int) -> ChartTheme:
    var i = idx % 5
    if i == 0:
        return ChartTheme.dark()
    elif i == 1:
        return ChartTheme.light()
    elif i == 2:
        return ChartTheme.midnight()
    elif i == 3:
        return ChartTheme.classic()
    else:
        return ChartTheme.high_contrast()


fn theme_name(idx: Int) -> String:
    var i = idx % 5
    if i == 0:
        return String("dark")
    elif i == 1:
        return String("light")
    elif i == 2:
        return String("midnight")
    elif i == 3:
        return String("classic")
    else:
        return String("high-contrast")


# =============================================================================
# Indicator / drawing rendering helpers.
# =============================================================================

struct VRange(ImplicitlyCopyable, Movable):
    """A padded [lo, hi] value range for fitting an oscillator sub-pane."""
    var lo: Float64
    var hi: Float64

    fn __init__(out self, lo: Float64, hi: Float64):
        self.lo = lo
        self.hi = hi


fn series_vrange(series: IndicatorSeries) -> VRange:
    """Min/max across every valid bar and line, padded 8% (for pane fit)."""
    var lo = 1.0e18
    var hi = -1.0e18
    for i in range(series.len()):
        if series.is_valid(i):
            for li in range(series.line_cnt):
                var v = series.line(i, li)
                if v < lo:
                    lo = v
                if v > hi:
                    hi = v
    if hi <= lo:
        return VRange(0.0, 1.0)
    var pad = (hi - lo) * 0.08
    return VRange(lo - pad, hi + pad)


fn line_rgb(idx: Int) -> ColorInt:
    """Distinct colour per indicator line (cycled)."""
    var i = idx % 6
    if i == 0:
        return ColorInt(240, 200, 60, 255)    # yellow
    if i == 1:
        return ColorInt(80, 200, 230, 255)     # cyan
    if i == 2:
        return ColorInt(200, 120, 230, 255)    # purple
    if i == 3:
        return ColorInt(120, 220, 130, 255)    # green
    if i == 4:
        return ColorInt(240, 130, 90, 255)     # orange
    return ColorInt(185, 192, 210, 255)        # grey


# =============================================================================
# Main demo loop.
# =============================================================================

fn main() raises:
    print("CHART ALL-IN-ONE DEMO — egui-charts MojoGUI port")
    print("=" * 56)

    var data = generate_sample_bars(180)
    print("Generated", data.len(), "synthetic bars")

    # Build the chart via the fluent builder.
    var builder = ChartBuilder.new()
    builder.with_symbol(String("DEMOUSD"))
    builder.with_timeframe(Timeframe(TF_HOUR1))
    builder.with_theme(ChartTheme.dark())
    builder.with_visible_candles(140)
    var chart = builder.build()
    # build() uses a default canvas; stretch the widget to fill our window.
    chart.x = 0
    chart.y = 0
    chart.width = WIN_W
    chart.height = WIN_H
    chart.set_data(data.copy())

    # Registries — cycle through EVERY indicator and drawing tool.
    var n = data.len()
    var i_a = 20
    var i_b = n - 20 if n - 20 > i_a else n - 1
    var i_mid = (i_a + i_b) // 2
    var ind_reg = IndicatorRegistry()
    var ind_names = ind_reg.list()       # all 20 indicator names
    var draw_reg = DrawingRegistry()
    var draw_names = draw_reg.list()      # all 14 drawing-tool names
    print("Registry:", len(ind_names), "indicators,", len(draw_names), "drawing tools")

    var types = all_chart_types()
    var type_index: Int = 0
    var theme_index: Int = 0
    var ind_index: Int = 1     # 0 = off; 1..N shows ind_names[idx-1]
    var draw_index: Int = 1    # 0 = off; 1..N shows draw_names[idx-1]

    # --- Open the window ----------------------------------------------------
    var ctx = RenderingContextInt(String("./c_src/librendering_with_fonts.so"))
    if not ctx.initialize(WIN_W, WIN_H, String("MojoGUI Chart — All Demo")):
        print("Failed to initialize window")
        return
    _ = ctx.load_default_font()

    # Fixed normal-resolution metrics (no screen/DPI detection).
    var font_lg: Int32 = 14
    var font_sm: Int32 = 11
    var header_h: Int32 = 30

    print("")
    print("Controls: SPACE/BACKSPACE chart type | T theme | I indicators |",
          "D drawings | arrows pan | +/- zoom | G grid | C crosshair | R reset")

    var sp_down = False
    var bk_down = False
    var t_down = False
    var i_down = False
    var d_down = False

    while True:
        _ = ctx.poll_events()
        if ctx.should_close_window():
            break

        # --- Input: demo-level toggles (rising edge) ------------------------
        var sp = ctx.get_key_state(KEY_SPACE)
        var bk = ctx.get_key_state(KEY_BACKSPACE)
        var tk = ctx.get_key_state(KEY_T)
        var ik = ctx.get_key_state(KEY_I)
        var dk = ctx.get_key_state(KEY_D)

        if sp and not sp_down:
            type_index = (type_index + 1) % len(types)
            chart.set_chart_type(types[type_index])
        if bk and not bk_down:
            type_index = (type_index - 1 + len(types)) % len(types)
            chart.set_chart_type(types[type_index])
        if tk and not t_down:
            theme_index = (theme_index + 1) % 5
            apply_theme(chart, theme_for(theme_index))
        if ik and not i_down:
            ind_index = (ind_index + 1) % (len(ind_names) + 1)
        if dk and not d_down:
            draw_index = (draw_index + 1) % (len(draw_names) + 1)

        sp_down = sp
        bk_down = bk
        t_down = tk
        i_down = ik
        d_down = dk

        # --- Forward pan/zoom/toggle keys to the engine ---------------------
        if ctx.get_key_state(KEY_LEFT):
            _ = chart.handle_key_event(KeyEventInt(KEY_LEFT, KEY_DOWN_STATE))
        if ctx.get_key_state(KEY_RIGHT):
            _ = chart.handle_key_event(KeyEventInt(KEY_RIGHT, KEY_DOWN_STATE))

        # --- Keep the price domain fitted to the viewport -------------------
        chart.update()

        # --- Render ---------------------------------------------------------
        _ = ctx.frame_begin()
        var bg = theme_for(theme_index).background
        _ = ctx.set_color(bg.r, bg.g, bg.b, 255)
        _ = ctx.draw_filled_rectangle(0, 0, WIN_W, WIN_H)

        chart.draw(ctx)

        # Build a LinearMap that matches the engine's CURRENT viewport so
        # overlays land exactly on the price axis.
        var lm = LinearMap(
            chart.bar_index_to_x(0), chart.bar_spacing,
            chart.price_min, chart.price_max,
            chart.plot_y(), chart.plot_bottom(),
        )

        if ind_index > 0:
            var iname = ind_names[ind_index - 1]
            var ind = ind_reg.create(iname)
            var series = ind.calculate(data.bars)
            if ind.is_overlay():
                # Plot directly on the price axis (MAs, bands, VWAP, channels).
                for li in range(series.line_cnt):
                    var c = line_rgb(li)
                    draw_indicator_line(ctx, series, li, lm, c.r, c.g, c.b, 255, 2)
            else:
                # Oscillator: translucent sub-pane fit to the series' own range.
                var pane_h = chart.plot_height() // 4
                var pane_top = chart.plot_bottom() - pane_h
                _ = ctx.set_color(10, 12, 18, 165)
                _ = ctx.draw_filled_rectangle(chart.plot_x(), pane_top,
                                              chart.plot_width(), pane_h)
                var vr = series_vrange(series)
                var pane_lm = LinearMap(chart.bar_index_to_x(0), chart.bar_spacing,
                                        vr.lo, vr.hi, pane_top, chart.plot_bottom())
                for li in range(series.line_cnt):
                    var c = line_rgb(li)
                    draw_indicator_line(ctx, series, li, pane_lm, c.r, c.g, c.b, 255, 2)
                _ = ctx.set_color(205, 211, 224, 255)
                _ = ctx.draw_text(iname, chart.plot_x() + 6, pane_top + 4, font_sm)

        if draw_index > 0:
            # Construct the current tool on sample data points and render it.
            var dname = draw_names[draw_index - 1]
            var d = draw_reg.begin(dname, ChartPoint(Float64(i_a), data.bars[i_a].low))
            if d.required_points() >= 2:
                d.drag(ChartPoint(Float64(i_b), data.bars[i_b].high))
            if d.required_points() >= 3:
                d.drag(ChartPoint(Float64(i_mid), data.bars[i_mid].close))
            _ = d.commit()
            d.set_color(255, 200, 60, 235)
            d.draw(ctx, lm)

        # --- Header strip + legend (drawn on top) ---------------------------
        _ = ctx.set_color(0, 0, 0, 190)
        _ = ctx.draw_filled_rectangle(0, 0, WIN_W, header_h)
        _ = ctx.set_color(235, 235, 240, 255)
        var ct = types[type_index]
        var ind_s = String("off") if ind_index == 0 else ind_names[ind_index - 1]
        var drw_s = String("off") if draw_index == 0 else draw_names[draw_index - 1]
        var header = String("DEMOUSD 1h  |  ") + ct.name() \
            + String("  [") + String(type_index + 1) + String("/20]") \
            + String("  |  theme: ") + theme_name(theme_index) \
            + String("  |  ind: ") + ind_s \
            + String("  |  draw: ") + drw_s
        _ = ctx.draw_text(header, 10, 9, font_lg)
        _ = ctx.set_color(150, 156, 170, 255)
        _ = ctx.draw_text(
            String("SPACE/BACKSPACE type  T theme  I cycle indicator  D cycle drawing  arrows pan  +/- zoom  G grid  C crosshair  R reset"),
            10, header_h + 4, font_sm)

        _ = ctx.frame_end()

    _ = ctx.cleanup()
    print("Demo finished.")
