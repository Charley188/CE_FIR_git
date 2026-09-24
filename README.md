# FIR 300tap 开发工程

Git 分支：`fir/300tap`。与另一 tap 分支共用仓库历史，各自拥有独立工作目录、IP 和数据。

| 打开入口 | 用途 |
|---|---|
| [adda/project/ce_fir_adda.xpr](adda/project/ce_fir_adda.xpr) | 上板工程 |
| [tb/ce_fir_tb.xpr](tb/ce_fir_tb.xpr) | 实际 ADDA 主链路仿真 |
| [matlab/MAIN.m](matlab/MAIN.m) | 模式一生成系数/输入，模式二定点仿真并比对 |
| [matlab/VNA_MAIN.m](matlab/VNA_MAIN.m) | 单路 bypass / 补偿系数生成 |

仿真流程：MATLAB 模式一生成 MEM/输入 → Vivado 主 TB 在线加载并仿真 → MATLAB 模式二。

上板流程与 FFT 工程一致：MATLAB 生成 `h_re.mem`、`h_im.mem` → **你手动复制到 `ps/src/coeff`** → Vitis Classic Clean → Build → Run。ADC/DAC 频点通过 VIO 修改，见 [在线操作说明](docs/ONLINE.md)。

- [完整手动操作说明](docs/MANUAL_WORKFLOW.md)
- [VNA 校准说明](docs/VNA.md)
- [定点链路与验证边界](docs/MODEL.md)
- [验证结果](docs/VALIDATION.md)

`rtl/`、`ip/`、`coeff/` 在本版本的 ADDA/TB 间共用。校准 FIR 固定为可重载、非对称、300 tap，`rtl/fir_ip_layout.vh` 的实部/虚部 AXI 位宽均为 48；`interp12_ip_layout.vh` 管插值 IP。
`data/input/` 和 `data/output/` 是自动衔接目录，无需搬运数据，也不检查批次身份。

首次重新生成 bitstream 并导出匹配 XSA，在 Vitis 中更新平台并导入 `ps/src/`。此后仅修改校准 FIR 系数或通过 VIO 调频不需要重做 bit；修改 tap 数、位宽、抽取/插值结构仍需重建硬件。第二路保持 RFDC 直通，不新增第二路校准 FIR。

工具基线：Vivado 2023.2，器件 xczu47dr-ffve1156-2-i；MATLAB R2025b（标准 300tap 设计用到 Signal Processing Toolbox 的 freqz）。
源码来源与迁移前摘要记录在 docs/source_manifest.json；旧工程未删除。仿真缓存、综合产物和日常交换数据不纳入 Git。
