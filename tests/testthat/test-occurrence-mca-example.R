mca_example <- function() {
  e <- new.env(parent = globalenv())
  sys.source(system.file("examples", "occurrence-mca-demo.R", package = "ldfreq", mustWork = TRUE), e)
  e
}

mca_table_again <- function(e, occurrences = e$occurrences, definitions = e$definitions, ...) {
  e$helper$ordination_mca_table(e$annotations, occurrences, definitions, "test-coding", ...)
}

test_that("MCA input preserves missing codes, levels, metadata and source anchors", {
  e <- mca_example(); x <- e$tab
  expect_equal(dim(x$indicator), c(15, 7))
  expect_equal(unname(rowSums(x$indicator)), rep(3, 15))
  expect_equal(x$observations$active, c(rep(TRUE, 15), FALSE, FALSE))
  expect_identical(x$occurrences, e$occurrences)
  expect_equal(x$variables$missing_n, c(1, 1, 0))
  expect_equal(x$categories$observed_n[x$categories$level == "unused-sense"], 0)
  hits <- e$helper$ordination_mca_occurrences(x, c("u17", "u01"))
  expect_equal(hits$source_text, e$text[c(17, 1)])
  expect_equal(stringi::stri_sub(hits$source_text, hits$start, hits$end), c("bank", "bank"))
  changed <- e$occurrences; changed$start[1] <- changed$start[1] + 1
  expect_error(mca_table_again(e, changed), "anchors")
  expect_error(mca_table_again(e, rbind(e$occurrences, e$occurrences[1, ])), "unique")
  expect_error(mca_table_again(e, max_cells = 104), "max_cells")
  changed <- e$occurrences; changed$sense <- as.character(changed$sense); changed$sense[1] <- " "
  expect_error(mca_table_again(e, changed), "nonblank")
  changed$sense <- seq_len(nrow(changed))
  expect_error(mca_table_again(e, changed), "character or unordered")
  expect_error(mca_table_again(e, definitions = e$definitions[1]), "at least two")
  expect_error(mca_table_again(e, definitions = c(occurrence_id = "ID", role = "Role")), "source IDs")
  changed <- x; changed$occurrences$writer_id[1] <- "edited"
  expect_error(e$helper$ordination_validate(changed), "changed")
  path <- tempfile(fileext = ".rds"); on.exit(unlink(path))
  saveRDS(e$record, path, version = 2)
  expect_identical(readRDS(path), e$record)
})

test_that("MCA geometry agrees with independent standardized-residual SVD", {
  skip_if_not_installed("ca")
  e <- mca_example(); x <- e$tab
  fit <- e$helper$ordination_mca(x, k = 100)
  z <- x$indicator; p <- z / sum(z); r <- rowSums(p); c <- colSums(p)
  s <- (p - outer(r, c)) / sqrt(outer(r, c)); ref <- svd(s)
  positive <- ref$d > 1e-8; d <- ref$d[positive]
  f <- sweep(sweep(ref$u[, positive, drop = FALSE], 1, sqrt(r), "/"), 2, d, "*")
  g <- sweep(sweep(ref$v[, positive, drop = FALSE], 1, sqrt(c), "/"), 2, d, "*")
  rows <- matrix(fit$rows$coordinate, nrow(z)); cols <- matrix(fit$categories$coordinate, ncol(z))
  expect_equal(unname(tcrossprod(rows)), unname(tcrossprod(f)), tolerance = 1e-10)
  expect_equal(unname(tcrossprod(cols)), unname(tcrossprod(g)), tolerance = 1e-10)
  expect_equal(fit$axes$eigenvalue[positive], d^2, tolerance = 1e-10)
  expect_equal(fit$diagnostics$total_inertia, 4/3, tolerance = 1e-10)
  expect_equal(fit$diagnostics$indicator_inertia, 4/3)
  expect_equal(fit$rows$mass, rep(1/15, nrow(fit$rows)))
  expect_equal(colSums(matrix(fit$rows$contribution, nrow(z))), rep(1, length(d)), tolerance = 1e-10)
  expect_equal(colSums(matrix(fit$categories$contribution, ncol(z))), rep(1, length(d)), tolerance = 1e-10)
  expect_equal(rowSums(matrix(fit$rows$cos2, nrow(z))), rep(1, nrow(z)), tolerance = 1e-10)
  expect_equal(rowSums(matrix(fit$categories$cos2, ncol(z))), rep(1, ncol(z)), tolerance = 1e-10)
  expect_equal(fit$rows$distance[seq_len(nrow(z))]^2, unname(rowSums(s^2)/r), tolerance = 1e-10)
  expect_true(e$result$diagnostics$cut_through_tied_axes)
  expect_false(fit$diagnostics$cut_through_tied_axes)
  expect_equal(e$result$diagnostics$retained_fraction, sum(d[1:2]^2)/(4/3))
  # Relabel and reorder without comparing arbitrary orientations of repeated axes.
  altered <- e$occurrences[nrow(e$occurrences):1, ]
  altered$sense <- factor(ifelse(is.na(altered$sense), NA, ifelse(altered$sense == "finance", "subject", "oblique")))
  again <- e$helper$ordination_mca(mca_table_again(e, altered), k = 100)
  reordered <- matrix(again$rows$coordinate, nrow(z))[nrow(z):1, , drop = FALSE]
  expect_equal(tcrossprod(reordered), tcrossprod(rows), tolerance = 1e-10)
  # An independent Japanese source exercises Unicode anchors and same labels in different variables.
  if (isTRUE(l10n_info()[["UTF-8"]])) {
    annotation <- e$annotations$provenance$annotation; annotation$language <- "ja"
    a <- lexdiv_import_annotations(data.frame(document_id = "ja", segment_id = "s1", token_index = 1:4,
      surface = c("橋", "箸", "橋", "箸")), data.frame(document_id = "ja", segment_id = "s1", text = "橋 箸 橋 箸"),
      annotation)
    o <- a$tokens[c("document_id", "segment_id", "token_index", "start", "end", "surface")]
    o$occurrence_id <- letters[1:4]; o$reading <- c("a", "b", "a", "b"); o$usage <- c("a", "b", "a", "b")
    t <- e$helper$ordination_mca_table(a, o, c(reading = "Authored", usage = "Authored"), "authored-ja")
    j <- e$helper$ordination_mca(t)
    expect_equal(j$diagnostics$effective_dimensions, 1)
    expect_equal(j$diagnostics$total_inertia, 1)
    expect_equal(nrow(t$categories), 4)
  }
})

test_that("degenerate MCA inputs retain audits and maps expose repeated axes", {
  skip_if_not_installed("ca")
  e <- mca_example(); changed <- e$occurrences
  changed$sense <- rep(NA_character_, nrow(changed))
  all_missing <- mca_table_again(e, changed)
  expect_equal(nrow(all_missing$indicator), 0)
  expect_error(e$helper$ordination_mca(all_missing), "complete observations")
  changed$sense <- "only"
  single <- mca_table_again(e, changed)
  expect_equal(single$variables$active_levels[1], 1)
  expect_error(e$helper$ordination_mca(single), "two active levels")
  changed <- e$occurrences; changed$sense <- as.character(changed$sense); changed$sense[1] <- "rare"
  rare <- e$helper$ordination_mca(mca_table_again(e, changed), k = 100)
  expect_true(all(is.finite(rare$rows$coordinate)))
  path <- tempfile(fileext = ".pdf"); grDevices::pdf(path)
  on.exit({grDevices::dev.off(); unlink(path)})
  expect_warning(color <- e$helper$ordination_mca_plot(e$result), "repeated eigenvalue")
  expect_warning(mono <- e$helper$ordination_mca_plot(e$result, monochrome = TRUE), "repeated eigenvalue")
  expect_identical(color, mono)
  expect_warning(e$helper$ordination_mca_plot(e$result, "categories"), "repeated eigenvalue")
  expect_error(e$helper$ordination_mca_plot(e$result, monochrome = NA), "TRUE or FALSE")
  expect_error(e$helper$ordination_mca(e$tab, k = 0), "k")
})
