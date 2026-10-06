# Explicit optional example: source this file with quanteda installed.
# Authored text, boundaries and lexical candidates, not analyzer predictions,
# corpus extracts, a conversion dictionary or evidence of kanji knowledge.
japanese_orthography_example <- local({
  segments <- data.frame(
    document_id = c("variants", rep("homophones", 3), "unlisted", "no_targets", "empty"),
    segment_id = c("s1", "s1", "s2", "s3", "s1", "s1", "s1"),
    text = c("りんごとリンゴと林檎。", "はしを渡る。", "はしで食べる。",
      "はしを見る。", "ぷにょ語。", "。", ""))
  parts <- list(c("りんご", "と", "リンゴ", "と", "林檎", "。"),
    c("はし", "を", "渡る", "。"), c("はし", "で", "食べる", "。"),
    c("はし", "を", "見る", "。"), c("ぷにょ語", "。"), "。", character())
  annotations <- data.frame(
    document_id = rep(segments$document_id, lengths(parts)),
    segment_id = rep(segments$segment_id, lengths(parts)),
    token_index = sequence(lengths(parts)), surface = unlist(parts, use.names = FALSE))
  imported <- ldfreq::lexdiv_import_annotations(annotations, segments,
    list(language = "ja", analyzer = "authored", analyzer_version = "1",
      dictionary = "authored", dictionary_version = "1",
      unit = "authored-single-token-example", normalization = "none"))

  # Shared IDs explicitly identify the same lexical item across spellings.
  # Readings and display labels are not identifiers; all three HASHI candidates
  # share a reading. Even one supplied candidate is not automatically selected.
  candidates <- data.frame(term = c("りんご", "リンゴ", "林檎", rep("はし", 3)),
    candidate_id = c(rep("apple", 3), "bridge", "chopsticks", "edge"),
    label = c(rep("林檎", 3), "橋", "箸", "端"),
    reading = c(rep("りんご", 3), rep("はし", 3)))
  targets <- c("りんご", "リンゴ", "林檎", "はし", "ぷにょ語")
  resource <- list(resource_id = "authored-ja-orthography", resource_version = "1",
    source_reference = "ldfreq japanese-orthography.R authored example",
    data_license = "MIT", lookup_unit = "exact surface",
    candidate_unit = "illustrative lexical identity; not a word family or sense inventory")
  initial <- ldfreq::lexdiv_ambiguity_review(imported, targets, candidates, resource)
  decisions <- initial$occurrences[initial$occurrences$surface != "ぷにょ語",
    c("review_id", "occurrence_id")]
  decisions$status <- c(rep("selected", 5), "unresolved")
  decisions$candidate_id <- c(rep("apple", 3), "bridge", "chopsticks", NA_character_)
  decisions$reviewer <- "authored-example"
  decisions$reason <- c(rep("Intended fruit in this authored example", 3),
    "Crossing context in this authored example", "Eating context in this authored example",
    "Seeing context does not identify which HASHI; retain alternatives")
  review <- ldfreq::lexdiv_ambiguity_review(imported, targets, candidates, resource, decisions)
  occurrences <- review$occurrences
  selected <- occurrences$status == "selected"
  occurrences$lexical_id <- ifelse(selected, occurrences$candidate_id, NA_character_)
  occurrences$lexical_label <- candidates$label[match(occurrences$lexical_id,
    candidates$candidate_id)]

  # All counts below describe TARGET occurrences, not all words in an essay.
  # Whole-target lexical types require every target to have a selected ID.
  # For partial coverage, compare both units on exactly the same selected rows.
  counts <- do.call(rbind, lapply(imported$documents$document_id, function(id) {
    rows <- which(occurrences$document_id == id)
    common <- rows[selected[rows]]
    n <- length(rows); resolved <- length(common)
    v <- length(unique(occurrences$lexical_id[common]))
    data.frame(document_id = id,
      source_N = sum(imported$tokens$document_id == id),
      target_N = n, selected_N = resolved,
      unreviewed_N = sum(occurrences$status[rows] == "unreviewed"),
      unresolved_N = sum(occurrences$status[rows] == "unresolved"),
      no_candidates_N = sum(occurrences$status[rows] == "no_candidates"),
      selection_coverage = if (n) resolved / n else NA_real_,
      surface_V = length(unique(occurrences$surface[rows])),
      lexical_V = if (resolved == n) v else NA_integer_,
      common_surface_V = length(unique(occurrences$surface[common])),
      common_lexical_V = v)
  }))
  list(imported = imported, initial = initial, review = review,
    occurrences = occurrences, counts = counts,
    scope = "authored target occurrences only; no inferred knowledge or automatic kanji conversion")
})

# Boundary review and lexical review are separate decisions. These complete
# alternative annotations are authored, not an independent segmentation gold
# standard. No characters are changed and no dictionary features are fabricated
# for the joined token. Both alternatives remain in the saved result.
japanese_boundary_example <- local({
  segments <- data.frame(document_id = c("boundary", "empty"), segment_id = "s1",
    text = c("はしではしをつかいます。", ""))
  alternatives <- list(
    split = c("はし", "で", "は", "し", "を", "つかい", "ます", "。"),
    reviewed = c("はし", "で", "はし", "を", "つかい", "ます", "。"))
  inputs <- lapply(names(alternatives), function(condition) {
    surface <- alternatives[[condition]]
    ldfreq::lexdiv_import_annotations(data.frame(document_id = "boundary", segment_id = "s1",
      token_index = seq_along(surface), surface = surface), segments,
      list(language = "ja", analyzer = "authored", analyzer_version = "1",
        dictionary = "none", dictionary_version = "not-applicable",
        unit = paste0("authored-boundary-", condition), normalization = "none"))
  })
  names(inputs) <- names(alternatives)
  alignment <- ldfreq::lexdiv_align_annotations(inputs$split, inputs$reviewed)
  boundary_decisions <- alignment$groups[alignment$groups$relation != "exact",
    c("alignment_id", "document_id", "segment_id", "start", "end", "keyword")]
  boundary_decisions$selected_annotation <- "reviewed"
  boundary_decisions$reviewer <- "authored-example"
  boundary_decisions$reason <- "Intended noun HASHI occupies characters 4-5; lexical identity reviewed separately"

  # The old split exposes only one whole-token HASHI. Recreate the lexical
  # review after reimporting the complete reviewed annotations. Old review IDs
  # must not be carried over silently, even for unchanged text.
  candidates <- data.frame(term = "はし", candidate_id = c("bridge", "chopsticks", "edge"),
    label = c("橋", "箸", "端"), reading = "はし")
  resource <- list(resource_id = "authored-ja-boundary-lexemes", resource_version = "1",
    source_reference = "ldfreq japanese-orthography.R authored boundary example",
    data_license = "MIT", candidate_unit = "illustrative lexical identity")
  before_review <- ldfreq::lexdiv_ambiguity_review(inputs$split, "はし", candidates, resource)
  initial_review <- ldfreq::lexdiv_ambiguity_review(inputs$reviewed, "はし", candidates, resource)
  decisions <- initial_review$occurrences[c("review_id", "occurrence_id")]
  decisions$status <- "selected"
  decisions$candidate_id <- c("bridge", "chopsticks")
  decisions$reviewer <- "authored-example"
  decisions$reason <- c("Author intends the location to be a bridge",
    "Author intends the instrument to be chopsticks; not inferred from spelling")
  review <- ldfreq::lexdiv_ambiguity_review(inputs$reviewed, "はし", candidates, resource, decisions)

  # Use each complete sequence, excluding only the declared punctuation.
  # An exact-span-only subset would discard the changed tokens under study.
  scores <- do.call(rbind, lapply(names(inputs), function(condition) {
    tokens <- inputs[[condition]]$tokens
    do.call(rbind, lapply(inputs[[condition]]$documents$document_id, function(id) {
      keep <- tokens$document_id == id & tokens$surface != "。"
      cbind(condition = condition, document_id = id,
        as.data.frame(ldfreq::lexdiv_metrics(tokens$surface[keep], metrics = "ttr")))
    }))
  }))
  rownames(scores) <- NULL
  list(inputs = inputs, alignment = alignment, boundary_decisions = boundary_decisions,
    before_review = before_review, initial_review = initial_review, review = review,
    scores = scores, selection = "all original surface tokens except the literal full stop; no lexical substitution",
    scope = "authored boundary choices and intended meanings; no analyzer accuracy or proficiency claim")
})
