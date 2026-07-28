library(ldfreq)

internal_names <- c(
  ".lexres_decode_gzip_bounded",
  ".lexres_load_resource_impl",
  ".lexres_load_tubelex",
  ".lexres_sha256_bytes",
  ".lexres_tubelex_expectation",
  ".lexres_tubelex_manifest_sha256",
  ".lexres_tubelex_paths"
)
for (internal_name in internal_names) {
  assign(
    internal_name,
    getFromNamespace(internal_name, "ldfreq"),
    envir = environment()
  )
}

assertions <- 0L
check <- function(condition, message) {
  assertions <<- assertions + 1L
  if (!isTRUE(condition)) stop(message, call. = FALSE)
}

read_bytes <- function(path) {
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  readBin(connection, "raw", n = as.integer(file.info(path)$size) + 1L)
}

paths <- .lexres_tubelex_paths()
manifest_path <- paths$manifest_path
artifact_path <- unname(paths$artifact_paths[[1L]])
bundle_dir <- dirname(manifest_path)
provenance_path <- file.path(bundle_dir, "build-provenance.json")
notice_path <- system.file("licenses", "tubelex", "NOTICE.md", package = "ldfreq")
copyrights_path <- system.file("COPYRIGHTS", package = "ldfreq")
inventory_path <- system.file(
  "spec", "ldfreq-resource-inventory.json",
  package = "ldfreq"
)
inventory_schema_path <- system.file(
  "spec", "ldfreq-resource-inventory.schema.json",
  package = "ldfreq"
)

for (path in c(
  manifest_path, artifact_path, provenance_path, notice_path, copyrights_path,
  inventory_path, inventory_schema_path
)) {
  check(nzchar(path) && file.exists(path), sprintf("Installed file missing: %s", path))
  check(isTRUE(file_test("-f", path)), sprintf("Installed member is not regular: %s", path))
}

identities <- list(
  manifest = c(
    bytes = 972,
    sha256 = "35dd3a7537174a462aa22ea41e470a0fc1dfc4b7fe7c28765465d040bf24bd04"
  ),
  artifact = c(
    bytes = 2549714,
    sha256 = "ded083e5b9f59ddfb719ebd88063778500cb347e1eab0f2d79ff55085d92fb4d"
  ),
  provenance = c(
    bytes = 6158,
    sha256 = "e95a9b0d4cad0c466fe875958ab8037d0738ff4d9f9a38c56583a38fe39cc785"
  ),
  notice = c(
    bytes = 4193,
    sha256 = "e65a1f5d0d6e7806e31e92d78bf3b903115e610c36bd9f2406269700441ecdd3"
  )
)
identity_paths <- list(
  manifest = manifest_path,
  artifact = artifact_path,
  provenance = provenance_path,
  notice = notice_path
)
for (name in names(identity_paths)) {
  bytes <- read_bytes(identity_paths[[name]])
  check(
    identical(as.double(length(bytes)), as.double(identities[[name]][["bytes"]])),
    sprintf("Installed %s byte count changed.", name)
  )
  check(
    identical(.lexres_sha256_bytes(bytes), unname(identities[[name]][["sha256"]])),
    sprintf("Installed %s SHA-256 changed.", name)
  )
}
check(
  identical(.lexres_tubelex_manifest_sha256, identities$manifest[["sha256"]]),
  "The compiled TUBELEX expectation is not bound to the installed manifest."
)

expectation <- .lexres_tubelex_expectation()
check(
  identical(expectation$resource_id, "tubelex-en-treebank-slim") &&
    identical(expectation$resource_version, "7cb5fb36-slim-v1") &&
    identical(expectation$max_artifacts, 1) &&
    identical(expectation$max_content_bytes, 9437184),
  "The installed TUBELEX expectation changed."
)

loaded <- .lexres_load_tubelex()
check(identical(loaded$status, "ok"), "The installed TUBELEX bundle did not load.")
check(is.na(loaded$failure_reason), "A successful TUBELEX load retained a failure reason.")
check(
  identical(
    loaded$resource_ref,
    list(
      contract_id = "ldfreq-lexical-sophistication-profile",
      contract_version = "0.1.0-draft.2",
      resource_id = "tubelex-en-treebank-slim",
      resource_version = "7cb5fb36-slim-v1",
      resource_manifest_sha256 = identities$manifest[["sha256"]]
    )
  ),
  "The TUBELEX resource reference changed."
)
check(
  identical(loaded$manifest$bundle_variant_id, "treebank-four-column-canonical-v1") &&
    identical(loaded$manifest$lookup_unit, "surface-form") &&
    identical(loaded$manifest$normalization_id, "nfkc-trim-root-lower-filtered-source-keys-v1"),
  "The TUBELEX manifest semantics changed."
)

evidence <- loaded$diagnostics$artifact_evidence[[1L]]
check(
  identical(evidence$artifact_sha256, identities$artifact[["sha256"]]) &&
    identical(evidence$artifact_bytes, 2549714) &&
    identical(evidence$content_sha256, "423dd4631c9da2f7442705d2930126da4cba980e46b6a5c0dda98336dce74916") &&
    identical(evidence$content_bytes, 8260448) &&
    identical(evidence$compression, "gzip"),
  "The TUBELEX artifact/content evidence changed."
)
check(
  identical(loaded$diagnostics$fallback_attempted, FALSE) &&
    identical(loaded$diagnostics$download_attempted, FALSE),
  "The installed TUBELEX loader attempted fallback or download."
)

resource <- loaded$resource[["tubelex_en_treebank_slim_csv_gz"]]
check(
  is.list(resource) &&
    identical(names(resource), c("word", "count", "videos", "channels", "totals")),
  "The TUBELEX decoded resource shape changed."
)
check(
  identical(length(resource$word), 515292L) &&
    identical(length(resource$count), 515292L) &&
    identical(length(resource$videos), 515292L) &&
    identical(length(resource$channels), 515292L),
  "The TUBELEX decoded row count changed."
)
check(
  identical(
    resource$totals,
    list(count = 171805865, videos = 105733, channels = 68405)
  ),
  "The TUBELEX declared totals changed."
)
check(!any(resource$word == "[TOTAL]"), "The TUBELEX total marker leaked into lookup rows.")
check(!anyDuplicated(resource$word), "The TUBELEX lookup contains duplicate keys.")
check(
  all(resource$channels <= resource$videos) &&
    all(resource$videos <= resource$count),
  "The TUBELEX count/prevalence ordering invariant failed."
)

known_rows <- list(
  the = c(count = 7448605, videos = 103830, channels = 60433),
  apple = c(count = 7403, videos = 3027, channels = 2563),
  zebra = c(count = 496, videos = 171, channels = 159),
  "don't" = c(count = 14898, videos = 9382, channels = 7366),
  "mother-in-law" = c(count = 287, videos = 189, channels = 182)
)
for (word in names(known_rows)) {
  index <- match(word, resource$word)
  observed <- c(
    count = resource$count[[index]],
    videos = resource$videos[[index]],
    channels = resource$channels[[index]]
  )
  check(identical(observed, known_rows[[word]]), sprintf("TUBELEX row changed: %s", word))
}

artifact_bytes <- read_bytes(artifact_path)
bounded <- .lexres_decode_gzip_bounded(artifact_bytes, 8260447)
check(
  identical(bounded$ok, FALSE) &&
    identical(bounded$limit_exceeded, TRUE) &&
    identical(bounded$violation, "content_size_limit_exceeded") &&
    is.null(bounded$bytes),
  "The gzip decoder exceeded its caller-provided content bound."
)
bad_header <- .lexres_decode_gzip_bounded(as.raw(c(0L, 1L, 2L)), 1024)
check(
  identical(bad_header$ok, FALSE) &&
    identical(bad_header$violation, "gzip_header"),
  "The gzip decoder accepted a non-gzip header."
)

mutated_reader <- local({
  manifest_bytes <- read_bytes(manifest_path)
  changed <- artifact_bytes
  changed[[1000L]] <- as.raw(bitwXor(as.integer(changed[[1000L]]), 1L))
  function(path, max_bytes) {
    if (identical(path, manifest_path)) {
      return(list(ok = TRUE, observed_state = "available", bytes = manifest_bytes))
    }
    list(ok = TRUE, observed_state = "available", bytes = changed)
  }
})
tampered <- .lexres_load_resource_impl(
  manifest_path,
  expectation,
  paths$artifact_paths,
  reader = mutated_reader
)
check(
  identical(tampered$status, "resource_error") &&
    identical(tampered$failure_reason, "hash_mismatch") &&
    identical(tampered$diagnostics$hash_role, "artifact_bytes") &&
    is.null(tampered$resource) &&
    identical(tampered$diagnostics$fallback_attempted, FALSE) &&
    identical(tampered$diagnostics$download_attempted, FALSE),
  "A mutated installed TUBELEX artifact escaped the compressed-byte hash gate."
)

if (!requireNamespace("jsonlite", quietly = TRUE)) {
  stop("The TUBELEX audit requires the suggested jsonlite package.", call. = FALSE)
}
provenance <- jsonlite::read_json(provenance_path, simplifyVector = FALSE)
check(
  identical(provenance$status, "direct-source-r-build-candidate-not-production") &&
    identical(provenance$source$commit, "7cb5fb36add76b83a266d1967536e1a1d3faa513") &&
    identical(provenance$source$sha256, "4096022259d5eaa7261c3bf22c3b0af9fd58ae8eebe17894c0b34a163954f936") &&
    identical(provenance$source$bundled_in_output, FALSE) &&
    identical(provenance$license$spdx, "BSD-3-Clause") &&
    identical(provenance$license$raw_subtitles_or_identifiers_included, FALSE),
  "The installed TUBELEX build provenance changed."
)
check(
  identical(
    provenance$release_unit$atomic_no_replace_against_compliant_wrappers,
    TRUE
  ) &&
    identical(
      provenance$release_unit$atomic_no_replace_against_noncooperating_processes,
      FALSE
    ),
  "The TUBELEX promotion concurrency scope changed."
)

inventory <- jsonlite::read_json(inventory_path, simplifyVector = FALSE)
check(
  identical(inventory$schema_version, "0.1.0") &&
    identical(inventory$reviewed_on, "2026-07-28") &&
    identical(inventory$policy$release_requires_independent_approval, TRUE) &&
    identical(inventory$policy$uncertainty_default, "exclude") &&
    identical(inventory$policy$runtime_network_access, FALSE) &&
    identical(inventory$policy$implicit_download_or_fallback, FALSE),
  "The installed resource-inventory policy changed."
)
check(
  identical(as.numeric(inventory$release_approved_resource_count), 0) &&
    length(inventory$included_resources) == 1L,
  "The installed inventory overstated release approval or resource count."
)
inventory_resource <- inventory$included_resources[[1L]]
check(
  identical(inventory_resource$resource_id, "tubelex-en-treebank-slim") &&
    identical(inventory_resource$distribution_state, "development-candidate") &&
    identical(inventory_resource$runtime_state, "internal-only") &&
    identical(inventory_resource$release_approved, FALSE) &&
    identical(inventory_resource$public_api, FALSE) &&
    identical(inventory_resource$license_spdx, "BSD-3-Clause") &&
    identical(inventory_resource$raw_source_bundled, FALSE) &&
    identical(inventory_resource$raw_subtitles_or_identifiers_included, FALSE),
  "The installed TUBELEX inventory state changed."
)
for (member in inventory_resource$package_members) {
  member_path <- system.file(member$path, package = "ldfreq")
  check(nzchar(member_path) && file.exists(member_path), sprintf(
    "Inventory member is not installed: %s", member$path
  ))
  member_bytes <- read_bytes(member_path)
  check(
    identical(as.numeric(length(member_bytes)), as.numeric(member$bytes)) &&
      identical(.lexres_sha256_bytes(member_bytes), member$sha256),
    sprintf("Inventory member identity changed: %s", member$path)
  )
}
excluded_ids <- vapply(
  inventory$not_included,
  function(resource_record) resource_record$resource_id,
  character(1L)
)
check(
  identical(
    excluded_ids,
    c(
      "ngsl-1.2", "oewn-2025", "nj8", "ngsl-31k-workbook",
      "coca", "ellipse-corpus", "python-resource-derived-golden-outputs"
    )
  ),
  "The explicit not-included resource inventory changed."
)

loader_functions <- list(
  .lexres_decode_gzip_bounded,
  .lexres_load_resource_impl,
  .lexres_load_tubelex,
  .lexres_tubelex_paths
)
loader_calls <- unique(unlist(lapply(
  loader_functions,
  function(fun) all.names(body(fun), functions = TRUE)
)))
forbidden_calls <- c(
  "download.file", "url", "curlGetHeaders", "socketConnection",
  "system", "system2", "shell", "pipe"
)
check(
  !any(forbidden_calls %in% loader_calls),
  "The installed TUBELEX load path gained network or shell behavior."
)

message(sprintf(
  paste(
    "Installed TUBELEX resource OK: %d assertions; 515,292 rows;",
    "compressed/content hashes, installed notices, bounded gzip,",
    "tamper detection, provenance, and no network/fallback."
  ),
  assertions
))
