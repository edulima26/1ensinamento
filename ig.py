"""Funcoes comuns para falar com a API do Instagram (apenas biblioteca padrao)."""
import datetime as dt
import json
import os
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).parent
BASE = os.environ.get("IG_BASE", "https://graph.instagram.com")
VERSAO = os.environ.get("GRAPH_VERSION", "v21.0")
BRT = dt.timezone(dt.timedelta(hours=-3))


def hoje_brt():
    return dt.datetime.now(BRT).date()


def carregar(nome, padrao=None):
    arquivo = ROOT / nome
    if not arquivo.exists():
        return padrao
    return json.loads(arquivo.read_text(encoding="utf-8"))


def salvar(nome, dados):
    texto = json.dumps(dados, ensure_ascii=False, indent=2) + "\n"
    (ROOT / nome).write_text(texto, encoding="utf-8")


def chave(cfg, post):
    """Identifica o post no estado: o id repete a cada lote, entao inclui o lote."""
    return f"{cfg['lote']}-{post['id']:02d}"


def api(metodo, caminho, **params):
    params.setdefault("access_token", os.environ["IG_TOKEN"])
    corpo = urllib.parse.urlencode(params)
    url = f"{BASE}/{VERSAO}/{caminho}"
    if metodo == "GET":
        req = urllib.request.Request(f"{url}?{corpo}")
    else:
        req = urllib.request.Request(url, data=corpo.encode(), method="POST")
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            return json.load(resp)
    except urllib.error.HTTPError as erro:
        detalhe = erro.read().decode("utf-8", "replace")
        raise RuntimeError(f"{metodo} {caminho} -> {erro.code}: {detalhe}") from None
