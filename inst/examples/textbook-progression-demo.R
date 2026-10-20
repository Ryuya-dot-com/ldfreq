# Authored textbook illustration, MIT licensed; no empirical learning outcomes.
library(ldfreq)
helper <- new.env(parent = globalenv())
sys.source(system.file("examples", "textbook-progression.R", package = "ldfreq",
  mustWork = TRUE), helper)
sections <- data.frame(document_id = "book", segment_id = sprintf("p%02d", 1:12),
  page = 1:12, unit = rep(1:6, each = 2), role = "body", observed = TRUE,
  text = c(
    "A planet moves. This planet is small. The planet looks blue.",
    paste("The planet has water. We study the planet. We draw the planet.",
      "A river flows. The river is wide."),
    "We visit a town.", "People work in a garden.",
    "The river is clean. We cross the river.", "Students share ideas.",
    "We recycle paper.", "They recycled paper. We recycle bottles.",
    "The river reaches the sea. Birds live near the river.", "",
    "Energy changes our lives.", "We write a report."))
raw <- as.list(quanteda::tokens(sections$text, what = "word",
  remove_punct = FALSE, remove_symbols = FALSE, remove_numbers = FALSE,
  remove_url = FALSE, remove_separators = TRUE, split_hyphens = FALSE))
tokens <- do.call(rbind, lapply(seq_along(raw), function(i) data.frame(
  document_id = rep(sections$document_id[i], length(raw[[i]])),
  segment_id = rep(sections$segment_id[i], length(raw[[i]])),
  token_index = seq_along(raw[[i]]), surface = raw[[i]])))
tokens$lemma <- tolower(tokens$surface)
tokens$lemma[tokens$lemma == "recycled"] <- "recycle"
annotations <- lexdiv_import_annotations(tokens,
  sections[c("document_id", "segment_id", "text")],
  list(language = "en", analyzer = "quanteda-tokens-word-with-authored-lemmas",
    analyzer_version = as.character(utils::packageVersion("quanteda")),
    dictionary = "authored-recycled-to-recycle", dictionary_version = "1",
    unit = "word-tokenizer-with-punctuation", normalization = "none",
    settings = paste("Punctuation/symbols/numbers/URLs retained; separators removed;",
      "hyphens unsplit; lowercase authored lemmas; recycled -> recycle")))
targets <- data.frame(query_id = c("river", "planet", "recycle", "energy", "protect"),
  introduction_unit = c(1L, 1L, 4L, 6L, 2L))
search <- helper$concordance_search(annotations,
  stats::setNames(as.list(targets$query_id), targets$query_id),
  term_col = "lemma", window = 4L)
progression <- helper$textbook_progression(search, sections, targets)
stopifnot(identical(progression$summary$occurrences, c(6L, 6L, 3L, 1L, 0L)),
  identical(progression$summary$observed_units_with_hits, c(3L, 1L, 1L, 1L, 0L)),
  progression$summary$later_status[4] == "no_later_units")
record <- list(progression = progression, session = utils::sessionInfo())
