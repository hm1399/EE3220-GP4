# TODO 02：实现 UART 外设

已完成。结果文件：

- `/Users/mandy/Desktop/EE3220/TBL2/ee3220_tbl2_skeleton_rev1.0/rtl/uart.sv`

## 目标

补出一个最小可用的 `uart.sv`，满足 mission clock 的基础需求：CPU 能通过 MMIO 发字符，串口终端能看到稳定输出。

## 本 TODO 完成后，你应该得到

- 新文件 `ee3220_tbl2_skeleton_rev1.0/rtl/uart.sv`
- 已定义好的 MMIO UART 接口
- 一个只保证 TX 正确工作的基础 UART

## agent 可以做什么

- 设计并实现 `uart.sv`
- 按 handout 参考地址实现 `UART_TXDATA` 和 `UART_STATUS`
- 实现 `tx_ready`
- 完成 115200、8N1 的发送时序
- 预留 `rx` 端口但不把 RX 功能作为主线
- 写少量必要注释，方便后续集成

## agent 如何实现

你可以把下面这组约束交给 agent：

- 文件路径：`ee3220_tbl2_skeleton_rev1.0/rtl/uart.sv`
- 总线接口风格应与现有 skeleton 一致，接受 `bus_valid / bus_we / bus_addr / bus_wdata`
- 对地址 `0x4000_0000 + 0x00`：
  - 写入低 8 位字符后启动发送
- 对地址 `0x4000_0000 + 0x04`：
  - 读 bit0 返回 `tx_ready`
- 发送器只做基础版：
  - idle = 1
  - start bit = 0
  - 8 data bits，LSB first
  - 1 stop bit = 1
- 分频器必须参数化，不能把当前板时钟写死到逻辑里
- 总线返回尽量简单、同步当前 skeleton 风格

要求 agent 在完成后说明：

- 状态机设计
- 波特率分频如何计算
- `tx_ready` 何时为 1，何时为 0
- 它修改了哪些文件

## 你必须做什么

- 你要检查 agent 是否真的按 `0x4000_0000` 和 `0x4000_0004` 做了
- 你要检查它有没有偷偷把 RX 当成主线加复杂功能
- 你要判断它是否引入了和后续 SoC 集成冲突的接口命名

这些检查最好你来做，因为一旦 UART 接口名字不统一，后面会连锁返工。

## 你一步一步怎么操作

1. 把本 TODO 交给一个 agent。
2. agent 完成后，先看它是否只新增了 `uart.sv`，以及是否只做了少量必要配套修改。
3. 打开 `uart.sv` 检查三件事：
   - MMIO 地址是否正确
   - `tx_ready` 是否存在
   - 波特率是否参数化
4. 不要立刻要求它做 SoC 集成；UART 本 TODO 的目标只是把模块本身写好。
5. 如果没问题，把这个文件保留下来，进入 `03_Timer外设.md`。

## 你要特别盯住的风险

- 地址做错
- 总线 ready 语义做错
- 发送器忙碌时还能继续写，导致丢字符
- 波特率分频写死到某个单一时钟
- 把 RX 做复杂了，反而拖慢主线

## 完成标准

满足下面条件就可以过关：

- `uart.sv` 已存在
- MMIO 行为与 handout 一致
- `tx_ready` 可被固件轮询
- 参数支持后续在仿真和 FPGA 下复用

## 交给下一个 TODO 的输入

- 可用的 `uart.sv`
- 已确定的 UART 模块端口名和总线接口
