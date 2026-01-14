# Project Roadmap

> **Last Updated:** 2026-01-13  
> **Current Focus:** Complete MVP Gameplay Loop

---

## 🔴 CRITICAL: MVP Completion

**Goal:** Test if creature production → deploy → harvest → recycle is engaging.

### Completed

- [x] Processing system with behavior-based architecture
- [x] Assembler behavior (blank → idle → ready → working → complete)
- [x] Ingredient detection, consumption on completion
- [x] Output production with stacking
- [x] Mana consumption per tick
- [x] NO_MANA and BLOCKED states
- [x] Mana fragment and regeneration system

### Pending

- [x] Start Ritual button in machine UI
- [x] Deploy assembled creatures using EntityRegistry
- [x] Placement system with ghost preview
- [ ] Collision detection for placement (red/green)
- [x] Toolbar item click → spawn entity
- [ ] Harvest interaction (click skeleton → harvest)
- [ ] Harvest timer and mana yield
- [ ] Recycle interaction to return materials

---

## 🟡 HIGH: Processing UI

- [x] Progress bar in Assembler UI
- [x] State label display
- [x] Mana display in machine view
- [ ] Color-code bars by state
- [ ] Recipe preview (requirements vs current)
- [ ] Show expected outputs before start
- [ ] Ritual visualization

---

## 🟢 MEDIUM: UX Polish

- [x] Machine state in inventory view
- [ ] Right-click split stack
- [ ] Shift-click transfer
- [ ] Item tooltips

---

## 🔵 LOW: Technical Debt

- [x] ECS migration (Nata → Evolved)
- [x] Simplified registries
- [ ] Replace letter rendering with sprites
- [ ] Registry validation on startup

---

## ⚪ FUTURE: Post-MVP

- [ ] Save/Load system
- [ ] Multiple creature types
- [ ] Automation buildings (conveyors, pipes)
- [ ] Global mana pool

---

## Notes

- Initial recipe assignment is hardcoded in assembler behavior
- Machine screens need non-slot widgets (buttons, dropdowns)
- Consider more complex machine visuals like Minecraft mod UIs
