\name{lexdiv_variant_metrics}
\alias{lexdiv_variant_metrics}
\alias{print.lexdiv_variant_results}
\title{Explicit Maas and Sequential-MTLD Comparison Variants}
\description{
Computes a bounded set of formula and aggregation variants without changing
the versioned thirteen-method \code{\link{lexdiv_metrics}} core. Discover
available variant identifiers with \code{lexdiv_methods(scope = "variants")}.
}
\usage{
lexdiv_variant_metrics(
  tokens,
  variants = lexdiv_methods(scope = "variants")$method_id,
  mtld_thresholds = 0.72
)

\method{print}{lexdiv_variant_results}(x, ...)
}
\arguments{
\item{tokens}{An ordered character vector accepted by \code{lexdiv_metrics()}.}
\item{variants}{A non-empty, duplicate-free character vector selected from
\code{lexdiv_methods(scope = "variants")$method_id}.}
\item{mtld_thresholds}{One to 16 distinct finite numbers strictly between zero
and one.}
\item{x}{A \code{lexdiv_variant_results} object.}
\item{...}{Additional arguments passed to \code{print.data.frame()}.}
}
\value{
A \code{lexdiv_variant_results} long data frame with formula, log-base,
factorization, status, and diagnostic columns. \code{print()} returns \code{x}
invisibly.
}
\examples{
tokens <- c(rep("a", 10), "b", "c", "d", "e")
catalog <- lexdiv_methods(scope = "variants")
catalog

variants <- lexdiv_variant_metrics(tokens, mtld_thresholds = c(0.72, 0.92))
variants[, c("family", "method_id", "value", "status")]
}
\seealso{\code{\link{lexdiv_methods}}, \code{\link{lexdiv_metrics}}}
\keyword{text}
