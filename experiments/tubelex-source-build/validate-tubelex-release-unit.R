#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) {
  stop(
    paste(
      "Usage: Rscript validate-tubelex-release-unit.R",
      "<pinned-source.tsv.xz> <fresh-audit-directory>"
    ),
    call. = FALSE
  )
}

for (package in c("digest", "jsonlite", "stringi")) {
  if (!requireNamespace(package, quietly = TRUE)) {
    stop(sprintf("The audit requires the R package %s.", package), call. = FALSE)
  }
}

source_path <- normalizePath(args[[1L]], mustWork = TRUE)
audit_root <- normalizePath(args[[2L]], mustWork = FALSE)
if (file.exists(audit_root)) {
  stop("The audit directory must not already exist.", call. = FALSE)
}
if (!dir.create(audit_root, recursive = TRUE, mode = "0755")) {
  stop("Could not create the audit directory.", call. = FALSE)
}
audit_root <- normalizePath(audit_root, mustWork = TRUE)

script_argument <- grep("^--file=", commandArgs(FALSE), value = TRUE)
if (length(script_argument) != 1L) {
  stop("Could not determine the validator path.", call. = FALSE)
}
script_path <- normalizePath(sub("^--file=", "", script_argument), mustWork = TRUE)
script_dir <- dirname(script_path)
wrapper_path <- normalizePath(
  file.path(script_dir, "promote-tubelex-release.R"),
  mustWork = TRUE
)
builder_path <- normalizePath(
  file.path(script_dir, "build-tubelex-from-source.R"),
  mustWork = TRUE
)
notice_path <- normalizePath(
  file.path(script_dir, "..", "..", "legal", "tubelex", "NOTICE.md"),
  mustWork = TRUE
)

expected <- list(
  source_bytes = 4152940,
  source_sha256 = "4096022259d5eaa7261c3bf22c3b0af9fd58ae8eebe17894c0b34a163954f936",
  content_bytes = 8260448,
  content_sha256 = "423dd4631c9da2f7442705d2930126da4cba980e46b6a5c0dda98336dce74916",
  rows = 515292,
  notice_bytes = 4193,
  notice_sha256 = "e65a1f5d0d6e7806e31e92d78bf3b903115e610c36bd9f2406269700441ecdd3",
  builder_sha256 = "f880b97fa159b89e2faadafc420df055f113ee2449049dbd2f0d33f4f30f23e6",
  wrapper_sha256 = "6ba5f8d314130691860e772a633a159477bbc130ad09d401c81cc0786926c20b"
)

assertions <- 0L
check <- function(condition, message) {
  assertions <<- assertions + 1L
  if (!isTRUE(condition)) stop(message, call. = FALSE)
}
sha256_file <- function(path) {
  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}
regular_file <- function(path) {
  file.exists(path) && isTRUE(file_test("-f", path)) &&
    !isTRUE(Sys.readlink(path) != "")
}
exit_code <- function(output) {
  status <- attr(output, "status")
  if (is.null(status)) 0L else as.integer(status)
}
run_wrapper <- function(destination, input = source_path) {
  output <- suppressWarnings(system2(
    file.path(R.home("bin"), "Rscript"),
    args = c(
      "--vanilla",
      shQuote(wrapper_path),
      shQuote(input),
      shQuote(destination)
    ),
    stdout = TRUE,
    stderr = TRUE
  ))
  list(status = exit_code(output), output = output)
}
read_canonical <- function(path) {
  connection <- gzfile(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  chunks <- list()
  total <- 0
  repeat {
    chunk <- readBin(connection, "raw", n = 1048576L)
    if (!length(chunk)) break
    total <- total + length(chunk)
    check(total <= 9437184, "A built artifact exceeded the decoded-content bound.")
    chunks[[length(chunks) + 1L]] <- chunk
  }
  if (!length(chunks)) raw() else do.call(c, chunks)
}

check(
  identical(as.numeric(file.info(source_path)$size), as.numeric(expected$source_bytes)),
  "The fixed source byte count changed."
)
check(identical(sha256_file(source_path), expected$source_sha256), "The fixed source hash changed.")
check(identical(sha256_file(builder_path), expected$builder_sha256), "The builder hash changed.")
check(identical(sha256_file(wrapper_path), expected$wrapper_sha256), "The wrapper hash changed.")
check(
  identical(as.numeric(file.info(notice_path)$size), as.numeric(expected$notice_bytes)) &&
    identical(sha256_file(notice_path), expected$notice_sha256),
  "The reviewed notice identity changed."
)

inspect_unit <- function(path) {
  expected_names <- sort(c(
    "NOTICE.md", "manifest.json",
    "tubelex_en_treebank_7cb5fb36_slim.csv.gz"
  ))
  actual_names <- sort(list.files(path, all.files = TRUE, no.. = TRUE))
  check(identical(actual_names, expected_names), "A release unit has unexpected members.")
  members <- file.path(path, expected_names)
  check(all(vapply(members, regular_file, logical(1L))), "A release member is not regular.")

  artifact_path <- file.path(path, "tubelex_en_treebank_7cb5fb36_slim.csv.gz")
  installed_notice <- file.path(path, "NOTICE.md")
  manifest_path <- file.path(path, "manifest.json")
  canonical <- read_canonical(artifact_path)
  check(
    identical(as.double(length(canonical)), as.double(expected$content_bytes)) &&
      identical(
        digest::digest(canonical, algo = "sha256", serialize = FALSE),
        expected$content_sha256
      ),
    "A release unit failed the canonical CSV identity gate."
  )
  check(
    identical(as.numeric(file.info(installed_notice)$size), as.numeric(expected$notice_bytes)) &&
      identical(sha256_file(installed_notice), expected$notice_sha256),
    "A release unit changed the reviewed notice."
  )

  manifest <- jsonlite::read_json(manifest_path, simplifyVector = FALSE)
  check(
    identical(manifest$status, "direct-source-r-build-candidate-not-production") &&
      identical(manifest$id, "tubelex-en-treebank-7cb5fb36-slim-r-direct-v1") &&
      identical(manifest$source$sha256, expected$source_sha256) &&
      identical(manifest$source$bundled_in_output, FALSE) &&
      identical(manifest$source$local_path_recorded, FALSE),
    "A release manifest changed its fixed source identity."
  )
  check(
    identical(manifest$artifact$sha256, sha256_file(artifact_path)) &&
      identical(as.numeric(manifest$artifact$bytes), as.numeric(file.info(artifact_path)$size)) &&
      identical(manifest$artifact$canonical_sha256, expected$content_sha256) &&
      identical(as.numeric(manifest$artifact$canonical_bytes), as.numeric(expected$content_bytes)) &&
      identical(as.numeric(manifest$artifact$word_rows), as.numeric(expected$rows)),
    "A release manifest does not bind its artifact."
  )
  check(
    identical(manifest$transformation$network_access, FALSE) &&
      identical(manifest$license$spdx, "BSD-3-Clause") &&
      identical(manifest$license$raw_subtitles_or_identifiers_included, FALSE),
    "A release manifest changed its transformation or license boundary."
  )
  check(
    identical(
      manifest$release_unit$atomic_no_replace_against_compliant_wrappers,
      TRUE
    ) &&
      identical(
        manifest$release_unit$atomic_no_replace_against_noncooperating_processes,
        FALSE
      ) &&
      identical(manifest$release_unit$notice_identity_verified_after_copy, TRUE),
    "A release manifest overstated its promotion guarantee."
  )
  tool_hashes <- vapply(
    manifest$release_unit$build_tools,
    function(tool) tool$sha256,
    character(1L)
  )
  check(
    identical(tool_hashes, c(expected$builder_sha256, expected$wrapper_sha256)),
    "A release manifest changed its build-tool hashes."
  )
  list(
    artifact_sha256 = sha256_file(artifact_path),
    manifest_sha256 = sha256_file(manifest_path),
    notice_sha256 = sha256_file(installed_notice)
  )
}

unit_a <- file.path(audit_root, "unit-a")
unit_b <- file.path(audit_root, "unit-b")
result_a <- run_wrapper(unit_a)
result_b <- run_wrapper(unit_b)
check(identical(result_a$status, 0L), "The first clean promotion failed.")
check(identical(result_b$status, 0L), "The second clean promotion failed.")
identity_a <- inspect_unit(unit_a)
identity_b <- inspect_unit(unit_b)
check(identical(identity_a, identity_b), "Two clean release units were not byte-identical.")

before_refusal <- identity_a
refusal <- run_wrapper(unit_a)
check(refusal$status != 0L, "The wrapper replaced an existing destination.")
check(identical(inspect_unit(unit_a), before_refusal), "Refusal changed an existing unit.")

lock_destination <- file.path(audit_root, "lock-test")
lock_path <- file.path(audit_root, ".lock-test.promotion-lock")
check(dir.create(lock_path, mode = "0700"), "Could not create the lock fixture.")
locked <- run_wrapper(lock_destination)
check(locked$status != 0L, "The wrapper ignored an existing cooperative lock.")
check(!file.exists(lock_destination), "Lock refusal created a destination.")
check(unlink(lock_path, recursive = TRUE, force = TRUE) == 0L, "Could not remove the lock fixture.")

corrupt_source <- file.path(audit_root, "corrupt-source.tsv.xz")
source_bytes <- readBin(source_path, "raw", n = as.integer(expected$source_bytes) + 1L)
source_bytes[[1000L]] <- as.raw(bitwXor(as.integer(source_bytes[[1000L]]), 1L))
connection <- file(corrupt_source, open = "wb")
writeBin(source_bytes, connection, useBytes = TRUE)
close(connection)
failure_destination <- file.path(audit_root, "forced-failure")
before_failure <- sort(list.files(audit_root, all.files = TRUE, no.. = TRUE))
failed <- run_wrapper(failure_destination, input = corrupt_source)
after_failure <- sort(list.files(audit_root, all.files = TRUE, no.. = TRUE))
check(failed$status != 0L, "The wrapper accepted a corrupt fixed source.")
check(!file.exists(failure_destination), "A failed build promoted a destination.")
check(
  identical(before_failure, after_failure),
  "A failed build left a lock or staging directory."
)

concurrent_destination <- file.path(audit_root, "concurrent-unit")
cluster <- parallel::makeCluster(2L)
on.exit({
  if (!is.null(cluster)) parallel::stopCluster(cluster)
}, add = TRUE)
concurrent_status <- unlist(parallel::parLapply(
  cluster,
  X = seq_len(2L),
  fun = function(index, rscript, wrapper, source, destination) {
    output <- suppressWarnings(system2(
      rscript,
      args = c(
        "--vanilla", shQuote(wrapper), shQuote(source), shQuote(destination)
      ),
      stdout = TRUE,
      stderr = TRUE
    ))
    status <- attr(output, "status")
    if (is.null(status)) 0L else as.integer(status)
  },
  rscript = file.path(R.home("bin"), "Rscript"),
  wrapper = wrapper_path,
  source = source_path,
  destination = concurrent_destination
))
parallel::stopCluster(cluster)
cluster <- NULL
check(
  identical(sort(concurrent_status), c(0L, 1L)),
  "Concurrent compliant wrappers did not produce one success and one refusal."
)
concurrent_identity <- inspect_unit(concurrent_destination)
check(
  identical(concurrent_identity, identity_a),
  "The concurrently promoted release unit changed identity."
)
check(
  !file.exists(file.path(audit_root, ".concurrent-unit.promotion-lock")),
  "Concurrent promotion left its cooperative lock."
)

message(sprintf(
  paste(
    "TUBELEX release-unit audit OK: %d assertions; two clean builds,",
    "canonical identity, notice/provenance binding, existing-target and lock",
    "refusal, failure cleanup, and one-winner cooperative concurrency."
  ),
  assertions
))
