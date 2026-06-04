"""
Chart theme presets — faithful port of egui-charts `src/theme/`.

Ported from:
  - /tmp/egui-charts-ref/src/theme/presets.rs          -> ThemePreset (preset enum + names)
  - /tmp/egui-charts-ref/src/theme/semantic.rs         -> ChartSemanticTokens resolution
  - /tmp/egui-charts-ref/src/tokens/design_tokens.ron  -> resolved color values

In the Rust crate the chart colors live in DESIGN_TOKENS (a RON file) and are
resolved per-preset by `ChartSemanticTokens::from_design_tokens(is_dark_chart)`.
Crucially, in Rust **only the `Light` preset uses the light-chart palette** —
Classic / Dark / Midnight / HighContrast all share the SAME dark-chart colors
(they differ only in UI chrome, which has no MojoGUI equivalent and is skipped
in phase 1).  `ChartTheme` flattens the resolved tokens into concrete `ColorInt`
fields so renderers/engine draw without a token lookup.

Field set is fixed by INTEGRATION_CONTRACT.md (consumed by renderers RenderView
and ChartInt): background, grid, axis, text, bull, bear, wick, crosshair, line,
area_fill, baseline.

Documented divergence: `midnight()` and `high_contrast()` are given a distinct
chart character (darker background / pure-black + brighter accents) so the demo
can visibly cycle themes.  The Rust originals resolve to the same dark-chart
palette as `dark()`; noted on each preset.

Conventions (model.mojo / PORT_SPEC "VERIFIED CONVENTIONS"): `out self` init,
`comptime` enum constants, `ImplicitlyCopyable, Movable`.  Imports only
`...rendering_int` for `ColorInt` (no engine/renderers imports — one-way deps).
"""

from ...rendering_int import ColorInt


# =============================================================================
# ThemePreset — port of theme/presets.rs  (enum ThemePreset)
# =============================================================================
# Order matches the Rust `ThemePreset` declaration (presets.rs lines 15-27).
# `Classic` is the Rust `#[default]`.

comptime TP_CLASSIC: Int32 = 0          # default — light UI chrome + dark chart
comptime TP_DARK: Int32 = 1             # full dark theme
comptime TP_LIGHT: Int32 = 2            # full light theme
comptime TP_MIDNIGHT: Int32 = 3         # midnight blue (dark UI + dark chart)
comptime TP_HIGH_CONTRAST: Int32 = 4    # accessibility (dark UI + dark chart)

comptime THEME_PRESET_COUNT: Int32 = 5
"""Total number of theme presets (theme/presets.rs `ThemePreset::all`)."""


fn theme_preset_name(preset: Int32) -> String:
    """Persistence name for a preset (port of `ThemePreset::name`)."""
    if preset == TP_CLASSIC:        return String("classic")
    if preset == TP_DARK:           return String("dark")
    if preset == TP_LIGHT:          return String("light")
    if preset == TP_MIDNIGHT:       return String("midnight")
    if preset == TP_HIGH_CONTRAST:  return String("high_contrast")
    return String("classic")


fn theme_preset_display_name(preset: Int32) -> String:
    """UI display name for a preset (port of `ThemePreset::display_name`)."""
    if preset == TP_CLASSIC:        return String("Classic")
    if preset == TP_DARK:           return String("Dark")
    if preset == TP_LIGHT:          return String("Light")
    if preset == TP_MIDNIGHT:       return String("Midnight")
    if preset == TP_HIGH_CONTRAST:  return String("High Contrast")
    return String("Classic")


# =============================================================================
# ChartTheme — flattened port of theme/semantic.rs::ChartSemanticTokens
# =============================================================================

struct ChartTheme(ImplicitlyCopyable, Movable):
    """Resolved chart colors for a single preset (port of
    `ChartSemanticTokens` in theme/semantic.rs).

    Field set fixed by INTEGRATION_CONTRACT.md.  Every field is a concrete
    `ColorInt` resolved from DESIGN_TOKENS for the preset's light/dark mode.
    Build one with a preset factory: `ChartTheme.dark()`, `.light()`,
    `.midnight()`, `.classic()`, `.high_contrast()`.
    """

    var preset: Int32
    """The `TP_*` preset id this theme was built from."""

    var background: ColorInt
    """Chart plot-area background (Rust `chart.bg`)."""
    var grid: ColorInt
    """Grid line color (Rust `chart.grid_line`)."""
    var axis: ColorInt
    """Axis line / tick color (Rust `chart.axis_text`)."""
    var text: ColorInt
    """Axis / label text (Rust `chart.axis_text`)."""
    var bull: ColorInt
    """Bullish (up) candle/bar body (Rust `chart.bullish` = green_400)."""
    var bear: ColorInt
    """Bearish (down) candle/bar body (Rust `chart.bearish` = red_400)."""
    var wick: ColorInt
    """Candle wick color (Rust resolves wick == body; a neutral grey is used
    here so wicks read on both bull and bear candles)."""
    var crosshair: ColorInt
    """Crosshair line color (Rust `chart.crosshair_line`)."""
    var line: ColorInt
    """Line / step / baseline series stroke (Rust `chart.price_line`)."""
    var area_fill: ColorInt
    """Area-fill color under a line/area series (Rust `chart.bullish_fill`)."""
    var baseline: ColorInt
    """Baseline reference level for Baseline charts (Rust `chart.grid_line_major`)."""

    fn __init__(out self, preset: Int32,
                background: ColorInt, grid: ColorInt, axis: ColorInt,
                text: ColorInt, bull: ColorInt, bear: ColorInt, wick: ColorInt,
                crosshair: ColorInt, line: ColorInt, area_fill: ColorInt,
                baseline: ColorInt):
        """Build a theme from explicit resolved colors (used by the presets)."""
        self.preset = preset
        self.background = background
        self.grid = grid
        self.axis = axis
        self.text = text
        self.bull = bull
        self.bear = bear
        self.wick = wick
        self.crosshair = crosshair
        self.line = line
        self.area_fill = area_fill
        self.baseline = baseline

    # =========================================================================
    # Presets — resolved from design_tokens.ron
    # =========================================================================
    # Sacred trading palette (never changes across presets):
    #   bullish = green_400 = (38, 166, 154)   bearish = red_400 = (239, 83, 80)
    #   bullish_fill = (38, 166, 154, 50)

    @staticmethod
    fn dark() -> ChartTheme:
        """Full dark theme — the dark-chart palette from DESIGN_TOKENS.

        Resolved values (semantic.rs `is_dark_chart == true`):
          bg=gray_950(19,23,34)  grid_line=(255,255,255,12)
          axis_text=(209,212,220)  crosshair_line=(178,181,190,120)
          bullish=green_400  bearish=red_400  price_line=axis_text
          bullish_fill=(38,166,154,50)  grid_line_major=(255,255,255,18)
        """
        return ChartTheme(
            TP_DARK,
            ColorInt(19, 23, 34, 255),        # background (gray_950)
            ColorInt(255, 255, 255, 12),      # grid
            ColorInt(209, 212, 220, 255),     # axis (axis_text)
            ColorInt(209, 212, 220, 255),     # text (axis_text)
            ColorInt(38, 166, 154, 255),      # bull (green_400)
            ColorInt(239, 83, 80, 255),       # bear (red_400)
            ColorInt(178, 181, 190, 255),     # wick (neutral grey)
            ColorInt(178, 181, 190, 120),     # crosshair (crosshair_line)
            ColorInt(209, 212, 220, 255),     # line (price_line == axis_text)
            ColorInt(38, 166, 154, 50),       # area_fill (bullish_fill)
            ColorInt(255, 255, 255, 18),      # baseline (grid_line_major)
        )

    @staticmethod
    fn classic() -> ChartTheme:
        """Classic theme — light UI chrome + dark chart (Rust `#[default]`).

        The chart area resolves to the SAME dark-chart palette as `dark()`
        (Rust `is_dark_chart` is true for Classic); only the surrounding UI
        chrome differs, which is out of scope for phase 1.  `preset` records
        that this is Classic.
        """
        var t = ChartTheme.dark()
        t.preset = TP_CLASSIC
        return t

    @staticmethod
    fn light() -> ChartTheme:
        """Full light theme — the light-chart palette from DESIGN_TOKENS.

        Resolved values (semantic.rs `is_dark_chart == false`):
          bg=white(255,255,255)  grid_line_light=(0,0,0,12)
          axis_text=text_light=gray_950(19,23,34)
          crosshair_line_light=(120,120,120,150)  price_line=text_light
          bullish/bearish unchanged  bullish_fill=(38,166,154,50)
        """
        return ChartTheme(
            TP_LIGHT,
            ColorInt(255, 255, 255, 255),     # background (white)
            ColorInt(0, 0, 0, 12),            # grid (grid_line_light)
            ColorInt(19, 23, 34, 255),        # axis (text_light)
            ColorInt(19, 23, 34, 255),        # text (text_light)
            ColorInt(38, 166, 154, 255),      # bull (green_400)
            ColorInt(239, 83, 80, 255),       # bear (red_400)
            ColorInt(80, 84, 92, 255),        # wick (dark grey on light bg)
            ColorInt(120, 120, 120, 150),     # crosshair (crosshair_line_light)
            ColorInt(19, 23, 34, 255),        # line (price_line == text_light)
            ColorInt(38, 166, 154, 50),       # area_fill (bullish_fill)
            ColorInt(0, 0, 0, 20),            # baseline (grid_line_major_light)
        )

    @staticmethod
    fn midnight() -> ChartTheme:
        """Midnight blue theme.

        Documented divergence: Rust resolves Midnight to the same dark-chart
        palette as `dark()`.  Here the background is darkened to a deep navy so
        the preset is visibly distinct when the demo cycles themes; the sacred
        trading palette and text colors stay identical to `dark()`.
        """
        var t = ChartTheme.dark()
        t.preset = TP_MIDNIGHT
        t.background = ColorInt(8, 12, 24, 255)   # deep navy plot area
        return t

    @staticmethod
    fn high_contrast() -> ChartTheme:
        """High-contrast accessibility theme.

        Documented divergence: Rust resolves HighContrast to the same dark-chart
        palette as `dark()` (only UI chrome changes).  Here the chart is pushed
        to pure black with brighter white text/grid for WCAG contrast, while
        keeping the sacred bullish/bearish hues.  Tagged `TP_HIGH_CONTRAST`.
        """
        return ChartTheme(
            TP_HIGH_CONTRAST,
            ColorInt(0, 0, 0, 255),           # background (pure black)
            ColorInt(255, 255, 255, 40),      # grid (brighter for contrast)
            ColorInt(255, 255, 255, 255),     # axis (white)
            ColorInt(255, 255, 255, 255),     # text (white)
            ColorInt(38, 166, 154, 255),      # bull (green_400, sacred)
            ColorInt(239, 83, 80, 255),       # bear (red_400, sacred)
            ColorInt(255, 255, 255, 255),     # wick (white)
            ColorInt(255, 255, 0, 200),       # crosshair (high-vis yellow)
            ColorInt(255, 255, 255, 255),     # line (white)
            ColorInt(38, 166, 154, 60),       # area_fill
            ColorInt(255, 255, 255, 70),      # baseline
        )

    @staticmethod
    fn from_preset(preset: Int32) -> ChartTheme:
        """Build a theme from a `TP_*` preset id (port of `Theme::from_preset`)."""
        if preset == TP_DARK:           return ChartTheme.dark()
        if preset == TP_LIGHT:          return ChartTheme.light()
        if preset == TP_MIDNIGHT:       return ChartTheme.midnight()
        if preset == TP_HIGH_CONTRAST:  return ChartTheme.high_contrast()
        return ChartTheme.classic()  # TP_CLASSIC and any unknown -> default
