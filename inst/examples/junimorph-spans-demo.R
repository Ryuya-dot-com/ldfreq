# Source junimorph-spans.R first. All text, annotations and table rows are authored.
# These six rows illustrate the format; they are not a bundled J-UniMorph extract.
junimorph_spans_example <- local({
  file <- tempfile(fileext = ".tsv")
  on.exit(unlink(file))
  writeLines(c("食べる\t食べられる\tV;PRS;IPFV;POT",
    "食べる\t食べられる\tV;PRS;IPFV;PASS", "食べる\t食べられる\tV;PRS;IPFV;ELEV",
    "食べる\t食べます\tV;PRS;IPFV;POL;FOREG", "開く\t開ける\tV;PRS;IPFV;POT",
    "開ける\t開ける\tV;PRS;IPFV"), file, useBytes = TRUE)
  reference <- read_junimorph(file, list(resource_id = "authored-format-example",
    resource_version = "1", source_reference = "ldfreq authored teaching rows",
    data_license = "MIT"))
  parts <- list(c("私", "は", "納豆", "を", "食べ", "られる", "。"),
    c("ここ", "で", "は", "納豆", "が", "食べ", "られる", "。"),
    c("先生", "が", "食べ", "ます", "。"), c("窓", "を", "開ける", "。"),
    c("ぷにょる", "。"), character())
  segments <- data.frame(document_id = c(rep("example", 5), "empty"),
    segment_id = c(paste0("s", 1:5), "s1"), text = vapply(parts, paste0, character(1), collapse = ""))
  tokens <- data.frame(document_id = rep(segments$document_id, lengths(parts)),
    segment_id = rep(segments$segment_id, lengths(parts)), token_index = sequence(lengths(parts)),
    surface = unlist(parts, use.names = FALSE))
  annotations <- ldfreq::lexdiv_import_annotations(tokens, segments,
    list(language = "ja", analyzer = "authored", analyzer_version = "1", dictionary = "none",
      dictionary_version = "not-applicable", unit = "authored-segments", normalization = "none"))
  targets <- c(unique(reference$records$form), "ぷにょる", "未出現")
  initial <- review_morphology_spans(annotations, reference, targets)
  decisions <- initial$occurrences[initial$occurrences$segment_id %in% c("s1", "s2", "s3"),
    c("review_id", "occurrence_id")]
  decisions$status <- c("selected", "unresolved", "selected")
  decisions$candidate_id <- c("row-1", NA_character_, "row-4")
  decisions$reviewer <- "authored-example"
  decisions$reason <- c("Author declares an ability reading for this teaching example",
    "Context does not determine a single morphological interpretation",
    "Author declares this polite form for the teaching example")
  reviewed <- review_morphology_spans(annotations, reference, targets, decisions)
  selected <- reviewed$occurrences[reviewed$occurrences$status == "selected", ]
  matched <- reference$records[match(selected$candidate_id, reference$records$candidate_id), ]
  selected$lemma <- matched$lemma; selected$features <- matched$features
  # Conditional form/lemma-label comparison on exactly the same selected spans.
  # All targeted spans are not resolved, so a complete lexical total is unavailable.
  counts <- data.frame(target_spans = nrow(reviewed$occurrences), selected_spans = nrow(selected),
    common_form_V = length(unique(selected$form)), common_lemma_label_V = length(unique(selected$lemma)),
    full_target_lemma_V = NA_integer_,
    source_N_before = nrow(initial$source$tokens), source_N_after = nrow(reviewed$source$tokens))
  list(reference = reference, annotations = annotations, initial = initial,
    reviewed = reviewed, selected = selected, counts = counts)
})
