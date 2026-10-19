ordination_example <- function() {
  e <- new.env(parent = globalenv())
  sys.source(system.file("examples", "lexical-ordination-demo.R", package = "ldfreq", mustWork = TRUE), e)
  e
}

ordination_again <- function(e, ...) {
  s <- e$tab$settings
  args <- c(list(x = e$annotations), s[c("document_ids", "preprocessing_id", "term_col",
    "keep", "min_count", "min_documents", "max_cells", "max_tokens")])
  overrides <- list(...); args[names(overrides)] <- overrides
  do.call(e$helper$ordination_table, args)
}

ordination_from_counts <- function(e, a) {
  surfaces <- lapply(seq_len(nrow(a)), function(i) rep(colnames(a), a[i, ]))
  ids <- paste0("x", seq_len(nrow(a)))
  segments <- data.frame(document_id = ids, segment_id = "s1",
    text = vapply(surfaces, paste, collapse = " ", FUN.VALUE = ""))
  tokens <- do.call(rbind, lapply(seq_along(ids), function(i) data.frame(
    document_id = rep(ids[i], length(surfaces[[i]])), segment_id = "s1",
    token_index = seq_along(surfaces[[i]]), surface = surfaces[[i]])))
  source <- lexdiv_import_annotations(tokens, segments, e$annotations$provenance$annotation)
  e$helper$ordination_table(source, ids, "authored-counts")
}

test_that("ordination tables retain counts, missingness and source membership", {
  e <- ordination_example(); x <- e$tab
  expected <- rbind(c(4,2,1,0,0,0,0,0), c(3,1,0,2,0,0,0,0),
    c(0,0,0,0,4,2,1,0), c(0,0,0,0,2,0,3,1), c(2,0,2,0,0,2,0,0),
    c(0,3,0,2,1,0,0,0), c(1,4,2,0,0,0,0,0))
  expect_equal(unname(x$active_counts), expected)
  expect_equal(rowSums(x$active_counts), setNames(c(7,6,7,6,6,6,7), paste0("d",1:7)))
  expect_equal(nrow(x$counts), 10)
  expect_equal(x$counts["partial", "learn"], 1)
  expect_equal(x$documents$missing_terms, c(rep(0,7),1,0,0,0))
  expect_equal(x$documents$status, c(rep("active",7),"incomplete_terms","empty_source",
    "no_selected_tokens","not_requested"))
  expect_equal(sum(x$token_audit$active), 45)
  for (term in colnames(expected <- x$active_counts)) {
    hits <- e$helper$ordination_occurrences(x, term)
    expect_equal(nrow(hits), sum(expected[,term]))
    expect_true(all(hits$surface == term))
    expect_equal(tabulate(match(hits$document_id, rownames(expected)), nrow(expected)),
      as.integer(expected[,term]))
  }
  filtered <- ordination_again(e, min_documents = 3)
  expect_equal(colnames(filtered$active_counts), c("learn","read","write","tree"))
  expect_identical(filtered$counts, x$counts)
  expect_equal(filtered$features$count, unname(colSums(x$active_counts)))
  none <- ordination_again(e, min_count = 100)
  expect_equal(dim(none$active_counts), c(0,0))
  expect_equal(sum(none$documents$status == "no_selected_features"), 7)
  expect_error(e$helper$ordination_mds(none), "At least two")
  empty <- ordination_again(e, document_ids = "empty")
  expect_equal(ncol(empty$counts), 0)
  expect_error(e$helper$ordination_mds(empty), "At least two")
})

test_that("CA has independently known inertia, distances and contributions", {
  skip_if_not_installed("ca")
  e <- ordination_example()
  two <- ordination_from_counts(e, matrix(c(30,10,10,30),2,dimnames=list(NULL,c("a","b"))))
  fit <- e$helper$ordination_ca(two)
  expect_equal(fit$axes$eigenvalue, .25, tolerance=1e-12)
  expect_equal(abs(fit$rows$coordinate), c(.5,.5), tolerance=1e-12)
  expect_equal(fit$rows$contribution, c(.5,.5), tolerance=1e-12)
  expect_equal(fit$rows$cos2, c(1,1), tolerance=1e-12)
  expect_equal(fit$diagnostics$effective_dimensions, 1)
  x <- e$helper$ordination_ca(e$tab, k=6)
  a <- e$tab$active_counts
  expected <- outer(rowSums(a),colSums(a))/sum(a)
  pearson <- sum((a-expected)^2/expected)
  expect_equal(sum(x$axes$eigenvalue), pearson/sum(a), tolerance=1e-12)
  points <- matrix(x$rows$coordinate,nrow(a))
  profiles <- a / rowSums(a)
  chi <- stats::dist(sweep(profiles,2,sqrt(colSums(a)/sum(a)),"/"))
  expect_equal(as.numeric(stats::dist(points)), as.numeric(chi), tolerance=1e-10)
  expect_equal(as.numeric(tapply(x$rows$contribution,x$rows$axis,sum)),rep(1,6),tolerance=1e-10)
  expect_equal(as.numeric(tapply(x$columns$contribution,x$columns$axis,sum)),rep(1,6),tolerance=1e-10)
  expect_true(all(x$rows$cos2 >= 0 & x$rows$cos2 <= 1+1e-10))
  identical_profiles <- ordination_from_counts(e,matrix(c(1,2,2,4),2,
    dimnames=list(NULL,c("a","b"))))
  expect_error(e$helper$ordination_ca(identical_profiles), "identical")
  single <- ordination_again(e,keep=e$annotations$tokens$surface=="learn")
  expect_error(e$helper$ordination_ca(single), "two active terms")
})

test_that("MDS distances agree with existing overlap and Euclidean PCA geometry", {
  e <- ordination_example(); a <- e$tab$active_counts
  pairs <- e$jaccard$pairs
  for (i in seq_len(nrow(pairs))) {
    aa <- pairs$document_a[i]; bb <- pairs$document_b[i]
    overlap <- lexdiv_term_overlap(colnames(a)[a[aa,]>0], colnames(a)[a[bb,]>0],
      measures="jaccard_types",document_ids=c(aa,bb))
    expect_equal(pairs$original_distance[i],1-overlap$summary$value)
  }
  expect_equal(as.matrix(e$jaccard$distance)["d1","d7"],0)
  expect_gt(as.matrix(e$hellinger$distance)["d1","d7"],0)
  expect_gt(e$jaccard$diagnostics$negative_eigenvalues,0)
  expect_identical(e$jaccard$settings$correction,"none")
  expect_equal(e$jaccard$fit$ac,0)
  h <- sqrt(a/rowSums(a))
  pca <- stats::prcomp(h,center=TRUE,scale.=FALSE)
  expect_equal(as.numeric(stats::dist(e$hellinger$points)),
    as.numeric(stats::dist(pca$x[,1:2])),tolerance=1e-10)
  full <- e$helper$ordination_mds(e$tab,"hellinger",k=6)
  expect_equal(full$pairs$original_distance,full$pairs$fitted_distance,tolerance=1e-10)
  expect_equal(full$diagnostics$negative_eigenvalues,0)
  expect_lt(full$diagnostics$distance_rmse,1e-10)
  revtab <- ordination_again(e,document_ids=rev(e$tab$settings$document_ids))
  reversed <- e$helper$ordination_mds(revtab,"hellinger")
  got <- as.matrix(stats::dist(reversed$points))[rownames(a),rownames(a)]
  expect_equal(got,as.matrix(stats::dist(e$hellinger$points)),tolerance=1e-10)
  pairtab <- ordination_again(e,document_ids=c("d1","d7"))
  expect_error(e$helper$ordination_mds(pairtab,"jaccard"),"All active distances")
  one <- e$helper$ordination_mds(pairtab,"hellinger")
  expect_equal(one$diagnostics$effective_dimensions,1)
  expect_lt(one$diagnostics$distance_rmse,1e-10)
})

test_that("invalid inputs, resource limits and edits fail without changing source", {
  e <- ordination_example(); x <- e$tab
  expect_error(e$helper$ordination_validate(list()),"changed")
  bad <- x; bad$active_counts[1,1] <- 100
  expect_error(e$helper$ordination_mds(bad),"changed")
  bad <- e$annotations; bad$tokens$lemma[1] <- "modified"
  expect_error(ordination_again(e,x=bad),"Source annotations changed")
  for (ids in list(character(),c("d1","d1"),"absent",NA_character_))
    expect_error(ordination_again(e,document_ids=ids),"unique, known")
  expect_error(ordination_again(e,keep=TRUE),"per original token")
  expect_error(ordination_again(e,term_col="token_index"),"character column")
  expect_error(ordination_again(e,preprocessing_id=""),"preprocessing_id")
  expect_error(ordination_again(e,max_cells=10),"Document-term cells")
  expect_error(ordination_again(e,min_count=0),"whole number")
  expect_error(e$helper$ordination_mds(x,k=0),"whole number")
  expect_error(e$helper$ordination_mds(x,distance="coverage"),"arg")
  compact <- ordination_again(e,min_count=1,keep=e$annotations$tokens$surface %in% c("learn","tree"),
    max_cells=30)
  expect_error(e$helper$ordination_mds(compact),"Document-distance cells")
  expect_error(e$helper$ordination_occurrences(x,"absent"),"exact active term")
  path <- tempfile(fileext=".rds"); on.exit(unlink(path))
  saveRDS(e$record,path,version=2)
  saved <- readRDS(path)
  expect_identical(saved,e$record)
  for (record in saved[c("table","jaccard","hellinger")])
    expect_invisible(e$helper$ordination_validate(record))
  expect_identical(e$helper$ordination_mds(saved$table,"jaccard"),e$jaccard)
})

test_that("plots preserve coordinates in color, monochrome and rank-one cases", {
  e <- ordination_example()
  path <- tempfile(fileext=".pdf"); grDevices::pdf(path)
  on.exit({grDevices::dev.off();unlink(path)})
  for (result in Filter(Negate(is.null),list(e$ca_result,e$jaccard,e$hellinger))) {
    color <- e$helper$ordination_plot(result)
    mono <- e$helper$ordination_plot(result,monochrome=TRUE)
    expect_identical(color,mono)
  }
  one <- e$helper$ordination_mds(ordination_again(e,document_ids=c("d1","d7")),"hellinger")
  expect_equal(e$helper$ordination_plot(one)$y,c(0,0))
  if (!is.null(e$ca_result)) expect_equal(nrow(e$helper$ordination_plot(e$ca_result,"terms")),8)
  expect_error(e$helper$ordination_plot(e$jaccard,"terms"),"document coordinates only")
})
