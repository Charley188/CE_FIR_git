# 迁移说明

源工程：D:/CE/CE_300tap_FIR。原文件未修改或删除。

- 以原 tb_CE_FIR 的算法 RTL、FIR/插值 XCI 和 COE 为基线；板级入口、BD、约束、时钟/调试 IP、HMC7044 网表来自原 ADDA。
- ADDA/TB 改为直接引用根目录 rtl、ip、coeff。主 TB 直接实例化上板的 adda_first_path_chain。
- 45tap 原 ADDA 的虚部输出写死 32 位，而原 TB/IP 为 16 位；采用 300tap 已有的宏位宽与符号扩展实现，移植为 45tap 配置。
- fir_ip_layout.vh 和 interp12_ip_layout.vh 改为手动维护，不依赖旧生成脚本。
- 300tap 的配对队列扩为 256 项，指针和计数宽度由深度推导；45tap 仍为 64 项。H=1 下实部/虚部不同延迟的真实 IP 测试观察到 300tap 峰值 154 项，数值比较 0 LSB。
- 保留原分支的 FIR 输出缓冲容量：45tap 为 64，300tap 为 512。
- MATLAB 仅保留主链路两模式和单路 VNA 两模式；模式二从真实 COE/输入重算定点模型，不读取预生成标准答案。无批次身份检查。
- IP/BD 使用 Global 综合，消除旧独立综合检查点依赖。缓存生成到各自工作目录，未收录旧 bit/XSA/DCP。
- 原 PS 应用源码保留，旧 Vitis 平台/构建缓存不迁移。

原始来源摘要见 source_manifest.json。Git 内只保留主工程和验证摘要；历史专项测试、runner、实验目录留在旧工程中。
