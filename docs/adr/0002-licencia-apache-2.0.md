# ADR-0002: Licencia de código y assets de FNF_Echoes

**Status:** Accepted
**Date:** 2026-08-05
**Deciders:** Salchorizo

## Contexto

FNF_Echoes es un mod/juego de ritmo basado en Friday Night Funkin', desarrollado como Trabajo de Fin de Máster pero con ambición de ser un producto real con buena producción y potencial de crecimiento más allá del ámbito académico.

El proyecto tiene requisitos específicos que condicionan la elección de licencia:

1. **Protección legal preventiva:** El autor requiere máxima protección contra trolls de patentes y litigios maliciosos.
2. **Comunidad y modding:** Se espera que la comunidad moddee sobre el proyecto y se inspire en su arquitectura.
3. **Compatibilidad de dependencias:** El proyecto depende de Codename Engine y del código fuente de Friday Night Funkin', ambos bajo Apache 2.0.
4. **Separación código/assets:** Los assets artísticos (arte, música, personajes propios) son propiedad intelectual original del autor y requieren protección diferente al código.
5. **Escalabilidad:** El proyecto aspira a crecer como producto real, no limitarse a un entregable académico.

## Decisión

Se usará **Apache License 2.0** para el código fuente del proyecto y **todos los derechos reservados** para los assets artísticos propios.

## Opciones consideradas

### Opción A: Apache License 2.0 (ELEGIDA)

| Dimensión | Evaluación |
|---|---|
| Protección anti-patentes | ✅ Cláusula de retaliación explícita: si alguien demanda por patentes, pierde la licencia |
| Permisividad para modding | ✅ Permite modificaciones, derivados y distribución sin restricciones |
| Compatibilidad con dependencias | ✅ Codename Engine y FNF código usan Apache 2.0 — máxima compatibilidad |
| Complejidad | Media — requiere NOTICE file y mantenimiento de atribuciones |
| Apropiado para proyectos ambiciosos | ✅ Usada por empresas grandes (Google, Apache Foundation) — escala bien |
| Protección de assets | ✅ Posible separación código/assets (código Apache 2.0, assets reservados) |

**Pros:** Protección real contra trolls de patentes, compatibilidad perfecta con dependencias, permite modding, escala con el proyecto.
**Contras:** Más compleja que MIT/BSD, requiere mantener NOTICE file.

### Opción B: MIT License

| Dimensión | Evaluación |
|---|---|
| Protección anti-patentes | ❌ Sin cláusula de retaliación — vulnerabilidad a trolls |
| Permisividad para modding | ✅ Permite modificaciones, derivados y distribución |
| Compatibilidad con dependencias | ✅ Compatible con Apache 2.0 (reciprocidad parcial) |
| Complejidad | Baja — muy simple, ~170 palabras |
| Apropiado para proyectos ambiciosos | ⚠️ Más común en proyectos personales/educativos |
| Protección de assets | ✅ Posible separación código/assets |

**Pros:** Simple, estándar en proyectos personales, permite modding.
**Contras:** Sin protección anti-patentes, menos robusta para proyectos con ambición comercial.

### Opción C: BSD 3-Clause

| Dimensión | Evaluación |
|---|---|
| Protección anti-patentes | ❌ Sin cláusula de retaliación |
| Permisividad para modding | ✅ Permite modificaciones, derivados y distribución |
| Compatibilidad con dependencias | ✅ Compatible con Apache 2.0 |
| Complejidad | Media — cláusula de "no endorsement" |
| Apropiado para proyectos ambiciosos | ⚠️ Más común en proyectos académicos/empresariales tradicionales |
| Protección de assets | ✅ Posible separación código/assets |

**Pros:** Balance entre simplicidad y protección, compatible con Apache 2.0.
**Contras:** Sin protección anti-patentes, menos común en ecosistema de mods.

### Opción D: GPL (descartada)

| Dimensión | Evaluación |
|---|---|
| Protección anti-patentes | ✅ Tiene cláusulas de patentes |
| Permisividad para modding | ❌ Copyleft — obliga a que derivados sean GPL también |
| Compatibilidad con dependencias | ❌ Incompatible con Apache 2.0 en algunas combinaciones |
| Complejidad | Alta — múltiples variantes (GPL-2.0, GPL-3.0, AGPL, LGPL) |
| Apropiado para proyectos ambiciosos | ⚠️ Usada por proyectos con ideología de software libre fuerte |
| Protección de assets | ❌ Difícil separación código/assets bajo copyleft |

**Pros:** Protección anti-patentes, ideología de software libre.
**Contras:** Copyleft restrictivo, incompatible con dependencias Apache 2.0, no alineado con objetivo de permitir modding sin restricciones.

## Análisis de trade-offs

El criterio decisivo es la protección contra trolls de patentes combinado con la compatibilidad de dependencias. MIT y BSD son más simples pero no ofrecen la cláusula de retaliación de Apache 2.0, que es la única protección estándar en licencias open source contra litigio de patentes. Dado que el autor requiere "máxima protección legal preventiva", Apache 2.0 es la única opción estándar que cumple este requisito.

La compatibilidad con Codename Engine y FNF (ambos Apache 2.0) es perfecta — no hay conflicto de licencias ni necesidad de excepciones. MIT/BSD serían compatibles pero subóptimos.

La separación código/assets es válida y común en proyectos de juegos: el código (Apache 2.0) permite que la comunidad moddee y aprenda de la arquitectura, mientras los assets (todos los derechos reservados) protegen la propiedad intelectual artística original del autor. Esta estructura está documentada en `NOTICE.md`.

## Consecuencias

- Se gana: protección real contra trolls de patentes, compatibilidad perfecta con dependencias, permiso para modding comunitario, estructura que escala si el proyecto crece comercialmente.
- Se acepta: complejidad media (mantenimiento de NOTICE file), mayor longitud de licencia que MIT/BSD.
- Protección dual: código abierto para contribuir al ecosistema, assets protegidos como propiedad intelectual original.

## Separación código/assets

La licencia Apache 2.0 aplica únicamente al código fuente (`mods/fnf-echoes/` y scripts Haxe). Los assets artísticos propios (arte, música, personajes, escenarios) están bajo todos los derechos reservados del autor (Salchorizo). Esta separación está documentada en `NOTICE.md` y es válida legalmente: la licencia del código no afecta los derechos de autor sobre los assets.

## Action Items

1. [x] Verificar que NOTICE.md sea claro sobre la separación código/assets.
2. [x] Actualizar nombre del autor en todos los archivos legales (Juan David Hoyos Ruiz → Salchorizo).
3. [ ] Mantener el NOTICE file actualizado si se añaden nuevas dependencias con requisitos de atribución específicos.
4. [ ] Si el proyecto crece comercialmente, revisar con abogado de propiedad intelectual si la estructura de licencia dual sigue siendo óptima.
