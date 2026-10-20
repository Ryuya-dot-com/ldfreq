"""Regression checks for the fail-closed evidence reuse boundary; no network."""
import copy
import importlib.util
from pathlib import Path
from unittest.mock import patch
import sys
sys.dont_write_bytecode = True

spec = importlib.util.spec_from_file_location("reuse", Path(__file__).with_name("verify-reuse.py"))
reuse = importlib.util.module_from_spec(spec)
spec.loader.exec_module(reuse)
state = {"Version": "0.4.0", "Source-Archive-Commit": "a" * 40, "Validation-Run": "123"}
workflow = "jobs:\n" + "".join(
    "  " + name + ":\n    runs-on: ubuntu-latest\n    steps:\n      - run: check\n"
    for name in ("check", "prepare-r-devel", "check-r-devel", "c-locale", "tubelex-build-audit"))
run = {"id": 123, "status": "completed", "conclusion": "success", "head_sha": "a" * 40,
       "path": ".github/workflows/R-CMD-check.yaml", "repository": {"full_name": "owner/repo"}}

def rejects(function):
    try:
        function()
    except ValueError:
        return
    raise AssertionError("Invalid reuse was accepted")

reuse.verify_ci(state, [], workflow, workflow, run, "owner/repo")
separate = {"Version": "0.4.0", "Validation-Commit": "a" * 40, "Validation-Run": "123"}
reuse.verify_ci(separate, ["man/tubelex_profile.Rd", "vignettes/release-scope.Rmd"],
                workflow, workflow, run, "owner/repo")
for changed in ("R/tubelex-profile.R", "tests/testthat/test-tubelex-profile.R",
                "inst/extdata/tubelex.csv", "DESCRIPTION", "NAMESPACE"):
    rejects(lambda: reuse.verify_ci(separate, [changed], workflow, workflow, run, "owner/repo"))
wrapped = workflow.replace("    runs-on:", "    needs: validation-scope\n    if: condition\n    runs-on:")
reuse.verify_ci(state, [], workflow, wrapped, run, "owner/repo")
rejects(lambda: reuse.verify_ci(state, [], workflow, workflow.replace("run: check", "run: skip"), run, "owner/repo"))
rejects(lambda: reuse.verify_ci(state, ["experiments/validate-japanese-tubelex.R"], workflow, workflow, run, "owner/repo"))
for field, value in (("id", 124), ("status", "in_progress"), ("conclusion", "failure"),
                     ("head_sha", "b" * 40), ("path", "another-workflow.yaml"),
                     ("repository", {"full_name": "another/repo"})):
    altered = copy.deepcopy(run); altered[field] = value
    rejects(lambda: reuse.verify_ci(state, [], workflow, workflow, altered, "owner/repo"))
for changed in ("R/core.R", "man/core.Rd", ".Rbuildignore", "vignettes/example.Rmd"):
    with patch.object(reuse, "git", return_value=changed):
        rejects(lambda: reuse.verify_source(state))
print("Evidence reuse rejects changed payload/test inputs, workflows, identity and incomplete/failed runs.")
