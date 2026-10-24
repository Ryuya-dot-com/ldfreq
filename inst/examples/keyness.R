# Compatibility names for scripts written before 0.4.0.9006.
# New analyses can call the documented ldfreq APIs without source().
# Resolve within the installed version; keep one implementation.
keyness_compare <- ldfreq::lexdiv_keyness
keyness_validate <- utils::getFromNamespace("keyness_validate", "ldfreq")
keyness_concordance <- utils::getFromNamespace("keyness_concordance", "ldfreq")
