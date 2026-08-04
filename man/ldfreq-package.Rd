\name{ldfreq-package}
\alias{ldfreq}
\alias{ldfreq-package}
\docType{package}
\title{Reproducible Lexical Diversity Profiles}
\description{
The \pkg{ldfreq} package computes explicitly versioned lexical-diversity
metrics from ordered pre-tokenized character vectors. It returns canonical
long-form records with method, parameter, schema, and contract provenance.
}
\details{
The initial release performs no tokenization, normalization,
lemmatization, or lexical-resource lookup. Start with \code{lexdiv_metrics()}
for one document, \code{lexdiv_metrics_batch()} for multiple documents, or
\code{lexdiv_profile()} for explicit parameter variants.
}
\section{Input boundary}{
The public core accepts ordered, already-tokenized character vectors. It does
not infer token boundaries, change case, normalize Unicode spelling, remove
tokens, or lemmatize. Batch inputs must carry explicit unique document IDs.
}
\section{Results and provenance}{
Metric results are long-form data frames. Read \code{status} and
\code{missing_reason} before \code{value}. Each row records the method, metric
contract, result schema, requested and effective parameters, token/type counts,
the frozen \code{below_quality_floor} field, and method diagnostics. Batch,
profile, and screen layers add separate envelopes without changing the core
record.
}
\section{Direction and contract scale}{
Direction applies only within the exact method, parameters, preprocessing, and
sampling design. Values from different metric IDs are not interchangeable.

\tabular{lll}{
Metric ID \tab Contract scale \tab Conventional score direction \cr
\code{ttr} \tab 0 to 1 \tab higher \cr
\code{rttr} \tab 0 or greater; no finite upper bound \tab higher \cr
\code{cttr} \tab 0 or greater; no finite upper bound \tab higher \cr
\code{herdan} \tab 0 to 1 \tab higher \cr
\code{maas} \tab 0 or greater; no finite upper bound \tab lower \cr
\code{msttr} \tab 0 to 1 \tab higher \cr
\code{mattr} \tab 0 to 1 \tab higher \cr
\code{mtld} \tab 0 or greater; no finite upper bound \tab higher \cr
\code{hdd} \tab 0 to 1 \tab higher \cr
\code{yule_k} \tab 0 inclusive to 10,000 exclusive \tab lower \cr
\code{yule_i} \tab 0 or greater; no finite upper bound \tab higher
}
}
\section{Interpretation boundary}{
The methods primarily operationalize lexical variety and repetition. They are
indices used within the lexical-diversity research domain, but no single score
represents the full multidimensional lexical-diversity construct. The metrics
describe lexical-distribution properties of the supplied tokens.
They are not direct measures of language proficiency, writing quality, reader
response, or communicative effectiveness. Inferring those constructs requires a
separate validated study design and cannot be justified by one score or by the
frozen \code{below_quality_floor} field.
}
\section{Quality screens}{
\code{below_quality_floor} and \code{lexdiv_screen()} are advisory token-count
evidence screens. Here, quality is a frozen field name; it does not mean writing
quality, measurement validity, or reliability. The screens never change a value,
effective parameter, status, or document membership. Passing a screen does not
establish validity or reliability; failing one does not erase an otherwise
computable value.
}
\section{Deferred surfaces}{
Raw-text tokenization, public lexical-resource lookup, and the separately named
expected-TTR D candidate are not part of the v0.1 public core. The installed
TUBELEX development candidate has no exported lookup API and records zero
release-approved resources.
}
\section{Offline smoke test}{
After loading \pkg{ldfreq}, run the installed script returned by
\code{system.file("examples", "offline-smoke.R", package = "ldfreq")}. It
exercises single, batch, profile, profile-batch, and screen workflows without a
network connection or external runtime.
}
\seealso{
\code{\link{lexdiv_metrics}}, \code{\link{lexdiv_profile}}
}
\examples{
metric_ids <- lexdiv_metric_ids()
head(metric_ids)

smoke_path <- system.file("examples", "offline-smoke.R", package = "ldfreq")
stopifnot(nzchar(smoke_path))
source(smoke_path, local = TRUE)
}
\keyword{package}
