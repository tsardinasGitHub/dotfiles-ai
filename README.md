# dotfiles-ai

Configuración personal del ecosistema [gentle-ai](https://github.com/gentle-ai/gentle-ai) (Gentleman Programming): reglas globales y skills propios para Cursor y VS Code Copilot.

## Contenido

```
cursor/
├── rules/          ← 6 reglas globales (aplican en ambos editores)
│   ├── auto-registry.mdc       — inicializa skill registry automáticamente
│   ├── auto-stack.mdc          — detecta stack y carga skills relevantes
│   ├── verification-first.mdc  — filosofía verification-first y legacy thresholds
│   ├── cognitive-protocol.mdc  — detección de cognitive smells
│   ├── output-protocol.mdc     — formato PROTOCOLO_EJECUTADO
│   └── skill-sync.mdc          — mirror bidireccional de skills entre editores
└── skills/         ← 10 skills propios (nunca sobreescritos por gentle-ai)
    ├── elixir-phoenix-stack/   — convenciones core Phoenix/LiveView/Ecto
    ├── elixir-antipatterns/    — anti-patrones prohibidos en Elixir
    ├── elixir-error-monad/     — patrones del monad Error.m
    ├── elixir-legacy-strategy/ — estrategia segura para código legacy
    ├── elixir-amnesia-mnesia/  — patrones Mnesia vía Amnesia
    ├── react-python-stack/     — convenciones fullstack React + Python/FastAPI
    ├── react-advanced/         — adapter pattern, React Query avanzado, hook architecture
    ├── python-fastapi-ddd/     — DDD/Hexagonal, Pure vs Coordinator, Railway-Oriented
    ├── python-antipatterns/    — anti-patrones prohibidos en Python/FastAPI
    └── testing-conventions/    — testing universal cross-stack (AAA, behavioral)
```

## Restaurar en PC nueva

**Prerequisito**: instalar [gentle-ai](https://github.com/gentle-ai/gentle-ai) y ejecutar:

```powershell
gentle-ai install --agent cursor,vscode-copilot --preset full-gentleman
```

Luego clonar este repo y ejecutar:

```powershell
git clone git@github.com:tsard/dotfiles-ai.git "$env:USERPROFILE\dotfiles-ai"
cd "$env:USERPROFILE\dotfiles-ai"

# Ver qué haría sin tocar nada
.\restore.ps1 -DryRun

# Aplicar
.\restore.ps1
```

Reiniciar Cursor y VS Code. Listo.

## Sincronización manual en bloque

Si por alguna razón los skills no se sincronizaron automáticamente entre editores:

```powershell
$gestionados = @('sdd-init','sdd-explore','sdd-propose','sdd-spec','sdd-design',
                 'sdd-tasks','sdd-apply','sdd-verify','sdd-archive',
                 'go-testing','skill-creator','_shared')

Get-ChildItem "$env:USERPROFILE\.cursor\skills" -Directory |
    Where-Object { $_.Name -notin $gestionados } |
    ForEach-Object {
        Copy-Item -Recurse -Force $_.FullName "$env:USERPROFILE\.copilot\skills\$($_.Name)"
        Write-Host "Sincronizado: $($_.Name)"
    }
```

## Sync automático (backup diario)

`sync.ps1` copia las reglas y skills actuales al repo y hace commit + push automáticamente si detecta cambios. Se ejecuta vía Windows Task Scheduler sin intervención manual.

**Registrar la tarea (una sola vez, como administrador):**

```powershell
cd "$env:USERPROFILE\dotfiles-ai"
.\register-task.ps1
```

La tarea queda programada todos los días a las **09:00 AM**. Si ese día no hubo cambios, termina silenciosamente sin crear commits vacíos.

**Rotación mensual de logs:** una vez al mes, `sync.ps1` copia el log local (`sync.log`) a `sync-archive.log` en el repo y lo sube a GitHub — sobreescribiendo el del mes anterior. Así siempre hay un mes de traza en el repo sin que el log crezca indefinidamente. `sync.log` queda solo en la PC (ignorado por git).

**Ejecutar manualmente en cualquier momento:**

```powershell
.\sync.ps1
```

**Ejecutar la tarea ahora sin esperar a las 09:00 AM:**

```powershell
Start-ScheduledTask -TaskName 'dotfiles-ai-sync'
```

**Eliminar la tarea (si cambias de PC o quieres reconfigurar):**

```powershell
Unregister-ScheduledTask -TaskName 'dotfiles-ai-sync' -Confirm:$false
```

## Verificar que el sync está funcionando

El log se escribe **siempre** al correr, haya o no cambios. Si no hay entrada de hoy, la tarea no corrió.

**Ver las últimas entradas del log:**

```powershell
Get-Content "$env:USERPROFILE\dotfiles-ai\sync.log" -Tail 20
```

**Ver cuándo corrió por última vez y si fue exitoso:**

```powershell
Get-ScheduledTaskInfo -TaskName 'dotfiles-ai-sync' | Select-Object LastRunTime, LastTaskResult
```

`LastTaskResult = 0` significa éxito. Cualquier otro valor indica un error.

**Señal de alerta:** si la última entrada en `sync.log` tiene más de 2 días de antigüedad, la tarea dejó de correr — re-ejecutar `register-task.ps1` como administrador.

## Engram (memoria persistente)

La memoria de las sesiones vive en `%USERPROFILE%\.engram\engram.db`.  
Recomendado: sincronizar la carpeta `~\.engram\` con OneDrive o Google Drive para no perderla ante fallo de hardware.
