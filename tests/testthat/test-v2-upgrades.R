test_that("English tokenizer 0.2.0 preserves number-unit tokens, undotted initialisms, URL punctuation, and warns on CJK", {
  txt <- "We walked 1,000km at 10:30am in the U.S.A today. See https://example.org/a."
  tok <- lexdiv_tokenize(
    txt,
    case = "preserve",
    tokenizer = "english"
  )
  expect_identical(tok$provenance$tokenizer_version, "0.2.0")
  expect_identical(
    tok$tokens$surface,
    c("We", "walked", "1,000km", "at", "10:30am", "in", "the", "U.S.A", "today", "See")
  )
  expect_identical(tok$provenance$excluded_spans$reason, "url")
  url_span <- tok$provenance$excluded_spans[1L, ]
  expect_identical(stringi::stri_sub(txt, url_span$start, url_span$end), "https://example.org/a")

  expect_warning(
    lexdiv_tokenize("\u65e5\u672c\u8a9e\u306e\u30c6\u30ad\u30b9\u30c8\u3092\u5206\u6790\u3057\u307e\u3059\u3002", tokenizer = "english"),
    "CJK"
  )

  # AntBNC parser handles UTF-8 BOM, comments, trailing tabs, and 4-column rank+freq rows
  ant <- tempfile(fileext = ".txt")
  on.exit(unlink(ant), add = TRUE)
  con <- file(ant, open = "wb")
  writeBin(as.raw(c(0xef, 0xbb, 0xbf)), con)
  writeLines(c(
    "# header comment",
    "1\t1000\trun\t->\trun\tran\trunning\t",
    "cat\t->\tcat\tcats\t"
  ), con, useBytes = TRUE)
  close(con)

  t1 <- lexdiv_tokenize("Cats ran.")
  fl <- lexdiv_flemmatize(t1, ant, resource_version = "bom-4col-v1")
  expect_identical(fl$tokens$flemma, c("cat", "run"))
})

test_that("unified polymorphic APIs and [.lexdiv_results preserve contracts and attributes", {
  single_res <- lexdiv_metrics(c("a", "b", "a", "c"), metrics = c("ttr", "maas"))
  sub_res <- single_res[1L, , drop = FALSE]
  expect_identical(attr(sub_res, "contract_id"), attr(single_res, "contract_id"))
  expect_identical(attr(sub_res, "contract_version"), attr(single_res, "contract_version"))
  expect_identical(attr(sub_res, "result_schema_id"), attr(single_res, "result_schema_id"))

  plan <- lexdiv_plan(presets = character(), specs = list(
    lexdiv_spec("ttr", request_id = "ttr"),
    lexdiv_spec("maas", request_id = "maas")
  ))
  prof_res <- lexdiv_metrics(c("a", "b", "a", "c"), plan = plan)
  expect_identical(attr(prof_res[1L, , drop = FALSE], "plan_md5"), plan$plan_md5)

  # Tokenization object passed directly to lexdiv_metrics, lexdiv_as_documents, and lexdiv_metrics_text
  tok_single <- lexdiv_tokenize("Cats chase cats and dogs.")
  expect_equal(lexdiv_metrics(tok_single, metrics = "ttr")$value, 0.8)
  expect_identical(
    lexdiv_as_documents(tok_single),
    list(document_1 = c("cats", "chase", "cats", "and", "dogs"))
  )

  tok_batch <- lexdiv_tokenize(c(d1 = "Cats chase cats.", d2 = "Dogs bark."))
  expect_true(is.list(tok_batch) && all(vapply(tok_batch, inherits, logical(1L), "lexdiv_tokenization")))
  expect_equal(lexdiv_metrics(tok_batch, metrics = "ttr")$value, c(2 / 3, 1))
  expect_identical(
    lexdiv_as_documents(tok_batch),
    list(d1 = c("cats", "chase", "cats"), d2 = c("dogs", "bark"))
  )

  no_audit <- lexdiv_metrics_text(
    c(d1 = "Cats chase cats.", d2 = "Dogs bark."),
    metrics = "ttr",
    retain_token_audit = FALSE
  )
  expect_equal(nrow(no_audit$token_audit), 0L)
  expect_equal(nrow(no_audit$results), 2L)
})

test_that("expected_ttr_d records accurate optimizer_iterations and unbounded_high effective_parameters", {
  too_short <- lexdiv_metrics(rep("a", 10L), metrics = "expected_ttr_d")
  expect_identical(too_short$diagnostics[[1L]]$optimizer_iterations, NA_integer_)

  all_unique <- lexdiv_metrics(paste0("w", seq_len(60L)), metrics = "expected_ttr_d")
  expect_identical(all_unique$missing_reason, "unbounded_high")
  expect_identical(all_unique$effective_parameters[[1L]], list())
  expect_identical(all_unique$diagnostics[[1L]]$optimizer_iterations, NA_integer_)

  converged <- lexdiv_metrics(rep(c("a", "b", "c", "d", "e"), 15L), metrics = "expected_ttr_d")
  expect_identical(converged$status, "ok")
  expect_identical(converged$diagnostics[[1L]]$optimizer_iterations, 100L)
})

test_that("MTLD <= variant and require_mtld_factors length screen work as specified", {
  # At threshold = 0.5 on c("a", "a", "b", "b"):
  # token 1 ("a"): TTR = 1/1 = 1.0
  # token 2 ("a"): TTR = 1/2 = 0.5 -> closes under <= (0.5 <= 0.5), stays open under < (0.5 < 0.5 is FALSE)
  toks <- c("a", "a", "b", "b")
  lt_row <- lexdiv_metrics(toks, metrics = "mtld", mtld_threshold = 0.5)
  le_row <- lexdiv_variant_metrics(
    toks,
    variants = "mtld_seq_bidir_dirmean_le_nomin_linear_tail_v1",
    mtld_thresholds = 0.5
  )
  expect_identical(lt_row$diagnostics[[1L]]$forward_complete_factors, 0L)
  expect_identical(le_row$diagnostics[[1L]]$forward_complete_factors, 2L)
  expect_equal(le_row$value, 2)

  # Tail-only MTLD screening
  plan <- lexdiv_plan(presets = character(), specs = list(
    lexdiv_spec("mtld", request_id = "mtld")
  ))
  # 55 unique tokens + 1 repeat -> N = 56 >= 50, TTR = 55/56 = 0.982 > 0.72 -> tail-only!
  tail_doc <- c(paste0("u", seq_len(55L)), "u1")
  full_doc <- rep(c("a", "b"), 30L)
  prof <- lexdiv_metrics(list(tail_only = tail_doc, full_factors = full_doc), plan = plan)

  scr_len <- lexdiv_screen_lengths(prof, floors = c(tokens_50 = 50L), require_mtld_factors = FALSE)
  expect_identical(scr_len$mtld_tail_only, c(TRUE, FALSE))
  expect_identical(scr_len$passes_screen, c(TRUE, TRUE))

  scr_strict <- lexdiv_screen_lengths(prof, floors = c(tokens_50 = 50L), require_mtld_factors = TRUE)
  expect_identical(scr_strict$passes_screen, c(FALSE, TRUE))
})

test_that("NJ8 inline spelling variants and norm_profile non-numeric/symbol columns work cleanly", {
  wl <- data.frame(
    NJ8 = seq_len(8000L),
    Word = paste0("headword_", seq_len(8000L)),
    stringsAsFactors = FALSE
  )
  wl$Word[10L] <- "program(me)"
  wl$Word[20L] <- "colo(u)r"
  wl$Word[30L] <- "theater/theatre"
  wl$Word[40L] <- "mom (mum, mummy)"

  prof <- nj8_profile(
    c("program", "programme", "color", "colour", "theater", "theatre", "mom", "mum", "mummy"),
    wordlist = wl,
    unit = "surface"
  )
  expect_identical(prof$lookup$rank, c(10L, 10L, 20L, 20L, 30L, 30L, 40L, 40L, 40L))

  norms <- data.frame(
    word = c("cat", "dog"),
    `%_known` = c(99.5, 98.2),
    aoa = c(3.1, 3.4),
    pos = c("noun", "noun"),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  np <- lexdiv_norm_profile(c("cat", "dog"), norms, key = "word")
  expect_identical(unique(np$summary$measure_id), c("pct_known", "aoa"))
})

test_that("bridged annotations retain cased text/offsets, default to term+is_word, and support pure-R KWIC and DP_norm", {
  texts <- c(
    d1 = "Don\u2019t shout in \u0130stanbul!",
    d2 = "Quiet streets in \u0130stanbul."
  )
  ann <- lexdiv_as_annotations(texts)
  expect_identical(ann$segments$text[[1L]], unname(texts[[1L]]))
  reconstructed <- stringi::stri_sub(
    ann$segments$text[match(ann$tokens$document_id, ann$segments$document_id)],
    from = ann$tokens$start,
    to = ann$tokens$end
  )
  expect_identical(reconstructed, ann$tokens$surface)
  ist_lower <- stringi::stri_trans_tolower("\u0130stanbul", locale = "en")
  expect_identical(ann$tokens$surface[ann$tokens$document_id == "d1"], c("Don\u2019t", "shout", "in", "\u0130stanbul", "!"))
  expect_identical(ann$tokens$term[ann$tokens$document_id == "d1" & ann$tokens$is_word], c("don't", "shout", "in", ist_lower))

  # Default term_col = NULL -> "term" and keep = NULL -> is_word
  if (isTRUE(l10n_info()[["UTF-8"]])) {
    conc <- lexdiv_concordance(ann, list(ist = ist_lower))
    expect_equal(nrow(conc$occurrences), 2L)
    expect_identical(conc$occurrences$keyword, c("\u0130stanbul", "\u0130stanbul"))

    disp <- lexdiv_concordance_dispersion(conc, "ist", parts = 2L, include_normalized = TRUE)
    expect_true("DP_norm" %in% names(disp$documents))
    expect_true(all(disp$documents$DP_norm >= 0 & disp$documents$DP_norm <= 1))
  } else {
    ann_ascii <- lexdiv_as_annotations(c(
      d1 = "Don\u2019t shout in London!",
      d2 = "Quiet streets in London."
    ))
    conc <- lexdiv_concordance(ann_ascii, list(lon = "london"))
    expect_equal(nrow(conc$occurrences), 2L)
    expect_identical(conc$occurrences$keyword, c("London", "London"))

    disp <- lexdiv_concordance_dispersion(conc, "lon", parts = 2L, include_normalized = TRUE)
    expect_true("DP_norm" %in% names(disp$documents))
    expect_true(all(disp$documents$DP_norm >= 0 & disp$documents$DP_norm <= 1))
  }

  key <- lexdiv_keyness(ann, target = "d1", reference = "d2")
  expect_false("!" %in% key$results$term)
  expect_false("." %in% key$results$term)
  expect_true(ist_lower %in% key$results$term)

  # Exercise pure-R fallback KWIC directly
  fb <- getFromNamespace(".concordance_fallback_kwic", "ldfreq")
  hits <- fb(
    ann$segments,
    ann$tokens,
    ann$tokens$term,
    ann$tokens$is_word,
    c("in", ist_lower),
    valuetype = "fixed",
    case_insensitive = FALSE
  )
  expect_equal(nrow(hits), 2L)
})

test_that("lexdiv_ngrams supports 4-gram lexical bundles across reference, build, and compare workflows", {
  tok_df <- data.frame(
    document_id = c(rep("d1", 5L), rep("d2", 5L)),
    segment_id = "s1",
    token_index = rep(1:5, 2L),
    term = c(
      "on", "the", "other", "hand", "however",
      "on", "the", "other", "hand", "indeed"
    ),
    stringsAsFactors = FALSE
  )
  ng <- lexdiv_ngrams(tok_df, "bundles-v1", n = c(2L, 4L))
  expect_true(all(paste0("term", 1:4) %in% names(ng$counts)))
  four <- ng$counts[ng$counts$n == 4L, ]
  expect_true(any(
    four$term1 == "on" & four$term2 == "the" &
      four$term3 == "other" & four$term4 == "hand" & four$count == 2
  ))

  res_meta <- lexdiv_resource_meta("bundle_ref", lookup_unit = "4gram")
  ref_a <- lexdiv_ngram_reference(ng, res_meta)
  prof <- lexdiv_ngram_profile(ng, ref_a)
  expect_true(all(prof$summary$status == "ok"))

  built <- lexdiv_build_ngram_reference(
    c("d1", "d2"),
    function(id) lexdiv_ngrams(tok_df[tok_df$document_id == id, ], "bundles-v1", n = 4L),
    res_meta
  )
  expect_equal(built$reference$totals$opportunities, 4)

  ref_b <- lexdiv_ngram_reference(
    ref_a$counts[ref_a$counts$count > 1, ],
    res_meta,
    totals = ref_a$totals,
    preprocessing_id = "bundles-v1",
    complete = FALSE
  )
  cmp <- lexdiv_compare_ngrams(ng, list(full = ref_a, pruned = ref_b))
  expect_s3_class(cmp, "lexdiv_ngram_comparison")
})

test_that("lexdiv_family_profile computes frequency bands, band_95/band_98, matched_family_ttr, and supplementary coverage", {
  ann <- lexdiv_as_annotations(c(d1 = "the cat in tokyo", empty = ""))
  dict <- data.frame(
    record_id = c("r1", "r2", "r3"),
    form = c("THE", "CAT", "IN"),
    family_id = c("F_THE", "F_CAT", "F_IN"),
    frequency_band = c(1L, 1L, 2L),
    stringsAsFactors = FALSE
  )
  supp <- data.frame(
    record_id = "s1",
    form = "TOKYO",
    family_id = "S_TOKYO",
    list_type = "proper_nouns",
    frequency_band = NA_integer_,
    stringsAsFactors = FALSE
  )
  res_meta <- list(
    resource_id = "synthetic_bnc",
    resource_version = "1.0",
    language = "en",
    source_reference = "synthetic",
    data_license = "MIT",
    family_definition = "level6",
    lookup_unit = "surface"
  )
  # Adapt bridged annotations: use term via surface for word tokens
  word_rows <- ann$tokens[ann$tokens$is_word, , drop = FALSE]
  seg <- data.frame(
    document_id = c("d1", "empty"),
    segment_id = "s1",
    text = c("the cat in tokyo", ""),
    stringsAsFactors = FALSE
  )
  tok <- data.frame(
    document_id = rep("d1", 4L),
    segment_id = "s1",
    token_index = 1:4,
    surface = word_rows$term,
    stringsAsFactors = FALSE
  )
  imported <- lexdiv_import_annotations(tok, seg, list(
    language = "en", analyzer = "test", analyzer_version = "1",
    dictionary = "none", dictionary_version = "none",
    unit = "word", normalization = "none"
  ))

  fp <- lexdiv_family_profile(
    imported, dict, res_meta,
    unit = "surface",
    normalization = "nfkc_lower",
    supplementary = supp
  )
  expect_true("occurrence_id" %in% names(fp$occurrences))
  expect_true("matched_family_ttr" %in% names(fp$documents))
  expect_equal(fp$documents$matched_family_ttr[1L], 1)
  expect_true(!is.null(fp$bands) && !is.null(fp$band_summary))
  d1_doc <- fp$documents[fp$documents$document_id == "d1", ]
  expect_equal(d1_doc$band_95, 2L)
  expect_equal(d1_doc$band_98, 2L)
})

test_that("study_table accepts screen/shorthand reporting and warns on unscreened model selection", {
  plan <- lexdiv_plan(presets = character(), specs = list(
    lexdiv_spec("ttr", request_id = "ttr")
  ))
  planned <- data.frame(
    observation_id = c("o1", "o2"),
    writer_id = c("w1", "w2"),
    task = "essay",
    occasion = 1L,
    stringsAsFactors = FALSE
  )
  submissions <- data.frame(
    observation_id = c("o1", "o2"),
    document_id = c("d1", "d2"),
    stringsAsFactors = FALSE
  )
  res <- lexdiv_metrics_text(
    c(d1 = "one two three four five six", d2 = "short"),
    plan = plan
  )
  screens <- lexdiv_screen_lengths(res, floors = c(min5 = 5L))

  st_screen <- lexdiv_study_table(planned, submissions, res, plan, "cond", reporting = screens)
  expect_identical(st_screen$reporting_status, c("report", "withhold"))

  st_qf <- lexdiv_study_table(planned, submissions, res, plan, "cond", reporting = "quality_floor")
  expect_identical(st_qf$reporting_status, c("report", "report"))

  st_none <- lexdiv_study_table(planned, submissions, res, plan, "cond", reporting = NULL)
  expect_warning(
    lexdiv_study_model_data(st_none, "cond", "ttr"),
    "not_screened"
  )
})

test_that("recipes support nj8_unit = lemma, cross-engine mismatch controls, and CLI BOM/slash handling", {
  plan <- lexdiv_plan(presets = character(), specs = list(lexdiv_spec("ttr", request_id = "ttr")))
  rec_lemma <- lexdiv_recipe(plan = plan, resources = "nj8", nj8_unit = "lemma")
  expect_identical(rec_lemma$schema_version, "1.1.0")
  expect_identical(rec_lemma$resources[[1L]]$unit, "lemma")

  if (requireNamespace("jsonlite", quietly = TRUE)) {
    p <- tempfile(fileext = ".json")
    on.exit(unlink(p), add = TRUE)
    lexdiv_write(rec_lemma, p)
    expect_identical(lexdiv_read(p), rec_lemma)
  }

  rec_surf <- lexdiv_recipe(plan = plan)
  tampered_icu <- rec_surf
  tampered_icu$engine$icu_version <- "0.0-synthetic"
  expect_warning(
    run_icu <- lexdiv_run_recipe(c(d1 = "Cats chase cats."), tampered_icu),
    "ICU"
  )
  expect_true(is.character(lexdiv_methods_text(run_icu)))

  tampered_ver <- rec_surf
  tampered_ver$engine$package_version <- "0.9.9-synthetic"
  expect_error(lexdiv_run_recipe(c(d1 = "Cats chase cats."), tampered_ver), "engine")
  expect_warning(
    out <- lexdiv_run_recipe(c(d1 = "Cats chase cats."), tampered_ver, allow_engine_mismatch = TRUE),
    "differ"
  )
  expect_equal(out$analysis$results$value, 2 / 3)

  if (requireNamespace("jsonlite", quietly = TRUE)) {
    in_dir <- tempfile("cli-in-")
    sub_dir <- file.path(in_dir, "sub")
    dir.create(sub_dir, recursive = TRUE)
    on.exit(unlink(in_dir, recursive = TRUE), add = TRUE)
    f_bom <- file.path(sub_dir, "essay.txt")
    con <- file(f_bom, open = "wb")
    writeBin(as.raw(c(0xef, 0xbb, 0xbf)), con)
    writeChar("The cat sat.", con, eos = NULL, useBytes = TRUE)
    close(con)

    rec_file <- tempfile(fileext = ".json")
    out_dir <- tempfile("cli-out-")
    on.exit(unlink(c(rec_file, out_dir), recursive = TRUE), add = TRUE)
    lexdiv_write(rec_surf, rec_file)
    cli <- system.file("exec", "ldfreq.R", package = "ldfreq")
    if (!nzchar(cli)) cli <- normalizePath("../../exec/ldfreq.R", mustWork = FALSE)
    if (nzchar(cli) && file.exists(cli)) {
      withr::local_envvar(R_LIBS = paste(.libPaths(), collapse = .Platform$path.sep))
      status <- system2(
        file.path(R.home("bin"), "Rscript"),
        shQuote(c("--vanilla", cli, "--recipe", rec_file, "--input", in_dir, "--output", out_dir, "--recursive"))
      )
      expect_identical(status, 0L)
      csv_df <- utils::read.csv(file.path(out_dir, "results.csv"), stringsAsFactors = FALSE)
      expect_identical(unique(csv_df$document_id), "sub/essay.txt")
      expect_equal(csv_df$N[csv_df$request_id == "ttr"], 3)
    }
  }
})

test_that("print.lexdiv_contextual_scores handles matrix prototypes without error", {
  seg <- data.frame(
    document_id = c("train1", "train2", "test1"),
    segment_id = "s1",
    text = c("bank river", "bank money", "bank water"),
    stringsAsFactors = FALSE
  )
  tok <- data.frame(
    document_id = rep(c("train1", "train2", "test1"), each = 2L),
    segment_id = "s1",
    token_index = rep(1:2, 3L),
    surface = c("bank", "river", "bank", "money", "bank", "water"),
    stringsAsFactors = FALSE
  )
  ann <- lexdiv_import_annotations(tok, seg, list(
    language = "en", analyzer = "test", analyzer_version = "1",
    dictionary = "none", dictionary_version = "none",
    unit = "word", normalization = "none"
  ))
  cand <- data.frame(
    term = c("bank", "bank"),
    candidate_id = c("sense_river", "sense_finance"),
    label = c("river bank", "financial bank"),
    stringsAsFactors = FALSE
  )
  res_meta <- list(
    resource_id = "senses", resource_version = "1",
    source_reference = "authored", data_license = "MIT"
  )
  # Disjoint train/test documents for supervised contextual scoring
  ann_tr <- lexdiv_import_annotations(tok[1:4, ], seg[1:2, ], list(
    language = "en", analyzer = "test", analyzer_version = "1",
    dictionary = "none", dictionary_version = "none",
    unit = "word", normalization = "none"
  ))
  ann_te <- lexdiv_import_annotations(tok[5:6, ], seg[3, , drop = FALSE], list(
    language = "en", analyzer = "test", analyzer_version = "1",
    dictionary = "none", dictionary_version = "none",
    unit = "word", normalization = "none"
  ))
  rev_tr <- lexdiv_ambiguity_review(ann_tr, "bank", cand, res_meta)
  dec_tr <- data.frame(
    review_id = rev_tr$provenance$review_id,
    occurrence_id = rev_tr$occurrences$occurrence_id,
    status = c("selected", "selected"),
    candidate_id = c("sense_river", "sense_finance"),
    reviewer = "r1",
    reason = "authored",
    stringsAsFactors = FALSE
  )
  rev_tr <- lexdiv_ambiguity_review(ann_tr, "bank", cand, res_meta, decisions = dec_tr)
  rev_te <- lexdiv_ambiguity_review(ann_te, "bank", cand, res_meta)
  mod_meta <- list(
    model_id = "authored", model_revision = "1",
    tokenizer_id = "authored", tokenizer_revision = "1",
    software = "test", software_version = "1",
    context_policy = "full segment; no truncation", representation = "2d"
  )
  make_ctx <- function(rev_obj, mat) {
    dat <- rev_obj$occurrences[c("review_id", "occurrence_id", "segment_text", "surface", "start", "end")]
    dat$status <- "processed"
    dat$reason <- "authored"
    rownames(mat) <- rev_obj$occurrences$occurrence_id
    lexdiv_import_contextual(rev_obj, dat, mod_meta, mat)
  }
  ctx_tr <- make_ctx(rev_tr, matrix(c(1, 0, 0, 1), ncol = 2, byrow = TRUE))
  ctx_te <- make_ctx(rev_te, matrix(c(0.9, 0.1), ncol = 2, byrow = TRUE))
  train_info <- list(
    training_id = "authored",
    annotation_protocol = "authored",
    partition_protocol = "disjoint documents",
    model_exposure = "unknown"
  )
  scores <- lexdiv_score_contextual(ctx_te, ctx_tr, rev_tr, train_info)
  out <- capture.output(vis <- withVisible(print(scores)))
  expect_false(vis$visible)
  expect_true(any(grepl("lexdiv_contextual_scores", out, fixed = TRUE)))
})
