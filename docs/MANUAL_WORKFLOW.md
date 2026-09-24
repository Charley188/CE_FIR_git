# 手动操作流程

日常只需 MATLAB、Vivado、Vitis Classic 的图形界面。

1. 打开 `matlab/MAIN.m`，设置 MODE=1 并 Run。standard 生成标准低通；current 读取 `coeff/` 的现有 COE；vna_bypass / vna_compensated 选择 VNA 输出。生成 ADC 输入和自然顺序的300tap `data/input/h_re.mem`、`h_im.mem`。
2. 打开 `tb/ce_fir_tb.xpr`，Run Behavioral Simulation。主 TB 通过 AXI 加载上述 MEM，再运行真实抽取/FIR/插值数据链。等待 `PASS MAIN`。
3. MATLAB MODE=2 并 Run，比较 `data/output/` 的抽取、FIR和DAC结果。
4. 要上板时，你手动复制选定的两份 MEM 到 `ps/src/coeff`，Vitis Clean → Build → Run。首次新硬件准备及详细步骤见 [ONLINE.md](ONLINE.md)。MATLAB 不自动复制到PS。
5. 要调频时，按 [NCO.md](NCO.md) 操作 VIO。

改变300tap校准系数无需重新定制FIR IP或修改位宽头文件。IP固定为可重载非对称结构；不要因虚部全零或 bypass 再启用对称优化。改变tap数量、数据/系数位宽或插值结构属于硬件修改，需要重新生成bit/XSA。

仿真默认仅对校准FIR的稳定复位期暂停IP时钟以加快装载阶段；AXI、CDC、RAM照常运行。该宏不用于综合。维护时移除 sim_1 的 CE_SIM_FAST_RESET 可使用完整复位时钟。

系数、输入和输出由使用者选择，不做批次身份自动识别。重新运行仿真前关闭上一轮仿真。
