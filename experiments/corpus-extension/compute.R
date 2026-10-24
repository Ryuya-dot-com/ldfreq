# Rscript compute.R package-root private-base corpus
args<-commandArgs(TRUE);stopifnot(length(args)==3L)
root<-normalizePath(args[[1]]);cache<-file.path(normalizePath(args[[2]]),args[[3]])
pkgload::load_all(root,quiet=TRUE)
hash<-function(f)digest::digest(file=f,algo='sha256')
planfile<-file.path(cache,'analysis-plan-private.rds');plan<-readRDS(planfile)
input<-file.path(cache,'prepared-private.rds');stopifnot(hash(input)==plan$identity$prepared)
x<-readRDS(input);metrics<-setdiff(lexdiv_metric_ids(),'expected_ttr_d')
source_files<-list.files(file.path(root,'R'),pattern='[.]R$',full.names=TRUE)
identity<-list(plan=hash(planfile),code=hash(file.path(root,'experiments/corpus-extension/compute.R')),
  source=setNames(vapply(source_files,hash,character(1)),basename(source_files)))
checkpoint<-file.path(cache,'extension-metrics-private.rds')
results<-vector('list',length(x$tokens))
if(file.exists(checkpoint)){saved<-readRDS(checkpoint);stopifnot(identical(saved$identity,identity));results<-saved$results}
score<-function(tokens,scope,part,n){
  z<-lexdiv_metrics(tokens,metrics=metrics)
  out<-as.data.frame(z[c('metric_id','value','status','missing_reason')])
  out$scope<-scope;out$part<-part;out$length<-n
  out$mtld_tail_only<-vapply(seq_len(nrow(z)),function(i){
    if(z$metric_id[[i]]!='mtld'||z$status[[i]]!='ok')return(NA)
    d<-z$diagnostics[[i]];d$forward_complete_factors==0L||d$reverse_complete_factors==0L
  },logical(1));out
}
needed<-sort(unique(unlist(plan$cohorts,use.names=FALSE)))
completed<-0L
for(i in needed){
  if(!is.null(results[[i]]))next
  tokens<-x$tokens[[i]];records<-list()
  for(scope in c('short','long','task')){
    starts<-plan$starts[[scope]][[as.character(i)]]
    if(is.null(starts))next
    sizes<-switch(scope,short=c(50L,100L),long=c(200L,500L,1000L),task=200L)
    for(j in seq_along(starts))for(n in sizes){
      part<-if(scope=='task')plan$metadata$task[[i]] else c('A','B')[[j]]
      records[[length(records)+1L]]<-score(tokens[seq.int(starts[[j]],length.out=n)],scope,part,n)
    }
  }
  results[[i]]<-do.call(rbind,records);completed<-completed+1L
  if(completed%%100L==0L||i==tail(needed,1L)){
    temp<-paste0(checkpoint,'.tmp');saveRDS(list(identity=identity,results=results),temp)
    stopifnot(file.rename(temp,checkpoint));cat(sum(!vapply(results[needed],is.null,logical(1))),'/',length(needed),format(Sys.time()),'\n');flush.console()
  }
}
stopifnot(!any(vapply(results[needed],is.null,logical(1))))
