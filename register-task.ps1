# register-task.ps1 — Registrar sync diario automático en Windows Task Scheduler
# Uso: ejecutar UNA SOLA VEZ como administrador
# Resultado: sync.ps1 se ejecutará diariamente a las 09:00 AM

$taskName  = "dotfiles-ai-sync"
$syncScript = "$PSScriptRoot\sync.ps1"

# Verificar que sync.ps1 existe
if (-not (Test-Path $syncScript)) {
    Write-Error "No se encontró sync.ps1 en $PSScriptRoot. Ejecuta desde la raíz del repo."
    exit 1
}

# Eliminar tarea previa si existe
if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    Write-Host "Tarea existente encontrada. Reemplazando..."
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

$action  = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NonInteractive -WindowStyle Hidden -File `"$syncScript`""

$trigger = New-ScheduledTaskTrigger -Daily -At "09:00AM"

$settings = New-ScheduledTaskSettingsSet `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 5) `
    -StartWhenAvailable `
    -DontStopOnIdleEnd

Register-ScheduledTask `
    -TaskName $taskName `
    -Action   $action `
    -Trigger  $trigger `
    -Settings $settings `
    -RunLevel Highest `
    -Description "Backup diario de skills y reglas de AI hacia GitHub (dotfiles-ai)" | Out-Null

Write-Host ""
Write-Host "Tarea registrada: '$taskName'"
Write-Host "  Horario : todos los días a las 09:00 AM"
Write-Host "  Script  : $syncScript"
Write-Host ""
Write-Host "Para ejecutar ahora sin esperar:"
Write-Host "  Start-ScheduledTask -TaskName '$taskName'"
Write-Host ""
Write-Host "Para eliminar la tarea en el futuro:"
Write-Host "  Unregister-ScheduledTask -TaskName '$taskName' -Confirm:`$false"
