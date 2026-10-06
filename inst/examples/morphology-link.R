# Explicit recipe: retain one row per selected corpus occurrence and keep
# educational families, recorded segmentation and one-step relations separate.
# Requires optional quanteda through the existing ambiguity-review API.
link_morphology_candidates <- function(family, morpholex, morphynet,
                                       selected = family$occurrences$selected,
                                       morpholex_decisions = NULL, morphynet_decisions = NULL) {
  check <- family; check$provenance$content_sha256 <- NULL
  if (!identical(family$provenance$method, "ldfreq-family-profile") ||
      !identical(family$provenance$content_sha256,
        digest::digest(check, algo = "sha256", serializeVersion = 2L)))
    stop("Supply an unmodified family profile.")
  o <- family$occurrences; x <- family$annotations
  ids <- c("document_id", "segment_id", "token_index")
  if (!is.logical(selected) || length(selected) != nrow(o) || anyNA(selected) ||
      !any(selected) || any(selected & !(o$selected %in% TRUE)))
    stop("selected must identify at least one known eligible occurrence without missing values.")
  if (!identical(o[ids], x$tokens[ids])) stop("Family and annotation occurrence IDs differ.")
  e <- new.env(parent = baseenv())
  sys.source(system.file("examples", "word-parts.R", package = "ldfreq", mustWork = TRUE), e)
  parts_profile <- e$word_parts_profile(x, morpholex$analyses, morpholex$parts, morpholex$resource)
  targets <- unique(o$surface[selected])
  a <- morpholex$analyses
  ml <- a[a$form %in% targets, , drop = FALSE]
  ml$term <- ml$form; ml$candidate_id <- ml$analysis_id
  ml$label <- paste(ml$form, ml$completeness, ml$analysis_id, sep = "; ")
  r <- morphynet$relations
  required <- c("relation_id", "source_word", "target_word", "source_pos", "target_pos", "morpheme", "affix_position")
  if (!is.data.frame(r) || !all(required %in% names(r)) || anyNA(r[required]) ||
      anyDuplicated(r$relation_id) || any(!r$affix_position %in% c("prefix", "suffix")))
    stop("Supply unique MorphyNet relation IDs and unchanged relation fields.")
  mn <- r[r$target_word %in% targets, , drop = FALSE]
  mn$term <- mn$target_word; mn$candidate_id <- mn$relation_id
  mn$label <- paste(mn$source_word, "->", mn$target_word, mn$morpheme, mn$affix_position)
  # Both reviews use the same complete annotations. Their candidate identities
  # differ, but occurrence IDs must agree. No resource votes on the other.
  ml_resource <- morpholex$resource
  ml_resource$lookup_unit <- "exact supplied surface; no lemma fallback or POS inference"
  mn_resource <- morphynet$resource
  mn_resource$lookup_unit <- ml_resource$lookup_unit
  ml_review <- ldfreq::lexdiv_ambiguity_review(x, targets, ml, ml_resource, decisions = morpholex_decisions)
  mn_review <- ldfreq::lexdiv_ambiguity_review(x, targets, mn, mn_resource, decisions = morphynet_decisions)
  key <- function(z) if (!nrow(z)) character() else do.call(paste0, lapply(z[ids], function(v)
    paste0(nchar(as.character(v), type = "bytes"), ":", v)))
  selected_key <- key(o[selected, ])
  li <- match(selected_key, key(ml_review$occurrences))
  ni <- match(selected_key, key(mn_review$occurrences))
  if (anyNA(li) || anyNA(ni) || !identical(ml_review$occurrences$occurrence_id[li],
      mn_review$occurrences$occurrence_id[ni])) stop("Morphology reviews did not preserve shared occurrence IDs.")
  for (review in list(ml_review, mn_review)) {
    eligible <- review$occurrences$occurrence_id[key(review$occurrences) %in% selected_key]
    if (any(!review$decisions$occurrence_id %in% eligible)) stop("A decision targets an excluded occurrence.")
  }
  out <- o[selected, c(ids, "surface", "start", "end", "family_id", "status"), drop = FALSE]
  names(out)[names(out) == "status"] <- "family_status"
  out$occurrence_id <- ml_review$occurrences$occurrence_id[li]
  out[c("pre", "keyword", "post")] <- ml_review$occurrences[li, c("pre", "keyword", "post")]
  if ("lemma" %in% names(x$tokens)) out$lemma <- x$tokens$lemma[selected]
  out$morpholex_lookup_status <- parts_profile$occurrences$status[selected]
  out$morpholex_candidate_count <- ml_review$occurrences$candidate_count[li]
  out$morpholex_review_status <- ml_review$occurrences$status[li]
  out$morpholex_analysis_id <- ml_review$occurrences$candidate_id[li]
  out$morphynet_candidate_count <- mn_review$occurrences$candidate_count[ni]
  out$morphynet_review_status <- mn_review$occurrences$status[ni]
  out$morphynet_relation_id <- mn_review$occurrences$candidate_id[ni]
  ar <- match(out$morpholex_analysis_id, a$analysis_id)
  complete <- out$morpholex_review_status == "selected" & !is.na(ar) & a$completeness[ar] == "complete"
  # Part totals use only explicitly selected complete analyses. Partial entries
  # remain available in the reference/review, without completing them by guessing.
  p <- morpholex$parts
  part_groups <- split(seq_len(nrow(p)), factor(p$analysis_id, levels = a$analysis_id))
  chosen_rows <- which(complete)
  part_rows <- unlist(part_groups[ar[chosen_rows]], use.names = FALSE)
  if (is.null(part_rows)) part_rows <- integer()
  counts <- lengths(part_groups)[ar[chosen_rows]]
  reviewed_parts <- cbind(out[rep(chosen_rows, counts), c(ids, "occurrence_id", "surface"), drop = FALSE],
    p[part_rows, , drop = FALSE])
  rr <- match(out$morphynet_relation_id, r$relation_id)
  relation_rows <- which(out$morphynet_review_status == "selected")
  reviewed_relations <- cbind(out[relation_rows, c(ids, "occurrence_id", "surface"), drop = FALSE],
    r[rr[relation_rows], , drop = FALSE])
  documents <- do.call(rbind, lapply(family$documents$document_id, function(id) {
    z <- out[out$document_id == id, , drop = FALSE]
    n <- nrow(z)
    rp <- reviewed_parts[reviewed_parts$document_id == id, , drop = FALSE]
    rn <- reviewed_relations[reviewed_relations$document_id == id, , drop = FALSE]
    complete_n <- sum(complete[out$document_id == id])
    d <- data.frame(document_id = id, eligible_N = n,
      family_resolved_N = sum(!is.na(z$family_id)),
      morpholex_matched_N = sum(z$morpholex_candidate_count > 0L),
      morpholex_ambiguous_N = sum(z$morpholex_candidate_count > 1L),
      morpholex_unique_complete_N = sum(z$morpholex_lookup_status == "complete"),
      morpholex_selected_N = sum(z$morpholex_review_status == "selected"),
      morpholex_selected_complete_N = complete_n,
      morpholex_unresolved_N = sum(z$morpholex_review_status == "unresolved"),
      morphynet_matched_N = sum(z$morphynet_candidate_count > 0L),
      morphynet_ambiguous_N = sum(z$morphynet_candidate_count > 1L),
      morphynet_selected_N = nrow(rn), morphynet_unresolved_N = sum(z$morphynet_review_status == "unresolved"),
      all_three_matched_N = sum(!is.na(z$family_id) & z$morpholex_candidate_count > 0L & z$morphynet_candidate_count > 0L),
      reviewed_prefix_instances = sum(rp$role == "prefix"),
      reviewed_suffix_instances = sum(rp$role == "suffix"),
      reviewed_root_instances = sum(rp$role == "root"),
      selected_prefix_relations = sum(rn$affix_position == "prefix"),
      selected_suffix_relations = sum(rn$affix_position == "suffix"))
    for (resource in c("morpholex", "morphynet")) {
      matched <- d[[paste0(resource, "_matched_N")]]
      d[[paste0(resource, "_unlisted_N")]] <- n - matched
      d[[paste0(resource, "_lookup_coverage")]] <- if (n) matched / n else NA_real_
      d[[paste0(resource, "_review_selection_coverage")]] <- if (n) d[[paste0(resource, "_selected_N")]] / n else NA_real_
    }
    for (role in c("prefix", "suffix", "root"))
      d[[paste0("full_", role, "_instances")]] <- if (complete_n == n) d[[paste0("reviewed_", role, "_instances")]] else NA_integer_
    d
  }))
  for (name in c("out", "documents", "reviewed_parts", "reviewed_relations")) {
    z <- get(name); rownames(z) <- NULL; assign(name, z)
  }
  list(occurrences = out, documents = documents, reviewed_parts = reviewed_parts,
    reviewed_relations = reviewed_relations,
    reviews = list(morpholex = ml_review, morphynet = mn_review),
    lookup = parts_profile,
    inputs = list(family = family, morpholex = morpholex, morphynet = morphynet, selected = selected,
      morpholex_decisions = morpholex_decisions, morphynet_decisions = morphynet_decisions),
    settings = list(matching = "exact annotation surface; family lookup policy retained separately",
      denominator = "one row per selected original token; context-only gaps stay excluded",
      counts = "reviewed complete segmentation parts and selected one-step relations are separate",
      inference = "no contextual correctness, learner knowledge or productivity inferred"))
}
