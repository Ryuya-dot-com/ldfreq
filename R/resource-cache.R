# Reference downloads are explicit; readers only inspect the selected cache.
.lex_resource_cache <- function(cache_dir = NULL) {
  if (is.null(cache_dir)) cache_dir <- getOption("ldfreq.resource_dir",
    Sys.getenv("LDFREQ_RESOURCE_DIR", unset = tools::R_user_dir("ldfreq", "cache")))
  if (!is.character(cache_dir) || is.object(cache_dir) || !is.null(dim(cache_dir)) ||
      length(cache_dir) != 1L || is.na(cache_dir) || !nzchar(cache_dir))
    stop("cache_dir must be one plain, nonempty directory path.", call. = FALSE)
  path.expand(cache_dir)
}

.lex_resource_names <- function(resources) {
  if (!is.character(resources) || is.object(resources) || !is.null(dim(resources)) ||
      !length(resources) || anyNA(resources) || anyDuplicated(resources) ||
      any(!resources %in% names(.lex_resource_catalog)))
    stop("resources must contain unique names from lexdiv_resource_info()$resource.", call. = FALSE)
  unname(resources)
}

.lex_resource_verified <- function(path, hashes) {
  all(vapply(names(hashes), function(name) {
    file <- file.path(path, name)
    file.exists(file) && !dir.exists(file) &&
      identical(digest::digest(file = file, algo = "sha256"), hashes[[name]])
  }, logical(1L)))
}

lexdiv_resource_info <- function(
    resources = c("tubelex", "nj8", "morpholex", "bnccoca", "morphynet"), cache_dir = NULL) {
  resources <- .lex_resource_names(resources)
  cache_dir <- .lex_resource_cache(cache_dir)
  do.call(rbind, lapply(resources, function(name) {
    item <- .lex_resource_catalog[[name]]
    path <- file.path(cache_dir, name, item$version)
    data.frame(resource = name, version = item$version, license = item$license,
      license_url = item$license_url,
      notice_url = paste0("https://github.com/Ryuya-dot-com/ldfreq/blob/v0.4.0.9006/inst/licenses/", name, "/NOTICE.md"),
      download_bytes = item$bytes,
      available = .lex_resource_verified(path, item$files), path = path,
      url = item$url, sha256 = item$sha256, citation = item$citation,
      stringsAsFactors = FALSE)
  }))
}

lexdiv_download_resources <- function(resources, accept_license = FALSE, cache_dir = NULL) {
  resources <- .lex_resource_names(resources)
  cache_dir <- .lex_resource_cache(cache_dir)
  if (!identical(accept_license, TRUE))
    stop("Review lexdiv_resource_info(resources), including each license_url, then explicitly set accept_license = TRUE to download.", call. = FALSE)
  for (name in resources) {
    item <- .lex_resource_catalog[[name]]
    target <- file.path(cache_dir, name, item$version)
    if (.lex_resource_verified(target, item$files)) next
    if (file.exists(target))
      stop("The existing resource cache is incomplete or modified: ", target,
        ". Remove that version directory explicitly before downloading again.", call. = FALSE)
    parent <- dirname(target)
    if (!dir.exists(parent) && !dir.create(parent, recursive = TRUE))
      stop("Cannot create resource cache: ", parent, call. = FALSE)
    local({
      archive <- tempfile("download-", tmpdir = parent, fileext = ".tar.gz")
      stage <- tempfile("unpack-", tmpdir = parent)
      on.exit(unlink(c(archive, stage), recursive = TRUE), add = TRUE)
      status <- utils::download.file(item$url, archive, mode = "wb", quiet = TRUE)
      if (!identical(status, 0L) || !file.exists(archive) ||
          file.info(archive)$size != item$bytes ||
          !identical(digest::digest(file = archive, algo = "sha256"), item$sha256))
        stop("Downloaded resource does not match the pinned size and SHA-256: ", name, call. = FALSE)
      members <- utils::untar(archive, list = TRUE)
      if (anyDuplicated(members) || !setequal(members, names(item$files)))
        stop("Downloaded resource contains unexpected members: ", name, call. = FALSE)
      dir.create(stage)
      if (utils::untar(archive, exdir = stage) != 0L ||
          !.lex_resource_verified(stage, item$files))
        stop("Extracted resource failed verification: ", name, call. = FALSE)
      if (!file.rename(stage, target))
        stop("Cannot install the verified resource cache: ", target, call. = FALSE)
    })
  }
  invisible(lexdiv_resource_info(resources, cache_dir))
}

.lex_resource_file <- function(resource, ...) {
  item <- .lex_resource_catalog[[resource]]
  relative <- file.path(...)
  key <- gsub("\\\\", "/", relative)
  if (is.null(item) || !key %in% names(item$files))
    stop("Unknown resource file.", call. = FALSE)
  path <- file.path(.lex_resource_cache(), resource, item$version)
  if (!.lex_resource_verified(path, item$files[key]))
    stop("Reference data '" , resource, "' are unavailable or modified. Review lexdiv_resource_info('",
      resource, "') and its license, then run lexdiv_download_resources('", resource,
      "', accept_license = TRUE).", call. = FALSE)
  file.path(path, relative)
}
