# Compatibility names for scripts written before 0.4.0.9006.
# New analyses can call the documented ldfreq APIs without source().
# Resolve within the installed version; keep one implementation.
.concordance_hash <- utils::getFromNamespace(".concordance_hash", "ldfreq")
.concordance_check <- utils::getFromNamespace(".concordance_check", "ldfreq")
.concordance_whole <- utils::getFromNamespace(".concordance_whole", "ldfreq")
concordance_search <- utils::getFromNamespace("concordance_search", "ldfreq")
concordance_sort <- ldfreq::lexdiv_concordance_sort
concordance_positions <- utils::getFromNamespace("concordance_positions", "ldfreq")
concordance_dispersion <- ldfreq::lexdiv_concordance_dispersion
