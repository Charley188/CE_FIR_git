# 300tap 单路 VNA 校准：与 FFT 相同的设计方法

入口为 `matlab/VNA_MAIN.m`。MATLAB 只导出结果，复制到 `ps/src/coeff` 由你手动完成。

本分支的 VNA_MAIN 通过文件选择导入复数 S21，不依赖仓库外固定路径。使用当前 DAC 同源时钟版本、单位冲激 FIR 测量作为基线。990 点总目标延迟是 2026-10-10 测量的配置示例，换测量后需重新估计。

## 1. 测量原始 bypass

MODE=1 输出 `matlab/vna/output/bypass/`：实部首 tap 为 65536，其余为0；虚部全0。校准 FIR 的数学响应为H=1，固定插值、抽取、RFDC和模拟链路仍保留。

手动复制该目录的 `h_re.mem`、`h_im.mem` 到 `ps/src/coeff`，Vitis Clean → Build → Run，测量复数S21。

## 2. 导入测量并设计补偿

MODE=2；`cfg.measurement_file` 留空时弹窗选择文件，也可填写路径。

- MAT：`freq_axis`（Hz）、`vna_data`（复数S21）；兼容 `freq` / `sdata_complex`。
- CSV：频率Hz、S21实部、S21虚部三列，不能直接填dB/相位列。
- `center_hz` 为实际RF中心，基带频率=测量频率−中心。频谱方向不自动推断。
- 测量必须覆盖指定通带，通带内点数严格大于300；频率不重复、数据有限，通带深零点会被拒绝。

| 参数 | 默认 | 含义 |
|---|---:|---|
| 采样率 / tap数 | 600 MSPS / 300 | 保持当前SSR=2 FIR硬件配置 |
| `passband_hz` | 225 MHz | 拟合中心±225MHz内的复数响应，总通带450MHz |
| `stopband_hz` | 270 MHz | ±270～300MHz为带外约束区；必须小于Nyquist频率 |
| `target_delay_samples` | 示例990 | 示例实测延迟约840.580点，再增加149.420点；总目标1650ns |
| `regularization` | 1e-4 | 初始正则化；不满足增益/量化范围时乘10重新求解 |
| `max_gain_db` | 6 dB | 补偿滤波器的峰值增益限制 |

目标幅度取实测通带幅度中位数，不再固定追求绝对0dB。通带外加入两侧各128个约束频点，矩阵系数0.25；通带最多选4097个点求解。使用增广矩阵最小二乘，lambda=regularization×拟合点数，最多8次尝试；不再整体缩小已求出的系数。方法与 `CE_FFT_git/matlab/lib/ce_vna.m` 一致。

**目标延迟表示补偿后整体延迟，不是 FIR 新增延迟。** 总延迟包含 RFDC、FIFO 与模拟链路，可以大于 tap 数。建议先拟合单位冲激测量的相位斜率，再将约149.5点的因果FIR延迟加到测量延迟上，检查量化预测的幅相误差。990点针对示例测量设定，不自动搜索最佳延迟。

`cfg.hardware_conjugate=true`：用户已确认本600 MSPS板需要实部不变、虚部取反，MATLAB在导出边界自动处理一次。MEM、COE、taps.csv以及design.mat顶层`h/q`均为可直接加载的硬件系数，不要再手工取反。`result.h/q/hq`及预测响应保留数学设计约定；`result.h_hw/q_hw/hq_hw`保存硬件系数，`hardware_conjugated`记录变换。MAIN直接消费已导出的文件，不再共轭。

225～270MHz为未直接拟合的过渡区。带宽参数来自 `matlab/fir_config.m`；需重新测量新RFDC倍率下的bypass，不得直接套用旧200 MSPS系数。

## 3. FIR和FFT必须保留的差异

二者先求有限长度时域h。FIR直接量化300个时域tap；FFT对h补零并FFT后量化频域点。FIR仍输出300行signed18/Q2.16 MEM，硬件和PS协议未改。

增益检查采用32768点FFT的浮点峰值加时域tap量化误差L1界；FIR没有OLS量化尾部。结果中的 `peak_gain_db` 是上述网格检查界，`quantized_peak_gain` 是量化后网格峰值的线性值。

## 4. 看什么结果

`matlab/vna/output/compensated/` 包含：

- `h_re.mem` / `h_im.mem`、对应COE和 `taps.csv`。
- `design.mat`：浮点/量化系数、配置、指标和通带预测响应。
- `metrics.txt`：补偿前后纹波、整体电平偏差、最大幅度偏差、相位误差、使用的正则化与尝试次数。
- `response.csv`：七列依次为RF频率、原S21实/虚部、量化补偿预测实/虚部、目标实/虚部；仅输出拟合通带。
- `response.png`：幅度相对通带中位数，相位相对目标总延迟；指标及曲线均基于量化后的tap。

幅度不平主要看 `predicted_ripple_db`，整体偏高/偏低看 `predicted_level_offset_db`，二者不要混为一谈。满足增益限制并不等于补偿效果达标。

## 5. 验证与上板

MAIN MODE=1 选择 `vna_compensated` → Vivado主TB → MAIN MODE=2，验证数字实现。之后你手动复制补偿MEM到PS并运行应用，再测量S21确认实际改善。

本次算法测试使用合成通道，不能代替实测补偿；测试细节见 `VNA_ALGORITHM_VALIDATION.md`。未改FFT工程、RTL/IP或PS，未自动复制系数到PS。
