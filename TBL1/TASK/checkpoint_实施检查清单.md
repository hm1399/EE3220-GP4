# EE3220 TBL1 实施检查清单（供 AI 逐步执行）

> 本文档是给 AI 的逐步执行指令。每个 Checkpoint 必须按顺序完成，完成后勾选。
> 每个 Checkpoint 都包含：目标、具体操作、验收标准、产出文件。

---

## 项目固定参数（全局常量，所有 Checkpoint 通用）

```text
N          = 64          码字长度
K          = 40          信息位（24 数据 + 16 CRC）
F          = 24          冻结位
dmin       = 8           最小汉明距离
CRC 多项式  = 0x11021     (x^16 + x^12 + x^5 + 1)
CRC 反馈    = 0x1021
CRC 初始值  = 0x0000
CRC 顺序    = MSB 优先（data_in[23] downto data_in[0]）
```

## 文件路径约定

```text
根目录：/Users/mandy/Documents/GitHub/EE3220-GP4/TBL1/
代码文件全部放在根目录下（不要放子目录）：
  polar_common_pkg.sv
  polar64_crc16_encoder.sv
  polar64_crc16_decoder.sv
  tb_basic.sv                ← 已提供，不要修改
```

---

## Checkpoint 1：创建 polar_common_pkg.sv（位置映射 + 辅助函数）

### 1.1 目标

创建共用参数包，包含 INFO_POS、FROZEN_POS 和 testbench 所需的辅助函数。

### 1.2 具体操作

创建文件 `polar_common_pkg.sv`，内容必须包含：

#### 1.2.1 参数定义

```systemverilog
package polar_common_pkg;

    localparam int N = 64;
    localparam int K = 40;
    localparam int F = 24;

    localparam int INFO_POS [0:39] = '{
        2,  3,  4,  5,  6,  7,  8,  9, 10, 11,
       12, 13, 14, 16, 17, 18, 19, 20, 21, 22,
       24, 25, 26, 28, 32, 33, 34, 35, 36, 37,
       38, 40, 41, 42, 44, 48, 49, 50, 52, 56
    };

    localparam int FROZEN_POS [0:23] = '{
        0,  1, 15, 23, 27, 29, 30, 31,
       39, 43, 45, 46, 47, 51, 53, 54,
       55, 57, 58, 59, 60, 61, 62, 63
    };
```

#### 1.2.2 辅助函数（tb_basic.sv 会调用，必须提供）

tb_basic.sv 中调用了以下函数，必须在 package 里实现：

**① `crc16_ccitt24(input logic [23:0] data)` → 返回 `logic [15:0]`**

```text
算法：
  crc = 16'h0000
  for i = 23 downto 0:
      feedback = data[i] ^ crc[15]
      crc = {crc[14:0], 1'b0}
      if (feedback) crc = crc ^ 16'h1021
  return crc
```

**② `build_u(input logic [23:0] data, input logic [15:0] crc)` → 返回 `logic [63:0]`**

```text
算法：
  u = 64'b0
  for k = 0..23:  u[INFO_POS[k]]      = data[23-k]
  for k = 0..15:  u[INFO_POS[24+k]]   = crc[15-k]
  // 冻结位已经是 0
  return u
```

**③ `polar_transform64(input logic [63:0] u)` → 返回 `logic [63:0]`**

```text
算法（蝶形变换）：
  v = u
  for s = 0 to 5:
      step = 1 << (s+1)      // 2, 4, 8, 16, 32, 64
      half = 1 << s           // 1, 2, 4, 8, 16, 32
      for i = 0 to 63, 步长 step:
          for j = 0 to half-1:
              v[i+j] = v[i+j] ^ v[i+j+half]
  return v
```

**④ `pos_tables_ok()` → 返回 `bit`**

```text
验证 INFO_POS 和 FROZEN_POS 的正确性：
  - 两个数组合并后恰好覆盖 0~63 每个值各一次
  - 无重复，无遗漏
  返回 1 表示正确，0 表示错误
```

**⑤ `min_info_row_weight()` → 返回 `int`**

```text
计算所有信息位位置的最小行重量：
  对每个 INFO_POS[k]：
    行重量 = 2^(6 - popcount(INFO_POS[k]))
  返回最小值（应该 = 8）
```

最后别忘了 `endpackage`。

### 1.3 验收标准

- [x] 文件路径：`TBL1/polar_common_pkg.sv`
- [x] INFO_POS 恰好 40 个元素，值与上面一致
- [x] FROZEN_POS 恰好 24 个元素，值与上面一致
- [x] INFO_POS ∪ FROZEN_POS = {0, 1, ..., 63}，无重叠
- [x] 所有 INFO_POS 的 popcount <= 3
- [x] 五个辅助函数全部实现
- [x] 使用 `package ... endpackage` 包裹
- [ ] 语法上可被 `xvlog -sv` 编译通过

### 1.4 产出文件

`polar_common_pkg.sv`

---

## Checkpoint 2：实现 CRC-16 模块

### 2.1 目标

实现 CRC-16-CCITT 计算，可以集成在编码器/解码器内部，也可以独立成 `crc.sv`。推荐直接在编码器和解码器内部用组合逻辑实现（不需要独立模块）。

### 2.2 规格（必须严格遵守，一个字都不能改）

```text
多项式：G(x) = x^16 + x^12 + x^5 + 1
完整多项式（17位）：17'h11021
反馈异或常量（16位）：16'h1021
初始余数：16'h0000
处理顺序：MSB 优先 → data_in[23], data_in[22], ..., data_in[0]
无反射（no reflect）
无最终异或（xorout = 0）
```

### 2.3 参考实现（SystemVerilog 组合逻辑）

```systemverilog
function automatic logic [15:0] calc_crc16(input logic [23:0] data);
    logic [15:0] crc;
    logic        fb;
    crc = 16'h0000;
    for (int i = 23; i >= 0; i--) begin
        fb  = data[i] ^ crc[15];
        crc = {crc[14:0], 1'b0};
        if (fb) crc = crc ^ 16'h1021;
    end
    return crc;
endfunction
```

### 2.4 验证方法

用 Python 计算参考值来对比：

```python
# Python 参考
def crc16_ccitt(data_24bit):
    crc = 0
    for i in range(23, -1, -1):
        bit = (data_24bit >> i) & 1
        feedback = bit ^ ((crc >> 15) & 1)
        crc = (crc << 1) & 0xFFFF
        if feedback:
            crc ^= 0x1021
    return crc

# 测试向量
print(hex(crc16_ccitt(0xABCDEF)))  # tb_basic 用的测试数据
print(hex(crc16_ccitt(0x000000)))
print(hex(crc16_ccitt(0xFFFFFF)))
```

### 2.5 验收标准

- [x] CRC 算法结果与 Python 参考实现一致
- [x] 初始值是 0x0000（不是 0xFFFF）
- [x] 处理顺序是 MSB 优先（i = 23 downto 0）
- [x] 反馈常量是 16'h1021（不是 17'h11021）
- [x] 可以在编码器和解码器中复用（同一套逻辑）

### 2.6 产出

CRC 逻辑（嵌入后续的编码器/解码器中，或独立 `crc.sv`）

---

## Checkpoint 3：实现编码器 polar64_crc16_encoder

### 3.1 目标

实现 Polar 编码器，输入 24 位数据，输出 64 位码字。

### 3.2 模块接口（必须严格匹配，不能多也不能少）

```systemverilog
module polar64_crc16_encoder (
    input  logic        clk,
    input  logic        rst_n,      // 异步低电平复位
    input  logic        start,      // 1 周期脉冲，启动编码
    input  logic [23:0] data_in,    // 24 位原始数据
    output logic        done,       // 1 周期脉冲，编码完成
    output logic [63:0] codeword    // 64 位编码后码字
);
```

### 3.3 内部逻辑（三步，全部用组合逻辑完成）

```text
第 1 步：CRC 计算
  crc = calc_crc16(data_in)    → 得到 16 位 CRC

第 2 步：组装 u 向量
  u = 64'b0
  for k = 0..23:   u[INFO_POS[k]]    = data_in[23-k]     ← 注意 23-k
  for k = 0..15:   u[INFO_POS[24+k]] = crc[15-k]         ← 注意 15-k
  FROZEN_POS 对应位置保持 0

第 3 步：蝶形变换
  v = u
  for s = 0..5:
      step = 2^(s+1);  half = 2^s
      for i = 0..63, 步长 step:
          for j = 0..half-1:
              v[i+j] = v[i+j] ^ v[i+j+half]
  codeword = v
```

### 3.4 时序要求（极其重要）

```text
Cycle 0:  start 被采样（posedge clk 时 start=1）
Cycle 1:  done 必须为 0（中间周期）
Cycle 2:  done 必须为 1，codeword 有效
Cycle 3:  done 必须回到 0（done 是单周期脉冲）
```

实现方式：用一个 2 拍移位寄存器或计数器。

```text
建议实现：
  reg [1:0] pipe;
  always_ff @(posedge clk or negedge rst_n):
    if (!rst_n) pipe <= 0
    else        pipe <= {pipe[0], start}
  done = pipe[1]
  codeword 在 done 拉高时输出（可以是寄存器输出或组合逻辑）
```

### 3.5 编码风格要求

- `import polar_common_pkg::*;`
- 用 `always_ff` 做时序逻辑，`always_comb` 做组合逻辑
- 异步复位 `rst_n`
- 不使用 `initial` 块
- 可综合 RTL 风格

### 3.6 验收标准

- [x] 模块名：`polar64_crc16_encoder`（精确匹配）
- [x] 端口名和方向与 3.2 完全一致
- [x] `import polar_common_pkg::*`
- [x] CRC 计算正确（与 Checkpoint 2 的参考一致）
- [x] u 向量组装：比特映射方向正确（23-k 和 15-k）
- [x] 蝶形变换方向正确：`v[i+j] ^= v[i+j+half]`（不是反过来）
- [x] done 在 start 后恰好第 2 个周期拉高，持续 1 个周期
- [x] 复位时 done=0, codeword=0
- [x] ref_encode(24'hABCDEF) 的结果与 DUT 输出一致

### 3.7 产出文件

`polar64_crc16_encoder.sv`

---

## Checkpoint 4：实现解码器 polar64_crc16_decoder

### 4.1 目标

实现 Polar 解码器，输入可能有错误的 64 位码字，输出 24 位数据和 valid 信号。

### 4.2 模块接口（必须严格匹配）

```systemverilog
module polar64_crc16_decoder (
    input  logic        clk,
    input  logic        rst_n,      // 异步低电平复位
    input  logic        start,      // 1 周期脉冲，启动解码
    input  logic [63:0] rx,         // 64 位接收码字
    output logic        done,       // 1 周期脉冲，解码完成
    output logic [23:0] data_out,   // 解码后的 24 位数据
    output logic        valid       // 1=数据有效，0=数据无效
);
```

### 4.3 内部逻辑（6 步）

```text
第 1 步：逆 Polar 变换
  对 rx 做蝶形变换（与编码相同，因为 Polar 变换矩阵的逆 = 自身）
  u_hat = polar_transform64(rx)

第 2 步：提取 syndrome
  syndrome = u_hat 在 FROZEN_POS 位置上的值组成的 24 位向量
  for k = 0..23: syndrome[k] = u_hat[FROZEN_POS[k]]

第 3 步：从 syndrome 推导错误模式
  如果 syndrome == 0 → 无错误
  否则：
    对 syndrome 做正向 Polar 变换，映射回 64 位错误向量 error_pattern
    （具体做法：创建 64 位向量 e，在 FROZEN_POS 位置填入 syndrome 对应值，
     其余位置填 0，然后做蝶形变换 → e 就是估计的错误模式）

    计算 error_weight = popcount(error_pattern)

    如果 error_weight <= 3 → 可纠正
    如果 error_weight >= 4 → 不可纠正，valid = 0

第 4 步：纠错
  如果可纠正：
    corrected_rx = rx ^ error_pattern
    重新做逆变换：u_hat = polar_transform64(corrected_rx)
  强制冻结位为 0：
    for k = 0..23: u_hat[FROZEN_POS[k]] = 0

第 5 步：提取数据和 CRC
  for k = 0..23:  data_out[23-k]  = u_hat[INFO_POS[k]]        ← 注意 23-k
  for k = 0..15:  crc_rx[15-k]    = u_hat[INFO_POS[24+k]]     ← 注意 15-k

第 6 步：CRC 校验
  crc_calc = calc_crc16(data_out)
  如果 crc_calc != crc_rx → valid = 0
  如果 crc_calc == crc_rx 且 error_weight <= 3 → valid = 1
```

### 4.4 valid 判定逻辑（安全优先，完整规则）

```text
valid = 1 当且仅当以下全部满足：
  ① syndrome 为 0 或对应的 error_weight <= 3
  ② CRC 校验通过（重新计算的 CRC == 提取的 CRC）

任何一条不满足 → valid = 0
有任何不确定 → valid = 0
```

### 4.5 时序要求

```text
done 在 start 后 12 个时钟周期内拉高（1 周期脉冲）
如果 <= 8 周期内完成 → 加分 +5

建议：组合逻辑完成所有计算，用 2 拍流水就够了
（与编码器类似的 pipeline 结构）
```

### 4.6 编码风格要求

- `import polar_common_pkg::*;`
- 用 `always_ff` + `always_comb`
- 异步复位 `rst_n`
- 可综合 RTL 风格

### 4.7 验收标准

- [ ] 模块名：`polar64_crc16_decoder`（精确匹配）
- [ ] 端口名和方向与 4.2 完全一致
- [ ] `import polar_common_pkg::*`
- [ ] **Case A（0 位翻转）**：valid=1，data_out 正确还原
- [ ] **Case B（1 位翻转）**：valid=1，data_out 正确还原
- [ ] **Case B（2 位翻转）**：valid=1，data_out 正确还原
- [ ] **Case B（3 位翻转）**：valid=1，data_out 正确还原
- [ ] **Case C（4 位翻转）**：valid=0
- [ ] **Case D（5 位翻转）**：如果 valid=1 则 data_out 必须正确（否则 valid=0）
- [ ] done 在 start 后 12 周期内拉高，持续 1 个周期
- [ ] 复位时 done=0, valid=0, data_out=0
- [ ] **绝对不能出现 valid=1 但 data_out 错误的情况**

### 4.8 产出文件

`polar64_crc16_decoder.sv`

---

## Checkpoint 5：编译验证（通过 tb_basic）

### 5.1 目标

使用已提供的 `tb_basic.sv` 进行仿真，全部通过。

### 5.2 操作步骤

```bash
# 进入项目目录
cd /Users/mandy/Documents/GitHub/EE3220-GP4/TBL1/

# 第 1 步：编译所有文件
xvlog -sv polar_common_pkg.sv polar64_crc16_encoder.sv \
    polar64_crc16_decoder.sv tb_basic.sv

# 第 2 步：elaboration
xelab tb_basic -debug typical -s sim_snapshot

# 第 3 步：运行仿真
xsim sim_snapshot -runall
```

### 5.3 预期输出

```text
[TB] pos_tables_ok=1, min_info_row_weight=8 (target >= 8)
[SMOKE][PASS] +10 : Encoder: matches reference on 24'hABCDEF and done @ +2
[SMOKE][PASS] +10 : Decoder: Case A/B/C on ABCDEF (plus 1 fail-safe spot check)
[SMOKE][PASS] +10 : Interface timing: ENC done @+2, DEC done <=12, pulses are 1-cycle
------------------------------------------------------------
[SUMMARY] SMOKE score = 30 / 30
------------------------------------------------------------
[tb_basic] PASS
```

### 5.4 验收标准

- [ ] `xvlog` 编译无错误
- [ ] `xelab` 无错误
- [ ] `xsim` 输出 SMOKE score = 30 / 30
- [ ] 输出 `[tb_basic] PASS`
- [ ] 无 `FAIL` 行
- [ ] `pos_tables_ok=1`
- [ ] `min_info_row_weight=8`

### 5.5 常见编译错误及修复

| 错误信息 | 原因 | 修复 |
| --- | --- | --- |
| `crc16_ccitt24 is not declared` | pkg 里函数名不对 | 函数名必须是 `crc16_ccitt24`，不是 `calc_crc16` |
| `build_u is not declared` | pkg 里缺少 `build_u` 函数 | 添加该函数 |
| `polar_transform64 is not declared` | pkg 里缺少蝶形变换函数 | 添加该函数 |
| `pos_tables_ok is not declared` | pkg 里缺少验证函数 | 添加该函数 |
| `min_info_row_weight is not declared` | pkg 里缺少该函数 | 添加该函数 |
| `port mismatch` | 模块端口名与 tb 不一致 | 严格按规格中的端口名 |
| `done timing error` | done 时序不对 | 检查 pipeline 逻辑 |

---

## Checkpoint 6：更新项目文档

### 6.1 目标

更新 structure.md 和 log.txt，准备提交材料。

### 6.2 操作

1. 更新 `structure.md`：反映所有模块的实际实现状态
2. 追加 `log.txt`：记录每个模块的实现过程
3. 编写 `README.md`：包含编译命令、模块说明
4. 最终提交前将 `log.txt` 整理复制到 `ai_log.txt`

### 6.3 验收标准

- [ ] `structure.md` 反映真实代码状态
- [ ] `log.txt` 有完整记录
- [ ] `README.md` 包含 xsim 编译运行命令

---

## 执行顺序总结

```text
Checkpoint 1 → 2 → 3 → 4 → 5 → 6
    │              │         │
    │              │         └─ 如果 5 失败，回到 3 或 4 调试
    │              └─ CRC 嵌入编码器/解码器
    └─ pkg 是所有后续的基础

每完成一个 Checkpoint，检查其验收标准全部通过后再进入下一个。
```

## 关键陷阱提醒（AI 必读）

1. **函数名必须精确匹配** tb_basic.sv 调用的名字：`crc16_ccitt24`、`build_u`、`polar_transform64`、`pos_tables_ok`、`min_info_row_weight`
2. **比特映射方向**：数据用 `23-k`，CRC 用 `15-k`，不要写成 `k`
3. **蝶形变换方向**：是 `v[i+j] ^= v[i+j+half]`，不是 `v[i+j+half] ^= v[i+j]`
4. **done 时序**：编码器恰好 2 周期（不是 1，不是 3），解码器 12 周期内
5. **done 是单周期脉冲**：拉高 1 个周期后必须回到 0
6. **CRC 初始值是 0x0000**：不是 0xFFFF
7. **valid 安全优先**：不确定就输出 0，错误的 valid=1 扣 20 分
8. **编码器的 codeword 必须与 ref_encode 结果一致**：这意味着 pkg 中的辅助函数和编码器的内部逻辑必须完全等价
9. **解码器处理 5 位翻转**：如果 valid=1，data_out 必须正确；否则 valid 必须为 0
10. **所有 .sv 文件放在 TBL1/ 根目录**：不要放子目录
