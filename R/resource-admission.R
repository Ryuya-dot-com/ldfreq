# Internal, non-exported release-admission evidence gate.
#
# This gate validates a pinned candidate, a strict external approval record,
# and the exact bytes of its preserved review evidence. It does not authenticate
# a reviewer, create an approval, expose a public API, or declare the package
# release-ready.

.lexres_admission_contract_id <- "ldfreq-resource-release-admission"
.lexres_admission_contract_version <- "0.1.0-draft.1"
.lexres_tubelex_admission_candidate_id <-
  "tubelex-en-treebank-slim-7cb5fb36-admission-v1"
.lexres_tubelex_admission_candidate_sha256 <-
  "8c8eca27e3f2810f6f1c8ed158f93acb22d8ad885d3832448cf3b6d194309de6"
.lexres_admission_approval_schema_id <- "ldfreq-resource-release-approval"
.lexres_admission_approval_schema_version <- "0.1.0"
.lexres_admission_approval_fields <- c(
  "Approval-Schema-ID",
  "Approval-Schema-Version",
  "Approval-ID",
  "Candidate-ID",
  "Candidate-SHA256",
  "Reviewed-Repository-Commit",
  "Reviewer-Name",
  "Reviewer-Affiliation",
  "Reviewer-GitHub-Login",
  "Reviewed-On",
  "Decision",
  "Independence-Attested",
  "Not-Candidate-Author-Or-Builder",
  "Redistribution-Terms",
  "Notice-And-Attribution",
  "Source-And-Artifact-Identity",
  "Package-Distribution-Scope",
  "Public-API-Scope",
  "Evidence-URL",
  "Evidence-Locator-ID",
  "Evidence-SHA256"
)
.lexres_admission_remaining_gates <- c(
  "public lookup and result contract",
  "final release-candidate source, installed, and binary inventory audit"
)

.lexres_admission_ref <- function() {
  list(
    contract_id = .lexres_admission_contract_id,
    contract_version = .lexres_admission_contract_version
  )
}

.lexres_tubelex_admission_candidate_ref <- function() {
  list(
    candidate_id = .lexres_tubelex_admission_candidate_id,
    candidate_sha256 = .lexres_tubelex_admission_candidate_sha256,
    candidate_state = "pending-independent-review"
  )
}

.lexres_tubelex_admission_paths <- function() {
  list(
    candidate_path = system.file(
      "spec", "tubelex-release-admission-candidate.json",
      package = "ldfreq"
    ),
    candidate_schema_path = system.file(
      "spec", "tubelex-release-admission-candidate.schema.json",
      package = "ldfreq"
    )
  )
}

.lexres_admission_result <- function(
    status,
    admission_gate_passed,
    failure_reason,
    approval_ref = NULL,
    diagnostics = list()) {
  list(
    status = status,
    admission_gate_passed = admission_gate_passed,
    package_release_ready = FALSE,
    failure_reason = failure_reason,
    admission_ref = .lexres_admission_ref(),
    candidate_ref = .lexres_tubelex_admission_candidate_ref(),
    resource_ref = .lexres_resource_ref(.lexres_tubelex_expectation()),
    approval_ref = approval_ref,
    remaining_gates = .lexres_admission_remaining_gates,
    diagnostics = diagnostics
  )
}

.lexres_admission_diagnostics <- function(...) {
  c(
    list(
      fallback_attempted = FALSE,
      download_attempted = FALSE,
      approval_authenticity_proven = FALSE,
      cryptographic_signature_verified = FALSE
    ),
    list(...)
  )
}

.lexres_admission_candidate_semantics <- function(record) {
  expected_top_names <- c(
    "$schema", "schema_version", "candidate_id", "candidate_state",
    "resource", "distribution_scope", "contract_refs", "approval_policy",
    "approval_record_contract", "remaining_gates_after_resource_approval"
  )
  if (!is.list(record) || is.object(record) ||
      !identical(names(record), expected_top_names)) {
    return(FALSE)
  }
  expected_resource <- list(
    resource_id = "tubelex-en-treebank-slim",
    resource_version = "7cb5fb36-slim-v1",
    upstream_commit = "7cb5fb36add76b83a266d1967536e1a1d3faa513",
    upstream_source_sha256 =
      "4096022259d5eaa7261c3bf22c3b0af9fd58ae8eebe17894c0b34a163954f936",
    manifest_sha256 = .lexres_tubelex_manifest_sha256,
    artifact_sha256 =
      "ded083e5b9f59ddfb719ebd88063778500cb347e1eab0f2d79ff55085d92fb4d",
    content_sha256 =
      "423dd4631c9da2f7442705d2930126da4cba980e46b6a5c0dda98336dce74916",
    license_spdx = "BSD-3-Clause",
    notice_path = "licenses/tubelex/NOTICE.md",
    notice_sha256 =
      "e65a1f5d0d6e7806e31e92d78bf3b903115e610c36bd9f2406269700441ecdd3"
  )
  expected_distribution <- list(
    package_component_state = "internal-development-candidate",
    raw_source_bundled = FALSE,
    raw_subtitles_or_identifiers_included = FALSE,
    runtime_network_access = FALSE,
    implicit_download_or_fallback = FALSE,
    public_api = FALSE,
    release_approved = FALSE
  )
  expected_contracts <- list(
    loader_contract_id = .lexres_contract_id,
    loader_contract_version = .lexres_contract_version,
    lookup_contract_id = .lexres_lookup_contract_id,
    lookup_contract_version = .lexres_lookup_contract_version,
    lookup_result_schema_id = .lexres_lookup_result_schema_id,
    lookup_result_schema_version = .lexres_lookup_result_schema_version
  )
  expected_policy <- list(
    independent_reviewer_required = TRUE,
    candidate_author_or_builder_may_approve = FALSE,
    approval_record_bundled = FALSE,
    unsigned_local_claim_is_not_proof = TRUE,
    disallowed_approver_logins = list("Ryuya-dot-com")
  )
  expected_approval_names <- c(
    "format", "schema_id", "schema_version", "fields",
    "approved_scope_values"
  )
  expected_scope <- list(
    redistribution_terms = "approved",
    notice_and_attribution = "approved",
    source_and_artifact_identity = "approved",
    package_distribution_scope = "approved",
    public_api_scope = "not-reviewed"
  )
  approval_contract <- record$approval_record_contract
  identical(record$`$schema`, "tubelex-release-admission-candidate.schema.json") &&
    identical(record$schema_version, "0.1.0") &&
    identical(record$candidate_id, .lexres_tubelex_admission_candidate_id) &&
    identical(record$candidate_state, "pending-independent-review") &&
    identical(record$resource, expected_resource) &&
    identical(record$distribution_scope, expected_distribution) &&
    identical(record$contract_refs, expected_contracts) &&
    identical(record$approval_policy, expected_policy) &&
    is.list(approval_contract) && !is.object(approval_contract) &&
    identical(names(approval_contract), expected_approval_names) &&
    identical(approval_contract$format, "strict-single-record-dcf") &&
    identical(
      approval_contract$schema_id,
      .lexres_admission_approval_schema_id
    ) &&
    identical(
      approval_contract$schema_version,
      .lexres_admission_approval_schema_version
    ) &&
    identical(
      unlist(approval_contract$fields, use.names = FALSE),
      .lexres_admission_approval_fields
    ) &&
    identical(approval_contract$approved_scope_values, expected_scope) &&
    identical(
      unlist(
        record$remaining_gates_after_resource_approval,
        use.names = FALSE
      ),
      .lexres_admission_remaining_gates
    )
}

.lexres_load_tubelex_admission_candidate <- function(
    reader = .lexres_read_raw_once) {
  paths <- .lexres_tubelex_admission_paths()
  if (!is.function(reader)) {
    .lexres_stop("reader must be an internal or test-seam function.")
  }
  if (!nzchar(paths$candidate_path) || !nzchar(paths$candidate_schema_path)) {
    return(.lexres_admission_result(
      status = "candidate_error",
      admission_gate_passed = FALSE,
      failure_reason = "candidate_unavailable",
      diagnostics = .lexres_admission_diagnostics(
        candidate_state = "missing_installed_contract"
      )
    ))
  }
  candidate_read <- reader(paths$candidate_path, 65536)
  if (!isTRUE(candidate_read$ok)) {
    return(.lexres_admission_result(
      status = "candidate_error",
      admission_gate_passed = FALSE,
      failure_reason = "candidate_unavailable",
      diagnostics = .lexres_admission_diagnostics(
        candidate_state = candidate_read$observed_state
      )
    ))
  }
  candidate_hash <- .lexres_sha256_bytes(candidate_read$bytes)
  if (!identical(
    candidate_hash,
    .lexres_tubelex_admission_candidate_sha256
  )) {
    return(.lexres_admission_result(
      status = "candidate_error",
      admission_gate_passed = FALSE,
      failure_reason = "candidate_hash_mismatch",
      diagnostics = .lexres_admission_diagnostics(
        expected_candidate_sha256 =
          .lexres_tubelex_admission_candidate_sha256,
        observed_candidate_sha256 = candidate_hash,
        observed_candidate_bytes = as.double(length(candidate_read$bytes))
      )
    ))
  }
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    return(.lexres_admission_result(
      status = "candidate_error",
      admission_gate_passed = FALSE,
      failure_reason = "json_decoder_unavailable",
      diagnostics = .lexres_admission_diagnostics(
        candidate_sha256 = candidate_hash
      )
    ))
  }
  candidate_text <- tryCatch(
    rawToChar(candidate_read$bytes),
    error = base::identity
  )
  candidate <- if (inherits(candidate_text, "error") ||
      !validUTF8(candidate_text)) {
    NULL
  } else {
    tryCatch(
      jsonlite::fromJSON(candidate_text, simplifyVector = FALSE),
      error = function(error) NULL
    )
  }
  if (is.null(candidate) ||
      !isTRUE(.lexres_admission_candidate_semantics(candidate))) {
    return(.lexres_admission_result(
      status = "candidate_error",
      admission_gate_passed = FALSE,
      failure_reason = "candidate_schema_mismatch",
      diagnostics = .lexres_admission_diagnostics(
        candidate_sha256 = candidate_hash,
        candidate_bytes = as.double(length(candidate_read$bytes))
      )
    ))
  }
  list(
    status = "candidate_ok",
    failure_reason = NA_character_,
    candidate_ref = .lexres_tubelex_admission_candidate_ref(),
    resource_ref = .lexres_resource_ref(.lexres_tubelex_expectation()),
    diagnostics = list(
      candidate_sha256 = candidate_hash,
      candidate_bytes = as.double(length(candidate_read$bytes)),
      fallback_attempted = FALSE,
      download_attempted = FALSE
    ),
    candidate = candidate
  )
}

.lexres_admission_failure <- function(
    failure_reason,
    diagnostics = list(),
    approval_ref = NULL,
    status = "approval_error") {
  .lexres_admission_result(
    status = status,
    admission_gate_passed = FALSE,
    failure_reason = failure_reason,
    approval_ref = approval_ref,
    diagnostics = do.call(
      .lexres_admission_diagnostics,
      diagnostics
    )
  )
}

.lexres_admission_value <- function(decoded, field) {
  unname(decoded$table[[field]][[1L]])
}

.lexres_valid_review_date <- function(value) {
  if (!grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", value)) return(FALSE)
  parsed <- suppressWarnings(as.Date(value, format = "%Y-%m-%d"))
  !is.na(parsed) && identical(format(parsed, "%Y-%m-%d"), value)
}

.lexres_valid_github_login <- function(value) {
  grepl(
    "^[A-Za-z0-9](?:[A-Za-z0-9-]{0,37}[A-Za-z0-9])?$|^[A-Za-z0-9]$",
    value,
    perl = TRUE
  ) && !grepl("--", value, fixed = TRUE)
}

.lexres_parse_admission_approval <- function(bytes) {
  decoded <- .lexres_decode_dcf(bytes)
  if (!isTRUE(decoded$ok) || !identical(decoded$row_count, 1L) ||
      !identical(names(decoded$table), .lexres_admission_approval_fields)) {
    return(list(ok = FALSE, failure_reason = "approval_schema_mismatch"))
  }
  values <- vapply(
    .lexres_admission_approval_fields,
    function(field) .lexres_admission_value(decoded, field),
    character(1L),
    USE.NAMES = TRUE
  )
  if (anyNA(values) || any(!nzchar(values)) ||
      any(grepl("[[:cntrl:]]", values))) {
    return(list(ok = FALSE, failure_reason = "approval_schema_mismatch"))
  }
  if (!identical(
    values[["Approval-Schema-ID"]],
    .lexres_admission_approval_schema_id
  ) || !identical(
    values[["Approval-Schema-Version"]],
    .lexres_admission_approval_schema_version
  ) || !grepl("^[a-z][a-z0-9._-]*$", values[["Approval-ID"]]) ||
      !grepl("^[0-9a-f]{64}$", values[["Candidate-SHA256"]]) ||
      !grepl("^[0-9a-f]{40}$", values[["Reviewed-Repository-Commit"]]) ||
      !.lexres_valid_github_login(values[["Reviewer-GitHub-Login"]]) ||
      !.lexres_valid_review_date(values[["Reviewed-On"]]) ||
      !(values[["Decision"]] %in% c("approved", "rejected")) ||
      !(values[["Independence-Attested"]] %in% c("true", "false")) ||
      !(values[["Not-Candidate-Author-Or-Builder"]] %in% c("true", "false")) ||
      !(values[["Redistribution-Terms"]] %in% c("approved", "not-approved")) ||
      !(values[["Notice-And-Attribution"]] %in% c("approved", "not-approved")) ||
      !(values[["Source-And-Artifact-Identity"]] %in% c("approved", "not-approved")) ||
      !(values[["Package-Distribution-Scope"]] %in% c("approved", "not-approved")) ||
      !identical(values[["Public-API-Scope"]], "not-reviewed") ||
      !grepl("^https://github[.]com/[^[:space:]]+$", values[["Evidence-URL"]]) ||
      !grepl("^[0-9a-f]{64}$", values[["Evidence-SHA256"]])) {
    return(list(ok = FALSE, failure_reason = "approval_schema_mismatch"))
  }
  locator_valid <- !inherits(tryCatch(
    .lexres_normalized_relative(
      values[["Evidence-Locator-ID"]],
      "Evidence-Locator-ID"
    ),
    error = base::identity
  ), "error")
  if (!locator_valid) {
    return(list(ok = FALSE, failure_reason = "approval_schema_mismatch"))
  }
  list(ok = TRUE, failure_reason = NA_character_, values = values)
}

.lexres_evaluate_tubelex_admission <- function(
    approval_path = NULL,
    evidence_path = NULL,
    repository_commit = NULL,
    reader = .lexres_read_raw_once) {
  candidate <- .lexres_load_tubelex_admission_candidate(reader = reader)
  if (!identical(candidate$status, "candidate_ok")) return(candidate)

  if (is.null(approval_path)) {
    return(.lexres_admission_failure(
      failure_reason = "approval_missing",
      status = "pending_independent_review",
      diagnostics = list(
        candidate_sha256 = candidate$diagnostics$candidate_sha256,
        approval_record_present = FALSE,
        release_approved_resource_count = 0
      )
    ))
  }
  approval_path <- .lexres_validate_local_path(approval_path, "approval_path")
  if (!is.function(reader)) {
    .lexres_stop("reader must be an internal or test-seam function.")
  }

  approval_read <- reader(approval_path, 32768)
  if (!isTRUE(approval_read$ok)) {
    return(.lexres_admission_failure(
      failure_reason = "approval_unavailable",
      diagnostics = list(
        approval_state = approval_read$observed_state
      )
    ))
  }
  approval_hash <- .lexres_sha256_bytes(approval_read$bytes)
  parsed <- .lexres_parse_admission_approval(approval_read$bytes)
  approval_ref <- list(
    approval_sha256 = approval_hash,
    approval_bytes = as.double(length(approval_read$bytes))
  )
  if (!isTRUE(parsed$ok)) {
    return(.lexres_admission_failure(
      failure_reason = parsed$failure_reason,
      approval_ref = approval_ref
    ))
  }
  values <- parsed$values
  repository_commit <- .lexres_scalar_string(
    repository_commit,
    "repository_commit"
  )
  if (!grepl("^[0-9a-f]{40}$", repository_commit)) {
    .lexres_stop("repository_commit must be one lowercase 40-hex commit SHA.")
  }
  approval_ref <- c(
    list(
      approval_id = values[["Approval-ID"]],
      decision = values[["Decision"]]
    ),
    approval_ref
  )
  if (!identical(
    values[["Candidate-ID"]],
    .lexres_tubelex_admission_candidate_id
  ) || !identical(
    values[["Candidate-SHA256"]],
    .lexres_tubelex_admission_candidate_sha256
  )) {
    return(.lexres_admission_failure(
      failure_reason = "approval_candidate_mismatch",
      approval_ref = approval_ref
    ))
  }
  if (!identical(
    values[["Reviewed-Repository-Commit"]],
    repository_commit
  )) {
    return(.lexres_admission_failure(
      failure_reason = "repository_commit_mismatch",
      approval_ref = approval_ref,
      diagnostics = list(
        expected_repository_commit = repository_commit,
        reviewed_repository_commit =
          values[["Reviewed-Repository-Commit"]]
      )
    ))
  }
  disallowed <- unlist(
    candidate$candidate$approval_policy$disallowed_approver_logins,
    use.names = FALSE
  )
  if (tolower(values[["Reviewer-GitHub-Login"]]) %in% tolower(disallowed) ||
      !identical(values[["Independence-Attested"]], "true") ||
      !identical(
        values[["Not-Candidate-Author-Or-Builder"]],
        "true"
      )) {
    return(.lexres_admission_failure(
      failure_reason = "reviewer_not_independent",
      approval_ref = approval_ref,
      diagnostics = list(
        reviewer_github_login = values[["Reviewer-GitHub-Login"]],
        independence_attested =
          identical(values[["Independence-Attested"]], "true"),
        not_candidate_author_or_builder = identical(
          values[["Not-Candidate-Author-Or-Builder"]],
          "true"
        )
      )
    ))
  }

  if (is.null(evidence_path)) {
    return(.lexres_admission_failure(
      failure_reason = "evidence_unavailable",
      approval_ref = approval_ref,
      diagnostics = list(approval_record_present = TRUE)
    ))
  }
  evidence_path <- .lexres_validate_local_path(evidence_path, "evidence_path")
  evidence_read <- reader(evidence_path, 5242880)
  if (!isTRUE(evidence_read$ok)) {
    return(.lexres_admission_failure(
      failure_reason = "evidence_unavailable",
      approval_ref = approval_ref,
      diagnostics = list(evidence_state = evidence_read$observed_state)
    ))
  }
  evidence_hash <- .lexres_sha256_bytes(evidence_read$bytes)
  if (!identical(evidence_hash, values[["Evidence-SHA256"]])) {
    return(.lexres_admission_failure(
      failure_reason = "evidence_hash_mismatch",
      approval_ref = approval_ref,
      diagnostics = list(
        expected_evidence_sha256 = values[["Evidence-SHA256"]],
        observed_evidence_sha256 = evidence_hash,
        observed_evidence_bytes = as.double(length(evidence_read$bytes))
      )
    ))
  }
  if (identical(values[["Decision"]], "rejected")) {
    return(.lexres_admission_failure(
      failure_reason = "approval_rejected",
      status = "independent_review_rejected",
      approval_ref = approval_ref,
      diagnostics = list(
        reviewer_github_login = values[["Reviewer-GitHub-Login"]],
        reviewed_on = values[["Reviewed-On"]],
        evidence_sha256 = evidence_hash,
        evidence_bytes = as.double(length(evidence_read$bytes))
      )
    ))
  }
  approved_scope <- c(
    "Redistribution-Terms" = "approved",
    "Notice-And-Attribution" = "approved",
    "Source-And-Artifact-Identity" = "approved",
    "Package-Distribution-Scope" = "approved",
    "Public-API-Scope" = "not-reviewed"
  )
  if (!identical(unname(values[names(approved_scope)]), unname(approved_scope))) {
    return(.lexres_admission_failure(
      failure_reason = "approval_scope_incomplete",
      approval_ref = approval_ref
    ))
  }

  .lexres_admission_result(
    status = "approval_record_valid",
    admission_gate_passed = TRUE,
    failure_reason = NA_character_,
    approval_ref = approval_ref,
    diagnostics = .lexres_admission_diagnostics(
      candidate_sha256 = candidate$diagnostics$candidate_sha256,
      reviewed_repository_commit = repository_commit,
      reviewer_name = values[["Reviewer-Name"]],
      reviewer_affiliation = values[["Reviewer-Affiliation"]],
      reviewer_github_login = values[["Reviewer-GitHub-Login"]],
      reviewed_on = values[["Reviewed-On"]],
      evidence_url = values[["Evidence-URL"]],
      evidence_locator_id = values[["Evidence-Locator-ID"]],
      evidence_sha256 = evidence_hash,
      evidence_bytes = as.double(length(evidence_read$bytes)),
      independence_attestation_recorded = TRUE,
      approval_authenticity_scope = "record-and-evidence-identity-only"
    )
  )
}
