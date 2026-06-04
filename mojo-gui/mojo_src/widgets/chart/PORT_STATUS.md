# PORT_STATUS.md — egui-charts → MojoGUI port ledger

Audited by `skeptic` (Task #9) against the read-only Rust reference at
`/tmp/egui-charts-ref/src/` (the full `egui-charts` crate, **132,087 LOC**, 529
`.rs` files). This is phase 1: the working core. Status legend:

- **PORTED** — algorithm/struct ported and verified bit-faithful against the `.rs`.
- **PARTIAL** — present but a documented divergence or incomplete subset.
- **STUBBED** — a placeholder that draws/returns something but is not the real algorithm.
- **DEFERRED** — intentionally not ported in phase 1 (no MojoGUI equivalent / out of scope).

## Honest coverage headline

| Dimension | Rust | Ported (Mojo) | Coverage |
|---|---|---|---|
| Total crate LOC | 132,087 | ~10,500 (`chart/*.mojo`) | **~8% of LOC** |
| `model/` transforms (renko/kagi/lb/pnf/range/HA) | 6 | 6 | **100%** |
| `studies/builtin` indicators | 119 | 5 (SMA/EMA/RSI/MACD/BB) | **~4%** |
| `drawings/rendering` tools | ~95 (28 files) | 4 (TrendLine/HLine/Rect/Fib) | **~4%** |
| `ChartType` render variants | 20 | 16 real + 3 stub + 1 fallback | **~80% render, ~60% faithful** |
| `scales/` (pricescale + marks + formatters) | 8 files | pricescale + marks (linear+log) | **~60%** |
| Whole subsystems (ui, ui_kit, scripting, backtest, theming engine, tokens) | ~90,000 LOC | 0 | **0% (deferred)** |

The realistic faithful coverage of the **full crate** is on the order of
**6–8%** by LOC. What *is* ported (the math core: transforms, the 5 studies,
the price/time scale math, the bar model) is high-quality and largely faithful.
The backlog (below) is the bulk of the crate.

---

## model/ — FOUNDATION

| Rust module | Status | Notes |
|---|---|---|
| `model/bar/bar.rs` (Bar + OHLC accessors) | **PORTED** | `is_bullish/bearish/doji`, `body_height/range/upper_wick/lower_wick`, `typical_price/weighted_close/midpoint/avg_price` + `hl2/hlc3/ohlc4`, `body_percentage/wick_ratio/change/change_percent`, `body_top/body_bottom` — all bit-faithful. |
| `model/bar/bar_data.rs` (BarData + Heikin-Ashi) | **PORTED** | `to_heikin_ashi` recurrence + seeding bit-faithful. `min_price/max_price/max_volume` return `0.0` on empty (Rust `Option<f64>`) — documented divergence, callers guard with `is_empty()`. |
| `model/chart_type.rs` (ChartType + category) | **PORTED** | 20 variants, discriminant order **matches Rust exactly** (`CT_BARS=0 … CT_SESSION_VOLUME=19`). Categories `CTC_STANDARD..CTC_ADVANCED`. |
| `model/timeframe.rs` | **PORTED** | `duration_ms` table + labels bit-faithful; 17 presets + `TF_CUSTOM`; variant order matches. `Bar.time` is epoch-**ms** `Int64` (Rust `DateTime<Utc>`) — documented divergence. |
| `model/symbol.rs` | **PORTED** (subset) | `Symbol` struct ported; rich `symbol_info.rs` metadata deferred. |
| `model/bar/io.rs`, `patterns.rs` | **DEFERRED** | CSV/JSON IO, candlestick pattern detection. |
| `model/{annotations,markers,footprint,tpo,session,quote,price_source,date_range,chartstate,timescale}.rs` | **PARTIAL/DEFERRED** | `price_source` (PS_OPEN..) and `timescale` coord math live in renderers/engine; the rest deferred. |
| `model/enums/*` | **PARTIAL** | Chart/marks enums folded into `comptime` Int32 constants. |

## model transforms (transforms.mojo) — PORTED, hand-verified

| Rust module | Status | Notes |
|---|---|---|
| `model/renko.rs` | **PORTED** | `to_renko_bricks` + `_atr` (renko variant) bit-faithful. brick boundary `floor(close/size)*size`, auto-bump `range/200`, MAX_BRICKS=10000. |
| `model/kagi.rs` | **PORTED** | `to_kagi_lines` + thickness flip + `_atr` bit-faithful. `KAGI_THIN=0/THICK=1` matches Rust order. auto-bump `range/500`. |
| `model/line_break.rs` | **PORTED** | `to_line_break_lines` + `detect_signal` faithful. (Note: `LB_SIGNAL_*` int values don't match Rust enum order, but only used internally; semantically correct.) |
| `model/point_figure.rs` | **PORTED** | `to_pnf_columns` + `_atr_pnf` faithful; `_round_half` correctly implements Rust round-half-away-from-zero (Mojo `round` is half-to-even). |
| `model/range_bar.rs` | **PORTED** | `to_range_bars_from_ticks` + `_from_ohlc` + `_atr_pnf` faithful. MAX_BARS=5000, MAX_ITERATIONS=100. |

**ATR variants correctly distinguished**: `_atr` (renko/kagi: `sum / period.min(len)`)
vs `_atr_pnf` (pnf/range: returns 1.0 for <2 bars, `sum / period`). Verified both.

## scales.mojo — PARTIAL (~60%)

| Rust module | Status | Notes |
|---|---|---|
| `scales/pricescale.rs` | **PORTED** | All 4 modes (Normal/Log/Percentage/IndexedTo100), `price_to_coord`/`coord_to_price`, Y-axis invert, ratio clamp, `auto_scale` w/ margins, mode transforms — bit-faithful. |
| `scales/pricescale_marks.rs` | **PORTED** | Heckbert nice-number step (1/2/5/10), linear + log marks, weight/precision — faithful. Missing the `is_finite()` NaN guards (Mojo has no easy is_finite). |
| `scales/timescale_marks.rs` | **PARTIAL** | TimeMark generator + civil-date decomposition ported; relies on a self-contained `_civil_from_days` instead of `chrono`. |
| `scales/price_formatter.rs` | **PARTIAL** | Default/precision formatting ported; Currency/Volume/Scientific subset. |
| `scales/time_formatter.rs` | **PARTIAL** | Default time formatter ported. |
| `scales/dual_pricescale.rs`, `price_display.rs` | **DEFERRED** | Dual (left+right) axis, price-display widget. |
| `TimeScale` (X axis) | **PORTED** | bar-index↔pixel + timestamp↔index; mirrors `model/timescale.rs` coord math. |

## engine.mojo — PORTED (core), PARTIAL (fidelity)

| Concern | Status | Notes |
|---|---|---|
| Coordinate map (`bar_index_to_x`/`x_to_bar_index`) | **PORTED** | Faithful to `model/timescale.rs` `idx_to_coord`/`coord_to_idx` (right-anchored, `base_idx + right_offset`). |
| Price map (`price_to_y`/`y_to_price`) | **PORTED** | Linear, top=price_max; no y-flip bug. |
| Auto-fit price | **PARTIAL** | Pads with **5%** top+bottom; Rust `PriceScale` default is 20% top / 10% bottom. See SKEPTIC_FINDINGS #6. |
| Pan (drag/keys) | **PORTED** | Direction faithful to `scroll_pixels`/`scroll_bars`. |
| Time zoom (`zoom_time`) | **PARTIAL** | **10× too sensitive** vs Rust `TimeScale::zoom` (`old*(1+s)` vs `old*(1+s/10)`). See SKEPTIC_FINDINGS #1. |
| Price zoom (`zoom_price`, right-drag) | **PORTED** | Exponential, anchored, range clamp. |
| `reset_view` | **PARTIAL** | Sets `right_offset=0`; Rust `jump_to_latest` uses `DEFAULT_RIGHT_OFFSET` whitespace. See #7. |
| Crosshair / grid / axes | **PORTED** (simplified) | 5-division price/time gridlines + labels; not the nice-number mark generator from scales.mojo (engine draws its own simple grid). See #8. |
| `state.rs` / `pan_zoom.rs` (kinetic, pinch, box-zoom, wheel) | **DEFERRED** | Only drag-pan + key/explicit zoom; no momentum/pinch/box-zoom. |
| `chart/{coords,hit_test,indicators,overlays,selection,tool_interaction,cursor_modes,series_api,interaction}` | **DEFERRED** | Large interaction subsystems. |

## renderers.mojo — 16 real / 3 stub / 1 fallback of 20 ChartTypes

| ChartType | Status | Notes |
|---|---|---|
| CT_CANDLES | **PORTED** | body min(open,close)..max, wick high-low, optional border — faithful. |
| CT_BARS (OHLC) | **PORTED** | high-low line + left open tick + right close tick. |
| CT_HOLLOW_CANDLES | **PORTED** | hollow when close>open. |
| CT_VOLUME_CANDLES | **PORTED** | width ∝ volume/max_volume. |
| CT_HEIKIN | **PORTED** | renders HA-shaped bars (note: expects HA pre-transform; see #4). |
| CT_LINE / LINE_WITH_MARKERS / STEP_LINE | **PORTED** | polyline of price_source. |
| CT_AREA / HLC_AREA | **PORTED** | filled column approximation (no native polygon). |
| CT_BASELINE | **PARTIAL** | baseline = first visible value; Rust uses configurable `options.baseline` (default 0.0). See #5. |
| CT_HIGH_LOW | **PORTED** | thin high-low rect. |
| CT_RANGE | **PARTIAL** | renderer faithful **but fed raw OHLC**, not `to_range_bars_*`. See #3. |
| CT_RENKO | **PARTIAL** | renderer faithful **but fed raw OHLC**, not `to_renko_bricks`. See #3. |
| CT_LINE_BREAK | **PARTIAL** | renderer faithful **but fed raw OHLC**, not `to_line_break_lines`. See #3. |
| CT_KAGI | **PARTIAL** | dedicated `render_kagi(List[KagiSeg])` exists but **not wired** into engine dispatch (falls back to high-low). See #2. |
| CT_POINT_AND_FIGURE | **PARTIAL** | dedicated `render_point_and_figure(List[PnfColumn])` exists but **not wired** (falls back to high-low). See #2. |
| CT_VOLUME_FOOTPRINT | **STUBBED** | placeholder band + POC line; faithful to Rust `*_placeholder`. |
| CT_TIME_PRICE_OPPORTUNITY | **STUBBED** | minimal TPO; real version bins price into stacked rows. |
| CT_SESSION_VOLUME | **STUBBED** | one block per session placeholder. |
| `chart/renderers/{crosshair,labels,markers,tooltip,session_breaks,volume,indicator,context}.rs` | **PARTIAL/DEFERRED** | crosshair/axes simplified in engine; tooltip/markers/labels/session_breaks deferred. |

## studies.mojo — 5 / 119 builtins

| Indicator | Status |
|---|---|
| SMA, EMA, RSI (Wilder), MACD, BollingerBands | **PORTED** (math bit-faithful, see SKEPTIC_FINDINGS — all clean) |
| The other **114** builtins (ADX, ATR, Stochastic, VWAP, Ichimoku, SuperTrend, Keltner, OBV, CCI, Aroon, Parabolic SAR, Donchian, …) | **DEFERRED** |
| `studies/{factory,custom,palette,indicator_trait}.rs` | **PARTIAL** | `IndicatorRegistry` ports `factory.rs` for the 5; custom/scripted indicators + palette deferred. |
| `IndicatorValue` enum | **PORTED** | as `IndicatorSeries` (row-major + valid mask). |

## drawings.mojo — 4 / ~95 tools

| Tool | Status |
|---|---|
| TrendLine, HorizontalLine, Rectangle, FibRetracement | **PORTED** | Fib levels/labels bit-faithful; fib line interpolation `start.y + (end.y-start.y)*level` faithful. begin/drag/commit + hit-test present. |
| The other ~91 tools (channels, pitchfork, gann, elliott, cycles, measurements, patterns, media, annotations, trading tools) | **DEFERRED** |
| `drawings/{manager,persistence,repositories,services/*}.rs` | **DEFERRED** | undo/redo history, z-order, snap, selection, persistence. |

## theme.mojo / config.mojo / builder.mojo — PORTED (subset)

| Module | Status | Notes |
|---|---|---|
| `theme/presets.rs` | **PORTED** | dark/light/midnight/classic/high_contrast ColorInt presets. |
| `theme/{manager,context,semantic,components}.rs`, `tokens/`, `theming.rs` | **DEFERRED** | RON design tokens, semantic theming engine (~5,500 LOC). |
| `config/*` | **PARTIAL** | `ChartConfig`/`CrosshairConfig` core flags; full config tree deferred. |
| `chart/builder.rs` | **PORTED** | fluent `ChartBuilder` + presets; built against engine's real API (not the idealized INTEGRATION_CONTRACT names — see #9). |

## Whole subsystems — DEFERRED (no MojoGUI equivalent / phase ≥2)

`ui/` (30,929 LOC), `ui_kit/` (7,455), `scripting/` (5,901), `backtest/` (2,103),
`icons/` (1,789), `ext/` (1,801), `widget/` (3,633), `validation/` (469),
`styles/` (575), `tokens/` (3,015), RON token files. Combined **~57,000 LOC**
intentionally out of phase-1 scope per PORT_SPEC.md.
