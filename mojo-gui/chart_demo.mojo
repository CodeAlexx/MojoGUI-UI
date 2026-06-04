"""
CHART DEMO — egui-charts MojoGUI port (phase 1)

Builds a dark-themed `ChartInt` via `ChartBuilder`, feeds it ~150 synthetic
OHLCV bars generated with a deterministic seeded random-walk (NO Date.now / no
random builtins — a fixed-seed LCG loop so the data is identical every run), and
runs a node_graph_demo-style window loop.  Press SPACE to cycle the chart type
(candles -> line -> area -> heikin -> renko -> ...), BACKSPACE to go back.

Build (compile-only check from repo root; do NOT open the window here):
    pixi run mojo build mojo-gui/chart_demo.mojo -o /tmp/chart_demo_check

Window loop / init pattern copied from node_graph_demo.mojo, but using the
high-level `RenderingContextInt` (Int32 coords, String text) from
mojo_src/rendering_int.mojo so the chart widget can render via `chart.render(ctx)`.

Engine methods used here are the INTEGRATION_CONTRACT.md ChartInt API:
`set_bars(var List[Bar])`, `set_chart_type`, `handle_key_event`, `render`, and
the public `x/y/width/height` fields (positioned below the header strip).
"""

from mojo_src.rendering_int import RenderingContextInt
from mojo_src.widget_int import KeyEventInt
from mojo_src.widgets.chart.model import (
    Bar,
    Timeframe, TF_HOUR1,
    ChartType, all_chart_types,
)
from mojo_src.widgets.chart.theme import ChartTheme
from mojo_src.widgets.chart.builder import ChartBuilder
from mojo_src.widgets.chart.engine import ChartInt


comptime WINDOW_WIDTH: Int32 = 1000
comptime WINDOW_HEIGHT: Int32 = 700

# Chart widget bounds inside the window (leaves a header strip at the top).
comptime HEADER_HEIGHT: Int32 = 36
comptime CHART_X: Int32 = 0
comptime CHART_Y: Int32 = HEADER_HEIGHT
comptime CHART_W: Int32 = WINDOW_WIDTH
comptime CHART_H: Int32 = WINDOW_HEIGHT - HEADER_HEIGHT

# GLFW key codes (match the constants used across the other widgets).
comptime GLFW_KEY_SPACE: Int32 = 32
comptime GLFW_KEY_BACKSPACE: Int32 = 259
comptime KEY_DOWN: Bool = True


# =============================================================================
# Deterministic synthetic OHLCV data — fixed-seed random walk, no builtins.
# =============================================================================

fn _lcg_next(state: UInt64) -> UInt64:
    """One step of a classic 64-bit linear congruential generator.

    Constants are the Numerical-Recipes LCG (a=6364136223846793005,
    c=1442695040888963407).  Pure integer math, fully deterministic — no
    `random` module and no time source, so every run yields identical bars.
    """
    return state * 6364136223846793005 + 1442695040888963407


fn _unit_float(state: UInt64) -> Float64:
    """Map an LCG state to a Float64 in [0.0, 1.0) using its high 32 bits."""
    var hi = (state >> 32) & 0xFFFFFFFF
    return Float64(hi) / 4294967296.0


fn generate_sample_bars(count: Int) -> List[Bar]:
    """Generate `count` deterministic OHLCV bars via a seeded random walk.

    The walk drifts the close around a starting price of 100.0 with small
    per-step moves; high/low straddle the open/close with a random wick, and
    volume is a bounded random value.  Bar timestamps advance by one hour
    (TF_HOUR1) from a fixed epoch so the time axis is monotonic without needing
    a real clock.  Returns a `List[Bar]` to match `ChartInt.set_bars`.
    """
    var bars = List[Bar]()
    if count <= 0:
        return bars^

    var state: UInt64 = 0x2545F4914F6CDD1D  # fixed, non-zero seed
    var price: Float64 = 100.0
    var time: Int64 = 1_700_000_000_000      # fixed epoch (ms); not "now"
    var step_ms: Int64 = 3_600_000           # 1 hour per bar (TF_HOUR1)

    for _i in range(count):
        var open = price

        # Random close move in roughly [-2.0, +2.0].
        state = _lcg_next(state)
        var move = (_unit_float(state) - 0.5) * 4.0
        var close = open + move
        if close < 1.0:
            close = 1.0  # keep prices positive for log-scale sanity

        # Upper/lower wicks: random extensions beyond the body.
        state = _lcg_next(state)
        var up_wick = _unit_float(state) * 1.5
        state = _lcg_next(state)
        var down_wick = _unit_float(state) * 1.5

        var body_top = open if open > close else close
        var body_bottom = open if open < close else close
        var high = body_top + up_wick
        var low = body_bottom - down_wick
        if low < 0.5:
            low = 0.5

        # Volume in roughly [1000, 6000].
        state = _lcg_next(state)
        var volume = 1000.0 + _unit_float(state) * 5000.0

        bars.append(Bar(time, open, high, low, close, volume))

        price = close
        time += step_ms

    return bars^


# =============================================================================
# Main demo loop (pattern from node_graph_demo.mojo).
# =============================================================================

fn main() raises:
    print("CHART DEMO — egui-charts MojoGUI port")
    print("=" * 50)
    print("Synthetic OHLCV (deterministic seed), dark theme, type cycling.")
    print("")

    # --- Build the data and the chart widget via the fluent builder ---------
    var bars = generate_sample_bars(150)
    print("Generated", len(bars), "synthetic bars")

    var builder = ChartBuilder.new()
    builder.with_symbol(String("DEMOUSD"))
    builder.with_timeframe(Timeframe(TF_HOUR1))
    builder.with_theme(ChartTheme.dark())
    builder.with_visible_candles(120)

    var chart = builder.build()

    # Position the chart below the header strip (engine exposes x/y/width/height).
    chart.x = CHART_X
    chart.y = CHART_Y
    chart.width = CHART_W
    chart.height = CHART_H

    chart.set_bars(bars^)  # hand the bars to the engine (owned move)

    # Chart types to cycle through (display order from model.all_chart_types()).
    var types = all_chart_types()
    var type_index: Int = 0

    # --- Open the window (high-level Int32 rendering context) ---------------
    # Library path is relative to the run directory (mojo-gui/), matching the
    # other demos which load "./c_src/librendering_with_fonts.so".
    var ctx = RenderingContextInt(String("./c_src/librendering_with_fonts.so"))

    if not ctx.initialize(WINDOW_WIDTH, WINDOW_HEIGHT, String("MojoGUI Chart Demo")):
        print("Failed to initialize window")
        return

    print("Window opened!")
    _ = ctx.load_default_font()
    print("Font loaded")
    print("")
    print("Controls:")
    print("  - SPACE: next chart type")
    print("  - BACKSPACE: previous chart type")
    print("  - Close window to exit")

    # Edge-detect state for the type-cycle keys (same idea as node_graph_demo's
    # mouse was_pressed latch).
    var space_was_down: Bool = False
    var back_was_down: Bool = False
    var frame_count: Int32 = 0

    while True:
        _ = ctx.poll_events()

        if ctx.should_close_window():
            break

        # --- Input: cycle chart type on SPACE / BACKSPACE (rising edge) -----
        var space_down = ctx.get_key_state(GLFW_KEY_SPACE)
        var back_down = ctx.get_key_state(GLFW_KEY_BACKSPACE)

        if space_down and not space_was_down:
            type_index = (type_index + 1) % len(types)
            chart.set_chart_type(types[type_index])
            # Also forward as a key event so the engine can react if it wants.
            _ = chart.handle_key_event(KeyEventInt(GLFW_KEY_SPACE, KEY_DOWN))

        if back_down and not back_was_down:
            type_index = (type_index - 1 + len(types)) % len(types)
            chart.set_chart_type(types[type_index])

        space_was_down = space_down
        back_was_down = back_down

        # --- Render ---------------------------------------------------------
        _ = ctx.frame_begin()

        # Window background (dark, matches the chart theme background).
        _ = ctx.set_color(19, 23, 34, 255)
        _ = ctx.draw_filled_rectangle(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)

        # The chart widget paints its own plot area, grid, axes and crosshair.
        chart.render(ctx)

        # Header strip + label (drawn last so it sits on top).
        _ = ctx.set_color(0, 0, 0, 180)
        _ = ctx.draw_filled_rectangle(0, 0, WINDOW_WIDTH, HEADER_HEIGHT)
        _ = ctx.set_color(235, 235, 240, 255)
        var ct = types[type_index]
        var header = String("Chart Demo  |  DEMOUSD 1h  |  Type: ") + ct.name() \
            + String("  (SPACE next / BACKSPACE prev)")
        _ = ctx.draw_text(header, 10, 10, 14)

        _ = ctx.frame_end()
        frame_count += 1

    _ = ctx.cleanup()
    print("")
    print("Demo finished!")
