# SIP-GSM Audio Bridge Implementation

## 概述 (Overview)

这个项目通过 Bash 脚本实现了 SIP (Session Initiation Protocol) 和 GSM (Global System for Mobile Communications) 呼叫之间的音频桥接。

This project implements audio bridging between SIP and GSM calls using a Bash script.

## 实现原理 (Implementation Architecture)

### 架构图 (Architecture Diagram)

```
[SIP 客户端]  <---SIP--->  [Asterisk PBX]  <---AT Commands--->  [GSM 调制解调器]  <---GSM--->  [移动网络]
[SIP Client]              (Audio Bridge)                      [GSM Modem]              [Mobile Network]
```

### 核心组件 (Core Components)

1. **Asterisk PBX**: 开源的 PBX (Private Branch Exchange) 系统，负责处理 SIP 协议和音频流
   - Handles SIP protocol communication
   - Manages audio codec transcoding
   - Routes calls between SIP and GSM channels

2. **chan_dongle/gammu**: GSM 调制解调器通信模块
   - Communicates with GSM modem via AT commands
   - Handles GSM call setup and audio
   - Manages SMS and network registration

3. **音频桥接 (Audio Bridging)**: 通过 Asterisk 拨号计划实现
   - Routes incoming SIP calls to GSM network
   - Routes incoming GSM calls to SIP trunk
   - Transcodes audio between different codecs

## 工作流程 (Workflow)

### SIP 到 GSM 呼叫 (SIP to GSM Call Flow)

1. SIP 客户端向 Asterisk 发起呼叫
2. Asterisk 接收 SIP INVITE 请求
3. Asterisk 通过 chan_dongle 向 GSM 调制解调器发送 AT 命令
4. GSM 调制解调器拨打目标号码
5. 建立音频流，Asterisk 在 SIP 和 GSM 之间转发音频数据

### GSM 到 SIP 呼叫 (GSM to SIP Call Flow)

1. GSM 调制解调器接收来电
2. chan_dongle 通知 Asterisk 有新的来电
3. Asterisk 根据拨号计划路由到 SIP trunk
4. Asterisk 向 SIP 服务器发起呼叫
5. 建立音频流，双向传输音频数据

## 技术细节 (Technical Details)

### SIP 配置 (SIP Configuration)

脚本配置 Asterisk 的 SIP trunk，包括：
- SIP 服务器地址和端口
- 认证信息（用户名和密码）
- 支持的音频编解码器（ulaw, alaw, gsm）
- NAT 穿透设置

### GSM 配置 (GSM Configuration)

脚本配置 GSM 调制解调器，包括：
- 串口设备路径（通常是 /dev/ttyUSB0）
- 波特率设置
- AT 命令接口
- 网络注册和信号强度检测

### 音频编解码 (Audio Codec Transcoding)

Asterisk 支持以下音频编解码器：
- **ulaw (G.711μ)**: 北美标准，64 kbps
- **alaw (G.711A)**: 欧洲标准，64 kbps
- **GSM**: 移动网络标准，13 kbps

Asterisk 会自动在不同编解码器之间进行转码，确保音频质量。

## 使用方法 (Usage)

### 1. 安装依赖 (Install Dependencies)

```bash
sudo ./sip_gsm_bridge.sh install
```

这会安装以下软件包：
- Asterisk PBX 和相关模块
- gammu 和 gammu-smsd（GSM 工具）
- sox 和 alsa-utils（音频工具）
- socat 和 netcat（网络工具）

### 2. 配置系统 (Configure System)

```bash
sudo ./sip_gsm_bridge.sh configure
```

交互式配置向导会提示输入：
- SIP 服务器地址
- SIP 用户名和密码
- GSM 设备路径
- GSM 波特率

### 3. 启动服务 (Start Service)

```bash
sudo ./sip_gsm_bridge.sh start
```

这会：
- 启动 Asterisk PBX 服务
- 初始化 GSM 调制解调器
- 启用自动启动

### 4. 检查状态 (Check Status)

```bash
sudo ./sip_gsm_bridge.sh status
```

显示：
- Asterisk 服务状态
- SIP trunk 注册状态
- GSM 调制解调器状态
- 当前活动呼叫

### 5. 测试连接 (Test Connectivity)

```bash
sudo ./sip_gsm_bridge.sh test
```

测试：
- SIP 服务器连接
- GSM 调制解调器通信
- 网络注册状态
- 信号强度

## 拨号计划示例 (Dialplan Example)

```asterisk
; 从 SIP 呼入，转发到 GSM
[from-sip]
exten => _X.,1,NoOp(Incoming SIP call from ${CALLERID(num)})
same => n,Set(CALLERID(name)=SIP-${CALLERID(num)})
same => n,Dial(Dongle/gsm0/${EXTEN},60,tT)
same => n,Hangup()

; 从 GSM 呼入，转发到 SIP
[from-gsm]
exten => _X.,1,NoOp(Incoming GSM call from ${CALLERID(num)})
same => n,Set(CALLERID(name)=GSM-${CALLERID(num)})
same => n,Dial(SIP/sip-trunk/${EXTEN},60,tT)
same => n,Hangup()
```

## 系统要求 (System Requirements)

### 硬件要求 (Hardware Requirements)

- GSM 调制解调器（USB 或串口接口）
  - 推荐型号：Huawei E1750, E173, E3131
  - 支持语音通话功能
- 有效的 SIM 卡（需要语音服务）
- 服务器或 VPS（最低 1GB RAM）

### 软件要求 (Software Requirements)

- Linux 操作系统（Ubuntu, Debian, CentOS）
- Root/sudo 权限
- 有效的 SIP 账号
- 网络连接

## 故障排除 (Troubleshooting)

### GSM 调制解调器未检测到

```bash
# 检查 USB 设备
lsusb

# 检查串口设备
ls -l /dev/ttyUSB*

# 切换 USB 模式
sudo usb_modeswitch -v 12d1 -p 1f01 -M "55534243123456780000000000000011062000000100000000000000000000"
```

### SIP 注册失败

```bash
# 检查 SIP 连接
nc -zv <SIP_SERVER> 5060

# 查看 Asterisk 日志
tail -f /var/log/asterisk/full

# 测试 SIP 注册
asterisk -rx "sip show registry"
```

### 音频问题

```bash
# 检查音频设备
aplay -l

# 测试音频
sox -n -t alsa default synth 5 sine 440

# 查看活动呼叫
asterisk -rx "core show channels"
```

## 配置文件位置 (Configuration Files)

- 主配置：`/etc/sip-gsm-bridge/config.conf`
- Asterisk 配置：`/etc/asterisk/`
  - `sip_custom.conf` - SIP trunk 配置
  - `dongle.conf` - GSM 调制解调器配置
  - `extensions_custom.conf` - 拨号计划
- 日志文件：`/var/log/sip-gsm-bridge.log`
- Gammu 配置：`/etc/gammu/gammurc`

## 安全注意事项 (Security Notes)

1. **密码保护**: 配置文件包含敏感信息，设置正确的权限
   ```bash
   chmod 600 /etc/sip-gsm-bridge/config.conf
   ```

2. **防火墙配置**: 开放必要的端口
   ```bash
   # SIP
   ufw allow 5060/udp
   # RTP (音频流)
   ufw allow 10000:20000/udp
   ```

3. **访问控制**: 限制 SIP trunk 访问
   - 使用强密码
   - 启用 IP 白名单
   - 定期更新认证信息

## 进阶配置 (Advanced Configuration)

### 多个 GSM 调制解调器

编辑 `/etc/asterisk/dongle.conf`：

```ini
[gsm0]
device=/dev/ttyUSB0
context=from-gsm

[gsm1]
device=/dev/ttyUSB2
context=from-gsm
```

### 呼叫录音

在拨号计划中添加：

```asterisk
exten => _X.,1,MixMonitor(/var/spool/asterisk/monitor/${UNIQUEID}.wav)
```

### 自动故障转移

配置多个 SIP trunk 和 GSM 通道，实现冗余。

## 许可证 (License)

GPLv2

## 贡献 (Contributing)

欢迎提交问题报告和拉取请求。

## 参考资料 (References)

- [Asterisk Documentation](https://wiki.asterisk.org/)
- [chan_dongle GitHub](https://github.com/wdoekes/asterisk-chan-dongle)
- [Gammu Documentation](https://wammu.eu/gammu/)
- [SIP Protocol RFC 3261](https://tools.ietf.org/html/rfc3261)
