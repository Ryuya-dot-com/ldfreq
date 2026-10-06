"""Independent check of pinned CoNLL-U endpoints and saved R comparison tables.

Usage: python3 check-eslspok-counts.py test.conllu evaluation-output-dir
This audit handles this corpus's integer-ID basic trees only; it is not a reader API.
"""
import csv
import sys
from pathlib import Path


def blocks(path):
    current_doc = None
    for block in Path(path).read_text().strip().split("\n\n"):
        meta, tokens = {}, []
        for line in block.splitlines():
            if line.startswith("# "):
                key, sep, value = line[2:].partition(" = ")
                if sep:
                    meta[key] = value
            elif line:
                fields = line.split("\t")
                assert len(fields) == 10 and fields[0].isdigit()
                tokens.append(fields)
        current_doc = meta.get("newdoc id", current_doc)
        if tokens:
            yield current_doc, meta["sent_id"], meta.get("text"), tokens


def endpoints(tokens, text):
    spans, cursor = [], 0
    for index, row in enumerate(tokens, 1):
        assert int(row[0]) == index
        while cursor < len(text) and text[cursor].isspace():
            cursor += 1
        assert text[cursor:cursor + len(row[1])] == row[1]
        spans.append((cursor + 1, cursor + len(row[1])))
        cursor += len(row[1])
    assert not text[cursor:].strip()
    pairs = set()
    for row, span in zip(tokens, spans):
        head = int(row[6])
        if row[3] == "ADJ" and row[7].split(":")[0] == "amod" and head > 0:
            if tokens[head - 1][3] == "NOUN":
                pairs.add(span + spans[head - 1])
    return pairs


corpus, output = Path(sys.argv[1]), Path(sys.argv[2])
with (output / "sentences.csv").open() as stream:
    rows = list(csv.DictReader(stream))
gold = {sid: (text, tokens) for _, sid, text, tokens in blocks(corpus)}
assert len(rows) == len(gold) == 232
predicted = {}
for doc, sid, text, tokens in blocks(output / "predicted.conllu"):
    predicted.setdefault(doc, []).append(tokens)
reference_pairs, predicted_pairs = set(), set()
for row in rows:
    sid = row["document_id"]
    text, tokens = gold[sid]
    ref = endpoints(tokens, text)
    assert len(ref) == int(row["reference_pairs"])
    if row["paired"] != "TRUE":
        assert row["prediction_pairs"] == "NA"
        continue
    parser_id = "sentence_" + row["source_order"]
    assert len(predicted[parser_id]) == 1
    pred = endpoints(predicted[parser_id][0], text)
    assert len(pred) == int(row["prediction_pairs"])
    for label, values in [("tp", ref & pred), ("fn", ref - pred), ("fp", pred - ref)]:
        assert len(values) == int(row[label])
    reference_pairs.update((sid,) + p for p in ref)
    predicted_pairs.update((sid,) + p for p in pred)
expected = {"tp": reference_pairs & predicted_pairs,
            "fn": reference_pairs - predicted_pairs,
            "fp": predicted_pairs - reference_pairs}
with (output / "occurrences.csv").open() as stream:
    saved = list(csv.DictReader(stream))
for label, pairs in expected.items():
    actual = [(r["document_id"],) + tuple(int(r[k]) for k in
              ["dependent_start", "dependent_end", "head_start", "head_end"])
              for r in saved if r["outcome"] == label]
    assert len(actual) == len(set(actual)) and set(actual) == pairs
with (output / "summary.csv").open() as stream:
    summary = next(csv.DictReader(stream))
for label, pairs in expected.items():
    assert int(summary[label]) == len(pairs)
print("Independent source-span, sentence-count and occurrence audit passed:",
      {k: len(v) for k, v in expected.items()})
