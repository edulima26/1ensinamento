# @1ensinamento: automação de posts

Um post por dia às 07:00 (Brasília), coleta diária de curtidas e comentários e relatório toda segunda-feira. Tudo roda no GitHub Actions, então não depende do seu computador ligado.

## Como funciona

| Arquivo | Função |
|---|---|
| `posts.json` | Os 30 posts do mês (título, frase, pergunta, legenda, hashtags) e o código do lote (`lote`). |
| `imagens/` | As 30 imagens JPEG, geradas por `gerar.ps1` no Windows. |
| `publicar.py` | Publica o próximo post ainda não publicado, no máximo um por dia. |
| `coletar.py` | Salva curtidas, comentários, alcance, salvamentos e seguidores em `metricas.json`. |
| `relatorio.py` | Escreve `relatorios/AAAA-MM-DD.md`: ranking, média por pilar e tom, comentários da semana. Com `ANTHROPIC_API_KEY`, inclui um resumo dos comentários feito pelo Claude. |
| `estado.json` | Registra o que já foi publicado (o robô atualiza sozinho). |
| `renovar_token.py` | Renova o token do Instagram, que dura 60 dias. |

## Configuração (uma vez só)

### 1. Conta do Instagram
No app: Configurações → Tipo de conta e ferramentas → **Mudar para conta profissional** (Criador ou Empresa).

### 2. App na Meta
1. Entre em developers.facebook.com e crie um app do tipo **Empresa (Business)**.
2. Adicione o produto **Instagram** e escolha **API com login do Instagram**.
3. Em *Funções do app*, adicione `@1ensinamento` como testador do Instagram e aceite o convite no app do Instagram (Configurações → Sites e apps → Convites de testador).
4. Em *Gerar tokens de acesso*, gere o token da conta `@1ensinamento`, com as permissões:
   `instagram_business_basic`, `instagram_business_content_publish`, `instagram_business_manage_comments`, `instagram_business_manage_insights`.
5. Guarde o token. Ele vale 60 dias e é renovado automaticamente (passo 4).

Para publicar na própria conta, o app pode ficar em modo de desenvolvimento, sem revisão da Meta.

### 3. Repositório no GitHub
1. Crie um repositório **público** (a API do Instagram precisa baixar as imagens por URL pública) e envie esta pasta.
2. *Settings → Secrets and variables → Actions → New repository secret*:
   - `IG_TOKEN`: o token do passo 2.
   - `ANTHROPIC_API_KEY` (opcional): para o resumo dos comentários no relatório.
   - `GH_PAT` (opcional): token do GitHub com permissão de escrever segredos, para renovar o `IG_TOKEN` sozinho.
3. *Settings → Actions → General → Workflow permissions*: marque **Read and write permissions**.

### 4. Teste antes de ligar
1. *Actions → Publicar post do dia → Run workflow* com **dry_run marcado**. Ele mostra no log a legenda e o endereço da imagem, sem publicar.
2. Abra o endereço da imagem do log no navegador. Se a imagem aparecer, a API consegue baixá-la.
3. Rode de novo com dry_run **desmarcado** para publicar o primeiro post de verdade. Confira no Instagram.
4. A partir daí o agendamento diário cuida do resto. Confira também *Coleta diaria e relatorio semanal → Run workflow*.

## Rotina mensal
1. Peça ao Claude os 30 novos posts (`posts.json` com um novo `lote`, por exemplo `2026-12`).
2. Rode `gerar.ps1` no Windows para gerar `imagens/` e `galeria.html`, e aprove.
3. Envie ao GitHub (`posts.json` e `imagens/`). O robô continua do primeiro post do novo lote.

## Pausar ou parar
- Pausar: *Actions → Publicar post do dia → ⋯ → Disable workflow*.
- Se o lote acabar, o robô só avisa no log "Lote concluído" e não publica nada.

## Cuidados
- O robô confere no próprio Instagram se já existe um post de hoje, para não duplicar.
- Se uma execução falhar, o GitHub envia e-mail. No dia seguinte o robô tenta de novo o mesmo post.
- Comentários são tratados só como dados no resumo do Claude; ele não executa instruções vindas deles.
- Os nomes exatos de métricas e a versão da API (`GRAPH_VERSION`, hoje v21.0) podem mudar; se a coleta falhar, o log mostra a resposta da Meta.
