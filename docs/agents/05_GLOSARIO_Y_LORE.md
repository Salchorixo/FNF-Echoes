# 05 — Glosario y lore (lo mínimo para no equivocarse)

La fuente completa de la historia está en Notion ("FNF Echoes || (WIP)" →
Historia y Canción 3 final). Esto es solo lo que un agente necesita para no
cometer errores en código, textos o nombres.

---

## 1. Glosario

| Término | Significado |
|---|---|
| **Echoes** | El conjunto del mod / la historia completa. Nunca se traduce. |
| **Echo** | Una temporada. Nunca se traduce. |
| **Capítulo / nodo** | Un punto del tablero-mapa (`StoryMapState`). |
| **Bloque** | Cada una de las dos mitades de una canción (antes y después de un giro de la historia). |
| **EchoOS** | El "sistema operativo" ficticio que dibuja el juego para la parte final: ventanas, pop-ups de error, carpetas, monitor de procesos. **No imita ni a Windows ni a macOS.** |
| **Crasheo 1** | Cierre real y controlado del juego al final del bloque 1 de la canción de Kiyu. El jugador debe reabrir el mod. |
| **Crasheo 2** | Cierre **falso**, dentro del juego: pop-up, Zyra detrás, impact frame, oscuridad. |
| **Menú roto** | Pantalla de inicio alterada que aparece al reabrir después del crasheo 1. |
| **Ficha de voz** | Descripción fija de la voz de un personaje que se repite literal en cada prompt de Suno. |
| **ADR** | Architecture Decision Record, en `docs/adr/`. |

## 2. Personajes

| Personaje | Qué es | Voz (en Suno) |
|---|---|---|
| **Zyra** | Protagonista. Gatito negro, **macho** ("él"). Una IA que tomó el cuerpo de un NPC; sus sentimientos distorsionan el mundo. | Aguda, tierna, con un toque leve de distorsión digital. |
| **Soul** | El primero de todos, con consciencia propia. Fue **reemplazado por Zyra** tras malos tratos. Vende las píldoras. Quiere sabotear a Zyra. | Versión más vieja, cansada y ronca de una voz de gato joven. |
| **Taro** | Perro, segunda canción. Producto de la imaginación de Zyra. | Grave (tenor bajo), cool, staccato, brillo robótico. |
| **Kiyu** | Gatita, canción final. Producto de la imaginación de Zyra: la persona de la que se enamora nunca existió. | Media, limpia, redonda como flauta sintética, juguetona. |

**Solo Zyra y Soul tienen consciencia.** Todo lo demás ocurre en la cabeza de
Zyra, dentro del computador.

## 3. Las 3 canciones

1. **Soul** — Zyra en crisis compra las píldoras.
2. **Taro** — Cita; Taro le da una pastilla y Zyra pierde el control.
3. **Kiyu (final)** — Bloque 1 romántico con Kiyu → crasheo 1 → menú roto → crasheo 2 → cutscene en la oscuridad → bloque 2: Zyra solo descubre que es una IA, rompe ventanas y el fondo deja ver el escritorio → final abierto.

## 4. Reglas de diseño que afectan al código

- **Nada de copiar el sistema real:** no uses nombres como `.exe` ni ventanas que imiten Windows o macOS. Todo es estilo EchoOS.
- **Privacidad:** el juego **nunca** captura, guarda ni envía nada del escritorio del jugador. La transparencia solo deja "ver a través".
- **Opción de privacidad:** "Efectos de escritorio" activado/desactivado (para quien juega en stream). Desactivado → se usa el escritorio falso.
- **Fotosensibilidad:** advertencia al inicio del mod y opción para reducir destellos (por el impact frame y los glitches).
- **Plataformas:** todo lo que dependa del sistema debe tener comportamiento definido en macOS **y** en Windows, o un plan B.

## 5. Si te piden ayudar con prompts de Suno

- Las voces van **por turnos**, nunca cantando a la vez.
- Solo vocales (ah, eh, ih, oh), sin palabras.
- Reglas obligatorias en cada prompt: la voz nunca se vuelve instrumento ni bajo, sin efectos, sin cambiar de tono fuera de su rango, cada voz idéntica de principio a fin.
- Límites de Suno: Style máx. 1000 caracteres; Lyrics máx. 5000.
- Instrucciones cortas por sección. Sin nombres de notas ni compases (Suno no los lee).
- Zyra siempre "he/his". Nunca se usa la función Voice/Persona de Suno.
