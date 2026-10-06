# Authored English/Japanese examples; no corpus, model or network required.
# source(system.file("examples", "annotation-alignment.R", package = "ldfreq"))
# Result: annotation_alignment_example. This script does not write files.
annotation_alignment_example <- local({
  segments <- data.frame(document_id = c("english", "japanese", "short", "empty"),
    segment_id = "s1", text = c("can't can't re-read.", "国際連合と国際連合。", "猫", ""))
  reference_words <- list(c("can't", "can't", "re-read", "."),
    c("国際連合", "と", "国際連合", "。"), "猫", character())
  predicted_words <- list(c("ca", "n't", "ca", "n't", "re", "-", "read", "."),
    c("国際", "連合", "と", "国際", "連合", "。"), "猫", character())
  metadata <- list(language = "en/ja-authored", analyzer = "authored", analyzer_version = "1",
    dictionary = "none", dictionary_version = "not-applicable", unit = "authored-token",
    normalization = "none")
  make_input <- function(words) {
    data <- do.call(rbind, lapply(seq_along(words), function(i) {
      surface <- words[[i]]
      data.frame(document_id = rep(segments$document_id[i], length(surface)),
        segment_id = rep("s1", length(surface)), token_index = seq_along(surface),
        surface = surface, upos = ifelse(surface %in% c(".", "。", "-"), "PUNCT",
          ifelse(surface == "と", "ADP", ifelse(i == 1, "VERB", "NOUN"))))
    }))
    ldfreq::lexdiv_import_annotations(data, segments, metadata)
  }
  inputs <- list(predicted = make_input(predicted_words), reference = make_input(reference_words),
    column = "upos", labels = c("NOUN", "VERB", "ADP", "PUNCT"), context_chars = 12L,
    reference_info = list(reference_id = "authored-segmentation-v1",
      annotation_protocol = "Authored contrast; neither segmentation is an independent gold standard",
      label_scheme = "Illustrative UPOS subset; compound labels are not propagated to their parts",
      model_exposure = "shown", evaluation_role = "development"))
  alignment <- do.call(ldfreq::lexdiv_align_annotations, inputs)
  # Compare whole supplied sequences, not just aligned tokens. A label-free
  # policy isolates segmentation differences and remains usable with absent POS.
  document_scores <- do.call(rbind, lapply(segments$document_id, function(id) {
    do.call(rbind, lapply(c("reference", "predicted"), function(condition) {
      tokens <- inputs[[condition]]$tokens
      words <- tokens$surface[tokens$document_id == id]
      score <- ldfreq::lexdiv_metrics(words, metrics = c("ttr", "mattr"), window_length = 4L)
      cbind(document_id = id, condition = condition,
        as.data.frame(score))
    }))
  }))
  rownames(document_scores) <- NULL
  ref <- subset(document_scores, condition == "reference")
  pred <- subset(document_scores, condition == "predicted")
  differences <- data.frame(document_id = ref$document_id, metric_id = ref$metric_id,
    reference_N = ref$N, predicted_N = pred$N, reference_V = ref$V, predicted_V = pred$V,
    reference_value = ref$value, predicted_value = pred$value,
    delta = pred$value - ref$value, reference_status = ref$status, predicted_status = pred$status)
  list(inputs = inputs, alignment = alignment, document_scores = document_scores,
    differences = differences, analysis = list(unit = "exact supplied surface; no normalization",
      selection = "all supplied tokens, including punctuation; no POS selection",
      metrics = c("ttr", "mattr"), window_length = 4L, difference = "predicted minus reference"))
})
