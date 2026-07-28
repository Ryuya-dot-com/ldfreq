admission_candidate_function <- getFromNamespace(
  ".lexres_load_tubelex_admission_candidate",
  "ldfreq"
)
admission_evaluate_function <- getFromNamespace(
  ".lexres_evaluate_tubelex_admission",
  "ldfreq"
)
admission_sha256_function <- getFromNamespace(".lexres_sha256_bytes", "ldfreq")
admission_candidate_id <- getFromNamespace(
  ".lexres_tubelex_admission_candidate_id",
  "ldfreq"
)
admission_candidate_sha256 <- getFromNamespace(
  ".lexres_tubelex_admission_candidate_sha256",
  "ldfreq"
)
admission_fields <- getFromNamespace(
  ".lexres_admission_approval_fields",
  "ldfreq"
)

admission_repository_commit <- paste(rep.int("a", 40L), collapse = "")
admission_evidence_bytes <- charToRaw(
  "preserved independent review evidence\n"
)

write_test_bytes <- function(bytes, stem, extension) {
  path <- tempfile(stem, fileext = extension)
  connection <- file(path, open = "wb")
  on.exit(close(connection), add = TRUE)
  writeBin(bytes, connection)
  path
}

admission_values <- function(overrides = list()) {
  values <- c(
    "Approval-Schema-ID" = "ldfreq-resource-release-approval",
    "Approval-Schema-Version" = "0.1.0",
    "Approval-ID" = "independent-tubelex-review-v1",
    "Candidate-ID" = admission_candidate_id,
    "Candidate-SHA256" = admission_candidate_sha256,
    "Reviewed-Repository-Commit" = admission_repository_commit,
    "Reviewer-Name" = "Independent Reviewer",
    "Reviewer-Affiliation" = "Independent Language Resources Group",
    "Reviewer-GitHub-Login" = "independent-reviewer",
    "Reviewed-On" = "2026-07-29",
    "Decision" = "approved",
    "Independence-Attested" = "true",
    "Not-Candidate-Author-Or-Builder" = "true",
    "Redistribution-Terms" = "approved",
    "Notice-And-Attribution" = "approved",
    "Source-And-Artifact-Identity" = "approved",
    "Package-Distribution-Scope" = "approved",
    "Public-API-Scope" = "not-reviewed",
    "Evidence-URL" =
      "https://github.com/example/review-evidence/pull/1#pullrequestreview-1",
    "Evidence-Locator-ID" = "reviews/tubelex-independent-review.txt",
    "Evidence-SHA256" = admission_sha256_function(admission_evidence_bytes)
  )
  for (name in names(overrides)) values[[name]] <- overrides[[name]]
  values
}

write_approval <- function(values = admission_values()) {
  stopifnot(identical(names(values), admission_fields))
  text <- paste0(
    paste0(names(values), ": ", unname(values), collapse = "\n"),
    "\n"
  )
  write_test_bytes(charToRaw(text), "tubelex-approval-", ".dcf")
}

write_evidence <- function(bytes = admission_evidence_bytes) {
  write_test_bytes(bytes, "tubelex-review-evidence-", ".txt")
}

evaluate_approval <- function(
    values = admission_values(),
    evidence_bytes = admission_evidence_bytes,
    repository_commit = admission_repository_commit) {
  approval_path <- write_approval(values)
  evidence_path <- write_evidence(evidence_bytes)
  on.exit(unlink(c(approval_path, evidence_path)), add = TRUE)
  admission_evaluate_function(
    approval_path = approval_path,
    evidence_path = evidence_path,
    repository_commit = repository_commit
  )
}

test_that("the installed candidate is byte-pinned and remains unapproved", {
  candidate <- admission_candidate_function()

  expect_identical(candidate$status, "candidate_ok")
  expect_identical(candidate$failure_reason, NA_character_)
  expect_identical(candidate$candidate_ref$candidate_id, admission_candidate_id)
  expect_identical(
    candidate$candidate_ref$candidate_sha256,
    admission_candidate_sha256
  )
  expect_identical(
    candidate$candidate$distribution_scope$release_approved,
    FALSE
  )
  expect_identical(candidate$candidate$distribution_scope$public_api, FALSE)
  expect_identical(
    candidate$candidate$approval_policy$approval_record_bundled,
    FALSE
  )
  expect_identical(
    unlist(
      candidate$candidate$approval_record_contract$fields,
      use.names = FALSE
    ),
    admission_fields
  )
})

test_that("missing approval remains a deterministic fail-closed state", {
  first <- admission_evaluate_function()
  second <- admission_evaluate_function()
  unavailable <- admission_evaluate_function(
    approval_path = tempfile("missing-approval-record-")
  )

  expect_identical(first, second)
  expect_identical(
    names(first),
    c(
      "status", "admission_gate_passed", "package_release_ready",
      "failure_reason", "admission_ref", "candidate_ref", "resource_ref",
      "approval_ref", "remaining_gates", "diagnostics"
    )
  )
  expect_identical(first$status, "pending_independent_review")
  expect_identical(first$admission_gate_passed, FALSE)
  expect_identical(first$package_release_ready, FALSE)
  expect_identical(first$failure_reason, "approval_missing")
  expect_null(first$approval_ref)
  expect_identical(first$diagnostics$approval_record_present, FALSE)
  expect_identical(first$diagnostics$release_approved_resource_count, 0)
  expect_identical(first$diagnostics$fallback_attempted, FALSE)
  expect_identical(first$diagnostics$download_attempted, FALSE)
  expect_identical(unavailable$status, "approval_error")
  expect_identical(unavailable$failure_reason, "approval_unavailable")
  expect_identical(unavailable$diagnostics$approval_state, "missing")
})

test_that("a complete independent record passes only the admission gate", {
  result <- evaluate_approval()

  expect_identical(result$status, "approval_record_valid")
  expect_identical(result$admission_gate_passed, TRUE)
  expect_identical(result$package_release_ready, FALSE)
  expect_identical(result$failure_reason, NA_character_)
  expect_identical(
    result$approval_ref$approval_id,
    "independent-tubelex-review-v1"
  )
  expect_identical(result$approval_ref$decision, "approved")
  expect_identical(
    result$diagnostics$reviewed_repository_commit,
    admission_repository_commit
  )
  expect_identical(
    result$diagnostics$reviewer_github_login,
    "independent-reviewer"
  )
  expect_identical(result$diagnostics$independence_attestation_recorded, TRUE)
  expect_identical(result$diagnostics$approval_authenticity_proven, FALSE)
  expect_identical(result$diagnostics$cryptographic_signature_verified, FALSE)
  expect_identical(
    result$diagnostics$approval_authenticity_scope,
    "record-and-evidence-identity-only"
  )
  expect_identical(
    result$remaining_gates,
    c(
      "public lookup and result contract",
      "final release-candidate source, installed, and binary inventory audit"
    )
  )
})

test_that("candidate identity and repository commit cannot drift", {
  candidate_mismatch <- evaluate_approval(admission_values(list(
    "Candidate-SHA256" = paste(rep.int("0", 64L), collapse = "")
  )))
  commit_mismatch <- evaluate_approval(
    repository_commit = paste(rep.int("b", 40L), collapse = "")
  )

  expect_identical(
    candidate_mismatch$failure_reason,
    "approval_candidate_mismatch"
  )
  expect_identical(candidate_mismatch$admission_gate_passed, FALSE)
  expect_identical(commit_mismatch$failure_reason, "repository_commit_mismatch")
  expect_identical(commit_mismatch$admission_gate_passed, FALSE)
})

test_that("self-approval and absent independence attestations are rejected", {
  self_approval <- evaluate_approval(admission_values(list(
    "Reviewer-GitHub-Login" = "ryuya-DOT-com"
  )))
  no_attestation <- evaluate_approval(admission_values(list(
    "Independence-Attested" = "false"
  )))
  builder <- evaluate_approval(admission_values(list(
    "Not-Candidate-Author-Or-Builder" = "false"
  )))

  for (result in list(self_approval, no_attestation, builder)) {
    expect_identical(result$status, "approval_error")
    expect_identical(result$failure_reason, "reviewer_not_independent")
    expect_identical(result$admission_gate_passed, FALSE)
    expect_identical(result$package_release_ready, FALSE)
  }
})

test_that("review evidence is exact and never searched by locator", {
  tampered <- evaluate_approval(
    evidence_bytes = charToRaw("changed evidence\n")
  )
  approval_path <- write_approval()
  on.exit(unlink(approval_path), add = TRUE)
  missing_evidence <- admission_evaluate_function(
    approval_path = approval_path,
    evidence_path = tempfile("missing-review-evidence-"),
    repository_commit = admission_repository_commit
  )

  expect_identical(tampered$failure_reason, "evidence_hash_mismatch")
  expect_identical(tampered$admission_gate_passed, FALSE)
  expect_identical(missing_evidence$failure_reason, "evidence_unavailable")
  expect_identical(missing_evidence$diagnostics$evidence_state, "missing")
  expect_identical(missing_evidence$diagnostics$fallback_attempted, FALSE)
  expect_identical(missing_evidence$diagnostics$download_attempted, FALSE)
})

test_that("incomplete scope and reviewer rejection remain blocking", {
  incomplete <- evaluate_approval(admission_values(list(
    "Notice-And-Attribution" = "not-approved"
  )))
  rejected <- evaluate_approval(admission_values(list(
    "Decision" = "rejected",
    "Redistribution-Terms" = "not-approved"
  )))

  expect_identical(incomplete$failure_reason, "approval_scope_incomplete")
  expect_identical(incomplete$admission_gate_passed, FALSE)
  expect_identical(rejected$status, "independent_review_rejected")
  expect_identical(rejected$failure_reason, "approval_rejected")
  expect_identical(rejected$admission_gate_passed, FALSE)
})

test_that("malformed approval records fail before evidence interpretation", {
  values <- admission_values()
  malformed_text <- paste0(
    paste0(names(values), ": ", unname(values), collapse = "\n"),
    "\nDecision: approved\n"
  )
  approval_path <- write_test_bytes(
    charToRaw(malformed_text),
    "malformed-tubelex-approval-",
    ".dcf"
  )
  evidence_path <- write_evidence()
  on.exit(unlink(c(approval_path, evidence_path)), add = TRUE)

  result <- admission_evaluate_function(
    approval_path = approval_path,
    evidence_path = evidence_path,
    repository_commit = admission_repository_commit
  )
  expect_identical(result$failure_reason, "approval_schema_mismatch")
  expect_identical(result$admission_gate_passed, FALSE)
})

test_that("the admission path has no network, shell, or fallback calls", {
  functions <- list(
    admission_candidate_function,
    admission_evaluate_function,
    getFromNamespace(".lexres_parse_admission_approval", "ldfreq")
  )
  calls <- unique(unlist(lapply(
    functions,
    function(fun) all.names(body(fun), functions = TRUE)
  )))
  expect_false(any(c(
    "download.file", "url", "curlGetHeaders", "socketConnection",
    "system", "system2", "shell", "pipe", "list.files"
  ) %in% calls))
  expect_false(any(grepl("admission", getNamespaceExports("ldfreq"))))
})
