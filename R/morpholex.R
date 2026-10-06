#' Read the bundled MorphoLex English database
#'
#' Returns original worksheet values with source and license metadata. This is
#' a reference-data reader, not a morphological analyzer. See morpholex_data.Rd
#' for the sheet formats, interpretation limits, and CC BY-NC-SA 4.0 terms.
#' @param sheets NULL for all sheets, or a nonempty character vector of unique
#'   worksheet names in the desired order.
#' @return A list with sheets (named data frames) and provenance.
#' @export
morpholex_data <- function(sheets = NULL) {
  if (!is.null(sheets) && (!is.character(sheets) || !length(sheets) ||
      anyNA(sheets) || any(!nzchar(sheets)) || anyDuplicated(sheets))) {
    stop("sheets must be NULL or a nonempty character vector of unique sheet names.", call. = FALSE)
  }
  result <- readRDS(system.file("extdata", "morpholex", "5bc425fb",
    "morpholex_en.rds", package = "ldfreq", mustWork = TRUE))
  if (is.null(sheets)) sheets <- names(result$sheets)
  unknown <- setdiff(sheets, names(result$sheets))
  if (length(unknown)) {
    stop("Unknown MorphoLex sheets: ", paste(unknown, collapse = ", "),
      ". Use morpholex_data()$provenance$sheet_catalog to list available sheets.", call. = FALSE)
  }
  result$sheets <- result$sheets[sheets]
  result$provenance$selected_sheets <- unname(sheets)
  result
}
