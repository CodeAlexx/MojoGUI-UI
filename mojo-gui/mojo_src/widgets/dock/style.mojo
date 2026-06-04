"""
Dock style presets — faithful port of egui_dock `src/style.rs`.

Ported from:
  - /tmp/egui_dock-ref/src/style.rs  -> Style / SeparatorStyle / TabBarStyle /
                                        TabStyle / TabInteractionStyle /
                                        TabBodyStyle / OverlayStyle

egui_dock's `Style` is a deep tree of sub-styles whose colors are mostly derived
at runtime from egui's `Visuals` (`Style::from_egui`).  MojoGUI is integer +
retained with no egui Visuals, so this port FLATTENS the sub-styles into the
single field set the dock area consumes (fixed by the dock task / DOCK_PORT_SPEC):
solid `ColorInt` colors + pixel sizes.

Structural defaults are kept faithful to the Rust `Default` impl:
  - SeparatorStyle.width = 1.0            -> splitter_width (rounded to 1 px min,
                                             widened to a usable grab size)
  - TabBarStyle.height = 24.0             -> tab_height
  - TabStyle.minimum_width = None         -> tab_min_width (a concrete default)
  - OverlayStyle.selection_color = Color32::from_rgb(0,191,255) * 0.5
                                          -> drop_zone (deep-sky-blue, translucent)

Color values: the Rust `Default::default()` palette is the *light* egui look
(WHITE backgrounds, BLACK/DARK_GRAY text, BLACK separators).  `light()` mirrors
that.  `dark()` resolves the same roles against egui's dark Visuals (dark panel
backgrounds, light text, grey separators) — this is what `from_egui` produces
for a dark theme.  The deep-sky-blue drop-zone overlay is preserved verbatim in
both (it is hardcoded in Rust, not theme-derived).

Conventions (DOCK_PORT_SPEC): `out self` init, `comptime` constants,
`ImplicitlyCopyable, Movable`.  Imports only `...rendering_int` for `ColorInt`.
"""

from ...rendering_int import ColorInt


# =============================================================================
# Structural sizes — egui_dock style.rs Default impl
# =============================================================================

comptime DEFAULT_TAB_HEIGHT: Int32 = 24       # TabBarStyle.height = 24.0
comptime DEFAULT_SPLITTER_WIDTH: Int32 = 4     # SeparatorStyle.width=1.0 visual,
                                               # widened to a usable grab target
comptime DEFAULT_TAB_MIN_WIDTH: Int32 = 64     # TabStyle.minimum_width concrete default


# =============================================================================
# DockStyle — flattened port of egui_dock `Style`
# =============================================================================

struct DockStyle(ImplicitlyCopyable, Movable):
    """Resolved colors + sizes for the dock area (flattened port of egui_dock
    `Style` in style.rs).

    Build one with a preset factory: `DockStyle.dark()` or `DockStyle.light()`.
    All colors are concrete `ColorInt` (RGBA 0-255); the dock area draws with
    these directly instead of resolving egui `Visuals` per frame.
    """

    # ----- Tab bar / tabs (TabBarStyle, TabStyle, TabInteractionStyle) -----
    var tab_bar_bg: ColorInt
    """Tab strip background (Rust `TabBarStyle.bg_fill`)."""
    var tab_bg: ColorInt
    """Inactive tab background (Rust `TabStyle.inactive.bg_fill`)."""
    var tab_active_bg: ColorInt
    """Active/focused tab background (Rust `TabStyle.active.bg_fill`)."""
    var tab_text: ColorInt
    """Inactive tab title text (Rust `TabStyle.inactive.text_color`)."""
    var tab_active_text: ColorInt
    """Active tab title text (Rust `TabStyle.active.text_color`)."""

    # ----- Borders / separators (SeparatorStyle, main_surface_border) ------
    var border: ColorInt
    """Body/tab outline color (Rust `TabBarStyle.hline_color` /
    `main_surface_border_stroke`)."""
    var splitter: ColorInt
    """Idle splitter color (Rust `SeparatorStyle.color_idle`)."""
    var splitter_hover: ColorInt
    """Hovered/dragged splitter color (Rust `SeparatorStyle.color_hovered`)."""

    # ----- Drop zone overlay (OverlayStyle) --------------------------------
    var drop_zone: ColorInt
    """Translucent drag-and-drop target highlight (Rust
    `OverlayStyle.selection_color` = deep-sky-blue * 0.5)."""

    # ----- Bodies + buttons (TabBodyStyle, ButtonsStyle) -------------------
    var body_bg: ColorInt
    """Leaf body background (Rust `TabBodyStyle.bg_fill`)."""
    var close_btn: ColorInt
    """Tab close 'x' glyph color (Rust `ButtonsStyle.close_tab_color`)."""

    # ----- Sizes (px) ------------------------------------------------------
    var tab_height: Int32
    """Tab strip height in pixels (Rust `TabBarStyle.height`)."""
    var splitter_width: Int32
    """Splitter thickness/grab width in pixels (Rust `SeparatorStyle.width`)."""
    var tab_min_width: Int32
    """Minimum tab width in pixels (Rust `TabStyle.minimum_width`)."""

    fn __init__(out self,
                tab_bar_bg: ColorInt, tab_bg: ColorInt, tab_active_bg: ColorInt,
                tab_text: ColorInt, tab_active_text: ColorInt,
                border: ColorInt, splitter: ColorInt, splitter_hover: ColorInt,
                drop_zone: ColorInt, body_bg: ColorInt, close_btn: ColorInt,
                tab_height: Int32 = DEFAULT_TAB_HEIGHT,
                splitter_width: Int32 = DEFAULT_SPLITTER_WIDTH,
                tab_min_width: Int32 = DEFAULT_TAB_MIN_WIDTH):
        """Build a style from explicit colors + sizes (used by the presets)."""
        self.tab_bar_bg = tab_bar_bg
        self.tab_bg = tab_bg
        self.tab_active_bg = tab_active_bg
        self.tab_text = tab_text
        self.tab_active_text = tab_active_text
        self.border = border
        self.splitter = splitter
        self.splitter_hover = splitter_hover
        self.drop_zone = drop_zone
        self.body_bg = body_bg
        self.close_btn = close_btn
        self.tab_height = tab_height
        self.splitter_width = splitter_width
        self.tab_min_width = tab_min_width

    fn __init__(out self):
        """Default style — the dark preset (so `DockStyle()` is usable directly,
        e.g. as a `DockAreaInt`'s initial style before `set_style`)."""
        self = DockStyle.dark()

    # =========================================================================
    # Presets
    # =========================================================================

    @staticmethod
    fn dark() -> DockStyle:
        """Dark theme — egui_dock `from_egui` resolved against dark Visuals.

        Dark panel backgrounds, light text, grey separators.  The deep-sky-blue
        drop-zone overlay (Rust `OverlayStyle.selection_color`) is preserved.
        """
        return DockStyle(
            ColorInt(30, 30, 30, 255),        # tab_bar_bg (dark strip)
            ColorInt(40, 40, 40, 255),        # tab_bg (inactive)
            ColorInt(60, 60, 64, 255),        # tab_active_bg
            ColorInt(170, 170, 170, 255),     # tab_text (inactive, dim)
            ColorInt(240, 240, 240, 255),     # tab_active_text (bright)
            ColorInt(20, 20, 20, 255),        # border (dark outline)
            ColorInt(20, 20, 20, 255),        # splitter (idle, dim)
            ColorInt(150, 150, 150, 255),     # splitter_hover (bright grey)
            ColorInt(0, 191, 255, 96),        # drop_zone (deep-sky-blue, ~0.5 alpha)
            ColorInt(27, 27, 27, 255),        # body_bg (extreme_bg dark)
            ColorInt(230, 230, 230, 255),     # close_btn (light glyph)
        )

    @staticmethod
    fn light() -> DockStyle:
        """Light theme — egui_dock `Style::default()` palette.

        Mirrors the Rust `Default` impl: WHITE backgrounds, BLACK/DARK_GRAY
        text, BLACK separators, GRAY hover.  Same deep-sky-blue drop zone.
        """
        return DockStyle(
            ColorInt(255, 255, 255, 255),     # tab_bar_bg (WHITE)
            ColorInt(255, 255, 255, 255),     # tab_bg (WHITE, inactive)
            ColorInt(255, 255, 255, 255),     # tab_active_bg (WHITE)
            ColorInt(96, 96, 96, 255),        # tab_text (DARK_GRAY, inactive)
            ColorInt(0, 0, 0, 255),           # tab_active_text (BLACK)
            ColorInt(0, 0, 0, 255),           # border (hline BLACK)
            ColorInt(0, 0, 0, 255),           # splitter (color_idle BLACK)
            ColorInt(128, 128, 128, 255),     # splitter_hover (color_hovered GRAY)
            ColorInt(0, 191, 255, 96),        # drop_zone (deep-sky-blue, ~0.5 alpha)
            ColorInt(255, 255, 255, 255),     # body_bg (WHITE)
            ColorInt(255, 255, 255, 255),     # close_btn (close_tab_color WHITE)
        )
