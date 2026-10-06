# Resource-defined families, distinct from lemma/flemma annotation and knowledge.
lexdiv_family_profile <- function(annotations, dictionary, resource,
                                  unit = c("surface", "lemma", "flemma"),
                                  normalization = c("identity", "nfkc_lower"),
                                  exclude_pos = character(), context_chars = 30L,
                                  max_tokens = 1e6, max_candidates = 1e6,
                                  review = NULL) {
  unit <- match.arg(unit)
  normalization <- match.arg(normalization)
  context_chars <- .lexann_context(context_chars)
  max_tokens <- .lexnorm_positive_whole(max_tokens, "max_tokens")
  max_candidates <- .lexnorm_positive_whole(max_candidates, "max_candidates")
  annotations <- .lexann_validate(annotations, "annotations", max_tokens)
  dictionary <- .lexnorm_plain_data_frame(dictionary, "dictionary")
  fields <- c("record_id", "form", "family_id")
  if (!all(fields %in% names(dictionary)))
    stop("dictionary requires record_id, form and family_id columns.", call. = FALSE)
  if (nrow(dictionary) > max_candidates)
    stop("Dictionary rows exceed max_candidates.", call. = FALSE)
  pos_match <- "upos" %in% names(dictionary)
  for (field in c(fields, if (pos_match) "upos")) {
    dictionary[[field]] <- .lexnorm_plain_character(dictionary[[field]], field, allow_zero = TRUE)
    if (any(!nzchar(stringi::stri_trim_both(dictionary[[field]]))))
      stop("Dictionary keys and IDs must not be blank.", call. = FALSE)
  }
  if (anyDuplicated(dictionary$record_id))
    stop("dictionary record_id must be unique; preserve IDs as character strings.", call. = FALSE)
  resource <- .lexnorm_plain_list(resource, "resource")
  required <- c("resource_id", "resource_version", "language", "source_reference",
    "data_license", "family_definition", "lookup_unit")
  if (!all(required %in% names(resource)))
    stop("resource requires: ", paste(required, collapse = ", "), ".", call. = FALSE)
  for (field in names(resource)) {
    resource[[field]] <- .lexnorm_scalar_string(resource[[field]], field)
    if (!nzchar(stringi::stri_trim_both(resource[[field]])))
      stop("Resource declarations must not be blank.", call. = FALSE)
  }
  if (!identical(resource$lookup_unit, unit))
    stop("resource$lookup_unit must agree with unit.", call. = FALSE)
  exclude_pos <- .lexnorm_plain_character(exclude_pos, "exclude_pos", allow_zero = TRUE)
  if (anyDuplicated(exclude_pos) || any(!exclude_pos %in% .lexprep_upos_tags))
    stop("exclude_pos must contain unique UD POS tags.", call. = FALSE)
  tokens <- annotations$tokens
  needed <- unique(c(unit, if (pos_match || length(exclude_pos)) "upos"))
  if (!all(needed %in% names(tokens)))
    stop("Annotations lack the selected unit or required upos column.", call. = FALSE)
  for (field in needed) {
    value <- tokens[[field]]
    if (!is.character(value) || !is.null(attributes(value)))
      stop("Selected units and POS must be plain character columns; missing values use NA.", call. = FALSE)
    .lexnorm_plain_character(value[!is.na(value)], field, allow_zero = TRUE)
    if (any(!is.na(value) & !nzchar(stringi::stri_trim_both(value))))
      stop("Selected units and POS must not contain blank values.", call. = FALSE)
  }
  if ("upos" %in% needed && any(!is.na(tokens$upos) & !tokens$upos %in% .lexprep_upos_tags))
    stop("upos must use UD tags or NA; map other tagsets explicitly.", call. = FALSE)
  if (pos_match && any(!dictionary$upos %in% .lexprep_upos_tags))
    stop("Dictionary upos must use UD tags without missing values or wildcards.", call. = FALSE)

  ids <- c("document_id", "segment_id", "token_index")
  occurrences <- tokens[unique(c(ids, "surface", "start", "end", needed))]
  query <- tokens[[unit]]
  known <- !is.na(query)
  query[known] <- .lexprep_flemma_normalize(query[known], normalization)
  form <- .lexprep_flemma_normalize(dictionary$form, normalization)
  if (any(!nzchar(form)) || any(!nzchar(query[known])))
    stop("Normalization must not produce empty matching keys.", call. = FALSE)
  occurrences$query <- query
  selected <- rep(TRUE, nrow(tokens))
  if (length(exclude_pos))
    selected <- ifelse(is.na(tokens$upos), NA, !tokens$upos %in% exclude_pos)
  occurrences$selected <- selected
  status <- rep("unlisted", nrow(tokens))
  status[!known] <- "missing_unit"
  if (pos_match) status[known & is.na(tokens$upos)] <- "missing_pos"
  status[selected %in% FALSE] <- "excluded"
  status[is.na(selected)] <- "unknown_selection"

  # Index distinct keys once; bound candidate expansion before constructing rows.
  ref_keys <- data.frame(form = form)
  query_keys <- data.frame(form = query)
  if (pos_match) {
    ref_keys$upos <- dictionary$upos
    query_keys$upos <- tokens$upos
  }
  key <- .lexng_key(ref_keys)
  unique_keys <- unique(key)
  groups <- split(seq_len(nrow(dictionary)), factor(match(key, unique_keys),
    levels = seq_along(unique_keys)))
  group <- match(.lexng_key(query_keys), unique_keys)
  eligible <- which(status == "unlisted" & !is.na(group))
  candidate_count <- integer(nrow(tokens))
  candidate_count[eligible] <- lengths(groups)[group[eligible]]
  if (sum(as.double(candidate_count)) > max_candidates)
    stop("Expanded candidate rows exceed max_candidates; split documents or reduce the dictionary scope.",
      call. = FALSE)
  family_options <- lapply(groups, function(idx) unique(dictionary$family_id[idx]))
  family_count <- integer(nrow(tokens))
  family_count[eligible] <- lengths(family_options)[group[eligible]]
  family_id <- rep(NA_character_, nrow(tokens))
  matched <- eligible[family_count[eligible] == 1L]
  if (length(matched))
    family_id[matched] <- vapply(family_options[group[matched]], `[[`, character(1), 1L)
  status[matched] <- "matched"
  status[eligible[family_count[eligible] > 1L]] <- "ambiguous"
  occurrences$status <- status
  occurrences$candidate_records <- candidate_count
  occurrences$candidate_families <- family_count
  occurrences$family_id <- family_id
  source <- annotations$segments$text[match(.lexng_key(tokens[c("document_id", "segment_id")]),
    .lexng_key(annotations$segments[c("document_id", "segment_id")]))]
  occurrences$pre <- stringi::stri_sub(source, pmax(1, tokens$start - context_chars), tokens$start - 1L)
  occurrences$keyword <- tokens$surface
  occurrences$post <- stringi::stri_sub(source, tokens$end + 1L,
    pmin(stringi::stri_length(source), tokens$end + context_chars))
  token_row <- rep(eligible, candidate_count[eligible])
  resource_row <- unlist(groups[group[eligible]], use.names = FALSE)
  if (is.null(resource_row)) resource_row <- integer()
  candidates <- cbind(tokens[token_row, ids, drop = FALSE],
    dictionary[resource_row, c(fields, if (pos_match) "upos"), drop = FALSE])
  rownames(candidates) <- rownames(occurrences) <- NULL

  # Prepare the existing review API's surface-based display, while retaining
  # record membership at each occurrence for the stricter application below.
  review_candidates <- unique(data.frame(term = tokens$surface[token_row],
    candidate_id = dictionary$record_id[resource_row],
    label = dictionary$family_id[resource_row],
    dictionary[resource_row, c("family_id", if (pos_match) "upos"), drop = FALSE]))
  review_candidates <- review_candidates[order(review_candidates$term,
    review_candidates$candidate_id, method = "radix"), , drop = FALSE]
  rownames(review_candidates) <- NULL
  review_resource <- resource
  review_resource$family_profile_sha256 <- digest::digest(list(
    "ldfreq-family-review-0.1.0", annotations$provenance$input_sha256,
    dictionary, resource, unit, normalization, exclude_pos),
    algo = "sha256", serializeVersion = 2L)
  required_review <- c("resource_id", "resource_version", "source_reference", "data_license")
  review_resource <- review_resource[c(required_review,
    sort(setdiff(names(review_resource), required_review), method = "radix"))]
  review_input <- list(targets = unique(review_candidates$term),
    candidates = review_candidates, resource = review_resource)
  occurrences$lookup_status <- status
  occurrences$lookup_family_id <- family_id
  for (field in c("review_status", "review_record_id", "reviewer", "reason"))
    occurrences[[field]] <- rep(NA_character_, nrow(tokens))
  if (!is.null(review)) {
    .lexamb_validate_review(review)
    if (!identical(review$source, annotations) ||
        !identical(review$candidates, review_input$candidates) ||
        !identical(review$provenance$resource, review_input$resource) ||
        !setequal(review$summary$term, review_input$targets))
      stop("Review differs from this family profile's source, dictionary or policy; regenerate from review_input.",
        call. = FALSE)
    ro <- review$occurrences
    row <- match(.lexng_key(ro[ids]), .lexng_key(tokens[ids]))
    explicit <- ro$status %in% c("selected", "unresolved")
    if (anyNA(row) || any(explicit & !(selected[row] %in% TRUE)))
      stop("Family review decisions require known-selected occurrences; excluded or unknown selection cannot be overridden.",
        call. = FALSE)
    chosen <- which(ro$status == "selected")
    chosen_key <- data.frame(ro[chosen, ids, drop = FALSE], record_id = ro$candidate_id[chosen])
    candidate_row <- match(.lexng_key(chosen_key), .lexng_key(candidates[c(ids, "record_id")]))
    if (anyNA(candidate_row))
      stop("Selected record is not eligible for this occurrence's unit and POS.", call. = FALSE)
    family_id[row[chosen]] <- candidates$family_id[candidate_row]
    status[row[chosen]] <- "matched"
    withheld <- row[ro$status == "unresolved"]
    status[withheld[status[withheld] == "matched"]] <- "review_unresolved"
    family_id[withheld] <- NA_character_
    occurrences$review_status[row] <- ro$status
    occurrences$review_record_id[row] <- ro$candidate_id
    occurrences$reviewer[row] <- ro$reviewer
    occurrences$reason[row] <- ro$reason
    occurrences$status <- status
    occurrences$family_id <- family_id
  }

  summarize <- function(idx) {
    s <- status[idx]
    chosen <- selected[idx]
    unknown <- sum(is.na(chosen))
    n <- sum(chosen %in% TRUE)
    found <- sum(s == "matched")
    unresolved <- sum(!s %in% c("matched", "excluded"))
    types <- length(unique(family_id[idx][s == "matched"]))
    complete <- unresolved == 0L
    data.frame(tokens = length(idx), excluded_tokens = sum(s == "excluded"),
      known_selected_tokens = n, unknown_selection_tokens = unknown,
      selected_tokens = if (unknown) NA_integer_ else n,
      matched_tokens = found, unlisted_tokens = sum(s == "unlisted"),
      ambiguous_tokens = sum(s == "ambiguous"), missing_unit_tokens = sum(s == "missing_unit"),
      missing_pos_tokens = sum(s == "missing_pos"), withheld_tokens = sum(s == "review_unresolved"),
      unresolved_tokens = unresolved,
      review_selected_tokens = sum(occurrences$review_status[idx] == "selected", na.rm = TRUE),
      review_unresolved_tokens = sum(occurrences$review_status[idx] == "unresolved", na.rm = TRUE),
      conditional_token_coverage = if (n) found / n else NA_real_,
      token_coverage = if (n && !unknown) found / n else NA_real_,
      observed_family_types = types, family_types = if (complete) types else NA_integer_,
      family_ttr = if (complete && n) types / n else NA_real_,
      status = if (!length(idx)) "empty" else if (!complete) "incomplete" else
        if (!n) "no_selected_tokens" else "complete")
  }
  documents <- annotations$documents
  rows <- split(seq_len(nrow(tokens)), factor(tokens$document_id, levels = documents$document_id))
  documents <- cbind(documents, do.call(rbind, lapply(rows, summarize)))
  rownames(documents) <- NULL
  members <- occurrences[status == "matched", c("document_id", "family_id", "surface", "query")]
  member_key <- .lexng_key(members)
  first <- !duplicated(member_key)
  members <- members[first, , drop = FALSE]
  members$n <- tabulate(match(member_key, member_key[first]), nbins = nrow(members))
  rownames(members) <- NULL
  out <- list(occurrences = occurrences, candidates = candidates, members = members,
    documents = documents, summary = summarize(seq_len(nrow(tokens))),
    annotations = annotations, dictionary = dictionary, review_input = review_input, review = review,
    provenance = list(method = "ldfreq-family-profile", method_version = "0.2.0",
      unit = unit, normalization = normalization, pos_matching = pos_match,
      exclude_pos = exclude_pos, context_chars = context_chars, resource = resource,
      resource_sha256 = digest::digest(dictionary, algo = "sha256", serializeVersion = 2L),
      coordinates = annotations$provenance$coordinates,
      assignment = "exact unique-family lookup; optional source/policy-bound record review; explicit unresolved vetoes assignment; no fallback",
      scope = "counts relative to the supplied family definition; not affix analysis or learner knowledge"))
  out$provenance$content_sha256 <- .lexng_hash(out)
  out
}
