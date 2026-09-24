# 在线 FIR 系数和频点修改

## 首次准备

打开 `adda/project/ce_fir_adda.xpr`，重新综合、实现、生成 bitstream，导出包含 bit 的新 XSA。在 Vitis Classic 2023.2 更新 A53 standalone 平台，导入 `ps/src`，保留 `src/coeff` 层次。旧 bit 不含 AXI 系数从机，不能搭配新 PS 应用使用。

本轮源码验证范围见 VALIDATION.md；首次完整实现、时序与板上验证仍需完成。

## 每次换系数（与 FFT 工程一致）

1. MATLAB `MAIN.m` 的 MODE=1 在 `data/input/` 生成 `h_re.mem`、`h_im.mem`。`VNA_MAIN.m` 在 `matlab/vna/output/bypass/` 或 `compensated/` 生成同名文件。
2. **你手动把选定的一对 MEM 复制到 `ps/src/coeff/`。程序不会自动复制。**
3. Vitis Classic：Clean → Build → Run。Clean 必须执行，因为 `.incbin` 文件改变不一定触发 C 文件重编译。
4. 等待串口 `Fine NCO VIO ready` 和 `COEFF DONE`。若显示 `COEFF ERROR`，查看 `ce_coeff_result` / `ce_coeff_last_hw_error()`；未完整加载或 CRC 错误时不会启动第一路。

每份 MEM 恰好 300 个五位十六进制数，范围 00000..3FFFF，18 位二进制补码，Q2.16；按自然 tap 0..299 顺序排列。实部 10000 + 虚部 00000 的首 tap、其余为零表示 H=1。这里是时域 FIR tap，不是 FFT 工程的 2048 点频域 H。

本版本只加载第一路，第二路仍然直通。因此不需要 `h_re_2.mem` / `h_im_2.mem`。固定插值 FIR 不参与在线更新。

PS 先验证文件再发 BEGIN。BEGIN 暂停/复位第一路数据链，逐项写 staging RAM、读回核对、计算 CRC；完整性检查通过才通过四个 FIR 的 RELOAD/CONFIG 接口应用新系数并释放数据链。切换期间信号有中断，不是无缝切换。应用启动过程还会按原程序重启 RFDC。

FIR IP 固定为 Non_Symmetric、18 位系数、16 位数据、300 taps、列 150,150、Coefficient_Reload=true。即使 bypass 或虚部全零也不改结构。生成的 reload_order 为 299..0，RTL 自动倒序发送，用户不重排 MEM。两套 IP 的 AXI 输出均为48位，复数加减使用49位后右移16位并饱和。

## 每次换频点

操作见 [NCO.md](NCO.md)。Hardware Manager 使用 `vio_adc_freq` / `vio_dac_freq`，先填48位频率字和通道掩码，再翻转提交位，等完成计数增加。ADC 与 DAC 分别更新，不保证同拍；变更 RF 频点后需要对应频点的校准系数。

## 维护接口

从机地址继承 BD 的 `param_m_axi`，PS 使用 `XPAR_PARAM_M_AXI_BASEADDR`。ID=0x43465231（CFR1，防止误用 FFT 加载器）。32位对齐、全字节写；AXI响应不等待算法时钟，命令用异步FIFO跨到200MHz，PS通过BUSY轮询。

| 偏移 | 功能 |
|---|---|
| 0x00 | 只读 ID |
| 0x04 | 命令：1 BEGIN，3 SEAL，4 START，5 ABORT，6 SNAPSHOT |
| 0x08 | 状态：bit0 BUSY，bit1 LOAD，bit2 SEALED，bit3 RUNNING，bit5 ERROR，bit6 VALID |
| 0x0C | 硬件错误码 |
| 0x10 | 通道，只允许0 |
| 0x14 | tap索引，0..299，PUSH后自动递增 |
| 0x18 / 0x1C | 实部/虚部18位原码（高位清零） |
| 0x20 | 写1提交当前tap，等待BUSY清零后继续 |
| 0x24 / 0x2C | 已接收tap数 / CRC32 |
| 0x34 | 预期CRC32，SEAL前写入 |

CRC使用反射多项式EDB88320，初值FFFFFFFF，最终取反；每个tap先实部再虚部，各按零扩展32位的小端四字节计算。保留的第二通道寄存器不参与校验。

维护脚本不属于日常操作步骤，用户只用 MATLAB、Vivado 和 Vitis GUI。
