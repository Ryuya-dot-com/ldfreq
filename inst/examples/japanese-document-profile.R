# Explicitly sourced recipe; not an exported API or Japanese analyzer.
# Original Unicode codepoints, dictionary labels and caller-defined POS groups
# are different descriptions. No normalization, lexical inference or scoring.
.japanese_profile_characters <- function(text) {
  patterns <- c(kana_shared = "[\u30fc\uff70\u309b\u309c\uff9e\uff9f]",
    mark = "\\p{M}", decimal_digit = "\\p{Nd}",
    whitespace = "\\p{White_Space}", punctuation = "\\p{P}", symbol = "\\p{S}",
    han = "\\p{sc=Han}", hiragana = "\\p{sc=Hiragana}",
    katakana = "\\p{sc=Katakana}", latin = "\\p{sc=Latin}")
  categories <- c(names(patterns), "other")
  # ponytail: materializes codepoint vectors; profile document subsets for very
  # large inputs. It does not expand a permanent character-occurrence table.
  characters <- strsplit(text, "", fixed = TRUE)
  alphabet <- unique(unlist(characters, use.names = FALSE))
  category <- rep("other", length(alphabet))
  for (name in names(patterns)) {
    hit <- stringi::stri_detect_regex(alphabet, patterns[[name]])
    category[category == "other" & hit] <- name
  }
  out <- matrix(0L, length(text), length(categories), dimnames = list(NULL, categories))
  for (i in seq_along(characters))
    out[i, ] <- tabulate(match(category[match(characters[[i]], alphabet)], categories),
      nbins = length(categories))
  attr(out, "patterns") <- patterns
  out
}

japanese_document_profile <- function(imported, selection, pos_groups, condition,
                                      pos_col = "POS1", origin_col = "goshu") {
  fail <- function(message) stop(message, call. = FALSE)
  scalar <- function(x) is.character(x) && length(x) == 1L && !is.na(x) && nzchar(trimws(x))
  if (!all(vapply(list(condition, pos_col, origin_col), scalar, logical(1))))
    fail("Declare one condition, POS column and word-origin column.")
  if (!is.list(imported) || !all(c("tokens", "segments", "provenance") %in% names(imported)) ||
      !identical(imported$provenance$importer, "ldfreq-external-annotations"))
    fail("Use an unchanged lexdiv_import_annotations() result.")
  checked <- ldfreq::lexdiv_import_annotations(imported$tokens,
    imported$segments[setdiff(names(imported$segments), c("token_count", "text_sha256"))],
    imported$provenance$annotation)
  if (!identical(checked, imported)) fail("Annotations changed; import the complete input again.")
  t <- imported$tokens
  keys <- c("document_id", "segment_id", "token_index", "start", "end", "surface")
  if (!identical(class(selection), "data.frame") || anyDuplicated(names(selection)) ||
      !all(c(keys, "in_body", "retained", "reason") %in% names(selection)) ||
      anyDuplicated(selection[keys]) || anyNA(selection[keys]) ||
      !all(vapply(selection[c("document_id", "segment_id", "surface", "reason")], is.character, logical(1))) ||
      !all(vapply(selection[c("token_index", "start", "end")], is.numeric, logical(1))) ||
      !all(vapply(selection[c("in_body", "retained")], is.logical, logical(1))) ||
      anyNA(selection[c("in_body", "retained", "reason")]) ||
      any(!nzchar(trimws(selection$reason))) || any(selection$retained & !selection$in_body))
    fail("Supply complete unique source anchors, logical in_body/retained and nonblank reasons.")
  # An exact multi-column join also accepts a reordered CSV without row-number matching.
  anchor <- t[keys]; anchor$.profile_row <- seq_len(nrow(t))
  chosen <- selection[c(keys, "in_body", "retained", "reason")]
  joined <- merge(anchor, chosen, by = keys, all = TRUE, sort = FALSE)
  if (nrow(joined) != nrow(t) || anyNA(joined$.profile_row) || anyNA(joined$retained))
    fail("Selection must cover every original token with unchanged source anchors.")
  joined <- joined[order(joined$.profile_row), ]
  rownames(joined) <- NULL
  selection <- joined[c(keys, "in_body", "retained", "reason")]
  missing <- function(x) is.na(x) | !nzchar(stringi::stri_trim_both(x)) | x == "*"
  if (!is.character(pos_groups) || is.null(names(pos_groups)) || !length(pos_groups) ||
      anyDuplicated(names(pos_groups)) || any(missing(names(pos_groups))) || any(missing(pos_groups)))
    fail("pos_groups must explicitly map unique nonmissing POS labels to nonmissing group labels.")
  get_feature <- function(column) {
    if (!column %in% names(t)) return(rep(NA_character_, nrow(t)))
    x <- t[[column]]
    if (!is.character(x) || is.object(x)) fail("Feature columns must be character, with missing values retained.")
    x
  }
  pos <- get_feature(pos_col); origin <- get_feature(origin_col)
  pos_missing <- missing(pos); origin_missing <- missing(origin)
  group <- unname(pos_groups[match(pos, names(pos_groups))])
  group[pos_missing] <- NA_character_
  group_status <- ifelse(pos_missing, "missing", ifelse(is.na(group), "unmapped", "observed"))
  token_chars <- .japanese_profile_characters(t$surface)
  source_chars <- .japanese_profile_characters(imported$segments$text)
  tokens <- selection
  tokens$condition <- rep(condition, nrow(tokens))
  tokens$pos_value <- pos; tokens$origin_value <- origin; tokens$pos_group <- group
  tokens$pos_status <- ifelse(pos_missing, "missing", "observed")
  tokens$origin_status <- ifelse(origin_missing, "missing", "observed")
  tokens$pos_group_status <- group_status
  for (name in colnames(token_chars)) tokens[[paste0("char_", name)]] <- token_chars[, name]
  documents <- characters <- features <- list()
  ids <- imported$documents$document_id
  values <- list(pos = replace(pos, pos_missing, NA_character_),
    origin = replace(origin, origin_missing, NA_character_), pos_group = group)
  states <- list(pos = tokens$pos_status, origin = tokens$origin_status, pos_group = group_status)
  columns <- c(pos = pos_col, origin = origin_col, pos_group = pos_col)
  for (i in seq_along(ids)) {
    id <- ids[i]; all <- t$document_id == id; keep <- all & selection$retained
    source_counts <- colSums(source_chars[imported$segments$document_id == id, , drop = FALSE])
    retained_counts <- colSums(token_chars[keep, , drop = FALSE])
    documents[[i]] <- data.frame(condition = condition, document_id = id,
      source_N = sum(all), outside_body_N = sum(all & !selection$in_body),
      excluded_inside_N = sum(all & selection$in_body & !selection$retained), retained_N = sum(keep),
      source_codepoints = sum(source_counts), retained_codepoints = sum(retained_counts),
      pos_missing_N = sum(keep & pos_missing), origin_missing_N = sum(keep & origin_missing),
      pos_unmapped_N = sum(keep & group_status == "unmapped"))
    populations <- list(original_text = source_counts, retained_tokens = retained_counts)
    characters[[i]] <- do.call(rbind, lapply(names(populations), function(population) {
      n <- populations[[population]]; denominator <- sum(n)
      data.frame(condition = condition, document_id = id, population = population,
        category = names(n), n = unname(n), denominator = denominator,
        proportion = if (denominator) unname(n) / denominator else NA_real_)
    }))
    features[[i]] <- do.call(rbind, lapply(names(values), function(feature) {
      v <- values[[feature]]; state <- states[[feature]]
      labels <- if (feature == "pos_group") unique(unname(pos_groups)) else unique(v[!is.na(v)])
      labels <- sort(labels, method = "radix")
      extra <- if (feature == "pos_group") c("missing", "unmapped") else "missing"
      categories <- c(labels, rep(NA_character_, length(extra)))
      status <- c(rep("observed", length(labels)), extra)
      n <- vapply(seq_along(categories), function(j) {
        matches <- state == status[j]
        if (!is.na(categories[j])) matches <- matches & !is.na(v) & v == categories[j]
        sum(keep & matches)
      }, numeric(1))
      data.frame(condition = condition, document_id = id, feature = feature,
        field_present = columns[[feature]] %in% names(t), category = categories, status = status,
        n = n, denominator = sum(keep), proportion = if (sum(keep)) n / sum(keep) else NA_real_)
    }))
  }
  bind <- function(x) { out <- do.call(rbind, x); rownames(out) <- NULL; out }
  list(documents = bind(documents), characters = bind(characters), features = bind(features),
    tokens = tokens, imported = imported, selection = selection,
    policy = list(condition = condition, pos_col = pos_col, origin_col = origin_col,
      pos_groups = pos_groups, missing = "NA, blank-only and literal *; raw values retained",
      character_unit = "original Unicode codepoints; no normalization; not grapheme clusters",
      character_priority = c(names(attr(token_chars, "patterns")), "other"),
      character_patterns = attr(token_chars, "patterns"),
      character_populations = "complete original segments, including gaps; or retained token surfaces only",
      feature_denominator = "all retained tokens, including missing and unmapped labels"),
    software = list(R = as.character(getRversion()), stringi = as.character(utils::packageVersion("stringi")),
      unicode = stringi::stri_info()[c("Unicode.version", "ICU.version")]))
}
