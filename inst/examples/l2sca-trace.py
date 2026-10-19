"""Save source texts, Penn parses and matched node IDs from a pinned L2SCA.

Explicit local execution only: Python standard library + Java + a separately
obtained original L2SCA-2023-08-15 distribution. No downloads or source imports.
See the ldfreq syntactic-complexity guide. The original software is not bundled.
"""
import argparse
import ast
import base64
import hashlib
import json
import os
from pathlib import Path
import platform
import subprocess
import tempfile

PARSER_DIR = "stanford-parser-full-2020-11-17"
HASHES = {
    "analyzeText.py": "4e9d7a130a802a540e2902d47d6c1b830f47dff09b3799480110163d1c040aef",
    "stanford-tregex-4.2.0.jar": "31c9783188f58092ff093972f39747c5a18ba6d3ce4aed288c3d9cbd8cfc59ae",
    PARSER_DIR + "/stanford-parser.jar": "af563212c61a491a9787591f8c05e722c0924196e64a57d011c20b38de83208c",
    PARSER_DIR + "/stanford-parser-4.2.0-models.jar": "e604e5582835ff810b96488c39767df9e05ae9a9cd41fe63ee3d55f8db8d9c78",
}
PATTERNS = ("s", "c", "t", "dc", "fc", "ft")

def sha256(data):
    return hashlib.sha256(data).hexdigest()


def run(args):
    try:
        result = subprocess.run(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
        try:
            stdout, stderr = (s.decode("utf-8", errors="strict").replace("\r\n", "\n").replace("\r", "\n")
                              for s in (result.stdout, result.stderr))
        except UnicodeDecodeError:
            return dict(exit_status=-2, stdout="", stdout_sha256=sha256(b""),
                stderr="Non-UTF-8 process output; original bytes retained as base64.",
                process_exit_status=result.returncode,
                stdout_base64=base64.b64encode(result.stdout).decode("ascii"),
                stderr_base64=base64.b64encode(result.stderr).decode("ascii"))
        return dict(exit_status=result.returncode, stdout=stdout, stderr=stderr,
                    stdout_sha256=sha256(stdout.encode("utf-8")))
    except OSError as error:
        return dict(exit_status=-1, stdout="", stderr=str(error), stdout_sha256=sha256(b""))


def analyze(inputs, directory, java):
    if not isinstance(inputs, list) or not inputs:
        raise ValueError("inputs must contain at least one document")
    ids = []
    for row in inputs:
        if (not isinstance(row, dict) or set(row) != {"document_id", "text"}
                or not isinstance(row["document_id"], str) or not row["document_id"].strip()
                or not isinstance(row["text"], str)
                or "\x00" in row["text"] or "\x00" in row["document_id"]):
            raise ValueError("Each input needs a nonblank document_id and non-missing text")
        row["text"].encode("utf-8", errors="strict")
        row["document_id"].encode("utf-8", errors="strict")
        ids.append(row["document_id"])
    if len(set(ids)) != len(ids):
        raise ValueError("document_id must be unique")
    for filename, expected in HASHES.items():
        if sha256((directory / filename).read_bytes()) != expected:
            raise ValueError("Unsupported or changed L2SCA file: " + filename)
    constants = {}
    # Never import analyzeText.py: importing it executes its file operations.
    for statement in ast.parse((directory / "analyzeText.py").read_text(encoding="utf-8")).body:
        if isinstance(statement, ast.Assign) and len(statement.targets) == 1:
            target = statement.targets[0]
            if isinstance(target, ast.Name) and target.id in PATTERNS:
                constants[target.id] = ast.literal_eval(statement.value)[1:-1]
    if set(constants) != set(PATTERNS):
        raise ValueError("The original query constants are incomplete")
    # Use explicit classpaths, without running an external shell script or loading
    # arbitrary additional jars from the user's directory.
    parser_jars = [directory / PARSER_DIR / name for name in
                   ("stanford-parser.jar", "stanford-parser-4.2.0-models.jar")]
    classpath = os.pathsep.join(str(p) for p in parser_jars)
    version = run([java, "-version"])
    if version["exit_status"] != 0:
        raise RuntimeError("Java could not start: " + version["stderr"])
    provenance = dict(kind="l2sca-pinned", language="en", distribution="L2SCA-2023-08-15",
        source="https://sites.psu.edu/xxl13/l2sca/", hashes=HASHES,
        python=platform.python_version(), java=version,
        exporter_sha256=sha256(Path(__file__).read_bytes()),
        parser="Stanford LexicalizedParser 4.2.0 englishPCFG",
        settings="original PCFG defaults; UTF-8; separate documents; Tregex -o -x; captured output newlines LF",
        patterns=constants)
    documents = []
    with tempfile.TemporaryDirectory(prefix="ldfreq-l2sca-") as temporary:
        temp = Path(temporary)
        for index, row in enumerate(inputs):
            source = temp / ("input-%06d.txt" % index)
            source.write_bytes(row["text"].encode("utf-8"))
            parser = run([java, "-Dfile.encoding=UTF-8", "-mx1500m", "-cp", classpath,
                "edu.stanford.nlp.parser.lexparser.LexicalizedParser", "-encoding", "UTF-8",
                "-outputFormat", "penn", "edu/stanford/nlp/models/lexparser/englishPCFG.ser.gz", str(source)])
            result = dict(row, text_sha256=sha256(row["text"].encode("utf-8")),
                          parser=parser, queries={}, status="parser_failed")
            documents.append(result)
            if parser["exit_status"] != 0:
                continue
            parsed = temp / "trees.parsed"
            parsed.write_bytes(parser["stdout"].encode("utf-8"))
            for name in PATTERNS:
                query = run([java, "-Dfile.encoding=UTF-8", "-mx100m", "-cp", str(directory / "stanford-tregex-4.2.0.jar"),
                    "edu.stanford.nlp.trees.tregex.TregexPattern", constants[name], str(parsed), "-o", "-x"])
                result["queries"][name] = query
                if query["exit_status"] != 0:
                    break
            result["status"] = "parsed" if (len(result["queries"]) == len(PATTERNS)
                and all(q["exit_status"] == 0 for q in result["queries"].values())) else "query_failed"
    return dict(format="ldfreq-l2sca-trace-1", provenance=provenance, documents=documents)


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--inputs", required=True, type=Path)
    p.add_argument("--l2sca-dir", required=True, type=Path)
    p.add_argument("--output", required=True, type=Path)
    p.add_argument("--java", default="java")
    args = p.parse_args()
    if args.output.exists():
        p.error("Output already exists; choose another filename")
    inputs = json.loads(args.inputs.read_text(encoding="utf-8"))
    result = analyze(inputs, args.l2sca_dir.resolve(strict=True), args.java)
    # Exclusive creation also prevents replacing an output created during the run.
    with args.output.open("x", encoding="utf-8") as stream:
        json.dump(result, stream, ensure_ascii=False, indent=2, allow_nan=False)
        stream.write("\n")
    print("Saved %d documents; inspect import status and logs before reporting." % len(inputs))


if __name__ == "__main__":
    main()
