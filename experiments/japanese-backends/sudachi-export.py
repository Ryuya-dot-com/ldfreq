"""Local, fixed-version Sudachi experiment; not an installed ldfreq API.

Input: UTF-8 JSON array of {document_id, segment_id, text} records.
Output: complete original surfaces, 1-based inclusive codepoint offsets,
separate dictionary features, and configuration/dictionary fingerprints.
No downloads, user dictionaries, text correction, or silent version fallback.
"""

import argparse
import hashlib
import json
from importlib.metadata import version
from pathlib import Path

import sudachidict_core
import sudachipy
from sudachipy import dictionary, tokenizer


def export(input_path, output_path, mode):
    for package, expected in [("SudachiPy", "0.6.11"),
                              ("SudachiDict-core", "20260428")]:
        if version(package) != expected:
            raise ValueError(f"This experiment requires {package}=={expected}")
    source_bytes = input_path.read_bytes()
    segments = json.loads(source_bytes.decode("utf-8"))
    if not isinstance(segments, list) or not segments:
        raise ValueError("Input must be a nonempty array of segment records")
    for row in segments:
        if not isinstance(row, dict) or any(
            not isinstance(row.get(key), str)
            for key in ("document_id", "segment_id", "text")
        ) or not row["document_id"] or not row["segment_id"]:
            raise ValueError("Each segment needs string IDs and text (which may be empty)")

    resources = Path(sudachipy.__file__).parent / "resources"
    dictionary_path = Path(sudachidict_core.__file__).parent / "resources/system.dic"
    analyzer = dictionary.Dictionary(
        config_path=str(resources / "sudachi.json"),
        resource_dir=str(resources), dict=str(dictionary_path.resolve())
    ).create()
    columns = ["document_id", "segment_id", "token_index", "surface", "start", "end",
               "dictionary_form", "normalized_form", "reading_form",
               "pos1", "pos2", "pos3", "pos4", "conjugation_type", "conjugation_form",
               "is_oov", "dictionary_id", "word_id", "analyzer_token_index"]
    tokens, zero_width_tokens = [], []
    for row in segments:
        text = row["text"]
        morphemes = analyzer.tokenize(text, getattr(tokenizer.Tokenizer.SplitMode, mode))
        cursor = anchored = zero_width = 0
        preceding_pos = None
        for index, m in enumerate(morphemes, 1):
            if m.begin() != cursor or text[m.begin():m.end()] != m.surface():
                raise ValueError("Analyzer did not preserve contiguous original surfaces")
            cursor = m.end()
            record = dict(zip(columns, [
                row["document_id"], row["segment_id"], None, m.surface(),
                m.begin() + 1, m.end(), m.dictionary_form(), m.normalized_form(),
                m.reading_form(), *m.part_of_speech(), m.is_oov(),
                m.dictionary_id(), m.word_id(), index
            ]))
            if not m.surface():
                # E.g. one original ellipsis expands to three analyzer dots.
                # Keep the raw rows as an audit, never invent character spans.
                # Lexical expansions such as ㍿ are deliberately unsupported.
                if m.part_of_speech()[0] != "補助記号" or preceding_pos != "補助記号":
                    raise ValueError("Non-symbol zero-width analyzer token: source projection unsupported")
                zero_width_tokens.append(record)
                zero_width += 1
            else:
                anchored += 1
                record["token_index"] = anchored
                tokens.append(record)
                preceding_pos = m.part_of_speech()[0]
        if cursor != len(text):
            raise ValueError("Analyzer left original characters unaccounted for")
        row["analyzer_token_count"] = len(morphemes)
        row["zero_width_token_count"] = zero_width

    provenance = dict(
        language="ja", analyzer="SudachiPy", analyzer_version=version("SudachiPy"),
        dictionary="SudachiDict-core", dictionary_version=version("SudachiDict-core"),
        unit=f"Sudachi-SplitMode-{mode}",
        normalization="original text/surface unchanged; internal default Sudachi plugins active",
        settings="bundled sudachi.json and resources; explicit core system.dic; no user dictionary",
        zero_width_policy="unanchored auxiliary-symbol expansions retained in separate audit; other zero-width tokens rejected; source token_index renumbered with analyzer_token_index preserved",
        input_json_sha256=hashlib.sha256(source_bytes).hexdigest(),
        exporter_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        feature_scope="dictionary_form is not UniDic orthBase; word_id is dictionary-scoped; OOV is not a spelling-error label"
    )
    for path in [dictionary_path, *sorted(resources.glob("*.json")),
                 *sorted(resources.glob("*.def"))]:
        with path.open("rb") as stream:
            provenance[f"{path.name}_sha256"] = hashlib.file_digest(stream, "sha256").hexdigest()
    output = dict(segments=segments, columns=columns, tokens=tokens,
                  zero_width_tokens=zero_width_tokens, provenance=provenance)
    output_path.write_text(json.dumps(output, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--mode", choices=["A", "B", "C"], required=True)
    args = parser.parse_args()
    export(args.input, args.output, args.mode)
