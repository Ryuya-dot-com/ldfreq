#!/usr/bin/env Rscript

# Repository-only public API integration audit. This intentionally uses only
# base/recommended R so it can run before the package is built or installed.

arguments <- commandArgs(trailingOnly = TRUE)
if (length(arguments) > 1L) {
  stop("Usage: audit-public-api.R [package-root]", call. = FALSE)
}
package_root <- normalizePath(
  if (length(arguments)) arguments[[1L]] else ".",
  mustWork = TRUE
)

fail <- function(format, ...) {
  stop(sprintf(format, ...), call. = FALSE)
}

read_required <- function(path) {
  full_path <- file.path(package_root, path)
  if (!file.exists(full_path)) fail("Required file is missing: %s", path)
  readLines(full_path, warn = FALSE, encoding = "UTF-8")
}

rbuildignore <- read_required(".Rbuildignore")
if (!"^docs$" %in% rbuildignore) {
  fail(".Rbuildignore must exclude locally rendered pkgdown output with ^docs$.")
}

namespace <- read_required("NAMESPACE")
exports <- sub(
  "^export\\(([^)]+)\\)$",
  "\\1",
  grep("^export\\([^)]+\\)$", namespace, value = TRUE)
)
s3_lines <- grep(
  "^S3method\\([^,]+,[^)]+\\)$",
  namespace,
  value = TRUE
)
s3_methods <- sub(
  "^S3method\\(([^,]+),([^)]+)\\)$",
  "\\1.\\2",
  s3_lines
)
if (!length(exports)) fail("NAMESPACE contains no exports.")
if (anyDuplicated(exports)) fail("NAMESPACE contains duplicate exports.")
if (anyDuplicated(s3_methods)) fail("NAMESPACE contains duplicate S3 registrations.")

rd_files <- list.files(
  file.path(package_root, "man"),
  pattern = "[.]Rd$",
  full.names = TRUE
)
if (!length(rd_files)) fail("No Rd files were found under man/.")

rd_tags <- function(object) {
  vapply(object, function(element) {
    tag <- attr(element, "Rd_tag")
    if (is.null(tag)) "" else tag
  }, character(1L))
}

rd <- setNames(lapply(rd_files, tools::parse_Rd), basename(rd_files))
alias_to_topic <- character()
topic_has_value <- logical()
topic_has_examples <- logical()
for (topic in names(rd)) {
  object <- rd[[topic]]
  tags <- rd_tags(object)
  aliases <- vapply(
    object[tags == "\\alias"],
    function(element) paste(element, collapse = ""),
    character(1L)
  )
  if (anyDuplicated(aliases)) fail("Rd topic %s repeats an alias.", topic)
  overlap <- intersect(names(alias_to_topic), aliases)
  if (length(overlap)) {
    fail("Rd alias occurs in more than one topic: %s", paste(overlap, collapse = ", "))
  }
  alias_to_topic[aliases] <- topic
  topic_has_value[[topic]] <- any(tags == "\\value")
  topic_has_examples[[topic]] <- any(tags == "\\examples")
}

missing_export_aliases <- setdiff(exports, names(alias_to_topic))
if (length(missing_export_aliases)) {
  fail(
    "Exported functions without installed help aliases: %s",
    paste(missing_export_aliases, collapse = ", ")
  )
}
missing_s3_aliases <- setdiff(s3_methods, names(alias_to_topic))
if (length(missing_s3_aliases)) {
  fail(
    "Registered S3 methods without installed help aliases: %s",
    paste(missing_s3_aliases, collapse = ", ")
  )
}

export_topics <- unname(alias_to_topic[exports])
without_value <- unique(export_topics[!topic_has_value[export_topics]])
without_examples <- unique(export_topics[!topic_has_examples[export_topics]])
if (length(without_value)) {
  fail("Export help topics without a value section: %s", paste(without_value, collapse = ", "))
}
if (length(without_examples)) {
  fail("Export help topics without examples: %s", paste(without_examples, collapse = ", "))
}

surface <- read_required(file.path("development", "API-SURFACE.md"))
surface_matches <- regexec("^\\| `([a-z][a-z0-9_]+)\\(\\)` \\|", surface)
surface_rows <- regmatches(surface, surface_matches)
surface_exports <- vapply(
  surface_rows[lengths(surface_rows) == 2L],
  `[[`,
  character(1L),
  2L
)
if (!setequal(exports, surface_exports)) {
  fail(
    paste0(
      "API-SURFACE.md export inventory differs from NAMESPACE. ",
      "Only in NAMESPACE: %s. Only in inventory: %s."
    ),
    paste(setdiff(exports, surface_exports), collapse = ", "),
    paste(setdiff(surface_exports, exports), collapse = ", ")
  )
}

pkgdown <- read_required("_pkgdown.yml")
pkgdown_matches <- regexec("^[[:space:]]+-[[:space:]]+([A-Za-z0-9_.-]+)[[:space:]]*$", pkgdown)
pkgdown_rows <- regmatches(pkgdown, pkgdown_matches)
pkgdown_topics <- vapply(
  pkgdown_rows[lengths(pkgdown_rows) == 2L],
  `[[`,
  character(1L),
  2L
)
required_topics <- unique(sub("[.]Rd$", "", c(
  alias_to_topic[exports],
  alias_to_topic[s3_methods]
)))
missing_pkgdown_topics <- setdiff(required_topics, pkgdown_topics)
if (length(missing_pkgdown_topics)) {
  fail(
    "Documented public API topics absent from _pkgdown.yml: %s",
    paste(missing_pkgdown_topics, collapse = ", ")
  )
}

discarding_generics <- grep(
  "^S3method\\((summary|as[.]data[.]frame),",
  namespace,
  value = TRUE
)
if (length(discarding_generics)) {
  fail(
    "Composite-table policy forbids implicit summary/as.data.frame registrations: %s",
    paste(discarding_generics, collapse = ", ")
  )
}

retired_names <- c(
  "new_jacet8000_profile", "new_jacet8000_profile_batch",
  "tubelex_frequency_profile", "lexdiv_overlap_measure_ids"
)
public_paths <- c(
  "DESCRIPTION", "NAMESPACE", "NEWS.md", "README.md", "R", "man",
  file.path("inst", "examples"), file.path("inst", "spec"), "vignettes"
)
public_files <- unlist(lapply(public_paths, function(path) {
  full_path <- file.path(package_root, path)
  if (dir.exists(full_path)) {
    list.files(full_path, recursive = TRUE, full.names = TRUE)
  } else if (file.exists(full_path)) {
    full_path
  } else {
    character()
  }
}), use.names = FALSE)
public_files <- public_files[!dir.exists(public_files)]
for (retired in retired_names) {
  hits <- vapply(public_files, function(path) {
    any(grepl(retired, readLines(path, warn = FALSE), fixed = TRUE))
  }, logical(1L))
  if (any(hits)) {
    relative <- substring(public_files[hits], nchar(package_root) + 2L)
    fail(
      "Retired public name %s remains in: %s",
      retired,
      paste(relative, collapse = ", ")
    )
  }
}

cat(sprintf(
  paste0(
    "Public API audit OK: %d exports, %d registered S3 methods, ",
    "%d documented public topics; inventory, pkgdown, examples, and ",
    "non-discarding composite policy agree.\n"
  ),
  length(exports),
  length(s3_methods),
  length(required_topics)
))
