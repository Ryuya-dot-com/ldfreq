# Validate saved results without rerunning corpus metrics or bootstrap replicates.
# Rscript experiments/corpus-stability/check-and-distributions.R package-root private-cache output-directory
args <- commandArgs(TRUE); stopifnot(length(args)==3L)
root <- normalizePath(args[[1]]); cache <- normalizePath(args[[2]]); out <- args[[3]]
pkgload::load_all(root,quiet=TRUE)
x <- readRDS(file.path(cache,"prepared-private.rds"))
saved <- readRDS(file.path(cache,"metrics-private.rds"))
stopifnot(length(saved$results)==nrow(x$metadata),
  !anyDuplicated(x$metadata[c("anon_id","question_id")]))
cohort <- which(x$metadata$N>=400L)
for(i in cohort) {
  starts <- sort(saved$starts[[i]])
  stopifnot(length(starts)==2L, starts[[1]]>=1L,
    starts[[2]]-starts[[1]]>=200L,starts[[2]]+199L<=x$metadata$N[[i]])
}
# Enumerate the construction independently for small excess lengths.
for(n in 400:410) {
  mapped <- t(combn(seq_len(n-398L),2)); mapped[,2] <- mapped[,2]+199L
  brute <- expand.grid(a=seq_len(n-199L),b=seq_len(n-199L))
  brute <- brute[brute$b-brute$a>=200L,]
  key <- function(a,b) paste(a,b,sep=":")
  stopifnot(setequal(key(mapped[,1],mapped[,2]),key(brute$a,brute$b)),
    !anyDuplicated(key(mapped[,1],mapped[,2])))
}
r <- do.call(rbind,lapply(seq_along(saved$results),function(i) {
  z <- saved$results[[i]];z$document<-i;z
}))
expected <- read.csv(file.path(out,"sampling-reliability.csv"))
for(j in seq_len(nrow(expected))) {
  e<-expected[j,];z<-r[r$metric_id==e$metric&r$length==e$length&r$part!="full",]
  a<-z[z$part=="A",];b<-z[z$part=="B",]
  pair<-data.frame(a=a$value,b=b$value[match(a$document,b$document)])
  pair<-pair[is.finite(pair$a)&is.finite(pair$b),]
  model<-data.frame(value=c(pair$a,pair$b),document=factor(rep(seq_len(nrow(pair)),2)))
  f<-unname(stats::oneway.test(value~document,data=model,var.equal=TRUE)$statistic)
  independent<-(f-1)/(f+1)
  stopifnot(nrow(pair)==e$complete_pairs,abs(independent-e$icc)<1e-10)
}
# Verify a spread of saved full-document scores with the final implementation.
selected<-unique(round(seq(1,nrow(x$metadata),length.out=20)))
for(i in selected) {
  old<-saved$results[[i]];old<-old[old$part=="full",]
  now<-lexdiv_metrics(x$tokens[[i]],metrics=old$metric_id)
  stopifnot(identical(old$status,now$status),isTRUE(all.equal(old$value,now$value,tolerance=1e-12)))
}
# Common bandwidth and evaluation range per measure; original scales, no differences.
measures<-c("mattr","hdd","mtld","mtld_ma")
densities<-list();quantiles<-list()
for(metric in unique(r$metric_id)) {
  z<-r[r$metric_id==metric&r$part!="full",]
  finite<-z$value[is.finite(z$value)]
  bw<-bw.nrd0(finite);limits<-range(finite)
  for(n in c(50,100,150,200)) {
    v<-z$value[z$length==n&is.finite(z$value)]
    q<-quantile(v,c(.05,.25,.5,.75,.95),names=FALSE)
    quantiles[[length(quantiles)+1L]]<-data.frame(metric=metric,length=n,
      computed=length(v),p05=q[1],p25=q[2],p50=q[3],p75=q[4],p95=q[5])
    if(metric %in% measures) {
      d<-density(v,bw=bw,from=limits[1],to=limits[2],n=256)
      densities[[length(densities)+1L]]<-data.frame(metric=metric,length=n,
        value=d$x,density=d$y,bandwidth=bw,computed=length(v))
    }
  }
}
write.csv(do.call(rbind,densities),file.path(out,"block-densities.csv"),row.names=FALSE)
write.csv(do.call(rbind,quantiles),file.path(out,"block-quantiles.csv"),row.names=FALSE)
provenance<-jsonlite::read_json(file.path(out,"provenance.json"),simplifyVector=FALSE)
provenance$identity$inputs<-as.list(saved$identity$inputs)
provenance$identity$source<-as.list(saved$identity$source)
provenance$checks<-list(complete_nonoverlapping_blocks=length(cohort),
  independent_anova_iccs=nrow(expected),final_implementation_documents=length(selected),
  final_source_sha256=as.list(setNames(vapply(names(saved$identity$source),function(f)
    digest::digest(file=file.path(root,"R",f),algo="sha256"),character(1)),names(saved$identity$source))))
jsonlite::write_json(provenance,file.path(out,"provenance.json"),pretty=TRUE,auto_unbox=TRUE)
cat("PASS: block sampling, 48 independent ANOVA ICC checks, 20 final-code score comparisons; original-scale distributions saved\n")
