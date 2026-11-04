# 四板硬件接线

各板独立供电，信号共地。板间接口为 3.3 V 逻辑，按板卡丝印和 FPGA 球号核对；J1/J2 的 11 脚为 5 V、29 脚为 3.3 V，不作为地线或信号线。接线时断电。

## A ↔ B：原并行素材与控制通道

下表按当前 A/B `1.adc` 导出，A/B 同信号使用相同 FPGA 球号对接。排针位置以开发板对应版本原理图核对，保留已工作的连线。

| 信号 | A 球号 | B 球号 | 方向 |
|---|---|---|---|
| link_data[0] | P4 | P4 | B→A |
| link_data[1] | N4 | N4 | B→A |
| link_data[2] | N3 | N3 | B→A |
| link_data[3] | M5 | M5 | B→A |
| link_data[4] | M3 | M3 | B→A |
| link_data[5] | M4 | M4 | B→A |
| link_data[6] | L3 | L3 | B→A |
| link_data[7] | J3 | J3 | B→A |
| link_req | J4 | J4 | B→A |
| link_ack | H4 | H4 | A→B |
| link_run_n | N1 | N1 | A→B |
| link_status | M2 | M2 | A→B |
| link_camera | M1 | M1 | A→B |
| GND | GND | GND | 共地 |

## A ↔ C：同步 RPC

| A 排针 | C 排针 | 球号 | 信号 | 方向 |
|---|---|---|---|---|
| J2-31 | J2-31 | J12 | SCLK | A→C |
| J2-32 | J2-32 | K11 | MOSI | A→C |
| J2-33 | J2-33 | K14 | MISO | C→A |
| J2-34 | J2-34 | L12 | REQ | A→C |
| J2-35 | J2-35 | M12 | ACK | C→A |
| J2-30 | J2-30 | GND | 地 | 共地 |

## C ↔ D：采集画面与服务通道

| C 排针 | D 排针 | 球号 | 信号 | 方向 |
|---|---|---|---|---|
| J1-38 | J1-38 | R15 | RPC MOSI | C→D |
| J1-39 | J1-39 | T15 | RPC MISO | D→C |
| J1-40 | J1-40 | R14 | RPC SCLK | C→D |
| J1-4 | J1-4 | F13 | COLOR[0] | D→C |
| J1-5 | J1-5 | H13 | COLOR[1] | D→C |
| J1-6 | J1-6 | H14 | COLOR[2] | D→C |
| J1-7 | J1-7 | J14 | COLOR[3] | D→C |
| J1-8 | J1-8 | J13 | COLOR[4] | D→C |
| J1-9 | J1-9 | K12 | PCLK | D→C |
| J1-10 | J1-10 | L14 | DE | D→C |
| J1-13 | J1-13 | M14 | VS | D→C |
| J1-12 | J1-12 | GND | 地 | 共地 |

## 屏幕与摄像头

- A HDMI：主屏展示、现场监控与告警；A 连接 OV5640。
- B：原 7 英寸电容触摸屏。
- C HDMI：D 的实时工况画面及 C 的本地视频。
- D：独立采集与分析角色，无需额外连接显示器或 TF 卡。

引脚的最终依据为仓库 `constraints/A`～`constraints/D`；工程未更改原引脚分配。
