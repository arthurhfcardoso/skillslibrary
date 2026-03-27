# Skills Library

Biblioteca central de skills e frameworks para Claude Code.
Repositório de referência usado pela [master-skill](~/.claude/skills/master-skill/) para instalar skills sob demanda em projetos.

## Estrutura

| Pasta | Origem | Descrição |
|---|---|---|
| `anthropics-skills/` | [anthropics/skills](https://github.com/anthropics/skills) | Skills oficiais da Anthropic |
| `composio-skills/` | [ComposioHQ/awesome-claude-skills](https://github.com/ComposioHQ/awesome-claude-skills) | Coleção comunitária (Composio) |
| `antigravity-skills/` | [sickn33/antigravity-awesome-skills](https://github.com/sickn33/antigravity-awesome-skills) | Catálogo Antigravity com 1800+ skills |
| `wshobson-agents/` | [wshobson/agents](https://github.com/wshobson/agents) | Agents e skills (wshobson) |
| `ruflo/` | [ruvnet/ruflo](https://github.com/ruvnet/ruflo) | Framework ruflo com CLI e plugins |
| `bmad-method/` | [bmad-code-org/BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD) | Framework BMAD para dev com agentes |
| `spec-kit/` | [github/spec-kit](https://github.com/github/spec-kit) | Spec Kit do GitHub para specs de projeto |

## Uso

```bash
# Listar skills disponíveis
/master-skill list

# Buscar skill por termo
/master-skill search brainstorming

# Instalar skill no projeto atual
/master-skill install <nome-da-skill>
```

## Arquitetura

```
C:/Projects/skillslibrary/     <-- este repo (depósito)
    ├── anthropics-skills/
    ├── composio-skills/
    ├── ...
    │
~/.claude/skills/              <-- skills globais (sempre ativas)
    ├── master-skill/          <-- orquestrador
    │
<projeto>/.claude/skills/      <-- skills do projeto (sob demanda)
    ├── brainstorming/
    ├── ...
```
