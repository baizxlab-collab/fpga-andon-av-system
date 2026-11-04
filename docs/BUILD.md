# 加密工程构建

## 工具与工程

- TD 6.2.168116（TD 6.2.1），目标器件 EG4S20BG256。
- Python 3.9+；构建脚本仅依赖标准库。
- 从仓库根目录运行命令，项目可放在任意本机目录，建议路径使用英文。

```powershell
python -B scripts/check_release.py
python -B scripts/build.py --board A --td D:/Anlogic/TD6.2.1 --stage synth
python -B scripts/build.py --board B --td D:/Anlogic/TD6.2.1 --stage synth
python -B scripts/build.py --board C --td D:/Anlogic/TD6.2.1 --stage synth
python -B scripts/build.py --board D --td D:/Anlogic/TD6.2.1 --stage synth
```

`--stage elaborate` 检查源码解析、层次展开和约束加载；`synth` 继续运行 RTL 优化和门级映射；`bit` 继续布局布线、时序报告、DRC 和位流生成。也可设置 `TD_HOME` 替代 `--td`。

每块板的日志、初始化数据副本和结果位于 `build/A`～`build/D`。该目录被 `.gitignore` 排除。运行 `--stage bit` 后，请依据最终 routed setup/hold 报告与 DRC 检查新位流，再用于实板；仓库 `firmware/` 保留的是原配套已验证位流，不会被构建脚本覆盖。

## TD 图形界面入口

各板入口为 `boards/A/A.al`、`boards/B/B.al`、`boards/C/C.al`、`boards/D/D.al`。源文件使用相对路径，加密 HDL 位于 `rtl/`，内存初始化文件同时置于原读取位置。以上命令行脚本会为当前机器生成绝对路径的临时 `.prj`，便于复现。

## 源码保护范围

317 个工程 HDL 文件以 `.enc.vp` 交付；引用的本地头文件在加密前递归展开，一并纳入保护。对外保留引脚/时序约束、初始化数据、工程元数据与构建接口。加密使用 TD 官方 Encrypt Tool 的源码保护格式，保留 anlogic-rsa-009 编译接收密钥以及 MGC 仿真接收密钥。实际支持的仿真器版本以该厂商工具为准。

源码加密与 FPGA 配置位流加密是不同环节；本仓库没有为芯片烧写 AES 密钥或改动器件安全配置。明文源码、内部编译数据库、密钥种子和加密输入目录均不纳入仓库。
