"""Prepare private source inventories from the documented source layout."""
from collections import Counter
import hashlib
import json
from pathlib import Path
import re
import sys
from lxml import etree

base = Path(sys.argv[1]).resolve()
corpus = sys.argv[2]
folder = base / corpus
parser = etree.XMLParser(load_dtd=False, no_network=True, resolve_entities=False)
sha = lambda b: hashlib.sha256(b).hexdigest()
rows = []
issues = []

if corpus == "icnale":
    for target in sorted((folder / 'source').glob('WE_*.txt')):
        data = target.read_bytes()
        m = re.fullmatch(r'WE_([A-Z]+)_(PTJ0|SMK0)_(\d+)_(.+)\.txt', target.name)
        assert m, target.name
        region, task, writer, level = m.groups()
        rows.append(dict(doc_id=target.stem, writer_id=region+'_'+writer,
            task=task, region=region, level=level, group='L1' if region=='ENS' else 'L2',
            genre='argumentative_essay', source_sha256=sha(data),
            source_path=str(target.relative_to(folder)), text=data.decode('utf-8-sig')))
    assert len(rows) == 5600
    pairs = Counter(x['writer_id'] for x in rows)
    assert set(pairs.values()) == {2}
    assert len({(x['writer_id'], x['task']) for x in rows}) == len(rows)

elif corpus == "bawe":
    for path in sorted((folder / 'source/download/CORPUS_UTF-8').glob('*.xml')):
        data = path.read_bytes()
        root = etree.fromstring(data, parser)
        def fields(xpath):
            return {p.get('n'): ''.join(p.itertext()).strip() for p in root.findall(xpath)}
        source = fields('teiHeader/fileDesc/sourceDesc/p')
        person = fields('teiHeader/profileDesc/particDesc/person/p')
        body = root.find('text/body')
        assert body is not None and person.get('student ID')
        # Inventory policy: body prose, including quotations; exclude footnotes,
        # table captions and formula/figure placeholders. No spelling correction.
        special = dict(Counter(e.tag for e in body.iter() if e.tag in
            ['note', 'quote', 'table', 'figure', 'formula']))
        etree.strip_elements(body, 'note', 'ref', 'table', 'figure', 'formula', with_tail=False)
        text = ''.join(body.itertext())
        rows.append(dict(doc_id=path.stem, writer_id=person['student ID'],
            task=source.get('module code', ''), genre=source.get('genre family', ''),
            discipline=source.get('discipline', ''), group=source.get('disciplinary group', ''),
            level=source.get('level', ''), first_language=person.get('first language', ''),
            declared_words=source.get('number of words', ''),
            number_authors=source.get('number of authors', ''),
            macrotype=source.get('macrotype of assignment', ''), special_markup=special,
            source_sha256=sha(data), source_path=str(path.relative_to(folder)), text=text))
    assert len(rows) == 2761

elif corpus == "oanc":
    source_root = folder / 'source/OANC-GrAF'
    ns = {'g': 'http://www.xces.org/ns/GrAF/1.0/'}
    for path in sorted(source_root.rglob('*.txt')):
        rel = path.relative_to(source_root)
        if rel.parts[0] != 'data':
            continue
        data = path.read_bytes()
        header = path.with_suffix('.anc')
        assert header.exists(), str(rel)
        header_status = 'ok'
        try:
            root = etree.parse(str(header), parser)
            primary = root.find('g:profileDesc/g:primaryData', ns)
            location = primary.get('loc') if primary is not None else None
            if location is None:
                content = root.find('g:profileDesc/g:annotations/g:annotation[@type="content"]', ns)
                location = content.get('ann.loc') if content is not None else None
                header_status = 'legacy_content_link' if location else 'missing_content_link'
            if location and (header.parent / location).resolve() != path.resolve():
                # A small set of distributed headers has stale or wrong links.
                # Do not attach uncertain bibliographic metadata to these texts.
                header_status = 'mismatched_content_link'
                root = None
        except etree.XMLSyntaxError:
            header_status = 'malformed_xml'
            root = None
        if header_status != 'ok':
            issues.append(dict(doc_id=str(rel.with_suffix('')), status=header_status))
        def value(xpath):
            if root is None:
                return []
            return [''.join(e.itertext()).strip() for e in root.findall(xpath, ns)]
        title = value('g:fileDesc/g:sourceDesc/g:title')
        edition = value('g:fileDesc/g:sourceDesc/g:edition')
        publisher = value('g:fileDesc/g:sourceDesc/g:publisher')
        extent = root.find('g:fileDesc/g:extent', ns) if root is not None else None
        rows.append(dict(doc_id=str(rel.with_suffix('')), writer_id='', task='',
            genre=rel.parts[2], group='spoken' if rel.parts[1]=='spoken' else 'written',
            collection='/'.join(rel.parts[2:-1]), source_title=title, source_edition=edition,
            authors=value('g:fileDesc/g:sourceDesc/g:author'), publisher=publisher,
            domain=value('g:profileDesc/g:textClass/g:domain'),
            declared_words=extent.get('wordCount', '') if extent is not None else '',
            source_sha256=sha(data), header_sha256=sha(header.read_bytes()), header_status=header_status,
            source_path=str(path.relative_to(folder)), text=data.decode('utf-8-sig')))
    assert len(rows) == 8824
else:
    raise ValueError(corpus)

assert len({x['doc_id'] for x in rows}) == len(rows)
for row in rows:
    row['corpus'] = corpus
    row['text_sha256'] = sha(row['text'].encode('utf-8'))
    assert row['text'].strip(), row['doc_id']
with (folder / 'extracted-private.jsonl').open('w') as out:
    for row in rows:
        out.write(json.dumps(row, ensure_ascii=False) + '\n')
report = dict(corpus=corpus, documents=len(rows),
    writers=len({x['writer_id'] for x in rows if x['writer_id']}),
    groups=dict(Counter(x['group'] for x in rows)),
    genres=dict(Counter(x['genre'] for x in rows)),
    exact_duplicate_texts=len(rows)-len({x['text_sha256'] for x in rows}),
    source_inventory_sha256=sha(json.dumps([(x['doc_id'], x['source_sha256']) for x in rows]).encode()))
(folder / 'source-issues-private.json').write_text(json.dumps(issues, indent=2))
report['metadata_issues'] = dict(Counter(x['status'] for x in issues))
(folder / 'source-inventory-summary.json').write_text(json.dumps(report, indent=2))
print(json.dumps(report, indent=2))
