# FIR 单仓库、双开发目录

| 工作目录 | 开发分支 | 工程说明 |
|---|---|---|
| CE_45tap_git | fir/45tap | [45tap 入口](../../CE_45tap_git/README.md) |
| CE_300tap_git | fir/300tap | [300tap 入口](../../CE_300tap_git/README.md) |

`.repo.git/` 保存唯一的 Git 对象库和分支历史。两个目录是 Git worktree，可以同时打开使用，不要再复制工程作为新版本。

在 Git 图形客户端中分别打开这两个工作目录，各自查看修改、提交和历史。稳定版本用 tag 标记；日常在对应分支提交。不要在一个工作目录切换到另一个已经占用的分支。
共用功能的修复在一个分支验证后，通过 cherry-pick 同步对应提交到另一分支，再重新验证。不要直接把另一版本整个 IP/系数目录覆盖过来。

同一版本的 ADDA 与 TB 共用物理 RTL/IP/头文件；两个版本之间独立保存工作副本，只通过 Git 同步代码。

纳入版本管理：RTL、XCI/BD、约束、COE、MATLAB/PS 源码、XPR、说明与验证摘要。
不纳入：Vivado 缓存、bit/XSA、日常输入输出、VNA 实测文件及生成结果。重要实验数据和发布 bit/XSA 请另外归档。

远端 origin：[Charley188/CE_FIR_git](https://github.com/Charley188/CE_FIR_git)。两个开发分支均跟踪对应远端分支，稳定标签也已推送。备份时应一起保留 `.repo.git` 和两个工作目录；不要单独删除或移动 `.repo.git`。
