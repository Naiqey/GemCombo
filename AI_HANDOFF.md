# GemCombo AI Handoff

This file is the shared coordination board for Claude and Codex.

- Claude role: project management, requirements, backlog, design notes.
- Codex role: implementation, Godot debugging, tests, commits.
- Source of design truth: `design.md`
- Source of task truth: `BACKLOG.md`

## Authority Order

When instructions conflict, follow this order:

1. Latest explicit user instruction
2. `AI_HANDOFF.md` Decisions and Conflicts
3. `BACKLOG.md`
4. `design.md`
5. Current code behavior

If a conflict affects implementation or scope, do not guess. Record it in `Conflicts` and ask the user, unless the latest user instruction already resolves it.

## Ownership Rules

Claude may edit:

- `AI_HANDOFF.md`
- `BACKLOG.md`
- `design.md`
- project-management notes, release plans, task specs

Codex may edit:

- Godot scripts: `*.gd`
- scenes: `*.tscn`
- resources: `*.tres`
- project config when needed
- `AI_HANDOFF.md` for implementation handoff notes

Do not edit the other assistant's active scope while it is listed in `Active Locks`, unless the user explicitly asks for an override.

## Current Focus

Owner: Codex

Priority order:
1. **BUG-003** — 诅咒生命周期修复
2. **GC-022** — 主界面显示诅咒
3. **GC-023** — 主界面显示道具 + 悬浮效果

## Latest User Requirements

- Experience leveling: killing 3 small enemies = 1 level up. Large enemies and bosses do NOT count.
- Claude uses file MCP only. Codex uses Godot MCP.
- UI text: use "波次" (wave) not "关卡" (level).
- Boss waves drop 1 relic; player chooses to take or skip.
- Curse is active ONLY while the Boss is alive; removed immediately on Boss death.
- Curse UI must be visible in the main game screen during Boss waves.
- Relics must be visible in the main game screen at all times; hover to show effect description.
- Combo bonus must apply to the card that triggers the combo, not the next card.

## Active Locks

| Owner | Scope | Since | Purpose | Status |
| --- | --- | --- | --- | --- |
| None | - | - | - | - |

## Claude Notes

### Claude Update - 2026-05-22
Changed: design.md full rewrite. BACKLOG.md rewrote GC-004, added GC-015/016/017/020/021.

### Claude Update - 2026-05-22 BUG-001
Needs Codex: Fix BUG-001 in `DeckManager.gd` `draw_card_for_effect()`.

### Claude Update - 2026-05-22 BUG-002
Needs Codex: Fix BUG-002 in `main.gd` `play_card()`.

### Claude Update - 2026-05-22 BUG-002 REOPEN
BUG-002 reset to 🔴. User confirmed still reproducing.

### Claude Update - 2026-05-22 BUG-003 + GC-022 + GC-023
Added BUG-003, GC-022, GC-023. Updated design.md §八 curse lifecycle.

### Claude Update - 2026-05-22 BUG-002 CLOSED
BUG-002 marked ✅ fixed. User confirmed resolved.

## Codex Notes

### Codex Update - 2026-05-22 03:03
Changed: EnemyWaveManager, main.gd, GemCard, cards/*.tres, card_ui. Headless validated.

### Codex Update - 2026-05-22 Draw Bugfix
Changed: DeckManager.gd draw_card_for_effect() uses discard_pile fallback.

### Codex Update - 2026-05-22 BUG-001
Changed: DeckManager.gd no longer reads from card_pool.

### Codex Update - 2026-05-22 BUG-002 / Refix / Overnight Continue / Overnight Systems
Changed: play_card() order fixed; preview combo aligned; VictoryWindow; RelicResource; relic window; ComboManager relic combo predicates; CRS-001 hand color randomization.


### Codex Update - 2026-05-22 BUG-003 GC-022 GC-023
Changed:
- main.gd: Boss deaths are now detected per dead enemy. on_boss_defeated() runs as soon as the Boss body dies, even if escort enemies remain alive.
- main.gd: on_boss_defeated() immediately calls 
emove_curse_for_level(...), so Boss-wave curses end on Boss death instead of wave clear.
- main.tscn / main.gd: Added CurseListLabel and update_curse_ui(). The label shows active curse names and hides when no curses are active.
- main.tscn / main.gd: Added RelicBar and update_relic_ui(). Picked-up relics are displayed as labels with tooltip descriptions from RelicResource.description.

Validated:
- Godot headless scene load succeeded: D:\Godot\Godot.exe --headless --path D:\GodotProject\gem-combo res://main.tscn --quit.
- Static checks confirmed BUG-003 boss-death curse removal path, CurseListLabel wiring, and RelicBar tooltip wiring.
- Godot editor MCP validation could not run in this session because MCP is still disconnected: Another MCP server connected and replaced this one.

Needs User:
- In-editor gameplay retest: enter Boss wave, confirm curse label appears; kill Boss while escorts remain, confirm curse label disappears and the next played card no longer triggers CRS-001.
- Pick up a relic and confirm RelicBar appears; hover relic name to confirm tooltip text.

### Codex Update - 2026-05-23 Art Asset Intake Prep
Changed:
- Created the ART_DIRECTION.md delivery directory structure under `assets/`, including card art/frame folders, enemy level folders, relics, icons, UI panels/buttons/popups, backgrounds, vfx, and fonts.
- Added `.gitkeep` files for empty intake folders so the structure can be committed before final art arrives.
- Added 1x1 transparent PNG placeholders for every currently missing file listed in ART_DIRECTION.md section 5 UI asset list, placed under the matching `assets/` subfolders.
- card_ui.gd: card cost-disabled state now uses `modulate.a = 0.45` and greys the cost badge with `#555555`; no separate disabled texture is required.
- card_ui.gd: gem slots now render as 8px empty circles with `#EAECEE` stroke and 1.5px line width.
- main.gd: card UI display context now passes affordability so card_ui can render disabled state from current energy.

Audit:
- `card_ui.gd`, `main.tscn`, and `main.gd` currently have no hardcoded `card_{color}_{number}_art.png`, `card_{color}_{number}_frame.png`, or `enemy_{level}_{type}_sprite.png` references to update. No existing art files were renamed.

Validated:
- Godot headless scene load succeeded: D:\Godot\Godot.exe --headless --path D:\GodotProject\gem-combo res://main.tscn --quit.

### Codex Update - 2026-05-23 Continue Backlog GC-008 GC-010
Changed:
- DeckManager.gd: merged duplicate draw-pile rebuild logic behind `_rebuild_draw_pile_from_player_deck(...)`; reset and new-turn rebuild now share one implementation.
- main.gd: target-selection mode now highlights all alive enemy buttons with an amber bordered style.
- main.gd: target selection can now be cancelled with Esc, a blank left-click, or by clicking the same pending target card again.
- Godot generated `.png.import` metadata for placeholder art assets after headless import.

Validated:
- Godot headless scene load succeeded: D:\Godot\Godot.exe --headless --path D:\GodotProject\gem-combo res://main.tscn --quit.

## Decisions

| Date | Decision | Reason |
| --- | --- | --- |
| 2026-05-21 | Claude uses file MCP only; Codex uses Godot MCP. | Avoid MCP connection conflicts. |
| 2026-05-21 | Use `design.md` instead of `design.xlsx`. | Text is faster for AI. |
| 2026-05-22 | Level structure: 5 levels × 3 waves; last wave = Boss. | User requirement. |
| 2026-05-22 | UI unit = "波次". | User requirement. |
| 2026-05-22 | Only small enemies give experience (3 = 1 level). | C-001. |
| 2026-05-22 | Gem slots: data + UI only, no logic yet. | User requirement. |
| 2026-05-22 | R-005 彩虹宝石: placeholder only. | User requirement. |
| 2026-05-22 | draw_card_for_effect() fallback: discard_pile only, never card_pool. | card_pool = all 16 global resources. |
| 2026-05-22 | combo_bonus calculated AFTER attempt_play(). | Combo applies to the triggering card. |
| 2026-05-22 | Curse lifecycle: active ONLY while Boss is alive; removed on Boss death. | User requirement (BUG-003). |

## Conflicts

| ID | Conflict | Current Decision | Owner | Status |
| --- | --- | --- | --- | --- |
| C-001 | All enemies vs small-only experience. | 3 small kills = 1 level. | — | ✅ Resolved |

## Open Questions

| ID | Question | Owner | Status |
| --- | --- | --- | --- |
| Q-001 | Rewrite GC-004 to match C-001? | — | ✅ Resolved |
| Q-002 | R-005 placeholder only? | Codex | Placeholder only |
| Q-003 | Curses stack across levels? | User | Open |

## Bug Reports

### BUG-001 抽牌从 card_pool 产生牌组外的牌

**状态**：✅ 已修复（用户待复测）

**复现**：第1回合打出其他3张后打出 yellow_01。
**预期**：抽到的牌来自 discard_pile，不含自身。
**涉及**：`DeckManager.gd` `draw_card_for_effect()`

---

### BUG-002 连击加成未生效

**状态**：✅ 已修复（用户确认 2026-05-22）

---

### BUG-003 诅咒生命周期错误：应仅在 Boss 存活期间生效

**状态**：✅ Codex 已修复，待游戏内复测

**复现**：进入 Boss 波次，击杀 Boss，观察诅咒是否解除。
**预期**：Boss 死亡后诅咒立即解除。
**实际**：诅咒持续到关卡结束。

**修复要求**：
- `remove_curse()` 在 `on_boss_defeated()` 内立即调用
- 诅咒绑定 Boss 本体，不绑定波次清空；护卫存活时击杀 Boss 诅咒也立即解除

**涉及**：`main.gd`（`on_boss_defeated()`）
**验收**：
- Boss 波次开始 → 诅咒激活
- Boss 死亡后下一次出牌 → 诅咒不生效
- 护卫存活时击杀 Boss → 诅咒立即解除

## Feature Requests

### GC-022 主界面显示当前激活的诅咒

**优先级**：P2 | **状态**：✅ Codex 已实现，待游戏内复测

**目标**：Boss 波次期间主界面实时显示激活的诅咒名称；Boss 死亡后清空。

**涉及**：`main.tscn`（新增 `CurseListLabel`）、`main.gd`（`update_curse_ui()`，在 apply/remove 时调用）

**验收**：进入 Boss 波次显示诅咒名；Boss 死亡后消失；无诅咒时隐藏。

---

### GC-023 主界面显示已持有道具，悬浮显示效果

**优先级**：P2 | **状态**：✅ Codex 已实现，待游戏内复测

**目标**：主界面固定区域横向显示所有已持有道具名称；鼠标悬浮弹出 tooltip 显示 `RelicResource.description`。

**涉及**：`main.tscn`（新增 `RelicBar`）、`main.gd`（`update_relic_ui()`，拾取道具后调用）

**验收**：
- 拾取道具后道具栏出现名称
- 悬浮显示效果描述
- 多道具横向排列不遮挡其他 UI
- 无道具时隐藏

## Handoff Protocol

When giving Claude work:

```
Read AI_HANDOFF.md first. Update with Claude Update when done. Do not modify Godot scripts.
```

When giving Codex work:

```
Read AI_HANDOFF.md and the relevant task. Validate in Godot editor (not just headless). Update AI_HANDOFF.md with Codex Update.
```
