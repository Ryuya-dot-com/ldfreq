#!/usr/bin/env Rscript

library(ldfreq)

for (name in c(
  ".lexres_expectation", ".lexres_failures", ".lexres_load_resource",
  ".lexres_load_resource_impl", ".lexres_manifest_schema_id",
  ".lexres_read_raw_once", ".lexres_resource_ref", ".lexres_sha256_bytes"
)) {
  assign(name, getFromNamespace(name, "ldfreq"), envir = .GlobalEnv)
}

fixture_candidates <- c(
  file.path("tests", "fixtures", "resource-loader"),
  file.path("fixtures", "resource-loader")
)
fixture_candidates <- fixture_candidates[dir.exists(fixture_candidates)]
if (length(fixture_candidates) == 0L) {
  stop("Resource-loader fixtures are unavailable.", call. = FALSE)
}
fixture_dir <- fixture_candidates[[1L]]
fixture_path <- function(name) file.path(fixture_dir, name)

assertions <- 0L
check <- function(condition, message) {
  assertions <<- assertions + 1L
  if (!isTRUE(condition)) stop(message, call. = FALSE)
}
check_error <- function(code, pattern, message) {
  error <- tryCatch({
    force(code)
    NULL
  }, error = identity)
  check(
    inherits(error, "error") && grepl(pattern, conditionMessage(error)),
    message
  )
}

manifest_identities <- list(
  "valid.manifest.dcf" = c(
    bytes = 798,
    sha256 = "173ca3fe2a65d49769700bc56b090b6059ccb87775d1bba8cb7112821c926e66"
  ),
  "wrong-manifest-schema.manifest.dcf" = c(
    bytes = 813,
    sha256 = "4cebecde834bc6af873d719b57c176dc01ce1c6751af9bdfdfa3fc4a90a86488"
  ),
  "unsupported-version.manifest.dcf" = c(
    bytes = 812,
    sha256 = "5b5f7dcb08f4d76ff2f1f60743eb1fb6e77d9b6cda27e2a2fa4e27bd8e044656"
  ),
  "wrong-payload-schema.manifest.dcf" = c(
    bytes = 820,
    sha256 = "438754b1a8c0e8e1a2a31790b873dfba7f547377a8a780ef2c16a5d3bad0c2d2"
  ),
  "malformed-payload.manifest.dcf" = c(
    bytes = 814,
    sha256 = "c1f705ec4c05abf779b4ea448356301edfb47d81965559d7b17d5ea0f7b15d40"
  )
)
artifact_identities <- list(
  "valid-resource.tsv" = c(
    bytes = 27,
    sha256 = "122af616ac3f0f9500f3ff648d488a5272c3657a50acfd0d3a2096525b64c899"
  ),
  "tampered-resource.tsv" = c(
    bytes = 27,
    sha256 = "1474656fcaeaf5b090defb3ca659a6c58259189b59f281e1362f2f16fcaead37"
  ),
  "wrong-schema-resource.tsv" = c(
    bytes = 31,
    sha256 = "b2b6b491832bf50a647f6a2185ffc612770959091828a7f80f16a83f8ecb336a"
  ),
  "malformed-resource.tsv" = c(
    bytes = 33,
    sha256 = "43024faf6ea6ef900f1cce1f4bab68ec00dfd0e79ef649041d6eca8199599320"
  )
)

read_bytes <- function(path) {
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  readBin(connection, "raw", n = as.integer(file.info(path)$size) + 1L)
}
for (collection in list(manifest_identities, artifact_identities)) {
  for (name in names(collection)) {
    fixture_identity <- collection[[name]]
    bytes <- read_bytes(fixture_path(name))
    check(
      identical(
        as.double(length(bytes)),
        as.double(fixture_identity[["bytes"]])
      ),
      sprintf("Fixture byte count changed: %s.", name)
    )
    check(
      identical(
        .lexres_sha256_bytes(bytes),
        unname(fixture_identity[["sha256"]])
      ),
      sprintf("Fixture SHA-256 changed: %s.", name)
    )
  }
}

check(
  identical(
    .lexres_sha256_bytes(charToRaw("abc")),
    "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
  ),
  "The hard-coded SHA-256 abc oracle failed."
)
check(
  identical(
    .lexres_failures,
    c(
      "resource_unavailable", "hash_mismatch",
      "unsupported_resource_version", "schema_mismatch"
    )
  ),
  "Resource failure precedence changed."
)

valid_hash <- unname(manifest_identities[["valid.manifest.dcf"]][["sha256"]])
valid_expectation <- .lexres_expectation(
  resource_id = "synthetic-frequency",
  resource_version = "1",
  manifest_sha256 = valid_hash,
  manifest_locator_id = "valid.manifest.dcf",
  max_manifest_bytes = 4096,
  max_artifact_bytes = 4096,
  max_content_bytes = 4096
)
check(
  identical(class(valid_expectation), "lexsoph_resource_expectation") &&
    identical(valid_expectation$manifest_schema_id, .lexres_manifest_schema_id),
  "Expectation class or schema identity changed."
)

valid_paths <- c(
  "valid-resource.tsv" = fixture_path("valid-resource.tsv")
)
success <- .lexres_load_resource(
  fixture_path("valid.manifest.dcf"),
  valid_expectation,
  valid_paths
)
check(
  identical(success$status, "ok") && is.na(success$failure_reason) &&
    identical(class(success), "list") && !is.object(success),
  "Valid bundle did not load successfully."
)
check(
  identical(
    success$resource_ref,
    list(
      contract_id = "ldfreq-lexical-sophistication-profile",
      contract_version = "0.1.0-draft.2",
      resource_id = "synthetic-frequency",
      resource_version = "1",
      resource_manifest_sha256 = valid_hash
    )
  ),
  "Success resource reference changed."
)
check(
  identical(
    success$manifest$resource_manifest_schema_id,
    "lexsoph-resource-manifest"
  ) &&
    identical(success$manifest$bundle_variant_id, "fixture-valid") &&
    identical(length(success$manifest$artifacts), 1L) &&
    identical(
      success$manifest$artifacts[[1L]]$source_layer_ids,
      "synthetic_frequency"
    ),
  "Validated manifest identity changed."
)
loaded <- success$resource[["synthetic_frequency_tsv"]]
check(
  identical(names(loaded), c("term", "count")) &&
    identical(loaded$term, c("alpha", "beta")) &&
    identical(loaded$count, c(10, 2)),
  "Synthetic payload rows changed."
)
check(
  identical(success$diagnostics$manifest_sha256, valid_hash) &&
    identical(success$diagnostics$manifest_bytes, 798) &&
    identical(success$diagnostics$fallback_attempted, FALSE) &&
    identical(success$diagnostics$download_attempted, FALSE),
  "Success manifest evidence or no-fallback state changed."
)
artifact_evidence <- success$diagnostics$artifact_evidence[[1L]]
check(
  identical(
    artifact_evidence$artifact_sha256,
    unname(artifact_identities[["valid-resource.tsv"]][["sha256"]])
  ) &&
    identical(artifact_evidence$content_sha256, artifact_evidence$artifact_sha256) &&
    identical(artifact_evidence$artifact_bytes, 27) &&
    identical(artifact_evidence$content_bytes, 27),
  "Artifact/content byte evidence changed."
)

check_failure_common <- function(result, reason, artifact_id, locator_id, stage) {
  check(
    identical(result$status, "resource_error") &&
      identical(result$failure_reason, reason) &&
      identical(class(result), "list") && !is.object(result) &&
      is.null(result$resource),
    sprintf("%s did not return a structured resource error.", reason)
  )
  check(
    identical(result$diagnostics$artifact_id, artifact_id) &&
      identical(result$diagnostics$artifact_locator_id, locator_id) &&
      identical(result$diagnostics$detection_stage, stage) &&
      identical(result$diagnostics$fallback_attempted, FALSE) &&
      identical(result$diagnostics$download_attempted, FALSE),
    sprintf("%s common diagnostics changed.", reason)
  )
  check(
    identical(result$resource_ref, .lexres_resource_ref(valid_expectation)),
    sprintf("%s changed the expected resource reference.", reason)
  )
}

missing <- .lexres_load_resource(
  fixture_path("absent.manifest.dcf"),
  valid_expectation,
  valid_paths
)
check_failure_common(
  missing,
  "resource_unavailable",
  "resource_manifest",
  "valid.manifest.dcf",
  "availability"
)
check(
  identical(missing$diagnostics$observed_state, "missing") &&
    identical(
      names(missing$diagnostics),
      c(
        "artifact_locator_id", "artifact_id", "detection_stage",
        "fallback_attempted", "download_attempted", "observed_state"
      )
    ),
  "Missing-manifest diagnostics changed."
)

directory_failure <- .lexres_load_resource(
  fixture_dir,
  valid_expectation,
  valid_paths
)
check_failure_common(
  directory_failure,
  "resource_unavailable",
  "resource_manifest",
  "valid.manifest.dcf",
  "availability"
)
check(
  identical(directory_failure$diagnostics$observed_state, "not_regular"),
  "A directory must not be accepted as a resource file."
)

small_limit <- .lexres_expectation(
  "synthetic-frequency", "1", valid_hash, "valid.manifest.dcf",
  max_manifest_bytes = 10,
  max_artifact_bytes = 4096,
  max_content_bytes = 4096
)
size_failure <- .lexres_load_resource(
  fixture_path("valid.manifest.dcf"),
  small_limit,
  valid_paths
)
check(
  identical(size_failure$failure_reason, "resource_unavailable") &&
    identical(size_failure$diagnostics$observed_state, "size_limit_exceeded"),
  "Manifest size limits must fail before allocation or decoding."
)

manifest_hash_failure <- .lexres_load_resource(
  fixture_path("unsupported-version.manifest.dcf"),
  valid_expectation,
  valid_paths
)
check_failure_common(
  manifest_hash_failure,
  "hash_mismatch",
  "resource_manifest",
  "valid.manifest.dcf",
  "hash"
)
check(
  identical(manifest_hash_failure$diagnostics$hash_role, "manifest_bytes") &&
    identical(manifest_hash_failure$diagnostics$expected_sha256, valid_hash) &&
    identical(
      manifest_hash_failure$diagnostics$observed_sha256,
      unname(manifest_identities[["unsupported-version.manifest.dcf"]][["sha256"]])
    ) &&
    identical(manifest_hash_failure$diagnostics$observed_bytes, 812),
  "Manifest hash expected/observed evidence changed."
)

version_hash <- unname(
  manifest_identities[["unsupported-version.manifest.dcf"]][["sha256"]]
)
version_expectation <- .lexres_expectation(
  "synthetic-frequency", "1", version_hash,
  "unsupported-version.manifest.dcf",
  max_manifest_bytes = 4096,
  max_artifact_bytes = 4096,
  max_content_bytes = 4096
)
version_failure <- .lexres_load_resource(
  fixture_path("unsupported-version.manifest.dcf"),
  version_expectation,
  valid_paths
)
check(
  identical(version_failure$failure_reason, "unsupported_resource_version") &&
    identical(version_failure$diagnostics$expected_resource_version, "1") &&
    identical(version_failure$diagnostics$observed_resource_version, "2") &&
    identical(version_failure$diagnostics$detection_stage, "version") &&
    is.null(version_failure$resource),
  "Unsupported version expected/observed evidence changed."
)

wrong_manifest_hash <- unname(
  manifest_identities[["wrong-manifest-schema.manifest.dcf"]][["sha256"]]
)
wrong_manifest_expectation <- .lexres_expectation(
  "synthetic-frequency", "1", wrong_manifest_hash,
  "wrong-manifest-schema.manifest.dcf",
  max_manifest_bytes = 4096,
  max_artifact_bytes = 4096,
  max_content_bytes = 4096
)
manifest_schema_failure <- .lexres_load_resource(
  fixture_path("wrong-manifest-schema.manifest.dcf"),
  wrong_manifest_expectation,
  valid_paths
)
check(
  identical(manifest_schema_failure$failure_reason, "schema_mismatch") &&
    identical(
      manifest_schema_failure$diagnostics$expected_schema_id,
      "lexsoph-resource-manifest"
    ) &&
    identical(
      manifest_schema_failure$diagnostics$observed_schema_id,
      "not-the-lexsoph-manifest"
    ) &&
    "manifest_schema_id" %in%
      manifest_schema_failure$diagnostics$schema_violations,
  "Manifest schema expected/observed evidence changed."
)

wrong_payload_hash <- unname(
  manifest_identities[["wrong-payload-schema.manifest.dcf"]][["sha256"]]
)
wrong_payload_expectation <- .lexres_expectation(
  "synthetic-frequency", "1", wrong_payload_hash,
  "wrong-payload-schema.manifest.dcf",
  max_manifest_bytes = 4096,
  max_artifact_bytes = 4096,
  max_content_bytes = 4096
)
payload_schema_failure <- .lexres_load_resource(
  fixture_path("wrong-payload-schema.manifest.dcf"),
  wrong_payload_expectation,
  c(
    "wrong-schema-resource.tsv" = fixture_path("wrong-schema-resource.tsv")
  )
)
check(
  identical(payload_schema_failure$failure_reason, "schema_mismatch") &&
    identical(
      payload_schema_failure$diagnostics$expected_schema_id,
      "synthetic-term-count-tsv"
    ) &&
    identical(
      payload_schema_failure$diagnostics$observed_schema_id,
      "unrecognized-tsv-header"
    ) &&
    identical(
      payload_schema_failure$diagnostics$schema_violations,
      "unexpected_header"
    ),
  "Payload schema expected/observed evidence changed."
)

malformed_hash <- unname(
  manifest_identities[["malformed-payload.manifest.dcf"]][["sha256"]]
)
malformed_expectation <- .lexres_expectation(
  "synthetic-frequency", "1", malformed_hash,
  "malformed-payload.manifest.dcf",
  max_manifest_bytes = 4096,
  max_artifact_bytes = 4096,
  max_content_bytes = 4096
)
malformed_failure <- .lexres_load_resource(
  fixture_path("malformed-payload.manifest.dcf"),
  malformed_expectation,
  c("malformed-resource.tsv" = fixture_path("malformed-resource.tsv"))
)
check(
  identical(malformed_failure$failure_reason, "schema_mismatch") &&
    identical(malformed_failure$diagnostics$schema_violations, "row_arity"),
  "Malformed row arity must be a schema mismatch after matching hashes."
)

artifact_hash_failure <- .lexres_load_resource(
  fixture_path("valid.manifest.dcf"),
  valid_expectation,
  c("valid-resource.tsv" = fixture_path("tampered-resource.tsv"))
)
check_failure_common(
  artifact_hash_failure,
  "hash_mismatch",
  "synthetic_frequency_tsv",
  "valid-resource.tsv",
  "hash"
)
check(
  identical(artifact_hash_failure$diagnostics$hash_role, "artifact_bytes") &&
    identical(
      artifact_hash_failure$diagnostics$expected_sha256,
      unname(artifact_identities[["valid-resource.tsv"]][["sha256"]])
    ) &&
    identical(
      artifact_hash_failure$diagnostics$observed_sha256,
      unname(artifact_identities[["tampered-resource.tsv"]][["sha256"]])
    ),
  "Artifact hash expected/observed evidence changed."
)

with_global_methods <- function(methods, code) {
  method_names <- names(methods)
  existed <- vapply(
    method_names,
    exists,
    logical(1L),
    envir = .GlobalEnv,
    inherits = FALSE
  )
  previous <- mget(
    method_names[existed],
    envir = .GlobalEnv,
    inherits = FALSE,
    ifnotfound = list(NULL)
  )
  on.exit({
    rm(list = method_names, envir = .GlobalEnv)
    if (length(previous)) list2env(previous, envir = .GlobalEnv)
  }, add = TRUE)
  for (name in method_names) assign(name, methods[[name]], envir = .GlobalEnv)
  force(code)
}

# The trust decision must not depend on user-defined S3 extraction methods.
s3_gate_result <- with_global_methods(
  list(
    "$.lexsoph_resource_expectation" = function(x, name) "forged",
    "$.lexsoph_resource_load" = function(x, name) "forged",
    "[.data.frame" = function(x, ...) stop("unexpected data-frame dispatch"),
    "[[.data.frame" = function(x, ...) stop("unexpected data-frame dispatch"),
    "as.data.frame.matrix" = function(x, ...) {
      stop("unexpected matrix coercion dispatch")
    },
    "unique.character" = function(x, ...) rep.int("forged", length(x))
  ),
  .lexres_load_resource(
    fixture_path("valid.manifest.dcf"),
    valid_expectation,
    c("valid-resource.tsv" = fixture_path("tampered-resource.tsv"))
  )
)
check(
  identical(s3_gate_result$failure_reason, "hash_mismatch") &&
    identical(s3_gate_result$diagnostics$hash_role, "artifact_bytes") &&
    identical(class(s3_gate_result), "list") && !is.object(s3_gate_result),
  "User-defined S3 methods bypassed the pinned artifact gate."
)

expectation_spoof_result <- with_global_methods(
  list("$.lexsoph_resource_expectation" = function(x, name) {
    if (identical(name, "manifest_sha256")) {
      return(version_hash)
    }
    if (identical(name, "resource_version")) return("2")
    NextMethod("$")
  }),
  .lexres_load_resource(
    fixture_path("unsupported-version.manifest.dcf"),
    valid_expectation,
    valid_paths
  )
)
check(
  identical(expectation_spoof_result$failure_reason, "hash_mismatch") &&
    identical(
      expectation_spoof_result$diagnostics$expected_sha256,
      valid_hash
    ),
  "Expectation extraction was altered by an S3 dollar method."
)

missing_artifact <- .lexres_load_resource(
  fixture_path("valid.manifest.dcf"),
  valid_expectation,
  c("valid-resource.tsv" = fixture_path("absent-resource.tsv"))
)
check(
  identical(missing_artifact$failure_reason, "resource_unavailable") &&
    identical(missing_artifact$diagnostics$artifact_id, "synthetic_frequency_tsv") &&
    identical(missing_artifact$diagnostics$observed_state, "missing") &&
    !is.null(missing_artifact$manifest),
  "Missing payload must retain validated manifest metadata."
)

# Hash precedence: the incompatible-version manifest has an incompatible schema
# payload too, but an unpinned byte stream must stop at hash mismatch.
check(
  identical(manifest_hash_failure$failure_reason, "hash_mismatch") &&
    is.null(manifest_hash_failure$manifest),
  "Hash mismatch must precede version and schema interpretation."
)

# The reader returns valid manifest bytes, then replaces the exact path with an
# incompatible manifest. Success proves hashing and parsing use the same raw.
toctou_path <- tempfile("lexres-toctou-", fileext = ".dcf")
invisible(file.copy(
  fixture_path("valid.manifest.dcf"),
  toctou_path,
  overwrite = TRUE
))
on.exit(unlink(toctou_path), add = TRUE)
reader_calls <- 0L
toctou_reader <- function(path, max_bytes) {
  reader_calls <<- reader_calls + 1L
  output <- .lexres_read_raw_once(path, max_bytes)
  if (identical(path, toctou_path) && isTRUE(output$ok)) {
    invisible(file.copy(
      fixture_path("unsupported-version.manifest.dcf"),
      toctou_path,
      overwrite = TRUE
    ))
  }
  output
}
toctou_success <- .lexres_load_resource_impl(
  toctou_path,
  valid_expectation,
  valid_paths,
  reader = toctou_reader
)
check(
  identical(toctou_success$status, "ok") && reader_calls == 2L,
  "Loader reopened the manifest after hashing or did not read each file once."
)

# No fallback: a valid decoy exists beside the exact missing path.
decoy_dir <- tempfile("lexres-decoy-")
dir.create(decoy_dir)
on.exit(unlink(decoy_dir, recursive = TRUE), add = TRUE)
invisible(file.copy(
  fixture_path("valid.manifest.dcf"),
  file.path(decoy_dir, "latest.manifest.dcf")
))
no_fallback <- .lexres_load_resource(
  file.path(decoy_dir, "required.manifest.dcf"),
  valid_expectation,
  valid_paths
)
check(
  identical(no_fallback$failure_reason, "resource_unavailable") &&
    identical(no_fallback$diagnostics$observed_state, "missing"),
  "Loader searched a sibling/latest fallback."
)

for (uri in c(
  "https://example.invalid/resource.dcf",
  "http://example.invalid/resource.dcf",
  "file:///tmp/resource.dcf",
  "ftp://example.invalid/resource.dcf",
  "sftp://example.invalid/resource.dcf",
  "data:text/plain,resource",
  "mailto:resource@example.invalid"
)) {
  check_error(
    .lexres_load_resource(uri, valid_expectation, valid_paths),
    "exact local filesystem path",
    sprintf("URI was not rejected before I/O: %s.", uri)
  )
}
check_error(
  .lexres_load_resource(
    c(fixture_path("valid.manifest.dcf"), fixture_path("valid.manifest.dcf")),
    valid_expectation,
    valid_paths
  ),
  "exactly one",
  "A vector of candidate manifest paths must be rejected."
)
check_error(
  .lexres_load_resource(
    fixture_path("valid.manifest.dcf"),
    valid_expectation,
    c("unexpected.tsv" = fixture_path("valid-resource.tsv"))
  ),
  "exactly match",
  "Artifact locator aliases must not trigger fallback."
)
check_error(
  .lexres_expectation(
    "synthetic-frequency", "1", toupper(valid_hash), "valid.manifest.dcf"
  ),
  "lowercase SHA-256",
  "Uppercase expected hashes must be rejected."
)
check_error(
  .lexres_expectation(
    "synthetic-frequency", "1", valid_hash, "../valid.manifest.dcf"
  ),
  "normalized relative locator",
  "Parent traversal in logical locators must be rejected."
)
for (locator in c("C:/outside", "ftp:resource", "line\nbreak")) {
  check_error(
    .lexres_expectation(
      "synthetic-frequency", "1", valid_hash, locator
    ),
    "normalized relative locator",
    sprintf("Unsafe logical locator was accepted: %s.", locator)
  )
}
tampered_expectation <- valid_expectation
tampered_expectation$resource_id <- "other-resource"
check_error(
  .lexres_load_resource(
    fixture_path("valid.manifest.dcf"),
    tampered_expectation,
    valid_paths
  ),
  "canonical or have been altered",
  "Classed but altered expectations must be rejected."
)
subclassed_expectation <- valid_expectation
class(subclassed_expectation) <- c(
  "spoofed_expectation", "lexsoph_resource_expectation"
)
check_error(
  .lexres_load_resource(
    fixture_path("valid.manifest.dcf"),
    subclassed_expectation,
    valid_paths
  ),
  "created by",
  "Expectation subclasses must be rejected."
)

write_manifest_case <- function(text, stem) {
  path <- tempfile(paste0("lexres-", stem, "-"), fileext = ".dcf")
  connection <- file(path, open = "wb")
  on.exit(close(connection), add = TRUE)
  writeBin(charToRaw(enc2utf8(text)), connection)
  path
}
expectation_for_manifest <- function(path, locator, ...) {
  .lexres_expectation(
    "synthetic-frequency",
    "1",
    .lexres_sha256_bytes(read_bytes(path)),
    locator,
    max_manifest_bytes = 8192,
    max_artifact_bytes = 4096,
    max_content_bytes = 4096,
    ...
  )
}
valid_manifest_text <- rawToChar(read_bytes(fixture_path("valid.manifest.dcf")))
temporary_manifests <- character()
on.exit(unlink(temporary_manifests), add = TRUE)

empty_field_cases <- c(
  "Manifest-Schema-ID: lexsoph-resource-manifest" = "Manifest-Schema-ID:",
  "Resource-Schema-Version: 1" = "Resource-Schema-Version:",
  "Artifact-Version: 1" = "Artifact-Version:",
  "License-ID: CC0-1.0" = "License-ID:",
  "Source-Layer-IDs: synthetic_frequency" = "Source-Layer-IDs:"
)
for (index in seq_along(empty_field_cases)) {
  mutated_text <- sub(
    names(empty_field_cases)[[index]],
    empty_field_cases[[index]],
    valid_manifest_text,
    fixed = TRUE
  )
  path <- write_manifest_case(mutated_text, paste0("empty-", index))
  temporary_manifests <- c(temporary_manifests, path)
  result <- .lexres_load_resource(
    path,
    expectation_for_manifest(path, paste0("empty-", index, ".manifest.dcf")),
    valid_paths
  )
  check(
    identical(result$failure_reason, "schema_mismatch"),
    sprintf("Empty manifest field %d was not a structured schema failure.", index)
  )
}

continuation_text <- sub(
  "License-ID: CC0-1.0",
  "License-ID: CC0-1.0\n continuation-value",
  valid_manifest_text,
  fixed = TRUE
)
continuation_path <- write_manifest_case(continuation_text, "continuation")
temporary_manifests <- c(temporary_manifests, continuation_path)
continuation_result <- .lexres_load_resource(
  continuation_path,
  expectation_for_manifest(
    continuation_path,
    "continuation.manifest.dcf"
  ),
  valid_paths
)
check(
  identical(continuation_result$failure_reason, "schema_mismatch") &&
    identical(
      continuation_result$diagnostics$schema_violations,
      "dcf_continuation_unsupported"
    ),
  "DCF continuation syntax was not rejected by the strict subset parser."
)

second_record <- sub(
  "Artifact-ID: synthetic_frequency_tsv",
  "Artifact-ID: synthetic_frequency_tsv_z",
  valid_manifest_text,
  fixed = TRUE
)
duplicate_locator_text <- paste0(valid_manifest_text, "\n", second_record)
duplicate_locator_path <- write_manifest_case(
  duplicate_locator_text,
  "duplicate-locator"
)
temporary_manifests <- c(temporary_manifests, duplicate_locator_path)
duplicate_locator_result <- .lexres_load_resource(
  duplicate_locator_path,
  expectation_for_manifest(
    duplicate_locator_path,
    "duplicate-locator.manifest.dcf"
  ),
  valid_paths
)
check(
  identical(duplicate_locator_result$failure_reason, "schema_mismatch") &&
    "artifact_locator_duplicate" %in%
      duplicate_locator_result$diagnostics$schema_violations,
  "Duplicate artifact locators were not rejected before path resolution."
)

second_distinct_record <- sub(
  "Artifact-Locator-ID: valid-resource.tsv",
  "Artifact-Locator-ID: valid-resource-copy.tsv",
  second_record,
  fixed = TRUE
)
two_artifact_text <- paste0(valid_manifest_text, "\n", second_distinct_record)
two_artifact_path <- write_manifest_case(two_artifact_text, "two-artifact")
temporary_manifests <- c(temporary_manifests, two_artifact_path)
artifact_count_result <- .lexres_load_resource(
  two_artifact_path,
  expectation_for_manifest(
    two_artifact_path,
    "two-artifact.manifest.dcf",
    max_artifacts = 1
  ),
  valid_paths
)
check(
  identical(artifact_count_result$failure_reason, "resource_unavailable") &&
    identical(
      artifact_count_result$diagnostics$observed_state,
      "artifact_count_limit_exceeded"
    ),
  "Bundle artifact-count limit was not enforced before path resolution."
)

total_artifact_result <- .lexres_load_resource(
  fixture_path("valid.manifest.dcf"),
  .lexres_expectation(
    "synthetic-frequency", "1", valid_hash, "valid.manifest.dcf",
    max_manifest_bytes = 4096,
    max_artifact_bytes = 4096,
    max_content_bytes = 4096,
    max_total_artifact_bytes = 26
  ),
  valid_paths
)
check(
  identical(total_artifact_result$failure_reason, "resource_unavailable") &&
    identical(
      total_artifact_result$diagnostics$observed_state,
      "bundle_artifact_size_limit_exceeded"
    ),
  "Aggregate declared artifact-byte limit was not enforced."
)

total_content_result <- .lexres_load_resource(
  fixture_path("valid.manifest.dcf"),
  .lexres_expectation(
    "synthetic-frequency", "1", valid_hash, "valid.manifest.dcf",
    max_manifest_bytes = 4096,
    max_artifact_bytes = 4096,
    max_content_bytes = 4096,
    max_total_content_bytes = 26
  ),
  valid_paths
)
check(
  identical(total_content_result$failure_reason, "resource_unavailable") &&
    identical(
      total_content_result$diagnostics$observed_state,
      "bundle_content_size_limit_exceeded"
    ),
  "Aggregate declared content-byte limit was not enforced."
)

for (name in names(artifact_identities)) {
  check(
    file.exists(fixture_path(name)) &&
      isTRUE(utils::file_test("-f", fixture_path(name))),
    sprintf("Versioned TSV fixture is absent from the source package: %s.", name)
  )
}

banned_calls <- c(
  "download.file", "url", "socketConnection", "system", "system2", "pipe"
)
loader_names <- all.names(body(.lexres_load_resource_impl), functions = TRUE)
check(
  !any(banned_calls %in% loader_names),
  "Runtime loader gained network, shell, or pipe fallback capability."
)

cat(sprintf(
  paste0(
    "Internal resource loader OK: %d assertions; one-read raw hashing, ",
    "manifest/artifact identity, all four failures, precedence, TOCTOU, ",
    "strict plain parsing/results, S3 isolation, no-fallback, no-network, ",
    "schema, version, inventory, and bundle limits verified.\n"
  ),
  assertions
))
