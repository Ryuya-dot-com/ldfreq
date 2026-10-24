# Rscript experiments/corpus-stability/summarize.R private-cache output-directory
args <- commandArgs(TRUE); stopifnot(length(args)==2L)
cache <- normalizePath(args[[1]]); out <- args[[2]]
dir.create(out,recursive=TRUE,showWarnings=FALSE)
x <- readRDS(file.path(cache,"prepared-private.rds"))
saved <- readRDS(file.path(cache,"metrics-private.rds"))
stopifnot(length(saved$results)==nrow(x$metadata),!any(vapply(saved$results,is.null,logical(1))))
r <- do.call(rbind,lapply(seq_along(saved$results),function(i) {
  z <- saved$results[[i]]; z$document <- i; z
}))
full <- r[r$part=="full",]
associations <- do.call(rbind,lapply(split(full,full$metric_id),function(z) {
  ok <- is.finite(z$value)
  data.frame(metric=z$metric_id[[1]],documents=nrow(z),computed=sum(ok),
    spearman_with_length=cor(z$value[ok],z$length[ok],method="spearman"))
}))
write.csv(associations,file.path(out,"full-length-associations.csv"),row.names=FALSE)
cohort <- which(x$metadata$N>=400L)
writers <- x$metadata$anon_id[cohort]
clusters <- split(seq_along(cohort),writers)
set.seed(20261025)
bootstrap <- replicate(2000L,unlist(clusters[sample.int(length(clusters),
  length(clusters),replace=TRUE)],use.names=FALSE),simplify=FALSE)
pair_stat <- function(a,b) {
  ok <- is.finite(a)&is.finite(b); a <- a[ok]; b <- b[ok]
  if(length(a)<3) return(c(icc=NA_real_,rho=NA_real_))
  between <- 2*var((a+b)/2); within <- mean((a-b)^2)/2
  c(icc=if(between+within>0) (between-within)/(between+within) else NA_real_,
    rho=if(sd(a)>0&&sd(b)>0) cor(a,b,method="spearman") else NA_real_)
}
interval <- function(x) {
  finite <- x[is.finite(x)]
  if (!length(finite)) return(c(lower=NA_real_,upper=NA_real_,finite=0))
  c(setNames(quantile(finite,c(.025,.975),names=FALSE),c("lower","upper")),finite=length(finite))
}
means <- reliability <- changes <- list(); private_values <- list()
for(metric in unique(r$metric_id)) {
  by_length <- list()
  for(n in c(50L,100L,150L,200L)) {
    z <- r[r$metric_id==metric&r$length==n&r$part!="full",]
    # Match within each part explicitly; input row ordering is irrelevant.
    za <- z[z$part=="A",]; zb <- z[z$part=="B",]
    a <- za$value[match(cohort,za$document)]; b <- zb$value[match(cohort,zb$document)]
    values <- c(a,b); finite <- values[is.finite(values)]
    means[[length(means)+1L]] <- data.frame(metric=metric,length=n,
      documents=length(cohort),blocks=length(values),computed=length(finite),
      missing=length(values)-length(finite),mean=mean(finite),sd=sd(finite),
      median=median(finite),mtld_tail_only=if(metric=="mtld") mean(z$mtld_tail_only,na.rm=TRUE) else NA_real_)
    observed <- pair_stat(a,b)
    boot <- vapply(bootstrap,function(i) pair_stat(a[i],b[i]),numeric(2))
    ic <- interval(boot["icc",]); rh <- interval(boot["rho",])
    reliability[[length(reliability)+1L]] <- data.frame(metric=metric,length=n,
      complete_pairs=sum(is.finite(a)&is.finite(b)),icc=observed[["icc"]],
      icc_lower=ic[["lower"]],icc_upper=ic[["upper"]],icc_bootstrap_finite=ic[["finite"]],
      spearman=observed[["rho"]],spearman_lower=rh[["lower"]],spearman_upper=rh[["upper"]],
      spearman_bootstrap_finite=rh[["finite"]])
    by_length[[as.character(n)]] <- (a+b)/2
  }
  low <- by_length[["50"]]; high <- by_length[["200"]]
  effect <- function(i) {
    ok <- is.finite(low[i])&is.finite(high[i]); a<-low[i][ok]; b<-high[i][ok]
    if(length(a)<3) return(c(change=NA_real_,standardized=NA_real_))
    delta <- mean(b-a); c(change=delta,standardized=delta/sd(b))
  }
  obs <- effect(seq_along(cohort)); boot <- vapply(bootstrap,effect,numeric(2))
  raw <- interval(boot["change",]); std <- interval(boot["standardized",])
  changes[[length(changes)+1L]] <- data.frame(metric=metric,
    complete_documents=sum(is.finite(low)&is.finite(high)),
    change_200_minus_50=obs[["change"]],change_lower=raw[["lower"]],change_upper=raw[["upper"]],
    standardized_change=obs[["standardized"]],standardized_lower=std[["lower"]],
    standardized_upper=std[["upper"]],bootstrap_finite=std[["finite"]])
  private_values[[metric]] <- by_length
  cat(metric,"complete\n");flush.console()
}
write.csv(do.call(rbind,means),file.path(out,"block-summaries.csv"),row.names=FALSE)
write.csv(do.call(rbind,reliability),file.path(out,"sampling-reliability.csv"),row.names=FALSE)
write.csv(do.call(rbind,changes),file.path(out,"paired-length-change.csv"),row.names=FALSE)
jsonlite::write_json(list(identity=saved$identity,
  corpus=list(documents=nrow(x$metadata),writers=length(unique(x$metadata$anon_id)),
    prompts=length(unique(x$metadata$question_id)),tokens=sum(x$metadata$N)),
  cohort=list(documents=length(cohort),writers=length(clusters),
    prompts=length(unique(x$metadata$question_id[cohort]))),
  bootstrap=list(replicates=length(bootstrap),seed=20261025,unit="writer",interval="percentile 95%"),
  R=as.character(getRversion())),file.path(out,"provenance.json"),pretty=TRUE,auto_unbox=TRUE)
saveRDS(private_values,file.path(cache,"length-values-private.rds"))
