# generate-copilot-skill-prompts.ps1
# Genera archivos *.instructions.md en %APPDATA%\Code\User\prompts\ a partir de tus skills.
#
# Objetivo: que VS Code Copilot inyecte tus skills personalizadas automáticamente (applyTo: "**").

param(
  [switch]$DryRun
)

$skills = @(
  "elixir-phoenix-stack",
  "elixir-antipatterns",
  "elixir-error-monad",
  "elixir-legacy-strategy",
  "elixir-amnesia-mnesia",
  "react-python-stack",
  "react-advanced",
  "python-fastapi-ddd",
  "python-antipatterns",
  "testing-conventions"
)

$destDir = "$env:APPDATA\Code\User\prompts"

function Strip-YamlFrontmatter {
  param([string]$raw)
  # Remove the first YAML frontmatter block: --- ... --- (including the trailing newline)
  if ($raw -match "^---[\s\S]*?\n---\n") {
    return ($raw -replace "^---[\s\S]*?\n---\n", "")
  }
  return $raw
}

foreach ($s in $skills) {
  # Source of truth: Copilot skills folder (mirrored from Cursor via skill-sync)
  $src = "$env:USERPROFILE\.copilot\skills\$s\$s\SKILL.md"
  if (-not (Test-Path $src)) {
    Write-Host "SKIP missing: $src"
    continue
  }

  $raw = Get-Content $src -Raw -Encoding UTF8
  $body = Strip-YamlFrontmatter -raw $raw

  $outPath = Join-Path $destDir ("$s.instructions.md")

  $out = @()
  $out += "---"
  $out += "name: $s"
  $out += "description: Copilot injected skill: $s"
  $out += 'applyTo: "**"'
  $out += "alwaysApply: true"
  $out += "---"
  $out += ""
  $out += $body

  $outText = ($out -join "`n")

  if ($DryRun) {
    Write-Host "[DRY-RUN] Would write: $outPath"
  } else {
    Set-Content -Path $outPath -Value $outText -Encoding UTF8
    Write-Host "Generated: $outPath"
  }
}

Write-Host "Done"

