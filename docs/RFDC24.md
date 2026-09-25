# RFDC 24x / PL 200 MSPS

本版本 ADC、DAC 均为 4.8 GSPS，RFDC 内部抽取/插值均为 24x。
ADC 每个 I/Q 分量端口为 16bit；DAC 为 32bit，每拍 `{Q,I}` 一个复数样本。
外部参考时钟保持 300 MHz，RFDC Clock Out 保持 300 MHz；ADC、DAC Clocking Wizard 输出改为 200 MHz。
旧的冗余 clk_300M 外部端口已移除，数据时钟使用 clk_adc0 / clk_dac0。
FIR 算法时钟仍为独立的 200 MHz，ADC→FIR、FIR→DAC 均保留异步 FIFO。
板上时钟必须同源锁定；有限深度 FIFO 不能消除独立振荡器的长期频差。

## PL 数据通路

第一路：ADC I/Q → 32bit异步FIFO → 300tap复数FIR → 32bit异步FIFO → DAC。
第二路：ADC I/Q → 32bit异步FIFO → DAC，严格按 valid/ready 传输。
移除活动工程中的 PL /12 抽取、3×2×2 插值、384bit块FIFO、12转8 gearbox 和旧DAC CDC。
旧文件保留作为历史参考，不参与活动工程编译。ILA 保留原 IP，只有 probe0(I) 和 probe8(Q) 有效，原其他样本通道置零。
FIFO预填充4点后开始消费；复位和系数重载期间允许数据中断，验证连续吞吐须在运行状态进行。

## MATLAB 与验证

MATLAB MAIN mode 1/2 现在模拟 RFDC 输出到 RFDC 输入之间的 PL 链路，输入文件为 input_200_i.txt/input_200_q.txt。
不再对输入进行12倍构造或对输出进行12倍插值。参考输出为300tap定点复数卷积，包含Q2.16截断和16bit饱和。
仿真输出 adc.txt、fir.txt、dac.txt、dac_beats.txt；每个DAC beat为一个复数样本。
这不包含 RFDC 内部滤波器或模拟链路；新硬件必须重新测量 bypass，再生成补偿系数。
VNA采样率保持200 MSPS，系数格式和PS手动复制流程不变。

保存并关闭 Vivado GUI 工程后，可通过 docs/maintenance/enable_rfdc24.tcl 重建BD/Wrapper并检查顶层。
validation/run_main.tcl 运行真实 FIR IP 仿真并检查第二路逐点直通。
设置环境变量 CE_TB_OPTIONS=-testplusarg CONTINUOUS 可检查两路持续每拍输入；默认随机DAC反压。
仿真后运行 MATLAB MAIN mode 2 验证每个输出样本。
硬件更新需要重新生成bitstream/XSA并更新Vitis硬件平台。

## 本次验证记录（2026-09-24）

- Vivado 2023.2 BD Validate通过；保存后的clk_adc0、clk_dac0、clk_200M均为200 MHz，ADC AXI每端口2字节，DAC每端口4字节。
- 完整sys_top RTL elaboration通过，0 Errors / 0 Critical Warnings；这不是布局布线时序收敛或bitstream验证。
- 真实FIR Compiler IP、AXI在线加载300tap，随机DAC反压：2347点完整传输；第二路逐点直通正确，停顿时输出保持。
- 连续流：2347点完整传输，两路启动后每拍接收；第一路和第二路输出均无中途空拍。
- MATLAB定点比较结果见data/output/comparison.txt；连续流独立输出在验证临时目录。全部ADC/FIR/DAC序列必须达到0 LSB误差。
- 第一、二路计数与排空检查通过；未进行模拟RFDC内部滤波器仿真和实板测试。
- 保留AWUSER/ARUSER转换告警，以及厂商生成ILA/XPM未使用端口等告警。RFDC生成文件含3bit默认倍率只读信息字段的24截断告警；这些常量用于配置读回信息，不修改厂商生成代码。新XSA上板后仍需用RFDC驱动确认实际抽取/插值倍率为24，不能用PL仿真推断硬核配置已生效。

工程外验证日志：D:/CE/rfdc24_project.log、rfdc24_sim.log、rfdc24_matlab_compare.log、rfdc24_cont.log、rfdc24_cont_matlab.log。
