#!/usr/bin/env Rscript

# Build and audit source, platform-packaged, and installed resource inventories.
# This is development evidence. Archive hashes identify one run and are not a
# claim that ordinary R package builds are reproducible.

arguments <- commandArgs(trailingOnly = TRUE)
if (length(arguments) != 2L) {
  stop(
    paste(
      "Usage: validate-package-resource-inventory.R",
      "/path/to/package /new/audit/directory"
    ),
    call. = FALSE
  )
}

package_root <- normalizePath(arguments[[1L]], mustWork = TRUE)
audit_root_requested <- arguments[[2L]]
if (file.exists(audit_root_requested) || dir.exists(audit_root_requested)) {
  stop("The audit directory must not already exist.", call. = FALSE)
}
if (!dir.create(audit_root_requested, recursive = TRUE, mode = "0755")) {
  stop("Could not create the audit directory.", call. = FALSE)
}
audit_root <- normalizePath(audit_root_requested, mustWork = TRUE)

if (!requireNamespace("digest", quietly = TRUE)) {
  stop("The audit requires the digest package.", call. = FALSE)
}
if (!requireNamespace("jsonlite", quietly = TRUE)) {
  stop("The audit requires the jsonlite package.", call. = FALSE)
}

assertions <- 0L
check <- function(condition, message) {
  assertions <<- assertions + 1L
  if (!isTRUE(condition)) stop(message, call. = FALSE)
}

slash_path <- function(path) gsub("\\\\", "/", path)

relative_files <- function(root) {
  if (!dir.exists(root)) return(character())
  paths <- list.files(
    root,
    all.files = TRUE,
    full.names = TRUE,
    recursive = TRUE,
    include.dirs = FALSE,
    no.. = TRUE
  )
  paths <- paths[vapply(paths, function(path) {
    isTRUE(utils::file_test("-f", path))
  }, logical(1L))]
  prefix <- paste0(normalizePath(root, mustWork = TRUE), .Platform$file.sep)
  output <- substring(normalizePath(paths, mustWork = TRUE), nchar(prefix) + 1L)
  sort(slash_path(output), method = "radix")
}

read_bytes <- function(path) {
  check(file.exists(path), sprintf("Required file is missing: %s", path))
  check(isTRUE(utils::file_test("-f", path)), sprintf(
    "Required member is not a regular file: %s", path
  ))
  link_target <- Sys.readlink(path)
  check(
    length(link_target) == 1L && (is.na(link_target) || !nzchar(link_target)),
    sprintf("Required member must not be a symlink: %s", path)
  )
  size <- unname(file.info(path)$size[[1L]])
  check(
    is.finite(size) && size >= 0 && size <= (.Machine$integer.max - 1),
    sprintf("Required member has an unsupported size: %s", path)
  )
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  bytes <- readBin(connection, what = "raw", n = as.integer(size) + 1L)
  check(identical(as.double(length(bytes)), as.double(size)), sprintf(
    "Required member changed while it was read: %s", path
  ))
  bytes
}

sha256_bytes <- function(bytes) {
  digest::digest(bytes, algo = "sha256", serialize = FALSE)
}

normalized_member <- function(path) {
  check(
    is.character(path) && length(path) == 1L && !is.na(path) && nzchar(path),
    "Inventory member paths must be non-empty strings."
  )
  parts <- strsplit(path, "/", fixed = TRUE)[[1L]]
  check(
    !startsWith(path, "/") &&
      !grepl("^[A-Za-z][A-Za-z0-9+.-]*:", path) &&
      !grepl("\\\\", path, fixed = TRUE) &&
      !endsWith(path, "/") &&
      !any(parts %in% c("", ".", "..")),
    sprintf("Inventory member is not a normalized relative path: %s", path)
  )
  path
}

description <- read.dcf(file.path(package_root, "DESCRIPTION"))
check(nrow(description) == 1L, "DESCRIPTION must contain one package record.")
package_name <- unname(description[[1L, "Package"]])
package_version <- unname(description[[1L, "Version"]])
check(
  grepl("^[A-Za-z][A-Za-z0-9.]*$", package_name),
  "Package name cannot be used as an archive root."
)
check(nzchar(package_version), "Package version is empty.")

inventory_source_path <- file.path(
  package_root, "inst", "spec", "ldfreq-resource-inventory.json"
)
schema_source_path <- file.path(
  package_root, "inst", "spec", "ldfreq-resource-inventory.schema.json"
)
inventory <- jsonlite::read_json(inventory_source_path, simplifyVector = FALSE)
inventory_schema <- jsonlite::read_json(schema_source_path, simplifyVector = FALSE)
check(
  identical(inventory$schema_version, "0.1.0") &&
    identical(inventory$policy$release_requires_independent_approval, TRUE),
  "Resource inventory policy changed."
)
check(
  identical(as.numeric(inventory$release_approved_resource_count), 0) &&
    length(inventory$included_resources) == 1L,
  "The development inventory must retain zero release-approved resources."
)
check(
  identical(inventory_schema$title, "ldfreq installed resource inventory") &&
    identical(inventory_schema$additionalProperties, FALSE),
  "Resource inventory schema changed unexpectedly."
)

inventory_members <- do.call(c, lapply(
  inventory$included_resources,
  function(resource) resource$package_members
))
check(length(inventory_members) > 0L, "No package members are declared.")
member_paths <- vapply(inventory_members, function(member) {
  normalized_member(member$path)
}, character(1L))
check(!anyDuplicated(member_paths), "Package inventory contains duplicate paths.")

source_member_bytes <- vector("list", length(member_paths))
names(source_member_bytes) <- member_paths
for (index in seq_along(member_paths)) {
  member <- inventory_members[[index]]
  path <- member_paths[[index]]
  check(
    identical(names(member), c("path", "bytes", "sha256")),
    sprintf("Inventory member fields changed: %s", path)
  )
  bytes <- read_bytes(file.path(package_root, "inst", path))
  check(
    identical(as.double(length(bytes)), as.double(member$bytes)),
    sprintf("Source member byte count differs from inventory: %s", path)
  )
  check(
    identical(sha256_bytes(bytes), member$sha256),
    sprintf("Source member SHA-256 differs from inventory: %s", path)
  )
  source_member_bytes[[index]] <- bytes
}

metadata_paths <- c(
  "spec/ldfreq-resource-inventory.json",
  "spec/ldfreq-resource-inventory.schema.json"
)
all_audited_paths <- c(member_paths, metadata_paths)
check(!anyDuplicated(all_audited_paths), "Audited package paths overlap.")
for (path in metadata_paths) {
  source_member_bytes[[path]] <- read_bytes(file.path(package_root, "inst", path))
}

expected_extdata <- sort(
  sub("^extdata/", "", member_paths[startsWith(member_paths, "extdata/")]),
  method = "radix"
)
check(length(expected_extdata) > 0L, "No extdata payload is declared.")
check(
  identical(
    relative_files(file.path(package_root, "inst", "extdata")),
    expected_extdata
  ),
  "The source tree contains undeclared or missing extdata payloads."
)

run_r_command <- function(arguments, working_directory, label) {
  old_directory <- setwd(working_directory)
  on.exit(setwd(old_directory), add = TRUE)
  status <- system2(file.path(R.home("bin"), "R"), args = arguments)
  check(
    identical(as.integer(status), 0L),
    sprintf("R CMD %s failed with status %s.", label, status)
  )
}

safe_archive_names <- function(names, label) {
  check(length(names) > 0L, sprintf("%s archive is empty.", label))
  for (name in names) {
    parts <- strsplit(slash_path(name), "/", fixed = TRUE)[[1L]]
    check(
      nzchar(name) &&
        !startsWith(slash_path(name), "/") &&
        !grepl("^[A-Za-z][A-Za-z0-9+.-]*:", name) &&
        !grepl("\\\\", name, fixed = TRUE) &&
        !any(parts %in% ".."),
      sprintf("%s archive contains an unsafe path: %s", label, name)
    )
  }
  invisible(names)
}

archive_names <- function(path, label) {
  if (grepl("[.]zip$", path, ignore.case = TRUE)) {
    names <- utils::unzip(path, list = TRUE)$Name
  } else {
    names <- utils::untar(path, list = TRUE)
  }
  safe_archive_names(names, label)
  names
}

extract_archive <- function(path, destination, label) {
  check(!file.exists(destination), sprintf(
    "%s extraction target already exists.", label
  ))
  check(dir.create(destination, mode = "0755"), sprintf(
    "Could not create %s extraction target.", label
  ))
  names <- archive_names(path, label)
  if (grepl("[.]zip$", path, ignore.case = TRUE)) {
    utils::unzip(path, exdir = destination)
  } else {
    utils::untar(path, exdir = destination)
  }
  check(
    dir.exists(file.path(destination, package_name)),
    sprintf("%s archive has an unexpected package root.", label)
  )
  names
}

source_work <- file.path(audit_root, "source-build")
check(dir.create(source_work, mode = "0755"), "Could not create source build directory.")
run_r_command(
  c("CMD", "build", shQuote(package_root)),
  source_work,
  "build"
)
source_archives <- list.files(
  source_work,
  pattern = paste0("^", package_name, "_.*[.]tar[.]gz$"),
  full.names = TRUE
)
check(length(source_archives) == 1L, "R CMD build did not create one source archive.")
source_archive <- source_archives[[1L]]
source_extract <- file.path(audit_root, "source-extracted")
source_archive_names <- extract_archive(source_archive, source_extract, "source")
check(
  !any(startsWith(source_archive_names, paste0(package_name, "/experiments/"))) &&
    !any(startsWith(source_archive_names, paste0(package_name, "/legal/"))),
  "Repository-only experiment or legal directories leaked into the source package."
)
source_package_root <- file.path(source_extract, package_name)

binary_work <- file.path(audit_root, "platform-build")
library_root <- file.path(audit_root, "library")
check(dir.create(binary_work, mode = "0755"), "Could not create platform build directory.")
check(dir.create(library_root, mode = "0755"), "Could not create audit library.")
run_r_command(
  c(
    "CMD", "INSTALL", "--build",
    shQuote(paste0("--library=", library_root)),
    shQuote(source_archive)
  ),
  binary_work,
  "INSTALL --build"
)
platform_archives <- list.files(
  binary_work,
  pattern = paste0("^", package_name, "_.*([.]zip|[.]tgz|[.]tar[.]gz)$"),
  full.names = TRUE
)
check(
  length(platform_archives) == 1L,
  "R CMD INSTALL --build did not create one platform package archive."
)
platform_archive <- platform_archives[[1L]]
platform_extract <- file.path(audit_root, "platform-extracted")
platform_archive_names <- extract_archive(
  platform_archive,
  platform_extract,
  "platform"
)
check(
  !any(startsWith(platform_archive_names, paste0(package_name, "/experiments/"))) &&
    !any(startsWith(platform_archive_names, paste0(package_name, "/legal/"))),
  "Repository-only experiment or legal directories leaked into the platform package."
)
platform_package_root <- file.path(platform_extract, package_name)
installed_package_root <- file.path(library_root, package_name)
check(dir.exists(installed_package_root), "The package was not installed in the audit library.")

layer_roots <- list(
  source_archive = file.path(source_package_root, "inst"),
  platform_archive = platform_package_root,
  installed_library = installed_package_root
)
for (layer_name in names(layer_roots)) {
  root <- layer_roots[[layer_name]]
  for (path in all_audited_paths) {
    observed <- read_bytes(file.path(root, path))
    check(
      identical(observed, source_member_bytes[[path]]),
      sprintf("%s member differs from the source tree: %s", layer_name, path)
    )
  }
  check(
    identical(relative_files(file.path(root, "extdata")), expected_extdata),
    sprintf("%s contains undeclared or missing extdata payloads.", layer_name)
  )
}

archive_record <- function(path) {
  bytes <- read_bytes(path)
  list(
    file = basename(path),
    bytes = as.numeric(length(bytes)),
    sha256 = sha256_bytes(bytes)
  )
}

member_records <- lapply(all_audited_paths, function(path) {
  bytes <- source_member_bytes[[path]]
  list(
    path = path,
    bytes = as.numeric(length(bytes)),
    sha256 = sha256_bytes(bytes)
  )
})

evidence <- list(
  schema_version = "0.1.0-development-evidence",
  status = "source-platform-installed-resource-inventory-ok",
  package = package_name,
  package_version = package_version,
  environment = list(
    os = unname(Sys.info()[["sysname"]]),
    platform = R.version$platform,
    r_version = R.version.string
  ),
  archive_hash_scope = paste(
    "Run identity only; ordinary R package archive hashes are not a",
    "reproducible-build claim."
  ),
  source_archive = archive_record(source_archive),
  platform_archive = archive_record(platform_archive),
  audited_members = member_records,
  extdata_members = expected_extdata,
  release_approved_resource_count = 0,
  undeclared_extdata_observed = FALSE,
  assertions = assertions
)
evidence_path <- file.path(audit_root, "package-resource-inventory-evidence.json")
jsonlite::write_json(
  evidence,
  evidence_path,
  auto_unbox = TRUE,
  pretty = TRUE,
  null = "null"
)

message(sprintf(
  paste(
    "Package resource inventory OK: %d assertions; %d members;",
    "source archive, platform archive, and installed library are byte-identical;",
    "evidence: %s"
  ),
  assertions,
  length(all_audited_paths),
  evidence_path
))
