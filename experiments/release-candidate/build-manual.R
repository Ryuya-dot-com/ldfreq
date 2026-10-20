arguments <- commandArgs(trailingOnly = TRUE)
stopifnot(length(arguments) == 2L)
package_root <- normalizePath(arguments[[1L]], mustWork = TRUE)
manual <- normalizePath(arguments[[2L]], mustWork = FALSE)
build <- paste0(manual, "-build")
stopifnot(!dir.exists(build))
config <- paste0(manual, "-tex")
stopifnot(dir.create(config))
writeLines(c("\\AtBeginDocument{\\sloppy}",
  "\\NewCommandCopy\\ldfreqUnderscore\\_",
  "\\NewCommandCopy\\ldfreqTexttt\\texttt",
  "\\DeclareRobustCommand{\\texttt}[1]{\\begingroup\\def\\_{\\ldfreqUnderscore\\allowbreak}\\ldfreqTexttt{#1}\\endgroup}"),
  file.path(config, "Rd.cfg"))
# Avoid texi2dvi's silent index omission on its fallback compilation.
Sys.setenv(R_TEXI2DVICMD = "emulation",
  TEXINPUTS = paste(normalizePath(config), Sys.getenv("TEXINPUTS"), sep = .Platform$path.sep))
status <- system2(file.path(R.home("bin"), "R"), c(
  "CMD", "Rd2pdf", "--no-preview", "--no-clean", "--force",
  paste0("--build-dir=", shQuote(build)),
  paste0("--output=", shQuote(manual)), shQuote(package_root)))
if (!identical(status, 0L)) quit(status = status)
index <- file.path(build, "Rd2.ind")
stopifnot(file.exists(manual), file.info(manual)$size > 0,
  file.exists(index), file.info(index)$size > 0)
lines <- readLines(index, warn = FALSE)
stopifnot(any(grepl("\\begin{theindex}", lines, fixed = TRUE)),
  any(grepl("lexdiv", lines, fixed = TRUE)),
  any(grepl("tubelex", lines, fixed = TRUE)))
cat("PDF manual and nonempty function index verified.\n")
