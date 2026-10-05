# Authored English/Japanese illustration; no model, corpus or network required.
# source(system.file("examples", "annotation-evaluation.R", package = "ldfreq"))
# Result: annotation_evaluation_example. No files are written by this script.
annotation_evaluation_example <- local({
  segments <- data.frame(document_id = c("english", "japanese", "reference_gap", "prediction_gap", "empty"),
    segment_id = "s1", text = c("cats and cats run.", "猫が猫を見る。", "dogs sleep.", "birds sing.", ""))
  tokens <- data.frame(document_id = rep(segments$document_id[1:4], c(5, 6, 3, 3)),
    segment_id = "s1", token_index = c(1:5, 1:6, 1:3, 1:3),
    surface = c("cats", "and", "cats", "run", ".", "猫", "が", "猫", "を", "見る", "。",
      "dogs", "sleep", ".", "birds", "sing", "."),
    upos = c("NOUN", "CCONJ", "NOUN", "VERB", "PUNCT", "NOUN", "ADP", "NOUN", "ADP", "VERB", "PUNCT",
      "NOUN", NA_character_, "PUNCT", "NOUN", "VERB", "PUNCT"))
  tokens$review_status <- ifelse(is.na(tokens$upos), "unresolved", "selected")
  tokens$reviewer <- "authored-reference"
  metadata <- list(language = "en/ja-authored", analyzer = "authored", analyzer_version = "1",
    dictionary = "none", dictionary_version = "not-applicable", unit = "authored-token",
    normalization = "none")
  reference <- ldfreq::lexdiv_import_annotations(tokens, segments, metadata)
  tokens$review_status <- tokens$reviewer <- NULL
  tokens$upos[c(3, 4, 8, 10, 13, 16)] <- c("VERB", "NOUN", "VERB", "NOUN", "VERB", NA_character_)
  tokens$prediction_reason <- ifelse(is.na(tokens$upos), "authored missing prediction", "authored label")
  predicted <- ldfreq::lexdiv_import_annotations(tokens, segments, metadata)
  inputs <- list(predicted = predicted, reference = reference, column = "upos",
    labels = c("NOUN", "VERB", "CCONJ", "ADP", "PUNCT"), context_chars = 12L,
    reference_info = list(reference_id = "authored-reference-v1",
      annotation_protocol = "Authored illustration; labels were not independently collected",
      label_scheme = "UPOS subset for authored tokens", model_exposure = "shown",
      evaluation_role = "development"))
  evaluated <- do.call(ldfreq::lexdiv_evaluate_annotations, inputs)

  # This analysis asks about noun surface diversity. Keep the selection policy
  # fixed across conditions. Completeness is required for the whole document;
  # an unavailable label could be a noun and is not silently treated as negative.
  selected_labels <- "NOUN"
  document_scores <- do.call(rbind, lapply(evaluated$documents$document_id, function(id) {
    pairs <- evaluated$pairs[evaluated$pairs$document_id == id, ]
    do.call(rbind, lapply(c("reference", "predicted"), function(condition) {
      label <- pairs[[paste0(condition, "_label")]]
      chosen <- label %in% selected_labels
      missing <- sum(is.na(label))
      score <- if (!missing) ldfreq::lexdiv_metrics(pairs$surface[chosen], metrics = "ttr") else NULL
      data.frame(document_id = id, condition = condition, source_tokens = nrow(pairs),
        missing_labels = missing, observed_selected = sum(chosen),
        selected_total = if (missing) NA_integer_ else sum(chosen),
        ttr = if (missing) NA_real_ else score$value,
        status = if (missing) "incomplete_annotation" else score$status,
        stringsAsFactors = FALSE)
    }))
  }))
  rownames(document_scores) <- NULL
  ref <- document_scores[document_scores$condition == "reference", ]
  pred <- document_scores[document_scores$condition == "predicted", ]
  differences <- data.frame(document_id = ref$document_id,
    reference_nouns = ref$selected_total, predicted_nouns = pred$selected_total,
    reference_ttr = ref$ttr, predicted_ttr = pred$ttr,
    delta_ttr = pred$ttr - ref$ttr,
    reference_status = ref$status, predicted_status = pred$status)
  list(inputs = inputs, evaluation = evaluated, document_scores = document_scores,
    differences = differences, analysis = list(selected_labels = selected_labels,
      unit = "exact supplied surface; no normalization", metric = "ttr",
      missing_policy = "No document score when any label in that condition is unavailable",
      difference = "predicted minus reference"))
})
