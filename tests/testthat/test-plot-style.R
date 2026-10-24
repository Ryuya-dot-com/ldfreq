plot_style_examples <- function() {
  documents <- list(short = c("a", "b", "a"), long = rep(c("a", "b", "c"), 40))
  plan <- lexdiv_plan(presets = character(), grids = lexdiv_grid(
    "mattr_sliding_step1_v1", parameter = "window_length", values = 3
  ))
  batch <- lexdiv_profile_batch(documents, plan)
  list(
    metric = lexdiv_metrics(documents$short, metrics = "mattr", window_length = 3),
    batch = lexdiv_metrics_batch(documents, metrics = "mattr", window_length = 3),
    profile = lexdiv_profile(documents$short, plan),
    profile_batch = batch,
    text = lexdiv_metrics_text("a b a", metrics = "mattr", window_length = 3),
    text_batch = lexdiv_metrics_text_batch(c(short = "a b a", long = "a b c a"),
      metrics = "mattr", window_length = 3),
    screen = lexdiv_screen(batch, floors = c(tokens_50 = 50L)),
    tubelex = structure(list(summary = data.frame(weighting = c("token", "type"),
      coverage = c(.75, .5))), class = "tubelex_profile"),
    levels = nj8_profile(c("a", "b", "unknown"),
      wordlist = data.frame(NJ8 = c(1, 1001), Word = c("a", "b"))),
    mattr = lexdiv_mattr_profile(c("a", "b", "a", "c", "d"), plan),
    reference = lexdiv_reference_coverage(documents, c("a", "b"))
  )
}

test_that("every plot mode preserves selected data and validates its switch", {
  path <- tempfile(fileext = ".pdf")
  grDevices::pdf(path)
  on.exit({ grDevices::dev.off(); unlink(path) }, add = TRUE)
  style_names <- c("bty", "las", "family", "tcl", "mgp")
  graphics::par(bty = "o", las = 3, family = "serif")
  saved_style <- graphics::par(style_names)
  for (x in plot_style_examples()) {
    color <- withVisible(plot(x))
    mono <- withVisible(plot(x, monochrome = TRUE))
    expect_false(color$visible)
    expect_false(mono$visible)
    expect_identical(mono$value, color$value)
    expect_identical(plot(x, monochrome = FALSE), color$value)
    expect_identical(graphics::par(style_names), saved_style)
    for (bad in list(NA, 1, "TRUE", c(TRUE, FALSE), logical())) {
      expect_error(plot(x, monochrome = bad), "monochrome")
    }
  }
})

test_that("graphics receive color defaults and distinguish monochrome series", {
  # Capture the actual graphics calls, including overlays and legends, without
  # making output depend on a platform's rasterizer or font metrics.
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  calls <- list()
  capture <- function(kind, args) {
    calls[[length(calls) + 1L]] <<- c(list(kind = kind,
      style = graphics::par(c("bty", "las", "family"))), args)
    invisible(NULL)
  }
  local_mocked_bindings(
    .lex_plot = function(...) capture("plot", list(...)),
    barplot = function(height, ...) {
      capture("barplot", c(list(height = height), list(...)))
      seq_along(height)
    },
    lines = function(...) capture("lines", list(...)),
    abline = function(...) capture("abline", list(...)),
    legend = function(...) capture("legend", list(...)),
    axis = function(...) invisible(NULL),
    .package = "ldfreq"
  )
  examples <- plot_style_examples()
  for (x in examples) {
    calls <- list()
    plot(x)
    expect_null(calls[[1L]]$main)
    expect_identical(calls[[1L]]$style, list(bty = "l", las = 1L, family = "sans"))
    colors <- unlist(lapply(calls, function(z) z$col), use.names = FALSE)
    rgb <- grDevices::col2rgb(colors)
    expect_true(any(rgb[1, ] != rgb[2, ] | rgb[2, ] != rgb[3, ]))
    calls <- list()
    plot(x, monochrome = TRUE)
    expect_null(calls[[1L]]$main)
    colors <- unlist(lapply(calls, function(z) z$col), use.names = FALSE)
    rgb <- grDevices::col2rgb(colors)
    expect_true(all(rgb[1, ] == rgb[2, ] & rgb[2, ] == rgb[3, ]))
  }
  for (x in examples[c("batch", "profile_batch", "screen")]) {
    calls <- list()
    plot(x)
    expect_equal(calls[[1L]]$pch, c(17, 19))
    calls <- list()
    plot(x, monochrome = TRUE)
    expect_equal(calls[[1L]]$pch, c(17, 19))
    calls <- list()
    plot(x, monochrome = TRUE, col = "red", pch = 4, main = "Explicit title")
    expect_identical(calls[[1L]]$col, "black")
    expect_equal(calls[[1L]]$pch, 4)
    expect_identical(calls[[1L]]$main, "Explicit title")
    calls <- list()
    plot(x, col = "purple")
    expect_identical(calls[[1L]]$col, "purple")
  }
  calls <- list()
  plot(examples$mattr, monochrome = TRUE, col = "red", mean_col = "blue")
  expect_identical(calls[[1L]]$col, "black")
  expect_identical(calls[[2L]]$col, "black")
  expect_equal(calls[[2L]]$lty, 2)
  calls <- list()
  plot(examples$levels, monochrome = TRUE, col = "red", cumulative_col = "blue")
  expect_false(calls[[1L]]$col[[1L]] == tail(calls[[1L]]$col, 1L))
  expect_identical(calls[[1L]]$border, "black")
  expect_identical(calls[[2L]]$col, "black")
  expect_identical(calls[[3L]]$col, c("grey70", "black"))
  expect_identical(calls[[1L]]$names.arg, c(as.character(1:8), "Off-list"))
  expect_identical(calls[[1L]]$yaxt, "n")
  calls <- list()
  plot(examples$batch, family = "mono", las = 2, bty = "u")
  expect_identical(calls[[1L]]$style, list(bty = "u", las = 2L, family = "mono"))
  calls <- list()
  plot(examples$levels, axes = FALSE, show_legend = FALSE)
  expect_false(calls[[1L]]$axes)
  expect_null(calls[[1L]]$yaxt)
})

test_that("empty proportions are not plotted as zeros and style survives errors", {
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  examples <- plot_style_examples()
  before <- graphics::par(c("bty", "las", "family", "tcl", "mgp"))
  expect_error(plot(examples$batch, col = "not-a-color"), "color")
  expect_identical(graphics::par(names(before)), before)
  expect_error(plot(examples$batch, las = 99), "las")
  expect_identical(graphics::par(names(before)), before)
  empty <- nj8_profile(character(), wordlist = data.frame(NJ8 = 1, Word = "a"))
  expect_error(plot(empty), "no finite values")
  count_rows <- plot(empty, scale = "count")
  expect_true(all(count_rows$exact_plot_value == 0))
})

test_that("narrow NJ8 plots retain every category label without shrinking text", {
  grDevices::pdf(NULL, width = 3.25, height = 3.2, pointsize = 11)
  on.exit(grDevices::dev.off(), add = TRUE)
  graphics::par(mar = c(4.2, 4.5, 1, .5))
  seen <- NULL
  original_axis <- graphics::axis
  local_mocked_bindings(axis = function(side, at = NULL, labels = TRUE, ...) {
    if (side == 1) seen <<- c(list(at = at, labels = labels), list(...))
    original_axis(side = side, at = at, labels = labels, ...)
  }, .package = "ldfreq")
  x <- nj8_profile(c("a", "unknown"), wordlist = data.frame(NJ8 = 1, Word = "a"))
  plot(x)
  expect_identical(seen$labels, c(as.character(1:8), "Off-\nlist"))
  expect_equal(seen$cex.axis, 1)
  expect_equal(tail(seen$padj, 1), 1)
  seen <- NULL
  plot(x, axisnames = FALSE)
  expect_null(seen)
})

test_that("manual axes honor switches and text settings without changing results", {
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  original_axis <- graphics::axis
  seen <- list()
  local_mocked_bindings(axis = function(...) {
    seen[[length(seen) + 1L]] <<- graphics::par(c("cex.axis", "col.axis", "font.axis"))
    original_axis(...)
  }, .package = "ldfreq")
  examples <- plot_style_examples()
  for (x in examples[c("metric", "batch", "profile", "profile_batch",
                      "text", "text_batch", "screen", "reference", "levels")]) {
    original <- plot(x)
    seen <- list()
    expect_identical(plot(x, axes = FALSE), original)
    expect_length(seen, 0L)
    seen <- list()
    # Suppress both axes so NJ8's proportion axis is also excluded here.
    expect_identical(plot(x, xaxt = "n", yaxt = "n"), original)
    expect_length(seen, 0L)
    before <- graphics::par(c("cex.axis", "col.axis", "font.axis"))
    seen <- list()
    plot(x, cex.axis = .7, col.axis = "purple", font.axis = 2)
    expect_true(length(seen) > 0L)
    expect_identical(seen[[1L]], list(cex.axis = .7, col.axis = "purple", font.axis = 2L))
    expect_identical(graphics::par(names(before)), before)
  }
})

test_that("bar arguments cannot corrupt geometry and NJ8 colors match the legend", {
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  examples <- plot_style_examples()
  before <- graphics::par(c("bty", "las", "family"))
  for (x in examples[c("levels", "tubelex")]) {
    invalid <- list(horiz = TRUE, height = 1, offset = 1, add = TRUE,
      log = "y", plot = FALSE)
    for (name in names(invalid)) {
      expect_error(do.call(plot, c(list(x = x), invalid[name])),
        paste0("Unsupported bar-plot argument.*", name))
    }
  }
  expect_error(plot(examples$tubelex, ylim = c(0, .8)), "Unsupported.*ylim")
  expect_error(plot(examples$tubelex, names.arg = c("a", "b")), "Unsupported.*names.arg")
  expect_error(plot(examples$levels, bar_col = "red"), "bar_col has been replaced by col")
  expect_error(plot(examples$levels, col = c("red", "blue")), "one color")
  expect_identical(graphics::par(names(before)), before)
  bars <- legend_colors <- NULL
  original_barplot <- graphics::barplot
  original_legend <- graphics::legend
  local_mocked_bindings(
    barplot = function(...) {
      bars <<- list(...)
      original_barplot(...)
    },
    legend = function(...) {
      legend_colors <<- list(...)$col
      original_legend(...)
    }, .package = "ldfreq")
  plot(examples$levels, col = "purple", cumulative_col = "orange")
  expect_true(all(head(bars$col, -1) == "purple"))
  expect_identical(tail(bars$col, 1), "#B8B8B8")
  expect_identical(legend_colors, c("purple", "orange"))
  plot(examples$levels, monochrome = TRUE, col = "red", border = "red",
    cumulative_col = "blue")
  expect_true(all(head(bars$col, -1) == "grey70"))
  expect_identical(tail(bars$col, 1), "grey90")
  expect_identical(bars$border, "black")
  expect_identical(legend_colors, c("grey70", "black"))
})
