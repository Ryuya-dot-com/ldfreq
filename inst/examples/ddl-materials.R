# Explicitly sourced teaching-material example; no exported API.
if (!exists("phrase_list_review", inherits = FALSE))
  sys.source(system.file("examples", "phrase-list-kwic.R", package = "ldfreq",
    mustWork = TRUE), envir = environment())

.ddl_hash <- function(x) digest::digest(x, algo = "sha256", serializeVersion = 2L)

ddl_material <- function(review, activities, items, sources, title,
                         language = c("en", "ja")) {
  language <- match.arg(language)
  fail <- function(message) stop(message, call. = FALSE)
  text_ok <- function(x, empty = FALSE) is.character(x) && !anyNA(x) &&
    all(validUTF8(x)) && (empty || all(nzchar(stringi::stri_trim_both(x))))
  table_ok <- function(x, columns) is.data.frame(x) && nrow(x) > 0L &&
    !anyDuplicated(names(x)) && setequal(names(x), columns)
  if (!is.list(review) || !all(c("source", "criterion", "worksheet") %in% names(review)))
    fail("Supply an unchanged phrase_list_review() record.")
  checked <- phrase_list_review(review$source, review$criterion, review$worksheet)
  if (!identical(review, checked)) fail("Review changed; reapply its original worksheet.")
  if (length(title) != 1L || !text_ok(title)) fail("Supply one nonblank UTF-8 title.")
  if (!table_ok(activities, c("activity_id", "prompt", "teacher_note")) ||
      !text_ok(activities$activity_id) || anyDuplicated(activities$activity_id) ||
      !text_ok(activities$prompt) || !text_ok(activities$teacher_note, empty = TRUE))
    fail("Activities need unique IDs, nonblank prompts and teacher_note strings (possibly empty).")
  if (!table_ok(items, c("occurrence_id", "activity_id")) ||
      !all(vapply(items, text_ok, logical(1))) || anyDuplicated(items$occurrence_id) ||
      !setequal(items$activity_id, activities$activity_id))
    fail("Items need unique occurrence IDs and must use every declared activity, with no extras.")
  row <- match(items$occurrence_id, review$occurrences$occurrence_id)
  if (anyNA(row) || any(review$occurrences$status[row] != "accepted"))
    fail("Select only accepted occurrence IDs from this review.")
  if (!table_ok(sources, c("document_id", "segment_id", "citation", "usage")) ||
      !all(vapply(sources, text_ok, logical(1))) ||
      anyDuplicated(sources[c("document_id", "segment_id")]))
    fail("Sources need unique document/segment pairs and nonblank citation/usage strings.")
  selected <- review$occurrences[row, , drop = FALSE]
  source_row <- vapply(seq_len(nrow(selected)), function(i) {
    j <- which(sources$document_id == selected$document_id[i] &
      sources$segment_id == selected$segment_id[i])
    if (length(j) == 1L) j else NA_integer_
  }, integer(1))
  if (anyNA(source_row) || !setequal(source_row, seq_len(nrow(sources))))
    fail("Supply sources for all and only selected document/segment pairs.")
  selected$activity_id <- items$activity_id
  selected$citation <- sources$citation[source_row]
  selected$usage <- sources$usage[source_row]
  # Activity order, then item-table order within each activity.
  selected <- selected[order(match(selected$activity_id, activities$activity_id),
    seq_len(nrow(selected))), , drop = FALSE]
  rownames(selected) <- NULL
  states <- c("accepted", "rejected", "unresolved", "unreviewed")
  result <- list(title = title, language = language, activities = activities,
    items = items, sources = sources, selected = selected, review = review,
    candidate_summary = data.frame(status = states,
      count = tabulate(match(review$occurrences$status, states), length(states))),
    settings = list(recipe_version = "1",
      selection = "explicit-subset-of-accepted; pending-candidates-retained",
      display = "original-KWIC; activity-order-then-item-order",
      learner = "selected-contexts-prompts-citations-usage-only",
      csv = "formula-like-text-prefixed-with-apostrophe; originals-in-RDS"),
    session = utils::sessionInfo())
  result$integrity_sha256 <- .ddl_hash(result)
  result
}

.ddl_check <- function(x) {
  if (!is.list(x) || !identical(x$settings$recipe_version, "1") ||
      !identical(x$integrity_sha256, .ddl_hash(x[names(x) != "integrity_sha256"])))
    stop("Material changed; rebuild it from the original review and teaching tables.",
      call. = FALSE)
  invisible(x)
}

ddl_material_write <- function(x, directory) {
  .ddl_check(x)
  if (!is.character(directory) || length(directory) != 1L || is.na(directory) ||
      !nzchar(directory) || file.exists(directory) || !dir.exists(dirname(directory)))
    stop("Choose a new output directory inside an existing parent; nothing is overwritten.",
      call. = FALSE)
  escape <- function(z) {
    for (pair in list(c("&", "&amp;"), c("<", "&lt;"), c(">", "&gt;"),
        c("\"", "&quot;"), c("'", "&#39;")))
      z <- gsub(pair[1], pair[2], z, fixed = TRUE)
    z
  }
  labels <- if (x$language == "ja") c("\u6d3b\u52d5", "\u51fa\u5178",
    "\u5229\u7528\u6761\u4ef6", "\u6c17\u4ed8\u3044\u305f\u3053\u3068\u30fb\u8aac\u660e") else
    c("Activity", "Source", "Use", "Observations and explanation")
  html <- c("<!doctype html>", paste0('<html lang="', x$language, '"><head>'),
    '<meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1">',
    paste0("<title>", escape(x$title), "</title>"),
    "<style>",
    "body{font-family:system-ui,'Hiragino Kaku Gothic ProN','Yu Gothic',sans-serif;",
    "max-width:180mm;margin:12mm auto;padding:0 6mm;font-size:12pt;line-height:1.6;color:#111;background:#fff}",
    "h1{font-size:18pt}h2{font-size:14pt;margin-top:1.4em}",
    ".prompt,.context,.citation,.usage{white-space:pre-wrap;overflow-wrap:anywhere}",
    "li{padding:3mm 1mm;border-bottom:1px solid #aaa;break-inside:avoid;page-break-inside:avoid}",
    ".citation,.usage{font-size:9pt;margin:.3em 0}.context{margin:.3em 0}",
    ".response{min-height:22mm;border:1px solid #888;margin:2mm 0 6mm}",
    "@media print{@page{size:auto;margin:15mm}body{margin:0;padding:0;max-width:none}",
    "h1,h2,.prompt{break-after:avoid;page-break-after:avoid}.response{break-inside:avoid}}",
    "</style></head><body>", paste0("<h1>", escape(x$title), "</h1>"))
  for (i in seq_len(nrow(x$activities))) {
    a <- x$activities[i, ]
    hits <- x$selected[x$selected$activity_id == a$activity_id, , drop = FALSE]
    html <- c(html, paste0("<section><h2>", labels[1], " ", i, "</h2>"),
      paste0('<p class="prompt">', escape(a$prompt), "</p>"), "<ol>")
    for (j in seq_len(nrow(hits))) {
      h <- hits[j, ]
      html <- c(html, paste0('<li><p class="context">', escape(h$pre),
        "<strong>", escape(h$keyword), "</strong>", escape(h$post), "</p>"),
        paste0('<p class="citation">', labels[2], ": ", escape(h$citation), "</p>"),
        paste0('<p class="usage">', labels[3], ": ", escape(h$usage), "</p></li>"))
    }
    html <- c(html, "</ol>", paste0("<p>", labels[4], "</p>"),
      paste0('<div class="response" aria-label="', labels[4], '"></div></section>'))
  }
  html <- enc2utf8(c(html, "</body></html>"))
  teacher <- x$selected
  a <- match(teacher$activity_id, x$activities$activity_id)
  teacher$activity_number <- a
  teacher$item_number <- sequence(tabulate(a, nrow(x$activities)))
  teacher$prompt <- x$activities$prompt[a]
  teacher$teacher_note <- x$activities$teacher_note[a]
  # CSV is a display export; keep untouched values in the private RDS.
  for (name in names(teacher)) if (is.character(teacher[[name]])) {
    z <- teacher[[name]]
    protect <- !is.na(z) & stringi::stri_detect_regex(z,
      "^[\\p{White_Space}]*[=+@-]|^[\\t\\r\\n]")
    z[protect] <- paste0("'", z[protect])
    # write.table otherwise translates UTF-8 to <U+....> in a C locale.
    # Prepare UTF-8 bytes explicitly, then write without native conversion.
    z <- enc2utf8(z)
    Encoding(z) <- "unknown"
    teacher[[name]] <- z
  }
  if (!dir.create(directory)) stop("Could not create output directory.", call. = FALSE)
  complete <- FALSE
  on.exit(if (!complete) unlink(directory, recursive = TRUE), add = TRUE)
  paths <- file.path(directory, c("learner.html", "teacher.csv", "material.rds"))
  writeLines(html, paths[1], useBytes = TRUE)
  utils::write.csv(teacher, paths[2], row.names = FALSE, na = "",
    fileEncoding = "")
  saveRDS(x, paths[3], version = 2)
  complete <- TRUE
  invisible(stats::setNames(paths, c("learner", "teacher", "record")))
}
