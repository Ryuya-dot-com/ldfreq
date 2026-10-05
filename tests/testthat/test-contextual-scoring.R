scoring_fixture <- function(japanese = FALSE) {
  word <- if (japanese) "人気" else "bank"
  candidates <- data.frame(term = rep(c(word, "paper", "cancel", "lost", "unseen"), each = 2),
    candidate_id = rep(c("a", "b"), 5), label = paste("authored", seq_len(10)))
  resource <- list(resource_id = "authored", resource_version = "1",
    source_reference = "Authored test candidates", data_license = "MIT")
  model <- list(model_id = "authored", model_revision = "1", tokenizer_id = "authored",
    tokenizer_revision = "1", software = "test", software_version = "1",
    context_policy = "full segment; no truncation", representation = "authored 2-dimensional vectors")
  make <- function(prefix, words, vectors, labels = NULL, texts = NULL) {
    pieces <- Map(function(i, word) c(paste0(prefix, i), word), seq_along(words), words)
    tokens <- data.frame(document_id = paste0(prefix, "-doc"),
      segment_id = rep(paste0("s", seq_along(words)), each = 2),
      token_index = rep(1:2, length(words)), surface = unlist(pieces, use.names = FALSE))
    if (is.null(texts)) texts <- vapply(pieces, paste, character(1), collapse = " ")
    source <- lexdiv_import_annotations(tokens, data.frame(document_id = paste0(prefix, "-doc"),
      segment_id = paste0("s", seq_along(words)), text = texts),
      list(language = "authored", analyzer = "authored", analyzer_version = "1",
        dictionary = "none", dictionary_version = "none", unit = "test", normalization = "none"))
    review <- lexdiv_ambiguity_review(source, c(word, "paper", "cancel", "lost", "unseen", "none", "absent"),
      candidates, resource)
    ids <- review$occurrences$occurrence_id
    data <- review$occurrences[c("review_id", "occurrence_id", "segment_text", "surface", "start", "end")]
    available <- rowSums(is.na(vectors)) == 0L
    data$status <- ifelse(available, "processed", "skipped")
    data$reason <- "Authored vector or illustrated missing output"
    vectors <- vectors[available, , drop = FALSE]; rownames(vectors) <- ids[available]
    output <- lexdiv_import_contextual(review, data, model, vectors)
    reference <- review
    if (!is.null(labels)) {
      d <- data[c("review_id", "occurrence_id")]
      d$status <- ifelse(is.na(labels), "unresolved", "selected"); d$candidate_id <- labels
      d$reviewer <- "authored"; d$reason <- "Authored test labels"
      reference <- lexdiv_ambiguity_review(source, review$summary$term, candidates, resource, d)
    }
    list(output = output, reference = reference)
  }
  tr <- make("train", c(rep(word, 4), "paper", "paper", "cancel", "cancel", "cancel", "lost", word),
    matrix(c(2,0, 0,4, 0,-3, 1,1, 1,0, 0,0, 1,0, -1,0, 0,1, NA,NA, NA,NA), ncol = 2, byrow = TRUE),
    c("a","a","b",NA,"a","b","a","a","b","a","a"))
  qu <- make("query", c(word,word,word,"paper","cancel","lost","unseen","none",word),
    matrix(c(1,0, 0,-1, 0,0, 1,0, 0,1, 1,0, 1,0, 1,0, NA,NA), ncol = 2, byrow = TRUE))
  list(x = qu$output, training = tr$output, reference = tr$reference,
    training_info = list(training_id = "authored", annotation_protocol = "Authored test labels",
      partition_protocol = "Different authored documents and target contexts", model_exposure = "unknown"))
}

score_fixture <- function(f) do.call(lexdiv_score_contextual, f)
reimport_scoring <- function(x, review = x$review, embeddings = x$embeddings, model = x$provenance$model) {
  lexdiv_import_contextual(review, x$data, model, embeddings)
}

test_that("raw-vector centroids, frequency counts and missingness agree with hand calculations", {
  skip_if_not_installed("quanteda", "4.5.0")
  f <- scoring_fixture(); out <- score_fixture(f)
  k <- match("bank", out$candidates$term)
  expect_equal(unname(out$prototypes[k, ]), c(1,2)/sqrt(5))
  expect_equal(out$centroid$suggestions$score[1:4], c(1/sqrt(5),0,-2/sqrt(5),1))
  expect_equal(out$frequency$suggestions$score[1:6], rep(c(3,1),3))
  expect_equal(out$candidates$n_selected, c(3,1,2,1,1,0,1,1,0,0))
  expect_equal(out$candidates$n_vectors, c(2,1,2,1,0,0,1,0,0,0))
  expect_identical(out$candidates$prototype_status,
    c("available","available","zero_centroid","available","no_valid_vectors",
      "no_selected_reference","available","no_valid_vectors","no_selected_reference","no_selected_reference"))
  expect_identical(out$query_occurrences$centroid_status, c("complete_scores","complete_scores",
    "zero_embedding","incomplete_scores","incomplete_scores","no_prototypes","no_prototypes",
    "no_candidates","missing_embedding"))
  expect_identical(out$query_occurrences$frequency_status, c(rep("complete_scores",6),
    "no_selected_training","no_candidates","complete_scores"))
  expect_equal(sum(out$training_occurrences$frequency_used),10)
  expect_equal(sum(out$training_occurrences$centroid_used),7)
  expect_identical(out$training_occurrences$centroid_status[c(4,6,10,11)],
    c("reference_not_selected","zero_embedding","missing_embedding","missing_embedding"))
  info <- list(reference_id="test", annotation_protocol="Unreviewed query", model_exposure="unknown",
    evaluation_role="development")
  ev <- lexdiv_evaluate_contextual(out$centroid, f$x$review, "higher", info)
  expect_equal(ev$summary$predictions,2)
  expect_identical(ev$pairs$predicted_candidate_id[1:2],c("a","b"))
  expect_equal(ev$summary$incomplete_scores,2)
  expect_equal(ev$summary$reference_selected,0)
  freq <- lexdiv_evaluate_contextual(out$frequency, f$x$review, "higher", info)
  expect_equal(freq$summary$predictions,6)
  expect_equal(freq$summary$tied_best,1)
  expect_identical(out$query,f$x); expect_identical(out$training,f$training)
  expect_identical(out$reference,f$reference)
  expect_identical(out$centroid$occurrences$status,f$x$occurrences$status)
  expect_identical(out$query_occurrences$model_status,f$x$occurrences$model_status)
  path<-tempfile(); on.exit(unlink(path)); saveRDS(out,path)
  expect_identical(readRDS(path),out)
})

test_that("query labels and preexisting suggestions never train or score the baselines", {
  skip_if_not_installed("quanteda", "4.5.0")
  f<-scoring_fixture(); expected<-score_fixture(f)
  r<-f$x$review; d<-r$occurrences[1:2,c("review_id","occurrence_id")]
  d$status<-"selected"; d$candidate_id<-c("b","a"); d$reviewer<-"authored"; d$reason<-"Changed query labels"
  r<-lexdiv_ambiguity_review(r$source,r$summary$term,r$candidates,r$provenance$resource,d)
  s<-data.frame(occurrence_id=d$occurrence_id,candidate_id=c("b","a"),score=c(1e6,1e6))
  model<-f$x$provenance$model; model$score_definition<-"Ignored prior scores"
  f$x<-lexdiv_import_contextual(r,f$x$data,model,f$x$embeddings,s)
  out<-score_fixture(f)
  expect_identical(out$prototypes,expected$prototypes)
  for (method in c("centroid","frequency")) {
    expect_identical(out[[method]]$suggestions[c("occurrence_id","candidate_id","score")],
      expected[[method]]$suggestions[c("occurrence_id","candidate_id","score")])
    expect_identical(out[[method]]$review,r)
  }
})

test_that("split checks reject reused documents and renamed copies of contexts", {
  skip_if_not_installed("quanteda", "4.5.0")
  f<-scoring_fixture(); f$x<-f$training
  expect_error(score_fixture(f),"document IDs")
  f<-scoring_fixture(); r<-f$training$review
  tokens<-r$source$tokens; segments<-r$source$segments[c("document_id","segment_id","text")]
  tokens$document_id<-segments$document_id<-"renamed-doc"
  source<-lexdiv_import_annotations(tokens,segments,r$source$provenance$annotation)
  review<-lexdiv_ambiguity_review(source,r$summary$term,r$candidates,r$provenance$resource)
  data<-review$occurrences[c("review_id","occurrence_id","segment_text","surface","start","end")]
  data$status<-f$training$data$status; data$reason<-"Renamed source copy"
  v<-f$training$embeddings; rownames(v)<-data$occurrence_id[data$status=="processed"]
  f$x<-lexdiv_import_contextual(review,data,f$training$provenance$model,v)
  expect_error(score_fixture(f),"identical target-bearing")
})

test_that("changed snapshots, incompatible models and invalid declarations are rejected", {
  skip_if_not_installed("quanteda", "4.5.0")
  f<-scoring_fixture()
  for (which in c("x","training")) {
    bad<-f; bad[[which]]$embeddings[1,1]<-99
    expect_error(score_fixture(bad),"unmodified")
  }
  bad<-f; bad$reference$occurrences$candidate_id[1]<-"b"
  expect_error(score_fixture(bad),"unmodified")
  bad<-f; bad$reference<-f$x$review
  expect_error(score_fixture(bad),"training review")
  for (field in c("model_revision","representation","software_version")) {
    bad<-f; m<-f$x$provenance$model; m[[field]]<-"other"
    bad$x<-reimport_scoring(f$x,model=m)
    expect_error(score_fixture(bad),"matching dimensions")
  }
  bad<-f; bad$x<-reimport_scoring(f$x,embeddings=cbind(f$x$embeddings,0))
  expect_error(score_fixture(bad),"matching dimensions")
  bad<-f; v<-f$x$embeddings; colnames(v)<-c("second","first")
  bad$x<-reimport_scoring(f$x,embeddings=v)
  expect_error(score_fixture(bad),"column names")
  for (field in names(f$training_info)) {
    bad<-f; bad$training_info[[field]]<-NULL
    expect_error(score_fixture(bad),"training_info requires")
  }
  bad<-f; bad$training_info$model_exposure<-"independent"
  expect_error(score_fixture(bad),"model_exposure")
  bad<-f; bad$training_info$partition_protocol<-" "
  expect_error(score_fixture(bad),"blank")
})

test_that("scaling, order and an empty training reference preserve explicit results", {
  skip_if_not_installed("quanteda", "4.5.0")
  f<-scoring_fixture(); expected<-score_fixture(f)
  for (scale in c(1e300,1e-300)) {
    scaled<-f
    scaled$x<-reimport_scoring(f$x,embeddings=f$x$embeddings*scale)
    scaled$training<-reimport_scoring(f$training,embeddings=f$training$embeddings*scale)
    expect_equal(score_fixture(scaled)$centroid$suggestions$score,expected$centroid$suggestions$score)
  }
  r<-f$reference
  f$reference<-lexdiv_ambiguity_review(r$source,rev(r$summary$term),r$candidates[nrow(r$candidates):1,],
    r$provenance$resource,r$decisions[nrow(r$decisions):1,],window=0)
  expect_identical(score_fixture(f)$centroid$suggestions,expected$centroid$suggestions)
  f$reference<-f$training$review
  empty<-score_fixture(f)
  expect_equal(nrow(empty$centroid$suggestions),0)
  expect_equal(nrow(empty$frequency$suggestions),0)
  expect_equal(empty$centroid$summary$occurrences,9)
  expect_true(all(empty$candidates$n_selected==0))
})

test_that("Japanese surfaces keep candidate IDs scoped to their own term", {
  skip_if_not_installed("quanteda", "4.5.0")
  skip_if_not(isTRUE(l10n_info()[["UTF-8"]]))
  out<-score_fixture(scoring_fixture(TRUE))
  expect_identical(out$centroid$suggestions$surface[1:4],rep("人気",4))
  expect_equal(out$centroid$suggestions$score[1:4],c(1/sqrt(5),0,-2/sqrt(5),1))
  expect_equal(out$candidates$n_selected[out$candidates$term=="人気"],c(3,1))
})

test_that("empty query and training inputs retain stable tables and missing prototypes", {
  skip_if_not_installed("quanteda", "4.5.0")
  f<-scoring_fixture(); r<-f$x$review
  source<-lexdiv_import_annotations(r$source$tokens[FALSE,],
    data.frame(document_id="empty-only",segment_id="s",text=""),r$source$provenance$annotation)
  review<-lexdiv_ambiguity_review(source,r$summary$term,r$candidates,r$provenance$resource)
  data<-review$occurrences[c("review_id","occurrence_id","segment_text","surface","start","end")]
  data$status<-data$reason<-character()
  empty<-lexdiv_import_contextual(review,data,f$x$provenance$model,f$x$embeddings[FALSE,,drop=FALSE])
  bad<-f; bad$x<-empty
  out<-score_fixture(bad)
  expect_equal(out$centroid$summary$occurrences,0)
  expect_type(out$query_occurrences$centroid_status,"character")
  expect_equal(nrow(out$frequency$suggestions),0)
  bad<-f; bad$training<-empty; bad$reference<-review
  out<-score_fixture(bad)
  expect_equal(nrow(out$training_occurrences),0)
  expect_equal(nrow(out$centroid$suggestions),0)
  expect_equal(nrow(out$frequency$suggestions),0)
  expect_true(all(is.na(out$prototypes)))
  expect_equal(out$centroid$summary$occurrences,9)
})

test_that("candidate metadata, resource changes and reserved audit names cannot be silently combined", {
  skip_if_not_installed("quanteda", "4.5.0")
  f<-scoring_fixture(); r<-f$x$review
  for (field in c("label","resource","reserved")) {
    candidates<-r$candidates; resource<-r$provenance$resource
    if (field=="label") candidates$label[1]<-"different interpretation"
    if (field=="resource") resource$resource_version<-"2"
    if (field=="reserved") candidates$n_selected<-0
    nr<-lexdiv_ambiguity_review(r$source,r$summary$term,candidates,resource)
    data<-f$x$data; data$review_id<-nr$provenance$review_id
    bad<-f; bad$x<-lexdiv_import_contextual(nr,data,f$x$provenance$model,f$x$embeddings)
    expect_error(score_fixture(bad),"same targets")
    if (field=="reserved") {
      tr<-f$training$review
      tr<-lexdiv_ambiguity_review(tr$source,tr$summary$term,candidates,resource)
      data<-f$training$data; data$review_id<-tr$provenance$review_id
      bad$training<-lexdiv_import_contextual(tr,data,f$training$provenance$model,f$training$embeddings)
      bad$reference<-tr
      expect_error(score_fixture(bad),"reserved scoring")
    }
  }
})
