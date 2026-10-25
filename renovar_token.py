"""Renova o token de longa duracao do Instagram e imprime so o novo token (para ir direto ao `gh secret set`)."""
import json
import os
import urllib.parse
import urllib.request

consulta = urllib.parse.urlencode({"grant_type": "ig_refresh_token", "access_token": os.environ["IG_TOKEN"]})
with urllib.request.urlopen(f"https://graph.instagram.com/refresh_access_token?{consulta}", timeout=60) as resp:
    print(json.load(resp)["access_token"], end="")
