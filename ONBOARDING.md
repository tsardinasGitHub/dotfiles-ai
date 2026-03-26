# Gentle AI — Onboarding Completo

> **Configurado para:** React + Python / Elixir | Cursor + VS Code Copilot | Windows

---

## Índice

1. [¿Qué es Gentle AI?](#1-qué-es-gentle-ai)
2. [Componentes en profundidad](#2-componentes-en-profundidad)
3. [Comandos CLI completos](#3-comandos-cli-completos)
4. [Agentes soportados](#4-agentes-soportados)
5. [Presets y Skills](#5-presets-y-skills)
6. [Rutas de configuración en Windows](#6-rutas-de-configuración-en-windows)
7. [GUÍA PRÁCTICA: Cómo ponerlo todo en marcha](#7-guía-práctica-cómo-ponerlo-todo-en-marcha)
   - [Fase 0 — Instalación única](#fase-0--instalación-única-hazlo-una-sola-vez)
   - [Fase 1 — Personalización global por stack](#fase-1--personalización-global-por-stack-hazlo-una-vez-por-stack)
   - [Fase 2 — Primer repo nuevo](#fase-2--cada-vez-que-abres-un-repo-nuevo)
   - [Fase 3 — Flujo de trabajo diario](#fase-3--flujo-de-trabajo-diario)
   - [Fase 4 — Mantenimiento del ecosistema](#fase-4--mantenimiento-del-ecosistema)
8. [Personalización global vs local](#8-personalización-global-vs-local-sin-miedo-a-upgrades)
9. [Trabajar con Cursor y VS Code indistintamente](#9-trabajar-con-cursor-y-vs-code-indistintamente)
10. [Referencia rápida](#10-referencia-rápida)

---

## 1. ¿Qué es Gentle AI?

Gentle AI **no es un instalador de agentes de IA** — es un **configurador de ecosistema**. Toma los agentes que ya usas (Cursor, VS Code Copilot, Claude Code…) y los potencia con una capa de memoria, flujo de trabajo, conocimiento especializado y personalidad.

**Antes de instalarlo**: tu agente es un chatbot que escribe código. Cada sesión empieza desde cero. No sabe nada de tus patrones, tu arquitectura, tus decisiones pasadas ni tus convenciones de equipo.

**Después de instalarlo**: tu agente recuerda todo entre sesiones, tiene un workflow estructurado para features complejas, consulta documentación actualizada de tus frameworks en tiempo real, y sigue tus convenciones de stack sin que tengas que repetirlas.

La **regla de oro**: cuanto menos pienses en Gentle AI después de instalarlo, mejor está funcionando. No hay comandos que memorizar ni workflows que aprender. Solo abres tu editor y trabajas.

---

## 2. Componentes en profundidad

### Engram — Memoria Persistente

**Qué es**: un servidor de memoria para tu agente de IA. Persiste contexto entre sesiones usando un sistema de observaciones estructuradas.

**Qué guarda automáticamente**:
- Decisiones de arquitectura ("usamos Zustand, no Redux en este proyecto")
- Bugs resueltos y su causa raíz
- Patrones descubiertos en el codebase
- Contexto de features en progreso
- Resultados de cada fase SDD

**Cómo funciona internamente**: el agente tiene instrucciones para llamar a `mem_save` antes de terminar una sesión y `mem_search` al comenzar una nueva. Esto ocurre de forma autónoma — tú no lo ves ni interactúas con ello.

**Qué NO debes hacer**: acceder a los archivos de Engram, modificarlos, ni intentar gestionarlo manualmente. Si está funcionando bien, es invisible.

**Personalización**: ninguna necesaria. Funciona out-of-the-box.

---

### SDD — Spec-Driven Development

**Qué es**: un workflow de 9 fases para implementar features sustanciales con calidad. No es un proceso que tú sigues — es uno que el agente sigue internamente.

**Las 9 fases** (el agente las gestiona, tú solo apruebas en puntos clave):

| Fase | Skill | Qué hace el agente |
|------|-------|--------------------|
| 1 | `sdd-init` | Establece el contexto SDD del proyecto |
| 2 | `sdd-explore` | Investiga el codebase, entiende el estado actual |
| 3 | `sdd-propose` | Propone el enfoque con intención, scope y alternativas |
| 4 | `sdd-spec` | Escribe los requisitos y escenarios de aceptación |
| 5 | `sdd-design` | Diseña la arquitectura técnica y las decisiones |
| 6 | `sdd-tasks` | Descompone en tareas atómicas e independientes |
| 7 | `sdd-apply` | Implementa siguiendo specs y diseño |
| 8 | `sdd-verify` | Valida que la implementación cumple las specs |
| 9 | `sdd-archive` | Archiva las specs delta en la documentación principal |

**Cuándo se activa**:
- **Tarea pequeña** → el agente la hace directamente, sin SDD
- **Feature sustancial** → el agente sugiere "esto merece SDD, ¿empezamos?"
- **Tú lo pides explícitamente** → escribe `"usa sdd"` o `"hazlo con sdd"` en el chat

**Sub-agentes**: en Cursor y VS Code Copilot, cuando SDD se activa el orquestador delega cada fase a un sub-agente especializado. Cada sub-agente busca el skill registry, carga los skills relevantes para tu proyecto, ejecuta su fase y persiste el resultado en Engram antes de retornar. El siguiente sub-agente lo recoge desde donde el anterior lo dejó.

**Personalización global**: crea un skill de stack (ver Fase 1 de la guía práctica). El sub-agente `sdd-apply` cargará automáticamente tus convenciones de React o Elixir cuando trabaje en esos proyectos.

**Personalización local por repo**: crea un archivo `AGENTS.md` o `.cursorrules` en la raíz del repo con tus convenciones específicas. El skill registry los detecta y los incluye en el contexto del orquestador.

---

### Skills — Biblioteca de Conocimiento Especializado

**Qué son**: archivos Markdown con instrucciones precisas para el agente sobre cómo hacer algo específico. No son código — son conocimiento estructurado que el agente lee y aplica.

**Cómo los carga el agente**: a través del skill registry (`.atl/skill-registry.md`). El orquestador lee el registry al inicio de la sesión y sabe exactamente qué skills existen, dónde están y cuándo aplicarlos.

**Los 11 skills instalados globalmente**:

| Skill | Directorio | Propósito |
|-------|------------|-----------|
| `sdd-init` | `~\.cursor\skills\sdd-init\` | Bootstrapping SDD en un proyecto |
| `sdd-explore` | `~\.cursor\skills\sdd-explore\` | Investigación pre-implementación |
| `sdd-propose` | `~\.cursor\skills\sdd-propose\` | Propuesta de cambio estructurada |
| `sdd-spec` | `~\.cursor\skills\sdd-spec\` | Escritura de especificaciones |
| `sdd-design` | `~\.cursor\skills\sdd-design\` | Diseño técnico y decisiones de arquitectura |
| `sdd-tasks` | `~\.cursor\skills\sdd-tasks\` | Descomposición en tareas atómicas |
| `sdd-apply` | `~\.cursor\skills\sdd-apply\` | Implementación guiada por specs |
| `sdd-verify` | `~\.cursor\skills\sdd-verify\` | Verificación contra especificaciones |
| `sdd-archive` | `~\.cursor\skills\sdd-archive\` | Archivado y sincronización de docs |
| `go-testing` | `~\.cursor\skills\go-testing\` | Patrones de testing en Go |
| `skill-creator` | `~\.cursor\skills\skill-creator\` | Cómo crear nuevos skills correctamente |

**Skills compartidos** (fragmentos comunes que todos los skills importan):

| Fragmento | Propósito |
|-----------|-----------|
| `_shared\persistence-contract.md` | Contrato de cómo persistir en Engram |
| `_shared\engram-convention.md` | Convenciones de uso de memoria |
| `_shared\openspec-convention.md` | Formato de specs |
| `_shared\sdd-phase-common.md` | Comportamiento común a todas las fases SDD |

**Skills personalizados**: puedes crear los tuyos propios en `~\.cursor\skills\nombre-custom\SKILL.md`. Gentle-ai **nunca sobreescribe directorios que no gestiona**, por lo que son seguros ante cualquier `sync` o `upgrade`.

**Skills propios ya creados para tus stacks**:

| Skill | Stack | Propósito |
|-------|-------|-----------|
| `elixir-phoenix-stack` | Elixir | Convenciones core Phoenix/LiveView/Ecto: patrones, estructura, GenServer, supervisores |
| `elixir-antipatterns` | Elixir | Anti-patrones prohibidos: complejidad, error handling, N+1, concurrencia, testing |
| `elixir-error-monad` | Elixir | Patrones correctos del monad `Error.m`: propagación, composición, diseño monádico |
| `elixir-legacy-strategy` | Elixir | Estrategia segura para codebases legacy: documentar → caracterizar → refactorizar |
| `elixir-amnesia-mnesia` | Elixir | Patrones Mnesia vía Amnesia: `deftable`, CRUD en transacciones, migración de esquema |
| `react-python-stack` | React + Python | Convenciones fullstack: Server Components, Zustand, TanStack Query, FastAPI, Pydantic |
| `react-advanced` | React | Adapter Pattern, React Query avanzado, arquitectura de hooks, error UI obligatorio |
| `python-fastapi-ddd` | Python | DDD/Hexagonal: Pure vs Coordinator, Protocol DI, Railway-Oriented, límites de módulo |
| `python-antipatterns` | Python | Anti-patrones prohibidos: fat routers, Pydantic como dominio, `.unwrap()` unsafe, N+1 |
| `testing-conventions` | Cross-stack | Testing universal: AAA, behavioral testing, mocking en interfaces, tests de integración |

---

### Context7 — Documentación Viva de Frameworks

**Qué es**: un servidor MCP (Model Context Protocol) que da al agente acceso a la documentación actualizada de cualquier librería o framework, directamente desde el contexto de la conversación.

**Por qué importa**: los LLMs tienen fecha de corte de entrenamiento. Context7 le da al agente acceso a la documentación real y actual de React 19, Phoenix 1.7, FastAPI, Ecto, etc. — no versiones viejas o alucinadas.

**Cuándo lo usa el agente**: automáticamente cuando trabaja con un framework o librería conocida. No necesitas pedírselo.

**Configuración en Windows**:
- Cursor: entrada en `~\.cursor\mcp.json` usando `npx -y @upstash/context7-mcp`
- VS Code Copilot: entrada en `%APPDATA%\Code\User\mcp.json` usando URL HTTP `https://mcp.context7.com/mcp`

**Personalización**: ninguna necesaria. Se instala automáticamente con gentle-ai.

---

### Persona — Comportamiento y Tono del Agente

**Qué es**: un system prompt base que define cómo se comporta el agente contigo. No solo el tono — también sus principios de decisión.

**Opciones disponibles**:

| Persona | Comportamiento |
|---------|----------------|
| `gentleman` (default) | Mentor orientado a enseñanza. Explica el "por qué". Cuestiona malas prácticas. Te hace pensar antes de darte la solución. Push back en anti-patterns. |
| `neutral` | Tono profesional, solo hechos. Sin personalidad. Hace lo que se le pide sin añadir contexto adicional. |
| `custom` | Tú defines el system prompt completo. Útil si tienes instrucciones muy específicas de empresa o flujo. |

**Recomendación**: `gentleman` es la opción correcta si quieres crecer como desarrollador. `neutral` si solo quieres ejecución rápida.

**Personalización por repo**: crea un `AGENTS.md` en la raíz del repo con instrucciones adicionales. El skill registry las detecta y las añade al contexto sin sobreescribir la persona base.

---

### Permissions — Guardrails de Seguridad

**Qué es**: un conjunto de restricciones que evitan que el agente tome acciones destructivas sin confirmación explícita.

**Qué previene**: borrado de archivos sin confirmación, commits automáticos, modificaciones fuera del scope acordado, acciones irreversibles sin aprobación.

**Cuándo lo notas**: cuando el agente te pide confirmación antes de hacer algo que podría tener consecuencias amplias.

**Personalización**: para repos donde quieras más o menos restricciones, puedes ajustar las instrucciones en el `AGENTS.md` del proyecto.

---

### GGA — Gentleman Guardian Angel

**Qué es**: un switcher de proveedor de IA por repositorio. Te permite usar Claude en un proyecto, GPT-4 en otro, y Gemini en un tercero, sin cambiar la configuración global de tu editor.

**Cómo funciona**: GGA instala un git hook en el repo. Cuando haces `cd` al directorio, el hook activa automáticamente el proveedor configurado para ese proyecto.

**Comandos** (desde Git Bash en Windows, no PowerShell):

```bash
gga init      # inicializa GGA en el repo actual
gga install   # instala el git hook
```

**Cuándo usarlo**: por proyecto, cuando quieras controlar qué modelo usa cada repo.

**Limitación en Windows**: GGA solo funciona en Git Bash. No funciona en PowerShell ni CMD. Esto es una limitación de GGA, no de Gentle AI.

---

### Theme — Gentleman Kanagawa

**Qué es**: overlay del tema visual Kanagawa adaptado al ecosistema Gentleman. Opcional.

**Cómo activarlo**: no está incluido en `full-gentleman` por defecto. Se activa pasando `--component theme` al instalar o con el TUI.

---

## 3. Comandos CLI completos

### `gentle-ai` (sin argumentos) — TUI interactiva

```powershell
gentle-ai
```

Lanza la interfaz visual que guía paso a paso: detección de agentes instalados → selección → persona → preset → modo SDD → árbol de dependencias → revisión → instalación.

---

### `gentle-ai install`

Pipeline completo: snapshot de backup → instalación de binarios → inyección de componentes → verificación.

```powershell
# Instalación para tu setup completo
gentle-ai install --agent cursor,vscode-copilot --preset full-gentleman

# Ver qué haría sin tocar nada (SIEMPRE hacer esto primero)
gentle-ai install --dry-run --agent cursor,vscode-copilot --preset full-gentleman

# Instalación granular (preset custom)
gentle-ai install \
  --agent cursor,vscode-copilot \
  --component engram,sdd,skills,context7,persona,permissions,gga \
  --skill sdd-init,sdd-apply,sdd-verify,skill-creator \
  --persona gentleman \
  --preset custom
```

**Flags completos**:

| Flag | Descripción | Valores posibles |
|------|-------------|------------------|
| `--agent` / `--agents` | Agentes a configurar | `cursor`, `vscode-copilot`, `claude-code`, `opencode`, `gemini-cli` |
| `--component` / `--components` | Componentes | `engram`, `sdd`, `skills`, `context7`, `persona`, `permissions`, `gga`, `theme` |
| `--skill` / `--skills` | Skills específicos | ver tabla de skills |
| `--persona` | Modo de persona | `gentleman`, `neutral`, `custom` |
| `--preset` | Preset | `full-gentleman`, `ecosystem-only`, `minimal`, `custom` |
| `--sdd-mode` | Modo SDD | `single` (default), `multi` (solo OpenCode) |
| `--dry-run` | Solo muestra el plan | — |

---

### `gentle-ai sync`

Re-aplica la configuración gestionada (SDD, Engram, Context7, GGA, Skills) sin reinstalar binarios ni re-ejecutar Engram setup. Úsalo después de un `upgrade` para propagar mejoras a los agentes.

```powershell
# Sync automático (detecta agentes instalados)
gentle-ai sync

# Sync para tus agentes específicos
gentle-ai sync --agent cursor,vscode-copilot

# Con permisos y tema también
gentle-ai sync --agent cursor,vscode-copilot --include-permissions --include-theme

# Ver el plan sin ejecutar
gentle-ai sync --dry-run
```

---

### `gentle-ai update`

Solo lectura. Compara versiones locales vs GitHub Releases de `gentle-ai`, `engram` y `gga`.

```powershell
gentle-ai update
```

---

### `gentle-ai upgrade`

Actualiza los binarios. Hace snapshot de configs antes de actualizar.

```powershell
gentle-ai upgrade              # actualiza todo
gentle-ai upgrade gentle-ai   # solo gentle-ai
gentle-ai upgrade --dry-run   # ver qué haría
```

---

### `gentle-ai restore`

Restaura desde backups en `%USERPROFILE%\.gentle-ai\backups\`.

```powershell
gentle-ai restore --list       # ver todos los backups
gentle-ai restore latest       # restaurar el más reciente
gentle-ai restore <id>         # restaurar uno específico
gentle-ai restore latest --yes # sin confirmación interactiva
```

---

### `gentle-ai version`

```powershell
gentle-ai version
gentle-ai --version
gentle-ai -v
```

---

## 4. Agentes soportados

| Agente | ID | SDD | MCP | Sub-agentes | Config Windows |
|--------|-----|-----|-----|-------------|----------------|
| **Cursor** | `cursor` | Sí | Sí | Sí (v2.5+ async) | `%USERPROFILE%\.cursor\` |
| **VS Code Copilot** | `vscode-copilot` | Sí | Sí | Sí (runSubagent) | `%APPDATA%\Code\User\` + `%USERPROFILE%\.copilot\` |
| Claude Code | `claude-code` | Sí | Sí | Sí (Agent tool) | `%USERPROFILE%\.claude\` |
| OpenCode | `opencode` | Sí + Multi-mode | Sí | Nativo | `%USERPROFILE%\.config\opencode\` |
| Gemini CLI | `gemini-cli` | Sí | Sí | Experimental | `%USERPROFILE%\.gemini\` |

**Diferencias importantes para tu setup**:
- Cursor y VS Code Copilot no tienen slash commands — todo se hace en lenguaje natural en el chat
- Multi-mode SDD (diferentes modelos por fase) es exclusivo de OpenCode
- El skill registry funciona igual en ambos editores — el archivo `.atl/skill-registry.md` es por proyecto, no por editor

---

## 5. Presets y Skills

### Presets

| Preset | Componentes incluidos | Cuándo usarlo |
|--------|----------------------|---------------|
| `full-gentleman` | Todo: engram + sdd + skills + context7 + persona + permissions + gga | Setup inicial. Máximo potencial. |
| `ecosystem-only` | Todo excepto persona y permissions en código | Si prefieres gestionar tú las instrucciones de comportamiento |
| `minimal` | Solo Engram | Si solo quieres memoria persistente |
| `custom` | Tú eliges todo | Control total |

### Qué sobreescribe cada `sync` / `upgrade`

Esto es crítico para entender qué es seguro personalizar:

| Directorio / Archivo | ¿Lo sobreescribe gentle-ai? |
|---------------------|---------------------------|
| `~\.cursor\skills\sdd-*\` | **Sí** — gestionado |
| `~\.cursor\skills\go-testing\` | **Sí** — gestionado |
| `~\.cursor\skills\skill-creator\` | **Sí** — gestionado |
| `~\.cursor\skills\_shared\` | **Sí** — gestionado |
| `~\.cursor\skills\mi-stack-react\` | **No** — tuyo para siempre |
| `~\.cursor\skills\elixir-phoenix\` | **No** — tuyo para siempre |
| `~\.cursor\rules\gentle-ai.mdc` | **Sí** — gestionado (persona + orquestador) |
| `~\.cursor\mcp.json` | **Sí** (solo sus entradas, no las tuyas) |
| `.atl\skill-registry.md` (en el repo) | **No** — se regenera cuando tú lo pides |
| `.atl\skills\` (en el repo) | **No** — tus skills locales |

---

## 6. Rutas de configuración en Windows

| Qué | Cursor | VS Code Copilot |
|-----|--------|-----------------|
| Skills globales | `%USERPROFILE%\.cursor\skills\` | `%USERPROFILE%\.copilot\skills\` |
| System prompt / Orquestador | `%USERPROFILE%\.cursor\rules\gentle-ai.mdc` | `%APPDATA%\Code\User\prompts\gentle-ai.instructions.md` |
| MCP servers | `%USERPROFILE%\.cursor\mcp.json` | `%APPDATA%\Code\User\mcp.json` |
| Settings | `%USERPROFILE%\.cursor\settings.json` | `%APPDATA%\Code\User\settings.json` |
| Backups gentle-ai | `%USERPROFILE%\.gentle-ai\backups\` | (mismo) |
| Skill registry (por proyecto) | `.atl\skill-registry.md` | (mismo archivo) |
| Skills locales (por proyecto) | `.atl\skills\` | (mismo directorio) |
| GGA config | `%USERPROFILE%\.config\gga\` | (mismo) |

---

## 7. GUÍA PRÁCTICA: Cómo ponerlo todo en marcha

Esta sección es la más importante. Las anteriores son referencia — esta es acción.

---

### Fase 0 — Instalación única (hazlo una sola vez)

> Ya completada en tu caso. Está documentada aquí para referencia futura.

**Problema conocido en Windows**: Cursor no crea `settings.json` hasta que cambias algo en la configuración. Si el instalador falla con ese archivo, créalo manualmente:

```powershell
echo '{}' | Out-File -FilePath "$env:USERPROFILE\.cursor\settings.json" -Encoding utf8 -NoNewline
```

Luego re-ejecuta:

```powershell
gentle-ai install --agent cursor,vscode-copilot --preset full-gentleman
```

Resultado esperado: `Verification checks: 64 passed, 0 failed`

**Después de la instalación**: reinicia Cursor y VS Code para que carguen las nuevas configuraciones de MCP y el system prompt.

---

### Fase 1 — Personalización global por stack (hazlo una vez por stack)

Esta fase configura skills globales que aplican a todos tus proyectos de ese stack, sin riesgo de ser sobreescritos en upgrades futuros.

#### 1.1 — Crear el skill para React + Python

Abre Cursor en cualquier proyecto y escribe en el chat:

```
Usa el skill-creator para crear un skill llamado "react-python-stack" con estas convenciones:

Frontend (React):
- React 19 con Server Components y hooks modernos
- Estado global con Zustand (no Redux ni Context para estado global)
- Server state con TanStack Query v5
- Estilos con Tailwind CSS, no CSS-in-JS
- Componentes siempre funcionales, nunca de clase
- Estructura feature-based: cada feature tiene su carpeta con componente, hook, types y test
- Tests con Vitest + Testing Library (no Enzyme)
- Validación de formularios con React Hook Form + Zod

Backend (Python):
- FastAPI como framework principal [ajusta si usas Django/Flask]
- Tipado estricto con Pydantic v2
- Tests con pytest + pytest-asyncio para async
- Estructura por dominio, no por tipo de archivo
- SQLAlchemy con Alembic para migraciones [o el ORM que uses]

Decisiones de equipo:
- Commits en inglés, PRs en español
- Sin comentarios que expliquen qué hace el código, solo por qué
- Tipos explícitos siempre, no inferidos cuando haya ambigüedad
```

El agente creará el skill usando el `skill-creator` instalado. Pedirle explícitamente que lo guarde en `%USERPROFILE%\.cursor\skills\react-python-stack\SKILL.md`.

Luego replicarlo en VS Code Copilot:

```powershell
# Copiar el skill al directorio de VS Code Copilot
Copy-Item -Recurse "$env:USERPROFILE\.cursor\skills\react-python-stack" "$env:USERPROFILE\.copilot\skills\react-python-stack"
```

#### 1.2 — Crear el skill para Elixir

```
Usa el skill-creator para crear un skill llamado "elixir-phoenix-stack" con estas convenciones:

- Phoenix 1.7 con LiveView para interfaces reactivas
- Ecto con PostgreSQL, migraciones siempre con timestamps
- GenServers con estado definido en structs tipados (defstruct con @type t)
- Supervisores con estrategia :one_for_one por defecto salvo justificación
- Pattern matching sobre condicionales (case/cond sobre if/else anidados)
- Pipe operator para transformaciones de datos, no variables intermedias
- Bounded Contexts como estructura de módulos (no MVC plano)
- Tests con ExUnit + Mox para mocks (no test de implementación, test de comportamiento)
- Doctests en funciones públicas de módulos de dominio
- Sin abreviaciones en nombres de variables ni módulos

Convenciones de LiveView:
- handle_event para interacciones de usuario
- Estado en assigns, no en procesos separados salvo necesidad real
- Componentes funcionales para UI reutilizable
```

Guardarlo en `%USERPROFILE%\.cursor\skills\elixir-phoenix-stack\SKILL.md` y replicar en `.copilot`.

#### 1.3 — Verificar que los skills están en su sitio

```powershell
ls "$env:USERPROFILE\.cursor\skills\"
# Debes ver: sdd-*, go-testing, skill-creator, _shared, react-python-stack, elixir-phoenix-stack
```

#### 1.4 — Crear un skill de testing cross-stack (opcional pero recomendado)

```
Usa el skill-creator para crear un skill llamado "testing-conventions" con estas convenciones
de testing que aplican a todos nuestros proyectos:

- Tests que prueban comportamiento, no implementación
- Arrange-Act-Assert como estructura interna
- Un test = una aserción de comportamiento (pueden ser múltiples asserts si es la misma cosa)
- Nombres descriptivos: "should [comportamiento] when [condición]"
- Sin mocks de módulos enteros, mockear interfaces/contratos específicos
- Tests de integración para flujos críticos, no solo unitarios
- No testear getters/setters triviales
```

---

### Fase 2 — Cada vez que abres un repo nuevo

> Esto es lo único que debes hacer por repo. Son 2 minutos.

#### Paso 1 — Abrir el repo en tu editor

Ábrelo normalmente en Cursor o VS Code.

#### Paso 2 — Inicializar el skill registry

En el chat del agente, escribe:

```
Inicializa el skill registry para este proyecto.
```

El agente ejecutará la lógica del `skill-registry`: escaneará todos los skills globales (`~\.cursor\skills\` o `~\.copilot\skills\`), leerá el frontmatter de cada uno, detectará si hay archivos de convenciones locales (`AGENTS.md`, `.cursorrules`, `CLAUDE.md`), y generará `.atl\skill-registry.md` en la raíz del repo.

**Qué contiene ese archivo**:
- Un índice de todos los skills disponibles con sus rutas
- Cuándo aplicar cada uno
- Las convenciones locales del proyecto detectadas

A partir de este momento, el orquestador SDD sabe exactamente qué skills tiene disponibles y cuándo usarlos.

#### Paso 3 (opcional) — Contextualizar el proyecto

Si es un proyecto con arquitectura particular o decisiones importantes, dale contexto al agente:

```
Este es un proyecto de [tipo]. Usamos [stack específico].
Las decisiones importantes de arquitectura son: [X, Y, Z].
El agente debe cargar el skill "react-python-stack" / "elixir-phoenix-stack" para este proyecto.
```

Engram guardará este contexto y estará disponible en todas las sesiones futuras de este repo.

#### Paso 4 (opcional) — GGA por proyecto si quieres cambiar modelo

Desde Git Bash (no PowerShell):

```bash
cd tu-proyecto
gga init
gga install
```

---

### Fase 3 — Flujo de trabajo diario

Una vez que tienes la Fase 0, 1 y 2 hechas, el flujo diario es:

**Abres el editor → abres el chat → trabajas.**

Nada más. El agente ya tiene:
- Contexto de sesiones anteriores (Engram)
- Skills de tu stack cargados (skill registry)
- Documentación actualizada disponible (Context7)
- SDD listo para activarse cuando lo necesite (orquestador)

#### Lo que PUEDES decirle al agente para sacar más partido:

| Quieres... | Dile al agente... |
|------------|-------------------|
| Implementar una feature compleja | `"Implementa X, usa sdd"` |
| Que investigue antes de tocar nada | `"Antes de implementar, explora el codebase y dime qué impacto tendría"` |
| Que recuerde una decisión importante | `"Guarda en memoria que en este proyecto usamos X patrón porque Y"` |
| Recuperar contexto de sesión anterior | `"¿Qué estábamos haciendo en la última sesión?"` |
| Que siga tus convenciones de stack | El skill ya está cargado — no hace falta decirle nada |
| Que revise tu código | `"Revisa esto con SDD verify"` |
| Crear un skill nuevo | `"Usa skill-creator para crear un skill de [X]"` |

#### Lo que NO debes hacer:

- Explicar tus convenciones en cada sesión — si lo estás haciendo, el skill registry no está bien configurado
- Memorizar las fases SDD — si lo estás haciendo, estás usando SDD demasiado manualmente
- Interactuar con Engram directamente — si lo estás haciendo, algo está mal

---

### Fase 4 — Mantenimiento del ecosistema

#### Rutina mensual (5 minutos)

```powershell
# 1. Ver si hay actualizaciones
gentle-ai update

# 2. Si hay, actualizar los binarios
gentle-ai upgrade --dry-run  # ver el plan primero
gentle-ai upgrade             # ejecutar

# 3. Propagar cambios a los configs de los agentes
gentle-ai sync --agent cursor,vscode-copilot
```

#### Después de `sync`, en el primer repo que abras:

```
Actualiza el skill registry, puede haber skills nuevos del último sync de gentle-ai.
```

#### Cuándo re-ejecutar el skill registry en un repo:

- Después de un `gentle-ai sync` (puede haber skills nuevos)
- Después de crear un skill nuevo (global o local)
- Después de modificar un skill existente
- Cuando añadas un `AGENTS.md` o `.cursorrules` al proyecto
- Si el agente parece ignorar convenciones que debería conocer

#### Si algo se rompe:

```powershell
# Ver backups disponibles
gentle-ai restore --list

# Restaurar el último backup bueno
gentle-ai restore latest
```

---

## 8. Personalización global vs local (sin miedo a upgrades)

### La regla de seguridad

Gentle-ai solo sobreescribe los directorios y archivos que él mismo creó con nombres específicos. Todo lo que pongas en directorios con **nombres distintos** es tuyo para siempre.

```
~\.cursor\skills\
├── sdd-apply\          ← GESTIONADO (se sobreescribe en upgrade)
├── sdd-init\           ← GESTIONADO
├── go-testing\         ← GESTIONADO
├── skill-creator\      ← GESTIONADO
├── _shared\            ← GESTIONADO
│
├── react-python-stack\ ← TUYO ✓ (nunca se toca)
├── elixir-phoenix\     ← TUYO ✓ (nunca se toca)
└── testing-conventions\← TUYO ✓ (nunca se toca)
```

Lo mismo aplica en `~\.copilot\skills\`.

### Skills globales vs locales

| Tipo | Dónde vive | Aplica a | Sobrevive upgrade |
|------|-----------|----------|-------------------|
| **Skill global de stack** | `~\.cursor\skills\mi-stack\SKILL.md` | Todos los proyectos | Sí ✓ |
| **Skill local de proyecto** | `.atl\skills\mi-skill\SKILL.md` | Solo ese repo | Sí ✓ |
| **Convención de repo** | `AGENTS.md` o `.cursorrules` en raíz | Solo ese repo | Sí ✓ |
| **Skill gestionado** | `~\.cursor\skills\sdd-apply\SKILL.md` | Todos los proyectos | No (se actualiza) |

### Cuándo usar cada tipo

**Skill global** (`~\.cursor\skills\`): convenciones de stack que aplican a todos tus proyectos del mismo tipo. React+Python es un ejemplo perfecto. Una vez creado, todos tus repos React lo tendrán disponible automáticamente sin hacer nada por repo.

**Skill local** (`.atl\skills\` en el repo): convenciones muy específicas de ese proyecto que no aplican en ningún otro. Por ejemplo, la arquitectura particular de un monorepo legacy o las convenciones de un equipo específico.

**`AGENTS.md` en el repo**: instrucciones de comportamiento del agente para ese proyecto concreto. Cómo hacer commits, qué ramas usar, qué no tocar. El skill registry lo detecta automáticamente.

### Añadir skills a la instalación global sin tocar los gestionados

Si quieres añadir un skill que aplique globalmente pero de forma diferente por editor:

```powershell
# Crear el directorio del skill en Cursor
New-Item -ItemType Directory -Path "$env:USERPROFILE\.cursor\skills\mi-nuevo-skill"

# Crear el SKILL.md (puedes pedirle al agente que use skill-creator para generarlo)
# Luego copiarlo a VS Code Copilot
Copy-Item -Recurse "$env:USERPROFILE\.cursor\skills\mi-nuevo-skill" "$env:USERPROFILE\.copilot\skills\mi-nuevo-skill"
```

### Actualizar un skill tuyo sin perder el contenido

Los skills son archivos Markdown. Para actualizarlos, simplemente edítalos directamente o pídele al agente:

```
Actualiza el skill "react-python-stack" para incluir también:
- React Query v5 patterns para mutations con optimistic updates
- Convención de error boundaries por feature
```

El agente modificará el `SKILL.md` existente. Después:

```
Actualiza el skill registry
```

---

## 9. Trabajar con Cursor y VS Code indistintamente

Esta sección responde a una pregunta crítica: si abres el mismo repo en Cursor un día y en VS Code Copilot al siguiente, ¿qué se comparte y qué no? ¿Tienes que hacer algo extra para mantener la consistencia?

La respuesta corta: **Engram es completamente compartido. Los skills necesitan sincronización manual. El skill registry puede necesitar regenerarse al cambiar de editor.**

---

### Engram — Memoria 100% compartida entre editores

Ambos editores apuntan exactamente al mismo binario con los mismos argumentos:

```json
// ~\.cursor\mcp.json  (Cursor)
"engram": { "command": "engram", "args": ["mcp", "--tools=agent"] }

// %APPDATA%\Code\User\mcp.json  (VS Code Copilot)
"engram": { "command": "engram", "args": ["mcp", "--tools=agent"] }
```

Y ese binario lee y escribe en un único archivo de base de datos:

```
%USERPROFILE%\.engram\engram.db   ← un solo archivo, compartido por ambos
```

**Consecuencia práctica**: lo que Cursor guarda en memoria, VS Code puede leerlo. Y viceversa. Si ayer en Cursor el agente guardó "en este proyecto usamos Zustand y decidimos no usar Context API porque X", mañana en VS Code Copilot el agente tendrá ese contexto disponible desde el inicio de la sesión.

**No necesitas hacer nada extra para Engram.** La memoria es un recurso global de tu máquina, no de cada editor.

---

### Skills globales — Sincronización automática bidireccional

Cada editor tiene su propio directorio de skills:

```
%USERPROFILE%\.cursor\skills\     ← skills de Cursor
%USERPROFILE%\.copilot\skills\    ← skills de VS Code Copilot
```

Los 11 skills gestionados por gentle-ai (`sdd-*`, `go-testing`, `skill-creator`, `_shared`) **ya están instalados en ambos** — el instalador los escribe en los dos directorios simultáneamente.

Para los **skills personalizados**, la sincronización está **automatizada** por la regla global `skill-sync` (`%USERPROFILE%\.cursor\rules\skill-sync.mdc`). Cuando el agente crea o modifica un skill en cualquiera de los dos editores, inmediatamente lo copia al directorio del otro:

- Modificas en **Cursor** → se copia a `~\.copilot\skills\<skill-name>`
- Modificas en **VS Code** → se copia a `~\.cursor\skills\<skill-name>`

El agente confirma con "Skill sincronizado en ambos editores." y no pide confirmación previa.

**Cuándo aplica**: al crear, actualizar o eliminar un skill. **No aplica** al leer un skill ni a los skills gestionados por gentle-ai (`sdd-*`, `go-testing`, `skill-creator`, `_shared`).

**Script de sincronización manual** (si alguna vez necesitas sincronizar en bloque desde PowerShell):

```powershell
$gestionados = @('sdd-init','sdd-explore','sdd-propose','sdd-spec','sdd-design',
                 'sdd-tasks','sdd-apply','sdd-verify','sdd-archive',
                 'go-testing','skill-creator','_shared')

$cursorSkills = "$env:USERPROFILE\.cursor\skills"
$copilotSkills = "$env:USERPROFILE\.copilot\skills"

Get-ChildItem $cursorSkills -Directory | Where-Object {
    $_.Name -notin $gestionados
} | ForEach-Object {
    $dest = Join-Path $copilotSkills $_.Name
    Copy-Item -Recurse -Force $_.FullName $dest
    Write-Host "Sincronizado: $($_.Name)"
}
```

---

### Skill Registry — Un archivo, dos vistas distintas

El archivo `.atl\skill-registry.md` vive en el repo y es generado por el agente. El detalle importante: cuando el agente genera el registry, escribe las **rutas absolutas de los skills según su propio directorio**.

- Si lo genera Cursor → las rutas apuntan a `%USERPROFILE%\.cursor\skills\`
- Si lo genera VS Code Copilot → las rutas apuntan a `%USERPROFILE%\.copilot\skills\`

En la práctica esto funciona igualmente porque ambos directorios existen en tu máquina y cualquier editor puede leer archivos de cualquier ruta. Pero si notas que el agente en un editor no parece "ver" los skills bien después de haber generado el registry con el otro, la solución es simple:

```
Regenera el skill registry para este proyecto.
```

El agente lo rehará con las rutas correctas para el editor actual.

**Recomendación práctica**: si tienes un repo donde trabajas 80% en Cursor y 20% en VS Code, genera el registry con Cursor y no te preocupes. Solo regeneralo si detectas comportamiento inconsistente al usar VS Code en ese repo.

---

### Context7 — Técnicamente diferente, funcionalmente igual

| Editor | Cómo conecta | Resultado |
|--------|-------------|-----------|
| Cursor | `npx -y @upstash/context7-mcp` (proceso local) | Documentación actualizada ✓ |
| VS Code Copilot | `https://mcp.context7.com/mcp` (HTTP remoto) | Documentación actualizada ✓ |

La fuente de datos es la misma. La forma de conectarse es diferente por limitaciones técnicas de cada editor. No afecta al resultado.

---

### Tabla resumen: qué se comparte y qué no

| Componente | ¿Compartido entre editores? | Qué necesitas hacer |
|-----------|---------------------------|---------------------|
| **Engram (memoria)** | ✅ Sí — mismo `engram.db` | Nada |
| **Skills gestionados** (sdd-*, go-testing…) | ✅ Sí — gentle-ai los instala en ambos | Nada |
| **Skills personalizados** (tus stacks) | ✅ Auto — regla `skill-sync` los sincroniza bidireccional | Nada (el agente lo hace al crear/modificar) |
| **Skill registry** (`.atl/skill-registry.md`) | ✅ Sí — mismo archivo en el repo | Regenerar si cambias de editor primario |
| **Context7** | ✅ Sí — misma fuente de docs | Nada |
| **Persona / Orquestador** | ✅ Sí — gentle-ai lo instala en ambos | Nada |
| **MCP servers** | ✅ Sí — configurados en ambos | Nada |

---

### Flujo de trabajo multi-editor recomendado

**Opción A: Un editor por proyecto** (más simple)

Elige un editor principal por proyecto y úsalo consistentemente. El otro editor siempre lo tienes disponible pero no lo alternas en el mismo repo. La memoria de Engram se comparte de todas formas, así que si algún día abres el repo en el otro editor, tendrá contexto.

**Opción B: Alternancia libre** (requiere un paso extra)

Si quieres alternar libremente entre editores en el mismo proyecto:

1. La sincronización de skills es **automática** — la regla `skill-sync` lo hace por ti al crear o modificar cualquier skill propio.
2. La primera vez que abres el repo en el "segundo" editor, regenera el registry:
   ```
   Regenera el skill registry para este proyecto
   ```
3. A partir de ahí, alterna libremente — Engram mantiene la continuidad.

**Regla práctica**: si en VS Code Copilot el agente parece "menos informado" que en Cursor sobre un proyecto, o no aplica las convenciones de stack correctas, siempre es una de dos cosas:
1. El skill personalizado no está en `~\.copilot\skills\` → pídele al agente que lo sincronice, o usa el script manual de PowerShell de la sección anterior
2. El skill registry tiene rutas de Cursor → regenera el registry

---

### Automatizar la detección de stack — regla global de auto-stack

Junto a la auto-verificación del registry, existe una segunda regla global que detecta automáticamente en qué stack estás trabajando y carga el skill correspondiente al inicio de cada sesión.

**Cómo funciona**: el agente detecta el stack por archivos indicadores y carga **todos** los skills relevantes, no solo uno.

| Si encuentra... | Stack detectado | Skills que carga |
|-----------------|-----------------|-----------------|
| `mix.exs` o `.ex` en `lib/` | Elixir | `elixir-phoenix-stack`, `elixir-antipatterns`, `elixir-error-monad`, `elixir-legacy-strategy` + `elixir-amnesia-mnesia` si hay Amnesia en el proyecto |
| `package.json` con `"react"` | React | `react-python-stack`, `react-advanced` |
| `requirements.txt` / `pyproject.toml` / `uv.lock` | Python | `react-python-stack`, `python-fastapi-ddd`, `python-antipatterns` |
| Combinación React + Python | Fullstack | Todos los de React + todos los de Python |
| `testing-conventions` (siempre) | Cross-stack | `testing-conventions` (se carga en cualquier stack si existe) |
| Ninguno de los anteriores | — | Sigue sin skill de stack, sin mencionar nada |

Un proyecto puede coincidir con múltiples stacks simultáneamente (por ejemplo, un monorepo fullstack).

La detección es **completamente silenciosa** — el agente no anuncia qué skills cargó. Si quieres saberlo, pregúntale: `"¿qué skills tienes cargados?"`.

Los archivos ya están creados en tu máquina:
- `%USERPROFILE%\.cursor\rules\auto-stack.mdc`
- `%APPDATA%\Code\User\prompts\auto-stack.md`

**Qué necesitas para que funcione**: que los skills de tu stack existan en el directorio global. Si un skill granular no se encuentra, el agente usa el skill compuesto como fallback (`react-python-stack` para React/Python, `elixir-phoenix-stack` para Elixir). Ya tienes todos estos skills creados (ver tabla en la sección 5).

**Estos archivos también sobreviven cualquier `gentle-ai sync` o `upgrade`.**

---

### Automatizar el check del skill registry — regla global de auto-verificación

El paso de "inicializa el skill registry" puede volverse completamente automático sin necesidad de git hooks ni scripts. La solución es crear una regla global permanente que le instruye al agente a comprobar el registry por su cuenta al inicio de cada sesión.

> **Por qué no git hooks**: los hooks ejecutan shell scripts, no comandos de agente IA. No hay forma de que un hook le diga al agente "ejecuta el skill registry" — el agente no tiene interfaz CLI para eso. GGA usa hooks para cambiar proveedores porque eso sí es una operación de shell. El skill registry no lo es.

Los archivos ya están creados en tu máquina en rutas que gentle-ai nunca toca:

**Cursor**: `%USERPROFILE%\.cursor\rules\auto-registry.mdc`
```
---
description: Auto-check skill registry at session start
alwaysApply: true
---
At the start of every new conversation, before doing anything else:
1. Check if .atl/skill-registry.md exists in the current project root.
2. If it does not exist: say "No encuentro el skill registry para este proyecto. Lo inicializo ahora."
   and run the skill registry initialization immediately.
3. If it exists: read it silently and proceed.
```

**VS Code Copilot**: `%APPDATA%\Code\User\prompts\auto-registry.md` (mismo contenido)

A partir de ahora, cuando abras cualquier repo en cualquiera de los dos editores, el agente comprueba solo si el registry existe. Si no existe, lo crea sin que tengas que pedírselo. Si existe, lo lee en silencio y empieza a trabajar.

**Estos archivos sobreviven cualquier `gentle-ai sync` o `upgrade`** porque tienen nombres distintos a los gestionados (`gentle-ai.mdc` y `gentle-ai.instructions.md`).

---

### Flujo al crear o modificar un skill propio

El flujo es ahora de dos pasos, no tres:

```
1. Crear / modificar skill en el chat del agente (en Cursor o VS Code)
   → el agente lo sincroniza automáticamente al otro editor (regla skill-sync)
2. En el chat: "actualiza el skill registry"
```

No hace falta ejecutar ningún script manualmente. Si por alguna razón el agente no sincronizó (por ejemplo, modificaste el SKILL.md directamente en el editor sin pasar por el chat), usa el script manual de PowerShell de la sección anterior para forzar la sincronización en bloque.

---

## 10. Referencia rápida

### Comandos de consola

| Situación | Comando |
|-----------|---------|
| Primera instalación | `gentle-ai install --agent cursor,vscode-copilot --preset full-gentleman` |
| Ver qué haría antes de instalar | `gentle-ai install --dry-run --agent cursor,vscode-copilot --preset full-gentleman` |
| Re-aplicar config sin reinstalar | `gentle-ai sync --agent cursor,vscode-copilot` |
| Verificar si hay actualizaciones | `gentle-ai update` |
| Actualizar todo | `gentle-ai upgrade` |
| Propagar cambios tras upgrade | `gentle-ai sync` |
| Algo se rompió, restaurar | `gentle-ai restore --list` → `gentle-ai restore latest` |
| TUI interactiva | `gentle-ai` |
| Activar GGA en un repo (Git Bash) | `gga init && gga install` |

### Lo que escribes en el chat del agente

| Situación | Escribe en el chat |
|-----------|-------------------|
| Proyecto nuevo, primera vez | `"inicializa el skill registry para este proyecto"` |
| Feature compleja | `"implementa X, usa sdd"` |
| Confirmar que SDD está activo | `"¿tienes el skill registry cargado?"` |
| Guardar una decisión en memoria | `"guarda en memoria que usamos X porque Y"` |
| Recuperar contexto anterior | `"¿qué estábamos haciendo la última sesión?"` |
| Crear skill de stack | `"usa skill-creator para crear un skill de [tu stack con tus convenciones]"` |
| Actualizar el registry | `"actualiza el skill registry"` |
| Revisar implementación | `"revisa esto con sdd-verify"` |
| Forzar uso de skill concreto | `"usa el skill elixir-phoenix-stack para esta tarea"` |

### Checklist de calidad: ¿está todo bien configurado?

- [ ] `gentle-ai install` completó con 0 failed
- [ ] Cursor reiniciado tras la instalación
- [ ] VS Code reiniciado tras la instalación
- [ ] **Reglas globales** activas en ambos editores: `auto-registry`, `auto-stack`, `verification-first`, `cognitive-protocol`, `output-protocol`, `skill-sync`
- [ ] **Skills Elixir** en `~\.cursor\skills\` y `~\.copilot\skills\`: `elixir-phoenix-stack`, `elixir-antipatterns`, `elixir-error-monad`, `elixir-legacy-strategy`, `elixir-amnesia-mnesia`
- [ ] **Skills React/Python** en `~\.cursor\skills\` y `~\.copilot\skills\`: `react-python-stack`, `react-advanced`, `python-fastapi-ddd`, `python-antipatterns`
- [ ] **Skill cross-stack** en ambos directorios: `testing-conventions`
- [ ] En cada repo activo: `.atl\skill-registry.md` existe
- [ ] El agente no te pide que le expliques tus convenciones en cada sesión
- [ ] El agente sugiere SDD espontáneamente cuando la tarea es grande
- [ ] Al crear un skill nuevo, el agente lo sincroniza automáticamente al otro editor

---

## 11. Migrar instrucciones largas existentes a skills y reglas

Si tienes un archivo de instrucciones de Copilot grande (tipo system prompt de 500+ líneas), la estrategia correcta no es mantenerlo como un bloque monolítico. Hay que dividirlo por responsabilidad y poner cada pieza en el lugar correcto.

### Cómo categorizar cualquier instrucción existente

| Pregunta | Destino |
|----------|---------|
| ¿Aplica a cualquier stack y cualquier proyecto? | Global rule (`~\.cursor\rules\`) |
| ¿Es específica de un lenguaje o framework? | Skill del stack (`~\.cursor\skills\nombre-stack\`) |
| ¿Tiene referencias a módulos concretos del proyecto? | `AGENTS.md` en el repo |
| ¿Es estado interno del LLM (variables, counters)? | **Eliminar** — el LLM lo gestiona solo |
| ¿Duplica lógica ya expresada en otras secciones? | **Eliminar** — redundante |
| ¿Está cubierto por el SDD de gentle-ai? | **Eliminar** — ya lo hace el orquestador |

### Las reglas globales instaladas en tu máquina

Además de las que crea gentle-ai, tienes estas reglas propias activas en ambos editores:

| Archivo | Qué hace | Seguro ante upgrade |
|---------|---------|---------------------|
| `verification-first` | Filosofía verification-first, jerarquía de verdad, verificación de funciones, legacy files | ✓ |
| `cognitive-protocol` | Detección de cognitive smells (CRITICAL/MEDIUM/LOW), protocolo de clarificación | ✓ |
| `output-protocol` | Formato PROTOCOLO_EJECUTADO + matriz de preguntas del Cognitive Hook | ✓ |
| `auto-registry` | Auto-check del skill registry al abrir proyecto | ✓ |
| `auto-stack` | Detección de stack y carga de todos los skills relevantes automáticamente | ✓ |
| `skill-sync` | Mirror bidireccional automático al crear/modificar/eliminar un skill propio | ✓ |

**Rutas** (ambos editores):
- Cursor: `%USERPROFILE%\.cursor\rules\[nombre].mdc`
- VS Code: `%APPDATA%\Code\User\prompts\[nombre].md`

### Qué se eliminó del copilot-instructions original y por qué

| Sección eliminada | Motivo |
|-------------------|--------|
| `EXECUTION_ORDER` YAML (máquina de estados) | Redundante — las reglas en lenguaje natural lo cubren |
| `CONTEXT_VARS` Python (FILE, LINES, MODE…) | Estado interno del LLM, no necesita instrucción explícita |
| `DECISION_ALGORITHM` Python | Redundante con las reglas de verificación y clasificación |
| `PREFLIGHT_OUTPUT_COMPACT` YAML | Formalismo excesivo, cubierto por `verification-first` |
| `PHASE_EXECUTION_COMPACT` (P1-P4) | Cubierto por el SDD de gentle-ai (explore→spec→design→apply→verify) |
| `AGENT_SKILLS` section | Obsoleto — gentle-ai gestiona los skills ahora |
| `TOOL_USAGE_COMPACT` | Redundante — los agentes saben cuándo usar cada tool |
| `PROHIBITED_BEHAVIORS_CONCRETE` | Cubierto por `verification-first` |
| `MODE_SELECTION_EXPLICIT` YAML completo | Simplificado en `verification-first` (legacy threshold) |

### Qué va en el AGENTS.md del repo Leasing (proyecto específico)

Las referencias a módulos concretos del proyecto NO son globales — van en el `AGENTS.md` del repo:

```markdown
# Leasing — Convenciones del proyecto

## Módulos de servicio (extender, no duplicar)
- `Leasing.Agile` — integraciones con Agile
- `Leasing.Slack` — integraciones con Slack  
- `Leasing.PostgresStorage` — acceso a base de datos
- `Leasing.Utils` — utilidades generales

## Archivos legacy
- Threshold: 1500 líneas
- Complejidad: ver `.complexity_results.json` en la raíz del repo

## Dominios del sistema
Auth | Leasing | Notifications | [añadir según crezca el proyecto]
```

### Regla de tamaño para skills

| Tipo | Líneas ideales | Señal de que hay que dividir |
|------|---------------|------------------------------|
| Skill de stack (convenciones) | 60–100 | Agente mezcla convenciones de áreas distintas |
| Skill de antipatrones | 60–90 | Catálogo tan largo que el agente lo ignora en parte |
| Skill de workflow | 100–180 | Nunca dividir — el flujo es una unidad |
| Global rule | 50–80 | Más de 3 responsabilidades distintas en el mismo archivo |

Un skill con más de 120 líneas de convenciones es candidato a dividirse en dos. La prueba: si puedes nombrar exactamente dos responsabilidades distintas en el skill, es momento de separarlo.
