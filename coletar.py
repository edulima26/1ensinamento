"""Coleta curtidas, comentarios e alcance dos posts publicados e guarda o historico."""
from ig import api, carregar, hoje_brt, salvar


def valor(item):
    if "total_value" in item:
        return item["total_value"].get("value", 0)
    return (item.get("values") or [{}])[0].get("value", 0)


def metricas_do_post(media_id):
    base = api("GET", media_id, fields="like_count,comments_count,permalink,timestamp")
    dados = {"likes": base.get("like_count", 0), "comentarios": base.get("comments_count", 0),
             "link": base.get("permalink"), "publicado_em": base.get("timestamp")}
    try:
        insights = api("GET", f"{media_id}/insights", metric="reach,saved,shares").get("data", [])
        for item in insights:
            dados[{"reach": "alcance", "saved": "salvos", "shares": "compartilhamentos"}[item["name"]]] = valor(item)
    except RuntimeError as erro:
        print(f"Aviso: insights indisponiveis para {media_id}: {erro}")
    return dados


def main():
    estado = carregar("estado.json", {"publicados": {}})
    historico = carregar("metricas.json", {"snapshots": [], "comentarios": {}})
    hoje = hoje_brt().isoformat()

    conta = api("GET", "me", fields="username,followers_count,media_count")
    posts = {}
    for post_chave, info in estado["publicados"].items():
        mid = info["media_id"]
        posts[post_chave] = metricas_do_post(mid)
        lista = api("GET", f"{mid}/comments", fields="id,text,username,timestamp,like_count", limit=100)
        guardados = historico["comentarios"].setdefault(post_chave, {})
        for c in lista.get("data", []):
            guardados[c["id"]] = {"texto": c.get("text", ""), "usuario": c.get("username"),
                                  "quando": c.get("timestamp"), "likes": c.get("like_count", 0)}

    snapshot = {"data": hoje, "seguidores": conta.get("followers_count"), "posts": posts}
    historico["snapshots"] = [s for s in historico["snapshots"] if s["data"] != hoje] + [snapshot]
    salvar("metricas.json", historico)
    print(f"Coletado: {len(posts)} posts, {conta.get('followers_count')} seguidores.")


if __name__ == "__main__":
    main()
