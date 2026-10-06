# Authored contexts, unchanged resource relations, illustrative reviewer choices.
# This nine-row excerpt is not a vocabulary coverage reference.
morphynet_example <- local({
  reference <- ldfreq::morphynet_read_derivations(
    system.file("extdata", "morphynet-example", "eng.derivational.example.tsv",
      package = "ldfreq", mustWork = TRUE), language = "en",
    resource_version = "English v1; nine-row teaching excerpt")
  source_rows <- utils::read.csv(system.file("extdata", "morphynet-example",
    "source-rows.csv", package = "ldfreq", mustWork = TRUE), colClasses = "character")
  segments <- data.frame(document_id = c(rep("example", 4), "empty"),
    segment_id = c("s1", "s2", "s3", "s4", "s1"),
    text = c("We retransmit signals.", "A transmitter supports reusability.",
      "We discuss reusability.", "The teachers explain.", ""))
  tokens <- data.frame(document_id = "example", segment_id = rep(paste0("s", 1:4), c(4,5,4,4)),
    token_index = c(1:4, 1:5, 1:4, 1:4),
    surface = c("We", "retransmit", "signals", ".", "A", "transmitter", "supports",
      "reusability", ".", "We", "discuss", "reusability", ".", "The", "teachers", "explain", "."))
  annotations <- ldfreq::lexdiv_import_annotations(tokens, segments,
    list(language = "en", analyzer = "authored token boundaries", analyzer_version = "1",
      dictionary = "none", dictionary_version = "1", unit = "word", normalization = "none"))
  targets <- c("retransmit", "transmitter", "reusability", "teachers")
  relations <- reference$relations
  candidates <- relations[relations$target_word %in% targets, , drop = FALSE]
  candidates$term <- candidates$target_word
  candidates$candidate_id <- candidates$relation_id
  candidates$label <- paste(candidates$source_word, "->", candidates$target_word,
    paste0("[", candidates$source_pos, "->", candidates$target_pos, "; ",
      candidates$morpheme, "; ", candidates$affix_position, "]"))
  resource <- reference$resource
  resource$selection_policy <- paste("Retain all incoming relations; selecting one records a",
    "study-specific analysis, not a claim that other relations are false or that all affixes are counted")
  resource$matching <- "Exact case-sensitive target word to supplied surface; no POS mapping"
  initial <- reviewed <- selected <- NULL
  if (requireNamespace("quanteda", quietly = TRUE)) {
    initial <- ldfreq::lexdiv_ambiguity_review(annotations, targets, candidates, resource)
    # The same form can be selected in one occurrence and left unresolved in another.
    # This is an explicit illustrative decision, not a linguistic gold standard.
    decision <- initial$occurrences[initial$occurrences$surface == "reusability",
      c("review_id", "occurrence_id")]
    choice <- candidates$candidate_id[candidates$source_word == "reusable" &
      candidates$target_word == "reusability" & candidates$morpheme == "ity"]
    stopifnot(length(choice) == 1L)
    decision$status <- c("selected", "unresolved")
    decision$candidate_id <- c(choice, NA_character_)
    decision$reviewer <- "authored-example"
    decision$reason <- c("Declared illustration: reusable + ity for this occurrence",
      "Withhold an analysis for this occurrence; preserve all three relations")
    reviewed <- ldfreq::lexdiv_ambiguity_review(annotations, targets, candidates,
      resource, decisions = decision)
    selected <- reviewed$occurrences[reviewed$occurrences$status == "selected", , drop = FALSE]
    row <- match(selected$candidate_id, relations$relation_id)
    selected <- cbind(selected, relations[row, , drop = FALSE])
    rownames(selected) <- NULL
  }
  list(reference = reference, source_rows = source_rows, annotations = annotations,
    targets = targets, candidates = candidates, resource = resource,
    initial = initial, reviewed = reviewed, selected = selected)
})
