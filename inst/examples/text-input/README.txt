These texts and metadata were authored for the ldfreq file-input tutorial.
They are MIT-licensed teaching material, not learner responses or observations.

texts/001.txt through texts/030.txt contain thirty constructed English documents.
They combine six topic passages and five endings, with zero to four repetitions
of an authored reminder sentence. Shared passages and repetition deliberately
produce variation in local vocabulary diversity. They are not thirty independent
writers, a representative corpus, or evidence about proficiency or group effects.
texts/031.txt is intentionally empty and remains in tables but not the MATTR plot.

Each nonempty TXT has two paragraphs, LF line endings and a final newline.
essays.csv contains the exact same 31 IDs and text strings, including newlines.
metadata.csv has fictional writer/task IDs in reverse document order; join by ID.
Repeated writer IDs illustrate data structure, not actual repeated measurements.
japanese.txt illustrates UTF-8 reading only, not English tokenization of Japanese.

japanese-workflow/ contains five authored files and complete prepared annotations.
The POS1 and goshu columns are authored teaching labels (version 2), not MeCab
or UniDic output. <MISSING> explicitly marks unassigned features. The three fruit
spellings share an authored 漢 origin label while their scripts differ; the
unlisted form has no assigned POS/origin. No learner data or dictionary is included.

Keep original input files and their identifiers when replacing these teaching
examples with your own permitted data. The common 50-token window is an explicit
choice for these constructed texts, not a universal research recommendation.
