# Source explicitly. Authored examples, not a tagger, NER system, spelling
# dictionary or new public API. No downloads or file writes.
lexical_counting_example <- local({
  segments <- data.frame(document_id = c("variants", "names", "numerals", "symbols",
    "technical", "protected_name", "unknown", "empty"), segment_id = "s1",
    text = c("The colour is color.", "Rose saw a rose.",
      "Two birds saw 2 birds in 2026.", "Cats + dogs = 2.",
      "C++ and C are different.", "Colour sells colour.", "Glorp runs.", ""))
  words <- list(c("The", "colour", "is", "color", "."),
    c("Rose", "saw", "a", "rose", "."),
    c("Two", "birds", "saw", "2", "birds", "in", "2026", "."),
    c("Cats", "+", "dogs", "=", "2", "."),
    c("C++", "and", "C", "are", "different", "."),
    c("Colour", "sells", "colour", "."), c("Glorp", "runs", "."), character())
  tags <- list(c("DET", "NOUN", "AUX", "NOUN", "PUNCT"),
    c("PROPN", "VERB", "DET", "NOUN", "PUNCT"),
    c("NUM", "NOUN", "VERB", "NUM", "NOUN", "ADP", "NUM", "PUNCT"),
    c("NOUN", "SYM", "NOUN", "SYM", "NUM", "PUNCT"),
    c("PROPN", "CCONJ", "PROPN", "AUX", "ADJ", "PUNCT"),
    c("PROPN", "VERB", "NOUN", "PUNCT"), c(NA_character_, "VERB", "PUNCT"), character())
  tokens <- do.call(rbind, lapply(seq_along(words), function(i)
    data.frame(document_id = rep(segments$document_id[i], length(words[[i]])),
      segment_id = rep("s1", length(words[[i]])), token_index = seq_along(words[[i]]),
      surface = words[[i]], upos = tags[[i]])))
  annotation <- ldfreq::lexdiv_import_annotations(tokens, segments,
    list(language = "en", analyzer = "authored-complete-tokens", analyzer_version = "1",
      dictionary = "none", dictionary_version = "not-applicable", unit = "authored-token",
      normalization = "none"))
  # Only three illustrative NOUN equivalences, not automatic British-to-American
  # conversion. Protect proper-name occurrences; never use suffix replacement.
  aliases <- data.frame(surface_key = c("colour", "centre", "theatre"),
    upos = "NOUN", reference_key = c("color", "center", "theater"),
    decision = "approved", reviewer = "example-author",
    reason = "Declared spelling equivalence for common-noun examples; not an error")
  alias_info <- list(id = "authored-three-noun-spelling-aliases", version = "1",
    sha256 = digest::digest(aliases, algo = "sha256", serializeVersion = 2L),
    scope = "Exact lowercased surface plus supplied NOUN; no inflection or suffix rules")
  audit <- annotation$tokens
  audit$surface_key <- stringi::stri_trans_tolower(audit$surface, locale = "en")
  approved <- aliases[aliases$decision == "approved", ]
  stopifnot(!anyDuplicated(approved[c("surface_key", "upos")]))
  index <- match(paste(audit$surface_key, audit$upos), paste(approved$surface_key, approved$upos))
  audit$alias_applied <- !is.na(index)
  audit$reference_key <- audit$surface_key
  audit$reference_key[audit$alias_applied] <- approved$reference_key[index[audit$alias_applied]]
  # Selection and spelling equivalence are independent decisions. Full source
  # rows remain intact; each filtered view keeps its original token_index.
  policies <- list(
    words_and_numerals = list(exclude = c("PUNCT", "SYM"), canonicalize = FALSE),
    without_proper_nouns = list(exclude = c("PUNCT", "SYM", "PROPN"), canonicalize = FALSE),
    without_numerals = list(exclude = c("PUNCT", "SYM", "NUM"), canonicalize = FALSE),
    without_names_or_numerals = list(exclude = c("PUNCT", "SYM", "PROPN", "NUM"), canonicalize = FALSE),
    spelling_equivalence = list(exclude = c("PUNCT", "SYM"), canonicalize = TRUE))
  runs <- selections <- metric_rows <- coverage_rows <- list()
  for (policy in names(policies)) {
    rule <- policies[[policy]]
    view <- audit
    view$eligible <- ifelse(is.na(view$upos), NA, !view$upos %in% rule$exclude)
    view$exclusion_reason <- ifelse(is.na(view$upos), "unknown_upos",
      ifelse(view$eligible, NA_character_, paste0("excluded_", view$upos)))
    view$term <- if (rule$canonicalize) view$reference_key else view$surface_key
    selections[[policy]] <- view
    runs[[policy]] <- list()
    for (id in segments$document_id) {
      rows <- view$document_id == id
      selected <- view[rows & view$eligible %in% TRUE, , drop = FALSE]
      unknown <- sum(is.na(view$eligible[rows]))
      diversity <- ldfreq::lexdiv_metrics(selected$term,
        metrics = c("ttr", "mattr"), window_length = 3L)
      exact <- ldfreq::nj8_profile(selected$surface_key, unit = "surface")
      aliased <- ldfreq::nj8_profile(selected$reference_key, unit = "surface")
      # These query positions index the selected vector. Link them explicitly
      # to original token positions; do not call canonical keys source surfaces.
      query_audit <- selected
      query_audit$exact_matched <- exact$lookup$matched
      query_audit$alias_matched <- aliased$lookup$matched
      runs[[policy]][[id]] <- list(diversity = diversity, exact = exact,
        aliased = aliased, query_audit = query_audit)
      k <- length(metric_rows) + 1L
      metric_rows[[k]] <- data.frame(policy = policy, document_id = id,
        metric_id = diversity$metric_id, selected_known = diversity$N,
        types_known = diversity$V, unknown_upos = unknown,
        excluded_known = sum(view$eligible[rows] %in% FALSE),
        conditional_value = diversity$value,
        reportable_value = if (unknown) NA_real_ else diversity$value,
        status = if (unknown) "unknown_selection" else diversity$status,
        missing_reason = if (unknown) "unknown_upos" else diversity$missing_reason)
      coverage_rows[[k]] <- data.frame(policy = policy, document_id = id,
        selected_known = nrow(selected), unknown_upos = unknown,
        exact_matched = exact$coverage$matched_tokens,
        alias_matched = aliased$coverage$matched_tokens,
        exact_coverage_conditional = exact$coverage$token_coverage,
        alias_coverage_conditional = aliased$coverage$token_coverage)
    }
  }
  # Punctuation/symbol/name/number exclusions break adjacency. A lexical tokenizer
  # has already dropped punctuation, so cannot recreate these gaps afterwards.
  view <- selections$without_names_or_numerals
  bigrams <- ldfreq::lexdiv_ngrams(view[view$eligible %in% TRUE, ],
    preprocessing_id = "authored-complete-positions-no-propn-num-punct-sym-v1",
    n = 2L, documents = segments$document_id)
  probes <- lapply(c("Two 2 2nd COVID-19 3.14 75%", "C++ R&D #topic @user",
    "can't well-known word\u2014word", "1,000 1000"), function(text)
      list(text = text, tokens = ldfreq::lexdiv_tokenize(text,
        tokenizer = "english", keep_numbers = TRUE)))
  list(annotation = annotation, aliases = aliases, alias_info = alias_info,
    policies = policies, selections = selections, runs = runs,
    metrics = do.call(rbind, metric_rows), coverage = do.call(rbind, coverage_rows),
    bigrams = bigrams, tokenizer_probes = probes,
    settings = list(case_for_counting = "lower-en-after-annotation",
      metrics = c("ttr", "mattr"), window_length = 3L,
      sequence = "selected tokens in original order; MATTR windows use selected tokens",
      unknown_upos = "retain rows; show conditional metrics; full-policy value unavailable",
      reference = "NJ8 exact and reviewed alias queries; original surface retained",
      ldfreq_version = as.character(utils::packageVersion("ldfreq"))))
})
# Save the whole object, including source, annotations, mappings, policies and
# reference objects, plus sessionInfo(). The output contains source text.
# saveRDS(list(result = lexical_counting_example, session = sessionInfo()), path)
