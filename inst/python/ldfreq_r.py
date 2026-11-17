"""Standard-library bridge to the installed ldfreq R package.

Requires Rscript, ldfreq and R's jsonlite package. No metrics are reimplemented.
Returned dictionaries are exactly the CLI's analysis.json representation.
The distinct module name permits coexistence with the separate ldfreq Web UI
Python package, whose aggregate export schema is different.
"""
import json
import os
from pathlib import Path
import subprocess
import tempfile

_RUNTIME_CACHE = {}


def _runtime(rscript):
    cached = _RUNTIME_CACHE.get(rscript)
    if cached is not None and Path(cached[0]).is_file():
        return cached
    expr = (
        'cat(system.file("exec", "ldfreq.R", package="ldfreq", mustWork=TRUE), '
        '"\\n", paste(.libPaths(), collapse=.Platform$path.sep), sep="")'
    )
    # Try without --vanilla first so user library paths (R_LIBS_USER) are discovered,
    # while running actual analyses under --vanilla with R_LIBS explicitly passed.
    try:
        result = subprocess.run(
            [rscript, "--no-save", "--no-restore", "--no-init-file", "-e", expr],
            check=True, capture_output=True, text=True, encoding="utf-8")
    except subprocess.CalledProcessError:
        result = subprocess.run(
            [rscript, "--vanilla", "-e", expr],
            check=True, capture_output=True, text=True, encoding="utf-8")
    lines = result.stdout.splitlines()
    entrypoint = lines[0].strip() if lines else ""
    r_libs = lines[1].strip() if len(lines) > 1 else ""
    info = (entrypoint, r_libs)
    _RUNTIME_CACHE[rscript] = info
    return info


def _run_env(r_libs):
    env = os.environ.copy()
    if r_libs and not env.get("R_LIBS"):
        env["R_LIBS"] = r_libs
    return env


def default_recipe(*, rscript="Rscript"):
    """Return the current R engine's resolved canonical recipe dictionary."""
    entrypoint, r_libs = _runtime(rscript)
    with tempfile.TemporaryDirectory(prefix="ldfreq-") as tmp:
        path = Path(tmp) / "recipe.json"
        subprocess.run([rscript, "--vanilla", entrypoint, "--init", str(path)],
                       check=True, capture_output=True, text=True, encoding="utf-8",
                       env=_run_env(r_libs))
        return json.loads(path.read_text(encoding="utf-8"))


def analyze_folder(folder, recipe, *, recursive=False, output=None, rscript="Rscript"):
    """Analyze UTF-8 .txt files using a recipe dictionary or JSON path.

    Optional output must name a new directory; existing files are not replaced.
    The record includes original texts. Without output, files are temporary.
    R failures propagate as CalledProcessError with stderr diagnostics.
    """
    entrypoint, r_libs = _runtime(rscript)
    with tempfile.TemporaryDirectory(prefix="ldfreq-") as tmp:
        if isinstance(recipe, dict):
            recipe_path = Path(tmp) / "recipe.json"
            recipe_path.write_text(json.dumps(recipe, ensure_ascii=False, allow_nan=False), encoding="utf-8")
        else:
            recipe_path = Path(recipe).resolve(strict=True)
        destination = Path(output).absolute() if output is not None else Path(tmp) / "results"
        args = [rscript, "--vanilla", entrypoint, "--recipe", str(recipe_path),
                "--input", str(Path(folder).resolve(strict=True)), "--output", str(destination)]
        if recursive:
            args.append("--recursive")
        subprocess.run(args, check=True, capture_output=True, text=True, encoding="utf-8",
                       env=_run_env(r_libs))
        return json.loads((destination / "analysis.json").read_text(encoding="utf-8"))


def analyze_text(text, recipe, *, output=None, rscript="Rscript"):
    """Analyze one Unicode string as document 'text.txt' through the R engine."""
    if not isinstance(text, str):
        raise TypeError("text must be a string")
    with tempfile.TemporaryDirectory(prefix="ldfreq-input-") as tmp:
        with open(Path(tmp) / "text.txt", "w", encoding="utf-8", newline="") as handle:
            handle.write(text)
        return analyze_folder(tmp, recipe, output=output, rscript=rscript)
