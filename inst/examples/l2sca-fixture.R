# Authored texts/trees and declared matched nodes, MIT licensed.
# No parser runs here; this is an inspectable arithmetic/import example.
l2sca_fixture <- function() {
  command <- function(text, status = 0L) list(exit_status = status, stdout = text,
    stderr = "authored fixture; no external process",
    stdout_sha256 = digest::digest(enc2utf8(text), algo = "sha256", serialize = FALSE))
  row <- function(id, text, penn, ids, status = "parsed") list(document_id = id, text = text,
    text_sha256 = digest::digest(enc2utf8(text), algo = "sha256", serialize = FALSE),
    parser = command(penn, if (status == "parser_failed") 1L else 0L),
    queries = if (status == "parser_failed") list() else lapply(ids, command), status = status)
  entries <- list(
    row("manual_coord_clauses", "Maya reads, and Leo writes.",
      "(ROOT (S (S (NP (NNP Maya)) (VP (VBZ reads))) (, ,) (CC and) (S (NP (NNP Leo)) (VP (VBZ writes))) (. .)))",
      list(s = "1:1", c = "1:3\n1:14", t = "1:2\n1:14", dc = "", fc = "", ft = "")),
    row("manual_coord_vp", "Maya reads and writes.",
      "(ROOT (S (NP (NNP Maya)) (VP (VP (VBZ reads)) (CC and) (VP (VBZ writes))) (. .)))",
      list(s = "1:1", c = "1:2", t = "1:2", dc = "", fc = "", ft = "")),
    row("manual_finite_complement", "Maya knows that Leo writes.",
      "(ROOT (S (NP (NNP Maya)) (VP (VBZ knows) (SBAR (IN that) (S (NP (NNP Leo)) (VP (VBZ writes))))) (. .)))",
      list(s = "1:1", c = "1:2\n1:12", t = "1:2", dc = "1:9", fc = "", ft = "")),
    row("manual_nonfinite_complement", "Maya expects Leo to write.",
      "(ROOT (S (NP (NNP Maya)) (VP (VBZ expects) (S (NP (NNP Leo)) (VP (TO to) (VP (VB write))))) (. .)))",
      list(s = "1:1", c = "1:2", t = "1:2", dc = "", fc = "", ft = "")),
    row("manual_fragment_FRAG", "A very quiet room.",
      "(ROOT (FRAG (NP (DT A) (ADJP (RB very) (JJ quiet)) (NN room)) (. .)))",
      list(s = "1:1", c = "", t = "", dc = "", fc = "1:2", ft = "1:2")),
    row("manual_fragment_NP", "A very quiet room.",
      "(ROOT (NP (DT A) (ADJP (RB very) (JJ quiet)) (NN room) (. .)))",
      list(s = "1:1", c = "", t = "", dc = "", fc = "", ft = "")),
    row("manual_imperative", "Read the book.",
      "(ROOT (S (VP (VB Read) (NP (DT the) (NN book))) (. .)))",
      list(s = "1:1", c = "1:2", t = "1:2", dc = "", fc = "", ft = "")),
    row("manual_relative", "The book that Leo wrote vanished.",
      "(ROOT (S (NP (NP (DT The) (NN book)) (SBAR (IN that) (S (NP (NNP Leo)) (VP (VBD wrote))))) (VP (VBD vanished)) (. .)))",
      list(s = "1:1", c = "1:2\n1:12", t = "1:2", dc = "1:9", fc = "", ft = "")),
    row("manual_reduced_relative", "The book written by Leo vanished.",
      "(ROOT (S (NP (NP (DT The) (NN book)) (VP (VBN written) (PP (IN by) (NP (NNP Leo))))) (VP (VBD vanished)) (. .)))",
      list(s = "1:1", c = "1:2", t = "1:2", dc = "", fc = "", ft = "")),
    row("empty", "", "", list(s = "", c = "", t = "", dc = "", fc = "", ft = "")),
    row("failed", "Maya reads books.", "", list(), "parser_failed"))
  documents <- do.call(rbind, lapply(entries, function(x)
    data.frame(document_id = x$document_id, text = x$text, stringsAsFactors = FALSE)))
  trace <- list(format = "ldfreq-l2sca-trace-1", provenance = list(
    kind = "authored-fixture", language = "en", source = "ldfreq authored structural examples",
    settings = "declared Penn trees and query-node observations; no original model run"),
    documents = entries)
  list(documents = documents, trace = trace)
}
