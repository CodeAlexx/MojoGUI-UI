"""
Compile + API smoke harness for chart/engine.mojo (ChartInt).

Build only (do NOT run — the GPU/display is busy):

    pixi run mojo build mojo-gui/chart_engine_smoke.mojo -o /tmp/chart_engine_smoke

Mirrors chart_smoke.mojo: imports the engine by absolute package path so the
engine's relative sibling imports (`from .model import ...`, `from ..rendering_int
import ...`) resolve.  Building the engine file *directly* fails with "cannot
import relative to a top-level package" — that is expected; use this harness.
"""

from mojo_src.widgets.chart.engine import ChartInt, create_chart_int
from mojo_src.widgets.chart.model import Bar, BarData, ChartType, CT_CANDLES, CT_LINE


fn main():
    var chart = create_chart_int(10, 10, 800, 500)

    # Feed a few synthetic bars.
    var data = BarData()
    data.push(Bar(1_000, 100.0, 105.0, 99.0, 104.0, 10.0))
    data.push(Bar(61_000, 104.0, 108.0, 103.0, 106.0, 12.0))
    data.push(Bar(121_000, 106.0, 107.0, 101.0, 102.0, 8.0))
    chart.set_data(data)
    chart.set_chart_type(ChartType(CT_LINE))

    # Exercise the viewport + coordinate API.
    chart.update()
    var x0 = chart.bar_index_to_x(0)
    var idx = chart.x_to_bar_index(x0)
    var y0 = chart.price_to_y(104.0)
    var p0 = chart.y_to_price(y0)
    chart.pan_by_pixels(20)
    chart.zoom_time(0.25, 400)
    chart.zoom_price(-30.0, 200)
    chart.reset_view()

    print("bars_visible:", chart.bars_visible())
    print("first/last visible:", chart.first_visible_index(), chart.last_visible_index())
    print("x0/idx:", x0, idx)
    print("y0/price:", y0, p0)
