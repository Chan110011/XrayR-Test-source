# XrayR-Test-source

这是基于 XrayR 源码构建的自用 release 仓库，当前主要提供 **Linux 64-bit / amd64** 安装包和官方风格一键脚本。

## 一键安装

默认安装最新 Release：

```bash
bash <(curl -Ls https://raw.githubusercontent.com/Chan110011/XrayR-Test-source/main/install.sh)
```

指定安装 `v0.9.5`：

```bash
bash <(curl -Ls https://raw.githubusercontent.com/Chan110011/XrayR-Test-source/main/install.sh) v0.9.5
```

备用写法：

```bash
wget -N https://raw.githubusercontent.com/Chan110011/XrayR-Test-source/main/install.sh && bash install.sh v0.9.5
```

## 管理命令

安装完成后会生成官方风格管理脚本：

```bash
XrayR
```

常用命令：

```bash
XrayR start      # 启动
XrayR stop       # 停止
XrayR restart    # 重启
XrayR status     # 查看状态
XrayR log        # 查看日志
XrayR update     # 更新
XrayR uninstall  # 卸载
XrayR version    # 查看版本
```

同时支持小写命令：

```bash
xrayr
```

## 重要说明

- 当前 Release 只构建并提供：

```text
XrayR-linux-64.zip
```

- 因此一键脚本目前只适合：

```text
Linux x86_64 / amd64
```

- 如果服务器是 `arm64 / aarch64`，脚本会尝试下载：

```text
XrayR-linux-arm64-v8a.zip
```

但当前仓库没有提供这个包，会导致下载失败。

- 安装目录：

```text
/usr/local/XrayR/
```

- 配置目录：

```text
/etc/XrayR/
```

- systemd 服务文件：

```text
/etc/systemd/system/XrayR.service
```

- 配置文件：

```text
/etc/XrayR/config.yml
```

- 查看运行日志：

```bash
journalctl -u XrayR.service -e --no-pager -f
```

## Release

当前使用的 release：

```text
v0.9.5
```

下载地址：

```text
https://github.com/Chan110011/XrayR-Test-source/releases/tag/v0.9.5
```

## 免责声明

本仓库为自用构建与测试用途。请自行确认源码、脚本和配置是否符合你的使用场景。使用本项目产生的任何问题需自行承担。
