# TBL2 Windows 课程机构建与环境安装指南

## 1. 先说结论

- `clock.mem` 不是在 Vivado 里生成的，而是先在终端里跑 `Makefile` 生成。
- Vivado 负责的是：
  - 加源文件
  - 跑仿真
  - 跑综合与实现
  - 生成 bitstream
- 本项目当前仓库的 `Makefile` 依赖：
  - 一套可用的 RISC-V 编译工具链，或完整 LLVM
  - `make`
  - `sh`
  - `python3`
- 课程 handout 明确写了课程机会提供：
  - PYNQ-Z2
  - Vivado 2022.2
  - UART terminal program
- 但 handout 没有明确保证课程机一定预装：
  - `riscv32-unknown-elf-gcc`
  - `riscv64-unknown-elf-gcc`
  - `make`
  - `python3`

所以，最稳的做法不是直接假设课程机里什么都有，而是先检查，再构建。

## 2. 不要在 Vivado 里做的事

下面这些步骤不在 `Create Block Design` 里做：

- 编译 `clock.c`
- 生成 `clock.elf`
- 生成 `clock.mem`

原因很简单：

- `ee3220_tbl2_skeleton_rev1.0/firmware/Makefile` 会先把 `clock.c + start.S + linker.ld` 编成 `elf/bin`
- 然后再调用 `tools/bin2mem.py` 生成 `clock.mem`
- `ee3220_tbl2_skeleton_rev1.0/rtl/imem.sv` 里用 `$readmemh("clock.mem", mem);` 读这个文件

没有 `clock.mem`，SoC 里就没有固件程序可跑。

## 3. 课程机上的最短操作路径

这部分默认你使用的是 Windows 课程机。

### 3.1 先开终端，不要先开 Block Design

推荐顺序：

1. 先打开 Windows Terminal、PowerShell 或 `cmd`
2. 先检查工具
3. 生成 `clock.mem`
4. 再进入 Vivado

### 3.2 先检查课程机到底有没有这些工具

在 `cmd` 里执行：

```cmd
where riscv32-unknown-elf-gcc
where riscv32-unknown-elf-objcopy
where riscv32-unknown-elf-objdump
where riscv64-unknown-elf-gcc
where riscv64-unknown-elf-objcopy
where riscv64-unknown-elf-objdump
where clang
where ld.lld
where llvm-objcopy
where llvm-objdump
where make
where sh
where python3
```

你真正需要的是下面两组条件之一成立：

- GCC 路线：
  - `riscv32-unknown-elf-gcc` 或 `riscv64-unknown-elf-gcc`
  - 对应的 `objcopy` 和 `objdump`
  - `make`
  - `sh`
  - `python3`
- LLVM 路线：
  - `clang`
  - `ld.lld`
  - `llvm-objcopy`
  - `llvm-objdump`
  - `make`
  - `sh`
  - `python3`

如果这两组都不满足，不要直接往下跑 `make`，先处理环境。

### 3.3 进入 firmware 目录

在 `cmd` 里执行：

```cmd
cd /d <你的仓库路径>\ee3220_tbl2_skeleton_rev1.0\firmware
```

例如：

```cmd
cd /d D:\EE3220\TBL2\ee3220_tbl2_skeleton_rev1.0\firmware
```

如果你的仓库就在用户目录，也可以是：

```cmd
cd /d C:\Users\<你的用户名>\Documents\GitHub\EE3220-GP4\TBL2\ee3220_tbl2_skeleton_rev1.0\firmware
```

### 3.4 运行构建

在 `cmd` 里执行：

```cmd
make clean
make
```

### 3.5 检查是否生成 `clock.mem`

在 `cmd` 里执行：

```cmd
dir ..\clock.mem
dir build
```

当前这个仓库下，目标文件应当出现在：

```text
<你的仓库路径>\ee3220_tbl2_skeleton_rev1.0\clock.mem
```

不是在 `firmware\build\` 里，也不是 Vivado 自动帮你生出来的。

### 3.6 生成成功以后，再进入 Vivado

生成 `clock.mem` 成功后，再开始 `TODO 06` 和 Vivado 相关步骤。

## 4. 生成完 `clock.mem` 以后，Vivado 里怎么做

### 4.1 工程类型

本项目应使用普通 `RTL Project`，不要用 `Create Block Design`。

原因：

- 顶层已经给了 `pynq_z2_tx_demo_top.sv`
- SoC 已经给了 `picorv32_soc_ref.sv`
- 约束已经给了 `pynq_z2_tx_demo.xdc`

你不是在用 IP Integrator 拼 Zynq PS，也不是在自己画 AXI block design。

### 4.2 Vivado 的基本流程

1. `Create Project`
2. 选择 `RTL Project`
3. 选择器件或 PYNQ-Z2 board
4. 加入 `rtl/` 下所有 `.sv`
5. 加入 `constraints/pynq_z2_tx_demo.xdc`
6. 加入 `clock.mem`
7. 设定 top module 为 `pynq_z2_tx_demo_top`
8. 先跑 simulation 或直接跑 synthesis

### 4.3 `clock.mem` 怎么加进 Vivado

推荐做法：

1. 打开工程
2. 点 `Add Sources`
3. 选择 `Add or Create Design Sources`
4. 把 `clock.mem` 加进去
5. 确认它被工程复制或引用成功

如果课程机工程目录和你生成 `clock.mem` 的目录分开，最稳的做法是把生成好的 `clock.mem` 放在 Vivado 工程可访问的位置，并重新 `Add Sources`。

### 4.4 顶层模块

必须确认 top module 是：

```text
pynq_z2_tx_demo_top
```

不要误设成：

- `picorv32_soc_ref`
- `uart`
- `timer`
- 其他 testbench 模块

## 5. Windows 下推荐的环境准备方案

这部分分成三种情况。

### 5.1 情况 A：课程机已经有完整工具

这是最理想情况。

如果你在课程机上已经能查到：

- `riscv32-unknown-elf-gcc` 或 `riscv64-unknown-elf-gcc`
- 或者 `clang + ld.lld + llvm-objcopy + llvm-objdump`
- 外加 `make + sh + python3`

那就不要折腾安装，直接进入第 3 节跑构建。

### 5.2 情况 B：课程机没有完整工具，但允许你在自己的 Windows 机器上准备环境

这是最推荐的本机准备方式：

- 用 MSYS2 提供 `make`、`sh`、`python3`
- 用完整 LLVM 提供 `clang`、`ld.lld`、`llvm-objcopy`、`llvm-objdump`

这样最贴合当前仓库的 `Makefile`。

### 5.3 情况 C：你手上只有 RISC-V GCC/xPack 一类工具链

可以用，但要特别注意：

- 当前 `Makefile` 只会自动探测：
  - `riscv32-unknown-elf-gcc`
  - `riscv64-unknown-elf-gcc`
  - `clang`
- 它不会自动探测：
  - `riscv-none-elf-gcc`

因此如果你装的是名字为 `riscv-none-elf-gcc` 的工具链，就算工具链本身可用，当前 `Makefile` 也未必会自动识别。

## 6. Windows 本机安装教程

下面的教程是给你自己的 Windows 机器准备环境时用的。  
如果你在课程机上没有管理员权限，优先问 TA，不要擅自改实验机环境。

## 6.1 先装 MSYS2

用途：

- 提供 `make`
- 提供 `sh`
- 提供 `python3`
- 让当前这个偏 Unix 风格的 `Makefile` 能正常跑

官方站点：

- MSYS2 官网：<https://www.msys2.org/>
- 安装说明：<https://www.msys2.org/docs/installer/>
- 更新说明：<https://www.msys2.org/docs/updating/>

### 安装步骤

1. 从 MSYS2 官网下载安装器
2. 按默认方式安装到：

```text
C:\msys64
```

3. 安装完成后，打开 `MSYS2 MSYS`
4. 先更新系统

在 MSYS2 终端里执行：

```bash
pacman -Suy
```

如果它提示关闭终端并重开，就照做。重开后再执行一次：

```bash
pacman -Suy
```

5. 安装本项目需要的包

在 MSYS2 终端里执行：

```bash
pacman -S --needed make python
```

这一步装好后，MSYS2 里会有：

- `make`
- `sh`
- `python3`

### 安装后验证

如果你把 `C:\msys64\usr\bin` 加进了 Windows `PATH`，那么回到 `cmd` 里执行：

```cmd
where make
where sh
where python3
```

如果你不想改全局 `PATH`，也可以只在 MSYS2 终端里跑 `make`。

## 6.2 再装完整 LLVM

用途：

- 提供 `clang`
- 提供 `ld.lld`
- 提供 `llvm-objcopy`
- 提供 `llvm-objdump`

当前仓库的 `Makefile` 已经支持这条路线。

官方文档：

- LLVM Windows 入门：<https://llvm.org/docs/GettingStartedVS.html>

### 安装建议

1. 安装官方 LLVM Windows 发行版
2. 把 LLVM 的 `bin` 目录加到 `PATH`

常见路径类似：

```text
C:\Program Files\LLVM\bin
```

### 安装后验证

在新的 `cmd` 里执行：

```cmd
where clang
where ld.lld
where llvm-objcopy
where llvm-objdump
clang --print-targets | findstr RISCV
```

如果最后一条能看到 `RISCV` 相关目标，说明这个 `clang` 至少看起来带有 RISC-V target。  
如果完全没有输出，就不要直接拿它跑本项目。

## 6.3 如果你更想用 RISC-V GCC

如果你已经拿到老师、TA 或课程机提供的 GCC 工具链，并且命令名就是：

- `riscv32-unknown-elf-gcc`
- 或 `riscv64-unknown-elf-gcc`

那你只需要额外保证：

- `make`
- `sh`
- `python3`

也已经可用。

验证命令：

```cmd
where riscv32-unknown-elf-gcc
where riscv32-unknown-elf-objcopy
where riscv32-unknown-elf-objdump
where riscv64-unknown-elf-gcc
where riscv64-unknown-elf-objcopy
where riscv64-unknown-elf-objdump
```

## 6.4 如果你装的是 xPack GNU RISC-V Embedded GCC

官方安装页：

- <https://xpack-dev-tools.github.io/riscv-none-elf-gcc-xpack/docs/install/>

这里要特别注意一个项目内的现实问题：

- xPack 默认提供的编译器名字通常是 `riscv-none-elf-gcc`
- 但当前仓库的 `Makefile` 不会自动探测这个名字

因此，xPack 不是当前仓库下“开箱即用”的默认路线。

如果你一定要用 xPack，通常有两种办法：

1. 最小修改 `Makefile`，把 `riscv-none-elf-gcc` 也加进探测逻辑
2. 自己做一层包装脚本，把 `riscv-none-elf-gcc` 包装成 `riscv32-unknown-elf-gcc`

如果你现在的目标只是尽快完成课程实验，不建议把时间花在这里。  
优先顺序应当是：

1. 课程机现成工具链
2. LLVM 路线
3. 再考虑 xPack 适配

## 7. 最推荐的本机组合

如果你是在自己的 Windows 机器上搭环境，当前仓库下最稳的组合是：

1. MSYS2
2. `pacman -S --needed make python`
3. 官方 LLVM

这样当前 `Makefile` 不用改，理论上就能走：

- `clang`
- `ld.lld`
- `llvm-objcopy`
- `llvm-objdump`
- `make`
- `sh`
- `python3`

## 8. 常见报错与处理

### 8.1 `make: command not found`

说明：

- 没装 GNU Make
- 或 `make.exe` 不在 `PATH`

处理：

- 安装 MSYS2 的 `make`
- 确认 `where make` 能找到它

### 8.2 `sh: not found`

说明：

- Windows 里只有 `make` 还不够
- 这个 `Makefile` 的命令依赖 shell 环境

处理：

- 安装 MSYS2
- 确认 `where sh` 能找到 `sh.exe`

### 8.3 `python3: not found`

说明：

- 当前仓库的 `Makefile` 调的是 `python3`
- 不是 `python`
- 也不是 `py`

处理：

- 最稳是装 MSYS2 的 `python`
- 然后确认 `where python3`

### 8.4 `No suitable RISC-V toolchain found`

说明：

- `Makefile` 没找到：
  - `riscv32-unknown-elf-gcc`
  - `riscv64-unknown-elf-gcc`
  - 或完整 LLVM 路线

处理：

- 先检查 `where ...`
- 没有就先补环境，不要继续往下跑

### 8.5 `clang: error: invalid linker name in argument '-fuse-ld=lld'`

说明：

- 你当前的 `clang` 不是完整 LLVM 安装
- 或 `ld.lld` 不在 `PATH`

处理：

- 安装完整 LLVM
- 确认 `where ld.lld`

### 8.6 `No available targets are compatible with triple "riscv32-unknown-elf"`

说明：

- 你当前的 `clang` 没有可用的 RISC-V backend

处理：

- 换一套完整 LLVM
- 或改走 GCC 路线

### 8.7 `clock.mem` 已生成，但 Vivado 里还是跑不起来

优先检查：

1. `clock.mem` 是否真的加入工程
2. top module 是否真的是 `pynq_z2_tx_demo_top`
3. `imem.sv` 是否能在工程运行目录里找到 `clock.mem`

## 9. 一套可以直接照着走的最终流程

### Windows 终端部分

```cmd
where riscv32-unknown-elf-gcc
where riscv64-unknown-elf-gcc
where clang
where ld.lld
where llvm-objcopy
where llvm-objdump
where make
where sh
where python3
cd /d <你的仓库路径>\ee3220_tbl2_skeleton_rev1.0\firmware
make clean
make
dir ..\clock.mem
```

### Vivado 部分

1. `Create Project`
2. 选 `RTL Project`
3. 加入所有 `.sv`
4. 加入 `.xdc`
5. 加入 `clock.mem`
6. 设 top 为 `pynq_z2_tx_demo_top`
7. 做 `TODO 06` 仿真
8. 仿真过后再做综合、实现、bitstream、上板

## 10. 参考

### 项目内文件

- `ee3220_tbl2_skeleton_rev1.0/firmware/Makefile`
- `ee3220_tbl2_skeleton_rev1.0/rtl/imem.sv`
- `MD/tbl2_handout/tbl2_handout.md`

### 外部官方文档

- Python Windows 下载页：<https://www.python.org/getit/windows/>
- Microsoft WinGet 文档：<https://learn.microsoft.com/en-us/windows/package-manager/winget/>
- MSYS2 官网：<https://www.msys2.org/>
- MSYS2 安装说明：<https://www.msys2.org/docs/installer/>
- MSYS2 更新说明：<https://www.msys2.org/docs/updating/>
- MSYS2 `make` 包页面：<https://packages.msys2.org/package/make>
- xPack GNU RISC-V Embedded GCC 安装页：<https://xpack-dev-tools.github.io/riscv-none-elf-gcc-xpack/docs/install/>
- LLVM Windows 文档：<https://llvm.org/docs/GettingStartedVS.html>
