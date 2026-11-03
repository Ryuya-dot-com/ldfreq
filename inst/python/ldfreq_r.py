"""Standard-library bridge to the installed ldfreq R package.

Requires Rscript, ldfreq and R's jsonlite package. No metrics are reimplemented.
Returned dictionaries are exactly the CLI's analysis.json representation.
The distinct module name permits coexistence with the separate ldfreq Web UI
Python package, whose aggregate export schema is different.
"""
import json
from pathlib import Path
import subprocess
import tempfile


def _entrypoint(rscript):
    result = subprocess.run(
        [rscript, "--vanilla", "-e",
         'cat(system.file("exec", "ldfreq.R", package="ldfreq", mustWork=TRUE))'],
        check=True, capture_output=True, text=True, encoding="utf-8")
    return result.stdout.strip()


def default_recipe(*, rscript="Rscript"):
    """Return the current R engine's resolved canonical recipe dictionary."""
    with tempfile.TemporaryDirectory(prefix="ldfreq-") as tmp:
        path = Path(tmp) / "recipe.json"
        subprocess.run([rscript, "--vanilla", _entrypoint(rscript), "--init", str(path)],
                       check=True, capture_output=True, text=True, encoding="utf-8")
        return json.loads(path.read_text(encoding="utf-8"))


def analyze_folder(folder, recipe, *, recursive=False, output=None, rscript="Rscript"):
    """Analyze UTF-8 .txt files using a recipe dictionary or JSON path.

    Optional output must name a new directory; existing files are not replaced.
    The record includes original texts. Without output, files are temporary.
    R failures propagate as CalledProcessError with stderr diagnostics.
    """
    with tempfile.TemporaryDirectory(prefix="ldfreq-") as tmp:
        if isinstance(recipe, dict):
            recipe_path = Path(tmp) / "recipe.json"
            recipe_path.write_text(json.dumps(recipe, ensure_ascii=False, allow_nan=False), encoding="utf-8")
        else:
            recipe_path = Path(recipe).resolve(strict=True)
        destination = Path(output).absolute() if output is not None else Path(tmp) / "results"
        args = [rscript, "--vanilla", _entrypoint(rscript), "--recipe", str(recipe_path),
                "--input", str(Path(folder).resolve(strict=True)), "--output", str(destination)]
        if recursive:
            args.append("--recursive")
        subprocess.run(args, check=True, capture_output=True, text=True, encoding="utf-8")
        return json.loads((destination / "analysis.json").read_text(encoding="utf-8"))


def analyze_text(text, recipe, *, output=None, rscript="Rscript"):
    """Analyze one Unicode string as document 'text.txt' through the R engine."""
    if not isinstance(text, str):
        raise TypeError("text must be a string")
    with tempfile.TemporaryDirectory(prefix="ldfreq-input-") as tmp:
        with open(Path(tmp) / "text.txt", "w", encoding="utf-8", newline="") as handle:
            handle.write(text)
        return analyze_folder(tmp, recipe, output=output, rscript=rscript)
