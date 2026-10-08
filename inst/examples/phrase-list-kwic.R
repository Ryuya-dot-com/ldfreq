# Copyable example helper; source explicitly. This is not an exported API.
# Search belongs to quanteda; source alignment and denominators remain explicit.
phrase_list_kwic <- function(x, phrases, resource, keep = rep(TRUE, nrow(x$tokens)),
                             window = 5L) {
  if (!is.list(x) || !identical(x$provenance$importer, "ldfreq-external-annotations"))
    stop("x must be an unmodified lexdiv_import_annotations() result.")
  checked <- ldfreq::lexdiv_import_annotations(x$tokens,
    x$segments[setdiff(names(x$segments), c("token_count", "text_sha256"))],
    x$provenance$annotation)
  if (!identical(x, checked)) stop("x has changed; import complete annotations again.")
  valid_strings <- function(z) is.character(z) && length(z) > 0L &&
    !anyNA(z) && all(validUTF8(z)) && all(nzchar(stringi::stri_trim_both(z)))
  if (!is.list(phrases) || !length(phrases) ||
      !valid_strings(names(phrases)) || anyDuplicated(names(phrases)) ||
      !all(vapply(phrases, function(z) valid_strings(z) && length(z) >= 2L &&
        !any(stringi::stri_detect_regex(z, "\\p{White_Space}")), logical(1))))
    stop("phrases needs unique nonblank IDs and at least two non-whitespace tokens per ID.")
  required <- c("resource_id", "resource_version", "source_reference", "data_license")
  if (!is.list(resource) || !all(required %in% names(resource)) ||
      anyDuplicated(names(resource)) || !valid_strings(names(resource)) ||
      !all(vapply(resource, function(z) valid_strings(z) && length(z) == 1L, logical(1))))
    stop("resource needs resource_id, resource_version, source_reference and data_license strings.")
  if (!is.logical(keep) || length(keep) != nrow(x$tokens) || anyNA(keep))
    stop("keep must contain one non-missing logical value per original token.")
  if (!is.numeric(window) || length(window) != 1L || is.na(window) ||
      !is.finite(window) || window < 0 || window != floor(window) ||
      window > .Machine$integer.max) stop("window must be a non-negative integer.")
  # Filtering retains original indices/counts, including trailing gaps.
  q <- ldfreq::lexdiv_as_quanteda(x$tokens[keep, , drop = FALSE], x$segments)
  offsets <- c(0, head(cumsum(x$segments$token_count), -1L))
  pieces <- lapply(seq_along(phrases), function(i) {
    # One sequence per call preserves distinct caller IDs even for identical lists.
    kw <- as.data.frame(quanteda::kwic(q$tokens, unname(phrases[i]), window = 0L,
      valuetype = "fixed", case_insensitive = FALSE))
    group <- match(kw$docname, q$segments$quanteda_docname)
    first <- offsets[group] + kw$from
    last <- offsets[group] + kw$to
    if (anyNA(group) || any(kw$to - kw$from + 1L != length(phrases[[i]])))
      stop("KWIC changed the expected segment or phrase length.")
    # quanteda fixed matching can treat canonically equivalent Unicode as equal.
    # Require the original, unnormalized component strings to match as well.
    exact <- vapply(seq_len(nrow(kw)), function(j) {
      rows <- seq.int(first[j], last[j])
      all(keep[rows]) && identical(unname(x$tokens$surface[rows]), unname(phrases[[i]]))
    }, logical(1))
    kw <- kw[exact, , drop = FALSE]; group <- group[exact]
    first <- first[exact]; last <- last[exact]
    start <- x$tokens$start[first]; end <- x$tokens$end[last]
    text <- x$segments$text[group]
    left <- offsets[group] + pmax(1, kw$from - window)
    right <- offsets[group] + pmin(x$segments$token_count[group], kw$to + window)
    data.frame(phrase_id = rep(names(phrases)[i], length(group)),
      document_id = x$segments$document_id[group], segment_id = x$segments$segment_id[group],
      from = kw$from, to = kw$to, start = start, end = end,
      pre = if (window == 0L) rep("", length(group)) else
        stringi::stri_sub(text, x$tokens$start[left], start - 1L),
      keyword = stringi::stri_sub(text, start, end),
      post = if (window == 0L) rep("", length(group)) else
        stringi::stri_sub(text, end + 1L, x$tokens$end[right]),
      segment_text = text, stringsAsFactors = FALSE)
  })
  occurrences <- do.call(rbind, pieces); rownames(occurrences) <- NULL
  # Per-ID counts and union coverage answer different questions.
  ids <- x$documents$document_id
  counts <- expand.grid(document_id = ids, phrase_id = names(phrases),
    KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
  cells <- match(occurrences$document_id, ids) +
    (match(occurrences$phrase_id, names(phrases)) - 1L) * length(ids)
  counts$occurrences <- tabulate(cells, nbins = nrow(counts))
  covered <- rep(FALSE, nrow(x$tokens))
  for (i in seq_len(nrow(occurrences))) {
    hit <- occurrences[i, ]
    group <- which(x$segments$document_id == hit$document_id &
      x$segments$segment_id == hit$segment_id)
    covered[offsets[group] + seq.int(hit$from, hit$to)] <- TRUE
  }
  token_doc <- match(x$tokens$document_id, ids)
  documents <- data.frame(document_id = ids,
    source_tokens = tabulate(token_doc, length(ids)),
    retained_tokens = tabulate(token_doc[keep], length(ids)),
    occurrences = tabulate(match(occurrences$document_id, ids), length(ids)),
    covered_tokens = tabulate(token_doc[covered], length(ids)))
  documents$coverage <- ifelse(documents$retained_tokens > 0,
    documents$covered_tokens / documents$retained_tokens, NA_real_)
  summary <- data.frame(phrase_id = names(phrases), tokens = lengths(phrases),
    occurrences = vapply(names(phrases), function(id)
      sum(counts$occurrences[counts$phrase_id == id]), numeric(1)),
    documents = vapply(names(phrases), function(id)
      sum(counts$occurrences[counts$phrase_id == id] > 0L), integer(1)), row.names = NULL)
  settings <- list(matching = "exact-case-sensitive-unnormalized-surface",
    overlap = "all-per-ID-occurrences; union-token-coverage", window = window,
    context_unit = "original-token-slots; segment-local-codepoint-offsets",
    coverage_denominator = "retained-tokens; NA-when-zero", keep = keep)
  list(occurrences = occurrences, counts = counts, documents = documents, summary = summary,
    source = x, phrases = phrases, resource = resource, settings = settings,
    provenance = list(example_version = "1", ldfreq_version = as.character(utils::packageVersion("ldfreq")),
      quanteda_version = as.character(utils::packageVersion("quanteda")),
      input_sha256 = digest::digest(list(x$provenance, phrases, resource, settings),
        algo = "sha256", serializeVersion = 2L)))
}

# Review exact list matches under one declared criterion. Not a sense classifier
# or an exported API. Source tokens and existing lexical metrics are unchanged.
phrase_list_review <- function(result, criterion, worksheet = NULL) {
  fail <- function(message) stop(message, call. = FALSE)
  blank <- function(x) is.na(x) | !nzchar(stringi::stri_trim_both(x))
  if (!is.character(criterion) || length(criterion) != 1L ||
      any(blank(criterion)) || !validUTF8(criterion))
    fail("Declare one nonblank UTF-8 review criterion.")
  if (!is.list(result) || !all(c("source", "phrases", "resource", "settings") %in% names(result)))
    fail("Supply an unchanged phrase_list_kwic() result.")
  # ponytail: replay the existing search for modest inspectable lists; a large
  # dictionary workflow would need separately validated occurrence storage.
  checked <- phrase_list_kwic(result$source, result$phrases, result$resource,
    result$settings$keep, result$settings$window)
  if (!identical(checked, result))
    fail("The search result changed; repeat phrase_list_kwic() before review.")
  hash <- function(x) digest::digest(x, algo = "sha256", serializeVersion = 2L)
  review_id <- hash(list("phrase-list-review-v1", result$provenance$input_sha256, criterion))
  hits <- result$occurrences
  anchors <- c("phrase_id", "document_id", "segment_id", "from", "to", "start", "end", "keyword")
  hits$review_id <- rep(review_id, nrow(hits))
  hits$occurrence_id <- vapply(seq_len(nrow(hits)), function(i)
    hash(as.list(hits[i, anchors, drop = FALSE])), character(1))
  fixed <- c("review_id", "occurrence_id", anchors)
  editable <- c("status", "reviewer", "reason")
  expected <- as.data.frame(lapply(hits[fixed], as.character), stringsAsFactors = FALSE)
  if (is.null(worksheet)) {
    worksheet <- expected
    worksheet$status <- rep("unreviewed", nrow(hits))
    worksheet$reviewer <- worksheet$reason <- rep(NA_character_, nrow(hits))
  }
  if (!is.data.frame(worksheet) || anyDuplicated(names(worksheet)) ||
      !setequal(names(worksheet), c(fixed, editable)) ||
      !all(vapply(worksheet, is.character, logical(1))))
    fail("Keep the worksheet columns as character; edit only status, reviewer and reason.")
  if (anyNA(worksheet[fixed]) || anyDuplicated(worksheet$occurrence_id) ||
      !setequal(worksheet$occurrence_id, expected$occurrence_id))
    fail("Keep every original occurrence ID exactly once, including unreviewed rows.")
  worksheet <- worksheet[match(expected$occurrence_id, worksheet$occurrence_id), c(fixed, editable)]
  rownames(worksheet) <- NULL
  for (field in fixed) if (!identical(worksheet[[field]], expected[[field]]))
    fail(paste("A fixed worksheet field changed:", field))
  states <- c("accepted", "rejected", "unresolved", "unreviewed")
  if (anyNA(worksheet$status) || any(!worksheet$status %in% states))
    fail("Status must be accepted, rejected, unresolved or unreviewed.")
  submitted <- worksheet$status != "unreviewed"
  if (any(submitted & (blank(worksheet$reviewer) | blank(worksheet$reason))))
    fail("Every submitted decision, including unresolved, needs a reviewer and reason.")
  if (any(!submitted & (!blank(worksheet$reviewer) | !blank(worksheet$reason))))
    fail("An unreviewed row is partly filled; submit a decision or clear reviewer and reason.")
  if (any(!vapply(worksheet[editable], function(x) all(validUTF8(x[!is.na(x)])), logical(1))))
    fail("Decision text must be valid UTF-8.")
  worksheet$reviewer[!submitted] <- worksheet$reason[!submitted] <- NA_character_
  hits[editable] <- worksheet[editable]

  documents <- result$documents
  counts <- result$counts
  ids <- documents$document_id
  document_row <- match(hits$document_id, ids)
  cell <- document_row + (match(hits$phrase_id, names(result$phrases)) - 1L) * length(ids)
  for (state in states) {
    documents[[state]] <- tabulate(document_row[hits$status == state], nrow(documents))
    counts[[state]] <- tabulate(cell[hits$status == state], nrow(counts))
  }
  # Accepted spans contribute their union of original slots, never summed lengths.
  source <- result$source
  offsets <- c(0, head(cumsum(source$segments$token_count), -1L))
  covered <- rep(FALSE, nrow(source$tokens))
  for (i in which(hits$status == "accepted")) {
    group <- which(source$segments$document_id == hits$document_id[i] &
      source$segments$segment_id == hits$segment_id[i])
    covered[offsets[group] + seq.int(hits$from[i], hits$to[i])] <- TRUE
  }
  documents$accepted_covered_tokens <- tabulate(
    match(source$tokens$document_id[covered], ids), length(ids))
  documents$accepted_coverage <- ifelse(documents$retained_tokens > 0,
    documents$accepted_covered_tokens / documents$retained_tokens, NA_real_)
  documents$review_complete <- documents$unresolved + documents$unreviewed == 0L
  documents$reportable_accepted_coverage <- ifelse(documents$review_complete,
    documents$accepted_coverage, NA_real_)
  list(occurrences = hits, worksheet = worksheet, counts = counts, documents = documents,
    source = result, criterion = criterion,
    provenance = list(example_version = "1", review_id = review_id,
      decisions = "complete worksheet; accepted/rejected/unresolved/unreviewed",
      coverage = "accepted union / all retained tokens; no token compounding",
      complete = "no unresolved or unreviewed matched occurrences; not inventory completeness"))
}
