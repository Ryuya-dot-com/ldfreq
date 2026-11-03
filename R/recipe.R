# Portable recipes contain resolved requests, never expressions to evaluate.
.record_json <- function(x, pretty = FALSE) {
  if (!requireNamespace("jsonlite", quietly = TRUE))
    stop("Install jsonlite to use recipe and analysis JSON.", call. = FALSE)
  as.character(jsonlite::toJSON(x, auto_unbox = TRUE, null = "null", na = "null",
    digits = 17, pretty = pretty, force = TRUE))
}

.record_fields <- function(x, fields, label) {
  if (!is.list(x) || is.null(names(x)) || anyDuplicated(names(x)) ||
      !setequal(names(x), fields))
    stop(label, " has missing, duplicated or unknown fields.", call. = FALSE)
}

.record_plain <- function(x) {
  if (is.data.frame(x)) {
    x <- as.data.frame(x)
    class(x) <- "data.frame"
    attributes(x) <- attributes(x)[c("names", "row.names", "class")]
    rownames(x) <- NULL
    x[] <- lapply(x, function(v) {
      if (is.list(v)) return(lapply(v, .record_plain))
      if (is.factor(v) || inherits(v, "Date") || inherits(v, "POSIXt")) return(as.character(v))
      if (is.object(v)) stop("Unsupported metadata column class; supply ordinary vectors.", call. = FALSE)
      v
    })
    return(x)
  }
  if (is.list(x)) return(lapply(x, .record_plain))
  x
}

.recipe_engine <- function(tokenizer) {
  p <- lexdiv_tokenize("", tokenizer = tokenizer)$provenance
  list(package_version = as.character(utils::packageVersion("ldfreq")),
    metric_contract_version = .lex_contract_version,
    preprocessing_contract_version = .lexprep_contract_version,
    tokenizer_id = p$tokenizer_id, tokenizer_version = p$tokenizer_version,
    stringi_version = as.character(utils::packageVersion("stringi")),
    icu_version = stringi::stri_info()$ICU.version)
}

#' Reusable raw-text analysis recipes
#'
#' A recipe freezes the resolved method parameters, preprocessing and optional
#' reference identities. Schema 1 supports raw text, surface forms and all word
#' tokens. External annotations, lemma/flemma reconstruction and custom resources
#' are outside this schema. Use the existing annotation APIs for those analyses.
#' Recipes contain no source text. JSON needs the optional package `jsonlite`.
#'
#' @param plan A normalized [lexdiv_plan()]. Presets are expanded before saving.
#' @param normalization,case,keep_numbers,tokenizer See [lexdiv_tokenize()].
#' @param resources Unique names from `c("nj8", "tubelex")`, or `character()`.
#'   Only the package's pinned, already downloaded resources are supported.
#' @param tubelex_tokenization_mismatch `"error"` or `"allow"`. The built-in
#'   tokenizer differs from TUBELEX segmentation; including TUBELEX requires
#'   explicit `"allow"`, recorded as a segmentation-sensitivity analysis.
#' @return A `lexdiv_recipe` list with resolved requests and environment/resource
#'   requirements. Save with [lexdiv_write()] and restore with [lexdiv_read()].
#' @examples
#' recipe <- lexdiv_recipe(lexdiv_plan(presets = character(),
#'   specs = lexdiv_spec("mattr", list(window_length = 5))))
#' if (requireNamespace("jsonlite", quietly = TRUE)) {
#'   path <- tempfile(fileext = ".json")
#'   lexdiv_write(recipe, path)
#'   restored <- lexdiv_read(path)
#'   stopifnot(identical(recipe, restored))
#'   unlink(path)
#' }
#' @md
#' @export
lexdiv_recipe <- function(plan = lexdiv_plan(), normalization = "NFC",
    case = "lower", keep_numbers = FALSE, tokenizer = "english",
    resources = character(), tubelex_tokenization_mismatch = "error") {
  plan <- .profile_validate_plan(plan)
  p <- lexdiv_tokenize("", normalization, case, keep_numbers, tokenizer)$provenance
  if (!is.character(resources) || anyNA(resources) || anyDuplicated(resources) ||
      any(!resources %in% c("nj8", "tubelex")))
    stop("resources must be unique names from nj8 and tubelex.", call. = FALSE)
  mismatch <- .lexprep_scalar_choice(tubelex_tokenization_mismatch,
    c("error", "allow"), "tubelex_tokenization_mismatch")
  if ("tubelex" %in% resources && mismatch != "allow")
    stop("TUBELEX requires explicit tubelex_tokenization_mismatch = 'allow'.",
      call. = FALSE)
  refs <- lapply(sort(resources), function(id) {
    item <- .lex_resource_catalog[[id]]
    list(id = id, version = if (id == "nj8") "jacet2016-8000-v1" else
      .lexres_tubelex_expectation()$resource_version, sha256 = item$sha256,
      citation = item$citation,
      normalization = if (id == "nj8") "nfkc_lower" else "tubelex",
      expand_parenthetical = id == "nj8",
      tokenization_mismatch = if (id == "tubelex") mismatch else "not_applicable")
  })
  specs <- lapply(plan$specifications, function(s)
    unclass(s)[c("request_id", "method_id", "parameters")])
  structure(list(schema = "ldfreq-recipe", schema_version = "1.0.0",
    engine = .recipe_engine(tokenizer),
    preprocessing = list(normalization = p$normalization, case = p$case,
      keep_numbers = p$keep_numbers, tokenizer = tokenizer,
      unit = "surface", word_inclusion = "all"),
    specifications = specs, resources = refs), class = "lexdiv_recipe")
}

.recipe_plan <- function(x) {
  specs <- lapply(x$specifications, function(s) {
    .record_fields(s, c("request_id", "method_id", "parameters"), "Specification")
    if (is.null(s$parameters)) s$parameters <- list()
    spec <- lexdiv_spec(s$method_id, s$parameters, s$request_id)
    if (!identical(spec$method_id, s$method_id))
      stop("Recipe methods must use resolved method IDs.", call. = FALSE)
    if (!identical(.profile_parameter_text(s$parameters),
        .profile_parameter_text(spec$parameters)))
      stop("Recipe parameters must be fully resolved.", call. = FALSE)
    spec
  })
  plan <- lexdiv_plan(presets = character(), specs = specs)
  if (length(plan$specifications) != length(specs)) stop("Duplicated recipe specifications.", call. = FALSE)
  plan
}

.recipe_validate <- function(x, execute = FALSE) {
  .record_fields(x, c("schema", "schema_version", "engine", "preprocessing",
    "specifications", "resources"), "Recipe")
  if (!identical(x$schema, "ldfreq-recipe") || !identical(x$schema_version, "1.0.0"))
    stop("Unsupported recipe schema.", call. = FALSE)
  .record_fields(x$preprocessing, c("normalization", "case", "keep_numbers",
    "tokenizer", "unit", "word_inclusion"), "Preprocessing")
  p <- x$preprocessing
  if (!identical(p$unit, "surface") || !identical(p$word_inclusion, "all"))
    stop("Recipe schema 1 supports surface forms and all word tokens only.", call. = FALSE)
  lexdiv_tokenize("", p$normalization, p$case, p$keep_numbers, p$tokenizer)
  engine <- .recipe_engine(p$tokenizer)
  .record_fields(x$engine, names(engine), "Engine")
  if (!all(vapply(x$engine, function(v) is.character(v) && length(v) == 1L &&
      !is.na(v) && nzchar(v), logical(1)))) stop("Invalid engine identity.", call. = FALSE)
  if (!is.list(x$specifications) || !length(x$specifications) ||
      length(x$specifications) > 128L || !is.list(x$resources))
    stop("Invalid recipe requests or resources.", call. = FALSE)
  .recipe_plan(x)
  ids <- vapply(x$resources, function(r) {
    .record_fields(r, c("id", "version", "sha256", "citation", "normalization",
      "expand_parenthetical", "tokenization_mismatch"), "Resource")
    if (!is.character(r$id) || length(r$id) != 1L || is.na(r$id) ||
        !r$id %in% c("nj8", "tubelex")) stop("Unknown recipe resource.", call. = FALSE)
    text_fields <- setdiff(names(r), "expand_parenthetical")
    if (!all(vapply(r[text_fields], function(v) is.character(v) && length(v) == 1L &&
        !is.na(v) && nzchar(v), logical(1))) || !is.logical(r$expand_parenthetical) ||
        length(r$expand_parenthetical) != 1L || is.na(r$expand_parenthetical))
      stop("Invalid resource identity or settings.", call. = FALSE)
    expected <- lexdiv_recipe(resources = r$id,
      tubelex_tokenization_mismatch = "allow")$resources[[1L]]
    if (execute && !identical(r, expected))
      stop("Resource requirements differ from the installed catalog: ", r$id, call. = FALSE)
    r$id
  }, character(1))
  if (anyDuplicated(ids)) stop("Duplicated recipe resources.", call. = FALSE)
  if (execute && !identical(x$engine, engine))
    stop("Recipe engine requirements differ from this environment; recreate the recipe explicitly to change environments.",
      call. = FALSE)
  class(x) <- "lexdiv_recipe"
  x
}

#' Run a saved recipe through the R calculation APIs
#'
#' No references are downloaded. Requested reference files and engine versions
#' must match the recipe. The record contains source texts, tokens and optional
#' document metadata; save it according to the study's access rules.
#' @param documents Named character vector or ID/text data frame, as for
#'   [lexdiv_metrics_text_batch()].
#' @param recipe A recipe from [lexdiv_recipe()] or [lexdiv_read()].
#' @param id_col,text_col Input column names.
#' @param metadata Optional document metadata, as for [lexdiv_metrics_text_batch()].
#' @param condition_id A label for this analysis condition, not measurement identity.
#' @return A `lexdiv_analysis` containing the recipe, calculation environment,
#'   source texts, complete metric results, preprocessing, resource profiles and
#'   saved method descriptions/citations. Its `$analysis` can be passed to
#'   [lexdiv_study_table()], including after JSON restoration.
#'   The objects in `$profiles` support [nj8_diagnostics()],
#'   [tubelex_diagnostics()] and TUBELEX batch plots after restoration.
#'   NJ8 batch profiles do not have a plot method.
#' @examples
#' recipe <- lexdiv_recipe(lexdiv_plan(presets = character(), specs = lexdiv_spec("ttr")))
#' run <- lexdiv_run_recipe(c(doc1 = "A small test text."), recipe)
#' run$analysis$results[, c("document_id", "metric_id", "value")]
#' @md
#' @export
lexdiv_run_recipe <- function(documents, recipe, id_col = "document_id",
    text_col = "text", metadata = NULL, condition_id = "analysis") {
  recipe <- .recipe_validate(recipe, execute = TRUE)
  condition_id <- .profile_scalar_identifier(condition_id, "condition_id")
  texts <- .lextext_documents(documents, id_col, text_col)
  p <- recipe$preprocessing
  ids <- vapply(recipe$resources, `[[`, character(1), "id")
  if (length(ids) && !all(lexdiv_resource_info(ids)$available))
    stop("Recipe reference data are unavailable or modified; obtain the pinned resources explicitly.", call. = FALSE)
  prepared <- lexdiv_tokenize_batch(stats::setNames(as.character(unlist(texts, use.names = FALSE)),
    names(texts)), normalization = p$normalization, case = p$case,
    keep_numbers = p$keep_numbers, tokenizer = p$tokenizer)
  analysis <- lexdiv_metrics_text_batch(prepared, plan = .recipe_plan(recipe), metadata = metadata)
  profiles <- lapply(ids, function(id) {
    if (id == "nj8") nj8_profile_batch(prepared, unit = "surface",
      normalization = "nfkc_lower", expand_parenthetical = TRUE) else
      tubelex_profile_batch(prepared, normalization = "tubelex", tokenization_mismatch = "allow")
  })
  names(profiles) <- ids
  if (any(vapply(profiles, function(p) !p$status %in% c("ok", "empty"), logical(1))))
    stop("A requested resource profile could not be calculated.", call. = FALSE)
  methods <- lexdiv_methods()
  wanted <- vapply(recipe$specifications, `[[`, character(1), "method_id")
  methods <- methods[match(wanted, methods$method_id), , drop = FALSE]
  references <- c(sprintf("Komuro, R. (2026). ldfreq: Reproducible Lexical Diversity and Frequency Profiles. R package version %s.",
    recipe$engine$package_version))
  if ("mattr" %in% methods$metric_id) references <- c(references,
    "Covington, M. A., & McFall, J. D. (2010). Cutting the Gordian Knot: The Moving-Average Type-Token Ratio (MATTR). https://doi.org/10.1080/09296171003643098")
  if (any(methods$metric_id %in% c("mtld", "hdd"))) references <- c(references,
    "McCarthy, P. M., & Jarvis, S. (2010). MTLD, vocd-D, and HD-D: A validation study of sophisticated approaches to lexical diversity assessment. https://doi.org/10.3758/BRM.42.2.381")
  references <- unique(c(references, vapply(recipe$resources, `[[`, character(1), "citation")))
  .analysis_restore(structure(list(schema = "ldfreq-analysis", schema_version = "1.0.0",
    condition_id = condition_id, recipe = recipe,
    execution = list(package_version = recipe$engine$package_version,
      r_version = R.version.string, platform = R.version$platform,
      created_at_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")),
    documents = data.frame(document_id = names(texts), text = as.character(unlist(texts, use.names = FALSE)),
      stringsAsFactors = FALSE),
    analysis = .record_plain(analysis), profiles = .record_plain(profiles),
    methods = .record_plain(methods), references = references), class = "lexdiv_analysis"))
}

# Restore only the package's known result classes; JSON cannot supply R classes.
.analysis_restore <- function(x) {
  template <- lexdiv_metrics_batch(stats::setNames(list(), character()),
    plan = .recipe_plan(x$recipe))
  rows <- x$analysis$results
  for (n in names(template)[vapply(template, is.list, logical(1))])
    rows[[n]] <- I(rows[[n]])
  x$analysis$results <- .lex_batch_restore_result_attributes(rows, template)
  class(x$analysis) <- "lexdiv_text_batch_results"
  if (!is.null(x$profiles$nj8)) {
    class(x$profiles$nj8) <- c("nj8_profile_batch", "lexical_level_profile_batch")
    x$profiles$nj8$document_provenance$preprocessing_ref <-
      I(x$profiles$nj8$document_provenance$preprocessing_ref)
  }
  if (!is.null(x$profiles$tubelex)) {
    class(x$profiles$tubelex) <- "tubelex_profile_batch"
    x$profiles$tubelex$profiles <- lapply(x$profiles$tubelex$profiles,
      function(p) structure(p, class = "tubelex_profile"))
  }
  class(x) <- "lexdiv_analysis"
  x
}

#' @rdname lexdiv_recipe
#' @param x A recipe or analysis record for compact display.
#' @param ... Unused additional arguments.
#' @export
print.lexdiv_recipe <- function(x, ...) {
  cat(sprintf("<lexdiv_recipe: %d specifications; %d resources>\n",
    length(x$specifications), length(x$resources)))
  cat(sprintf("  ldfreq %s | tokenizer=%s | normalization=%s | case=%s\n",
    x$engine$package_version, x$preprocessing$tokenizer,
    x$preprocessing$normalization, x$preprocessing$case))
  cat("  Inspect $specifications and $resources for complete settings.\n")
  invisible(x)
}

#' @rdname lexdiv_run_recipe
#' @param x An analysis record for compact display.
#' @param ... Unused additional arguments.
#' @export
print.lexdiv_analysis <- function(x, ...) {
  rows <- x$analysis$results
  cat(sprintf("<lexdiv_analysis: %d documents; %d metric records; %d resources>\n",
    nrow(x$documents), nrow(rows), length(x$profiles)))
  cat(sprintf("  Available: %d | Missing: %d | ldfreq %s\n",
    sum(rows$status == "ok"), sum(rows$status == "missing"), x$execution$package_version))
  cat("  Results: $analysis$results | Resources: $profiles | Settings: $recipe\n")
  invisible(x)
}

# Tables carry explicit column types so JSON null and character IDs round-trip.
.record_cells <- function(x) lapply(unname(as.list(x)), function(v) {
  if (is.numeric(v) && (is.nan(v) || is.infinite(v)))
    list(nonfinite = as.character(v)) else v
})

.record_pack <- function(x) {
  if (is.data.frame(x)) return(list(table_schema = "ldfreq-columns-1",
    types = lapply(x, typeof), data = lapply(x, function(v)
      if (is.list(v)) lapply(v, .record_pack) else .record_cells(v))))
  if (is.list(x)) return(lapply(x, .record_pack))
  if (!is.null(x) && (length(x) != 1L || anyNA(x) || is.double(x) || !is.null(names(x))))
    return(list(vector_schema = "ldfreq-vector-1", type = typeof(x),
      values = .record_cells(x), names = names(x)))
  x
}

.record_vector <- function(type, values) {
  if (length(type) != 1L || !type %in% c("character", "integer", "double", "logical"))
    stop("Unsupported column/vector type.", call. = FALSE)
  proto <- switch(type, character = character(1), integer = integer(1),
    double = double(1), logical = logical(1))
  vapply(as.list(values), function(v) {
    if (type == "double" && is.list(v) && identical(names(v), "nonfinite") &&
        is.character(v$nonfinite) && length(v$nonfinite) == 1L &&
        v$nonfinite %in% c("NaN", "Inf", "-Inf"))
      return(as.numeric(v$nonfinite))
    if (is.null(v)) return(switch(type, character = NA_character_,
      integer = NA_integer_, double = NA_real_, logical = NA))
    if (length(v) != 1L || !(typeof(v) == type || (type == "double" && is.integer(v))))
      stop("JSON value disagrees with its declared column type.", call. = FALSE)
    v
  }, proto, USE.NAMES = FALSE)
}

.record_unpack <- function(x) {
  if (!is.list(x)) return(x)
  if (identical(x$vector_schema, "ldfreq-vector-1")) {
    .record_fields(x, c("vector_schema", "type", "values", "names"), "Vector")
    v <- .record_vector(x$type, x$values)
    if (!is.null(x$names)) {
      n <- unlist(x$names, use.names = FALSE)
      if (!is.character(n) || length(n) != length(v)) stop("Invalid vector names.", call. = FALSE)
      names(v) <- n
    }
    return(v)
  }
  if (identical(x$table_schema, "ldfreq-columns-1")) {
    .record_fields(x, c("table_schema", "types", "data"), "Table")
    if (!is.list(x$types) || !is.list(x$data) ||
        !identical(names(x$types), names(x$data)) || anyDuplicated(names(x$data)))
      stop("Invalid table columns.", call. = FALSE)
    cols <- Map(function(type, values) {
      if (!type %in% c("character", "integer", "double", "logical", "list"))
        stop("Unsupported table column type.", call. = FALSE)
      if (type == "list") return(I(lapply(values, .record_unpack)))
      .record_vector(type, values)
    }, x$types, x$data)
    if (length(unique(lengths(cols))) > 1L) stop("Unequal table column lengths.", call. = FALSE)
    out <- as.data.frame(cols, stringsAsFactors = FALSE, check.names = FALSE, optional = TRUE)
    for (n in names(cols)[vapply(cols, is.list, logical(1))]) out[[n]] <- unclass(cols[[n]])
    return(.record_plain(out))
  }
  lapply(x, .record_unpack)
}

.analysis_validate <- function(x) {
  .record_fields(x, c("schema", "schema_version", "condition_id", "recipe",
    "execution", "documents", "analysis", "profiles", "methods", "references"), "Analysis")
  if (!identical(x$schema, "ldfreq-analysis") || !identical(x$schema_version, "1.0.0"))
    stop("Unsupported analysis schema.", call. = FALSE)
  x$recipe <- .recipe_validate(x$recipe)
  .profile_scalar_identifier(x$condition_id, "condition_id")
  if (!is.data.frame(x$documents) || !identical(names(x$documents), c("document_id", "text")))
    stop("Missing source document table.", call. = FALSE)
  ids <- .lex_batch_validate_ids(x$documents$document_id, nrow(x$documents))
  .lextext_documents(x$documents, "document_id", "text")
  r <- x$analysis$results
  required <- c("document_id", "request_id", "method_id", "value", "status",
    "missing_reason", "N", "V", "requested_parameters", "effective_parameters")
  if (!is.data.frame(r) || !all(required %in% names(r)) ||
      !is.numeric(r$value) || !is.numeric(r$N) || !is.numeric(r$V))
    stop("Invalid analysis result table.", call. = FALSE)
  plan <- .recipe_plan(x$recipe)
  template <- lexdiv_metrics(character(), plan = plan)
  di <- match(r$document_id, ids)
  ri <- match(r$request_id, template$request_id)
  if (anyNA(di) || anyNA(ri) || anyDuplicated(paste(di, ri)) ||
      nrow(r) != length(ids) * nrow(template)) stop("Incomplete or duplicated document/request rows.", call. = FALSE)
  static <- setdiff(names(template), c("value", "status", "missing_reason",
    "effective_parameters", "N", "V", "below_quality_floor", "diagnostics"))
  if (!all(names(template) %in% names(r)) || any(!vapply(static, function(n)
      isTRUE(all.equal(r[[n]], template[[n]][ri], check.attributes = FALSE)), logical(1))))
    stop("Results disagree with the saved recipe.", call. = FALSE)
  if (anyNA(r$status) || any(!r$status %in% c("ok", "missing")) ||
      any(r$status == "ok" & (!is.finite(r$value) | !is.na(r$missing_reason))) ||
      any(r$status == "missing" & (!is.na(r$value) | is.na(r$missing_reason))) ||
      anyNA(r$N) || anyNA(r$V) || any(!is.finite(r$N) | !is.finite(r$V)) ||
      any(r$N != floor(r$N) | r$V != floor(r$V) | r$N < 0 | r$V < 0 | r$V > r$N))
    stop("Inconsistent result values, counts or missingness.", call. = FALSE)
  for (i in which(r$status == "ok")) {
    if (!identical(.profile_parameter_text(r$requested_parameters[[i]]),
        .profile_parameter_text(r$effective_parameters[[i]])))
      stop("Effective parameters disagree with the recipe.", call. = FALSE)
  }
  if (!identical(names(x$analysis$preprocessing), ids))
    stop("Preprocessing records do not match document IDs.", call. = FALSE)
  audit <- x$analysis$token_audit
  if (!is.data.frame(audit) || !all(c("document_id", "selected_unit", "eligible") %in% names(audit)) ||
      !is.logical(audit$eligible) || anyNA(audit$eligible) || any(!audit$document_id %in% ids))
    stop("Invalid token audit.", call. = FALSE)
  for (i in seq_along(ids)) {
    p <- x$analysis$preprocessing[[i]]
    token <- p$tokenization
    expected <- x$recipe$preprocessing
    source_hash <- digest::digest(charToRaw(enc2utf8(x$documents$text[[i]])),
      algo = "sha256", serialize = FALSE)
    if (!identical(token$source_text_sha256, source_hash) ||
        !identical(token$tokenizer_id, x$recipe$engine$tokenizer_id) ||
        !identical(token$tokenizer_version, x$recipe$engine$tokenizer_version) ||
        !identical(token$normalization, expected$normalization) ||
        !identical(token$case, expected$case) ||
        !identical(token$keep_numbers, expected$keep_numbers) ||
        !identical(p$selected_unit, expected$unit) ||
        !identical(p$word_inclusion, expected$word_inclusion) ||
        !is.numeric(p$eligible_tokens) || length(p$eligible_tokens) != 1L ||
        is.na(p$eligible_tokens) || any(r$N[di == i] != p$eligible_tokens))
      stop("Source text, preprocessing or counts disagree with the record.", call. = FALSE)
    units <- audit$selected_unit[audit$document_id == ids[[i]] & audit$eligible]
    if (!is.character(units) || anyNA(units) || any(!nzchar(units)) ||
        any(r$N[di == i] != length(units)) || any(r$V[di == i] != length(unique(units))))
      stop("Token audit disagrees with result counts.", call. = FALSE)
  }
  if (!is.list(x$execution) || !identical(x$execution$package_version,
      x$recipe$engine$package_version)) stop("Calculation version is inconsistent.", call. = FALSE)
  wanted <- vapply(x$recipe$specifications, `[[`, character(1), "method_id")
  if (!is.data.frame(x$methods) || !all(c("method_id", "metric_id", "definition", "label") %in% names(x$methods)) ||
      !identical(x$methods$method_id, wanted) || !is.character(x$references) || anyNA(x$references))
    stop("Invalid saved method descriptions or references.", call. = FALSE)
  resource_ids <- vapply(x$recipe$resources, `[[`, character(1), "id")
  if (!is.list(x$profiles) || !setequal(names(x$profiles), resource_ids))
    stop("Resource profiles disagree with the recipe.", call. = FALSE)
  for (reference in x$recipe$resources) {
    profile <- x$profiles[[reference$id]]
    p <- profile$provenance
    version <- if (reference$id == "nj8") p$resource_version else p$resource$resource_version
    if (!identical(version, reference$version) ||
        !identical(p$query_normalization, reference$normalization) ||
        !is.character(profile$status) || length(profile$status) != 1L ||
        !profile$status %in% c("ok", "empty"))
      stop("Executed resource provenance disagrees with the recipe.", call. = FALSE)
  }
  .analysis_restore(x)
}

#' Save and read portable recipes and analysis records
#'
#' JSON preserves nested metadata and typed tables (column names, types and
#' arrays of values), including zero-row tables and character IDs. It contains
#' source text when saving an analysis. CSV is a scalar long metric table:
#' document x condition x request, with list columns encoded as JSON strings.
#' Keep the JSON record beside CSV; CSV alone is not a reproducible analysis.
#' Existing files are never overwritten. Unknown schemas are rejected.
#' @param x A recipe or analysis produced by [lexdiv_recipe()] or [lexdiv_run_recipe()].
#' @param path Output or input file path.
#' @param format `"json"` for a recipe/analysis or `"csv"` for analysis metrics.
#' @return `lexdiv_write()` invisibly returns the output path. `lexdiv_read()`
#'   returns a validated recipe or analysis without recalculating document scores.
#' @examples
#' if (requireNamespace("jsonlite", quietly = TRUE)) {
#'   recipe <- lexdiv_recipe(lexdiv_plan(presets = character(), specs = lexdiv_spec("ttr")))
#'   run <- lexdiv_run_recipe(c("001" = "One small example."), recipe)
#'   path <- tempfile(fileext = ".json")
#'   lexdiv_write(run, path)
#'   restored <- lexdiv_read(path)
#'   stopifnot(identical(restored$analysis$results, run$analysis$results))
#'   unlink(path)
#' }
#' @md
#' @export
lexdiv_write <- function(x, path, format = c("json", "csv")) {
  format <- match.arg(format)
  path <- .lex_batch_scalar_name(path, "path")
  if (file.exists(path)) stop("Output already exists: ", path, call. = FALSE)
  recipe <- identical(x$schema, "ldfreq-recipe")
  x <- if (recipe) .recipe_validate(x) else .analysis_validate(x)
  if (format == "csv" && recipe) stop("Recipes require JSON.", call. = FALSE)
  text <- if (format == "json") .record_json(.record_pack(x), pretty = TRUE) else NULL
  stage <- tempfile("ldfreq-write-", tmpdir = dirname(path))
  on.exit(unlink(stage), add = TRUE)
  if (format == "json") writeLines(enc2utf8(text), stage, useBytes = TRUE) else {
    rows <- x$analysis$results
    rows$condition_id <- rep(x$condition_id, nrow(rows))
    for (n in names(rows)[vapply(rows, is.list, logical(1))])
      rows[[n]] <- vapply(rows[[n]], .record_json, character(1))
    utils::write.csv(rows, stage, row.names = FALSE, na = "", fileEncoding = "UTF-8")
  }
  if (!file.copy(stage, path, overwrite = FALSE)) stop("Could not write output: ", path, call. = FALSE)
  invisible(path)
}

#' @rdname lexdiv_write
#' @md
#' @export
lexdiv_read <- function(path) {
  .record_json(list())
  path <- .lex_batch_scalar_name(path, "path")
  if (!file.exists(path) || dir.exists(path)) stop("Input must be a local JSON file.", call. = FALSE)
  x <- jsonlite::fromJSON(paste(readLines(path, encoding = "UTF-8", warn = FALSE), collapse = "\n"),
    simplifyVector = FALSE)
  x <- .record_unpack(x)
  # Primitive JSON arrays in parameter settings represent numeric R vectors.
  recipe <- if (identical(x$schema, "ldfreq-recipe")) x else x$recipe
  if (is.null(recipe)) stop("Missing recipe schema.", call. = FALSE)
  recipe$specifications <- lapply(recipe$specifications, function(s) {
    if (is.list(s$parameters)) s$parameters <- lapply(s$parameters, function(v)
      if (is.list(v) && is.null(names(v))) unlist(v, use.names = FALSE) else v)
    s
  })
  if (identical(x$schema, "ldfreq-recipe")) return(.recipe_validate(recipe))
  x$recipe <- recipe
  x$references <- unlist(x$references, use.names = FALSE)
  .analysis_validate(x)
}
