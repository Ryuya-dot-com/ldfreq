"""Independent 80-digit references for the near-saturation D regression.

Development only: requires mpmath; not a package/runtime dependency.
python3 development/verify-expected-ttr-d.py
"""
import mpmath as mp

mp.mp.dps = 80
for population in (10000, 100000, 1000000):
    N = mp.mpf(population)
    sizes = [mp.mpf(n) for n in range(35, 51)]
    # One doubleton and N-2 singletons. A duplicate reduces the sample's
    # distinct count by one with probability n(n-1)/(N(N-1)).
    targets = [1 - (n - 1) / (N * (N - 1)) for n in sizes]
    pointwise = [n * y * y / (2 * (1 - y)) for n, y in zip(sizes, targets)]

    def derivative(D):
        result = mp.mpf(0)
        for n, y in zip(sizes, targets):
            root = mp.sqrt(1 + 2 * n / D)
            fitted = 2 / (root + 1)
            result += 2 * (fitted - y) * 2 * n / (D * root * (root + 1)**2)
        return result

    # Independent linear-D bisection and high-precision near-one subtraction.
    low, high = min(pointwise), max(pointwise)
    for _ in range(300):
        mid = (low + high) / 2
        if derivative(mid) < 0:
            low = mid
        else:
            high = mid
    print(f"N={population}, D_reference={mp.nstr((low + high) / 2, 30)}")
