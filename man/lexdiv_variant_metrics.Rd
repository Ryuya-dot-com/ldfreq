\name{lexdiv_variant_metrics}
\alias{lexdiv_variant_ids}
\alias{lexdiv_variant_metrics}
\title{Explicit Maas and sequential-MTLD comparison variants}
\description{
List or compute a bounded set of formula and aggregation variants without
changing the frozen eleven-method \code{lexdiv_metrics()} core.
}
\usage{
lexdiv_variant_ids()

lexdiv_variant_metrics(
  tokens,
  variants = lexdiv_variant_ids()$method_id,
  mtld_thresholds = 0.72
)
}
\arguments{
\item{tokens}{A plain ordered character vector accepted by
\code{lexdiv_metrics()}.}
\item{variants}{A plain, non-empty, duplicate-free character vector selected
from the \code{method_id} column returned by \code{lexdiv_variant_ids()}.}
\item{mtld_thresholds}{One to 16 distinct finite numbers strictly between zero
and one. Each requested MTLD method is expanded over these thresholds.}
}
\details{
The Maas rows distinguish \eqn{a} from \eqn{a^2} and natural-log from
base-10 definitions. These transformations are not numerically
interchangeable, even where they preserve rank order.

The MTLD rows distinguish the frozen \pkg{ldfreq} directional-score mean from
three final-tail factorization and mean-factor-length aggregations. Factor
lengths and proportions remain available in the diagnostics list-column.

Rows described as TAALED-relevant comparators identify only their documented
formula, factorization, and aggregation scope. They do not assert official or
end-to-end TAALED compatibility: preprocessing, invalid-input policy,
short-text handling, and licensed source-code identity remain outside that
claim. No third-party code is included or translated.
}
\value{
\code{lexdiv_variant_ids()} returns a method catalog.
\code{lexdiv_variant_metrics()} returns a \code{lexdiv_variant_results} long
data frame. Maas rows occur once per method; MTLD rows occur once per
method-threshold combination. Contract identity, status, missing reason,
parameters, counts, reference label, comparison scope, and diagnostics are
explicit columns.
}
\examples{
tokens <- c(rep("a", 10), "b", "c", "d", "e")

catalog <- lexdiv_variant_ids()
catalog

variants <- lexdiv_variant_metrics(
  tokens,
  mtld_thresholds = c(0.72, 0.92)
)
variants[, c("family", "method_id", "value", "status")]
}
\seealso{\code{\link{lexdiv_metrics}}, \code{\link{lexdiv_preprocessing}}}
\keyword{text}
