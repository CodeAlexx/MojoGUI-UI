# MojoGUI module map

> One paragraph per public module. Read this once at session start to know
> where things live. ⭐ marks modules most applications depend on directly.
> ⚠️ marks areas with deferred features or sharp edges to know about.

MojoGUI is a native, integer-coordinate widget toolkit written in Mojo. It
renders through a small C drawing backend (one GLFW/OpenGL window) wrapped by a
Mojo FFI layer, so every widget speaks the same handful of primitives:
rectangles, lines, circles, and text. On top of that core sit three feature
packages — an interactive financial **chart** engine, a **dock** layout manager
for tabbed/split panes, and a drag-to-reorder **dnd** list — plus a broad set of
standalone form and container widgets. Coordinates and sizes are `Int32`
throughout (pixels); only the chart's price/time math keeps `Float64` precision
and converts to pixels at draw time. Widgets are retained-mode value structs:
you build them, feed them input events, and call `draw(ctx)` each frame.

---

## Core

### ⭐ `mojo_src/rendering_int.mojo` — the rendering context and value types
The foundation every widget draws through. `RenderingContextInt` owns the
dynamically-loaded C drawing library and exposes the full primitive set:
window lifecycle (`initialize`, `cleanup`, `frame_begin`, `frame_end`,
`should_close_window`), drawing (`set_color(r,g,b,a)`, `draw_rectangle` /
`draw_filled_rectangle`, `draw_circle` / `draw_filled_circle`,
`draw_line(x1,y1,x2,y2,thickness)`, `draw_text(text,x,y,size)`), text metrics
(`get_text_width`, `get_text_height`, `load_default_font`), and input polling
(`poll_events`, `get_mouse_x` / `get_mouse_y`, `get_mouse_button_state(button)`,
`get_key_state(key_code)`). Colors are passed as 0–255 integers and normalized
to 0.0–1.0 for OpenGL internally. The module also defines the shared value
types used everywhere: `ColorInt(r,g,b,a)`, `PointInt(x,y)`, `SizeInt(w,h)`, and
`RectInt(x,y,width,height)` with a `contains(point)` test. A set of free
functions (`color_black`, `color_white`, `color_red`, `color_gray`, …) return
common colors. There is no native polyline, polygon, gradient, or bezier —
those shapes are composed from lines and rectangles by the widgets that need
them.

### ⭐ `mojo_src/widget_int.mojo` — the widget contract and base
Defines the common widget interface. `WidgetInt` is the trait every widget
conceptually satisfies: `get_bounds` / `set_bounds`, `is_visible` /
`set_visible`, `contains_point`, `handle_mouse_event`, `handle_key_event`,
`render`, and `update`. `MouseEventInt(x, y, button, pressed)` and
`KeyEventInt(key_code, pressed)` are the input event records passed into those
handlers. `BaseWidgetInt(x, y, width, height)` is a concrete helper holding
`bounds`, `visible`, `enabled`, `background_color`, `border_color`, and
`border_width`, with `render_background(ctx)` for the common
fill-plus-border pattern; widgets compose it (hold the fields they need)
rather than inherit. `EventManagerInt` is a small helper that polls the
context each frame and tracks current/previous mouse position so callers can
detect movement and button state.

---

## Chart package (`mojo_src/widgets/chart/`)

A complete interactive financial charting engine: 20 chart types, 20 technical
indicators, 14 drawing tools, logarithmic/percentage price scales, a time axis
with adaptive tick marks, five theme presets, and a fluent builder. Everything
keeps prices as `Float64` and only rounds to pixels at draw time.

### ⭐ `model.mojo` — domain types
The core data vocabulary. `Bar` is one OHLCV candle (`time` as Unix-epoch
milliseconds, plus `open`/`high`/`low`/`close`/`volume` as `Float64`) with a
rich accessor set: direction (`is_bullish`, `is_bearish`, `is_doji`),
measurements (`body_height`, `range`, `upper_wick`, `lower_wick`), derived
prices (`typical_price`/`hlc3`, `weighted_close`, `midpoint`/`hl2`,
`avg_price`/`ohlc4`), ratios (`body_percentage`, `wick_ratio`, `change`,
`change_percent`), and body bounds (`body_top`, `body_bottom`). `BarData` wraps
a `List[Bar]` with `push`, `len`, aggregations (`min_price`, `max_price`,
`max_volume`, `total_volume`, `avg_volume`) and a `to_heikin_ashi()`
transform. `Symbol(name, display_name)` identifies an instrument. `Timeframe`
covers presets from `TF_MS100` to `TF_MONTH1` plus a `custom(seconds)` form,
with `duration_ms`, `total_seconds`/`seconds`, and `as_str` label. `ChartType`
wraps one of the 20 `CT_*` ids and answers `name`, `description`, `category`,
`uses_ohlc`, `supports_volume`, `requires_parameters`, `is_time_independent`,
and `transforms_data`; `all_chart_types()` returns them in display order and
`ChartTypeParams` carries renko/kagi/range/P&F/line-break/baseline parameters.

### ⭐ `scales.mojo` — price and time mapping
Turns prices and bar positions into screen coordinates. `PriceScale` supports
four modes (`PS_NORMAL`, `PS_LOGARITHMIC`, `PS_PERCENTAGE`, `PS_INDEXED_TO_100`)
with auto-scaling (`auto_scale_to`, `auto_scale_from_bars`) or a manual range,
and converts both ways (`price_to_coord` / `coord_to_price`,
`price_to_pixel_y` / `pixel_y_to_price`). `TimeScale` holds bar spacing and a
horizontal offset, supports `pan_by` / `zoom_by`, and maps bar index ↔ pixel and
time ↔ index/pixel (`index_to_pixel_x`, `time_to_pixel_x`, `pixel_x_to_index`,
…). `PriceMarkGenerator` produces axis labels (`PriceMark` with price, text,
coordinate, and weight) at "nice" intervals, and `TimeMarkGenerator` produces
`TimeMark`s classified by granularity (`TMT_YEAR` … `TMT_TIME_WITH_SECONDS`)
and weighted (`TMW_*`) so the renderer can thin labels as the user zooms.

### `transforms.mojo` — alternative bar constructions
Time-independent and smoothed series built from raw bars. `to_renko_bricks`
emits `RenkoBrick`s using a `RenkoConfig` (fixed brick size or
`RenkoConfig.from_atr`). `to_kagi_lines` emits `KagiLine`s from a `KagiConfig`
(fixed reversal, ATR-based, or percentage), tracking thin/thick line weight on
trend reversals. `to_line_break_lines` builds N-line-break `LineBreakLine`s
(configurable line count) and `detect_signal` classifies the latest pattern
(`LB_SIGNAL_BULLISH`, `…BEARISH`, reversals, or none). `to_pnf_columns` builds
Point & Figure `PnfColumn`s (X/O) from a `PointFigureConfig` (box size or ATR,
reversal count, optional close-only). Each result type converts back to a `Bar`
via `to_bar()` so renderers and scales can treat them uniformly. Internal
helpers compute price min/max and ATR. (Heikin-Ashi lives on `BarData` in
`model.mojo`.)

### ⭐ `engine.mojo` — the `ChartInt` widget
The interactive chart itself, composed (not inherited) from a bounds rect. It
owns the bar data, a `ChartType`, time/price view state, theme, config, and
crosshair state, and handles all interaction: panning (`pan_by_pixels`),
time/price zoom (`zoom_time`, `zoom_price` anchored at the cursor), auto-fit
(`auto_fit_price`), and `reset_view`. `handle_mouse_event` and
`handle_key_event` wire up drag-pan, wheel-style zoom, and shortcuts (arrows,
`+`/`-`, `R` reset, `G` grid, `C` crosshair). It exposes coordinate mapping
(`bar_index_to_x`, `x_to_bar_index`, `price_to_y`, `y_to_price`) and visible-
range queries (`first_visible_index`, `last_visible_index`, `bars_visible`).
`draw(ctx)` paints background, grid, axes, and crosshair, then delegates the
actual series drawing to `renderers.draw_series` via a `RenderView` — the engine
never duplicates renderer logic. `create_chart_int(x,y,w,h)` is the factory.

### ⭐ `renderers.mojo` — one draw function per chart type
The drawing back end for all 20 chart types, each a free function taking a
`RenderingContextInt`, a `RenderView` (the area + scale snapshot), and the bars:
`draw_candles`, `draw_ohlc_bars`, `draw_hollow_candles`,
`draw_volume_candles`, `draw_heikin_ashi`, `draw_line`,
`draw_line_with_markers`, `draw_step_line`, `draw_area`, `draw_hlc_area`,
`draw_baseline`, `draw_high_low`, `draw_range_bars`, `draw_renko`, `draw_kagi`,
`draw_line_break`, `draw_point_and_figure`, `draw_volume_footprint`,
`draw_session_volume`, `draw_tpo`, plus `draw_volume_histogram`. `draw_series`
dispatches on `ChartType` to the right one. A `price_source_compute` helper
selects OPEN/HIGH/LOW/CLOSE/HL2/HLC3/OHLC4 for line-style charts, and a family
of small primitives (`_vline`, `_filled_rect_minmax`, `_area_column`,
`_draw_wicks`, `_body_filled`/`_body_hollow`, `_polyline`, `_x_symbol`/
`_o_symbol`) compose candles, areas, and P&F glyphs from the core line/rect
primitives.

### `studies.mojo` — technical indicators
20 indicators behind a uniform `Indicator` type and an `IndicatorRegistry`.
Constructors cover `sma`, `ema`, `wma`, `hma`, `vwma`, `rsi`, `macd`,
`bollinger`, `atr`, `adx`, `stochastic`, `williams_r`, `cci`, `roc`, `obv`,
`vwap`, `mfi`, `aroon`, `donchian`, and `keltner` (the `IND_*` ids). Each
`Indicator` reports `name`, `desc`, whether it's an `is_overlay` (drawn on the
price pane vs. a sub-pane), its `line_cnt`, and `line_names`, and computes an
`IndicatorSeries` from a `List[Bar]` via `calculate`. `IndicatorSeries` stores
one-, two-, or three-line outputs per bar with validity tracking (`is_valid`,
`line(bar, idx)`) so leading warm-up bars render as gaps. `IndicatorRegistry`
holds a configured set with visibility toggles.

### `drawings.mojo` — on-chart drawing tools
14 manual drawing tools behind a `Drawing` type and a `DrawingRegistry`. The
`DRAW_*` kinds cover trend line, horizontal/vertical line, rectangle, ray,
extended line, cross line, parallel channel, ellipse, text, price range, and the
Fibonacci family (retracement, extension, fan). A `ChartPoint(bar_idx, price)`
anchors tools in data space. Tools follow a lifecycle: `Drawing.begin(kind, p0)`,
`drag(p1)` while placing, then `commit()`; `required_points` says how many
clicks a tool needs, `hit_test` enables selection, and `draw(ctx, map)` renders
through a `LinearMap` (data→screen). Fibonacci helpers (`fib_levels`,
`fib_ext_levels`, `fib_fan_levels` and their label functions) supply the
standard ratio sets. `DrawingRegistry` lists available tools by name and
constructs them.

### `theme.mojo` — color presets
`ChartTheme` bundles every color and a few sizes the chart needs (background,
grid, axis text, bullish/bearish candles, wicks, crosshair, volume, etc.). Five
presets are provided as constructors — `classic()` (default, light chrome over a
dark chart), `dark()`, `light()`, `midnight()`, and `high_contrast()` — selected
by the `TP_*` ids via `from_preset`, with `theme_preset_name` /
`theme_preset_display_name` for menus.

### `config.mojo` — behavior options
Non-color settings. `ChartConfig` collects toggles and defaults (grid, axes,
price-scale mode, right offset, and similar layout knobs), and `CrosshairConfig`
controls crosshair behavior: mode (`CH_MODE_NORMAL` follows the mouse,
`CH_MODE_MAGNET` snaps to the nearest OHLC point), style (`CH_STYLE_FULL`/`DOT`/
`ARROW`), and line style (`CH_LINE_SOLID`/`DASHED`/`DOTTED`).

### ⭐ `builder.mojo` — fluent chart construction
`ChartBuilder` assembles a ready-to-use `ChartInt` without juggling every field
by hand. Presets (`new`, `extended`, `price_chart`, `options_chart`) seed
sensible defaults, and chained setters (`with_symbol`, `with_timeframe`,
`with_theme`, `with_chart_type` / `with_type`, `with_config`,
`with_visible_candles`, `with_right_price_scale`) configure it; `build()`
returns the configured `ChartInt`. ⚠️ A higher-level `TradingChart` facade
(symbol search, indicator panels) is planned but not part of this build —
`build()` returns the chart widget directly.

### `mathx.mojo` — pure-Mojo math helpers
Self-contained transcendental functions so the chart never links a math
library: `csin`, `ccos`, `ctan` (range-reduced series), `cln`, `clog10`, and
`cexp`, plus constants `PI`, `TAU`, `HALF_PI`, `LN2`, `LN10`, `LOG10E`. The
logarithmic price scale and any trig in renderers/drawings route through these.

---

## Dock package (`mojo_src/widgets/dock/`)

A docking layout manager: tabbed leaf panes split horizontally/vertically into a
resizable, rearrangeable tree, all inside one window. The dock owns the layout
(tab strips, splitters, drag-and-drop docking); the host draws each pane's
content into the body rectangle the dock reports.

### ⭐ `model.mojo` — the layout tree
The data model. `DockTab(id, title)` is one pane tab. `LeafNode` is a stack of
tabs with the active index, a full `rect`, and a `viewport` (body) rect.
`SplitNode` holds the split `rect`, a `fraction` (share given to the first /
top / left child, `Float64`), and collapse bookkeeping. `Node` is a tagged
union (`NODE_EMPTY`/`LEAF`/`VERTICAL`/`HORIZONTAL`) wrapping a leaf or split,
with predicates (`is_leaf`, `is_parent`, `is_vertical`, `is_horizontal`) and
`rect`/`set_rect`. `Tree` stores nodes in a binary-heap-indexed list (children
of node *i* live at *2i+1* and *2i+2*) and provides the layout operations:
`split_left` / `split_right` / `split_above` / `split_below` (and the general
`split`), `remove_leaf`, `remove_tab`, `set_active_tab`, `push_to_focused_leaf`,
`find_active`, `find_tab_by_id`, and `root_node`. Free helpers `node_root`,
`node_left`, `node_right`, and `node_parent` express the heap math. `DockState`
holds the main-surface `Tree` and forwards `push_to_focused_leaf`. ⚠️ Indices
use `-1` for "none"; multi-pane "surfaces" in separate OS windows are deferred
(single window), so only the main surface exists.

### ⭐ `area.mojo` — the `DockAreaInt` widget + host content API
The interactive dock widget, composed from a bounds rect. `layout()` walks the
tree and assigns each node its pixel rectangle from the split fractions;
`draw(ctx)` paints splitters, per-leaf tab strips, and the active-tab highlight.
`handle_mouse_event` implements tab clicks (activate), tab close, splitter drag
(adjusting a split's fraction between `MIN_FRACTION` and `MAX_FRACTION`), and
tab drag-and-docking: it tracks the grabbed tab, computes the hovered leaf and
drop zone (`ZONE_CENTER`/`LEFT`/`RIGHT`/`TOP`/`BOTTOM`, with edge zones sized by
`EDGE_ZONE_FRAC`), previews the drop region, and on release mutates the tree to
move or split. The host-content API lets the application render each pane:
`leaf_count()`, `leaf_body_rect(i)` (the `RectInt` to draw into), and
`leaf_active_tab_id(i)`. `create_dock_area_int(x,y,w,h)` is the factory.

### `style.mojo` — dock appearance
`DockStyle` gathers the dock's colors (tab background, active tab, tab text,
borders, splitter, drop-zone overlay, body background) and sizes
(`DEFAULT_TAB_HEIGHT`, `DEFAULT_SPLITTER_WIDTH`, `DEFAULT_TAB_MIN_WIDTH`).
`dark()` and `light()` presets are provided; a `DockAreaInt` takes one via
`set_style`.

---

## Drag-and-drop package (`mojo_src/widgets/dnd/`)

### ⭐ `dnd.mojo` — `DndListInt` reorderable list
A vertical list of rows the user reorders by dragging. `DndItem(id, label)` is
one row; `DndListInt` (composed from a bounds rect) holds the items and the
drag state. Build it with `add_item` / `set_items`, style it with `set_style`
(`DndStyle`) and `set_row_height`, and read it back with `item_count`,
`item_id(i)`, `item_label(i)`, and `order()` (the current id ordering).
`handle_mouse_event` plus `on_mouse_move` track the grab, render the dragged row
following the cursor, and reorder the list on drop; `last_response()` returns a
`DragDropResponse` reporting whether a drag is in progress or just finished and
which id moved (`-1` when none). The reorder itself is the standalone
`shift_vec(items, from_, to)` primitive (a `DragUpdate(from_, to)` describes the
move). `create_dnd_list_int(x,y,w,h)` is the factory. ⚠️ Reorder is instant on
drop; return/settle animations are deferred.

---

## Other widgets (`mojo_src/widgets/*_int.mojo`)

A library of standalone form, container, and navigation widgets. Each is a
self-contained `*Int` value struct following the same
`handle_mouse_event` / `handle_key_event` / `draw(ctx)` pattern.

- `button_int` — clickable push button with label and pressed/hover state.
- `checkbox_int` — toggle box with label.
- `slider_int` — draggable value slider over a min/max range.
- `spinbox_int` — numeric entry with increment/decrement arrows.
- `progressbar_int` — determinate progress fill.
- `textlabel_int` — static text label.
- `textedit_int` — single/multi-line editable text field.
- `searchbox_int` — text field with search affordance.
- `dropdown_int` / `combobox_int` — selectable option lists (closed/expandable).
- `listbox_int` — scrollable single/multi-select list.
- `listview_int` — column/detail list view.
- `treeview_int` — collapsible hierarchical tree.
- `columnheader_int` — sortable column header strip.
- `tabcontrol_int` — classic tabbed pane control.
- `split_tab_widget` — splittable tabbed container.
- `accordion_int` — vertically stacked collapsible sections.
- `container_int` — generic child-holding panel.
- `dockpanel_int` — edge-docking panel layout.
- `menu_int` / `contextmenu_int` — menu bar and right-click context menu.
- `toolbar_int` — button/tool strip.
- `statusbar_int` — bottom status strip.
- `navbar_int` — navigation bar.
- `breadcrumb_int` — path/breadcrumb trail.
- `dialog_int` — modal dialog frame.
- `filedialog_int` — file open/save dialog.
- `colorpicker_int` — color selection control.
- `datetimepicker_int` — date/time selection control.
- `icon_int` — icon glyph drawing.
- `scrollbar_int` — draggable scrollbar.
- `node_graph_int` — node-based graph editor with pan/zoom, draggable nodes,
  ports, and connection edges.
- `source_editor_int` — code/source text editor.
- `advanced_widgets_int` — assorted higher-level composite widgets.
- `widget_constants` / `widget_events` — shared constants and event helpers used
  across the widget set.
