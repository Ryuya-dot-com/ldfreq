#!/usr/bin/env Rscript

arguments <- commandArgs(trailingOnly = TRUE)
if (length(arguments) > 1L) {
  stop("Usage: validate-tubelex-admission.R [/path/to/package]", call. = FALSE)
}
package_root <- normalizePath(
  if (length(arguments)) arguments[[1L]] else ".",
  mustWork = TRUE
)
if (!requireNamespace("jsonlite", quietly = TRUE)) {
  stop("The admission command requires jsonlite.", call. = FALSE)
}

assertions <- 0L
check <- function(condition, message) {
  assertions <<- assertions + 1L
  if (!isTRUE(condition)) stop(message, call. = FALSE)
}
read_record <- function(...) {
  path <- file.path(package_root, ...)
  check(file.exists(path), sprintf("Required record is missing: %s", path))
  check(isTRUE(file_test("-f", path)), sprintf("Record is not regular: %s", path))
  check(!nzchar(Sys.readlink(path)), sprintf("Record must not be a symlink: %s", path))
  jsonlite::read_json(path, simplifyVector = FALSE)
}

candidate <- read_record(
  "experiments", "resource-admission",
  "tubelex-release-admission-candidate.json"
)
candidate_schema <- read_record(
  "experiments", "resource-admission",
  "tubelex-release-admission-candidate.schema.json"
)
release_inventory <- read_record(
  "experiments", "resource-admission",
  "ldfreq-release-resource-inventory.json"
)
release_inventory_schema <- read_record(
  "experiments", "resource-admission",
  "ldfreq-release-resource-inventory.schema.json"
)
installed_manifest <- read_record(
  "inst", "spec", "ldfreq-installed-resource-manifest.json"
)
installed_manifest_schema <- read_record(
  "inst", "spec", "ldfreq-installed-resource-manifest.schema.json"
)

check(
  identical(candidate$schema_version, "0.4.0") &&
    identical(candidate$record_scope, "repository-release-evidence") &&
    identical(candidate$candidate_state, "maintainer-approved") &&
    identical(
      candidate_schema$title,
      "ldfreq repository-only TUBELEX release-admission record"
    ) && identical(candidate_schema$additionalProperties, FALSE),
  "The repository admission-record contract changed."
)
resource <- candidate$resource
distribution <- candidate$distribution_scope
policy <- candidate$admission_policy
decision <- candidate$maintainer_decision
basis <- decision$legal_basis
controls <- decision$risk_controls
check(
  identical(resource$resource_id, "tubelex-en-treebank-slim") &&
    identical(resource$resource_version, "7cb5fb36-slim-v1") &&
    identical(resource$license_spdx, "BSD-3-Clause") &&
    identical(distribution$package_component_state, "release-candidate") &&
    identical(distribution$raw_source_bundled, FALSE) &&
    identical(distribution$raw_subtitles_or_identifiers_included, FALSE) &&
    identical(distribution$runtime_network_access, FALSE) &&
    identical(distribution$implicit_download_or_fallback, FALSE) &&
    identical(distribution$public_api, TRUE) &&
    identical(distribution$release_approved, TRUE),
  "The approved TUBELEX distribution boundary changed."
)
check(
  identical(policy$decision_authority, "package-maintainer") &&
    identical(policy$independent_reviewer_required, FALSE) &&
    identical(policy$optional_independent_review_permitted, TRUE) &&
    identical(policy$automated_identity_checks_required, TRUE) &&
    identical(policy$final_inventory_audit_required, TRUE),
  "The repository admission policy changed."
)
check(
  identical(decision$decision_id, "tubelex-maintainer-redistribution-decision-2026-08-06") &&
    identical(decision$decision, "approved") &&
    identical(decision$decided_on, "2026-08-06") &&
    identical(decision$decided_by$github_login, "Ryuya-dot-com") &&
    identical(decision$decided_by$role, "package-maintainer") &&
    identical(basis$license_spdx, "BSD-3-Clause") &&
    identical(basis$upstream_repository, "https://github.com/naist-nlp/tubelex") &&
    is.character(basis$interpretation) && length(basis$interpretation) == 1L &&
    !is.na(basis$interpretation) && nzchar(basis$interpretation),
  "The maintainer decision or legal basis changed."
)
check(
  identical(unname(unlist(decision$approved_scopes, use.names = FALSE)), rep(TRUE, 5L)) &&
    identical(controls$raw_subtitles_or_identifiers_included, FALSE) &&
    identical(controls$upstream_commit_and_source_hash_pinned, TRUE) &&
    identical(controls$bsd_notice_and_disclaimer_installed, TRUE) &&
    identical(controls$transformation_disclosed, TRUE) &&
    identical(controls$runtime_download_or_fallback, FALSE) &&
    identical(controls$independent_legal_opinion_obtained, FALSE),
  "The approved scope or risk controls changed."
)
remaining_gates <- unname(unlist(
  candidate$remaining_gates_after_resource_approval,
  use.names = FALSE
))
check(
  identical(
    remaining_gates,
    "final release-candidate source, installed, and binary inventory audit"
  ),
  "The repository admission record changed its remaining gate."
)

check(
  identical(release_inventory$schema_version, "0.2.0") &&
    identical(release_inventory$record_scope, "repository-release-evidence") &&
    identical(
      release_inventory_schema$title,
      "ldfreq repository-only release resource inventory"
    ) && identical(release_inventory_schema$additionalProperties, FALSE),
  "The repository release-inventory contract changed."
)
check(
  identical(release_inventory$package_scope, "public-api-resource-release-candidate") &&
    identical(release_inventory$policy$release_requires_independent_approval, FALSE) &&
    identical(release_inventory$policy$release_requires_maintainer_license_decision, TRUE) &&
    identical(release_inventory$policy$uncertainty_default, "exclude") &&
    identical(release_inventory$policy$runtime_network_access, FALSE) &&
    identical(release_inventory$policy$implicit_download_or_fallback, FALSE) &&
    identical(as.numeric(release_inventory$release_approved_resource_count),
      as.numeric(length(release_inventory$included_resources))),
  "The repository release inventory changed its policy or resource count."
)
excluded_ids <- vapply(
  release_inventory$not_included,
  function(record) record$resource_id,
  character(1L)
)
check(
  identical(
    excluded_ids,
    c(
      "ngsl-1.2", "oewn-2025", "antbnc-lemma-list",
      "ngsl-31k-workbook", "coca", "ellipse-corpus",
      "python-resource-derived-golden-outputs"
    )
  ),
  "The repository release inventory changed its excluded-resource record."
)

check(
  identical(installed_manifest$schema_version, "1.2.0") &&
    identical(installed_manifest$package_scope, "installed-lexical-resources") &&
    identical(installed_manifest$runtime_policy$network_access, FALSE) &&
    identical(installed_manifest$runtime_policy$implicit_download_or_fallback, FALSE) &&
    identical(installed_manifest_schema$title, "ldfreq installed resource manifest") &&
    identical(installed_manifest_schema$additionalProperties, FALSE),
  "The installed resource-manifest contract changed."
)
installed_ids <- vapply(installed_manifest$resources, `[[`, character(1L), "resource_id")
release_ids <- vapply(release_inventory$included_resources, `[[`, character(1L), "resource_id")
expected_ids <- c("tubelex-en-treebank-slim", "new-jacet8000", "morpholex-en",
  "bnccoca-level6", "morphynet-en-example")
check(!anyDuplicated(installed_ids) && !anyDuplicated(release_ids) &&
  setequal(installed_ids, expected_ids) && setequal(release_ids, installed_ids),
  "Installed and admitted resource identities are incomplete or duplicated.")
member_identity <- function(records) lapply(records, function(record) {
  list(path = record$path, bytes = record$bytes, sha256 = record$sha256)
})
shared_fields <- c("resource_id", "resource_version", "runtime_state", "public_api",
  "license_spdx", "license_name", "source_commit", "source_url", "source_sha256",
  "raw_source_bundled", "raw_subtitles_or_identifiers_included", "manifest_sha256",
  "artifact_sha256", "content_sha256", "content_scope")
for (id in installed_ids) {
  installed_resource <- installed_manifest$resources[[match(id, installed_ids)]]
  admitted_resource <- release_inventory$included_resources[[match(id, release_ids)]]
  check(identical(installed_resource$distribution, "bundled") &&
    identical(admitted_resource$release_approved, TRUE) &&
    identical(unname(installed_resource[shared_fields]), unname(admitted_resource[shared_fields])) &&
    identical(member_identity(installed_resource$package_members),
      member_identity(admitted_resource$package_members)),
    sprintf("Installed and admitted resource records disagree: %s", id))
}
installed <- installed_manifest$resources[[match(resource$resource_id, installed_ids)]]
release_resource <- release_inventory$included_resources[[match(resource$resource_id, release_ids)]]
identity_fields <- c(
  "resource_id", "resource_version", "license_spdx", "source_commit",
  "source_sha256", "raw_source_bundled",
  "raw_subtitles_or_identifiers_included", "manifest_sha256",
  "artifact_sha256", "content_sha256"
)
candidate_identity <- list(
  resource_id = resource$resource_id,
  resource_version = resource$resource_version,
  license_spdx = resource$license_spdx,
  source_commit = resource$upstream_commit,
  source_sha256 = resource$upstream_source_sha256,
  raw_source_bundled = distribution$raw_source_bundled,
  raw_subtitles_or_identifiers_included =
    distribution$raw_subtitles_or_identifiers_included,
  manifest_sha256 = resource$manifest_sha256,
  artifact_sha256 = resource$artifact_sha256,
  content_sha256 = resource$content_sha256
)
check(
  identical(unname(installed[identity_fields]), unname(candidate_identity)) &&
    identical(unname(installed[identity_fields]), unname(release_resource[identity_fields])) &&
    identical(
      member_identity(installed$package_members),
      member_identity(release_resource$package_members)
    ) &&
    identical(installed$distribution, "bundled") &&
    identical(installed$runtime_state, "public") &&
    identical(installed$public_api, TRUE),
  "Repository admission evidence and the installed manifest disagree."
)
check(
  !file.exists(file.path(
    package_root, "inst", "spec", "tubelex-release-admission-candidate.json"
  )) && !file.exists(file.path(
    package_root, "inst", "spec", "tubelex-release-admission-candidate.schema.json"
  )),
  "Repository-only admission records leaked into inst/spec."
)

result <- list(
  status = "maintainer_decision_valid",
  record_scope = "repository-release-evidence",
  admission_gate_passed = TRUE,
  installed_manifest_consistent = TRUE,
  installed_resource_count = length(installed_ids),
  decision_id = decision$decision_id,
  remaining_gates = remaining_gates,
  excluded_resource_count = length(excluded_ids),
  assertions = assertions
)
cat(jsonlite::toJSON(result, auto_unbox = TRUE, pretty = TRUE, null = "null"))
cat("\n")
