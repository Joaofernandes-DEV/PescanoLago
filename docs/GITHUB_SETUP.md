# Configuração do GitHub

Repositório: <https://github.com/Joaofernandes-DEV/PescanoLago> (público, branch padrão `main`).

## Proteção da `main` (configurada e comprovada)

Configurada pela API em 2026-10-17. O repositório público permite proteção de branch no plano gratuito.

| Regra | Valor |
|---|---|
| Pull Request obrigatório | Sim, 0 aprovações (projeto solo; o CI é o revisor obrigatório) |
| Checks obrigatórios | `Verificações do repositório`, `Varredura de segredos`, `Validação de dados`, `Lint GDScript e pureza do núcleo`, `Pipeline do Blender`, `Testes Godot (headless)`, `Build e fumaça` (desde a Fase 3) |
| Branch atualizada antes do merge (`strict`) | Sim |
| Regras valem para admin (`enforce_admins`) | Sim |
| Force push | Bloqueado |
| Exclusão da `main` | Bloqueada |
| Conversas resolvidas antes do merge | Sim |

### Como conferir

```bash
gh api repos/Joaofernandes-DEV/PescanoLago/branches/main/protection --jq "{checks: .required_status_checks.contexts, strict: .required_status_checks.strict, admins: .enforce_admins.enabled, force_push: .allow_force_pushes.enabled, deletions: .allow_deletions.enabled}"
```

Saída no fim da Fase 1 (2026-10-17):

```json
{"admins":true,"checks":["Verificações do repositório","Varredura de segredos","Testes Godot (headless)","Validação de dados","Lint GDScript e pureza do núcleo","Pipeline do Blender"],"deletions":false,"force_push":false,"strict":true}
```

Prova de que vale também para o admin: um push direto de um commit descartável para a `main` foi recusado.

```text
remote: error: GH006: Protected branch update failed for refs/heads/main.
remote: - Changes must be made through a pull request.
remote: - 6 of 6 required status checks are expected.
 ! [remote rejected] ... -> main (protected branch hook declined)
```

### Como reaplicar (se precisar recriar o repositório)

Salve o JSON abaixo em um arquivo (por exemplo, `protection.json`) e rode o comando seguinte. Os nomes em `contexts` precisam ser iguais ao `name:` dos jobs do CI.

```json
{
  "required_status_checks": {"strict": true, "contexts": ["Verificações do repositório", "Varredura de segredos", "Validação de dados", "Lint GDScript e pureza do núcleo", "Pipeline do Blender", "Testes Godot (headless)", "Build e fumaça"]},
  "enforce_admins": true,
  "required_pull_request_reviews": {"required_approving_review_count": 0},
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_conversation_resolution": true
}
```

```bash
gh api -X PUT repos/Joaofernandes-DEV/PescanoLago/branches/main/protection --input protection.json
```

## Merge

- Os três tipos de merge estão habilitados no repositório. O projeto usa **merge commit** (`gh pr merge N --merge`), nunca squash, para preservar um commit por arquivo.
- Branches de PR mescladas podem ser apagadas manualmente; nada é apagado automaticamente.

## Limitações e passos manuais

- **Ao adicionar um job novo ao CI:** depois do primeiro PR verde com ele, inclua o nome do job em `contexts` (endpoint `.../protection/required_status_checks`, método PATCH).
- **Git LFS:** cota gratuita de 10 GiB de armazenamento e 10 GiB de banda por mês. Com orçamento de US$ 0, ao estourar, o LFS é bloqueado até o fim do mês (sem cobrança). Conferir em *Settings → Billing and plans* da conta a cada fase de arte.
- **Se o repositório virar privado:** no plano gratuito, a proteção de branch deixa de valer para repositórios privados. A alternativa seria o GitHub Pro ou manter as verificações locais (`python tools/ci/check_repo.py`) antes de cada PR.
- **Segredos (Fase 9):** a chave de assinatura do Android vai em *Settings → Secrets and variables → Actions*, cadastrada pelo usuário. Nunca no repositório.
