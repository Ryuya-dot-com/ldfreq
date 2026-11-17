#' Read Nation's cached BNC/COCA Level 6 word-family lists
#'
#' @param include_supplementary One `TRUE` or `FALSE`. When `TRUE`, additionally
#'   attaches `combined` (`rbind(dictionary, supplementary)`) and
#'   `combined_resource` (a resource declaration explicitly recording inclusion
#'   of supplementary lists 31--34) for direct use with [lexdiv_family_profile()].
#' @param cache_dir Optional directory containing verified downloaded resources;
#'   defaults to the configured or user resource cache.
#' @return A list with `dictionary`, `supplementary`, `catalog`, `resource`, and
#'   `provenance` (plus `combined` and `combined_resource` when
#'   `include_supplementary = TRUE`).
#' @export
bnccoca_data <- function(include_supplementary = FALSE, cache_dir = NULL) {
  include_supplementary <- .lexprep_scalar_flag(
    include_supplementary,
    "include_supplementary"
  )
  rds_path <- .lex_resource_file(
    "bnccoca", "extdata", "bnccoca", "ac81c7a6", "bnccoca.rds",
    cache_dir = cache_dir
  )
  result <- readRDS(rds_path)
  if (include_supplementary) {
    combined <- rbind(result$dictionary, result$supplementary)
    rownames(combined) <- NULL
    combined_resource <- result$resource
    combined_resource$family_definition <- paste(
      "Source headword/member grouping in basewrd1-25 (25 frequency/range bands)",
      "plus supplementary lists basewrd31-34 (proper_names, marginal_words,",
      "transparent_compounds, acronyms); Bauer-Nation Level 6 inclusion criteria;",
      "no POS or sense disambiguation."
    )
    result$combined <- combined
    result$combined_resource <- combined_resource
  }
  result
}
