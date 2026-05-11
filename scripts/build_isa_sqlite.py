#!/usr/bin/env python3
"""Build isaprep/Resources/exam_content.sqlite from ISA JSON sources.

Reads:
  /Users/ceejay/Developer/Scripts/cristcdl_scraper/tasks/exports/isa_quiz.json
  /Users/ceejay/Developer/Scripts/cristcdl_scraper/tasks/exports/isa_flashcards_atomic.json

Writes:
  isaprep/Resources/exam_content.sqlite

Schema is the same as the legacy CDL DB (so the existing Swift wrapper keeps
working) with two relaxations and one addition:
  * `questions.state_id` stays nullable; we always store NULL.
  * `exam_specs.state_id` is made nullable and we store NULL.
  * NEW table `flashcards` for the atomic study-card feature.

`states`, `cheat_sheets`, `handbooks` tables are created empty for source
compatibility but left unused.
"""

import json
import os
import sqlite3
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
QUIZ_JSON = "/Users/ceejay/Developer/Scripts/cristcdl_scraper/tasks/exports/isa_quiz.json"
CARDS_JSON = "/Users/ceejay/Developer/Scripts/cristcdl_scraper/tasks/exports/isa_flashcards_atomic.json"
OUT_SQLITE = os.path.join(ROOT, "isaprep", "Resources", "exam_content.sqlite")

LICENSE_CODE = "isa"
LICENSE_NAME = "ISA Certified Arborist"
LICENSE_ICON = "leaf.fill"

# Display order for topics (matches competitor app + visual variety).
TOPIC_ORDER = [
    "Tree Biology",
    "Identification and Selection",
    "Soil Management",
    "Installation and Establishment",
    "Pruning",
    "Diagnosis and Treatment",
    "Tree Protection",
    "Tree Risk Management",
    "Safe Work Practices",
    "Urban Forestry",
]


def topic_to_code(topic: str) -> str:
    return topic.lower().replace(" ", "_").replace("-", "_")


def main() -> int:
    if os.path.exists(OUT_SQLITE):
        os.remove(OUT_SQLITE)

    quiz = json.load(open(QUIZ_JSON))
    cards = json.load(open(CARDS_JSON))

    conn = sqlite3.connect(OUT_SQLITE)
    cur = conn.cursor()

    cur.executescript(
        """
        CREATE TABLE licenses (
          id   INTEGER PRIMARY KEY,
          code TEXT UNIQUE NOT NULL,
          name TEXT NOT NULL,
          icon TEXT
        );
        CREATE TABLE states (
          id   INTEGER PRIMARY KEY,
          code TEXT UNIQUE NOT NULL,
          name TEXT NOT NULL
        );
        CREATE TABLE categories (
          id         INTEGER PRIMARY KEY,
          license_id INTEGER NOT NULL REFERENCES licenses(id),
          code       TEXT NOT NULL,
          name       TEXT NOT NULL,
          kind       TEXT NOT NULL,
          sort_order INTEGER DEFAULT 0,
          UNIQUE(license_id, code)
        );
        CREATE TABLE questions (
          id          INTEGER PRIMARY KEY,
          license_id  INTEGER NOT NULL REFERENCES licenses(id),
          category_id INTEGER NOT NULL REFERENCES categories(id),
          state_id    INTEGER REFERENCES states(id),
          text        TEXT NOT NULL,
          explanation TEXT,
          image_name  TEXT,
          difficulty  INTEGER DEFAULT 1,
          lang        TEXT NOT NULL DEFAULT 'en'
        );
        CREATE INDEX idx_q_lookup ON questions(license_id, category_id, state_id, lang);
        CREATE TABLE answers (
          id          INTEGER PRIMARY KEY,
          question_id INTEGER NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
          text        TEXT NOT NULL,
          is_correct  INTEGER NOT NULL DEFAULT 0,
          sort_order  INTEGER DEFAULT 0
        );
        CREATE INDEX idx_a_q ON answers(question_id);
        CREATE TABLE cheat_sheets (
          id          INTEGER PRIMARY KEY,
          license_id  INTEGER NOT NULL REFERENCES licenses(id),
          state_id    INTEGER REFERENCES states(id),
          title       TEXT NOT NULL,
          body_md     TEXT NOT NULL,
          cover_image TEXT,
          lang        TEXT NOT NULL DEFAULT 'en'
        );
        CREATE TABLE handbooks (
          id         INTEGER PRIMARY KEY,
          state_id   INTEGER REFERENCES states(id),
          license_id INTEGER NOT NULL REFERENCES licenses(id),
          title      TEXT NOT NULL,
          pdf_name   TEXT,
          body_md    TEXT,
          version    TEXT,
          lang       TEXT NOT NULL DEFAULT 'en'
        );
        CREATE TABLE exam_specs (
          id             INTEGER PRIMARY KEY,
          state_id       INTEGER REFERENCES states(id),
          license_id     INTEGER NOT NULL REFERENCES licenses(id),
          category_id    INTEGER REFERENCES categories(id),
          question_count INTEGER NOT NULL,
          pass_threshold REAL NOT NULL,
          time_limit_sec INTEGER
        );
        CREATE TABLE flashcards (
          id          INTEGER PRIMARY KEY,
          license_id  INTEGER NOT NULL REFERENCES licenses(id),
          category_id INTEGER NOT NULL REFERENCES categories(id),
          type        TEXT NOT NULL,
          front       TEXT NOT NULL,
          back        TEXT NOT NULL,
          tags_json   TEXT,
          source      TEXT,
          sort_order  INTEGER DEFAULT 0,
          lang        TEXT NOT NULL DEFAULT 'en'
        );
        CREATE INDEX idx_fc_lookup ON flashcards(license_id, category_id, lang);
        """
    )

    cur.execute(
        "INSERT INTO licenses(id, code, name, icon) VALUES (?,?,?,?)",
        (1, LICENSE_CODE, LICENSE_NAME, LICENSE_ICON),
    )
    license_id = 1

    cat_id_by_topic = {}
    for i, topic in enumerate(TOPIC_ORDER, start=1):
        cur.execute(
            "INSERT INTO categories(id, license_id, code, name, kind, sort_order) VALUES (?,?,?,?,?,?)",
            (i, license_id, topic_to_code(topic), topic, "core", i * 10),
        )
        cat_id_by_topic[topic] = i

    # Difficulty heuristic: generated == easy(1), xlsx == medium(2), isa.json == hard(3).
    diff_by_source = {"generated": 1, "xlsx": 2, "isa.json": 3}

    for q in quiz["questions"]:
        cat_id = cat_id_by_topic[q["topic"]]
        cur.execute(
            "INSERT INTO questions(id, license_id, category_id, state_id, text, explanation, image_name, difficulty, lang) "
            "VALUES (?,?,?,?,?,?,?,?,?)",
            (
                q["id"],
                license_id,
                cat_id,
                None,
                q["question"],
                q.get("explanation"),
                None,
                diff_by_source.get(q.get("source", ""), 1),
                "en",
            ),
        )
        for idx, ch in enumerate(q["choices"]):
            cur.execute(
                "INSERT INTO answers(question_id, text, is_correct, sort_order) VALUES (?,?,?,?)",
                (q["id"], ch["text"], 1 if ch["correct"] else 0, idx),
            )

    for c in cards["cards"]:
        cat_id = cat_id_by_topic[c["topic"]]
        cur.execute(
            "INSERT INTO flashcards(id, license_id, category_id, type, front, back, tags_json, source, sort_order, lang) "
            "VALUES (?,?,?,?,?,?,?,?,?,?)",
            (
                c["id"],
                license_id,
                cat_id,
                c["type"],
                c["front"],
                c["back"],
                json.dumps(c.get("tags", [])),
                c.get("source"),
                c["id"],
                "en",
            ),
        )

    # Full-exam spec: 200 random questions, 76% pass, 210 minutes.
    cur.execute(
        "INSERT INTO exam_specs(state_id, license_id, category_id, question_count, pass_threshold, time_limit_sec) "
        "VALUES (?,?,?,?,?,?)",
        (None, license_id, None, 200, 0.76, 210 * 60),
    )

    conn.commit()

    n_q = cur.execute("SELECT COUNT(*) FROM questions").fetchone()[0]
    n_a = cur.execute("SELECT COUNT(*) FROM answers").fetchone()[0]
    n_fc = cur.execute("SELECT COUNT(*) FROM flashcards").fetchone()[0]
    n_cat = cur.execute("SELECT COUNT(*) FROM categories").fetchone()[0]
    print(f"OK -> {OUT_SQLITE}")
    print(f"  questions: {n_q}, answers: {n_a}, flashcards: {n_fc}, categories: {n_cat}")
    conn.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
