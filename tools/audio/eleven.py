#!/usr/bin/env python3
"""Gera as músicas e os sons do jogo no ElevenLabs (lista em tools/audio/audio_list.json).

A chave da API NUNCA fica no projeto. O script procura, nesta ordem:
  1. a variável de ambiente ELEVENLABS_API_KEY;
  2. o arquivo Documents/HerdeiroDosCeus_chave/elevenlabs.txt (só a chave, uma linha).

Comandos (rodar na pasta do projeto):
  python -X utf8 tools/audio/eleven.py status              créditos da conta e o que já foi gerado
  python -X utf8 tools/audio/eleven.py custo <ids|--all>   quanto vai custar, sem gerar nada
  python -X utf8 tools/audio/eleven.py gen <ids|--music|--sfx|--all> [--force] [--yes]
  python -X utf8 tools/audio/eleven.py aprovar <id> <versão>
  python -X utf8 tools/audio/eleven.py aprovar-tudo        música: versão 1; efeitos: todas as versões
  python -X utf8 tools/audio/eleven.py ouvir               refaz a página para ouvir tudo

Os arquivos gerados vão para assets/_inbox/audio/<id>_<versão>.mp3 (o Godot e o git ignoram
essa pasta). "aprovar" copia a versão escolhida para assets/audio/ (música em music/<id>.mp3,
efeito em sfx/el/<id>_<versão>.ogg). Gastos ficam em tools/audio/audio_log.json.
"""
import json
import os
import shutil
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LIST = ROOT / "tools" / "audio" / "audio_list.json"
LOG = ROOT / "tools" / "audio" / "audio_log.json"
INBOX = ROOT / "assets" / "_inbox" / "audio"
MUSIC_DIR = ROOT / "assets" / "audio" / "music"
SFX_DIR = ROOT / "assets" / "audio" / "sfx" / "el"
API = "https://api.elevenlabs.io/v1"
KEY_FILE = Path.home() / "Documents" / "HerdeiroDosCeus_chave" / "elevenlabs.txt"
MUSIC_PER_MIN = 900
SFX_EACH = 200
ASK_ABOVE = 5000  # créditos: acima disso, pede --yes


def key() -> str:
    k = os.environ.get("ELEVENLABS_API_KEY", "").strip()
    if not k and KEY_FILE.exists():
        lines = KEY_FILE.read_text(encoding="utf-8-sig").split()
        k = lines[0].strip() if lines else ""
    if not k:
        sys.exit(f"Chave não encontrada. Salve a chave (só ela, uma linha) em:\n  {KEY_FILE}")
    return k


def items() -> list:
    d = json.loads(LIST.read_text(encoding="utf-8"))
    out = []
    for kind in ("music", "sfx"):
        for it in d.get(kind, []):
            it = dict(it)
            it["model"] = d.get("music_model" if kind == "music" else "sfx_model")
            out.append(it)
    return out


def cost(it: dict) -> int:
    if it["kind"] == "music":
        return round(it["seconds"] / 60 * MUSIC_PER_MIN) * it.get("variants", 1)
    return SFX_EACH * it.get("variants", 1)


def pick(args: list) -> list:
    all_items = items()
    if "--all" in args:
        return all_items
    if "--music" in args:
        return [i for i in all_items if i["kind"] == "music"]
    if "--sfx" in args:
        return [i for i in all_items if i["kind"] == "sfx"]
    ids = [a for a in args if not a.startswith("--")]
    by_id = {i["id"]: i for i in all_items}
    bad = [i for i in ids if i not in by_id]
    if bad:
        sys.exit("Não estão na lista: " + ", ".join(bad))
    return [by_id[i] for i in ids]


def request(method: str, path: str, body: dict | None = None, query: str = "") -> tuple[int, bytes]:
    data = json.dumps(body).encode("utf-8") if body is not None else None
    req = urllib.request.Request(API + path + query, data=data, method=method)
    req.add_header("xi-api-key", key())
    req.add_header("Content-Type", "application/json")
    req.add_header("User-Agent", "game-audio-tool/1.0")
    try:
        with urllib.request.urlopen(req, timeout=600) as r:
            return r.status, r.read()
    except urllib.error.HTTPError as e:
        return e.code, e.read()


def explain(code: int, payload: bytes) -> str:
    text = payload.decode("utf-8", "replace")[:400]
    if code == 401:
        return "A chave foi recusada (401). Confira se copiou a chave inteira e se ela tem as permissões de efeitos sonoros e música."
    if code in (402, 429) or "quota" in text.lower():
        return f"Sem créditos ou limite atingido ({code}): {text}"
    return f"Erro {code}: {text}"


def credits() -> tuple[int, int] | None:
    code, data = request("GET", "/user/subscription")
    if code != 200:
        print(explain(code, data))
        return None
    s = json.loads(data)
    return int(s.get("character_count", 0)), int(s.get("character_limit", 0))


def log(entry: dict) -> None:
    rows = json.loads(LOG.read_text(encoding="utf-8")) if LOG.exists() else []
    rows.append(entry)
    LOG.write_text(json.dumps(rows, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")


def generate(it: dict, n: int) -> bytes | str:
    if it["kind"] == "music":
        body = {"prompt": it["prompt"], "music_length_ms": int(it["seconds"] * 1000), "model_id": it["model"],
                "force_instrumental": True}
        code, data = request("POST", "/music", body, "?output_format=mp3_44100_128")
    else:
        body = {"text": it["prompt"], "model_id": it["model"], "prompt_influence": it.get("prompt_influence", 0.4)}
        if it.get("seconds"):
            body["duration_seconds"] = max(0.5, min(30.0, float(it["seconds"])))
        if it.get("loop"):
            body["loop"] = True
        code, data = request("POST", "/sound-generation", body, "?output_format=mp3_44100_128")
    if code != 200:
        return explain(code, data)
    return data


def cmd_status() -> None:
    c = credits()
    if c:
        used, limit = c
        print(f"Créditos usados neste mês: {used:,} de {limit:,}  (sobram {limit - used:,})")
    done = sorted(p.name for p in INBOX.glob("*.mp3")) if INBOX.exists() else []
    print(f"Arquivos gerados em assets/_inbox/audio: {len(done)}")
    total = sum(cost(i) for i in items())
    print(f"A lista completa custa ~{total:,} créditos ({len(items())} itens).")


def cmd_cost(args: list) -> None:
    sel = pick(args)
    for it in sel:
        print(f"  {it['id']:<18} {it['kind']:<5} {it.get('variants', 1)} versão(ões)  ~{cost(it):,}")
    print(f"Total: ~{sum(cost(i) for i in sel):,} créditos")


def cmd_gen(args: list) -> None:
    sel = pick(args)
    force = "--force" in args
    todo = []
    for it in sel:
        for n in range(1, it.get("variants", 1) + 1):
            out = INBOX / f"{it['id']}_{n}.mp3"
            if out.exists() and not force:
                continue
            todo.append((it, n, out))
    if not todo:
        print("Nada a gerar (já existem; use --force para refazer).")
        return
    est = sum((round(it["seconds"] / 60 * MUSIC_PER_MIN) if it["kind"] == "music" else SFX_EACH) for it, _, _ in todo)
    print(f"Vou gerar {len(todo)} arquivo(s), ~{est:,} créditos.")
    if est > ASK_ABOVE and "--yes" not in args:
        sys.exit(f"Passa de {ASK_ABOVE:,} créditos: rode de novo com --yes para confirmar.")
    INBOX.mkdir(parents=True, exist_ok=True)
    before = credits()
    for it, n, out in todo:
        t0 = time.time()
        res = generate(it, n)
        if isinstance(res, str):
            print(f"  ✗ {it['id']}_{n}: {res}")
            if "401" in res or "créditos" in res.lower():
                break
            continue
        out.write_bytes(res)
        print(f"  ✓ {out.name}  ({len(res) // 1024} KB, {time.time() - t0:.0f} s)")
        log({"id": it["id"], "version": n, "kind": it["kind"], "file": out.name, "date": time.strftime("%Y-%m-%d %H:%M"),
             "estimate": round(it["seconds"] / 60 * MUSIC_PER_MIN) if it["kind"] == "music" else SFX_EACH})
    after = credits()
    if before and after:
        print(f"Gasto real: {after[0] - before[0]:,} créditos. Sobram {after[1] - after[0]:,}.")
    cmd_listen()


def cmd_approve(args: list) -> None:
    if len(args) < 2:
        sys.exit("Uso: aprovar <id> <versão>   (ex.: aprovar vila 2)")
    by_id = {i["id"]: i for i in items()}
    it = by_id.get(args[0])
    src = INBOX / f"{args[0]}_{args[1]}.mp3"
    if it is None or not src.exists():
        sys.exit(f"Não achei {src.name}.")
    if it["kind"] == "music":
        MUSIC_DIR.mkdir(parents=True, exist_ok=True)
        dst = MUSIC_DIR / f"{it['id']}.mp3"
        shutil.copyfile(src, dst)
    else:
        SFX_DIR.mkdir(parents=True, exist_ok=True)
        dst = SFX_DIR / f"{it['id']}_{args[1]}.ogg"
        ff = shutil.which("ffmpeg")
        if not ff:
            sys.exit("ffmpeg não encontrado (precisa para converter em ogg).")
        subprocess.run([ff, "-y", "-loglevel", "error", "-i", str(src), "-c:a", "libvorbis", "-q:a", "5", str(dst)], check=True)
    log({"id": it["id"], "version": int(args[1]), "approved": str(dst.relative_to(ROOT)), "date": time.strftime("%Y-%m-%d %H:%M")})
    print(f"Aprovado: {dst.relative_to(ROOT)}")


def cmd_approve_all() -> None:
    """Music: version 1 (unless one was approved already); effects: every version (they are
    variations played at random, e.g. 3 footsteps)."""
    approved = {r["id"] for r in (json.loads(LOG.read_text(encoding="utf-8")) if LOG.exists() else []) if "approved" in r}
    for it in items():
        files = sorted(INBOX.glob(f"{it['id']}_*.mp3"), key=lambda f: int(f.stem.rsplit("_", 1)[1]))
        if not files:
            print(f"  (sem arquivo) {it['id']}")
            continue
        if it["kind"] == "music":
            if it["id"] in approved:
                continue
            cmd_approve([it["id"], files[0].stem.rsplit("_", 1)[1]])
        else:
            for f in files:
                cmd_approve([it["id"], f.stem.rsplit("_", 1)[1]])


def cmd_listen() -> None:
    """A simple page with a player for every generated file, grouped by id."""
    if not INBOX.exists():
        return
    rows = []
    for it in items():
        files = sorted(INBOX.glob(f"{it['id']}_*.mp3"))
        if not files:
            continue
        players = "".join(f'<div class="v"><b>versão {f.stem.rsplit("_", 1)[1]}</b><audio controls preload="none" src="{f.name}"></audio></div>' for f in files)
        rows.append(f'<section><h2>{it["id"]} <small>{"música" if it["kind"] == "music" else "efeito"}</small></h2><p>{it["prompt"]}</p>{players}</section>')
    html = ("<!doctype html><meta charset='utf-8'><title>Sons do jogo</title><style>body{font-family:sans-serif;max-width:900px;"
            "margin:20px auto;padding:0 16px;background:#1d1712;color:#f3e3c0}section{border-bottom:1px solid #4a3a2a;padding:10px 0}"
            "h2{margin:4px 0;color:#ffd23f}small{color:#c8b89a;font-weight:normal}p{color:#c8b89a;font-size:13px}.v{display:flex;"
            "align-items:center;gap:12px;margin:6px 0}audio{width:420px}</style><h1>Sons gerados para ouvir</h1>"
            "<p>Diga qual versão de cada um aprovar (ex.: vila 2).</p>" + "".join(rows))
    (INBOX / "ouvir.html").write_text(html, encoding="utf-8")
    print(f"Página para ouvir: {INBOX / 'ouvir.html'}")


def main() -> None:
    if len(sys.argv) < 2:
        print(__doc__)
        return
    cmd, args = sys.argv[1], sys.argv[2:]
    if cmd == "status":
        cmd_status()
    elif cmd == "custo":
        cmd_cost(args or ["--all"])
    elif cmd == "gen":
        cmd_gen(args)
    elif cmd == "aprovar":
        cmd_approve(args)
    elif cmd == "aprovar-tudo":
        cmd_approve_all()
    elif cmd == "ouvir":
        cmd_listen()
    else:
        print(__doc__)


if __name__ == "__main__":
    main()
