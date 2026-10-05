"""Offline checks for the installed example's original-codepoint contract."""
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.dont_write_bytecode = True
script = (Path(sys.argv.pop(1)) if len(sys.argv) > 1 else
          Path(__file__).resolve().parents[1] / "inst/examples/contextual-embeddings.py")
spec = importlib.util.spec_from_file_location("contextual_example", script)
example = importlib.util.module_from_spec(spec)
spec.loader.exec_module(example)


class SourceSpans(unittest.TestCase):
    def test_exact_subwords_and_repeated_words(self):
        offsets = [(0, 0), (0, 4), (5, 7), (7, 9), (0, 0)]
        mask, ids = [1, 0, 0, 0, 1], [101, 1, 2, 3, 102]
        self.assertEqual(example.target_positions(offsets, mask, ids, 0, 4, 100), [1])
        self.assertEqual(example.target_positions(offsets, mask, ids, 5, 9, 100), [2, 3])

    def test_crossing_gaps_overlaps_unknowns_and_empty_targets_fail(self):
        for offsets, special, ids, start, end in [
            ([(0, 4)], [0], [1], 1, 4),
            ([(0, 2), (3, 4)], [0, 0], [1, 2], 0, 4),
            ([(0, 3), (2, 4)], [0, 0], [1, 2], 0, 4),
            ([(0, 4)], [0], [100], 0, 4),
            ([(0, 4)], [1], [1], 0, 4),
            ([(0, 4)], [0], [1], 5, 9),
        ]:
            with self.subTest(offsets=offsets, start=start), self.assertRaises(ValueError):
                example.target_positions(offsets, special, ids, start, end, 100)

    def test_json_uses_codepoints_not_bytes_or_utf16(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "request.json"
            row = dict(review_id="r", occurrence_id="o", segment_text="😀e\u0301人気",
                       surface="人気", start=4, end=5)
            def write(rows):
                path.write_text(json.dumps(dict(schema_version="0.1.0", occurrences=rows)), encoding="utf-8")
            write([row])
            self.assertEqual(example.read_request(path), [row])
            for bad in [dict(row, start=5), dict(row, start=True), dict(row, surface="人")]:
                write([bad])
                with self.assertRaises(ValueError):
                    example.read_request(path)
            write([row, row])
            with self.assertRaises(ValueError):
                example.read_request(path)
            write([])
            self.assertEqual(example.read_request(path), [])


if __name__ == "__main__":
    unittest.main()
