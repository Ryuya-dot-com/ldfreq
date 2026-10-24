pair_sums <- function(a,b) {
  ok<-is.finite(a)&is.finite(b);a[!ok]<-0;b[!ok]<-0
  cbind(n=as.numeric(ok),a=a,b=b,aa=a*a,bb=b*b,ab=a*b)
}
pair_statistics <- function(s) {
  s<-as.matrix(s);n<-s[,'n'];ma<-s[,'a']/n;mb<-s[,'b']/n
  between<-2*((s[,'aa']+2*s[,'ab']+s[,'bb'])/4-(s[,'a']+s[,'b'])^2/(4*n))/(n-1)
  within<-(s[,'aa']+s[,'bb']-2*s[,'ab'])/(2*n)
  denom<-between+within
  icc<-(between-within)/denom
  ccc_denom<-(s[,'aa']+s[,'bb'])/n-2*ma*mb
  ccc<-2*(s[,'ab']/n-ma*mb)/ccc_denom
  tol<-1e-13*pmax(1,(s[,'aa']+s[,'bb'])/pmax(n,1))
  icc[n<3|!is.finite(denom)|denom<=tol]<-NA_real_
  ccc[n<3|!is.finite(ccc_denom)|ccc_denom<=tol]<-NA_real_
  cbind(icc=icc,ccc=ccc,mean_a=ma,mean_b=mb)
}
mean_sums <- function(a,b) {
  oka<-is.finite(a);okb<-is.finite(b);a[!oka]<-0;b[!okb]<-0
  cbind(n=as.numeric(oka)+as.numeric(okb),sum=a+b,square=a*a+b*b)
}
change_sums <- function(low,high) {
  ok<-is.finite(low)&is.finite(high);low[!ok]<-0;high[!ok]<-0
  cbind(n=as.numeric(ok),low=low,high=high,high2=high*high)
}
change_statistics <- function(s) {
  s<-as.matrix(s);n<-s[,'n'];delta<-(s[,'high']-s[,'low'])/n
  variance<-(s[,'high2']-s[,'high']^2/n)/(n-1)
  std<-delta/sqrt(pmax(0,variance));std[n<3|variance<=1e-13*pmax(1,s[,'high2']/pmax(n,1))]<-NA_real_
  delta[n<3]<-NA_real_;cbind(change=delta,standardized=std)
}
cluster_info <- function(cluster,ok=rep(TRUE,length(cluster))) {
  counts<-table(cluster[ok]);c(clusters=length(counts),largest_share=if(length(counts))max(counts)/sum(counts) else NA_real_)
}
bootstrap_weights <- function(cluster,seed,B=2000L) {
  levels<-sort(unique(cluster));index<-match(cluster,levels);set.seed(seed)
  list(index=index,weights=if(length(levels)>=20L)t(rmultinom(B,length(levels),rep(1/length(levels),length(levels)))) else NULL)
}
bootstrap_sums <- function(s,design) {
  observed<-matrix(colSums(s),nrow=1L,dimnames=list(NULL,colnames(s)))
  if(is.null(design$weights))return(observed)
  totals<-rowsum(s,design$index,reorder=TRUE)
  rbind(observed,design$weights%*%totals)
}
interval <- function(x,clusters) {
  x<-x[is.finite(x)];valid<-length(x)>=1900L&&clusters>=20L
  q<-if(valid)quantile(x,c(.025,.975),names=FALSE) else c(NA_real_,NA_real_)
  c(lower=q[[1]],upper=q[[2]],finite=length(x))
}
rank_agreement <- function(a,b) {
  ok<-is.finite(a)&is.finite(b);a<-a[ok];b<-b[ok]
  if(length(a)<3L||sd(a)==0||sd(b)==0)NA_real_ else cor(a,b,method='spearman')
}
