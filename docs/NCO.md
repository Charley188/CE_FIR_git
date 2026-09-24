# VIO 在线调频

本工程采用与 CE_FFT_git 相同的 Fine NCO/VIO 控制器，ADC/DAC 原始采样率均为4.8GS/s。

## 启动默认值

原 Coarse 时的频率枚举由本机 RFDC component.xml 核对。Fine 默认值保持实际工程原有的 +/-Fs/4 数字混频偏移，而不是沿用原先未生效的 NCO 字段。

| 通道 | ADC NCO | DAC NCO |
|---|---:|---:|
| 第一通道：ADC01 / DAC00 | +1.2 GHz，400000000000 | -1.2 GHz，C00000000000 |
| 第二通道：ADC23 / DAC02 | +1.2 GHz，400000000000 | -1.2 GHz，C00000000000 |

本工程原 Coarse 配置两路均为 ADC +Fs/4、DAC -Fs/4，Fine 默认值保持该偏移；第二路默认值与 FFT 参考工程不同。Fine 和 Coarse 的实际幅度/相位表现仍需板上测量。

## PS 为什么有少量改动

main.c 在原 RFDC 启动流程之后、ce_coeff_run 之前调用 ce_nco_vio_init()。
该函数只设置 NCO Update Mode 的事件源并读回确认；每次调频不经过 PS。
设置规则：(原寄存器值 & ~7) | 2，即只把低三位设为 Tile，保留其余位。

相对 RFDC 基地址的寄存器偏移：

- ADC 两路包含四个内部切片：0x1608C、0x1648C、0x1688C、0x16C8C。
- DAC 两路：0x0608C、0x0688C。

使用 16 位读写，与本机官方 xrfdc 驱动一致。依据 rfdc_v12_0/src/xrfdc_hw.h：
ADC/DAC Tile0 DRP 基址 0x16000/0x6000，物理切片步长 0x400，NCO_UPDT 偏移 0x08C，事件掩码 7，Tile 值 2。
本机生成的 ADC/DAC NCO 状态机会写 DRP 0x72E 来发出 Tile 更新事件。
生成初始化 ROM 未发现显式设置该事件寄存器的条目；本轮未上板读取原硬件默认值，因此不声称原值必定不是 2。
这里显式设置已知值以避免依赖未验证的上电状态。如果后续 PS 再重启/复位 RFDC，也须重新调用初始化。

## 使用步骤

1. 在上述 Vivado 工程重新综合、实现并生成 bitstream。当前旧 bit 不含本功能。
2. 导出新 XSA，在 Vitis Classic 更新平台并重新编译 app_seu。Debug 内旧 makefile 的绝对路径不是本轮构建入口。
3. 下载新 bit 和匹配的 probes 文件，运行应用。等待串口提示 Fine NCO VIO ready 及系数加载成功。
4. Hardware Manager 打开 vio_adc_freq 或 vio_dac_freq，将频率输出显示进制设为 Hex。
5. 先写 probe_out0 / probe_out1 的 12 位十六进制频率字，再设 probe_out2 掩码。
6. 确认 probe_in0 的 bit0/bit1 均为 0，再翻转 probe_out3（0→1 或 1→0 均可）提交一次。
7. 等待 probe_in1 完成计数增加、probe_in0 bit0 回到 0。下一次再翻转提交位。

| VIO probe | 位宽 | 含义 |
|---|---:|---|
| probe_out0 | 48 | 第一通道的 NCO 频率字 |
| probe_out1 | 48 | 第二通道的 NCO 频率字 |
| probe_out2 | 2 | 更新掩码：1=第一路，2=第二路，3=两路，0=不提交 |
| probe_out3 | 1 | 提交翻转位，默认 0 |
| probe_in0 | 4 | bit0=控制器忙；bit1=RFDC busy；bit2=超时；bit3=观察到 busy 应答 |
| probe_in1 | 16 | 已完成事务计数（复位清零，溢出回绕） |
| probe_in2 / 3 | 48 | 最近锁存的请求频率，不是 RFDC 寄存器读回 |

超时约 0.168 s（2^24 个 100 MHz 周期）；超时会继续保持负载并等待，不会误报成功。
忙碌期间提交会忽略，不排队；完成后重新翻转提交位。超时标志在下一次接受新事务时清除。

## 频率字

word = round(f_NCO / Fs * 2^48)，负数按 48 位补码编码。此接口范围为 [-Fs/2, Fs/2)。
Fs 使用 ADC/DAC 原始采样率 4800 MHz，不是抽取后的 2400 MHz，也不是 PL 的 300 MHz。

示例：+1200 MHz → 400000000000；-1200 MHz → C00000000000；0 → 000000000000。
任意频点可用可选工具 docs/maintenance/nco_word.ps1 -FrequencyMHz 1000 换算；上板操作只需 VIO，无需运行脚本。
这里输入的是带符号的 NCO 数字偏移；模拟中心频率还取决于 ADC/DAC 方向、Nyquist 区和频谱镜像，不能把 RF 频率直接不加判断地填入。


第二路仍是原 RFDC 直通，可以调频但没有第二路校准FIR。ADC/DAC不保证同拍更新，切频后需等待管线稳定并加载对应校准系数。

本轮只确认BD生成和RTL展开，未进行新的板上NCO验证。控制器与FFT参考版本一致。
