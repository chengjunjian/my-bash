SIP-GSM Audio Bridge Architecture
===================================

This document explains the technical architecture and implementation details 
of how audio is bridged between SIP and GSM calls in this project.

实现架构详解 (Detailed Implementation Architecture)
================================================

1. SYSTEM ARCHITECTURE / 系统架构
---------------------------------

┌─────────────────┐          ┌──────────────────┐          ┌─────────────────┐          ┌──────────────────┐
│   SIP Client    │          │  Asterisk PBX    │          │   GSM Modem     │          │  Mobile Network  │
│   (Softphone)   │◄────────►│  (Audio Bridge)  │◄────────►│   (Hardware)    │◄────────►│   (Cellular)     │
│                 │   SIP    │                  │   AT     │                 │   GSM    │                  │
└─────────────────┘          └──────────────────┘   CMD    └─────────────────┘          └──────────────────┘
      ▲                             ▲                            ▲
      │                             │                            │
      │                             │                            │
   [Codecs:                   [Components:               [Interface:
    ulaw, alaw,                Asterisk Core              /dev/ttyUSB0
    gsm, g729]                 chan_sip                   AT Commands
                               chan_dongle                Voice Audio]
                               Dialplan]


2. CALL FLOW - SIP TO GSM / 呼叫流程：SIP 到 GSM
------------------------------------------------

Step 1: SIP Call Initiation
    SIP Client ──[INVITE]──> Asterisk PBX
    
Step 2: SIP Processing
    Asterisk receives INVITE request
    Matches dialplan: [from-sip] context
    Extracts destination number
    
Step 3: GSM Dialing
    Asterisk ──[ATD<number>]──> GSM Modem
    GSM Modem initiates cellular call
    
Step 4: Call Establishment
    GSM Modem ──[RING/CONNECT]──> Asterisk
    Asterisk ──[200 OK]──> SIP Client
    
Step 5: Audio Bridge Active
    SIP Client ◄──[RTP Audio]──► Asterisk ◄──[PCM Audio]──► GSM Modem
    
    Audio Flow:
    - SIP uses RTP packets (UDP)
    - Asterisk transcodes if needed
    - GSM uses PCM audio over serial
    
Step 6: Call Termination
    Either side hangs up
    Asterisk sends BYE to SIP
    Asterisk sends ATH to GSM


3. CALL FLOW - GSM TO SIP / 呼叫流程：GSM 到 SIP
------------------------------------------------

Step 1: GSM Call Arrival
    Mobile Network ──[Incoming Call]──> GSM Modem
    
Step 2: Modem Notification
    GSM Modem ──[RING, CLIP]──> Asterisk
    chan_dongle module detects incoming call
    
Step 3: Dialplan Processing
    Asterisk matches [from-gsm] context
    Extracts caller ID
    Determines SIP destination
    
Step 4: SIP Invitation
    Asterisk ──[INVITE]──> SIP Trunk
    SIP Trunk ──[INVITE]──> SIP Client
    
Step 5: Call Answer
    SIP Client ──[200 OK]──> Asterisk
    Asterisk ──[ATA]──> GSM Modem
    
Step 6: Audio Bridge Active
    GSM Modem ◄──[PCM Audio]──► Asterisk ◄──[RTP Audio]──► SIP Client


4. AUDIO CODEC HANDLING / 音频编解码处理
---------------------------------------

Supported Codecs:
┌──────────┬──────────┬──────────┬─────────────────────┐
│  Codec   │ Bitrate  │  Usage   │    Compatibility    │
├──────────┼──────────┼──────────┼─────────────────────┤
│ ulaw     │ 64 kbps  │ SIP      │ North America       │
│ alaw     │ 64 kbps  │ SIP      │ Europe/Asia         │
│ GSM      │ 13 kbps  │ Both     │ Mobile networks     │
│ G.729    │ 8 kbps   │ Optional │ Bandwidth saving    │
└──────────┴──────────┴──────────┴─────────────────────┘

Transcoding Process:
    SIP (ulaw) ──> Asterisk [Transcoder] ──> GSM (PCM)
                        │
                   [Real-time conversion]
                        │
                   [Buffer management]


5. COMPONENT INTERACTIONS / 组件交互
-----------------------------------

A. Asterisk Core
   - Manages call state
   - Handles dialplan execution
   - Coordinates between channels
   
B. chan_sip Module
   - SIP protocol stack
   - Registration management
   - RTP stream handling
   
C. chan_dongle Module
   - AT command interface
   - GSM modem control
   - Audio routing to serial port
   
D. Dialplan Engine
   [from-sip]
     ↓
   Route to Dongle
     ↓
   [from-gsm]
     ↓
   Route to SIP


6. CONFIGURATION FILES / 配置文件结构
------------------------------------

/etc/asterisk/
    ├── sip_custom.conf       (SIP trunk configuration)
    │   ├── [general]         - Global SIP settings
    │   └── [sip-trunk]       - Trunk definition
    │
    ├── dongle.conf           (GSM modem configuration)
    │   ├── [general]         - Dongle settings
    │   └── [gsm0]            - Specific modem
    │
    └── extensions_custom.conf (Dialplan)
        ├── [from-sip]        - SIP incoming
        └── [from-gsm]        - GSM incoming

/etc/gammu/
    └── gammurc               (GSM utility config)

/etc/sip-gsm-bridge/
    └── config.conf           (Bridge settings)


7. AUDIO PATH / 音频路径
------------------------

Detailed Audio Flow:

SIP Side:                    Bridge:                     GSM Side:
                            
[Microphone]                                            [Cellular Network]
     │                                                         │
     ▼                                                         ▼
[SIP Codec]                                            [GSM Codec]
     │                                                         │
     ▼                                                         ▼
[RTP Packets] ────────►  [Asterisk]  ◄──────────  [PCM Audio Stream]
                             │
                             │
                      [Jitter Buffer]
                             │
                      [Codec Transcoding]
                             │
                      [Audio Mixer/Router]


8. ERROR HANDLING / 错误处理
---------------------------

Network Issues:
    - SIP registration failure → Retry with backoff
    - GSM modem disconnect → Automatic reconnection
    - RTP timeout → Call termination
    
Hardware Issues:
    - Modem not found → Alert and guide user
    - SIM card error → Display error message
    - Audio device error → Fallback to alternate device
    
Call Issues:
    - Busy signal → Return proper SIP code
    - No answer → Timeout and hangup
    - Codec mismatch → Transcode automatically


9. SECURITY CONSIDERATIONS / 安全考虑
------------------------------------

SIP Security:
    ✓ Password authentication
    ✓ Optional TLS encryption
    ✓ IP-based access control
    
GSM Security:
    ✓ SIM card PIN protection
    ✓ Device access permissions
    ✓ Serial port security
    
System Security:
    ✓ Config file permissions (chmod 600)
    ✓ Log rotation
    ✓ Firewall rules


10. PERFORMANCE CHARACTERISTICS / 性能特征
-----------------------------------------

Latency:
    SIP Processing:     < 10ms
    Codec Transcoding:  < 20ms
    GSM Modem:          50-100ms
    Total One-Way:      80-130ms
    
Bandwidth:
    SIP (ulaw):         ~80 kbps (including overhead)
    SIP (GSM codec):    ~20 kbps
    Serial (GSM):       115200 bps (sufficient for voice)
    
Capacity:
    Calls per modem:    1 (single channel)
    Multiple modems:    Supported (add more [gsm] sections)
    Concurrent calls:   Limited by number of modems


11. IMPLEMENTATION CODE FLOW / 代码执行流程
------------------------------------------

Script Execution Flow:

main()
  │
  ├──> load_config()
  │     └──> Read /etc/sip-gsm-bridge/config.conf
  │
  ├──> parse_command()
  │     │
  │     ├──> install
  │     │     ├──> check_root()
  │     │     ├──> install_dependencies()
  │     │     │     ├──> apt-get install asterisk
  │     │     │     ├──> apt-get install gammu
  │     │     │     └──> apt-get install sox alsa-utils
  │     │     └──> print_success()
  │     │
  │     ├──> configure
  │     │     ├──> configure_sip()
  │     │     │     ├──> Prompt for SIP settings
  │     │     │     └──> Write sip_custom.conf
  │     │     ├──> configure_gsm()
  │     │     │     ├──> Detect GSM device
  │     │     │     └──> Write dongle.conf
  │     │     ├──> configure_dialplan()
  │     │     │     └──> Write extensions_custom.conf
  │     │     └──> save_config()
  │     │
  │     ├──> start
  │     │     ├──> systemctl start asterisk
  │     │     ├──> gammu identify
  │     │     └──> log_message()
  │     │
  │     ├──> status
  │     │     ├──> Check Asterisk status
  │     │     ├──> Check SIP registration
  │     │     ├──> Check GSM modem
  │     │     └──> Show active calls
  │     │
  │     └──> test
  │           ├──> test_sip()
  │           │     ├──> nc -zv $SIP_SERVER $SIP_PORT
  │           │     └──> asterisk -rx "sip show registry"
  │           └──> test_gsm()
  │                 ├──> gammu identify
  │                 ├──> gammu getsignalquality
  │                 └──> gammu getnetworkinfo
  │
  └──> exit


12. TROUBLESHOOTING GUIDE / 故障排查指南
---------------------------------------

Problem: No audio in calls
Solution:
  1. Check RTP ports: netstat -ln | grep 10000
  2. Verify codec compatibility
  3. Test audio devices: aplay -l
  
Problem: GSM modem not detected
Solution:
  1. Check USB connection: lsusb
  2. Switch mode: usb_modeswitch
  3. Check permissions: ls -l /dev/ttyUSB*
  
Problem: SIP registration fails
Solution:
  1. Verify credentials in config
  2. Test network: nc -zv $SIP_SERVER 5060
  3. Check firewall: ufw status
  4. View logs: tail -f /var/log/asterisk/full


END OF ARCHITECTURE DOCUMENT
=============================
