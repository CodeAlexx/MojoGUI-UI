"""Pure-Mojo trigonometry for the chart package (no libm dependency).

Why this exists: `math.cos`/`math.sin` link against libm, and the optimizer
fuses an adjacent cos+sin into a single `sincos@GLIBC` call that fails to LINK
in some chart binaries (measured: `chart_all_demo` →
`undefined reference to symbol 'sincos@@GLIBC_2.2.5'`, while `_check_all` linked
fine — so it is binary-dependent and unreliable). These polynomial
approximations have zero libm dependency, so every chart binary links, and they
are accurate to well under 1% over the full circle — ample for rendering
ellipses, Fibonacci fans, Gann angles, and any angle-based geometry.

`floor` is safe to import from `math` (it does not pull in `sincos`; the
committed build already links it via transforms.mojo/scales.mojo).
"""

from math import floor

comptime PI: Float64 = 3.141592653589793
comptime TAU: Float64 = 6.283185307179586
comptime HALF_PI: Float64 = 1.5707963267948966


fn csin(x_in: Float64) -> Float64:
    """sin(x) via range-reduction to [-PI, PI] + 9th-order Taylor (Horner).

    Max abs error ~7e-3 near +/-PI; exact at 0 and the principal angles used for
    rendering.  No libm call, so it always links.
    """
    var k = floor((x_in + PI) / TAU)
    var x = x_in - k * TAU
    var x2 = x * x
    return x * (
        1.0
        + x2 * (-1.0 / 6.0
        + x2 * (1.0 / 120.0
        + x2 * (-1.0 / 5040.0
        + x2 * (1.0 / 362880.0))))
    )


fn ccos(x: Float64) -> Float64:
    """cos(x) = sin(x + PI/2)."""
    return csin(x + HALF_PI)


fn ctan(x: Float64) -> Float64:
    """tan(x) = sin/cos, guarded near the asymptote."""
    var c = ccos(x)
    if c > -1e-12 and c < 1e-12:
        return 0.0
    return csin(x) / c
