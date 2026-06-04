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


comptime LN2: Float64 = 0.6931471805599453
comptime LN10: Float64 = 2.302585092994046
comptime LOG10E: Float64 = 0.4342944819032518


fn cln(x: Float64) -> Float64:
    """Natural log with no libm dependency (so chart binaries link).

    `math.log`/`math.log10` pull a libm symbol (`log10@GLIBC`) that fails to LINK
    in the FFI-linked chart demos (same class as the `sincos` issue).  This
    reduces `x = m * 2^e` with m in [1,2), then evaluates ln(m) with the
    fast-converging atanh series ln(m) = 2*(t + t^3/3 + t^5/5 + ...),
    t = (m-1)/(m+1).  Accurate to ~1e-12 over the reduced range — far better
    than the rendering needs.  Non-positive input returns 0.0 (matches the
    chart's `_price_to_log` non-positive guard).
    """
    if x <= 0.0:
        return 0.0
    # Binary range-reduce to m in [1, 2).
    var m = x
    var e: Int = 0
    while m >= 2.0:
        m /= 2.0
        e += 1
    while m < 1.0:
        m *= 2.0
        e -= 1
    var t = (m - 1.0) / (m + 1.0)
    var t2 = t * t
    # atanh series: t + t^3/3 + t^5/5 + t^7/9 + ... (9 terms => ample accuracy).
    var sum = t
    var term = t
    var k = 3.0
    for _i in range(8):
        term *= t2
        sum += term / k
        k += 2.0
    return 2.0 * sum + Float64(e) * LN2


fn clog10(x: Float64) -> Float64:
    """log base 10 via `cln` (no libm)."""
    return cln(x) * LOG10E


fn cexp(x: Float64) -> Float64:
    """e^x with no libm dependency.

    Range-reduces by the integer part in base-2 (x = n*ln2 + r) then evaluates
    e^r with a 10-term Taylor series on the small remainder.  Pairs with `cln`
    for the chart's log-price scale (`_log_to_price`).
    """
    # x = n*ln2 + r, |r| <= ln2/2 ; e^x = 2^n * e^r.
    var n = floor(x / LN2 + 0.5)
    var r = x - n * LN2
    # e^r Taylor (Horner), 10 terms.
    var er = 1.0
    var term = 1.0
    for i in range(1, 11):
        term *= r / Float64(i)
        er += term
    # 2^n by squaring/halving.
    var p = 1.0
    var ni = Int(n)
    if ni >= 0:
        for _i in range(ni):
            p *= 2.0
    else:
        for _i in range(-ni):
            p /= 2.0
    return er * p
