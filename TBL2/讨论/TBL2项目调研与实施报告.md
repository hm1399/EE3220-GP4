# EE3220 TBL2 项目调研与实施报告

## 1. 项目到底要做什么

这个项目的目标，是在老师提供的 RISC-V SoC skeleton 基础上，做出一个可以在 UART 终端显示时间的 `Mission Clock`。最基本的成功标准只有三件事：

- 上电后能正常启动
- 时间每秒递增一次
- 串口终端上能稳定显示 `HH:MM:SS`

按照讲义，本项目不是让你从零设计 CPU，而是让你在现有 PicoRV32 处理器系统外围，补齐外设、固件和验证。

你们团队最终至少要完成：

- `uart.sv`
- `timer.sv`
- `clock.c`
- `tb_basic.sv`
- SoC 集成与上板验证

同时，项目要求你们不要修改处理器本体，重点是做 MMIO 外设、固件和系统集成。

## 2. 我读完这个仓库后，确认目前已经给了什么

这个仓库已经给了你们一套“半成品平台”，关键内容如下。

### 2.1 文档类

- `MD/tbl2_handout/tbl2_handout.md`
  - 最完整的 handout，写清楚任务、接口、验收标准、交付物。
- `MD/TBL2/TBL2.md`
  - 课堂流程和精简版目标说明。
- `pynq/MD/EE3220_TBL2_Connections/EE3220_TBL2_Connections.md`
  - CH340 和 PYNQ-Z2 的接线方法。
- `pynq/MD/pynqz2_user_manual_v1_0-1525725/pynqz2_user_manual_v1_0-1525725.md`
  - PYNQ-Z2 参考手册，确认了 125 MHz 板载时钟、W19/W18 引脚等信息。

### 2.2 已提供的硬件骨架

- `ee3220_tbl2_skeleton_rev1.0/rtl/picorv32.v`
  - 完整 PicoRV32 CPU，本项目不应修改。
- `ee3220_tbl2_skeleton_rev1.0/rtl/imem.sv`
  - 指令存储器，使用 `$readmemh` 从 `clock.mem` 读程序。
- `ee3220_tbl2_skeleton_rev1.0/rtl/dmem.sv`
  - 数据存储器，基地址为 `0x0001_0000`，大小 8 KB。
- `ee3220_tbl2_skeleton_rev1.0/rtl/picorv32_soc_ref.sv`
  - SoC 骨架。现在只接了 CPU、IMEM、DMEM；UART 和 timer 的例化代码被注释掉了，说明这里正是你们要补的地方。
- `ee3220_tbl2_skeleton_rev1.0/rtl/pynq_z2_tx_demo_top.sv`
  - 顶层封装，输入 125 MHz 板时钟，PLL 后给 SoC 一个 62.5 MHz 时钟，并把 UART 端口引出来。
- `ee3220_tbl2_skeleton_rev1.0/constraints/pynq_z2_tx_demo.xdc`
  - 约束文件，确认 `clk_125mhz` 在 `H16`，`uart_txd` 在 `W19`，`uart_rxd` 在 `W18`。

### 2.3 已提供的软件构建骨架

- `ee3220_tbl2_skeleton_rev1.0/firmware/start.S`
  - 启动代码，只做了栈初始化，然后调用 `main`。
- `ee3220_tbl2_skeleton_rev1.0/firmware/linker.ld`
  - 链接脚本，`.text` 放 IMEM，`.data/.bss` 放 DMEM。
- `ee3220_tbl2_skeleton_rev1.0/firmware/Makefile`
  - 固件构建流程：`clock.c + start.S + linker.ld -> clock.elf -> clock.bin -> clock.mem`。
- `ee3220_tbl2_skeleton_rev1.0/tools/bin2mem.py`
  - 把二进制转成 `readmemh` 可用的 `.mem` 文件。

## 3. 目前仓库里还缺什么

当前仓库里没有下面这些关键文件：

- `uart.sv`
- `timer.sv`
- `clock.c`
- `tb_basic.sv`
- `README.md`
- `report.pdf`
- `ai_log.txt`

也就是说，这个仓库现在只是“平台 + 说明书”，并不是一个已经可跑通的完整工程。你真正要做的，就是把这些缺口补齐，并且把它们和现有 skeleton 接起来。

## 4. 你实际需要实现的东西

## 4.1 UART 外设

UART 是本项目最关键的输出通道。基础要求只需要发数据，不强制接收数据一定可用。

你至少要实现：

- 一个 MMIO 写寄存器，用于写入待发送字符
- 一个 MMIO 状态寄存器，用于告诉 CPU 当前是否可继续发送
- 115200 baud、8 data bits、no parity、1 stop bit
- 输出端连接到 `uart_txd`

最稳妥的做法是先只做 TX 路径，把 RX 留空或只保留输入端口不使用。因为 base requirement 只要求“能显示时间”，不要求串口命令控制。

## 4.2 Timer 外设

Timer 的作用是“每秒给固件一个 tick 事件”。

推荐做法：

- 内部计数器按 SoC 时钟计数
- 到达设定周期后把 `tick_pending` 置 1
- 固件读到后通过写 1 清除这个标志

这里一定不要把 1 秒周期写死成 125,000,000。因为当前顶层 `pynq_z2_tx_demo_top.sv` 实际给 SoC 的时钟是 62.5 MHz，并且把 `TIMER_TICK_CYCLES` 参数传成了 `SOC_CLK_HZ`。所以 timer 最好严格按参数实现，这样仿真和上板都能复用。

## 4.3 SoC 集成

`picorv32_soc_ref.sv` 是你们集成的主战场。你要做的事情包括：

- 例化 `uart`
- 例化 `timer`
- 给它们分配 MMIO 地址范围
- 在总线返回路径中加入 `uart_ready / uart_rdata`
- 在总线返回路径中加入 `timer_ready / timer_rdata`
- 保证地址命中时只有对应外设响应

也就是说，当前的 interconnect 只认识 IMEM 和 DMEM，你需要把 UART 和 timer 正式挂上去。

## 4.4 裸机固件 `clock.c`

固件需要完成的逻辑其实很明确：

- 上电后从 `00:00:00` 开始
- 先输出初始时间
- 轮询 timer 的 tick 标志
- 每来一次 tick，就更新时间
- 正确处理秒、分、时进位
- 通过 UART 把新的时间字符串打印出来

讲义明确要求检查以下 rollover：

- `00:00:59 -> 00:01:00`
- `00:59:59 -> 01:00:00`
- `23:59:59 -> 00:00:00`

如果时间紧，显示方式用“每秒打印一行”就够了；如果想更好看，可以用回车符或 VT100/ANSI 控制做原地刷新，但这只是加分项。

## 4.5 测试平台 `tb_basic.sv`

讲义要求至少验证：

- reset 后输出是否从 `00:00:00` 开始
- 下一秒是否变成 `00:00:01`
- 分钟进位
- 小时进位
- 24 小时回卷

仿真时可以把 UART 分频和 timer 周期调小，不需要真的等现实世界 1 秒。老师也明确允许你们在 simulation 中缩短定时参数，但 FPGA 演示时必须恢复官方配置。

## 5. 讲义指定的参考 MMIO 接口

虽然 handout 前面说地址可以由团队自定，但后面又给出了“本次 TBL 的 reference MMIO interface”。为了少踩坑，建议直接照这个做，不要自创地址。

推荐直接使用：

| 模块 | 地址 | 含义 |
|------|------|------|
| `UART_BASE` | `0x4000_0000` | UART 基地址 |
| `UART_TXDATA` | `0x4000_0000 + 0x00` | 写入一个字节开始发送 |
| `UART_STATUS` | `0x4000_0000 + 0x04` | bit0 = `tx_ready` |
| `TIMER_BASE` | `0x4000_0010` | Timer 基地址 |
| `TIMER_STATUS` | `0x4000_0010 + 0x00` | bit0 = `tick_pending` |
| `TIMER_VALUE` | `0x4000_0010 + 0x04` | 当前计数值或调试寄存器 |

对应行为也最好完全照 handout：

- 只有当 `tx_ready = 1` 时，固件才写下一个字符
- `tick_pending = 1` 表示到了一秒
- 固件向 `TIMER_STATUS` 写 1 清除 tick

## 6. 这个项目最合理的实现顺序

如果你现在要真正动手，我建议按下面顺序做。

### 第一步：先做 `uart.sv`

原因很简单：只要 UART 能发，你就能最快看到“系统有没有活着”。即使 timer 还没完全对，也能先用固件打印固定字符串做 bring-up。

### 第二步：做 `timer.sv`

先把“每秒产生一次事件”做对，再去考虑显示格式。Timer 的逻辑本身不复杂，关键是参数化和清零语义要一致。

### 第三步：修改 `picorv32_soc_ref.sv`

把 UART 和 timer 接进总线，并完成地址解码。这一步一旦接错，固件再正确也跑不出来。

### 第四步：写 `clock.c`

固件先用最简单方案：

- 轮询 UART ready
- 轮询 timer tick
- 每次 tick 更新时间并打印

不要一开始就做串口收命令、彩色终端、按键设时，这些都不是主线。

### 第五步：生成 `clock.mem`

进入 `firmware` 目录跑 `make`，让程序被编译并转成 IMEM 初始化文件。没有 `clock.mem`，`imem.sv` 就没有程序可执行。

### 第六步：写 `tb_basic.sv`

重点不是把 testbench 做得很华丽，而是要能证明：

- reset 正确
- 时间递增正确
- rollover 正确

### 第七步：上板

综合、实现、生成 bitstream 后，把 UART 接到 CH340，再开串口终端看输出。

## 7. 上板时你要特别注意什么

根据仓库里的接线说明，你们当前这套工程更像是“走 PL 引脚 + 外部 CH340”的方案，而不是直接用板载 PS 的 USB-UART。

当前建议接法：

- PYNQ `W19` 作为 `uart_txd`，接 CH340 `RXD`
- PYNQ `W18` 作为 `uart_rxd`，接 CH340 `TXD`
- 一定共地，GND 要接对
- 不要把 CH340 的 `3V3` 或 `5V` 电源脚接到这些 UART 信号脚
- CH340 必须工作在 3.3V TTL

串口终端参数：

- 115200 baud
- 8 data bits
- no parity
- 1 stop bit

## 8. 这个项目里最容易踩的坑

- 把 CPU 当成可修改部分。实际上 handout 已明确不该改处理器。
- Timer 周期写死成 125 MHz，导致当前 demo top 下 1 秒不准。
- MMIO 地址、寄存器语义和固件不一致。
- UART 没有 `tx_ready`，导致连续写字符时丢数据。
- `TIMER_STATUS` 清除语义没按“write-1-to-clear”做。
- 固件没处理三种关键 rollover。
- 仿真和上板参数混在一起，导致仿真太慢或硬件波特率错误。

## 9. 你最后需要交什么

根据 handout，最终提交包 `team_<XX>_submission.zip` 至少应包含：

- `uart.sv`
- `timer.sv`
- `tb_basic.sv`
- `firmware/clock.c`
- `linker.ld`
- `Makefile`
- `clock.mem`
- `README.md`
- `report.pdf`
- `ai_log.txt`

其中：

- `README.md` 要写 build 步骤、仿真命令、MMIO memory map、分工
- `report.pdf` 要简述系统结构、UART/timer 接口、固件策略

## 10. 一句话总结

这个项目本质上是一个“在现成 PicoRV32 SoC 上补 UART、补 timer、写裸机时钟程序，再把它跑上 FPGA”的系统集成题。

如果你问“我现在最该做什么”，答案就是：

1. 先实现 `uart.sv`
2. 再实现 `timer.sv`
3. 把两者接进 `picorv32_soc_ref.sv`
4. 写 `clock.c`
5. 生成 `clock.mem`
6. 写 `tb_basic.sv`
7. 上板连 CH340 做最终演示

按这个顺序推进，最符合当前仓库结构，也最容易在课堂时限内完成。
