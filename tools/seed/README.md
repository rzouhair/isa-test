# Exam content seeder

Builds `isaprep/Resources/exam_content.sqlite` from CSVs in `sample/`.

## Run

```bash
python3 tools/seed/seed.py --out isaprep/Resources/exam_content.sqlite
```

## Add / edit content

1. Edit or add rows to the CSVs in `sample/`.
2. For long-form text (handbook body, cheat sheet markdown), drop a `.md` file in `sample/` and reference it via `body_md_file`.
3. Re-run the seed command.
4. Rebuild the app — the new `.sqlite` is copied from the bundle into Caches on next launch.

## Files

| CSV              | Columns                                                                              |
|------------------|--------------------------------------------------------------------------------------|
| `licenses.csv`   | `code,name,icon`                                                                     |
| `states.csv`     | `code,name`                                                                          |
| `categories.csv` | `license_code,code,name,kind,sort_order`                                             |
| `questions.csv`  | `external_id,license_code,state_code,category_code,text,explanation,image_name,difficulty,lang` |
| `answers.csv`    | `question_external_id,text,is_correct,sort_order`                                    |
| `cheat_sheets.csv` | `license_code,state_code,title,body_md_file,cover_image,lang`                      |
| `handbooks.csv`  | `state_code,license_code,title,pdf_name,body_md_file,version,lang`                   |
| `exam_specs.csv` | `state_code,license_code,category_code,question_count,pass_threshold,time_limit_sec` |

## Rules

- `state_code` blank in `questions.csv` / `cheat_sheets.csv` → common across states.
- `category_code` blank in `exam_specs.csv` → mixed exam (not category-scoped).
- `external_id` in `questions.csv` is only used to join `answers.csv`; final SQLite uses auto-increment IDs.
- Schema is re-applied from `schema.sql` on every run (output file is dropped first).
