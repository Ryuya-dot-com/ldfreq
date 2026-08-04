\name{lexdiv_length_evidence}
\alias{lexdiv_length_evidence}
\title{Inspect Context-Specific Token-Length Evidence}
\usage{
lexdiv_length_evidence()
}
\value{
A data frame with one row per metric/evidence relationship. Columns retain the
source kind, metric and method scope, token floor, evidence role, population,
modality/genre, target-method equivalence status, universal-cutoff flag, DOI,
and URL.
}
\description{
Returns the empirical-study and versioned-tool-guidance records that motivate
descriptive 50- and 100-token screens. The records do not define computational
domains, suppress values, or claim universal validity cutoffs.
}
\details{
The 100-token MTLD record concerns Koizumi's study of 20 lower-intermediate
Japanese adolescent L2 English speakers. The 50-token records from Zenker and
Kyle concern 4,542 written L2 argumentative essays and use 50 as the minimum
observed segment length. TAALED 0.32 versioned usage guidance is identified separately
as versioned tool guidance rather than primary empirical evidence.

Method equivalence is not inferred from a shared metric label. In particular,
the evidence table does not assert that Gramulator, TAALED, or another package's
MTLD implementation is numerically identical to the frozen target method.
}
\examples{
evidence <- lexdiv_length_evidence()
evidence[evidence$metric_id == "mtld", ]
}
