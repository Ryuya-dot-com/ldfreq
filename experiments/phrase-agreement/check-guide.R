# Repository-only checks for the guide-local recipe; no new package dependency.
# R_LIBS should select the already installed ldfreq >= 0.3.0.9003.
# Usage: Rscript --vanilla experiments/phrase-agreement/check-guide.R REPO OUTPUT
args <- commandArgs(trailingOnly = TRUE)
repo <- normalizePath(if (length(args)) args[1] else ".", mustWork = TRUE)
output <- if (length(args) > 1L) args[2] else tempfile("phrase-agreement-check-")
dir.create(output, recursive = TRUE, showWarnings = FALSE)
stopifnot(utils::packageVersion("ldfreq") >= "0.3.0.9003",
  requireNamespace("irr", quietly = TRUE), isTRUE(l10n_info()[["UTF-8"]]))
guide <- readLines(file.path(repo, "vignettes", "annotated-corpora.Rmd"), encoding = "UTF-8")
chunk <- function(label) {
  start <- grep(paste0("^```\\{r ", label, "[,}]"), guide)
  stopifnot(length(start) == 1L)
  end <- which(seq_along(guide) > start & guide == "```")[1]
  parse(text = guide[seq.int(start + 1L, end - 1L)])
}
env <- new.env()
sys.source(system.file("examples", "phrase-review-demo.R", package = "ldfreq",
  mustWork = TRUE), env)
labels <- c("phrase-agreement-function", "phrase-agreement-example",
  "phrase-agreement-kappa", "phrase-agreement-published-check",
  "phrase-agreement-discussion", "phrase-agreement-save")
for (label in labels) eval(chunk(label), env)
x <- env$phrase_comparison
s <- x$summary
stopifnot(identical(s$phrase_id, c("departure", "departure_long", "hindrance", "absent")),
  identical(s$occurrences, c(4L, 2L, 4L, 0L)),
  identical(s$both_decided, c(2L, 0L, 2L, 0L)),
  identical(s$agreement, c(1L, 0L, 2L, 0L)),
  identical(s$incomplete, c(2L, 2L, 2L, 0L)),
  identical(s$observed_agreement, c(.5, NA_real_, 1, NA_real_)),
  identical(s$a_accepted, c(1L, 0L, 1L, 0L)),
  identical(s$b_accepted, c(2L, 0L, 1L, 0L)),
  nrow(x$status_counts) == 64L, sum(x$status_counts$occurrences) == 10L,
  nrow(x$review_queue) == 7L, sum(x$pairs$outcome == "incomplete") == 6L,
  identical(env$phrase_kappa$kappa, c(0, NA_real_, 1, NA_real_)),
  identical(env$review_a$source$source$tokens, env$after_discussion$source$source$tokens),
  nrow(env$discussion_log) == 3L, nrow(env$phrase_profiles) == 18L,
  identical(env$review_a$documents$accepted_covered_tokens, c(3L,0L,4L,0L,0L,0L)),
  identical(env$review_b$documents$accepted_covered_tokens, c(4L,0L,4L,4L,0L,0L)),
  identical(env$after_discussion$documents$accepted_covered_tokens, c(3L,0L,4L,4L,0L,0L)),
  is.na(env$review_b$documents$reportable_accepted_coverage[1]),
  identical(env$agreement_restored, env$agreement_record))
saved_kappa <- readRDS(file.path(env$phrase_review_dir, "kappa.rds"))
stopifnot(identical(saved_kappa$comparison, x),
  identical(saved_kappa$estimates, env$phrase_kappa),
  identical(saved_kappa$irr_version, as.character(utils::packageVersion("irr"))))
expect_error <- function(expr) {
  error <- tryCatch({force(expr); NULL}, error = identity)
  stopifnot(inherits(error, "error"))
  conditionMessage(error)
}
compare <- env$compare_phrase_reviews
a <- env$review_a; b <- env$review_b; ids <- x$reviewers
rejections <- c(
  same_rater = expect_error(compare(a, b, rep(ids[1], 2))),
  wrong_rater = expect_error(compare(a, b, c(ids[1], "someone-else"))),
  blank_rater = expect_error(compare(a, b, c(ids[1], " "))))
sheet <- b$worksheet
sheet$reviewer[which(sheet$status != "unreviewed")[1]] <- ids[1]
mixed <- env$phrase_list_review(b$source, b$criterion, sheet)
rejections <- c(rejections, mixed_raters = expect_error(compare(a, mixed, ids)))
altered <- a; altered$documents$accepted[1] <- 999L
rejections <- c(rejections, edited_result = expect_error(compare(altered, b, ids)))
sheet <- b$worksheet[-1, ]
rejections <- c(rejections, missing_row = expect_error(
  env$phrase_list_review(b$source, b$criterion, sheet)))
sheet <- rbind(b$worksheet, b$worksheet[1, ])
rejections <- c(rejections, duplicate_row = expect_error(
  env$phrase_list_review(b$source, b$criterion, sheet)))
changed <- env$phrase_list_review(b$source, paste(b$criterion, "New rule."))
rejections <- c(rejections, changed_criterion = expect_error(compare(a, changed, ids)))
changed_search <- env$phrase_list_kwic(env$phrase_annotations, env$review_phrases,
  env$phrase_resource, env$phrase_keep, window = 2L)
changed <- env$phrase_list_review(changed_search, b$criterion)
rejections <- c(rejections, changed_context = expect_error(compare(a, changed, ids)))
stopifnot(identical(compare(a, env$phrase_list_review(b$source, b$criterion,
  b$worksheet[rev(seq_len(nrow(b$worksheet))), ]), ids), x))

# No paired decision is different from perfect agreement or zero agreement.
pending <- env$phrase_before
none <- compare(pending, pending, c("not-started-A", "not-started-B"))
stopifnot(all(none$summary$both_decided == 0L),
  all(is.na(none$summary$observed_agreement)), nrow(none$review_queue) == 10L)
nohit_search <- env$phrase_list_kwic(env$phrase_annotations,
  list(absent = c("not", "present")), env$phrase_resource, env$phrase_keep)
nohit <- env$phrase_list_review(nohit_search, a$criterion)
empty <- compare(nohit, nohit, c("A", "B"))
stopifnot(nrow(empty$pairs) == 0L, nrow(empty$review_queue) == 0L,
  nrow(empty$summary) == 1L, empty$summary$occurrences == 0L,
  is.na(empty$summary$observed_agreement), nrow(empty$reviews[[1]]$documents) == 6L)

# Constant labels: observed agreement 1, but kappa is undefined.
constant <- function(id) {
  sheet <- a$worksheet
  sheet$status <- "accepted"; sheet$reviewer <- id; sheet$reason <- "Authored edge case."
  env$phrase_list_review(a$source, a$criterion, sheet)
}
env$phrase_comparison <- compare(constant("A"), constant("B"), c("A", "B"))
eval(chunk("phrase-agreement-kappa"), env)
stopifnot(all(is.na(env$phrase_kappa$kappa)), identical(env$phrase_kappa$status,
  c(rep("constant_single_category", 3), "no_paired_decisions")))
env$phrase_comparison <- x
eval(chunk("phrase-agreement-kappa"), env)

# Published count tables, checked independently of the phrase helper.
# Matrices are row-major (rater A) with columns for rater B.
tables <- list(artstein_poesio_table1 = c(20L,10L,20L,50L),
  di_eugenio_glass_example3 = c(90L,5L,5L,0L),
  di_eugenio_glass_example4 = c(45L,5L,5L,45L),
  di_eugenio_glass_example5 = c(40L,15L,20L,25L),
  di_eugenio_glass_example6 = c(40L,35L,0L,25L))
expected_kappa <- c(8/23, -1/19, .8, 2/7, 4/11)
printed_kappa <- c(.348, -.048, .8, .27, .418)
rounding_tolerance <- c(.0005, .0005, .005, .005, .0005)
audit <- do.call(rbind, lapply(seq_along(tables), function(i) {
  counts <- matrix(tables[[i]], 2, 2, byrow = TRUE)
  ratings <- data.frame(a = rep(c("yes","yes","no","no"), tables[[i]]),
    b = rep(c("yes","no","yes","no"), tables[[i]]))
  estimate <- irr::kappa2(ratings, weight = "unweighted")$value
  stopifnot(isTRUE(all.equal(estimate, expected_kappa[i], tolerance = 1e-12)))
  data.frame(example = names(tables)[i], n = sum(counts),
    observed_agreement = sum(diag(counts))/sum(counts),
    kappa = estimate, expected_from_counts = expected_kappa[i],
    printed_kappa = printed_kappa[i],
    matches_printed_rounding = abs(estimate - printed_kappa[i]) <= rounding_tolerance[i],
    irr_version = as.character(utils::packageVersion("irr")))
}))
utils::write.csv(audit, file.path(output, "coefficient-audit.csv"), row.names = FALSE)
saveRDS(list(record = env$agreement_record, kappa = env$phrase_kappa,
  rejection_messages = rejections, coefficient_audit = audit, session = sessionInfo()),
  file.path(output, "guide-validation.rds"), version = 2)
cat("Six guide chunks, authored counts and coverage, nine rejection cases, reordered worksheets,\n",
  "empty/pending/constant cases, saved replay and five published coefficient tables passed.\n", sep = "")
