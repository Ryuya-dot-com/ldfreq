test_that("wrong token containers cannot silently produce lexical scores", {
  wrong <- list(factor(c("a","b")),data.frame(token=c("a","b")),matrix(c("a","b")),
    I(c("a","b")),1:3,list("a","b"))
  for(tokens in wrong) {
    result <- lexdiv_metrics(tokens,metrics=c("ttr","mattr","mtld_ma"))
    expect_true(all(result$status=="invalid_input"))
    expect_true(all(is.na(result$value)))
    expect_true(all(result$missing_reason=="invalid_token"))
  }
  expect_identical(lexdiv_metrics(character(),metrics="ttr")$missing_reason,"empty_input")
  expect_identical(lexdiv_metrics(c("a",NA_character_),metrics="ttr")$status,"invalid_input")
  for(text in wrong) expect_error(lexdiv_tokenize(text))
})

test_that("numeric settings and sheet selectors retain their declared types", {
  tokens <- rep(letters[1:8],20)
  for(bad in list(factor("10"),data.frame(x=10),matrix(10),I(10),"10",as.Date("2026-01-01"))) {
    expect_error(lexdiv_metrics(tokens,metrics="mattr",window_length=bad))
    expect_error(lexdiv_metrics(tokens,metrics="hdd",sample_size=bad))
    expect_error(lexdiv_metrics(tokens,metrics="mtld_ma",mtld_threshold=bad))
    expect_error(ldfreq:::.concordance_whole(bad,"window"),"whole number")
  }
  for(bad in list(factor("All roots"),matrix("All roots"),I("All roots"),data.frame(x="All roots")))
    expect_error(morpholex_data(bad),"sheets")
  expect_error(ldfreq:::.mtld_parameters(data.frame(threshold=.72)),"list")
})

test_that("canonical action names are exact compatibility aliases", {
  expect_identical(lexdiv_compare_ngrams,lexdiv_ngram_compare)
  expect_identical(lexdiv_build_ngram_reference,lexdiv_ngram_reference_build)
  expect_identical(lexdiv_sort_concordance,lexdiv_concordance_sort)
  expect_identical(lexdiv_screen_lengths,lexdiv_screen)
  expect_identical(lexdiv_methods("variants"),lexdiv_variant_ids())
})
