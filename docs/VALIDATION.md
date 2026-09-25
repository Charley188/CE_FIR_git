# 在线加载与调频验证（2026-09-24）

当前RFDC24/200 MSPS改版验证见 [RFDC24.md](RFDC24.md)。以下早期记录包含已移除的PL变采样链路，不代表当前RFDC硬核和板上测量结果。

当前FIR VNA补偿算法已改为FFT一致的方法，算法专项测试见 [VNA_ALGORITHM_VALIDATION.md](VNA_ALGORITHM_VALIDATION.md)。下列在线加载/RTL记录属于此前硬件验证。

环境：Vivado/XSim 2023.2、MATLAB R2025b、Vitis ARM GCC。

已完成：

- 接入在线加载后的真实 ADDA 主 TB 通过：28608 ADC样点、2384抽取/FIR样点、3576 DAC beats；无FIFO/背压/顺序错误。MATLAB模式二的抽取、FIR、DAC逐点误差均为0 LSB，见 `validation/main_online_result.txt`。
- FIR Compiler 两套 IP 改为可重载、非对称300tap，输出实际有效43位、AXI补齐48位。检查两份生成的 reload_order，均精确为299..0。
- `validation/tb_online.sv` 使用真实 FIR Compiler + XPM + 生产AXI控制器：非对称复数三tap、全部300tap、signed18边界值、连续两次在线换系数，1400个复数输出与整数卷积/饱和参考完全一致。
- 同一测试检查未装载START、不完整SEAL、错误CRC拒绝、恢复重新加载、RAM读回/计数/CRC及ABORT；输出 `PASS ONLINE`。
- 仿真仅在FIR持续复位16个时钟后停止其无效复位时钟；AXI、CDC和staging RAM持续运行，实际重载和数据计算使用真实IP。该选项不影响综合。
- NCO控制器源码、控制器参数及VIO接口与FFT参考工程一致；默认频点保持FIR原配置，两路均为ADC +1.2GHz、DAC -1.2GHz。Vivado BD校验/生成成功；整板RTL展开通过，无Error/Critical Warning，保留原板级普通告警。
- PS main.c、ce_coeff.c、ce_coeff_files.c 使用ARM GCC和现有FFT BSP编译通过。正式ELF需使用本工程新XSA生成的BSP；未复用旧ELF。原main.c三个未使用变量告警仍在。
- MATLAB全300tap signed18边界累加与饱和测试通过，已去除旧41位模型上限。
- MATLAB MAIN模式一输出28608个ADC样点及两份300行MEM。VNA bypass导出首tap=10000、其余0，虚部全0；运行前后PS MEM哈希一致，确认不会自动复制到PS。

本轮不包含完整综合/布局布线、时序收敛、新bit/XSA生成或板上RF/NCO测量。原固定系数版本记录如下，仅作为历史证据，不能替代本轮重载结构的验证。

---

# 验证记录（2026-09-23）

环境：Vivado/XSim 2023.2；MATLAB R2025b。原工程保留，来源清单中的原文件摘要核对一致。

已完成：

- 标准系数：真实 FIR Compiler + XPM 主链路，MATLAB 抽取、FIR、DAC 逐点比较均为 0 LSB。
- 非对称复数三 tap 激励系数（其余 tap 为零）：真实 IP，实部/虚部 TDATA 均为 32 位，逐点比较 0 LSB。
- H=1 bypass：真实 IP 主链路及 MATLAB 比对 0 LSB；配对队列峰值 154 项。300tap 配对队列已从 64 扩为 256 项，能够承接实部/虚部 309/156 周期的延迟差。
- MATLAB 比较器：独立结果副本注入 1 LSB 错误和 DAC lane 错误，均被拒绝。
- VNA：单位冲激导出，以及已知复数增益/12 ns 延迟的合成 MAT/CSV 测量输入，两个格式得到一致结果。合成数据只用于开发验证，不是实测校准证据。
- ADDA：BD 验证/生成及 RTL 展开通过，无 Error/Critical Warning；保留原板级/IP 的普通告警（690 条）。不依赖原工程 OOC 检查点。
- ADDA/TB 的直接引用无缺失、无旧工程路径，共用 16 个 RTL/头文件，见 validation/reference_audit.json。

标准配置：18 位整数 COE（Q2.16），16 位输入；实部 TDATA 40 位，虚部全零 TDATA 16 位。
非对称测试：实部 [49152,8192,-4096]，虚部 [8192,-2048,1024]，补零到当前 tap 数；该测试先于 300tap 配对队列扩容，扩容后的 H=1 和最终标准配置另外验证。

细分证据见 validation/ 下的比较摘要和 TB 完成状态。

本记录不等价于完整综合/布局布线、时序收敛、bit/XSA 生成或上板测量通过。第二路 RFDC 直通及模拟链路未在主 TB 中验证。VNA 实测补偿仍需你测得 bypass 后验证。
