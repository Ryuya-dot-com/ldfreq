# Shared implementation for the public API and legacy installed examples.
# These helpers assemble saved results. They do not fit or choose a model.
study_long_table <- function(planned, submissions, results, plan, condition_id,
                             reporting = NULL, max_rows = 1e6) {
  fail <- function(message) stop(message, call. = FALSE)
  table_ok <- function(x) is.data.frame(x) && !anyDuplicated(names(x)) &&
    all(nzchar(names(x))) && !anyNA(names(x))
  ids_ok <- function(x) is.character(x) && !is.object(x) && is.null(dim(x)) &&
    !anyNA(x) && all(validUTF8(x)) && all(nzchar(trimws(x)))
  unique_ids <- function(x) ids_ok(x) && !anyDuplicated(x)
  if (!table_ok(planned) ||
      !all(c("observation_id", "writer_id", "task", "occasion") %in% names(planned)) ||
      !unique_ids(planned$observation_id) ||
      !all(vapply(planned, function(x) is.atomic(x) && is.null(dim(x)), logical(1))))
    fail("planned needs unique character observation_id, writer_id, task, occasion and atomic columns.")
  for (name in c("writer_id", "task")) {
    x <- planned[[name]]
    if (!(is.character(x) || is.factor(x)) ||
        !ids_ok(as.character(x[!is.na(x)])))
      fail("writer_id and task must be character/factor labels; use NA for unknown labels.")
  }
  if (!table_ok(submissions) ||
      !setequal(names(submissions), c("observation_id", "document_id", "input_characters")) ||
      !unique_ids(submissions$observation_id) || !unique_ids(submissions$document_id) ||
      !all(submissions$observation_id %in% planned$observation_id))
    fail("submissions needs observation_id, document_id and input_characters, with at most one document per known observation.")
  chars <- submissions$input_characters
  if (!is.numeric(chars) || is.object(chars) || any(is.nan(chars)) ||
      any(!is.na(chars) & (!is.finite(chars) | chars < 0 | chars != floor(chars))))
    fail("input_characters must be nonnegative whole counts, or NA when unavailable.")
  if (!ids_ok(condition_id) || length(condition_id) != 1L)
    fail("condition_id must be one explicit nonblank character identifier.")
  if (!is.numeric(max_rows) || length(max_rows) != 1L || is.na(max_rows) ||
      !is.finite(max_rows) || max_rows < 1 || max_rows != floor(max_rows))
    fail("max_rows must be one positive whole number.")
  if (!table_ok(results) || !inherits(results, "lexdiv_profile_batch_results"))
    fail("results must be the complete result of lexdiv_metrics_batch(..., plan = plan).")

  # Empty tokens validate the public plan and supply request metadata, even
  # when no document was submitted. No submitted document is recalculated.
  template <- ldfreq::lexdiv_metrics(character(), plan = plan)
  class(template) <- "data.frame"
  n_requests <- nrow(template)
  if (nrow(planned) * n_requests > max_rows)
    fail("The planned observation-by-request table exceeds max_rows.")
  reserved <- c(names(results), "condition_id", "submission_status", "input_status",
    "input_characters", "computation_status", "reporting_status", "reporting_reason")
  if (any(names(planned) %in% reserved))
    fail("Rename planned columns that collide with result or study-output columns.")
  if (!all(c("document_id", names(template)) %in% names(results)) ||
      !ids_ok(results$document_id) || !ids_ok(results$request_id))
    fail("results are missing required document/request fields.")
  di <- match(results$document_id, submissions$document_id)
  ri <- match(results$request_id, template$request_id)
  key <- (di - 1) * n_requests + ri
  if (anyNA(key) || anyDuplicated(key) ||
      length(key) != nrow(submissions) * n_requests)
    fail("results must contain exactly one row per submitted document and planned request.")
  static <- setdiff(names(template), c("value", "status", "missing_reason",
    "effective_parameters", "N", "V", "below_quality_floor", "diagnostics"))
  if (any(!vapply(static, function(name)
    identical(results[[name]], template[[name]][ri]), logical(1))))
    fail("Result methods, parameters or plan identity do not match plan.")
  if (!is.numeric(results$value) || !is.numeric(results$N) || !is.numeric(results$V) ||
      anyNA(results$N) || anyNA(results$V) ||
      any(!is.finite(results$N) | results$N < 0 | results$N != floor(results$N)) ||
      any(!is.finite(results$V) | results$V < 0 | results$V > results$N |
          results$V != floor(results$V)) ||
      !is.character(results$status) || anyNA(results$status) ||
      any(!results$status %in% c("ok", "missing")) ||
      !is.character(results$missing_reason) ||
      any(results$status == "ok" & (!is.finite(results$value) | !is.na(results$missing_reason))) ||
      any(results$status == "missing" & (!is.na(results$value) |
          is.na(results$missing_reason) | !nzchar(results$missing_reason))))
    fail("Results have inconsistent counts, computation status or missing reasons.")
  counts <- unique(as.data.frame(results)[c("document_id", "N", "V")])
  if (anyDuplicated(counts$document_id))
    fail("One condition must use the same selected tokens for every request in a document.")
  selected <- counts$N[match(submissions$document_id, counts$document_id)]
  if (any(!is.na(chars) & chars == 0 & selected > 0))
    fail("A zero-character submission cannot have selected tokens.")

  oi <- rep(seq_len(nrow(planned)), each = n_requests)
  si <- rep(seq_len(n_requests), times = nrow(planned))
  submitted <- match(planned$observation_id[oi], submissions$observation_id)
  found <- match((submitted - 1) * n_requests + si, key)
  rows <- as.data.frame(results)[found, , drop = FALSE]
  class(rows) <- "data.frame"
  for (name in static) rows[[name]] <- template[[name]][si]
  rows$document_id <- submissions$document_id[submitted]
  rows <- cbind(planned[oi, , drop = FALSE], rows)
  rownames(rows) <- NULL
  rows$condition_id <- rep(condition_id, nrow(rows))
  rows$submission_status <- rep("not_submitted", nrow(rows))
  rows$submission_status[!is.na(submitted)] <- "submitted"
  rows$input_characters <- chars[submitted]
  rows$input_status <- as.character(ifelse(is.na(submitted), "not_submitted",
    ifelse(is.na(rows$input_characters), "unknown",
      ifelse(rows$input_characters == 0, "empty_text",
        ifelse(rows$N == 0, "no_selected_tokens", "selected_tokens")))))
  rows$computation_status <- as.character(ifelse(is.na(submitted), "not_submitted", rows$status))
  rows$reporting_status <- rep("not_screened", nrow(rows))
  rows$reporting_reason <- rep(NA_character_, nrow(rows))
  if (!is.null(reporting)) {
    required <- c("document_id", "request_id", "reporting_status", "reporting_reason")
    if (!table_ok(reporting) || !setequal(names(reporting), required) ||
        !ids_ok(reporting$document_id) || !ids_ok(reporting$request_id) ||
        !ids_ok(reporting$reporting_status) || !ids_ok(reporting$reporting_reason) ||
        any(!reporting$reporting_status %in% c("report", "withhold")))
      fail("reporting needs complete document/request decisions (report/withhold) and nonblank reasons.")
    report_key <- (match(reporting$document_id, submissions$document_id) - 1) *
      n_requests + match(reporting$request_id, template$request_id)
    if (anyNA(report_key) || anyDuplicated(report_key) || !setequal(report_key, key))
      fail("reporting must cover exactly the submitted document/request rows.")
    j <- match((submitted - 1) * n_requests + si, report_key)
    observed <- !is.na(submitted)
    rows$reporting_status[observed] <- reporting$reporting_status[j[observed]]
    rows$reporting_reason[observed] <- reporting$reporting_reason[j[observed]]
  }
  rows
}

study_model_data <- function(study, condition_id, request_id,
                             required = c("writer_id", "task", "occasion")) {
  fail <- function(message) stop(message, call. = FALSE)
  selector_ok <- function(x) is.character(x) && length(x) == 1L &&
    !is.na(x) && nzchar(trimws(x))
  needed <- c("observation_id", "document_id", "condition_id", "request_id",
    "specification_id", "method_id", "plan_md5", "value", "submission_status",
    "computation_status", "reporting_status")
  if (!is.data.frame(study) || anyDuplicated(names(study)) ||
      !all(needed %in% names(study)) || !selector_ok(condition_id) ||
      !selector_ok(request_id) || !is.character(required) || anyNA(required) ||
      anyDuplicated(required) || !all(required %in% names(study)))
    fail("Supply a study table, one condition_id/request_id and existing required metadata columns.")
  if (anyNA(study$condition_id) || anyNA(study$request_id))
    fail("Study condition/request identifiers cannot be missing.")
  rows <- study[study$condition_id == condition_id & study$request_id == request_id, , drop = FALSE]
  if (!nrow(rows)) fail("No planned observations match the selected condition and request.")
  if (anyNA(rows$observation_id) || anyDuplicated(rows$observation_id) ||
      anyNA(rows$specification_id) || length(unique(rows$specification_id)) != 1L ||
      anyNA(rows$method_id) || length(unique(rows$method_id)) != 1L ||
      anyNA(rows$plan_md5) || length(unique(rows$plan_md5)) != 1L)
    fail("Select one specification and one row per observation; do not pool requests or windows.")
  if (anyNA(rows$submission_status) || anyNA(rows$computation_status) ||
      anyNA(rows$reporting_status))
    fail("Study status columns cannot be missing.")
  missing_metadata <- vapply(seq_len(nrow(rows)), function(i) {
    bad <- vapply(required, function(name) {
      x <- rows[[name]][i]
      if (length(x) != 1L || !is.atomic(x)) fail("Required metadata must be scalar columns.")
      is.na(x) || (is.numeric(x) && !is.finite(x)) ||
        ((is.character(x) || is.factor(x)) && !nzchar(trimws(as.character(x))))
    }, logical(1))
    paste(required[bad], collapse = ",")
  }, character(1))
  # Keep separate flags: one row may have several exclusion reasons.
  audit <- rows[c("observation_id", "document_id", "condition_id", "request_id")]
  audit$not_submitted <- rows$submission_status != "submitted"
  audit$not_computable <- rows$computation_status != "ok" | !is.finite(rows$value)
  audit$not_reportable <- rows$reporting_status != "report"
  audit$missing_metadata <- missing_metadata
  audit$included <- !audit$not_submitted & !audit$not_computable &
    !audit$not_reportable & !nzchar(missing_metadata)
  data <- rows[audit$included, , drop = FALSE]
  if (anyNA(data$document_id) || anyDuplicated(data$document_id))
    fail("A selected document cannot represent multiple model observations.")
  rownames(data) <- data$observation_id
  rownames(audit) <- NULL
  list(data = data, audit = audit)
}

lexdiv_study_table <- study_long_table
lexdiv_study_model_data <- study_model_data
