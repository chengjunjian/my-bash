# Quick Start Guide - SIP-GSM Audio Bridge

## 快速开始指南

### 前提条件 (Prerequisites)

✓ Ubuntu/Debian Linux 系统  
✓ Root 或 sudo 权限  
✓ USB GSM 调制解调器（支持语音通话）  
✓ 有效的 SIM 卡  
✓ SIP 账号信息  

### 5 分钟快速部署

#### 1. 克隆或下载脚本

```bash
cd /opt
git clone https://github.com/chengjunjian/my-bash.git
cd my-bash/telecom
```

#### 2. 安装依赖

```bash
sudo ./sip_gsm_bridge.sh install
```

这将安装：
- Asterisk PBX
- Gammu (GSM 工具)
- 音频和网络工具

⏱️ 预计时间：3-5 分钟

#### 3. 插入 GSM 调制解调器

1. 将 SIM 卡插入 GSM 调制解调器
2. 连接 USB 调制解调器到服务器
3. 检查设备：

```bash
lsusb                    # 应该看到调制解调器
ls -l /dev/ttyUSB*      # 应该看到 /dev/ttyUSB0 或类似设备
```

#### 4. 配置服务

```bash
sudo ./sip_gsm_bridge.sh configure
```

按提示输入：
- SIP 服务器地址（如：sip.example.com）
- SIP 用户名
- SIP 密码
- GSM 设备路径（通常是 /dev/ttyUSB0）
- GSM 波特率（通常是 115200）

💡 **提示**：配置会保存到 `/etc/sip-gsm-bridge/config.conf`

#### 5. 启动服务

```bash
sudo ./sip_gsm_bridge.sh start
```

#### 6. 检查状态

```bash
sudo ./sip_gsm_bridge.sh status
```

应该看到：
- ✓ Asterisk 服务运行中
- ✓ SIP trunk 已注册
- ✓ GSM 调制解调器已连接

### 测试呼叫流程

#### 从 SIP 呼叫到 GSM

1. 使用 SIP 客户端（如 Zoiper, X-Lite）连接到 Asterisk
2. 拨打手机号码
3. 呼叫通过 GSM 调制解调器接通

#### 从 GSM 呼叫到 SIP

1. 用手机拨打 SIM 卡号码
2. GSM 调制解调器接收呼叫
3. 自动转接到 SIP 客户端

### 常见问题排查

#### GSM 调制解调器未检测到

```bash
# 切换 USB 模式
sudo apt-get install usb-modeswitch usb-modeswitch-data
sudo usb_modeswitch -v 12d1 -p 1f01 -M "55534243123456780000000000000011062000000100000000000000000000"
```

#### SIP 无法注册

1. 检查防火墙设置：
```bash
sudo ufw allow 5060/udp
sudo ufw allow 10000:20000/udp
```

2. 测试 SIP 连接：
```bash
nc -zv <SIP_SERVER> 5060
```

3. 查看 Asterisk 日志：
```bash
sudo tail -f /var/log/asterisk/full
```

#### 无音频

1. 检查 RTP 端口是否开放
2. 确认编解码器匹配
3. 检查 NAT 设置

### 高级用法

#### 查看日志

```bash
# SIP-GSM Bridge 日志
sudo tail -f /var/log/sip-gsm-bridge.log

# Asterisk 详细日志
sudo tail -f /var/log/asterisk/full

# Asterisk CLI
sudo asterisk -rvvv
```

#### 测试 GSM 调制解调器

```bash
# 识别调制解调器
sudo gammu identify

# 检查信号强度
sudo gammu getsignalquality

# 检查网络注册
sudo gammu getnetworkinfo
```

#### 手动配置文件

配置文件位置：
- `/etc/sip-gsm-bridge/config.conf` - 主配置
- `/etc/asterisk/sip_custom.conf` - SIP 配置
- `/etc/asterisk/dongle.conf` - GSM 配置
- `/etc/asterisk/extensions_custom.conf` - 拨号计划

### 停止服务

```bash
sudo ./sip_gsm_bridge.sh stop
```

### 重启服务

```bash
sudo ./sip_gsm_bridge.sh restart
```

### 卸载

```bash
# 停止服务
sudo ./sip_gsm_bridge.sh stop

# 移除配置
sudo rm -rf /etc/sip-gsm-bridge

# 卸载 Asterisk（可选）
sudo apt-get remove --purge asterisk
```

## English Quick Start

### Prerequisites

✓ Ubuntu/Debian Linux  
✓ Root/sudo access  
✓ USB GSM modem (voice-capable)  
✓ Active SIM card  
✓ SIP account credentials  

### 5-Minute Deployment

#### 1. Download the Script

```bash
cd /opt
git clone https://github.com/chengjunjian/my-bash.git
cd my-bash/telecom
```

#### 2. Install Dependencies

```bash
sudo ./sip_gsm_bridge.sh install
```

#### 3. Connect GSM Modem

1. Insert SIM card into GSM modem
2. Connect USB modem to server
3. Verify device:

```bash
lsusb
ls -l /dev/ttyUSB*
```

#### 4. Configure

```bash
sudo ./sip_gsm_bridge.sh configure
```

Enter when prompted:
- SIP server address
- SIP username and password
- GSM device path
- GSM baudrate

#### 5. Start Service

```bash
sudo ./sip_gsm_bridge.sh start
```

#### 6. Check Status

```bash
sudo ./sip_gsm_bridge.sh status
```

### Making Test Calls

**SIP to GSM**: Use SIP client to dial a mobile number  
**GSM to SIP**: Call the SIM card number from a mobile phone  

### Support

For issues or questions, check:
- `/var/log/sip-gsm-bridge.log`
- `/var/log/asterisk/full`
- Run: `sudo ./sip_gsm_bridge.sh test`

### More Information

See the full README.md for detailed documentation.
