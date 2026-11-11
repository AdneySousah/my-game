#!/usr/bin/env python3
"""Rewrites data JSON files in a compact, readable style:
short lists (coordinates, id lists) stay on one line, objects keep 2-space indent.

  python -X utf8 tools/format_json.py data/maps/*.json
"""
import json
import sys
from pathlib import Path

INLINE_MAX = 100


def fmt(value, indent: int = 0) -> str:
    pad = " " * indent
    inner = " " * (indent + 2)
    flat = json.dumps(value, ensure_ascii=False)
    if isinstance(value, (list, dict)) and len(flat) + indent <= INLINE_MAX and not _has_nested_dict_list(value):
        return flat.replace('{"', '{ "').replace('"}', '" }').replace(']}', '] }') if isinstance(value, dict) else flat
    if isinstance(value, dict):
        items = [f'{inner}{json.dumps(k, ensure_ascii=False)}: {fmt(v, indent + 2)}' for k, v in value.items()]
        return "{\n" + ",\n".join(items) + f"\n{pad}}}"
    if isinstance(value, list):
        if all(not isinstance(v, (list, dict)) or len(json.dumps(v)) < 40 for v in value) and len(flat) <= INLINE_MAX * 2:
            return flat
        items = [inner + fmt(v, indent + 2) for v in value]
        return "[\n" + ",\n".join(items) + f"\n{pad}]"
    return flat


def _has_nested_dict_list(value) -> bool:
    if isinstance(value, list):
        return any(isinstance(v, dict) and len(json.dumps(v)) > 60 for v in value)
    return False


def main() -> None:
    for name in sys.argv[1:]:
        path = Path(name)
        data = json.loads(path.read_text(encoding="utf-8"))
        path.write_text(fmt(data) + "\n", encoding="utf-8", newline="\n")
        json.loads(path.read_text(encoding="utf-8"))
        print(f"ok {path}")


if __name__ == "__main__":
    main()
