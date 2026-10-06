#!/usr/bin/env python3
"""Explicit, offline Hugging Face example; never invoked by ldfreq itself.

Requires separately installed torch/transformers and a cached, pinned model.
Extracts final-layer target-token means, not sentence-transformer embeddings
or sense predictions. See vignette('contextual-models', package='ldfreq').
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import re


def target_positions(offsets, special, token_ids, start, end, unknown_id):
    """Require an exact, contiguous target cover in Python codepoint offsets."""
    positions = [i for i, (a, b) in enumerate(offsets) if a < end and b > start]
    cursor = start
    for i in positions:
        a, b = offsets[i]
        if special[i] or token_ids[i] == unknown_id or a != cursor or b <= a or b > end:
            raise ValueError("Target subwords do not exactly cover the source span, or include an unknown token")
        cursor = b
    if not positions or cursor != end:
        raise ValueError("Target subwords do not exactly cover the source span")
    return positions


def read_request(path):
    request = json.loads(Path(path).read_text(encoding="utf-8"))
    if request.get("schema_version") != "0.1.0" or not isinstance(request.get("occurrences"), list):
        raise ValueError("Expected schema_version 0.1.0 and an occurrences array")
    seen = set()
    fields = ("review_id", "occurrence_id", "segment_text", "surface", "start", "end")
    rows = []
    for item in request["occurrences"]:
        row = {key: item[key] for key in fields}
        if any(not isinstance(row[key], str) or not row[key] for key in fields[:4]):
            raise ValueError("Source anchors must be non-empty strings")
        if any(type(row[key]) is not int for key in ("start", "end")):
            raise ValueError("Source positions must be integer Unicode codepoints")
        start, end = row["start"] - 1, row["end"]
        if not 0 <= start < end <= len(row["segment_text"]) or row["segment_text"][start:end] != row["surface"]:
            raise ValueError("Source surface/span mismatch; no normalization is allowed")
        if row["occurrence_id"] in seen:
            raise ValueError("Duplicate occurrence ID")
        seen.add(row["occurrence_id"])
        rows.append(row)
    return rows


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--model", required=True, help="Hugging Face repository ID, already cached locally")
    parser.add_argument("--revision", required=True, help="Exact 40-character model commit")
    args = parser.parse_args()
    if not re.fullmatch(r"[0-9a-f]{40}", args.revision):
        parser.error("--revision must be an exact lowercase 40-character commit")
    if Path(args.model).exists():
        parser.error("--model must be a repository ID, not a local directory overriding the pinned revision")
    if Path(args.output).exists():
        parser.error("--output already exists; choose a new path")
    rows = read_request(args.input)

    # Some tokenizer compatibility checks bypass local_files_only. Set these
    # before importing either library, within this explicit child process.
    os.environ["HF_HUB_OFFLINE"] = "1"
    os.environ["TRANSFORMERS_OFFLINE"] = "1"
    os.environ["HF_HUB_DISABLE_TELEMETRY"] = "1"
    import torch
    import transformers
    import tokenizers
    from transformers import AutoModel, AutoTokenizer

    options = dict(revision=args.revision, local_files_only=True, trust_remote_code=False)
    tokenizer = AutoTokenizer.from_pretrained(args.model, use_fast=True, **options)
    if not tokenizer.is_fast:
        raise ValueError("This example requires a fast tokenizer with original-text offsets")
    model = AutoModel.from_pretrained(args.model, use_safetensors=True, **options).to("cpu").eval()
    limits = [v for v in (tokenizer.model_max_length, getattr(model.config, "max_position_embeddings", None))
              if isinstance(v, int) and 0 < v < 10**9]
    if not limits:
        raise ValueError("No finite input length limit; review this model separately")
    maximum = min(limits)
    values, ids = [], []
    # ponytail: one occurrence per forward pass; batch/cached segment inference only after profiling.
    for row in rows:
        row.update(status="skipped", reason="not processed", input_tokens=None, target_subwords=None)
        try:
            encoded = tokenizer(row["segment_text"], return_offsets_mapping=True,
                                return_special_tokens_mask=True, return_tensors="pt", truncation=False)
            row["input_tokens"] = encoded["input_ids"].shape[1]
            if row["input_tokens"] > maximum:
                row["reason"] = "Full segment exceeds model/tokenizer limit; no truncation performed"
                continue
            offsets = encoded.pop("offset_mapping")[0].tolist()
            special = encoded.pop("special_tokens_mask")[0].tolist()
            positions = target_positions(offsets, special, encoded["input_ids"][0].tolist(),
                                         row["start"] - 1, row["end"], tokenizer.unk_token_id)
            row["target_subwords"] = len(positions)
            with torch.inference_mode():
                vector = model(**encoded).last_hidden_state[0, positions].mean(dim=0)
            if not bool(torch.isfinite(vector).all()):
                raise RuntimeError("Non-finite target embedding")
            values.append(vector.tolist())
            ids.append(row["occurrence_id"])
            row.update(status="processed", reason="Exact target subword cover; full segment used")
        except ValueError as error:
            row["reason"] = str(error)
        except RuntimeError as error:
            row.update(status="error", reason=str(error))
    result = dict(schema_version="0.1.0", data=rows,
                  embeddings=dict(occurrence_ids=ids, values=values), model=dict(
        model_id=args.model, model_revision=args.revision,
        tokenizer_id=args.model, tokenizer_revision=args.revision,
        software="transformers", software_version=transformers.__version__,
        torch_version=torch.__version__, tokenizers_version=tokenizers.__version__,
        python_version=platform.python_version(), device="cpu", dtype=str(next(model.parameters()).dtype),
        context_policy="full segment; no truncation",
        representation="last hidden layer; arithmetic mean of exact target subwords; no L2 normalization",
        normalization="source unchanged; model tokenizer defaults",
        input_limit=str(maximum), script_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest()))
    with open(args.output, "x", encoding="utf-8") as handle:
        json.dump(result, handle, ensure_ascii=False, allow_nan=False, indent=2)
        handle.write("\n")
    print(f"{len(ids)}/{len(rows)} occurrences have embeddings; inspect skipped/error reasons")


if __name__ == "__main__":
    main()
