# Linear + Git + Pull Requests — FNF_Echoes

Este documento define **cómo se trabaja de principio a fin**: una idea nace como issue en Linear, se convierte en rama, se entrega en una Pull Request de GitHub y se cierra sola al mergear. Aplica a Zyra y a cualquier agente de IA que opere sobre el repo.

Complementa a `docs/WORKFLOW.md` (reparto de trabajo entre Cowork y Claude Code/editor local) y a `docs/agents/01_PROTOCOLO_DE_SESION.md` (cómo empezar/terminar una sesión). Este archivo es el que manda para **ramas, commits, PR, merge y estados de Linear**.

---

## 1. Resumen de una pantalla

```
Linear: Backlog → Todo → In Progress → In Review → Done
                            │              │          ▲
         (se crea la rama   │   (se abre   │  (se mergea la PR:
          con el ID)        │    la PR)    │   Linear lo mueve solo)
GitHub:               rama BE-12  →   PR "Closes BE-12"  →  Rebase and merge → main
```

Las 7 reglas que no se negocian:

1. **Todo trabajo tiene una issue de Linear.** (Excepción: §9.)
2. **Una issue = una rama = una PR.** Una cosa por PR.
3. **El ID de la issue va en el nombre de la rama y en la PR** (`Closes BE-12`). Así Linear y GitHub se enlazan solos.
4. **La PR siempre apunta a `main`.** Nunca a otra rama de feature, nunca ramas apiladas (ver §5).
5. **Nadie commitea directo a `main`.** Todo entra por PR.
6. **Antes de mergear, te lees tu propio diff** en la pestaña *Files changed* y marcas el checklist (§6). El revisor eres tú: la revisión no se salta, se hace uno mismo.
7. **Merge con "Rebase and merge"** (§7). Cada commit de la rama acaba tal cual en `main`, por eso cada commit debe ser limpio.

---

## 2. Equipos de Linear y prefijos

Workspace de Linear: **FNF Echoes** (`linear.app/fnf-echoes`).

| Equipo | Prefijo | Proyectos (áreas) que contiene |
|---|---|---|
| **DESIGN** | `DS-` | ANIMATIONS, DECISIONS, ART & BACKGROUNDS, MUSIC & AUDIO, CHARTS, MECHANICS, CUTSCENES & STORY |
| **BACK** | `BE-` | ENGINE & PLATFORM, GAMEPLAY MECHANICS, MENUS & UI, FINAL SEQUENCE, ARCHITECTURE, RELEASE & TFM |

Las áreas son **Proyectos de Linear** (cada uno con su descripción de "Qué entra aquí"). **Toda issue se asigna a un Proyecto**; la descripción del proyecto dice si el tema es suyo o va en otro.

- Una issue de **DS** que necesite código (p. ej. "implementar la animación X en el juego") se **parte**: la decisión/arte queda en DS y se crea una issue hija en BE para la implementación, enlazada con relación *Related*.
- Las issues de DS que son **solo creativas** (decidir el final, generar música en Suno, dibujar) normalmente no tienen PR: se cierran a mano al decidir/entregar, y el resultado se anota en Notion o se sube a `mods/` en una issue BE.

---

## 3. Estados de Linear

Se usan los estados por defecto de Linear, sin inventar más (menos estados = menos mantenimiento).

> **Pendiente de Zyra (a 2026-10-02):** en los equipos BACK y DESIGN **no existe el estado "In Review"** (solo hay Backlog, Todo, In Progress, Done, Canceled, Duplicate). Hay que crearlo a mano en *Settings → Teams → (equipo) → Workflow → Add status*, categoría **Started**, en los dos equipos. Mientras no exista, una issue con la PR abierta se queda en *In Progress* y el resto del flujo funciona igual.

| Estado | Significa | Quién lo mueve | Condición para entrar |
|---|---|---|---|
| **Backlog** | Idea o tarea anotada, sin compromiso. | Tú, al crearla. | Existe título y una frase de contexto. |
| **Todo** | Decidido que se hace y lista para empezar. | Tú, al priorizar. | Tiene **criterio de aceptación** claro (§4). |
| **In Progress** | Se está trabajando **ahora**. | Automático al crear la rama / abrir PR en borrador; o a mano. | Existe la rama con el ID. **Máximo 2 issues en este estado a la vez.** |
| **In Review** | La PR está abierta y esperando tu autorrevisión. | Automático al abrir la PR (no borrador). | La PR existe, está probada o marcada "NO PROBADO". |
| **Done** | Está en `main`. | **Automático al mergear la PR.** | PR mergeada. |
| **Canceled** | Ya no se hará. | Tú. | Comentario con el motivo. |
| **Duplicate** | Ya existe otra issue. | Tú. | Enlazada a la original. |

Reglas de movimiento:

- **Nunca saltes a Done a mano si hay código**: déjalo al merge. Si se movió a mano y no hay PR, algo está mal.
- Si una issue queda **bloqueada** (esperas una decisión de Zyra, un asset de Suno, etc.): no cambies el estado; añade la etiqueta `blocked` y un comentario que diga **qué** la bloquea. Cuando se desbloquee, quita la etiqueta.
- Si una issue lleva más de ~1 semana en **In Progress** sin commits, vuelve a **Todo** con un comentario (relevo) o se parte en issues más pequeñas.
- Si una issue crece a mitad de camino: **no la amplíes**. Crea otra issue para lo nuevo y enlázala.

### Automatizaciones de Linear (configurar una vez)

En Linear → *Settings → Teams → (DESIGN y BACK) → Workflows* (la automatización de pull requests y commits), activar:

- PR en borrador abierta → **In Progress**
- PR abierta / lista para review → **In Review**
- PR mergeada → **Done**

Y en *Settings → Integrations → GitHub*: conectar el repo `Salchorixo/FNF-Echoes`. Sin esta integración nada de lo anterior es automático y hay que mover los estados a mano.

> Si algún día la integración no está disponible (o un agente no tiene acceso a Linear), el agente **no inventa estados**: deja el relevo en `docs/agents/00_ESTADO_ACTUAL.md` y dice que no pudo tocar Linear.

---

## 4. Anatomía de una buena issue

Plantilla (cópiala en la descripción de cada issue de BE; en DS basta Contexto + Criterio):

```markdown
## Contexto
Por qué existe esta tarea (1-3 frases). Enlaza Notion / ADR si aplica.

## Alcance
- Qué SÍ se hace (lista corta).

## Fuera de alcance
- Qué NO se hace aquí (para que la tarea no crezca).

## Criterio de aceptación
- [ ] Cómo compruebo que está terminada, en términos observables.
      Ej.: "Abro el juego, voy a Options y al cambiar el idioma a EN los textos cambian".

## Archivos / documentos afectados
- `mods/fnf-echoes/data/states/XState.hx`, `docs/agents/03_RECETAS.md`...
```

Reglas:

- **Título**: verbo en infinitivo + qué (`Añadir pantalla de Options`, no `Options`). Los títulos de Linear pueden ir en español.
- **Sin criterio de aceptación no pasa a Todo.** Es lo que evita el "¿ya está?" infinito.
- Tamaño objetivo: **cabe en 1-2 sesiones de trabajo**. Si no cabe, se parte en sub-issues.
- **Prioridad**: Urgent solo para lo que rompe el juego o bloquea todo lo demás. El resto, High/Medium/Low.
- **Etiquetas** (a nivel de workspace). Tipo, una por issue: `Bug`, `Feature`, `Improvement`. Estado/contexto, las que hagan falta:
  - `needs-zyra`: falta una decisión de historia/arte/diseño (los agentes no la toman, ver `AGENTS.md` §0.10).
  - `blocked`: espera algo externo (ver §3).
  - `engine`: toca `engine/` y por tanto exige ADR aprobado (`AGENTS.md` §0.3).
  - `windows`: específico de Windows (nunca se ha probado, ver `00_ESTADO_ACTUAL.md`).
- **Proyecto**: obligatorio (ver §2). **Milestones**: dentro de cada proyecto, para las fechas de entrega del TFM (p. ej. "Canción 1 jugable"). Así Linear muestra el avance real hacia la entrega.

---

## 5. Ramas

Nombre: `tipo/ID-descripcion-corta-en-kebab-case`.

| Tipo | Cuándo usarlo | Ejemplo |
|---|---|---|
| `feature/` | Sistema o contenido nuevo | `feature/BE-12-transparencia-windows` |
| `fix/` | Corrección de un bug | `fix/BE-30-shader-vhs-parpadeo` |
| `docs/` | Solo documentación (ADRs, este archivo, manual de agentes) | `docs/BE-41-adr-voces-suno` |
| `chore/` | Mantenimiento sin lógica nueva (config, estructura, ignorados) | `chore/BE-8-gitignore-audio` |
| `refactor/` | Reordenar código sin cambiar comportamiento | `refactor/BE-22-extraer-maptoken` |

- **El ID es obligatorio.** Es lo que enlaza la rama con la issue. Puedes usar el botón "Copy git branch name" de Linear (da algo como `usuario/be-12-titulo`), pero **respeta el prefijo `tipo/`** de arriba; Linear reconoce el ID en cualquier parte del nombre.
- Se crea **siempre desde `main` actualizada**:
  ```bash
  git checkout main && git pull origin main
  git checkout -b feature/BE-12-transparencia-windows
  ```
- **No apilar ramas.** Una rama nace de `main`, no de otra feature. Si tu tarea depende de otra aún no mergeada: espera a que se mergee, o une ambas en una sola issue/PR. (Lección aprendida: en la Fase 1-6 se apilaron 7 ramas, cada PR se mergeó contra la anterior y al final el código **no llegó a `main`** hasta una PR de consolidación, la #12.)
- Una rama = un tema. Si a mitad aparece un arreglo sin relación, va en **su propia issue, rama y PR**.
- Vida corta: la rama debería vivir **días, no semanas**. Cuanto más vive, más conflictos al rebasear.
- Se borra al mergear (§8).

---

## 6. Commits y Pull Request

### Commits

Formato: `tipo: descripción corta en español (ID)`.

```
feat: pantalla de Options con carrusel de categorías (BE-12)
fix: el idioma no persistía al reiniciar (BE-31)
docs: workflow de Linear y PR (BE-40)
```

- Tipos: `feat`, `fix`, `docs`, `chore`, `refactor`, `legal`.
- **El ID va al final del asunto.** Con "Rebase and merge" los commits llegan a `main` uno a uno, sin la PR alrededor; el ID es lo que permite, años después, saber a qué issue pertenece cada línea de `git log`.
- **Cada commit explica una cosa y se entiende solo.** Nada de `WIP`, `cambios varios`, `arreglo`. Como se mergea con rebase, **lo que commiteas es lo que queda en `main` para siempre**.
- Los trailers de coautoría de agentes (`Co-Authored-By: ...`) se mantienen.

### Pull Request

1. Antes de abrirla, deja la rama al día y limpia:
   ```bash
   git fetch origin
   git rebase origin/main          # resuelve conflictos AQUÍ, no en GitHub
   git push --force-with-lease     # solo en TU rama de feature, nunca en main
   ```
2. Revisa el checklist de `docs/CODING_STANDARDS.md`.
3. Abre la PR **contra `main`**:
   - **Título:** igual que un commit (`tipo: qué hace (ID)`).
   - **Descripción:** usa esta plantilla.
     ```markdown
     Closes BE-12

     ## Qué cambia
     ## Por qué
     ## Cómo se probó
     (qué ejecutaste y qué viste; si no: "NO PROBADO, porque ...")
     ## Notas
     (decisiones, ADR enlazado, cosas que Zyra debe saber)
     ```
   - **`Closes BE-12`** (o `Fixes`/`Resolves`) en la descripción es lo que mueve la issue a Done al mergear. Si la PR solo hace **parte** de la issue, usa `Part of BE-12` (no la cierra).
   - Si hay decisión de arquitectura no trivial, el ADR va **en la misma PR**.
4. Si aún no está lista, ábrela como **borrador** (*Draft*): la issue pasa a In Progress y no a In Review.
5. **Autorrevisión (obligatoria, aunque nadie más lo exija):** en *Files changed*, lee tu propio diff como si fuera de otra persona y comprueba:
   - [ ] Solo hay cambios relacionados con la issue (nada de reformateos ni archivos colados).
   - [ ] No hay archivos ignorados, binarios grandes, audio ni secretos.
   - [ ] Código en inglés, documentación en español.
   - [ ] Probado, o marcado "NO PROBADO" con motivo.
   - [ ] Los cambios en `docs/` y `00_ESTADO_ACTUAL.md` reflejan lo que cambió.
   - [ ] Los commits están limpios (se van a `main` tal cual).
6. Resuelve tus propios comentarios (los de agentes o los tuyos) antes de mergear.

---

## 7. Merge: "Rebase and merge"

Zyra mergea sus propias PR; **no hace falta aprobación de otra persona**. Estrategia por defecto: **Rebase and merge**.

```bash
gh pr merge --rebase --delete-branch      # o el botón "Rebase and merge" en GitHub
```

Por qué rebase y no squash: deja una historia **lineal y fiel**, un commit por cambio, sin commits de merge. Es el motivo por el que los commits deben ser limpios (§6).

**Excepción: usa "Squash and merge"** cuando la rama tenga commits desordenados (varios `fix` de lo mismo, pruebas, `WIP`). En ese caso el título de la PR pasa a ser el commit único de `main`, así que debe seguir el formato `tipo: qué hace (ID)`.

**Nunca "Create a merge commit".**

Trampas conocidas del rebase-merge:

- GitHub **reescribe los commits** al mergear (nuevos hashes). Tu rama local queda obsoleta: **bórrala y no la reutilices** (§8).
- Si hay conflictos con `main`, el botón no se habilita: rebasea tú en local (§6.1) y vuelve a empujar.
- Si dependías de otra rama apilada, el rebase duplica commits → por eso **no se apilan ramas** (§5).

### Protección de `main` en GitHub (configuración objetivo)

- Require a pull request before merging, con **0 aprobaciones requeridas** (la autorrevisión es la regla de §6, no un bloqueo técnico).
- **Require linear history** (impide commits de merge; coherente con rebase/squash).
- Require conversation resolution before merging.
- No permitir force-push ni borrado de `main`.
- *Automatically delete head branches* activado.
- Permitir **Rebase merge** y **Squash merge**; desactivar **Merge commit**.

Estado real a 2026-10-03 (leído con `gh api`): **aplicado tal cual esta lista**. `enforce_admins` sigue en `false` a propósito: es lo que permite a Zyra la excepción de push directo de §9. Cambiar estos ajustes es tarea de Zyra (un agente solo lo propone).

---

## 8. Después del merge

GitHub borra la rama **remota** solo (*Automatically delete head branches*), pero tu máquina no se entera. La limpieza local se hace con **un comando**, desde el checkout principal:

```bash
git done
```

`git done` es un alias de git **local** (vive en `.git/config`, no se versiona). Hace, en orden:

1. Se niega si hay **cambios sin commitear** (no mueve ramas bajo tu trabajo) o si lo ejecutas **dentro de un worktree** (ver §12).
2. `git fetch --prune`, cambia a `main` y la actualiza con `pull --ff-only`.
3. Borra las ramas locales cuya remota desapareció **y** que tienen una PR **mergeada** (lo confirma `gh`). Si la remota desapareció pero no hay PR mergeada, **conserva la rama** y avisa: puede ser trabajo sin subir.
4. Si esa rama tenía un **worktree**, lo quita antes (si tiene cambios sin commitear, lo conserva y avisa).
5. `git worktree prune`.

Necesita `gh` con sesión iniciada. **Instalación** (una vez por máquina; copia y pega todo el bloque):

```bash
git config --local alias.done "$(cat <<'EOF'
!f() {
  root=$(git worktree list --porcelain | sed -n '1s/^worktree //p');
  if [ "$(git rev-parse --git-dir)" != "$(git rev-parse --git-common-dir)" ]; then
    echo "Estas dentro de un worktree. Ejecuta git done desde el checkout principal: $root";
    return 1;
  fi;
  [ -z "$(git status --porcelain --untracked-files=no)" ] || { echo "Hay cambios sin commitear: no toco nada."; return 1; };
  git fetch origin --prune || return 1;
  git checkout main && git pull --ff-only origin main || return 1;
  for b in $(git for-each-ref --format='%(refname:short) %(upstream:track)' refs/heads | grep -F '[gone]' | cut -d' ' -f1); do
    if [ "$(gh pr list --head "$b" --state merged --json number --jq length 2>/dev/null)" -gt 0 ] 2>/dev/null; then
      wt=$(git worktree list --porcelain | awk -v b="branch refs/heads/$b" '/^worktree /{p=substr($0,10)} $0==b{print p}');
      if [ -n "$wt" ]; then
        git worktree remove "$wt" || { echo "No pude quitar el worktree $wt (cambios sin commitear?). Conservo $b."; continue; };
      fi;
      git branch -D "$b";
    else
      echo "Conservo $b: su remota se borro pero no tiene PR mergeada.";
    fi;
  done;
  git worktree prune;
}; f
EOF
)"
```

Se usa `-D` (no `-d`) porque con rebase/squash-merge los hashes cambian y git cree que la rama "no está mergeada"; por eso la comprobación de PR mergeada va por `gh` y no por git.

> `gh pr merge --rebase --delete-branch` (mergear desde la terminal) hace por sí solo la parte de borrar la rama local; `git done` cubre el caso normal de mergear desde el botón de GitHub.

Sin el alias, a mano:

```bash
git checkout main && git pull --ff-only origin main
git branch -D feature/BE-12-transparencia-windows
```

Y comprueba tres cosas:

1. La issue de Linear pasó a **Done** (si no, la integración no se enlazó: mira que el ID esté en la rama y `Closes ID` en la PR).
2. `docs/agents/00_ESTADO_ACTUAL.md` quedó actualizado (parte del relevo, ver `01_PROTOCOLO_DE_SESION.md` §3).
3. Si la issue dejó trabajo pendiente, hay **otra issue** para eso (no se queda en el aire).

---

## 9. Excepciones

- **Cambios sin issue**: un typo de documentación o un `.gitignore` de una línea no necesitan issue. Rama `docs/descripcion-corta` o `chore/descripcion-corta`, commit sin ID y PR normal. Si crece más de 1-2 archivos, **crea la issue**.
- **Hotfix** (el juego no abre): issue `Urgent` + etiqueta `Bug`, rama `fix/BE-XX-...` desde `main`, PR mínima, merge, y el resto del trabajo se rebasea encima.
- **Push directo a `main`**: solo lo puede hacer Zyra y solo para documentación pura de procedimiento (como la primera subida del manual de agentes, 2026-10-02). **Ningún agente** pushea a `main`, ni siquiera con permiso técnico para hacerlo (`AGENTS.md` §0.6). Si Zyra lo hace, lo hace conscientemente y sin código dentro.
- **Cowork / Claude Code a la vez**: ver "Sincronización: git, no magia" en `docs/WORKFLOW.md`. Antes de empezar: `git status`, `git branch --show-current`, `git log --oneline -10`.

---

## 10. Reglas específicas para agentes de IA

- **Parte siempre de una issue.** Si no te dieron un ID, pídelo o propón crear la issue; no empieces a ciegas.
- **Cuidado con el workspace de Linear.** Puede haber más de un workspace conectado a tu herramienta (por ejemplo **SICDA**, otro proyecto de Zyra, que **también usa el prefijo `BE-`**). Antes de leer, crear o editar una issue, comprueba que el workspace es **FNF Echoes** (`get_workspace` → `linear.app/fnf-echoes`). Si no lo es, para y avisa. Un `BE-12` de SICDA no es un `BE-12` de Echoes.
- **No muevas estados "a Done"** ni cierres issues: lo hace el merge. Tú puedes mover a *In Progress* al empezar y a *In Review* al abrir la PR si la integración no lo hace sola.
- **El relevo** (`01_PROTOCOLO_DE_SESION.md` §3) va como **comentario en la issue** y también en `00_ESTADO_ACTUAL.md`.
- **No mergees PR tú**, salvo que Zyra lo pida explícitamente en esa sesión. Abrir la PR sí; el botón de merge es de Zyra.
- **No uses `--force` ni `--no-verify`.** `--force-with-lease` solo en la rama de feature que tú creaste.
- **No cambies la configuración del repo en GitHub ni los ajustes de Linear** (protección de ramas, automatizaciones, workflows): propón el cambio y espera.
- Si Linear o GitHub no están accesibles desde tu herramienta, **dilo** y deja el relevo en el repo.

---

## 11. Ejemplo completo, de la idea al `main`

Tarea: *"Prototipar la transparencia real de ventana en Windows"* (issue `BE-12`, estado **Todo**).

```bash
# 1) Empezar (Linear: la issue pasa a In Progress al crear la rama)
git checkout main
git pull origin main
git checkout -b feature/BE-12-transparencia-windows

# 2) Trabajar en commits pequeños
git add engine/source/funkin/backend/utils/native/Windows.hx
git commit -m "feat: ventana layered con color clave en Windows (BE-12)"
git add docs/adr/0003-transparencia-de-ventana.md
git commit -m "docs: añade resultado de la prueba de color clave al ADR-0003 (BE-12)"

# 3) Dejar la rama al día y subirla
git fetch origin
git rebase origin/main
git push -u origin feature/BE-12-transparencia-windows

# 4) Abrir la PR (Linear: pasa a In Review)
gh pr create --base main \
  --title "feat: transparencia de ventana en Windows con color clave (BE-12)" \
  --body "Closes BE-12 ..."

# 5) Autorrevisión en 'Files changed' + checklist de §6

# 6) Mergear (Linear: pasa a Done solo)
gh pr merge --rebase --delete-branch

# 7) Limpiar
git checkout main && git pull origin main
```

> Este ejemplo toca `engine/`, así que antes de la rama debe existir un ADR aprobado (ver `AGENTS.md` §0.3 y ADR-0003).

---

## 12. Worktrees (varias issues a la vez)

Un *worktree* es otra carpeta de trabajo del **mismo repo** con su propia rama. Sirve para tener dos issues abiertas a la vez, o para que un agente trabaje en paralelo, **sin apilar ramas** (§5) y sin mover la rama de tu checkout principal.

Reglas (siguen siendo las de siempre): **un worktree = una issue = una rama = una PR**, y el máximo de 2 issues en *In Progress* (§3) cuenta también aquí.

### Dónde viven

| Qué | Ruta |
|---|---|
| Checkout principal (`main`, motor compilado) | `/Volumes/Zyras Zone/Projects/FNF_Echoes` |
| Worktrees | `/Volumes/Zyras Zone/Projects/FNF_Echoes-worktrees/<ID>-descripcion` |

La carpeta de worktrees es **hermana** del repo, no está dentro: por eso git no la ve y no hace falta ignorarla. Usa siempre rutas absolutas y entre comillas (la ruta tiene espacios).

> Existe además `.claude/worktrees/agent-a148a96f1853ae6ce` (un worktree viejo de un agente, ya sin registrar en git). No se borra sin preguntar a Zyra; las ramas nuevas **no** usan esa carpeta.

### Crear uno

Desde el checkout principal, con `main` actualizada (la rama nace de `main`, como siempre):

```bash
cd "/Volumes/Zyras Zone/Projects/FNF_Echoes"
git checkout main && git pull --ff-only origin main
git worktree add -b docs/BE-6-git-done-y-worktrees \
  "/Volumes/Zyras Zone/Projects/FNF_Echoes-worktrees/BE-6-git-done-y-worktrees" main
```

### Qué trae y qué no

- **`engine/` llega vacío.** Es un submódulo y un worktree nuevo no lo inicializa. Para tareas de **docs** o de **`mods/`** no hace falta. **No lo inicialices ahí** (duplicarías el motor y su compilación). Cualquier tarea que toque `engine/` o necesite compilar se hace **en el checkout principal**.
- **`mods/` llega incompleto.** Solo trae `mods/fnf-echoes/`. Los archivos `mods/autoload.txt` y `mods/readme.txt` **no están versionados** (los ignora `mods/*` en `.gitignore`), así que no aparecen. Sin `autoload.txt` el motor no carga el mod.

### Probar el juego desde un worktree

El `.app` compilado solo mira `mods/` a través de un enlace simbólico que apunta al checkout principal. Para probar los cambios de un worktree hay que **reapuntar** el enlace y **restaurarlo** al terminar:

```bash
APP="/Volumes/Zyras Zone/Projects/FNF_Echoes/engine/export/release/macos/bin/CodenameEngine.app/Contents/Resources/mods"
WT="/Volumes/Zyras Zone/Projects/FNF_Echoes-worktrees/BE-6-git-done-y-worktrees"

cp "/Volumes/Zyras Zone/Projects/FNF_Echoes/mods/autoload.txt" "$WT/mods/"   # una vez por worktree (git lo ignora)
ln -sfn "$WT/mods" "$APP"                                                     # el juego ahora carga el worktree
# ... abrir el juego y probar ...
ln -sfn "/Volumes/Zyras Zone/Projects/FNF_Echoes/mods" "$APP"                 # RESTAURAR siempre al terminar
```

**NO PROBADO ejecutando el juego:** el procedimiento sale de `docs/PROJECT_STRUCTURE.md` (regla 6) y de leer el enlace real del `.app`; lo único probado es `git done` con worktrees (§8). Quien lo use por primera vez, que confirme que el juego carga el mod y lo anote aquí.

Solo **un** worktree a la vez puede estar enlazado. Si olvidas restaurar, el juego carga código de otra rama sin avisar: ante un comportamiento raro, comprueba primero a dónde apunta el enlace (`ls -l "$APP"`). Para Windows no hay procedimiento (plataforma sin probar).

### Limpiarlo después del merge

Desde el **checkout principal**:

```bash
git done
```

Quita el worktree y borra la rama si su PR está mergeada (detalle en §8). A mano:

```bash
git worktree list                       # ver cuáles existen
git worktree remove "<ruta del worktree>"
git branch -D docs/BE-6-git-done-y-worktrees
git worktree prune                      # limpia registros de carpetas que ya no existen
```

Si restauraste el enlace de la sección anterior, no queda nada más que limpiar. Si el worktree tiene cambios sin commitear, `git worktree remove` se niega (y `git done` lo conserva y avisa): decide tú si commitear, guardar o descartar; **no uses `--force` sin mirar qué se pierde**.

### Trampas conocidas

- **Una rama solo puede estar en un worktree.** `git checkout main` falla dentro de un worktree secundario porque `main` ya está abierta en el principal. Por eso `git done` se niega a correr dentro de uno y te dice la ruta a la que ir.
- **No borres la carpeta de un worktree con `rm -rf` ni con Finder.** Git sigue creyendo que existe y la rama queda "ocupada". Si ya lo hiciste: `git worktree prune`.
- **`git branch -D` no borra una rama que tiene un worktree vivo.** Quita primero el worktree (o usa `git done`).
- Un agente que trabaja en un worktree sigue las mismas reglas que en el principal (§10): no cambia de rama, no toca el checkout principal y deja el relevo en la issue.
