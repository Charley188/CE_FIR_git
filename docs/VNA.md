# 300tap 单路 VNA 校准：与 FFT 相同的设计方法

入口为 `matlab/VNA_MAIN.m`。MATLAB 只导出结果，复制到 `ps/src/coeff` 由你手动完成。

当前板卡约定：VNA 流程在导出前自动对抽头共轭一次，即实部不变、虚部取反。MEM、COE、taps.csv 和 design.mat 顶层 h/q 均是可直接加载的硬件系数，不要再手动取反。MODE=1 的实数单位冲激不受影响。

## 1. 测量原始 bypass

MODE=1 输出 `matlab/vna/output/bypass/`：实部首 tap 为 65536，其余为0；虚部全0。校准 FIR 的数学响应为H=1，固定插值、抽取、RFDC和模拟链路仍保留。

手动复制该目录的 `h_re.mem`、`h_im.mem` 到 `ps/src/coeff`，Vitis Clean → Build → Run，测量复数S21。

## 2. 导入测量并设计补偿

MODE=2；`cfg.measurement_file` 留空时弹窗选择文件，也可填写路径。

- MAT：`freq_axis`（Hz）、`vna_data`（复数S21）；兼容 `freq` / `sdata_complex`。
- CSV：频率Hz、S21实部、S21虚部三列，不能直接填dB/相位列。
- `center_hz` 为实际RF中心，基带频率=测量频率−中心。频谱方向不自动推断。
- 当前流程固定在导出时执行板卡共轭约定，不自动识别其他板卡的方向；输入仍须是 H=1 bypass 实测，不能直接替换为补偿后的实测。
- 测量必须覆盖指定通带，通带内点数严格大于300；频率不重复、数据有限，通带深零点会被拒绝。

| 参数 | 默认 | 含义 |
|---|---:|---|
| 采样率 / tap数 | 200 MSPS / 300 | 保持当前FIR硬件配置 |
| `passband_hz` | 80 MHz | 拟合中心±80MHz内的复数响应 |
| `stopband_hz` | 90 MHz | ±90～100MHz为带外约束区；必须小于Nyquist频率 |
| `target_delay_samples` | 当前测量 596 | 补偿后整体响应的目标延迟；约 447 点实测链路延迟加 149 点 FIR 延迟 |
| `regularization` | 1e-4 | 初始正则化；不满足增益/量化范围时乘10重新求解 |
| `max_gain_db` | 当前测量 8 dB | 补偿滤波器的峰值增益限制；需检查 DAC 输出余量 |

目标幅度取实测通带幅度中位数，不再固定追求绝对0dB。通带外加入两侧各128个约束频点，矩阵系数0.25；通带最多选4097个点求解。使用增广矩阵最小二乘，lambda=regularization×拟合点数，最多8次尝试；不再整体缩小已求出的系数。方法与 `CE_FFT_git/matlab/lib/ce_vna.m` 一致。

**延迟语义与FFT一致：不自动去除测量的整体延迟，配置值是补偿后的总目标延迟。** 当前 bypass 测量在 200 MSPS 下约有 447 点链路延迟，因此设为 596 点；总延迟可以大于 FIR 的 300 tap，但相对于实测链路增加的延迟仍应落在 FIR 的可实现范围。原 149 点目标会要求 FIR 提前近 298 点，预测输出几乎为零。当前实现不自动搜索最佳延迟；更换测量或硬件后需重新估算，并检查结果。

80～90MHz为未直接拟合的过渡区，不再指定原版本的升余弦过渡目标。

## 3. FIR和FFT必须保留的差异

二者先求有限长度时域h。FIR直接量化300个时域tap；FFT对h补零并FFT后量化频域点。FIR仍输出300行signed18/Q2.16 MEM，硬件和PS协议未改。

增益检查采用32768点FFT的浮点峰值加时域tap量化误差L1界；FIR没有OLS量化尾部。结果中的 `peak_gain_db` 是上述网格检查界，`quantized_peak_gain` 是量化后网格峰值的线性值。

## 4. 看什么结果

`matlab/vna/output/compensated/` 包含：

- `h_re.mem` / `h_im.mem`、对应COE和 `taps.csv`。
- `design.mat`：顶层 h/q 及 result.h_hw/q_hw/hq_hw 为已共轭硬件系数；result.h/q/hq 为原数学设计系数，result.hardware_conjugated=true 标记已执行转换。
- `metrics.txt`：补偿前后纹波、整体电平偏差、最大幅度偏差、相位误差、使用的正则化与尝试次数。
- `response.csv`：七列依次为RF频率、原S21实/虚部、量化补偿预测实/虚部、目标实/虚部；仅输出拟合通带。
- `response.png`：幅度相对通带中位数，相位相对目标总延迟；指标及曲线基于量化后的数学设计系数，并标为 Design-domain prediction。上板映射采用导出共轭约定；曲线不是完整 RFDC 模型或实测保证。

幅度不平主要看 `predicted_ripple_db`，整体偏高/偏低看 `predicted_level_offset_db`，二者不要混为一谈。满足增益限制并不等于补偿效果达标。

## 5. 验证与上板

MAIN MODE=1 选择 `vna_compensated` → Vivado主TB → MAIN MODE=2，验证数字实现。之后你手动复制补偿MEM到PS并运行应用，再测量S21确认实际改善。

VNA导出共轭仅用于适配VNA/MATLAB与FPGA的频率方向约定，不用于修正TB与MATLAB之间的差异。TB与MATLAB定点参考始终使用同一份系数和标准复数运算，逐点比较时不额外共轭、翻转频率或交换I/Q。

MAIN 直接使用已导出的硬件 COE 做定点参考和 TB 输入，不再次共轭。导出一致性回归入口为 `validation/test_fir_vna_export.m`，覆盖 MEM/COE/CSV/MAT、重复导出、MAIN 衔接和 bypass。

本次算法测试使用合成通道，不能代替实测补偿；测试细节见 `VNA_ALGORITHM_VALIDATION.md`。未改FFT工程、RTL/IP或PS，未自动复制系数到PS。
