#!/usr/bin/env python3
"""
Build exam_content.sqlite from CSVs in sample/.

Usage:
    python3 tools/seed/seed.py --out examprep/Resources/exam_content.sqlite

CSV formats (sample/ dir):
  - licenses.csv:    code,name,icon
  - states.csv:      code,name
  - categories.csv:  license_code,code,name,kind,sort_order
  - questions.csv:   external_id,license_code,state_code,category_code,text,explanation,image_name,difficulty,lang
                     (state_code blank → federal/common)
  - answers.csv:     question_external_id,text,is_correct,sort_order
  - cheat_sheets.csv: license_code,state_code,title,body_md_file,cover_image,lang
                     (body_md_file is a path under sample/ for the markdown body)
  - handbooks.csv:   state_code,license_code,title,pdf_name,body_md_file,version,lang
  - exam_specs.csv:  state_code,license_code,category_code,question_count,pass_threshold,time_limit_sec
                     (category_code blank → mixed)

External IDs in questions.csv/answers.csv are only used to join the two CSVs
at seed time; final SQLite stores numeric auto-increment IDs.
"""
import argparse
import csv
import os
import sqlite3
import sys
from pathlib import Path


def read_csv(path: Path):
    if not path.exists():
        return []
    with path.open(encoding='utf-8', newline='') as f:
        return list(csv.DictReader(f))


def read_file_if_present(path: Path) -> str:
    if not path or not path.exists():
        return ''
    return path.read_text(encoding='utf-8')


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--out', required=True, help='Output .sqlite path')
    parser.add_argument('--root', default=str(Path(__file__).parent), help='Seed root (sample/ must live under it)')
    parser.add_argument('--extras', action='append', default=[],
                        help='Additional directory with questions.csv / answers.csv (repeatable)')
    args = parser.parse_args()

    root = Path(args.root)
    sample = root / 'sample'
    schema_sql = (root / 'schema.sql').read_text()
    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)

    # Each extras dir contributes its own questions.csv + answers.csv.
    # Resolved relative to `root` if not absolute.
    extras_dirs = [Path(e) if Path(e).is_absolute() else (root.parent.parent / e) for e in args.extras]
    for extra in extras_dirs:
        if not extra.exists():
            print(f"[seed] ERROR extras dir not found: {extra}", file=sys.stderr)
            return 1

    if out.exists():
        out.unlink()

    db = sqlite3.connect(out)
    db.executescript(schema_sql)

    # --- licenses
    license_ids = {}
    for row in read_csv(sample / 'licenses.csv'):
        cur = db.execute(
            'INSERT INTO licenses (code, name, icon) VALUES (?, ?, ?)',
            (row['code'], row['name'], row.get('icon') or None),
        )
        license_ids[row['code']] = cur.lastrowid

    # --- states
    state_ids = {}
    for row in read_csv(sample / 'states.csv'):
        cur = db.execute(
            'INSERT INTO states (code, name) VALUES (?, ?)',
            (row['code'], row['name']),
        )
        state_ids[row['code']] = cur.lastrowid

    # --- categories
    category_ids = {}  # (license_code, category_code) -> id
    for row in read_csv(sample / 'categories.csv'):
        license_id = license_ids[row['license_code']]
        cur = db.execute(
            'INSERT INTO categories (license_id, code, name, kind, sort_order) VALUES (?, ?, ?, ?, ?)',
            (license_id, row['code'], row['name'], row['kind'], int(row.get('sort_order') or 0)),
        )
        category_ids[(row['license_code'], row['code'])] = cur.lastrowid

    # --- questions + answers (joined via external_id)
    # Loaded from sample/ first, then any --extras dirs. External IDs must
    # be unique across all sources.
    q_by_ext = {}  # external_id -> question row_id
    question_sources = [sample] + extras_dirs

    for src in question_sources:
        for row in read_csv(src / 'questions.csv'):
            ext = row['external_id']
            if ext in q_by_ext:
                print(f"[seed] ERROR duplicate external_id={ext} (second source: {src})", file=sys.stderr)
                return 1
            license_id = license_ids[row['license_code']]
            state_id = state_ids.get(row.get('state_code') or '') or None
            category_id = category_ids[(row['license_code'], row['category_code'])]
            cur = db.execute(
                """INSERT INTO questions (license_id, category_id, state_id, text, explanation, image_name, difficulty, lang)
                     VALUES (?, ?, ?, ?, ?, ?, ?, ?)""",
                (
                    license_id,
                    category_id,
                    state_id,
                    row['text'],
                    row.get('explanation') or None,
                    row.get('image_name') or None,
                    int(row.get('difficulty') or 1),
                    row.get('lang') or 'en',
                ),
            )
            q_by_ext[ext] = cur.lastrowid

    for src in question_sources:
        for row in read_csv(src / 'answers.csv'):
            ext = row['question_external_id']
            if ext not in q_by_ext:
                print(f"[seed] WARN answer refs unknown question external_id={ext} (source: {src})", file=sys.stderr)
                continue
            db.execute(
                'INSERT INTO answers (question_id, text, is_correct, sort_order) VALUES (?, ?, ?, ?)',
                (
                    q_by_ext[ext],
                    row['text'],
                    int(row.get('is_correct') or 0),
                    int(row.get('sort_order') or 0),
                ),
            )

    # --- cheat_sheets
    for row in read_csv(sample / 'cheat_sheets.csv'):
        license_id = license_ids[row['license_code']]
        state_id = state_ids.get(row.get('state_code') or '') or None
        body_md = read_file_if_present(sample / row['body_md_file']) if row.get('body_md_file') else ''
        db.execute(
            """INSERT INTO cheat_sheets (license_id, state_id, title, body_md, cover_image, lang)
                 VALUES (?, ?, ?, ?, ?, ?)""",
            (license_id, state_id, row['title'], body_md, row.get('cover_image') or None, row.get('lang') or 'en'),
        )

    # --- handbooks
    for row in read_csv(sample / 'handbooks.csv'):
        license_id = license_ids[row['license_code']]
        state_id = state_ids[row['state_code']]
        body_md = read_file_if_present(sample / row['body_md_file']) if row.get('body_md_file') else None
        db.execute(
            """INSERT INTO handbooks (state_id, license_id, title, pdf_name, body_md, version, lang)
                 VALUES (?, ?, ?, ?, ?, ?, ?)""",
            (state_id, license_id, row['title'], row.get('pdf_name') or None, body_md, row.get('version') or None, row.get('lang') or 'en'),
        )

    # --- exam_specs
    for row in read_csv(sample / 'exam_specs.csv'):
        license_id = license_ids[row['license_code']]
        state_id = state_ids[row['state_code']]
        cat_code = row.get('category_code') or ''
        category_id = category_ids.get((row['license_code'], cat_code)) if cat_code else None
        time_limit = row.get('time_limit_sec')
        db.execute(
            """INSERT INTO exam_specs (state_id, license_id, category_id, question_count, pass_threshold, time_limit_sec)
                 VALUES (?, ?, ?, ?, ?, ?)""",
            (
                state_id,
                license_id,
                category_id,
                int(row['question_count']),
                float(row['pass_threshold']),
                int(time_limit) if time_limit else None,
            ),
        )

    db.commit()
    db.close()
    size = os.path.getsize(out)
    print(f"[seed] Wrote {out} ({size} bytes)")
    return 0


if __name__ == '__main__':
    sys.exit(main())
