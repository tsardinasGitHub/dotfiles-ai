# sync.ps1 — Sincronizar configuración local de AI hacia el repo (backup a GitHub)
# Uso: .\sync.ps1
# Se ejecuta automáticamente vía Task Scheduler. Ver register-task.ps1

$repo          = $PSScriptRoot
$cursorRules   = "$env:USERPROFILE\.cursor\rules"
$cursorSkills  = "$env:USERPROFILE\.cursor\skills"
$logFile       = "$repo\sync.log"
$archiveFile   = "$repo\sync-archive.log"

$managed = @(
    'sdd-init', 'sdd-explore', 'sdd-propose', 'sdd-spec', 'sdd-design',
    'sdd-tasks', 'sdd-apply', 'sdd-verify', 'sdd-archive',
    'go-testing', 'skill-creator', '_shared'
)

function Log($msg) {
    $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  $msg"
    Write-Host $line
    Add-Content -Path $logFile -Value $line -Encoding UTF8
}

function LogBlank() {
    Write-Host ""
    Add-Content -Path $logFile -Value "" -Encoding UTF8
}

# --- Rotación mensual ---
# Si el archivo de archivo existe y es de un mes anterior, rotar.
# Si no existe todavía, rotar en cuanto haya algo que archivar.
$needsRotation = $false
if (Test-Path $logFile) {
    $logContent = Get-Content $logFile -Raw -Encoding UTF8
    if ($logContent -and $logContent.Trim()) {
        if (Test-Path $archiveFile) {
            $archiveDate = (Get-Item $archiveFile).LastWriteTime
            $now = Get-Date
            if ($archiveDate.Year -ne $now.Year -or $archiveDate.Month -ne $now.Month) {
                $needsRotation = $true
            }
        } else {
            $needsRotation = $true
        }
    }
}

if ($needsRotation) {
    $monthLabel = (Get-Item $logFile).LastWriteTime.ToString('yyyy-MM')
    $header = "# Log archivado: $monthLabel"
    Set-Content -Path $archiveFile -Value $header -Encoding UTF8
    Get-Content $logFile -Encoding UTF8 | Add-Content -Path $archiveFile -Encoding UTF8
    Clear-Content $logFile
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  [ROTACION] Log de $monthLabel archivado en sync-archive.log"
    Add-Content -Path $logFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  [ROTACION] Log de $monthLabel archivado en sync-archive.log" -Encoding UTF8
}

LogBlank
Log "=== dotfiles-ai sync ==="

# --- Reglas globales ---
LogBlank
Log "Sincronizando reglas..."
if (Test-Path $cursorRules) {
    Get-ChildItem "$cursorRules\*.mdc" -File -ErrorAction SilentlyContinue | ForEach-Object {
        Copy-Item -Force $_.FullName "$repo\cursor\rules\$($_.Name)"
        Log "  regla: $($_.Name)"
    }
} else {
    Log "  [SKIP] $cursorRules no encontrado"
}

# --- Skills propios (excluir gestionados por gentle-ai) ---
LogBlank
Log "Sincronizando skills..."
if (Test-Path $cursorSkills) {
    Get-ChildItem $cursorSkills -Directory | Where-Object { $_.Name -notin $managed } | ForEach-Object {
        $dst = "$repo\cursor\skills\$($_.Name)"
        Copy-Item -Recurse -Force $_.FullName $dst
        Log "  skill: $($_.Name)"
    }
} else {
    Log "  [SKIP] $cursorSkills no encontrado"
}

# --- Commit y push si hay cambios ---
LogBlank
$status = git -C $repo status --porcelain 2>&1
if ($status) {
    Log "Cambios detectados:"
    $status | ForEach-Object { Log "  $_" }
    git -C $repo add . | Out-Null
    $date = Get-Date -Format 'yyyy-MM-dd'
    git -C $repo commit -m "sync: $date" | Out-Null
    Log "Commit realizado: sync: $date"
    git -C $repo push 2>&1 | Out-Null
    Log "Push completado."
} else {
    Log "Sin cambios. Nada que commitear."
}
LogBlank
