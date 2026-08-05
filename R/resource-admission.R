# Internal, non-exported release-admission evidence gate.
#
# The gate validates one byte-pinned TUBELEX candidate and the maintainer
# decision embedded in that candidate. CRAN makes the package maintainer
# accountable for third-party license compliance; independent review is
# permitted but is not a release prerequisite.

.lexres_admission_contract_id <- "ldfreq-resource-release-admission"
.lexres_admission_contract_version <- "0.2.0"
.lexres_tubelex_admission_candidate_id <-
  "tubelex-en-treebank-slim-7cb5fb36-public-profile-admission-v3"
.lexres_tubelex_admission_candidate_sha256 <-
  "254f8abc49fdf12c2d6abb91c2cca2210766444a3482eb0390d5c51a439a2acb"
.lexres_admission_remaining_gates <- c(
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
    candidate_state = "maintainer-approved"
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

.lexres_admission_diagnostics <- function(...) {
  c(
    list(
      fallback_attempted = FALSE,
      download_attempted = FALSE
    ),
    list(...)
  )
}

.lexres_admission_result <- function(
    status,
    admission_gate_passed,
    failure_reason,
    decision_ref = NULL,
    diagnostics = list()) {
  list(
    status = status,
    admission_gate_passed = admission_gate_passed,
    package_release_ready = FALSE,
    failure_reason = failure_reason,
    admission_ref = .lexres_admission_ref(),
    candidate_ref = .lexres_tubelex_admission_candidate_ref(),
    resource_ref = .lexres_resource_ref(.lexres_tubelex_expectation()),
    decision_ref = decision_ref,
    remaining_gates = .lexres_admission_remaining_gates,
    diagnostics = diagnostics
  )
}

.lexres_admission_candidate_semantics <- function(record) {
  if (!is.list(record) || is.object(record)) return(FALSE)
  expected_top_names <- c(
    "$schema", "schema_version", "candidate_id", "candidate_state",
    "resource", "distribution_scope", "contract_refs", "admission_policy",
    "maintainer_decision", "remaining_gates_after_resource_approval"
  )
  if (!identical(names(record), expected_top_names)) return(FALSE)

  resource <- record$resource
  distribution <- record$distribution_scope
  policy <- record$admission_policy
  decision <- record$maintainer_decision
  basis <- decision$legal_basis
  controls <- decision$risk_controls
  scopes <- decision$approved_scopes

  identical(record$`$schema`, "tubelex-release-admission-candidate.schema.json") &&
    identical(record$schema_version, "0.3.0") &&
    identical(record$candidate_id, .lexres_tubelex_admission_candidate_id) &&
    identical(record$candidate_state, "maintainer-approved") &&
    identical(resource$resource_id, "tubelex-en-treebank-slim") &&
    identical(resource$resource_version, "7cb5fb36-slim-v1") &&
    identical(
      resource$upstream_commit,
      "7cb5fb36add76b83a266d1967536e1a1d3faa513"
    ) &&
    identical(resource$license_spdx, "BSD-3-Clause") &&
    identical(resource$notice_path, "licenses/tubelex/NOTICE.md") &&
    identical(distribution$package_component_state, "release-candidate") &&
    identical(distribution$raw_source_bundled, FALSE) &&
    identical(distribution$raw_subtitles_or_identifiers_included, FALSE) &&
    identical(distribution$runtime_network_access, FALSE) &&
    identical(distribution$implicit_download_or_fallback, FALSE) &&
    identical(distribution$public_api, TRUE) &&
    identical(distribution$release_approved, TRUE) &&
    identical(policy$decision_authority, "package-maintainer") &&
    identical(policy$independent_reviewer_required, FALSE) &&
    identical(policy$optional_independent_review_permitted, TRUE) &&
    identical(policy$automated_identity_checks_required, TRUE) &&
    identical(policy$final_inventory_audit_required, TRUE) &&
    identical(
      decision$decision_id,
      "tubelex-maintainer-redistribution-decision-2026-08-06"
    ) &&
    identical(decision$decision, "approved") &&
    identical(decision$decided_on, "2026-08-06") &&
    identical(decision$decided_by$name, "Komuro Ryuya") &&
    identical(decision$decided_by$github_login, "Ryuya-dot-com") &&
    identical(decision$decided_by$role, "package-maintainer") &&
    identical(basis$license_spdx, "BSD-3-Clause") &&
    identical(
      basis$upstream_repository,
      "https://github.com/naist-nlp/tubelex"
    ) &&
    identical(
      basis$cran_policy_url,
      "https://cran.r-project.org/web/packages/policies.html"
    ) &&
    is.character(basis$interpretation) &&
    length(basis$interpretation) == 1L &&
    !is.na(basis$interpretation) &&
    nzchar(basis$interpretation) &&
    identical(unname(unlist(scopes, use.names = FALSE)), rep(TRUE, 5L)) &&
    identical(controls$raw_subtitles_or_identifiers_included, FALSE) &&
    identical(controls$upstream_commit_and_source_hash_pinned, TRUE) &&
    identical(controls$bsd_notice_and_disclaimer_installed, TRUE) &&
    identical(controls$transformation_disclosed, TRUE) &&
    identical(controls$runtime_download_or_fallback, FALSE) &&
    identical(controls$independent_legal_opinion_obtained, FALSE) &&
    identical(
      unlist(
        record$remaining_gates_after_resource_approval,
        use.names = FALSE
      ),
      .lexres_admission_remaining_gates
    )
}

.lexres_admission_failure <- function(
    failure_reason,
    diagnostics = list(),
    status = "candidate_error") {
  .lexres_admission_result(
    status = status,
    admission_gate_passed = FALSE,
    failure_reason = failure_reason,
    diagnostics = do.call(.lexres_admission_diagnostics, diagnostics)
  )
}

.lexres_load_tubelex_admission_candidate <- function(
    reader = .lexres_read_raw_once) {
  paths <- .lexres_tubelex_admission_paths()
  if (!is.function(reader)) {
    .lexres_stop("reader must be an internal or test-seam function.")
  }
  if (!nzchar(paths$candidate_path) || !nzchar(paths$candidate_schema_path)) {
    return(.lexres_admission_failure(
      failure_reason = "candidate_unavailable",
      diagnostics = list(candidate_state = "missing_installed_contract")
    ))
  }

  candidate_read <- reader(paths$candidate_path, 65536)
  if (!isTRUE(candidate_read$ok)) {
    return(.lexres_admission_failure(
      failure_reason = "candidate_unavailable",
      diagnostics = list(candidate_state = candidate_read$observed_state)
    ))
  }
  candidate_hash <- .lexres_sha256_bytes(candidate_read$bytes)
  if (!identical(
    candidate_hash,
    .lexres_tubelex_admission_candidate_sha256
  )) {
    return(.lexres_admission_failure(
      failure_reason = "candidate_hash_mismatch",
      diagnostics = list(
        expected_candidate_sha256 =
          .lexres_tubelex_admission_candidate_sha256,
        observed_candidate_sha256 = candidate_hash,
        observed_candidate_bytes = as.double(length(candidate_read$bytes))
      )
    ))
  }
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    return(.lexres_admission_failure(
      failure_reason = "json_decoder_unavailable",
      diagnostics = list(candidate_sha256 = candidate_hash)
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
    return(.lexres_admission_failure(
      failure_reason = "candidate_schema_mismatch",
      diagnostics = list(
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
    diagnostics = .lexres_admission_diagnostics(
      candidate_sha256 = candidate_hash,
      candidate_bytes = as.double(length(candidate_read$bytes))
    ),
    candidate = candidate
  )
}

.lexres_evaluate_tubelex_admission <- function(
    reader = .lexres_read_raw_once) {
  candidate <- .lexres_load_tubelex_admission_candidate(reader = reader)
  if (!identical(candidate$status, "candidate_ok")) return(candidate)

  decision <- candidate$candidate$maintainer_decision
  basis <- decision$legal_basis
  controls <- decision$risk_controls
  .lexres_admission_result(
    status = "maintainer_decision_valid",
    admission_gate_passed = TRUE,
    failure_reason = NA_character_,
    decision_ref = list(
      decision_id = decision$decision_id,
      decision = decision$decision,
      decided_on = decision$decided_on,
      authority = decision$decided_by$role,
      github_login = decision$decided_by$github_login
    ),
    diagnostics = .lexres_admission_diagnostics(
      candidate_sha256 = candidate$diagnostics$candidate_sha256,
      release_approved_resource_count = 1,
      license_spdx = basis$license_spdx,
      upstream_repository = basis$upstream_repository,
      pinned_license_url = basis$pinned_license_url,
      cran_policy_url = basis$cran_policy_url,
      independent_reviewer_required = FALSE,
      optional_independent_review_permitted = TRUE,
      independent_legal_opinion_obtained =
        controls$independent_legal_opinion_obtained,
      decision_scope = "maintainer-license-and-distribution-judgment"
    )
  )
}
