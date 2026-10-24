# Compatibility names for scripts written before 0.4.0.9006.
# New analyses can call the documented ldfreq APIs without source().
# Resolve within the installed version; keep one implementation.
collocation_profile <- ldfreq::lexdiv_collocations
collocation_validate <- utils::getFromNamespace("collocation_validate", "ldfreq")
