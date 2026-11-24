"""Build the Shady Meadows SQLite database and run every query in queries.sql.

Usage:
    python3 run.py              # prints each result as a Markdown table
    python3 run.py --out FILE   # also writes the results to FILE
    python3 run.py --check      # compares the data-quality summary with the expected findings

Needs only Python 3 (sqlite3 is part of the standard library).
"""
import re
import sqlite3
import sys
from pathlib import Path

HERE = Path(__file__).parent
DB = HERE / "shady_meadows.db"


def build_db() -> sqlite3.Connection:
    if DB.exists():
        DB.unlink()
    con = sqlite3.connect(DB)
    con.executescript((HERE / "schema.sql").read_text(encoding="utf-8"))
    con.executescript((HERE / "seed.sql").read_text(encoding="utf-8"))
    con.commit()
    return con


def split_queries(sql: str):
    """Yield (name, comment, query) for each '-- name:' block."""
    blocks = re.split(r"^-- name: ", sql, flags=re.M)[1:]
    for block in blocks:
        name, _, rest = block.partition("\n")
        lines = rest.splitlines()
        comment = [l[3:] for l in lines if l.startswith("-- ")]
        query = "\n".join(l for l in lines if not l.startswith("--")).strip()
        yield name.strip(), comment, query


def to_markdown(cols, rows) -> str:
    if not rows:
        return "_(no rows)_"
    fmt = lambda v: "NULL" if v is None else str(v)
    out = ["| " + " | ".join(cols) + " |", "|" + "---|" * len(cols)]
    out += ["| " + " | ".join(fmt(v) for v in r) + " |" for r in rows]
    return "\n".join(out)


# Expected findings for the seed data (the "oracle" for this dataset).
# If someone edits seed.sql or a query, `python3 run.py --check` shows what changed.
EXPECTED = {
    "Q01 overlapping pairs": 3,
    "Q02 invalid date ranges": 2,
    "Q03 names with digits": 2,
    "Q04 form rule violations": 4,
    "Q05 probable double submits": 1,
    "Q06 orphan bookings": 1,
    "Q07 booked after stay started": 1,
}


def check(con) -> int:
    sql = (HERE / "queries.sql").read_text(encoding="utf-8")
    summary_sql = next(q for n, _, q in split_queries(sql) if n == "Q12_data_quality_summary")
    summary = dict(con.execute(summary_sql).fetchall())
    failures = 0
    for name, expected in EXPECTED.items():
        actual = summary.get(name)
        status = "PASS" if actual == expected else "FAIL"
        failures += status == "FAIL"
        print(f"{status}  {name}: expected {expected}, got {actual}")
    print(f"\n{len(EXPECTED) - failures}/{len(EXPECTED)} checks passed")
    return 1 if failures else 0


def main():
    con = build_db()
    if "--check" in sys.argv:
        sys.exit(check(con))
    sql = (HERE / "queries.sql").read_text(encoding="utf-8")
    report = []
    for name, comment, query in split_queries(sql):
        cur = con.execute(query)
        cols = [d[0] for d in cur.description]
        rows = cur.fetchall()
        question = next((c for c in comment if c.startswith("Question:")), "")
        report.append(f"### {name}\n{question}\n\n{to_markdown(cols, rows)}\n")
    text = "\n".join(report)
    print(text)
    if "--out" in sys.argv:
        Path(sys.argv[sys.argv.index("--out") + 1]).write_text(text, encoding="utf-8")


if __name__ == "__main__":
    main()
