# Optional recipe, explicitly sourced; not an exported ldfreq function.
# Supply the complete udpipe_annotate() result and a one-sentence-per-row roster.
# No model loading, inference, downloading or file writes occur in this helper.
import_udpipe_sentences <- function(annotation, segments, provenance) {
  if (!requireNamespace("udpipe", quietly = TRUE))
    stop("Install the optional udpipe package to read its saved output.", call. = FALSE)
  if (!is.data.frame(segments) || !all(c("document_id", "segment_id", "parser_id", "text") %in% names(segments)))
    stop("segments needs document_id, segment_id, parser_id and original text.", call. = FALSE)
  ids <- segments$parser_id
  if (!is.character(ids) || anyNA(ids) || anyDuplicated(ids) || !length(ids) ||
      any(!grepl("^[A-Za-z0-9][A-Za-z0-9_.-]*$", ids)))
    stop("Supply unique parser_id values containing only letters, digits, _, . or -.", call. = FALSE)
  if (!is.character(segments$text) || anyNA(segments$text) ||
      any(!validUTF8(segments$text)))
    stop("Supply non-missing original UTF-8 text, including empty inputs.", call. = FALSE)
  if (!inherits(annotation, "udpipe_connlu") ||
      !is.character(annotation$x) || !identical(unname(annotation$x), unname(segments$text)) ||
      !is.character(annotation$conllu) || length(annotation$conllu) != 1L || anyNA(annotation$conllu) ||
      !is.character(annotation$errors) || length(annotation$errors) != nrow(segments) || anyNA(annotation$errors))
    stop("Supply the complete udpipe_annotate() output for exactly this ordered source roster.", call. = FALSE)
  failed <- nzchar(annotation$errors)
  if (any(failed))
    stop("UDPipe reported errors for: ", paste(ids[failed], collapse = ", "),
      ". Keep and inspect annotation$errors; do not drop failed inputs.", call. = FALSE)
  if (nzchar(annotation$conllu)) {
    # Use UDPipe's reader. Do not reconstruct source text or request its derived offsets.
    data <- as.data.frame(annotation)
  } else {
    data <- data.frame(doc_id = character(), sentence_id = integer(), token_id = character(),
      token = character(), lemma = character(), upos = character(), head_token_id = character(),
      dep_rel = character(), deps = character(), stringsAsFactors = FALSE)
  }
  group <- match(data$doc_id, ids)
  if (anyNA(group) || anyNA(data$sentence_id) || any(diff(group) < 0))
    stop("Parser IDs must match the source roster in order, with known sentence IDs.", call. = FALSE)
  sentences <- split(data$sentence_id, group)
  if (any(vapply(sentences, function(x) length(unique(x)) != 1L, logical(1))))
    stop("One original sentence per segment is required; UDPipe returned multiple sentences.", call. = FALSE)
  if (any(data$sentence_id != 1L))
    stop("A single UDPipe sentence must have sentence_id 1 in each parser input.", call. = FALSE)
  if (anyNA(data$token_id) || any(!grepl("^[1-9][0-9]*$", data$token_id)))
    stop("Multiword-token ranges and empty nodes are unsupported; retain the raw output for review.", call. = FALSE)
  if (any(!is.na(data$deps)))
    stop("Enhanced dependencies are unsupported in this basic-tree recipe.", call. = FALSE)
  if (any(!is.na(data$head_token_id) & !grepl("^(0|[1-9][0-9]*)$", data$head_token_id)))
    stop("Head IDs must be basic integer token IDs or missing.", call. = FALSE)
  tokens <- data.frame(document_id = segments$document_id[group],
    segment_id = segments$segment_id[group], token_index = as.numeric(data$token_id),
    surface = data$token, lemma = data$lemma, upos = data$upos,
    head = as.numeric(data$head_token_id), deprel = data$dep_rel,
    parser_id = data$doc_id, parser_sentence_id = data$sentence_id,
    stringsAsFactors = FALSE)
  for (column in intersect(c("xpos", "feats", "misc"), names(data))) tokens[[column]] <- data[[column]]
  if (!is.list(provenance) || !identical(provenance$analyzer, "udpipe"))
    stop("Declare provenance$analyzer = 'udpipe' and the original model/version information.", call. = FALSE)
  required <- c("model", "model_sha256", "model_source", "model_license", "tokenizer", "tagger", "parser")
  if (!all(required %in% names(provenance)))
    stop("Record model identity, SHA-256, source, license and tokenizer/tagger/parser settings.", call. = FALSE)
  provenance$udpipe_reader_version <- as.character(utils::packageVersion("udpipe"))
  provenance$udpipe_output_sha256 <- digest::digest(annotation, algo = "sha256", serializeVersion = 2L)
  provenance$sentence_policy <- "caller-supplied sentences; one parser sentence per segment"
  provenance$adapter <- "installed-example-udpipe-amod-0.1.0"
  ldfreq::lexdiv_import_annotations(tokens, segments, provenance)
}
