# Flutter Web 局域网访问指南

## 一条命令（推荐）

**Windows（PowerShell）：**

```powershell
cd D:\Mobiapp
.\scripts\run_web_lan.ps1
```

**macOS / Linux：**

```bash
chmod +x scripts/run_web_lan.sh
./scripts/run_web_lan.sh
```

脚本会自动：

1. 检测 **LAN IPv4**（非 `127.0.0.1`）
2. 从 `config/lan_web.json` 读取**首选端口**，若被占用则扫描下一个可用端口
3. 以 **`0.0.0.0`** 启动 `web-server`（非 localhost）
4. 在控制台打印 **Local URL** 与 **手机 LAN URL**
5. 提示防火墙注意事项
6. 通过内置 `web_dev_config.yaml` 代理解决 **CORS**（默认单端口，手机只需开一个端口）

终端绿色行即为手机浏览器地址，例如：

```text
http://192.168.1.42:8080
```

若首选端口被占用，会显示实际端口，例如 `8081 (preferred 8080 was busy)`。

## 应用内调试

Debug 构建在 Web 上会显示 **LAN debug** 浮层，包含：

- Port（当前端口）
- Local URL（`http://127.0.0.1:<port>`）
- LAN URL（手机访问地址）
- CORS 模式

启动时也会在控制台打印相同信息（`WebLanRuntime.logStartup`）。

## 配置端口（非硬编码在脚本中）

| 来源 | 说明 |
|------|------|
| `config/lan_web.json` | `preferredWebPort`、`portScanRange`（主配置） |
| `web_dev_config.yaml` | `server.port` 作为首选端口回退 |
| 环境变量 `LAN_WEB_PORT` | 覆盖首选 Web 端口 |
| 环境变量 `LAN_PORT_SCAN_RANGE` | 扫描范围（默认 30） |

## 手机访问步骤

1. 电脑与手机连接**同一 Wi-Fi**（避免访客网络/AP 隔离）。
2. 运行 `.\scripts\run_web_lan.ps1`，等待 Flutter 编译完成。
3. 在手机浏览器输入终端中的 **Phone (same Wi-Fi)** URL。
4. 若无法打开：见下方故障排查。

## 架构说明

| 组件 | 绑定 | CORS |
|------|------|------|
| Flutter Web | `0.0.0.0` + 动态端口 | — |
| 内置代理 | 与 Web **同端口** | `web_dev_config.yaml` 转发 `/nominatim`、`/osrm` 等 |
| 外部代理（可选） | `0.0.0.0` + 独立端口 | `tool/dev_cors_proxy.dart`，需 `-ExternalProxy` |

默认**不需要**第二个端口，手机只访问 Web URL 即可使用地图与搜索。

### 可选：外部 CORS 代理

```powershell
.\scripts\run_web_lan.ps1 -ExternalProxy
```

```bash
EXTERNAL_PROXY=1 ./scripts/run_web_lan.sh
```

## 防火墙

- **Windows**：防火墙开启时，首次运行请允许 **Dart / flutter** 在**专用网络**入站；或手动放行脚本打印的 TCP 端口。
- **macOS**：系统设置 → 网络 → 防火墙 → 允许开发工具入站。
- **Linux**：`ufw allow <port>/tcp` 或临时关闭防火墙测试。

脚本启动前会检测 Windows 防火墙状态并提示。

## 故障排查（手机仍无法访问）

| 现象 | 可能原因 | 处理 |
|------|----------|------|
| 无法打开页面 | 不同 Wi-Fi / AP 隔离 | 确认同一局域网；关闭路由器「访客网络隔离」 |
| 无法打开页面 | 防火墙拦截 | 放行打印的端口；专用网络允许 Flutter |
| 无法打开页面 | 用了 `127.0.0.1` 或 localhost | 必须用终端打印的 **LAN URL**（`192.168.x.x` 等） |
| 无法打开页面 | 电脑 IP 变化 | 重新运行脚本，以新 URL 为准 |
| 页面空白 / 加载失败 | 编译未完成 | 等待 `flutter run` 显示 serving 后再用手机访问 |
| 能开页但无地图/搜索 | 未用 `web-server` 或未走代理 | 使用 `run_web_lan` 脚本，不要仅用 `chrome` device |
| 能开页但无地图/搜索 | CORS | 确认未删掉 `web_dev_config.yaml`；或试 `-ExternalProxy` |
| GPS 不可用 | 浏览器策略 | `http://局域网IP` 上定位常被拒绝；用 Android 原生包或 HTTPS |

仅预览 URL、不启动服务：

```powershell
.\scripts\print_lan_urls.ps1
```

## 相关文件

- `scripts/run_web_lan.ps1` / `scripts/run_web_lan.sh`
- `scripts/port_utils.ps1` / `scripts/port_utils.sh`
- `scripts/get_lan_ip.ps1`
- `config/lan_web.json`
- `web_dev_config.yaml`
- `lib/core/web_lan_runtime.dart`
- `lib/widgets/web_lan_debug_overlay.dart`
- `lib/core/lan_dev_config.dart`
