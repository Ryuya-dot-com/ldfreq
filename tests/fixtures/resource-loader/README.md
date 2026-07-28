# Synthetic resource-loader fixtures

All files in this directory are project-authored synthetic data released under
CC0-1.0. The terms and counts are invented solely to exercise local resource
loading, byte hashing, version detection, schema rejection, and failure
precedence. They contain no NGSL, TUBELEX, Open English WordNet, learner-text,
or third-party lexical rows.

The validator pins exact bytes and SHA-256 values. A one-byte value change,
header change, malformed row, missing path, or incompatible manifest version is
therefore an explicit test condition rather than a source-data claim.
