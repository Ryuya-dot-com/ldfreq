summarize_external <- function(r,out) {
  r$documented_boundary<-r$metric=='mattr'&r$length==50L&is.finite(r$ours)&is.na(r$external)
  summary<-do.call(rbind,lapply(split(r,interaction(r$corpus,r$scope,r$length,r$metric,drop=TRUE)),function(z){
    finite<-is.finite(z$ours)&is.finite(z$external);delta<-abs(z$ours[finite]-z$external[finite])
    data.frame(corpus=z$corpus[[1]],scope=z$scope[[1]],length=z$length[[1]],metric=z$metric[[1]],blocks=nrow(z),
      comparable=sum(finite),missing_disagreements=sum(!z$same_missing),documented_boundary=sum(z$documented_boundary),
      unexplained_missing_disagreements=sum(!z$same_missing&!z$documented_boundary),
      matches_1e_10=sum(delta<=1e-10),max_abs_difference=max(c(0,delta)))
  }))
  write.csv(summary,file.path(out,'external-comparison.csv'),row.names=FALSE)
  print(aggregate(cbind(blocks,comparable,missing_disagreements,documented_boundary,unexplained_missing_disagreements,matches_1e_10)~metric,summary,sum))
  print(aggregate(max_abs_difference~metric,summary,max))
  stopifnot(all(summary$unexplained_missing_disagreements==0),all(summary$max_abs_difference[summary$metric!='mtld']<1e-10))
  invisible(summary)
}
