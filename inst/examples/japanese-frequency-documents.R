# Explicit recipes, not exported APIs. No downloads, inference or file writes.
sys.source(system.file("examples", "japanese-document-profile.R", package = "ldfreq", mustWork = TRUE),
  envir = environment())

japanese_frequency_documents <- function(profile, keys, reference) {
  fail <- function(message) stop(message, call. = FALSE)
  if (!is.list(profile) || !all(c("imported", "selection", "policy", "documents") %in% names(profile)))
    fail("Supply a complete Japanese document profile.")
  p <- profile$policy
  checked <- japanese_document_profile(profile$imported, profile$selection, p$pos_groups,
    p$condition, p$pos_col, p$origin_col)
  fields <- setdiff(names(checked), "software")
  if (!identical(checked[fields], profile[fields])) fail("Document profile changed; rebuild it from complete inputs.")
  anchors <- c("document_id", "segment_id", "token_index", "start", "end", "surface")
  required <- c(anchors, "lookup_term", "key_reason")
  if (!identical(class(keys), "data.frame") || anyDuplicated(names(keys)) ||
      !all(required %in% names(keys)) || anyDuplicated(keys[anchors]) || anyNA(keys[anchors]) ||
      !all(vapply(keys[c("document_id", "segment_id", "surface", "lookup_term", "key_reason")], is.character, logical(1))) ||
      !all(vapply(keys[c("token_index", "start", "end")], is.numeric, logical(1))) ||
      anyNA(keys$key_reason) || any(!nzchar(stringi::stri_trim_both(keys$key_reason))) ||
      any(!is.na(keys$lookup_term) & (!nzchar(stringi::stri_trim_both(keys$lookup_term)) | keys$lookup_term == "*")))
    fail("Supply complete unique anchors, lookup_term (NA if unresolved), and nonblank key_reason.")
  t <- profile$tokens
  rows <- t[anchors]; rows$.frequency_row <- seq_len(nrow(rows))
  joined <- merge(rows, keys[required], by = anchors, all = TRUE, sort = FALSE)
  if (nrow(joined) != nrow(t) || anyNA(joined$.frequency_row) || anyNA(joined$key_reason))
    fail("Keys must cover every original token with unchanged source anchors.")
  joined <- joined[order(joined$.frequency_row), ]; rownames(joined) <- NULL
  keys <- joined[required]
  t$lookup_term <- keys$lookup_term; t$key_reason <- keys$key_reason
  if (!is.list(reference) || !all(c("norms", "key", "measure_specs", "resource") %in% names(reference)))
    fail("Supply norms, key, measure_specs and resource for the reference.")
  ids <- profile$documents$document_id
  terms <- stats::setNames(lapply(ids, function(id)
    t$lookup_term[t$document_id == id & t$retained & !is.na(t$lookup_term)]), ids)
  # Reuse the public implementation for validation, means, token/type weighting
  # and all measure-level missingness; no independent frequency formula here.
  norms <- ldfreq::lexdiv_norm_profile_batch(terms, reference$norms, reference$key,
    reference$measure_specs, reference$resource)
  # Validate even excluded keys, which never enter the document summaries.
  all_keys <- t$lookup_term[!is.na(t$lookup_term)]
  if (any(!validUTF8(all_keys)) || any(Encoding(all_keys) %in% c("bytes", "latin1")))
    fail("Lookup terms must be valid UTF-8.")
  index <- match(t$lookup_term, reference$norms[[reference$key]])
  t$lookup_status <- ifelse(is.na(t$lookup_term), "unresolved_key",
    ifelse(is.na(index), "unmatched", "matched"))
  specs <- reference$measure_specs
  for (i in seq_len(nrow(specs)))
    t[[paste0("value_", specs$measure_id[i])]] <- reference$norms[[specs$value_column[i]]][index]
  documents <- profile$documents
  for (status in c("unresolved_key", "unmatched", "matched"))
    documents[[paste0(status, "_N")]] <- vapply(ids, function(id)
      sum(t$document_id == id & t$retained & t$lookup_status == status), integer(1))
  documents$keyed_N <- documents$retained_N - documents$unresolved_key_N
  documents$key_coverage <- ifelse(documents$retained_N > 0,
    documents$keyed_N / documents$retained_N, NA_real_)
  documents$matched_coverage <- ifelse(documents$retained_N > 0,
    documents$matched_N / documents$retained_N, NA_real_)
  list(documents = documents, occurrences = t, norms = norms,
    source_profile = profile, keys = keys, reference = reference,
    policy = list(key_matching = "Exact supplied keys; no normalization or lexical inference",
      document_coverage = "Matched retained tokens / all retained tokens, including unresolved keys",
      norm_denominators = "Only resolved keys enter norm summaries; type means use unique exact lookup keys",
      means = "Observed matched values only; keep missing values distinct from observed zero"))
}

common_japanese_frequency <- function(profiles) {
  if (!is.list(profiles) || length(profiles) < 2L || is.null(names(profiles)) ||
      anyNA(names(profiles)) || any(!nzchar(names(profiles))) || anyDuplicated(names(profiles)))
    stop("Supply a named list of at least two complete frequency profiles.", call. = FALSE)
  first <- profiles[[1]]
  anchors <- c("document_id", "segment_id", "token_index", "start", "end", "surface")
  # Token numbers can shift after a split: commonality uses source spans instead.
  spans <- setdiff(anchors, "token_index")
  text_fields <- c("document_id", "segment_id", "text")
  value_cols <- paste0("value_", first$reference$measure_specs$measure_id)
  eligible <- lapply(profiles, function(x) {
    rebuilt <- japanese_frequency_documents(x$source_profile, x$keys, x$reference)
    if (!identical(rebuilt, x)) stop("Use unchanged frequency profiles.", call. = FALSE)
    if (!identical(x$reference, first$reference) ||
        !identical(x$source_profile$imported$segments[text_fields],
          first$source_profile$imported$segments[text_fields]))
      stop("Compare the same complete source segments and the same reference.", call. = FALSE)
    t <- x$occurrences
    t[t$retained & t$lookup_status == "matched" & stats::complete.cases(t[value_cols]), spans]
  })
  common <- Reduce(function(x, y) merge(x, y, by = spans, sort = FALSE), eligible)
  common <- common[do.call(order, common[spans]), , drop = FALSE]; rownames(common) <- NULL
  compared <- lapply(profiles, function(x) {
    p <- x$source_profile; mask <- p$selection
    rows <- mask[spans]; rows$.row <- seq_len(nrow(mask))
    shared <- merge(rows, common, by = spans, sort = FALSE)$.row
    keep <- seq_len(nrow(mask)) %in% shared
    mask$reason[mask$retained & !keep] <- "not_common_observed_span"
    mask$retained <- mask$retained & keep
    q <- japanese_document_profile(p$imported, mask, p$policy$pos_groups,
      paste0("common:", p$policy$condition), p$policy$pos_col, p$policy$origin_col)
    japanese_frequency_documents(q, x$keys, x$reference)
  })
  list(all = profiles, common = compared, common_spans = common,
    policy = paste("Same source document/segment/start/end/surface, retained and matched in every condition;",
      "all supplied measures observed in every condition. Changed-boundary spans are excluded;",
      "this conservative intersection does not align or combine split tokens."))
}

plot_japanese_frequency_coverage <- function(x, monochrome = FALSE) {
  if (!is.logical(monochrome) || length(monochrome) != 1L || is.na(monochrome))
    stop("monochrome must be TRUE or FALSE.", call. = FALSE)
  if (!requireNamespace("ggplot2", quietly = TRUE)) stop("Install ggplot2 to plot coverage.")
  d <- x$documents
  d$document <- factor(d$document_id, levels = rev(d$document_id))
  ggplot2::ggplot(d, ggplot2::aes(x = matched_coverage, y = document)) +
    ggplot2::geom_point(colour = if (monochrome) "black" else "#0072B2", size = 2.5, na.rm = TRUE) +
    ggplot2::scale_x_continuous(limits = c(0, 1), breaks = seq(0, 1, .25)) +
    ggplot2::scale_y_discrete(drop = FALSE) +
    ggplot2::labs(x = "Matched tokens / all retained tokens", y = "Document") +
    ggplot2::theme_classic(base_size = 12)
}
