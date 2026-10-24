# Rscript check-results.R package-root private-base result-directory
args<-commandArgs(TRUE);stopifnot(length(args)==3L)
root<-normalizePath(args[[1]]);base<-normalizePath(args[[2]]);out<-args[[3]]
errors<-numeric();cells<-0L;total_scores<-0L
for(corpus in c('icnale','oanc','bawe')) {
  cache<-file.path(base,corpus);plan<-readRDS(file.path(cache,'analysis-plan-private.rds'))
  saved<-readRDS(file.path(cache,'extension-metrics-private.rds'));d<-plan$metadata
  needed<-sort(unique(unlist(plan$cohorts,use.names=FALSE)))
  r<-do.call(rbind,lapply(needed,function(i){z<-saved$results[[i]];z$document<-i;z}))
  total_scores<-total_scores+nrow(r)
  stopifnot(all((r$status=='ok')==is.finite(r$value)),!anyDuplicated(r[c('document','scope','part','length','metric_id')]))
  bycell<-split(r,paste(r$scope,r$metric_id,r$length,sep='/'))
  results<-read.csv(file.path(out,paste0(corpus,'-reliability.csv')))
  for(j in seq_len(nrow(results))) {
    rec<-results[j,];ix<-intersect(plan$cohorts[[rec$scope]],plan$groups[[rec$group]])
    z<-bycell[[paste(rec$scope,rec$metric,rec$length,sep='/')]];za<-z[z$part=='A',];zb<-z[z$part=='B',]
    a<-za$value[match(ix,za$document)];b<-zb$value[match(ix,zb$document)];ok<-is.finite(a)&is.finite(b)
    stopifnot(sum(ok)==rec$complete_pairs)
    if(is.finite(rec$icc)) {
      y<-cbind(a[ok],b[ok]);subject_means<-rowMeans(y);n<-nrow(y)
      msb<-2*sum((subject_means-mean(y))^2)/(n-1);msw<-sum((y-subject_means)^2)/n
      oracle<-(msb-msw)/(msb+msw);errors<-c(errors,abs(oracle-rec$icc));cells<-cells+1L
    }
  }
}
stopifnot(max(errors)<1e-9)
summary<-list(score_rows=total_scores,independent_ANOVA_cells=cells,max_abs_error=max(errors),passed=TRUE)
jsonlite::write_json(summary,file.path(out,'numerical-checks.json'),auto_unbox=TRUE,pretty=TRUE)
print(summary)
