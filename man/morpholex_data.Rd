\name{morpholex_data}
\alias{morpholex_data}
\title{Read the Bundled MorphoLex English Database}
\usage{
morpholex_data(sheets = NULL)
}
\arguments{
\item{sheets}{\code{NULL} for all 34 worksheets, or a nonempty character vector
of unique worksheet names in the desired order. Unknown names are errors.}
}
\description{
Reads the bundled MorphoLex-en worksheet values without downloading data or
requiring Excel, \pkg{readxl}, Python, or a model. This is a reference-data
reader, not a morphological analyzer.
}
\value{
A plain list with two components:
\describe{
\item{\code{sheets}}{Named data frames, one per selected worksheet. All columns
are character; empty cells are \code{NA}. Numeric measures require explicit
conversion with \code{as.numeric()}. IDs, case, spelling, sheet/row order, and
cell whitespace are retained. The Presentation sheet uses generated column
names; other sheets use the original header row.}
\item{\code{provenance}}{Resource ID/version, source URL/file and SHA-256,
reference, data license and license URL, data-dictionary SHA-256, transformation
ID/description, build-time readxl version, complete sheet catalog
(\code{sheet}, \code{rows}, \code{columns}, \code{start_row},
\code{start_column}), and selected sheet names. Start positions are one-based
Excel coordinates of the occupied region, including the header where present.
The resource version is the original workbook SHA-256.}
}
}
\details{
The snapshot contains 68,624 word records across 30 prefix-root-suffix (PRS)
sheets, 142 prefix rows, 240 suffix rows, 15,471 root rows, and the Presentation
sheet. These counts describe this snapshot, not distinct spellings or a
validated vocabulary-size scale. Differently shaped sheets are kept separate.
Word sheets retain \code{ELP_ItemID}, \code{Word}, \code{POS}, \code{Nmorph},
\code{PRS_signature}, \code{MorphoLexSegm}, and all available root/affix columns.
The three aggregate sheets are named \code{All prefixes}, \code{All suffixes},
and \code{All roots}.

Segmentation uses canonical morphemes and excludes inflection. For example,
\code{teachers} is represented with teach and -er, without plural -s.
Unlisted words do not have a known zero morpheme count. The six entries on
\code{0-0-0} retain the source's classification and are not silently discarded.
MorphoLex root/affix family sizes, cumulative HAL frequencies, whole-word
frequency, and counts in a user's corpus are different quantities. The data
do not establish learner knowledge, synchronic transparency, or educational
word-family membership.

All worksheet values are retained as text; workbook formatting and formulas
are not retained. Blank exterior margins are omitted. Numeric and logical
cells use R text representation; the source \code{Word} cells for ELP IDs
42162 and 65908 are logical values and read as \code{TRUE} and \code{FALSE}.
Exact lowercase queries do not match these uppercase values. No linguistic
corrections or inferred parts are added.
The bundled original data dictionary describes the variables, including PFMF,
family size, HAL frequency, P, and P*. Its path is shown in the examples.
The explicitly sourced \file{examples/morpholex-word-parts.R} recipe selects
word records and extracts supported canonical parts for the accompanying
word-parts recipe. That recipe is not an exported morphology API.
}
\section{License and attribution}{
MorphoLex-en data and the original data dictionary are distributed under
CC BY-NC-SA 4.0, not the MIT license of the independent ldfreq code.
The license permits noncommercial sharing and adaptation subject to
attribution, change notices, and the applicable ShareAlike conditions.
It does not grant commercial-use permission. See
\url{https://creativecommons.org/licenses/by-nc-sa/4.0/} and the installed
\file{licenses/morpholex/NOTICE.md} and \file{CC-BY-NC-SA-4.0.md}.
Cite the resource paper when using these data; package citation alone is not
resource attribution. Original authors do not endorse this R conversion.
}
\references{
Sánchez-Gutiérrez, C. H., Mailhot, H., Deacon, S. H., and Wilson, M. A. (2018).
MorphoLex: A derivational morphological database for 70,000 English words.
\emph{Behavior Research Methods}, 50, 1568--1580.
\doi{10.3758/s13428-017-0981-8}.
}
\source{\url{https://github.com/hugomailhot/MorphoLex-en}}
\seealso{\code{\link{bnccoca_data}},
\href{https://ryuya-dot-com.github.io/ldfreq/articles/word-families-and-affixes.html}{Word families, roots and affixes tutorial}.
The tutorial explains how to source the word-parts recipes; those helpers
are not exported package functions.}
\examples{
# "0-1-1" is a source worksheet: zero prefixes, one root, one suffix.
reference <- morpholex_data(c("0-1-1", "All roots"))
words <- reference$sheets[["0-1-1"]]
words[words$Word \%in\% c("teacher", "teachers"),
      c("Word", "MorphoLexSegm", "ROOT1_FamSize", "ROOT1_Freq_HAL")]
# Both records contain teach and -er. Plural -s is outside this resource's scope.
roots <- reference$sheets[["All roots"]]
roots$HAL_freq <- as.numeric(roots$HAL_freq)
reference$provenance$data_license
dictionary_path <- system.file("extdata", "morpholex", "5bc425fb",
                               "MorphoLEX_en-Data_Dictionary.pdf", package = "ldfreq")
}
