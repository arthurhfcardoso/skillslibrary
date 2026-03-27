# Skills Library

Biblioteca central de skills e frameworks para operacao de agentes no ecossistema Madame Labs.

## Documento principal

- Catalogo unico: [CATALOGO.md](CATALOGO.md)
- Total de skills mapeadas atualmente: **2668**

## Como atualizar

```powershell
pwsh ./scripts/gerar-catalogos-skills.ps1
# fallback no Windows PowerShell:
powershell -ExecutionPolicy Bypass -File .\scripts\gerar-catalogos-skills.ps1
```

## Notas

- O `spec-kit` e tratado como framework (sem inventario `SKILL.md`).
- Este processo nao usa API externa; gera tudo com dados locais.

