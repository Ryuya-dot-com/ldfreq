# Inspect and explicitly download optional reference data

Lists fixed reference-data versions and their separate terms, or
downloads selected resources after an explicit acknowledgement.
Installing the package and ordinary calculations never download
reference data.

## Usage

``` r
lexdiv_resource_info(resources = c("tubelex", "nj8", "morpholex", "bnccoca", "morphynet"), cache_dir = NULL)
lexdiv_download_resources(resources, accept_license = FALSE, cache_dir = NULL)
```

## Arguments

- resources:

  Unique resource names as a plain character vector. The inspection
  default lists all resources; downloading always requires an explicit
  selection.

- accept_license:

  Exactly `TRUE` after reviewing each resource's `license_url` and
  `notice_url`. Defaults to `FALSE`, which refuses downloads.

- cache_dir:

  One directory path. Defaults to option `ldfreq.resource_dir`, then
  environment variable `LDFREQ_RESOURCE_DIR`, then
  `tools::R_user_dir("ldfreq", "cache")`. Set the same option or
  environment variable when reading resources stored outside the default
  cache.

## Value

A data frame with resource name, fixed version, license and notice URLs,
download bytes, verified availability, cache path, archive URL, SHA-256
and citation. The downloader returns it invisibly.

## Details

Archives are downloaded from a fixed release and checked for byte count,
SHA-256, expected member names and individual file hashes before
installation. A verified cache is reused without a download. An
incomplete or modified cache produces an error; it is not silently
replaced. To repair one, explicitly remove only the version directory
reported by `lexdiv_resource_info()` and rerun the download. Other
resource versions remain separate.

MorphoLex is CC BY-NC-SA 4.0 (noncommercial); BNC/COCA is CC BY-SA 4.0;
MorphyNet is CC BY-SA 3.0; TUBELEX is BSD-3-Clause; NJ8 has its own
permission and attribution terms. These datasets are not included in the
MIT package. The MorphyNet resource is a nine-row example, not the full
database.

No resource is needed for the core diversity metrics. Resource-specific
readers explain the required download if a cache is missing. Copying a
verified cache to an offline machine is supported; use the same cache
setting there. Unused caches may be removed explicitly by the user.

## Examples

``` r
lexdiv_resource_info()[c("resource", "license", "available", "download_bytes")]
if (FALSE) { # \dontrun{
# Review the source, license_url and notice_url before downloading.
lexdiv_download_resources("tubelex", accept_license = TRUE)
lexdiv_resource_info("tubelex")
} # }
```
