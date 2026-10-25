\name{plot.lexdiv_results}
\alias{plot.lexdiv_results}
\alias{plot.lexdiv_batch_results}
\alias{plot.lexdiv_profile_results}
\alias{plot.lexdiv_profile_batch_results}
\alias{plot.lexdiv_text_results}
\alias{plot.lexdiv_screen_results}
\alias{plot.tubelex_profile}
\title{Plot one metric, a length screen or TUBELEX coverage}
\usage{
\method{plot}{lexdiv_results}(x, metric_id = NULL, request_id = NULL,
  col = NULL, pch = 19, main = NULL, xlab = "", ylab = NULL, ...,
  monochrome = FALSE)

\method{plot}{lexdiv_batch_results}(x, metric_id = NULL, request_id = NULL,
  col = NULL, pch = 19, main = NULL, xlab = "", ylab = NULL, ...,
  monochrome = FALSE)

\method{plot}{lexdiv_profile_results}(x, metric_id = NULL, request_id = NULL,
  col = NULL, pch = 19, main = NULL, xlab = "", ylab = NULL, ...,
  monochrome = FALSE)

\method{plot}{lexdiv_profile_batch_results}(x, metric_id = NULL,
  request_id = NULL, col = NULL, pch = 19, main = NULL, xlab = "",
  ylab = NULL, ..., monochrome = FALSE)

\method{plot}{lexdiv_text_results}(x, ..., monochrome = FALSE)

\method{plot}{lexdiv_screen_results}(x, screen_id = NULL, col = NULL,
  pch = 19, main = NULL, xlab = "document / request", ylab = "tokens",
  ..., monochrome = FALSE)

\method{plot}{tubelex_profile}(x, col = "#0072B2", main = NULL,
  ylab = "coverage", ..., monochrome = FALSE)
}
\arguments{
\item{x}{A supported lexical-diversity, length-screen or TUBELEX result.}
\item{metric_id}{One exact metric ID. May be omitted only for a single-metric result.}
\item{request_id}{An optional profile request ID to select.}
\item{screen_id}{One screen ID. May be omitted only for a single-screen result.}
\item{col, pch, main, xlab, ylab}{Base-graphics settings. Metric points below
 the advisory token floor are orange triangles; other finite results are blue
 circles. Explicit \code{pch} overrides the default symbols.}
\item{monochrome}{One \code{TRUE} or \code{FALSE}; specify by name.
 \code{TRUE} overrides \code{col} with black (gray for TUBELEX bars).
 Point symbols are retained. Defaults to color.}
\item{...}{Additional base-graphics arguments, including \code{axes},
 \code{xaxt}, \code{cex.axis}, \code{family}, \code{las} and \code{bty}.
 TUBELEX bars use fixed category labels and a fixed zero-to-one scale;
 \code{height}, \code{horiz}, \code{offset}, \code{add}, \code{log},
 \code{plot}, \code{ylim} and \code{names.arg} are rejected for that plot.}
}
\description{Draws a single measurement specification and invisibly returns
its selected rows. Different metrics or parameter settings are not combined
on one scale.}
\value{The selected data frame, invisibly. Metric plots retain missing rows
as well as computed rows. Original results are unchanged.}
\details{
Metric plots require a single specification, including when all rows share
the same metric ID. Select a request or subset the input by specification.
Their invisible return contains \code{label} followed by the complete selected
result rows, including parameter and contract columns. Only finite rows with
\code{status = "ok"} receive points. Other rows retain their horizontal
positions labelled \dQuote{not computed}; they are not drawn at zero.
All selected rows participate in the specification check. A selection with
no finite \code{ok} value raises an error. TUBELEX plots
show token- and type-weighted match coverage on a fixed zero-to-one scale. All
plot methods return the plotted data invisibly for testing and reuse.
Plots have no automatic title. A sans serif font, horizontal tick labels and
an open frame are used by default. Override these with \code{family},
\code{las} or \code{bty} in \code{...}; cosmetic graphics parameters are
restored after drawing, including after an error. The default metric y-axis
label is the uppercase metric ID, except for \dQuote{TTR (V/N)}.
Place figure numbers, titles and notes outside the image in the manuscript.
Explicit \code{main} remains available for custom base graphics.
TTR uses a zero-to-one scale by default (override with \code{ylim}) and
includes token counts in the horizontal labels. Equal measurement
specifications do not make unequal-length TTR values comparable. TTR has no
advisory token floor; a blue circle does not establish adequate precision.
For length diagnostics use a scatterplot of \code{N} against \code{value},
retaining task and writer information. For large batches, use explicit
grouped plots instead of crowded document labels. See the installed
\code{choosing-metrics} guide for controlled-length evidence and sampling
reliability.
\code{plot.lexdiv_text_results()} delegates to the unchanged
\code{results} component, so it accepts the same metric-selection arguments
and does not plot preprocessing coverage on a metric scale.

\code{axes = FALSE} suppresses both axes; \code{xaxt = "n"} suppresses
only the horizontal axis, including manually drawn document labels.
\code{cex.axis}, \code{col.axis} and \code{font.axis} also apply to those
labels. Graphics settings are restored after drawing or an error.
}
\examples{
long <- lexdiv_metrics_batch(list(a = c("one", "two", "one"),
  empty = character(), b = c("one", "two", "three")),
  metrics = c("ttr", "maas"))
plot(long, metric_id = "ttr")
plot(long, metric_id = "ttr", monochrome = TRUE, cex.axis = 0.9)
text_result <- lexdiv_metrics_text("Words repeat words.", metrics = "ttr")
plot(text_result)

# Only this optional profile needs downloaded reference data.
if (lexdiv_resource_info("tubelex")$available) {
  profile <- tubelex_profile(c("the", "not-in-resource"))
  plot(profile)
}
}
\seealso{\code{\link{lexdiv_widen}}, \code{\link{nj8_profile}},
\code{\link{plot.lexdiv_mattr_profile}},
\code{\link{lexdiv_reference_coverage}}, \code{\link{lexdiv_concordance}}.}
