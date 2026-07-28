# TUBELEX attribution and change notice

This package's candidate English frequency/prevalence index is derived solely
from an already published aggregate **TUBELEX** frequency table. It does not use
or distribute source subtitles.

## Source and citation

- Project: https://github.com/naist-nlp/tubelex
- Source commit: `7cb5fb36add76b83a266d1967536e1a1d3faa513`
- Source asset: `frequencies/tubelex-en-treebank.tsv.xz`
- Source SHA-256:
  `4096022259d5eaa7261c3bf22c3b0af9fd58ae8eebe17894c0b34a163954f936`
- Source license: BSD 3-Clause License
- License at the pinned commit:
  https://github.com/naist-nlp/tubelex/blob/7cb5fb36add76b83a266d1967536e1a1d3faa513/LICENSE
- Citation: Adam Nohejl et al. (2025), *Beyond Film Subtitles: Is YouTube the
  Best Approximation of Spoken Vocabulary?*, COLING 2025,
  https://aclanthology.org/2025.coling-main.641/

## Changes made for the R package candidate

The fixed upstream xz file and its decompressed bytes are SHA-256 checked before
parsing. The no-quote UTF-8 TSV is checked for its exact 19-column schema,
canonical non-negative integers, unique word keys, row/category totals, and
`channels <= videos <= count` invariants.

Source words are not normalized into new keys. A source row is retained only
when its existing word field already equals its Unicode NFKC, trimmed, lowercase
form; is at most 64 Unicode code points; and matches an optional leading ASCII
apostrophe followed by non-empty Unicode General Category `L*` components
separated by ASCII apostrophes or hyphens. This is the reviewed equivalent of the
existing project Python reference implementation's `str.isalpha()`-based lookup
predicate; it is not an upstream TUBELEX rule. The complete retained-key set
and the final canonical artifact hash are checked to detect Unicode-library drift.

All 15 `count:<category>` columns are used to validate the source but are removed
from the distributed candidate. The retained exact keys are sorted in Unicode
code-point order. The candidate preserves `count`, `videos`, and `channels` as
integers and appends the original `[TOTAL]` values. The resulting canonical CSV
has 515,292 word rows and SHA-256
`423dd4631c9da2f7442705d2930126da4cba980e46b6a5c0dda98336dce74916`.
It is then gzip-compressed without a modification timestamp. The canonical CSV
hash, rather than a toolchain-specific gzip hash, is the cross-platform identity.

No raw subtitle text, contiguous subtitle passage, subtitle filename, video ID,
channel ID, video title, source document name, or local source path is included.
No endorsement by Adam Nohejl, other TUBELEX contributors, or NAIST is implied.

## Upstream BSD 3-Clause License

BSD 3-Clause License

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
