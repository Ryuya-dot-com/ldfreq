test_that("tibble-like subclassed data frames and named vectors work across v1.0.0 APIs", {
  as_tbl <- function(df) {
    class(df) <- c("tbl_df", "tbl", "data.frame")
    df
  }

  # Named character vectors in single-document and pair APIs
  named_toks <- c(w1 = "the", w2 = "cat", w3 = "the", w4 = "dog")
  m <- lexdiv_metrics(named_toks, metrics = "ttr")
  expect_identical(m$status, "ok")
  expect_equal(m$value, 0.75)

  ov <- lexdiv_term_overlap(named_toks, c(x1 = "cat", x2 = "bird"))
  expect_true(all(ov$summary$status == "ok"))

  wl <- as_tbl(data.frame(NJ8 = c(1L, 1001L), Word = c("the", "cat"), stringsAsFactors = FALSE))
  nj <- nj8_profile(named_toks, wordlist = wl, unit = "surface")
  expect_identical(nj$status, "ok")
  nj_diag <- nj8_diagnostics(nj)
  expect_s3_class(nj_diag, "nj8_diagnostics")
  capture.output(expect_invisible(print(nj_diag)))

  # Tidy token tibble -> lexdiv_as_documents(id_col=)
  tidy_tbl <- as_tbl(data.frame(
    essay_id = c("d1", "d1", "d2"),
    word = c("alpha", "beta", "alpha"),
    stringsAsFactors = FALSE
  ))
  docs <- lexdiv_as_documents(tidy_tbl, id_col = "essay_id", token_col = "word")
  expect_identical(docs, list(d1 = c("alpha", "beta"), d2 = "alpha"))

  # Raw-text tibble -> lexdiv_metrics_text_batch -> lexdiv_widen
  raw_tbl <- as_tbl(data.frame(
    document_id = c("d1", "d2"),
    text = c("Cats chase cats and dogs!", "A dog barked."),
    stringsAsFactors = FALSE
  ))
  tb_res <- lexdiv_metrics_text_batch(raw_tbl, metrics = "ttr")
  wide <- tb_res |> lexdiv_widen(values_from = c("value", "N"))
  expect_s3_class(wide, "lexdiv_wide_results")
  expect_equal(wide$ttr__N, c(5, 3))
  expect_equal(wide$ttr__value, c(0.8, 1.0))
})

test_that("ergonomic norm specs, resource metadata, and metric_id shorthands work", {
  norms <- data.frame(
    word = c("cat", "dog", "rare"),
    familiarity = c(6.5, 6.2, 2.1),
    aoa = c(3.2, 3.5, 12.0),
    stringsAsFactors = FALSE
  )
  # Zero-boilerplate norm profile and batch norm profile
  p1 <- lexdiv_norm_profile(c("cat", "dog", "unknown"), norms, key = "word")
  expect_s3_class(p1, "lexdiv_norm_profile")
  expect_identical(p1$provenance$contract_version, "0.2.0")
  expect_equal(nrow(p1$summary), 4L)

  pb <- lexdiv_norm_profile_batch(
    list(d1 = c("cat", "dog"), d2 = c("rare", "unknown")),
    norms,
    key = "word"
  )
  expect_s3_class(pb, "lexdiv_norm_profile_batch")
  expect_equal(nrow(pb$summary), 8L)

  # Shorthand metric_id in lexdiv_spec and lexdiv_grid
  spec_short <- lexdiv_spec("mtld", list(threshold = 0.75), request_id = "mtld_75")
  spec_full <- lexdiv_spec(
    "mtld_seq_bidir_dirmean_lt_nomin_linear_tail_v1",
    list(threshold = 0.75),
    request_id = "mtld_75"
  )
  expect_identical(spec_short, spec_full)

  grid_short <- lexdiv_grid("mattr", "window_length", c(10, 20))
  expect_length(grid_short, 2L)
})

test_that("unified raw-text plan workflow connects directly to screen and study_table", {
  plan <- lexdiv_plan(
    presets = character(),
    specs = list(
      lexdiv_spec("ttr", request_id = "ttr"),
      lexdiv_spec("mattr", list(window_length = 4), request_id = "mattr_4")
    )
  )
  single <- lexdiv_metrics_text("Cats chase cats and dogs.", plan = plan)
  expect_s3_class(single$results, "lexdiv_profile_results")
  expect_equal(nrow(lexdiv_screen_lengths(single, floors = c(f4 = 4L))), 2L)

  texts <- c(d1 = "Cats chase cats and dogs.", d2 = "Short.")
  batch_res <- lexdiv_metrics_text_batch(texts, plan = plan)
  expect_s3_class(batch_res$results, "lexdiv_profile_batch_results")

  screens <- lexdiv_screen_lengths(batch_res, floors = c(f4 = 4L))
  expect_identical(screens$passes_screen, c(TRUE, TRUE, FALSE, FALSE))

  planned <- data.frame(
    observation_id = c("obs1", "obs2", "obs3"),
    writer_id = c("w1", "w2", "w3"),
    task = "prompt_a",
    occasion = 1L,
    stringsAsFactors = FALSE
  )
  # Note: input_characters omitted and automatically populated from batch_res!
  submissions <- data.frame(
    observation_id = c("obs1", "obs2"),
    document_id = c("d1", "d2"),
    stringsAsFactors = FALSE
  )
  reporting <- data.frame(
    document_id = rep(c("d1", "d2"), each = 2L),
    request_id = rep(c("ttr", "mattr_4"), times = 2L),
    reporting_status = "report",
    reporting_reason = "pre-registered",
    stringsAsFactors = FALSE
  )
  study <- lexdiv_study_table(
    planned, submissions, batch_res, plan, "english_lower", reporting
  )
  expect_equal(
    study$input_characters[study$observation_id == "obs1"][1L],
    nchar(texts[["d1"]])
  )
  mod <- lexdiv_study_model_data(study, "english_lower", "mattr_4")
  expect_s3_class(mod, "lexdiv_study_model_data")
  expect_identical(rownames(mod$data), "obs1")
  capture.output(expect_invisible(print(mod)))
})

test_that("batch lemmatization, batch flemmatization, and lexdiv_as_annotations bridge work", {
  texts <- c(
    d1 = "Hello, world! The cats ran quickly in 2026.",
    d2 = "Dogs barked loudly; cats slept."
  )
  toks <- lexdiv_tokenize_batch(texts)
  lem_toks <- lexdiv_lemmatize_batch(
    toks,
    lemmas = list(
      d1 = c("hello", "world", "the", "cat", "run", "quickly", "in"),
      d2 = c("dog", "bark", "loudly", "cat", "sleep")
    ),
    backend_id = "test-lemma",
    backend_version = "1"
  )
  expect_identical(lem_toks$d1$tokens$lemma[4:5], c("cat", "run"))

  ant_file <- tempfile(fileext = ".txt")
  on.exit(unlink(ant_file), add = TRUE)
  writeLines(c("cat\t->\tcat\tcats", "dog\t->\tdog\tdogs"), ant_file, useBytes = TRUE)
  flem_toks <- lexdiv_flemmatize_batch(toks, ant_file, resource_version = "v1")
  expect_identical(flem_toks$d1$tokens$flemma[4], "cat")

  # Direct raw-text -> lexdiv_as_annotations() bridge
  ann <- lexdiv_as_annotations(texts)
  expect_s3_class(ann, "lexdiv_annotations")
  expect_true(all(c("surface", "term", "is_word", "is_number") %in% names(ann$tokens)))
  capture.output(expect_invisible(print(ann)))

  # Annotated tokenizations + texts -> lexdiv_as_annotations() bridge
  ann_lem <- lexdiv_as_annotations(lem_toks, texts = texts)
  expect_s3_class(ann_lem, "lexdiv_annotations")
  expect_true("lemma" %in% names(ann_lem$tokens))

  if (requireNamespace("quanteda", quietly = TRUE)) {
    conc <- lexdiv_concordance(ann_lem, list(cat = "cat"), term_col = "lemma")
    expect_s3_class(conc, "lexdiv_concordance")
    expect_equal(nrow(conc$occurrences), 2L)
    capture.output(expect_invisible(print(conc)))

    sorted <- lexdiv_sort_concordance(conc, case_insensitive = TRUE)
    expect_equal(nrow(sorted), 2L)

    disp <- lexdiv_concordance_dispersion(conc, parts = 2L)
    expect_s3_class(disp, "lexdiv_dispersion")
    capture.output(expect_invisible(print(disp)))

    coll <- lexdiv_collocations(conc)
    expect_s3_class(coll, "lexdiv_collocations")
    capture.output(expect_invisible(print(coll)))

    key <- lexdiv_keyness(ann_lem, target = "d1", reference = "d2", term_col = "lemma")
    expect_s3_class(key, "lexdiv_keyness")
    capture.output(expect_invisible(print(key)))

    # Base-R concordance plot works without ggplot2
    grDevices::pdf(NULL)
    on.exit(grDevices::dev.off(), add = TRUE)
    drawn <- withVisible(plot(conc))
    expect_false(drawn$visible)
    expect_equal(nrow(drawn$value$occurrences), 2L)
  }
})
