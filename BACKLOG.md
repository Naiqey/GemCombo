# GemCombo — 开发任务 Backlog

> Claude 负责需求整理，Codex 负责实现。设计参考：`design.md`

---

## 优先级 & 状态说明

| 级别 | 含义 | 符号 | 含义 |
|------|------|------|------|
| P1 | 阻断性，游戏无法正常运行 | ⬜ | 待开始 |
| P2 | 设计偏差，影响完整性 | 🔵 | 进行中 |
| P3 | 体验质量提升 | ✅ | 已完成 |
| P4 | 可选扩展 | 🔴 | 阻塞 |

---

## P1 — 紧急

---

### GC-001 补全 16 张 .tres 卡牌数据

**优先级**：P1 | **状态**：⬜ 待开始

**目标**：按 `design.md §四卡牌列表` 填写所有 `.tres` 字段，含新增的 `gem_slots = 0`。

**涉及文件**：`cards/*.tres`、`GemCard.gd`、`EffectResource.gd`

**数值表**（来自 design.md §四）

| 文件 | card_name | color | cost | EffectType | value | dur | gem_slots |
|------|-----------|-------|------|------------|-------|-----|-----------|
| red_01 | 精准打击 | RED | 1 | DEAL_DAMAGE_SINGLE | 2 | — | 0 |
| red_02 | 灼烧 | RED | 2 | DEAL_DAMAGE_DOT | 2 | 2 | 0 |
| red_03 | 横扫 | RED | 3 | DEAL_DAMAGE_AOE | 3 | — | 0 |
| red_04 | 引爆伤口 | RED | 4 | DEAL_DAMAGE_DOT_BONUS | 4 | — | 0 |
| yellow_01 | 战术抽牌 | YELLOW | 1 | DRAW_CARD | 2 | — | 0 |
| yellow_02 | 扩充手牌 | YELLOW | 2 | INCREASE_HAND_LIMIT | 1 | — | 0 |
| yellow_03 | 蓄势 | YELLOW | 3 | GAIN_STRENGTH_TURN | 2 | — | 0 |
| yellow_04 | 抗性姿态 | YELLOW | 4 | GAIN_RESISTANCE_TURN | 2 | — | 0 |
| blue_01 | 蓄能 | BLUE | 1 | GAIN_ENERGY | 2 | — | 0 |
| blue_02 | 预支费用 | BLUE | 2 | GAIN_ENERGY_NEXT_TURN | 2 | — | 0 |
| blue_03 | 费用折扣 | BLUE | 3 | REDUCE_HAND_COST_TURN | 1 | — | 0 |
| blue_04 | 费用重置 | BLUE | 4 | RESET_ENERGY | 0 | — | 0 |
| green_01 | 疗愈 | GREEN | 1 | GAIN_HEALTH_REGEN | 3 | — | 0 |
| green_02 | 护甲 | GREEN | 2 | GAIN_BLOCK | 2 | — | 0 |
| green_03 | 护盾 | GREEN | 3 | GAIN_SHIELD | 2 | — | 0 |
| green_04 | 无敌 | GREEN | 4 | GAIN_INVINCIBLE | 1 | — | 0 |

**验收**
- `card_pool.size() == 16`；所有字段与上表一致；`gem_slots` 字段存在且 = 0

**测试**
- 逐一打出每张卡，效果和卡面数值一致
- `blue_04` 不触发 combo 加成（value=0）

---

### GC-002 补全未实现的 EffectType 分支

**优先级**：P1 | **状态**：⬜ 待开始

**目标**：`main.gd play_card()` 和 `card_ui.gd _get_card_description()` 中为 `DISCARD_CARD / APPLY_VULNERABLE / APPLY_WEAK / DOUBLE_DAMAGE_NEXT` 添加 match 分支（实现或空占位均可，不得静默失败）。

**涉及文件**：`EffectResource.gd`、`main.gd`、`card_ui.gd`

**验收**：无未处理 EffectType；card_ui 描述同步

**测试**：打出每种类型的卡不崩溃；DISCARD_CARD 弃牌堆正确更新

---

### GC-003 抽卡不能抽到自身

**优先级**：P1 | **状态**：⬜ 待开始

**目标**：确认 `play_card()` 顺序为 `remove_from_hand → resolve_effects → discard_card`；`draw_card_from_draw_pile()` 在 refill 时不从当前回合弃牌堆取牌。

**涉及文件**：`main.gd`（`play_card()`）、`DeckManager.gd`（`refill_draw_pile_from_discard()`）

**验收**：打出战术抽牌后不抽回自身；连打多张抽牌卡无循环

**测试**：手牌只剩战术抽牌时打出，确认抽出的不是本张；弃牌堆牌数正确

---

### GC-015 关卡 & 波次系统重构

**优先级**：P1 | **状态**：⬜ 待开始

**目标**：将 `EnemyWaveManager.gd` 从「6 关单波次」重构为「5 关多波次」结构，UI 文字统一改为"波次"。

**涉及文件**：`EnemyWaveManager.gd`、`main.gd`、`main.tscn`

**数据结构**：
```gdscript
# EnemyWaveManager 新结构
levels = [
  { # 关卡 1
    "name": "新手林地",
    "waves": [
      { "name": "树丛小兵", "enemies": [{"hp":5,"atk":3},{"hp":5,"atk":3}] },
      { "name": "巡逻卫兵", "enemies": [{"hp":5,"atk":3},{"hp":5,"atk":3},{"hp":5,"atk":3}] },
      { "name": "林地领主", "is_boss": true,
        "enemies": [{"hp":30,"atk":5,"type":"boss"},{"hp":5,"atk":3},{"hp":5,"atk":3}] }
    ]
  },
  # ... 关卡 2~5 见 design.md §三
]
current_level_index: int
current_wave_index: int
```

**UI 变更**
- `wave_label` 文字格式：`"关卡 {L} · 第 {W} 波次 · {name}"`
- Boss 波次入场时调用 `apply_curse(level_index)`

**验收**
- 5 关 × 各 3 波次正确加载；最后一波 `is_boss=true`
- Boss 死亡触发 `on_boss_defeated()`；小怪死亡计入 `small_enemy_kill_count`
- 所有波次完成后触发胜利

**测试**
- 关卡 1 波次 1→2→3 顺序推进
- Boss 波次死亡后弹出道具弹窗（GC-016 依赖）
- 旧 GC-007/GC-011 相关逻辑在新结构下验证通过

---

### GC-020 卡牌新增宝石槽字段与 UI 渲染

**优先级**：P1 | **状态**：⬜ 待开始

**目标**：`GemCard.gd` 添加 `@export var gem_slots: int = 0`；`card_ui.gd` 在卡牌底部渲染对应数量的空圆圈。

**涉及文件**：`GemCard.gd`、`card_ui.gd`

**验收**
- `GemCard` 有 `gem_slots` 字段，默认 0
- `gem_slots = 0` 时 UI 不渲染圆圈
- `gem_slots = 2` 时底部显示 2 个灰色空圆圈（直径约 8px）

**测试**：临时将某张卡 `gem_slots` 改为 2，运行游戏确认圆圈出现；改回 0 后消失

---

## P2 — 重要

---

### GC-004 升级触发修正（遵循 C-001）

**优先级**：P2 | **状态**：⬜ 待开始

**目标**：`gain_experience_for_enemy()` 仅对 `type == "small"` 的敌人计入经验；每累积 3 次触发升级。大怪和 Boss 不给经验。

**涉及文件**：`main.gd`（`gain_experience_for_enemy()`）

**注意**：此任务与 AI_HANDOFF C-001 保持一致，覆盖 BACKLOG 旧描述。

**验收**
- 击杀小怪：`small_kill_count` +1；达 3 时升级并重置计数
- 击杀大怪/Boss：`small_kill_count` 不变
- 升级后 `player_level / player_strength / max_player_health` 正确更新

**测试**：连杀 3 个小怪后升级弹窗出现；杀大怪不触发升级

---

### GC-005 手牌动态数值实时刷新

**优先级**：P2 | **状态**：⬜ 待开始

**目标**：`ComboManager.combo_updated` 信号触发后立即刷新所有手牌 `card_ui.set_display_context()`。

**涉及文件**：`main.gd`、`card_ui.gd`

**验收**：打出牌形成连击后，手牌中其他卡牌数值同帧更新；断连后归 0

**测试**：打出红1→剩余手牌攻击牌显示 +2；断连后恢复基础值

---

### GC-006 DoT 致死跳过敌人攻击

**优先级**：P2 | **状态**：⬜ 待开始

**目标**：`_on_end_turn_pressed()` 中，DoT tick 后若所有敌人死亡，跳过 `enemy_attack()`，直接推进波次。

**涉及文件**：`main.gd`、`EnemyWaveManager.gd`

**验收**：DoT 致死 → 无敌人攻击 → 直接进下一波次；DoT 未致死 → 正常攻击

**测试**：敌人剩 1HP + DoT 2，结束回合，玩家不受伤且进入下一波次

---

### GC-007 胜利界面

**优先级**：P2 | **状态**：⬜ 待开始

**目标**：关卡 5 第 3 波次（最终 Boss）死亡后弹出胜利弹窗，显示等级/力量/回合数，含「再来一次」按钮。

**涉及文件**：`main.gd`（新增 `show_victory_window()`）、`main.tscn`（新增 `VictoryWindow`）

**验收**：最终 Boss 死亡 → 弹窗出现；点击重开完整重置；弹窗不可关闭

**测试**：通关后弹窗显示；点击「再来一次」回合数归 1

---

### GC-008 牌堆重建逻辑去重

**优先级**：P2 | **状态**：⬜ 待开始

**目标**：合并或注释区分 `reset_draw_pile_from_player_deck` 和 `rebuild_draw_pile_from_player_deck`。

**涉及文件**：`DeckManager.gd`、`main.gd`

**验收**：两个方法职责明确，有注释；无逻辑重复

**测试**：游戏开始和第 2 回合均正确抽牌

---

### GC-016 道具系统：Boss 掉落 & 拾取弹窗

**优先级**：P2 | **状态**：⬜ 待开始（依赖 GC-015）

**目标**：Boss 死亡后弹出道具弹窗，展示名称+描述，玩家选择「拾取」或「跳过」；拾取后存入 `player_relics: Array`。

**涉及文件**：`main.gd`（`on_boss_defeated()`、`show_relic_window()`）、`main.tscn`（新增 `RelicWindow`）、新增 `RelicResource.gd`

**RelicResource 结构**：
```gdscript
class_name RelicResource extends Resource
@export var relic_id: String       # "R-001"
@export var relic_name: String     # "奇数宝珠"
@export var description: String
@export var effect_type: String    # 供 ComboManager 读取
```

**验收**
- Boss 死亡后 `RelicWindow` 弹出，显示 `relic_name` 和 `description`
- 「拾取」：`player_relics.append(relic)`；「跳过」：直接关闭
- 弹窗关闭后推进下一波次/关卡

**测试**：关卡 1 Boss 死亡后弹窗出现；拾取后 `player_relics.size() == 1`

---

### GC-017 道具效果：连击规则扩展（R-001 ~ R-004）

**优先级**：P2 | **状态**：⬜ 待开始（依赖 GC-016）

**目标**：`ComboManager.can_combo(card_a, card_b)` 在原始条件外，额外检查 `player_relics` 中的道具条件。

**涉及文件**：`ComboManager.gd`（`can_combo()`）

**道具条件表**：

| relic_id | 额外连击条件 |
|----------|------------|
| R-001 奇数宝珠 | `card_a.cost % 2 == 1 and card_b.cost % 2 == 1` |
| R-002 偶数宝珠 | `card_a.cost % 2 == 0 and card_b.cost % 2 == 0` |
| R-003 猫眼石 | `{card_a.color, card_b.color} == {BLUE, GREEN}` |
| R-004 犬视晶 | `{card_a.color, card_b.color} == {YELLOW, BLUE}` |

**最终判断逻辑**：
```gdscript
func can_combo(prev, curr) -> bool:
    if prev.color == curr.color: return true
    if prev.cost == curr.cost: return true
    for relic in player_relics:
        if check_relic_combo(relic, prev, curr): return true
    return false
```

**验收**：持有 R-001 时，1费+3费触发连击；无 R-001 时不触发

**测试**
- 无道具：费1红 → 费3蓝，断连
- 持有 R-001：费1红 → 费3蓝，连击
- 持有 R-003：蓝牌 → 绿牌，连击

---

### GC-021 诅咒系统：变色诅咒（CRS-001）

**优先级**：P2 | **状态**：⬜ 待开始（依赖 GC-015）

**目标**：进入关卡 1 Boss 波次时施加「变色诅咒」；玩家每次出牌后，手牌中所有卡牌颜色随机重新分配。

**涉及文件**：新增 `CurseManager.gd`（AutoLoad）、`main.gd`（`apply_curse()`、`after_play_card()`）、`card_ui.gd`（颜色显示）

**CurseManager 接口**：
```gdscript
# CurseManager.gd
var active_curses: Array = []
func apply_curse(curse_id: String): ...
func remove_curse(curse_id: String): ...
func is_active(curse_id: String) -> bool: ...
```

**变色诅咒逻辑**：
```
trigger: 玩家每次 play_card() 结算后
effect: 遍历手牌中所有 card，card.color = Color.values().pick_random()
        card_ui 刷新颜色显示
scope: 持续到当前关卡结束（关卡切换时 remove_curse("CRS-001")）
```

**验收**
- 进入关卡 1 Boss 波次：`CurseManager.is_active("CRS-001") == true`
- 出牌后手牌颜色随机改变（可能与原色相同）
- 颜色改变影响 `ComboManager.can_combo()` 的颜色判断
- 关卡 1 通关后：`is_active("CRS-001") == false`

**测试**：进入 Boss 波次 → 出一张牌 → 手牌颜色刷新；通关后颜色正常

---

## P3 — 改进

---

### GC-009 费用不足卡牌灰化

**优先级**：P3 | **状态**：⬜ 待开始

**目标**：能量不足时卡牌 `Button` 降低 alpha 或灰化；出牌/费用变化后立即刷新。

**涉及文件**：`card_ui.gd`、`main.gd`

**验收**：能量不足卡牌视觉置灰；蓝3减费后恢复；新回合全部恢复

**测试**：能量剩1，费用2+的卡置灰；打出蓝3后恢复

---

### GC-010 目标选择高亮 & 取消

**优先级**：P3 | **状态**：⬜ 待开始

**目标**：选目标状态下存活敌人按钮高亮；点击空白或再次点击取消，`pending_target_card = null`。

**涉及文件**：`main.gd`、`main.tscn`

**验收**：进入选目标→存活敌人高亮；点击目标→结算+高亮消失；取消→恢复正常

**测试**：点击精准打击→高亮；点击目标→结算；Esc/空白→取消

---

### GC-011 大怪差异化行为（蓄力/重击）

**优先级**：P3 | **状态**：⬜ 待开始（依赖 GC-015 新结构）

**目标**：大怪支持 `behavior: "charge"` 字段；蓄力回合 ATK=0，下回合 ATK×2；`enemy_intent_label` 提前预告。

**涉及文件**：`EnemyWaveManager.gd`、`main.gd`

**验收**：蓄力回合不攻击；重击回合 ATK 翻倍；小怪不受影响

**测试**：大怪蓄力回合玩家不受伤；下一回合伤害翻倍

---

### GC-012 存档/读档

**优先级**：P3 | **状态**：⬜ 待开始

**目标**：波次切换时写入 JSON（`user://save.json`）；启动时检测并提示继续/新游戏；重开清除存档。

**存档字段**：`level_index, wave_index, player_health, max_player_health, player_level, player_experience, player_strength, player_deck[], player_relics[]`

**涉及文件**：`main.gd`、`DeckManager.gd`

**验收**：波次切换后存档；重启从正确波次继续；死亡重开清除存档

**测试**：波次 1-2 清关后关闭，重启继续；死亡后新游戏从关卡1开始

---

## P4 — 可选

---

### GC-013 永久力量卡

**优先级**：P4 | **状态**：⬜ 待开始

**目标**：新增 `EffectType.GAIN_STRENGTH`（永久），打出后 `player_strength` 永久+value，与 `GAIN_STRENGTH_TURN` 区分。

**涉及文件**：`EffectResource.gd`、`main.gd`、`DeckManager.gd`

**验收**：下一回合力量保留；存档后读档保留

---

### GC-014 音效与动画

**优先级**：P4 | **状态**：⬜ 待开始

**目标**：卡牌打出动画（0.2s）；受伤飘字；连击 `combo_label` 缩放。

**涉及文件**：`card_ui.gd`、`main.gd`、`main.tscn`

**验收**：快速出牌不堆积；AOE 每个敌人各自飘字；断连有消散效果

---

## 附录：状态追踪

| ID | 摘要 | 优先级 | 状态 |
|----|------|--------|------|
| GC-001 | 补全卡牌数据（含 gem_slots） | P1 | ⬜ |
| GC-002 | 未实现 EffectType 修复 | P1 | ⬜ |
| GC-003 | 抽卡不能抽自身 | P1 | ⬜ |
| GC-015 | 关卡波次系统重构 | P1 | ⬜ |
| GC-020 | 宝石槽字段 + UI | P1 | ⬜ |
| GC-004 | 升级触发修正（3小怪） | P2 | ⬜ |
| GC-005 | 手牌数值实时刷新 | P2 | ⬜ |
| GC-006 | DoT 致死跳过攻击 | P2 | ⬜ |
| GC-007 | 胜利界面 | P2 | ⬜ |
| GC-008 | 牌堆重建去重 | P2 | ⬜ |
| GC-016 | 道具弹窗 & 拾取 | P2 | ⬜ |
| GC-017 | 道具连击规则扩展 | P2 | ⬜ |
| GC-021 | 诅咒：变色诅咒 | P2 | ⬜ |
| GC-009 | 费用不足灰化 | P3 | ⬜ |
| GC-010 | 目标选择高亮 | P3 | ⬜ |
| GC-011 | 大怪蓄力行为 | P3 | ⬜ |
| GC-012 | 存档/读档 | P3 | ⬜ |
| GC-013 | 永久力量卡 | P4 | ⬜ |
| GC-014 | 音效与动画 | P4 | ⬜ |
