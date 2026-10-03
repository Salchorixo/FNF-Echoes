# 01 — Protocolo de sesión

Cómo empezar, trabajar y terminar una sesión para que **la siguiente (tuya o de
otro agente) pueda continuar sin perder nada**.

---

## 1. Al empezar (en este orden, sin saltarte pasos)

1. Lee `AGENTS.md` §0.
2. Lee `docs/agents/00_ESTADO_ACTUAL.md` completo, sobre todo "Última sesión".
3. Mira el estado real del repo:
   ```bash
   git status
   git branch --show-current
   git log --oneline -10
   ```
4. Decide qué caso es:

| Lo que ves | Qué haces |
|---|---|
| Estás en `main` | Crea una rama antes de tocar nada: `git checkout -b tipo/descripcion` |
| Hay cambios sin commitear que no son tuyos | **No los borres ni los commitees.** Pregunta a Zyra de quién son. |
| La "Última sesión" dejó algo a medias | Retómalo **antes** de empezar algo nuevo (ver §2). |
| El estado no coincide con el repo | Manda el repo. Anótalo para corregir `00_ESTADO_ACTUAL.md` al final. |

5. Escribe en una frase qué vas a hacer y en qué archivos. Si son más de 3 archivos, divide la tarea.

## 2. Retomar una sesión a medias

1. Lee el relevo (en `00_ESTADO_ACTUAL.md` §7 o en el comentario de la issue de Linear).
2. Mira el diff de lo que quedó: `git diff` y `git diff --staged`.
3. Lee **completos** los archivos que el relevo menciona.
4. Comprueba lo que el relevo dice que funcionaba: ejecútalo de nuevo. No confíes en "ya funcionaba".
5. Continúa por el "Siguiente paso" del relevo. Si no está claro, pregunta.

## 3. El relevo (obligatorio al terminar o al parar)

Escríbelo en `00_ESTADO_ACTUAL.md` §7 (sobrescribiendo la anterior) **y**, si
hay issue de Linear, también como comentario en la issue. Usa exactamente esta
plantilla:

```markdown
- **Fecha:** AAAA-MM-DD
- **Rama:** tipo/descripcion
- **Issue:** BE-XX o DS-XX (o "sin issue")
- **Objetivo de la sesión:** una frase.
- **Qué se hizo:** lista corta, con rutas de archivo.
- **Probado:** qué se ejecutó y qué se vio. Si no se probó: "NO PROBADO, porque ...".
- **Qué quedó a medias:** exactamente dónde (archivo + función).
- **Errores pendientes:** el mensaje literal, copiado.
- **Decisiones tomadas:** y por qué. Si es de arquitectura → ADR.
- **Preguntas para Zyra:** lo que no pudiste decidir.
- **Siguiente paso:** UNA acción concreta y pequeña.
```

Un buen "Siguiente paso": *"En `OptionsState.hx`, función `create()`, añadir la
fila 'Reduce flashes' copiando la fila 'Flashing lights'."*
Un mal "Siguiente paso": *"Seguir con las opciones."*

## 4. Probar los cambios

- **Cambios solo en `mods/fnf-echoes/`** (HScript, shaders, datos, imágenes): no hace falta recompilar el motor. Cierra el juego y vuelve a abrir el `.app`/`.exe` ya compilado. El mod se enlaza junto al ejecutable (ver `docs/PROJECT_STRUCTURE.md`, regla 6).
  - Para encontrar el ejecutable compilado: `find engine/export -maxdepth 4 -name "*.app"` (macOS).
- **Cambios en `engine/`** (solo con ADR): recompilar siguiendo la receta del ADR-0001 (macOS). Ese proceso es largo y delicado; si falla, **no improvises parches**: copia el error literal y para.
- **Windows** nunca se ha probado. Si tu cambio es específico de una plataforma, dilo en el commit y en el relevo.
- Lo visual (shaders, animaciones, sincronía con la música) **solo se valida mirando el juego**. Si no puedes verlo, escribe "NO PROBADO VISUALMENTE".

## 5. Commits y PR

El flujo completo (issue de Linear → rama → PR → merge) está en `docs/GIT_WORKFLOW.md`. Lo mínimo:

- Parte de una issue de Linear; su ID va en la rama (`feature/BE-12-descripcion`) y al final del commit.
- Commit pequeño, un tema: `tipo: descripción corta (BE-12)` en español (`feat`, `fix`, `docs`, `chore`, `refactor`).
- Antes de abrir la PR: checklist de `docs/CODING_STANDARDS.md`.
- La PR va **contra `main`**, con `Closes BE-12` y explica **qué** y **por qué**. Si hubo decisión de arquitectura, enlaza el ADR.
- El merge ("Rebase and merge") lo hace Zyra tras leer su propio diff. **Tú no mergeas** salvo que Zyra lo pida explícitamente en esa sesión.
- Tras el merge, Zyra limpia con `git done` desde el checkout principal (`GIT_WORKFLOW.md` §8). Si trabajas en un **worktree** (`FNF_Echoes-worktrees/`), lee `GIT_WORKFLOW.md` §12 antes: `engine/` llega vacío, `git checkout main` falla y probar el juego exige reapuntar un enlace.

## 6. Al terminar (checklist final)

1. [ ] El cambio hace solo lo que se pidió.
2. [ ] Código en inglés, documentación en español.
3. [ ] Probado, o marcado "NO PROBADO" con el motivo.
4. [ ] Commit hecho en una rama (nunca en `main`).
5. [ ] Relevo escrito (§3).
6. [ ] `00_ESTADO_ACTUAL.md` actualizado si cambió algo del estado general.
7. [ ] Si se tomó una decisión técnica nueva → ADR o nota en `docs/CODING_STANDARDS.md`.
