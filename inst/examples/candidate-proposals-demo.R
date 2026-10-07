# Authored Japanese example; no API call, no independent accuracy evidence.
# Source candidate-proposals.R into the same environment before this file.
candidate_proposals_example <- local({
  words <- list(c("あの", "店", "は", "若者", "に", "人気", "が", "ある", "。"),
    c("深夜", "の", "公園", "に", "は", "人気", "が", "なく", "、", "誰", "も", "い", "なかっ", "た", "。"),
    c("ここ", "は", "人気", "が", "ない", "。"), c("駅", "に", "着い", "た", "。"))
  segments <- data.frame(document_id = paste0("authored-", 1:4), segment_id = "s1",
    text = vapply(words, paste0, character(1), collapse = ""))
  tokens <- data.frame(document_id = rep(segments$document_id, lengths(words)), segment_id = "s1",
    token_index = sequence(lengths(words)), surface = unlist(words, use.names = FALSE))
  annotations <- ldfreq::lexdiv_import_annotations(tokens, segments, list(language = "ja",
    analyzer = "authored", analyzer_version = "1", dictionary = "authored", dictionary_version = "1",
    unit = "authored tokens, not validated UniDic units", normalization = "none"))
  candidates <- data.frame(term = "人気", candidate_id = c("popularity", "human-presence"),
    label = c("人気（にんき）: people liking or supporting someone or something",
      "人気（ひとけ）: signs of people being present"))
  resource <- list(resource_id = "authored-proposal-demo", resource_version = "1",
    source_reference = "Authored labels, not a dictionary or gold standard", data_license = "MIT")
  review <- ldfreq::lexdiv_ambiguity_review(annotations, c("人気", "駅"), candidates, resource)
  plan <- prepare_candidate_proposals(review, review$occurrences$occurrence_id[1:3])
  proposals <- data.frame(occurrence_id = plan$anchors$occurrence_id,
    proposal_status = c("selected", "selected", "unresolved"),
    candidate_id = c("popularity", "human-presence", NA_character_),
    reason = c("Authored: being liked by young people", "Authored: nobody in the park",
      "Authored: this context does not settle the reading"))
  model <- list(model_id = "authored", model_revision = "1", prompt_version = "none")
  imported <- import_candidate_proposals(review, plan, proposals, model)
  list(review = review, plan = plan, proposals = proposals, model = model, imported = imported)
})
