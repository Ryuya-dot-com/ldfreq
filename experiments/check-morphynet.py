"""Independent source-to-R comparison, including the installed teaching excerpt.

Usage: python3 experiments/check-morphynet.py SOURCE_DIRECTORY PACKAGE_ROOT CSV_EXPORT
"""
from pathlib import Path
import csv
import hashlib
import sys

source, package, exported = map(Path, sys.argv[1:])
original = source / "eng.derivational.v1.tsv"
sha = hashlib.sha256(original.read_bytes()).hexdigest()
assert sha == "5920edacc1888b14464fc5cd96beea0a721221d56d1dc0e49de22f4c7c537c50"
with original.open(encoding="utf-8", newline="") as stream:
    rows = list(csv.reader(stream, delimiter="\t", quoting=csv.QUOTE_NONE))
assert len(rows) == 225131
columns = ["source_word", "target_word", "source_pos", "target_pos", "morpheme", "affix_position"]
with exported.open(encoding="utf-8", newline="") as stream:
    observed = list(csv.DictReader(stream))
assert len(observed) == len(rows)
for line, (record, fields) in enumerate(zip(observed, rows), 1):
    expected = dict(zip(columns, fields))
    expected.update(source_line=str(line), relation_id=f"morphynet:{sha[:12]}:{line:07d}")
    assert record == expected, line

folder = package / "inst/extdata/morphynet-example"
with (folder / "eng.derivational.example.tsv").open(encoding="utf-8", newline="") as stream:
    excerpt = list(csv.reader(stream, delimiter="\t", quoting=csv.QUOTE_NONE))
with (folder / "source-rows.csv").open(encoding="utf-8", newline="") as stream:
    mapping = list(csv.DictReader(stream))
assert len(excerpt) == len(mapping) == 9
for index, (fields, record) in enumerate(zip(excerpt, mapping), 1):
    assert record["example_line"] == str(index) and record["original_sha256"] == sha
    assert fields == rows[int(record["original_line"]) - 1]
targets = {"teacher", "transmitter", "unhappiness", "reusability", "retransmit", "transmission"}
assert excerpt == [row for row in rows if row[1] in targets]
print("All 225,131 source rows, six fields and generated line IDs match the R reader.")
print("All nine excerpt rows, source hashes and original line mappings match.")
print("Includes every incoming relation for the six declared example targets.")
