"""Publica no Instagram o proximo post do lote (no maximo um por dia)."""
import datetime as dt
import os
import time

from ig import api, carregar, chave, hoje_brt, salvar, BRT


def legenda(cfg, post):
    return f"{post['legenda']}\n\n{cfg['pilares'][post['pilar']]['hashtags']}"


def ja_postou_hoje(hoje):
    """Confere no proprio Instagram, para nunca duplicar mesmo se o estado falhar."""
    recentes = api("GET", "me/media", fields="timestamp", limit=5).get("data", [])
    for item in recentes:
        quando = dt.datetime.strptime(item["timestamp"], "%Y-%m-%dT%H:%M:%S%z")
        if quando.astimezone(BRT).date() == hoje:
            return True
    return False


def main():
    simulado = os.environ.get("DRY_RUN") == "1"
    cfg = carregar("posts.json")
    estado = carregar("estado.json", {"publicados": {}})
    hoje = hoje_brt()

    if any(v["data"] == hoje.isoformat() for v in estado["publicados"].values()):
        print("Ja existe post de hoje no estado. Nada a fazer.")
        return

    pendentes = [p for p in cfg["posts"] if chave(cfg, p) not in estado["publicados"]]
    if not pendentes:
        print(f"Lote {cfg['lote']} concluido. Gere e envie o proximo lote.")
        return
    post = pendentes[0]

    repo = os.environ["GITHUB_REPOSITORY"]
    ramo = os.environ.get("GITHUB_REF_NAME", "main")
    url = f"https://raw.githubusercontent.com/{repo}/{ramo}/imagens/post_{post['id']:02d}.jpg"
    texto = legenda(cfg, post)

    print(f"Post {chave(cfg, post)} ({post['pilar']})\nImagem: {url}\n---\n{texto}\n---")
    if simulado:
        print("DRY_RUN: nada foi publicado.")
        return

    if ja_postou_hoje(hoje):
        print("O Instagram ja tem um post de hoje. Nada a fazer.")
        return

    container = api("POST", "me/media", image_url=url, caption=texto)["id"]
    for _ in range(60):
        status = api("GET", container, fields="status_code")["status_code"]
        if status == "FINISHED":
            break
        if status in ("ERROR", "EXPIRED"):
            raise RuntimeError(f"Container {container} terminou com status {status}")
        time.sleep(5)
    else:
        raise RuntimeError(f"Container {container} nao ficou pronto a tempo")

    media_id = api("POST", "me/media_publish", creation_id=container)["id"]
    estado["publicados"][chave(cfg, post)] = {"media_id": media_id, "data": hoje.isoformat()}
    salvar("estado.json", estado)
    print(f"Publicado: media {media_id}")


if __name__ == "__main__":
    main()
