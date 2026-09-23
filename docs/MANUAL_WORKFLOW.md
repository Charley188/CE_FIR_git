# 手动操作流程

日常只需 MATLAB 和 Vivado 的图形界面。工程已建好，不需要运行 Python、PowerShell 或 Tcl。

## 1. MATLAB 生成输入

打开本工作目录的 `matlab/MAIN.m`，设置 `MODE=1`，点击 Run。

- `COEFFICIENT_SOURCE='standard'`：重新生成当前分支的标准升余弦低通系数。
- `current`：使用已经放在 `coeff/` 的系数，不覆盖它们。
- `vna_bypass` / `vna_compensated`：使用 VNA_MAIN 输出的对应 COE。
- `BASE_SAMPLES`：200 MSPS 域的激励长度，默认 2048。
- `AMPLITUDE_LSB`：激励幅度；插值后超出 signed16 时程序报错，调低后重跑。

模式一直接写入 `coeff/fir_coef_re.coe`、`coeff/fir_coef_im.coe`，以及 `data/input/input_2400_i.txt`、`input_2400_q.txt`、`config.txt`。尾部零样本包含 FIR 和插值冲刷区间，无需自己补零。
插值 COE 沿用已验证的三个固定滤波器。它们也是 MATLAB 模式二实际读取的系数。

## 2. 修改系数后，在 Vivado 更新 IP

打开 `tb/ce_fir_tb.xpr`。同一 tap 版本的 ADDA 工程先关闭，避免两个 Vivado 窗口同时保存同一 XCI；45tap 和 300tap 互不影响，可以同时使用。

在 Sources/IP Sources 中分别双击 `fir_coef_re`、`fir_coef_im`，重新选择本工程 `coeff/` 的对应 COE，确认 IP 配置后点击 OK，再 Generate Output Products，选择 Global 综合方式。板级 BD 同样使用 Global，避免依赖旧 OOC 检查点。
如果从标准低通切到非对称补偿，先在同一配置界面把列配置调整到适合新系数的值；若旧 COE 没有被重新解析，可先将系数源切换到 Vector，再切回 COE File 并重新选择文件。
即使 COE 路径没变，也要重新加载文件并确认配置，不能只改磁盘 COE 后直接使用旧 IP 输出产物。

保留以下配置：

| 项目 | 值 |
|---|---|
| 输入数据 | signed 16，整数 |
| 系数 | signed 18，Integer Coefficients |
| IP 系数小数位 | 0（COE 中存的是已乘 65536 的整数） |
| 系数结构 | Inferred，根据当前文件推断 |
| 输出 | Full Precision |
| Coefficient Reload | 关闭 |
| 数据/时钟频率 | 200 MHz / 200 MHz |

Q2.16 的缩放在生产 RTL 中右移 16 位完成；不要同时把 IP 系数小数位改成 16。

### 300tap 的 DSP 列配置

对实部、虚部 IP 分别判断各自的整数系数是否首尾对称。MATLAB 模式一会打印判断结果。

- 对称（包括全零虚部）：Multi-Column Support = Custom，Column Configuration = `150`。
- 非对称：Multi-Column Support = Custom，Column Configuration = `150,150`。

标准低通通常实部对称、虚部全零；VNA 复数补偿通常非对称；H=1 的首 tap 单位冲激也不是首尾对称。
45tap 继续使用 Automatic 列配置。

## 3. 手动核对位宽头文件

生成 IP 后查看各 IP 的 Verilog 实例化模板或生成的端口声明（在 IP Sources 下，或对应 `ip/<名字>/generated/` 目录）。找到 `m_axis_data_tdata`。

| 生成端口范围 | 对应宏 |
|---|---|
| 实部 `[39:0]` | FIR_RE_TDATA_WIDTH 40 |
| 虚部 `[15:0]` | FIR_IM_TDATA_WIDTH 16 |
| 虚部 `[31:0]` | FIR_IM_TDATA_WIDTH 32 |

直接编辑 `rtl/fir_ip_layout.vh`。宏表示实际 AXI TDATA 位宽，不是未经字节补齐的算术有效位宽。
ADDA/TB 共用这一个文件。宏不会改变 IP，只负责匹配它。

当前复数乘加支持单个 FIR 输出端口 16～40 位，统一符号扩展到 41 位再加减。修改系数后还要查看 IP 的 Latency：

- 45tap 输出缓冲为 64 项，300tap 为 512 项；应留有流水线余量。
- 四支 FIR 的结果配对队列：45tap 为 64 项，300tap 为 256 项；实部/虚部延迟差分别应小于 60 / 252 周期，保持余量。300tap 的 H=1 实部与全零虚部可能相差 153 周期，已由扩容后的配对队列承接。
- 若超出范围，停止使用该配置，需要重新评估缓冲和实现，不能只改宏。

`rtl/interp12_ip_layout.vh` 管三个插值 IP 的字段宽度、并行度和延迟。默认不修改插值配置；若改变它们，必须同步核对该头文件以及包装器中的抽头数/延迟常量。

## 4. Vivado 主链路仿真

点击 Run Simulation → Run Behavioral Simulation。工程默认运行到 TB 自行结束。修改过 RTL/IP 后关闭旧仿真再重新启动，确保重新编译。

TB 直接实例化 ADDA 生产模块 `adda_first_path_chain`，使用真实 FIR Compiler 和 XPM FIFO。输入和输出目录已经设置好，无需复制文件。

结果写到 `data/output/`：

- `decimator.txt`、`fir.txt`、`dac.txt`：每行 `sample_index I Q`，索引从 0 开始。
- `dac_beats.txt`：每行 `beat_index I0 Q0 ... I7 Q7`。
- `tb_status.txt`：开始为 RUNNING，正常完成为 PASS 和计数。

TB 检查 FIFO 故障、未知值、I/Q 成对接收、DAC 背压稳定性和样本数量。它不读取 MATLAB 标准答案。TB PASS 表示链路和计数检查通过，数值准确性由下一步判断。

## 5. MATLAB 定点仿真和比对

将 `MAIN.m` 的 `MODE` 改成 2，点击 Run。

模式二从 `coeff/` 读真实整数系数，从 `data/input/` 读同一套输入，运行定点模型，然后读取 `data/output/`。分别比较抽取、FIR、DAC 的整数样本，并检查 DAC lane 顺序。

输出 `comparison.txt`、`comparison.mat`、`comparison.png`。不做自动增益/相位/时间平移；任何非零 LSB 误差会报告失败，仍保留统计和图像便于定位。
没有批次 ID、哈希或时间戳检查，你自行判断输入与结果是否对应。PASS 状态仅用于判断 TB 是否完整运行，不能证明结果属于当前这批输入。

## 6. 上板

关闭本版本 TB 工程，打开 `adda/project/ce_fir_adda.xpr`。确认共享 IP 已更新、位宽头文件正确，然后在 GUI 中重新综合、实现、生成 bitstream 并导出含 bitstream 的 XSA。

PS 源码位于 `ps/src/`；在 Vitis 中基于新 XSA 建立平台和应用。当前 FIR 不支持通过 PS 在线重载系数，改变 COE 后需要新的硬件产物。

## 路径与恢复

两个工作目录分别保存各自数据和缓存。MATLAB 根据 MAIN.m 所在位置定位根目录，不依赖 MATLAB 当前目录。
Vivado 的 Simulation Settings → Simulation → xsim.simulate.xsim.more_options 已设置 INPUT_DIR/OUTPUT_DIR 的绝对路径。若移动整个工作目录，在 GUI 中把这两个路径改到新目录。
`coeff/presets/` 是迁移时的基准系数备份；实际 IP/MATLAB 只引用 `coeff/` 根目录的五个 COE。
