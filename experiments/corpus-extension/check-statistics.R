args<-commandArgs(TRUE);stopifnot(length(args)==1L)
source(file.path(args[[1]],'experiments/corpus-extension/statistics.R'))
set.seed(81032)
cluster<-rep(seq_len(40),sample(1:7,40,replace=TRUE));a<-rnorm(length(cluster));b<-.7*a+rnorm(length(a))
a[c(5,19)]<-NA;b[c(7,20)]<-NA
oracle<-function(a,b) {
  ok<-is.finite(a)&is.finite(b);a<-a[ok];b<-b[ok];n<-length(a);y<-cbind(a,b)
  means<-rowMeans(y);grand<-mean(y)
  msb<-2*sum((means-grand)^2)/(n-1);msw<-sum((y-means)^2)/n
  c(icc=(msb-msw)/(msb+msw),ccc=2*mean((a-mean(a))*(b-mean(b)))/(mean((a-mean(a))^2)+mean((b-mean(b))^2)+(mean(a)-mean(b))^2),mean_a=mean(a),mean_b=mean(b))
}
s<-pair_sums(a,b);actual<-pair_statistics(matrix(colSums(s),1,dimnames=list(NULL,colnames(s))))[1,]
stopifnot(isTRUE(all.equal(actual,oracle(a,b),tolerance=1e-12)))
design<-bootstrap_weights(cluster,90210);fast<-pair_statistics(bootstrap_sums(s,design))
for(j in c(1,2,23,2000)) {
  selected<-rep(seq_len(40),design$weights[j,]);ix<-unlist(lapply(selected,function(k)which(cluster==k)),use.names=FALSE)
  stopifnot(isTRUE(all.equal(unname(fast[j+1,]),unname(oracle(a[ix],b[ix])),tolerance=1e-11)))
}
low<-(a+b)/2;high<-low+rnorm(length(low),.1,.2)
cs<-change_statistics(bootstrap_sums(change_sums(low,high),design))
for(j in c(1,23,2000)) {
  selected<-rep(seq_len(40),design$weights[j,]);ix<-unlist(lapply(selected,function(k)which(cluster==k)),use.names=FALSE)
  ok<-is.finite(low[ix])&is.finite(high[ix]);l<-low[ix][ok];h<-high[ix][ok]
  stopifnot(isTRUE(all.equal(unname(cs[j+1,]),c(mean(h-l),mean(h-l)/sd(h)),tolerance=1e-11)))
}
for(v in list(rep(1,5),rep(.001,5),rep(0,5)))stopifnot(all(is.na(pair_statistics(matrix(colSums(pair_sums(v,v)),1,dimnames=list(NULL,colnames(s))))[1,c('icc','ccc')])))
stopifnot(pair_statistics(matrix(colSums(pair_sums(1:5,5:1)),1,dimnames=list(NULL,colnames(s))))[1,'icc']<0)
stopifnot(all(is.na(interval(rep(.5,2000),19)[1:2])),all(is.na(interval(rep(.5,1899),20)[1:2])))
cat('ANOVA, CCC, unequal-cluster bootstrap, missing data, constants, negative ICC and interval checks passed\n')
