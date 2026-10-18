"""Check runner failure paths without Java, a model, or network access."""
import base64
import importlib.util
from pathlib import Path
import subprocess
import sys
import tempfile

path = Path(__file__).resolve().parents[1] / "inst/examples/l2sca-trace.py"
spec = importlib.util.spec_from_file_location("l2sca_trace", path)
runner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runner)
with tempfile.TemporaryDirectory() as tmp:
    tmp = Path(tmp)
    for inputs in ([], {}, [{"document_id": "", "text": "x"}],
                   [{"document_id": "a", "text": None}],
                   [{"document_id": "a", "text": "\x00"}],
                   [{"document_id": "a", "text": "x"}] * 2):
        try:
            runner.analyze(inputs, tmp, "java")
        except ValueError:
            pass
        else:
            raise AssertionError("Invalid input accepted")
    failed = runner.run([str(tmp / "absent-executable")])
    assert failed["exit_status"] == -1 and failed["stdout"] == ""
    decoded = runner.run([sys.executable, "-c", "import sys; sys.stdout.buffer.write(b'a\\r\\nb\\r')"])
    assert decoded["stdout"] == "a\nb\n" and decoded["stdout_sha256"] == runner.sha256(b"a\nb\n")
    raw = runner.run([sys.executable, "-c", "import sys; sys.stdout.buffer.write(b'\\xff')"])
    assert raw["exit_status"] == -2 and base64.b64decode(raw["stdout_base64"]) == b"\xff"
    output = tmp / "trace.json"
    output.write_bytes(b"existing evidence")
    run = subprocess.run([sys.executable, str(path), "--inputs", str(tmp / "absent"),
        "--l2sca-dir", str(tmp), "--output", str(output)], capture_output=True)
    assert run.returncode != 0 and b"Output already exists" in run.stderr
    assert output.read_bytes() == b"existing evidence"
print("PASS: rejected invalid rosters; retained process failures and invalid UTF-8; preserved existing output.")
