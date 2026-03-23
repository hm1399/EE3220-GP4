# TODO 03：实现 Timer 外设

已完成。结果文件：

- `/Users/mandy/Desktop/EE3220/TBL2/ee3220_tbl2_skeleton_rev1.0/rtl/timer.sv`

## 目标

补出 `timer.sv`，让固件能够每秒收到一次 tick 事件，并能通过写 1 清除该事件。

## 本 TODO 完成后，你应该得到

- 新文件 `ee3220_tbl2_skeleton_rev1.0/rtl/timer.sv`
- 已定义好的 `tick_pending` 语义
- 一个参数化的计时器，而不是写死某个频率的临时逻辑

## agent 可以做什么

- 设计并实现 `timer.sv`
- 实现 `TIMER_STATUS` 和 `TIMER_VALUE`
- 做出 `write-1-to-clear` 的 tick 清除逻辑
- 让计时周期由参数控制
- 保证未来仿真时可把周期调短

## agent 如何实现

你可以把下面要求直接交给 agent：

- 文件路径：`ee3220_tbl2_skeleton_rev1.0/rtl/timer.sv`
- 参考地址：
  - `0x4000_0010 + 0x00` 为 `TIMER_STATUS`
  - `0x4000_0010 + 0x04` 为 `TIMER_VALUE`
- `TIMER_STATUS[0]`：
  - 读时返回 `tick_pending`
  - 写 1 时清除 `tick_pending`
- 内部逻辑：
  - 一个参数化计数器
  - 计数到周期值后置位 `tick_pending`
  - 然后重新开始下一个周期
- `TIMER_VALUE`：
  - 可以返回当前计数值或调试值
- 设计应与 `pynq_z2_tx_demo_top.sv` 传入的 `TIMER_TICK_CYCLES` 兼容

要求 agent 在完成后明确说明：

- 周期参数如何工作
- 计数器在什么时候归零
- `tick_pending` 何时置位、何时清除

## 你必须做什么

- 你要确认 agent 没有把周期写死成 `125_000_000`
- 你要确认 `TIMER_STATUS` 真的是 write-1-to-clear，而不是读清除
- 你要确认 timer 行为与后续 `clock.c` 能直接对上

## 你一步一步怎么操作

1. 把本 TODO 交给一个 agent。
2. agent 完成后，重点检查 `timer.sv` 是否参数化。
3. 看它的寄存器地址是否严格对应 `0x4000_0010` 和 `0x4000_0014`。
4. 检查清除逻辑是不是“写 1 清除”。
5. 如果正确，就进入 `04_SoC集成.md`。

## 你要特别盯住的风险

- 写死 125 MHz
- tick 置位后不会清掉
- tick 需要读清除，和 handout 不一致
- timer 不支持仿真缩短周期

## 完成标准

- `timer.sv` 已存在
- `tick_pending` 语义清晰
- 周期为参数化实现
- 可被后续固件直接轮询使用

## 交给下一个 TODO 的输入

- 可用的 `timer.sv`
- 已确定的 timer 寄存器定义
