"""
Chart drawing tools — faithful port of egui-charts `src/drawings/`.

Ported from:
  - /tmp/egui-charts-ref/src/drawings/domain/coordinates.rs -> ChartPoint
  - /tmp/egui-charts-ref/src/drawings/domain/drawing.rs      -> Drawing (lifecycle)
  - /tmp/egui-charts-ref/src/drawings/domain/tool_type/behavior.rs -> required_points
  - /tmp/egui-charts-ref/src/drawings/domain/options.rs      -> Fibonacci levels
  - /tmp/egui-charts-ref/src/drawings/services/interaction.rs-> hit_test + point_to_line_distance

Starter set (per PORT_SPEC phase 1): TrendLine, HorizontalLine, Rectangle,
FibRetracement.

Design notes (how the Rust trait maps onto Mojo):
  - Rust has a single `struct Drawing` carrying a `DrawingToolType` enum and a
    `Vec<ChartPoint>`; hit testing is a free function dispatching on tool type.
    Mojo (0.26.2 nightly) lacks payload enums and cheap trait objects, so a
    drawing is one `Drawing` struct discriminated by `kind` (the `DRAW_*`
    constants), holding up to two chart-space anchor points.  This mirrors the
    "Int32 id + thin wrapper" pattern used throughout the chart port.
  - Coordinates are stored in CHART space `(bar_idx: Float64, price: Float64)`
    so drawings are stable across pan/zoom (exactly as Rust's `chart_points`).
    They are mapped to pixels only at draw / hit-test time via a `LinearMap`.
  - The Rust creation lifecycle (begin click -> drag -> commit) is ported as
    `begin(p0)` / `drag(p1)` / `commit()`.  `hit_test(point)` returns whether a
    screen-space point is within 5px of the drawing, using the same
    point-to-segment distance and Fibonacci-level proximity as the Rust
    `DrawingInteraction::hit_test`.

Conventions (see PORT_SPEC.md "VERIFIED CONVENTIONS" and model.mojo):
  - Prices/bar indices stay Float64; converted to Int32 pixels only at draw time.
  - `__init__(out self, ...)`, mutating methods take `mut self`.
"""

from math import sqrt
# RESOLVED (bug-fixer, Task #8): drawings reuse studies.LinearMap for the
# chart->pixel mapping by design (one shared affine map across overlays);
# unified with studies rather than the engine's contract RenderView.
from .studies import LinearMap
from ...rendering_int import RenderingContextInt


# =============================================================================
# Drawing kind discriminants (the ported starter tools)
# =============================================================================

comptime DRAW_TRENDLINE: Int32 = 0
"""Click-click diagonal line between two anchors (TrendLine)."""
comptime DRAW_HLINE: Int32 = 1
"""Single-anchor horizontal line at a price (HorizontalLine)."""
comptime DRAW_RECT: Int32 = 2
"""Drag-to-draw rectangle between two corners (Rectangle / Rust `Rect`)."""
comptime DRAW_FIB: Int32 = 3
"""Fibonacci retracement between two anchors (FibonacciRetracement)."""


# Fibonacci retracement ratios — verbatim from drawings/domain/options.rs
# `FibonacciConfig::default` (and the hit-test array in interaction.rs).
comptime FIB_LEVEL_COUNT: Int = 7
"""Number of default retracement levels (0 .. 1)."""


fn fib_levels() -> List[Float64]:
    """Default Fibonacci retracement ratios (port of `FibonacciConfig::default`).

    Exactly `[0.0, 0.236, 0.382, 0.5, 0.618, 0.786, 1.0]` — the same ratios the
    Rust renderer plots and the hit-test checks.
    """
    var v = List[Float64]()
    v.append(0.0)
    v.append(0.236)
    v.append(0.382)
    v.append(0.5)
    v.append(0.618)
    v.append(0.786)
    v.append(1.0)
    return v^


fn fib_level_label(level: Float64) -> String:
    """Display label for a default retracement level (port of options.rs labels)."""
    if level == 0.0:   return String("0%")
    if level == 0.236: return String("23.6%")
    if level == 0.382: return String("38.2%")
    if level == 0.5:   return String("50%")
    if level == 0.618: return String("61.8%")
    if level == 0.786: return String("78.6%")
    if level == 1.0:   return String("100%")
    return String("")


# =============================================================================
# ChartPoint — port of drawings/domain/coordinates.rs (struct ChartPoint)
# =============================================================================

struct ChartPoint(ImplicitlyCopyable, Movable):
    """A persistent point in chart space (port of `ChartPoint`).

    Stored as `(bar_idx, price)` so it stays stable across pan/zoom; screen
    coordinates are derived each frame via the current transform.  Rust keeps
    `bar_idx` as `f32`; here it is `Float64` for uniformity with the price math.
    """

    var bar_idx: Float64
    """Bar index (may be fractional for points between bars)."""
    var price: Float64
    """Price level."""

    fn __init__(out self, bar_idx: Float64, price: Float64):
        """Creates a chart point (port of `ChartPoint::new`)."""
        self.bar_idx = bar_idx
        self.price = price

    @staticmethod
    fn zero() -> ChartPoint:
        """Chart point at the origin (port of `ChartPoint::zero`)."""
        return ChartPoint(0.0, 0.0)


# =============================================================================
# Drawing — port of drawings/domain/drawing.rs (struct Drawing) + lifecycle
# =============================================================================

struct Drawing(ImplicitlyCopyable, Movable):
    """A single chart drawing (port of `Drawing`, starter tool set).

    Discriminated by `kind` (a `DRAW_*` constant).  Holds two chart-space
    anchors (`p0`, `p1`); `HorizontalLine` uses only `p0`.  `completed` mirrors
    Rust's completion flag (set once `required_points` are present).

    Lifecycle (port of the Rust click/drag/commit flow):
      1. `Drawing.begin(kind, p0)` — first click sets the start anchor.
      2. `drag(p1)` — pointer move updates the live end anchor.
      3. `commit()` — second click/release finalizes (`completed = True`).
    """

    var kind: Int32
    """One of the `DRAW_*` constants."""
    var p0: ChartPoint
    """First anchor (start)."""
    var p1: ChartPoint
    """Second anchor (end); equals `p0` until the first `drag`."""
    var has_p1: Bool
    """Whether a second anchor has been set (drag/commit happened)."""
    var completed: Bool
    """Whether the drawing is finalized (port of `Drawing::completed`)."""
    var color_r: Int32
    var color_g: Int32
    var color_b: Int32
    var color_a: Int32
    """Stroke colour RGBA (default red #F23645, matching `Drawing::new`)."""
    var stroke_width: Int32
    """Stroke width in pixels (Rust default 2.0)."""
    var visible: Bool
    """Whether the drawing is rendered (port of `Drawing::visible`)."""

    fn __init__(out self, kind: Int32, p0: ChartPoint):
        """Begin a drawing at anchor `p0` (port of `Drawing::new` + first point).

        Defaults match `Drawing::new`: red stroke, width 2, visible, not yet
        completed.  `p1` is seeded to `p0` so a draw before the first drag shows
        a zero-length stub rather than reading uninitialized state.
        """
        self.kind = kind
        self.p0 = p0
        self.p1 = p0
        self.has_p1 = False
        self.completed = False
        self.color_r = 242
        self.color_g = 54
        self.color_b = 69
        self.color_a = 255
        self.stroke_width = 2
        self.visible = True

    @staticmethod
    fn begin(kind: Int32, p0: ChartPoint) -> Drawing:
        """Start a new drawing at `p0` (alias for the constructor)."""
        return Drawing(kind, p0)

    fn required_points(self) -> Int:
        """Anchors needed to complete (port of `required_points`).

        HorizontalLine is single-click (1); TrendLine/Rectangle/Fib are
        click-click or drag-to-draw (2).
        """
        if self.kind == DRAW_HLINE:
            return 1
        return 2

    fn drag(mut self, p1: ChartPoint):
        """Update the live end anchor during creation (port of drag-to-draw).

        For a single-anchor HorizontalLine this moves `p0` (the price), matching
        the Rust single-click tools whose only coordinate is updated on drag.
        """
        if self.kind == DRAW_HLINE:
            self.p0 = p1
        else:
            self.p1 = p1
            self.has_p1 = True

    fn commit(mut self) -> Bool:
        """Finalize the drawing (port of completion check).

        Returns whether the drawing is now `completed` (it is, once the required
        anchors are present).  Mirrors `Drawing::check_completion`.
        """
        if self.required_points() == 1:
            self.completed = True
        elif self.has_p1:
            self.completed = True
        return self.completed

    fn set_color(mut self, r: Int32, g: Int32, b: Int32, a: Int32):
        """Set the stroke colour (port of `Drawing.color`)."""
        self.color_r = r
        self.color_g = g
        self.color_b = b
        self.color_a = a

    fn name(self) -> String:
        """Display name for this tool."""
        if self.kind == DRAW_TRENDLINE: return String("TrendLine")
        if self.kind == DRAW_HLINE:     return String("HorizontalLine")
        if self.kind == DRAW_RECT:      return String("Rectangle")
        if self.kind == DRAW_FIB:       return String("FibRetracement")
        return String("?")

    # ----- Hit testing (port of DrawingInteraction::hit_test) ---------------

    fn hit_test(self, sx: Int32, sy: Int32, map: LinearMap,
                tolerance: Int32 = 5) -> Bool:
        """Whether screen point `(sx, sy)` selects this drawing.

        Port of the per-tool branches in `DrawingInteraction::hit_test` with the
        same 5px tolerance:
          - TrendLine: within tolerance of the segment (point-to-line distance).
          - HorizontalLine: within tolerance of the horizontal line's y.
          - Rectangle: inside the rect spanned by the two corners.
          - Fib: within tolerance of the diagonal OR any horizontal level line
            (the level lines only count between the two x anchors).
        """
        if not self.visible:
            return False

        var x0 = map.bar_to_x(Int(self.p0.bar_idx))
        var y0 = map.price_to_y(self.p0.price)
        var x1 = map.bar_to_x(Int(self.p1.bar_idx))
        var y1 = map.price_to_y(self.p1.price)
        var tol = Float64(tolerance)

        if self.kind == DRAW_TRENDLINE:
            return _point_to_line_distance(Float64(sx), Float64(sy),
                Float64(x0), Float64(y0), Float64(x1), Float64(y1)) <= tol

        if self.kind == DRAW_HLINE:
            return abs(Float64(sy) - Float64(y0)) <= tol

        if self.kind == DRAW_RECT:
            var min_x = Float64(min(x0, x1))
            var max_x = Float64(max(x0, x1))
            var min_y = Float64(min(y0, y1))
            var max_y = Float64(max(y0, y1))
            return (Float64(sx) >= min_x and Float64(sx) <= max_x
                    and Float64(sy) >= min_y and Float64(sy) <= max_y)

        if self.kind == DRAW_FIB:
            # Main diagonal.
            if _point_to_line_distance(Float64(sx), Float64(sy),
                    Float64(x0), Float64(y0), Float64(x1), Float64(y1)) <= tol:
                return True
            # Horizontal level lines between the two x anchors.
            var levels = fib_levels()
            var min_x = Float64(min(x0, x1))
            var max_x = Float64(max(x0, x1))
            for i in range(len(levels)):
                var y = Float64(y0) + (Float64(y1) - Float64(y0)) * levels[i]
                if abs(Float64(sy) - y) <= tol:
                    if Float64(sx) >= min_x and Float64(sx) <= max_x:
                        return True
            return False

        return False

    # ----- Rendering (compose from rendering_int line/rect primitives) ------

    fn draw(self, ctx: RenderingContextInt, map: LinearMap):
        """Render this drawing at the current transform (port of the rendering
        module's per-tool `render_*`).

        All geometry is mapped from chart space to pixels here, so the drawing
        tracks pan/zoom.  Composed from `draw_line` / `draw_rectangle` since
        rendering_int has no polyline/polygon primitives.
        """
        if not self.visible:
            return
        _ = ctx.set_color(self.color_r, self.color_g, self.color_b, self.color_a)

        var x0 = map.bar_to_x(Int(self.p0.bar_idx))
        var y0 = map.price_to_y(self.p0.price)
        var x1 = map.bar_to_x(Int(self.p1.bar_idx))
        var y1 = map.price_to_y(self.p1.price)

        if self.kind == DRAW_TRENDLINE:
            _ = ctx.draw_line(x0, y0, x1, y1, self.stroke_width)

        elif self.kind == DRAW_HLINE:
            # Span the full plot width at the anchor price.
            _ = ctx.draw_line(map.x0, y0,
                              map.x0 + Int32(map.bar_step * 1000.0), y0,
                              self.stroke_width)

        elif self.kind == DRAW_RECT:
            var rx = min(x0, x1)
            var ry = min(y0, y1)
            var rw = Int32(abs(Int(x1 - x0)))
            var rh = Int32(abs(Int(y1 - y0)))
            _ = ctx.draw_rectangle(rx, ry, rw, rh)

        elif self.kind == DRAW_FIB:
            # Diagonal anchor line.
            _ = ctx.draw_line(x0, y0, x1, y1, 1)
            # Horizontal level lines + labels, between the two x anchors.
            var lx = min(x0, x1)
            var rx = max(x0, x1)
            var levels = fib_levels()
            for i in range(len(levels)):
                var y = y0 + Int32((Float64(y1) - Float64(y0)) * levels[i])
                _ = ctx.draw_line(lx, y, rx, y, 1)
                _ = ctx.draw_text(fib_level_label(levels[i]), rx + 4, y - 6, 10)


# =============================================================================
# DrawingRegistry — name -> tool factory (port of the tool-type catalogue)
# =============================================================================

struct DrawingRegistry(Copyable, Movable):
    """Create drawing tools by name (port of the drawing tool catalogue).

    Pre-loaded with the phase-1 starter tools.  `kind_of(name)` returns the
    `DRAW_*` discriminant and a `found` flag; `begin(name, p0)` constructs a
    drawing in its initial (uncommitted) state.
    """

    var names: List[String]
    """Registered tool names (insertion order)."""

    fn __init__(out self):
        """Creates a registry pre-loaded with the starter tools."""
        self.names = List[String]()
        self.names.append(String("TrendLine"))
        self.names.append(String("HorizontalLine"))
        self.names.append(String("Rectangle"))
        self.names.append(String("FibRetracement"))

    fn has(self, name: String) -> Bool:
        """Whether a tool with `name` is registered."""
        for i in range(len(self.names)):
            if self.names[i] == name:
                return True
        return False

    fn count(self) -> Int:
        """Number of registered tools."""
        return len(self.names)

    fn list(self) -> List[String]:
        """All registered tool names."""
        return self.names.copy()

    fn kind_of(self, name: String) -> Int32:
        """Discriminant for a tool name, or `-1` if the name is unknown.

        (A `(Int32, Bool)` tuple return is avoided because the current compiler
        rejects tuple construction in some package-import contexts; `-1` is the
        not-found sentinel — guard with `has(name)` for an explicit bool.)
        """
        if name == "TrendLine":      return DRAW_TRENDLINE
        if name == "HorizontalLine": return DRAW_HLINE
        if name == "Rectangle":      return DRAW_RECT
        if name == "FibRetracement": return DRAW_FIB
        return -1

    fn begin(self, name: String, p0: ChartPoint) -> Drawing:
        """Begin a drawing of the named tool at `p0` (port of tool creation).

        Guard with `has(name)` first: an unknown name returns a placeholder
        TrendLine.  (A `(Drawing, Bool)` tuple return is avoided because the
        current compiler rejects tuple construction over a struct with nested
        struct fields; callers use `has`/`kind_of` for the found flag.)
        """
        var k = self.kind_of(name)
        if k < 0:
            return Drawing.begin(DRAW_TRENDLINE, p0)
        return Drawing.begin(k, p0)


# =============================================================================
# point_to_line_distance — verbatim port of interaction.rs
# =============================================================================

fn _point_to_line_distance(px: Float64, py: Float64,
                           ax: Float64, ay: Float64,
                           bx: Float64, by: Float64) -> Float64:
    """Perpendicular distance from point to segment [a, b] (port of
    `point_to_line_distance`).

    The projection parameter is clamped to `[0, 1]`; a degenerate (zero-length)
    segment returns the Euclidean distance to `a` — matching the Rust 1e-6 guard.
    """
    var dx = bx - ax
    var dy = by - ay
    var len_sq = dx * dx + dy * dy

    if len_sq < 1e-6:
        var ex = px - ax
        var ey = py - ay
        return sqrt(ex * ex + ey * ey)

    var t = ((px - ax) * dx + (py - ay) * dy) / len_sq
    if t < 0.0:
        t = 0.0
    elif t > 1.0:
        t = 1.0

    var proj_x = ax + t * dx
    var proj_y = ay + t * dy
    var ddx = px - proj_x
    var ddy = py - proj_y
    return sqrt(ddx * ddx + ddy * ddy)
