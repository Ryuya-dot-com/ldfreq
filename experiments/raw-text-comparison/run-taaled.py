"""python run-taaled.py upstream-ld.py inputs.json output.json fallback|pylats

Use Python 3.9, TAALED revision 27b19e1, and optionally Pylats 0.40 with
spaCy 3.8.7 / en_core_web_sm 3.8.0. Upstream code/data are not redistributed.
The collector captures the actual tokens handed to scoring by ldwrite().
"""
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import sys
import tempfile

source, inputs, output, mode = sys.argv[1:]
source = Path(source).resolve()
assert hashlib.sha256(source.read_bytes()).hexdigest() == (
    "9cebf124f3ec0a4fa1c7d8c4fd641c5c77de609c9b4bb057fe3b624bb9e6dd27")
inputs = Path(inputs).resolve()
output = Path(output).resolve()
os.chdir(source.parent)  # upstream resource lookup
spec = importlib.util.spec_from_file_location("audited_taaled", source)
ld = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ld)
cases = json.loads(inputs.read_text())
configs = {"taaled_fallback": None}
versions = {"python": sys.version, "taaled": "0.32", "source_sha256":
            hashlib.sha256(source.read_bytes()).hexdigest()}
settings = {}
if mode == "fallback":
    assert importlib.util.find_spec("pylats") is None
else:
    assert mode == "pylats"
    from pylats import lats
    import spacy
    assert lats.version == ".40" and lats.ld_params_en.nlp is not None
    class Content(lats.ld_params_en):
        # Explicit alternative: retain only NOUN, PROPN, VERB, ADJ and ADV.
        posignore = ["ADP", "AUX", "CCONJ", "DET", "INTJ", "NUM", "PART",
                     "PRON", "PUNCT", "SCONJ", "SYM", "X", "SPACE", ""]
    configs = {"taaled_pylats_surface": lats.parameters,
               "taaled_pylats_ld": lats.ld_params_en,
               "taaled_pylats_content": Content}
    versions.update(pylats="0.40", spacy=spacy.__version__,
                    model=lats.ld_params_en.nlp.meta,
                    pylats_source_sha256=hashlib.sha256(Path(lats.__file__).read_bytes()).hexdigest())
    for name, params in configs.items():
        settings[name] = {k: getattr(params, k) for k in ["model", "lemma", "lower",
            "pos", "posignore", "attested", "nonumbers", "removel", "punctuation"]}
rows = []
with tempfile.TemporaryDirectory() as temp:
    for case, text in cases.items():
        path = Path(temp) / (case + ".txt")
        path.write_text(text, encoding="utf-8")
        for pipeline, params in configs.items():
            class Collect:
                def __init__(self, tokens):
                    engine = ld.lexdiv()
                    self.vald = {"ntokens": len(tokens), "ttr": engine.TTR(tokens),
                                 "mtldo": engine.MTLD(tokens, outputs=True)[2]}
                    rows.append(dict(case=case, pipeline=pipeline, tokens=tokens,
                                     native=self.vald))
            ld.ldwrite([str(path)], outname=str(Path(temp)/"scores.tsv"),
                       loi=["ntokens", "ttr", "mtldo"], funct=Collect, params=params)
assert len(rows) == len(cases) * len(configs)
output.write_text(json.dumps(dict(versions=versions, settings=settings, results=rows,
    inputs_sha256=hashlib.sha256(inputs.read_bytes()).hexdigest()), indent=2), encoding="utf-8")
