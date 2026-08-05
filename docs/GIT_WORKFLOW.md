# Git y Pull Requests — FNF_Echoes

Este documento define cómo se gestionan ramas, commits y Pull Requests en este repo. Aplica a los dos desarrolladores del equipo y a cualquier agente de IA que opere sobre el repo en su nombre.

Complementa a `docs/WORKFLOW.md` (que reparte el trabajo entre Cowork y Claude Code/editor local). Este documento es específico de **git y GitHub**, sin importar qué herramienta se esté usando.

## Equipo

| Persona | Usuario GitHub | Rol |
|---|---|---|
| Salchorizo | `Salchorixo` | Dueño del repo |
| Compañero | `nakamuraj471-stack` | Colaborador |

En cada PR, el autor pide review al otro. No hay excepción por tamaño del cambio.

## Regla de oro

**Nadie commitea directo a `main`.** `main` está protegida: todo cambio entra por Pull Request, con al menos **1 revisión aprobada** antes de mergear. Esto aplica también a cambios "pequeños" de documentación — el objetivo es que el compañero siempre tenga visibilidad de lo que entra al repo.

## Ramas

Nombre de rama: `tipo/descripcion-corta-en-kebab-case`.

| Tipo | Cuándo usarlo | Ejemplo |
|---|---|---|
| `feature/` | Sistema o contenido nuevo | `feature/tablero-mapa` |
| `fix/` | Corrección de un bug | `fix/shader-vhs-parpadeo` |
| `docs/` | Solo documentación (README, ADRs, este archivo) | `docs/adr-0002-progress-manager` |
| `chore/` | Mantenimiento sin lógica nueva (deps, configuración, estructura de carpetas) | `chore/gitignore-builds` |
| `refactor/` | Reordenar código existente sin cambiar comportamiento | `refactor/extraer-maptoken` |

Una rama = un tema. Si a mitad de una rama `feature/` aparece un fix sin relación, ese fix va en su propia rama y su propia PR.

## Commits

Formato ya establecido en `AGENTS.md`: `tipo: descripción corta`, en español o inglés pero consistente dentro del mismo commit.

Tipos usados en este repo (Conventional Commits, adaptado): `feat`, `fix`, `docs`, `chore`, `refactor`, `legal`.

Commits pequeños y descriptivos — cada commit debe poder explicarse en una frase. Evitar commits tipo "cambios varios" o "WIP".

## Flujo de una Pull Request

1. Crear rama desde `main` actualizada (`git pull origin main` antes de ramificar).
2. Commitear en la rama siguiendo la convención de arriba.
3. Antes de abrir la PR, repasar el checklist de `docs/CODING_STANDARDS.md`.
4. Abrir la PR contra `main` con:
   - Título: mismo formato que los commits (`tipo: qué hace`).
   - Descripción: qué cambia y **por qué** (no solo el qué — el porqué es lo que el compañero necesita para revisar bien).
   - Si hay una decisión de arquitectura no trivial detrás, enlazar o crear el ADR correspondiente en `docs/adr/` en la misma PR.
5. Pedir revisión al compañero. Nadie mergea su propia PR sin esa aprobación.
6. Resolver todos los comentarios de la revisión antes de mergear.
7. Mergear con **squash and merge** — mantiene `main` con un commit limpio por feature/fix, aunque la rama haya tenido commits intermedios desordenados.
8. Borrar la rama tras el merge.

## Branch protection en `main` (configuración objetivo en GitHub)

- Require a pull request before merging.
- Require approvals: 1.
- Require conversation resolution before merging.
- No permitir force-push ni borrado directo de `main`.

## Qué pasa si hay conflicto entre Cowork y Claude Code

Ver la sección "Sincronización: git, no magia" en `docs/WORKFLOW.md` — la disciplina de "revisar `git status` antes de empezar, no trabajar en ambas herramientas a la vez sobre los mismos archivos" aplica igual cuando además hay una segunda persona trabajando en su propia rama.

## Ejemplo completo, paso a paso

Supongamos que a Salchorizo le toca prototipar el shader VHS (pendiente de `docs/WORKFLOW.md`):

```bash
git checkout main
git pull origin main                    # traer lo último antes de ramificar
git checkout -b feature/shader-vhs       # nueva rama, nunca se trabaja sobre main

# ... trabaja, prueba, compila ...

git add src/shaders/VHSShader.hx
git commit -m "feat: prototipo de shader VHS con distorsión de línea"
git push -u origin feature/shader-vhs    # sube la rama (no main) a GitHub
```

Luego, en GitHub: abre una PR de `feature/shader-vhs` hacia `main`, escribe qué hace y por qué, y asigna a `nakamuraj471-stack` como reviewer. Cuando aprueba, se mergea con squash y se borra la rama. `main` nunca ve un commit que el compañero no haya visto antes.
