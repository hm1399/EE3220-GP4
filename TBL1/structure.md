# 项目架构文档（自动生成，请勿手动编辑）

> 最后更新：2026-02-23 14:45

## 文件清单

| 文件名 | 状态 | 说明 |
| --- | --- | --- |
| polar_common_pkg.sv | 已完成 | 共用参数包（INFO_POS, FROZEN_POS, 5个辅助函数） |
| polar64_crc16_encoder.sv | 已完成 | Polar 编码器 |
| polar64_crc16_decoder.sv | 未开始 | Polar 解码器 |
| crc.sv | 不需要 | CRC 已集成到 pkg 函数和编码器/解码器中 |
| tb_basic.sv | 已提供 | 测试平台（由课程提供，不可修改） |

## INFO_POS / FROZEN_POS（当前使用的值）

- INFO_POS = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 16, 17, 18, 19, 20, 21, 22, 24, 25, 26, 28, 32, 33, 34, 35, 36, 37, 38, 40, 41, 42, 44, 48, 49, 50, 52, 56]
- FROZEN_POS = [0, 1, 15, 23, 27, 29, 30, 31, 39, 43, 45, 46, 47, 51, 53, 54, 55, 57, 58, 59, 60, 61, 62, 63]
- dmin 验证结果：通过（min_info_row_weight = 8）

## polar_common_pkg.sv 辅助函数

| 函数名 | 说明 |
| --- | --- |
| crc16_ccitt24 | CRC-16-CCITT，24位输入→16位CRC，MSB优先，初始0x0000 |
| build_u | 从 data(24bit) 和 crc(16bit) 构造 64 位 u 向量 |
| polar_transform64 | 6 级蝶形变换，v[i+j] ^= v[i+j+half] |
| pos_tables_ok | 验证 INFO_POS ∪ FROZEN_POS = {0..63} 无重叠 |
| min_info_row_weight | 计算最小行重量，返回 8 |

## 模块：polar64_crc16_encoder

- 端口列表：clk, rst_n, start, data_in[23:0], done, codeword[63:0]
- done 延迟：恰好 +2 周期（3 级流水：pipe0→pipe1→done）
- CRC 计算方式：组合逻辑，调用 pkg 中的 crc16_ccitt24
- 蝶形变换实现：组合逻辑，调用 pkg 中的 polar_transform64
- 数据锁存：start 时将 data_in 寄存到 data_reg，编码基于 data_reg
- codeword 寄存：pipe1 有效时将组合结果寄存到 codeword 输出
- 已知问题：无

## 模块：polar64_crc16_decoder

- 端口列表：未实现
- done 延迟：未实现（要求：12 周期内）
- 解码策略：未确定
- syndrome 计算方式：未确定
- 纠错实现：未确定
- CRC 校验实现：未确定
- valid 判定逻辑：未确定
- 已知问题：无（未开始）

## 模块：CRC（如果独立存在）

- 文件名：不需要独立文件，已集成到 polar_common_pkg.sv 的 crc16_ccitt24 函数中
- 实现方式：组合逻辑 for 循环，24 次迭代移位+条件异或
- 接口：function crc16_ccitt24(input logic [23:0] data) → logic [15:0]

## 测试平台：tb_basic.sv

- 已实现的测试场景（课程提供）：
  - [x] Case A：0 位翻转
  - [x] Case B：1-3 位翻转
  - [x] Case C：4 位翻转
  - [x] 5 位翻转 fail-safe 检查
- 使用的测试数据：24'hABCDEF
- 仿真结果：未运行

## 变更历史

| 日期 | 变更内容 |
| --- | --- |
| 2026-02-22 | 初始创建，所有模块未开始 |
| 2026-02-23 | 完成 Checkpoint 1：创建 polar_common_pkg.sv，包含位置映射和5个辅助函数 |
| 2026-02-23 | 完成 Checkpoint 2：CRC-16 验证通过（已集成在 pkg 中） |
| 2026-02-23 | 完成 Checkpoint 3：创建 polar64_crc16_encoder.sv，3级流水线，done @+2 |
