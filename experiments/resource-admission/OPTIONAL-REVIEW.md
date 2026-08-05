# Optional TUBELEX review checklist

An additional reviewer may inspect the exact candidate, but no reviewer identity
or approval record is required for release. A useful advisory review should
confirm:

1. the pinned upstream repository contains the published English frequency list
   and the BSD-3-Clause root license;
2. the README offers aggregate frequency lists while withholding full corpus
   text for copyright reasons;
3. `inst/licenses/tubelex/NOTICE.md` and `inst/COPYRIGHTS` retain attribution,
   disclaimer, source identity, and the package transformation statement;
4. the bundled slim table contains aggregate word/count/video/channel values but
   no subtitle text, video ID, channel ID, title, filename, or local path;
5. the public profile reports unmatched values as missing and exposes coverage;
6. no runtime download, network lookup, or fallback is possible; and
7. the exact source, installed, and platform resource inventories agree.

Record any disagreement as an issue or pull-request review. An advisory review
can improve the evidence but cannot create rights absent from the upstream
license.
