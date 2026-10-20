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


def verify_ci(state, changed, old, new, run, repo):
    # Changed release controls are checked afresh; other test inputs must match.
    allowed_files = {".github/workflows/R-CMD-check.yaml",
                     ".github/workflows/release-candidate.yaml",
                     "development/RELEASE-CHECKLIST.md", "README.md"}
    allowed_controls = {"generate-release-evidence.R", "validate-public-scan.R",
                        "state.dcf", "verify-reuse.py", "validate-reuse.py",
                        "build-manual.R", "README.md", "RELEASE-CHECKLIST.md",
                        "run-as-cran-check.R", "assemble-run-index.R", "validate-note-policy.R"}
    allowed_files.update("experiments/release-candidate/" + name for name in allowed_controls)
    # These documentation repairs are exercised by the fresh exact-archive
    # matrix. Runtime code, resources, tests and numeric audit inputs still
    # have to be byte-identical to the successful baseline.
    allowed_files.update("man/" + name + ".Rd" for name in (
        "lexdiv_evaluate_contextual", "lexdiv_score_contextual", "tubelex_profile"))
    allowed_files.update("vignettes/" + name + ".Rmd" for name in (
        "auditing-vocabulary-profiles", "getting-started", "release-scope",
        "word-families-and-affixes", "designing-comparisons", "contextual-models"))
    if set(changed) - allowed_files:
        raise ValueError("Numeric CI inputs changed outside the rechecked release controls")
    for name in ("check", "prepare-r-devel", "check-r-devel", "c-locale", "tubelex-build-audit"):
        if job_body(old, name) != job_body(new, name):
            raise ValueError("Reused numeric CI definition changed: " + name)
    if not (str(run["id"]) == state["Validation-Run"]
            and run["conclusion"] == "success" and run["status"] == "completed"
            and run["head_sha"] == state.get("Validation-Commit", state.get("Source-Archive-Commit"))
            and run["path"] == ".github/workflows/R-CMD-check.yaml"
            and run["repository"]["full_name"] == repo):
        raise ValueError("Declared baseline CI did not complete successfully on this source")


def main():
    state = dict(line.split(": ", 1) for line in
                 Path("experiments/release-candidate/state.dcf").read_text().splitlines())
    ci_mode = sys.argv[1] == "ci"
    reuse = "Validation-Run" in state if ci_mode else "Source-Archive-Run" in state
    output = os.environ.get("GITHUB_OUTPUT")
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
        verify_ci(state, changed, old, new, run, repo)
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
        (archive.parent / "source-reuse.json").write_text(json.dumps(evidence, indent=2) + "\n")
    if output:
        with open(output, "a") as stream:
            stream.write("reuse=true\n")


if __name__ == "__main__":
    main()
