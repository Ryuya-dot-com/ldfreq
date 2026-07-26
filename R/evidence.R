# Public metadata for context-specific token-length evidence.

#' Inspect context-specific token-length evidence
#'
#' Returns the evidence and tool-guidance records used to motivate descriptive
#' 50- and 100-token screens. These records do not define computational domains
#' and are not universal validity cutoffs.
#'
#' @return A data frame with one row per metric/evidence relationship.
#' @export
lexdiv_length_evidence <- function() {
  output <- data.frame(
    evidence_id = c(
      "koizumi_2012_mtld_spoken_l2_100",
      "zenker_kyle_2021_mtld_original_written_l2_50",
      "zenker_kyle_2021_mattr_written_l2_50",
      "taaled_0_32_mattr_guidance_50",
      "taaled_0_32_mtld_original_guidance_50",
      "taaled_0_32_hdd_guidance_50",
      "taaled_0_32_maas_guidance_100"
    ),
    source_id = c(
      "koizumi_2012",
      "zenker_kyle_2021",
      "zenker_kyle_2021",
      rep.int("taaled_0_32_documentation", 4L)
    ),
    source_kind = c(
      rep.int("empirical_study", 3L),
      rep.int("versioned_tool_guidance", 4L)
    ),
    metric_id = c("mtld", "mtld", "mattr", "mattr", "mtld", "hdd", "maas"),
    method_scope = c(
      "Gramulator 5.0 raw bidirectional MTLD; target equivalence not asserted",
      "MTLD Original; target equivalence not asserted",
      "MATTR with a 50-token window",
      "TAALED 0.32 MATTR",
      "TAALED 0.32 MTLD Original",
      "TAALED 0.32 expected-TTR-scaled HD-D",
      "TAALED 0.32 Maas variant"
    ),
    floor_tokens = c(100, 50, 50, 50, 50, 50, 100),
    evidence_role = c(
      "context_specific_recommendation",
      "minimum_observed_stable_length",
      "minimum_observed_stable_length",
      "use_with_confidence_tool_guidance",
      "use_with_confidence_tool_guidance",
      "use_with_caution_tool_guidance",
      "use_with_caution_tool_guidance"
    ),
    population = c(
      "20 lower-intermediate Japanese adolescent L2 English learners",
      "4,542 ICNALE L2 English argumentative essays",
      "4,542 ICNALE L2 English argumentative essays",
      rep.int("not one validation population", 4L)
    ),
    modality_genre = c(
      "tape-mediated spoken responses on familiar topics",
      "written argumentative essays",
      "written argumentative essays",
      rep.int("general tool guidance", 4L)
    ),
    target_method_equivalence = c(
      "not_asserted", "not_asserted", "conditional",
      "not_asserted", "not_asserted", "not_asserted", "not_asserted"
    ),
    universal_cutoff = rep.int(FALSE, 7L),
    doi = c(
      "10.7820/vli.v01.1.koizumi",
      "10.1016/j.asw.2020.100505",
      "10.1016/j.asw.2020.100505",
      rep.int(NA_character_, 4L)
    ),
    url = c(
      "https://www.castledown.com/journals/vli/article/download/vli.v01.1.koizumi/213",
      "https://www.sciencedirect.com/science/article/pii/S1075293520300660",
      "https://www.sciencedirect.com/science/article/pii/S1075293520300660",
      rep.int("https://pypi.org/project/taaled/", 4L)
    ),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  row.names(output) <- NULL
  output
}
