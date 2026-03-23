# TODO 05：写固件并生成 `clock.mem`

已完成到当前环境可达上限。结果文件：

- `/Users/mandy/Desktop/EE3220/TBL2/ee3220_tbl2_skeleton_rev1.0/firmware/clock.c`
- `clock.mem` 目标输出路径：`/Users/mandy/Desktop/EE3220/TBL2/ee3220_tbl2_skeleton_rev1.0/clock.mem`

## 目标

写出 `clock.c`，让 RISC-V 固件能从 `00:00:00` 开始，每秒更新时间并通过 UART 打印出来；随后生成 `clock.mem` 供 IMEM 使用。

## 本 TODO 完成后，你应该得到

- 新文件 `ee3220_tbl2_skeleton_rev1.0/firmware/clock.c`
- 可编译的 bare-metal 固件源码
- 在具备可用 RISC-V 工具链的环境中可生成 `clock.mem`

## 已完成的实现

- 已新增 `ee3220_tbl2_skeleton_rev1.0/firmware/clock.c`
- 直接使用 handout 冻结下来的 MMIO 宏定义：
  - `UART_BASE = 0x4000_0000`
  - `UART_TXDATA @ +0x00`
  - `UART_STATUS @ +0x04`
  - `TIMER_BASE = 0x4000_0010`
  - `TIMER_STATUS @ +0x00`
  - `TIMER_VALUE @ +0x04`
- 已实现：
  - `uart_putc`
  - `uart_puts`
  - 两位十进制输出
  - `timer_tick_pending`
  - `timer_clear_tick`
  - `mission_time_tick`
  - `print_time`
- 启动后先输出一次 `00:00:00`
- 后续轮询 timer：
  - 检查 `tick_pending`
  - 写 `1` 清除 tick
  - 更新时间
  - 通过 UART 输出新时间
- 当前采用最低风险输出格式：每秒一行 `HH:MM:SS\r\n`
- 已实现三种 rollover：
  - `00:00:59 -> 00:01:00`
  - `00:59:59 -> 01:00:00`
  - `23:59:59 -> 00:00:00`

## 关键检查结果

- `clock.c` 已存在
- MMIO 地址与 `uart.sv`、`timer.sv`、`picorv32_soc_ref.sv` 一致
- 固件未使用 `printf` 或其他标准库输出函数
- `tick_pending` 采用 handout 要求的 write-1-to-clear
- `clock.mem` 的 Makefile 输出位置已确认是：
  - `/Users/mandy/Desktop/EE3220/TBL2/ee3220_tbl2_skeleton_rev1.0/clock.mem`

## 本地构建验证

已在 `ee3220_tbl2_skeleton_rev1.0/firmware` 下尝试运行 `make`，结果如下：

- `build/` 目录已创建
- `clock.mem` 未生成
- 第一处失败为：
  - `clang: error: invalid linker name in argument '-fuse-ld=lld'`

进一步探针结果：

- `clang --target=riscv32-unknown-elf ... -c clock.c`
  - 失败：`No available targets are compatible with triple "riscv32-unknown-unknown-elf"`
- `clang --target=riscv32-unknown-elf ... -c start.S`
  - 失败：Apple clang 不识别 RISC-V 相关选项
- 当前 PATH 中没有可用的：
  - `riscv32-unknown-elf-gcc`
  - `riscv64-unknown-elf-gcc`
  - `lld`
  - `llvm-objcopy`
  - `llvm-objdump`

结论：

- 本机缺少可用的 RISC-V 交叉工具链
- 当前阻塞点是环境问题，不是已经确认的 `clock.c` 逻辑错误
- 需要在课程机或安装完整 RISC-V 工具链后，再生成 `clock.mem`

## 下一步怎么做

1. 在课程环境或本机安装可用工具链：
   - `riscv32-unknown-elf-gcc`，或
   - `riscv64-unknown-elf-gcc`，或
   - 带 RISC-V 后端的完整 LLVM（含 `lld`、`llvm-objcopy`、`llvm-objdump`）
2. 进入 `ee3220_tbl2_skeleton_rev1.0/firmware`
3. 运行 `make`
4. 检查是否生成：
   - `/Users/mandy/Desktop/EE3220/TBL2/ee3220_tbl2_skeleton_rev1.0/clock.mem`
5. 生成成功后，再进入 `06_测试平台与仿真.md`

## 完成标准

在当前机器上，下面项目已经满足：

- `clock.c` 已存在
- 固件逻辑完整
- `clock.mem` 输出位置已确认
- 已明确本地未生成 `clock.mem` 的原因是工具链缺失

后续在具备工具链的环境中，还需要补齐：

- 实际生成 `clock.mem`

## 交给下一个 TODO 的输入

- 可用固件源码 `clock.c`
- 已验证的 MMIO 宏定义
- 明确的 `clock.mem` 目标路径
- 一条待完成事项：在课程机生成 `clock.mem`
