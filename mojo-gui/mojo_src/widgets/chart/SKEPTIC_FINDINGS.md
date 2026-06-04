# SKEPTIC_FINDINGS.md — adversarial audit (Task #9)

Audited by `skeptic`, READ-ONLY, against `/tmp/egui-charts-ref/src/`.
Each finding: **severity** · Mojo location · Rust reference · what's wrong · fix.

Severity legend:
- **BLOCKER** — compile-affecting or breaks the phase-1 Definition of Done.
- **CORRECTNESS** — wrong numeric/visual output vs the source algorithm.
- **FAITHFULNESS** — diverges from the Rust source but is a defensible choice / cosmetic.
- **MINOR** — naming, labels, missing defensive guards.

Bottom line up front: **the ported math is sound.** transforms.mojo (renko/kagi/
line_break/point_figure/range_bar/heikin), studies.mojo (SMA/EMA/RSI/MACD/BB),
the price/time scale math, and the bar model are all bit-faithful — I tried to
break them and could not. The real issues are in the **engine↔renderer wiring**
(transform types are not pre-transformed before rendering) and a **10× zoom
sensitivity** bug. No BLOCKER-class compile errors were found by reading; the
bug-fixer's `pixi run mojo build` gate remains authoritative for compilation.

---

## #1 — Time-zoom is 10× too sensitive  · CORRECTNESS

- **Mojo**: `engine.mojo:416` — `var new_spacing = old_spacing * (1.0 + zoom_scale)`
- **Rust**: `model/timescale.rs:281` — `let new_spacing = old_spacing + zoom_scale * (old_spacing / 10.0);` (i.e. `old_spacing * (1.0 + zoom_scale/10.0)`)
- **Wrong**: For the same `zoom_scale`, the Mojo step is 10× larger. Keyboard `+`
  passes `0.25` → Mojo grows spacing +25% per press; Rust intends +2.5%. Mouse-wheel
  callers passing Rust's `(-delta/100).clamp(-0.5,0.5)` would zoom wildly.
- **Fix**: `var new_spacing = old_spacing * (1.0 + zoom_scale / 10.0)`. (Then the
  keyboard `0.25`/`-0.25` give a Rust-equivalent feel.)

## #2 — Kagi & Point&Figure are NOT wired into the render dispatch  · CORRECTNESS (DoD-relevant)

- **Mojo**: `renderers.mojo:1308-1312` — the `else` branch of `render_chart_type`
  catches `CT_KAGI` / `CT_POINT_AND_FIGURE` and calls `render_high_low(...)`.
  Dedicated, correct `render_kagi(List[KagiSeg])` (`renderers.mojo:973`) and
  `render_point_and_figure(List[PnfColumn])` (`renderers.mojo:1086`) exist but are
  never reached because `engine._draw_series` (`engine.mojo:675`) only calls the
  single-`BarData` `render_chart_type`.
- **Rust**: `chart/renderers/mod.rs` dispatches Kagi/PnF to their real renderers
  with the transformed series.
- **Wrong**: Selecting Kagi or P&F draws a high-low bar chart, not Kagi/P&F.
- **Fix**: In `engine._draw_series`, for `CT_KAGI` call
  `transforms.to_kagi_lines(visible.bars, cfg)` → map to `KagiSeg` → `render_kagi`;
  for `CT_POINT_AND_FIGURE` call `transforms.to_pnf_columns(...)` → `PnfColumn` →
  `render_point_and_figure`. (Phase-2 wiring; not compile-blocking.)

## #3 — Renko / LineBreak / Range render RAW OHLC, not the transform output  · CORRECTNESS (DoD-relevant)

- **Mojo**: `engine.mojo:646-676` builds `visible` from the raw `self.data.bars`
  and passes it straight to `render_chart_type`, which routes `CT_RENKO`→
  `render_renko` (`renderers.mojo:939`), `CT_LINE_BREAK`→`render_line_break`
  (`:1033`), `CT_RANGE`→`render_range_bars` (`:895`). Each of those renderers is
  documented and coded to expect the **pre-built** brick/line/range series
  (`# IMPORT-TODO bug-fixer: caller passes transforms.to_renko_bricks(...)`).
- **Rust**: the chart computes `to_renko_bricks` / `to_line_break_lines` /
  `to_range_bars_from_ohlc` before rendering.
- **Wrong**: Renko/LineBreak/Range draw the raw candles laid out as bricks/blocks,
  so the phase-1 DoD ("renders … renko") is visually satisfied but **not faithful**.
- **Fix**: In `engine._draw_series`, branch before building `visible`: if the chart
  type transforms data, run the matching `transforms.mojo` fn over the full data,
  then feed the result. The renderers themselves are correct and need no change.

## #4 — Heikin-Ashi rendered from raw bars (no HA transform applied)  · CORRECTNESS

- **Mojo**: `engine.mojo:675` routes `CT_HEIKIN` → `render_heikin_ashi`
  (`renderers.mojo:569`) with raw `visible` bars. `render_heikin_ashi` draws them
  as candles; it does **not** apply the HA recurrence — that lives in
  `transforms.to_heikin_ashi` / `BarData.to_heikin_ashi`.
- **Rust**: Heikin chart type runs `to_heikin_ashi` first.
- **Wrong**: Heikin renders identically to plain candles.
- **Fix**: For `CT_HEIKIN`, build `visible` from `transforms.to_heikin_ashi(slice)`
  (or `self.data.to_heikin_ashi()` then slice). Same wiring class as #3.
- **Note**: the HA *math* (`model.mojo:278`, `transforms.mojo:1044`) is bit-faithful
  — this is purely a wiring gap.

## #5 — Baseline uses first-value, Rust uses a configurable baseline (default 0.0)  · FAITHFULNESS

- **Mojo**: `renderers.mojo:836-838` — `baseline = price_source_compute(first bar)`.
- **Rust**: `chart/series/baseline.rs:31,50` — `options.baseline: f64` (Default `0.0`),
  set via `with_baseline`; color split is `value >= options.baseline`.
- **Wrong**: Not faithful to the Rust default; the Mojo choice (anchor to first
  visible value) is more practical but differs from the source.
- **Fix**: Add a `baseline: Float64` to `ChartConfig`/`RenderColors` (default 0.0),
  thread it into `render_baseline`. Low priority — defensible divergence.

## #6 — Auto-fit price margins differ (5% vs Rust 20%/10%)  · FAITHFULNESS

- **Mojo**: `engine.mojo:380-383` — 5% top **and** 5% bottom padding.
- **Rust**: `scales/pricescale.rs` `PriceScaleMargins::default` (and the doc-cited
  default) is **top 0.2 / bottom 0.1** (20% top, 10% bottom). `scales.mojo:110-111`
  itself correctly stores `margin_top=0.2 / margin_bottom=0.1` — but the engine's
  hand-rolled `auto_fit_price` does not use `PriceScale`, so it ignores those.
- **Wrong**: The engine's vertical framing differs from Rust and from its own
  `scales.mojo`. Asymmetric vs symmetric padding also differs.
- **Fix**: Route `auto_fit_price` through `scales.PriceScale.auto_scale_to` (which
  is already faithful), or at minimum use 0.2/0.1.

## #7 — `reset_view` loses the right-edge whitespace  · FAITHFULNESS

- **Mojo**: `engine.mojo:466` — `self.right_offset = 0.0`.
- **Rust**: `model/timescale.rs:188-190` `jump_to_latest` sets
  `right_offset = DEFAULT_RIGHT_OFFSET` (≈2.5 bars; field default is 5.0).
- **Wrong**: After reset the last bar sits flush at the right edge instead of with
  the sticky whitespace gutter Rust keeps.
- **Fix**: Define `DEFAULT_RIGHT_OFFSET` and use it in `reset_view`.

## #8 — Grid/axis use fixed 5 divisions, not the nice-number mark generator  · FAITHFULNESS

- **Mojo**: `engine.mojo:702-706` (grid) and `:723-728` (axis labels) hardcode 5
  evenly-spaced price divisions; vertical gridlines are pixel-stepped (`~60px`).
- **Rust**: `chart/rendering/{grid,axes}.rs` drive gridlines/labels from
  `PriceMarkGenerator` / `TimeMarkGenerator` (the Heckbert nice-number marks).
- **Wrong**: Labels land on arbitrary fractional prices, not round numbers. The
  faithful `PriceMarkGenerator` is already ported in `scales.mojo` but unused by
  the engine.
- **Fix**: Call `scales.PriceMarkGenerator.generate_marks(...)` for the horizontal
  gridlines + price labels, and `TimeMarkGenerator` for the time axis.

## #9 — INTEGRATION_CONTRACT API vs the actual engine API drifted  · MINOR (spec drift)

- **Contract** (`INTEGRATION_CONTRACT.md`) specifies `ChartInt.set_bars(var
  bars: List[Bar])`, `set_visible_bars(n)`, fields `first_idx/bars_visible/
  bar_width`, and a shared `RenderView` struct that renderers consume.
- **Actual**: `engine.mojo` exposes `set_data(BarData)`, `bars_visible()` (method),
  `right_offset`/`bar_spacing`, and renderers consume `ViewGeom` (not `RenderView`).
- **Why it's only MINOR**: `builder.mojo` (`:34-38`, `:210-236`) was written against
  the **actual** engine API and is internally consistent, and the demo presumably
  follows. Nothing calls the contract's idealized names. So this is documentation
  drift, not a broken call path. The bug-fixer's compile gate is authoritative.
- **Fix**: Update INTEGRATION_CONTRACT.md to match the shipped engine API (or add
  thin `set_bars`/`set_visible_bars` shims if external callers were promised them).

## #10 — `LineBreakSignal` constant values don't match the Rust enum order  · MINOR

- **Mojo**: `transforms.mojo:400-404` — `NONE=0, BULLISH=1, BEARISH=2,
  BULLISH_REVERSAL=3, BEARISH_REVERSAL=4`.
- **Rust**: `model/line_break.rs:183-194` — `Bullish, Bearish, BullishReversal,
  BearishReversal, None` (None last, value 4).
- **Why MINOR**: `detect_signal` returns the right *semantic* value and the ints are
  never serialized or compared across the FFI boundary. No behavioral impact.
- **Fix**: Optional — reorder for parity if any consumer relies on the numeric value.

## #11 — `pricescale_marks` linear/log generators drop the `is_finite()` NaN guards  · MINOR

- **Mojo**: `scales.mojo:514` (`_generate_linear_marks`), `:552` (`_generate_log_marks`).
- **Rust**: `scales/pricescale_marks.rs:123-128, 158-160, 206-216, 222-224` guard
  `!x.is_finite()` on inputs, step, start_price, and log values.
- **Why MINOR**: Mojo lacks a cheap `is_finite`; the zero/tiny-range and `nice_step<=0`
  guards are kept, so a NaN price range would still mostly be handled. A pathological
  NaN could slip through and produce no marks rather than a panic.
- **Fix**: Add explicit `!= x` (NaN-self-inequality) checks at the entry points if
  NaN-bearing data is possible.

---

## Verified-clean (I tried to break these and could not)

- **ATR variants** — `_atr` (renko/kagi: `sum / min(period, len)`) vs `_atr_pnf`
  (pnf/range: `1.0` for <2 bars, `sum / period`). Both bit-faithful (`transforms.mojo:53,94`).
- **Round-half-away-from-zero** — `_round_half` (`transforms.mojo:648`) correctly
  replaces Mojo's round-half-to-even for P&F box counts, matching Rust `f64::round`.
- **Renko/Kagi/LineBreak/PnF/Range/HA** transform math — all bit-faithful (see PORT_STATUS).
- **SMA/EMA/RSI/MACD/Bollinger** — EMA seeding (`values[0]==close[0]`, no warmup),
  RSI Wilder smoothing + `1e-10` loss floor, MACD signal seeded on `macd_line[0]`,
  Bollinger **population** variance (`/period`) and `i<period-1` warmup — all match.
- **PriceScale** modes (Normal/Log/Percentage/IndexedTo100), Y-invert, ratio clamp,
  log base (`ln/ln(e)`), percent/indexed transforms — bit-faithful (`scales.mojo:190-352`).
- **Nice-number tick step** (Heckbert 1/2/5/10) + linear/log mark loops — faithful.
- **Bar OHLC accessors** (hl2/hlc3/ohlc4, wicks, change_percent div-guard) — bit-faithful.
- **ChartType (20) and Timeframe (17+custom) discriminant order** — match Rust exactly.
- **Candle body/wick rules** (`min/max(open,close)`, body min-height, optional border)
  and **Fibonacci** levels/labels/interpolation — faithful.
- **Coordinate maps** (`bar_index_to_x`/`x_to_bar_index`, `price_to_y`/`y_to_price`) —
  faithful to `timescale.rs`; no y-axis-flip or off-by-one found.
