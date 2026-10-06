#!/usr/bin/env Rscript
# Repository-only regressions. No package builds or remote check claims.
local({
args <- commandArgs(trailingOnly = TRUE)
package_root <- normalizePath(if (length(args)) args[[1L]] else ".", mustWork = TRUE)
scratch <- tempfile("ldfreq-inventory-regressions-")
dir.create(scratch)
on.exit(unlink(scratch, recursive = TRUE), add = TRUE)
read_json <- function(path) jsonlite::read_json(path, simplifyVector = FALSE)
write_json <- function(x, path) jsonlite::write_json(x, path,
  auto_unbox = TRUE, pretty = TRUE, null = "null")
installed <- "inst/spec/ldfreq-installed-resource-manifest.json"
admitted <- "experiments/resource-admission/ldfreq-release-resource-inventory.json"
inventory_script <- file.path(package_root, "experiments/package-resource-inventory/validate-package-resource-inventory.R")
admission_script <- file.path(package_root, "experiments/resource-admission/validate-tubelex-admission.R")
passed <- 0L
run_case <- function(name, mutate, pattern = NULL, admission = FALSE) {
  fixture <- file.path(scratch, name)
  dir.create(fixture)
  stopifnot(file.copy(file.path(package_root, "DESCRIPTION"), fixture),
    file.copy(file.path(package_root, "inst"), fixture, recursive = TRUE))
  dir.create(file.path(fixture, "experiments"))
  stopifnot(file.copy(file.path(package_root, "experiments/resource-admission"),
    file.path(fixture, "experiments"), recursive = TRUE))
  mutate(fixture)
  # A preflight regression must fail before attempting to read this sentinel.
  archive <- file.path(fixture, "ldfreq_0.2.0.tar.gz")
  writeLines("Not an archive: preflight must reject the fixture first.", archive)
  command <- if (admission) c(admission_script, fixture) else
    c(inventory_script, fixture, file.path(fixture, "audit"), archive)
  output <- suppressWarnings(system2(file.path(R.home("bin"), "Rscript"),
    c("--vanilla", vapply(command, shQuote, character(1L))), stdout = TRUE, stderr = TRUE))
  failed <- !is.null(attr(output, "status")) && attr(output, "status") != 0L
  if (is.null(pattern)) {
    stopifnot(!failed, isTRUE(jsonlite::fromJSON(paste(output, collapse = "\n"))$admission_gate_passed))
  } else if (!failed || !any(grepl(pattern, output, fixed = TRUE))) {
    stop(name, ": expected rejection was absent: ", paste(output, collapse = "\n"))
  }
  passed <<- passed + 1L
  cat("PASS:", name, "\n")
}
edit_record <- function(root, path, mutate) {
  path <- file.path(root, path)
  write_json(mutate(read_json(path)), path)
}
run_case("admission-valid", function(p) NULL, admission = TRUE)
run_case("admission-reordered", function(p) edit_record(p, installed, function(x) {
  x$resources <- rev(x$resources); x
}), admission = TRUE)
run_case("missing-resource", function(p) edit_record(p, installed, function(x) {
  x$resources <- x$resources[-3L]; x
}), "identities are incomplete", TRUE)
run_case("duplicate-resource", function(p) edit_record(p, installed, function(x) {
  x$resources[[5L]] <- x$resources[[3L]]; x
}), "identities are incomplete or duplicated", TRUE)
run_case("wrong-component-license", function(p) edit_record(p, admitted, function(x) {
  x$included_resources[[3L]]$license_spdx <- "MIT"; x
}), "records disagree: morpholex-en", TRUE)
run_case("unapproved-component", function(p) edit_record(p, admitted, function(x) {
  x$included_resources[[4L]]$release_approved <- FALSE; x
}), "records disagree: bnccoca-level6", TRUE)
run_case("excerpt-scope-drift", function(p) edit_record(p, admitted, function(x) {
  x$included_resources[[5L]]$content_scope <- "Complete database"; x
}), "records disagree: morphynet-en-example", TRUE)
run_case("admitted-member-drift", function(p) edit_record(p, admitted, function(x) {
  x$included_resources[[4L]]$package_members[[1L]]$bytes <- 1; x
}), "records disagree: bnccoca-level6", TRUE)
run_case("missing-data", function(p) unlink(file.path(p,
  "inst/extdata/bnccoca/ac81c7a6/bnccoca.rds")), "Required file is missing")
run_case("missing-license", function(p) unlink(file.path(p,
  "inst/licenses/morpholex/CC-BY-NC-SA-4.0.md")), "Required file is missing")
run_case("same-size-tamper", function(p) {
  path <- file.path(p, "inst/licenses/morphynet/CC-BY-SA-3.0.txt")
  bytes <- readBin(path, "raw", file.info(path)$size)
  bytes[[1L]] <- as.raw(bitwXor(as.integer(bytes[[1L]]), 1L)); writeBin(bytes, path)
}, "Source member SHA-256 differs")
run_case("stale-copyrights", function(p) edit_record(p, installed, function(x) {
  members <- x$resources[[1L]]$package_members
  i <- which(vapply(members, `[[`, character(1L), "path") == "COPYRIGHTS")
  x$resources[[1L]]$package_members[[i]]$bytes <- 1401; x
}), "Source member byte count differs")
run_case("undeclared-data", function(p) writeLines("extra", file.path(p,
  "inst/extdata/unlisted.txt")), "undeclared or missing extdata")
run_case("undeclared-license", function(p) writeLines("extra", file.path(p,
  "inst/licenses/unlisted.txt")), "undeclared or missing license")
run_case("duplicate-member", function(p) edit_record(p, installed, function(x) {
  x$resources[[3L]]$package_members[[2L]] <- x$resources[[3L]]$package_members[[1L]]; x
}), "duplicate paths")
run_case("invalid-member-path", function(p) edit_record(p, installed, function(x) {
  x$resources[[3L]]$package_members[[1L]]$path <- "../outside"; x
}), "not a normalized relative path")

# Exercise the actual record-generation expressions with local fixture values.
# These checks are not a clean-candidate generator run or cross-platform CI.
expressions <- parse(file.path(package_root, "experiments/release-candidate/generate-release-evidence.R"))
assignment <- function(name) which(vapply(expressions, function(x)
  is.call(x) && identical(x[[1L]], as.name("<-")) && identical(x[[2L]], as.name(name)), logical(1L)))
env <- new.env(parent = globalenv())
env$description <- read.dcf(file.path(package_root, "DESCRIPTION"))
env$package_extract <- env$package_root <- package_root
env$package_name <- "ldfreq"; env$package_version <- "0.2.0"
env$root_id <- "SPDXRef-Package-ldfreq"
env$check <- function(ok, message) if (!isTRUE(ok)) stop(message)
env$sha256_file <- function(path) digest::digest(file = path, algo = "sha256")
for (i in seq.int(assignment("root_license"), assignment("spdx_packages"))) eval(expressions[[i]], env)
env$commit <- paste(rep("0", 40), collapse = "")
env$archive_record <- list(sha256 = paste(rep("0", 64), collapse = ""))
env$created <- "2026-10-06T00:00:00Z"; env$relationships <- list()
eval(expressions[[assignment("dependency_sbom")]], env)
sbom <- env$dependency_sbom
stopifnot(identical(sbom$packages[[1L]]$licenseDeclared, "LicenseRef-ldfreq-component-terms"),
  identical(sbom$hasExtractedLicensingInfos[[1L]]$extractedText,
    paste(readLines(file.path(package_root, "LICENSE")), collapse = "\n")),
  grepl("CC BY-NC-SA 4.0", sbom$hasExtractedLicensingInfos[[1L]]$extractedText, fixed = TRUE))
cat("PASS: generated SPDX preserves source component terms\n")

for (i in seq.int(assignment("resource_manifest_path"), assignment("resource_bom"))) {
  eval(expressions[[i]], env)
}
stopifnot(length(env$resource_bom$installed_manifest$resources) == 5L,
  length(env$resource_bom$release_inventory$included_resources) == 5L,
  identical(env$resource_bom$admission_record$resource_id, "tubelex-en-treebank-slim"))
env$package_extract <- file.path(scratch, "missing-resource")
result <- tryCatch({
  for (i in seq.int(assignment("resource_manifest_path"), assignment("resource_bom"))) {
    eval(expressions[[i]], env)
  }
  NULL
}, error = conditionMessage)
stopifnot(is.character(result), grepl("manifest differs from the checkout", result, fixed = TRUE))
cat("PASS: resource BOM includes all admissions and rejects an older archive manifest\n")

# Exercise the production aggregation loop with explicitly synthetic OS records.
expressions <- parse(file.path(package_root, "experiments/release-candidate/assemble-run-index.R"))
loops <- Filter(function(x) is.call(x) && identical(x[[1L]], as.name("for")) &&
  any(grepl("inventory_record <-", deparse(x), fixed = TRUE)), as.list(expressions))
stopifnot(length(loops) == 1L)
ids <- vapply(read_json(file.path(package_root, installed))$resources, `[[`, character(1L), "resource_id")
env$expected_resource_ids <- ids; env$inventory_labels <- env$labels <- "fixture"
env$results <- list(list(environment = list(os = "fixture")))
env$provenance <- list(artifact = list(sha256 = "fixture"))
record <- list(status = "source-platform-installed-resource-inventory-ok",
  environment = env$results[[1L]]$environment,
  source_archive_origin = "provided-exact-release-candidate",
  comparison_authority = "provided-exact-source-archive",
  source_archive = env$provenance$artifact, installed_resource_count = length(ids),
  installed_resource_ids = unname(ids), undeclared_extdata_observed = FALSE)
env$inventories <- list(record); eval(loops[[1L]], env)
for (mutation in c("stale-count", "different-id")) {
  bad <- record
  if (mutation == "stale-count") bad$installed_resource_count <- 1L else
    bad$installed_resource_ids[[5L]] <- "wrong-resource"
  env$inventories <- list(bad)
  result <- tryCatch({eval(loops[[1L]], env); NULL}, error = conditionMessage)
  stopifnot(is.character(result), grepl("Resource boundary changed", result, fixed = TRUE))
}
cat("PASS: aggregation accepts five IDs and rejects count/identity drift\n")
cat(sprintf("Resource regressions OK: %d CLI cases and 3 release-record checks.\n", passed))
})
