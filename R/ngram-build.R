# Process bounded extraction chunks, retaining counts rather than occurrences.
lexdiv_ngram_reference_build <- function(sources, read_chunk, resource, max_types = 1e6) {
  sources <- .lex_batch_validate_ids(sources, length(sources))
  if (!length(sources)) stop("sources must not be empty.", call. = FALSE)
  if (!is.function(read_chunk)) stop("read_chunk must be a function.", call. = FALSE)
  resource <- .lexnorm_resource(resource)
  max_types <- .lexnorm_positive_whole(max_types, "max_types")
  counts <- totals <- NULL
  documents <- character()
  records <- roster <- vector("list", length(sources))
  preprocessing_id <- NULL
  for (i in seq_along(sources)) {
    source <- sources[i]
    chunk <- tryCatch({
      value <- read_chunk(source)
      .lexng_validate_result(value, "lexdiv_ngrams")
      value
    }, error = function(e)
      stop("Failed to read source '", source, "': ", conditionMessage(e), call. = FALSE))
    ids <- unique(chunk$documents$document_id)
    if (any(ids %in% documents))
      stop("Document IDs must not occur in more than one chunk; source: ", source, call. = FALSE)
    documents <- c(documents, ids)
    if (is.null(totals)) {
      totals <- chunk$totals
      totals$opportunities[] <- 0; totals$documents[] <- 0
      counts <- chunk$counts[FALSE, ]
      preprocessing_id <- chunk$provenance$preprocessing_id
    }
    if (!identical(preprocessing_id, chunk$provenance$preprocessing_id) ||
        !setequal(totals$n, chunk$totals$n))
      stop("Chunks must agree on preprocessing_id and requested n values.", call. = FALSE)
    if (nrow(chunk$counts) > max_types)
      stop("Distinct n-gram types exceed max_types.", call. = FALSE)
    combined <- rbind(counts, chunk$counts)
    key <- .lexng_key(combined[.lexng_columns])
    first <- !duplicated(key)
    if (sum(first) > max_types)
      stop("Distinct n-gram types exceed max_types.", call. = FALSE)
    counts <- combined[first, , drop = FALSE]
    if (nrow(combined)) {
      sums <- rowsum(as.matrix(combined[c("count", "document_count")]),
        group = match(key, key[first]), reorder = FALSE)
      counts$count <- as.double(sums[, 1])
      counts$document_count <- as.double(sums[, 2])
      rm(sums)
    }
    rownames(counts) <- NULL
    index <- match(totals$n, chunk$totals$n)
    totals$opportunities <- totals$opportunities + chunk$totals$opportunities[index]
    totals$documents <- totals$documents + chunk$totals$documents[index]
    records[[i]] <- data.frame(source_id = source, chunk$totals,
      extraction_sha256 = chunk$provenance$content_sha256, stringsAsFactors = FALSE)
    roster[[i]] <- data.frame(source_id = rep(source, length(ids)), document_id = ids,
      stringsAsFactors = FALSE)
    # Drop the last chunk too: it may contain most of the input occurrences.
    rm(chunk, combined, key, first)
  }
  reference <- lexdiv_ngram_reference(counts, resource, totals, preprocessing_id, complete = TRUE)
  source_table <- do.call(rbind, records); rownames(source_table) <- NULL
  document_table <- do.call(rbind, roster); rownames(document_table) <- NULL
  list(reference = reference, sources = source_table, documents = document_table,
    provenance = list(builder = "ldfreq-ngram-reference-build", builder_version = "0.1.0",
      preprocessing_id = preprocessing_id, source_order = sources,
      document_policy = "whole-documents-in-exactly-one-chunk",
      retained = "counts-denominators-document-roster-extraction-fingerprints",
      max_types = max_types,
      network_policy = "no-package-network-calls-callback-is-caller-controlled"))
}
