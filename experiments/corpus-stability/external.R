# Actual koRpus calls; requires koRpus and koRpus.lang.en. No corpus download.
args <- commandArgs(TRUE); stopifnot(length(args) == 3L)
root <- normalizePath(args[[1]]); cache <- normalizePath(args[[2]]); out <- args[[3]]
dir.create(out,recursive=TRUE,showWarnings=FALSE)
pkgload::load_all(root,quiet=TRUE)
suppressPackageStartupMessages(library(koRpus.lang.en))
x <- readRDS(file.path(cache,"prepared-private.rds")); d <- x$metadata
d$quartile <- cut(d$N,unique(quantile(d$N,seq(0,1,.25))),include.lowest=TRUE)
strata <- split(seq_len(nrow(d)),interaction(d$level,d$quartile,drop=TRUE))
selected <- unlist(lapply(strata,function(i) {
  i <- i[order(d$N[i],as.integer(d$answer_id[i]))]
  i[unique(round(seq(1,length(i),length.out=min(20,length(i)))))]
}),use.names=FALSE)
records <- list()
for (i in selected) {
  tokens <- x$tokens[[i]]
  # Exclude formula-domain failures from the external call, not from reporting.
  if (length(tokens)<50) next
  # A supplied token table bypasses koRpus character-input retokenization.
  # NN and lemma are placeholders, unused by these surface-token measures.
  tagged <- suppressWarnings(koRpus::readTagged(
    data.frame(token=tokens,tag="NN",lemma=tokens),lang="en",
    tagger="TreeTagger",apply.sentc.end=FALSE,rm.sgml=FALSE))
  k <- suppressWarnings(koRpus::lex.div(tagged,
    measure=c("TTR","MATTR","HD-D","MTLD-MA","MTLD"),
    case.sens=TRUE,force.lang="en",quiet=TRUE,keep.tokens=TRUE,
    window=50,rand.sample=42,factor.size=.72,min.tokens=9,MTLDMA.steps=1,
    corp.rm.class=character()))
  stopifnot(identical(k@tt$tokens,tokens))
  external <- c(ttr=k@TTR,mattr=k@MATTR$MATTR,hdd=k@HDD$ATTR,
    mtld_ma=k@MTLDMA$MTLDMA,mtld=k@MTLD$MTLD)
  ours <- lexdiv_metrics(tokens,metrics=names(external))
  z <- data.frame(metric=names(external),ours=ours$value,external=unname(external),
    same_missing=is.na(ours$value)==is.na(external),N=length(tokens),
    course_level=d$level[[i]],stringsAsFactors=FALSE)
  records[[length(records)+1L]] <- z
}
r <- do.call(rbind,records)
summary <- do.call(rbind,lapply(split(r,r$metric),function(z) {
  comparable <- is.finite(z$ours)&is.finite(z$external)
  delta <- abs(z$ours[comparable]-z$external[comparable])
  data.frame(metric=z$metric[[1]],documents=nrow(z),comparable=sum(comparable),
    missing_disagreements=sum(!z$same_missing),
    matches_1e_10=sum(delta<=1e-10),max_abs_difference=max(c(0,delta)))
}))
write.csv(summary,file.path(out,"external-comparison.csv"),row.names=FALSE)
jsonlite::write_json(list(package="koRpus",version=as.character(packageVersion("koRpus")),
  language_package=as.character(packageVersion("koRpus.lang.en")),R=as.character(getRversion()),
  selected_before_domain_check=length(selected),minimum_tokens=50,
  token_identity_verified=TRUE,settings=list(window=50,rand.sample=42,factor.size=.72,
    min.tokens=9,MTLDMA.steps=1,case.sens=TRUE),
  inputs=x$input_sha256,source_sha256=digest::digest(file=file.path(root,"R/metric-mtld.R"),algo="sha256")),
  file.path(out,"external-provenance.json"),auto_unbox=TRUE,pretty=TRUE)
saveRDS(list(selected=selected,comparisons=r),file.path(cache,"external-private.rds"))
print(summary)
stopifnot(all(summary$missing_disagreements==0),
  all(summary$max_abs_difference[summary$metric!="mtld"]<1e-10))
