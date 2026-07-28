#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) {
  stop(
    "Usage: Rscript promote-tubelex-release.R <pinned-source.tsv.xz> <new-release-directory>",
    call. = FALSE
  )
}
for (package in c("digest", "jsonlite")) {
  if (!requireNamespace(package, quietly = TRUE)) {
    stop(sprintf("The release wrapper requires %s.", package), call. = FALSE)
  }
}

main <- function() {
command <- commandArgs(trailingOnly = FALSE)
file_argument <- grep("^--file=", command, value = TRUE)
if (length(file_argument) != 1L) {
  stop("The release wrapper must be executed with Rscript.", call. = FALSE)
}
script_path <- normalizePath(sub("^--file=", "", file_argument), mustWork = TRUE)
script_directory <- dirname(script_path)
project_root <- normalizePath(file.path(script_directory, "..", ".."), mustWork = TRUE)
builder_path <- normalizePath(
  file.path(script_directory, "build-tubelex-from-source.R"),
  mustWork = TRUE
)
notice_path <- normalizePath(
  file.path(project_root, "legal", "tubelex", "NOTICE.md"),
  mustWork = TRUE
)
source_path <- normalizePath(args[[1L]], mustWork = TRUE)
release_path <- normalizePath(args[[2L]], mustWork = FALSE)
release_parent <- dirname(release_path)
release_name <- basename(release_path)
is_symbolic_link <- function(path) {
  target <- Sys.readlink(path)
  !is.na(target) && nzchar(target)
}

if (!nzchar(release_name) || release_name %in% c(".", "..")) {
  stop("The release directory must have a concrete basename.", call. = FALSE)
}
if (file.exists(release_path) || is_symbolic_link(release_path)) {
  stop("Refusing to replace an existing release path or symbolic link.", call. = FALSE)
}
if (!dir.exists(release_parent)) {
  dir.create(release_parent, recursive = TRUE, showWarnings = FALSE)
}
release_parent <- normalizePath(release_parent, mustWork = TRUE)
if (file.access(release_parent, 2L) != 0L) {
  stop("The release parent is not writable.", call. = FALSE)
}

expected_notice_bytes <- 4193
expected_notice_sha256 <- "e65a1f5d0d6e7806e31e92d78bf3b903115e610c36bd9f2406269700441ecdd3"
notice_bytes <- unname(file.info(notice_path)$size)
notice_sha256 <- digest::digest(file = notice_path, algo = "sha256", serialize = FALSE)
if (!identical(as.numeric(notice_bytes), as.numeric(expected_notice_bytes)) ||
    !identical(notice_sha256, expected_notice_sha256)) {
  stop("The reviewed TUBELEX notice identity changed.", call. = FALSE)
}

# An atomically created sibling lock prevents two compliant instances of this
# wrapper from promoting to the same name concurrently. Base R has no portable
# rename-no-replace primitive, so a non-cooperating process could still create a
# destination in the final check-to-rename interval. The manifest and README
# state this scope explicitly instead of claiming a race-free no-clobber rule.
lock_path <- file.path(
  release_parent,
  paste0(".", release_name, ".promotion-lock")
)
if (file.exists(lock_path) || is_symbolic_link(lock_path) ||
    !dir.create(lock_path, mode = "0700", showWarnings = FALSE)) {
  stop("Could not acquire the cooperative release promotion lock.", call. = FALSE)
}
lock_owned <- TRUE
on.exit({
  if (lock_owned && dir.exists(lock_path) && !is_symbolic_link(lock_path)) {
    unlink(lock_path, recursive = TRUE, force = TRUE)
  }
}, add = TRUE)

staging_path <- tempfile(pattern = ".tubelex-release-", tmpdir = release_parent)
if (!dir.create(staging_path, mode = "0755")) {
  stop("Could not create a sibling staging directory.", call. = FALSE)
}
staging_path <- normalizePath(staging_path, mustWork = TRUE)
on.exit({
  # This path was created above under the explicit release parent and is never
  # reassigned. After successful directory rename it no longer exists.
  if (dir.exists(staging_path)) unlink(staging_path, recursive = TRUE, force = TRUE)
}, add = TRUE)

artifact_name <- "tubelex_en_treebank_7cb5fb36_slim.csv.gz"
artifact_path <- file.path(staging_path, artifact_name)
builder_manifest_path <- file.path(staging_path, ".builder-manifest.json")
manifest_path <- file.path(staging_path, "manifest.json")
staged_notice_path <- file.path(staging_path, "NOTICE.md")

rscript <- file.path(R.home("bin"), "Rscript")
status <- system2(
  rscript,
  args = c(
    "--vanilla",
    shQuote(builder_path),
    shQuote(source_path),
    shQuote(artifact_path),
    shQuote(builder_manifest_path)
  ),
  stdout = TRUE,
  stderr = TRUE
)
exit_status <- attr(status, "status")
if (!is.null(exit_status) && exit_status != 0L) {
  stop(
    paste(c("The direct-source builder failed:", status), collapse = "\n"),
    call. = FALSE
  )
}
if (!file.copy(notice_path, staged_notice_path, overwrite = FALSE, copy.mode = TRUE)) {
  stop("Could not stage the reviewed notice.", call. = FALSE)
}
staged_notice_bytes <- unname(file.info(staged_notice_path)$size)
staged_notice_sha256 <- digest::digest(
  file = staged_notice_path,
  algo = "sha256",
  serialize = FALSE
)
if (!identical(as.numeric(staged_notice_bytes), as.numeric(expected_notice_bytes)) ||
    !identical(staged_notice_sha256, expected_notice_sha256)) {
  stop("The staged notice does not match the reviewed identity.", call. = FALSE)
}

manifest <- jsonlite::read_json(builder_manifest_path, simplifyVector = FALSE)
artifact_bytes <- unname(file.info(artifact_path)$size)
artifact_sha256 <- digest::digest(file = artifact_path, algo = "sha256", serialize = FALSE)
assert_manifest <- function(condition, message) {
  if (!isTRUE(condition)) stop(message, call. = FALSE)
}
numeric_manifest_equal <- function(value, expected) {
  length(value) == 1L && is.numeric(value) &&
    identical(as.numeric(value), as.numeric(expected))
}
assert_manifest(
  identical(manifest$schema_version, "0.2.0-experiment") &&
    identical(manifest$status, "direct-source-r-build-candidate-not-production") &&
    identical(manifest$id, "tubelex-en-treebank-7cb5fb36-slim-r-direct-v1"),
  "The staged manifest identity is not the reviewed direct-build contract."
)
assert_manifest(
  identical(manifest$source$commit, "7cb5fb36add76b83a266d1967536e1a1d3faa513") &&
    identical(manifest$source$sha256, "4096022259d5eaa7261c3bf22c3b0af9fd58ae8eebe17894c0b34a163954f936") &&
    identical(manifest$source$decompressed_sha256, "5ccfde4184698c1fa8049ba7c761d253d039fa5ad4e93e15239644fe6034b5c1") &&
    numeric_manifest_equal(manifest$source$word_rows, 613309) &&
    identical(manifest$source$local_path_recorded, FALSE) &&
    identical(manifest$source$bundled_in_output, FALSE) &&
    identical(manifest$source$verified_before_parsing, TRUE),
  "The staged manifest source provenance is incomplete or changed."
)
assert_manifest(
  identical(
    manifest$reviewed_reference$sha256,
    "3731f23f3385ed630777ff56b5edbed5db46eee256ededceb0ac213016f31675"
  ) &&
    identical(manifest$reviewed_reference$used_as_build_input, FALSE) &&
    identical(manifest$reviewed_reference$local_path_recorded, FALSE) &&
    identical(
      manifest$reviewed_reference$expected_projection_canonical_sha256,
      "423dd4631c9da2f7442705d2930126da4cba980e46b6a5c0dda98336dce74916"
    ),
  "The staged manifest reviewed-reference provenance is incomplete or changed."
)
assert_manifest(
  identical(manifest$artifact$file, artifact_name) &&
    numeric_manifest_equal(manifest$artifact$bytes, artifact_bytes) &&
    identical(manifest$artifact$sha256, artifact_sha256) &&
    numeric_manifest_equal(manifest$artifact$canonical_bytes, 8260448) &&
    identical(
      manifest$artifact$canonical_sha256,
      "423dd4631c9da2f7442705d2930126da4cba980e46b6a5c0dda98336dce74916"
    ) &&
    numeric_manifest_equal(manifest$artifact$word_rows, 515292),
  "The staged artifact does not match its reviewed manifest."
)
assert_manifest(
  identical(manifest$transformation$network_access, FALSE) &&
    identical(manifest$license$spdx, "BSD-3-Clause") &&
    identical(manifest$license$attribution_and_disclaimer_required, TRUE) &&
    identical(manifest$license$raw_subtitles_or_identifiers_included, FALSE),
  "The staged manifest transformation or license contract changed."
)

manifest$release_unit <- list(
  promotion_policy = paste(
    "cooperative sibling lock and two existing-target checks; fresh sibling",
    "staging directory renamed as one unit with base R file.rename"
  ),
  content_promotion_primitive = "one sibling-directory file.rename call",
  atomic_no_replace_against_compliant_wrappers = TRUE,
  atomic_no_replace_against_noncooperating_processes = FALSE,
  notice_identity_verified_after_copy = TRUE,
  build_tools = list(
    list(
      file = "experiments/tubelex-source-build/build-tubelex-from-source.R",
      sha256 = digest::digest(file = builder_path, algo = "sha256", serialize = FALSE)
    ),
    list(
      file = "experiments/tubelex-source-build/promote-tubelex-release.R",
      sha256 = digest::digest(file = script_path, algo = "sha256", serialize = FALSE)
    )
  ),
  files = list(
    list(
      file = artifact_name,
      role = "runtime aggregate data",
      bytes = artifact_bytes,
      sha256 = artifact_sha256
    ),
    list(
      file = "NOTICE.md",
      role = "upstream license, attribution, and change statement",
      bytes = staged_notice_bytes,
      sha256 = staged_notice_sha256
    ),
    list(
      file = "manifest.json",
      role = "provenance and validation record",
      self_hash_recorded = FALSE
    )
  )
)
temporary_manifest <- file.path(staging_path, ".manifest.json.tmp")
jsonlite::write_json(
  manifest,
  temporary_manifest,
  pretty = TRUE,
  auto_unbox = TRUE,
  null = "null",
  digits = NA
)
write("", file = temporary_manifest, append = TRUE)
roundtrip_manifest <- jsonlite::read_json(temporary_manifest, simplifyVector = FALSE)
assert_manifest(
  identical(roundtrip_manifest$id, manifest$id) &&
    identical(roundtrip_manifest$release_unit$notice_identity_verified_after_copy, TRUE) &&
    identical(
      roundtrip_manifest$release_unit$atomic_no_replace_against_noncooperating_processes,
      FALSE
    ) &&
    length(roundtrip_manifest$release_unit$files) == 3L,
  "The final staged manifest failed its JSON round-trip contract."
)
if (file.exists(manifest_path) || is_symbolic_link(manifest_path)) {
  stop("The final manifest path unexpectedly exists in staging.", call. = FALSE)
}
if (!file.rename(temporary_manifest, manifest_path)) {
  stop("Could not install the final staged manifest.", call. = FALSE)
}
if (unlink(builder_manifest_path, force = TRUE) != 0L) {
  stop("Could not remove the private builder manifest from staging.", call. = FALSE)
}

expected_files <- sort(c(artifact_name, "manifest.json", "NOTICE.md"))
actual_files <- sort(list.files(staging_path, all.files = TRUE, no.. = TRUE))
if (!identical(actual_files, expected_files)) {
  stop("The staged release unit contains unexpected or missing files.", call. = FALSE)
}
for (path in file.path(staging_path, expected_files)) {
  if (!file.exists(path) || dir.exists(path) || is_symbolic_link(path)) {
    stop("Every staged release member must be a regular file.", call. = FALSE)
  }
}
Sys.chmod(file.path(staging_path, expected_files), mode = "0644")
Sys.chmod(staging_path, mode = "0755")

# Recheck the destination immediately before the one-step directory promotion.
if (file.exists(release_path) || is_symbolic_link(release_path)) {
  stop("The release path appeared during staging; refusing to replace it.", call. = FALSE)
}
if (!file.rename(staging_path, release_path)) {
  stop("Could not atomically promote the staged release directory.", call. = FALSE)
}
if (unlink(lock_path, recursive = TRUE, force = TRUE) == 0L) {
  lock_owned <- FALSE
} else {
  warning("The release was promoted, but its cooperative lock could not be removed.")
}

cat(sprintf(
  "Promoted fresh TUBELEX release unit %s (%s, manifest.json, NOTICE.md).\n",
  basename(release_path),
  artifact_name
))
}

main()
