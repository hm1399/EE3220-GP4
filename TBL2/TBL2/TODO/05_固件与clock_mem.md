# TODO 05：写固件并生成 `clock.mem`

## 目标

写出 `clock.c`，让 RISC-V 固件能从 `00:00:00` 开始，每秒更新时间并通过 UART 打印出来；随后生成 `clock.mem` 供 IMEM 使用。

## 本 TODO 完成后，你应该得到

- 新文件 `ee3220_tbl2_skeleton_rev1.0/firmware/clock.c`
- 可编译的 bare-metal 固件
- 生成出来的 `clock.mem`

## agent 可以做什么

- 编写 `clock.c`
- 用 handout 的 MMIO 宏定义访问 UART 和 timer
- 实现 `uart_putc`、字符串输出、时间加一逻辑
- 实现三种 rollover
- 在条件允许时尝试本地编译，生成 `clock.mem`

## agent 如何实现

你可以把下面约束直接交给 agent：

- 文件路径：`ee3220_tbl2_skeleton_rev1.0/firmware/clock.c`
- 不依赖标准库输出函数
- 直接用 volatile MMIO 读写寄存器
- 启动后先输出一次 `00:00:00`
- 之后轮询 timer：
  - 检查 `tick_pending`
  - 清除 tick
  - 更新时间
  - 输出新的时间
- 显示可以先用“每秒一行”的最低风险实现
- 不要优先做 VT100、颜色、串口设时等扩展

如果本地工具链可行，agent 可以继续：

- 进入 `ee3220_tbl2_skeleton_rev1.0/firmware`
- 运行 `make`
- 观察是否生成上级目录下的 `clock.mem`

## 你必须做什么

- 你要确认输出格式满足老师要求即可，不要为了美观拖慢主线
- 你要检查 `clock.mem` 是否真的生成在项目需要的位置
- 如果 agent 本地编译失败，你要判断是代码问题还是你本机工具链缺失

目前环境里我能看到 `clang`，所以 agent 可能有机会本地编译；但如果遇到你课程机器和本机环境不同，最终仍应以课程环境结果为准。

## 你一步一步怎么操作

1. 确保 SoC 集成已完成。
2. 把本 TODO 交给一个 agent。
3. agent 完成后，先检查：
   - `clock.c` 是否存在
   - 是否使用了正确 MMIO 地址
   - 是否实现了 rollover
4. 如果 agent 报告可编译，检查项目根目录或约定位置是否已有 `clock.mem`。
5. 如果没有 `clock.mem`，让 agent 说明是工具链问题还是代码问题。
6. 只有在 `clock.c` 基本稳定后，再进入 `06_测试平台与仿真.md`。

## 你要特别盯住的风险

- 直接调用 `printf`
- 地址与硬件不一致
- 忘了清 `tick_pending`
- 没输出初始时间
- `23:59:59` 回卷错误

## 完成标准

- `clock.c` 已存在
- 固件逻辑完整
- 至少理论上可生成 `clock.mem`
- 若本地工具链可用，`clock.mem` 已生成

## 交给下一个 TODO 的输入

- 可用固件
- `clock.mem`
- 已验证的 MMIO 宏定义
