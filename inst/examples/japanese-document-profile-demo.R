# Authored offline example. The CSV's POS/origin labels are teaching inputs,
# not actual UniDic output. The existing file recipe retains all source/decisions.
sys.source(system.file("examples", "japanese-file-workflow.R", package = "ldfreq", mustWork = TRUE),
  envir = environment())

## ---- ja-profile-load
sys.source(system.file("examples", "japanese-document-profile.R", package = "ldfreq", mustWork = TRUE),
  envir = environment())

## ---- ja-profile-build
# A declared, deliberately partial example map; other POS remain unmapped.
ja_pos_groups <- c("名詞" = "content", "動詞" = "content", "形容詞" = "content",
  "形状詞" = "content", "副詞" = "content", "助詞" = "function", "助動詞" = "function")
ja_profile <- japanese_document_profile(ja_file_import, ja_file_selection,
  pos_groups = ja_pos_groups, condition = "authored-body-excluding-full-stops")
stopifnot(isTRUE(all.equal(ja_profile$documents$retained_N, as.data.frame(ja_file_metrics)$N)))

## ---- ja-profile-save
ja_profile_record <- list(profile = ja_profile, file_review = ja_file_record)
saveRDS(ja_profile_record, file.path(ja_file_output, "document-profile.rds"), version = 2)
for (name in c("documents", "characters", "features"))
  utils::write.csv(ja_profile[[name]], file.path(ja_file_output, paste0("profile-", name, ".csv")),
    row.names = FALSE, fileEncoding = "UTF-8", na = "NA")
stopifnot(identical(readRDS(file.path(ja_file_output, "document-profile.rds")), ja_profile_record))

## ---- ja-profile-replay
saved_profile <- readRDS(file.path(ja_file_output, "document-profile.rds"))$profile
replayed_profile <- japanese_document_profile(saved_profile$imported, saved_profile$selection,
  saved_profile$policy$pos_groups, saved_profile$policy$condition,
  pos_col = saved_profile$policy$pos_col, origin_col = saved_profile$policy$origin_col)
stopifnot(identical(replayed_profile, saved_profile))
