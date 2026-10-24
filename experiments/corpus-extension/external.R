# Rscript external.R package-root private-base output-directory
args<-commandArgs(TRUE);stopifnot(length(args)==3L)
root<-normalizePath(args[[1]]);base<-normalizePath(args[[2]]);out<-args[[3]]
pkgload::load_all(root,quiet=TRUE);suppressPackageStartupMessages(library(koRpus.lang.en))
records<-list();selected_count<-0L
for(corpus in c('icnale','oanc','bawe')) {
  cache<-file.path(base,corpus);x<-readRDS(file.path(cache,'prepared-private.rds'))
  plan<-readRDS(file.path(cache,'analysis-plan-private.rds'));saved<-readRDS(file.path(cache,'extension-metrics-private.rds'));d<-plan$metadata
  groups<-switch(corpus,icnale=d$group,oanc=d$genre,bawe=d$group)
  for(scope in c('short','long','task')) {
    ix<-plan$cohorts[[scope]];if(!length(ix))next
    selected<-unlist(lapply(split(ix,groups[ix]),function(i){
      i<-i[order(d$N[i],d$doc_id[i])];i[unique(round(seq(1,length(i),length.out=min(3L,length(i)))))]
    }),use.names=FALSE)
    sizes<-switch(scope,short=c(50L,100L),long=c(200L,500L,1000L),task=200L)
    for(i in selected)for(n in sizes) {
      start<-plan$starts[[scope]][[as.character(i)]][[1]];tokens<-x$tokens[[i]][seq.int(start,length.out=n)]
      tagged<-suppressWarnings(koRpus::readTagged(data.frame(token=tokens,tag='NN',lemma=tokens),
        lang='en',tagger='TreeTagger',apply.sentc.end=FALSE,rm.sgml=FALSE))
      k<-suppressWarnings(koRpus::lex.div(tagged,measure=c('TTR','MATTR','HD-D','MTLD-MA','MTLD'),
        case.sens=TRUE,force.lang='en',quiet=TRUE,keep.tokens=TRUE,window=50,rand.sample=42,
        factor.size=.72,min.tokens=9,MTLDMA.steps=1,corp.rm.class=character()))
      stopifnot(identical(k@tt$tokens,tokens))
      external<-c(ttr=k@TTR,mattr=k@MATTR$MATTR,hdd=k@HDD$ATTR,mtld_ma=k@MTLDMA$MTLDMA,mtld=k@MTLD$MTLD)
      z<-saved$results[[i]];z<-z[z$scope==scope&z$length==n&(z$part=='A'|scope=='task'),]
      stopifnot(nrow(z)==12L);ours<-z$value[match(names(external),z$metric_id)]
      records[[length(records)+1L]]<-data.frame(corpus=corpus,scope=scope,length=n,metric=names(external),
        ours=ours,external=unname(external),same_missing=is.na(ours)==is.na(external))
      selected_count<-selected_count+1L
    }
    cat(corpus,scope,'selected blocks',length(selected)*length(sizes),'complete\n');flush.console()
  }
}
r<-do.call(rbind,records)
saveRDS(r,file.path(base,'external-comparison-private.rds'))
jsonlite::write_json(list(koRpus=as.character(packageVersion('koRpus')),language=as.character(packageVersion('koRpus.lang.en')),
  blocks=selected_count,token_identity_verified=TRUE,code=digest::digest(file=file.path(root,'experiments/corpus-extension/external.R'),algo='sha256')),
  file.path(out,'external-provenance.json'),auto_unbox=TRUE,pretty=TRUE)
source(file.path(root,'experiments/corpus-extension/external-summary.R'))
summarize_external(r,out)
