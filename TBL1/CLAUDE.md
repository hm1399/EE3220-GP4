# EE3220 TBL1 — Polar Code + CRC-16 纠错系统项目

## 项目概述

为 Space-Z 火星机器人通信设计纠错码（ECC）子系统。使用 Polar 码 + 嵌入式 CRC-16，用 SystemVerilog 实现编码器和解码器，在 Vivado xsim 中仿真验证。

安全原则：**宁可拒绝指令（valid=0），也不执行错误指令。**

## 固定参数

```
N  = 64        （码字长度）
K  = 40        （信息位 = 24 数据 + 16 CRC）
冻结位 = 24
码率 R = 40/64 = 0.625
dmin = 8       （最小汉明距离，纠正 1-3 位，检测 4 位）
```

## 位置映射规则

- INFO_POS[0..39]：信息位位置，必须满足 popcount(i) <= 3（保证 dmin=8）
- FROZEN_POS[0..23]：冻结位位置，编码时置 0，解码时强制为 0
- 共 42 个候选位置满足 popcount<=3，用 Bhattacharyya 参数（BEC(0.5)）排序，选最可靠的 40 个
- 位置映射定义在 `polar_common_pkg.sv` 中，编码器和解码器共用

## CRC-16-CCITT 规范（必须严格遵守）

```
多项式：G(x) = x^16 + x^12 + x^5 + 1
Verilog 完整多项式：17'h11021（不要写 16'h11021）
反馈异或常量：16'h1021
初始余数：16'h0000
处理顺序：MSB 优先（data_in[23] downto data_in[0]）
无反射，无最终异或（xorout = 0）
```

参考算法：

```
crc = 0
for i = 23 downto 0:
    feedback = data_in[i] XOR crc[15]
    crc = (crc << 1) & 0xFFFF
    if feedback == 1:
        crc = crc XOR 0x1021
```

## Polar 蝶形变换（无比特反转）

```
v = u
for s = 0..5:
    step = 2^(s+1)
    half = 2^s
    for i = 0..63, 步长 step:
        for j = 0..half-1:
            v[i+j] = v[i+j] XOR v[i+j+half]
codeword = v
```

这是纯组合逻辑操作，可在单周期内完成。

## 模块接口（必须严格匹配）

### polar64_crc16_encoder

```systemverilog
module polar64_crc16_encoder (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        start,      // 1 周期脉冲
    input  logic [23:0] data_in,
    output logic        done,       // 1 周期脉冲
    output logic [63:0] codeword
);
```

- `done` 必须在 `start` 后**恰好第 2 个时钟沿**拉高
- 流程：计算 CRC → 组装 u 向量（信息位+冻结位=0）→ 蝶形变换 → 输出

### polar64_crc16_decoder

```systemverilog
module polar64_crc16_decoder (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        start,      // 1 周期脉冲
    input  logic [63:0] rx,
    output logic        done,       // 1 周期脉冲
    output logic [23:0] data_out,
    output logic        valid
);
```

- `done` 必须在 `start` 后 **12 周期内**拉高（<= 8 周期可加分 +5）
- 流程：逆变换 → 强制冻结位为 0 → 有界距离解码（半径 3）→ 提取数据和 CRC → CRC 校验
- `valid=1` 当且仅当：存在唯一合法码字距离 <= 3 **且** CRC 校验通过

## 解码器数据提取规则

```
for k = 0..23:  data_out[23-k]  = u_hat[INFO_POS[k]]
for k = 0..15:  crc_rx[15-k]    = u_hat[INFO_POS[24+k]]
```

注意 `23-k` 和 `15-k` 的映射方向，不要搞反。

## 编码器数据放置规则

```
for k = 0..23:  u[INFO_POS[k]]      = data_in[23-k]
for k = 0..15:  u[INFO_POS[24+k]]   = crc[15-k]
for k = 0..23:  u[FROZEN_POS[k]]    = 0
```

## valid 判定逻辑（安全优先）

1. 逆 Polar 变换得到 u_hat
2. 检查冻结位 syndrome（冻结位位置的 u_hat 值）
3. 如果 syndrome 对应的错误模式汉明重量 <= 3：纠正，继续
4. 如果 syndrome 对应的错误模式汉明重量 = 4：拒绝，valid=0
5. 如果 syndrome 对应的错误模式汉明重量 >= 5：拒绝，valid=0
6. 纠正后提取数据，重新计算 CRC 并与提取的 CRC 比较
7. CRC 不匹配 → valid=0
8. 一切通过 → valid=1

## 文件结构

```
TBL1/
├── polar_common_pkg.sv          # 共用参数包（INFO_POS, FROZEN_POS）
├── polar64_crc16_encoder.sv     # 编码器
├── polar64_crc16_decoder.sv     # 解码器
├── crc.sv                       # CRC 模块（可选，也可集成）
├── tb_basic.sv                  # 测试平台
├── README.md
├── report.pdf                   # 最多 2 页
├── ai_log.txt                   # AI 使用日志
└── TBL1_文档/                    # 项目文档
```

## 仿真命令

```bash
xvlog -sv polar_common_pkg.sv polar64_crc16_encoder.sv \
    polar64_crc16_decoder.sv tb_basic.sv
xelab tb_basic -debug typical -s sim_snapshot
xsim sim_snapshot -runall
```

## 验证场景

| 场景 | 输入 | 预期 valid | 预期 data_out |
| --- | --- | --- | --- |
| Case A：0 位翻转 | codeword 原样 | 1 | 与 data_in 一致 |
| Case B：1-3 位翻转 | 翻转 codeword 的 1~3 位 | 1 | 与 data_in 一致 |
| Case C：4 位翻转 | 翻转 codeword 的 4 位 | 0 | 不关心 |

## 编码风格要求

- 使用 SystemVerilog（.sv 后缀）
- 可综合 RTL 风格：用 always_ff / always_comb，不用 initial 块（testbench 除外）
- 信号命名清晰，与规范一致
- 避免 latch：所有 always_comb 分支覆盖完整
- 复位使用异步低电平有效（rst_n）

## 常见错误提醒

1. **CRC 多项式写错**：完整多项式是 17'h11021，不是 16'h11021；反馈常量是 16'h1021
2. **比特顺序搞反**：数据提取用 `23-k` 而非 `k`，CRC 提取用 `15-k` 而非 `k`
3. **蝶形变换方向错**：是 `v[i+j] ^= v[i+j+half]`，不是反过来
4. **冻结位没强制为 0**：解码时必须将 u_hat 的冻结位位置清零
5. **done 时序不对**：编码器必须恰好 2 周期，不是 1 也不是 3
6. **valid 太激进**：不确定时必须输出 valid=0，错误的 valid=1 扣分最重（20 分）
7. **INFO_POS/FROZEN_POS 不一致**：编码器和解码器必须用同一套，放在 pkg 里共享

## 评分分布

| 项目 | 分值 |
| --- | --- |
| CRC 正确性 | 15 |
| 编码器正确性 | 20 |
| 解码器无错信道 | 15 |
| 安全行为（valid 正确性） | 20 |
| 接口/时序 | 10 |
| 测试平台 | 10 |
| 代码+文档 | 10 |
| **总计** | **100** |
| 加分：done<=8 周期 | +5 |
| 加分：流水线架构 | +5 |
| 加分：可综合 RTL 风格 | +5 |

## AI 使用日志（自动维护）

每次对本项目进行代码生成、修改或重要决策时，必须自动追加记录到 `log.txt`。

日志文件路径：`/Users/mandy/Desktop/EE3220/TBL1/log.txt`

每条记录格式：

```text
=== YYYY-MM-DD HH:MM ===
操作：<简述做了什么，如"生成 CRC 模块"、"修改解码器 valid 逻辑">
文件：<涉及的文件列表>
提示词摘要：<用户的关键指令>
采纳内容：<生成/修改了什么代码或内容>
修改原因：<为什么这样做>
---
```

规则：
- 每次写入或编辑 .sv 文件后，立即追加一条日志
- 每次做出架构决策（如选定 INFO_POS/FROZEN_POS）后，追加一条日志
- 每次修复 bug 后，追加一条日志，说明 bug 原因和修复方式
- 日志用中文书写，代码片段可用英文
- 使用 Bash 工具以追加模式（>>）写入，不要覆盖已有内容
- 最终提交前，将 `log.txt` 内容整理复制到 `ai_log.txt`

## 项目架构文档（自动维护）

每次对项目进行代码变更后，必须同步更新架构文档，确保文档始终反映代码的真实状态，防止 AI 在后续对话中产生幻觉。

文档路径：`/Users/mandy/Desktop/EE3220/TBL1/structure.md`

### 何时更新

- 新建或删除任何 `.sv` 文件后
- 模块接口（端口列表）发生变化后
- INFO_POS / FROZEN_POS 确定或修改后
- 编码器/解码器内部实现方式发生变化后
- 修复 bug 导致逻辑变更后
- 测试平台增加新的测试场景后

### 文档必须包含的内容

文档用以下固定结构书写，每个部分都必须如实反映当前代码：

```markdown
# 项目架构文档（自动生成，请勿手动编辑）

> 最后更新：YYYY-MM-DD HH:MM

## 文件清单

| 文件名 | 状态 | 说明 |
| --- | --- | --- |
| polar_common_pkg.sv | 已完成/进行中/未开始 | 共用参数包 |
| ... | ... | ... |

## INFO_POS / FROZEN_POS（当前使用的值）

- INFO_POS = [具体数组值，或"未确定"]
- FROZEN_POS = [具体数组值，或"未确定"]
- dmin 验证结果：通过/未验证

## 模块：polar64_crc16_encoder

- 端口列表：[列出当前代码中实际的端口]
- done 延迟：[实际实现的周期数]
- CRC 计算方式：[组合逻辑 / 串行移位 / 查表，写明实际采用的方式]
- 蝶形变换实现：[组合逻辑展开 / for 循环 generate / 流水线，写明实际方式]
- 已知问题：[列出当前已知但未修复的问题，没有则写"无"]

## 模块：polar64_crc16_decoder

- 端口列表：[列出当前代码中实际的端口]
- done 延迟：[实际实现的周期数]
- 解码策略：[具体说明当前采用的解码算法，如 syndrome 查表 / 逐位判决 / 枚举纠错]
- syndrome 计算方式：[具体说明]
- 纠错实现：[如何从 syndrome 定位错误位并翻转]
- CRC 校验实现：[组合逻辑 / 复用编码器的 CRC 模块]
- valid 判定逻辑：[按顺序列出当前代码中实际的判定条件]
- 已知问题：[列出当前已知但未修复的问题，没有则写"无"]

## 模块：CRC（如果独立存在）

- 文件名：[crc.sv 或 已集成到 encoder/decoder 中]
- 实现方式：[组合逻辑并行 / 串行移位寄存器]
- 接口：[列出端口]

## 测试平台：tb_basic.sv

- 已实现的测试场景：
  - [ ] Case A：0 位翻转
  - [ ] Case B：1-3 位翻转
  - [ ] Case C：4 位翻转
  - [ ] 多数据值测试
- 使用的测试数据：[列出 data_in 的具体值]
- 仿真结果：通过/失败/未运行

## 变更历史

| 日期 | 变更内容 |
| --- | --- |
| YYYY-MM-DD | 初始创建 / 具体变更说明 |
```

### 更新规则

- 使用 Write 工具**整体重写** `structure.md`（不是追加），确保内容完整一致
- 每个字段必须反映代码的**实际当前状态**，不写计划、不写猜测
- 如果某模块尚未实现，状态写"未开始"，实现方式写"未确定"
- 如果实现方式与之前不同（如重构），必须更新为新的描述
- 在更新 `structure.md` 之前，先 Read 相关 `.sv` 文件确认实际内容
