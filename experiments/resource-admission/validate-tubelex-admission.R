#!/usr/bin/env Rscript
# Validate separately downloadable data identities and the installed catalog.
args <- commandArgs(TRUE)
root <- normalizePath(if(length(args)) args[[1]] else ".",mustWork=TRUE)
read <- function(path) jsonlite::read_json(file.path(root,path),simplifyVector=FALSE)
m <- read("inst/spec/ldfreq-installed-resource-manifest.json")
r <- read("experiments/resource-admission/ldfreq-release-resource-inventory.json")
e <- new.env(parent=baseenv()); sys.source(file.path(root,"R/resource-catalog.R"),e)
cat <- e$.lex_resource_catalog
check <- function(ok,message) if(!isTRUE(ok)) stop(message,call.=FALSE)
check(identical(m$schema_version,"2.0.0") &&
  identical(m$package_scope,"optional-reference-resources") &&
  identical(m$runtime_policy$network_access,FALSE) &&
  identical(m$runtime_policy$implicit_download_or_fallback,FALSE) &&
  identical(m$runtime_policy$explicit_download_api,"lexdiv_download_resources"),
  "Optional resource boundary changed.")
ids <- vapply(m$resources,`[[`,character(1),"resource_id")
expected <- c("tubelex-en-treebank-slim","new-jacet8000","morpholex-en","bnccoca-level6","morphynet-en-example")
check(!anyDuplicated(ids)&&setequal(ids,expected),"Resource identities are incomplete or duplicated.")
release_ids <- vapply(r$optional_resources,`[[`,character(1),"resource_id")
check(!anyDuplicated(release_ids)&&setequal(ids,release_ids),"Release resource identities are incomplete or duplicated.")
for(resource in m$resources) {
  other <- r$optional_resources[[match(resource$resource_id,release_ids)]]
  check(identical(resource,other),paste("Resource records disagree:",resource$resource_id))
  check(identical(resource$distribution,"explicit-download")&&
    identical(resource$runtime_state,"optional")&&!resource$raw_source_bundled,
    "Reference data must be optional, separate downloads.")
  item <- cat[[resource$resource_name]]
  # JSON numbers/lists and R catalog integers/vectors differ only in representation.
  check(isTRUE(all.equal(resource$download,item,check.attributes=FALSE)),
    paste("Download catalog disagrees:",resource$resource_id))
  files <- names(item$files)
  check(length(files)>0L&&!anyDuplicated(files)&&
    all(!grepl("(^/|^[A-Za-z]:|\\\\|(^|/)\\.\\.(/|$))",files))&&
    all(grepl("^[0-9a-f]{64}$",unlist(item$files))),"Unsafe or invalid download members.")
  check(grepl("^https://github.com/Ryuya-dot-com/ldfreq/releases/download/reference-data-20261024/",item$url)&&
    grepl("^[0-9a-f]{64}$",item$sha256)&&is.numeric(item$bytes)&&item$bytes>0,
    "Invalid fixed download identity.")
}
cat(jsonlite::toJSON(list(status="optional-resource-catalog-ok",admission_gate_passed=TRUE,
  optional_resources=length(ids),third_party_data_bundled=FALSE),auto_unbox=TRUE,pretty=TRUE),"\n")
