"""
Compile harness for the chart model package.

Verifies that the chart package imports resolve and the core model types
construct correctly.  Build only (do NOT run — the GPU/display is busy):

    pixi run mojo build mojo-gui/chart_smoke.mojo -o /tmp/chart_smoke

This is the canonical import pattern other chart builders must use to pull in
model types: an absolute package path rooted at `mojo_src`.
"""

from mojo_src.widgets.chart.model import (
    Bar,
    BarData,
    Symbol,
    Timeframe,
    ChartType,
    ChartTypeParams,
    all_chart_types,
    chart_type_category_name,
    TF_HOUR4,
    CT_CANDLES,
    CT_HEIKIN,
    CHART_TYPE_COUNT,
)


fn main():
    # Construct a couple of bars (timestamps are Unix epoch milliseconds).
    var bullish = Bar(1_700_000_000_000, 100.0, 110.0, 95.0, 105.0, 1000.0)
    var bearish = Bar(1_700_000_060_000, 105.0, 110.0, 95.0, 100.0, 1200.0)

    var data = BarData()
    data.push(bullish)
    data.push(bearish)

    print("bars:", data.len())
    print("bullish?", bullish.is_bullish())
    print("range:", bullish.range())          # 110 - 95 = 15.0
    print("body_top:", bullish.body_top())      # max(100, 105) = 105.0
    print("hlc3:", bullish.hlc3())              # (110+95+105)/3
    print("min_price:", data.min_price())       # 95.0
    print("max_price:", data.max_price())       # 110.0

    var ha = data.to_heikin_ashi()
    print("ha bars:", ha.len())

    var sym = Symbol("BTCUSDT", "Bitcoin / Tether")
    print("symbol:", sym.name, "active?", sym.active)

    var tf = Timeframe(TF_HOUR4)
    print("timeframe:", tf.as_str(), "duration_ms:", tf.duration_ms())
    var custom = Timeframe.custom(45)
    print("custom tf:", custom.as_str(), "seconds:", custom.seconds())

    var ct = ChartType(CT_CANDLES)
    print("chart type:", ct.name(), "uses_ohlc?", ct.uses_ohlc())
    print("category:", chart_type_category_name(ct.category()))
    print("heikin transforms?", ChartType(CT_HEIKIN).transforms_data())

    var params = ChartTypeParams()
    print("renko brick:", params.renko_brick_size)

    print("chart type count:", len(all_chart_types()), "expected:", CHART_TYPE_COUNT)
