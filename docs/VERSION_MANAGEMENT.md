# 分支与目录

同一仓库 https://github.com/Charley188/CE_FIR_git ：

| 分支 | 配置 |
|---|---|
| fir/45tap | 历史45tap工程 |
| fir/300tap | 200 MSPS、300tap工程 |
| 600M | 600 MSPS、300tap、SSR=2、DAC同源算法时钟 |

600M沿用200M的主目录：adda、coeff、data、docs、ip、matlab、ps、rtl、tb、validation。各分支独立克隆或checkout，避免混用IP输出、BIT/LTX/XSA、ELF及板卡系数。

仓库保存RTL、BD/XCI、工程入口、默认系数和常规操作文档。Vivado/Vitis缓存、综合实现结果、临时测试工程、日志、报告、波形、测量和生成的补偿系数由本机保留，通过.gitignore排除。

主工程入口为adda/project/ce_fir_adda.xpr；重新生成输出后综合和实现。PS默认单位冲激MEM适合重新测量，具体板卡补偿由VNA_MAIN生成、手动复制，再Vitis Clean → Build → Run。