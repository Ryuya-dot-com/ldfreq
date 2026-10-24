# Rscript plot-distributions.R private-base result-directory
args<-commandArgs(TRUE);stopifnot(length(args)==2L)
base<-normalizePath(args[[1]]);out<-args[[2]]
rows<-ecdf_rows<-list()
for(corpus in c('icnale','oanc','bawe')) {
  plan<-readRDS(file.path(base,corpus,'analysis-plan-private.rds'))
  saved<-readRDS(file.path(base,corpus,'extension-metrics-private.rds'))
  groups<-switch(corpus,icnale=c('L2','L1'),oanc=c('written','spoken'),bawe='all')
  for(scope in c('short','long'))for(group in groups) {
    ix<-intersect(plan$cohorts[[scope]],plan$groups[[group]]);if(!length(ix))next
    r<-do.call(rbind,saved$results[ix]);r<-r[r$scope==scope,]
    for(metric in c('mattr','hdd','mtld','mtld_ma')) {
      z<-r[r$metric_id==metric&is.finite(r$value),];pooled<-z$value
      bandwidth<-stats::bw.nrd0(pooled);limits<-range(pooled)+c(-1,1)*3*bandwidth
      for(n in sort(unique(z$length))) {
        values<-z$value[z$length==n];den<-density(values,bw=bandwidth,from=limits[[1]],to=limits[[2]],n=256)
        rows[[length(rows)+1L]]<-data.frame(corpus=corpus,scope=scope,group=group,metric=metric,length=n,
          value=den$x,density=den$y,bandwidth=bandwidth,computed_blocks=length(values))
        if(scope=='short') {
          tab<-table(values);ecdf_rows[[length(ecdf_rows)+1L]]<-data.frame(corpus=corpus,scope=scope,group=group,
            metric=metric,length=n,value=as.numeric(names(tab)),cumulative=cumsum(as.numeric(tab))/length(values))
        }
      }
    }
  }
}
densities<-do.call(rbind,rows);write.csv(densities,file.path(out,'block-densities.csv'),row.names=FALSE)
ecdfs<-do.call(rbind,ecdf_rows);write.csv(ecdfs,file.path(out,'block-ecdf.csv'),row.names=FALSE)
plot_distribution<-function(corpus,scope,group,monochrome=FALSE) {
  source<-if(scope=='short')ecdfs else densities
  z<-source[source$corpus==corpus&source$scope==scope&source$group==group,]
  z$y<-if(scope=='short')z$cumulative else z$density
  z$length<-factor(z$length);z$metric<-factor(z$metric,c('mattr','hdd','mtld','mtld_ma'),c('MATTR','HD-D','MTLD','MTLD-MA'))
  p<-ggplot2::ggplot(z,ggplot2::aes(value,y,colour=length,linetype=length))+
    (if(scope=='short')ggplot2::geom_step(linewidth=.6) else ggplot2::geom_line(linewidth=.6))+
    ggplot2::facet_wrap(~metric,scales='free',ncol=2)+
    ggplot2::labs(x='Score',y=if(scope=='short')'Cumulative proportion' else 'Density',colour='Tokens',linetype='Tokens')+
    ggplot2::theme_classic(base_size=12)+ggplot2::theme(legend.position='bottom')
  p+ggplot2::scale_colour_manual(values=if(monochrome)rep('black',3) else c('#0072B2','#D55E00','#009E73'))
}
for(spec in list(c('icnale','short','L2'),c('oanc','long','written'),c('bawe','long','all'))) {
  p<-plot_distribution(spec[[1]],spec[[2]],spec[[3]])
  stem<-paste(spec[[1]],spec[[2]],'distributions',sep='-')
  ggplot2::ggsave(file.path(out,paste0(stem,'.png')),p,width=7,height=5,dpi=180)
  ggplot2::ggsave(file.path(out,paste0(stem,'.svg')),p,width=7,height=5)
}
