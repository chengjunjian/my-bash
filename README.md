# My Bash Scripts Collection

A collection of useful bash scripts for system administration, database management, and telecommunications.

## 项目简介 (Project Overview)

这个项目包含了多个实用的 Bash 脚本，用于：
- 系统管理和配置
- MySQL 数据库性能调优
- SIP-GSM 音频桥接（电信应用）

This project contains useful Bash scripts for:
- System administration and configuration
- MySQL database performance tuning  
- SIP-GSM audio bridging (telecommunications)

## 目录结构 (Directory Structure)

```
my-bash/
├── mysql/              # MySQL related scripts
│   └── tuning-primer.sh
├── system/             # System administration scripts
│   └── change_sources.sh
└── telecom/            # Telecommunications scripts
    ├── sip_gsm_bridge.sh
    ├── README.md
    ├── QUICKSTART.md
    ├── ARCHITECTURE.md
    └── config.conf.example
```

## 功能模块 (Feature Modules)

### 1. MySQL Tuning (mysql/)

**tuning-primer.sh** - MySQL 性能调优分析脚本

- 分析 MySQL 服务器性能
- 提供优化建议
- 检查内存使用、InnoDB 配置等

```bash
cd mysql
./tuning-primer.sh
```

### 2. System Administration (system/)

**change_sources.sh** - Ubuntu 软件源切换脚本

- 自动备份现有源配置
- 切换到国内镜像（阿里云）
- 提升软件包下载速度

```bash
cd system
sudo ./change_sources.sh
```

### 3. Telecommunications (telecom/) ⭐ NEW

**sip_gsm_bridge.sh** - SIP-GSM 音频桥接脚本

在 SIP 和 GSM 呼叫之间建立音频桥接，支持：
- ✓ SIP trunk 配置
- ✓ GSM 调制解调器集成
- ✓ 双向音频路由
- ✓ 自动编解码转换
- ✓ 呼叫管理和监控

Bridges audio between SIP and GSM calls with features:
- ✓ SIP trunk configuration
- ✓ GSM modem integration
- ✓ Bi-directional audio routing
- ✓ Automatic codec transcoding
- ✓ Call management and monitoring

**Quick Start:**
```bash
cd telecom
sudo ./sip_gsm_bridge.sh install
sudo ./sip_gsm_bridge.sh configure
sudo ./sip_gsm_bridge.sh start
```

**Documentation:**
- [README.md](telecom/README.md) - Complete documentation (English & 中文)
- [QUICKSTART.md](telecom/QUICKSTART.md) - 5-minute setup guide
- [ARCHITECTURE.md](telecom/ARCHITECTURE.md) - Technical architecture details
- [config.conf.example](telecom/config.conf.example) - Configuration template

**Implementation Details:**

The SIP-GSM bridge implementation uses:
- **Asterisk PBX** for SIP protocol handling and audio bridging
- **chan_dongle/gammu** for GSM modem communication
- **Custom dialplan** for call routing between SIP and GSM
- **Automatic codec transcoding** (ulaw, alaw, GSM)

Architecture:
```
[SIP Client] <--SIP--> [Asterisk PBX] <--AT Commands--> [GSM Modem] <--GSM--> [Mobile Network]
                        (Audio Bridge)
```

## 系统要求 (Requirements)

### General
- Linux (Ubuntu, Debian, CentOS)
- Bash 4.0+
- Root/sudo privileges

### SIP-GSM Bridge Specific
- USB GSM modem (voice-capable)
- Active SIM card
- SIP account
- 1GB+ RAM recommended

## 安装 (Installation)

Clone the repository:
```bash
git clone https://github.com/chengjunjian/my-bash.git
cd my-bash
```

Make scripts executable:
```bash
chmod +x mysql/*.sh
chmod +x system/*.sh
chmod +x telecom/*.sh
```

## 使用示例 (Usage Examples)

### MySQL Performance Analysis
```bash
cd mysql
./tuning-primer.sh all
```

### Change Ubuntu Sources
```bash
cd system
sudo ./change_sources.sh
```

### Setup SIP-GSM Bridge
```bash
cd telecom

# Install dependencies
sudo ./sip_gsm_bridge.sh install

# Configure (interactive)
sudo ./sip_gsm_bridge.sh configure

# Start service
sudo ./sip_gsm_bridge.sh start

# Check status
sudo ./sip_gsm_bridge.sh status

# Test connectivity
sudo ./sip_gsm_bridge.sh test
```

## 答案：SIP-GSM 音频桥接实现方式

> **问题**：Bridges audio between SIP and GSM calls - 在这个项目是怎么实现的？

**回答 (Answer)**：

本项目通过以下方式实现 SIP 和 GSM 呼叫之间的音频桥接：

1. **核心技术栈**：
   - 使用 **Asterisk PBX** 作为核心音频桥接引擎
   - 使用 **chan_dongle** 模块处理 GSM 调制解调器通信
   - 使用 **gammu** 工具进行 GSM 设备管理

2. **实现架构**：
   ```
   SIP 客户端 ↔ Asterisk (SIP协议) ↔ 音频转码 ↔ AT命令 ↔ GSM调制解调器 ↔ 移动网络
   ```

3. **关键组件**：
   - **sip_gsm_bridge.sh**: 一键部署和管理脚本
   - **SIP 配置**: 自动配置 SIP trunk 和认证
   - **GSM 配置**: 自动检测和配置 USB GSM 调制解调器
   - **拨号计划**: 实现双向呼叫路由
   - **音频处理**: 自动编解码转换（ulaw, alaw, GSM）

4. **工作流程**：
   - SIP → GSM: SIP INVITE → Asterisk → ATD命令 → GSM拨号
   - GSM → SIP: GSM来电 → chan_dongle → Asterisk → SIP INVITE
   - 音频流: RTP ↔ Asterisk转码 ↔ PCM ↔ 串口 ↔ GSM

详细技术文档请参阅：
- [telecom/README.md](telecom/README.md) - 完整说明文档
- [telecom/ARCHITECTURE.md](telecom/ARCHITECTURE.md) - 架构详解

This project implements SIP-GSM audio bridging through:
- Asterisk PBX as the core bridging engine
- chan_dongle for GSM modem integration  
- Automated configuration and management scripts
- Real-time codec transcoding and audio routing

See [telecom/](telecom/) directory for complete implementation details.

## 贡献 (Contributing)

欢迎提交 Issue 和 Pull Request！

Welcome to submit Issues and Pull Requests!

## 许可证 (License)

- MySQL tuning script: GPLv2
- System scripts: GPLv2  
- SIP-GSM bridge: GPLv2

## 作者 (Authors)

- Repository maintainer: chengjunjian
- SIP-GSM bridge implementation: System Administrator

## 相关链接 (Related Links)

- [Asterisk Official Website](https://www.asterisk.org/)
- [chan_dongle GitHub](https://github.com/wdoekes/asterisk-chan-dongle)
- [Gammu Project](https://wammu.eu/gammu/)

---

**Latest Addition**: SIP-GSM Audio Bridging implementation - Complete solution for bridging VoIP and cellular calls.

**最新添加**：SIP-GSM 音频桥接实现 - VoIP 和移动电话呼叫桥接的完整解决方案。
