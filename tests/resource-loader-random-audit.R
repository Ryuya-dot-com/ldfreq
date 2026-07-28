#!/usr/bin/env Rscript

library(ldfreq)

for (name in c(
  ".lexres_expectation", ".lexres_load_resource_impl", ".lexres_sha256_bytes"
)) {
  assign(name, getFromNamespace(name, "ldfreq"), envir = .GlobalEnv)
}

RNGkind(
  kind = "Mersenne-Twister",
  normal.kind = "Inversion",
  sample.kind = "Rejection"
)
set.seed(20260725)

assertions <- 0L
check <- function(condition, message) {
  assertions <<- assertions + 1L
  if (!isTRUE(condition)) stop(message, call. = FALSE)
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
manifest_path <- file.path(fixture_dir, "valid.manifest.dcf")
artifact_path <- file.path(fixture_dir, "valid-resource.tsv")
read_bytes <- function(path) {
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  readBin(connection, "raw", n = as.integer(file.info(path)$size) + 1L)
}
manifest_bytes <- read_bytes(manifest_path)
artifact_bytes <- read_bytes(artifact_path)
manifest_hash <- "173ca3fe2a65d49769700bc56b090b6059ccb87775d1bba8cb7112821c926e66"
artifact_hash <- "122af616ac3f0f9500f3ff648d488a5272c3657a50acfd0d3a2096525b64c899"
expectation <- .lexres_expectation(
  "synthetic-frequency",
  "1",
  manifest_hash,
  "valid.manifest.dcf",
  max_manifest_bytes = 4096,
  max_artifact_bytes = 4096,
  max_content_bytes = 4096
)
artifact_paths <- c("valid-resource.tsv" = artifact_path)

mutate_raw <- function(value) {
  mode <- sample.int(5L, 1L)
  if (mode == 1L) {
    index <- sample.int(length(value), 1L)
    replacement <- bitwXor(as.integer(value[[index]]), sample.int(255L, 1L))
    value[[index]] <- as.raw(replacement)
    value
  } else if (mode == 2L) {
    c(value, as.raw(sample.int(256L, 1L) - 1L))
  } else if (mode == 3L && length(value) > 1L) {
    value[-sample.int(length(value), 1L)]
  } else if (mode == 4L) {
    index <- sample.int(length(value) + 1L, 1L)
    insertion <- as.raw(sample.int(256L, 1L) - 1L)
    c(
      if (index > 1L) value[seq_len(index - 1L)] else raw(),
      insertion,
      if (index <= length(value)) value[index:length(value)] else raw()
    )
  } else {
    cut <- sample.int(length(value), 1L)
    c(value, value[cut])
  }
}

iterations <- 500L
for (iteration in seq_len(iterations)) {
  mutated_manifest <- mutate_raw(manifest_bytes)
  mutated_manifest_hash <- .lexres_sha256_bytes(mutated_manifest)
  check(
    !identical(mutated_manifest, manifest_bytes),
    sprintf("Manifest mutation was a no-op at iteration %d.", iteration)
  )
  check(
    !identical(mutated_manifest_hash, manifest_hash),
    sprintf("Manifest mutation retained the pinned hash at iteration %d.", iteration)
  )
  manifest_reads <- 0L
  manifest_mutation_reader <- function(path, max_bytes) {
    manifest_reads <<- manifest_reads + 1L
    if (identical(path, manifest_path)) {
      list(ok = TRUE, observed_state = "available", bytes = mutated_manifest)
    } else {
      list(ok = TRUE, observed_state = "available", bytes = artifact_bytes)
    }
  }
  manifest_result <- .lexres_load_resource_impl(
    manifest_path,
    expectation,
    artifact_paths,
    reader = manifest_mutation_reader
  )
  check(
    identical(manifest_result$failure_reason, "hash_mismatch"),
    sprintf("Manifest mutation escaped hash gate at iteration %d.", iteration)
  )
  check(
    identical(manifest_result$diagnostics$hash_role, "manifest_bytes") &&
      identical(manifest_result$diagnostics$expected_sha256, manifest_hash) &&
      identical(
        manifest_result$diagnostics$observed_sha256,
        mutated_manifest_hash
      ),
    sprintf("Manifest hash evidence failed at iteration %d.", iteration)
  )
  check(
    identical(
      manifest_result$diagnostics$observed_bytes,
      as.double(length(mutated_manifest))
    ) && manifest_reads == 1L,
    sprintf("Manifest mutation triggered a later read at iteration %d.", iteration)
  )
  check(
    is.null(manifest_result$manifest) && is.null(manifest_result$resource) &&
      identical(manifest_result$diagnostics$fallback_attempted, FALSE) &&
      identical(manifest_result$diagnostics$download_attempted, FALSE),
    sprintf("Manifest mutation leaked state or fallback at iteration %d.", iteration)
  )

  mutated_artifact <- mutate_raw(artifact_bytes)
  mutated_artifact_hash <- .lexres_sha256_bytes(mutated_artifact)
  check(
    !identical(mutated_artifact, artifact_bytes),
    sprintf("Artifact mutation was a no-op at iteration %d.", iteration)
  )
  check(
    !identical(mutated_artifact_hash, artifact_hash),
    sprintf("Artifact mutation retained the pinned hash at iteration %d.", iteration)
  )
  artifact_reads <- 0L
  artifact_mutation_reader <- function(path, max_bytes) {
    artifact_reads <<- artifact_reads + 1L
    if (identical(path, manifest_path)) {
      list(ok = TRUE, observed_state = "available", bytes = manifest_bytes)
    } else {
      list(ok = TRUE, observed_state = "available", bytes = mutated_artifact)
    }
  }
  artifact_result <- .lexres_load_resource_impl(
    manifest_path,
    expectation,
    artifact_paths,
    reader = artifact_mutation_reader
  )
  check(
    identical(artifact_result$failure_reason, "hash_mismatch"),
    sprintf("Artifact mutation escaped hash gate at iteration %d.", iteration)
  )
  check(
    identical(artifact_result$diagnostics$hash_role, "artifact_bytes") &&
      identical(artifact_result$diagnostics$expected_sha256, artifact_hash) &&
      identical(
        artifact_result$diagnostics$observed_sha256,
        mutated_artifact_hash
      ),
    sprintf("Artifact hash evidence failed at iteration %d.", iteration)
  )
  check(
    identical(
      artifact_result$diagnostics$observed_bytes,
      as.double(length(mutated_artifact))
    ) && artifact_reads == 2L,
    sprintf("Artifact mutation read count failed at iteration %d.", iteration)
  )
  check(
    !is.null(artifact_result$manifest) && is.null(artifact_result$resource) &&
      identical(artifact_result$diagnostics$fallback_attempted, FALSE) &&
      identical(artifact_result$diagnostics$download_attempted, FALSE),
    sprintf("Artifact mutation leaked resource or fallback at iteration %d.", iteration)
  )
}

cat(sprintf(
  paste0(
    "Resource loader random audit OK: %d iterations, %d byte mutations, ",
    "%d assertions; hash precedence and one-read/no-fallback behavior verified.\n"
  ),
  iterations,
  iterations * 2L,
  assertions
))
