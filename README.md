# OpenClaw Windows One-Click Deploy

[简体中文](#简体中文) | [English](#english)

---

## 简体中文

面向 Windows 平台的 OpenClaw 单窗口一键部署工具，自动完成 Git、Node.js 及 `openclaw@latest` 的安装配置，并生成网关（Gateway）与控制面板（Dashboard）的快捷启动脚本。

作者：[@K2st0r](https://github.com/K2st0r)

### 文件说明

| 文件 | 说明 |
| --- | --- |
| `Start-OpenClaw-Deploy.cmd` | 启动图形化部署工具 |
| `OpenClaw-OneClick-Deploy.ps1` | 核心部署脚本 |
| `OpenClaw-Dashboard.cmd` | 部署完成后打开 Dashboard |
| `OpenClaw-Gateway.cmd` | 部署完成后启动 Gateway |
| `OpenClaw-Shell.cmd` | 打开已注入 Git、Node、OpenClaw 环境变量的命令行 |

### 使用步骤

1. 下载或克隆本仓库
2. 双击 `Start-OpenClaw-Deploy.cmd`
3. 在弹出的窗口中指定部署目录（如 `D:\claw`）
4. 选择模型提供商及模型
5. 填写 API Key（可选；留空则仅完成基础部署）
6. 点击部署，等待进度条完成
7. 部署完成后工具将自动启动 Gateway 并打开 Dashboard

**推荐使用根地址访问 Dashboard：**

```text
http://127.0.0.1:18789/
```

> ⚠️ 请勿直接使用历史会话链接（如 `http://127.0.0.1:18789/chat?session=agent%3Amain%3Amain`），旧会话可能因浏览器缓存的令牌信息导致连接异常或加载缓慢。

### 系统要求

本工具在常规 Windows 10 / Windows 11 干净环境下可正常运行，无需预先安装 Git、Node.js 或 OpenClaw。

**必要依赖：**

- Windows PowerShell 5 及以上版本
- 可访问 GitHub、npm registry 及 Node.js 官方下载源的有效网络环境
- 若需直接使用云端模型，请确保持有有效的模型 API Key

> 💡 若本机已安装 Git 或 Node.js，工具将优先复用现有版本；未安装时则自动下载部署。

OpenClaw CLI 将安装于指定部署目录下：

```text
<部署目录>\runtime\npm-global\openclaw.cmd
```

### 模型配置

工具已内置以下模型提供商的预设配置：

- **国内：** DeepSeek、Moonshot / Kimi、Qwen / 阿里百炼、Volcengine / 豆包 / 火山引擎、MiniMax、Z.AI / GLM
- **海外：** OpenAI、OpenRouter、xAI、Anthropic
- **本地 / 自定义：** Ollama、Custom OpenAI-compatible API

**配置示例（以火山引擎为例）：**

| 字段 | 填写内容 |
| --- | --- |
| Provider | `Volcengine / Doubao` |
| Model | 对应模型 ID，如 `doubao-seed-1-6-lite-251015` |
| API Key | 火山引擎 Ark API Key |
| Base URL | 通常无需修改；自定义兼容接口时按需填写 |

API Key 等信息将写入部署目录下的环境变量文件：

```text
<部署目录>\openclaw-home\.env
```

> 🔒 `openclaw-home` 目录包含敏感配置，请勿提交至 GitHub。

### 部署后目录结构

```text
runtime\                  Git / Node / OpenClaw CLI
downloads\                下载缓存及临时任务
openclaw-home\            OpenClaw 配置、状态、工作区及密钥引用
resources\                可选同步的 OpenClaw 源码
OpenClaw-Dashboard.cmd
OpenClaw-Gateway.cmd
OpenClaw-Shell.cmd
```

以上均为运行时产物，不应纳入版本控制。

### 切换模型

OpenClaw 的聊天界面并非模型选择页面，模型配置由后端管理。如需切换模型，请通过 `OpenClaw-Shell.cmd` 打开命令行并执行：

```powershell
openclaw models list
openclaw models set volcengine/doubao-seed-1-8-251228
```

若未通过 `OpenClaw-Shell.cmd` 进入命令行，需手动指定部署目录：

```powershell
$env:OPENCLAW_STATE_DIR="D:\claw\openclaw-home"
$env:OPENCLAW_CONFIG_PATH="D:\claw\openclaw-home\openclaw.json"
D:\claw\runtime\npm-global\openclaw.cmd models list
D:\claw\runtime\npm-global\openclaw.cmd models set volcengine/doubao-seed-1-8-251228
```

### 常见问题

**Dashboard 无法连接**

- 通过部署工具重新点击"打开 Dashboard"，工具将尝试重启当前部署目录下的 Gateway。
- 确认访问地址为 `http://127.0.0.1:18789/`，避免使用旧的 chat session 链接。
- 若浏览器缓存了旧令牌，请复制工具输出的 Gateway Token 并填入页面中的令牌输入框。

**模型不可见或调用失败**

- 确认当前使用的部署目录正确，避免连接到旧部署（如 `D:\claw2`、`D:\claw3`）的 Gateway。
- 运行 `openclaw models list`，确认模型状态为 `configured`。
- 检查 API Key 是否有效、模型服务是否已开通、账户余额是否充足。
- 火山引擎等国内模型需确保模型 ID 与账号权限匹配。

**GitHub 同步缓慢**

- 基础部署流程不依赖源码同步，同步失败不影响正常使用。
- 国内网络环境下可配置系统代理或使用加速工具（如 Steam++）。

**提示权限不足或 symlink 创建失败**

- 此类问题通常影响部分插件功能，不影响基础对话能力。
- 可使用管理员权限重新运行，或直接使用当前基础功能。

### 发布注意事项

`.gitignore` 已排除以下运行时产物：

```text
downloads/
runtime/
openclaw-home/
resources/
*.log
*.events.jsonl
```

提交前请确保不包含真实 API Key、`.env` 文件、下载缓存、运行时目录及本地 OpenClaw 状态数据。

### 许可证

MIT License

---

## English

A streamlined Windows-based OpenClaw one-click deployer that automates the setup of Git, Node.js, and `openclaw@latest`, along with Gateway and Dashboard launchers — all within a single deployment directory.

Author: [@K2st0r](https://github.com/K2st0r)

### Files

| File | Description |
| --- | --- |
| `Start-OpenClaw-Deploy.cmd` | Launches the graphical deployment tool |
| `OpenClaw-OneClick-Deploy.ps1` | Core deployment script |
| `OpenClaw-Dashboard.cmd` | Opens the Dashboard post-deployment |
| `OpenClaw-Gateway.cmd` | Starts the Gateway post-deployment |
| `OpenClaw-Shell.cmd` | Opens a shell with Git, Node, and OpenClaw paths pre-loaded |

### Usage

1. Download or clone this repository
2. Double-click `Start-OpenClaw-Deploy.cmd`
3. Select a deployment directory (e.g., `D:\claw`)
4. Choose your model provider and model
5. Enter your API key (optional; leave blank for base setup only)
6. Click to deploy and wait for the progress bar to complete
7. Once finished, the tool will automatically start Gateway and open Dashboard

**Use the root URL to access Dashboard:**

```text
http://127.0.0.1:18789/
```

> ⚠️ Avoid using stale chat-session URLs (e.g., `http://127.0.0.1:18789/chat?session=agent%3Amain%3Amain`) as they may reference cached tokens that cause connection errors or slow loading.

### System Requirements

Designed for standard Windows 10 / Windows 11 environments with no prerequisites for Git, Node.js, or OpenClaw.

**Required:**

- Windows PowerShell 5+
- Internet access to GitHub, npm registry, and the Node.js official download source
- A valid provider API key for cloud-model usage

> 💡 If Git or Node.js is already installed, the tool will reuse the existing installation; otherwise it downloads them automatically.

The OpenClaw CLI is installed at:

```text
<deploy-root>\runtime\npm-global\openclaw.cmd
```

### Model Configuration

Built-in provider presets include:

- **China-based:** DeepSeek, Moonshot / Kimi, Qwen / Alibaba Bailian, Volcengine / Doubao, MiniMax, Z.AI / GLM
- **Global:** OpenAI, OpenRouter, xAI, Anthropic
- **Local / Custom:** Ollama, Custom OpenAI-compatible API

**Example (Volcengine / Doubao):**

| Field | Value |
| --- | --- |
| Provider | `Volcengine / Doubao` |
| Model | Model ID, e.g., `doubao-seed-1-6-lite-251015` |
| API Key | Volcengine Ark API Key |
| Base URL | Usually not required; specify only for custom endpoints |

Secrets are stored in:

```text
<deploy-root>\openclaw-home\.env
```

> 🔒 Do not commit the `openclaw-home` directory — it contains sensitive credentials.

### Post-Deployment Directory Layout

```text
runtime\                  Git / Node / OpenClaw CLI
downloads\                Download cache and temp jobs
openclaw-home\            OpenClaw config, state, workspace, and secret references
resources\                Optional synced OpenClaw source
OpenClaw-Dashboard.cmd
OpenClaw-Gateway.cmd
OpenClaw-Shell.cmd
```

All entries above are runtime artifacts and should not be version-controlled.

### Switching Models

The OpenClaw chat page is not the model selector — models are managed on the backend. To switch, use `OpenClaw-Shell.cmd` to open a shell and run:

```powershell
openclaw models list
openclaw models set volcengine/doubao-seed-1-8-251228
```

If not using `OpenClaw-Shell.cmd`, specify the deployment directory manually:

```powershell
$env:OPENCLAW_STATE_DIR="D:\claw\openclaw-home"
$env:OPENCLAW_CONFIG_PATH="D:\claw\openclaw-home\openclaw.json"
D:\claw\runtime\npm-global\openclaw.cmd models list
D:\claw\runtime\npm-global\openclaw.cmd models set volcengine/doubao-seed-1-8-251228
```

### Troubleshooting

**Dashboard opens but cannot connect**

- Reopen Dashboard from the deployer tool, which will attempt to restart the Gateway for the current deployment directory.
- Ensure the URL is `http://127.0.0.1:18789/` — avoid stale chat-session links.
- If the browser has cached an old token, copy the Gateway token output by the tool and paste it into the token field on the page.

**Model not visible or unavailable**

- Verify the active deployment directory — ensure you are not connected to an old Gateway from directories like `D:\claw2` or `D:\claw3`.
- Run `openclaw models list` and confirm the model status is `configured`.
- Validate that the API key is active, the model service is enabled, and the account has sufficient quota.
- For China-based providers (e.g., Volcengine), ensure the model ID matches the account's granted permissions.

### Publishing Notes

Generated runtime directories are ignored by `.gitignore`:

```text
downloads/
runtime/
openclaw-home/
resources/
*.log
*.events.jsonl
```

Do not publish real API keys, `.env` files, download caches, runtime directories, or local OpenClaw state.

### License

MIT License
