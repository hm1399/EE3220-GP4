# TODO 04：把 UART 和 Timer 接进 SoC

已完成。结果文件：

- `/Users/mandy/Desktop/EE3220/TBL2/ee3220_tbl2_skeleton_rev1.0/rtl/picorv32_soc_ref.sv`

## 目标

修改 `picorv32_soc_ref.sv`，让 CPU 可以真正访问到 UART 和 timer，而不是只连着 IMEM 和 DMEM。

## 本 TODO 完成后，你应该得到

- 修改后的 `ee3220_tbl2_skeleton_rev1.0/rtl/picorv32_soc_ref.sv`
- UART、timer 已例化
- 总线 ready/rdata 路径已包含新外设
- 顶层仍保持与现有 `pynq_z2_tx_demo_top.sv` 兼容

## agent 可以做什么

- 在 `picorv32_soc_ref.sv` 中例化 UART 和 timer
- 补齐 `uart_rdata / uart_ready / timer_rdata / timer_ready`
- 修改 interconnect，把外设响应接入 `mem_ready` 和 `mem_rdata`
- 确保地址命中不会冲突
- 保持当前 top-level 接口不变

## agent 如何实现

你可以要求 agent：

- 只修改与集成相关的 SoC 文件，不碰 CPU 本体
- 把当前注释掉的 UART/timer 参考框架变成正式代码
- 采用 handout 的 MMIO 地址，不自己发明新地址
- 保持 IMEM、DMEM 行为不变
- 如果需要新增 `logic` 信号，只在 `picorv32_soc_ref.sv` 内处理
- 保证 `invalid_ready` 的处理仍合理，避免未知地址访问卡死

agent 完成后，应当明确告诉你：

- 它新增了哪些内部信号
- `mem_ready` 优先级如何安排
- `mem_rdata` 多路选择如何安排
- 它是否改动了除 `picorv32_soc_ref.sv` 外的其他文件

## 你必须做什么

- 你要检查 agent 是否误改了 `picorv32.v`
- 你要检查 `picorv32_soc_ref.sv` 是否仍然和 `pynq_z2_tx_demo_top.sv` 对接得上
- 你要判断地址命中和 ready 逻辑有没有明显互相打架

## 你一步一步怎么操作

1. 确保 `uart.sv` 和 `timer.sv` 已经存在。
2. 把本 TODO 交给一个 agent。
3. agent 完成后，先看修改文件列表。
4. 如果它改了 `picorv32.v`，先不要接受。
5. 打开 `picorv32_soc_ref.sv`，检查：
   - UART 是否例化
   - timer 是否例化
   - `mem_ready` 是否包含 UART/timer
   - `mem_rdata` 是否包含 UART/timer
6. 如果没问题，再进入 `05_固件与clock_mem.md`。

## 你要特别盯住的风险

- 改到了 CPU
- 总线 ready 多源冲突
- 地址命中重叠
- 忘了把 `uart_txd` 连接到外设输出
- `invalid_ready` 逻辑被破坏，导致 CPU 卡住

## 完成标准

- SoC 里已经正式挂上 UART 和 timer
- top-level 端口没有被破坏
- CPU 访问外设的路径已经打通

## 交给下一个 TODO 的输入

- 已集成的 SoC
- 可以被固件访问的 MMIO 外设
