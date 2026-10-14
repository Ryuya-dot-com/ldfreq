"""Export authored parity fixtures; not a supported ldfreq analyzer adapter."""
import argparse
import hashlib
import importlib.metadata
import json
import platform
from pathlib import Path

import fugashi

p = argparse.ArgumentParser()
p.add_argument("input")
p.add_argument("dictionary")
p.add_argument("configuration")
p.add_argument("output")
a = p.parse_args()
# MeCab options use whitespace as a separator in this limited experiment.
assert not any(c.isspace() for c in a.dictionary + a.configuration)
tagger = fugashi.GenericTagger(f"-r {a.configuration} -d {a.dictionary}")
assert len(tagger.dictionary_info) == 1
assert Path(tagger.dictionary_info[0]["filename"]).resolve() == (
    Path(a.dictionary) / "sys.dic"
).resolve()
segments = json.loads(Path(a.input).read_text(encoding="utf-8"))
tokens, counts = [], []
for segment in segments:
    text, cursor, local = segment["text"], 0, []
    for index, node in enumerate(tagger(text), 1):
        # Fugashi's preceding whitespace and surface lengths use Python
        # Unicode code points, independently of ldfreq's R alignment.
        cursor += len(node.white_space)
        start = cursor + 1
        cursor += len(node.surface)
        assert text[start - 1 : cursor] == node.surface
        feature = node.feature
        base = feature[10] if len(feature) > 10 else None
        if base in ("", "*", "NA"):
            base = None
        row = dict(document_id=segment["document_id"], segment_id=segment["segment_id"],
                   token_index=index, surface=node.surface, raw_feature=node.feature_raw,
                   start=start, end=cursor, POS1=feature[0], orthBase=base,
                   is_unk=node.is_unk)
        tokens.append(row)
        local.append(row)
    assert not text[cursor:] or text[cursor:].isspace()
    for unit in ("surface", "orthBase"):
        selected = [r[unit] for r in local
                    if r["POS1"] not in ("空白", "補助記号")
                    and not any(c.isspace() for c in r["surface"])
                    and r[unit] is not None]
        n, v = len(selected), len(set(selected))
        counts.append(dict(document_id=segment["document_id"], unit=unit,
                           N=n, V=v, ttr=v / n if n else None))
files = ("sys.dic", "unk.dic", "char.bin", "matrix.bin", "dicrc")
result = dict(tokens=tokens, counts=counts,
              provenance=dict(python=platform.python_version(), platform=platform.platform(),
                              fugashi=importlib.metadata.version("fugashi"),
                              dictionary_sha256={name: hashlib.sha256(
                                  (Path(a.dictionary) / name).read_bytes()).hexdigest()
                                  for name in files},
                              configuration_sha256=hashlib.sha256(
                                  Path(a.configuration).read_bytes()).hexdigest()))
Path(a.output).write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n",
                          encoding="utf-8")
