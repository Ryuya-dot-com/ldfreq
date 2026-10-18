# Authored synthetic word sequences, not learner observations.
# See vignette("repeated-observations", package = "ldfreq").
helper <- new.env(parent = baseenv())
sys.source(system.file("examples", "study-table.R", package = "ldfreq",
  mustWork = TRUE), helper)

# This example explicitly schedules every writer at both tasks and all visits.
# Use the actual scheduled rows for a design with a different allocation.
planned <- expand.grid(writer_id = sprintf("%03d", 1:18),
  task = c("description", "argument"), occasion = c(0, 4, 8),
  KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
planned$observation_id <- sprintf("obs-%03d", seq_len(nrow(planned)))
planned$task <- factor(planned$task, levels = c("description", "argument"))
contrasts(planned$task) <- stats::contr.treatment(levels(planned$task), base = 1)
planned$scheduled_date <- as.Date("2026-01-05") + 7 * planned$occasion

# Local RNG state prevents sourcing the example from changing the user's RNG.
texts <- local({
  had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (had_seed) old_seed <- get(".Random.seed", envir = .GlobalEnv)
  on.exit(if (had_seed) assign(".Random.seed", old_seed, envir = .GlobalEnv)
    else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
      rm(".Random.seed", envir = .GlobalEnv))
  set.seed(731)
  vocabulary <- c("apple", "bird", "city", "door", "earth", "field", "garden",
    "house", "island", "journey", "kite", "lake", "moon", "night", "ocean",
    "path", "question", "river", "stone", "tree", "umbrella", "valley",
    "water", "year", "cloud", "flower")
  writer_intercept <- stats::runif(18, 0.5, 1.5)
  writer_slope <- stats::runif(18, -0.08, 0.04)
  vapply(seq_len(nrow(planned)), function(i) {
    w <- as.integer(planned$writer_id[i])
    exponent <- writer_intercept[w] + writer_slope[w] * planned$occasion[i] +
      ifelse(planned$task[i] == "argument", 0.15, 0)
    paste(sample(vocabulary, 80, replace = TRUE,
      prob = seq_along(vocabulary)^(-exponent)), collapse = " ")
  }, character(1))
})

# Deliberate edge cases: absent, empty, no words, short, withheld, unknown writer.
texts[2:4] <- c("", "... !!!", "apple bird apple")
planned$writer_id[6] <- NA_character_
submitted_rows <- 2:nrow(planned)
texts <- setNames(texts[submitted_rows], sprintf("doc-%03d", submitted_rows))
submissions <- data.frame(observation_id = planned$observation_id[submitted_rows],
  document_id = names(texts), input_characters = nchar(texts, type = "chars"),
  stringsAsFactors = FALSE, row.names = NULL)
condition <- list(id = "english-surface-lower", tokenizer = "english",
  normalization = "NFC", case = "lower", keep_numbers = FALSE,
  unit = "surface", inclusion = "all tokens returned by lexdiv_tokenize_batch",
  resources = "No external annotation model or lexical reference resource")
prepared <- ldfreq::lexdiv_tokenize_batch(texts, tokenizer = condition$tokenizer,
  normalization = condition$normalization, case = condition$case,
  keep_numbers = condition$keep_numbers)
tokens <- lapply(prepared, function(x) x$tokens$surface)
plan <- ldfreq::lexdiv_plan(presets = character(), specs = list(
  ldfreq::lexdiv_spec("ttr_v_over_n_v1", request_id = "ttr"),
  ldfreq::lexdiv_spec("mattr_sliding_step1_v1", list(window_length = 10),
    request_id = "mattr10")))
results <- ldfreq::lexdiv_metrics_batch(tokens, plan = plan)
reporting <- as.data.frame(results)[c("document_id", "request_id")]
reporting$reporting_status <- "report"
reporting$reporting_reason <- "No additional reporting restriction in this illustration"
held <- reporting$document_id == "doc-005"
reporting$reporting_status[held] <- "withhold"
reporting$reporting_reason[held] <- "Authored example of an unresolved document review"
study <- helper$study_long_table(planned, submissions, results, plan,
  condition$id, reporting)
selection <- list(condition_id = condition$id, request_id = "mattr10",
  required = c("writer_id", "task", "occasion"))
selected <- do.call(helper$study_model_data, c(list(study = study), selection))

record <- list(example = "Synthetic word sequences for a workflow illustration",
  planned = planned, submissions = submissions, texts = texts,
  condition = condition, prepared = prepared, tokens = tokens, plan = plan,
  results = results, reporting = reporting, study = study,
  selection = selection, selected = selected,
  model_formula = stats::as.formula(
    "value ~ occasion + task + (1 + occasion | writer_id)", env = baseenv()),
  session = utils::sessionInfo())
invisible(record)
