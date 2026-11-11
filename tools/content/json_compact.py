"""Grava JSON dos mapas no formato do projeto: objetos em várias linhas, mas listas de
números e objetos pequenos numa linha só. Uso: python -X utf8 tools/content/json_compact.py <arquivo.json> ..."""
import json
import sys


def _inline(v) -> str:
    return json.dumps(v, ensure_ascii=False, separators=(", ", ": "))


def _fmt(v, ind: int) -> str:
    pad = "  " * ind
    if isinstance(v, dict):
        one = _inline(v)
        if len(one) <= 110 and not any(isinstance(x, (dict, list)) and len(_inline(x)) > 60 for x in v.values()):
            return one
        items = [f'{pad}  {json.dumps(k, ensure_ascii=False)}: {_fmt(x, ind + 1)}' for k, x in v.items()]
        return "{\n" + ",\n".join(items) + "\n" + pad + "}"
    if isinstance(v, list):
        one = _inline(v)
        if len(one) <= 110 and all(not isinstance(x, dict) for x in v):
            return one
        items = [f"{pad}  {_fmt(x, ind + 1)}" for x in v]
        return "[\n" + ",\n".join(items) + "\n" + pad + "]"
    return _inline(v)


def write(path: str, data) -> None:
    with open(path, "w", encoding="utf-8") as f:
        f.write(_fmt(data, 0) + "\n")


if __name__ == "__main__":
    for p in sys.argv[1:]:
        write(p, json.load(open(p, encoding="utf-8")))
        print("ok:", p)
