# Roguelite de Ajedrez — Plan de Trabajo (Demo de Noviembre)

> **Meta:** Demo jugable de 3 rondas para mediados de noviembre: tienda (3 ofertas + reroll), compra/colocación, combate automático básico, victoria/derrota, recompensas, HUD minimal y export.

---

## ✅ Objetivos de la Demo
- [ ] Run jugable corta de **3 rondas**
- [x] **Tienda** (3 ofertas + reroll)
- [x] **Compra** desde blueprints y **colocación** en tablero
- [ ] **Combate automático** básico (turnos alternados, reglas por pieza)
- [ ] **Victoria/Derrota** + **recompensa** de oro por ronda
- [ ] **HUD** minimal (oro, ronda, botones de fase/tienda)
- [ ] **Seed** reproducible
- [ ] **Export** (Windows/Linux) + script de **presentación (5–7 min)**

---

## 🗓️ Roadmap por Sprints

### Sprint 0 — Setup & Esqueleto _(26–28 sep)_
**Objetivo:** dejar el proyecto listo para iterar.
- [x] Crear repo y proyecto **Godot 4.x**
- [x] Estructura carpetas: `scenes/`, `scripts/`, `ui/`, `assets/placeholder/`, `core/`, `combat/`, `shop/`
- [x] Stubs de clases: `Run`, `Round`, `Board`, `BoardTile`, `Player`, `Shop`, `ShopOffer`, `Piece` (+subclases), `PieceBlueprint`, `Enemy`, `Behavior`, `Effect`
- [x] Enums: `PieceType`, `Rarity`, `TileState`, `RunState`
**DoD**
- [ ] Escena principal corre con botón **Start Run**

---

### Sprint 1 — Modelo + Tablero Base _(29 sep – 5 oct)_
**Objetivo:** tablero operativo y piezas colocables (sin combate).
- [x] `Board`: grilla visible, estados (vacía/ocupada)
- [x] Colocar/retirar `Piece` en el tablero 
- [x] `legalMoves()` para **Peón**, **Torre**, **Caballo** (resto stub)
- [ ] HUD básico: **oro** + **inventario**
**DoD**
- [x] Arrastrar/colocar piezas y devolverlas
- [x] `legalMoves()` pinta casillas válidas

---

### Sprint 2 — Tienda y Economía _(6 – 12 oct)_
**Objetivo:** comprar piezas a partir de blueprints.
- [x] `PieceBlueprint` con `base_hp/atk/range` y `instantiate()`
- [x] `Shop`: n ofertas, `reroll(cost)`, precios por `Rarity`
- [x] `Player.buy()`: descuenta oro, agrega al inventario, valida fondos
- [ ] UI tienda: lista de ofertas, **Comprar** y **Reroll**
**DoD**
- [x] Inventario se actualiza al comprar
- [x] Reroll consume oro y renueva ofertas

---

### Sprint 3 — Loop de Ronda & Progresión _(13 – 19 oct)_
**Objetivo:** cerrar el ciclo Tienda → Colocación → (Combate placeholder) → Recompensa.
- [ ] `Round.start()` / `Round.resolve()`
- [ ] Estados de fase en UI y navegación
- [ ] `Run.nextRound()`: tamaño prog. **5×5 → 6×6 → 7×7**
- [ ] Recompensa de oro fija por ronda
**DoD**
- [ ] Completar **2 rondas** con transición de fases
- [ ] Resolución de combate placeholder (si aún no está el real)

---

### Sprint 4 — Combate Automático _(20 – 26 oct)_
**Objetivo:** combate funcional básico.
- [x] Sistema de **turnos** (alternado / iniciativa simple)
- [x] Movimiento/ataque según `PieceType` (mín.: Peón, Torre, Caballo)
- [ ] `Enemy` + `Behavior` **agresivo** simple
- [ ] `Board.isVictory()` (condición de fin)
**DoD**
- [x] Piezas **se mueven y atacan** hasta resultado
- [ ] `Round.resolve()` avanza a la siguiente ronda

---

### Sprint 5 — Efectos & Balance Inicial _(27 oct – 2 nov)_
**Objetivo:** dar “sabor” y cerrar MVP.
- [ ] 2–3 **Effects** simples: 
  - [ ] `+1 ATK` a **Peones**
  - [ ] `Curación +1` al iniciar ronda
  - [ ] `Armadura +1` al primer golpe
- [ ] 1 **Event** post-ronda (opcional)
- [ ] Ajustar **stats** y **costos** en `PieceBlueprint`
- [ ] Persistir **seed** y permitir **reintentar** seed
**DoD**
- [ ] Effects aplican en combate/estado
- [ ] Flujo de tienda reproducible por seed

---

### Sprint 6 — UI/UX, Export y Script de Demo _(3 – 9 nov)_
**Objetivo:** dejarlo presentable y exportable.
- [ ] HUD prolijo (oro, ronda, botones de fase, mini log de acciones)
- [ ] Pantallas: **Title**, **Run en curso**, **Fin de run**
- [ ] **Export** Godot a Windows/Linux
- [ ] **Script de demo** paso a paso + semillas de referencia
**DoD**
- [ ] Build corre fuera del editor
- [ ] Se juegan **3 rondas** completas y termina la run

---

### Sprint 7 — Buffer, Pruebas y Presentación _(10 – 15 nov)_
**Objetivo:** estabilizar y preparar presentación.
- [ ] Fixes de bugs / limpieza de logs
- [ ] Presentación (5–7 min): objetivo, diagrama, gameplay loop, lecciones y backlog
- [ ] Capturas/GIFs de gameplay
**DoD**
- [ ] Demo estable
- [ ] Presentación lista
- [ ] README completo

---

## 📦 MVP Técnico
- [ ] Piezas: **Peón**, **Torre**, **Caballo**
- [ ] Tablero: cuadrícula + casilla **normal** (opcional **bloqueada**)
- [ ] IA: 1 `Behavior` **agresivo**
- [ ] Efectos: **2** (uno global y uno por pieza)
- [ ] Economía: 3 `Rarity` (**Común/Raro/Épico**)
- [ ] Rondas: **3** (5×5 → 6×6 → 7×7)

---

## 🧩 Backlog (post-demo)
- [ ] Más tipos de pieza (**Alfil**, **Reina**, **Rey**) y reglas avanzadas
- [ ] `Behavior` adicionales (oportunista, foco al rey)
- [ ] Más **Effects** y **Events**
- [ ] Animaciones/partículas
- [ ] Guardado de run y **metaprogresión**
- [ ] Balance fino de precio/rareza

---

## 🧪 Pruebas mínimas

**Unitarias**
- [x] `legalMoves()` por tipo
- [x] `Shop.reroll()` y distribución de `Rarity`
- [x] `Player.buy()` sin fondos
- [ ] `Effect.apply/remove`

**Integración**
- [ ] Tienda → Colocación → Combate → Recompensa (2 seeds distintas)

**UI**
- [ ] Botones deshabilitados según fase
- [ ] Feedback de **oro insuficiente**

---

## 🗃️ Estructura de Carpetas (sugerida)