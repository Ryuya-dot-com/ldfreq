admission_candidate_function <- getFromNamespace(
  ".lexres_load_tubelex_admission_candidate",
  "ldfreq"
)
admission_evaluate_function <- getFromNamespace(
  ".lexres_evaluate_tubelex_admission",
  "ldfreq"
)
admission_semantics_function <- getFromNamespace(
  ".lexres_admission_candidate_semantics",
  "ldfreq"
)
admission_candidate_id <- getFromNamespace(
  ".lexres_tubelex_admission_candidate_id",
  "ldfreq"
)
admission_candidate_sha256 <- getFromNamespace(
  ".lexres_tubelex_admission_candidate_sha256",
  "ldfreq"
)

test_that("the installed candidate pins a maintainer-approved decision", {
  candidate <- admission_candidate_function()

  expect_identical(candidate$status, "candidate_ok")
  expect_identical(candidate$failure_reason, NA_character_)
  expect_identical(candidate$candidate_ref$candidate_id, admission_candidate_id)
  expect_identical(
    candidate$candidate_ref$candidate_sha256,
    admission_candidate_sha256
  )
  expect_identical(candidate$candidate_ref$candidate_state, "maintainer-approved")
  expect_identical(
    candidate$candidate$distribution_scope$release_approved,
    TRUE
  )
  expect_identical(
    candidate$candidate$admission_policy$independent_reviewer_required,
    FALSE
  )
  expect_identical(
    candidate$candidate$admission_policy$optional_independent_review_permitted,
    TRUE
  )
  expect_identical(
    candidate$candidate$maintainer_decision$decided_by$github_login,
    "Ryuya-dot-com"
  )
  expect_identical(
    candidate$candidate$maintainer_decision$legal_basis$license_spdx,
    "BSD-3-Clause"
  )
})

test_that("the maintainer decision passes only the resource admission gate", {
  first <- admission_evaluate_function()
  second <- admission_evaluate_function()

  expect_identical(first, second)
  expect_identical(
    names(first),
    c(
      "status", "admission_gate_passed", "package_release_ready",
      "failure_reason", "admission_ref", "candidate_ref", "resource_ref",
      "decision_ref", "remaining_gates", "diagnostics"
    )
  )
  expect_identical(first$status, "maintainer_decision_valid")
  expect_identical(first$admission_gate_passed, TRUE)
  expect_identical(first$package_release_ready, FALSE)
  expect_identical(first$failure_reason, NA_character_)
  expect_identical(
    first$decision_ref$decision_id,
    "tubelex-maintainer-redistribution-decision-2026-08-06"
  )
  expect_identical(first$decision_ref$authority, "package-maintainer")
  expect_identical(first$diagnostics$release_approved_resource_count, 1)
  expect_identical(first$diagnostics$independent_reviewer_required, FALSE)
  expect_identical(
    first$diagnostics$optional_independent_review_permitted,
    TRUE
  )
  expect_identical(
    first$diagnostics$independent_legal_opinion_obtained,
    FALSE
  )
  expect_identical(
    first$remaining_gates,
    "final release-candidate source, installed, and binary inventory audit"
  )
})

test_that("missing and modified candidate bytes fail closed", {
  missing_reader <- function(path, max_bytes) {
    list(ok = FALSE, observed_state = "missing", bytes = NULL)
  }
  candidate_path <- getFromNamespace(
    ".lexres_tubelex_admission_paths",
    "ldfreq"
  )()$candidate_path
  bytes <- readBin(candidate_path, what = "raw", n = file.info(candidate_path)$size)
  bytes[[100L]] <- as.raw(bitwXor(as.integer(bytes[[100L]]), 1L))
  modified_reader <- function(path, max_bytes) {
    list(ok = TRUE, observed_state = "available", bytes = bytes)
  }

  missing <- admission_evaluate_function(reader = missing_reader)
  modified <- admission_evaluate_function(reader = modified_reader)

  expect_identical(missing$status, "candidate_error")
  expect_identical(missing$failure_reason, "candidate_unavailable")
  expect_identical(missing$admission_gate_passed, FALSE)
  expect_identical(modified$status, "candidate_error")
  expect_identical(modified$failure_reason, "candidate_hash_mismatch")
  expect_identical(modified$admission_gate_passed, FALSE)
  expect_identical(modified$diagnostics$fallback_attempted, FALSE)
  expect_identical(modified$diagnostics$download_attempted, FALSE)
})

test_that("candidate semantics require the approved scope and risk boundary", {
  path <- getFromNamespace(".lexres_tubelex_admission_paths", "ldfreq")()$candidate_path
  candidate <- jsonlite::read_json(path, simplifyVector = FALSE)
  changed_scope <- candidate
  changed_scope$maintainer_decision$approved_scopes$public_api_scope <- FALSE
  changed_boundary <- candidate
  changed_boundary$distribution_scope$raw_subtitles_or_identifiers_included <- TRUE

  expect_true(admission_semantics_function(candidate))
  expect_false(admission_semantics_function(changed_scope))
  expect_false(admission_semantics_function(changed_boundary))
})

test_that("the admission path has no network, shell, or fallback calls", {
  functions <- list(
    admission_candidate_function,
    admission_evaluate_function,
    admission_semantics_function
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
