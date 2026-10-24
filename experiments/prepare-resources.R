#!/usr/bin/env Rscript
# Explicit maintainer/CI setup; never called by package installation or tests.
args <- commandArgs(TRUE)
if(length(args)!=2L || !identical(args[[2]],"--accept-license"))
  stop("Usage: Rscript experiments/prepare-resources.R cache-directory --accept-license; first review the separate resource terms.")
e <- new.env(parent=globalenv())
sys.source("R/resource-catalog.R",e);sys.source("R/resource-cache.R",e)
e$lexdiv_download_resources(names(e$.lex_resource_catalog),accept_license=TRUE,cache_dir=args[[1]])
cat("Verified optional resources in",normalizePath(args[[1]],winslash="/"),"\n")
if(nzchar(Sys.getenv("GITHUB_ENV"))) cat(paste0("LDFREQ_RESOURCE_DIR=",
  normalizePath(args[[1]],winslash="/"),"\n"),file=Sys.getenv("GITHUB_ENV"),append=TRUE)
