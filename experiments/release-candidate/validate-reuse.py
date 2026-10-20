"""Regression checks for the fail-closed evidence reuse boundary; no network."""
import copy
import importlib.util
from pathlib import Path
from unittest.mock import patch
import sys
import subprocess
import textwrap
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

report_before = 'stopifnot(identical(saved$inference$tables, record$inference$tables),'
report_after = 'stopifnot(identical(saved$inference$settings$df_method, "kenward-roger"),'
with patch.object(reuse, "git", return_value=report_before):
    with patch.object(Path, "read_text", return_value=report_after):
        reuse.verify_ci(separate, ["vignettes/repeated-observations.Rmd"],
                        workflow, workflow, run, "owner/repo")
    with patch.object(Path, "read_text", return_value=report_after + "\nfit <- different_model()"):
        rejects(lambda: reuse.verify_ci(separate, ["vignettes/repeated-observations.Rmd"],
                                       workflow, workflow, run, "owner/repo"))

platform_state = {"Platform-Validation-Commit": "a" * 40, "Platform-Validation-Run": "123"}
platform_old = "".join(
    "  " + name + ":\n    runs-on: ${{ matrix.os }}\n"
    "    strategy:\n      matrix:\n        " + key + ": old\n"
    "    steps:\n      - run: check\n"
    for name, key in (("check", "config"), ("tubelex-build-audit", "os")))
platform_new = platform_old.replace("config: old",
    "config: ${{ fromJSON(needs.validation-scope.outputs.check-matrix) }}").replace(
    "os: old", "os: ${{ fromJSON(needs.validation-scope.outputs.builder-matrix) }}")
platform_run = copy.deepcopy(run)
platform_run["conclusion"] = "failure"
platform_jobs = [{"name": name, "status": "completed", "conclusion": "success"}
                 for name in ("macos-latest / R release", "windows-latest / R release",
                              "windows-latest / TUBELEX builder")]
reuse.verify_platform_reuse(platform_state, [], platform_old, platform_new,
                           platform_run, "owner/repo", platform_jobs)
for changed in ("R/core.R", "DESCRIPTION", "tests/testthat/test-example.R",
                "vignettes/repeated-observations.Rmd"):
    rejects(lambda: reuse.verify_platform_reuse(platform_state, [changed],
        platform_old, platform_new, platform_run, "owner/repo", platform_jobs))
for index in range(3):
    bad = copy.deepcopy(platform_jobs)
    bad[index]["conclusion"] = "failure"
    rejects(lambda: reuse.verify_platform_reuse(platform_state, [],
        platform_old, platform_new, platform_run, "owner/repo", bad))
rejects(lambda: reuse.verify_platform_reuse(platform_state, [], platform_old,
    platform_new.replace("run: check", "run: skip"), platform_run, "owner/repo", platform_jobs))
for field, value in (("status", "in_progress"), ("head_sha", "b" * 40),
                     ("path", "other.yaml"), ("id", 456),
                     ("repository", {"full_name": "other/repo"})):
    bad = copy.deepcopy(platform_run); bad[field] = value
    rejects(lambda: reuse.verify_platform_reuse(platform_state, [],
        platform_old, platform_new, bad, "owner/repo", platform_jobs))
rejects(lambda: reuse.verify_platform_reuse(platform_state, [], platform_old,
    platform_new, platform_run, "owner/repo", platform_jobs[:2]))
rejects(lambda: reuse.verify_platform_reuse(platform_state, [], platform_old,
    platform_new, platform_run, "owner/repo", platform_jobs + platform_jobs[:1]))
print("Platform reuse requires unchanged payload, unchanged reused steps and three completed successful jobs.")

linux_workflow = platform_new + "".join(
    "  " + name + ":\n    runs-on: ubuntu-24.04\n    steps:\n      - run: check\n"
    for name in ("prepare-r-devel", "check-r-devel", "c-locale"))
linux_jobs = [{"name": name, "status": "completed", "conclusion": "success"}
              for name in ("ubuntu-24.04 / R release", "ubuntu-24.04 / R devel",
                           "ubuntu-24.04 / C locale", "ubuntu-24.04 / TUBELEX builder")]
old_pin = "${{ matrix.config.r == '4.1' && 'Matrix@1.6-5 MASS@7.3-60 readxl@1.4.5' || '' }}"
new_pin = old_pin.replace("readxl@1.4.5", "readxl@1.4.5 pbkrtest@0.5.2")
linux_old = linux_workflow.replace("      - run: check", "      - run: check\n            " + old_pin, 1)
linux_new = linux_old.replace(old_pin, new_pin)
reuse.verify_platform_reuse(platform_state, [], linux_old, linux_new,
                           platform_run, "owner/repo", linux_jobs, linux=True)
for index in range(4):
    for field, value in (("conclusion", "failure"), ("status", "in_progress")):
        bad = copy.deepcopy(linux_jobs); bad[index][field] = value
        rejects(lambda: reuse.verify_platform_reuse(platform_state, [], linux_old,
            linux_new, platform_run, "owner/repo", bad, linux=True))
for altered in (linux_new.replace("r == '4.1'", "r == 'release'"),
                linux_new.replace("pbkrtest@0.5.2", "pbkrtest@0.5.3"),
                linux_new.replace("run: check", "run: skip")):
    rejects(lambda: reuse.verify_platform_reuse(platform_state, [], linux_old,
        altered, platform_run, "owner/repo", linux_jobs, linux=True))
for bad in (linux_jobs[:3], linux_jobs + linux_jobs[:1]):
    rejects(lambda: reuse.verify_platform_reuse(platform_state, [], linux_old,
        linux_new, platform_run, "owner/repo", bad, linux=True))
print("Additional Linux evidence requires four successful jobs; only the exact R 4.1 pin is exempt.")

aggregate = Path(".github/workflows/R-CMD-check.yaml").read_text().split(
    "      - name: Require every matrix check to pass\n", 1)[1].split("        run: |\n", 1)[1]
aggregate = textwrap.dedent(aggregate)
keys = ("CHECK_RESULT", "DEVEL_RESULT", "C_LOCALE_RESULT", "TUBELEX_RESULT", "PDF_MANUAL_RESULT")
for retained in ("false", "true"):
    valid = dict.fromkeys(keys, "success")
    valid["LINUX_REUSE"] = retained
    if retained == "true":
        for key in keys[1:4]:
            valid[key] = "skipped"
    assert subprocess.run(["/bin/bash", "-c", aggregate], env=valid, capture_output=True).returncode == 0
    for key in keys:
        for invalid in ("failure", "cancelled", ""):
            bad = dict(valid, **{key: invalid})
            assert subprocess.run(["/bin/bash", "-c", aggregate], env=bad, capture_output=True).returncode != 0
    if retained == "false":
        bad = dict(valid, DEVEL_RESULT="skipped")
        assert subprocess.run(["/bin/bash", "-c", aggregate], env=bad, capture_output=True).returncode != 0
print("The aggregate accepts only fresh success or explicitly verified retained jobs; failure cannot pass.")
