test_that("inspection and missing readers do not create or download caches", {
  cache <- tempfile("absent-cache-")
  withr::local_options(ldfreq.resource_dir=cache)
  expect_false(dir.exists(cache))
  info <- lexdiv_resource_info()
  expect_false(any(info$available))
  expect_false(dir.exists(cache))
  expect_error(lexdiv_download_resources("morpholex"), "accept_license")
  expect_error(morpholex_data(), "lexdiv_download_resources")
  expect_error(nj8_profile("word"), "lexdiv_download_resources")
  expect_error(bnccoca_data(), "lexdiv_download_resources")
  expect_false(dir.exists(cache))
  expect_equal(lexdiv_metrics(c("a","b","a"), metrics="ttr")$value, 2/3)
})

test_that("explicit resource downloads verify archives, files and reuse", {
  scratch <- tempfile(); dir.create(scratch); withr::local_dir(scratch)
  on.exit(unlink(scratch,recursive=TRUE),add=TRUE)
  writeLines("Authored MIT fixture, not third-party data", "data.txt")
  archive <- file.path(scratch,"fixture.tar.gz")
  utils::tar(archive,files="data.txt",compression="gzip",tar="internal")
  item <- list(version="fixture-v1",license="MIT",license_url="https://opensource.org/license/mit",
    citation="Authored test",url=paste0("file://",archive),bytes=unname(file.info(archive)$size),
    sha256=digest::digest(file=archive,algo="sha256"),
    files=setNames(list(digest::digest(file="data.txt",algo="sha256")),"data.txt"))
  local_mocked_bindings(.lex_resource_catalog=list(tubelex=item),.package="ldfreq")
  cache <- file.path(scratch,"cache")
  result <- lexdiv_download_resources("tubelex",TRUE,cache)
  expect_true(result$available)
  unlink(archive) # A verified cache must be reusable without the source URL.
  expect_identical(lexdiv_download_resources("tubelex",TRUE,cache),result)
  file <- file.path(result$path,"data.txt")
  writeLines("modified",file)
  expect_false(lexdiv_resource_info("tubelex",cache)$available)
  expect_error(lexdiv_download_resources("tubelex",TRUE,cache),"incomplete or modified")
  expect_identical(readLines(file),"modified")
})

test_that("wrong types and implicit acceptance are rejected before networking", {
  for(bad in list(factor("tubelex"),data.frame(x="tubelex"),matrix("tubelex"),
    I("tubelex"),c("tubelex","tubelex"),NA_character_,character()))
    expect_error(lexdiv_resource_info(bad),"resources")
  for(bad in list(factor("x"),data.frame(x="x"),matrix("x"),I("x"),c("x","y"),""))
    expect_error(lexdiv_resource_info(cache_dir=bad),"cache_dir")
  for(bad in list(1L,"TRUE",NA,logical(),c(TRUE,TRUE),I(TRUE)))
    expect_error(lexdiv_download_resources("tubelex",bad),"accept_license")
})

test_that("corrupt downloads cannot leave an apparently installed resource", {
  scratch <- tempfile();dir.create(scratch);withr::local_dir(scratch)
  on.exit(unlink(scratch,recursive=TRUE),add=TRUE)
  writeLines("Authored fixture", "data.txt")
  archive <- file.path(scratch,"fixture.tar.gz")
  utils::tar(archive,files="data.txt",compression="gzip",tar="internal")
  make_item <- function() list(version="fixture",license="MIT",license_url="https://opensource.org/license/mit",
    citation="Authored test",url=paste0("file://",archive),bytes=unname(file.info(archive)$size),
    sha256=digest::digest(file=archive,algo="sha256"),files=list(data.txt=digest::digest(file="data.txt",algo="sha256")))
  for(failure in c("archive-hash","member-hash","unexpected-member")) local({
    item <- make_item()
    if(failure=="archive-hash") item$sha256 <- paste(rep("0",64),collapse="")
    if(failure=="member-hash") item$files$data.txt <- paste(rep("0",64),collapse="")
    if(failure=="unexpected-member") names(item$files) <- "different.txt"
    local_mocked_bindings(.lex_resource_catalog=list(tubelex=item),.package="ldfreq")
    cache <- file.path(scratch,failure)
    expect_error(lexdiv_download_resources("tubelex",TRUE,cache),
      "SHA-256|verification|unexpected members")
    expect_false(dir.exists(file.path(cache,"tubelex","fixture")))
    expect_length(list.files(file.path(cache,"tubelex"),all.files=TRUE,no..=TRUE),0L)
  })
})
