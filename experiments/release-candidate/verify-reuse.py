"""Verify declared reuse of an exact source archive or completed numeric CI."""
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys


def git(*args):
    return subprocess.check_output(["git", *args], text=True).strip()


def job_body(workflow, name):
    match = re.search(r"^  " + re.escape(name) + r":\n(.*?)(?=^  [\w-]+:|\Z)",
                      workflow, re.M | re.S)
    if not match:
        raise ValueError("Missing reused job: " + name)
    return "\n".join(line for line in match[1].splitlines()
                     if line.strip() and not line.lstrip().startswith("#")
                     and not re.match(r"^    (needs|if):", line))


def verify_source(state):
    commit = state["Source-Archive-Commit"]
    if not re.fullmatch(r"[0-9a-f]{40}", commit):
        raise ValueError("Invalid source-build commit")
    ignored = Path(".Rbuildignore").read_text().splitlines()
    if not all(rule in ignored for rule in (r"^\.github$", "^experiments$", "^development$")):
        raise ValueError("Reuse exclusions are no longer excluded from R builds")
    changed = git("diff", "--name-only", commit, "HEAD").splitlines()
    if any(not name.startswith((".github/", "experiments/", "development/")) for name in changed):
        raise ValueError("Package source changed since the declared source build")
    previous = git("show", commit + ":DESCRIPTION")
    if not re.search(r"^Version: " + re.escape(state["Version"]) + "$", previous, re.M):
        raise ValueError("Reused source has a different package version")
    return changed


def verify_ci(state, changed, old, new, run, repo, jobs=None):
    # Changed release controls are checked afresh; other test inputs must match.
    allowed_files = {".github/workflows/R-CMD-check.yaml",
                     ".github/workflows/release-candidate.yaml",
                     "development/RELEASE-CHECKLIST.md", "README.md",
                     "experiments/package-resource-inventory/check-resource-inventory.R"}
    allowed_controls = {"generate-release-evidence.R", "validate-public-scan.R",
                        "state.dcf", "verify-reuse.py", "validate-reuse.py",
                        "build-manual.R", "README.md", "RELEASE-CHECKLIST.md",
                        "run-as-cran-check.R", "assemble-run-index.R", "validate-note-policy.R",
                        "check-note-policy.R"}
    allowed_files.update("experiments/release-candidate/" + name for name in allowed_controls)
    builder_recheck = state.get("Recheck-TUBELEX-Builder") == "true"
    windows_recheck = state.get("Recheck-Windows") == "true"
    if "Recheck-Windows" in state and (not windows_recheck or not builder_recheck):
        raise ValueError("Invalid Windows recheck declaration")
    if "Recheck-TUBELEX-Builder" in state and not builder_recheck:
        raise ValueError("Invalid builder recheck declaration")
    if builder_recheck:
        # Only the separate resource builder changes; package checks must match.
        allowed_files = {".github/workflows/R-CMD-check.yaml"}
        allowed_files.update("experiments/release-candidate/" + name for name in (
            "state.dcf", "verify-reuse.py", "validate-reuse.py", "README.md"))
        allowed_files.update("experiments/tubelex-source-build/" + name for name in (
            "NOTICE.md", "README.md", "promote-tubelex-release.R",
            "validate-tubelex-release-unit.R"))
        if windows_recheck and ".gitattributes" in changed:
            previous = git("show", state["Validation-Commit"] + ":.gitattributes")
            anchor = "inst/licenses/tubelex/NOTICE.md -text"
            expected = previous.replace(anchor, anchor + "\ninst/licenses/tubelex/LICENSE -text")
            if previous.count(anchor) != 1 or Path(".gitattributes").read_text().strip() != expected:
                raise ValueError("Attributes change exceeds the byte-pinned LICENSE repair")
            allowed_files.add(".gitattributes")
        if set(changed) - allowed_files:
            raise ValueError("Builder recheck requires identical package and test inputs")
    # These documentation repairs are exercised by the fresh exact-archive
    # matrix. Runtime code, resources, tests and numeric audit inputs still
    # have to be byte-identical to the successful baseline.
    allowed_files.update("man/" + name + ".Rd" for name in (
        "lexdiv_evaluate_contextual", "lexdiv_score_contextual", "tubelex_profile"))
    allowed_files.update("vignettes/" + name + ".Rmd" for name in (
        "auditing-vocabulary-profiles", "getting-started", "release-scope",
        "word-families-and-affixes", "designing-comparisons", "contextual-models"))
    # One reporting-only repair: the fresh-session chunk must use saved data.
    reporting = "vignettes/repeated-observations.Rmd"
    if reporting in changed:
        commit = state.get("Validation-Commit", state.get("Source-Archive-Commit"))
        previous = git("show", commit + ":" + reporting)
        before = 'stopifnot(identical(saved$inference$tables, record$inference$tables),'
        after = 'stopifnot(identical(saved$inference$settings$df_method, "kenward-roger"),'
        if previous.count(before) != 1 or previous.replace(before, after) != Path(reporting).read_text().strip():
            raise ValueError("Repeated-study change exceeds the saved-report repair")
        allowed_files.add(reporting)
    if set(changed) - allowed_files:
        raise ValueError("Numeric CI inputs changed outside the rechecked release controls")
    for name in ("check", "prepare-r-devel", "check-r-devel", "c-locale", "tubelex-build-audit"):
        if job_body(old, name) != job_body(new, name):
            raise ValueError("Reused numeric CI definition changed: " + name)
    if not (str(run["id"]) == state["Validation-Run"]
            and (builder_recheck or run["conclusion"] == "success") and run["status"] == "completed"
            and run["head_sha"] == state.get("Validation-Commit", state.get("Source-Archive-Commit"))
            and run["path"] == ".github/workflows/R-CMD-check.yaml"
            and run["repository"]["full_name"] == repo):
        raise ValueError("Declared baseline CI did not complete successfully on this source")
    if builder_recheck:
        required = {"ubuntu-24.04 / R release", "ubuntu-24.04 / R 4.1",
                    "macos-latest / R release", "windows-latest / R release",
                    "ubuntu-24.04 / R devel", "ubuntu-24.04 / C locale"}
        if windows_recheck:
            required.remove("windows-latest / R release")
        for name in required:
            matching = [job for job in (jobs or []) if job["name"] == name]
            if len(matching) != 1 or matching[0]["status"] != "completed" or \
                    matching[0]["conclusion"] != "success":
                raise ValueError("Missing successful package job: " + name)


def verify_platform_reuse(state, changed, old, new, run, repo, jobs, linux=False):
    """Retain completed checks when only another platform's setup is repaired."""
    allowed = {".github/workflows/R-CMD-check.yaml",
               "experiments/release-candidate/state.dcf",
               "experiments/release-candidate/verify-reuse.py",
               "experiments/release-candidate/validate-reuse.py"}
    if set(changed) - allowed:
        raise ValueError("Platform reuse requires identical package and test inputs")
    if not (str(run["id"]) == state["Platform-Validation-Run"]
            and run["status"] == "completed"
            and run["head_sha"] == state["Platform-Validation-Commit"]
            and run["path"] == ".github/workflows/R-CMD-check.yaml"
            and run["repository"]["full_name"] == repo):
        raise ValueError("Platform evidence has wrong source, workflow or completion state")
    names = ("check", "tubelex-build-audit")
    if linux:
        names += ("prepare-r-devel", "check-r-devel", "c-locale")
    for name in names:
        def normalized(workflow):
            body = job_body(workflow, name).replace("ubuntu-latest", "ubuntu-24.04")
            # This exact conditional is false for every reused R-release job.
            # R 4.1 is always checked afresh; other dependency changes fail.
            if name == "check":
                body = body.replace(
                    "${{ matrix.config.r == '4.1' && 'Matrix@1.6-5 MASS@7.3-60 readxl@1.4.5 pbkrtest@0.5.2' || '' }}",
                    "${{ matrix.config.r == '4.1' && 'Matrix@1.6-5 MASS@7.3-60 readxl@1.4.5' || '' }}")
            return "\n".join(line for line in body.splitlines() if not re.match(
                r"^        (config|os):|^          - \{os:", line))
        if normalized(old) != normalized(new):
            raise ValueError("Reused platform test steps changed: " + name)
    for name, key, field in (("check", "config", "check-matrix"),
                             ("tubelex-build-audit", "os", "builder-matrix")):
        expected = "        " + key + ": ${{ fromJSON(needs.validation-scope.outputs." + field + ") }}"
        if expected not in job_body(new, name):
            raise ValueError("Platform matrix is not controlled by verified evidence")
    required = {"macos-latest / R release", "windows-latest / R release",
                "windows-latest / TUBELEX builder"}
    if linux:
        required = {"ubuntu-24.04 / R release", "ubuntu-24.04 / R devel",
                    "ubuntu-24.04 / C locale", "ubuntu-24.04 / TUBELEX builder"}
    for name in required:
        matching = [job for job in jobs if job["name"] == name]
        if len(matching) != 1 or matching[0]["status"] != "completed" or \
                matching[0]["conclusion"] != "success":
            raise ValueError("Missing successful platform job: " + name)
    return sorted(required)


def main():
    state = dict(line.split(": ", 1) for line in
                 Path("experiments/release-candidate/state.dcf").read_text().splitlines())
    ci_mode = sys.argv[1] == "ci"
    reuse = "Validation-Run" in state if ci_mode else "Source-Archive-Run" in state
    output = os.environ.get("GITHUB_OUTPUT")
    if ci_mode:
        platform_reuse = "Platform-Validation-Run" in state
        linux_reuse = "Additional-Platform-Validation-Run" in state
        builder_recheck = state.get("Recheck-TUBELEX-Builder") == "true"
        windows_recheck = state.get("Recheck-Windows") == "true"
        if "Recheck-Windows" in state and (not windows_recheck or not builder_recheck):
            raise ValueError("Windows recheck requires the bounded builder repair mode")
        if "Recheck-TUBELEX-Builder" in state and (not builder_recheck or not reuse):
            raise ValueError("Builder recheck requires a valid numerical baseline")
        if linux_reuse and not platform_reuse:
            raise ValueError("Additional platform evidence needs the primary platform record")
        if platform_reuse and reuse:
            raise ValueError("Choose full CI reuse or platform reuse, not both")
        configs = [{"os": os_name, "r": r_version} for os_name, r_version in
                   (("ubuntu-24.04", "release"), ("ubuntu-24.04", "4.1"),
                    ("macos-latest", "release"), ("windows-latest", "release"))]
        builders = ["ubuntu-24.04", "windows-latest"]
        if windows_recheck:
            configs = [{"os": "windows-latest", "r": "release"}]
        if platform_reuse:
            path = ".github/workflows/R-CMD-check.yaml"
            repo = os.environ["GITHUB_REPOSITORY"]
            for prefix in ("", "Additional-") if linux_reuse else ("",):
                commit = state.get(prefix + "Platform-Validation-Commit", "")
                run_id = state[prefix + "Platform-Validation-Run"]
                if not re.fullmatch(r"[0-9a-f]{40}", commit) or not re.fullmatch(r"[0-9]+", run_id):
                    raise ValueError("Invalid platform evidence identity")
                run = json.loads(subprocess.check_output([
                    "gh", "api", f"repos/{repo}/actions/runs/{run_id}"]))
                jobs = json.loads(subprocess.check_output([
                    "gh", "api", f"repos/{repo}/actions/runs/{run_id}/jobs?per_page=100"]))["jobs"]
                record = {"Platform-Validation-Commit": commit, "Platform-Validation-Run": run_id}
                kept = verify_platform_reuse(record,
                    git("diff", "--name-only", commit, "HEAD").splitlines(),
                    git("show", commit + ":" + path), Path(path).read_text(), run, repo, jobs,
                    linux=bool(prefix))
                print(json.dumps({"reused_platform_run": run_id, "head": commit, "jobs": kept}))
            configs = configs[:2]
            builders = builders[:1]
            if linux_reuse:
                configs = configs[1:2]
                builders = []
        if output:
            with open(output, "a") as stream:
                stream.write("check-matrix=" + json.dumps(configs) + "\n")
                stream.write("builder-matrix=" + json.dumps(builders) + "\n")
                stream.write("platform-reuse=" + str(platform_reuse).lower() + "\n")
                stream.write("linux-reuse=" + str(linux_reuse).lower() + "\n")
                stream.write("builder-recheck=" + str(builder_recheck).lower() + "\n")
                stream.write("windows-recheck=" + str(windows_recheck).lower() + "\n")
    if not reuse:
        if output:
            with open(output, "a") as stream:
                stream.write("reuse=false\n")
        return
    if ci_mode:
        commit = state.get("Validation-Commit", state.get("Source-Archive-Commit", ""))
        if not re.fullmatch(r"[0-9a-f]{40}", commit):
            raise ValueError("Invalid validation commit")
        if not re.fullmatch(r"[0-9]+", state["Validation-Run"]):
            raise ValueError("Invalid declared validation run")
        changed = git("diff", "--name-only", commit, "HEAD").splitlines()
        path = ".github/workflows/R-CMD-check.yaml"
        old = git("show", commit + ":" + path)
        new = Path(path).read_text()
        repo = os.environ["GITHUB_REPOSITORY"]
        run = json.loads(subprocess.check_output([
            "gh", "api", f"repos/{repo}/actions/runs/{state['Validation-Run']}"]))
        jobs = None
        if builder_recheck:
            jobs = json.loads(subprocess.check_output([
                "gh", "api", f"repos/{repo}/actions/runs/{state['Validation-Run']}/jobs?per_page=100"]))["jobs"]
        verify_ci(state, changed, old, new, run, repo, jobs)
        print(json.dumps({"reused_run": run["id"], "head": run["head_sha"], "changed": changed}))
    else:
        changed = verify_source(state)
        if not re.fullmatch(r"[0-9]+", state["Source-Archive-Run"]):
            raise ValueError("Invalid declared source run")
        archive = Path(sys.argv[1])
        if archive.name != f"ldfreq_{state['Version']}.tar.gz" or hashlib.sha256(
                archive.read_bytes()).hexdigest() != state["Source-Archive-SHA256"]:
            raise ValueError("Reused source archive identity mismatch")
        evidence = {key: value for key, value in state.items() if key.startswith("Source-Archive-")}
        evidence.update(candidate_commit=git("rev-parse", "HEAD"), excluded_changes=changed)
        if "Check-Evidence-Run" in state:
            if state["Check-Evidence-Run"] != state["Source-Archive-Run"]:
                raise ValueError("Check evidence must come from the declared archive run")
            repo = os.environ["GITHUB_REPOSITORY"]
            run = json.loads(subprocess.check_output([
                "gh", "api", f"repos/{repo}/actions/runs/{state['Check-Evidence-Run']}"]))
            if not (run["status"] == "completed" and
                    run["head_sha"] == state["Source-Archive-Commit"] and
                    run["path"] == ".github/workflows/release-candidate.yaml" and
                    run["repository"]["full_name"] == repo):
                raise ValueError("Completed check evidence does not match the source run")
            evidence["check_evidence_run"] = run["id"]
        if state.get("Reuse-Manual") == "true":
            prior = json.loads((archive.parent / "evidence/release-provenance.json").read_text())
            manual = archive.parent / prior["manual"]["file"]
            index = archive.parent / (manual.name + "-build/Rd2.ind")
            if not (hashlib.sha256(manual.read_bytes()).hexdigest() == prior["manual"]["sha256"]
                    and index.is_file() and index.stat().st_size > 0):
                raise ValueError("Completed indexed manual identity mismatch")
            evidence["reused_manual"] = prior["manual"]
        (archive.parent / "source-reuse.json").write_text(json.dumps(evidence, indent=2) + "\n")
    if output:
        with open(output, "a") as stream:
            stream.write("reuse=true\n")


if __name__ == "__main__":
    main()
