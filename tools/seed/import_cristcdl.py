#!/usr/bin/env python3
"""
Convert the cristcdl_scraper JSON dump into questions.csv + answers.csv
matching the existing seed format.

Usage:
    python3 tools/seed/import_cristcdl.py \
        --in /Users/ceejay/Documents/cristcdl_scraper/cristcdl_data \
        --out tools/seed/cristcdl

Output:
    <out>/questions.csv  — header: external_id,license_code,state_code,category_code,text,explanation,image_name,difficulty,lang
    <out>/answers.csv    — header: question_external_id,text,is_correct,sort_order

- All questions are filed under license_code='cdl' and state_code='' (federal).
- Dedupe is GLOBAL by normalized text: each unique question appears exactly
  once across all topics. First-seen wins (quiz files scanned in sorted
  filename order for determinism). Cross-topic drops are logged so the
  categorization choice is auditable.
- external_id format: CDL-<topic_prefix>-<NNNN>  (stable within a single run,
  but may shift if source content changes — acceptable since IDs are
  rebuilt each seed).
"""
from __future__ import annotations

import argparse
import csv
import json
import re
import sys
from collections import defaultdict
from pathlib import Path
from typing import Dict, List, Tuple

# scraper topic slug -> our categories.code  (matches tools/seed/sample/categories.csv)
TOPIC_MAP = {
    'general-knowledge':   'general_knowledge',
    'air-brakes':          'air_brakes',
    'combination':         'combination_vehicles',
    'hazardous-material':  'hazmat',
    'tanker':              'tanker',
    'doubles-triples':     'doubles_triples',
    'passenger':           'passenger',
    'school-bus':          'school_bus',
    'pretrip':             'pre_trip',
}

# Short prefix for external_id so they read nicely in CSV.
TOPIC_PREFIX = {
    'general-knowledge':   'GK',
    'air-brakes':          'AB',
    'combination':         'CV',
    'hazardous-material':  'HZ',
    'tanker':              'TK',
    'doubles-triples':     'DT',
    'passenger':           'PS',
    'school-bus':          'SB',
    'pretrip':             'PT',
}


def normalize(text: str) -> str:
    """Dedup key helper — lowercase, collapse whitespace, strip trailing punctuation."""
    return re.sub(r'\s+', ' ', text.strip().lower()).rstrip('.?!')


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--in', dest='in_dir', required=True, help='cristcdl_data directory')
    parser.add_argument('--out', required=True, help='Output dir (questions.csv + answers.csv)')
    args = parser.parse_args()

    in_dir = Path(args.in_dir)
    out_dir = Path(args.out)
    quizzes_dir = in_dir / 'quizzes'

    if not quizzes_dir.is_dir():
        print(f"[import] ERROR quizzes dir not found: {quizzes_dir}", file=sys.stderr)
        return 1
    out_dir.mkdir(parents=True, exist_ok=True)

    # Load all quiz files sorted for deterministic external_ids across runs.
    quiz_files = sorted(quizzes_dir.glob('*.json'))
    if not quiz_files:
        print(f"[import] ERROR no quiz JSON files under {quizzes_dir}", file=sys.stderr)
        return 1

    # Global dedup: normalized_text -> topic-of-first-occurrence.
    seen: Dict[str, str] = {}
    per_topic_counter: Dict[str, int] = defaultdict(int)
    per_topic_kept: Dict[str, int] = defaultdict(int)
    per_topic_dropped_intra: Dict[str, int] = defaultdict(int)
    per_topic_dropped_cross: Dict[str, int] = defaultdict(int)
    # Human-readable log of cross-topic drops for auditing.
    cross_topic_drops: List[Tuple[str, str, str]] = []   # (dropped_topic, kept_topic, text_preview)

    questions_rows: List[List[str]] = []
    answers_rows: List[List[str]] = []

    for quiz_path in quiz_files:
        data = json.loads(quiz_path.read_text(encoding='utf-8'))
        topic = data.get('topic') or ''
        category_code = TOPIC_MAP.get(topic)
        if category_code is None:
            print(f"[import] SKIP unknown topic '{topic}' in {quiz_path.name}", file=sys.stderr)
            continue
        prefix = TOPIC_PREFIX[topic]

        for q in data.get('questions', []):
            text = (q.get('question') or '').strip()
            if not text:
                continue
            key = normalize(text)
            if key in seen:
                prev_topic = seen[key]
                if prev_topic == topic:
                    per_topic_dropped_intra[topic] += 1
                else:
                    per_topic_dropped_cross[topic] += 1
                    cross_topic_drops.append((topic, prev_topic, text[:80]))
                continue
            seen[key] = topic

            per_topic_counter[topic] += 1
            per_topic_kept[topic] += 1
            external_id = f"CDL-{prefix}-{per_topic_counter[topic]:04d}"
            explanation = (q.get('explanation') or '').strip()

            questions_rows.append([
                external_id, 'cdl', '', category_code,
                text, explanation, '', '1', 'en'
            ])

            options = q.get('options') or {}
            correct_key = q.get('correct')
            # Preserve a,b,c,d ordering for sort_order.
            for sort_idx, letter in enumerate(sorted(options.keys())):
                answer_text = (options[letter] or '').strip()
                if not answer_text:
                    continue
                is_correct = '1' if letter == correct_key else '0'
                answers_rows.append([external_id, answer_text, is_correct, str(sort_idx)])

    # Write CSVs.
    q_path = out_dir / 'questions.csv'
    a_path = out_dir / 'answers.csv'

    with q_path.open('w', encoding='utf-8', newline='') as f:
        w = csv.writer(f)
        w.writerow(['external_id', 'license_code', 'state_code', 'category_code',
                    'text', 'explanation', 'image_name', 'difficulty', 'lang'])
        w.writerows(questions_rows)

    with a_path.open('w', encoding='utf-8', newline='') as f:
        w = csv.writer(f)
        w.writerow(['question_external_id', 'text', 'is_correct', 'sort_order'])
        w.writerows(answers_rows)

    # Report.
    print(f"[import] wrote {q_path} ({len(questions_rows)} questions)")
    print(f"[import] wrote {a_path} ({len(answers_rows)} answers)")
    print(f"[import] per topic:")
    for topic in sorted(TOPIC_MAP):
        kept = per_topic_kept.get(topic, 0)
        intra = per_topic_dropped_intra.get(topic, 0)
        cross = per_topic_dropped_cross.get(topic, 0)
        if kept or intra or cross:
            print(f"         {topic:<22} kept={kept:>4}  intra-dup={intra:>3}  cross-dup={cross:>3}")
    total_intra = sum(per_topic_dropped_intra.values())
    total_cross = sum(per_topic_dropped_cross.values())
    print(f"[import] totals: kept={sum(per_topic_kept.values())}  "
          f"intra-dup={total_intra}  cross-dup={total_cross}")

    if cross_topic_drops:
        print(f"[import] cross-topic drops (kept in first-seen topic):")
        for dropped_topic, kept_topic, preview in cross_topic_drops:
            print(f"         [{dropped_topic}] duplicates [{kept_topic}]: \"{preview}...\"")
    return 0


if __name__ == '__main__':
    sys.exit(main())
