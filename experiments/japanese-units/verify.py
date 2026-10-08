"""Independent count/coverage check: python3 verify.py local-cache output-dir.

Uses Python codepoint positions and sets, not the R importer's derived offsets.
This checks input/selection/count correspondence, not MTLD validity.
"""
import csv
import json
from pathlib import Path
import sys

cache, output = map(Path, sys.argv[1:])
ref = {}
for unit, repo, base in [("SUW", "GSD", "ja_gsd"), ("LUW", "GSDLUW", "ja_gsdluw")]:
    source = cache / f"UD_Japanese-{repo}" / f"{base}-ud-test.conllu"
    for block in source.read_text(encoding="utf-8").strip().split("\n\n"):
        lines = block.splitlines()
        text = next(s[9:] for s in lines if s.startswith("# text = "))
        sid = next(s[12:] for s in lines if s.startswith("# sent_id = "))
        cursor, tokens = 0, []
        for line in lines:
            if line.startswith("#"):
                continue
            fields = line.split("\t")
            assert len(fields) == 10 and fields[0].isdigit()
            form, pos = fields[1], fields[3]
            while cursor < len(text) and text[cursor].isspace() and not text.startswith(form, cursor):
                cursor += 1
            assert text.startswith(form, cursor)
            spans = {i for i in range(cursor, cursor + len(form)) if not text[i].isspace()}
            cursor += len(form)
            tokens.append((form, pos, spans))
        assert not text[cursor:].strip()
        for policy in ["all_tokens", "exclude_PUNCT_SYM"]:
            selected = [t for t in tokens if policy == "all_tokens" or t[1] not in ("PUNCT", "SYM")]
            ref[unit, policy, sid] = (len(selected), len({t[0] for t in selected}),
                                     set().union(*(t[2] for t in selected)))
with (output / "ud-sentence-metrics.csv").open(encoding="utf-8", newline="") as f:
    rows = list(csv.DictReader(f))
assert len(rows) == 543 * 2 * 2 * 3
assert len({(r["document_id"], r["condition"], r["policy"], r["metric_id"]) for r in rows}) == len(rows)
for row in rows:
    n, v, _ = ref[row["condition"], row["policy"], row["document_id"]]
    assert int(row["N"]) == n and int(row["V"]) == v
    if row["metric_id"] == "ttr":
        assert abs(float(row["value"]) - v / n) < 1e-12
with (output / "coverage.csv").open(encoding="utf-8", newline="") as f:
    coverage = list(csv.DictReader(f))
assert len(coverage) == 543 * 2
assert len({(r["document_id"], r["policy"]) for r in coverage}) == len(coverage)
for row in coverage:
    same = ref["SUW", row["policy"], row["document_id"]][2] == ref["LUW", row["policy"], row["document_id"]][2]
    assert same == (row["same_coverage"] == "TRUE")
receipt = dict(metric_rows=len(rows), ttr_rows=sum(r["metric_id"] == "ttr" for r in rows),
               coverage_rows=len(coverage), passed=True)
print(json.dumps(receipt))
