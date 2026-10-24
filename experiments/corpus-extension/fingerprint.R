# Rscript fingerprint.R private-base
args<-commandArgs(TRUE);stopifnot(length(args)==1L)
for(corpus in c('icnale','oanc','bawe')) {
  cache<-file.path(args[[1]],corpus);d<-readRDS(file.path(cache,'prepared-private.rds'))
  hashes<-vapply(d$tokens,digest::digest,character(1),algo='sha256')
  duplicates<-duplicated(hashes)
  result<-data.frame(doc_id=d$metadata$doc_id,token_sha256=hashes,
    duplicate_of=ifelse(duplicates,d$metadata$doc_id[match(hashes,hashes)],NA_character_))
  path<-file.path(cache,'token-duplicates-private.rds')
  if(file.exists(path))stopifnot(identical(readRDS(path),result)) else saveRDS(result,path)
}
