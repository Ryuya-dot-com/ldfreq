# Source in an environment containing the fitted `record` from the
# repeated-observations guide. This is a fixed reporting recipe, not a model API.
for (dependency in c("lme4", "emmeans", "pbkrtest")) {
  if (!requireNamespace(dependency, quietly = TRUE))
    stop("This example requires optional package: ", dependency, call. = FALSE)
}
stopifnot(is.list(record), inherits(record$model$fit, "lmerMod"))
fit <- record$model$fit
model_data <- record$selected$data
model_frame <- stats::model.frame(fit)
if (!lme4::isREML(fit))
  stop("This recipe requires a REML fit; it does not refit the model.", call. = FALSE)
if (!nrow(model_data) ||
    !all(model_data$method_id == "mattr_sliding_step1_v1") ||
    !all(vapply(model_data$requested_parameters,
      function(p) identical(as.numeric(p$window_length), 10), logical(1))))
  stop("This recipe reports the saved MATTR10 specification only.", call. = FALSE)
if (!identical(rownames(model_frame), model_data$observation_id))
  stop("Model rows must match the selected observation IDs.", call. = FALSE)
for (column in c("value", "occasion", "task", "writer_id")) {
  if (!isTRUE(all.equal(as.character(model_frame[[column]]),
                       as.character(model_data[[column]]))))
    stop("Model data differ from the saved selection: ", column, call. = FALSE)
}
if (!is.numeric(model_data$occasion) ||
    !setequal(levels(model_data$task), c("description", "argument")))
  stop("This recipe requires numeric weeks and the two named tasks.", call. = FALSE)

diagnostics <- list(
  optimizer_code = fit@optinfo$conv$opt,
  convergence_messages = fit@optinfo$conv$lme4$messages,
  fitting_warnings = record$model$diagnostics$warnings,
  fitting_messages = record$model$diagnostics$messages,
  singular = lme4::isSingular(fit, tol = 1e-4),
  singular_tolerance = 1e-4,
  dropped_fixed_columns = attr(lme4::getME(fit, "X"), "col.dropped")
)
observations <- model_data[c("observation_id", "document_id", "writer_id",
  "task", "occasion", "value")]
observations$fitted <- as.numeric(stats::fitted(fit))
observations$residual <- as.numeric(stats::residuals(fit))
diagnostics$conditional_fitted_outside_response_bounds <-
  observations$observation_id[observations$fitted < 0 | observations$fitted > 1]

inference <- list(
  status = "model_diagnostics_require_review",
  settings = list(
    response = "MATTR10", unit = "original 0-1 scale",
    weeks = c(0, 4, 8), tasks = c("description", "argument"),
    task_weights = c(description = 0.5, argument = 0.5),
    target = "Population mean under the fitted Gaussian identity-link model",
    contrast = "week 8 minus week 0, equal weights for the two named tasks",
    level = 0.95, adjustment = "none",
    interval = "pointwise confidence intervals; one planned contrast",
    df_method = "kenward-roger",
    prediction_interval = FALSE
  ),
  diagnostics = diagnostics,
  observations = observations,
  observation_ids = model_data$observation_id,
  writers = length(unique(model_data$writer_id)),
  selection_audit = record$selected$audit,
  tables = NULL,
  versions = vapply(c("ldfreq", "lme4", "emmeans", "pbkrtest"),
    function(x) as.character(utils::packageVersion(x)), character(1))
)
issues <- c(
  if (any(diagnostics$optimizer_code != 0)) "optimizer",
  if (length(diagnostics$convergence_messages)) "convergence",
  if (length(diagnostics$fitting_warnings)) "fitting_warning",
  if (diagnostics$singular) "singular",
  if (length(diagnostics$dropped_fixed_columns)) "rank_deficient"
)
inference$diagnostics$issues <- issues

# Keep an inspectable record even when model diagnostics block interval reporting.
if (!length(issues)) {
  estimation_warnings <- estimation_messages <- character()
  grid <- withCallingHandlers(
    emmeans::emmeans(fit, ~ occasion * task,
      at = list(occasion = inference$settings$weeks,
        task = inference$settings$tasks),
      lmer.df = "kenward-roger", disable.pbkrtest = FALSE,
      pbkrtest.limit = 3000),
    warning = function(w)
      estimation_warnings <<- c(estimation_warnings, conditionMessage(w)),
    message = function(m)
      estimation_messages <<- c(estimation_messages, conditionMessage(m))
  )
  if (!identical(attr(grid@dffun, "mesg"), "kenward-roger"))
    stop("Kenward-Roger was not used; no substitute method is accepted.",
      call. = FALSE)
  cells <- as.data.frame(stats::confint(grid, level = 0.95, adjust = "none"))
  week_grid <- emmeans::emmeans(grid, ~ occasion, weights = "equal")
  weeks <- as.data.frame(stats::confint(week_grid, level = 0.95, adjust = "none"))
  # Derive coefficients from labels, not from a presumed reference-grid order.
  coefficients <- as.numeric(weeks$occasion == 8) -
    as.numeric(weeks$occasion == 0)
  planned <- emmeans::contrast(week_grid,
    list(week_8_minus_0 = coefficients), adjust = "none")
  comparison <- as.data.frame(stats::confint(planned,
    level = 0.95, adjust = "none"))
  cells$observed_n <- vapply(seq_len(nrow(cells)), function(i)
    sum(model_data$task == cells$task[i] &
      model_data$occasion == cells$occasion[i]), integer(1))
  cells$support <- vapply(seq_len(nrow(cells)), function(i) {
    observed_weeks <- model_data$occasion[model_data$task == cells$task[i]]
    if (cells$occasion[i] < min(observed_weeks) ||
        cells$occasion[i] > max(observed_weeks)) "extrapolation"
    else if (cells$observed_n[i] == 0) "unobserved_cell"
    else "observed_cell"
  }, character(1))
  cells$interval_outside_response_bounds <- cells$lower.CL < 0 | cells$upper.CL > 1
  weeks$support <- vapply(weeks$occasion, function(w) {
    support <- cells$support[cells$occasion == w]
    if ("extrapolation" %in% support) "extrapolation"
    else if ("unobserved_cell" %in% support) "unobserved_cell"
    else "observed_cells"
  }, character(1))
  comparison$support <- if (any(weeks$support[weeks$occasion %in% c(0, 8)] !=
    "observed_cells")) "inspect_endpoint_support" else "observed_endpoints"
  inference$tables <- list(cells = cells, weeks = weeks, comparison = comparison)
  inference$grid <- grid
  inference$week_grid <- week_grid
  inference$planned_contrast <- planned
  inference$contrast_coefficients <- stats::setNames(coefficients, weeks$occasion)
  inference$diagnostics$estimation_warnings <- estimation_warnings
  inference$diagnostics$estimation_messages <- estimation_messages
  inference$status <- if (length(estimation_warnings)) "estimation_requires_review"
    else "computed_not_validated_for_substantive_inference"
}
inference$session <- utils::sessionInfo()
record$inference <- inference
invisible(inference)
