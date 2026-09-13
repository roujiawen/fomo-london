#!/usr/bin/env python3
"""
Bootstrap the curated tag hierarchy from an exported tag_hierarchy.json.

A fresh city DB has no curated tags — only keywords the crawl produces — so the
export audit fails and filters are empty. The curated event/venue taxonomy is
city-agnostic (Jazz, Ballet, Dive Bar, Museum apply anywhere), so we seed it from
fomo.nyc's live export (fomo.nyc/data/tag_hierarchy.json), which carries name,
scope, emoji, parents, aliases and icon_id for every tag.

Skips the venue 'Neighborhood' family (NYC-specific geography) so a London app
doesn't show NYC neighborhoods; the Neighborhood root is kept as an empty
structural root. Once loaded, re-run the pipeline: processing maps crawl keywords
onto these curated tags via aliases and backfills ancestors, wiring events to the
filters automatically.

Idempotent (ON DUPLICATE KEY / INSERT IGNORE). Reads DB creds from the same
env/.env as the pipeline (pipeline/db.py).

Usage:
    ./.venv/bin/python deploy/import_tag_hierarchy.py path/to/tag_hierarchy.json
"""
import json
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'pipeline'))
from dotenv import load_dotenv  # noqa: E402
load_dotenv()
import db  # noqa: E402


def _neighborhood_family(tags):
    """Venue tag names that are descendants of 'Neighborhood' (NYC geography)."""
    children = {}
    for t in tags:
        if t.get('scope') != 'venue':
            continue
        for p in t.get('parents') or []:
            children.setdefault(p, []).append(t['name'])
    skip, stack = set(), ['Neighborhood']
    while stack:
        cur = stack.pop()
        for c in children.get(cur, []):
            if c not in skip:
                skip.add(c)
                stack.append(c)
    return skip  # excludes the 'Neighborhood' root itself (kept)


def main(path):
    data = json.load(open(path))
    tags = data['tags']
    skip = _neighborhood_family(tags)
    keep = [t for t in tags if not (t.get('scope') == 'venue' and t['name'] in skip)]
    print(f"source tags: {len(tags)} | skipping {len(skip)} NYC-neighborhood venue tags | loading {len(keep)}")

    conn = db.create_connection()
    if not conn:
        print("FAIL: no DB connection")
        return 1
    cur = conn.cursor()

    # 1. Upsert curated tags (promotes an existing keyword of the same name+scope).
    for t in keep:
        cur.execute(
            "INSERT INTO tags (name, scope, type, emoji, icon_id, is_quick_filter, display_order) "
            "VALUES (%s,%s,'tag',%s,%s,%s,%s) "
            "ON DUPLICATE KEY UPDATE type='tag', emoji=VALUES(emoji), icon_id=VALUES(icon_id), "
            "is_quick_filter=VALUES(is_quick_filter), display_order=VALUES(display_order)",
            (t['name'], t['scope'], t.get('emoji'), t.get('icon_id'),
             1 if t.get('quickFilter') else 0, t.get('order')))
    conn.commit()

    # id lookup by (name, scope)
    cur.execute("SELECT id, name, scope FROM tags")
    ids = {(name, scope): tid for tid, name, scope in cur.fetchall()}

    # 2. Hierarchy edges (within scope)
    edges = 0
    for t in keep:
        cid = ids.get((t['name'], t['scope']))
        for p in t.get('parents') or []:
            pid = ids.get((p, t['scope']))
            if pid and cid:
                cur.execute("INSERT IGNORE INTO tag_hierarchy (parent_tag_id, child_tag_id) VALUES (%s,%s)", (pid, cid))
                edges += cur.rowcount
    conn.commit()

    # 3. Aliases (scope-keyed; PK is (scope, alias) so first writer wins)
    aliases = 0
    for t in keep:
        tid = ids.get((t['name'], t['scope']))
        if not tid:
            continue
        for a in t.get('aliases') or []:
            cur.execute("INSERT IGNORE INTO tag_aliases (tag_id, alias, scope) VALUES (%s,%s,%s)", (tid, a, t['scope']))
            aliases += cur.rowcount
    conn.commit()

    cur.execute("SELECT COUNT(*) FROM tags WHERE type='tag'")
    curated = cur.fetchone()[0]
    print(f"done: {curated} curated tags, {edges} hierarchy edges, {aliases} aliases")
    cur.close()
    conn.close()
    return 0


if __name__ == '__main__':
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(2)
    sys.exit(main(sys.argv[1]))
