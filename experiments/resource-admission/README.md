# Optional reference-resource inventory

The installed catalog identifies five separately downloaded snapshots. None
of their data files or data licenses are part of the code archive. The package
retains the BSD notice and license for its adapted TUBELEX tokenizer example.

`validate-tubelex-admission.R` retains its historical command name, but now
compares all five optional resource identities across the R download catalog,
installed manifest and release inventory. It checks fixed URLs, hashes, safe
member paths and the absence of implicit downloads. Resource attribution and
license texts remain in each separately distributed archive.

Run `Rscript experiments/resource-admission/validate-tubelex-admission.R .`.
Use `experiments/prepare-resources.R` only after reviewing the resource terms;
it explicitly prepares a cache for reference-dependent integration checks.
