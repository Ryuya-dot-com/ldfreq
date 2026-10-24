# Rscript prepare-plan.R package-root private-base
args <- commandArgs(TRUE); stopifnot(length(args)==2L)
root <- normalizePath(args[[1]]); base <- normalizePath(args[[2]])
protocol <- file.path(root,'experiments/corpus-extension/PROTOCOL.md')
hash <- function(f) digest::digest(file=f,algo='sha256')
components <- function(links) {
  parent <- seq_along(links)
  find <- function(i) { while(parent[[i]]!=i) i<-parent[[i]]; i }
  seen <- new.env(hash=TRUE,parent=emptyenv())
  for(i in seq_along(links)) for(key in links[[i]]) {
    if(exists(key,seen,inherits=FALSE)) {
      a<-find(i); b<-find(get(key,seen,inherits=FALSE)); if(a!=b) parent[[max(a,b)]]<-min(a,b)
    } else assign(key,i,seen)
  }
  vapply(seq_along(links),find,integer(1))
}
stopifnot(identical(components(list(c('a','b'),'c',c('b','c'),'d')),c(1L,1L,1L,4L)))
pair_starts <- function(n,m) {
  s<-sort(sample.int(n-2L*m+2L,2L));s[[2]]<-s[[2]]+m-1L;sample(s)
}
for(ci in seq_along(corpora<-c('icnale','oanc','bawe'))) {
  corpus<-corpora[[ci]]; cache<-file.path(base,corpus)
  input<-file.path(cache,'prepared-private.rds');x<-readRDS(input);d<-x$metadata
  dupfile<-file.path(cache,'token-duplicates-private.rds');dups<-readRDS(dupfile)
  stopifnot(identical(d$doc_id,dups$doc_id),identical(names(x$tokens),d$doc_id))
  if(corpus=='oanc') {
    linkfile<-file.path(cache,'source-links-private.json');z<-jsonlite::fromJSON(linkfile)
    stopifnot(identical(d$doc_id,z$doc_id)); links<-z$links
  } else links<-lapply(d$writer_id,function(w) paste0('writer:',w))
  links<-Map(c,links,paste0('tokens:',dups$token_sha256))
  d$cluster<-components(links)
  eligible<-if(corpus=='bawe') d$number_authors=='1' else rep(TRUE,nrow(d))
  selected<-which(eligible);selected<-selected[!duplicated(dups$token_sha256[selected])]
  d$selected<-seq_len(nrow(d))%in%selected
  short<-selected[d$N[selected]>=200L]
  long<-if(corpus=='icnale') integer() else selected[d$N[selected]>=2000L]
  task<-integer()
  if(corpus=='icnale') {
    bywriter<-split(short,d$writer_id[short]);task<-sort(unlist(bywriter[lengths(bywriter)==2L],use.names=FALSE))
  }
  set.seed(202610240L+ci)
  starts<-list(short=setNames(lapply(d$N[short],pair_starts,m=100L),short),
    long=setNames(lapply(d$N[long],pair_starts,m=1000L),long),
    task=setNames(lapply(d$N[task],function(n) sample.int(n-199L,1L)),task))
  for(scope in c('short','long')) for(j in names(starts[[scope]])) {
    s<-sort(starts[[scope]][[j]]);m<-if(scope=='short')100L else 1000L
    stopifnot(s[[1]]>=1L,s[[2]]-s[[1]]>=m,s[[2]]+m-1L<=d$N[[as.integer(j)]])
  }
  groups<-if(corpus=='icnale') list(L2=which(d$group=='L2'),L1=which(d$group=='L1')) else
    if(corpus=='oanc') list(written=which(d$group=='written'),spoken=which(d$group=='spoken')) else list(all=seq_len(nrow(d)))
  add_groups<-function(field,prefix,restrict=rep(TRUE,nrow(d))) {
    z<-split(which(restrict),field[restrict]);names(z)<-paste0(prefix,names(z));z
  }
  if(corpus=='icnale') groups<-c(groups,add_groups(d$region,'region:',d$group=='L2'),
    add_groups(d$level,'level:',d$group=='L2'),add_groups(d$task,'task:',d$group=='L2'))
  if(corpus=='oanc') groups<-c(groups,add_groups(d$genre,'genre:'))
  if(corpus=='bawe') groups<-c(groups,add_groups(d$group,'discipline:'),
    add_groups(ifelse(grepl('+',d$genre,fixed=TRUE),'compound',d$genre),'genre:'))
  identity<-list(prepared=hash(input),duplicates=hash(dupfile),protocol=hash(protocol),
    preparation=hash(file.path(root,'experiments/corpus-extension/prepare-plan.R')),
    links=if(corpus=='oanc')hash(linkfile) else NULL)
  plan<-list(corpus=corpus,metadata=d,cohorts=list(short=short,long=long,task=task),
    groups=groups,starts=starts,identity=identity,seed=202610240L+ci)
  target<-file.path(cache,'analysis-plan-private.rds')
  if(file.exists(target)) stopifnot(identical(readRDS(target),plan)) else saveRDS(plan,target)
  for(scope in names(plan$cohorts)) {
    ix<-plan$cohorts[[scope]];counts<-table(d$cluster[ix])
    cat(corpus,scope,'documents',length(ix),'clusters',length(counts),
      'largest share',if(length(ix))max(counts)/length(ix) else NA,'\n')
  }
}
