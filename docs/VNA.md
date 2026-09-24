# 单路 VNA 校准

打开 `matlab/VNA_MAIN.m`，编辑顶部参数后点击 Run。

## 模式一：测量 bypass

`MODE=1` 生成 `matlab/vna/output/bypass/fir_coef_re.coe` 和 `fir_coef_im.coe`。实部首 tap 为 65536，其他为 0；虚部全零，即校准 FIR 的 H=1。
抽取、插值及模拟链路仍然存在，这正是随后测量的 bypass 系统。这里没有额外的 FIR 移位延迟。

在 MAIN 中选择 `vna_bypass`，运行模式一，生成仿真输入；用于测量时手动把 bypass 目录的 h_re.mem、h_im.mem 复制到 ps/src/coeff，再 Vitis Clean → Build → Run。测得复数 S21 后保存到 `matlab/vna/input/`。

## 模式二：根据实测 bypass 优化系数

`MODE=2`；设置 `cfg.measurement_file`、射频中心 `center_hz`。

- MAT：`freq_axis`（Hz）与 `vna_data`（复数 S21）。兼容 `freq`、`sdata_complex` 字段。
- CSV：三列，频率 Hz、S21 实部、S21 虚部。
- 数据要覆盖中心 ±100 MHz，频率不能重复，点数至少等于 tap 数。

按当前分支的 45/300 tap、200 MSPS、18 位 Q2.16 约束做正则化复数最小二乘拟合。目标幅频响应在 ±80 MHz 内平坦，80～100 MHz 为升余弦过渡。
保留实测整体传输延迟，补偿剩余频响；默认额外 FIR 延迟为 floor((N-1)/2) 个 200 MSPS 样本。该延迟处理仅用于 VNA 设计，不用于 MATLAB/TB 比对对齐。

`target_gain` 指定目标通带幅度；`regularization` 控制求逆正则化；`max_gain_db` 限制浮点补偿滤波器在密集频率网格上的峰值增益。限制触发时整体缩小系数并报告 scale，实际幅度目标可能无法达到。量化后的峰值和通带误差另外报告，不保证任意实测链路都可由有限 tap 精确补偿。

输出到 `matlab/vna/output/compensated/`：实部/虚部 COE 和同名 h_re.mem / h_im.mem、tap 表、拟合参数、原始/补偿/目标频响和对比图。
MAIN 模式一选择 `vna_compensated`，再走真实 IP 仿真和 MATLAB 模式二。数值比对通过后，手动复制 compensated 目录的两份 MEM 到 ps/src/coeff，再 Vitis Clean → Build → Run。

这里同时输出 COE 和 MEM，在线加载流程见 ONLINE.md；复制到 PS 的步骤由你手动完成。VNA 只处理一个通道，也不附带历史演示或其他校准功能。
