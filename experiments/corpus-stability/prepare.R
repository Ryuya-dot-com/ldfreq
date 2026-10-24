# Rscript experiments/corpus-stability/prepare.R package-root private-cache
args <- commandArgs(TRUE)
stopifnot(length(args) == 2L)
root <- normalizePath(args[[1]])
cache <- normalizePath(args[[2]])
pkgload::load_all(root, quiet = TRUE)
hashes <- c(answer = "8fc5b9dc8148f0330231d67efc2f855a6ee520aeabe2be4afdb442b3ce6e6f82",
  course = "d6b710cd284126383f96dd9fccc088ba3dcb28b5e80349cde531d565254c22c2",
  question = "0b789694740ffae6620bb3f3e65d3ed18dcde3278fa1de5d821fbcaf5873e5cf")
for (name in names(hashes)) stopifnot(identical(
  digest::digest(file = file.path(cache, paste0(name, ".csv")), algo = "sha256"), hashes[[name]]))
read <- function(name, ...) read.csv(file.path(cache, paste0(name, ".csv")),
  fileEncoding = "UTF-8", stringsAsFactors = FALSE, ...)
x <- read("answer", colClasses = c(rep("character", 7), "NULL", "NULL"))
courses <- read("course", colClasses = "character")
questions <- read("question", colClasses = "character")
x$class <- courses$class_id[match(x$course_id, courses$course_id)]
x$level <- courses$level_id[match(x$course_id, courses$course_id)]
x$type <- questions$question_type_id[match(x$question_id, questions$question_id)]
x <- x[which(x$version == "1" & x$class == "w" & x$type == "4"), ]
x <- x[order(as.integer(x$answer_id)), ]
# Retain the first original response per writer and prompt; revisions excluded.
x <- x[!duplicated(x[c("anon_id", "question_id")]), ]
tokens <- lapply(x$text, function(text) lexdiv_tokenize(text,
  tokenizer = "english", normalization = "NFC", case = "lower",
  keep_numbers = FALSE)$tokens$surface)
x$N <- lengths(tokens)
text_hashes <- vapply(x$text, digest::digest, character(1), algo = "sha256", serialize = FALSE)
names(tokens) <- x$answer_id
saveRDS(list(metadata = x[setdiff(names(x), c("text", "text_len"))], tokens = tokens,
  text_sha256 = text_hashes, input_sha256 = hashes), file.path(cache, "prepared-private.rds"))
print(data.frame(documents = nrow(x), writers = length(unique(x$anon_id)),
  prompts = length(unique(x$question_id)), tokens = sum(x$N)))
print(quantile(x$N, c(0,.1,.25,.5,.75,.9,1)))
print(table(x$level))
for (minimum in c(50,100,200,400,800)) {
  z <- x[x$N >= minimum, ]
  print(data.frame(minimum = minimum, documents = nrow(z),
    writers = length(unique(z$anon_id)), prompts = length(unique(z$question_id))))
}
