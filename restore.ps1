# restore.ps1 — Restaurar configuración de AI en PC nueva
# Uso: .\restore.ps1
# Prerequisito: gentle-ai ya debe estar instalado (gentle-ai install --agent cursor,vscode-copilot --preset full-gentleman)

param(
    [switch]$DryRun
)

$repo = $PSScriptRoot
$cursorRules  = "$env:USERPROFILE\.cursor\rules"
$cursorSkills = "$env:USERPROFILE\.cursor\skills"
$copilotSkills = "$env:USERPROFILE\.copilot\skills"

function Sync-Item($src, $dst) {
    if ($DryRun) {
        Write-Host "[DRY-RUN] $src → $dst"
    } else {
        $parent = Split-Path $dst -Parent
        if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        Copy-Item -Recurse -Force $src $dst
    }
}

Write-Host ""
Write-Host "=== Restaurando reglas globales ==="
Get-ChildItem "$repo\cursor\rules" -File | ForEach-Object {
    Sync-Item $_.FullName "$cursorRules\$($_.Name)"
    Write-Host "  Regla: $($_.Name)"
}

Write-Host ""
Write-Host "=== Restaurando skills (Cursor + VS Code Copilot) ==="
Get-ChildItem "$repo\cursor\skills" -Directory | ForEach-Object {
    Sync-Item $_.FullName "$cursorSkills\$($_.Name)"
    Sync-Item $_.FullName "$copilotSkills\$($_.Name)"
    Write-Host "  Skill: $($_.Name)"
}

Write-Host ""
if ($DryRun) {
    Write-Host "DRY-RUN completado. Ejecuta sin -DryRun para aplicar."
} else {
    Write-Host ""
    Write-Host "=== Generando *.instructions.md para Copilot ==="
    & "$repo\\generate-copilot-skill-prompts.ps1"
    Write-Host ""
    Write-Host "Restauración completada."
    Write-Host ""
    Write-Host "Próximos pasos:"
    Write-Host "  1. Reinicia Cursor y VS Code"
    Write-Host "  2. Abre un repo y verifica que el skill registry se inicialice automáticamente"
}
