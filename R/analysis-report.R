.analysis_input <- function(x) {
  if (is.character(x) && length(x) == 1L) x <- lexdiv_read(x)
  .analysis_validate(x)
}

# Use the shortest decimal that recovers the saved numeric parameter exactly.
.report_number <- function(value) {
  for (digits in seq_len(17L)) {
    text <- format(value, digits = digits, trim = TRUE, decimal.mark = ".", scientific = FALSE)
    if (identical(as.numeric(text), as.numeric(value))) return(text)
  }
  text
}

#' Inspect differences between saved analysis conditions
#'
#' Measurement equality concerns definitions, preprocessing and resources, not
#' research validity. Different configurations can be compared deliberately in
#' sensitivity analyses; this function never pools or removes observations.
#' Length differences are cautions, not universal exclusion thresholds. Equal
#' settings do not establish comparable tasks, populations or independent units.
#' Length checks include both the batch distribution and counts for shared
#' document IDs. A shared ID alone does not establish paired observations.
#' Difference values use JSON and require the optional package `jsonlite`.
#' @param x,y Analysis records or paths to their JSON exports.
#' @return A list with `measurement` (`"same"` or `"different"`),
#'   `study_comparability = "not_established"`, and a `differences` data frame
#'   with field, severity, left/right values and an explanation. Malformed or
#'   unsupported records fail validation rather than being labelled comparable.
#' @examples
#' recipe <- lexdiv_recipe(lexdiv_plan(presets = character(), specs = lexdiv_spec("ttr")))
#' a <- lexdiv_run_recipe(c(a = "One short text."), recipe)
#' b <- lexdiv_run_recipe(c(b = "A different and somewhat longer text."), recipe)
#' if (requireNamespace("jsonlite", quietly = TRUE)) lexdiv_compare_analyses(a, b)
#' @md
#' @export
lexdiv_compare_analyses <- function(x, y) {
  x <- .analysis_input(x)
  y <- .analysis_input(y)
  rows <- list()
  add <- function(field, severity, left, right, explanation) {
    if (!identical(left, right)) rows[[length(rows) + 1L]] <<- data.frame(
      field = field, severity = severity, left = .record_json(left),
      right = .record_json(right), explanation = explanation, stringsAsFactors = FALSE)
  }
  for (field in names(x$recipe$preprocessing)) add(paste0("preprocessing.", field),
    "measurement", x$recipe$preprocessing[[field]], y$recipe$preprocessing[[field]],
    "Different counting settings; keep conditions separate.")
  for (field in names(x$recipe$engine)) add(paste0("engine.", field),
    if (field == "package_version") "caution" else "measurement",
    x$recipe$engine[[field]], y$recipe$engine[[field]],
    if (field == "package_version") "Software versions differ; review changes before treating implementations as equivalent." else
      "Definition, tokenizer or normalization engine differs.")
  specs <- function(r) sort(vapply(r$specifications, function(s)
    paste(s$method_id, .profile_parameter_text(s$parameters), sep = ":"), character(1)))
  add("measurement_specifications", "measurement", specs(x$recipe), specs(y$recipe),
    "Method IDs or resolved parameters differ; request labels alone do not identify measurements.")
  refs <- function(r) lapply(r$resources, function(v) v[setdiff(names(v), "citation")])
  add("resources", "measurement", refs(x$recipe), refs(y$recipe),
    "Reference identity, version, fingerprint or lookup settings differ.")
  resource_identity <- function(a) lapply(a$profiles, function(profile) {
    p <- profile$provenance
    p[intersect(c("contract_id", "contract_version", "resource", "lookup", "resource_id",
      "resource_version", "resource_source_sha256", "resource_canonical_sha256",
      "query_normalization_id", "selected_unit", "tokenization_mismatch"), names(p))]
  })
  add("executed_resources", "measurement", resource_identity(x), resource_identity(y),
    "Executed resource definitions or content fingerprints differ.")
  lengths_for <- function(a) {
    r <- a$analysis$results
    sort(r$N[!duplicated(r$document_id)])
  }
  add("selected_token_counts", "caution", lengths_for(x), lengths_for(y),
    "Document counts or length distributions differ. Evaluate length sensitivity for each measure and study design.")
  shared <- sort(intersect(x$documents$document_id, y$documents$document_id), method = "radix")
  if (length(shared)) {
    counts_for <- function(a) {
      r <- a$analysis$results
      data.frame(document_id = shared, selected_tokens = r$N[match(shared, r$document_id)],
        stringsAsFactors = FALSE)
    }
    add("shared_document_token_counts", "caution", counts_for(x), counts_for(y),
      "Selected-token counts differ for shared document IDs, even if batch length distributions agree. Verify document correspondence before a paired comparison.")
  }
  rates <- function(a) {
    r <- a$analysis$results
    list(documents = nrow(a$documents), unavailable = sum(r$status != "ok"),
      below_advisory_floor = sum(r$below_quality_floor, na.rm = TRUE))
  }
  add("availability", "caution", rates(x), rates(y),
    "Availability or advisory-length flags differ; flags do not automatically exclude scores.")
  coverage <- function(a) lapply(a$profiles, function(p)
    p[intersect(c("summary", "coverage"), names(p))])
  if (length(x$profiles) || length(y$profiles)) add("resource_coverage", "caution",
    .record_pack(coverage(x)), .record_pack(coverage(y)),
    "Inspect denominators, off-list terms and conditional resource summaries separately from diversity scores.")
  result <- if (length(rows)) do.call(rbind, rows) else data.frame(
    field = character(), severity = character(), left = character(), right = character(),
    explanation = character(), stringsAsFactors = FALSE)
  list(measurement = if (any(result$severity == "measurement")) "different" else "same",
    study_comparability = "not_established", differences = result)
}

#' Describe saved calculations in English or Japanese
#'
#' Creates deterministic methods text from recorded settings, not a language
#' model. It uses the calculation version, never the current reporting version.
#' Saved stringi/ICU versions are reported. Numeric parameters use a decimal
#' point regardless of the current R display options.
#' Study sampling, justification of settings and inference require the author's
#' own account. References cover software, MATTR, MTLD/HD-D and selected
#' resources; other methods are identified by their saved definition and ID.
#' @param x An analysis record or its JSON path.
#' @param language `"en"` or `"ja"`.
#' @return A character vector of paragraphs, including references. Write it
#'   with `writeLines(..., useBytes = TRUE)` after UTF-8 encoding if necessary.
#' @examples
#' recipe <- lexdiv_recipe(lexdiv_plan(presets = character(), specs = lexdiv_spec("ttr")))
#' run <- lexdiv_run_recipe(c(doc1 = "A short text."), recipe)
#' cat(lexdiv_methods_text(run), sep = "\n\n")
#' @md
#' @export
lexdiv_methods_text <- function(x, language = c("en", "ja")) {
  x <- .analysis_input(x)
  language <- match.arg(language)
  ja <- language == "ja"
  p <- x$recipe$preprocessing
  e <- x$recipe$engine
  first <- if (ja) sprintf(
    "%d \u6587\u66f8\u306e\u8a9e\u5f59\u591a\u69d8\u6027\u3092 ldfreq %s \u3067\u7b97\u51fa\u3057\u305f\u3002\u30c8\u30fc\u30af\u30ca\u30a4\u30b6\u30fc\u306f %s\uff08\u7248 %s\uff09\u3001Unicode \u6b63\u898f\u5316\u306f %s\u3001\u5927\u6587\u5b57\u30fb\u5c0f\u6587\u5b57\u306e\u51e6\u7406\u306f %s\u3001\u6570\u5024\u30c8\u30fc\u30af\u30f3\u306e\u4fdd\u6301\u306f %s \u3068\u3057\u305f\u3002\u8868\u5c64\u5f62\u3092\u4f7f\u7528\u3057\u3001\u5185\u5bb9\u8a9e\u3078\u306e\u9650\u5b9a\u306f\u884c\u308f\u306a\u304b\u3063\u305f\u3002",
    nrow(x$documents), e$package_version, e$tokenizer_id, e$tokenizer_version,
    p$normalization, p$case, if (p$keep_numbers) "\u3042\u308a" else "\u306a\u3057") else sprintf(
    "Lexical diversity was calculated for %d documents using ldfreq %s. Tokenization used %s (version %s), %s Unicode normalization, case handling '%s', and %s numeric tokens. Surface forms were analyzed without content-word filtering.",
    nrow(x$documents), e$package_version, e$tokenizer_id, e$tokenizer_version,
    p$normalization, p$case, if (p$keep_numbers) "retention of" else "exclusion of")
  first <- paste(first, if (ja) sprintf(
    "\u6b63\u898f\u5316\u306b\u306f stringi %s\uff08ICU %s\uff09\u3092\u4f7f\u7528\u3057\u305f\u3002",
    e$stringi_version, e$icu_version) else sprintf(
    "Normalization used stringi %s (ICU %s).", e$stringi_version, e$icu_version))
  definitions_ja <- c(ttr = "\u7570\u306a\u308a\u8a9e\u6570 V \u3092\u7dcf\u8a9e\u6570 N \u3067\u9664\u3057\u305f TTR",
    rttr = "V / sqrt(N)", cttr = "V / sqrt(2N)", herdan = "ln(V) / ln(N)",
    maas = "(ln(N) - ln(V)) / ln(N)^2",
    msttr = "\u91cd\u8907\u3057\u306a\u3044\u5b8c\u5168\u306a\u533a\u9593\u306e TTR \u306e\u5e73\u5747\uff08\u7aef\u6570\u533a\u9593\u306f\u9664\u5916\uff09",
    mattr = "1\u8a9e\u305a\u3064\u79fb\u52d5\u3055\u305b\u305f\u5168\u3066\u306e\u5b8c\u5168\u306a\u7a93\u306e TTR \u306e\u5e73\u5747",
    mtld = "\u9806\u65b9\u5411\u30fb\u9006\u65b9\u5411\u306e MTLD \u306e\u7b97\u8853\u5e73\u5747\u3002TTR \u304c\u95be\u5024\u3092\u53b3\u5bc6\u306b\u4e0b\u56de\u308b\u3068\u56e0\u5b50\u3092\u9589\u3058\u3001\u6700\u5c0f\u56e0\u5b50\u9577\u306f\u8a2d\u3051\u305a\u3001\u6700\u7d42\u8a9e\u3067\u3082\u9589\u9396\u3092\u5224\u5b9a\u3057\u3001\u6b8b\u4f59\u56e0\u5b50\u3092 (1 - TTR) / (1 - \u95be\u5024) \u3067\u52a0\u7b97",
    mtld_ma = "\u5404\u8a9e\u304b\u3089\u9806\u65b9\u5411\u306b\u958b\u59cb\u3057\u3001TTR \u304c\u95be\u5024\u3092\u53b3\u5bc6\u306b\u4e0b\u56de\u308b\u9577\u305510\u8a9e\u4ee5\u4e0a\u306e\u5b8c\u5168\u56e0\u5b50\u306e\u9577\u3055\u3092\u5e73\u5747",
    hdd = "\u8d85\u5e7e\u4f55\u5206\u5e03\u306b\u3088\u308b\u6a19\u672c\u4e2d\u306e\u671f\u5f85\u7570\u306a\u308a\u8a9e\u6570\u3092\u6a19\u672c\u30b5\u30a4\u30ba\u3067\u9664\u3057\u305f HD-D",
    expected_ttr_d = "\u6709\u9650\u6bcd\u96c6\u56e3\u306e\u671f\u5f85 TTR \u306b D \u3092\u5f53\u3066\u306f\u3081\u308b\u6c7a\u5b9a\u8ad6\u7684\u63a8\u5b9a\uff08\u5b9f\u9a13\u7684\u624b\u6cd5\u3067\u3042\u308a\u3001\u7121\u4f5c\u70ba\u518d\u6a19\u672c\u5316\u306b\u3088\u308b vocd-D \u3068\u306f\u7570\u306a\u308b\uff09",
    yule_k = "10000 * (M2 - N) / N^2\uff08M2 \u306f\u5404\u8a9e\u983b\u5ea6\u306e\u4e8c\u4e57\u548c\uff09",
    yule_i = "V^2 / (M2 - V)\uff08M2 \u306f\u5404\u8a9e\u983b\u5ea6\u306e\u4e8c\u4e57\u548c\uff09")
  paragraphs <- vapply(seq_along(x$recipe$specifications), function(i) {
    s <- x$recipe$specifications[[i]]
    m <- x$methods[match(s$method_id, x$methods$method_id), , drop = FALSE]
    definition <- if (ja) unname(definitions_ja[m$metric_id]) else m$definition
    if (!ja && m$metric_id == "mtld") definition <- paste(definition,
      "with final-token closure checks, residual credit (1 - TTR) / (1 - threshold), and the arithmetic mean of directional scores")
    if (!ja && m$metric_id == "msttr") definition <- paste(definition, "discarding the incomplete remainder")
    if (!ja && m$metric_id == "expected_ttr_d") definition <- paste(definition,
      "(experimental; not random-resampling vocd-D)")
    parameters <- paste(vapply(names(s$parameters), function(n)
      paste0(n, " = ", paste(vapply(s$parameters[[n]], .report_number, character(1)), collapse = ", ")),
      character(1)), collapse = "; ")
    if (!nzchar(parameters)) parameters <- if (ja) "\u8a2d\u5b9a\u9805\u76ee\u306a\u3057" else "none"
    if (ja) sprintf("%s \u3092\u7b97\u51fa\u3057\u305f\u3002\u65b9\u6cd5 ID: %s\u3002\u30d1\u30e9\u30e1\u30fc\u30bf: %s\u3002", definition, s$method_id, parameters) else
      sprintf("We calculated %s (%s). Method ID: %s. Parameters: %s.", m$label, definition, s$method_id, parameters)
  }, character(1))
  refs <- vapply(x$recipe$resources, function(r) {
    base <- if (ja) sprintf("\u53c2\u7167\u8cc7\u6e90 %s\uff08\u7248 %s\u3001\u7167\u5408\u6b63\u898f\u5316 %s\uff09\u3092\u4f7f\u7528\u3057\u305f\u3002", r$id, r$version, r$normalization) else
      sprintf("The %s reference (version %s) was used with %s lookup normalization.", r$id, r$version, r$normalization)
    if (r$id == "nj8") paste(base, if (ja)
      "\u8868\u5c64\u5f62\u3092\u7167\u5408\u3057\u3001\u62ec\u5f27\u4ed8\u304d\u306e\u5225\u8868\u8a18\u3092\u5c55\u958b\u3057\u305f\u3002\u30ea\u30b9\u30c8\u5916\u8a9e\u3082\u30ab\u30d0\u30ec\u30c3\u30b8\u306e\u5206\u6bcd\u306b\u542b\u3081\u305f\u3002" else
      "Surface forms were matched with parenthetical aliases expanded; off-list forms remained in the coverage denominator.") else
      paste(base, if (ja)
        "\u7d44\u8fbc\u307f\u30c8\u30fc\u30af\u30ca\u30a4\u30b6\u30fc\u3068\u53c2\u7167\u8cc7\u6e90\u306e\u5206\u5272\u65b9\u6cd5\u306e\u76f8\u9055\u3092\u660e\u793a\u7684\u306b\u8a31\u5bb9\u3057\u305f\u3002\u983b\u5ea6\u7b49\u306e\u5e73\u5747\u306f\u7167\u5408\u3067\u304d\u305f\u8a9e\u306b\u6761\u4ef6\u4ed8\u3051\u3089\u308c\u3001\u30ab\u30d0\u30ec\u30c3\u30b8\u3068\u4f75\u8a18\u3057\u305f\u3002" else
        "The known segmentation mismatch was explicitly allowed. Frequency/prevalence means were conditional on matched terms and retained alongside coverage.")
  }, character(1))
  r <- x$analysis$results
  last <- if (ja) sprintf(
    "\u6587\u66f8\u00d7\u6e2c\u5b9a\u4ed5\u69d8\u306e %d \u884c\u306e\u3046\u3061 %d \u884c\u306f\u8a08\u7b97\u4e0d\u80fd\u3067\u3042\u308a\u3001\u6b20\u640d\u7406\u7531\u3068\u3068\u3082\u306b\u4fdd\u6301\u3057\u305f\u3002\u77ed\u3044\u30c6\u30ad\u30b9\u30c8\u306e\u6ce8\u610f\u30d5\u30e9\u30b0\u306b\u3088\u308b\u81ea\u52d5\u9664\u5916\u306f\u884c\u308f\u306a\u304b\u3063\u305f\u3002\u6761\u4ef6\u306e\u4e00\u81f4\u3084\u8a08\u7b97\u53ef\u80fd\u6027\u306f\u3001\u6e2c\u5b9a\u7cbe\u5ea6\u307e\u305f\u306f\u7814\u7a76\u4e0a\u306e\u6bd4\u8f03\u306e\u59a5\u5f53\u6027\u3092\u4fdd\u8a3c\u3057\u306a\u3044\u3002",
    nrow(r), sum(r$status != "ok")) else sprintf(
    "Of %d document-by-specification rows, %d were non-computable and retained with their missingness reasons. Advisory length flags did not automatically exclude scores. Matching settings and computability do not establish measurement precision or study comparability.",
    nrow(r), sum(r$status != "ok"))
  c(first, paragraphs, refs, last, paste(if (ja) "\u53c2\u8003\u6587\u732e\uff1a" else "References:",
    paste(x$references, collapse = "\n"), sep = "\n"))
}
