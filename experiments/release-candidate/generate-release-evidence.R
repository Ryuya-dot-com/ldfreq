#!/usr/bin/env Rscript

arguments <- commandArgs(trailingOnly = TRUE)
if (length(arguments) != 4L) {
  stop(
    paste(
      "Usage: generate-release-evidence.R",
      "/path/to/package /path/to/source.tar.gz /path/to/manual.pdf",
      "/new/evidence/directory"
    ),
    call. = FALSE
  )
}

if (!requireNamespace("digest", quietly = TRUE)) {
  stop("The release evidence generator requires digest.", call. = FALSE)
}
if (!requireNamespace("jsonlite", quietly = TRUE)) {
  stop("The release evidence generator requires jsonlite.", call. = FALSE)
}

package_root <- normalizePath(arguments[[1L]], mustWork = TRUE)
source_archive <- normalizePath(arguments[[2L]], mustWork = TRUE)
manual_pdf <- normalizePath(arguments[[3L]], mustWork = TRUE)
output_requested <- arguments[[4L]]
if (file.exists(output_requested) || dir.exists(output_requested)) {
  stop("The evidence directory must not already exist.", call. = FALSE)
}
if (!dir.create(output_requested, recursive = TRUE, mode = "0755")) {
  stop("Could not create the evidence directory.", call. = FALSE)
}
output_root <- normalizePath(output_requested, mustWork = TRUE)

check <- function(condition, message) {
  if (!isTRUE(condition)) stop(message, call. = FALSE)
}

sha256_file <- function(path) {
  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}

file_record <- function(path) {
  info <- file.info(path)
  check(nrow(info) == 1L && !is.na(info$size), paste("Cannot stat", path))
  list(
    file = basename(path),
    bytes = as.numeric(info$size[[1L]]),
    sha256 = sha256_file(path)
  )
}

write_json <- function(value, path) {
  jsonlite::write_json(
    value,
    path,
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null",
    digits = NA
  )
}

git_value <- function(args) {
  old <- setwd(package_root)
  on.exit(setwd(old), add = TRUE)
  value <- system2("git", args = args, stdout = TRUE, stderr = TRUE)
  status <- attr(value, "status")
  check(is.null(status) || identical(status, 0L), paste(value, collapse = "\n"))
  check(length(value) == 1L && nzchar(value), paste("git", paste(args, collapse = " "), "returned no value"))
  unname(value[[1L]])
}

git_lines <- function(args) {
  old <- setwd(package_root)
  on.exit(setwd(old), add = TRUE)
  value <- system2("git", args = args, stdout = TRUE, stderr = TRUE)
  status <- attr(value, "status")
  check(is.null(status) || identical(status, 0L), paste(value, collapse = "\n"))
  unname(value)
}

description <- read.dcf(file.path(package_root, "DESCRIPTION"))
check(nrow(description) == 1L, "DESCRIPTION must contain one package record.")
package_name <- unname(description[[1L, "Package"]])
package_version <- unname(description[[1L, "Version"]])
check(!grepl("[.]9000$", package_version), "A development version cannot be a release candidate.")
expected_archive <- sprintf("%s_%s.tar.gz", package_name, package_version)
expected_manual <- sprintf("%s_%s.pdf", package_name, package_version)
check(identical(basename(source_archive), expected_archive), "The source archive name does not match DESCRIPTION.")
check(identical(basename(manual_pdf), expected_manual), "The manual name does not match DESCRIPTION.")

status_lines <- git_lines(c("status", "--porcelain=v1", "--untracked-files=all"))
check(length(status_lines) == 0L, "Release evidence must be generated from a clean checkout.")
commit <- git_value(c("rev-parse", "HEAD"))
tree <- git_value(c("rev-parse", "HEAD^{tree}"))
declared_commit <- Sys.getenv("CANDIDATE_COMMIT", unset = "")
if (nzchar(declared_commit)) {
  check(identical(commit, declared_commit), "CANDIDATE_COMMIT does not match checkout HEAD.")
}
repository_url <- git_value(c("remote", "get-url", "origin"))
branch <- Sys.getenv("GITHUB_REF_NAME", unset = "")

archive_names <- utils::untar(source_archive, list = TRUE)
check(length(archive_names) > 0L, "The source archive is empty.")
archive_names <- gsub("\\\\", "/", archive_names)
for (name in archive_names) {
  parts <- strsplit(name, "/", fixed = TRUE)[[1L]]
  check(
    nzchar(name) && !startsWith(name, "/") &&
      !grepl("^[A-Za-z][A-Za-z0-9+.-]*:", name) &&
      !any(parts %in% c("", ".", "..")),
    paste("Unsafe archive path:", name)
  )
  check(identical(parts[[1L]], package_name), paste("Unexpected archive root:", name))
}

forbidden_members <- c(
  "^\\.git($|/)", "^\\.github($|/)", "^experiments($|/)",
  "^legal($|/)", "^RELEASE-CANDIDATE[.]md$", "^RELEASE-CHECKLIST[.]md$",
  "^DEVELOPMENT[.]md$", "^CONTRIBUTING[.]md$", "^tools($|/)"
)
relative_archive_names <- sub(paste0("^", package_name, "/?"), "", archive_names)
for (pattern in forbidden_members) {
  check(!any(grepl(pattern, relative_archive_names)), paste("Repository-only member leaked into archive:", pattern))
}

extract_root <- tempfile("ldfreq-release-extract-")
check(dir.create(extract_root, mode = "0755"), "Could not create extraction directory.")
on.exit(unlink(extract_root, recursive = TRUE, force = TRUE), add = TRUE)
utils::untar(source_archive, exdir = extract_root)
package_extract <- file.path(extract_root, package_name)
check(dir.exists(package_extract), "The expected package root was not extracted.")

all_paths <- list.files(
  package_extract,
  all.files = TRUE,
  full.names = TRUE,
  recursive = TRUE,
  include.dirs = FALSE,
  no.. = TRUE
)
all_paths <- all_paths[vapply(all_paths, function(path) {
  isTRUE(utils::file_test("-f", path))
}, logical(1L))]
prefix <- paste0(normalizePath(package_extract, mustWork = TRUE), .Platform$file.sep)
relative_paths <- gsub("\\\\", "/", substring(normalizePath(all_paths), nchar(prefix) + 1L))
ordering <- order(relative_paths, method = "radix")
all_paths <- all_paths[ordering]
relative_paths <- relative_paths[ordering]

text_extensions <- "[.](R|Rd|Rmd|md|dcf|json|ya?ml|txt|csv)$"
scan_patterns <- c(
  "Codex", "OpenAI", "INTERNAL-ROADMAP", "W[0-9]+-REVIEW",
  "/Users/", "[A-Za-z]:\\\\Users\\\\"
)
scan_findings <- list()
for (index in seq_along(all_paths)) {
  size <- file.info(all_paths[[index]])$size[[1L]]
  if (!grepl(text_extensions, relative_paths[[index]], ignore.case = TRUE) ||
      is.na(size) || size > 1048576) next
  lines <- readLines(all_paths[[index]], warn = FALSE, encoding = "UTF-8")
  for (pattern in scan_patterns) {
    hits <- grep(pattern, lines, perl = TRUE)
    if (length(hits)) {
      scan_findings[[length(scan_findings) + 1L]] <- list(
        path = relative_paths[[index]],
        pattern = pattern,
        lines = as.integer(hits)
      )
    }
  }
}
check(length(scan_findings) == 0L, "Internal workflow or local-environment wording was found in the archive.")

package_files <- lapply(seq_along(all_paths), function(index) {
  info <- file.info(all_paths[[index]])
  list(
    path = relative_paths[[index]],
    bytes = as.numeric(info$size[[1L]]),
    sha256 = sha256_file(all_paths[[index]])
  )
})
archive_record <- file_record(source_archive)
manual_record <- file_record(manual_pdf)
package_bom <- list(
  schema_version = "1.0.0",
  bom_type = "R-source-package-file-bom",
  package = package_name,
  version = package_version,
  candidate_commit = commit,
  artifact = archive_record,
  file_count = length(package_files),
  files = package_files
)
package_bom_path <- file.path(output_root, "package-file-bom.json")
write_json(package_bom, package_bom_path)

split_dependency_entries <- function(value) {
  if (length(value) == 0L || is.na(value) || !nzchar(value)) {
    return(data.frame(
      package = character(), requirement = character(),
      stringsAsFactors = FALSE
    ))
  }
  requirements <- trimws(strsplit(value, ",", fixed = TRUE)[[1L]])
  packages <- trimws(sub("[[:space:]]*\\(.*$", "", requirements))
  keep <- nzchar(packages)
  data.frame(
    package = packages[keep],
    requirement = requirements[keep],
    stringsAsFactors = FALSE
  )
}

split_dependencies <- function(value) {
  split_dependency_entries(value)$package
}

dependency_fields <- c("Depends", "Imports", "LinkingTo", "Suggests", "Enhances")
direct <- do.call(rbind, lapply(dependency_fields, function(field) {
  value <- if (field %in% colnames(description)) description[[1L, field]] else NA_character_
  entries <- split_dependency_entries(value)
  if (!nrow(entries)) return(NULL)
  data.frame(
    package = entries$package,
    scope = field,
    requirement = entries$requirement,
    stringsAsFactors = FALSE
  )
}))
if (is.null(direct)) {
  direct <- data.frame(
    package = character(), scope = character(), requirement = character(),
    stringsAsFactors = FALSE
  )
}

installed <- utils::installed.packages(noCache = TRUE)
installed_names <- rownames(installed)
required_names <- unique(direct$package[direct$package != "R"])
missing_names <- setdiff(required_names, installed_names)
check(!length(missing_names), paste("Direct dependencies are not installed:", paste(missing_names, collapse = ", ")))

queue <- required_names
resolved <- character()
edges <- list()
while (length(queue)) {
  current <- queue[[1L]]
  queue <- queue[-1L]
  if (current %in% resolved) next
  resolved <- c(resolved, current)
  row <- installed[current, , drop = FALSE]
  hard_fields <- intersect(c("Depends", "Imports", "LinkingTo"), colnames(row))
  child_names <- unique(unlist(lapply(hard_fields, function(field) {
    split_dependencies(row[[1L, field]])
  }), use.names = FALSE))
  child_names <- setdiff(child_names, c("R", current))
  missing_children <- setdiff(child_names, installed_names)
  check(!length(missing_children), paste("Transitive dependencies are not installed:", paste(missing_children, collapse = ", ")))
  for (child in child_names) {
    edges[[length(edges) + 1L]] <- c(current, child)
  }
  queue <- unique(c(queue, setdiff(child_names, resolved)))
}
resolved <- sort(unique(resolved), method = "radix")

spdx_id <- function(name) paste0("SPDXRef-Package-", gsub("[^A-Za-z0-9.-]", "-", name))
root_id <- spdx_id(package_name)
root_license <- unname(description[[1L, "License"]])
check(
  identical(root_license, "MIT + file LICENSE"),
  "The release-evidence SPDX declaration must be reviewed for a changed package license."
)
spdx_packages <- list(list(
  name = package_name,
  SPDXID = root_id,
  versionInfo = package_version,
  downloadLocation = "NOASSERTION",
  filesAnalyzed = FALSE,
  licenseConcluded = "NOASSERTION",
  licenseDeclared = "MIT",
  comment = paste("Source package DESCRIPTION license field:", root_license)
))
r_requirement <- direct$requirement[direct$package == "R"]
check(length(r_requirement) == 1L, "DESCRIPTION must declare exactly one R requirement.")
r_id <- spdx_id("R")
spdx_packages[[length(spdx_packages) + 1L]] <- list(
  name = "R",
  SPDXID = r_id,
  versionInfo = as.character(getRversion()),
  downloadLocation = "https://www.r-project.org/",
  filesAnalyzed = FALSE,
  licenseConcluded = "NOASSERTION",
  licenseDeclared = "NOASSERTION",
  comment = paste(
    "Build-source runner R version; DESCRIPTION requirement:",
    r_requirement[[1L]]
  )
)
for (name in resolved) {
  row <- installed[name, , drop = FALSE]
  raw_license <- if ("License" %in% colnames(row)) row[[1L, "License"]] else NA_character_
  spdx_packages[[length(spdx_packages) + 1L]] <- list(
    name = name,
    SPDXID = spdx_id(name),
    versionInfo = unname(row[[1L, "Version"]]),
    downloadLocation = "NOASSERTION",
    filesAnalyzed = FALSE,
    licenseConcluded = "NOASSERTION",
    licenseDeclared = "NOASSERTION",
    comment = if (is.na(raw_license)) "Installed DESCRIPTION has no License field." else paste("Installed DESCRIPTION license field:", raw_license)
  )
}

relationships <- list(list(
  spdxElementId = "SPDXRef-DOCUMENT",
  relationshipType = "DESCRIBES",
  relatedSpdxElement = root_id
))
for (index in seq_len(nrow(direct))) {
  relationships[[length(relationships) + 1L]] <- list(
    spdxElementId = root_id,
    relationshipType = "DEPENDS_ON",
    relatedSpdxElement = spdx_id(direct$package[[index]]),
    comment = paste(
      "DESCRIPTION", direct$scope[[index]], "requirement:",
      direct$requirement[[index]]
    )
  )
}
for (edge in edges) {
  relationships[[length(relationships) + 1L]] <- list(
    spdxElementId = spdx_id(edge[[1L]]),
    relationshipType = "DEPENDS_ON",
    relatedSpdxElement = spdx_id(edge[[2L]])
  )
}

created <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
dependency_sbom <- list(
  spdxVersion = "SPDX-2.3",
  dataLicense = "CC0-1.0",
  SPDXID = "SPDXRef-DOCUMENT",
  name = paste0(package_name, "-", package_version, "-dependency-sbom"),
  documentNamespace = paste0(
    "https://github.com/Ryuya-dot-com/ldfreq/release-evidence/",
    commit, "/", archive_record$sha256
  ),
  comment = paste(
    "Dependency inventory from the release-R build-source runner.",
    "The five check environments remain separately recorded in their raw logs",
    "and check-result records; this document does not claim a cross-platform lockfile."
  ),
  creationInfo = list(
    created = created,
    creators = list("Tool: ldfreq-generate-release-evidence-1.1.0")
  ),
  packages = spdx_packages,
  relationships = relationships
)
dependency_sbom_path <- file.path(output_root, "dependency-sbom.spdx.json")
write_json(dependency_sbom, dependency_sbom_path)
written_sbom <- jsonlite::read_json(
  dependency_sbom_path,
  simplifyVector = FALSE
)
check(
  is.list(written_sbom$creationInfo$creators) &&
    length(written_sbom$creationInfo$creators) == 1L,
  "SPDX creationInfo.creators must serialize as an array."
)
written_package_names <- vapply(
  written_sbom$packages,
  function(value) value$name,
  character(1L)
)
check(
  all(c(package_name, "R") %in% written_package_names),
  "The SPDX document omitted the package or R runtime."
)
written_root <- written_sbom$packages[[match(package_name, written_package_names)]]
check(
  identical(written_root$licenseDeclared, "MIT"),
  "The SPDX package license declaration changed."
)
written_r_relationships <- Filter(function(value) {
  identical(value$spdxElementId, root_id) &&
    identical(value$relationshipType, "DEPENDS_ON") &&
    identical(value$relatedSpdxElement, r_id)
}, written_sbom$relationships)
check(
  length(written_r_relationships) == 1L &&
    grepl("R \\(>= 4[.]1[.]0\\)$", written_r_relationships[[1L]]$comment),
  "The SPDX document omitted or changed the DESCRIPTION R constraint."
)

resource_inventory_path <- file.path(
  package_extract, "inst", "spec", "ldfreq-resource-inventory.json"
)
check(file.exists(resource_inventory_path), "The source package has no resource inventory.")
resource_inventory <- jsonlite::read_json(resource_inventory_path, simplifyVector = FALSE)
resource_bom <- list(
  schema_version = "1.0.0",
  bom_type = "ldfreq-resource-bom",
  package = package_name,
  version = package_version,
  candidate_commit = commit,
  artifact_sha256 = archive_record$sha256,
  inventory_file = "inst/spec/ldfreq-resource-inventory.json",
  inventory_sha256 = sha256_file(resource_inventory_path),
  inventory = resource_inventory
)
resource_bom_path <- file.path(output_root, "resource-bom.json")
write_json(resource_bom, resource_bom_path)

evidence_records <- list(
  package_file_bom = file_record(package_bom_path),
  dependency_sbom = file_record(dependency_sbom_path),
  resource_bom = file_record(resource_bom_path)
)
provenance <- list(
  schema_version = "1.0.0",
  status = "technical-evidence-generated",
  repository = list(url = repository_url, branch = if (nzchar(branch)) branch else NULL),
  candidate = list(commit = commit, tree = tree, package = package_name, version = package_version),
  artifact = archive_record,
  manual = manual_record,
  environment = list(
    generated_at_utc = created,
    os = unname(Sys.info()[["sysname"]]),
    platform = R.version$platform,
    r_version = R.version.string,
    github_run_id = if (nzchar(Sys.getenv("GITHUB_RUN_ID"))) Sys.getenv("GITHUB_RUN_ID") else NULL,
    github_run_attempt = if (nzchar(Sys.getenv("GITHUB_RUN_ATTEMPT"))) Sys.getenv("GITHUB_RUN_ATTEMPT") else NULL
  ),
  evidence = evidence_records,
  resource_boundary = list(
    release_approved_resource_count = resource_inventory$release_approved_resource_count,
    public_resource_api_candidate = TRUE,
    candidate_resources_are_not_release_admitted = TRUE
  ),
  go_no_go = list(
    decision = "PENDING_INDEPENDENT_REVIEW",
    reviewer = NULL,
    reviewed_on = NULL,
    known_limitations = c(
      "Raw-text preprocessing is a separately versioned development API.",
      paste(
        "Maas and MTLD comparisons are a separately contracted sensitivity",
        "API, not official TAALED compatibility."
      ),
      "The public TUBELEX profile and bundled resource are not release-approved.",
      "Ordinary R package archive hashes identify the tested artifact but do not establish reproducible builds."
    ),
    rollback = paste(
      "Before publication, do not create a tag or release asset and revert or",
      "supersede the candidate through a reviewed pull request."
    )
  )
)
provenance_path <- file.path(output_root, "release-provenance.json")
write_json(provenance, provenance_path)

message(sprintf(
  "Release evidence generated for %s at %s (%d package files).",
  archive_record$file,
  commit,
  length(package_files)
))
