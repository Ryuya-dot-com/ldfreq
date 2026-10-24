# Rscript summarize.R package-root private-base corpus output-directory
args<-commandArgs(TRUE);stopifnot(length(args)==4L)
root<-normalizePath(args[[1]]);cache<-file.path(normalizePath(args[[2]]),args[[3]]);out<-args[[4]]
dir.create(out,recursive=TRUE,showWarnings=FALSE)
source(file.path(root,'experiments/corpus-extension/statistics.R'))
hash<-function(f)digest::digest(file=f,algo='sha256')
planfile<-file.path(cache,'analysis-plan-private.rds');plan<-readRDS(planfile);d<-plan$metadata
metricfile<-file.path(cache,'extension-metrics-private.rds');saved<-readRDS(metricfile)
stopifnot(identical(saved$identity$plan,hash(planfile)))
needed<-sort(unique(unlist(plan$cohorts,use.names=FALSE)))
stopifnot(!any(vapply(saved$results[needed],is.null,logical(1))))
r<-do.call(rbind,lapply(needed,function(i){z<-saved$results[[i]];z$document<-i;z}))
bycell<-split(r,paste(r$scope,r$metric_id,r$length,sep='/'));rm(r)
identity<-list(metrics=hash(metricfile),plan=hash(planfile),code=hash(file.path(root,'experiments/corpus-extension/summarize.R')),
  statistics=hash(file.path(root,'experiments/corpus-extension/statistics.R')))
checkdir<-file.path(cache,'summary-checkpoints-private');dir.create(checkdir,showWarnings=FALSE)
records<-list();metrics<-unique(saved$results[[needed[[1]]]]$metric_id)
ci<-match(plan$corpus,c('icnale','oanc','bawe'))
for(si in seq_along(scopes<-names(plan$cohorts)))for(gi in seq_along(plan$groups)) {
  scope<-scopes[[si]];group<-names(plan$groups)[[gi]]
  cohort<-intersect(plan$cohorts[[scope]],plan$groups[[gi]])
  if(length(cohort)<3L||(scope=='task'&&startsWith(group,'task:')))next
  file<-file.path(checkdir,paste0(scope,'-',gi,'.rds'))
  if(file.exists(file)) {
    record<-readRDS(file);stopifnot(identical(record$identity,identity));records[[length(records)+1L]]<-record;next
  }
  if(scope=='task') {
    ia<-cohort[d$task[cohort]=='PTJ0'];ib<-cohort[d$task[cohort]=='SMK0'];
    ib<-ib[match(d$writer_id[ia],d$writer_id[ib])];stopifnot(!anyNA(ib),all(d$cluster[ia]==d$cluster[ib]));cluster<-d$cluster[ia]
  } else cluster<-d$cluster[cohort]
  seed<-202610260L+ci*1000L+si*100L+gi;design<-bootstrap_weights(cluster,seed)
  sizes<-switch(scope,short=c(50L,100L),long=c(200L,500L,1000L),task=200L)
  summaries<-reliability<-changes<-taskstats<-list()
  for(metric in metrics) {
    values<-list()
    for(n in sizes) {
      z<-bycell[[paste(scope,metric,n,sep='/')]]
      if(scope=='task') {
        a<-z$value[match(ia,z$document)];b<-z$value[match(ib,z$document)]
      } else {
        za<-z[z$part=='A',];zb<-z[z$part=='B',]
        a<-za$value[match(cohort,za$document)];b<-zb$value[match(cohort,zb$document)]
      }
      ok<-is.finite(a)&is.finite(b);info<-cluster_info(cluster,ok)
      st<-pair_statistics(bootstrap_sums(pair_sums(a,b),design))
      ic<-interval(st[-1,'icc'],info[['clusters']]);cc<-interval(st[-1,'ccc'],info[['clusters']])
      tag<-data.frame(corpus=plan$corpus,scope=scope,group=group,metric=metric,length=n)
      if(scope=='task') {
        ca<-interval(st[-1,'mean_a'],info[['clusters']]);cb<-interval(st[-1,'mean_b'],info[['clusters']])
        taskstats[[length(taskstats)+1L]]<-cbind(tag,writers=length(a),complete_pairs=sum(ok),
          clusters=info[['clusters']],largest_cluster_share=info[['largest_share']],
          mean_ptj=st[1,'mean_a'],mean_smk=st[1,'mean_b'],mean_ptj_lower=ca[['lower']],mean_ptj_upper=ca[['upper']],
          mean_smk_lower=cb[['lower']],mean_smk_upper=cb[['upper']],ccc=st[1,'ccc'],
          ccc_lower=cc[['lower']],ccc_upper=cc[['upper']],bootstrap_finite=cc[['finite']],spearman=rank_agreement(a,b))
        next
      }
      ms<-bootstrap_sums(mean_sums(a,b),design);mstat<-ms[,'sum']/ms[,'n']
      mc<-interval(mstat[-1],cluster_info(cluster,is.finite(a)|is.finite(b))[['clusters']])
      finite<-c(a,b)[is.finite(c(a,b))]
      tails<-z$mtld_tail_only[z$document%in%cohort]
      summaries[[length(summaries)+1L]]<-cbind(tag,documents=length(cohort),blocks=2L*length(cohort),
        computed=length(finite),missing=2L*length(cohort)-length(finite),mean=mean(finite),sd=sd(finite),median=median(finite),
        mean_lower=mc[['lower']],mean_upper=mc[['upper']],mean_bootstrap_finite=mc[['finite']],
        mtld_tail_only=if(metric=='mtld')mean(tails,na.rm=TRUE) else NA_real_)
      reliability[[length(reliability)+1L]]<-cbind(tag,documents=length(cohort),complete_pairs=sum(ok),
        clusters=info[['clusters']],largest_cluster_share=info[['largest_share']],icc=st[1,'icc'],
        icc_lower=ic[['lower']],icc_upper=ic[['upper']],bootstrap_finite=ic[['finite']],spearman=rank_agreement(a,b))
      values[[as.character(n)]]<-(a+b)/2
    }
    if(scope!='task') {
      low<-values[[1]];high<-values[[length(values)]];ok<-is.finite(low)&is.finite(high);info<-cluster_info(cluster,ok)
      st<-change_statistics(bootstrap_sums(change_sums(low,high),design))
      rc<-interval(st[-1,'change'],info[['clusters']]);sc<-interval(st[-1,'standardized'],info[['clusters']])
      changes[[length(changes)+1L]]<-data.frame(corpus=plan$corpus,scope=scope,group=group,metric=metric,
        length_low=min(sizes),length_high=max(sizes),documents=length(cohort),complete_documents=sum(ok),
        clusters=info[['clusters']],largest_cluster_share=info[['largest_share']],
        change=st[1,'change'],change_lower=rc[['lower']],change_upper=rc[['upper']],
        standardized_change=st[1,'standardized'],standardized_lower=sc[['lower']],standardized_upper=sc[['upper']],
        bootstrap_finite=sc[['finite']])
    }
  }
  record<-list(identity=identity,seed=seed,summaries=do.call(rbind,summaries),reliability=do.call(rbind,reliability),
    changes=do.call(rbind,changes),task=do.call(rbind,taskstats))
  saveRDS(record,file);records[[length(records)+1L]]<-record
  cat(plan$corpus,scope,group,'complete\n');flush.console()
}
for(name in c('summaries','reliability','changes','task')) {
  z<-do.call(rbind,lapply(records,`[[`,name));if(!is.null(z))write.csv(z,file.path(out,paste0(plan$corpus,'-',name,'.csv')),row.names=FALSE,na='')
}
jsonlite::write_json(list(identity=identity,bootstrap=list(replicates=2000L,unit='record-linked component',minimum_clusters=20L,
  minimum_finite_replicates=1900L),R=as.character(getRversion())),file.path(out,paste0(plan$corpus,'-provenance.json')),auto_unbox=TRUE,pretty=TRUE)
