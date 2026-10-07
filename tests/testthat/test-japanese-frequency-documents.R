japanese_frequency_fixture <- function() {
  skip_if_not_installed("quanteda", "4.5.0")
  skip_if_not(isTRUE(l10n_info()[["UTF-8"]]))
  e <- new.env(parent = baseenv())
  sys.source(system.file("examples", "japanese-frequency-demo.R", package = "ldfreq", mustWork = TRUE), e)
  e
}

test_that("document frequency preserves full denominators and existing arithmetic", {
  e <- japanese_frequency_fixture(); on.exit(unlink(e$ja_file_output, recursive = TRUE))
  x <- e$ja_frequency; d <- x$documents; t <- x$occurrences
  expect_equal(d$retained_N, c(5, 9, 1, 0, 0))
  expect_equal(d$matched_N, c(5, 8, 0, 0, 0))
  expect_equal(d$unresolved_key_N, c(0, 1, 0, 0, 0))
  expect_equal(d$unmatched_N, c(0, 0, 1, 0, 0))
  expect_equal(d$matched_coverage, c(1, 8/9, 0, NA, NA))
  expect_equal(d$key_coverage, c(1, 8/9, 1, NA, NA))
  expect_equal(d$retained_N, d$matched_N + d$unresolved_key_N + d$unmatched_N)
  a <- subset(x$norms$summary, weighting == "token" & measure_id == "per_million")
  expect_equal(a$estimate, c(406, 1305/8, NA, NA, NA))
  expect_equal(a$input_units, c(5, 8, 1, 0, 0))
  expect_equal(a$resource_coverage, c(1, 1, 0, NA, NA))
  b <- subset(x$norms$summary, weighting == "type" & measure_id == "per_million")
  expect_equal(b$estimate[1], 505)
  expect_equal(b$input_units[1:2], c(2, 7))
  c <- subset(x$norms$summary, weighting == "token" & measure_id == "channel_proportion")
  expect_equal(c$observed_value_units[1:2], c(5, 7))
  expect_equal(t$value_per_million[t$surface == "見る"], 0)
  expect_true(is.na(t$value_channel_proportion[t$surface == "見る"]))
  expect_equal(nrow(t), nrow(e$ja_file_import$tokens))
  expect_identical(x$source_profile$imported, e$ja_file_import)
  expect_identical(e$ja_frequency_saved$review$file_review$after, e$ja_file_after)
  expect_identical(e$ja_frequency_replayed, e$ja_frequency_inputs)
  csv <- utils::read.csv(file.path(e$ja_file_output, "frequency-documents.csv"), fileEncoding = "UTF-8")
  expect_equal(csv$matched_coverage, d$matched_coverage)
})

test_that("frequency keys reject stale anchors, duplication and invalid references", {
  e <- japanese_frequency_fixture(); on.exit(unlink(e$ja_file_output, recursive = TRUE))
  run <- e$japanese_frequency_documents; p <- e$ja_profile; k <- e$ja_frequency_keys; r <- e$ja_demo_reference
  expect_identical(run(p, k[nrow(k):1, ], r), e$ja_frequency)
  expect_error(run(p, k[-1, ], r), "every original token")
  bad <- k; bad$end[2] <- bad$end[2] + 1
  expect_error(run(p, bad, r), "unchanged source anchors")
  expect_error(run(p, rbind(k, k[1, ]), r), "unique anchors")
  bad <- k; bad$key_reason[1] <- " "
  expect_error(run(p, bad, r), "nonblank")
  bad <- k; bad$lookup_term[1] <- "*"
  expect_error(run(p, bad, r), "NA if unresolved")
  bad <- k; bad$lookup_term[1] <- "\u3000"
  expect_error(run(p, bad, r), "NA if unresolved")
  bad <- p; bad$documents$retained_N[1] <- 100
  expect_error(run(bad, k, r), "profile changed")
  bad <- r; bad$norms <- rbind(bad$norms, bad$norms[1, ])
  expect_error(run(p, k, bad), "unique")
  bad <- r; bad$norms$per_million[1] <- -1
  expect_error(run(p, k, bad), "valid_min|bounds|below")
  missing <- k; missing$lookup_term <- NA_character_
  z <- run(p, missing, r)
  expect_equal(z$documents$unresolved_key_N, p$documents$retained_N)
  expect_true(all(is.na(z$norms$summary$estimate)))
  expect_true(all(z$norms$summary$input_units == 0))
  expect_equal(z$documents$matched_coverage, c(0, 0, 0, NA, NA))
})

test_that("common comparisons retain only identical observed source spans", {
  e <- japanese_frequency_fixture(); on.exit(unlink(e$ja_file_output, recursive = TRUE))
  c <- e$ja_frequency_comparison
  expect_equal(nrow(c$common_spans), 7)
  expect_equal(c$common$body$documents$retained_N, c(3, 4, 0, 0, 0))
  expect_equal(c$common$body$documents$retained_N, c$common$content$documents$retained_N)
  expect_identical(c$common$body$norms, c$common$content$norms)
  expect_identical(c$all$body, e$ja_frequency)
  expect_false("見る" %in% c$common_spans$surface)
  bad <- e$ja_frequency; bad$reference$resource$resource_version <- "2"
  bad <- e$japanese_frequency_documents(bad$source_profile, bad$keys, bad$reference)
  expect_error(e$common_japanese_frequency(list(a = e$ja_frequency, b = bad)), "same reference")
  bad <- e$ja_frequency; bad$occurrences$value_per_million[2] <- 99
  expect_error(e$common_japanese_frequency(list(a = e$ja_frequency, b = bad)), "unchanged")
  z <- e$ja_frequency_keys; z$lookup_term <- NA_character_
  empty <- e$japanese_frequency_documents(e$ja_profile, z, e$ja_demo_reference)
  both <- e$common_japanese_frequency(list(a = e$ja_frequency, b = empty))
  expect_equal(nrow(both$common_spans), 0)
  expect_true(all(both$common$a$documents$retained_N == 0))
  expect_true(all(is.na(both$common$a$documents$matched_coverage)))
  # Equal token anchors alone are insufficient if the original text has changed.
  original <- e$ja_profile$imported
  segments <- original$segments[c("document_id", "segment_id", "text")]
  segments$text[1] <- paste0(segments$text[1], " ")
  changed <- lexdiv_import_annotations(original$tokens, segments, original$provenance$annotation)
  p <- e$japanese_document_profile(changed, e$ja_profile$selection, e$ja_pos_groups, "changed-text")
  q <- e$japanese_frequency_documents(p, e$ja_frequency_keys, e$ja_demo_reference)
  expect_error(e$common_japanese_frequency(list(a = e$ja_frequency, b = q)), "same complete source")
  skip_if_not_installed("ggplot2")
  plot <- e$plot_japanese_frequency_coverage(e$ja_frequency)
  mono <- e$plot_japanese_frequency_coverage(e$ja_frequency, monochrome = TRUE)
  expect_null(plot$labels$title)
  expect_null(plot$labels$subtitle)
  expect_identical(plot$layers[[1]]$aes_params$colour, "#0072B2")
  expect_identical(mono$layers[[1]]$aes_params$colour, "black")
  expect_equal(nrow(ggplot2::ggplot_build(plot)$data[[1]]), 5)
})

test_that("frequency commonality tolerates shifted token indices but not split spans", {
  e <- new.env(parent = baseenv())
  sys.source(system.file("examples", "japanese-frequency-documents.R", package = "ldfreq", mustWork = TRUE), e)
  segments <- data.frame(document_id = c("text", "empty"), segment_id = "s1", text = c("学校へ学校", ""))
  provenance <- list(language="ja", analyzer="authored", analyzer_version="1", dictionary="none",
    dictionary_version="none", unit="authored", normalization="none")
  coarse <- data.frame(document_id="text",segment_id="s1",token_index=1:3,surface=c("学校","へ","学校"),POS1="名詞")
  fine <- data.frame(document_id="text",segment_id="s1",token_index=1:4,surface=c("学","校","へ","学校"),POS1="名詞")
  specs <- data.frame(measure_id="f",value_column="f",construct_id="corpus_frequency",value_unit="authored",
    direction="descriptive",language="Japanese",variety="authored",population_id="demo",collection_year="none",
    valid_min=0,valid_max=NA_real_)
  resource <- list(resource_id="demo",resource_version="1",creator="authors",source_reference="authored",
    data_license="MIT",transformation_id="none",lookup_unit="surface",resource_key_normalization_id="identity")
  reference <- list(norms=data.frame(word=c("学校","へ","学","校"),f=c(10,20,3,4)),
    key="word",measure_specs=specs,resource=resource)
  run <- function(t, name) {
    x <- lexdiv_import_annotations(t, segments, provenance)
    mask <- x$tokens[c("document_id","segment_id","token_index","start","end","surface")]
    mask$in_body <- TRUE; mask$retained <- TRUE; mask$reason <- "retained"
    p <- e$japanese_document_profile(x,mask,setNames("content", "\u540d\u8a5e"),name)
    keys <- mask[1:6]; keys$lookup_term <- keys$surface; keys$key_reason <- "authored surface key"
    e$japanese_frequency_documents(p,keys,reference)
  }
  z <- e$common_japanese_frequency(list(coarse=run(coarse,"coarse"),fine=run(fine,"fine")))
  expect_equal(z$common_spans$start, c(3,4))
  expect_equal(z$common$coarse$documents$retained_N, c(2,0))
  expect_equal(z$common$fine$documents$retained_N, c(2,0))
  expect_equal(z$common$coarse$norms$summary$estimate[1], 15)
  expect_identical(z$common$coarse$norms, z$common$fine$norms)
  empty <- coarse[FALSE, ]
  x <- lexdiv_import_annotations(empty,segments[2, ],provenance)
  mask <- x$tokens[c("document_id","segment_id","token_index","start","end","surface")]
  mask$in_body <- logical();mask$retained <- logical();mask$reason <- character()
  p <- e$japanese_document_profile(x,mask,setNames("content", "\u540d\u8a5e"),"empty")
  keys <- mask[1:6];keys$lookup_term <- character();keys$key_reason <- character()
  q <- e$japanese_frequency_documents(p,keys,reference)
  expect_equal(q$documents$retained_N,0)
  expect_true(is.na(q$documents$matched_coverage))
  expect_equal(nrow(q$occurrences),0)
})
