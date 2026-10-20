ddl_example <- function() {
  skip_if_not_installed("quanteda", "4.5.0")
  skip_if_not(isTRUE(l10n_info()[["UTF-8"]]))
  e <- new.env(parent = globalenv())
  sys.source(system.file("examples", "ddl-materials-demo.R",
    package = "ldfreq", mustWork = TRUE), e)
  e
}

test_that("teaching selection preserves review, original contexts and explicit ordering", {
  e <- ddl_example()
  for (language in c("en", "ja")) {
    x <- e$materials[[language]]
    expect_identical(x$review, e$review)
    expect_identical(x$selected$occurrence_id, x$items$occurrence_id)
    expect_identical(x$selected$segment_id, c("s2", "s1"))
    expect_true(all(x$selected$status == "accepted"))
    expect_identical(paste0(x$selected$pre, x$selected$keyword, x$selected$post),
      x$selected$segment_text)
    expect_equal(sum(x$candidate_summary$count), nrow(e$review$occurrences))
    expect_true(all(x$candidate_summary$count[3:4] > 0))
    expect_identical(stringi::stri_sub(x$selected$segment_text,
      x$selected$start, x$selected$end), x$selected$keyword)
    f <- tempfile(fileext = ".rds")
    saveRDS(x, f); expect_identical(readRDS(f), x); unlink(f)
  }
})

test_that("learner output contains selected text and sources but no private record fields", {
  e <- ddl_example()
  for (language in c("en", "ja")) {
    x <- e$materials[[language]]
    d <- tempfile("ddl-")
    paths <- e$helper$ddl_material_write(x, d)
    html <- paste(readLines(paths["learner"], encoding = "UTF-8"), collapse = "\n")
    teacher <- read.csv(paths["teacher"], colClasses = "character", encoding = "UTF-8")
    expect_identical(readRDS(paths["record"]), x)
    expect_identical(teacher$occurrence_id, x$selected$occurrence_id)
    expect_identical(teacher$teacher_note, rep(x$activities$teacher_note, 2))
    expect_match(html, paste0('<html lang="', language, '">'), fixed = TRUE)
    expect_match(html, x$selected$citation[1], fixed = TRUE)
    expect_match(html, x$selected$keyword[1], fixed = TRUE)
    for (secret in c("Teacher only", "authored-demo-teacher",
        "Insufficient context", "Later they", "No listed phrase", "unresolved",
        x$selected$occurrence_id, e$review$criterion))
      expect_false(grepl(secret, html, fixed = TRUE), info = secret)
    expect_match(html, "@media print", fixed = TRUE)
    expect_error(e$helper$ddl_material_write(x, d), "nothing is overwritten")
    expect_identical(readRDS(paths["record"]), x)
    unlink(d, recursive = TRUE)
  }
})

test_that("selection validation rejects pending, missing and mismatched records", {
  e <- ddl_example(); x <- e$materials$en
  make <- function(review = x$review, activities = x$activities,
      items = x$items, sources = x$sources, title = x$title) {
    e$helper$ddl_material(review, activities, items, sources, title)
  }
  bad <- x$review; bad$occurrences$keyword[1] <- "changed"
  expect_error(make(review = bad), "Review changed")
  bad <- x$items; bad$occurrence_id[1] <- "missing"
  expect_error(make(items = bad), "only accepted")
  bad$occurrence_id[1] <- subset(x$review$occurrences, status == "unresolved")$occurrence_id[1]
  expect_error(make(items = bad), "only accepted")
  bad$occurrence_id[1] <- subset(x$review$occurrences, status == "unreviewed")$occurrence_id[1]
  expect_error(make(items = bad), "only accepted")
  sheet <- x$review$worksheet
  sheet$status[sheet$occurrence_id == x$items$occurrence_id[1]] <- "rejected"
  rejected <- e$helper$phrase_list_review(x$review$source, x$review$criterion, sheet)
  expect_error(make(review = rejected), "only accepted")
  expect_error(make(items = x$items[FALSE, ]), "Items need")
  expect_error(make(items = x$items[c(1, 1), ]), "unique occurrence")
  bad <- x$items; bad$activity_id[1] <- "unknown"
  expect_error(make(items = bad), "every declared")
  bad <- x$activities; bad$prompt <- NA_character_
  expect_error(make(activities = bad), "Activities need")
  expect_error(make(sources = x$sources[1, ]), "all and only")
  expect_error(make(sources = x$sources[c(1, 1, 2), ]), "unique document")
  bad <- x$sources; bad$usage[1] <- ""
  expect_error(make(sources = bad), "citation/usage")
  expect_error(make(title = ""), "title")
  bad <- x; bad$selected$pre[1] <- "changed"
  expect_error(e$helper$ddl_material_write(bad, tempfile()), "Material changed")
  expect_error(e$helper$ddl_material_write(x, file.path(tempfile(), "missing")), "existing parent")
})

test_that("HTML escapes literal markup and CSV neutralizes formula-like display strings", {
  e <- ddl_example(); x <- e$materials$en
  a <- x$activities
  a$prompt <- "<script>alert('prompt')</script> & \"observe\""
  a$teacher_note <- "=HYPERLINK(\"https://example.invalid\", \"private\")"
  s <- x$sources; s$citation[1] <- "<img src=x onerror=alert(1)>"
  s$usage[1] <- "@private-formula"
  x <- e$helper$ddl_material(x$review, a, x$items, s, "<title> & teacher")
  d <- tempfile()
  paths <- e$helper$ddl_material_write(x, d)
  html <- paste(readLines(paths["learner"]), collapse = "\n")
  expect_false(grepl("<script|<img|onerror=\"", html))
  expect_match(html, "&lt;script&gt;", fixed = TRUE)
  expect_match(html, "&amp;", fixed = TRUE)
  expect_false(grepl("HYPERLINK", html, fixed = TRUE))
  csv <- read.csv(paths["teacher"], colClasses = "character", encoding = "UTF-8")
  expect_true(all(startsWith(csv$teacher_note, "'=")))
  expect_true(any(startsWith(csv$usage, "'@")))
  expect_identical(readRDS(paths["record"])$activities$teacher_note, a$teacher_note)
  unlink(d, recursive = TRUE)
})

test_that("multiple activities and nested candidates retain distinct identities", {
  e <- ddl_example(); x <- e$materials$en
  h <- subset(x$review$occurrences, document_id == "en" & status == "accepted")
  expect_equal(nrow(h), 3)
  a <- data.frame(activity_id = c("second", "first"),
    prompt = c("Explain the contrast.", "Find the context."), teacher_note = "")
  items <- data.frame(occurrence_id = h$occurrence_id,
    activity_id = c("first", "second", "first"))
  z <- e$helper$ddl_material(x$review, a, items, x$sources, "Grouped examples")
  expect_identical(z$selected$occurrence_id, h$occurrence_id[c(2, 1, 3)])
  expect_equal(length(unique(z$selected$occurrence_id)), 3)
  expect_equal(nrow(z$selected), 3)
  expect_identical(z$review, x$review)
})

test_that("ASCII searches and UTF-8 handout writing work independently of the input locale", {
  skip_if_not_installed("quanteda", "4.5.0")
  e <- new.env(parent = globalenv())
  sys.source(system.file("examples", "ddl-materials.R",
    package = "ldfreq", mustWork = TRUE), e)
  segments <- data.frame(document_id = "doc", segment_id = "s1", text = "take off")
  tokens <- data.frame(document_id = "doc", segment_id = "s1",
    token_index = 1:2, surface = c("take", "off"))
  annotations <- lexdiv_import_annotations(tokens, segments,
    list(language = "en", analyzer = "authored", analyzer_version = "1",
      dictionary = "none", dictionary_version = "none",
      unit = "authored-tokens", normalization = "none"))
  resource <- list(resource_id = "test", resource_version = "1",
    source_reference = "authored test", data_license = "MIT")
  search <- e$phrase_list_kwic(annotations, list(target = c("take", "off"),
    absent = c("not", "here")), resource)
  before <- e$phrase_list_review(search, "Select a context for observation.")
  sheet <- before$worksheet
  sheet$status <- "accepted"; sheet$reviewer <- "test"; sheet$reason <- "Test example."
  review <- e$phrase_list_review(search, before$criterion, sheet)
  activities <- data.frame(activity_id = "a",
    prompt = "\u6bd4\u8f03: \"caf\u00e9\", take off\nExplain.", teacher_note = "private")
  items <- data.frame(occurrence_id = sheet$occurrence_id, activity_id = "a")
  sources <- data.frame(document_id = "doc", segment_id = "s1",
    citation = "\u51fa\u5178", usage = "MIT")
  x <- e$ddl_material(review, activities, items, sources, "\u7528\u4f8b", language = "ja")
  expect_equal(x$review$counts$occurrences[x$review$counts$phrase_id == "absent"], 0)
  d <- tempfile()
  files <- e$ddl_material_write(x, d)
  html <- readLines(files["learner"], encoding = "UTF-8")
  expect_true(any(grepl("\u7528\u4f8b", html, fixed = TRUE)))
  expect_true(any(grepl("\u6bd4\u8f03", html, fixed = TRUE)))
  csv <- read.csv(files["teacher"], colClasses = "character", encoding = "UTF-8")
  expect_identical(csv$prompt, activities$prompt)
  expect_identical(csv$citation, sources$citation)
  expect_identical(readRDS(files["record"]), x)
  absent <- e$phrase_list_review(e$phrase_list_kwic(annotations,
    list(absent = c("not", "here")), resource), before$criterion)
  expect_equal(nrow(absent$occurrences), 0)
  expect_error(e$ddl_material(absent, activities, items[FALSE, ], sources, "Empty"),
    "Items need")
  unlink(d, recursive = TRUE)
})
