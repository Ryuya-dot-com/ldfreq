test_that("the installed offline smoke script exercises exported workflows", {
  smoke_path <- system.file(
    "examples",
    "offline-smoke.R",
    package = "ldfreq"
  )
  expect_true(nzchar(smoke_path))

  smoke_environment <- new.env(parent = asNamespace("ldfreq"))
  smoke <- source(smoke_path, local = smoke_environment)
  expect_true(isTRUE(smoke$value))
})
