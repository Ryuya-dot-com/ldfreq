#!/usr/bin/env python3
"""Optional external English token preparation for ldfreq's TUBELEX profiles.

The apostrophe, numeric-token, and word-filter rules below are adapted from
TUBELEX lang_utils.py at 7cb5fb36add76b83a266d1967536e1a1d3faa513:
https://github.com/naist-nlp/tubelex/blob/7cb5fb36add76b83a266d1967536e1a1d3faa513/lang_utils.py

Copyright (c) 2022-4, Adam Nohejl
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
"""
import hashlib
import json
from pathlib import Path
import platform
import re
import sys
from typing import Iterable, Iterator
import unicodedata

import nltk

RE_DIGIT_RANGES         = r'\d⁰¹²³⁴⁵⁶⁷⁸⁹₀-₉①-⑳⓪⓵-⓽⓿❶-❾⑴-⒇⒈-⒛🄀'

RE_NUM_TOKEN            = rf'[{RE_DIGIT_RANGES}]+'

RE_RELAXED_W_TOKEN      = r'[^\d]*(?!\d)[\w{EXTRA_CHARS}][^\d]*'

PAT_NUM_TOKEN       = re.compile(RE_NUM_TOKEN)

num_split           = PAT_NUM_TOKEN.split

PAT_RELAXED_W_TOKEN = re.compile(RE_RELAXED_W_TOKEN)

match_relaxed_word  = PAT_RELAXED_W_TOKEN.fullmatch

NUM_TOKEN = '<num>'

def iter_tokenized_replace_num(ts: Iterable[str]) -> Iterator[str]:
    # Boundaries between items of ts are created by tokenization
    in_num = False
    for t in ts:
        tns = num_split(t)
        # Boundaries between items of tns (some if which may be empty) correspond to
        # numbers. We coalesce adjacent numbers together.
        if len(tns) <= 1:
            in_num = False
            yield t
            continue
        itns = iter(tns)
        for tn in itns:
            if tn:
                yield tn
                in_num = False
            else:
                if not in_num:
                    yield NUM_TOKEN
                    in_num = True
            break
        for tn in itns:
            if not in_num:
                yield NUM_TOKEN
            if tn:
                yield tn
                in_num = False
            else:
                in_num = True

RSQUOTE2APOS: dict[int, int] = {ord('’'): ord('\'')}

RE_SMART_APOS     = re.compile(
    # Preserve -- has group(1)
    r'‘(([^‘’]*\b’\b)*[^‘’]*)’(?!s)|'   # paired single quotes, see `in_quotes` below
    # Replace by apostrophe:
    r'’|'                               # right single quote except pairs like above
    r'(?<=[A-Za-z]{2})′|'               # prime following at least two alphabet letters
    r'′(?=s)'                           # prime before 's'
    )

sub_smart_apos   = RE_SMART_APOS.sub

def repl_smart_apos(m: re.Match) -> str:
    '''
    Translates "smart" apostrophe (right single quote ’ or prime ′) to apostrophe '.
    Keeps legit "‘...’" or "a′" as is.

    Basic quotes/apostrophies:

    >>> sub_smart_apos(repl_smart_apos, 'It’s me. It’s ‘you and me’.')
    "It's me. It's ‘you and me’."

    Trickier case (resolved using r'(?!s)'):

    >>> sub_smart_apos(repl_smart_apos, '‘It’s A’ ‘and’ it’s B.')
    "‘It's A’ ‘and’ it's B."

    Imperfect matching:

    >>> sub_smart_apos(repl_smart_apos,
    ...     'This isn‘t an apostrophe. ‘It’s an apostrophe.’ ‘This isn’t an apostrophe.'
    ...     )
    "This isn‘t an apostrophe. ‘It's an apostrophe.’ ‘This isn’t an apostrophe."

    Primes:

    >>> sub_smart_apos(repl_smart_apos, 'It′s an a′, it can′t be b′. Countries′ names.')
    "It's an a′, it can't be b′. Countries' names."
    '''

    in_quotes = m.group(1)  # inside paired single quotes
    return (
        # Keep outer quotes, replace inner right single quotes using translate():
        f'‘{in_quotes.translate(RSQUOTE2APOS)}’' if in_quotes is not None
        # Replace other right single quotes or primes found by regex:
        else '\''
        )


def prepare(text):
    """Pinned-source English tokenization/filtering, before subtitle cleaning."""
    text = sub_smart_apos(repl_smart_apos, text)
    tokens = iter_tokenized_replace_num(nltk.word_tokenize(text, language="english"))
    return [unicodedata.normalize("NFKC", token).lower()
            for token in tokens if match_relaxed_word(token)]


def unique_document_ids(pairs):
    documents = {}
    for doc_id, text in pairs:
        if doc_id in documents:
            raise ValueError("Document IDs must be unique.")
        documents[doc_id] = text
    return documents


def main():
    if len(sys.argv) != 3:
        raise SystemExit("Usage: tubelex-tokenize.py input-texts.json output-tokens.json")
    source, destination = map(Path, sys.argv[1:])
    if source.resolve() == destination.resolve() or destination.exists():
        raise SystemExit("Choose a new output path; existing files are not overwritten.")
    raw = source.read_bytes()
    documents = json.loads(raw.decode("utf-8-sig"), object_pairs_hook=unique_document_ids)
    if not isinstance(documents, dict) or any(
        not isinstance(k, str) or not k or not isinstance(v, str)
        for k, v in documents.items()
    ):
        raise SystemExit("Input must be a JSON object mapping document IDs to text strings.")
    try:
        model = Path(str(nltk.data.find("tokenizers/punkt_tab/english/")))
        if not model.is_dir():
            raise LookupError("Use an unpacked English punkt_tab model.")
        model_hashes = {p.name: hashlib.sha256(p.read_bytes()).hexdigest()
                        for p in sorted(model.iterdir()) if p.is_file()}
        prepared = {doc_id: prepare(text) for doc_id, text in documents.items()}
    except LookupError as error:
        raise SystemExit("Install NLTK's English punkt_tab model before running this "
                         "offline recipe (python3 -m nltk.downloader punkt_tab).") from error
    output = {
        "documents": prepared,
        "preprocessing": {
            "recipe_id": "ldfreq-tubelex-input-v1",
            "tubelex_source_commit": "7cb5fb36add76b83a266d1967536e1a1d3faa513",
            "tokenizer": "nltk.word_tokenize(language=english)",
            "nltk_version": nltk.__version__,
            "python_version": platform.python_version(),
            "unicode_version": unicodedata.unidata_version,
            "punkt_english_files_sha256": model_hashes,
            "source_texts_sha256": hashlib.sha256(raw).hexdigest(),
            "script_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
            "transform": "source smart-apostrophe; Treebank/Punkt; source number and word filters; NFKC/lower",
            "scope": "English token preparation; excludes subtitle collection, cleaning and deduplication"
        }
    }
    with destination.open("x", encoding="utf-8", newline="\n") as handle:
        json.dump(output, handle, ensure_ascii=False, indent=2)
        handle.write("\n")


if __name__ == "__main__":
    main()
