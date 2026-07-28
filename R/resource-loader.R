# Internal, non-exported loader for byte-pinned local resource bundles.
#
# The loader uses SHA-256 only as a content-identity and corruption-detection
# mechanism. Manifest approval and distribution rights remain external gates.

.lexres_contract_id <- "ldfreq-lexical-sophistication-profile"
.lexres_contract_version <- "0.1.0-draft.2"
.lexres_manifest_schema_id <- "lexsoph-resource-manifest"
.lexres_manifest_schema_version <- "0.1.0-draft.2"
.lexres_tubelex_manifest_sha256 <-
  "35dd3a7537174a462aa22ea41e470a0fc1dfc4b7fe7c28765465d040bf24bd04"
.lexres_failures <- c(
  "resource_unavailable",
  "hash_mismatch",
  "unsupported_resource_version",
  "schema_mismatch"
)
.lexres_manifest_dcf_fields <- c(
  "Manifest-Schema-ID",
  "Manifest-Schema-Version",
  "Resource-ID",
  "Resource-Version",
  "Bundle-Variant-ID",
  "Resource-Schema-ID",
  "Resource-Schema-Version",
  "Lookup-Unit",
  "Normalization-ID",
  "Artifact-ID",
  "Artifact-Version",
  "Artifact-SHA256",
  "Artifact-Bytes",
  "Artifact-Role",
  "Artifact-Locator-ID",
  "Content-Schema-ID",
  "Content-Schema-Version",
  "License-ID",
  "Notice-Path",
  "Compression",
  "Content-SHA256",
  "Content-Bytes",
  "Source-Layer-IDs"
)

.lexres_stop <- function(...) {
  stop(sprintf(...), call. = FALSE)
}

.lexres_plain_character <- function(value, argument, allow_empty = FALSE) {
  if (
    !is.character(value) ||
      is.object(value) ||
      !is.null(dim(value)) ||
      !is.null(attributes(value)) ||
      (!allow_empty && length(value) == 0L) ||
      anyNA(value) ||
      any(!nzchar(value)) ||
      any(Encoding(value) %in% c("bytes", "latin1")) ||
      any(!validUTF8(value))
  ) {
    .lexres_stop(
      "%s must be a plain valid-UTF-8 character vector without missing or empty values.",
      argument
    )
  }
  Encoding(value) <- "UTF-8"
  value
}

.lexres_scalar_string <- function(value, argument) {
  value <- .lexres_plain_character(value, argument)
  if (length(value) != 1L) {
    .lexres_stop("%s must contain exactly one value.", argument)
  }
  value
}

.lexres_identifier <- function(value, argument) {
  value <- .lexres_scalar_string(value, argument)
  if (!grepl("^[a-z][a-z0-9._-]*$", value)) {
    .lexres_stop("%s must be one lowercase ASCII identifier.", argument)
  }
  value
}

.lexres_sha256 <- function(value, argument) {
  value <- .lexres_scalar_string(value, argument)
  if (!grepl("^[0-9a-f]{64}$", value)) {
    .lexres_stop("%s must be one lowercase SHA-256 value.", argument)
  }
  value
}

.lexres_positive_limit <- function(value, argument) {
  if (
    !is.numeric(value) ||
      is.object(value) ||
      !is.null(dim(value)) ||
      !is.null(attributes(value)) ||
      length(value) != 1L ||
      is.na(value) ||
      !is.finite(value) ||
      value < 1 ||
      value != floor(value) ||
      value > (.Machine$integer.max - 1)
  ) {
    .lexres_stop(
      "%s must be one positive integer no larger than %d.",
      argument,
      .Machine$integer.max - 1L
    )
  }
  as.double(value)
}

.lexres_normalized_relative <- function(value, argument) {
  value <- .lexres_scalar_string(value, argument)
  parts <- strsplit(value, "/", fixed = TRUE)[[1L]]
  if (
    startsWith(value, "/") ||
      startsWith(value, "~") ||
      grepl("^[A-Za-z][A-Za-z0-9+.-]*:", value) ||
      grepl("[[:cntrl:]]", value) ||
      grepl("\\", value, fixed = TRUE) ||
      endsWith(value, "/") ||
      any(parts %in% c("", ".", ".."))
  ) {
    .lexres_stop("%s must be a normalized relative locator.", argument)
  }
  value
}

.lexres_byte_order <- function(value) {
  keys <- vapply(value, function(item) {
    paste(sprintf("%02x", as.integer(charToRaw(item))), collapse = "")
  }, character(1L))
  order(keys, method = "radix")
}

.lexres_plain_unique <- function(value) {
  output <- character()
  for (item in value) {
    already_seen <- any(vapply(
      output,
      function(previous) identical(previous, item),
      logical(1L)
    ))
    if (!already_seen) output <- c(output, item)
  }
  output
}

.lexres_has_duplicate <- function(value) {
  length(.lexres_plain_unique(value)) != length(value)
}

.lexres_expectation <- function(
    resource_id,
    resource_version,
    manifest_sha256,
    manifest_locator_id,
    manifest_schema_id = .lexres_manifest_schema_id,
    manifest_schema_version = .lexres_manifest_schema_version,
    max_manifest_bytes = 1048576,
    max_artifact_bytes = 104857600,
    max_content_bytes = 209715200,
    max_artifacts = 64,
    max_total_artifact_bytes = 536870912,
    max_total_content_bytes = 1073741824) {
  output <- list(
    resource_id = .lexres_identifier(resource_id, "resource_id"),
    resource_version = .lexres_scalar_string(
      resource_version,
      "resource_version"
    ),
    manifest_sha256 = .lexres_sha256(manifest_sha256, "manifest_sha256"),
    manifest_locator_id = .lexres_normalized_relative(
      manifest_locator_id,
      "manifest_locator_id"
    ),
    manifest_schema_id = .lexres_identifier(
      manifest_schema_id,
      "manifest_schema_id"
    ),
    manifest_schema_version = .lexres_scalar_string(
      manifest_schema_version,
      "manifest_schema_version"
    ),
    max_manifest_bytes = .lexres_positive_limit(
      max_manifest_bytes,
      "max_manifest_bytes"
    ),
    max_artifact_bytes = .lexres_positive_limit(
      max_artifact_bytes,
      "max_artifact_bytes"
    ),
    max_content_bytes = .lexres_positive_limit(
      max_content_bytes,
      "max_content_bytes"
    ),
    max_artifacts = .lexres_positive_limit(
      max_artifacts,
      "max_artifacts"
    ),
    max_total_artifact_bytes = .lexres_positive_limit(
      max_total_artifact_bytes,
      "max_total_artifact_bytes"
    ),
    max_total_content_bytes = .lexres_positive_limit(
      max_total_content_bytes,
      "max_total_content_bytes"
    )
  )
  output$expectation_sha256 <- .lexres_sha256_bytes(
    serialize(output, connection = NULL, version = 3L)
  )
  structure(output, class = "lexsoph_resource_expectation")
}

.lexres_tubelex_expectation <- function() {
  .lexres_expectation(
    resource_id = "tubelex-en-treebank-slim",
    resource_version = "7cb5fb36-slim-v1",
    manifest_sha256 = .lexres_tubelex_manifest_sha256,
    manifest_locator_id = "extdata/tubelex/7cb5fb36/resource.manifest.dcf",
    max_manifest_bytes = 2048,
    max_artifact_bytes = 3145728,
    max_content_bytes = 9437184,
    max_artifacts = 1,
    max_total_artifact_bytes = 3145728,
    max_total_content_bytes = 9437184
  )
}

.lexres_tubelex_paths <- function() {
  bundle_dir <- system.file(
    "extdata", "tubelex", "7cb5fb36",
    package = "ldfreq"
  )
  if (!nzchar(bundle_dir)) {
    .lexres_stop("The installed TUBELEX resource bundle is unavailable.")
  }
  list(
    manifest_path = file.path(bundle_dir, "resource.manifest.dcf"),
    artifact_paths = c(
      "tubelex_en_treebank_7cb5fb36_slim.csv.gz" = file.path(
        bundle_dir,
        "tubelex_en_treebank_7cb5fb36_slim.csv.gz"
      )
    )
  )
}

.lexres_validate_expectation <- function(expectation) {
  expected_names <- c(
    "resource_id", "resource_version", "manifest_sha256",
    "manifest_locator_id", "manifest_schema_id", "manifest_schema_version",
    "max_manifest_bytes", "max_artifact_bytes", "max_content_bytes",
    "max_artifacts", "max_total_artifact_bytes", "max_total_content_bytes",
    "expectation_sha256"
  )
  if (
    !identical(base::class(expectation), "lexsoph_resource_expectation") ||
      !is.list(expectation)
  ) {
    .lexres_stop("expectation must be created by .lexres_expectation().")
  }
  plain <- base::unclass(expectation)
  if (!identical(base::names(plain), expected_names)) {
    .lexres_stop("expectation must be created by .lexres_expectation().")
  }
  reconstructed <- base::do.call(
    .lexres_expectation,
    plain[seq_len(length(expected_names) - 1L)]
  )
  if (!identical(plain, base::unclass(reconstructed))) {
    .lexres_stop("expectation fields are not canonical or have been altered.")
  }
  invisible(plain)
}

.lexres_validate_local_path <- function(path, argument) {
  path <- .lexres_scalar_string(path, argument)
  has_scheme <- grepl(
    "^[A-Za-z][A-Za-z0-9+.-]*:",
    path,
    perl = TRUE
  )
  windows_drive <- grepl("^[A-Za-z]:[/\\\\]", path, perl = TRUE)
  if ((has_scheme && !windows_drive) || grepl("[[:cntrl:]]", path)) {
    .lexres_stop("%s must be an exact local filesystem path, not a URI.", argument)
  }
  path
}

.lexres_read_raw_once <- function(path, max_bytes) {
  path <- .lexres_validate_local_path(path, "path")
  max_bytes <- .lexres_positive_limit(max_bytes, "max_bytes")
  if (!file.exists(path)) {
    return(list(ok = FALSE, observed_state = "missing", bytes = NULL))
  }
  if (!isTRUE(utils::file_test("-f", path))) {
    return(list(ok = FALSE, observed_state = "not_regular", bytes = NULL))
  }
  information <- file.info(path)
  observed_size <- unname(information$size[[1L]])
  if (!is.finite(observed_size) || observed_size < 0) {
    return(list(ok = FALSE, observed_state = "stat_failed", bytes = NULL))
  }
  if (observed_size > max_bytes) {
    return(list(
      ok = FALSE,
      observed_state = "size_limit_exceeded",
      bytes = NULL
    ))
  }
  if (!identical(unname(file.access(path, mode = 4L)), 0L)) {
    return(list(ok = FALSE, observed_state = "unreadable", bytes = NULL))
  }
  result <- tryCatch({
    connection <- file(path, open = "rb")
    on.exit(close(connection), add = TRUE)
    readBin(connection, what = "raw", n = as.integer(observed_size) + 1L)
  }, error = base::identity)
  if (inherits(result, "error")) {
    return(list(ok = FALSE, observed_state = "read_error", bytes = NULL))
  }
  if (length(result) > max_bytes) {
    return(list(
      ok = FALSE,
      observed_state = "size_limit_exceeded",
      bytes = NULL
    ))
  }
  list(ok = TRUE, observed_state = "available", bytes = result)
}

.lexres_sha256_bytes <- function(bytes) {
  if (!is.raw(bytes) || is.object(bytes) || !is.null(attributes(bytes))) {
    .lexres_stop("bytes must be a plain raw vector.")
  }
  output <- digest::digest(bytes, algo = "sha256", serialize = FALSE)
  .lexres_sha256(unname(output), "computed SHA-256")
}

.lexres_resource_ref <- function(expectation) {
  expectation <- .lexres_validate_expectation(expectation)
  list(
    contract_id = .lexres_contract_id,
    contract_version = .lexres_contract_version,
    resource_id = expectation$resource_id,
    resource_version = expectation$resource_version,
    resource_manifest_sha256 = expectation$manifest_sha256
  )
}

.lexres_failure <- function(
    expectation,
    reason,
    artifact_locator_id,
    artifact_id,
    detection_stage,
    extra,
    manifest = NULL) {
  expectation_fields <- .lexres_validate_expectation(expectation)
  reason <- .lexres_scalar_string(reason, "reason")
  if (!(reason %in% .lexres_failures)) {
    .lexres_stop("reason is not a registered resource failure.")
  }
  common <- list(
    artifact_locator_id = .lexres_normalized_relative(
      artifact_locator_id,
      "artifact_locator_id"
    ),
    artifact_id = .lexres_identifier(artifact_id, "artifact_id"),
    detection_stage = .lexres_identifier(
      detection_stage,
      "detection_stage"
    ),
    fallback_attempted = FALSE,
    download_attempted = FALSE
  )
  if (!is.list(extra) || is.object(extra) || is.null(names(extra))) {
    .lexres_stop("extra failure diagnostics must be a plain named list.")
  }
  required_extra <- switch(
    reason,
    resource_unavailable = "observed_state",
    hash_mismatch = c(
      "hash_role", "expected_sha256", "observed_sha256", "observed_bytes"
    ),
    unsupported_resource_version = c(
      "expected_resource_version", "observed_resource_version"
    ),
    schema_mismatch = c(
      "expected_schema_id", "expected_schema_version", "observed_schema_id",
      "observed_schema_version", "schema_violations"
    )
  )
  if (!identical(names(extra), required_extra)) {
    .lexres_stop("Failure diagnostics do not have the exact fields for %s.", reason)
  }
  diagnostics <- c(common, extra)
  output <- list(
    status = "resource_error",
    failure_reason = reason,
    resource_ref = list(
      contract_id = .lexres_contract_id,
      contract_version = .lexres_contract_version,
      resource_id = expectation_fields$resource_id,
      resource_version = expectation_fields$resource_version,
      resource_manifest_sha256 = expectation_fields$manifest_sha256
    ),
    diagnostics = diagnostics,
    manifest = manifest,
    resource = NULL
  )
  output
}

.lexres_unavailable <- function(
    expectation,
    locator_id,
    artifact_id,
    observed_state,
    manifest = NULL) {
  .lexres_failure(
    expectation = expectation,
    reason = "resource_unavailable",
    artifact_locator_id = locator_id,
    artifact_id = artifact_id,
    detection_stage = "availability",
    extra = list(
      observed_state = .lexres_identifier(observed_state, "observed_state")
    ),
    manifest = manifest
  )
}

.lexres_hash_failure <- function(
    expectation,
    locator_id,
    artifact_id,
    hash_role,
    expected_sha256,
    observed_sha256,
    observed_bytes,
    manifest = NULL) {
  hash_role <- .lexres_scalar_string(hash_role, "hash_role")
  if (!(hash_role %in% c("manifest_bytes", "artifact_bytes", "decoded_content"))) {
    .lexres_stop("hash_role is not registered.")
  }
  expected_sha256 <- .lexres_sha256(expected_sha256, "expected_sha256")
  observed_sha256 <- .lexres_sha256(observed_sha256, "observed_sha256")
  if (identical(expected_sha256, observed_sha256)) {
    .lexres_stop("A hash mismatch requires distinct expected and observed hashes.")
  }
  if (
    length(observed_bytes) != 1L ||
      !is.numeric(observed_bytes) ||
      is.na(observed_bytes) ||
      !is.finite(observed_bytes) ||
      observed_bytes < 0 ||
      observed_bytes != floor(observed_bytes)
  ) {
    .lexres_stop("observed_bytes must be one non-negative integer.")
  }
  .lexres_failure(
    expectation = expectation,
    reason = "hash_mismatch",
    artifact_locator_id = locator_id,
    artifact_id = artifact_id,
    detection_stage = "hash",
    extra = list(
      hash_role = hash_role,
      expected_sha256 = expected_sha256,
      observed_sha256 = observed_sha256,
      observed_bytes = as.double(observed_bytes)
    ),
    manifest = manifest
  )
}

.lexres_version_failure <- function(
    expectation,
    observed_version,
    manifest = NULL) {
  observed_version <- .lexres_scalar_string(
    observed_version,
    "observed_resource_version"
  )
  expectation_fields <- .lexres_validate_expectation(expectation)
  if (identical(expectation_fields$resource_version, observed_version)) {
    .lexres_stop("A version failure requires distinct expected and observed versions.")
  }
  .lexres_failure(
    expectation = expectation,
    reason = "unsupported_resource_version",
    artifact_locator_id = expectation_fields$manifest_locator_id,
    artifact_id = "resource_manifest",
    detection_stage = "version",
    extra = list(
      expected_resource_version = expectation_fields$resource_version,
      observed_resource_version = observed_version
    ),
    manifest = manifest
  )
}

.lexres_schema_failure <- function(
    expectation,
    locator_id,
    artifact_id,
    expected_schema_id,
    expected_schema_version,
    observed_schema_id,
    observed_schema_version,
    violations,
    manifest = NULL) {
  expected_schema_id <- .lexres_identifier(
    expected_schema_id,
    "expected_schema_id"
  )
  expected_schema_version <- .lexres_scalar_string(
    expected_schema_version,
    "expected_schema_version"
  )
  optional_scalar <- function(value, argument) {
    if (length(value) == 1L && is.character(value) && is.na(value)) {
      return(NA_character_)
    }
    if (
      !is.character(value) ||
        is.object(value) ||
        !is.null(dim(value)) ||
        !is.null(attributes(value)) ||
        length(value) != 1L ||
        Encoding(value) %in% c("bytes", "latin1") ||
        !validUTF8(value)
    ) {
      .lexres_stop("%s must be one valid-UTF-8 string or missing.", argument)
    }
    Encoding(value) <- "UTF-8"
    value
  }
  observed_schema_id <- optional_scalar(
    observed_schema_id,
    "observed_schema_id"
  )
  observed_schema_version <- optional_scalar(
    observed_schema_version,
    "observed_schema_version"
  )
  violations <- .lexres_plain_character(violations, "schema_violations")
  violations <- .lexres_plain_unique(violations)
  violations <- violations[.lexres_byte_order(violations)]
  .lexres_failure(
    expectation = expectation,
    reason = "schema_mismatch",
    artifact_locator_id = locator_id,
    artifact_id = artifact_id,
    detection_stage = "schema",
    extra = list(
      expected_schema_id = expected_schema_id,
      expected_schema_version = expected_schema_version,
      observed_schema_id = observed_schema_id,
      observed_schema_version = observed_schema_version,
      schema_violations = violations
    ),
    manifest = manifest
  )
}

.lexres_decode_dcf <- function(bytes) {
  if (!is.raw(bytes)) .lexres_stop("DCF decoder requires raw bytes.")
  if (any(bytes == as.raw(0L))) {
    return(list(ok = FALSE, table = NULL, violation = "nul_byte"))
  }
  text <- tryCatch(rawToChar(bytes), error = base::identity)
  if (inherits(text, "error") || !validUTF8(text)) {
    return(list(ok = FALSE, table = NULL, violation = "invalid_utf8"))
  }
  Encoding(text) <- "UTF-8"
  if (grepl("\\r(?!\\n)", text, perl = TRUE)) {
    return(list(ok = FALSE, table = NULL, violation = "invalid_line_ending"))
  }
  lines <- strsplit(text, "\n", fixed = TRUE)[[1L]]
  lines <- sub("\\r$", "", lines, perl = TRUE)
  has_forbidden_control <- vapply(lines, function(line) {
    raw_line <- charToRaw(line)
    any(raw_line %in% as.raw(c(0:8, 11:12, 14:31, 127)))
  }, logical(1L))
  if (any(has_forbidden_control)) {
    return(list(ok = FALSE, table = NULL, violation = "control_character"))
  }

  records <- list()
  current <- list()
  finish_record <- function() {
    if (!length(current)) return(FALSE)
    records[[length(records) + 1L]] <<- current
    current <<- list()
    TRUE
  }
  for (line in lines) {
    if (!nzchar(line)) {
      finish_record()
      next
    }
    if (grepl("^[[:space:]]", line)) {
      return(list(
        ok = FALSE,
        table = NULL,
        violation = "dcf_continuation_unsupported"
      ))
    }
    separator <- regexpr(":", line, fixed = TRUE)[[1L]]
    if (separator < 2L) {
      return(list(ok = FALSE, table = NULL, violation = "dcf_field_syntax"))
    }
    field <- substr(line, 1L, separator - 1L)
    remainder <- substr(line, separator + 1L, nchar(line, type = "chars"))
    if (!grepl("^[A-Za-z][A-Za-z0-9-]*$", field)) {
      return(list(ok = FALSE, table = NULL, violation = "dcf_field_name"))
    }
    if (nzchar(remainder)) {
      if (!startsWith(remainder, " ")) {
        return(list(ok = FALSE, table = NULL, violation = "dcf_field_spacing"))
      }
      value <- substr(remainder, 2L, nchar(remainder, type = "chars"))
      if (startsWith(value, " ")) {
        return(list(ok = FALSE, table = NULL, violation = "dcf_field_spacing"))
      }
    } else {
      value <- ""
    }
    if (field %in% names(current)) {
      return(list(ok = FALSE, table = NULL, violation = "dcf_duplicate_field"))
    }
    current[[field]] <- value
  }
  finish_record()
  if (!length(records)) {
    return(list(ok = FALSE, table = NULL, violation = "dcf_decode_failed"))
  }
  field_order <- names(records[[1L]])
  if (any(!vapply(
    records,
    function(record) identical(names(record), field_order),
    logical(1L)
  ))) {
    return(list(ok = FALSE, table = NULL, violation = "dcf_record_fields"))
  }
  table <- stats::setNames(lapply(field_order, function(field) {
    vapply(records, function(record) record[[field]], character(1L))
  }), field_order)
  list(
    ok = TRUE,
    table = table,
    row_count = length(records),
    violation = NA_character_
  )
}

.lexres_manifest_version <- function(decoded) {
  if (!isTRUE(decoded$ok) || !("Resource-Version" %in% names(decoded$table))) {
    return(NA_character_)
  }
  values <- .lexres_plain_unique(decoded$table[["Resource-Version"]])
  if (length(values) != 1L || is.na(values) || !nzchar(values)) {
    return(NA_character_)
  }
  unname(values)
}

.lexres_parse_nonnegative_integer <- function(value) {
  if (
    length(value) != 1L ||
      is.na(value) ||
      !grepl("^(0|[1-9][0-9]*)$", value)
  ) {
    return(NA_real_)
  }
  output <- suppressWarnings(as.double(value))
  if (!is.finite(output) || output > 9007199254740991) NA_real_ else output
}

.lexres_parse_identifier_set <- function(value) {
  if (length(value) != 1L || is.na(value) || !nzchar(value)) return(NULL)
  output <- strsplit(value, ",", fixed = TRUE)[[1L]]
  if (
    any(!grepl("^[a-z][a-z0-9._-]*$", output)) ||
      .lexres_has_duplicate(output) ||
      !identical(.lexres_byte_order(output), seq_along(output))
  ) {
    return(NULL)
  }
  output
}

.lexres_manifest_semantics <- function(decoded, expectation) {
  observed_schema_id <- if (
    isTRUE(decoded$ok) && "Manifest-Schema-ID" %in% names(decoded$table)
  ) decoded$table[["Manifest-Schema-ID"]][[1L]] else NA_character_
  observed_schema_version <- if (
    isTRUE(decoded$ok) && "Manifest-Schema-Version" %in% names(decoded$table)
  ) decoded$table[["Manifest-Schema-Version"]][[1L]] else NA_character_
  if (!isTRUE(decoded$ok)) {
    return(list(
      ok = FALSE,
      observed_schema_id = observed_schema_id,
      observed_schema_version = observed_schema_version,
      violations = decoded$violation,
      manifest = NULL
    ))
  }
  table <- decoded$table
  row_count <- decoded$row_count
  violations <- character()
  if (
    !is.list(table) || is.object(table) ||
      !identical(names(table), .lexres_manifest_dcf_fields) ||
      !identical(unname(lengths(table)), rep.int(row_count, length(table)))
  ) {
    violations <- c(violations, "manifest_fields")
  }
  required_present <- all(.lexres_manifest_dcf_fields %in% names(table))
  if (!required_present) {
    return(list(
      ok = FALSE,
      observed_schema_id = observed_schema_id,
      observed_schema_version = observed_schema_version,
      violations = .lexres_plain_unique(c(violations, "manifest_fields_missing")),
      manifest = NULL
    ))
  }
  common_fields <- .lexres_manifest_dcf_fields[1:9]
  for (field in common_fields) {
    if (length(.lexres_plain_unique(table[[field]])) != 1L) {
      violations <- c(violations, "inconsistent_resource_fields")
      break
    }
  }
  if (!identical(observed_schema_id, expectation$manifest_schema_id)) {
    violations <- c(violations, "manifest_schema_id")
  }
  if (!identical(observed_schema_version, expectation$manifest_schema_version)) {
    violations <- c(violations, "manifest_schema_version")
  }
  if (!identical(table[["Resource-ID"]][[1L]], expectation$resource_id)) {
    violations <- c(violations, "resource_id")
  }
  if (!identical(table[["Resource-Version"]][[1L]], expectation$resource_version)) {
    violations <- c(violations, "resource_version")
  }
  identifier_fields <- c(
    "Bundle-Variant-ID", "Resource-Schema-ID", "Lookup-Unit",
    "Normalization-ID", "Artifact-ID", "Artifact-Role",
    "Content-Schema-ID"
  )
  for (field in identifier_fields) {
    if (any(!grepl("^[a-z][a-z0-9._-]*$", table[[field]]))) {
      violations <- c(violations, paste0("invalid_", tolower(field)))
    }
  }
  nonempty_fields <- c(
    "Manifest-Schema-ID", "Manifest-Schema-Version", "Resource-ID",
    "Resource-Version", "Resource-Schema-Version", "Artifact-Version",
    "Content-Schema-Version", "License-ID", "Source-Layer-IDs"
  )
  for (field in nonempty_fields) {
    if (anyNA(table[[field]]) || any(!nzchar(table[[field]]))) {
      violations <- c(violations, paste0("empty_", tolower(field)))
    }
  }
  all_values <- unlist(table, recursive = FALSE, use.names = FALSE)
  if (any(grepl("[[:cntrl:]]", all_values))) {
    violations <- c(violations, "control_character")
  }
  for (field in c("Artifact-SHA256", "Content-SHA256")) {
    if (any(!grepl("^[0-9a-f]{64}$", table[[field]]))) {
      violations <- c(violations, paste0("invalid_", tolower(field)))
    }
  }
  parsed_artifact_bytes <- vapply(
    table[["Artifact-Bytes"]],
    .lexres_parse_nonnegative_integer,
    numeric(1L)
  )
  parsed_content_bytes <- vapply(
    table[["Content-Bytes"]],
    .lexres_parse_nonnegative_integer,
    numeric(1L)
  )
  if (anyNA(parsed_artifact_bytes)) violations <- c(violations, "artifact_bytes")
  if (anyNA(parsed_content_bytes)) violations <- c(violations, "content_bytes")
  parsed_source_layers <- lapply(
    table[["Source-Layer-IDs"]],
    .lexres_parse_identifier_set
  )
  if (any(vapply(parsed_source_layers, is.null, logical(1L)))) {
    violations <- c(violations, "source_layer_ids")
  }
  if (any(!(table[["Compression"]] %in% c("none", "gzip")))) {
    violations <- c(violations, "compression")
  }
  normalized_locator <- vapply(seq_len(row_count), function(index) {
    !inherits(tryCatch(
      .lexres_normalized_relative(
        table[["Artifact-Locator-ID"]][[index]],
        "Artifact-Locator-ID"
      ),
      error = base::identity
    ), "error")
  }, logical(1L))
  normalized_notice <- vapply(seq_len(row_count), function(index) {
    !inherits(tryCatch(
      .lexres_normalized_relative(
        table[["Notice-Path"]][[index]],
        "Notice-Path"
      ),
      error = base::identity
    ), "error")
  }, logical(1L))
  if (any(!normalized_locator)) violations <- c(violations, "artifact_locator")
  if (any(!normalized_notice)) violations <- c(violations, "notice_path")
  artifact_ids <- table[["Artifact-ID"]]
  if (.lexres_has_duplicate(artifact_ids)) {
    violations <- c(violations, "artifact_id_duplicate")
  }
  if (.lexres_has_duplicate(table[["Artifact-Locator-ID"]])) {
    violations <- c(violations, "artifact_locator_duplicate")
  }
  if (!identical(.lexres_byte_order(artifact_ids), seq_along(artifact_ids))) {
    violations <- c(violations, "artifact_id_order")
  }
  violations <- .lexres_plain_unique(violations)
  if (length(violations)) {
    return(list(
      ok = FALSE,
      observed_schema_id = observed_schema_id,
      observed_schema_version = observed_schema_version,
      violations = violations,
      manifest = NULL
    ))
  }
  artifacts <- lapply(seq_len(row_count), function(index) {
    list(
      artifact_id = table[["Artifact-ID"]][[index]],
      artifact_version = table[["Artifact-Version"]][[index]],
      artifact_sha256 = table[["Artifact-SHA256"]][[index]],
      artifact_bytes = parsed_artifact_bytes[[index]],
      artifact_role = table[["Artifact-Role"]][[index]],
      artifact_locator_id = table[["Artifact-Locator-ID"]][[index]],
      content_schema_id = table[["Content-Schema-ID"]][[index]],
      content_schema_version = table[["Content-Schema-Version"]][[index]],
      license_id = table[["License-ID"]][[index]],
      notice_path = table[["Notice-Path"]][[index]],
      compression = table[["Compression"]][[index]],
      content_sha256 = table[["Content-SHA256"]][[index]],
      content_bytes = parsed_content_bytes[[index]],
      source_layer_ids = parsed_source_layers[[index]]
    )
  })
  list(
    ok = TRUE,
    observed_schema_id = observed_schema_id,
    observed_schema_version = observed_schema_version,
    violations = character(),
    manifest = list(
      resource_manifest_schema_id = observed_schema_id,
      resource_manifest_schema_version = observed_schema_version,
      resource_id = table[["Resource-ID"]][[1L]],
      resource_version = table[["Resource-Version"]][[1L]],
      bundle_variant_id = table[["Bundle-Variant-ID"]][[1L]],
      resource_schema_id = table[["Resource-Schema-ID"]][[1L]],
      resource_schema_version = table[["Resource-Schema-Version"]][[1L]],
      lookup_unit = table[["Lookup-Unit"]][[1L]],
      normalization_id = table[["Normalization-ID"]][[1L]],
      artifacts = artifacts
    )
  )
}

.lexres_sum_exceeds <- function(values, limit) {
  total <- 0
  for (value in values) {
    if (value > limit - total) return(TRUE)
    total <- total + value
  }
  FALSE
}

.lexres_validate_artifact_paths <- function(artifact_paths, manifest) {
  if (
    !is.character(artifact_paths) ||
      is.object(artifact_paths) ||
      !is.null(dim(artifact_paths)) ||
      is.null(names(artifact_paths)) ||
      anyNA(artifact_paths) ||
      any(!nzchar(artifact_paths)) ||
      anyNA(names(artifact_paths)) ||
      any(!nzchar(names(artifact_paths))) ||
      .lexres_has_duplicate(names(artifact_paths))
  ) {
    .lexres_stop("artifact_paths must be a plain uniquely named character vector.")
  }
  expected_names <- vapply(
    manifest$artifacts,
    function(artifact) artifact$artifact_locator_id,
    character(1L)
  )
  if (!identical(names(artifact_paths), expected_names)) {
    .lexres_stop(
      "artifact_paths names and order must exactly match the manifest locator inventory."
    )
  }
  vapply(seq_along(artifact_paths), function(index) {
    .lexres_validate_local_path(
      artifact_paths[[index]],
      sprintf("artifact_paths[[%d]]", index)
    )
  }, character(1L), USE.NAMES = FALSE)
}

.lexres_decode_synthetic_term_count <- function(bytes) {
  if (any(bytes == as.raw(0L))) {
    return(list(
      ok = FALSE,
      observed_schema_id = NA_character_,
      observed_schema_version = NA_character_,
      violations = "nul_byte",
      resource = NULL
    ))
  }
  text <- tryCatch(rawToChar(bytes), error = base::identity)
  if (inherits(text, "error") || !validUTF8(text)) {
    return(list(
      ok = FALSE,
      observed_schema_id = NA_character_,
      observed_schema_version = NA_character_,
      violations = "invalid_utf8",
      resource = NULL
    ))
  }
  Encoding(text) <- "UTF-8"
  lines <- strsplit(text, "\n", fixed = TRUE)[[1L]]
  if (length(lines) && !nzchar(lines[[length(lines)]])) {
    lines <- lines[-length(lines)]
  }
  observed_id <- if (
    length(lines) && identical(lines[[1L]], "term\tcount")
  ) "synthetic-term-count-tsv" else "unrecognized-tsv-header"
  observed_version <- if (
    identical(observed_id, "synthetic-term-count-tsv")
  ) "1" else NA_character_
  if (!identical(observed_id, "synthetic-term-count-tsv")) {
    return(list(
      ok = FALSE,
      observed_schema_id = observed_id,
      observed_schema_version = observed_version,
      violations = "unexpected_header",
      resource = NULL
    ))
  }
  if (length(lines) < 2L) {
    return(list(
      ok = FALSE,
      observed_schema_id = observed_id,
      observed_schema_version = observed_version,
      violations = "no_data_rows",
      resource = NULL
    ))
  }
  fields <- strsplit(lines[-1L], "\t", fixed = TRUE)
  if (any(lengths(fields) != 2L)) {
    return(list(
      ok = FALSE,
      observed_schema_id = observed_id,
      observed_schema_version = observed_version,
      violations = "row_arity",
      resource = NULL
    ))
  }
  terms <- vapply(fields, `[[`, character(1L), 1L)
  counts_text <- vapply(fields, `[[`, character(1L), 2L)
  violations <- character()
  if (any(!grepl("^[a-z]+$", terms))) violations <- c(violations, "term_format")
  if (.lexres_has_duplicate(terms)) violations <- c(violations, "duplicate_term")
  counts <- unname(vapply(
    counts_text,
    .lexres_parse_nonnegative_integer,
    numeric(1L),
    USE.NAMES = FALSE
  ))
  if (anyNA(counts)) violations <- c(violations, "count_format")
  if (length(violations)) {
    return(list(
      ok = FALSE,
      observed_schema_id = observed_id,
      observed_schema_version = observed_version,
      violations = violations,
      resource = NULL
    ))
  }
  list(
    ok = TRUE,
    observed_schema_id = observed_id,
    observed_schema_version = observed_version,
    violations = character(),
    resource = list(term = terms, count = counts)
  )
}

.lexres_decode_gzip_bounded <- function(bytes, max_bytes) {
  if (
    length(bytes) < 2L ||
      !identical(bytes[1:2], as.raw(c(0x1f, 0x8b)))
  ) {
    return(list(
      ok = FALSE,
      limit_exceeded = FALSE,
      violation = "gzip_header",
      bytes = NULL
    ))
  }
  raw_connection <- rawConnection(bytes, open = "rb")
  gzip_connection <- tryCatch(
    gzcon(raw_connection, allowNonCompressed = FALSE, text = FALSE),
    error = base::identity
  )
  if (inherits(gzip_connection, "error")) {
    try(close(raw_connection), silent = TRUE)
    return(list(
      ok = FALSE,
      limit_exceeded = FALSE,
      violation = "gzip_stream",
      bytes = NULL
    ))
  }
  on.exit(try(close(gzip_connection), silent = TRUE), add = TRUE)

  chunks <- list()
  total <- 0
  decoded <- tryCatch({
    repeat {
      request <- min(1048576, max_bytes - total + 1)
      chunk <- readBin(
        gzip_connection,
        what = "raw",
        n = as.integer(request)
      )
      if (!length(chunk)) break
      total <- total + length(chunk)
      if (total > max_bytes) {
        return(list(
          ok = FALSE,
          limit_exceeded = TRUE,
          violation = "content_size_limit_exceeded",
          bytes = NULL
        ))
      }
      chunks[[length(chunks) + 1L]] <- chunk
    }
    if (!length(chunks)) raw() else do.call(c, chunks)
  }, error = base::identity)
  if (is.list(decoded) && identical(decoded$limit_exceeded, TRUE)) {
    return(decoded)
  }
  if (inherits(decoded, "error")) {
    return(list(
      ok = FALSE,
      limit_exceeded = FALSE,
      violation = "gzip_stream",
      bytes = NULL
    ))
  }
  list(
    ok = TRUE,
    limit_exceeded = FALSE,
    violation = NA_character_,
    bytes = decoded
  )
}

.lexres_decode_compression <- function(bytes, compression, max_bytes) {
  if (identical(compression, "none")) {
    if (length(bytes) > max_bytes) {
      return(list(
        ok = FALSE,
        limit_exceeded = TRUE,
        violation = "content_size_limit_exceeded",
        bytes = NULL
      ))
    }
    return(list(
      ok = TRUE,
      limit_exceeded = FALSE,
      violation = NA_character_,
      bytes = bytes
    ))
  }
  if (identical(compression, "gzip")) {
    return(.lexres_decode_gzip_bounded(bytes, max_bytes))
  }
  list(
    ok = FALSE,
    limit_exceeded = FALSE,
    violation = "compression_adapter_unregistered",
    bytes = NULL
  )
}

.lexres_decode_tubelex_frequency <- function(bytes) {
  failure <- function(violations) {
    list(
      ok = FALSE,
      observed_schema_id = "tubelex-frequency-prevalence-csv",
      observed_schema_version = "1",
      violations = .lexres_plain_unique(violations),
      resource = NULL
    )
  }
  if (!length(bytes) || any(bytes == as.raw(0L))) {
    return(failure(if (!length(bytes)) "empty_content" else "nul_byte"))
  }
  if (any(bytes == as.raw(13L)) || !identical(bytes[[length(bytes)]], as.raw(10L))) {
    return(failure("line_endings"))
  }
  if (
    length(bytes) > 1L &&
      any(
        bytes[-length(bytes)] == as.raw(10L) &
          bytes[-1L] == as.raw(10L)
      )
  ) {
    return(failure("blank_line"))
  }
  text <- tryCatch(rawToChar(bytes), error = base::identity)
  if (inherits(text, "error") || !validUTF8(text)) {
    return(failure("invalid_utf8"))
  }
  Encoding(text) <- "UTF-8"
  connection <- textConnection(text, open = "r", local = TRUE)
  table <- tryCatch(
    utils::read.table(
      connection,
      header = TRUE,
      sep = ",",
      quote = "",
      comment.char = "",
      colClasses = rep.int("character", 4L),
      check.names = FALSE,
      stringsAsFactors = FALSE,
      blank.lines.skip = TRUE,
      fill = FALSE,
      strip.white = FALSE
    ),
    error = base::identity
  )
  try(close(connection), silent = TRUE)
  if (inherits(table, "error")) return(failure("csv_decode"))

  expected_columns <- c("word", "count", "videos", "channels")
  violations <- character()
  if (!identical(names(table), expected_columns)) {
    return(failure("unexpected_header"))
  }
  if (!identical(nrow(table), 515293L)) {
    violations <- c(violations, "row_count")
  }
  fields <- unname(as.list(table))
  if (any(vapply(fields, anyNA, logical(1L))) ||
      any(vapply(fields, function(field) any(!nzchar(field)), logical(1L)))) {
    violations <- c(violations, "empty_field")
  }

  words <- table[["word"]]
  if (length(words)) Encoding(words) <- "UTF-8"
  if (
    !length(words) ||
      !identical(words[[length(words)]], "[TOTAL]") ||
      any(words[-length(words)] == "[TOTAL]")
  ) {
    violations <- c(violations, "total_row")
  }
  lexical_words <- if (length(words)) words[-length(words)] else character()
  if (
    any(!validUTF8(lexical_words)) ||
      any(grepl("[[:cntrl:],]", lexical_words)) ||
      any(nchar(lexical_words, type = "chars") > 64L)
  ) {
    violations <- c(violations, "word_format")
  }
  if (anyDuplicated(lexical_words)) {
    violations <- c(violations, "duplicate_word")
  }

  numeric_text <- table[c("count", "videos", "channels")]
  canonical_numeric <- vapply(
    numeric_text,
    function(field) all(grepl("^(0|[1-9][0-9]*)$", field)),
    logical(1L)
  )
  numeric_values <- lapply(
    numeric_text,
    function(field) suppressWarnings(as.double(field))
  )
  if (!all(canonical_numeric) ||
      any(vapply(numeric_values, function(field) {
        any(!is.finite(field) | field > 9007199254740991)
      }, logical(1L)))) {
    violations <- c(violations, "numeric_format")
  }
  counts <- numeric_values[["count"]]
  videos <- numeric_values[["videos"]]
  channels <- numeric_values[["channels"]]
  if (length(counts) && any(channels > videos | videos > counts)) {
    violations <- c(violations, "count_order")
  }
  if (
    length(counts) &&
      !identical(
        c(count = counts[[length(counts)]],
          videos = videos[[length(videos)]],
          channels = channels[[length(channels)]]),
        c(count = 171805865, videos = 105733, channels = 68405)
      )
  ) {
    violations <- c(violations, "total_values")
  }
  if (length(violations)) return(failure(violations))

  row_indexes <- seq_len(length(words) - 1L)
  list(
    ok = TRUE,
    observed_schema_id = "tubelex-frequency-prevalence-csv",
    observed_schema_version = "1",
    violations = character(),
    resource = list(
      word = lexical_words,
      count = counts[row_indexes],
      videos = videos[row_indexes],
      channels = channels[row_indexes],
      totals = list(
        count = counts[[length(counts)]],
        videos = videos[[length(videos)]],
        channels = channels[[length(channels)]]
      )
    )
  )
}

.lexres_decode_content <- function(bytes, schema_id, schema_version) {
  adapter_key <- paste(schema_id, schema_version, sep = "::")
  switch(
    adapter_key,
    "synthetic-term-count-tsv::1" =
      .lexres_decode_synthetic_term_count(bytes),
    "tubelex-frequency-prevalence-csv::1" =
      .lexres_decode_tubelex_frequency(bytes),
    list(
      ok = FALSE,
      observed_schema_id = NA_character_,
      observed_schema_version = NA_character_,
      violations = "content_adapter_unregistered",
      resource = NULL
    )
  )
}

.lexres_load_resource_impl <- function(
    manifest_path,
    expectation,
    artifact_paths,
    reader = .lexres_read_raw_once) {
  expectation_fields <- .lexres_validate_expectation(expectation)
  manifest_path <- .lexres_validate_local_path(manifest_path, "manifest_path")
  if (!identical(reader, .lexres_read_raw_once) && !is.function(reader)) {
    .lexres_stop("reader must be the internal reader or a test seam function.")
  }

  manifest_read <- reader(manifest_path, expectation_fields$max_manifest_bytes)
  if (!isTRUE(manifest_read$ok)) {
    return(.lexres_unavailable(
      expectation,
      expectation_fields$manifest_locator_id,
      "resource_manifest",
      manifest_read$observed_state
    ))
  }
  manifest_bytes <- manifest_read$bytes
  manifest_hash <- .lexres_sha256_bytes(manifest_bytes)
  if (!identical(manifest_hash, expectation_fields$manifest_sha256)) {
    return(.lexres_hash_failure(
      expectation,
      expectation_fields$manifest_locator_id,
      "resource_manifest",
      "manifest_bytes",
      expectation_fields$manifest_sha256,
      manifest_hash,
      length(manifest_bytes)
    ))
  }

  decoded_manifest <- .lexres_decode_dcf(manifest_bytes)
  observed_version <- .lexres_manifest_version(decoded_manifest)
  if (!is.na(observed_version) &&
      !identical(observed_version, expectation_fields$resource_version)) {
    return(.lexres_version_failure(expectation, observed_version))
  }
  manifest_result <- .lexres_manifest_semantics(
    decoded_manifest,
    expectation_fields
  )
  if (!isTRUE(manifest_result$ok)) {
    return(.lexres_schema_failure(
      expectation,
      expectation_fields$manifest_locator_id,
      "resource_manifest",
      expectation_fields$manifest_schema_id,
      expectation_fields$manifest_schema_version,
      manifest_result$observed_schema_id,
      manifest_result$observed_schema_version,
      manifest_result$violations
    ))
  }
  manifest <- manifest_result$manifest
  if (length(manifest$artifacts) > expectation_fields$max_artifacts) {
    return(.lexres_unavailable(
      expectation,
      expectation_fields$manifest_locator_id,
      "resource_manifest",
      "artifact_count_limit_exceeded",
      manifest = manifest
    ))
  }
  declared_artifact_bytes <- vapply(
    manifest$artifacts,
    function(artifact) artifact$artifact_bytes,
    numeric(1L)
  )
  if (.lexres_sum_exceeds(
    declared_artifact_bytes,
    expectation_fields$max_total_artifact_bytes
  )) {
    return(.lexres_unavailable(
      expectation,
      expectation_fields$manifest_locator_id,
      "resource_manifest",
      "bundle_artifact_size_limit_exceeded",
      manifest = manifest
    ))
  }
  declared_content_bytes <- vapply(
    manifest$artifacts,
    function(artifact) artifact$content_bytes,
    numeric(1L)
  )
  if (.lexres_sum_exceeds(
    declared_content_bytes,
    expectation_fields$max_total_content_bytes
  )) {
    return(.lexres_unavailable(
      expectation,
      expectation_fields$manifest_locator_id,
      "resource_manifest",
      "bundle_content_size_limit_exceeded",
      manifest = manifest
    ))
  }
  artifact_paths <- .lexres_validate_artifact_paths(artifact_paths, manifest)

  resources <- vector("list", length(manifest$artifacts))
  evidence <- vector("list", length(manifest$artifacts))
  artifact_ids <- vapply(
    manifest$artifacts,
    function(artifact) artifact$artifact_id,
    character(1L)
  )
  names(resources) <- artifact_ids
  names(evidence) <- artifact_ids
  for (index in seq_along(manifest$artifacts)) {
    artifact <- manifest$artifacts[[index]]
    artifact_path <- artifact_paths[[index]]
    artifact_read <- reader(artifact_path, expectation_fields$max_artifact_bytes)
    if (!isTRUE(artifact_read$ok)) {
      return(.lexres_unavailable(
        expectation,
        artifact$artifact_locator_id,
        artifact$artifact_id,
        artifact_read$observed_state,
        manifest = manifest
      ))
    }
    artifact_bytes <- artifact_read$bytes
    artifact_hash <- .lexres_sha256_bytes(artifact_bytes)
    if (!identical(artifact_hash, artifact$artifact_sha256)) {
      return(.lexres_hash_failure(
        expectation,
        artifact$artifact_locator_id,
        artifact$artifact_id,
        "artifact_bytes",
        artifact$artifact_sha256,
        artifact_hash,
        length(artifact_bytes),
        manifest = manifest
      ))
    }
    if (length(artifact_bytes) != artifact$artifact_bytes) {
      return(.lexres_schema_failure(
        expectation,
        artifact$artifact_locator_id,
        artifact$artifact_id,
        artifact$content_schema_id,
        artifact$content_schema_version,
        artifact$content_schema_id,
        artifact$content_schema_version,
        "artifact_byte_count_mismatch",
        manifest = manifest
      ))
    }
    if (artifact$content_bytes > expectation_fields$max_content_bytes) {
      return(.lexres_unavailable(
        expectation,
        artifact$artifact_locator_id,
        artifact$artifact_id,
        "content_size_limit_exceeded",
        manifest = manifest
      ))
    }
    compression_result <- .lexres_decode_compression(
      artifact_bytes,
      artifact$compression,
      expectation_fields$max_content_bytes
    )
    if (!isTRUE(compression_result$ok) &&
        isTRUE(compression_result$limit_exceeded)) {
      return(.lexres_unavailable(
        expectation,
        artifact$artifact_locator_id,
        artifact$artifact_id,
        "content_size_limit_exceeded",
        manifest = manifest
      ))
    }
    if (!isTRUE(compression_result$ok)) {
      return(.lexres_schema_failure(
        expectation,
        artifact$artifact_locator_id,
        artifact$artifact_id,
        artifact$content_schema_id,
        artifact$content_schema_version,
        NA_character_,
        NA_character_,
        compression_result$violation,
        manifest = manifest
      ))
    }
    content_bytes <- compression_result$bytes
    content_hash <- .lexres_sha256_bytes(content_bytes)
    if (!identical(content_hash, artifact$content_sha256)) {
      return(.lexres_hash_failure(
        expectation,
        artifact$artifact_locator_id,
        artifact$artifact_id,
        "decoded_content",
        artifact$content_sha256,
        content_hash,
        length(content_bytes),
        manifest = manifest
      ))
    }
    if (length(content_bytes) != artifact$content_bytes) {
      return(.lexres_schema_failure(
        expectation,
        artifact$artifact_locator_id,
        artifact$artifact_id,
        artifact$content_schema_id,
        artifact$content_schema_version,
        artifact$content_schema_id,
        artifact$content_schema_version,
        "content_byte_count_mismatch",
        manifest = manifest
      ))
    }
    decoded_content <- .lexres_decode_content(
      content_bytes,
      artifact$content_schema_id,
      artifact$content_schema_version
    )
    if (!isTRUE(decoded_content$ok)) {
      return(.lexres_schema_failure(
        expectation,
        artifact$artifact_locator_id,
        artifact$artifact_id,
        artifact$content_schema_id,
        artifact$content_schema_version,
        decoded_content$observed_schema_id,
        decoded_content$observed_schema_version,
        decoded_content$violations,
        manifest = manifest
      ))
    }
    resources[[index]] <- decoded_content$resource
    evidence[[index]] <- list(
      artifact_id = artifact$artifact_id,
      artifact_locator_id = artifact$artifact_locator_id,
      artifact_sha256 = artifact_hash,
      artifact_bytes = as.double(length(artifact_bytes)),
      content_sha256 = content_hash,
      content_bytes = as.double(length(content_bytes)),
      compression = artifact$compression,
      content_schema_id = decoded_content$observed_schema_id,
      content_schema_version = decoded_content$observed_schema_version
    )
  }

  output <- list(
    status = "ok",
    failure_reason = NA_character_,
    resource_ref = list(
      contract_id = .lexres_contract_id,
      contract_version = .lexres_contract_version,
      resource_id = expectation_fields$resource_id,
      resource_version = expectation_fields$resource_version,
      resource_manifest_sha256 = expectation_fields$manifest_sha256
    ),
    diagnostics = list(
      manifest_locator_id = expectation_fields$manifest_locator_id,
      manifest_sha256 = manifest_hash,
      manifest_bytes = as.double(length(manifest_bytes)),
      fallback_attempted = FALSE,
      download_attempted = FALSE,
      artifact_evidence = evidence
    ),
    manifest = manifest,
    resource = resources
  )
  output
}

.lexres_load_resource <- function(manifest_path, expectation, artifact_paths) {
  .lexres_load_resource_impl(
    manifest_path = manifest_path,
    expectation = expectation,
    artifact_paths = artifact_paths,
    reader = .lexres_read_raw_once
  )
}

.lexres_load_tubelex <- function() {
  paths <- .lexres_tubelex_paths()
  .lexres_load_resource(
    paths$manifest_path,
    .lexres_tubelex_expectation(),
    paths$artifact_paths
  )
}
