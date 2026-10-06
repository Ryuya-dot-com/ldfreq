# Plot one local MATTR trajectory

Plot one local MATTR trajectory

## Usage

``` r
# S3 method for class 'lexdiv_mattr_profile'
plot(
  x,
  request_id = NULL,
  add_global_mean = TRUE,
  col = "#0072B2",
  lwd = 2,
  type = "l",
  main = NULL,
  xlab = "Window midpoint (token position)",
  ylab = "Local TTR",
  ylim = c(0, 1),
  mean_col = "#D55E00",
  mean_lty = 2,
  ...,
  monochrome = FALSE
)
```

## Arguments

- x:

  A `lexdiv_mattr_profile` object.

- request_id:

  One request ID. It may be omitted only when the plan has a single
  specification.

- add_global_mean:

  One `TRUE` or `FALSE` value indicating whether to add the canonical
  MATTR value as a horizontal line.

- col, lwd, type, main, xlab, ylab, ylim:

  Base-graphics settings.

- mean_col, mean_lty:

  Settings for the global-mean line.

- monochrome:

  One `TRUE` or `FALSE` value; specify by name. Defaults to color;
  `TRUE` overrides `col` and `mean_col` with black. Line types are
  retained, including the dashed mean line. No title is added
  automatically; place figure titles and notes outside the image.

- ...:

  Additional arguments passed to
  [`graphics::plot()`](https://rdrr.io/r/graphics/plot.default.html).

## Value

Invisibly, the exact window rows displayed.

## Details

Plot defaults use a sans serif font, horizontal tick labels and an open
frame. Override these with `family`, `las` or `bty` in the plot method's
`...`. Cosmetic graphics parameters are restored after drawing.

The x-axis uses each complete window's midpoint and the y-axis uses its
local TTR. By default, the canonical whole-profile MATTR value is drawn
as a dashed horizontal line. When a plan contains several window
lengths, select exactly one trajectory by its `request_id`. The returned
rows can be reused in custom graphics without parsing the displayed
plot.
