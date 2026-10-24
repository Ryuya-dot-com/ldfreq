# Rscript experiments/corpus-stability/compute.R package-root private-cache
args <- commandArgs(TRUE); stopifnot(length(args) == 2L)
root <- normalizePath(args[[1]]); cache <- normalizePath(args[[2]])
pkgload::load_all(root, quiet = TRUE)
x <- readRDS(file.path(cache, "prepared-private.rds"))
metrics <- setdiff(lexdiv_metric_ids(), "expected_ttr_d")
source_files <- c("api.R", "metric-mtld.R", "metric-basic.R", "metric-hdd.R", "metric-yule.R")
source_files <- unique(c(source_files[file.exists(file.path(root, "R", source_files))],
  list.files(file.path(root, "R"), "^metric-.*[.]R$")))
identity <- list(inputs = x$input_sha256, preparation = digest::digest(
  file = file.path(root,"experiments/corpus-stability/prepare.R"), algo = "sha256"),
  source = setNames(vapply(file.path(root,"R",source_files), function(f)
    digest::digest(file=f,algo="sha256"), character(1)), source_files),
  protocol = digest::digest(file=file.path(root,"experiments/corpus-stability/PROTOCOL.md"),algo="sha256"))
checkpoint <- file.path(cache, "metrics-private.rds")
set.seed(20261024)
starts <- lapply(x$metadata$N, function(n) {
  if(n < 400) return(integer())
  s <- sort(sample.int(n-398L, 2L)); s[[2]] <- s[[2]]+199L
  sample(s)
})
if (file.exists(checkpoint)) {
  saved <- readRDS(checkpoint); stopifnot(identical(saved$identity, identity))
  results <- saved$results
} else results <- vector("list", length(x$tokens))
score <- function(tokens, part, length) {
  z <- lexdiv_metrics(tokens, metrics = metrics)
  out <- as.data.frame(z[c("metric_id", "value", "status", "missing_reason")])
  out$part <- part; out$length <- length
  out$mtld_tail_only <- vapply(seq_len(nrow(z)), function(i) {
    if(z$metric_id[[i]] != "mtld" || z$status[[i]] != "ok") return(NA)
    d <- z$diagnostics[[i]]
    d$forward_complete_factors == 0L || d$reverse_complete_factors == 0L
  }, logical(1))
  out
}
for (i in seq_along(x$tokens)) {
  if (!is.null(results[[i]])) next
  tokens <- x$tokens[[i]]
  z <- list(score(tokens,"full",length(tokens)))
  if (length(starts[[i]])) for (j in 1:2) for (n in c(50L,100L,150L,200L)) {
    start <- starts[[i]][[j]]
    z[[length(z)+1L]] <- score(tokens[seq.int(start,length.out=n)],c("A","B")[[j]],n)
  }
  results[[i]] <- do.call(rbind,z)
  if (i %% 100L == 0L || i == length(x$tokens)) {
    temp <- paste0(checkpoint,".tmp")
    saveRDS(list(identity=identity,starts=starts,results=results),temp)
    stopifnot(file.rename(temp,checkpoint))
    cat(i,"/",length(x$tokens),format(Sys.time()),"\n"); flush.console()
  }
}
