# Direct-source R build of the TUBELEX slim artifact

Created: 2026-07-25
Status: integrated internal development candidate; no public API or release approval

## Result

The R-only builder starts from the pinned upstream
`tubelex-en-treebank.tsv.xz`, not from a Python-derived CSV. It verifies both the
compressed and decompressed SHA-256 values before parsing, validates all 19 TSV
columns and complete totals, applies the lookup predicate, sorts exact source
keys, and emits the four-column R candidate.

Two clean runs produced identical results:

| Property | Result |
|---|---:|
| Upstream word rows | 613,309 |
| Retained lookup rows | 515,292 |
| Excluded rows | 98,017 |
| Retained token mass | 169,889,910 |
| Canonical CSV bytes | 8,260,448 |
| Canonical CSV SHA-256 | `423dd4631c9da2f7442705d2930126da4cba980e46b6a5c0dda98336dce74916` |
| gzip bytes in this toolchain | 2,549,714 |
| gzip SHA-256 in this toolchain | `ded083e5b9f59ddfb719ebd88063778500cb347e1eab0f2d79ff55085d92fb4d` |

The canonical hash is identical to the earlier four-column projection. That is
the cross-platform semantic gate. The compressed hash is only a toolchain check,
because gzip OS bytes and deflate output may differ across zlib versions.

Full evidence is in [measurement.json](measurement.json). The upstream source is
deliberately not retained in this repository. The 2.55 MB output is installed as
an internal development candidate together with its manifest, build provenance,
reviewed notice, and package copyright declaration.

## Unicode audit finding

An initial R/ICU predicate using the derived Unicode property `Alphabetic`
retained 515,511 rows—219 too many. The extra keys contained combining marks or
other characters admitted by ICU's broader property but rejected by Python
`str.isalpha()`.

The final predicate uses Unicode General Category `L*`:

```text
^'?(?:\p{L}+)(?:['-]\p{L}+)*$
```

Together with NFKC/trim/root-lower equality and the 64-code-point limit, it
matched all 515,292 reviewed retained keys with zero additions and zero omissions.
The final canonical hash remains a mandatory guard against future Unicode/ICU
version drift.

The audit can be repeated with:

```sh
Rscript --vanilla experiments/tubelex-source-build/audit-unicode-filter.R \
  /path/to/tubelex-en-treebank.tsv.xz \
  /path/to/reviewed-19-column-artifact.csv.gz
```

## Reproduction

Obtain only the fixed source at commit
`7cb5fb36add76b83a266d1967536e1a1d3faa513`, then use fresh output paths:

```sh
Rscript --vanilla experiments/tubelex-source-build/build-tubelex-from-source.R \
  /path/to/tubelex-en-treebank.tsv.xz \
  /private/tmp/tubelex-slim.csv.gz \
  /private/tmp/tubelex-slim-manifest.json
```

The builder performs no network access and refuses to overwrite outputs. It
requires R packages `digest`, `jsonlite`, and `stringi`.

To build artifact, manifest, and the reviewed BSD notice as a single fresh
release unit, use a destination directory that does not exist:

```sh
Rscript --vanilla experiments/tubelex-source-build/promote-tubelex-release.R \
  /path/to/tubelex-en-treebank.tsv.xz \
  /private/tmp/tubelex-release-unit
```

The wrapper builds in a sibling staging directory, verifies all three regular
files, sets file mode `0644`, and renames the directory as one unit. An atomic
sibling lock excludes concurrent compliant wrappers, and pre-existing targets
or symlinks are refused. Base R does not provide a portable atomic
rename-no-replace primitive, so this is not a guarantee against a noncooperating
process creating the target in the final check-to-rename interval. Two clean
runs produced byte-identical artifact, NOTICE, and manifest; a concurrent run
gave one success and one lock refusal. A forced builder failure left no target,
lock, or staging directory. The measured identities are in `measurement.json`. The
distribution manifest also pins the reviewed 19-column reference identity and
states that it was used only for an external set-equivalence audit, not as a
build input. It rehashes NOTICE after copying, validates provenance/license
fields fail-closed, records builder/wrapper hashes, and avoids replacing an
existing staged manifest for Windows portability.

## Package integration and remaining release gates

The numerical/data transformation gate and the full release-unit validator have
passed locally on macOS. The package workflow repeats the builder, cooperative
lock, cleanup, and identity checks on Ubuntu and Windows, while ordinary package
checks exercise the installed resource and its machine-readable inventory.

Release approval still requires:

1. an independent legal/provenance approval of this exact candidate;
2. platform binary-package membership and byte-identity audits; and
3. a final release-candidate build and check after all approved resources are
   frozen.

The artifact contains published aggregate frequencies only. It contains no raw
subtitle text, contiguous passages, video IDs, channel IDs, document names, or
local source paths.
