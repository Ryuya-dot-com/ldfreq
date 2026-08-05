antbnc_fixture_file <- function(lines = c(
    "be\t->\tam\tbe\tis\twas\twere",
    "go\t->\tgo\tgoes\tgoing\tgone\twent",
    "interest\t->\tinterest\tinterested\tinteresting\tinterests",
    "see\t->\tsaw\tsee\tseen",
    "study\t->\tstudies\tstudy\tstudying"
)) {
  path <- tempfile(fileext = ".txt")
  writeLines(lines, path, useBytes = TRUE)
  path
}
