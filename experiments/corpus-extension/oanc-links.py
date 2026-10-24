"""Extract person/source links from private OANC headers. No text is exported."""
import json
from pathlib import Path
import re
import sys
import unicodedata
from lxml import etree

base = Path(sys.argv[1]).resolve()
ns = {'g': 'http://www.xces.org/ns/GrAF/1.0/'}
def norm(s):
    return ' '.join(unicodedata.normalize('NFKC', s).casefold().split())

out = []
with (base / 'extracted-private.jsonl').open() as f:
    for line in f:
        row = json.loads(line)
        path = (base / row['source_path']).with_suffix('.anc')
        links = []
        if row['header_status'] not in ['malformed_xml', 'mismatched_content_link']:
            root = etree.parse(str(path), etree.XMLParser(no_network=True))
            for person in root.findall('g:profileDesc/g:particDesc/g:person', ns):
                if person.get('id'):
                    source = 'switchboard' if row['genre']=='telephone' else 'charlotte'
                    links.append('person:' + source + ':' + norm(person.get('id')))
            for author in row['authors']:
                if norm(author): links.append('author:' + norm(author))
        collection = row['collection']
        if collection.startswith('non-fiction/OUP/') or collection=='technical/911report':
            links.append('work:' + norm(collection))
        if row['genre']=='travel_guides' and row['source_title']:
            links.append('guide:' + norm(' '.join(row['source_title'])))
        if collection in ['journal/verbatim','letters/icic'] or not links:
            source = re.sub(r'^(journal/slate|telephone/switchboard)/\d+$', r'\1', collection)
            links.append('collection:' + norm(source))
        assert links
        out.append(dict(doc_id=row['doc_id'], links=sorted(set(links))))
assert len(out)==8824 and len({x['doc_id'] for x in out})==8824
(base/'source-links-private.json').write_text(json.dumps(out, ensure_ascii=False))
print('Header links saved for', len(out), 'documents')
