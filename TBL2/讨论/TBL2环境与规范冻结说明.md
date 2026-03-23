# TBL2 环境与规范冻结说明

## 1. 目的

这份文档用于完成 `TODO/01_环境与规范冻结.md`，并作为后续所有 agent 的统一约束输入。

从这一刻开始，后续 UART、timer、SoC 集成、firmware、testbench 的实现，默认都应遵循本文档；除非你明确决定改规范，否则不要随意变更地址、接口语义或文件边界。

## 2. 冻结后的总体决策

本项目先冻结为“基础可演示版”，不以加分项为主线。

### 2.1 当前确定要做的范围

- 实现 `uart.sv`
- 实现 `timer.sv`
- 修改 `picorv32_soc_ref.sv` 完成 MMIO 集成
- 编写 `firmware/clock.c`
- 生成 `clock.mem`
- 编写基础 `tb_basic.sv`
- 完成 FPGA 演示与提交材料收尾

### 2.2 当前明确不作为主线的内容

- UART 命令设时
- pause/resume
- countdown
- alarm message
- ANSI 彩色终端
- 光标控制美化
- 使用 push button 设时
- 完整 UART RX 功能

这些功能以后可以加，但在基础版打通之前，一律不优先。

## 3. 冻结后的平台假设

根据当前仓库代码和文档，后续开发默认采用下面的平台假设。

### 3.1 硬件平台

- 板卡：PYNQ-Z2
- 外部串口：CH340
- 连接方式：PL 引脚对外接 UART
- 关键引脚：
  - `uart_txd -> W19`
  - `uart_rxd -> W18`
- 接线方式：
  - PYNQ `W19 -> CH340 RXD`
  - PYNQ `W18 -> CH340 TXD`
  - GND 共地

### 3.2 时钟与复位

- 顶层使用 `pynq_z2_tx_demo_top.sv`
- 输入时钟来自板上 `125 MHz`
- 顶层 PLL 之后，SoC 工作时钟为 `62.5 MHz`
- `picorv32_soc_ref.sv` 中 `TIMER_TICK_CYCLES` 默认由顶层参数传入

因此：

- timer 不允许把“1 秒”写死为 `125_000_000`
- timer 必须按参数实现

### 3.3 当前本地环境观察

当前命令行环境中可见：

- `clang`
- `iverilog`

当前命令行环境中未在 PATH 看到：

- `vivado`

据此冻结分工：

- agent 可负责：代码编写、文件修改、固件、testbench、轻量仿真
- 你必须亲自完成：Vivado GUI、综合、实现、生成 bitstream、烧板、物理接线、串口终端观察

## 4. 冻结后的 MMIO 规范

后续所有代码默认直接采用 handout 提供的参考 MMIO 接口，不再自定义新地址。

| 模块 | 地址 | 语义 |
|------|------|------|
| `UART_BASE` | `0x4000_0000` | UART 基地址 |
| `UART_TXDATA` | `0x4000_0000 + 0x00` | 写低 8 位字符后启动发送 |
| `UART_STATUS` | `0x4000_0000 + 0x04` | 读 bit0，返回 `tx_ready` |
| `TIMER_BASE` | `0x4000_0010` | timer 基地址 |
| `TIMER_STATUS` | `0x4000_0010 + 0x00` | 读 bit0，返回 `tick_pending`；写 bit0=1 清除 |
| `TIMER_VALUE` | `0x4000_0010 + 0x04` | 当前计数值或调试值 |

## 5. 冻结后的行为语义

### 5.1 UART

- 只把 TX 路径作为主线
- UART 采用 `115200 baud, 8 data bits, no parity, 1 stop bit`
- 固件在写 `UART_TXDATA` 之前，必须轮询 `UART_STATUS[0]`
- `tx_ready = 1` 表示当前可以接受一个新字符
- `tx_ready = 0` 表示发送器忙碌
- `rx` 端口可以保留，但不要求先实现完整接收逻辑

### 5.2 Timer

- timer 的职责是每秒给 firmware 一次可见 tick
- `tick_pending = 1` 表示“已经到了一秒，等待 firmware 处理”
- firmware 通过向 `TIMER_STATUS` 写 1 清除 tick
- timer 周期必须参数化
- 仿真时允许把周期缩短
- FPGA 演示时必须使用与顶层时钟一致的真实 1 秒行为

### 5.3 Firmware

基础行为冻结为：

- 上电后从 `00:00:00` 开始
- 先输出一次初始时间
- 之后每秒更新并输出一次
- 必须正确处理以下 rollover：
  - `00:00:59 -> 00:01:00`
  - `00:59:59 -> 01:00:00`
  - `23:59:59 -> 00:00:00`

输出形式先冻结为最低风险方案：

- 允许“每秒打印一行”
- 不强制要求原地刷新
- 不强制要求 VT100/ANSI

## 6. 文件边界冻结

## 6.1 必须新增的文件

后续基础版开发，至少应新增这些文件：

- `ee3220_tbl2_skeleton_rev1.0/rtl/uart.sv`
- `ee3220_tbl2_skeleton_rev1.0/rtl/timer.sv`
- `ee3220_tbl2_skeleton_rev1.0/firmware/clock.c`
- `tb_basic.sv` 或等价位置的基础 testbench
- `README.md`
- `ai_log.txt`
- 报告源文件或中间稿，最终导出为 `report.pdf`

## 6.2 允许修改的文件

为了打通基础版，允许修改这些文件：

- `ee3220_tbl2_skeleton_rev1.0/rtl/picorv32_soc_ref.sv`
- 如确有必要，可最小范围修改：
  - `ee3220_tbl2_skeleton_rev1.0/rtl/pynq_z2_tx_demo_top.sv`
  - `ee3220_tbl2_skeleton_rev1.0/firmware/Makefile`

但默认原则是：

- 优先不改 `pynq_z2_tx_demo_top.sv`
- 优先不改 `Makefile`
- 先在现有 skeleton 上接入模块，再谈调整构建流程

## 6.3 默认不应修改的文件

这些文件当前已满足基础平台用途，默认不应修改：

- `ee3220_tbl2_skeleton_rev1.0/rtl/imem.sv`
- `ee3220_tbl2_skeleton_rev1.0/rtl/dmem.sv`
- `ee3220_tbl2_skeleton_rev1.0/firmware/start.S`
- `ee3220_tbl2_skeleton_rev1.0/firmware/linker.ld`
- `ee3220_tbl2_skeleton_rev1.0/tools/bin2mem.py`
- `ee3220_tbl2_skeleton_rev1.0/constraints/pynq_z2_tx_demo.xdc`

## 6.4 明确禁止修改的文件

基础版阶段，明确禁止修改：

- `ee3220_tbl2_skeleton_rev1.0/rtl/picorv32.v`

原因：

- 讲义要求不要修改处理器本体
- 当前任务重点是 MMIO 外设、固件和系统集成，不是 CPU 设计

## 7. 目录与产物放置约定

为了减少混乱，后续统一采用下面的放置约定。

### 7.1 RTL

- 新外设放在 `ee3220_tbl2_skeleton_rev1.0/rtl/`

### 7.2 Firmware

- `clock.c` 放在 `ee3220_tbl2_skeleton_rev1.0/firmware/`
- `clock.mem` 由 Makefile 生成到 `ee3220_tbl2_skeleton_rev1.0/`

### 7.3 验证

- 若无课程指定固定目录，`tb_basic.sv` 可先放项目根目录或后续单独建 `sim/`
- 但在真正动手前，建议后续 agent 先确认 testbench 放置位置，再保持一致

### 7.4 文档

- 分析、冻结说明、阶段报告放在 `讨论/`
- 任务分解放在 `TODO/`

## 8. 后续开发顺序冻结

后续按下面顺序推进，不建议跳步：

1. `uart.sv`
2. `timer.sv`
3. `picorv32_soc_ref.sv` 集成
4. `clock.c`
5. `clock.mem`
6. `tb_basic.sv`
7. Vivado 工程与上板
8. README / report / ai_log / 打包

## 9. 依赖关系

### 9.1 UART 外设

依赖：

- 已冻结 MMIO 地址
- 已冻结串口模式

产出：

- `uart.sv`

### 9.2 Timer 外设

依赖：

- 已冻结 `TIMER_BASE`
- 已冻结 tick 清除语义
- 已确认 SoC 时钟来自顶层参数

产出：

- `timer.sv`

### 9.3 SoC 集成

依赖：

- `uart.sv`
- `timer.sv`

产出：

- 可访问 MMIO 外设的 `picorv32_soc_ref.sv`

### 9.4 Firmware

依赖：

- UART 和 timer 寄存器语义已冻结
- SoC 地址不再变化

产出：

- `clock.c`
- `clock.mem`

### 9.5 Testbench

依赖：

- UART、timer、SoC、firmware 已基本稳定

产出：

- `tb_basic.sv`
- 基础仿真结果

### 9.6 上板

依赖：

- `clock.mem`
- 完整 RTL
- 基础仿真至少通过主要用例

产出：

- 串口终端可见 mission clock

## 10. 当前阶段的完成结论

`TODO 01` 现在可以视为完成，冻结结果如下：

- 项目只做基础版作为主线
- MMIO 直接采用 handout 参考地址
- UART 以 TX 为主线，RX 不作为当前关键路径
- timer 必须参数化，不允许写死时钟周期
- 不修改 `picorv32.v`
- 上板采用 CH340 外接方案

## 11. 交给 TODO 02 的输入

后续做 `TODO 02：UART 外设` 时，应直接引用本文档，默认使用以下冻结条件：

- `UART_BASE = 0x4000_0000`
- `UART_TXDATA @ +0x00`
- `UART_STATUS @ +0x04`
- `UART_STATUS[0] = tx_ready`
- 只保证 TX 主线
- 波特率必须参数化
