\name{lexdiv_read_texts}
\alias{lexdiv_read_texts}
\title{Read One or More UTF-8 Text Files as Named Raw Documents}
\usage{
lexdiv_read_texts(
  path,
  document_ids = NULL,
  pattern = "[.]txt$",
  recursive = FALSE,
  max_file_bytes = 10 * 1024^2,
  max_total_bytes = 100 * 1024^2
)
}
\arguments{
\item{path}{Either one local directory or a plain character vector containing
one or more explicit local file paths. URLs are not supported.}
\item{document_ids}{Optional explicit document IDs aligned one-to-one with the
selected files. By default, IDs are filename stems. IDs must be unique,
non-empty valid-UTF-8 strings.}
\item{pattern}{Regular expression used only when \code{path} is a directory.
Matching is case-insensitive; the default selects \file{.txt} files.}
\item{recursive}{Whether directory discovery includes subdirectories.}
\item{max_file_bytes}{Maximum allowed size of each file in bytes.}
\item{max_total_bytes}{Maximum combined size of all selected files in bytes.}
}
\description{
Reads explicit local file paths, or discovers files from one local directory,
without tokenizing or otherwise changing their contents. Each file becomes
one scalar character string suitable for \code{lexdiv_metrics_text()}.
}
\details{
Directory discovery is deterministic: files are returned in the order
produced by \code{list.files()}, which is alphabetical for a fixed directory.
Explicit file vectors preserve caller order. A directory with no matching
files, duplicate resolved paths, duplicate derived IDs, unreadable files,
invalid UTF-8, embedded NUL bytes, and size-bound violations are errors.

The function only reads text. Use
\code{lapply(corpus$texts, lexdiv_metrics_text, ...)} to retain a separate token and
preprocessing audit for every raw document. Use
\code{lexdiv_metrics_batch()} only after every document has already been
converted to a token vector.
}
\value{
A \code{lexdiv_text_corpus} list containing \code{texts}, a named character
vector in selected-file order; \code{documents}, a path-private manifest with
document IDs, basenames, byte sizes, and SHA-256 identities; and
\code{provenance}, the versioned reader choices and bounds. Absolute paths are
not retained.
}
\examples{
directory <- tempfile("ldfreq-texts-")
dir.create(directory)
writeLines("One short document.", file.path(directory, "document_a.txt"))
writeLines("Another short document.", file.path(directory, "document_b.txt"))

corpus <- lexdiv_read_texts(directory)
corpus$documents

raw_documents <- lapply(corpus$texts, lexdiv_metrics_text, metrics = "ttr")
raw_documents$document_a$results

unlink(directory, recursive = TRUE)
}
\seealso{\code{\link{lexdiv_text_corpus}},
\code{\link{lexdiv_metrics_text}},
\code{\link{lexdiv_metrics_batch}}}
\keyword{text}
