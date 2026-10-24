# Legacy analysis records

`public-analysis-api-v1.rds` was generated with the fixed ldfreq 0.4.0.9005
source distribution. It contains authored, MIT-licensed concordance, collocation
and keyness examples and a small three-observation study (submitted, empty and
unsubmitted). No natural corpus, personal paths or session environments are saved.

The fixture tests migration of saved plain-list objects, input/result shapes,
IDs, missingness, positional calls and the new plotting class. Existing example
tests independently enumerate counts and opportunities and check numerical
references; equality to this fixture does not substitute for those checks.
