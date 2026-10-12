# FIR 300tap 开发工程

当前数据通路：RFDC 8倍抽取/插值，PL 600 MSPS，300 MHz 每拍两个复数样本（SSR=2）；配置、资源和验证见 [SSR600说明](docs/SSR600.md)。默认总通带450 MHz。

Git 分支：`600M`。200 MSPS 版本保留在 `fir/300tap`，本分支保持相同的主目录结构。

算法时钟 `clk_300M` 与 `clk_dac0` 在 BD 中连接同一个 `clk_wiz_dac/clk_out1`；`clk_300m_locked` 对应 DAC Clock Wizard 的 `locked`。模式 VIO、算法 ILA 和系数控制器一起使用该时钟。操作及诊断位定义见 [DIAGNOSTIC_VIO.md](docs/DIAGNOSTIC_VIO.md)。

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

`rtl/`、`ip/`、`coeff/` 在本版本的 ADDA/TB 间共用。校准 FIR 固定为可重载、非对称、300 tap、SSR=2；`rtl/fir_ip_layout.vh` 的48位是每个实数输出样本的AXI补齐宽度，每个实数FIR总输出96位。原PL插值IP不再参与活动工程。
`data/input/` 和 `data/output/` 是自动衔接目录，无需搬运数据，也不检查批次身份。

首次重新生成 bitstream 并导出匹配 XSA，在 Vitis 中更新平台并导入 `ps/src/`。此后仅修改校准 FIR 系数或通过 VIO 调频不需要重做 bit；修改 tap 数、位宽、抽取/插值结构仍需重建硬件。第二路保持 RFDC 直通，不新增第二路校准 FIR。

工具基线：Vivado 2023.2，器件 xczu47dr-ffve1156-2-i；MATLAB R2025b（标准 300tap 设计用到 Signal Processing Toolbox 的 freqz）。
本分支只保存主干工程和可复现的验证入口。构建缓存、实验备份、测量数据、生成的 VNA 系数和 BIT/LTX/XSA 不纳入 Git。PS 默认 MEM 为单位冲激；具体板卡的补偿系数由 VNA_MAIN 生成后手动加载。
