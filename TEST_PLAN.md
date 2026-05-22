# GemCombo — 自动化测试计划

> 生成日期：2026-05-22
> 来源：AI_HANDOFF.md / BACKLOG.md / design.md
> 执行方式：GDScript 单元测试（推荐 GUT 框架）或 Godot MCP 脚本驱动
> 不覆盖：UI 像素级视觉测试、音效、动画（属人工验收范围）

---

## 系统索引

| 系统 | 用例范围 |
|------|----------|
| 1. 牌堆系统 | TC-001 ~ TC-008 |
| 2. 连击系统 | TC-009 ~ TC-018 |
| 3. 卡牌效果 | TC-019 ~ TC-036 |
| 4. 防御系统 | TC-037 ~ TC-044 |
| 5. 升级系统 | TC-045 ~ TC-049 |
| 6. 关卡波次 | TC-050 ~ TC-059 |
| 7. 道具系统 | TC-060 ~ TC-068 |
| 8. 诅咒系统 | TC-069 ~ TC-074 |
| 9. 宝石槽 | TC-075 ~ TC-077 |
| 10. 游戏流程 | TC-078 ~ TC-084 |

---

## 1. 牌堆系统

### TC-001
**目标**：游戏开始时玩家牌组包含 4 张 1 费卡
**前置**：调用 `start_fresh_game()`
**操作**：读取 `deck_manager.player_deck`
**断言**：`player_deck.size() == 4`；每张 `card.cost == 1`
**优先级**：P1

---

### TC-002
**目标**：抽牌堆从玩家牌组完整复制
**前置**：`start_fresh_game()` 后
**操作**：读取 `deck_manager.draw_pile`
**断言**：`draw_pile.size() == player_deck.size()`；两者 card_name 集合一致
**优先级**：P1

---

### TC-003
**目标**：每回合开始重建抽牌堆，弃牌堆清空
**前置**：第 1 回合打出 2 张牌（进入弃牌堆），调用 `draw_new_turn_hand()`
**操作**：读取 `discard_pile` 和 `draw_pile`
**断言**：`discard_pile.size() == 0`；`draw_pile` 来自 `player_deck`
**优先级**：P1

---

### TC-004
**目标**：抽牌效果不能抽到自身（BUG-001 / BUG-003 覆盖）
**前置**：手牌只剩 yellow_01（战术抽牌），其余 3 张在弃牌堆
**操作**：`play_card(yellow_01)`；读取新增手牌
**断言**：新手牌中不含 yellow_01；新手牌均来自 `player_deck`
**优先级**：P1

---

### TC-005
**目标**：抽牌堆和弃牌堆均空时，抽牌返回 null 且游戏不崩溃
**前置**：`draw_pile = []`；`discard_pile = []`
**操作**：调用 `deck_manager.draw_card_for_effect(null)`
**断言**：返回值 `== null`；无异常抛出
**优先级**：P1

---

### TC-006
**目标**：抽牌堆耗尽时，从弃牌堆补充（不含当前打出的牌）
**前置**：`draw_pile = []`；`discard_pile` 含 3 张牌；`excluded_card = discard_pile[0]`
**操作**：`deck_manager.draw_card_for_effect(excluded_card)`
**断言**：抽出的牌不是 `excluded_card`；`draw_pile` 来源为 `discard_pile` 减去 `excluded_card`
**优先级**：P1

---

### TC-007
**目标**：card_pool 不参与抽牌（BUG-001 回归测试）
**前置**：`player_deck` 只含 4 张特定卡；反复抽牌 20 次
**操作**：`deck_manager.draw_card_for_effect()` × 20
**断言**：抽出的所有卡 card_name 均在 `player_deck` 的 card_name 集合内
**优先级**：P1

---

### TC-008
**目标**：手牌达到上限时，抽牌操作无效且不崩溃
**前置**：手牌 `size() == max_hand_size`
**操作**：调用 `draw_card_from_draw_pile()`
**断言**：手牌 size 不变；draw_pile size 不变
**优先级**：P2

---

## 2. 连击系统

### TC-009
**目标**：第一张牌 combo = 0，不产生加成
**前置**：`ComboManager.break_combo()`（确保 last_card = null）
**操作**：`ComboManager.attempt_play(red_01)`
**断言**：`ComboManager.current_combo == 0`
**优先级**：P1

---

### TC-010
**目标**：同色连击 combo +1
**前置**：`attempt_play(red_01)`（combo=0，last_card=red_01）
**操作**：`attempt_play(red_03)`（同色红，不同费）
**断言**：`current_combo == 1`
**优先级**：P1

---

### TC-011
**目标**：同费连击 combo +1
**前置**：`attempt_play(blue_01)`（费用1，combo=0）
**操作**：`attempt_play(yellow_01)`（费用1，不同色）
**断言**：`current_combo == 1`
**优先级**：P1

---

### TC-012
**目标**：颜色和费用均不同时断连，combo 归 0
**前置**：`attempt_play(red_01)`（红，费1，combo=0）
**操作**：`attempt_play(blue_02)`（蓝，费2）
**断言**：`current_combo == 0`；`last_card == null`
**优先级**：P1

---

### TC-013
**目标**：连击加成在触发连击的当张牌结算时生效（BUG-002 回归）
**前置**：`start_fresh_game()`；手牌含 blue_01（费1）和 yellow_01（费1，抽2张）；`player_strength = 0`
**操作**：`play_card(blue_01)`；`play_card(yellow_01)`；记录抽牌数
**断言**：yellow_01 打出后 `current_combo == 1`；本回合抽牌数 = `2 + 1×2 = 4`
**优先级**：P1

---

### TC-014
**目标**：连续 3 连击加成值正确
**前置**：连续打出 3 张同色牌（combo 依次为 0→1→2）
**操作**：第 3 张（combo=2）打出，效果 value=2 的卡
**断言**：结算值 = `2 + 2×2 = 6`
**优先级**：P1

---

### TC-015
**目标**：回合结束后 combo 重置
**前置**：打出 2 张同色牌，`current_combo == 1`
**操作**：`_on_end_turn_pressed()`；开始下一回合
**断言**：新回合 `current_combo == 0`；`last_card == null`
**优先级**：P1

---

### TC-016
**目标**：blue_04（RESET_ENERGY，value=0）不触发连击加成
**前置**：已有连击 combo=2；打出 blue_04
**操作**：记录 blue_04 结算时的 combo_bonus
**断言**：blue_04 效果不受 combo_bonus 影响（`RESET_ENERGY` 恢复费用固定，不加 combo）
**优先级**：P2

---

### TC-017
**目标**：道具 R-001（奇数宝珠）——奇费连击
**前置**：`player_relics` 含 R-001；`attempt_play(red_01)`（费1红）
**操作**：`attempt_play(blue_03)`（费3蓝，不同色不同费，但同为奇数）
**断言**：`current_combo == 1`（R-001 扩展连击成功）
**优先级**：P2

---

### TC-018
**目标**：道具 R-003（猫眼石）——蓝绿互连
**前置**：`player_relics` 含 R-003；`attempt_play(blue_01)`（蓝，费1）
**操作**：`attempt_play(green_02)`（绿，费2，不同色不同费）
**断言**：`current_combo == 1`（R-003 扩展连击成功）
**优先级**：P2

---

## 3. 卡牌效果

### TC-019
**目标**：DEAL_DAMAGE_SINGLE 单体伤害公式正确
**前置**：`player_strength=1`；`turn_strength=0`；`combo_bonus=2`（combo=1）；敌人 HP=10
**操作**：`play_card(red_01, target_index=0)`（base=2）
**断言**：敌人 HP = `10 - (2 + 2 + 1) = 5`
**优先级**：P1

---

### TC-020
**目标**：DEAL_DAMAGE_AOE 对所有存活敌人造成相同伤害
**前置**：3 个存活敌人，HP 各 8；`combo_bonus=0`；`player_strength=0`
**操作**：`play_card(red_03)`（base=3）
**断言**：3 个敌人 HP 均为 `8-3=5`
**优先级**：P1

---

### TC-021
**目标**：DEAL_DAMAGE_DOT 施加持续伤害，不吃力量
**前置**：`player_strength=3`；`combo_bonus=0`；敌人 HP=20
**操作**：`play_card(red_02, target_index=0)`（base=2，duration=2）
**断言**：敌人 `dot_damage==2`；`dot_duration==2`；敌人 HP=20（施加时不立即扣血）
**优先级**：P1

---

### TC-022
**目标**：DoT 每回合结算，持续回合递减
**前置**：敌人有 `dot_damage=3`，`dot_duration=2`，HP=20
**操作**：`tick_enemy_dot()`（第1次）
**断言**：敌人 HP=17；`dot_duration==1`
**优先级**：P1

---

### TC-023
**目标**：DoT 持续到 0 时消除
**前置**：敌人 `dot_damage=3`，`dot_duration=1`，HP=10
**操作**：`tick_enemy_dot()`
**断言**：敌人 HP=7；`dot_duration==0`
**优先级**：P1

---

### TC-024
**目标**：DEAL_DAMAGE_DOT_BONUS 目标有 DoT 时额外 +3
**前置**：敌人有 DoT；`player_strength=0`；`combo_bonus=0`；HP=20
**操作**：`play_card(red_04, 0)`（base=4）
**断言**：敌人 HP = `20 - (4+0+0+3) = 13`
**优先级**：P1

---

### TC-025
**目标**：DEAL_DAMAGE_DOT_BONUS 目标无 DoT 时无额外伤害
**前置**：敌人无 DoT；`player_strength=0`；`combo_bonus=0`；HP=20
**操作**：`play_card(red_04, 0)`（base=4）
**断言**：敌人 HP = `20 - 4 = 16`
**优先级**：P1

---

### TC-026
**目标**：DRAW_CARD 抽牌数正确（无连击）
**前置**：手牌 1 张（yellow_01），`draw_pile` 有 3 张；`combo_bonus=0`
**操作**：`play_card(yellow_01)`
**断言**：手牌增加 2 张；`draw_pile.size()` 减少 2
**优先级**：P1

---

### TC-027
**目标**：GAIN_ENERGY 增加本回合费用
**前置**：`current_player_energy=2`；`current_player_energy_max=4`；`combo_bonus=0`
**操作**：`play_card(blue_01)`（base=2）
**断言**：`current_player_energy == 4`（扣1费打牌后+2，但实际：打牌前2费，扣1后1费，再+2=3费）
> 注：实际断言 = 打牌前能量 - cost + effect_value = 2 - 1 + 2 = 3
**断言修正**：`current_player_energy == 3`；`current_player_energy_max == 4+2 = 6`
**优先级**：P1

---

### TC-028
**目标**：GAIN_ENERGY_NEXT_TURN 下回合才生效
**前置**：`next_turn_energy_bonus=0`；`combo_bonus=0`
**操作**：`play_card(blue_02)`（base=2）；结束回合；开始新回合
**断言**：本回合 `current_player_energy` 不因此牌增加；新回合 `current_player_energy_max = BASE(4) + 2 = 6`
**优先级**：P1

---

### TC-029
**目标**：REDUCE_HAND_COST_TURN 本回合手牌费用降低，最低 0
**前置**：`hand_cost_reduction=0`；`combo_bonus=0`
**操作**：`play_card(blue_03)`（base=1）；读取一张费用 1 的卡实际费用
**断言**：`hand_cost_reduction==1`；费用 1 的卡 `get_current_card_cost() == 0`
**优先级**：P1

---

### TC-030
**目标**：RESET_ENERGY 恢复费用到当前上限
**前置**：`current_player_energy=1`；`current_player_energy_max=4`
**操作**：`play_card(blue_04)`（cost=4，需先保证能量足够，可设 energy=4 再扣3）
**断言**：`current_player_energy == current_player_energy_max`
**优先级**：P1

---

### TC-031
**目标**：GAIN_HEALTH_REGEN 回血不超过最大生命
**前置**：`current_player_health=28`；`max_player_health=30`；`combo_bonus=0`
**操作**：`play_card(green_01)`（base=3）
**断言**：`current_player_health == 30`（上限封顶）
**优先级**：P1

---

### TC-032
**目标**：GAIN_BLOCK 护甲可叠加
**前置**：`current_player_block=2`；`combo_bonus=0`
**操作**：`play_card(green_02)`（base=2）
**断言**：`current_player_block == 4`
**优先级**：P1

---

### TC-033
**目标**：GAIN_SHIELD 护盾设置
**前置**：`current_player_shield=0`；`combo_bonus=0`
**操作**：`play_card(green_03)`（base=2）
**断言**：`current_player_shield == 2`
**优先级**：P1

---

### TC-034
**目标**：GAIN_INVINCIBLE 本回合无敌标志设置
**前置**：`is_invincible=false`
**操作**：`play_card(green_04)`
**断言**：`is_invincible == true`
**优先级**：P1

---

### TC-035
**目标**：GAIN_STRENGTH_TURN 本回合力量增加
**前置**：`turn_strength=0`；`combo_bonus=0`
**操作**：`play_card(yellow_03)`（base=2）
**断言**：`turn_strength == 2`
**优先级**：P1

---

### TC-036
**目标**：INCREASE_HAND_LIMIT 手牌上限增加
**前置**：`max_hand_size=6`；`combo_bonus=0`
**操作**：`play_card(yellow_02)`（base=1）
**断言**：`max_hand_size == 7`
**优先级**：P2

---

## 4. 防御系统

### TC-037
**目标**：无敌时敌人攻击伤害为 0
**前置**：`is_invincible=true`；`current_player_health=20`；敌人总 ATK=6
**操作**：`enemy_attack()`
**断言**：`current_player_health == 20`
**优先级**：P1

---

### TC-038
**目标**：护盾优先抵消伤害，抵消后清空
**前置**：`current_player_shield=3`；`current_player_block=0`；`current_player_health=20`；敌人 ATK=5
**操作**：`enemy_attack()`
**断言**：`current_player_health == 18`（5-3=2 穿透）；`current_player_shield == 0`
**优先级**：P1

---

### TC-039
**目标**：护甲减伤后可叠加归零
**前置**：`current_player_shield=0`；`current_player_block=4`；`current_player_health=20`；敌人 ATK=3
**操作**：`enemy_attack()`
**断言**：`current_player_health == 20`（护甲完全吸收）；`current_player_block == 1`
**优先级**：P1

---

### TC-040
**目标**：抗性在护盾护甲后结算
**前置**：`turn_resistance=2`；`current_player_shield=0`；`current_player_block=0`；HP=20；ATK=5
**操作**：`enemy_attack()`
**断言**：`current_player_health == 17`（5-2=3）
**优先级**：P1

---

### TC-041
**目标**：受伤流程顺序：无敌→护盾→护甲→抗性→扣血
**前置**：`is_invincible=false`；`shield=2`；`block=3`；`resistance=1`；HP=20；ATK=8
**操作**：`enemy_attack()`
**断言**：8-shield(2)=6；6-block(3)=3；3-resistance(1)=2；HP=18
**优先级**：P1

---

### TC-042
**目标**：HP 最低为 0，不出现负数
**前置**：`current_player_health=1`；敌人 ATK=10；无任何防御
**操作**：`enemy_attack()`
**断言**：`current_player_health == 0`；`is_game_over == true`
**优先级**：P1

---

### TC-043
**目标**：护甲在回合开始时重置
**前置**：`current_player_block=5`
**操作**：`start_next_player_turn()`
**断言**：`current_player_block == 0`
**优先级**：P1

---

### TC-044
**目标**：无敌在回合开始时重置
**前置**：`is_invincible=true`
**操作**：`start_next_player_turn()`
**断言**：`is_invincible == false`
**优先级**：P1

---

## 5. 升级系统

### TC-045
**目标**：击杀 3 个小怪触发升级（C-001）
**前置**：`player_experience=0`；`player_level=1`；`player_strength=0`
**操作**：`gain_experience_for_enemy({"type":"small"})` × 3
**断言**：`player_level==2`；`player_strength==1`；`max_player_health==35`；`player_experience==0`（重置）
**优先级**：P1

---

### TC-046
**目标**：击杀大怪不给经验
**前置**：`player_experience=0`
**操作**：`gain_experience_for_enemy({"type":"large"})`
**断言**：`player_experience == 0`；`player_level == 1`
**优先级**：P1

---

### TC-047
**目标**：击杀 Boss 不给经验
**前置**：`player_experience=0`
**操作**：`gain_experience_for_enemy({"type":"boss"})`
**断言**：`player_experience == 0`；`player_level == 1`
**优先级**：P1

---

### TC-048
**目标**：升级奖励队列正确——每次升级排队 1 次三选一
**前置**：`queued_reward_count=0`
**操作**：连杀 3 个小怪（触发升级）
**断言**：`queued_reward_count` 在奖励窗口未打开前 ≥ 1；奖励窗口弹出 3 张卡供选择
**优先级**：P2

---

### TC-049
**目标**：选择奖励卡后，加入 player_deck
**前置**：奖励窗口已打开，有 3 张候选卡
**操作**：`_on_reward_card_selected(pending_reward_cards[0])`
**断言**：`player_deck.size()` 比选牌前多 1；选中的卡在 `player_deck` 中
**优先级**：P2

---

## 6. 关卡波次系统

### TC-050
**目标**：游戏加载 5 个关卡，每关 3 波次
**前置**：`enemy_waves.setup()`
**操作**：遍历 `enemy_waves.levels`
**断言**：`levels.size() == 5`；每个 level 的 `waves.size() == 3`
**优先级**：P1

---

### TC-051
**目标**：每关最后一波 is_boss = true
**前置**：`enemy_waves.setup()`
**操作**：检查每个 level 的 `waves[2].is_boss`
**断言**：5 个关卡的第 3 波 `is_boss == true`
**优先级**：P1

---

### TC-052
**目标**：清空当前波次后推进到下一波次
**前置**：关卡 1 波次 1，击杀所有敌人
**操作**：`resolve_enemy_deaths()`
**断言**：`enemy_waves.current_wave_index == 1`（推进到波次 2）
**优先级**：P1

---

### TC-053
**目标**：关卡内所有波次完成后推进到下一关卡
**前置**：关卡 1 波次 3（Boss），击杀所有敌人
**操作**：`resolve_enemy_deaths()`
**断言**：`current_level_index == 1`（推进到关卡 2）；`current_wave_index == 0`
**优先级**：P1

---

### TC-054
**目标**：Boss 死亡时触发 on_boss_defeated
**前置**：Boss 波次，仅 Boss 存活，HP=1
**操作**：打出足够伤害的攻击牌；`resolve_enemy_deaths()`
**断言**：`pending_relic_rewards >= 1`（on_boss_defeated 已调用）
**优先级**：P1

---

### TC-055
**目标**：DoT 致死后跳过敌人攻击（GC-006）
**前置**：敌人 HP=1，`dot_damage=2`，`dot_duration=1`；玩家 HP=15
**操作**：`_on_end_turn_pressed()`
**断言**：玩家 HP 不变（敌人 DoT 致死，跳过 enemy_attack）；波次推进
**优先级**：P1

---

### TC-056
**目标**：小怪死亡计入 kill count，大怪不计入
**前置**：`player_experience=0`
**操作**：`gain_experience_for_enemy({"type":"small"})`；`gain_experience_for_enemy({"type":"large"})`
**断言**：`player_experience == 1`（仅小怪 +1）
**优先级**：P1

---

### TC-057
**目标**：UI 波次标题格式正确
**前置**：`current_level_index=0`；`current_wave_index=0`；波次 name="树丛小兵"
**操作**：`enemy_waves.get_wave_title()`
**断言**：返回值包含 "关卡 1"、"第 1 波次"、"树丛小兵"
**优先级**：P2

---

### TC-058
**目标**：5 个关卡全部完成后 is_complete = true
**前置**：`current_level_index=4`；`current_wave_index=2`（最终 Boss）
**操作**：击杀所有敌人；`resolve_enemy_deaths()`
**断言**：`enemy_waves.is_complete == true`；`is_game_over == true`
**优先级**：P1

---

### TC-059
**目标**：手牌上限在波次切换时重置为 6
**前置**：`max_hand_size=8`（被黄2扩充过）；清空当前波次
**操作**：`resolve_enemy_deaths()`（波次推进）
**断言**：`max_hand_size == 6`
**优先级**：P2

---

## 7. 道具系统

### TC-060
**目标**：击败 Boss 后 pending_relic_rewards +1
**前置**：`pending_relic_rewards=0`；Boss 波次，Boss HP=1
**操作**：击杀 Boss；`resolve_enemy_deaths()`
**断言**：`pending_relic_rewards == 1`
**优先级**：P1

---

### TC-061
**目标**：拾取道具后存入 player_relics
**前置**：`player_relics=[]`；RelicWindow 已弹出，展示 R-001
**操作**：点击「拾取」按钮（`_on_relic_take_pressed()`）
**断言**：`player_relics.size() == 1`；`player_relics[0].relic_id == "R-001"`
**优先级**：P1

---

### TC-062
**目标**：跳过道具后 player_relics 不变
**前置**：`player_relics=[]`；RelicWindow 已弹出
**操作**：点击「跳过」按钮
**断言**：`player_relics.size() == 0`
**优先级**：P1

---

### TC-063
**目标**：R-001 奇数宝珠——费1+费3 触发连击
**前置**：`player_relics=[R-001]`；`attempt_play(card_cost_1)`
**操作**：`ComboManager.can_combo(card_cost_1, card_cost_3)`
**断言**：返回 `true`
**优先级**：P2

---

### TC-064
**目标**：R-001 无效时——费1+费3 不触发连击
**前置**：`player_relics=[]`；颜色不同费用1和3
**操作**：`ComboManager.can_combo(card_cost_1, card_cost_3)`
**断言**：返回 `false`
**优先级**：P2

---

### TC-065
**目标**：R-002 偶数宝珠——费2+费4 触发连击
**前置**：`player_relics=[R-002]`
**操作**：`ComboManager.can_combo(card_cost_2, card_cost_4)`
**断言**：返回 `true`
**优先级**：P2

---

### TC-066
**目标**：R-003 猫眼石——蓝+绿触发连击
**前置**：`player_relics=[R-003]`
**操作**：`ComboManager.can_combo(blue_card, green_card)`（不同费用）
**断言**：返回 `true`
**优先级**：P2

---

### TC-067
**目标**：R-004 犬视晶——黄+蓝触发连击
**前置**：`player_relics=[R-004]`
**操作**：`ComboManager.can_combo(yellow_card, blue_card)`（不同费用）
**断言**：返回 `true`
**优先级**：P2

---

### TC-068
**目标**：多件道具条件取并集
**前置**：`player_relics=[R-001, R-003]`
**操作**：`can_combo(blue_cost1, green_cost3)`（满足 R-001 奇费 且 R-003 蓝绿）
**断言**：返回 `true`
**优先级**：P2

---

## 8. 诅咒系统

### TC-069
**目标**：进入 Boss 波次时施加 CRS-001 诅咒
**前置**：`active_curses=[]`；推进到关卡 1 Boss 波次
**操作**：`apply_curse(0)`（level_index=0）
**断言**：`active_curses.has("CRS-001") == true`
**优先级**：P1

---

### TC-070
**目标**：Boss 死亡时立即移除诅咒（BUG-003 回归）
**前置**：`active_curses=["CRS-001"]`；Boss 死亡，护卫存活
**操作**：`on_boss_defeated()`
**断言**：`active_curses.has("CRS-001") == false`
**优先级**：P1

---

### TC-071
**目标**：变色诅咒激活时，出牌后手牌颜色随机化
**前置**：`active_curses=["CRS-001"]`；手牌 3 张，颜色已知
**操作**：`play_card(any_card)`；记录手牌颜色
**断言**：手牌颜色集合与打牌前相比有可能不同（随机性，至少验证代码路径被调用：`card.color` 被重新赋值）
**优先级**：P1

---

### TC-072
**目标**：变色诅咒不激活时，出牌后手牌颜色不变
**前置**：`active_curses=[]`；手牌 3 张，颜色记录
**操作**：`play_card(any_card)`
**断言**：剩余手牌颜色与打牌前一致
**优先级**：P1

---

### TC-073
**目标**：诅咒不重复施加
**前置**：`active_curses=["CRS-001"]`
**操作**：再次 `apply_curse(0)`
**断言**：`active_curses.count("CRS-001") == 1`（不重复添加）
**优先级**：P2

---

### TC-074
**目标**：CurseListLabel 在 Boss 波次显示诅咒名，Boss 死亡后清空（GC-022）
**前置**：进入关卡 1 Boss 波次
**操作**：检查 `CurseListLabel.text`；击杀 Boss 后再检查
**断言**：Boss 存活时 text 包含"变色诅咒"；Boss 死亡后 text 为空或节点隐藏
**优先级**：P2

---

## 9. 宝石槽系统

### TC-075
**目标**：GemCard 有 gem_slots 字段，默认 0
**前置**：加载任意一张 .tres 卡牌
**操作**：读取 `card.gem_slots`
**断言**：`card.gem_slots == 0`；字段存在不报错
**优先级**：P1

---

### TC-076
**目标**：gem_slots=0 时 card_ui 不渲染圆圈
**前置**：card.gem_slots=0；实例化 card_ui
**操作**：检查 card_ui 底部圆圈节点数量
**断言**：圆圈节点数 == 0
**优先级**：P2

---

### TC-077
**目标**：gem_slots=2 时 card_ui 渲染 2 个圆圈
**前置**：card.gem_slots=2；实例化 card_ui
**操作**：检查 card_ui 底部圆圈节点数量
**断言**：圆圈节点数 == 2
**优先级**：P2

---

## 10. 游戏流程

### TC-078
**目标**：start_fresh_game 完整重置所有状态
**前置**：游戏已进行若干回合（HP 受损，有道具，有诅咒，连击非0）
**操作**：`start_fresh_game()`
**断言**：`current_player_health==30`；`player_level==1`；`player_strength==0`；`player_relics==[]`；`active_curses==[]`；`current_combo==0`；`turn_count==1`
**优先级**：P1

---

### TC-079
**目标**：玩家死亡时 is_game_over = true，end_turn_button 禁用
**前置**：`current_player_health=1`；敌人 ATK=5；无防御
**操作**：`enemy_attack()`
**断言**：`is_game_over==true`；`end_turn_button.disabled==true`
**优先级**：P1

---

### TC-080
**目标**：死亡后重开，状态完整重置
**前置**：`is_game_over=true`
**操作**：`_on_restart_button_pressed()`
**断言**：`current_player_health==30`；`is_game_over==false`；`turn_count==1`；`player_deck.size()==4`
**优先级**：P1

---

### TC-081
**目标**：最终 Boss 死亡触发胜利流程
**前置**：`current_level_index=4`；`current_wave_index=2`；Boss HP=1
**操作**：击杀最终 Boss；`resolve_enemy_deaths()`
**断言**：`enemy_waves.is_complete==true`；`is_game_over==true`；VictoryWindow 可见
**优先级**：P1

---

### TC-082
**目标**：能量不足时无法出牌
**前置**：`current_player_energy=0`；手牌含费用 1 的卡
**操作**：`play_card(red_01)`
**断言**：敌人 HP 不变；`current_player_energy==0`
**优先级**：P1

---

### TC-083
**目标**：每回合开始能量重置为基础上限
**前置**：`current_player_energy=0`；`next_turn_energy_bonus=0`
**操作**：`start_next_player_turn()`
**断言**：`current_player_energy == BASE_PLAYER_ENERGY`（= 4）
**优先级**：P1

---

### TC-084
**目标**：下回合加费（blue_02）在新回合能量上限中体现
**前置**：`next_turn_energy_bonus=2`（已由 blue_02 设置）
**操作**：`start_next_player_turn()`
**断言**：`current_player_energy_max == 6`；`current_player_energy == 6`；`next_turn_energy_bonus == 0`（消费后重置）
**优先级**：P1

---

## 附录：用例统计

| 系统 | 用例数 | P1 | P2 |
|------|--------|----|----|
| 牌堆系统 | 8 | 7 | 1 |
| 连击系统 | 10 | 6 | 4 |
| 卡牌效果 | 18 | 14 | 4 |（含 TC-036）
| 防御系统 | 8 | 8 | 0 |
| 升级系统 | 5 | 3 | 2 |
| 关卡波次 | 10 | 7 | 3 |
| 道具系统 | 9 | 3 | 6 |（含 TC-068）
| 诅咒系统 | 6 | 4 | 2 |
| 宝石槽 | 3 | 1 | 2 |
| 游戏流程 | 7 | 7 | 0 |
| **合计** | **84** | **60** | **24** |

## 附录：测试执行建议

**推荐框架**：[GUT (Godot Unit Test)](https://github.com/bitwes/Gut) — 可直接在 Godot 编辑器内运行

**目录结构建议**：
```
res://tests/
  test_deck_manager.gd      # TC-001 ~ TC-008
  test_combo_manager.gd     # TC-009 ~ TC-018
  test_card_effects.gd      # TC-019 ~ TC-036
  test_defense.gd           # TC-037 ~ TC-044
  test_leveling.gd          # TC-045 ~ TC-049
  test_wave_system.gd       # TC-050 ~ TC-059
  test_relics.gd            # TC-060 ~ TC-068
  test_curses.gd            # TC-069 ~ TC-074
  test_gem_slots.gd         # TC-075 ~ TC-077
  test_game_flow.gd         # TC-078 ~ TC-084
```

**CI 建议**：P1 用例作为 PR 门禁，全部通过后方可合并；P2 用例作为每日回归。
