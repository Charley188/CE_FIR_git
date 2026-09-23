# FIR 300tap 开发工程

Git 分支：`fir/300tap`。与另一 tap 分支共用仓库历史，各自拥有独立工作目录、IP 和数据。

| 打开入口 | 用途 |
|---|---|
| [adda/project/ce_fir_adda.xpr](adda/project/ce_fir_adda.xpr) | 上板工程 |
| [tb/ce_fir_tb.xpr](tb/ce_fir_tb.xpr) | 实际 ADDA 主链路仿真 |
| [matlab/MAIN.m](matlab/MAIN.m) | 模式一生成系数/输入，模式二定点仿真并比对 |
| [matlab/VNA_MAIN.m](matlab/VNA_MAIN.m) | 单路 bypass / 补偿系数生成 |

日常流程：MATLAB 模式一 → 系数改变时用 Vivado GUI 更新 IP 并核对位宽头文件 → Vivado 主 TB 仿真 → MATLAB 模式二。

- [完整手动操作说明](docs/MANUAL_WORKFLOW.md)
- [VNA 校准说明](docs/VNA.md)
- [定点链路与验证边界](docs/MODEL.md)
- [验证结果](docs/VALIDATION.md)

`rtl/`、`ip/`、`coeff/` 在本版本的 ADDA/TB 间共用。`rtl/fir_ip_layout.vh` 手动维护，填写生成后真实 AXI 端口位宽；`interp12_ip_layout.vh` 管插值 IP。
`data/input/` 和 `data/output/` 是自动衔接目录，无需搬运数据，也不检查批次身份。

保留原版 `ps/src/`，在 Vitis 中配合重新导出的 XSA 使用。FIR 系数固化在 IP，修改系数后上板需要重新生成 bitstream。

工具基线：Vivado 2023.2，器件 xczu47dr-ffve1156-2-i；MATLAB R2025b（标准 300tap 设计用到 Signal Processing Toolbox 的 freqz）。
源码来源与迁移前摘要记录在 docs/source_manifest.json；旧工程未删除。仿真缓存、综合产物和日常交换数据不纳入 Git。
