"""Check fixed upstream snapshots and, optionally, Nation R-exported tables.

Usage: python3 experiments/check-morphology-references.py SOURCE_DIR [CSV_DIR]
CSV_DIR contains dictionary.csv, supplementary.csv and catalog.csv from the
bundled bnccoca_data() result. This independent check uses only Python stdlib.
"""
from pathlib import Path
import csv
import hashlib
import json
import sys
import zipfile
from collections import Counter, defaultdict

source = Path(sys.argv[1])
hashes = {
    "BNC_COCA_25000.zip": "ac81c7a60e5c76cd2bbf0c59b0501808f0d4fa026b2936919dd54329a9bb6a69",
    "eng.derivational.v1.tsv": "5920edacc1888b14464fc5cd96beea0a721221d56d1dc0e49de22f4c7c537c50",
    "jpn": "6ba4589cd43846c8afab5bdf5f4c498e03e32849f95c3e5c9840be2975d4b888",
}
for filename, expected in hashes.items():
    assert hashlib.sha256((source / filename).read_bytes()).hexdigest() == expected, filename

tables = {"dictionary": [], "supplementary": []}
catalog = []
with zipfile.ZipFile(source / "BNC_COCA_25000.zip") as archive:
    for number in range(1, 35):
        name = f"basewrd{number}.txt"
        content = archive.read(name)
        category = ("frequency" if number <= 25 else "placeholder" if number <= 30
                    else ["proper_names", "marginal_words", "transparent_compounds", "acronyms"][number - 31])
        rows = []
        family_id = headword = None
        for line_number, line in enumerate(content.decode("utf-8-sig").splitlines(), 1):
            if not line:
                continue
            form, flag = line.split()
            assert flag == "0"
            record_id = f"bnccoca:{number:02d}:{line_number:05d}"
            is_headword = not line.startswith("\t")
            if is_headword:
                family_id, headword = record_id, form
            assert family_id is not None
            rows.append(dict(record_id=record_id, form=form, family_id=family_id,
                             headword=headword, frequency_band=str(number) if number <= 25 else "",
                             list_type=category, source_file=name, source_line=str(line_number),
                             is_headword="TRUE" if is_headword else "FALSE", range_flag=flag))
        catalog.append(dict(source_file=name, list_type=category, rows=str(len(rows)),
                            families=str(sum(r["is_headword"] == "TRUE" for r in rows)),
                            included="FALSE" if category == "placeholder" else "TRUE",
                            sha256=hashlib.sha256(content).hexdigest()))
        if number <= 25:
            tables["dictionary"].extend(rows)
        elif number >= 31:
            tables["supplementary"].extend(rows)

if len(sys.argv) > 2:
    for name, expected in dict(tables, catalog=catalog).items():
        with (Path(sys.argv[2]) / f"{name}.csv").open(encoding="utf-8", newline="") as stream:
            actual = list(csv.DictReader(stream))
        assert len(actual) == len(expected), (name, len(actual), len(expected))
        for row_number, (observed, wanted) in enumerate(zip(actual, expected), 1):
            assert observed == wanted, (name, row_number, observed, wanted)
    print("All 105,477 bundled analysis rows and 34 catalog rows equal independent source parsing.")

with (source / "eng.derivational.v1.tsv").open(encoding="utf-8", newline="") as stream:
    morphology = list(csv.reader(stream, delimiter="\t"))
assert len(morphology) == 225131 and all(len(row) == 6 for row in morphology)
assert ["transmit", "retransmit", "V", "V", "re", "prefix"] in morphology
assert ["transmit", "transmitter", "V", "N", "er", "suffix"] in morphology
assert not any(row[:2] == ["mit", "transmit"] for row in morphology)

with (source / "jpn").open(encoding="utf-8", newline="") as stream:
    japanese = list(csv.reader(stream, delimiter="\t"))
assert len(japanese) == 12687 and all(len(row) == 3 for row in japanese)
forms = defaultdict(list)
for lemma, form, features in japanese:
    forms[form].append((lemma, features))
assert {features for _, features in forms["食べられる"]} == {
    "V;PRS;IPFV;POT", "V;PRS;IPFV;PASS", "V;PRS;IPFV;ELEV"}
assert {lemma for lemma, _ in forms["開ける"]} == {"開く", "開ける"}
print(json.dumps({
    "source_sha256": hashes,
    "nation": {name: len(rows) for name, rows in tables.items()},
    "morphynet_derivation": {"rows": len(morphology), "positions": dict(Counter(row[5] for row in morphology))},
    "junimorph": {"rows": len(japanese), "lemmas": len({row[0] for row in japanese}),
                  "forms": len(forms), "forms_with_multiple_records": sum(len(rows) > 1 for rows in forms.values()),
                  "taberareru": forms["食べられる"], "akeru": forms["開ける"]}
}, ensure_ascii=False, indent=2))
