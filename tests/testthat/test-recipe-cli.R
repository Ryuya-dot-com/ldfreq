test_that("installed CLI and Python bridge use the R engine and preserve failures", {
  skip_if_not_installed("jsonlite")
  script <- system.file("exec", "ldfreq.R", package = "ldfreq")
  skip_if(!nzchar(script), "CLI requires the installed package")
  root <- tempfile("recipe-cli-")
  dir.create(root)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  input <- file.path(root, "input"); dir.create(input)
  writeBin(charToRaw("A cat and a dog.\r\n"), file.path(input, "001.txt"))
  file.create(file.path(input, "empty.txt"))
  dir.create(file.path(input, "nested"))
  writeBin(charToRaw("More text."), file.path(input, "nested", "001.txt"))
  withr::local_envvar(c(R_LIBS = paste(.libPaths(), collapse = .Platform$path.sep),
    PYTHONDONTWRITEBYTECODE = "1"))
  log <- file.path(root, "cli.log")
  cli <- function(args) suppressWarnings(system2(file.path(R.home("bin"), "Rscript"),
    shQuote(c("--vanilla", script, args)), stdout = log, stderr = log))
  recipe_path <- file.path(root, "recipe.json")
  expect_equal(cli(c("--init", recipe_path)), 0, info = paste(readLines(log), collapse = "\n"))
  output <- file.path(root, "output")
  args <- c("--recipe", recipe_path, "--input", input, "--output", output)
  expect_equal(cli(args), 0, info = paste(readLines(log), collapse = "\n"))
  from_cli <- lexdiv_read(file.path(output, "analysis.json"))
  direct <- lexdiv_run_recipe(c("001.txt" = "A cat and a dog.\r\n", "empty.txt" = ""),
    lexdiv_read(recipe_path))
  expect_identical(from_cli$analysis, direct$analysis)
  expect_identical(from_cli$documents, direct$documents)
  expect_equal(length(list.files(output)), 5)
  expect_equal(cli(args), 1)
  expect_identical(lexdiv_read(file.path(output, "analysis.json")), from_cli)
  args[6] <- file.path(root, "recursive")
  expect_equal(cli(c(args, "--recursive")), 0)
  recursive <- lexdiv_read(file.path(args[6], "analysis.json"))
  expect_equal(nrow(recursive$documents), 3)
  expect_true("nested/001.txt" %in% recursive$documents$document_id)
  writeBin(as.raw(c(255, 254)), file.path(input, "invalid.txt"))
  args[6] <- file.path(root, "failed")
  expect_equal(cli(args), 1)
  expect_false(dir.exists(args[6]))

  python <- Sys.which("python3")
  if (nzchar(python)) {
    # An existing Python ldfreq package must not be shadowed by the R bridge.
    legacy <- file.path(root, "existing-python")
    dir.create(file.path(legacy, "ldfreq"), recursive = TRUE)
    writeLines("origin = 'existing-python-package'", file.path(legacy, "ldfreq", "__init__.py"))
    withr::local_envvar(c(PYTHONPATH = paste(
      system.file("python", package = "ldfreq"), legacy, sep = .Platform$path.sep)))
    code <- paste(c(
      "import json, ldfreq, ldfreq_r, pathlib, subprocess",
      "assert ldfreq.origin == 'existing-python-package'",
      "recipe = ldfreq_r.default_recipe()",
      "a = ldfreq_r.analyze_text('A cat and a dog.\\r\\n', recipe)",
      "assert a['schema'] == 'ldfreq-analysis'",
      "assert a['documents']['data']['text'] == ['A cat and a dog.\\r\\n']",
      "assert a['analysis']['results']['data']['value'][0] == 0.8",
      "try:",
      "    ldfreq_r.analyze_text(3, recipe)",
      "except TypeError:",
      "    pass",
      "else:",
      "    raise AssertionError('non-text input accepted')"), collapse = "\n")
    status <- suppressWarnings(system2(python, c("-c", shQuote(code)), stdout = log, stderr = log))
    expect_equal(status, 0, info = paste(readLines(log), collapse = "\n"))
  }
})
