param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
    [string]$MetadataFile = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'catalogos/repos-metadata.yaml'),
    [string]$CatalogPath = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'CATALOGO.md'),
    [string]$ReadmePath = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'README.md'),
    [string]$TranslationCachePath = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'catalogos/translation-cache-pt.json'),
    [switch]$DisableTranslation
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Normalize-Value {
    param([string]$Value)
    if ($null -eq $Value) { return '' }
    $text = $Value.Trim()
    if (
        ($text.StartsWith('"') -and $text.EndsWith('"')) -or
        ($text.StartsWith("'") -and $text.EndsWith("'"))
    ) {
        return $text.Substring(1, $text.Length - 2)
    }
    return $text
}

function Escape-MarkdownCell {
    param([string]$Value)
    if ($null -eq $Value) { return '' }
    $text = $Value -replace '\|', '\|'
    $text = $text -replace "`r?`n", ' '
    $text = $text -replace '\s+', ' '
    return $text.Trim()
}

function To-Anchor {
    param([string]$Value)
    $text = $Value.ToLowerInvariant()
    $text = $text -replace '[^a-z0-9\s-]', ''
    $text = $text -replace '\s+', '-'
    $text = $text -replace '-+', '-'
    return $text.Trim('-')
}

function Parse-MetadataFile {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Arquivo de metadados nao encontrado: $Path"
    }

    $repos = New-Object System.Collections.Generic.List[object]
    $current = $null

    foreach ($rawLine in Get-Content -LiteralPath $Path -Encoding UTF8) {
        $line = $rawLine.TrimEnd()
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        if ($line.TrimStart().StartsWith('#')) { continue }
        if ($line -match '^\s*repos:\s*$') { continue }

        if ($line -match '^\s*-\s*repo_id:\s*(.+?)\s*$') {
            if ($null -ne $current) {
                $repos.Add([pscustomobject]$current)
            }
            $current = @{
                repo_id = Normalize-Value -Value $Matches[1]
                display_name = ''
                github_owner_repo = ''
                creator = ''
                purpose = ''
                artifacts = ''
                notes = ''
            }
            continue
        }

        if ($null -eq $current) { continue }

        if ($line -match '^\s*([a-z_]+):\s*(.*?)\s*$') {
            $key = $Matches[1]
            $value = Normalize-Value -Value $Matches[2]
            if ($current.ContainsKey($key)) {
                $current[$key] = $value
            }
        }
    }

    if ($null -ne $current) {
        $repos.Add([pscustomobject]$current)
    }

    if ($repos.Count -eq 0) {
        throw "Nenhum repositorio valido encontrado em: $Path"
    }

    return $repos
}

function Get-FrontmatterValue {
    param(
        [string]$Line,
        [string]$Key
    )

    if ($Line -match "^\s*${Key}:\s*(.+?)\s*$") {
        return Normalize-Value -Value $Matches[1]
    }
    return $null
}

function Read-SkillMetadata {
    param([string]$Path)

    $name = ''
    $description = ''
    $inFrontmatter = $false
    $lineIndex = 0

    foreach ($line in Get-Content -LiteralPath $Path -TotalCount 140 -Encoding UTF8) {
        if ($lineIndex -eq 0 -and $line.Trim() -eq '---') {
            $inFrontmatter = $true
            $lineIndex++
            continue
        }

        if ($inFrontmatter -and $line.Trim() -eq '---') {
            break
        }

        if ($inFrontmatter) {
            if ([string]::IsNullOrWhiteSpace($name)) {
                $parsedName = Get-FrontmatterValue -Line $line -Key 'name'
                if ($parsedName) { $name = $parsedName }
            }
            if ([string]::IsNullOrWhiteSpace($description)) {
                $parsedDescription = Get-FrontmatterValue -Line $line -Key 'description'
                if ($parsedDescription) { $description = $parsedDescription }
            }
        }

        $lineIndex++
    }

    if ([string]::IsNullOrWhiteSpace($name)) {
        $name = Split-Path -Path (Split-Path -Path $Path -Parent) -Leaf
    }

    return [pscustomobject]@{
        name = $name
        description = $description
    }
}

function Get-Taxonomy {
    $taxonomy = New-Object System.Collections.Generic.List[object]
    $taxonomy.Add([pscustomobject]@{ niche='Planejamento e Descoberta'; area='Negocio e Growth'; relevancia_padrao='Media' })
    $taxonomy.Add([pscustomobject]@{ niche='Arquitetura e Design de Sistemas'; area='Engenharia de Software'; relevancia_padrao='Media' })
    $taxonomy.Add([pscustomobject]@{ niche='Desenvolvimento Backend e APIs'; area='Engenharia de Software'; relevancia_padrao='Baixa' })
    $taxonomy.Add([pscustomobject]@{ niche='Desenvolvimento Frontend e UX/UI'; area='Engenharia de Software'; relevancia_padrao='Baixa' })
    $taxonomy.Add([pscustomobject]@{ niche='Mobile e Plataformas Cliente'; area='Engenharia de Software'; relevancia_padrao='Baixa' })
    $taxonomy.Add([pscustomobject]@{ niche='Testes, QA e Debug'; area='Engenharia de Software'; relevancia_padrao='Media' })
    $taxonomy.Add([pscustomobject]@{ niche='DevOps, Cloud, CI/CD e Kubernetes'; area='Infraestrutura e Operacoes'; relevancia_padrao='Baixa' })
    $taxonomy.Add([pscustomobject]@{ niche='Seguranca e Compliance'; area='Infraestrutura e Operacoes'; relevancia_padrao='Baixa' })
    $taxonomy.Add([pscustomobject]@{ niche='Dados, Analytics e ML/LLM'; area='Dados e IA'; relevancia_padrao='Media' })
    $taxonomy.Add([pscustomobject]@{ niche='Automacao de Ferramentas e Integracoes'; area='Produtividade e Documentacao'; relevancia_padrao='Alta' })
    $taxonomy.Add([pscustomobject]@{ niche='Conteudo, Marketing, SEO e Vendas'; area='Negocio e Growth'; relevancia_padrao='Alta' })
    $taxonomy.Add([pscustomobject]@{ niche='Documentacao, PM e Operacao de Times'; area='Produtividade e Documentacao'; relevancia_padrao='Alta' })
    return $taxonomy
}

function Classify-Skill {
    param([string]$Text)

    $rules = @(
        @{ pattern='(security|seguranca|pentest|vulnerab|owasp|xss|sqli|csrf|compliance|gdpr|hipaa|pci|forensic|threat|auth)'; niche='Seguranca e Compliance'; area='Infraestrutura e Operacoes' },
        @{ pattern='(kubernetes|helm|terraform|devops|ci/cd|cicd|cloud|aws|azure|gcp|deployment|prometheus|grafana|sre|observability|docker|gitops)'; niche='DevOps, Cloud, CI/CD e Kubernetes'; area='Infraestrutura e Operacoes' },
        @{ pattern='(machine learning|\bml\b|llm|rag|embedding|vector|langchain|langgraph|model|dataset|analytics|data pipeline|data engineering|\bai\b|evaluation)'; niche='Dados, Analytics e ML/LLM'; area='Dados e IA' },
        @{ pattern='(seo|marketing|sales|crm|copy|content|social|ads|lead|pricing|growth|launch|funnel|objection|vendas)'; niche='Conteudo, Marketing, SEO e Vendas'; area='Negocio e Growth' },
        @{ pattern='(automation|automate|workflow|integration|mcp|slack|gmail|notion|google|jira|trello|airtable|hubspot|zapier|make|whatsapp|calendar|pipeline automation)'; niche='Automacao de Ferramentas e Integracoes'; area='Produtividade e Documentacao' },
        @{ pattern='(frontend|\bui\b|\bux\b|react|nextjs|next.js|angular|vue|tailwind|css|design system|accessibility|web design|html)'; niche='Desenvolvimento Frontend e UX/UI'; area='Engenharia de Software' },
        @{ pattern='(mobile|android|ios|swiftui|react native|flutter|expo)'; niche='Mobile e Plataformas Cliente'; area='Engenharia de Software' },
        @{ pattern='(backend|\bapi\b|fastapi|nestjs|express|nodejs|django|flask|grpc|database|postgres|redis|server)'; niche='Desenvolvimento Backend e APIs'; area='Engenharia de Software' },
        @{ pattern='(architecture|arquitet|microservice|ddd|cqrs|event sourcing|design pattern|system design|hexagonal)'; niche='Arquitetura e Design de Sistemas'; area='Engenharia de Software' },
        @{ pattern='(test|testing|\bqa\b|debug|troubleshoot|playwright|jest|pytest|quality|lint|coverage)'; niche='Testes, QA e Debug'; area='Engenharia de Software' },
        @{ pattern='(brainstorm|discovery|planning|roadmap|brief|product|research|prioritization|strategy|discovery)'; niche='Planejamento e Descoberta'; area='Negocio e Growth' },
        @{ pattern='(documentation|readme|changelog|wiki|onboarding|project management|standup|retrospective|doc\b|communication|conductor|playbook)'; niche='Documentacao, PM e Operacao de Times'; area='Produtividade e Documentacao' }
    )

    foreach ($rule in $rules) {
        if ($Text -match $rule.pattern) {
            return [pscustomobject]@{ niche=$rule.niche; area=$rule.area }
        }
    }

    return [pscustomobject]@{
        niche = 'Documentacao, PM e Operacao de Times'
        area = 'Produtividade e Documentacao'
    }
}

function Get-DefaultRelevancia {
    param([string]$Niche)
    switch ($Niche) {
        'Automacao de Ferramentas e Integracoes' { return 'Alta' }
        'Conteudo, Marketing, SEO e Vendas' { return 'Alta' }
        'Documentacao, PM e Operacao de Times' { return 'Alta' }
        'Planejamento e Descoberta' { return 'Media' }
        'Arquitetura e Design de Sistemas' { return 'Media' }
        'Testes, QA e Debug' { return 'Media' }
        'Dados, Analytics e ML/LLM' { return 'Media' }
        default { return 'Baixa' }
    }
}

function Resolve-Relevancia {
    param(
        [string]$Niche,
        [string]$Text
    )

    $default = Get-DefaultRelevancia -Niche $Niche

    if ($Text -match '(seo|marketing|sales|crm|whatsapp|lead|copy|social|automation|workflow|integration|notion|slack|gmail|google|customer|conteudo|vendas)') {
        return 'Alta'
    }

    if ($Text -match '(llm|rag|prompt|agent|data|analytics|test|qa|architect|planning|debug|research)') {
        return 'Media'
    }

    return $default
}

function Translate-DescriptionsToPortuguese {
    param(
        [System.Collections.Generic.List[object]]$Entries,
        [string]$CachePath
    )

    if ($DisableTranslation.IsPresent) {
        Write-Host 'Traducao desativada por parametro.'
        return
    }

    $pythonCmd = Get-Command python -ErrorAction SilentlyContinue
    if ($null -eq $pythonCmd) {
        Write-Host 'Python nao encontrado; mantendo descricoes originais.'
        return
    }

    $descriptions = $Entries |
        ForEach-Object { $_.description } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        Sort-Object -Unique

    if (($descriptions | Measure-Object).Count -eq 0) {
        return
    }

    $tmpInput = [System.IO.Path]::GetTempFileName()
    $tmpOutput = [System.IO.Path]::GetTempFileName()

    try {
        $jsonInput = $descriptions | ConvertTo-Json -Depth 3
        Set-Content -LiteralPath $tmpInput -Value $jsonInput -Encoding UTF8

        $env:TRANS_INPUT_JSON = $tmpInput
        $env:TRANS_OUTPUT_JSON = $tmpOutput
        $env:TRANS_CACHE_JSON = $CachePath

        $pyCode = @'
import json
import os
import time
from deep_translator import GoogleTranslator

input_path = os.environ["TRANS_INPUT_JSON"]
output_path = os.environ["TRANS_OUTPUT_JSON"]
cache_path = os.environ["TRANS_CACHE_JSON"]

with open(input_path, "r", encoding="utf-8-sig") as f:
    texts = json.load(f)

cache = {}
if os.path.exists(cache_path):
    try:
        with open(cache_path, "r", encoding="utf-8") as f:
            cache = json.load(f)
    except Exception:
        cache = {}

translator = GoogleTranslator(source="auto", target="pt")
missing = [t for t in texts if t and t not in cache]
total = len(texts)
missing_total = len(missing)
print(f"[translate] total={total} missing={missing_total}", flush=True)

for idx, text in enumerate(missing):
    try:
        translated = translator.translate(text)
        cache[text] = translated if translated else text
    except Exception:
        cache[text] = text
    if (idx + 1) % 25 == 0 or idx + 1 == missing_total:
        os.makedirs(os.path.dirname(cache_path), exist_ok=True)
        with open(cache_path, "w", encoding="utf-8") as f:
            json.dump(cache, f, ensure_ascii=False, indent=2)
        print(f"[translate] progress={idx + 1}/{missing_total}", flush=True)
    time.sleep(0.15)

os.makedirs(os.path.dirname(cache_path), exist_ok=True)
with open(cache_path, "w", encoding="utf-8") as f:
    json.dump(cache, f, ensure_ascii=False, indent=2)

records = [{"source": t, "target": cache.get(t, t)} for t in texts]
with open(output_path, "w", encoding="utf-8") as f:
    json.dump(records, f, ensure_ascii=False)
'@

        $pyCode | python -
        if ($LASTEXITCODE -ne 0) {
            throw "Falha na etapa Python de traducao."
        }

        $records = Get-Content -LiteralPath $tmpOutput -Raw -Encoding UTF8 | ConvertFrom-Json
        $translationMap = @{}
        foreach ($record in $records) {
            $translationMap[[string]$record.source] = [string]$record.target
        }

        foreach ($entry in $Entries) {
            if (-not [string]::IsNullOrWhiteSpace($entry.description) -and $translationMap.ContainsKey([string]$entry.description)) {
                $entry.description = Escape-MarkdownCell -Value $translationMap[[string]$entry.description]
            }
        }

        Write-Host ("Descricoes traduzidas para PT: {0}" -f ($translationMap.Count))
    }
    finally {
        if (Test-Path -LiteralPath $tmpInput) { Remove-Item -LiteralPath $tmpInput -Force }
        if (Test-Path -LiteralPath $tmpOutput) { Remove-Item -LiteralPath $tmpOutput -Force }
        Remove-Item Env:TRANS_INPUT_JSON -ErrorAction SilentlyContinue
        Remove-Item Env:TRANS_OUTPUT_JSON -ErrorAction SilentlyContinue
        Remove-Item Env:TRANS_CACHE_JSON -ErrorAction SilentlyContinue
    }
}

function Write-CatalogDocument {
    param(
        [string]$Path,
        [System.Collections.Generic.List[object]]$Repos,
        [System.Collections.Generic.List[object]]$Taxonomy,
        [System.Collections.Generic.List[object]]$Entries,
        [hashtable]$RepoSummary
    )

    $totalSkills = ($Entries | Measure-Object).Count
    $lines = New-Object System.Collections.Generic.List[string]

    $lines.Add('# CATALOGO DE SKILLS')
    $lines.Add('')
    $lines.Add('Documento unico de inventario das skills dos repositorios selecionados para a Madame Labs.')
    $lines.Add('Organizacao principal por nicho/dominio, com classificacao automatica hibrida e coluna de relevancia para a estrategia da Madame Labs.')
    $lines.Add('')
    $lines.Add('## Sumario')
    $lines.Add('')
    $lines.Add('- [Fichas dos repositorios](#fichas-dos-repositorios)')
    $lines.Add('- [Taxonomia oficial (12 nichos + 5 areas)](#taxonomia-oficial-12-nichos--5-areas)')
    $lines.Add('- [Resumo quantitativo](#resumo-quantitativo)')
    $lines.Add('- [Catalogo completo por nicho](#catalogo-completo-por-nicho)')
    $lines.Add('- [Glossario de relevancia ml](#glossario-de-relevancia-ml)')
    $lines.Add('')

    $lines.Add('## Fichas dos repositorios')
    $lines.Add('')
    foreach ($repo in $Repos) {
        $repoCount = 0
        if ($RepoSummary.ContainsKey($repo.repo_id)) { $repoCount = [int]$RepoSummary[$repo.repo_id] }
        $lines.Add(('### {0}' -f $repo.display_name))
        $lines.Add('')
        $lines.Add(('- Criador: {0}' -f $repo.creator))
        $lines.Add(('- Repositorio: {0}' -f $repo.github_owner_repo))
        $lines.Add(('- Proposito: {0}' -f $repo.purpose))
        $lines.Add(('- O que criou: {0}' -f $repo.artifacts))
        $lines.Add(('- Notas: {0}' -f $repo.notes))
        $lines.Add(('- Inventario de skills neste repo: **{0}**' -f $repoCount))
        $lines.Add('')
    }

    $lines.Add('## Taxonomia oficial (12 nichos + 5 areas)')
    $lines.Add('')
    $lines.Add('| Nicho | Area | Relevancia ML padrao |')
    $lines.Add('|---|---|---|')
    foreach ($row in $Taxonomy) {
        $lines.Add(('| {0} | {1} | {2} |' -f $row.niche, $row.area, $row.relevancia_padrao))
    }
    $lines.Add('')

    $lines.Add('## Resumo quantitativo')
    $lines.Add('')
    $lines.Add(('- Total de repositorios mapeados: **{0}**' -f $Repos.Count))
    $lines.Add(('- Total de skills mapeadas: **{0}**' -f $totalSkills))
    $lines.Add('')
    $lines.Add('| Repositorio | Total Skills |')
    $lines.Add('|---|---:|')
    foreach ($repo in $Repos) {
        $repoCount = 0
        if ($RepoSummary.ContainsKey($repo.repo_id)) { $repoCount = [int]$RepoSummary[$repo.repo_id] }
        $lines.Add(('| `{0}` | {1} |' -f $repo.repo_id, $repoCount))
    }
    $lines.Add('')

    $lines.Add('## Catalogo completo por nicho')
    $lines.Add('')

    foreach ($taxonomyRow in $Taxonomy) {
        $niche = $taxonomyRow.niche
        $area = $taxonomyRow.area
        $nicheEntries = $Entries | Where-Object { $_.niche -eq $niche } | Sort-Object repo_id, name, path
        $count = ($nicheEntries | Measure-Object).Count
        $lines.Add(('### {0} ({1})' -f $niche, $area))
        $lines.Add('')
        $lines.Add(('- Total de skills neste nicho: **{0}**' -f $count))
        $lines.Add('')
        if ($count -eq 0) {
            $lines.Add('Nenhuma skill classificada neste nicho.')
            $lines.Add('')
            continue
        }
        $lines.Add('| Skill | Descricao | Nicho | Area | Repo | Path | Relevancia ML |')
        $lines.Add('|---|---|---|---|---|---|---|')
        foreach ($entry in $nicheEntries) {
            $skill = Escape-MarkdownCell -Value $entry.name
            $description = Escape-MarkdownCell -Value $entry.description
            $pathCode = ('`{0}`' -f (Escape-MarkdownCell -Value $entry.path))
            $repoCode = ('`{0}`' -f $entry.repo_id)
            $descFinal = if ([string]::IsNullOrWhiteSpace($description)) { '(sem description)' } else { $description }
            $lines.Add(('| {0} | {1} | {2} | {3} | {4} | {5} | {6} |' -f $skill, $descFinal, $entry.niche, $entry.area, $repoCode, $pathCode, $entry.relevancia_ml))
        }
        $lines.Add('')
    }

    $lines.Add('## Glossario de relevancia ml')
    $lines.Add('')
    $lines.Add('- **Alta**: aplicacao direta na operacao atual da Madame Labs (automacao, conteudo, growth, operacao de time).')
    $lines.Add('- **Media**: utilidade relevante para planejamento, qualidade e evolucao de produto/engenharia.')
    $lines.Add('- **Baixa**: utilidade indireta no contexto atual; pode entrar em fases futuras.')
    $lines.Add('')

    Set-Content -LiteralPath $Path -Value $lines -Encoding UTF8
}

function Write-Readme {
    param(
        [string]$Path,
        [int]$TotalSkills
    )

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('# Skills Library')
    $lines.Add('')
    $lines.Add('Biblioteca central de skills e frameworks para operacao de agentes no ecossistema Madame Labs.')
    $lines.Add('')
    $lines.Add('## Documento principal')
    $lines.Add('')
    $lines.Add('- Catalogo unico: [CATALOGO.md](CATALOGO.md)')
    $lines.Add(('- Total de skills mapeadas atualmente: **{0}**' -f $TotalSkills))
    $lines.Add('')
    $lines.Add('## Como atualizar')
    $lines.Add('')
    $lines.Add('```powershell')
    $lines.Add('pwsh ./scripts/gerar-catalogos-skills.ps1')
    $lines.Add('# fallback no Windows PowerShell:')
    $lines.Add('powershell -ExecutionPolicy Bypass -File .\scripts\gerar-catalogos-skills.ps1')
    $lines.Add('```')
    $lines.Add('')
    $lines.Add('## Notas')
    $lines.Add('')
    $lines.Add('- O `spec-kit` e tratado como framework (sem inventario `SKILL.md`).')
    $lines.Add('- Este processo nao usa API externa; gera tudo com dados locais.')
    $lines.Add('')

    Set-Content -LiteralPath $Path -Value $lines -Encoding UTF8
}

if (-not (Test-Path -LiteralPath $Root)) {
    throw "Root invalido: $Root"
}

$repos = Parse-MetadataFile -Path $MetadataFile
$taxonomy = Get-Taxonomy

$entries = New-Object System.Collections.Generic.List[object]
$repoSummary = @{}

foreach ($repo in $repos) {
    $repoPath = Join-Path $Root $repo.repo_id
    if (-not (Test-Path -LiteralPath $repoPath)) {
        throw "Pasta do repositorio nao encontrada para repo_id '$($repo.repo_id)': $repoPath"
    }

    $skillFiles = Get-ChildItem -Path $repoPath -Recurse -File -Filter 'SKILL.md' -ErrorAction SilentlyContinue |
        Sort-Object FullName

    $repoSummary[$repo.repo_id] = ($skillFiles | Measure-Object).Count

    foreach ($skillFile in $skillFiles) {
        $meta = Read-SkillMetadata -Path $skillFile.FullName
        $relativePath = $skillFile.FullName.Substring($Root.Length + 1).Replace('\', '/')
        $pathEscaped = Escape-MarkdownCell -Value $relativePath
        $nameEscaped = Escape-MarkdownCell -Value $meta.name
        $descriptionEscaped = Escape-MarkdownCell -Value $meta.description
        $classificationText = ('{0} {1} {2}' -f $pathEscaped, $nameEscaped, $descriptionEscaped).ToLowerInvariant()
        $class = Classify-Skill -Text $classificationText
        $relevancia = Resolve-Relevancia -Niche $class.niche -Text $classificationText

        $entries.Add([pscustomobject]@{
                repo_id = $repo.repo_id
                name = $nameEscaped
                description = $descriptionEscaped
                path = $pathEscaped
                niche = $class.niche
                area = $class.area
                relevancia_ml = $relevancia
            })
    }
}

Translate-DescriptionsToPortuguese -Entries $entries -CachePath $TranslationCachePath

Write-CatalogDocument -Path $CatalogPath -Repos $repos -Taxonomy $taxonomy -Entries $entries -RepoSummary $repoSummary
Write-Readme -Path $ReadmePath -TotalSkills (($entries | Measure-Object).Count)

Write-Host ("Catalogo unico gerado em: {0}" -f $CatalogPath)
Write-Host ("README atualizado em: {0}" -f $ReadmePath)
