#!/usr/bin/env python3
"""Generate data/progression/xp_table.json from the GDD curve.

Time per level m(L) = BASE + C * L**P minutes, fitted so level 100 takes
TOTAL_HOURS. XP to next level = m(L) * KILLS_PER_MIN * mob_xp(L).
Re-run after changing any constant: python tools/balance/gen_xp.py
"""
import json
from pathlib import Path

LEVEL_CAP = 100
TOTAL_HOURS = 30
BASE_MIN = 4.0
POWER = 1.5
KILLS_PER_MIN = 6
MOB_XP_BASE = 10
MOB_XP_GROWTH = 1.055

OUT = Path(__file__).resolve().parents[2] / "data" / "progression" / "xp_table.json"


def mob_xp(level: int) -> int:
    return round(MOB_XP_BASE * MOB_XP_GROWTH ** (level - 1))


def nice(value: float) -> int:
    """Round to 2 significant digits so numbers read well in game."""
    mag = 10 ** max(1, len(str(int(value))) - 2)
    return int(round(value / mag) * mag)


def main() -> None:
    levels = range(1, LEVEL_CAP)
    c = (TOTAL_HOURS * 60 - BASE_MIN * len(levels)) / sum(l ** POWER for l in levels)
    xp_to_next = [nice((BASE_MIN + c * l ** POWER) * KILLS_PER_MIN * mob_xp(l)) for l in levels]
    data = {
        "_comment": "Gerado por tools/balance/gen_xp.py. Não editar à mão.",
        "xp_to_next": xp_to_next,
        "mob_xp": [mob_xp(l) for l in range(1, LEVEL_CAP + 1)],
    }
    OUT.write_text(json.dumps(data, ensure_ascii=False) + "\n", encoding="utf-8", newline="\n")
    print(f"ok: {len(xp_to_next)} níveis, total {sum(xp_to_next):,} XP -> {OUT}")


if __name__ == "__main__":
    main()
