# 600M 分支验证与使用边界

本分支保留与200M版本相同的主目录及常规验证入口，只更新600 MSPS、SSR=2所需源码。临时测试脚本、日期实验目录、输出报告和测量数据不随源码上传。

已有验证：600 MSPS数字主链路曾核对2348个复数样点，ADC/FIR/DAC对MATLAB整数模型均为0 LSB误差；全tap在线加载、CRC、边界系数与饱和测试核对1400个样点。DAC同源时钟改动完成BD校验和生成HDL核对，同源诊断仿真曾核对3366拍，包括模式切换与断流恢复。

这些记录来自工作工程已有验证。历史布局布线结果不能代表最终DAC同源配置的时序签核；本次源码整理不生成BIT。当前源码需要在目标工具环境重新生成输出、综合与布局布线后上板验收。

2026-10-10用户确认新时钟版本、冲激FIR测量的975–1425 MHz起伏约1.895 dB，对应补偿系数量化预测约0.091 dB。尚无该组补偿后实测结果。仓库PS默认MEM仍为单位冲激，板卡专用补偿系数由VNA_MAIN重新生成并手动加载。

常规流程：MATLAB MAIN MODE=1生成输入/系数 → Vivado执行validation/run_main.tcl → MATLAB MAIN MODE=2逐点比对。run_main.tcl负责设置当前仓库路径及运行时间，不使用旧电脑绝对路径。直接打开TB工程时也先执行该脚本配置。

validation/run_online.tcl与tb_online.sv验证在线加载。MATLAB test_fir_vna_export(scratch)验证硬件导出；test_fir_vna_algorithm(fft_root,scratch)是原版本保留的可选FFT算法对照，需要另提供FFT参考工程。测试输出存到仓库外scratch目录。

主工程打开adda/project/ce_fir_adda.xpr，重新生成IP/BD输出，再综合、布局布线、检查时序并生成BIT。Hardware Manager为该BIT重新生成/加载匹配的LTX；不要复用旧时钟版本的BIT或LTX。诊断信号及模式操作见DIAGNOSTIC_VIO.md。