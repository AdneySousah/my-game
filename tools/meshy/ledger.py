#!/usr/bin/env python3
"""Meshy credit ledger and asset tracker.

Keeps tools/meshy/assets.json as the single source of truth for every
Meshy asset: what is planned, what was spent, and where it is in review.

Usage:
  python tools/meshy/ledger.py report
  python tools/meshy/ledger.py add <id> --category enm --phase 3 --prompt "..." [--method mcp|web]
  python tools/meshy/ledger.py spend <id> <task_type> <credits> [--task-id X] [--date YYYY-MM-DD]
  python tools/meshy/ledger.py status <id> <status> [--file path] [--note "..."]
  python tools/meshy/ledger.py can-spend <credits>
  python tools/meshy/ledger.py validate
"""
from __future__ import annotations

import argparse
import json
import sys
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DB = Path(__file__).resolve().parent / "assets.json"

STATUSES = ("planned", "generating", "review", "approved", "rejected", "imported")
CATEGORIES = {
    "hero": "assets/characters",
    "cos": "assets/characters",
    "enm": "assets/enemies",
    "boss": "assets/enemies",
    "npc": "assets/npcs",
    "prp": "assets/props",
    "env": "assets/environment",
}


def load() -> dict:
    with DB.open(encoding="utf-8") as f:
        return json.load(f)


def save(db: dict) -> None:
    with DB.open("w", encoding="utf-8", newline="\n") as f:
        json.dump(db, f, ensure_ascii=False, indent=2)
        f.write("\n")


def find(db: dict, asset_id: str) -> dict:
    for a in db["assets"]:
        if a["id"] == asset_id:
            return a
    sys.exit(f"erro: asset '{asset_id}' não existe. Use 'add' primeiro.")


def cycle_start(today: date, start_day: int) -> date:
    """First day of the current Meshy billing cycle."""
    if today.day >= start_day:
        return today.replace(day=start_day)
    year, month = (today.year, today.month - 1) if today.month > 1 else (today.year - 1, 12)
    return date(year, month, start_day)


def spent_this_cycle(db: dict, today: date) -> int:
    start = cycle_start(today, db["budget"]["cycle_start_day"]).isoformat()
    return sum(
        t["credits"]
        for a in db["assets"]
        for t in a["tasks"]
        if t["date"] >= start
    )


def available(db: dict, today: date) -> int:
    b = db["budget"]
    return b["monthly_credits"] - b["reserve"] - spent_this_cycle(db, today)


def cmd_report(db: dict, _: argparse.Namespace) -> None:
    today = date.today()
    b = db["budget"]
    spent = spent_this_cycle(db, today)
    total = sum(t["credits"] for a in db["assets"] for t in a["tasks"])
    start = cycle_start(today, b["cycle_start_day"])
    print(f"Ciclo desde {start.isoformat()}: gastos {spent} de {b['monthly_credits']} "
          f"(reserva {b['reserve']}) -> disponível {available(db, today)}")
    print(f"Total gasto no projeto: {total}")
    counts = {s: 0 for s in STATUSES}
    for a in db["assets"]:
        counts[a["status"]] += 1
    print("Assets: " + ", ".join(f"{s} {n}" for s, n in counts.items()))
    phases = sorted({a["phase"] for a in db["assets"]})
    for p in phases:
        items = [a for a in db["assets"] if a["phase"] == p]
        cost = sum(t["credits"] for a in items for t in a["tasks"])
        print(f"  Fase {p}: {len(items)} assets, {cost} créditos")
        for a in items:
            c = sum(t["credits"] for t in a["tasks"])
            print(f"    - {a['id']:<28} {a['status']:<10} {a['method']:<4} {c:>4} cr")


def cmd_add(db: dict, args: argparse.Namespace) -> None:
    if args.category not in CATEGORIES:
        sys.exit(f"erro: categoria deve ser uma de {', '.join(CATEGORIES)}")
    if not args.id.startswith(args.category + "_"):
        sys.exit(f"erro: o id deve começar com '{args.category}_'")
    if any(a["id"] == args.id for a in db["assets"]):
        sys.exit(f"erro: asset '{args.id}' já existe")
    db["assets"].append({
        "id": args.id,
        "category": args.category,
        "phase": args.phase,
        "method": args.method,
        "status": "planned",
        "prompt": args.prompt,
        "file": f"{CATEGORIES[args.category]}/{args.id}/{args.id}.glb",
        "tasks": [],
        "notes": [],
    })
    save(db)
    print(f"ok: {args.id} planejado (fase {args.phase}, {args.method})")


def cmd_spend(db: dict, args: argparse.Namespace) -> None:
    a = find(db, args.id)
    a["tasks"].append({
        "type": args.task_type,
        "credits": args.credits,
        "task_id": args.task_id,
        "date": args.date or date.today().isoformat(),
    })
    if a["status"] == "planned":
        a["status"] = "generating"
    save(db)
    print(f"ok: {args.credits} créditos registrados em {args.id}. "
          f"Disponível no ciclo: {available(db, date.today())}")


def cmd_status(db: dict, args: argparse.Namespace) -> None:
    if args.status not in STATUSES:
        sys.exit(f"erro: status deve ser um de {', '.join(STATUSES)}")
    a = find(db, args.id)
    a["status"] = args.status
    if args.file:
        a["file"] = args.file
    if args.note:
        a["notes"].append(f"{date.today().isoformat()}: {args.note}")
    save(db)
    print(f"ok: {args.id} -> {args.status}")


def cmd_can_spend(db: dict, args: argparse.Namespace) -> None:
    left = available(db, date.today())
    if args.credits <= left:
        print(f"SIM: {args.credits} cabem (disponível {left})")
        return
    print(f"NAO: {args.credits} passam do disponível ({left}). Espere o próximo ciclo ou peça aprovação.")
    sys.exit(1)


def cmd_validate(db: dict, _: argparse.Namespace) -> None:
    problems = 0
    for a in db["assets"]:
        if a["status"] in ("approved", "imported") and not (ROOT / a["file"]).exists():
            print(f"falta arquivo: {a['id']} -> {a['file']}")
            problems += 1
    print("ok: tudo certo" if problems == 0 else f"{problems} problema(s)")
    sys.exit(1 if problems else 0)


def main() -> None:
    p = argparse.ArgumentParser(description="Controle de créditos e assets do Meshy")
    sub = p.add_subparsers(dest="cmd", required=True)

    sub.add_parser("report")

    a = sub.add_parser("add")
    a.add_argument("id")
    a.add_argument("--category", required=True)
    a.add_argument("--phase", type=int, required=True)
    a.add_argument("--prompt", required=True)
    a.add_argument("--method", choices=("mcp", "web"), default="mcp")

    s = sub.add_parser("spend")
    s.add_argument("id")
    s.add_argument("task_type", help="ex.: text-to-image, image-to-3d, text-to-3d, remesh, rigging, animation, retexture")
    s.add_argument("credits", type=int)
    s.add_argument("--task-id")
    s.add_argument("--date")

    st = sub.add_parser("status")
    st.add_argument("id")
    st.add_argument("status")
    st.add_argument("--file")
    st.add_argument("--note")

    c = sub.add_parser("can-spend")
    c.add_argument("credits", type=int)

    sub.add_parser("validate")

    for stream in (sys.stdout, sys.stderr):
        stream.reconfigure(encoding="utf-8")
    args = p.parse_args()
    db = load()
    {
        "report": cmd_report,
        "add": cmd_add,
        "spend": cmd_spend,
        "status": cmd_status,
        "can-spend": cmd_can_spend,
        "validate": cmd_validate,
    }[args.cmd](db, args)


if __name__ == "__main__":
    main()
