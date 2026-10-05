# Authored basic-UD examples, not independent parser accuracy data.
# No corpus, model, network access or file writes are required.
amod_pairs_example <- local({
  segments <- data.frame(document_id = c("english", "wrong_head", "japanese", "zero",
    "unavailable", "partial", "partial", "empty"),
    segment_id = c(rep("s1", 6), "s2", "s1"),
    text = c("Big red balloons float.", "Small birds see large fish.",
      "赤い鳥を見る。", "Birds fly.", "Quiet birds rest.",
      "Red birds fly.", "Blue birds fly.", ""))
  surfaces <- list(c("Big", "red", "balloons", "float", "."),
    c("Small", "birds", "see", "large", "fish", "."),
    c("赤い", "鳥", "を", "見る", "。"), c("Birds", "fly", "."),
    c("Quiet", "birds", "rest", "."), c("Red", "birds", "fly", "."),
    c("Blue", "birds", "fly", "."), character())
  data <- segments[rep(seq_len(nrow(segments)), lengths(surfaces)), c("document_id", "segment_id")]
  data$token_index <- unlist(lapply(surfaces, seq_along), use.names = FALSE)
  data$surface <- unlist(surfaces, use.names = FALSE)
  data$lemma <- c("big", "red", "balloon", "float", ".", "small", "bird", "see", "large", "fish", ".",
    "赤い", "鳥", "を", "見る", "。", "bird", "fly", ".", "quiet", "bird", "rest", ".",
    "red", "bird", "fly", ".", "blue", "bird", "fly", ".")
  data$upos <- c("ADJ", "ADJ", "NOUN", "VERB", "PUNCT", "ADJ", "NOUN", "VERB", "ADJ", "NOUN", "PUNCT",
    "ADJ", "NOUN", "ADP", "VERB", "PUNCT", "NOUN", "VERB", "PUNCT",
    rep(c("ADJ", "NOUN", "VERB", "PUNCT"), 3))
  data$head <- c(3, 3, 4, 0, 4, 2, 3, 0, 5, 3, 3, 2, 4, 2, 0, 4, 2, 0, 2,
    rep(c(2, 3, 0, 3), 3))
  data$deprel <- c("amod", "amod", "nsubj", "root", "punct", "amod", "nsubj", "root", "amod", "obj", "punct",
    "amod", "obj", "case", "root", "punct", "nsubj", "root", "punct",
    rep(c("amod", "nsubj", "root", "punct"), 3))
  metadata <- list(language = "en/ja-authored", analyzer = "authored-basic-UD", analyzer_version = "1",
    dictionary = "none", dictionary_version = "not-applicable", unit = "authored-syntactic-word",
    normalization = "none")
  reference <- ldfreq::lexdiv_import_annotations(data, segments, metadata)
  data$head[1] <- 4 # The supplied head is a verb: outside the declared feature.
  data$head[6] <- 5 # Same pair count, but a different noun and source occurrence.
  data$deprel[12] <- "dep" # Omitted amod relation.
  missing <- data$document_id == "unavailable" |
    (data$document_id == "partial" & data$segment_id == "s2")
  data$head[missing] <- NA_real_
  data$deprel[missing] <- NA_character_
  predicted <- ldfreq::lexdiv_import_annotations(data, segments, metadata)
  inputs <- list(reference = reference, predicted = predicted, unit = "lemma")
  reference_pairs <- ldfreq::lexdiv_amod_pairs(reference, unit = inputs$unit)
  predicted_pairs <- ldfreq::lexdiv_amod_pairs(predicted, unit = inputs$unit)

  # Pair identity uses both endpoints, never just words or the number of pairs.
  identity <- c("document_id", "segment_id", "dependent_start", "dependent_end", "head_start", "head_end")
  ref <- reference_pairs$occurrences[identity]
  pred <- predicted_pairs$occurrences[identity]
  ref$reference_present <- rep(TRUE, nrow(ref))
  pred$predicted_present <- rep(TRUE, nrow(pred))
  comparison <- merge(ref, pred, by = identity, all = TRUE, sort = FALSE)
  comparison$reference_present[is.na(comparison$reference_present)] <- FALSE
  comparison$predicted_present[is.na(comparison$predicted_present)] <- FALSE
  ref_docs <- reference_pairs$documents
  pred_docs <- predicted_pairs$documents[match(ref_docs$document_id, predicted_pairs$documents$document_id), ]
  complete <- ref_docs$status != "incomplete_annotation" & pred_docs$status != "incomplete_annotation"
  comparison$evaluated <- complete[match(comparison$document_id, ref_docs$document_id)]
  comparison$outcome <- ifelse(!comparison$evaluated, "not_evaluated",
    ifelse(comparison$reference_present & comparison$predicted_present, "tp",
      ifelse(comparison$reference_present, "fn", "fp")))
  differences <- data.frame(document_id = ref_docs$document_id,
    reference_pairs = ref_docs$pairs, predicted_pairs = pred_docs$pairs,
    delta_pairs = pred_docs$pairs - ref_docs$pairs,
    reference_types = ref_docs$types, predicted_types = pred_docs$types,
    reference_coverage = ref_docs$token_coverage, predicted_coverage = pred_docs$token_coverage,
    evaluated = complete)
  for (outcome in c("tp", "fp", "fn"))
    differences[[outcome]] <- vapply(seq_len(nrow(differences)), function(i) {
      if (!complete[i]) return(NA_integer_)
      sum(comparison$document_id == differences$document_id[i] & comparison$outcome == outcome)
    }, integer(1))
  list(inputs = inputs, reference = reference_pairs, predicted = predicted_pairs,
    comparison = comparison, differences = differences,
    reference_info = list(reference_id = "authored-basic-UD-v1", model_exposure = "shown",
      evaluation_role = "development", annotation_protocol = "Authored fixtures, not independent human judgments",
      feature = reference_pairs$provenance$feature))
})
