# 项目架构文档（自动生成，请勿手动编辑）

> 最后更新：2026-02-23 17:00

## 文件清单

| 文件名 | 状态 | 说明 |
| --- | --- | --- |
| team_4_submission/polar_common_pkg.sv | 已完成 | 共用参数包（INFO_POS, FROZEN_POS, 5个辅助函数） |
| team_4_submission/polar64_crc16_encoder.sv | 已完成 | 编码器，done @+2 周期 |
| team_4_submission/polar64_crc16_decoder.sv | 已完成 | 解码器，done @+2 周期，列syndrome有界距离解码 |
| team_4_submission/run_sim.sh | 已完成 | Vivado xsim 一键仿真脚本（Linux/macOS） |
| team_4_submission/run_sim.bat | 已完成 | Vivado xsim 一键仿真脚本（Windows） |
| tb_basic.sv | 已提供 | 公开 smoke 测试平台（不修改） |
| structure.md | 已完成 | 本文档 |
| log.txt | 已完成 | AI 使用日志 |
| ai_log.txt | 已完成 | 最终提交版 AI 日志 |
| README.md | 已完成 | 编译运行说明 |

## INFO_POS / FROZEN_POS（当前使用的值）

- INFO_POS = [2,3,4,5,6,7,8,9,10,11,12,13,14,16,17,18,19,20,21,22,24,25,26,28,32,33,34,35,36,37,38,40,41,42,44,48,49,50,52,56]
- FROZEN_POS = [0,1,15,23,27,29,30,31,39,43,45,46,47,51,53,54,55,57,58,59,60,61,62,63]
- dmin 验证结果：通过（min_info_row_weight = 8，对应 popcount(i) <= 3 的最大 popcount=3，2^(6-3)=8）

## 模块：polar64_crc16_encoder

- 端口列表：clk, rst_n, start, data_in[23:0], done, codeword[63:0]
- done 延迟：恰好 +2 周期（pipe0→pipe1→done 三级移位寄存器）
- CRC 计算方式：组合逻辑（always_comb 中调用 crc16_ccitt24 函数）
- 蝶形变换实现：组合逻辑（always_comb 中调用 polar_transform64 函数）
- 流水线：data_reg 在 start 时锁存 data_in；pipe1 时将 cw_comb 寄存到 codeword
- 已知问题：无

## 模块：polar64_crc16_decoder

- 端口列表：clk, rst_n, start, rx[63:0], done, data_out[23:0], valid
- done 延迟：恰好 +2 周期（pipe0→pipe1→done 三级移位寄存器）
- 解码策略：列 syndrome 有界距离解码（BDD，t=3）
  - Step 1：对 rx_reg 施加 polar_transform64（自逆，即逆变换）
  - Step 2：提取冻结位位置的值，构成 24-bit syndrome
  - Step 3：搜索权重 1/2/3 的错误模式，使其列 syndrome 的 XOR 等于当前 syndrome
  - Step 4：对 (rx_reg XOR err_pat) 再次施加 polar_transform64，强制冻结位为 0
  - Step 5：提取 data_out[23-k]=u_final[INFO_POS[k]]，crc_rx[15-k]=u_final[INFO_POS[24+k]]
  - Step 6：重新计算 CRC，与提取的 crc_rx 比较
- syndrome 计算方式：syndrome[k] = u_hat[FROZEN_POS[k]]，for k=0..23
- 纠错实现：COL_SYN 64元素查找表（localparam），逐级权重搜索（1→2→3）
- CRC 校验实现：组合逻辑调用 crc16_ccitt24 函数
- valid 判定逻辑：correctable && (crc_calc == crc_rx)
- 已知问题：verilator 对 always_comb 内部局部 logic 声明可能报 LATCH 警告（与工具版本有关），功能正确，Python 全案例验证通过

## 模块：CRC

- 文件名：已集成到 polar_common_pkg.sv 中（函数 crc16_ccitt24）
- 实现方式：串行移位，24 次循环（MSB 先，多项式 0x1021，初始 0x0000）
- 接口：function automatic logic [15:0] crc16_ccitt24(input logic [23:0] data)

## 测试平台：tb_basic.sv

- 已实现的测试场景：
  - [x] Case A：0 位翻转（valid=1, data 正确）
  - [x] Case B：1/2/3 位翻转（valid=1, data 正确）
  - [x] Case C：4 位翻转（valid=0）
  - [x] Case D：5 位翻转 fail-safe（valid=1 时 data 必须正确）
  - [x] 编码器 done 时序（恰好 +2 周期）
  - [x] 解码器 done 时序（12 周期内）
- 使用的测试数据：data_in = 24'hABCDEF
- 仿真结果：Python 镜像仿真 SMOKE score = 30/30（全部通过）；待 Vivado xsim 实际运行确认

## 变更历史

| 日期 | 变更内容 |
| --- | --- |
| 2026-02-23 14:30 | 创建 polar_common_pkg.sv（Checkpoint 1/2） |
| 2026-02-23 14:45 | 创建 polar64_crc16_encoder.sv（Checkpoint 3） |
| 2026-02-23 15:30 | 修复 polar_transform64 方向 + 创建 polar64_crc16_decoder.sv（Checkpoint 4） |
| 2026-02-23 16:00 | 修复 decoder always_comb latch + 创建 run_sim.sh（Checkpoint 5） |
| 2026-02-23 17:00 | 更新 structure.md, log.txt, README.md, ai_log.txt（Checkpoint 6） |
