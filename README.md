# OpenClaw Windows One-Click Deploy

[简体中文](#简体中文) | [English](#english)

## 简体中文

这是一个面向 Windows 的 OpenClaw 单窗口一键部署工具。它会在你选择的部署目录内准备 Git、Node.js、`openclaw@latest`、OpenClaw 本地状态目录、Gateway 和 Dashboard 启动脚本。

作者：[@K2st0r](https://github.com/K2st0r)

### 文件说明

- `Start-OpenClaw-Deploy.cmd`：启动图形化部署工具。
- `OpenClaw-OneClick-Deploy.ps1`：主部署脚本。
- `OpenClaw-Dashboard.cmd`：部署后打开 Dashboard。
- `OpenClaw-Gateway.cmd`：部署后启动 Gateway。
- `OpenClaw-Shell.cmd`：打开已注入 Git、Node、OpenClaw 路径的命令行。

### 使用方法

1. 下载或克隆本仓库。
2. 双击 `Start-OpenClaw-Deploy.cmd`。
3. 在窗口中选择部署目录，例如 `D:\claw`。
4. 选择模型提供商和模型。
5. 有 API Key 就填入 API Key；没有也可以先跳过，只完成基础部署。
6. 点击开始部署，等待进度条完成。
7. 部署完成后工具会自动启动 Gateway，并打开 Dashboard。

推荐打开地址是根地址：

```text
http://127.0.0.1:18789/
```

不要优先使用旧的会话链接，例如：

```text
http://127.0.0.1:18789/chat?session=agent%3Amain%3Amain
```

旧会话可能加载历史较慢，或者因为浏览器缓存的旧令牌导致连接异常。

### 全新电脑能否使用

目标是支持常规 Windows 10 / Windows 11 干净环境一键部署，不要求预装 Git、Node.js 或 OpenClaw。

仍然需要：

- Windows PowerShell 5+
- 可访问 GitHub、npm registry、Node.js 下载源的网络
- 如果要直接使用云模型，需要有效的模型 API Key

如果本机已有 Git 或 Node.js，工具会优先复用；如果没有，会自动下载。OpenClaw CLI 会安装到你选择的部署目录：

```text
<部署目录>\runtime\npm-global\openclaw.cmd
```

### 模型和 Key 填写

工具内置了常见国内和海外模型提供商，例如：

- DeepSeek
- Moonshot / Kimi
- Qwen / 阿里百炼
- Volcengine / Doubao / 火山引擎
- MiniMax
- Z.AI / GLM
- OpenAI
- OpenRouter
- xAI
- Anthropic
- Ollama
- Custom OpenAI-compatible API

以火山引擎为例：

- Provider 选择 `Volcengine / Doubao`
- Model 选择或填写对应模型 ID，例如 `doubao-seed-1-6-lite-251015`
- API Key 填写火山 Ark Key
- Base URL 通常不用填，除非你使用自定义兼容接口

部署后 Key 会写入部署目录的：

```text
<部署目录>\openclaw-home\.env
```

不要把 `openclaw-home` 提交到 GitHub。

### 部署后的目录结构

部署目录中会生成：

```text
runtime\                 Git / Node / OpenClaw CLI
downloads\               下载缓存和临时 job
openclaw-home\           OpenClaw 配置、状态、工作区和密钥引用
resources\               可选同步的 OpenClaw 源码
OpenClaw-Dashboard.cmd
OpenClaw-Gateway.cmd
OpenClaw-Shell.cmd
```

这些都是运行产物，不应该提交到仓库。

### 切换模型

OpenClaw 的聊天页通常不是模型选择页。模型主要由后端配置决定。如果你要切换模型，可以在 `OpenClaw-Shell.cmd` 中运行：

```powershell
openclaw models list
openclaw models set volcengine/doubao-seed-1-8-251228
```

如果没有使用 `OpenClaw-Shell.cmd`，需要先指定部署目录：

```powershell
$env:OPENCLAW_STATE_DIR="D:\claw\openclaw-home"
$env:OPENCLAW_CONFIG_PATH="D:\claw\openclaw-home\openclaw.json"
D:\claw\runtime\npm-global\openclaw.cmd models list
D:\claw\runtime\npm-global\openclaw.cmd models set volcengine/doubao-seed-1-8-251228
```

### 常见问题

如果 Dashboard 打得开但一直连不上：

- 使用工具重新点击 `打开 Dashboard`，它会尝试重启当前部署目录的 Gateway。
- 确认打开的是 `http://127.0.0.1:18789/`，不要用旧的 chat session 链接。
- 如果浏览器缓存了旧令牌，复制工具输出的 Gateway token，粘贴到页面的 Gateway 令牌输入框。

如果模型显示不出来或不能用：

- 先确认部署目录正确，不要连到旧的 `D:\claw2`、`D:\claw3` 等旧 Gateway。
- 运行 `openclaw models list` 看模型是否是 `configured`。
- 检查 API Key 是否有效、模型是否开通、账号是否有余额。
- 火山引擎等国内模型需要确保对应模型 ID 和账号权限匹配。

如果 GitHub 同步很慢：

- 基础部署不依赖源码同步成功。
- 国内网络可以自行使用系统代理或 Steam++ 加速。

如果提示 Windows 权限或 symlink 失败：

- 这通常影响部分插件能力，不一定影响基础聊天。
- 可以用管理员权限重新运行，或继续使用基础功能。

### 发布到 GitHub 前注意

`.gitignore` 已排除常见运行产物：

```text
downloads/
runtime/
openclaw-home/
resources/
*.log
*.events.jsonl
```

提交前不要包含真实 API Key、`.env`、下载缓存、运行时目录或本机 OpenClaw 状态。

### 许可证

MIT License

## English

This is a single-window OpenClaw one-click deployer for Windows. It prepares Git, Node.js, `openclaw@latest`, local OpenClaw state, Gateway, and Dashboard launchers inside the selected deployment directory.

Author: [@K2st0r](https://github.com/K2st0r)

### Files

- `Start-OpenClaw-Deploy.cmd`: launches the GUI deployer.
- `OpenClaw-OneClick-Deploy.ps1`: main deployment script.
- `OpenClaw-Dashboard.cmd`: opens the Dashboard after deployment.
- `OpenClaw-Gateway.cmd`: starts the Gateway after deployment.
- `OpenClaw-Shell.cmd`: opens a shell with local Git, Node, and OpenClaw paths loaded.

### Usage

1. Download or clone this repository.
2. Double-click `Start-OpenClaw-Deploy.cmd`.
3. Choose a deployment directory, for example `D:\claw`.
4. Select provider and model.
5. Paste your API key if available, or leave it empty to deploy the base setup first.
6. Click start and wait for the progress bar to finish.
7. After deployment, the tool starts Gateway and opens Dashboard.

Recommended Dashboard URL:

```text
http://127.0.0.1:18789/
```

Avoid old direct chat-session URLs unless you know what you are doing.

### Clean Windows Support

The deployer is intended to work on a normal clean Windows 10 / Windows 11 machine without preinstalled Git, Node.js, or OpenClaw.

It still requires:

- Windows PowerShell 5+
- Internet access to GitHub, npm registry, and Node.js downloads
- A valid provider API key for usable cloud-model access

OpenClaw CLI is installed into:

```text
<deploy-root>\runtime\npm-global\openclaw.cmd
```

### Model Setup

Built-in provider presets include DeepSeek, Moonshot/Kimi, Qwen, Volcengine/Doubao, MiniMax, Z.AI, OpenAI, OpenRouter, xAI, Anthropic, Ollama, and custom OpenAI-compatible APIs.

Secrets are written to:

```text
<deploy-root>\openclaw-home\.env
```

Do not commit `openclaw-home`.

### Switching Models

The OpenClaw chat page is usually not the model picker. Models are configured on the backend.

Use `OpenClaw-Shell.cmd`, then run:

```powershell
openclaw models list
openclaw models set volcengine/doubao-seed-1-8-251228
```

Or specify the deploy root manually:

```powershell
$env:OPENCLAW_STATE_DIR="D:\claw\openclaw-home"
$env:OPENCLAW_CONFIG_PATH="D:\claw\openclaw-home\openclaw.json"
D:\claw\runtime\npm-global\openclaw.cmd models list
```

### Troubleshooting

If Dashboard opens but does not connect, reopen it from the deployer so it can restart the Gateway for the selected deploy root. Use `http://127.0.0.1:18789/` instead of stale chat-session URLs.

If a model does not appear or cannot be used, verify the active deploy root, run `openclaw models list`, check that the model is configured, and confirm that the provider API key, model ID, quota, and account permissions are valid.

### GitHub Publishing Notes

Generated runtime folders are ignored:

```text
downloads/
runtime/
openclaw-home/
resources/
*.log
*.events.jsonl
```

Do not publish real API keys, `.env`, local runtime files, caches, or OpenClaw state.

### License

MIT License
