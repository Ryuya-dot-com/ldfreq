"""Run the upstream implementation, without copying its formulas.

Usage: python3 run-taaled.py /path/to/pinned/ld.py inputs.json output.json
Requires setuptools providing pkg_resources; plotting is optional upstream.
The upstream source is separately obtained and is not redistributed here.
"""
import hashlib
import importlib.util
import json
import platform
import sys
from pathlib import Path

source, inputs, output = map(Path, sys.argv[1:])
sha256 = hashlib.sha256(source.read_bytes()).hexdigest()
assert sha256 == "9cebf124f3ec0a4fa1c7d8c4fd641c5c77de609c9b4bb057fe3b624bb9e6dd27"
spec = importlib.util.spec_from_file_location("taaled_comparator", source)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
engine = module.lexdiv()
rows = []
for case, tokens in json.loads(inputs.read_text())["cases"].items():
    mtld, mtldav, mtldo, _, _ = engine.MTLD(tokens, outputs=True)
    values = {"mtld": mtld, "mtldav": mtldav, "mtldo": mtldo,
              "ttr": engine.TTR(tokens), "maas_log10": engine.MAAS(tokens)}
    for metric, value in values.items():
        rows.append(dict(case=case, metric=metric, value=value))
output.write_text(json.dumps(dict(
    tool="TAALED", source_version=module.version, python=platform.python_version(),
    commit="27b19e1cda26e6f4d869d36afea6874f08825618", sha256=sha256,
    inputs_sha256=hashlib.sha256(inputs.read_bytes()).hexdigest(),
    parameters=dict(mn=10, ttrval=0.72), results=rows), indent=2) + "\n")
