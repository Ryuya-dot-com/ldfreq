# Source explicitly; this example is not an exported API or a correction engine.
# Coordinates refer to the ORIGINAL, unnormalised document: 1-based inclusive
# Unicode code points. An insertion at start uses end = start - 1 and original = "".
# All versions must be constructed from the same original documents and ledger.
apply_reviewed_edits <- function(documents, edits, categories, policy) {
  fail <- function(message) stop(message, call. = FALSE)
  chars <- function(x, blank = TRUE) is.character(x) && !anyNA(x) &&
    all(validUTF8(x)) && !any(Encoding(x) %in% c("bytes", "latin1")) &&
    (blank || all(nzchar(trimws(x))))
  fields <- c("edit_id", "document_id", "start", "end", "original",
    "replacement", "category", "decision", "reviewer", "reason")
  output_fields <- c("applied", "pre", "post", "revised_start", "revised_end")
  if (!is.data.frame(documents) || anyDuplicated(names(documents)) ||
      !all(c("document_id", "text") %in% names(documents)) || !nrow(documents) ||
      !chars(documents$document_id, FALSE) || anyDuplicated(documents$document_id) ||
      !chars(documents$text))
    fail("documents requires unique nonempty document_id and nonmissing UTF-8 text; retain metadata columns.")
  if (!is.data.frame(edits) || anyDuplicated(names(edits)) ||
      !all(fields %in% names(edits)) || any(output_fields %in% names(edits)))
    fail("edits requires the documented ledger columns and no reserved output columns.")
  for (field in setdiff(fields, c("start", "end"))) {
    if (!chars(edits[[field]], field %in% c("original", "replacement", "reviewer")))
      fail(paste("Invalid UTF-8 or missing/blank ledger field:", field))
  }
  if (anyDuplicated(edits$edit_id) ||
      any(!edits$document_id %in% documents$document_id))
    fail("Use unique edit_id values and known document_id values.")
  if (any(!edits$decision %in% c("approved", "rejected", "unresolved")) ||
      any(edits$decision != "unresolved" & !nzchar(trimws(edits$reviewer))))
    fail("Decisions must be approved, rejected or unresolved; completed decisions require a reviewer.")
  if (!chars(categories, FALSE) || anyDuplicated(categories) ||
      !chars(policy, FALSE) || length(policy) != 1L)
    fail("Supply unique categories (character(0) for no edits) and one explicit policy description.")
  for (field in c("start", "end")) {
    x <- edits[[field]]
    if (!is.numeric(x) || anyNA(x) || any(!is.finite(x) | x != floor(x)))
      fail("start and end must be finite integer code-point coordinates.")
  }
  source <- documents$text[match(edits$document_id, documents$document_id)]
  size <- stringi::stri_length(source)
  if (any(edits$start < 1 | edits$start > size + 1 |
      edits$end < edits$start - 1 | edits$end > size))
    fail("An edit is outside its original document; insertions require end = start - 1.")
  # Explicit empty intervals avoid special zero/negative substring semantics.
  slice <- function(text, start, end) {
    if (end < start) "" else stringi::stri_sub(text, start, end)
  }
  for (i in seq_len(nrow(edits))) {
    if (!identical(slice(source[i], edits$start[i], edits$end[i]), edits$original[i]))
      fail(paste("Original substring mismatch at edit", edits$edit_id[i]))
  }
  if (any(edits$original == edits$replacement))
    fail("An edit must change text; identical original and replacement are not edits.")

  audit <- edits
  audit$applied <- edits$decision == "approved" & edits$category %in% categories
  audit$pre <- audit$post <- rep("", nrow(edits))
  audit$revised_start <- audit$revised_end <- rep(NA_real_, nrow(edits))
  for (i in seq_len(nrow(edits))) {
    audit$pre[i] <- slice(source[i], max(1, edits$start[i] - 24), edits$start[i] - 1)
    audit$post[i] <- slice(source[i], edits$end[i] + 1, min(size[i], edits$end[i] + 24))
  }
  revised <- documents
  counts <- data.frame(document_id = documents$document_id,
    proposed = integer(nrow(documents)), applied = integer(nrow(documents)),
    approved_outside_policy = integer(nrow(documents)), rejected = integer(nrow(documents)),
    unresolved = integer(nrow(documents)))
  for (d in seq_len(nrow(documents))) {
    rows <- which(edits$document_id == documents$document_id[d])
    active <- rows[audit$applied[rows]]
    active <- active[order(edits$start[active], edits$end[active])]
    if (length(active) > 1L && (anyDuplicated(edits$start[active]) ||
        any(edits$start[active[-1L]] <= edits$end[active[-length(active)]])))
      fail(paste("Overlapping edits or shared insertion positions in document", documents$document_id[d]))
    counts$proposed[d] <- length(rows)
    counts$applied[d] <- length(active)
    counts$approved_outside_policy[d] <- sum(edits$decision[rows] == "approved" & !audit$applied[rows])
    counts$rejected[d] <- sum(edits$decision[rows] == "rejected")
    counts$unresolved[d] <- sum(edits$decision[rows] == "unresolved")
    text <- documents$text[d]
    cursor <- 1
    shift <- 0
    pieces <- character()
    for (i in active) {
      pieces <- c(pieces, slice(text, cursor, edits$start[i] - 1), edits$replacement[i])
      audit$revised_start[i] <- edits$start[i] + shift
      audit$revised_end[i] <- audit$revised_start[i] + stringi::stri_length(edits$replacement[i]) - 1
      shift <- shift + stringi::stri_length(edits$replacement[i]) -
        (edits$end[i] - edits$start[i] + 1)
      cursor <- edits$end[i] + 1
    }
    if (length(active))
      revised$text[d] <- paste0(c(pieces, slice(text, cursor, stringi::stri_length(text))), collapse = "")
  }
  hash <- function(x) vapply(x, function(text)
    digest::digest(charToRaw(enc2utf8(text)), algo = "sha256", serialize = FALSE), character(1), USE.NAMES = FALSE)
  counts$original_sha256 <- hash(documents$text)
  counts$revised_sha256 <- hash(revised$text)
  list(inputs = list(documents = documents, edits = edits, categories = categories, policy = policy),
    original = documents, revised = revised, edits = audit, documents = counts,
    settings = list(example_version = "1", policy = policy, categories = categories,
      coordinates = "original-document-1-based-inclusive-Unicode-codepoints",
      revised_coordinates = "revised-document-1-based-inclusive-Unicode-codepoints",
      empty_interval = "end = start - 1", context_characters = 24L))
}
