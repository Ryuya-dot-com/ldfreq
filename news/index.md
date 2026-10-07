# Changelog

## ldfreq 0.2.0 (development)

### Reviewing annotation decisions

- Added an executable KWIC worksheet tutorial: separate
  context/candidate tables, UTF-8 CSV editing, fixed-ID checks,
  partial-row rejection, reapplication and complete RDS saving. Document
  counts retain unsubmitted and unresolved cases, documents without
  targets and empty documents. It uses existing APIs.

### Reading your own text files

- Expanded the English input guide with executable single-file, folder
  and CSV routes, explicit document/metadata IDs, empty-document
  handling, plotting and complete RDS saving. Small authored texts are
  supplied as teaching files.
- Added an explicitly sourced UTF-8/CP932 file-reading example retaining
  original line endings and source hashes, recording a removed UTF-8 BOM
  and rejecting failed or lossy decoding. It adds no exported API or
  dependency.

### Linking family and morphology decisions

- Added an explicitly sourced workflow connecting existing family
  occurrences to MorphoLex segmentations and MorphyNet formation
  candidates. One selected corpus token retains one output row; lookup
  coverage, candidate alternatives, contextual decisions and
  part/relation counts remain separate. Excluded or unresolved
  occurrences cannot silently enter complete totals.
- Added an executable teaching example and save/replay instructions. The
  local ICNALE GRA V2.1 check reuses saved tokens and family
  assignments; corpus text and individual outputs are not bundled.
  Public exports and required dependencies are unchanged.

### Japanese morphology spans

- Added explicit local J-UniMorph-format reading and multi-token span
  review examples. Original rows, feature bundles, file identity and
  source positions survive KWIC decisions and saving. Exact matches with
  incompatible token boundaries, overlapping spans, multiple candidates
  and unresolved decisions remain explicit. Span review does not merge
  tokens or change word counts.
- Added an executable authored example and a local-resource recipe to
  the Japanese guide. No J-UniMorph table, learner text, new export or
  required dependency is bundled. Real-input matching is distinguished
  from accuracy.

### Japanese corpus input

- Added an explicitly sourced reader for locally acquired NINJAL Essay
  Database text ZIPs and metadata tables. Explicit UTF-8/CP932 decoding,
  byte round-trip checks, BOM records, original line endings and
  metadata IDs are retained; missing writer records remain visible. No
  corpus data is bundled.
- Fixed external-annotation alignment when an analyzer emits CR tokens
  but omits intervening LF characters. Whitespace-prefixed tokens now
  use the first exact match across whitespace-only gaps. Omitted
  non-whitespace characters, changed surfaces and incorrect supplied
  positions still cause an error.

### Japanese spelling and contextual lexical identity

- Extended the spelling example with separate boundary and lexical
  reviews: complete alternative annotations retain the same kana source,
  alignment links the changed span, and KWIC review is regenerated for
  the reviewed segmentation. Full-sequence counts include the changed
  tokens; previous review IDs cannot be silently reused after
  resegmentation.
- Added an optional, offline example retaining hiragana, katakana and
  kanji surfaces while reviewing lexical identity at individual KWIC
  occurrences. Authored spelling variants share an explicitly selected
  ID; homophones can receive different IDs or remain unresolved. Full
  and common-set counts keep their denominators visible, including
  missing candidates and empty documents.
- Expanded the Japanese annotation guide to distinguish orthographic
  production, lexical identity and evidence of kanji knowledge. No
  automatic kana-to-kanji converter, new exported API or corpus data is
  added.

### Comparing word-counting units

- Added an explicitly sourced recipe comparing surface, supplied lemma
  and family types/TTR on a shared set of occurrence IDs.
  Whole-selection coverage, unresolved assignments and unavailable
  totals remain visible alongside the conditional comparison. Source IDs
  and complete profiles survive RDS saving.
- Extended the Nation example and preprocessing guide with
  hand-countable examples, including an unlisted word that changes the
  comparison denominator. No new exported API, analyzer or identity
  fallback is introduced.

### Resource inventory

- The installed inventory now includes MorphoLex, Nation BNC/COCA and
  the MorphyNet excerpt alongside NJ8 and TUBELEX, with data scope,
  source identity and component-specific license files. The excerpt is
  marked as example-only.
- Distribution checks now compare all declared data and license files
  across source, platform packages and installations. Release records
  retain the package’s component-specific terms rather than declaring
  the collection MIT.

### MorphyNet formation relations and contextual review

- Added
  [`morphynet_read_derivations()`](https://ryuya-dot-com.github.io/ldfreq/reference/morphynet_read_derivations.md)
  for local six-column TSV files, with explicit language/version, source
  hash and line IDs. Original POS, spelling, alternatives and multiword
  fields are retained; no POS mapping, lemmatization or
  family/segmentation inference is performed.
- Added nine attributed CC BY-SA 3.0 example relations, an original-row
  map, and an optional quanteda KWIC workflow using
  [`lexdiv_ambiguity_review()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ambiguity_review.md).
  Selection and withholding apply to individual occurrences; other
  relations remain visible. These decisions do not assert a unique true
  derivation.
- The full English v1 file is supported as local input; it is not
  bundled. The excerpt is for teaching and must not be used as a
  coverage inventory.

### Nation’s BNC/COCA word families

- Added
  [`bnccoca_data()`](https://ryuya-dot-com.github.io/ldfreq/reference/bnccoca_data.md)
  with the complete 25-band Level 6 inventory (25,000 families; 75,679
  headword/member rows), source IDs, frequency bands, hashes, citation
  and CC BY-SA 4.0 terms. The 29,798 supplementary rows are separate;
  placeholder slots and Range software are excluded.
- An offline example connects the actual lists to
  [`lexdiv_family_profile()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_family_profile.md).
  It retains unmatched forms, original occurrences and saved-result
  replay. `use`/`uses` and `colour`/`color` share source families;
  `reusability` is unlisted in this snapshot. No membership is inferred
  from spelling.
- Documented the distinction between educational families, MorphyNet
  derivational relations and Japanese J-UniMorph inflectional features.
  The subsequent MorphyNet reader is described above; J-UniMorph remains
  a researched candidate. Neither adds a contextual analyzer.

### Bundled MorphoLex English reference data

- Added
  [`morpholex_data()`](https://ryuya-dot-com.github.io/ldfreq/reference/morpholex_data.md)
  for all 34 worksheets, including 68,624 word records and the
  prefix/suffix/root aggregates. Character-valued source tables retain
  IDs, missingness, case, order and whitespace. Source identity,
  conversion details, and the original data dictionary accompany the
  data.
- MorphoLex is redistributed under **CC BY-NC-SA 4.0**, including its
  noncommercial and applicable ShareAlike conditions. The independent R
  code remains MIT licensed. `DESCRIPTION` now refers to a
  component-specific `LICENSE` and declares the bundled distribution’s
  use restrictions.
- The word-parts recipe reads bundled tables by default, without
  `readxl` or network access. An explicit workbook path still uses
  optional `readxl`. Data inclusion does not turn the recipe into a
  validated morphology analyzer.

### Source-linked roots and affixes examples

- Added explicitly sourced recipes for caller-provided morphological
  analyses: separate root/prefix/suffix roles, inflection/derivation,
  boundness and part IDs; source KWIC, alternative candidates, partial
  analyses and denominators remain visible. Complete counts require
  complete selected occurrences; observed part counts are available
  separately. Saved inputs support RDS replay.
- Added a MorphoLex reader with explicit sheet/word selection, retained
  source rows, declared derivational scope and unsupported-entry
  handling. Local workbooks use existing suggested `readxl`; bundled
  data are read in base R. The guide distinguishes declared parts from
  derivation trees, learner knowledge and morphological productivity.

### Source-linked word-family profiles

- Family profiles now prepare the existing ambiguity-review interface
  and accept its complete result via `review`. Record selections and
  explicit unresolved judgments apply per occurrence; lookup results,
  reviewer/reason and full review remain available. Source, inventory
  and policy mismatches stop reuse, and candidate membership is checked
  against each occurrence’s POS/unit. Added an optional
  contextual-review example with CSV/RDS guidance.
- Added experimental
  [`lexdiv_family_profile()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_family_profile.md)
  for caller-supplied form-to-family tables and explicit resource
  definitions. It preserves source occurrences, family-member counts,
  candidate records, KWIC and empty documents. Surface, supplied lemma
  and supplied flemma keys remain distinct from assigned families.
- Unlisted forms, ambiguous families, missing lexical/POS annotations
  and exclusions remain explicit. Complete family totals and TTR are
  unavailable when selected occurrences remain unresolved. Multiple
  records assigning the same family do not inflate ambiguity or token
  counts.
- Added an authored offline example comparing surface, lemma, flemma and
  family TTR/MATTR on the same occurrences. This example adds no model,
  automatic affix analysis, new dependency or learner-knowledge
  inference.

### Spelling varieties and lexical counting policies

- Added an explicitly sourced example comparing declared spelling
  equivalence, exact/alias NJ8 lookup and supplied POS selections for
  names, numerals and symbols. Full annotations retain source positions,
  unresolved POS and empty documents; n-gram extraction preserves gaps
  left by excluded tokens.
- Expanded the English guide and number-argument help: content-word
  selection includes PROPN, numeric pattern flags are not semantic NUM
  tags, and the lexical tokenizer does not preserve specialist forms
  such as C++ or all punctuation/symbol boundaries. The example shows
  the existing complete-input import route. No tokenizer defaults,
  resource bytes, runtime algorithms, exported functions or mandatory
  dependencies changed.

### Reviewed learner-text versions

- Added explicitly sourced, offline examples that apply approved text
  edits under a declared policy while retaining original documents,
  writer/task metadata, rejected/unresolved proposals, source context
  and text hashes. Source-checked code-point spans support insertion,
  deletion and word-boundary changes; overlapping applied edits stop for
  review.
- Extended the vocabulary-audit guide with research-based distinctions
  between learner errors, annotation errors and off-list words. The
  example reruns existing surface TTR/MATTR and NJ8 profiles for
  original, spelling-reviewed and broader-reviewed text, preserving
  denominators and missing results. No automatic correction, new export,
  dependency or corpus is added; existing annotation comparisons
  continue to require the same source text.

### Optional UDPipe dependency workflow

- The sentence-input guide now explicitly preserves caller-supplied
  sentence boundaries with UDPipe’s presegmented tokenizer; embedded
  line breaks must be resolved explicitly. Saved multi-sentence outputs
  remain unsupported.
- Added an explicitly sourced recipe for complete saved UDPipe outputs
  from caller-supplied sentences, preserving original text, empty
  inputs, source IDs, model identity and parser errors. Unsupported
  sentence splits, multiword rows, empty nodes and enhanced edges stop
  for review rather than being discarded.
- Extended the dependency guide from actual English parsing to
  source-endpoint comparisons, overlaid count distributions and replay
  without model inference. The authored example is not an independent
  parser-accuracy study. UDPipe is an optional suggestion; no model,
  corpus or new exported function is bundled.
- Removed a remaining in-figure missing-data title from the Japanese
  stimulus guide; the missingness explanation is now reported outside
  the image.
- Replaced difference-axis figures with original-value and overlaid
  frequency displays. The annotation guide adds an optional ggplot2
  density-overlay recipe using a common bandwidth, TTR boundary
  correction and solid/dashed lines in both color modes. Difference
  tables remain available for auditing.

### Source-linked adjective–noun dependencies

- Added experimental
  [`lexdiv_amod_pairs()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_amod_pairs.md)
  for supplied basic UD trees, selecting ADJ dependents with amod
  relations to NOUN heads. Non-adjacent pairs retain both source
  endpoints, direction, original KWIC and document identity.
- Tree checks reject invalid heads, self-links, cycles and root
  contradictions. Sentences with missing head/relation/UPOS remain
  explicit; their document totals are unavailable instead of zero.
  Surface/lemma type counts separately report missing lexical values and
  retain complete input provenance.
- Added an offline English/Japanese example, endpoint comparison and a
  guide showing why equal counts can conceal different pairs. No parser,
  corpus, model, required dependency, MI score or general accuracy claim
  was added.

### Color and monochrome plots

- All eleven [`plot()`](https://rdrr.io/r/graphics/plot.default.html)
  methods default to color and accept the named argument
  `monochrome = TRUE`. Both color modes use triangles in metric/screen
  plots below advisory thresholds and circles otherwise unless `pch` is
  supplied; MATTR retains its dashed mean line, and NJ8 retains its
  separate off-list bar.
- Removed automatic plot titles. Metric IDs now label the metric y-axis;
  figure titles and notes belong outside the image. Existing explicit
  color settings remain available in color mode; monochrome overrides
  series colors. Computable plots retain their rows, denominators,
  selection rules and invisible returns.
- Refined publication defaults with a sans serif font, horizontal tick
  labels, open frames and a consistent Okabe–Ito blue/orange palette.
  Cosmetic graphics settings are restored, including on errors; explicit
  overrides remain available.
- NJ8 proportion plots share 0–1 ticks across documents; legends use
  reserved space. All eight levels and Off-list are labelled, with
  Off-list wrapped at narrow widths. Undefined proportions now stop
  instead of appearing as zero.
- Added publication-size PDF/PNG export instructions and document-level
  original-value displays. Sources and limits of descriptive versus
  inferential graphics are explained in the report guide. No inferential
  model was added.

### Source alignment across token segmentations

- Added experimental
  [`lexdiv_align_annotations()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_align_annotations.md)
  for complete imports of the same original segments with different
  token boundaries. Source-interval groups retain split/merge/complex
  relations, both token IDs and original KWIC.
- Exact token-span coverage and internal-junction agreement have
  separate denominators. Optional label evaluation is conditional on
  exact span pairs; unmatched tokens and missing labels remain visible.
  Existing same-segmentation evaluation retains its strict contract and
  results.
- Added an offline English/Japanese example and guide connecting
  whole-input token/type counts, TTR and fixed-window MATTR to
  saved-input replay. No corpus, model or required dependency was added.
  These examples do not establish analyzer accuracy or psychological
  validity.

### Reference-based annotation evaluation

- Added experimental
  [`lexdiv_evaluate_annotations()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_evaluate_annotations.md)
  for complete external annotations with identical source segmentation
  and an explicit reference. It returns per-label TP/FP/FN,
  precision/recall/F1, document coverage, sparse confusion counts and
  every occurrence with original-text character context.
- Unavailable references are not scored as negatives; missing
  predictions on available references count as false negatives. Empty
  documents and original review/failure metadata survive. Reference
  independence remains a declaration.
- A new guide and offline English/Japanese example connect changed noun
  selections to document TTR, retaining incomplete and empty documents.
  Equal noun counts can hide different selected words. No analyzer,
  model, corpus or new dependency is added; different segmentations and
  dependency-head accuracy are outside this evaluator’s contract.

### Annotation sensitivity example

- Added explicitly sourced offline scripts linking changes in supplied
  lemmas and UPOS to source-text context, TTR/MATTR and NJ8 coverage.
  Paired differences retain non-computable results; selection and
  reference denominators remain separate, including missing annotations
  and empty documents.
- The vocabulary-audit guide explains original-text checks, position
  mapping, fixed analysis conditions and saved-input replay. Authored
  examples show why changed labels need not change scores and unchanged
  counts can hide different exclusions. No new export, dependency,
  corpus or annotation-accuracy claim is introduced.

### Source-aligned phrase-list example

- Added an explicitly sourced helper and an offline English/Japanese
  example linking caller-supplied phrase components to quanteda search,
  original-text KWIC, per-ID counts and union token coverage. Long,
  nested and overlapping expressions retain source positions; exclusions
  remain gaps.
- The annotated-corpora guide explains segmentation, exact surface
  matching, case/Unicode policy, punctuation, empty documents,
  denominators, RDS replay and separate human interpretation. No new
  export, dependency or external phrase inventory is added.

### Reusable contextual study example

- Added three installed R scripts connecting authored source/annotation
  inputs, document/group split checks, development evaluation, frozen
  settings and training inputs, test scoring before reference access,
  and read-only replay.
- The contextual-model guide explains replacing the illustration with
  real annotations and model outputs. Reports retain each method’s
  coverage, common-occurrence comparisons, unresolved references and
  individual judgments. The example does not establish independent
  labels or empirical accuracy; no new exported API, inference, corpus,
  model or dependency is added.

### Supervised contextual baselines

- Added experimental
  [`lexdiv_score_contextual()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_score_contextual.md)
  with centroid-cosine and training-frequency scores, using selected
  training references without reading query labels or prior suggestions.
  Both outputs feed contextual evaluation.
- Checks disjoint document IDs, identical target-context copies,
  candidate/ resource snapshots and embedding declarations/dimensions.
  These checks do not establish a leak-free study or independent human
  labels.
- Retains per-candidate training counts, normalized prototypes,
  zero/missing vectors, canceling centroids, original model reasons and
  complete inputs. Unseen candidates remain missing for cosine and
  zero-count for an observed surface’s frequency baseline. Unseen
  surfaces receive no scores. No fallback, smoothing, tie breaking,
  inference or new dependency is implicit.
- The English/Japanese guide connects authored training examples,
  separate query references, coverage-aware baseline comparison, KWIC
  inspection and RDS replay.

### Comparing model suggestions with reference judgments

- Added experimental
  [`lexdiv_evaluate_contextual()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_evaluate_contextual.md)
  with explicit score direction and absolute tie tolerance. Predictions
  require scores for the complete supplied inventory and one best
  candidate; missing rivals and ties abstain.
- Overall/per-term summaries report matching predictions, conditional
  agreement, reference/prediction/pair coverage, singleton predictions
  and unscored reference candidates. Term-specific confusion counts and
  a KWIC review queue retain unavailable comparisons. Human judgments
  are not overwritten.
- Reference protocol, model exposure and evaluation role are recorded as
  caller declarations. The guide distinguishes reference agreement from
  validated WSD accuracy and illustrates high conditional agreement with
  low coverage. No model inference, new dependency, external data or
  tuning procedure is added.

### External contextual model outputs

- Added experimental
  [`lexdiv_import_contextual()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_import_contextual.md)
  to check occurrence IDs, source text/spans and review identity before
  attaching external embeddings or candidate scores. Human decisions
  remain separate; skipped, failed and absent output stays in the
  coverage denominator. Scores are not converted to probabilities or
  automatic selections.
- Added an offline English/Japanese guide and an explicitly invoked
  Python example using separately cached, commit-pinned Hugging Face
  models. It checks exact target subword coverage and skips overlong
  contexts without truncation. R does not invoke inference, install
  software or download models. No model weights, corpus data or new R
  dependency is included.

### Reviewed Japanese polysemy estimates

- Added explicitly sourced `read_wlsp_polysemy()` and
  `review_wlsp_polysemy_items()` examples for the separately obtained,
  pinned WLSP-norms v1.0 file. Exact WIDs, decorated words,
  classifications, signed estimates, mapping reasons and unselected
  items remain visible.
- Added a guide joining reviewed items and KWIC occurrences to these
  values, reusing the existing norm-profile and ambiguity APIs.
  Full-item coverage is separate from the selected-record profile.
  Values are not rescaled into raw ratings, sense counts or
  sense-specific frequencies. No new exported API, dependency or
  external rating data is added.

### Contextual ambiguity review

- Added
  [`lexdiv_compare_ambiguity()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_compare_ambiguity.md)
  to pair two intact reviews by occurrence ID, retain both decisions and
  KWIC contexts, and return disagreements and other open cases for
  review. Conditional agreement, its numerator/denominator,
  joint-selection coverage and status pairs are explicit.
  Missing/unresolved choices never count as semantic agreements; no
  kappa or automatic adjudication is computed. Review results now
  include a whole-result fingerprint.
- Extended the separately sourced WLSP example with
  `wlsp_ambiguity_candidates()` to connect the verified local v4.0 file
  to KWIC candidates. Record IDs, readings, classifications, coverage
  and source terms survive. Record counts are not treated as validated
  counts of distinct senses; no data are bundled.
- Added experimental
  [`lexdiv_ambiguity_review()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ambiguity_review.md)
  for complete imported annotations. It reuses optional quanteda KWIC
  search and retains original segment text, token positions, candidate
  counts, and occurrence identities.
- Caller-supplied candidates and explicit decisions stay separate.
  Single candidates are not selected automatically; unreviewed,
  selected, unresolved and no-candidate occurrences remain
  distinguishable. Decisions include a reviewer and reason and are
  checked against the source/candidate snapshot.
- Added an offline English/Japanese guide with reordered decisions and
  an RDS round trip. No semantic model, dictionary, corpus, automatic
  sense disambiguation, sense-specific reference frequencies or new
  dependency is added.

### Japanese frequency and stimulus review

- UTF-8 frequency fields are read without conversion to the native
  locale. The optional gibasa recipe requires R \>= 4.2; the core
  remains R \>= 4.1.
- Added an explicitly sourced local-file helper for the pinned Japanese
  TUBELEX orthographic-base table. It records
  original/reviewed/normalized forms, unresolved and unmatched items,
  source hash and published denominators; frequencies and video/channel
  proportions reuse
  [`lexdiv_norm_profile()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_norm_profile.md).
- Added a stimulus-selection guide joining TUBELEX, WLSP-familiarity,
  AoA and BOI by study item ID, with per-condition missingness,
  distributions, explicit WLSP choices and an RDS round trip. The
  optional gibasa annotation workflow connects reviewed base forms while
  retaining original token positions.
- No Japanese data tables or new mandatory dependencies are bundled. The
  helper performs reviewed key lookup, not full TUBELEX tokenizer
  replication.

### Japanese norms for stimulus items

- Added an explicitly sourced WLSP-familiarity example for reviewing all
  exact-spelling candidates and recording item-to-record choices with
  reasons. It preserves unmatched and unreviewed items separately,
  checks record IDs against the intended spelling, and retains five
  published estimates without choosing a candidate automatically. Norm
  data are obtained separately.
- Added a guide and an explicitly sourced example for separately
  obtained Japanese AoA or BOI aggregate files. It reuses
  [`lexdiv_norm_profile()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_norm_profile.md)
  and retains study IDs, experimental conditions, source IDs, rating
  counts, SDs, unmatched items, source hashes and data terms. Each
  resource works independently.
- Documented age-category interpretation, condition-specific missingness
  and ambiguous spelling/reading keys. No external norm values, new
  dependencies, automatic downloads or new exported functions are
  included.

### External annotations and a Japanese input workflow

- Added experimental
  [`lexdiv_import_annotations()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_import_annotations.md)
  to align complete external token tables with original segment text. It
  retains lexical forms, POS, missing annotations, original token
  indices, empty documents, dictionary declarations and source hashes.
  Positions use segment-local Unicode codepoints; omitted non-whitespace
  text and normalization mismatches fail.
- Added an offline Japanese illustration and an optional R-only
  gibasa/UniDic recipe. The importer needs no new mandatory dependency;
  gibasa is suggested for the recipe and dictionaries are obtained
  separately. Filtering preserves gaps for the existing n-gram and
  quanteda interfaces. English tokenizer, bundled resources and all
  existing metric definitions are unchanged.
- This does not bundle Japanese frequency norms or add a new
  morphological analyzer, split/merge comparison, or evidence of
  cross-language measurement equivalence.

### Building references from larger local inputs

- Added
  [`lexdiv_ngram_reference_build()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ngram_reference_build.md)
  to read whole-document extraction chunks sequentially and retain exact
  type counts, document counts, denominators and source fingerprints.
  Occurrence tables are released after each chunk. Distinct types and
  document IDs still occupy memory; there is no disk-backed index,
  pruning or automatic resume. No dependency was added.
- MASC reader interface 0.2.0 accepts `documentHeader`/`.hdr` references
  as well as Mini-MASC’s `cesHeader`/`.anc` layout. Boundary checks are
  unchanged. An audit of all 392 official MASC 3.0.0 documents accepted
  122 and rejected 270 under these checks; this is not validated
  whole-corpus support.

### Comparing reference choices

- Added
  [`lexdiv_ngram_compare()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ngram_compare.md)
  to apply named references to the same target, retain each reference’s
  available-value mean and coverage, and compare rates on target items
  with defined values in every reference. Common-set means, differences
  from an explicit baseline, source positions, denominators and metadata
  stay together; undefined comparisons remain missing.
- Added an offline example showing that pruning can raise a conditional
  mean while frequencies on the common items remain unchanged. Existing
  frequency arithmetic is reused; there are no new dependencies or
  automatic rankings.
- Clarified that the quanteda adapter’s UTF-8 requirement concerns the
  running R session, including on macOS. `C.UTF-8` is UTF-8-capable and
  differs from the plain `C` locale used in a stress test.

### Annotated corpus input and quanteda integration

- Added experimental
  [`lexdiv_read_masc()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_read_masc.md)
  for local GrAF 1.0 Penn annotations, verified with Mini-MASC 1.0. It
  retains supplied token boundaries, lemma/POS features,
  sentence/utterance IDs, source coordinates, original text and file
  fingerprints. Overlapping, discontinuous or unresolved spans are
  rejected. Source anchors may explicitly use Unicode codepoints or
  UTF-16 code units.
- Added
  [`lexdiv_as_quanteda()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_read_masc.md)
  for explicit token and segment tables, preserving excluded positions,
  empty segments and mappings back to source rows. It uses quanteda’s
  public APIs without retokenization; quanteda is an optional
  dependency. Existing core calculations and tokenizer defaults are
  unchanged. Non-ASCII imports require a UTF-8 locale; the adapter
  verifies imported terms and positions and never changes the user’s
  locale.
- Added an offline guide and original, MIT-licensed annotation example.
  MASC/OANC corpus data are not bundled or automatically downloaded.
  Other annotation layers and OANC are not validated reader inputs. See
  the MASC 3.0.0 scope above before using that release.

### Adjacent n-grams with local references

- Added
  [`lexdiv_ngrams()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ngrams.md)
  for adjacent bigrams and trigrams from explicit document/segment IDs
  and original positions. It retains occurrences, corpus and document
  counts, eligible-window totals, empty documents and provenance.
  Position gaps break adjacency; no sentence splitting or normalization
  is inferred. An occurrence-row ceiling is checked before output
  allocation.
- Added
  [`lexdiv_ngram_reference()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ngrams.md)
  for local extractions or external aggregate tables with explicit
  totals and source metadata, and
  [`lexdiv_ngram_profile()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ngrams.md)
  for per-document token/type means and coverage. Complete-reference
  sample zeros and unlisted incomplete-reference keys have different
  states. Rates divide by eligible n-gram opportunities. RDS preserves
  full provenance.
- Added an offline guide with authored examples, boundary
  counterexamples, CSV import and RDS reuse. No n-gram corpus, new
  dependency, association score or automatic download is added. Contract
  version starts at 0.1.0.

### Open-access academic texts

- Added an explicitly run example and guide using three CC BY 4.0 JOSS
  papers. The recipe checks pinned source hashes and licenses, records
  paragraph extraction, and saves attribution, metadata, diagnostics and
  full results. Paper text is obtained only when requested and is not
  bundled. `xml2` is an optional dependency for this recipe. Author L1
  remains unknown; the example describes academic English without
  assigning a native-speaker label.

### Caller-supplied references across corpora

- Added
  [`lexdiv_norm_profile_batch()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_norm_profile_batch.md)
  with one shared resource validation, a global output-row bound, and
  document-specific summary, lookup and coverage tables. Single-document
  arithmetic and missingness are unchanged. Empty documents and
  unmatched/missing annotations remain explicit.
- Added a guide for custom reference data, exact word units, document
  metadata, three coverage denominators and reproducible saving. No new
  dependencies or external datasets are required. Third-party copyright
  notices are now also referenced from DESCRIPTION.

### Corpus scope and study design

- Clarified native-speaker and learner corpus applications, including
  within-population register comparisons. The comparison guide
  distinguishes analysis samples, reference resources and matched
  comparison samples, with spoken-data boundaries and
  language-background metadata kept explicit. The vocabulary-use guide
  remains one application, not an input requirement.

### Paired vocabulary responses

- Added
  [`lexdiv_compare_responses()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_compare_responses.md)
  for already scored binary response pairs. It checks composite pair
  IDs, separates directional disagreement and three missingness
  patterns, and reports numerators and denominators by explicit groups.
  Original metadata remain attached. It does not score free text,
  dichotomize partial credit, or estimate lexical employability.
- The vocabulary-use guide now includes CSV input, item/sense matching,
  rubric metadata and repeated-occasion examples using this function.

### TUBELEX diagnostics and vocabulary-use evidence

- Added
  [`tubelex_diagnostics()`](https://ryuya-dot-com.github.io/ldfreq/reference/tubelex_diagnostics.md)
  to turn existing profiles into reusable summary and document tables,
  count confirmed unmatched terms, and inspect query normalization. It
  retains empty/failed documents and unresolved matches, separates
  recorded input conditions, and performs no new resource lookup.
- Added a worked guide connecting TUBELEX word-form features to
  explicitly scored learner-by-item responses. It distinguishes
  recognition, meaning recall and contextual use, preserves missing
  pairs and directional disagreement, and does not interpret corpus
  frequency as an employability score.

### Reproducible lemma dictionaries

- `lexdiv_lemmatize(method = "textstem")` now accepts `dictionary`,
  `dictionary_id` and `dictionary_version`. It records the actual
  dictionary’s SHA-256 fingerprint and lookup locale, including for the
  default lexicon dictionary. Save the dictionary separately for reruns.
  It remains an optional, context-free backend; aligned supplied
  annotations support contextual review.
- Preprocessing contract 0.4.0 retains reading of 0.3.0 objects and
  0.2.0 Unicode objects. Lexical-overlap contract 0.2.0 checks
  dictionary records for lemma comparisons involving textstem; absent
  legacy records cannot establish strict comparability. Metric formulas
  and result schemas are unchanged.

### Annotation comparisons

- Added
  [`lexdiv_compare_annotations()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_compare_annotations.md)
  to compare lemma, UPOS and flemma annotations on the same tokenized
  text or named document batches. It checks original text and token
  alignment, pairs by document ID, retains empty documents and missing
  annotations, and preserves both provenance records. Differences
  identify changed labels, not errors or proficiency gains.

### NJ8 diagnostics

- Added
  [`nj8_diagnostics()`](https://ryuya-dot-com.github.io/ldfreq/reference/nj8_diagnostics.md)
  for existing single or batch profiles. It counts unmatched terms and
  surface-to-unit mappings by occurrences and documents, flags
  introduced numeric/whitespace labels, and preserves coverage,
  exclusions and provenance. It does not rerun lookup, correct
  annotations or label unmatched terms as difficult words.
- Added a worked guide to surface/lemma coverage and parameter
  sensitivity, using authored examples that run without an external
  model or corpus. It includes paired document/condition tables that
  retain uncomputable rows, and a fixed-frequency example separating
  MATTR position effects from HD-D.

### English text and document tables

- Added an opt-in `tokenizer = "english"` using R and the existing
  stringi dependency. It retains contractions, hyphenated words and
  dotted initialisms, canonicalizes apostrophe/hyphen typography, and
  records excluded URLs, emails and number-like spans with
  processed-text offsets and fingerprints. Existing Unicode-tokenizer
  defaults and numerical definitions are unchanged.
- Added
  [`lexdiv_tokenize_batch()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_text_batch.md)
  for named text vectors or explicit ID/text tables, and
  [`lexdiv_metrics_text_batch()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_text_batch.md)
  for raw or prepared documents. Document IDs, empty documents, full
  metric rows, token audits, and preprocessing records survive the batch
  workflow; missing texts produce identified errors.
- Preprocessing contract 0.3.0 supports both tokenizer identities. Saved
  0.2.0 Unicode objects remain valid. Neither tokenizer claims Treebank
  equivalence.
- Added a tokenizer guide with worked segmentation differences,
  CSV/UTF-8 text input, NJ8 coverage, and reporting guidance.

### Bundled vocabulary and research workflows

- New JACET 8000 is bundled with JACET’s permission and source
  attribution.
  [`nj8_profile()`](https://ryuya-dot-com.github.io/ldfreq/reference/nj8_profile.md)
  and
  [`nj8_profile_batch()`](https://ryuya-dot-com.github.io/ldfreq/reference/nj8_profile.md)
  now default to this versioned table; explicit external tables remain
  supported. The level-profile contract advances to 0.2.0, recording
  bundled/external identity and the bundled source citation.
- Checked all 8,000 rank/entry pairs against the official workbook.
  Corrected three entries in the supplied snapshot: restore `nan` at
  rank 6926, and lowercase `true`/`false` at ranks 326/2382. Source and
  correction records are installed with the data. Lookup checks the
  bundled file before use.
- Added a complete text-to-report example, resource/method citation
  guidance, and an optional external NLTK recipe for TUBELEX input.
  Python remains optional and is not called by any R calculation.
- Reorganized the introduction around comparison conditions and
  reference coverage, with an explicit comparison to existing R
  packages.

### Compatibility and migration

- TUBELEX profiles now reject `lexdiv_tokenization` objects by default
  because their segmentation differs from the bundled Treebank resource.
  Prepare source-compatible term vectors externally; vector alignment
  remains unverified. The explicit `tokenization_mismatch = "allow"`
  override records a different-tokenizer sensitivity analysis. Coverage
  is not alignment evidence.
- Preprocessing contract 0.2.0 requires text hashes, token pattern,
  character counts, and a token-table fingerprint, and checks
  normalization consistency. Recreate objects saved under 0.1.0 from
  their original text and reapply annotations. Tokenizer rules and
  tokenizer version 0.1.0 are unchanged.
- [`lexdiv_widen()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_convenience.md)
  retains contract, requested/effective parameters, and N/V by default.
  It rejects column groups containing unlike specifications; plan-local
  request labels are not globally unique. Metric plots similarly require
  one specification and invisibly return all selected result fields.

### Corrections and additions

- Corrected cancellation near saturation in
  `expected_ttr_d_hypergeom_fit_v1` by computing expected duplicate-draw
  fractions and model residuals directly. The exact expected-TTR curve,
  objective, and method ID remain unchanged; record package version for
  numerical reproducibility. A one-doubleton, million-token regression
  agrees with an independent 80-digit reference. The earlier result was
  about 8.8% too small. No arbitrary D cap is introduced.
- Added
  [`tubelex_profile_batch()`](https://ryuya-dot-com.github.io/ldfreq/reference/tubelex_profile.md)
  with one verified resource snapshot per call, document-local invalid
  results, a row budget, and complete per-document outputs.
- TUBELEX profile contract 0.2.0 records the input alignment boundary
  and adds explicit `normalization = "tubelex_apostrophe"` for internal
  apostrophe/prime typography. This does not provide Treebank
  segmentation. Default term-vector normalization, resource bytes, and
  lookup formulas are unchanged.
- Documented the frozen MTLD minimum-factor/tail discontinuity and added
  a regression example. Its definition has not been silently clamped or
  replaced.
- Added a worked research-design vignette distinguishing parameter
  sensitivity, computability, reference coverage, and evidence of
  construct validity.

## ldfreq 0.1.0

### Caller-supplied lexical norm profiles

- Added
  [`lexdiv_norm_profile()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_norm_profile.md)
  for exact, single-document profiling against caller-supplied lexical
  norm tables. One call can describe several measures while preserving
  each measure’s construct, unit, direction, population, and resource
  provenance.
- Token- and exact-type means use observed matched values only. The
  result reports resource coverage, input-relative value coverage, and
  conditional annotation coverage separately; OOV terms and matched keys
  with missing annotations are never converted to zero or merged into
  one missing state.
- Added strict table and metadata validation, deterministic
  resource-row-order invariance, a whole-result row bound, bounded
  printing, an installed normative JSON contract, and randomized
  independent-oracle tests. The API performs no implicit normalization,
  fuzzy matching, thresholding, composite scoring, runtime download, or
  data-license inference.

### Local MATTR profile

- Added
  [`lexdiv_mattr_profile()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_mattr_profile.md)
  to expose every complete step-one MATTR window, its local TTR, and
  position-only window exposure without retaining token strings. It
  accepts only canonical MATTR specifications from the existing
  [`lexdiv_spec()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_profile.md)
  /
  [`lexdiv_grid()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_profile.md)
  /
  [`lexdiv_plan()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_profile.md)
  identity layer.
- The unchanged
  [`lexdiv_profile()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_profile.md)
  rows remain the summary authority. Local means reconcile with the core
  value; empty, invalid, and too-short inputs retain canonical
  structured missingness and receive no fabricated detail rows.
- Added a combined row bound, bounded print method, and
  one-request-at-a-time plot method. The contract treats the output as a
  descriptive local trajectory and positional-exposure audit, not an
  inferential stability test, automatic window selector, or universal
  text-length rule.

### Reference coverage API

- Added
  [`lexdiv_reference_coverage()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_reference_coverage.md)
  for the directional many-to-one question: what proportion of each
  document’s tokens and distinct types occurs in one explicit reference
  term set? The document-major long summary retains measure and method
  IDs, numerators, denominators, input counts, match counts, status,
  missing reasons, and contract/schema identity.
- Kept matching exact and preprocessing-free. Document repetition
  affects only token-weighted coverage; reference repetition affects
  diagnostics but not set membership. Empty documents, an empty
  reference, invalid document vectors, and an invalid reference have
  distinct, tested behavior.
- Added named-list and explicit data-frame batch inputs, a whole-result
  row bound, opt-in term/count/match details with disclosure, path-free
  IDs, a bounded print method, and a one-weighting-at-a-time plot method
  that returns its plotted rows invisibly.

### Canonical public API names

- Established
  [`nj8_profile()`](https://ryuya-dot-com.github.io/ldfreq/reference/nj8_profile.md),
  [`nj8_profile_batch()`](https://ryuya-dot-com.github.io/ldfreq/reference/nj8_profile.md),
  [`tubelex_profile()`](https://ryuya-dot-com.github.io/ldfreq/reference/tubelex_profile.md),
  and
  [`lexdiv_overlap_ids()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_overlap.md)
  as the sole public names for their respective operations. The compact
  resource names and regular `_ids` catalog suffix keep autocomplete and
  installed help within one canonical vocabulary.
- Registered the corresponding result classes and S3 methods under the
  same canonical vocabulary, and synchronized it across README examples,
  installed help, vignettes, the offline smoke example, and pkgdown
  navigation.
- Added concise, lossless print methods for method specifications,
  grids, and plans, and made
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html) on a raw-text
  metric result delegate to its unchanged core result table. Plot
  methods continue to return the displayed data invisibly for reuse.

### New overlap API

- Added
  [`lexdiv_term_overlap()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_overlap.md)
  for exact distinct-term Jaccard, Dice, directional coverage, and
  overlap-coefficient results with explicit numerators, denominators,
  empty-set behavior, and optional term details.
- Added
  [`lexdiv_content_overlap()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_overlap.md)
  for exact overlap after explicit Universal POS content-word selection.
  It reports annotation coverage and fails by default when unit-relevant
  preprocessing or annotation settings differ or are unverifiable.
- Term-level detail remains opt-in. Results record whether exact lexical
  terms are retained, and the print method displays a disclosure when
  they are.
- Flemma comparisons now use disclosed caller-declared version labels
  rather than byte or canonical-content hashes. Strict comparison treats
  missing or different resource versions as unverifiable or mismatched.
  Two inputs with no overrides remain comparable; otherwise both must
  declare the same override version.

### Other corrections

- [`lexdiv_metrics_text()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_preprocessing.md)
  forwards custom expected-TTR D sample sizes to the token-vector core.
- Lemma, UPOS, and flemma annotations are checked against their recorded
  settings before use. UPOS identity is explicit even when the same
  pipeline generates lemmas and tags.
- MATTR plotting validates `add_global_mean`; plots return their
  selected data invisibly. S3 methods are documented in installed help.

### Initial release

- Added twelve versioned lexical-diversity metrics for ordered,
  pre-tokenized input: TTR, RTTR/Guiraud, CTTR, Herdan’s C, Maas
  a-squared, MSTTR, MATTR, MTLD, HD-D, deterministic expected-TTR D,
  Yule’s K, and Yule’s I.
- Added
  [`lexdiv_as_documents()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_convenience.md)
  for named lists, tidy one-token-per-row data frames, and `quanteda`
  tokens objects without adding a runtime dependency on `quanteda`.
- Added
  [`lexdiv_widen()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_convenience.md)
  as a deterministic, computation-free long-to-wide transformation that
  keeps profile parameter requests distinct.
- Added base-R plot methods for metric, batch, profile, screen, TUBELEX
  coverage, and existing New JACET 8000 results.
- Added
  [`lexdiv_tokenize()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_preprocessing.md)
  and
  [`lexdiv_metrics_text()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_preprocessing.md)
  for raw English text. Unicode normalization, case handling, number
  retention, token offsets, and lexical-unit selection are retained in
  preprocessing provenance.
- Added
  [`lexdiv_lemmatize()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_preprocessing.md)
  for caller-supplied annotations and an optional `textstem` backend.
  Missing lemmas and UPOS tags remain explicit.
- Added
  [`lexdiv_flemmatize()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_flemmatize.md)
  for caller-supplied AntBNC form-to-family-lemma mappings. Fixed
  adapter identities, caller-declared resource/override labels, identity
  fallback, and match coverage are recorded without retaining local file
  names, content hashes, absolute paths, or redistributing the list.
- Added
  [`lexdiv_variant_ids()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_variant_metrics.md)
  and
  [`lexdiv_variant_metrics()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_variant_metrics.md)
  to compare four Maas definitions and four sequential-MTLD definitions.
  TAALED-related rows are formula comparators, not end-to-end
  compatibility claims.
- Added bounded method specifications, parameter grids, request plans,
  multi-document profiles, and independent token-length screens.
- Added
  [`nj8_profile()`](https://ryuya-dot-com.github.io/ldfreq/reference/nj8_profile.md)
  and its batch and plot methods, initially for a caller-supplied New
  JACET 8000 list. Exact and cumulative Level 1–8 token and type rates
  retain off-list items in the denominator. Version 0.1.0 did not bundle
  the list; version 0.2.0 adds the permitted reference table.
- Added
  [`tubelex_profile()`](https://ryuya-dot-com.github.io/ldfreq/reference/tubelex_profile.md)
  with explicit query normalization, lossless matched and unmatched
  rows, token and type coverage, and matched-only frequency and
  prevalence summaries.
- Added the slim TUBELEX-EN aggregate with its BSD-3-Clause notice,
  COPYRIGHTS entry, source identity, transformation provenance, and
  package inventory. Runtime lookup has no network, download, or
  fallback path.
- Added machine-readable contracts, schemas, hand fixtures, differential
  audits, executable examples, an offline smoke test, and cross-platform
  R package checks.
- Clarified that the metrics operationalize lexical variety and
  repetition; they are not direct measures of proficiency, writing
  quality, validity, or reliability. Resource-relative frequency and
  level profiles likewise require coverage-aware, corpus-specific
  interpretation.
- Added the deterministic expected-TTR curve-fit D under the explicit
  method ID `expected_ttr_d_hypergeom_fit_v1`. It uses exact
  finite-population expected TTR values, no random sampling, and makes
  no CLAN VOCD identity claim.
