[CmdletBinding()]
param(
    [switch]$WorkerMode,
    [string]$WorkerJobFile
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
if (-not $WorkerMode) {
    [System.Windows.Forms.Application]::EnableVisualStyles()
    [System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)
}

$script:ScriptPath = $MyInvocation.MyCommand.Path
$script:LauncherDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:RootDir = $script:LauncherDir
$script:RuntimeDir = Join-Path $script:RootDir "runtime"
$script:DownloadsDir = Join-Path $script:RootDir "downloads"
$script:StateDir = Join-Path $script:RootDir "openclaw-home"
$script:WorkspaceDir = Join-Path $script:StateDir "workspace"
$script:ResourcesDir = Join-Path $script:RootDir "resources"
$script:SourceDir = Join-Path $script:ResourcesDir "openclaw-source"
$script:EnvFilePath = Join-Path $script:StateDir ".env"
$script:ConfigFilePath = Join-Path $script:StateDir "openclaw.json"
$script:GitDir = Join-Path $script:RuntimeDir "git"
$script:NodeDir = Join-Path $script:RuntimeDir "node"
$script:NpmPrefixDir = Join-Path $script:RuntimeDir "npm-global"
$script:NpmCacheDir = Join-Path $script:RuntimeDir "npm-cache"
$script:GatewayPort = "18789"
$script:GatewayBind = "loopback"
$script:RepoSyncTimeoutSeconds = 180
$script:ModelSyncTimeoutSeconds = 180
$script:CurrentLanguage = "zhCN"
$script:UiApplying = $false
$script:UiReady = $false
$script:AppVersion = "2026.05.06.15"
$script:SyncedOpenClawModels = @{}
$script:ModelSyncProcess = $null
$script:ModelSyncProviderKey = $null
$script:ModelSyncOutputFilePath = $null
$script:ModelSyncScriptPath = $null
$script:ModelSyncStartedAt = $null
$script:Theme = @{
    Window = [System.Drawing.Color]::FromArgb(20, 22, 27)
    Panel = [System.Drawing.Color]::FromArgb(32, 35, 43)
    Control = [System.Drawing.Color]::FromArgb(43, 47, 57)
    Input = [System.Drawing.Color]::FromArgb(24, 27, 34)
    Border = [System.Drawing.Color]::FromArgb(96, 116, 143)
    Text = [System.Drawing.Color]::FromArgb(245, 247, 250)
    Muted = [System.Drawing.Color]::FromArgb(206, 214, 225)
    Dim = [System.Drawing.Color]::FromArgb(172, 184, 199)
    Accent = [System.Drawing.Color]::FromArgb(0, 122, 204)
    AccentHover = [System.Drawing.Color]::FromArgb(25, 145, 235)
    AccentDown = [System.Drawing.Color]::FromArgb(0, 95, 160)
    Warning = [System.Drawing.Color]::FromArgb(255, 211, 130)
    LogBack = [System.Drawing.Color]::FromArgb(12, 14, 18)
    Link = [System.Drawing.Color]::FromArgb(117, 196, 255)
}
$script:I18n = ConvertFrom-Json @'
{
  "zhCN": {
    "lang_name": "\u7b80\u4f53\u4e2d\u6587",
    "form_title": "OpenClaw \u4e00\u952e\u90e8\u7f72 | K2st0r",
    "title": "OpenClaw Windows \u5355\u7a97\u53e3\u4e00\u952e\u90e8\u7f72",
    "subtitle": "\u5728\u4e00\u4e2a\u7a97\u53e3\u4e2d\u5b8c\u6210 Git\u3001Node\u3001OpenClaw \u5b89\u88c5\uff0c\u5e76\u53ef\u9884\u586b\u6a21\u578b\u53c2\u6570\u3002",
    "language": "\u8bed\u8a00",
    "settings_title": "\u90e8\u7f72\u8bbe\u7f6e",
    "settings_steps": "1. \u9009\u62e9\u6a21\u578b\u63d0\u4f9b\u5546   2. \u4ece\u4e0b\u62c9\u5217\u8868\u9009\u62e9\u6a21\u578b   3. \u7c98\u8d34 API Key   4. \u70b9\u51fb\u5f00\u59cb\u90e8\u7f72",
    "provider": "\u6a21\u578b\u63d0\u4f9b\u5546",
    "provider_hint": "\u5148\u9009\u62e9\u4f60\u8981\u63a5\u5165\u7684\u6a21\u578b\u901a\u9053\u3002",
    "model": "\u6a21\u578b\u9009\u62e9",
    "model_hint": "\u9ed8\u8ba4\u4f7f\u7528\u5185\u7f6e\u5217\u8868\uff1b\u70b9\u51fb\u540c\u6b65\u6a21\u578b\u53ef\u4ece\u7f51\u4e0a\u62c9\u53d6\u6700\u65b0 OpenClaw \u6a21\u578b\u76ee\u5f55\u3002",
    "api_key": "API Key",
    "api_key_hint": "\u8fd9\u91cc\u7c98\u8d34\u5bf9\u5e94\u5e73\u53f0\u7684 Key\uff1b\u7559\u7a7a\u5219\u5148\u8df3\u8fc7\u6a21\u578b\u8ba4\u8bc1\u3002",
    "show_key": "\u663e\u793a Key",
    "base_url": "Base URL",
    "base_url_hint": "\u4ec5 Custom \u6216 Ollama \u901a\u5e38\u9700\u8981\u586b\u5199\uff0c\u5176\u4f59\u4e00\u822c\u53ef\u7559\u7a7a\u3002",
    "deploy_root": "\u90e8\u7f72\u76ee\u5f55",
    "deploy_root_hint": "\u9009\u62e9 OpenClaw \u8981\u5b89\u88c5\u5230\u7684\u6839\u76ee\u5f55\uff0cruntime\u3001downloads\u3001openclaw-home \u90fd\u4f1a\u653e\u5728\u8fd9\u91cc\u3002",
    "workspace": "\u5de5\u4f5c\u533a\u76ee\u5f55",
    "workspace_hint": "\u5de5\u4f5c\u533a\u4f1a\u81ea\u52a8\u8ddf\u968f\u90e8\u7f72\u76ee\u5f55\uff0c\u56fa\u5b9a\u4e3a openclaw-home\\workspace\u3002",
    "guide_title": "\u586b\u5199\u8bf4\u660e",
    "guide_provider": "\u5f53\u524d\u63d0\u4f9b\u5546",
    "guide_model": "\u6a21\u578b\u9009\u62e9\u5904",
    "guide_key": "Key \u586b\u5199\u5904",
    "guide_key_env": "\u5efa\u8bae\u5bf9\u5e94\u7684\u5bc6\u94a5\u53d8\u91cf",
    "guide_key_none": "\u5f53\u524d\u63d0\u4f9b\u5546\u4e0d\u9700\u8981 API Key",
    "guide_base": "Base URL",
    "guide_base_required": "\u5f53\u524d\u63d0\u4f9b\u5546\u9700\u8981\u586b\u5199\u517c\u5bb9\u63a5\u53e3\u5730\u5740",
    "guide_base_optional": "\u5f53\u524d\u63d0\u4f9b\u5546\u901a\u5e38\u4e0d\u9700\u8981\u586b\u5199",
    "guide_model_empty": "\u53ef\u6682\u65f6\u7559\u7a7a\uff0c\u90e8\u7f72\u540e\u4e5f\u53ef\u518d\u4fee\u6539",
    "guide_key_input": "\u76f4\u63a5\u5728\u5de6\u4fa7 API Key \u8f93\u5165\u6846\u7c98\u8d34",
    "guide_tip": "\u5de6\u4fa7\u771f\u6b63\u8f93\u5165\u6a21\u578b\u548c Key\uff0c\u53f3\u4fa7\u53ea\u8d1f\u8d23\u63d0\u793a\u683c\u5f0f\u548c\u793a\u4f8b\u3002",
    "install_daemon": "\u5b89\u88c5 OpenClaw \u540e\u53f0\u670d\u52a1",
    "sync_repo": "\u540c\u6b65 GitHub \u4ed3\u5e93\u5230 resources\\openclaw-source",
    "button_start": "\u5f00\u59cb\u90e8\u7f72",
    "button_browse": "\u9009\u62e9...",
    "button_sync_models": "\u540c\u6b65\u6a21\u578b",
    "button_open_folder": "\u6253\u5f00\u5f53\u524d\u76ee\u5f55",
    "button_open_state": "\u6253\u5f00\u72b6\u6001\u76ee\u5f55",
    "button_open_dashboard": "\u6253\u5f00 Dashboard",
    "button_copy_url": "\u590d\u5236\u5730\u5740",
    "button_copy_token": "\u590d\u5236\u4ee4\u724c",
    "button_clear_log": "\u6e05\u7a7a\u65e5\u5fd7",
    "button_close": "\u5173\u95ed\u7a97\u53e3",
    "status_ready": "\u5c31\u7eea\u3002\u6240\u6709\u6b65\u9aa4\u90fd\u4f1a\u53ea\u5728\u8fd9\u4e2a\u7a97\u53e3\u91cc\u663e\u793a\u3002",
    "status_starting": "\u6b63\u5728\u542f\u52a8\u90e8\u7f72...",
    "status_preparing": "\u6b63\u5728\u51c6\u5907\u76ee\u5f55...",
    "status_downloading_git": "\u6b63\u5728\u4e0b\u8f7d Git...",
    "status_git_ready": "Git \u5df2\u5c31\u7eea\u3002",
    "status_checking_git": "\u6b63\u5728\u68c0\u67e5 Git \u73af\u5883...",
    "status_downloading_node": "\u6b63\u5728\u4e0b\u8f7d Node.js...",
    "status_node_ready": "Node.js \u5df2\u5c31\u7eea\u3002",
    "status_checking_node": "\u6b63\u5728\u68c0\u67e5 Node.js \u73af\u5883...",
    "status_installing_cli": "\u6b63\u5728\u5b89\u88c5 OpenClaw CLI...",
    "status_cli_ready": "OpenClaw CLI \u5df2\u5c31\u7eea\u3002",
    "status_checking_cli": "\u6b63\u5728\u68c0\u67e5 OpenClaw CLI \u73af\u5883...",
    "status_syncing_repo": "\u6b63\u5728\u540c\u6b65 GitHub \u4ed3\u5e93...",
    "status_repo_ready": "GitHub \u4ed3\u5e93\u5df2\u540c\u6b65\u3002",
    "status_repo_skipped": "GitHub \u4ed3\u5e93\u540c\u6b65\u5df2\u8df3\u8fc7\u3002",
    "status_writing_env": "\u6b63\u5728\u5199\u5165\u73af\u5883\u53d8\u91cf...",
    "status_onboard": "\u6b63\u5728\u6267\u884c OpenClaw \u521d\u59cb\u5316...",
    "status_onboard_done": "OpenClaw \u521d\u59cb\u5316\u5df2\u5b8c\u6210\u3002",
    "status_setting_model": "\u6b63\u5728\u5199\u5165\u9ed8\u8ba4\u6a21\u578b...",
    "status_syncing_models": "\u6b63\u5728\u540c\u6b65 OpenClaw \u6a21\u578b\u5217\u8868...",
    "status_validating": "\u6b63\u5728\u68c0\u67e5\u914d\u7f6e...",
    "status_complete": "\u90e8\u7f72\u5b8c\u6210\u3002",
    "status_failed": "\u90e8\u7f72\u5931\u8d25\u3002",
    "status_complete_hint": "\u90e8\u7f72\u5b8c\u6210\u3002\u53ef\u4ee5\u76f4\u63a5\u5173\u95ed\u7a97\u53e3\u6216\u6253\u5f00\u90e8\u7f72\u76ee\u5f55\u3002",
    "status_failed_hint": "\u90e8\u7f72\u5931\u8d25\u3002\u8bf7\u76f4\u63a5\u5728\u672c\u7a97\u53e3\u67e5\u770b\u65e5\u5fd7\u3002",
    "author": "\u4f5c\u8005",
    "log_root": "\u90e8\u7f72\u6839\u76ee\u5f55\uff1a",
    "log_launchers": "\u5df2\u751f\u6210\u540e\u7eed\u542f\u52a8\u811a\u672c\u3002",
    "log_fetch_git": "\u6b63\u5728\u83b7\u53d6 Git for Windows \u6700\u65b0 MinGit \u53d1\u884c\u4fe1\u606f\u3002",
    "log_check_git": "\u5148\u68c0\u67e5\u672c\u5730\u5df2\u6709 Git \u662f\u5426\u53ef\u7528\u3002",
    "log_use_existing_git": "\u5df2\u68c0\u6d4b\u5230\u53ef\u7528 Git\uff0c\u8df3\u8fc7\u4e0b\u8f7d\uff1a",
    "log_fetch_node": "\u6b63\u5728\u83b7\u53d6 Node.js 24 x64 ZIP \u53d1\u884c\u4fe1\u606f\u3002",
    "log_check_node": "\u5148\u68c0\u67e5\u672c\u5730\u5df2\u6709 Node.js \u662f\u5426\u53ef\u7528\u3002",
    "log_use_existing_node": "\u5df2\u68c0\u6d4b\u5230\u53ef\u7528 Node.js\uff0c\u8df3\u8fc7\u4e0b\u8f7d\uff1a",
    "log_install_cli": "\u6b63\u5728\u901a\u8fc7 npm \u5b89\u88c5 openclaw@latest\u3002",
    "log_check_cli": "\u5148\u68c0\u67e5\u5f53\u524d\u90e8\u7f72\u76ee\u5f55\u6216\u7cfb\u7edf\u4e2d\u662f\u5426\u5df2\u6709 OpenClaw CLI\u3002",
    "log_use_existing_cli": "\u5df2\u68c0\u6d4b\u5230\u53ef\u7528 OpenClaw CLI\uff0c\u8df3\u8fc7\u5b89\u88c5\uff1a",
    "log_repo_target": "GitHub \u540c\u6b65\u76ee\u6807\uff1a",
    "log_repo_done": "GitHub \u6e90\u7801\u76ee\u5f55\u5df2\u66f4\u65b0\u3002",
    "log_repo_running": "GitHub \u4ed3\u5e93\u6b63\u5728\u540c\u6b65\u4e2d\uff0c\u8fdb\u5ea6\u6761\u4f1a\u6301\u7eed\u63a8\u8fdb\uff1b\u5982\u9700\u52a0\u901f\u53ef\u4f7f\u7528 Steam++ \u6216\u7cfb\u7edf\u4ee3\u7406\u3002",
    "log_repo_timeout": "GitHub \u4ed3\u5e93\u540c\u6b65\u8d85\u65f6\uff0c\u5df2\u8df3\u8fc7\uff0c\u4e0d\u5f71\u54cd\u57fa\u7840\u90e8\u7f72\uff1a",
    "log_repo_skip": "GitHub \u4ed3\u5e93\u540c\u6b65\u5931\u8d25\uff0c\u5df2\u8df3\u8fc7\uff0c\u4e0d\u5f71\u54cd\u57fa\u7840\u90e8\u7f72\uff1a",
    "log_repo_missing_git": "\u76ee\u6807\u76ee\u5f55\u5df2\u5b58\u5728\uff0c\u4f46\u4e0d\u662f\u53ef\u66f4\u65b0\u7684 Git \u4ed3\u5e93\uff0c\u5df2\u8df3\u8fc7 GitHub \u4ed3\u5e93\u540c\u6b65\uff1a",
    "log_repo_skipped_continue": "\u5df2\u8df3\u8fc7 GitHub \u4ed3\u5e93\u540c\u6b65\uff0c\u540e\u7eed\u90e8\u7f72\u7ee7\u7eed\u3002",
    "log_env_file": "\u73af\u5883\u53d8\u91cf\u6587\u4ef6\uff1a",
    "log_onboard_start": "\u6b63\u5728\u5f00\u59cb\u975e\u4ea4\u4e92\u521d\u59cb\u5316\u3002",
    "log_no_key": "\u5f53\u524d\u63d0\u4f9b\u5546\u672a\u586b\u5199 Key\uff0c\u672c\u6b21\u5148\u5b8c\u6210\u57fa\u7840\u90e8\u7f72\u3002",
    "log_base_deploy_done": "\u57fa\u7840\u90e8\u7f72\u5df2\u5b8c\u6210\u3002",
    "log_set_model": "\u6b63\u5728\u5199\u5165\u9ed8\u8ba4\u6a21\u578b\uff1a",
    "log_model_sync_start": "\u6b63\u5728\u4ece\u7f51\u4e0a\u62c9\u53d6\u6700\u65b0 OpenClaw \u6a21\u578b\u76ee\u5f55\uff1a",
    "log_model_sync_done": "\u5df2\u540c\u6b65 OpenClaw \u6a21\u578b\u6570\u91cf\uff1a",
    "log_model_sync_none": "\u672a\u8bfb\u53d6\u5230\u65b0\u6a21\u578b\uff0c\u5df2\u4fdd\u7559\u5f53\u524d\u5217\u8868\u3002",
    "log_model_sync_missing_cli": "\u65e0\u6cd5\u8fde\u63a5 npm registry \u6216\u4e0b\u8f7d OpenClaw \u5305\uff0c\u5df2\u4fdd\u7559\u5185\u7f6e\u5217\u8868\u3002",
    "log_model_sync_timeout": "\u6a21\u578b\u540c\u6b65\u8d85\u65f6\uff0c\u5df2\u505c\u6b62\u672c\u6b21\u540c\u6b65\u3002",
    "log_model_sync_failed": "\u6a21\u578b\u540c\u6b65\u5931\u8d25\uff1a",
    "log_validate": "\u6b63\u5728\u6267\u884c openclaw config validate\u3002",
    "log_dashboard_url": "Dashboard \u5730\u5740\uff1a",
    "log_gateway_token": "Gateway \u4ee4\u724c\uff1a",
    "log_gateway_starting": "\u6b63\u5728\u540e\u53f0\u542f\u52a8 OpenClaw Gateway...",
    "log_gateway_started": "OpenClaw Gateway \u5df2\u5c31\u7eea\uff1a",
    "log_gateway_already_running": "OpenClaw Gateway \u5df2\u5728\u8fd0\u884c\uff1a",
    "log_gateway_start_failed": "OpenClaw Gateway \u542f\u52a8\u5931\u8d25\uff1a",
    "log_browser_launch": "\u5df2\u5c1d\u8bd5\u81ea\u52a8\u6253\u5f00\u6d4f\u89c8\u5668\uff1a",
    "log_browser_launch_failed": "\u81ea\u52a8\u6253\u5f00\u6d4f\u89c8\u5668\u5931\u8d25\uff1a",
    "log_dashboard_opened": "\u5df2\u6253\u5f00 Dashboard\uff1a",
    "log_copy_url_done": "\u5df2\u590d\u5236 Dashboard \u5730\u5740\u3002",
    "log_copy_token_done": "\u5df2\u590d\u5236 Gateway \u4ee4\u724c\u3002",
    "log_copy_token_missing": "\u5f53\u524d\u8fd8\u6ca1\u6709\u53ef\u590d\u5236\u7684 Gateway \u4ee4\u724c\u3002",
    "log_open_dashboard_failed": "\u6253\u5f00 Dashboard \u5931\u8d25\uff1a",
    "log_copy_failed": "\u590d\u5236\u5931\u8d25\uff1a",
    "log_complete": "\u73b0\u5728\u53ef\u4ee5\u4f7f\u7528 OpenClaw-Dashboard.cmd \u6216 OpenClaw-Gateway.cmd\u3002",
    "msg_done": "OpenClaw \u90e8\u7f72\u5b8c\u6210\u3002",
    "msg_done_title": "\u5b8c\u6210",
    "msg_failed_title": "\u5931\u8d25",
    "msg_workspace": "\u5de5\u4f5c\u533a\u8def\u5f84\u4e0d\u80fd\u4e3a\u7a7a\u3002",
    "msg_deploy_root": "\u90e8\u7f72\u76ee\u5f55\u4e0d\u80fd\u4e3a\u7a7a\u3002",
    "msg_custom_base": "Custom \u63d0\u4f9b\u5546\u5fc5\u987b\u586b\u5199 Base URL\u3002",
    "provider_Skip": "\u5148\u8df3\u8fc7\u6a21\u578b\u914d\u7f6e",
    "provider_DeepSeek": "DeepSeek | \u6df1\u5ea6\u6c42\u7d22",
    "provider_MoonshotCN": "Moonshot AI / Kimi | \u6708\u4e4b\u6697\u9762\uff08\u56fd\u5185\uff09",
    "provider_Moonshot": "Moonshot AI / Kimi",
    "provider_KimiCoding": "Kimi Coding | Kimi \u7f16\u7801",
    "provider_QwenStandardCN": "Qwen Standard CN | \u963f\u91cc\u767e\u70bc",
    "provider_QwenCodingCN": "Qwen Coding CN | \u963f\u91cc\u767e\u70bc\u7f16\u7801",
    "provider_Volcengine": "Volcengine / Doubao | \u706b\u5c71\u5f15\u64ce",
    "provider_MiniMaxCN": "MiniMax | \u56fd\u5185",
    "provider_ZAI": "Z.AI / GLM | \u667a\u8c31",
    "provider_OpenAI": "OpenAI",
    "provider_OpenRouter": "OpenRouter",
    "provider_xAI": "xAI",
    "provider_Anthropic": "Anthropic",
    "provider_Ollama": "Ollama | \u672c\u5730\u6a21\u578b",
    "provider_Custom": "\u81ea\u5b9a\u4e49 OpenAI \u517c\u5bb9\u63a5\u53e3"
  },
  "enUS": {
    "lang_name": "English",
    "form_title": "OpenClaw One-Click Deploy | K2st0r",
    "title": "OpenClaw Windows One-Click Deploy",
    "subtitle": "Install Git, Node, and OpenClaw in one window, with optional model presets before onboarding.",
    "language": "Language",
    "settings_title": "Deployment Settings",
    "settings_steps": "1. Choose provider   2. Pick a model   3. Paste API key   4. Start deployment",
    "provider": "Provider",
    "provider_hint": "Choose the model channel you want to connect first.",
    "model": "Model",
    "model_hint": "The default list is built in. Use Sync Models to fetch the latest OpenClaw model catalog online.",
    "api_key": "API Key",
    "api_key_hint": "Paste the provider key here. Leave empty if you want to skip model auth for now.",
    "show_key": "Show key",
    "base_url": "Base URL",
    "base_url_hint": "Usually only needed for Custom or Ollama. Most providers can leave this empty.",
    "deploy_root": "Deploy Root",
    "deploy_root_hint": "Choose the root folder where OpenClaw will be installed. runtime, downloads, and openclaw-home will all live there.",
    "workspace": "Workspace",
    "workspace_hint": "Workspace follows the deploy root automatically and stays fixed at openclaw-home\\workspace.",
    "guide_title": "Input Guide",
    "guide_provider": "Selected Provider",
    "guide_model": "Model Picker",
    "guide_key": "API Key Field",
    "guide_key_env": "Suggested secret variable",
    "guide_key_none": "This provider does not require an API key",
    "guide_base": "Base URL",
    "guide_base_required": "This provider requires a compatible endpoint URL",
    "guide_base_optional": "This provider usually does not need a Base URL",
    "guide_model_empty": "This can stay empty for now and be changed later",
    "guide_key_input": "Paste the value directly into the API Key box on the left",
    "guide_tip": "Model and key are entered on the left. This panel only explains the expected format and examples.",
    "install_daemon": "Install OpenClaw background service",
    "sync_repo": "Sync GitHub repo into resources\\openclaw-source",
    "button_start": "Start Deploy",
    "button_browse": "Browse...",
    "button_sync_models": "Sync Models",
    "button_open_folder": "Open Folder",
    "button_open_state": "Open State Folder",
    "button_open_dashboard": "Open Dashboard",
    "button_copy_url": "Copy URL",
    "button_copy_token": "Copy Token",
    "button_clear_log": "Clear Log",
    "button_close": "Close",
    "status_ready": "Ready. Everything runs in this window only.",
    "status_starting": "Starting deployment...",
    "status_preparing": "Preparing folders...",
    "status_downloading_git": "Downloading Git...",
    "status_git_ready": "Git ready.",
    "status_checking_git": "Checking Git environment...",
    "status_downloading_node": "Downloading Node.js...",
    "status_node_ready": "Node.js ready.",
    "status_checking_node": "Checking Node.js environment...",
    "status_installing_cli": "Installing OpenClaw CLI...",
    "status_cli_ready": "OpenClaw CLI ready.",
    "status_checking_cli": "Checking OpenClaw CLI environment...",
    "status_syncing_repo": "Syncing GitHub repo...",
    "status_repo_ready": "GitHub repo synced.",
    "status_repo_skipped": "GitHub repo sync skipped.",
    "status_writing_env": "Writing env file...",
    "status_onboard": "Running OpenClaw onboard...",
    "status_onboard_done": "OpenClaw onboard finished.",
    "status_setting_model": "Setting default model...",
    "status_syncing_models": "Syncing OpenClaw model list...",
    "status_validating": "Validating config...",
    "status_complete": "Deploy complete.",
    "status_failed": "Deploy failed.",
    "status_complete_hint": "Deploy complete. You can close this window or open the deploy folder now.",
    "status_failed_hint": "Deploy failed. Check the logs in this window directly.",
    "author": "Author",
    "log_root": "Root:",
    "log_launchers": "Launcher scripts generated.",
    "log_fetch_git": "Fetching latest MinGit release metadata from Git for Windows.",
    "log_check_git": "Checking whether a usable Git already exists first.",
    "log_use_existing_git": "Detected a usable Git and skipped download:",
    "log_fetch_node": "Fetching latest Node.js 24 x64 zip info.",
    "log_check_node": "Checking whether a usable Node.js already exists first.",
    "log_use_existing_node": "Detected a usable Node.js and skipped download:",
    "log_install_cli": "Running npm install for openclaw@latest.",
    "log_check_cli": "Checking whether OpenClaw CLI already exists in this deploy root or on the system.",
    "log_use_existing_cli": "Detected a usable OpenClaw CLI and skipped install:",
    "log_repo_target": "GitHub target:",
    "log_repo_done": "GitHub source is up to date.",
    "log_repo_running": "GitHub repo sync is running. The progress bar will keep moving; use Steam++ or a system proxy if you want acceleration.",
    "log_repo_timeout": "GitHub repo sync timed out and was skipped. Base deployment will continue:",
    "log_repo_skip": "GitHub repo sync failed and was skipped. Base deployment will continue:",
    "log_repo_missing_git": "Target folder exists but is not an updatable Git repo. Skipping GitHub repo sync:",
    "log_repo_skipped_continue": "GitHub repo sync was skipped. Deployment will continue.",
    "log_env_file": "File:",
    "log_onboard_start": "Starting non-interactive local onboarding.",
    "log_no_key": "No provider key was entered. Base deploy will continue without model auth.",
    "log_base_deploy_done": "Base deploy completed.",
    "log_set_model": "Model:",
    "log_model_sync_start": "Fetching latest OpenClaw model catalog online:",
    "log_model_sync_done": "Synced OpenClaw model count:",
    "log_model_sync_none": "No new models were loaded. Keeping the current list.",
    "log_model_sync_missing_cli": "Could not reach npm registry or download the OpenClaw package. Keeping the built-in list.",
    "log_model_sync_timeout": "Model sync timed out and was stopped.",
    "log_model_sync_failed": "Model sync failed:",
    "log_validate": "Running openclaw config validate.",
    "log_dashboard_url": "Dashboard URL:",
    "log_gateway_token": "Gateway token:",
    "log_gateway_starting": "Starting OpenClaw Gateway in the background...",
    "log_gateway_started": "OpenClaw Gateway is ready:",
    "log_gateway_already_running": "OpenClaw Gateway is already running:",
    "log_gateway_start_failed": "OpenClaw Gateway failed to start:",
    "log_browser_launch": "Browser launch requested:",
    "log_browser_launch_failed": "Browser launch failed:",
    "log_dashboard_opened": "Dashboard opened:",
    "log_copy_url_done": "Dashboard URL copied.",
    "log_copy_token_done": "Gateway token copied.",
    "log_copy_token_missing": "No Gateway token is available yet.",
    "log_open_dashboard_failed": "Open Dashboard failed:",
    "log_copy_failed": "Copy failed:",
    "log_complete": "Use OpenClaw-Dashboard.cmd or OpenClaw-Gateway.cmd next.",
    "msg_done": "OpenClaw deploy finished.",
    "msg_done_title": "Completed",
    "msg_failed_title": "Failed",
    "msg_workspace": "Workspace path cannot be empty.",
    "msg_deploy_root": "Deploy root path cannot be empty.",
    "msg_custom_base": "Custom provider requires Base URL.",
    "provider_Skip": "Skip model setup for now",
    "provider_DeepSeek": "DeepSeek",
    "provider_MoonshotCN": "Moonshot AI / Kimi (China)",
    "provider_Moonshot": "Moonshot AI / Kimi",
    "provider_KimiCoding": "Kimi Coding",
    "provider_QwenStandardCN": "Qwen Standard CN (Alibaba)",
    "provider_QwenCodingCN": "Qwen Coding CN (Alibaba)",
    "provider_Volcengine": "Volcengine / Doubao",
    "provider_MiniMaxCN": "MiniMax (China)",
    "provider_ZAI": "Z.AI / GLM",
    "provider_OpenAI": "OpenAI",
    "provider_OpenRouter": "OpenRouter",
    "provider_xAI": "xAI",
    "provider_Anthropic": "Anthropic",
    "provider_Ollama": "Ollama",
    "provider_Custom": "Custom OpenAI-compatible API"
  }
}
'@

function Get-T {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Key,
        [string]$Language
    )

    if ([string]::IsNullOrWhiteSpace($Language)) {
        $Language = $script:CurrentLanguage
    }

    return $script:I18n.PSObject.Properties[$Language].Value.PSObject.Properties[$Key].Value
}

function Get-ErrorMessage {
    param(
        [Parameter(Mandatory = $true)]
        $ErrorObject
    )

    if ($null -eq $ErrorObject) {
        return "Unknown error."
    }

    try {
        if ($ErrorObject -is [System.Exception]) {
            return [string]$ErrorObject.Message
        }

        $exceptionProperty = $ErrorObject.PSObject.Properties["Exception"]
        if ($exceptionProperty -and $null -ne $exceptionProperty.Value) {
            $exceptionValue = $exceptionProperty.Value
            if ($exceptionValue -is [System.Exception]) {
                return [string]$exceptionValue.Message
            }

            $messageProperty = $exceptionValue.PSObject.Properties["Message"]
            if ($messageProperty -and -not [string]::IsNullOrWhiteSpace([string]$messageProperty.Value)) {
                return [string]$messageProperty.Value
            }

            return [string]$exceptionValue.ToString()
        }

        $messageOnlyProperty = $ErrorObject.PSObject.Properties["Message"]
        if ($messageOnlyProperty -and -not [string]::IsNullOrWhiteSpace([string]$messageOnlyProperty.Value)) {
            return [string]$messageOnlyProperty.Value
        }

        return [string]$ErrorObject.ToString()
    }
    catch {
        return [string]$ErrorObject
    }
}

function Write-DebugTrace {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    try {
        $logPath = Join-Path $script:RootDir "launcher-debug.log"
        $line = ("[{0}] {1}" -f (Get-Date).ToString("yyyy-MM-dd HH:mm:ss"), $Message)
        Add-Content -LiteralPath $logPath -Value $line -Encoding UTF8
    }
    catch {
    }
}

function Reset-DebugTrace {
    try {
        $logPath = Join-Path $script:RootDir "launcher-debug.log"
        if (Test-Path -LiteralPath $logPath) {
            Remove-Item -LiteralPath $logPath -Force
        }
    }
    catch {
    }
}

function Get-ResultPropertyValue {
    param(
        $Object,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        $DefaultValue = $null
    )

    try {
        if ($null -eq $Object) {
            return $DefaultValue
        }

        $property = $Object.PSObject.Properties[$Name]
        if ($null -eq $property) {
            return $DefaultValue
        }

        return $property.Value
    }
    catch {
        return $DefaultValue
    }
}

function Hide-ConsoleWindow {
    try {
        Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class OpenClawConsoleWindow {
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
'@ -ErrorAction SilentlyContinue

        $consoleHandle = [OpenClawConsoleWindow]::GetConsoleWindow()
        if ($consoleHandle -ne [IntPtr]::Zero) {
            [void][OpenClawConsoleWindow]::ShowWindow($consoleHandle, 0)
        }
    }
    catch {
    }
}

function Set-DeploymentRoot {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RootPath
    )

    $resolvedRoot = [System.IO.Path]::GetFullPath($RootPath)
    $script:RootDir = $resolvedRoot
    $script:RuntimeDir = Join-Path $script:RootDir "runtime"
    $script:DownloadsDir = Join-Path $script:RootDir "downloads"
    $script:StateDir = Join-Path $script:RootDir "openclaw-home"
    $script:WorkspaceDir = Join-Path $script:StateDir "workspace"
    $script:ResourcesDir = Join-Path $script:RootDir "resources"
    $script:SourceDir = Join-Path $script:ResourcesDir "openclaw-source"
    $script:EnvFilePath = Join-Path $script:StateDir ".env"
    $script:ConfigFilePath = Join-Path $script:StateDir "openclaw.json"
    $script:GitDir = Join-Path $script:RuntimeDir "git"
    $script:NodeDir = Join-Path $script:RuntimeDir "node"
    $script:NpmPrefixDir = Join-Path $script:RuntimeDir "npm-global"
    $script:NpmCacheDir = Join-Path $script:RuntimeDir "npm-cache"
}

function Get-DefaultWorkspaceForRoot {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RootPath
    )

    $resolvedRoot = [System.IO.Path]::GetFullPath($RootPath)
    return (Join-Path (Join-Path $resolvedRoot "openclaw-home") "workspace")
}

function ConvertTo-JobJson {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Job
    )

    $payload = [ordered]@{
        ProviderKey = $Job.ProviderKey
        Model = $Job.Model
        ApiKey = $Job.ApiKey
        BaseUrl = $Job.BaseUrl
        DeployRoot = $Job.DeployRoot
        Workspace = $Job.Workspace
        InstallDaemon = [bool]$Job.InstallDaemon
        CloneOfficialRepo = [bool]$Job.CloneOfficialRepo
        Language = $Job.Language
        Progress = 0
        Status = ""
    }

    return ($payload | ConvertTo-Json -Depth 8)
}

function Write-WorkerEvent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [hashtable]$Payload
    )

    $line = ($Payload | ConvertTo-Json -Compress -Depth 8) + [Environment]::NewLine
    $encoding = New-Object System.Text.UTF8Encoding($true)
    $bytes = $encoding.GetBytes($line)
    $stream = $null
    try {
        $writeBom = -not (Test-Path -LiteralPath $Path) -or ((Get-Item -LiteralPath $Path).Length -eq 0)
        $stream = New-Object System.IO.FileStream($Path, [System.IO.FileMode]::Append, [System.IO.FileAccess]::Write, [System.IO.FileShare]::ReadWrite)
        if ($writeBom) {
            $preamble = $encoding.GetPreamble()
            if ($preamble.Length -gt 0) {
                $stream.Write($preamble, 0, $preamble.Length)
            }
        }
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Flush()
    }
    finally {
        if ($stream) {
            $stream.Dispose()
        }
    }
}

function Invoke-WorkerDeployment {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Job,
        [Parameter(Mandatory = $true)]
        [string]$EventFile
    )

    $writeEvent = {
        param(
            [string]$Type,
            [int]$Progress,
            [string]$Status,
            [string]$Log,
            [bool]$Success,
            [string]$Error
        )

        Write-WorkerEvent -Path $EventFile -Payload @{
            type = $Type
            progress = $Progress
            status = $Status
            log = $Log
            success = $Success
            error = $Error
            language = $Job.Language
        }
    }

    $report = {
        param(
            [int]$Progress,
            [string]$Status,
            [string]$Log
        )

        $Job.Progress = $Progress
        $Job.Status = $Status
        & $writeEvent "progress" $Progress $Status $Log $false ""
    }

    $reportLog = {
        param([string]$Message)
        & $writeEvent "log" $Job.Progress $Job.Status $Message $false ""
    }

    $invokeLoggedProcessWithHeartbeat = {
        param(
            [string]$FilePath,
            [string[]]$ArgumentList,
            [string]$WorkingDirectory,
            [hashtable]$EnvironmentVariables,
            [int]$HeartbeatProgress,
            [string]$HeartbeatStatus,
            [string]$HeartbeatPrefix
        )

        $outputFile = Join-Path $script:DownloadsDir ("process-output-" + [Guid]::NewGuid().ToString("N") + ".log")
        $jobFile = Join-Path $script:DownloadsDir ("process-job-" + [Guid]::NewGuid().ToString("N") + ".ps1")
        try {
            $jobScript = @"
`$ErrorActionPreference = 'Stop'
`$envMap = ConvertFrom-Json @'
$((ConvertTo-Json $EnvironmentVariables -Compress))
'@
foreach (`$item in `$envMap.PSObject.Properties) {
    [Environment]::SetEnvironmentVariable(`$item.Name, [string]`$item.Value, 'Process')
}
`$psi = New-Object System.Diagnostics.ProcessStartInfo
`$psi.FileName = '$($FilePath.Replace("'", "''"))'
`$psi.Arguments = '$((ConvertTo-ProcessArgumentString -Arguments $ArgumentList).Replace("'", "''"))'
`$psi.WorkingDirectory = '$($WorkingDirectory.Replace("'", "''"))'
`$psi.UseShellExecute = `$false
`$psi.RedirectStandardOutput = `$true
`$psi.RedirectStandardError = `$true
`$psi.CreateNoWindow = `$true
`$process = New-Object System.Diagnostics.Process
`$process.StartInfo = `$psi
`$null = `$process.Start()
`$stdout = `$process.StandardOutput.ReadToEndAsync()
`$stderr = `$process.StandardError.ReadToEndAsync()
`$process.WaitForExit()
`$outText = `$stdout.GetAwaiter().GetResult()
`$errText = `$stderr.GetAwaiter().GetResult()
@(
    'EXITCODE=' + `$process.ExitCode
    '---STDOUT---'
    `$outText
    '---STDERR---'
    `$errText
) | Set-Content -LiteralPath '$($outputFile.Replace("'", "''"))' -Encoding UTF8
exit `$process.ExitCode
"@
            Set-Content -LiteralPath $jobFile -Value $jobScript -Encoding UTF8

            $workerProcess = Start-Process -FilePath (Join-Path $PSHOME "powershell.exe") -ArgumentList @(
                "-NoProfile",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                $jobFile
            ) -PassThru -WindowStyle Hidden

            $waitSeconds = 0
            while (-not $workerProcess.HasExited) {
                Start-Sleep -Seconds 2
                $waitSeconds += 2
                $progressOffset = [Math]::Min(5, [Math]::Max(1, [Math]::Ceiling(($waitSeconds / [Math]::Max(1, $script:RepoSyncTimeoutSeconds)) * 5)))
                & $report ($HeartbeatProgress + [int]$progressOffset) $HeartbeatStatus ""
                if ($waitSeconds -ge $script:RepoSyncTimeoutSeconds) {
                    try {
                        $workerProcess.Kill()
                    }
                    catch {
                    }
                    throw "Timed out after $waitSeconds seconds."
                }
            }

            if (-not (Test-Path -LiteralPath $outputFile)) {
                throw "Process output file was not created."
            }

            $logLines = Get-Content -LiteralPath $outputFile
            foreach ($line in $logLines) {
                if ([string]::IsNullOrWhiteSpace($line)) {
                    continue
                }
                if ($line -eq "---STDOUT---" -or $line -eq "---STDERR---") {
                    continue
                }
                if ($line -like "EXITCODE=*") {
                    continue
                }
                & $ReportLog $line
            }

            $exitLine = $logLines | Where-Object { $_ -like "EXITCODE=*" } | Select-Object -First 1
            $exitCode = if ($exitLine) { [int]($exitLine -replace '^EXITCODE=', '') } else { $workerProcess.ExitCode }
            if ($exitCode -ne 0) {
                throw ("Process failed with exit code {0}: {1} {2}" -f $exitCode, $FilePath, ($ArgumentList -join ' '))
            }
        }
        finally {
            if (Test-Path -LiteralPath $jobFile) {
                Remove-Item -LiteralPath $jobFile -Force -ErrorAction SilentlyContinue
            }
            if (Test-Path -LiteralPath $outputFile) {
                Remove-Item -LiteralPath $outputFile -Force -ErrorAction SilentlyContinue
            }
        }
    }

    try {
        $providerDefinition = Get-ProviderDefinition -ProviderKey $Job.ProviderKey
        Set-DeploymentRoot -RootPath $Job.DeployRoot
        $Job.Workspace = Get-DefaultWorkspaceForRoot -RootPath $script:RootDir

        Ensure-Directory -Path $script:RuntimeDir
        Ensure-Directory -Path $script:DownloadsDir
        Ensure-Directory -Path $script:StateDir
        Ensure-Directory -Path $script:ResourcesDir
        Ensure-Directory -Path $Job.Workspace

        & $report 4 (Get-T -Key "status_preparing" -Language $Job.Language) ((Get-T -Key "log_root" -Language $Job.Language) + " " + $script:RootDir)
        & $reportLog ("Workspace: " + $Job.Workspace)
        Write-Launchers
        & $report 8 (Get-T -Key "status_preparing" -Language $Job.Language) (Get-T -Key "log_launchers" -Language $Job.Language)

        & $report 12 (Get-T -Key "status_checking_git" -Language $Job.Language) (Get-T -Key "log_check_git" -Language $Job.Language)
        $gitExe = Resolve-GitExecutable
        if ([string]::IsNullOrWhiteSpace($gitExe)) {
            & $report 14 (Get-T -Key "status_downloading_git" -Language $Job.Language) (Get-T -Key "log_fetch_git" -Language $Job.Language)
            $gitRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/git-for-windows/git/releases/latest" -Headers @{
                "User-Agent" = "OpenClaw-OneClick-Deploy"
                "Accept" = "application/vnd.github+json"
            }
            $gitAsset = $gitRelease.assets | Where-Object { $_.name -match '^MinGit-.*64-bit\.zip$' } | Select-Object -First 1
            if ($null -eq $gitAsset) {
                throw "Could not locate a MinGit 64-bit asset in the latest Git for Windows release."
            }
            $gitZipPath = Join-Path $script:DownloadsDir $gitAsset.name
            & $report 16 (Get-T -Key "status_downloading_git" -Language $Job.Language) ("Asset: " + $gitAsset.browser_download_url)
            Invoke-DownloadFile -Uri $gitAsset.browser_download_url -OutFile $gitZipPath -Headers @{ "User-Agent" = "OpenClaw-OneClick-Deploy" }
            Remove-DirectorySafe -Path $script:GitDir
            Expand-Archive -Path $gitZipPath -DestinationPath $script:GitDir -Force
            $gitExe = Resolve-GitExecutable
            if ([string]::IsNullOrWhiteSpace($gitExe)) {
                throw "Git deploy failed. Missing usable git executable after download."
            }
        }
        else {
            & $report 16 (Get-T -Key "status_checking_git" -Language $Job.Language) ((Get-T -Key "log_use_existing_git" -Language $Job.Language) + " " + $gitExe)
        }
        & $report 24 (Get-T -Key "status_git_ready" -Language $Job.Language) ("Using: " + $gitExe)

        & $report 28 (Get-T -Key "status_checking_node" -Language $Job.Language) (Get-T -Key "log_check_node" -Language $Job.Language)
        $nodeExe = Resolve-NodeExecutable
        $npmCmd = $null
        if (-not [string]::IsNullOrWhiteSpace($nodeExe)) {
            $npmCmd = Get-NpmCommandFromNodePath -NodePath $nodeExe
        }

        if ([string]::IsNullOrWhiteSpace($nodeExe) -or [string]::IsNullOrWhiteSpace($npmCmd)) {
            & $report 30 (Get-T -Key "status_downloading_node" -Language $Job.Language) (Get-T -Key "log_fetch_node" -Language $Job.Language)
            $nodeIndex = Invoke-RestMethod -Uri "https://nodejs.org/dist/index.json"
            $nodeRelease = $nodeIndex | Where-Object { $_.version -match '^v24\.' -and $_.files -contains 'win-x64-zip' } | Select-Object -First 1
            if ($null -eq $nodeRelease) {
                throw "Could not locate a Node.js 24 x64 zip release."
            }
            $nodeVersion = $nodeRelease.version
            $nodeZipName = "node-$nodeVersion-win-x64.zip"
            $nodeZipUrl = "https://nodejs.org/dist/$nodeVersion/$nodeZipName"
            $nodeZipPath = Join-Path $script:DownloadsDir $nodeZipName
            & $report 32 (Get-T -Key "status_downloading_node" -Language $Job.Language) ("Asset: " + $nodeZipUrl)
            Invoke-DownloadFile -Uri $nodeZipUrl -OutFile $nodeZipPath
            $nodeTempDir = Join-Path $script:DownloadsDir ("node-extract-" + [Guid]::NewGuid().ToString("N"))
            Ensure-Directory -Path $nodeTempDir
            Expand-Archive -Path $nodeZipPath -DestinationPath $nodeTempDir -Force
            $expandedNodeDir = Get-ChildItem -LiteralPath $nodeTempDir -Directory | Select-Object -First 1
            if ($null -eq $expandedNodeDir) {
                throw "Node.js zip unpack failed."
            }
            Remove-DirectorySafe -Path $script:NodeDir
            Move-Item -LiteralPath $expandedNodeDir.FullName -Destination $script:NodeDir
            Remove-DirectorySafe -Path $nodeTempDir
            $nodeExe = Resolve-NodeExecutable
            if ([string]::IsNullOrWhiteSpace($nodeExe)) {
                throw "Node.js deploy failed. Missing usable node executable after download."
            }
            $npmCmd = Get-NpmCommandFromNodePath -NodePath $nodeExe
            if ([string]::IsNullOrWhiteSpace($npmCmd)) {
                throw "Node.js deploy failed. Missing usable npm command after download."
            }
        }
        else {
            & $report 32 (Get-T -Key "status_checking_node" -Language $Job.Language) ((Get-T -Key "log_use_existing_node" -Language $Job.Language) + " " + $nodeExe)
        }
        & $report 40 (Get-T -Key "status_node_ready" -Language $Job.Language) ("Using: " + $nodeExe)

        & $report 44 (Get-T -Key "status_checking_cli" -Language $Job.Language) (Get-T -Key "log_check_cli" -Language $Job.Language)
        $openClawCmd = Resolve-OpenClawCommand
        if ([string]::IsNullOrWhiteSpace($openClawCmd)) {
            & $report 46 (Get-T -Key "status_installing_cli" -Language $Job.Language) (Get-T -Key "log_install_cli" -Language $Job.Language)
            Ensure-Directory -Path $script:NpmPrefixDir
            Ensure-Directory -Path $script:NpmCacheDir
            $nodeParentDir = Split-Path -Parent $nodeExe
            $npmEnv = @{
                "PATH" = "$nodeParentDir;$($env:PATH)"
                "npm_config_cache" = $script:NpmCacheDir
            }
            & $reportLog ("Install target: " + $script:NpmPrefixDir)
            Invoke-LoggedProcess -FilePath $npmCmd -ArgumentList @("install", "--global", "openclaw@latest", "--prefix", $script:NpmPrefixDir) -WorkingDirectory $script:RootDir -EnvironmentVariables $npmEnv -ReportLog $reportLog
            $openClawCmd = Resolve-OpenClawCommand
            if ([string]::IsNullOrWhiteSpace($openClawCmd)) {
                throw "OpenClaw CLI install failed. Missing usable openclaw command after install."
            }
        }
        else {
            & $report 46 (Get-T -Key "status_checking_cli" -Language $Job.Language) ((Get-T -Key "log_use_existing_cli" -Language $Job.Language) + " " + $openClawCmd)
        }
        $localOpenClawCmd = Join-Path $script:NpmPrefixDir "openclaw.cmd"
        if (-not (Test-Path -LiteralPath $localOpenClawCmd)) {
            throw "OpenClaw CLI install failed. Missing local CLI at $localOpenClawCmd"
        }
        $openClawCmd = $localOpenClawCmd
        & $report 56 (Get-T -Key "status_cli_ready" -Language $Job.Language) ("CLI path: " + $openClawCmd)

        if ($Job.CloneOfficialRepo) {
            & $report 60 (Get-T -Key "status_syncing_repo" -Language $Job.Language) ((Get-T -Key "log_repo_target" -Language $Job.Language) + " " + $script:SourceDir)
            $repoEnv = @{ "PATH" = "$script:GitDir\cmd;$($env:PATH)" }
            $repoSyncCompleted = $false
            & $reportLog (Get-T -Key "log_repo_running" -Language $Job.Language)

            try {
                if (-not (Test-Path -LiteralPath $script:SourceDir)) {
                    & $invokeLoggedProcessWithHeartbeat $gitExe @("clone", "--depth", "1", "https://github.com/openclaw/openclaw.git", $script:SourceDir) $script:RootDir $repoEnv 60 (Get-T -Key "status_syncing_repo" -Language $Job.Language) (Get-T -Key "log_repo_running" -Language $Job.Language)
                    $repoSyncCompleted = $true
                }
                elseif (Test-Path -LiteralPath (Join-Path $script:SourceDir ".git")) {
                    & $invokeLoggedProcessWithHeartbeat $gitExe @("-C", $script:SourceDir, "pull", "--ff-only") $script:RootDir $repoEnv 60 (Get-T -Key "status_syncing_repo" -Language $Job.Language) (Get-T -Key "log_repo_running" -Language $Job.Language)
                    $repoSyncCompleted = $true
                }
                else {
                    & $report 66 (Get-T -Key "status_repo_skipped" -Language $Job.Language) ((Get-T -Key "log_repo_missing_git" -Language $Job.Language) + " " + $script:SourceDir)
                }
            }
            catch {
                $repoSyncError = Get-ErrorMessage -ErrorObject $_
                $repoSkipKey = if ($repoSyncError -like "Timed out after*") { "log_repo_timeout" } else { "log_repo_skip" }
                & $report 66 (Get-T -Key "status_repo_skipped" -Language $Job.Language) ((Get-T -Key $repoSkipKey -Language $Job.Language) + " " + $repoSyncError)
            }

            if ($repoSyncCompleted) {
                & $report 66 (Get-T -Key "status_repo_ready" -Language $Job.Language) (Get-T -Key "log_repo_done" -Language $Job.Language)
            }
            else {
                & $report 68 (Get-T -Key "status_repo_skipped" -Language $Job.Language) (Get-T -Key "log_repo_skipped_continue" -Language $Job.Language)
            }
        }

        & $report 70 (Get-T -Key "status_writing_env" -Language $Job.Language) ((Get-T -Key "log_env_file" -Language $Job.Language) + " " + $script:EnvFilePath)
        $envMap = Get-ExistingEnvMap -Path $script:EnvFilePath
        if (-not $envMap.ContainsKey("OPENCLAW_GATEWAY_TOKEN") -or [string]::IsNullOrWhiteSpace([string]$envMap["OPENCLAW_GATEWAY_TOKEN"])) {
            $gatewayTokenBytes = New-Object byte[] 24
            [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($gatewayTokenBytes)
            $envMap["OPENCLAW_GATEWAY_TOKEN"] = [Convert]::ToBase64String($gatewayTokenBytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')
        }
        if (-not [string]::IsNullOrWhiteSpace($Job.ApiKey) -and $null -ne $providerDefinition.EnvKey) {
            $envMap[$providerDefinition.EnvKey] = $Job.ApiKey
        }
        Set-Content -LiteralPath $script:EnvFilePath -Value (ConvertTo-DotEnvText -Map $envMap) -Encoding ASCII

        & $report 76 (Get-T -Key "status_onboard" -Language $Job.Language) (Get-T -Key "log_onboard_start" -Language $Job.Language)
        $openClawEnv = @{
            "OPENCLAW_STATE_DIR" = $script:StateDir
            "OPENCLAW_CONFIG_PATH" = $script:ConfigFilePath
            "PATH" = "$script:GitDir\cmd;$script:NodeDir;$script:NpmPrefixDir;$($env:PATH)"
            "OPENCLAW_GATEWAY_TOKEN" = [string]$envMap["OPENCLAW_GATEWAY_TOKEN"]
        }
        if (-not [string]::IsNullOrWhiteSpace($Job.ApiKey) -and $null -ne $providerDefinition.EnvKey) {
            $openClawEnv[$providerDefinition.EnvKey] = $Job.ApiKey
        }

        $providerForOnboarding = $providerDefinition
        if ($providerDefinition.RequiresKey -and [string]::IsNullOrWhiteSpace($Job.ApiKey)) {
            $providerForOnboarding = Get-ProviderDefinition -ProviderKey "Skip"
            & $report 78 (Get-T -Key "status_onboard" -Language $Job.Language) (Get-T -Key "log_no_key" -Language $Job.Language)
        }

        if ($Job.ProviderKey -eq "Custom" -and [string]::IsNullOrWhiteSpace($Job.BaseUrl)) {
            throw "Custom provider requires a Base URL."
        }

        $onboardArgs = New-Object System.Collections.Generic.List[string]
        $null = $onboardArgs.Add("onboard")
        $null = $onboardArgs.Add("--non-interactive")
        $null = $onboardArgs.Add("--reset")
        $null = $onboardArgs.Add("--mode")
        $null = $onboardArgs.Add("local")
        $null = $onboardArgs.Add("--workspace")
        $null = $onboardArgs.Add($Job.Workspace)
        $null = $onboardArgs.Add("--gateway-port")
        $null = $onboardArgs.Add($script:GatewayPort)
        $null = $onboardArgs.Add("--gateway-bind")
        $null = $onboardArgs.Add($script:GatewayBind)
        $null = $onboardArgs.Add("--gateway-auth")
        $null = $onboardArgs.Add("token")
        $null = $onboardArgs.Add("--gateway-token")
        $null = $onboardArgs.Add([string]$envMap["OPENCLAW_GATEWAY_TOKEN"])
        $null = $onboardArgs.Add("--auth-choice")
        $null = $onboardArgs.Add([string]$providerForOnboarding.AuthChoice)
        $null = $onboardArgs.Add("--secret-input-mode")
        $null = $onboardArgs.Add("ref")
        $null = $onboardArgs.Add("--daemon-runtime")
        $null = $onboardArgs.Add("node")
        $null = $onboardArgs.Add("--skip-skills")
        $null = $onboardArgs.Add("--skip-health")
        $null = $onboardArgs.Add("--accept-risk")
        if ($Job.InstallDaemon) {
            $null = $onboardArgs.Add("--install-daemon")
        }

        if ($Job.ProviderKey -eq "Custom" -and $providerForOnboarding.AuthChoice -ne "skip") {
            $null = $onboardArgs.Add("--custom-base-url")
            $null = $onboardArgs.Add($Job.BaseUrl)
            if (-not [string]::IsNullOrWhiteSpace($Job.Model)) {
                $null = $onboardArgs.Add("--custom-model-id")
                $null = $onboardArgs.Add($Job.Model)
            }
            $null = $onboardArgs.Add("--custom-compatibility")
            $null = $onboardArgs.Add("openai")
        }

        if ($Job.ProviderKey -eq "Ollama") {
            if (-not [string]::IsNullOrWhiteSpace($Job.BaseUrl)) {
                $null = $onboardArgs.Add("--custom-base-url")
                $null = $onboardArgs.Add($Job.BaseUrl)
            }
            if (-not [string]::IsNullOrWhiteSpace($Job.Model)) {
                $null = $onboardArgs.Add("--custom-model-id")
                $null = $onboardArgs.Add($Job.Model)
            }
        }

        & $report 82 "Running OpenClaw onboard..." ("Command: openclaw " + ($onboardArgs -join ' '))
        Invoke-LoggedProcess -FilePath $openClawCmd -ArgumentList $onboardArgs.ToArray() -WorkingDirectory $script:RootDir -EnvironmentVariables $openClawEnv -ReportLog $reportLog
        & $report 90 (Get-T -Key "status_onboard_done" -Language $Job.Language) (Get-T -Key "log_base_deploy_done" -Language $Job.Language)

        if (-not [string]::IsNullOrWhiteSpace($Job.Model)) {
            & $report 94 (Get-T -Key "status_setting_model" -Language $Job.Language) ((Get-T -Key "log_set_model" -Language $Job.Language) + " " + $Job.Model)
            Invoke-LoggedProcess -FilePath $openClawCmd -ArgumentList @("models", "set", $Job.Model) -WorkingDirectory $script:RootDir -EnvironmentVariables $openClawEnv -ReportLog $reportLog
        }

        & $report 97 (Get-T -Key "status_validating" -Language $Job.Language) (Get-T -Key "log_validate" -Language $Job.Language)
        Invoke-LoggedProcess -FilePath $openClawCmd -ArgumentList @("config", "validate") -WorkingDirectory $script:RootDir -EnvironmentVariables $openClawEnv -ReportLog $reportLog

        & $report 100 (Get-T -Key "status_complete" -Language $Job.Language) (Get-T -Key "log_complete" -Language $Job.Language)
        & $writeEvent "result" 100 (Get-T -Key "status_complete" -Language $Job.Language) "" $true ""
    }
    catch {
        $errorMessage = Get-ErrorMessage -ErrorObject $_
        & $report $Job.Progress (Get-T -Key "status_failed" -Language $Job.Language) $errorMessage
        & $writeEvent "result" $Job.Progress (Get-T -Key "status_failed" -Language $Job.Language) "" $false $errorMessage
    }
}

Hide-ConsoleWindow
if (-not $WorkerMode) {
    Set-DeploymentRoot -RootPath $script:LauncherDir
    Reset-DebugTrace
    Write-DebugTrace ("Launcher session started. version=v" + $script:AppVersion)
}

function Ensure-Directory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        [void](New-Item -ItemType Directory -Path $Path -Force)
    }
}

function Remove-DirectorySafe {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (Test-Path -LiteralPath $Path) {
        Remove-Item -LiteralPath $Path -Recurse -Force
    }
}

function Clear-ModelSyncTempDirectories {
    if (-not (Test-Path -LiteralPath $script:DownloadsDir)) {
        return
    }

    foreach ($directory in Get-ChildItem -LiteralPath $script:DownloadsDir -Directory -Filter "model-sync-package-*" -ErrorAction SilentlyContinue) {
        try {
            Remove-Item -LiteralPath $directory.FullName -Recurse -Force
        }
        catch {
        }
    }
}

function Get-ExistingEnvMap {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $map = @{}
    if (-not (Test-Path -LiteralPath $Path)) {
        return $map
    }

    foreach ($line in Get-Content -LiteralPath $Path) {
        if ($line -match '^\s*#') {
            continue
        }

        if ($line -match '^\s*([A-Za-z_][A-Za-z0-9_]*)=(.*)$') {
            $key = $matches[1]
            $value = $matches[2].Trim()
            if ($value.StartsWith('"') -and $value.EndsWith('"') -and $value.Length -ge 2) {
                $value = $value.Substring(1, $value.Length - 2).Replace('\"', '"')
            }
            $map[$key] = $value
        }
    }

    return $map
}

function Get-DashboardUrl {
    param(
        [string]$BindMode = $script:GatewayBind,
        [string]$Port = $script:GatewayPort,
        [string]$Token = ""
    )

    $dashboardHost = "127.0.0.1"
    if ($BindMode -eq "custom") {
        $dashboardHost = "127.0.0.1"
    }

    $url = ("http://{0}:{1}/" -f $dashboardHost, $Port)
    if (-not [string]::IsNullOrWhiteSpace($Token)) {
        $url = $url + "#token=" + [System.Uri]::EscapeDataString($Token)
    }

    return $url
}

function Get-GatewayTokenFromEnvFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$EnvFilePath
    )

    $envMap = Get-ExistingEnvMap -Path $EnvFilePath
    if ($envMap.ContainsKey("OPENCLAW_GATEWAY_TOKEN")) {
        return [string]$envMap["OPENCLAW_GATEWAY_TOKEN"]
    }

    return ""
}

function Import-DotEnvToProcessEnvironment {
    param(
        [Parameter(Mandatory = $true)]
        [string]$EnvFilePath,
        [Parameter(Mandatory = $true)]
        [System.Diagnostics.ProcessStartInfo]$StartInfo
    )

    $envMap = Get-ExistingEnvMap -Path $EnvFilePath
    foreach ($entry in $envMap.GetEnumerator()) {
        if (-not [string]::IsNullOrWhiteSpace([string]$entry.Key)) {
            $StartInfo.Environment[[string]$entry.Key] = [string]$entry.Value
        }
    }
}

function Append-UiLog {
    param(
        [Parameter(Mandatory = $true)]
        [System.Windows.Forms.RichTextBox]$LogTextBox,
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    $timestamp = (Get-Date).ToString("HH:mm:ss")
    $LogTextBox.AppendText("[$timestamp] $Message`r`n")
    $LogTextBox.SelectionStart = $LogTextBox.TextLength
    $LogTextBox.ScrollToCaret()
}

function Set-ResultAccessState {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DeployRoot
    )

    $script:LastDeployRoot = $DeployRoot
    $script:LastGatewayToken = Get-GatewayTokenFromEnvFile -EnvFilePath (Join-Path (Join-Path $DeployRoot "openclaw-home") ".env")
    $script:LastDashboardUrl = Get-DashboardUrl -Token $script:LastGatewayToken
}

function Test-GatewayListening {
    param(
        [string]$HostName = "127.0.0.1",
        [int]$Port = [int]$script:GatewayPort
    )

    $tcpClient = $null
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $asyncResult = $tcpClient.BeginConnect($HostName, $Port, $null, $null)
        if (-not $asyncResult.AsyncWaitHandle.WaitOne(500, $false)) {
            return $false
        }

        $tcpClient.EndConnect($asyncResult)
        return $true
    }
    catch {
        return $false
    }
    finally {
        if ($tcpClient) {
            $tcpClient.Close()
        }
    }
}

function Stop-OpenClawGatewayOnPort {
    param(
        [int]$Port = [int]$script:GatewayPort
    )

    try {
        $listeners = @(Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue)
        foreach ($listener in $listeners) {
            $pid = [int]$listener.OwningProcess
            if ($pid -le 0 -or $pid -eq $PID) {
                continue
            }

            $processInfo = Get-CimInstance Win32_Process -Filter ("ProcessId = {0}" -f $pid) -ErrorAction SilentlyContinue
            $commandLine = if ($processInfo) { [string]$processInfo.CommandLine } else { "" }
            if ($commandLine -notmatch '(?i)openclaw' -or $commandLine -notmatch '(?i)gateway') {
                continue
            }

            Write-DebugTrace ("Stopping existing OpenClaw gateway PID=" + $pid + " on port " + $Port)
            Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
        }

        for ($attempt = 0; $attempt -lt 20; $attempt++) {
            if (-not (Test-GatewayListening -Port $Port)) {
                return
            }
            Start-Sleep -Milliseconds 250
        }
    }
    catch {
        Write-DebugTrace ("Failed to stop gateway on port " + $Port + ": " + (Get-ErrorMessage -ErrorObject $_))
    }
}

function Resolve-OpenClawCommandForRoot {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DeployRoot
    )

    $localOpenClaw = Join-Path (Join-Path (Join-Path $DeployRoot "runtime") "npm-global") "openclaw.cmd"
    if (Test-Path -LiteralPath $localOpenClaw) {
        return $localOpenClaw
    }

    foreach ($candidate in @("openclaw.cmd", "openclaw")) {
        $command = Get-CommandPathIfExists -CommandName $candidate
        if (-not [string]::IsNullOrWhiteSpace($command)) {
            return $command
        }
    }

    return $null
}

function Start-OpenClawGatewayForDeployRoot {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DeployRoot,
        [System.Windows.Forms.RichTextBox]$LogTextBox,
        [string]$Language = $script:CurrentLanguage
    )

    $resolvedRoot = [System.IO.Path]::GetFullPath($DeployRoot)
    Set-ResultAccessState -DeployRoot $resolvedRoot

    if ($script:GatewayProcess -and -not $script:GatewayProcess.HasExited -and (Test-GatewayListening)) {
        if ($LogTextBox) {
            Append-UiLog -LogTextBox $LogTextBox -Message ((Get-T -Key "log_gateway_already_running" -Language $Language) + " " + $script:LastDashboardUrl)
        }
        return $true
    }

    Stop-OpenClawGatewayOnPort -Port ([int]$script:GatewayPort)

    $openClawCmd = Resolve-OpenClawCommandForRoot -DeployRoot $resolvedRoot
    if ([string]::IsNullOrWhiteSpace($openClawCmd)) {
        throw "OpenClaw CLI not found. Run deployment first."
    }

    $runtimeDir = Join-Path $resolvedRoot "runtime"
    $stateDir = Join-Path $resolvedRoot "openclaw-home"
    $configPath = Join-Path $stateDir "openclaw.json"
    $gitDir = Join-Path $runtimeDir "git"
    $nodeDir = Join-Path $runtimeDir "node"
    $npmPrefixDir = Join-Path $runtimeDir "npm-global"

    if ($LogTextBox) {
        Append-UiLog -LogTextBox $LogTextBox -Message (Get-T -Key "log_gateway_starting" -Language $Language)
    }

    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $openClawCmd
    $startInfo.Arguments = ConvertTo-ProcessArgumentString -Arguments @(
        "gateway",
        "run",
        "--port",
        $script:GatewayPort,
        "--bind",
        $script:GatewayBind,
        "--auth",
        "token",
        "--force",
        "--verbose"
    )
    $startInfo.WorkingDirectory = $resolvedRoot
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.CreateNoWindow = $true
    $startInfo.Environment["OPENCLAW_STATE_DIR"] = $stateDir
    $startInfo.Environment["OPENCLAW_CONFIG_PATH"] = $configPath
    $startInfo.Environment["PATH"] = "$gitDir\cmd;$nodeDir;$npmPrefixDir;$($env:PATH)"
    Import-DotEnvToProcessEnvironment -EnvFilePath (Join-Path $stateDir ".env") -StartInfo $startInfo
    if (-not [string]::IsNullOrWhiteSpace($script:LastGatewayToken)) {
        $startInfo.Environment["OPENCLAW_GATEWAY_TOKEN"] = $script:LastGatewayToken
    }

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo
    if (-not $process.Start()) {
        throw "Gateway process did not start."
    }

    $script:GatewayProcess = $process
    Write-DebugTrace ("Started gateway PID=" + $process.Id + "; root=" + $resolvedRoot)

    for ($attempt = 0; $attempt -lt 40; $attempt++) {
        Start-Sleep -Milliseconds 250
        if (Test-GatewayListening) {
            if ($LogTextBox) {
                Append-UiLog -LogTextBox $LogTextBox -Message ((Get-T -Key "log_gateway_started" -Language $Language) + " " + $script:LastDashboardUrl)
            }
            return $true
        }

        if ($process.HasExited) {
            $stdout = ""
            $stderr = ""
            try { $stdout = $process.StandardOutput.ReadToEnd() } catch {}
            try { $stderr = $process.StandardError.ReadToEnd() } catch {}
            $details = (($stdout, $stderr) -join "`n").Trim()
            if ([string]::IsNullOrWhiteSpace($details)) {
                $details = "exit code " + $process.ExitCode
            }
            throw $details
        }
    }

    throw "Gateway port $script:GatewayPort did not become ready within 10 seconds."
}

function Set-PanelStyle {
    param(
        [Parameter(Mandatory = $true)]
        [System.Windows.Forms.Control]$Control,
        [System.Drawing.Color]$BackColor = $script:Theme.Panel,
        [int]$Radius = 16
    )

    $Control.BackColor = $BackColor
    if ($Control.PSObject.Properties.Name -contains "BorderStyle") {
        $Control.BorderStyle = "FixedSingle"
    }
    $Control.Region = $null
}

function Set-InputStyle {
    param(
        [Parameter(Mandatory = $true)]
        [System.Windows.Forms.Control]$Control,
        [bool]$ReadOnly = $false
    )

    $Control.BackColor = if ($ReadOnly) { $script:Theme.Control } else { $script:Theme.Input }
    $Control.ForeColor = if ($ReadOnly) { $script:Theme.Muted } else { $script:Theme.Text }
    if ($Control.PSObject.Properties.Name -contains "FlatStyle") {
        $Control.FlatStyle = "Flat"
    }
    if ($Control.PSObject.Properties.Name -contains "BorderStyle") {
        $Control.BorderStyle = "FixedSingle"
    }
    $Control.Region = $null
}

function Set-VsCodeButtonStyle {
    param(
        [Parameter(Mandatory = $true)]
        [System.Windows.Forms.Button]$Button,
        [System.Drawing.Color]$BackColor = $script:Theme.Control,
        [System.Drawing.Color]$ForeColor = $script:Theme.Text,
        [bool]$Primary = $false
    )

    $Button.FlatStyle = "Flat"
    $Button.BackColor = $BackColor
    $Button.ForeColor = $ForeColor
    $Button.Region = $null
    $Button.FlatAppearance.BorderSize = if ($Primary) { 0 } else { 1 }
    $Button.FlatAppearance.BorderColor = if ($Primary) { $script:Theme.Accent } else { $script:Theme.Border }
    if ($Primary) {
        $Button.FlatAppearance.MouseOverBackColor = $script:Theme.AccentHover
        $Button.FlatAppearance.MouseDownBackColor = $script:Theme.AccentDown
    }
    else {
        $Button.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(59, 66, 80)
        $Button.FlatAppearance.MouseDownBackColor = $script:Theme.Panel
    }
    $Button.UseVisualStyleBackColor = $false
}

function Set-CheckBoxStyle {
    param(
        [Parameter(Mandatory = $true)]
        [System.Windows.Forms.CheckBox]$CheckBox,
        [System.Drawing.Color]$BackColor = $script:Theme.Window
    )

    $CheckBox.BackColor = $BackColor
    $CheckBox.ForeColor = $script:Theme.Text
    $CheckBox.FlatStyle = "Flat"
    $CheckBox.FlatAppearance.BorderColor = $script:Theme.Border
    $CheckBox.FlatAppearance.CheckedBackColor = $script:Theme.Control
    $CheckBox.UseVisualStyleBackColor = $false
}

function Set-LabelStyle {
    param(
        [Parameter(Mandatory = $true)]
        [System.Windows.Forms.Label]$Label,
        [System.Drawing.Color]$ForeColor = $script:Theme.Text
    )

    $Label.ForeColor = $ForeColor
    $Label.BackColor = [System.Drawing.Color]::Transparent
}

function Set-TextColorsRecursive {
    param(
        [Parameter(Mandatory = $true)]
        [System.Windows.Forms.Control]$Root
    )

    foreach ($child in $Root.Controls) {
        if ($child -is [System.Windows.Forms.Label]) {
            $current = $child.ForeColor
            if ($current.ToArgb() -eq [System.Drawing.SystemColors]::ControlText.ToArgb() -or $current.ToArgb() -eq [System.Drawing.Color]::Black.ToArgb()) {
                Set-LabelStyle -Label $child -ForeColor $script:Theme.Text
            }
        }
        elseif ($child -is [System.Windows.Forms.LinkLabel]) {
            $child.BackColor = [System.Drawing.Color]::Transparent
        }
        if ($child.Controls.Count -gt 0) {
            Set-TextColorsRecursive -Root $child
        }
    }
}

function ConvertTo-DotEnvText {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Map
    )

    $lines = @(
        "# Managed by OpenClaw-OneClick-Deploy.ps1",
        "# Re-running the deployer may refresh known keys."
    )

    foreach ($entry in $Map.GetEnumerator() | Sort-Object Key) {
        $value = [string]$entry.Value
        if ($value -match '[\s"#]') {
            $escaped = $value.Replace('"', '\"')
            $lines += ('{0}="{1}"' -f $entry.Key, $escaped)
        }
        else {
            $lines += ('{0}={1}' -f $entry.Key, $value)
        }
    }

    return ($lines -join [Environment]::NewLine)
}

function Get-ProviderKeys {
    return @(
        "Skip",
        "DeepSeek",
        "MoonshotCN",
        "Moonshot",
        "KimiCoding",
        "QwenStandardCN",
        "QwenCodingCN",
        "Volcengine",
        "MiniMaxCN",
        "ZAI",
        "OpenAI",
        "OpenRouter",
        "xAI",
        "Anthropic",
        "Ollama",
        "Custom"
    )
}

function Get-ProviderDefinition {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProviderKey
    )

    $definitions = @{
        Skip = @{
            DisplayName = "provider_Skip"
            AuthChoice = "skip"
            EnvKey = $null
            SupportsBaseUrl = $false
            RequiresKey = $false
            DefaultModel = ""
        }
        OpenAI = @{
            DisplayName = "provider_OpenAI"
            AuthChoice = "openai-api-key"
            EnvKey = "OPENAI_API_KEY"
            SupportsBaseUrl = $false
            RequiresKey = $true
            DefaultModel = "openai/gpt-5.5"
        }
        OpenRouter = @{
            DisplayName = "provider_OpenRouter"
            AuthChoice = "openrouter-api-key"
            EnvKey = "OPENROUTER_API_KEY"
            SupportsBaseUrl = $false
            RequiresKey = $true
            DefaultModel = "openrouter/auto"
        }
        DeepSeek = @{
            DisplayName = "provider_DeepSeek"
            AuthChoice = "deepseek-api-key"
            EnvKey = "DEEPSEEK_API_KEY"
            SupportsBaseUrl = $false
            RequiresKey = $true
            DefaultModel = "deepseek/deepseek-chat"
        }
        MoonshotCN = @{
            DisplayName = "provider_MoonshotCN"
            AuthChoice = "moonshot-api-key-cn"
            EnvKey = "MOONSHOT_API_KEY"
            SupportsBaseUrl = $false
            RequiresKey = $true
            DefaultModel = "moonshot/kimi-k2.5"
        }
        Moonshot = @{
            DisplayName = "provider_Moonshot"
            AuthChoice = "moonshot-api-key"
            EnvKey = "MOONSHOT_API_KEY"
            SupportsBaseUrl = $false
            RequiresKey = $true
            DefaultModel = "moonshot/kimi-k2.5"
        }
        KimiCoding = @{
            DisplayName = "provider_KimiCoding"
            AuthChoice = "kimi-code-api-key"
            EnvKey = "KIMI_API_KEY"
            SupportsBaseUrl = $false
            RequiresKey = $true
            DefaultModel = "kimi-coding/k2p6"
        }
        QwenStandardCN = @{
            DisplayName = "provider_QwenStandardCN"
            AuthChoice = "qwen-standard-api-key-cn"
            EnvKey = "QWEN_API_KEY"
            SupportsBaseUrl = $false
            RequiresKey = $true
            DefaultModel = "qwen/qwen3.5-plus"
        }
        QwenCodingCN = @{
            DisplayName = "provider_QwenCodingCN"
            AuthChoice = "qwen-api-key-cn"
            EnvKey = "QWEN_API_KEY"
            SupportsBaseUrl = $false
            RequiresKey = $true
            DefaultModel = "qwen/qwen3.5-plus"
        }
        Volcengine = @{
            DisplayName = "provider_Volcengine"
            AuthChoice = "volcengine-api-key"
            EnvKey = "VOLCANO_ENGINE_API_KEY"
            SupportsBaseUrl = $false
            RequiresKey = $true
            DefaultModel = "volcengine-plan/ark-code-latest"
        }
        MiniMaxCN = @{
            DisplayName = "provider_MiniMaxCN"
            AuthChoice = "minimax-cn-api"
            EnvKey = "MINIMAX_API_KEY"
            SupportsBaseUrl = $false
            RequiresKey = $true
            DefaultModel = "minimax/MiniMax-M2.7"
        }
        xAI = @{
            DisplayName = "provider_xAI"
            AuthChoice = "xai-api-key"
            EnvKey = "XAI_API_KEY"
            SupportsBaseUrl = $false
            RequiresKey = $true
            DefaultModel = "xai/grok-4"
        }
        ZAI = @{
            DisplayName = "provider_ZAI"
            AuthChoice = "zai-api-key"
            EnvKey = "ZAI_API_KEY"
            SupportsBaseUrl = $false
            RequiresKey = $true
            DefaultModel = "zai/glm-5.1"
        }
        Anthropic = @{
            DisplayName = "provider_Anthropic"
            AuthChoice = "apiKey"
            EnvKey = "ANTHROPIC_API_KEY"
            SupportsBaseUrl = $false
            RequiresKey = $true
            DefaultModel = "anthropic/claude-opus-4-6"
        }
        Ollama = @{
            DisplayName = "provider_Ollama"
            AuthChoice = "ollama"
            EnvKey = $null
            SupportsBaseUrl = $true
            RequiresKey = $false
            DefaultModel = "qwen3.5:27b"
        }
        Custom = @{
            DisplayName = "provider_Custom"
            AuthChoice = "custom-api-key"
            EnvKey = "CUSTOM_API_KEY"
            SupportsBaseUrl = $true
            RequiresKey = $true
            DefaultModel = "your-model-id"
        }
    }

    if (-not $definitions.ContainsKey($ProviderKey)) {
        throw "Unknown provider key: $ProviderKey"
    }

    return $definitions[$ProviderKey]
}

function Get-ObjectPropertyValue {
    param(
        [object]$InputObject,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if ($null -eq $InputObject) {
        return $null
    }

    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $null
    }

    return $property.Value
}

function Select-UniqueNonEmptyStrings {
    param(
        [object[]]$Items,
        [bool]$AllowEmpty = $false
    )

    $seen = @{}
    $result = New-Object System.Collections.Generic.List[string]
    foreach ($item in @($Items)) {
        if ($null -eq $item) {
            continue
        }

        $text = ([string]$item).Trim()
        if (-not $AllowEmpty -and [string]::IsNullOrWhiteSpace($text)) {
            continue
        }

        $key = $text.ToLowerInvariant()
        if (-not $seen.ContainsKey($key)) {
            $seen[$key] = $true
            [void]$result.Add($text)
        }
    }

    return $result.ToArray()
}

function Get-ProviderCatalogIds {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProviderKey
    )

    switch ($ProviderKey) {
        "OpenAI" { return @("openai") }
        "OpenRouter" { return @("openrouter") }
        "DeepSeek" { return @("deepseek") }
        "MoonshotCN" { return @("moonshot") }
        "Moonshot" { return @("moonshot") }
        "KimiCoding" { return @("kimi", "kimi-coding", "moonshot") }
        "QwenStandardCN" { return @("qwen", "modelstudio", "dashscope", "qwencloud") }
        "QwenCodingCN" { return @("qwen", "modelstudio", "dashscope", "qwencloud") }
        "Volcengine" { return @("volcengine-plan", "volcengine") }
        "MiniMaxCN" { return @("minimax", "minimax-portal") }
        "ZAI" { return @("zai") }
        "xAI" { return @("xai") }
        "Anthropic" { return @("anthropic") }
        "Ollama" { return @("ollama") }
        default { return @() }
    }
}

function Get-OpenClawPackageRoots {
    $candidates = New-Object System.Collections.Generic.List[string]

    foreach ($candidate in @(
        (Join-Path $script:NpmPrefixDir "node_modules\openclaw"),
        (Join-Path (Join-Path $env:APPDATA "npm") "node_modules\openclaw")
    )) {
        if (-not [string]::IsNullOrWhiteSpace($candidate)) {
            [void]$candidates.Add($candidate)
        }
    }

    foreach ($commandCandidate in @(
        (Join-Path $script:NpmPrefixDir "openclaw.cmd"),
        (Join-Path (Join-Path $env:APPDATA "npm") "openclaw.cmd")
    )) {
        if (Test-Path -LiteralPath $commandCandidate) {
            $commandDir = Split-Path -Parent $commandCandidate
            [void]$candidates.Add((Join-Path $commandDir "node_modules\openclaw"))
        }
    }

    return @(Select-UniqueNonEmptyStrings -Items ($candidates.ToArray()) | Where-Object { Test-Path -LiteralPath $_ })
}

function Get-OpenClawManifestModelOptions {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProviderKey
    )

    $providerIds = @(Get-ProviderCatalogIds -ProviderKey $ProviderKey)
    if ($providerIds.Count -eq 0) {
        return @()
    }

    $models = New-Object System.Collections.Generic.List[string]
    foreach ($root in Get-OpenClawPackageRoots) {
        $extensionsDir = Join-Path $root "dist\extensions"
        if (-not (Test-Path -LiteralPath $extensionsDir)) {
            continue
        }

        foreach ($manifestFile in Get-ChildItem -LiteralPath $extensionsDir -Recurse -Filter "openclaw.plugin.json" -ErrorAction SilentlyContinue) {
            try {
                $manifest = Get-Content -LiteralPath $manifestFile.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
                $modelCatalog = Get-ObjectPropertyValue -InputObject $manifest -Name "modelCatalog"
                $providers = Get-ObjectPropertyValue -InputObject $modelCatalog -Name "providers"
                if ($null -eq $providers) {
                    continue
                }

                foreach ($providerId in $providerIds) {
                    $providerCatalog = Get-ObjectPropertyValue -InputObject $providers -Name $providerId
                    $providerModels = Get-ObjectPropertyValue -InputObject $providerCatalog -Name "models"
                    foreach ($model in @($providerModels)) {
                        $modelId = Get-ObjectPropertyValue -InputObject $model -Name "id"
                        if ([string]::IsNullOrWhiteSpace([string]$modelId)) {
                            continue
                        }

                        $modelText = ([string]$modelId).Trim()
                        if ($modelText.Contains("/")) {
                            [void]$models.Add($modelText)
                        }
                        else {
                            [void]$models.Add(("{0}/{1}" -f $providerId, $modelText))
                        }
                    }
                }
            }
            catch {
            }
        }
    }

    return @(Select-UniqueNonEmptyStrings -Items ($models.ToArray()))
}

function Get-OpenClawBundledModuleModelOptions {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProviderKey
    )

    $models = New-Object System.Collections.Generic.List[string]
    foreach ($root in Get-OpenClawPackageRoots) {
        $distDir = Join-Path $root "dist"
        if (-not (Test-Path -LiteralPath $distDir)) {
            continue
        }

        $moduleSpecs = @()
        switch ($ProviderKey) {
            "QwenStandardCN" {
                $moduleSpecs = @(@{ File = "models-BibziGt5.js"; Prefix = "qwen"; Pattern = 'id:\s*"([^"]+)"' })
            }
            "QwenCodingCN" {
                $moduleSpecs = @(@{ File = "models-BibziGt5.js"; Prefix = "qwen"; Pattern = 'id:\s*"([^"]+)"' })
            }
            "xAI" {
                $moduleSpecs = @(@{ File = "model-definitions-CsER1IBx.js"; Prefix = "xai"; Pattern = 'id:\s*"([^"]+)"' })
            }
            "MiniMaxCN" {
                $moduleSpecs = @(@{ File = "provider-models-wWx85uVe.js"; Prefix = "minimax"; Pattern = '"(MiniMax-[^"]+)"' })
            }
            default {
                $moduleSpecs = @()
            }
        }

        foreach ($spec in $moduleSpecs) {
            $filePath = Join-Path $distDir ([string]$spec.File)
            if (-not (Test-Path -LiteralPath $filePath)) {
                continue
            }

            try {
                $content = Get-Content -LiteralPath $filePath -Raw -Encoding UTF8
                foreach ($match in [regex]::Matches($content, [string]$spec.Pattern)) {
                    if ($match.Groups.Count -lt 2) {
                        continue
                    }

                    $modelId = $match.Groups[1].Value.Trim()
                    if ([string]::IsNullOrWhiteSpace($modelId)) {
                        continue
                    }
                    if ($modelId -eq [string]$spec.Prefix) {
                        continue
                    }

                    [void]$models.Add(("{0}/{1}" -f ([string]$spec.Prefix), $modelId))
                }
            }
            catch {
            }
        }
    }

    return @(Select-UniqueNonEmptyStrings -Items ($models.ToArray()))
}

function Get-ProviderModelOptions {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProviderKey
    )

    $options = @{
        Skip = @("")
        OpenAI = @(
            "openai/gpt-5.5",
            "openai/gpt-5.4",
            "openai/gpt-5.4-mini",
            "openai/gpt-5.3",
            "openai/gpt-5.2",
            "openai/gpt-5",
            "openai/gpt-5-mini",
            "openai/gpt-5-nano",
            "openai/gpt-4.1",
            "openai/gpt-4.1-mini",
            "openai/gpt-4.1-nano",
            "openai/o4-mini",
            "openai/o3",
            "openai/o3-mini"
        )
        OpenRouter = @(
            "openrouter/auto",
            "openrouter/openai/gpt-5.5",
            "openrouter/openai/gpt-5",
            "openrouter/anthropic/claude-sonnet-4.6",
            "openrouter/anthropic/claude-sonnet-4",
            "openrouter/deepseek/deepseek-v4-pro",
            "openrouter/deepseek/deepseek-v4-flash",
            "openrouter/moonshotai/kimi-k2.6",
            "openrouter/qwen/qwen3.5-plus",
            "openrouter/x-ai/grok-4"
        )
        DeepSeek = @(
            "deepseek/deepseek-chat",
            "deepseek/deepseek-reasoner",
            "deepseek/deepseek-v4-pro",
            "deepseek/deepseek-v4-flash"
        )
        MoonshotCN = @(
            "moonshot/kimi-k2.6",
            "moonshot/kimi-k2.5",
            "moonshot/kimi-k2-thinking",
            "moonshot/kimi-k2-thinking-turbo",
            "moonshot/kimi-k2-turbo",
            "moonshot/kimi-latest",
            "moonshot/kimi-thinking-preview"
        )
        Moonshot = @(
            "moonshot/kimi-k2.6",
            "moonshot/kimi-k2.5",
            "moonshot/kimi-k2-thinking",
            "moonshot/kimi-k2-thinking-turbo",
            "moonshot/kimi-k2-turbo",
            "moonshot/kimi-latest",
            "moonshot/kimi-thinking-preview"
        )
        KimiCoding = @(
            "kimi-coding/k2p6",
            "kimi-coding/kimi-for-coding",
            "kimi-coding/kimi-k2-thinking",
            "moonshot/kimi-k2.6",
            "moonshot/kimi-k2.5"
        )
        QwenStandardCN = @(
            "qwen/qwen3.5-plus",
            "qwen/qwen3.6-plus",
            "qwen/qwen3-max-2026-01-23",
            "qwen/qwen3-coder-next",
            "qwen/qwen3-coder-plus",
            "qwen/qwen-max",
            "qwen/qwen-plus",
            "qwen/qwen-turbo"
        )
        QwenCodingCN = @(
            "qwen/qwen3-coder-plus",
            "qwen/qwen3-coder-next",
            "qwen/qwen3.5-plus",
            "qwen/qwen3-max-2026-01-23",
            "qwen/MiniMax-M2.5",
            "qwen/glm-5",
            "qwen/glm-4.7",
            "qwen/kimi-k2.5"
        )
        Volcengine = @(
            "volcengine-plan/ark-code-latest",
            "volcengine/doubao-seed-code-preview-251028",
            "volcengine/doubao-seed-1-8-251228",
            "volcengine/doubao-seed-1-6-lite-251015",
            "volcengine/doubao-seed-1-6-thinking-250715",
            "volcengine/kimi-k2-5-260127",
            "volcengine/glm-4-7-251222",
            "volcengine/deepseek-v3-2-251201"
        )
        MiniMaxCN = @(
            "minimax/MiniMax-M2.7",
            "minimax/MiniMax-M2.7-highspeed",
            "minimax/MiniMax-M2.5",
            "minimax/MiniMax-M2.5-highspeed",
            "minimax/MiniMax-Text-01"
        )
        ZAI = @(
            "zai/glm-5.1",
            "zai/glm-5",
            "zai/glm-5-turbo",
            "zai/glm-5v-turbo",
            "zai/glm-4.7",
            "zai/glm-4.7-flash",
            "zai/glm-4.7-flashx",
            "zai/glm-4.6",
            "zai/glm-4.6v",
            "zai/glm-4.5",
            "zai/glm-4.5-air",
            "zai/glm-4.5-flash",
            "zai/glm-4.5v"
        )
        xAI = @(
            "xai/grok-4.3",
            "xai/grok-4",
            "xai/grok-4-fast",
            "xai/grok-4-fast-non-reasoning",
            "xai/grok-4-1-fast",
            "xai/grok-4-1-fast-non-reasoning",
            "xai/grok-4.20-beta-latest-reasoning",
            "xai/grok-4.20-beta-latest-non-reasoning",
            "xai/grok-code-fast-1",
            "xai/grok-3",
            "xai/grok-3-fast",
            "xai/grok-3-mini",
            "xai/grok-3-mini-fast"
        )
        Anthropic = @(
            "anthropic/claude-opus-4-7",
            "anthropic/claude-opus-4-6",
            "anthropic/claude-opus-4-5",
            "anthropic/claude-sonnet-4-6",
            "anthropic/claude-sonnet-4-5",
            "anthropic/claude-sonnet-4",
            "anthropic/claude-haiku-4-5"
        )
        Ollama = @(
            "qwen3.5:27b",
            "qwen3:32b",
            "qwen2.5-coder:32b",
            "deepseek-r1:32b",
            "deepseek-r1:14b",
            "llama3.3:70b",
            "gemma3:27b",
            "mistral-small:24b"
        )
        Custom = @(
            "your-model-id"
        )
    }

    if (-not $options.ContainsKey($ProviderKey)) {
        return @("")
    }

    $mergedOptions = New-Object System.Collections.Generic.List[string]
    foreach ($model in @($options[$ProviderKey])) {
        [void]$mergedOptions.Add([string]$model)
    }
    if ($script:SyncedOpenClawModels.ContainsKey($ProviderKey)) {
        foreach ($model in @($script:SyncedOpenClawModels[$ProviderKey])) {
            [void]$mergedOptions.Add([string]$model)
        }
    }

    return @(Select-UniqueNonEmptyStrings -Items ($mergedOptions.ToArray()) -AllowEmpty ($ProviderKey -eq "Skip"))
}

function Get-ProviderSelectionKey {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DisplayText,
        [string]$Language = $script:CurrentLanguage
    )

    foreach ($key in Get-ProviderKeys) {
        $definition = Get-ProviderDefinition -ProviderKey $key
        if ((Get-T -Key $definition.DisplayName -Language $Language) -eq $DisplayText) {
            return $key
        }
    }

    throw "Unknown provider display text: $DisplayText"
}

function Normalize-ModelId {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProviderKey,
        [string]$Model
    )

    if ([string]::IsNullOrWhiteSpace($Model)) {
        return ""
    }

    $trimmedModel = $Model.Trim()
    if ($trimmedModel.Contains("/")) {
        return $trimmedModel
    }

    switch ($ProviderKey) {
        "DeepSeek" { return "deepseek/$trimmedModel" }
        "MoonshotCN" { return "moonshot/$trimmedModel" }
        "Moonshot" { return "moonshot/$trimmedModel" }
        "KimiCoding" { return "kimi-coding/$trimmedModel" }
        "QwenStandardCN" { return "qwen/$trimmedModel" }
        "QwenCodingCN" { return "qwen/$trimmedModel" }
        "MiniMaxCN" { return "minimax/$trimmedModel" }
        "ZAI" { return "zai/$trimmedModel" }
        "OpenAI" { return "openai/$trimmedModel" }
        "OpenRouter" { return "openrouter/$trimmedModel" }
        "xAI" { return "xai/$trimmedModel" }
        "Anthropic" { return "anthropic/$trimmedModel" }
        "Volcengine" {
            if ($trimmedModel -match '(?i)(ark-code|coding|code)') {
                return "volcengine-plan/$trimmedModel"
            }
            return "volcengine/$trimmedModel"
        }
        default { return $trimmedModel }
    }
}

function ConvertTo-ProcessArgumentString {
    param(
        [string[]]$Arguments
    )

    if ($null -eq $Arguments -or $Arguments.Count -eq 0) {
        return ""
    }

    $encoded = foreach ($argument in $Arguments) {
        if ($null -eq $argument) {
            '""'
            continue
        }

        $argumentText = [string]$argument
        if ($argumentText -eq "") {
            '""'
            continue
        }

        if ($argumentText -notmatch '[\s"]') {
            $argumentText
            continue
        }

        '"' + ($argumentText -replace '(\\*)"', '$1$1\"' -replace '(\\+)$', '$1$1') + '"'
    }

    return ($encoded -join ' ')
}

function Get-CommandPathIfExists {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CommandName
    )

    try {
        $command = Get-Command -Name $CommandName -ErrorAction Stop | Select-Object -First 1
        if ($null -ne $command -and -not [string]::IsNullOrWhiteSpace([string]$command.Source)) {
            return [string]$command.Source
        }
    }
    catch {
    }

    return $null
}

function Test-ExecutableVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        [Parameter(Mandatory = $true)]
        [string[]]$ArgumentList,
        [hashtable]$EnvironmentVariables
    )

    if (-not (Test-Path -LiteralPath $FilePath)) {
        return $false
    }

    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $FilePath
        $psi.Arguments = ConvertTo-ProcessArgumentString -Arguments $ArgumentList
        $psi.UseShellExecute = $false
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.CreateNoWindow = $true
        if ($EnvironmentVariables) {
            foreach ($entry in $EnvironmentVariables.GetEnumerator()) {
                $psi.Environment[$entry.Key] = [string]$entry.Value
            }
        }

        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $psi
        $null = $process.Start()
        $null = $process.StandardOutput.ReadToEnd()
        $null = $process.StandardError.ReadToEnd()
        $process.WaitForExit()
        return ($process.ExitCode -eq 0)
    }
    catch {
        return $false
    }
}

function Resolve-GitExecutable {
    $portableGit = Join-Path $script:GitDir "cmd\git.exe"
    if (Test-ExecutableVersion -FilePath $portableGit -ArgumentList @("--version")) {
        return $portableGit
    }

    $systemGit = Get-CommandPathIfExists -CommandName "git.exe"
    if ([string]::IsNullOrWhiteSpace($systemGit)) {
        $systemGit = Get-CommandPathIfExists -CommandName "git"
    }

    if (-not [string]::IsNullOrWhiteSpace($systemGit) -and (Test-ExecutableVersion -FilePath $systemGit -ArgumentList @("--version"))) {
        return $systemGit
    }

    return $null
}

function Resolve-NodeExecutable {
    $portableNode = Join-Path $script:NodeDir "node.exe"
    if (Test-ExecutableVersion -FilePath $portableNode -ArgumentList @("--version")) {
        return $portableNode
    }

    $systemNode = Get-CommandPathIfExists -CommandName "node.exe"
    if ([string]::IsNullOrWhiteSpace($systemNode)) {
        $systemNode = Get-CommandPathIfExists -CommandName "node"
    }

    if (-not [string]::IsNullOrWhiteSpace($systemNode) -and (Test-ExecutableVersion -FilePath $systemNode -ArgumentList @("--version"))) {
        return $systemNode
    }

    return $null
}

function Get-NpmCommandFromNodePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$NodePath
    )

    $nodeDir = Split-Path -Parent $NodePath
    foreach ($candidate in @(
        (Join-Path $nodeDir "npm.cmd"),
        (Join-Path $nodeDir "npm")
    )) {
        if (Test-ExecutableVersion -FilePath $candidate -ArgumentList @("--version")) {
            return $candidate
        }
    }

    $systemNpm = Get-CommandPathIfExists -CommandName "npm.cmd"
    if ([string]::IsNullOrWhiteSpace($systemNpm)) {
        $systemNpm = Get-CommandPathIfExists -CommandName "npm"
    }

    if (-not [string]::IsNullOrWhiteSpace($systemNpm) -and (Test-ExecutableVersion -FilePath $systemNpm -ArgumentList @("--version"))) {
        return $systemNpm
    }

    return $null
}

function Resolve-OpenClawCommand {
    param(
        [bool]$AllowSystemFallback = $false
    )

    $localOpenClaw = Join-Path $script:NpmPrefixDir "openclaw.cmd"
    $portableNode = Join-Path $script:NodeDir "node.exe"
    $localOpenClawEnv = @{
        "PATH" = "$script:NodeDir;$script:NpmPrefixDir;$($env:PATH)"
    }
    if (Test-Path -LiteralPath $portableNode) {
        $localOpenClawEnv["PATHEXT"] = "$($env:PATHEXT);.JS"
    }

    if (Test-ExecutableVersion -FilePath $localOpenClaw -ArgumentList @("--help") -EnvironmentVariables $localOpenClawEnv) {
        return $localOpenClaw
    }

    if (-not $AllowSystemFallback) {
        return $null
    }

    $systemOpenClaw = Get-CommandPathIfExists -CommandName "openclaw.cmd"
    if ([string]::IsNullOrWhiteSpace($systemOpenClaw)) {
        $systemOpenClaw = Get-CommandPathIfExists -CommandName "openclaw"
    }

    if (-not [string]::IsNullOrWhiteSpace($systemOpenClaw) -and (Test-ExecutableVersion -FilePath $systemOpenClaw -ArgumentList @("--help"))) {
        return $systemOpenClaw
    }

    return $null
}

function Invoke-DownloadFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Uri,
        [Parameter(Mandatory = $true)]
        [string]$OutFile,
        [hashtable]$Headers
    )

    Ensure-Directory -Path (Split-Path -Parent $OutFile)
    if (Test-Path -LiteralPath $OutFile) {
        Remove-Item -LiteralPath $OutFile -Force
    }

    $requestParams = @{
        Uri     = $Uri
        OutFile = $OutFile
    }

    if ($Headers) {
        $requestParams.Headers = $Headers
    }

    Invoke-WebRequest @requestParams
}

function Invoke-LoggedProcess {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        [Parameter(Mandatory = $true)]
        [string[]]$ArgumentList,
        [Parameter(Mandatory = $true)]
        [string]$WorkingDirectory,
        [Parameter(Mandatory = $true)]
        [hashtable]$EnvironmentVariables,
        [Parameter(Mandatory = $true)]
        [scriptblock]$ReportLog
    )

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $FilePath
    $psi.Arguments = ConvertTo-ProcessArgumentString -Arguments $ArgumentList
    $psi.WorkingDirectory = $WorkingDirectory
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true

    foreach ($entry in $EnvironmentVariables.GetEnumerator()) {
        $psi.Environment[$entry.Key] = [string]$entry.Value
    }

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi

    $null = $process.Start()

    try {
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()

        while (-not $process.WaitForExit(250)) {
        }

        $process.WaitForExit()

        $stdoutText = $stdoutTask.GetAwaiter().GetResult()
        $stderrText = $stderrTask.GetAwaiter().GetResult()

        foreach ($line in (($stdoutText -split "`r?`n") + ($stderrText -split "`r?`n"))) {
            if (-not [string]::IsNullOrWhiteSpace($line)) {
                & $ReportLog $line.Trim()
            }
        }

        if ($process.ExitCode -ne 0) {
            throw "Process failed with exit code $($process.ExitCode): $FilePath $($ArgumentList -join ' ')"
        }
    }
    finally {
        $process.Dispose()
    }
}

function Write-Launchers {
    $commonBlock = @'
@echo off
set "ROOT=%~dp0"
set "OPENCLAW_STATE_DIR=%ROOT%openclaw-home"
set "OPENCLAW_CONFIG_PATH=%ROOT%openclaw-home\openclaw.json"
set "PATH=%ROOT%runtime\git\cmd;%ROOT%runtime\node;%ROOT%runtime\npm-global;%PATH%"
if exist "%ROOT%openclaw-home\.env" (
  for /f "usebackq eol=# tokens=1,* delims==" %%A in ("%ROOT%openclaw-home\.env") do (
    if not "%%A"=="" set "%%A=%%~B"
  )
)
set "OPENCLAW_CMD=%ROOT%runtime\npm-global\openclaw.cmd"
if not exist "%OPENCLAW_CMD%" for %%I in (openclaw.cmd) do set "OPENCLAW_CMD=%%~$PATH:I"
if not exist "%OPENCLAW_CMD%" (
  echo OpenClaw CLI has not been installed yet.
  pause
  exit /b 1
)
'@

    $files = @{
        "OpenClaw-Dashboard.cmd" = @(
            $commonBlock,
            'call "%OPENCLAW_CMD%" dashboard'
        ) -join "`r`n"
        "OpenClaw-Gateway.cmd" = @(
            $commonBlock,
            'call "%OPENCLAW_CMD%" gateway run --port 18789 --bind loopback --auth token --force --verbose'
        ) -join "`r`n"
        "OpenClaw-Shell.cmd" = @(
            $commonBlock,
            'title OpenClaw Local Shell',
            'cmd /k'
        ) -join "`r`n"
    }

    foreach ($entry in $files.GetEnumerator()) {
        Set-Content -LiteralPath (Join-Path $script:RootDir $entry.Key) -Value $entry.Value -Encoding ASCII
    }
}

function Set-DefaultFields {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProviderKey,
        [Parameter(Mandatory = $true)]
        [System.Windows.Forms.ComboBox]$ModelComboBox,
        [Parameter(Mandatory = $true)]
        [System.Windows.Forms.TextBox]$BaseUrlTextBox
    )

    $definition = Get-ProviderDefinition -ProviderKey $ProviderKey
    $modelOptions = @(Get-ProviderModelOptions -ProviderKey $ProviderKey)
    $ModelComboBox.Items.Clear()
    foreach ($modelOption in $modelOptions) {
        [void]$ModelComboBox.Items.Add($modelOption)
    }

    if ($ProviderKey -eq "Custom" -or $ProviderKey -eq "Ollama") {
        $ModelComboBox.DropDownStyle = "DropDown"
    }
    else {
        $ModelComboBox.DropDownStyle = "DropDownList"
    }

    if ($modelOptions.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace([string]$definition.DefaultModel)) {
        $ModelComboBox.SelectedItem = $definition.DefaultModel
    }
    else {
        $ModelComboBox.Text = [string]$definition.DefaultModel
    }

    switch ($ProviderKey) {
        "DeepSeek" {
            $BaseUrlTextBox.Text = ""
        }
        "MoonshotCN" {
            $BaseUrlTextBox.Text = ""
        }
        "Moonshot" {
            $BaseUrlTextBox.Text = ""
        }
        "KimiCoding" {
            $BaseUrlTextBox.Text = ""
        }
        "QwenStandardCN" {
            $BaseUrlTextBox.Text = ""
        }
        "QwenCodingCN" {
            $BaseUrlTextBox.Text = ""
        }
        "Volcengine" {
            $BaseUrlTextBox.Text = ""
        }
        "MiniMaxCN" {
            $BaseUrlTextBox.Text = ""
        }
        "Ollama" {
            $BaseUrlTextBox.Text = "http://127.0.0.1:11434"
        }
        "Custom" {
            $BaseUrlTextBox.Text = "https://your-endpoint/v1"
        }
        default {
            $BaseUrlTextBox.Text = ""
        }
    }

    $BaseUrlTextBox.Enabled = $definition.SupportsBaseUrl
}

function Convert-ProviderKeyToOpenClawProviderIds {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProviderKey
    )

    switch ($ProviderKey) {
        "OpenAI" { return @("openai") }
        "OpenRouter" { return @("openrouter") }
        "DeepSeek" { return @("deepseek") }
        "MoonshotCN" { return @("moonshot") }
        "Moonshot" { return @("moonshot") }
        "KimiCoding" { return @("kimi-coding", "kimi", "moonshot") }
        "QwenStandardCN" { return @("qwen", "modelstudio", "dashscope") }
        "QwenCodingCN" { return @("qwen", "modelstudio", "dashscope") }
        "Volcengine" { return @("volcengine-plan", "volcengine") }
        "MiniMaxCN" { return @("minimax") }
        "ZAI" { return @("zai") }
        "xAI" { return @("xai") }
        "Anthropic" { return @("anthropic") }
        default { return @() }
    }
}

function Get-SyncedModelCandidatesFromCliOutput {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProviderKey,
        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    $providerIds = @(Convert-ProviderKeyToOpenClawProviderIds -ProviderKey $ProviderKey)
    if ($providerIds.Count -eq 0) {
        return @()
    }

    $models = New-Object System.Collections.Generic.List[string]

    try {
        $json = $Text | ConvertFrom-Json
        foreach ($item in @($json.models)) {
            $key = Get-ObjectPropertyValue -InputObject $item -Name "key"
            if (-not [string]::IsNullOrWhiteSpace([string]$key)) {
                [void]$models.Add([string]$key)
            }
        }
    }
    catch {
    }

    foreach ($line in ($Text -split "`r?`n")) {
        $trimmedLine = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmedLine)) {
            continue
        }

        foreach ($providerId in $providerIds) {
            $escapedProvider = [regex]::Escape($providerId)
            $pattern = "(?i)\b$escapedProvider/[A-Za-z0-9][A-Za-z0-9._:@+\-]*"
            foreach ($match in [regex]::Matches($trimmedLine, $pattern)) {
                [void]$models.Add($match.Value)
            }
        }
    }

    return @(Select-UniqueNonEmptyStrings -Items ($models.ToArray()))
}

function Update-GuidePanel {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProviderKey,
        [Parameter(Mandatory = $true)]
        [hashtable]$GuideControls
    )

    $definition = Get-ProviderDefinition -ProviderKey $ProviderKey
    $translatedName = Get-T -Key $definition.DisplayName
    $modelOptions = @(Get-ProviderModelOptions -ProviderKey $ProviderKey)
    $modelPreview = if ($modelOptions.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace([string]$modelOptions[0])) {
        ($modelOptions | Select-Object -First 3) -join [Environment]::NewLine
    }
    else {
        Get-T -Key "guide_model_empty"
    }

    $GuideControls.ProviderValue.Text = $translatedName
    $GuideControls.ModelValue.Text = $modelPreview
    $GuideControls.KeyValue.Text = if ($definition.RequiresKey) { Get-T -Key "guide_key_input" } else { Get-T -Key "guide_key_none" }
    $GuideControls.KeyEnvValue.Text = if ($definition.EnvKey) { $definition.EnvKey } else { "-" }
    $GuideControls.BaseValue.Text = if ($definition.SupportsBaseUrl) { Get-T -Key "guide_base_required" } else { Get-T -Key "guide_base_optional" }
}

function Apply-Language {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Language,
        [Parameter(Mandatory = $true)]
        [hashtable]$Controls
    )

    $script:UiApplying = $true
    try {
        $previousLanguage = $script:CurrentLanguage
        $selectedProviderKey = "Skip"
        if ($Controls.ProviderComboBox.SelectedItem) {
            try {
                $selectedProviderKey = Get-ProviderSelectionKey -DisplayText $Controls.ProviderComboBox.SelectedItem.ToString() -Language $previousLanguage
            }
            catch {
                $selectedProviderKey = "Skip"
            }
        }

        $script:CurrentLanguage = $Language

        $Controls.Form.Text = (Get-T -Key "form_title") + " | v" + $script:AppVersion
        $Controls.TitleLabel.Text = Get-T -Key "title"
        $Controls.SubTitleLabel.Text = Get-T -Key "subtitle"
        $Controls.LanguageLabel.Text = Get-T -Key "language"
        $Controls.SettingsHeaderLabel.Text = Get-T -Key "settings_title"
        $Controls.SettingsStepsLabel.Text = Get-T -Key "settings_steps"
        $Controls.ProviderLabel.Text = Get-T -Key "provider"
        $Controls.ProviderHintLabel.Text = Get-T -Key "provider_hint"
        $Controls.ModelLabel.Text = Get-T -Key "model"
        $Controls.ModelHintLabel.Text = Get-T -Key "model_hint"
        $Controls.SyncModelsButton.Text = Get-T -Key "button_sync_models"
        $Controls.KeyLabel.Text = Get-T -Key "api_key"
        $Controls.KeyHintLabel.Text = Get-T -Key "api_key_hint"
        $Controls.ShowKeyCheckBox.Text = Get-T -Key "show_key"
        $Controls.BaseUrlLabel.Text = Get-T -Key "base_url"
        $Controls.BaseUrlHintLabel.Text = Get-T -Key "base_url_hint"
        $Controls.DeployRootLabel.Text = Get-T -Key "deploy_root"
        $Controls.DeployRootHintLabel.Text = Get-T -Key "deploy_root_hint"
        $Controls.BrowseDeployRootButton.Text = Get-T -Key "button_browse"
        $Controls.WorkspaceLabel.Text = Get-T -Key "workspace"
        $Controls.WorkspaceHintLabel.Text = Get-T -Key "workspace_hint"
        $Controls.GuideHeaderLabel.Text = Get-T -Key "guide_title"
        $Controls.GuideProviderLabel.Text = Get-T -Key "guide_provider"
        $Controls.GuideModelLabel.Text = Get-T -Key "guide_model"
        $Controls.GuideKeyLabel.Text = Get-T -Key "guide_key"
        $Controls.GuideKeyEnvLabel.Text = Get-T -Key "guide_key_env"
        $Controls.GuideBaseLabel.Text = Get-T -Key "guide_base"
        $Controls.GuideTipTextLabel.Text = Get-T -Key "guide_tip"
        $Controls.InstallDaemonCheckBox.Text = Get-T -Key "install_daemon"
        $Controls.CloneRepoCheckBox.Text = Get-T -Key "sync_repo"
        $Controls.StartButton.Text = Get-T -Key "button_start"
        $Controls.OpenFolderButton.Text = Get-T -Key "button_open_folder"
        $Controls.OpenHomeButton.Text = Get-T -Key "button_open_state"
        $Controls.OpenDashboardButton.Text = Get-T -Key "button_open_dashboard"
        $Controls.CopyUrlButton.Text = Get-T -Key "button_copy_url"
        $Controls.CopyTokenButton.Text = Get-T -Key "button_copy_token"
        $Controls.ClearLogButton.Text = Get-T -Key "button_clear_log"
        $Controls.CloseButton.Text = Get-T -Key "button_close"
        $Controls.FooterLabel.Text = Get-T -Key "author"

        $Controls.ProviderComboBox.Items.Clear()
        foreach ($key in Get-ProviderKeys) {
            $null = $Controls.ProviderComboBox.Items.Add((Get-T -Key (Get-ProviderDefinition -ProviderKey $key).DisplayName))
        }
        $Controls.ProviderComboBox.SelectedItem = Get-T -Key (Get-ProviderDefinition -ProviderKey $selectedProviderKey).DisplayName

        Update-GuidePanel -ProviderKey $selectedProviderKey -GuideControls $Controls.GuideControls
        Set-TextColorsRecursive -Root $Controls.Form
    }
    finally {
        $script:UiApplying = $false
    }
}

if ($WorkerMode) {
    try {
        if ([string]::IsNullOrWhiteSpace($WorkerJobFile)) {
            throw "WorkerJobFile is required in worker mode."
        }

        $jobJson = Get-Content -LiteralPath $WorkerJobFile -Raw -Encoding UTF8
        $jobObject = ConvertFrom-Json -InputObject $jobJson
        $job = @{
            ProviderKey = [string]$jobObject.ProviderKey
            Model = [string]$jobObject.Model
            ApiKey = [string]$jobObject.ApiKey
            BaseUrl = [string]$jobObject.BaseUrl
            DeployRoot = [string]$jobObject.DeployRoot
            Workspace = [string]$jobObject.Workspace
            InstallDaemon = [bool]$jobObject.InstallDaemon
            CloneOfficialRepo = [bool]$jobObject.CloneOfficialRepo
            Language = [string]$jobObject.Language
            Progress = [int]$jobObject.Progress
            Status = [string]$jobObject.Status
        }
        $eventFile = [System.IO.Path]::ChangeExtension($WorkerJobFile, ".events.jsonl")
        Invoke-WorkerDeployment -Job $job -EventFile $eventFile
    }
    catch {
        $message = Get-ErrorMessage -ErrorObject $_
        try {
            if (-not [string]::IsNullOrWhiteSpace($WorkerJobFile)) {
                $eventFile = [System.IO.Path]::ChangeExtension($WorkerJobFile, ".events.jsonl")
                Write-WorkerEvent -Path $eventFile -Payload @{
                    type = "result"
                    progress = 0
                    status = "Worker failed."
                    log = ""
                    success = $false
                    error = $message
                    language = "enUS"
                }
            }
        }
        catch {
        }
    }
    exit
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "OpenClaw One-Click Deploy | K2st0r | v$script:AppVersion"
$form.ClientSize = New-Object System.Drawing.Size(1160, 870)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.BackColor = $script:Theme.Window
$form.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 9)

$heroPanel = New-Object System.Windows.Forms.Panel
$heroPanel.Location = New-Object System.Drawing.Point(18, 14)
$heroPanel.Size = New-Object System.Drawing.Size(1124, 88)
Set-PanelStyle -Control $heroPanel -BackColor $script:Theme.Panel -Radius 24
$form.Controls.Add($heroPanel)

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "OpenClaw Windows One-Click Deploy"
$titleLabel.Location = New-Object System.Drawing.Point(24, 16)
$titleLabel.Size = New-Object System.Drawing.Size(640, 30)
$titleLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 16, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = $script:Theme.Text
$heroPanel.Controls.Add($titleLabel)

$subTitleLabel = New-Object System.Windows.Forms.Label
$subTitleLabel.Text = "Single-window deployer: download Git and Node, install OpenClaw, sync resources, and optionally preload model credentials."
$subTitleLabel.Location = New-Object System.Drawing.Point(24, 50)
$subTitleLabel.Size = New-Object System.Drawing.Size(780, 20)
$subTitleLabel.ForeColor = $script:Theme.Muted
$heroPanel.Controls.Add($subTitleLabel)

$languageLabel = New-Object System.Windows.Forms.Label
$languageLabel.Text = "Language"
$languageLabel.Location = New-Object System.Drawing.Point(868, 18)
$languageLabel.Size = New-Object System.Drawing.Size(70, 22)
$languageLabel.ForeColor = $script:Theme.Text
$heroPanel.Controls.Add($languageLabel)

$languageComboBox = New-Object System.Windows.Forms.ComboBox
$languageComboBox.DropDownStyle = "DropDownList"
$languageComboBox.Location = New-Object System.Drawing.Point(944, 14)
$languageComboBox.Size = New-Object System.Drawing.Size(150, 28)
Set-InputStyle -Control $languageComboBox
$null = $languageComboBox.Items.Add((Get-T -Key "lang_name" -Language "zhCN"))
$null = $languageComboBox.Items.Add("English")
$heroPanel.Controls.Add($languageComboBox)

$settingsGroup = New-Object System.Windows.Forms.Panel
$settingsGroup.Location = New-Object System.Drawing.Point(18, 116)
$settingsGroup.Size = New-Object System.Drawing.Size(724, 420)
Set-PanelStyle -Control $settingsGroup -BackColor $script:Theme.Panel -Radius 22
$form.Controls.Add($settingsGroup)

$settingsHeaderLabel = New-Object System.Windows.Forms.Label
$settingsHeaderLabel.Text = "Deployment Settings"
$settingsHeaderLabel.Location = New-Object System.Drawing.Point(20, 12)
$settingsHeaderLabel.Size = New-Object System.Drawing.Size(220, 22)
$settingsHeaderLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 10.5, [System.Drawing.FontStyle]::Bold)
$settingsHeaderLabel.ForeColor = $script:Theme.Text
$settingsGroup.Controls.Add($settingsHeaderLabel)

$settingsStepsLabel = New-Object System.Windows.Forms.Label
$settingsStepsLabel.Text = "1. Choose provider   2. Fill model ID   3. Paste API key   4. Start deployment"
$settingsStepsLabel.Location = New-Object System.Drawing.Point(20, 38)
$settingsStepsLabel.Size = New-Object System.Drawing.Size(670, 20)
$settingsStepsLabel.ForeColor = $script:Theme.Muted
$settingsGroup.Controls.Add($settingsStepsLabel)

$providerLabel = New-Object System.Windows.Forms.Label
$providerLabel.Text = "Provider"
$providerLabel.Location = New-Object System.Drawing.Point(20, 72)
$providerLabel.Size = New-Object System.Drawing.Size(100, 22)
Set-LabelStyle -Label $providerLabel
$settingsGroup.Controls.Add($providerLabel)

$providerComboBox = New-Object System.Windows.Forms.ComboBox
$providerComboBox.DropDownStyle = "DropDownList"
$providerComboBox.Location = New-Object System.Drawing.Point(130, 68)
$providerComboBox.Size = New-Object System.Drawing.Size(554, 28)
Set-InputStyle -Control $providerComboBox
foreach ($key in Get-ProviderKeys) {
    $null = $providerComboBox.Items.Add((Get-T -Key (Get-ProviderDefinition -ProviderKey $key).DisplayName))
}
$settingsGroup.Controls.Add($providerComboBox)

$providerHintLabel = New-Object System.Windows.Forms.Label
$providerHintLabel.Text = "Choose the model channel you want to connect first."
$providerHintLabel.Location = New-Object System.Drawing.Point(130, 98)
$providerHintLabel.Size = New-Object System.Drawing.Size(554, 18)
$providerHintLabel.ForeColor = $script:Theme.Dim
$settingsGroup.Controls.Add($providerHintLabel)

$modelLabel = New-Object System.Windows.Forms.Label
$modelLabel.Text = "Model"
$modelLabel.Location = New-Object System.Drawing.Point(20, 130)
$modelLabel.Size = New-Object System.Drawing.Size(100, 22)
Set-LabelStyle -Label $modelLabel
$settingsGroup.Controls.Add($modelLabel)

$modelComboBox = New-Object System.Windows.Forms.ComboBox
$modelComboBox.Location = New-Object System.Drawing.Point(130, 126)
$modelComboBox.Size = New-Object System.Drawing.Size(426, 28)
$modelComboBox.DropDownStyle = "DropDownList"
Set-InputStyle -Control $modelComboBox
$settingsGroup.Controls.Add($modelComboBox)

$syncModelsButton = New-Object System.Windows.Forms.Button
$syncModelsButton.Text = "Sync Models"
$syncModelsButton.Location = New-Object System.Drawing.Point(572, 125)
$syncModelsButton.Size = New-Object System.Drawing.Size(112, 30)
Set-VsCodeButtonStyle -Button $syncModelsButton
$settingsGroup.Controls.Add($syncModelsButton)

$modelHintLabel = New-Object System.Windows.Forms.Label
$modelHintLabel.Text = "Enter the exact model identifier here, for example deepseek/deepseek-chat."
$modelHintLabel.Location = New-Object System.Drawing.Point(130, 156)
$modelHintLabel.Size = New-Object System.Drawing.Size(554, 18)
$modelHintLabel.ForeColor = $script:Theme.Dim
$settingsGroup.Controls.Add($modelHintLabel)

$keyLabel = New-Object System.Windows.Forms.Label
$keyLabel.Text = "API Key"
$keyLabel.Location = New-Object System.Drawing.Point(20, 188)
$keyLabel.Size = New-Object System.Drawing.Size(100, 22)
Set-LabelStyle -Label $keyLabel
$settingsGroup.Controls.Add($keyLabel)

$keyTextBox = New-Object System.Windows.Forms.TextBox
$keyTextBox.Location = New-Object System.Drawing.Point(130, 184)
$keyTextBox.Size = New-Object System.Drawing.Size(426, 28)
$keyTextBox.UseSystemPasswordChar = $true
Set-InputStyle -Control $keyTextBox
$settingsGroup.Controls.Add($keyTextBox)

$showKeyCheckBox = New-Object System.Windows.Forms.CheckBox
$showKeyCheckBox.Text = "Show key"
$showKeyCheckBox.Location = New-Object System.Drawing.Point(572, 186)
$showKeyCheckBox.Size = New-Object System.Drawing.Size(112, 24)
Set-CheckBoxStyle -CheckBox $showKeyCheckBox -BackColor $script:Theme.Panel
$showKeyCheckBox.Add_CheckedChanged({
    $keyTextBox.UseSystemPasswordChar = -not $showKeyCheckBox.Checked
})
$settingsGroup.Controls.Add($showKeyCheckBox)

$keyHintLabel = New-Object System.Windows.Forms.Label
$keyHintLabel.Text = "Paste the provider key here. Leave empty if you want to skip model auth for now."
$keyHintLabel.Location = New-Object System.Drawing.Point(130, 214)
$keyHintLabel.Size = New-Object System.Drawing.Size(554, 18)
$keyHintLabel.ForeColor = $script:Theme.Dim
$settingsGroup.Controls.Add($keyHintLabel)

$baseUrlLabel = New-Object System.Windows.Forms.Label
$baseUrlLabel.Text = "Base URL"
$baseUrlLabel.Location = New-Object System.Drawing.Point(20, 246)
$baseUrlLabel.Size = New-Object System.Drawing.Size(100, 22)
Set-LabelStyle -Label $baseUrlLabel
$settingsGroup.Controls.Add($baseUrlLabel)

$baseUrlTextBox = New-Object System.Windows.Forms.TextBox
$baseUrlTextBox.Location = New-Object System.Drawing.Point(130, 242)
$baseUrlTextBox.Size = New-Object System.Drawing.Size(554, 28)
Set-InputStyle -Control $baseUrlTextBox
$settingsGroup.Controls.Add($baseUrlTextBox)

$baseUrlHintLabel = New-Object System.Windows.Forms.Label
$baseUrlHintLabel.Text = "Usually only needed for Custom or Ollama. Most providers can leave this empty."
$baseUrlHintLabel.Location = New-Object System.Drawing.Point(130, 272)
$baseUrlHintLabel.Size = New-Object System.Drawing.Size(554, 18)
$baseUrlHintLabel.ForeColor = $script:Theme.Dim
$settingsGroup.Controls.Add($baseUrlHintLabel)

$deployRootLabel = New-Object System.Windows.Forms.Label
$deployRootLabel.Text = "Deploy Root"
$deployRootLabel.Location = New-Object System.Drawing.Point(20, 306)
$deployRootLabel.Size = New-Object System.Drawing.Size(100, 22)
Set-LabelStyle -Label $deployRootLabel
$settingsGroup.Controls.Add($deployRootLabel)

$deployRootTextBox = New-Object System.Windows.Forms.TextBox
$deployRootTextBox.Location = New-Object System.Drawing.Point(130, 302)
$deployRootTextBox.Size = New-Object System.Drawing.Size(426, 28)
$deployRootTextBox.Text = $script:RootDir
Set-InputStyle -Control $deployRootTextBox
$settingsGroup.Controls.Add($deployRootTextBox)

$browseDeployRootButton = New-Object System.Windows.Forms.Button
$browseDeployRootButton.Text = "Browse..."
$browseDeployRootButton.Location = New-Object System.Drawing.Point(572, 301)
$browseDeployRootButton.Size = New-Object System.Drawing.Size(112, 30)
Set-VsCodeButtonStyle -Button $browseDeployRootButton
$settingsGroup.Controls.Add($browseDeployRootButton)

$deployRootHintLabel = New-Object System.Windows.Forms.Label
$deployRootHintLabel.Text = "Choose the root folder where OpenClaw will be installed. runtime, downloads, and openclaw-home will all live there."
$deployRootHintLabel.Location = New-Object System.Drawing.Point(130, 332)
$deployRootHintLabel.Size = New-Object System.Drawing.Size(554, 30)
$deployRootHintLabel.ForeColor = $script:Theme.Dim
$settingsGroup.Controls.Add($deployRootHintLabel)

$workspaceLabel = New-Object System.Windows.Forms.Label
$workspaceLabel.Text = "Workspace"
$workspaceLabel.Location = New-Object System.Drawing.Point(20, 372)
$workspaceLabel.Size = New-Object System.Drawing.Size(100, 22)
Set-LabelStyle -Label $workspaceLabel
$settingsGroup.Controls.Add($workspaceLabel)

$workspaceTextBox = New-Object System.Windows.Forms.TextBox
$workspaceTextBox.Location = New-Object System.Drawing.Point(130, 368)
$workspaceTextBox.Size = New-Object System.Drawing.Size(554, 28)
$workspaceTextBox.Text = Get-DefaultWorkspaceForRoot -RootPath $script:RootDir
$workspaceTextBox.ReadOnly = $true
$workspaceTextBox.TabStop = $false
Set-InputStyle -Control $workspaceTextBox -ReadOnly $true
$settingsGroup.Controls.Add($workspaceTextBox)

$workspaceHintLabel = New-Object System.Windows.Forms.Label
$workspaceHintLabel.Text = "OpenClaw working folder used for local code and tasks."
$workspaceHintLabel.Location = New-Object System.Drawing.Point(130, 398)
$workspaceHintLabel.Size = New-Object System.Drawing.Size(554, 18)
$workspaceHintLabel.ForeColor = $script:Theme.Dim
$settingsGroup.Controls.Add($workspaceHintLabel)

$guideGroup = New-Object System.Windows.Forms.Panel
$guideGroup.Location = New-Object System.Drawing.Point(758, 116)
$guideGroup.Size = New-Object System.Drawing.Size(384, 420)
Set-PanelStyle -Control $guideGroup -BackColor $script:Theme.Panel -Radius 22
$form.Controls.Add($guideGroup)

$guideHeaderLabel = New-Object System.Windows.Forms.Label
$guideHeaderLabel.Text = "Input Guide"
$guideHeaderLabel.Location = New-Object System.Drawing.Point(20, 12)
$guideHeaderLabel.Size = New-Object System.Drawing.Size(180, 22)
$guideHeaderLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 10.5, [System.Drawing.FontStyle]::Bold)
$guideHeaderLabel.ForeColor = $script:Theme.Text
$guideGroup.Controls.Add($guideHeaderLabel)

$guideProviderLabel = New-Object System.Windows.Forms.Label
$guideProviderLabel.Location = New-Object System.Drawing.Point(20, 48)
$guideProviderLabel.Size = New-Object System.Drawing.Size(120, 20)
Set-LabelStyle -Label $guideProviderLabel -ForeColor $script:Theme.Muted
$guideGroup.Controls.Add($guideProviderLabel)

$guideProviderValue = New-Object System.Windows.Forms.Label
$guideProviderValue.Location = New-Object System.Drawing.Point(20, 72)
$guideProviderValue.Size = New-Object System.Drawing.Size(336, 34)
$guideProviderValue.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 11, [System.Drawing.FontStyle]::Bold)
$guideProviderValue.ForeColor = $script:Theme.Link
$guideGroup.Controls.Add($guideProviderValue)

$guideModelLabel = New-Object System.Windows.Forms.Label
$guideModelLabel.Location = New-Object System.Drawing.Point(20, 116)
$guideModelLabel.Size = New-Object System.Drawing.Size(120, 20)
Set-LabelStyle -Label $guideModelLabel -ForeColor $script:Theme.Muted
$guideGroup.Controls.Add($guideModelLabel)

$guideModelValue = New-Object System.Windows.Forms.Label
$guideModelValue.Location = New-Object System.Drawing.Point(20, 140)
$guideModelValue.Size = New-Object System.Drawing.Size(336, 36)
$guideModelValue.ForeColor = $script:Theme.Text
$guideGroup.Controls.Add($guideModelValue)

$guideKeyLabel = New-Object System.Windows.Forms.Label
$guideKeyLabel.Location = New-Object System.Drawing.Point(20, 188)
$guideKeyLabel.Size = New-Object System.Drawing.Size(120, 20)
Set-LabelStyle -Label $guideKeyLabel -ForeColor $script:Theme.Muted
$guideGroup.Controls.Add($guideKeyLabel)

$guideKeyValue = New-Object System.Windows.Forms.Label
$guideKeyValue.Location = New-Object System.Drawing.Point(20, 212)
$guideKeyValue.Size = New-Object System.Drawing.Size(336, 34)
$guideKeyValue.ForeColor = $script:Theme.Text
$guideGroup.Controls.Add($guideKeyValue)

$guideKeyEnvLabel = New-Object System.Windows.Forms.Label
$guideKeyEnvLabel.Location = New-Object System.Drawing.Point(20, 256)
$guideKeyEnvLabel.Size = New-Object System.Drawing.Size(170, 20)
Set-LabelStyle -Label $guideKeyEnvLabel -ForeColor $script:Theme.Muted
$guideGroup.Controls.Add($guideKeyEnvLabel)

$guideKeyEnvValue = New-Object System.Windows.Forms.Label
$guideKeyEnvValue.Location = New-Object System.Drawing.Point(20, 280)
$guideKeyEnvValue.Size = New-Object System.Drawing.Size(336, 24)
$guideKeyEnvValue.Font = New-Object System.Drawing.Font("Consolas", 9.2, [System.Drawing.FontStyle]::Bold)
$guideKeyEnvValue.ForeColor = $script:Theme.Warning
$guideGroup.Controls.Add($guideKeyEnvValue)

$guideBaseLabel = New-Object System.Windows.Forms.Label
$guideBaseLabel.Location = New-Object System.Drawing.Point(20, 316)
$guideBaseLabel.Size = New-Object System.Drawing.Size(120, 20)
Set-LabelStyle -Label $guideBaseLabel -ForeColor $script:Theme.Muted
$guideGroup.Controls.Add($guideBaseLabel)

$guideBaseValue = New-Object System.Windows.Forms.Label
$guideBaseValue.Location = New-Object System.Drawing.Point(20, 340)
$guideBaseValue.Size = New-Object System.Drawing.Size(336, 22)
$guideBaseValue.ForeColor = $script:Theme.Text
$guideGroup.Controls.Add($guideBaseValue)

$guideTipLabel = New-Object System.Windows.Forms.Panel
$guideTipLabel.Location = New-Object System.Drawing.Point(758, 538)
$guideTipLabel.Size = New-Object System.Drawing.Size(384, 48)
Set-PanelStyle -Control $guideTipLabel -BackColor $script:Theme.Control -Radius 18
$form.Controls.Add($guideTipLabel)

$guideTipTextLabel = New-Object System.Windows.Forms.Label
$guideTipTextLabel.Location = New-Object System.Drawing.Point(14, 8)
$guideTipTextLabel.Size = New-Object System.Drawing.Size(356, 32)
$guideTipTextLabel.ForeColor = $script:Theme.Muted
$guideTipLabel.Controls.Add($guideTipTextLabel)

$installDaemonCheckBox = New-Object System.Windows.Forms.CheckBox
$installDaemonCheckBox.Text = "Install OpenClaw background service"
$installDaemonCheckBox.Location = New-Object System.Drawing.Point(22, 548)
$installDaemonCheckBox.Size = New-Object System.Drawing.Size(260, 28)
$installDaemonCheckBox.Checked = $true
Set-CheckBoxStyle -CheckBox $installDaemonCheckBox
$form.Controls.Add($installDaemonCheckBox)

$cloneRepoCheckBox = New-Object System.Windows.Forms.CheckBox
$cloneRepoCheckBox.Text = "Sync official repo into resources\\openclaw-source"
$cloneRepoCheckBox.Location = New-Object System.Drawing.Point(306, 548)
$cloneRepoCheckBox.Size = New-Object System.Drawing.Size(380, 28)
$cloneRepoCheckBox.Checked = $true
Set-CheckBoxStyle -CheckBox $cloneRepoCheckBox
$form.Controls.Add($cloneRepoCheckBox)

$startButton = New-Object System.Windows.Forms.Button
$startButton.Text = "Start Deploy"
$startButton.Location = New-Object System.Drawing.Point(22, 590)
$startButton.Size = New-Object System.Drawing.Size(220, 46)
Set-VsCodeButtonStyle -Button $startButton -BackColor $script:Theme.Accent -ForeColor ([System.Drawing.Color]::White) -Primary $true
$form.Controls.Add($startButton)

$openFolderButton = New-Object System.Windows.Forms.Button
$openFolderButton.Text = "Open Folder"
$openFolderButton.Location = New-Object System.Drawing.Point(258, 590)
$openFolderButton.Size = New-Object System.Drawing.Size(156, 46)
Set-VsCodeButtonStyle -Button $openFolderButton
$openFolderButton.Add_Click({
    $targetRoot = if ([string]::IsNullOrWhiteSpace($deployRootTextBox.Text)) { $script:RootDir } else { $deployRootTextBox.Text }
    Ensure-Directory -Path $targetRoot
    Start-Process -FilePath "explorer.exe" -ArgumentList $targetRoot
})
$form.Controls.Add($openFolderButton)

$openHomeButton = New-Object System.Windows.Forms.Button
$openHomeButton.Text = "Open State Folder"
$openHomeButton.Location = New-Object System.Drawing.Point(430, 590)
$openHomeButton.Size = New-Object System.Drawing.Size(184, 46)
Set-VsCodeButtonStyle -Button $openHomeButton
$openHomeButton.Add_Click({
    $targetRoot = if ([string]::IsNullOrWhiteSpace($deployRootTextBox.Text)) { $script:RootDir } else { $deployRootTextBox.Text }
    $targetStateDir = Join-Path $targetRoot "openclaw-home"
    Ensure-Directory -Path $targetStateDir
    Start-Process -FilePath "explorer.exe" -ArgumentList $targetStateDir
})
$form.Controls.Add($openHomeButton)

$openDashboardButton = New-Object System.Windows.Forms.Button
$openDashboardButton.Text = "Open Dashboard"
$openDashboardButton.Location = New-Object System.Drawing.Point(630, 590)
$openDashboardButton.Size = New-Object System.Drawing.Size(166, 46)
Set-VsCodeButtonStyle -Button $openDashboardButton
$form.Controls.Add($openDashboardButton)

$copyUrlButton = New-Object System.Windows.Forms.Button
$copyUrlButton.Text = "Copy URL"
$copyUrlButton.Location = New-Object System.Drawing.Point(812, 590)
$copyUrlButton.Size = New-Object System.Drawing.Size(112, 46)
Set-VsCodeButtonStyle -Button $copyUrlButton
$form.Controls.Add($copyUrlButton)

$copyTokenButton = New-Object System.Windows.Forms.Button
$copyTokenButton.Text = "Copy Token"
$copyTokenButton.Location = New-Object System.Drawing.Point(940, 590)
$copyTokenButton.Size = New-Object System.Drawing.Size(132, 46)
Set-VsCodeButtonStyle -Button $copyTokenButton
$form.Controls.Add($copyTokenButton)

$clearLogButton = New-Object System.Windows.Forms.Button
$clearLogButton.Text = "Clear Log"
$clearLogButton.Location = New-Object System.Drawing.Point(878, 642)
$clearLogButton.Size = New-Object System.Drawing.Size(116, 42)
Set-VsCodeButtonStyle -Button $clearLogButton
$form.Controls.Add($clearLogButton)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Ready. Everything runs in this window only."
$statusLabel.Location = New-Object System.Drawing.Point(22, 658)
$statusLabel.Size = New-Object System.Drawing.Size(835, 24)
$statusLabel.ForeColor = $script:Theme.Muted
$form.Controls.Add($statusLabel)

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(22, 690)
$progressBar.Size = New-Object System.Drawing.Size(1120, 24)
$progressBar.Minimum = 0
$progressBar.Maximum = 100
$progressBar.Value = 0
$form.Controls.Add($progressBar)

$logTextBox = New-Object System.Windows.Forms.RichTextBox
$logTextBox.Location = New-Object System.Drawing.Point(22, 728)
$logTextBox.Size = New-Object System.Drawing.Size(1120, 104)
$logTextBox.ReadOnly = $true
$logTextBox.BackColor = $script:Theme.LogBack
$logTextBox.ForeColor = $script:Theme.Text
$logTextBox.BorderStyle = "FixedSingle"
$logTextBox.Font = New-Object System.Drawing.Font("Consolas", 9.2)
Set-PanelStyle -Control $logTextBox -BackColor $script:Theme.LogBack
$form.Controls.Add($logTextBox)

$closeButton = New-Object System.Windows.Forms.Button
$closeButton.Text = "Close"
$closeButton.Location = New-Object System.Drawing.Point(1010, 642)
$closeButton.Size = New-Object System.Drawing.Size(124, 42)
Set-VsCodeButtonStyle -Button $closeButton
$closeButton.Enabled = $true
$form.Controls.Add($closeButton)

$footerLabel = New-Object System.Windows.Forms.Label
$footerLabel.Text = "Author"
$footerLabel.Location = New-Object System.Drawing.Point(22, 842)
$footerLabel.Size = New-Object System.Drawing.Size(60, 20)
$footerLabel.ForeColor = $script:Theme.Dim
$form.Controls.Add($footerLabel)

$authorLink = New-Object System.Windows.Forms.LinkLabel
$authorLink.Text = "K2st0r | https://github.com/K2st0r"
$authorLink.Location = New-Object System.Drawing.Point(86, 842)
$authorLink.Size = New-Object System.Drawing.Size(330, 20)
$authorLink.BackColor = $script:Theme.Window
$authorLink.LinkColor = $script:Theme.Link
$authorLink.ActiveLinkColor = $script:Theme.Accent
$authorLink.Add_LinkClicked({
    Start-Process -FilePath "https://github.com/K2st0r"
})
$form.Controls.Add($authorLink)

$openDashboardButton.Add_Click({
    try {
        $targetRoot = if (-not [string]::IsNullOrWhiteSpace($script:LastDeployRoot)) { $script:LastDeployRoot } elseif (-not [string]::IsNullOrWhiteSpace($deployRootTextBox.Text)) { [System.IO.Path]::GetFullPath($deployRootTextBox.Text.Trim()) } else { $script:RootDir }
        Set-ResultAccessState -DeployRoot $targetRoot
        [void](Start-OpenClawGatewayForDeployRoot -DeployRoot $targetRoot -LogTextBox $logTextBox -Language $script:CurrentLanguage)
        Start-Process -FilePath $script:LastDashboardUrl | Out-Null
        Append-UiLog -LogTextBox $logTextBox -Message ((Get-T -Key "log_dashboard_opened") + " " + $script:LastDashboardUrl)
    }
    catch {
        Append-UiLog -LogTextBox $logTextBox -Message ((Get-T -Key "log_open_dashboard_failed") + " " + (Get-ErrorMessage -ErrorObject $_))
    }
})

$copyUrlButton.Add_Click({
    try {
        $targetRoot = if (-not [string]::IsNullOrWhiteSpace($script:LastDeployRoot)) { $script:LastDeployRoot } elseif (-not [string]::IsNullOrWhiteSpace($deployRootTextBox.Text)) { [System.IO.Path]::GetFullPath($deployRootTextBox.Text.Trim()) } else { $script:RootDir }
        Set-ResultAccessState -DeployRoot $targetRoot
        [System.Windows.Forms.Clipboard]::SetText($script:LastDashboardUrl)
        Append-UiLog -LogTextBox $logTextBox -Message (Get-T -Key "log_copy_url_done")
    }
    catch {
        Append-UiLog -LogTextBox $logTextBox -Message ((Get-T -Key "log_copy_failed") + " " + (Get-ErrorMessage -ErrorObject $_))
    }
})

$copyTokenButton.Add_Click({
    try {
        $targetRoot = if (-not [string]::IsNullOrWhiteSpace($script:LastDeployRoot)) { $script:LastDeployRoot } elseif (-not [string]::IsNullOrWhiteSpace($deployRootTextBox.Text)) { [System.IO.Path]::GetFullPath($deployRootTextBox.Text.Trim()) } else { $script:RootDir }
        Set-ResultAccessState -DeployRoot $targetRoot
        if ([string]::IsNullOrWhiteSpace($script:LastGatewayToken)) {
            Append-UiLog -LogTextBox $logTextBox -Message (Get-T -Key "log_copy_token_missing")
            return
        }
        [System.Windows.Forms.Clipboard]::SetText($script:LastGatewayToken)
        Append-UiLog -LogTextBox $logTextBox -Message (Get-T -Key "log_copy_token_done")
    }
    catch {
        Append-UiLog -LogTextBox $logTextBox -Message ((Get-T -Key "log_copy_failed") + " " + (Get-ErrorMessage -ErrorObject $_))
    }
})

$browseDeployRootButton.Add_Click({
    $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderDialog.Description = "Select the deployment root folder"
    $folderDialog.SelectedPath = if ([string]::IsNullOrWhiteSpace($deployRootTextBox.Text)) { $script:RootDir } else { $deployRootTextBox.Text }
    $folderDialog.ShowNewFolderButton = $true
    if ($folderDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $selectedPath = [System.IO.Path]::GetFullPath($folderDialog.SelectedPath)
        $deployRootTextBox.Text = $selectedPath
        $workspaceTextBox.Text = Get-DefaultWorkspaceForRoot -RootPath $selectedPath
    }
    $folderDialog.Dispose()
})

$deployRootTextBox.Add_TextChanged({
    if ($script:UiApplying) {
        return
    }

    $candidate = $deployRootTextBox.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($candidate)) {
        $workspaceTextBox.Text = ""
        return
    }

    try {
        $workspaceTextBox.Text = Get-DefaultWorkspaceForRoot -RootPath $candidate
    }
    catch {
    }
})

$clearLogButton.Add_Click({
    $logTextBox.Clear()
})

$guideControls = @{
    ProviderValue = $guideProviderValue
    ModelValue = $guideModelValue
    KeyValue = $guideKeyValue
    KeyEnvValue = $guideKeyEnvValue
    BaseValue = $guideBaseValue
}

$uiControls = @{
    Form = $form
    TitleLabel = $titleLabel
    SubTitleLabel = $subTitleLabel
    LanguageLabel = $languageLabel
    SettingsGroup = $settingsGroup
    SettingsHeaderLabel = $settingsHeaderLabel
    SettingsStepsLabel = $settingsStepsLabel
    ProviderLabel = $providerLabel
    ProviderHintLabel = $providerHintLabel
    ModelLabel = $modelLabel
    ModelHintLabel = $modelHintLabel
    ModelComboBox = $modelComboBox
    SyncModelsButton = $syncModelsButton
    KeyLabel = $keyLabel
    KeyHintLabel = $keyHintLabel
    ShowKeyCheckBox = $showKeyCheckBox
    BaseUrlLabel = $baseUrlLabel
    BaseUrlHintLabel = $baseUrlHintLabel
    DeployRootLabel = $deployRootLabel
    DeployRootHintLabel = $deployRootHintLabel
    BrowseDeployRootButton = $browseDeployRootButton
    DeployRootTextBox = $deployRootTextBox
    WorkspaceLabel = $workspaceLabel
    WorkspaceHintLabel = $workspaceHintLabel
    GuideGroup = $guideGroup
    GuideHeaderLabel = $guideHeaderLabel
    GuideProviderLabel = $guideProviderLabel
    GuideModelLabel = $guideModelLabel
    GuideKeyLabel = $guideKeyLabel
    GuideKeyEnvLabel = $guideKeyEnvLabel
    GuideBaseLabel = $guideBaseLabel
    GuideTipLabel = $guideTipLabel
    GuideTipTextLabel = $guideTipTextLabel
    InstallDaemonCheckBox = $installDaemonCheckBox
    CloneRepoCheckBox = $cloneRepoCheckBox
    StartButton = $startButton
    OpenFolderButton = $openFolderButton
    OpenHomeButton = $openHomeButton
    OpenDashboardButton = $openDashboardButton
    CopyUrlButton = $copyUrlButton
    CopyTokenButton = $copyTokenButton
    ClearLogButton = $clearLogButton
    CloseButton = $closeButton
    FooterLabel = $footerLabel
    ProviderComboBox = $providerComboBox
    GuideControls = $guideControls
}

$languageComboBox.Add_SelectedIndexChanged({
    if ($script:UiApplying -or -not $script:UiReady) {
        return
    }

    $selectedLanguage = if ($languageComboBox.SelectedIndex -eq 0) { "zhCN" } else { "enUS" }
    Apply-Language -Language $selectedLanguage -Controls $uiControls
    if (-not ($script:WorkerProcess -and -not $script:WorkerProcess.HasExited -and -not $script:WorkerCompleted)) {
        $statusLabel.Text = Get-T -Key "status_ready"
    }
})

$providerComboBox.Add_SelectedIndexChanged({
    if ($script:UiApplying -or -not $script:UiReady) {
        return
    }
    $providerKey = Get-ProviderSelectionKey -DisplayText $providerComboBox.SelectedItem.ToString()
    Set-DefaultFields -ProviderKey $providerKey -ModelComboBox $modelComboBox -BaseUrlTextBox $baseUrlTextBox
    Update-GuidePanel -ProviderKey $providerKey -GuideControls $guideControls
})

$modelSyncTimer = New-Object System.Windows.Forms.Timer
$modelSyncTimer.Interval = 500
$modelSyncTimer.Add_Tick({
    try {
        if (-not $script:ModelSyncProcess) {
            $modelSyncTimer.Stop()
            return
        }

        $elapsedSeconds = if ($script:ModelSyncStartedAt) { [int]((Get-Date) - $script:ModelSyncStartedAt).TotalSeconds } else { 0 }
        if (-not $script:ModelSyncProcess.HasExited -and $elapsedSeconds -ge $script:ModelSyncTimeoutSeconds) {
            try {
                $script:ModelSyncProcess.Kill()
            }
            catch {
            }
            Append-UiLog -LogTextBox $logTextBox -Message (Get-T -Key "log_model_sync_timeout")
            $statusLabel.Text = Get-T -Key "status_ready"
            $deploymentRunning = ($script:WorkerProcess -and -not $script:WorkerProcess.HasExited -and -not $script:WorkerCompleted)
            $startButton.Enabled = -not $deploymentRunning
            $providerComboBox.Enabled = -not $deploymentRunning
            $modelComboBox.Enabled = -not $deploymentRunning
            $syncModelsButton.Enabled = -not $deploymentRunning
            $languageComboBox.Enabled = -not $deploymentRunning
            $modelSyncTimer.Stop()
            $script:ModelSyncProcess.Dispose()
            $script:ModelSyncProcess = $null
            return
        }

        if (-not $script:ModelSyncProcess.HasExited) {
            return
        }

        $modelSyncTimer.Stop()
        $providerKey = $script:ModelSyncProviderKey
        $outputText = ""
        if (-not [string]::IsNullOrWhiteSpace($script:ModelSyncOutputFilePath) -and (Test-Path -LiteralPath $script:ModelSyncOutputFilePath)) {
            $outputText = Get-Content -LiteralPath $script:ModelSyncOutputFilePath -Raw -Encoding UTF8
        }

        if ($script:ModelSyncProcess.ExitCode -ne 0) {
            $message = (Get-T -Key "log_model_sync_failed") + " exit code " + $script:ModelSyncProcess.ExitCode
            if (-not [string]::IsNullOrWhiteSpace($outputText)) {
                $firstOutputLine = ($outputText -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -First 1)
                if (-not [string]::IsNullOrWhiteSpace($firstOutputLine)) {
                    $message = $message + "; " + $firstOutputLine.Trim()
                }
            }
            Append-UiLog -LogTextBox $logTextBox -Message $message
        }
        else {
            $syncedModels = @(Get-SyncedModelCandidatesFromCliOutput -ProviderKey $providerKey -Text $outputText)
            if ($syncedModels.Count -gt 0) {
                $script:SyncedOpenClawModels[$providerKey] = $syncedModels
                $currentText = $modelComboBox.Text
                Set-DefaultFields -ProviderKey $providerKey -ModelComboBox $modelComboBox -BaseUrlTextBox $baseUrlTextBox
                if (-not [string]::IsNullOrWhiteSpace($currentText) -and ($modelComboBox.Items.Contains($currentText))) {
                    $modelComboBox.SelectedItem = $currentText
                }
                Update-GuidePanel -ProviderKey $providerKey -GuideControls $guideControls
                Append-UiLog -LogTextBox $logTextBox -Message ((Get-T -Key "log_model_sync_done") + " " + $syncedModels.Count)
            }
            else {
                Append-UiLog -LogTextBox $logTextBox -Message (Get-T -Key "log_model_sync_none")
            }
        }

        $statusLabel.Text = Get-T -Key "status_ready"
        $deploymentRunning = ($script:WorkerProcess -and -not $script:WorkerProcess.HasExited -and -not $script:WorkerCompleted)
        $startButton.Enabled = -not $deploymentRunning
        $providerComboBox.Enabled = -not $deploymentRunning
        $modelComboBox.Enabled = -not $deploymentRunning
        $syncModelsButton.Enabled = -not $deploymentRunning
        $languageComboBox.Enabled = -not $deploymentRunning
    }
    catch {
        Append-UiLog -LogTextBox $logTextBox -Message ((Get-T -Key "log_model_sync_failed") + " " + (Get-ErrorMessage -ErrorObject $_))
        $statusLabel.Text = Get-T -Key "status_ready"
        $deploymentRunning = ($script:WorkerProcess -and -not $script:WorkerProcess.HasExited -and -not $script:WorkerCompleted)
        $startButton.Enabled = -not $deploymentRunning
        $providerComboBox.Enabled = -not $deploymentRunning
        $modelComboBox.Enabled = -not $deploymentRunning
        $syncModelsButton.Enabled = -not $deploymentRunning
        $languageComboBox.Enabled = -not $deploymentRunning
        $modelSyncTimer.Stop()
    }
    finally {
        if ($script:ModelSyncProcess -and $script:ModelSyncProcess.HasExited) {
            try {
                $script:ModelSyncProcess.Dispose()
            }
            catch {
            }
            $script:ModelSyncProcess = $null
        }
        if ($null -eq $script:ModelSyncProcess) {
            foreach ($tempPath in @($script:ModelSyncOutputFilePath, $script:ModelSyncScriptPath)) {
                if (-not [string]::IsNullOrWhiteSpace($tempPath) -and (Test-Path -LiteralPath $tempPath)) {
                    try {
                        Remove-Item -LiteralPath $tempPath -Force
                    }
                    catch {
                    }
                }
            }

            $script:ModelSyncProviderKey = $null
            $script:ModelSyncOutputFilePath = $null
            $script:ModelSyncScriptPath = $null
            $script:ModelSyncStartedAt = $null
        }
    }
})

$syncModelsButton.Add_Click({
    if ($script:ModelSyncProcess -and -not $script:ModelSyncProcess.HasExited) {
        return
    }

    try {
        $providerKey = Get-ProviderSelectionKey -DisplayText $providerComboBox.SelectedItem.ToString()
        $providerIds = @(Convert-ProviderKeyToOpenClawProviderIds -ProviderKey $providerKey)
        if ($providerIds.Count -eq 0) {
            Append-UiLog -LogTextBox $logTextBox -Message (Get-T -Key "log_model_sync_none")
            return
        }

        Ensure-Directory -Path $script:DownloadsDir
        Clear-ModelSyncTempDirectories
        $syncId = [Guid]::NewGuid().ToString("N")
        $script:ModelSyncProviderKey = $providerKey
        $script:ModelSyncOutputFilePath = Join-Path $script:DownloadsDir ("model-sync-$syncId.out")
        $script:ModelSyncScriptPath = Join-Path $script:DownloadsDir ("model-sync-$syncId.ps1")
        $providerJson = ConvertTo-Json $providerIds -Compress
        $scriptContent = @"
`$ErrorActionPreference = 'Stop'
function Add-UniqueLine {
    param([System.Collections.Generic.List[string]]`$Lines, [string]`$Value)
    if ([string]::IsNullOrWhiteSpace(`$Value)) { return }
    `$trimmed = `$Value.Trim()
    if (-not `$Lines.Contains(`$trimmed)) {
        [void]`$Lines.Add(`$trimmed)
    }
}

function Read-ModelIdsFromManifest {
    param([string]`$Root, [string[]]`$Providers, [System.Collections.Generic.List[string]]`$Lines)
    `$extensionDir = Join-Path `$Root 'dist\extensions'
    if (-not (Test-Path -LiteralPath `$extensionDir)) { return }
    foreach (`$manifestFile in Get-ChildItem -LiteralPath `$extensionDir -Recurse -Filter 'openclaw.plugin.json' -ErrorAction SilentlyContinue) {
        try {
            `$manifest = Get-Content -LiteralPath `$manifestFile.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
            `$catalog = `$manifest.modelCatalog
            if (`$null -eq `$catalog -or `$null -eq `$catalog.providers) { continue }
            foreach (`$provider in `$Providers) {
                `$providerCatalog = `$catalog.providers.PSObject.Properties[`$provider]
                if (`$null -eq `$providerCatalog -or `$null -eq `$providerCatalog.Value.models) { continue }
                foreach (`$model in @(`$providerCatalog.Value.models)) {
                    if (`$null -eq `$model.id -or [string]::IsNullOrWhiteSpace([string]`$model.id)) { continue }
                    `$modelId = [string]`$model.id
                    if (`$modelId.Contains('/')) {
                        Add-UniqueLine -Lines `$Lines -Value `$modelId
                    }
                    else {
                        Add-UniqueLine -Lines `$Lines -Value (`$provider + '/' + `$modelId)
                    }
                }
            }
        }
        catch {
        }
    }
}

function Read-ModelIdsFromBundledJs {
    param([string]`$Root, [string]`$ProviderKey, [System.Collections.Generic.List[string]]`$Lines)
    `$distDir = Join-Path `$Root 'dist'
    if (-not (Test-Path -LiteralPath `$distDir)) { return }
    `$specs = @()
    switch (`$ProviderKey) {
        'QwenStandardCN' { `$specs = @(@{ File = 'models-BibziGt5.js'; Prefix = 'qwen'; Pattern = 'id:\s*\"([^\"]+)\"' }) }
        'QwenCodingCN' { `$specs = @(@{ File = 'models-BibziGt5.js'; Prefix = 'qwen'; Pattern = 'id:\s*\"([^\"]+)\"' }) }
        'xAI' { `$specs = @(@{ File = 'model-definitions-CsER1IBx.js'; Prefix = 'xai'; Pattern = 'id:\s*\"([^\"]+)\"' }) }
        'MiniMaxCN' { `$specs = @(@{ File = 'provider-models-wWx85uVe.js'; Prefix = 'minimax'; Pattern = '\"(MiniMax-[^\"]+)\"' }) }
        default { `$specs = @() }
    }

    foreach (`$spec in `$specs) {
        `$filePath = Join-Path `$distDir ([string]`$spec.File)
        if (-not (Test-Path -LiteralPath `$filePath)) { continue }
        try {
            `$content = Get-Content -LiteralPath `$filePath -Raw -Encoding UTF8
            foreach (`$match in [regex]::Matches(`$content, [string]`$spec.Pattern)) {
                if (`$match.Groups.Count -lt 2) { continue }
                `$modelId = `$match.Groups[1].Value.Trim()
                if ([string]::IsNullOrWhiteSpace(`$modelId) -or `$modelId -eq [string]`$spec.Prefix) { continue }
                Add-UniqueLine -Lines `$Lines -Value (([string]`$spec.Prefix) + '/' + `$modelId)
            }
        }
        catch {
        }
    }
}

`$providers = ConvertFrom-Json @'
$providerJson
'@
`$providerKey = '$($providerKey.Replace("'", "''"))'
`$lines = New-Object System.Collections.Generic.List[string]
`$workDir = Join-Path '$($script:DownloadsDir.Replace("'", "''"))' ('model-sync-package-$syncId')
`$cacheTarballPath = Join-Path '$($script:DownloadsDir.Replace("'", "''"))' 'openclaw-latest.tgz'
if (Test-Path -LiteralPath `$workDir) { Remove-Item -LiteralPath `$workDir -Recurse -Force }
[void](New-Item -ItemType Directory -Path `$workDir -Force)
try {
    if (-not (Test-Path -LiteralPath `$cacheTarballPath) -or (Get-Item -LiteralPath `$cacheTarballPath).Length -lt 1024) {
        `$registry = Invoke-RestMethod -Uri 'https://registry.npmjs.org/openclaw/latest'
        if (`$null -eq `$registry.dist -or [string]::IsNullOrWhiteSpace([string]`$registry.dist.tarball)) {
            throw 'npm registry response did not include a tarball URL.'
        }
        Invoke-WebRequest -Uri ([string]`$registry.dist.tarball) -OutFile `$cacheTarballPath
    }
    tar -xzf `$cacheTarballPath -C `$workDir
    `$packageRoot = Join-Path `$workDir 'package'
    if (-not (Test-Path -LiteralPath `$packageRoot)) {
        `$packageRoot = (Get-ChildItem -LiteralPath `$workDir -Directory | Select-Object -First 1).FullName
    }
    Read-ModelIdsFromManifest -Root `$packageRoot -Providers @(`$providers) -Lines `$lines
    Read-ModelIdsFromBundledJs -Root `$packageRoot -ProviderKey `$providerKey -Lines `$lines
}
catch {
    Add-UniqueLine -Lines `$lines -Value ('ERROR ' + `$_.Exception.Message)
}
finally {
    try {
        if (Test-Path -LiteralPath `$workDir) {
            Remove-Item -LiteralPath `$workDir -Recurse -Force
        }
    }
    catch {
    }
}
`$lines | Set-Content -LiteralPath '$($script:ModelSyncOutputFilePath.Replace("'", "''"))' -Encoding UTF8
"@
        Set-Content -LiteralPath $script:ModelSyncScriptPath -Value $scriptContent -Encoding UTF8

        $script:ModelSyncProcess = Start-Process -FilePath (Join-Path $PSHOME "powershell.exe") -ArgumentList @(
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            $script:ModelSyncScriptPath
        ) -PassThru -WindowStyle Hidden
        $script:ModelSyncStartedAt = Get-Date
        $startButton.Enabled = $false
        $providerComboBox.Enabled = $false
        $modelComboBox.Enabled = $false
        $syncModelsButton.Enabled = $false
        $languageComboBox.Enabled = $false
        $statusLabel.Text = Get-T -Key "status_syncing_models"
        Append-UiLog -LogTextBox $logTextBox -Message ((Get-T -Key "log_model_sync_start") + " " + ($providerIds -join ", "))
        $modelSyncTimer.Start()
    }
    catch {
        $startButton.Enabled = $true
        $providerComboBox.Enabled = $true
        $modelComboBox.Enabled = $true
        $syncModelsButton.Enabled = $true
        $languageComboBox.Enabled = $true
        $statusLabel.Text = Get-T -Key "status_ready"
        Append-UiLog -LogTextBox $logTextBox -Message ((Get-T -Key "log_model_sync_failed") + " " + (Get-ErrorMessage -ErrorObject $_))
    }
})

Apply-Language -Language "zhCN" -Controls $uiControls
$languageComboBox.SelectedIndex = 0
$providerComboBox.SelectedItem = Get-T -Key (Get-ProviderDefinition -ProviderKey "Skip").DisplayName
Set-DefaultFields -ProviderKey "Skip" -ModelComboBox $modelComboBox -BaseUrlTextBox $baseUrlTextBox
Update-GuidePanel -ProviderKey "Skip" -GuideControls $guideControls
$statusLabel.Text = Get-T -Key "status_ready"

$script:UiReady = $true
$script:WorkerProcess = $null
$script:GatewayProcess = $null
$script:WorkerJobFilePath = $null
$script:WorkerEventFilePath = $null
$script:WorkerEventOffset = 0
$script:WorkerCompleted = $false

$setDeploymentUiState = {
    param([bool]$IsRunning)

    $startButton.Enabled = -not $IsRunning
    $providerComboBox.Enabled = -not $IsRunning
    $modelComboBox.Enabled = -not $IsRunning
    $syncModelsButton.Enabled = -not $IsRunning
    $keyTextBox.Enabled = -not $IsRunning
    $baseUrlTextBox.Enabled = -not $IsRunning
    $deployRootTextBox.Enabled = -not $IsRunning
    $browseDeployRootButton.Enabled = -not $IsRunning
    $installDaemonCheckBox.Enabled = -not $IsRunning
    $cloneRepoCheckBox.Enabled = -not $IsRunning
    $languageComboBox.Enabled = -not $IsRunning
}

$closeWorkerSafely = {
    try {
        if ($pollTimer) {
            $pollTimer.Stop()
        }
    }
    catch {
    }

    try {
        if ($modelSyncTimer) {
            $modelSyncTimer.Stop()
        }
    }
    catch {
    }

    try {
        if ($script:WorkerProcess -and -not $script:WorkerProcess.HasExited) {
            Write-DebugTrace ("Stopping worker PID=" + $script:WorkerProcess.Id + " because the main window is closing.")
            $script:WorkerProcess.Kill()
            try {
                [void]$script:WorkerProcess.WaitForExit(2000)
            }
            catch {
            }
        }
    }
    catch {
        Write-DebugTrace ("Failed to stop worker on close: " + (Get-ErrorMessage -ErrorObject $_))
    }

    try {
        if ($script:ModelSyncProcess -and -not $script:ModelSyncProcess.HasExited) {
            $script:ModelSyncProcess.Kill()
            try {
                [void]$script:ModelSyncProcess.WaitForExit(1000)
            }
            catch {
            }
        }
    }
    catch {
        Write-DebugTrace ("Failed to stop model sync on close: " + (Get-ErrorMessage -ErrorObject $_))
    }

    try {
        if ($script:GatewayProcess -and -not $script:GatewayProcess.HasExited) {
            Write-DebugTrace ("Stopping gateway PID=" + $script:GatewayProcess.Id + " because the main window is closing.")
            $script:GatewayProcess.Kill()
            try {
                [void]$script:GatewayProcess.WaitForExit(1000)
            }
            catch {
            }
        }
    }
    catch {
        Write-DebugTrace ("Failed to stop gateway on close: " + (Get-ErrorMessage -ErrorObject $_))
    }
    finally {
        if ($script:WorkerProcess) {
            try {
                $script:WorkerProcess.Dispose()
            }
            catch {
            }
        }
        $script:WorkerProcess = $null
        $script:WorkerCompleted = $true
        if ($script:GatewayProcess) {
            try {
                $script:GatewayProcess.Dispose()
            }
            catch {
            }
        }
        $script:GatewayProcess = $null
        if ($script:ModelSyncProcess) {
            try {
                $script:ModelSyncProcess.Dispose()
            }
            catch {
            }
        }
        $script:ModelSyncProcess = $null
    }
}

$closeButton.Add_Click({
    try {
        $closeButton.Enabled = $false
        & $closeWorkerSafely
    }
    finally {
        $form.Close()
    }
})

$pollTimer = New-Object System.Windows.Forms.Timer
$pollTimer.Interval = 400
$pollTimer.Add_Tick({
    try {
        if ([string]::IsNullOrWhiteSpace($script:WorkerEventFilePath) -or -not (Test-Path -LiteralPath $script:WorkerEventFilePath)) {
            if ($script:WorkerProcess -and $script:WorkerProcess.HasExited -and -not $script:WorkerCompleted) {
                $pollTimer.Stop()
                $script:WorkerCompleted = $true
                & $setDeploymentUiState $false
                $statusLabel.Text = Get-T -Key "status_failed"
                $failureText = (Get-T -Key "status_failed") + " Worker exited before writing any event output. Check launcher-debug.log."
                $timestamp = (Get-Date).ToString("HH:mm:ss")
                $logTextBox.AppendText("[$timestamp] $failureText`r`n")
                $logTextBox.SelectionStart = $logTextBox.TextLength
                $logTextBox.ScrollToCaret()
                $progressBar.Value = 0
            }
            return
        }

        $stream = [System.IO.File]::Open($script:WorkerEventFilePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
        try {
            $stream.Seek($script:WorkerEventOffset, [System.IO.SeekOrigin]::Begin) | Out-Null
            $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::UTF8)
            try {
                while (-not $reader.EndOfStream) {
                    $line = $reader.ReadLine()
                    if ([string]::IsNullOrWhiteSpace($line)) {
                        continue
                    }

                    $event = $line | ConvertFrom-Json
                    if ($event.progress -ne $null) {
                        $progressBar.Value = [Math]::Max($progressBar.Minimum, [Math]::Min($progressBar.Maximum, [int]$event.progress))
                    }
                    if (-not [string]::IsNullOrWhiteSpace([string]$event.status)) {
                        $statusLabel.Text = [string]$event.status
                    }
                    if (-not [string]::IsNullOrWhiteSpace([string]$event.log)) {
                        $timestamp = (Get-Date).ToString("HH:mm:ss")
                        $logTextBox.AppendText("[$timestamp] $($event.log)`r`n")
                        $logTextBox.SelectionStart = $logTextBox.TextLength
                        $logTextBox.ScrollToCaret()
                    }
                    if ([string]$event.type -eq "result") {
                        $pollTimer.Stop()
                        $script:WorkerCompleted = $true
                        & $setDeploymentUiState $false

                        if ([bool]$event.success) {
                            $statusLabel.Text = Get-T -Key "status_complete_hint" -Language ([string]$event.language)
                            $progressBar.Value = 100
                            $timestamp = (Get-Date).ToString("HH:mm:ss")
                            $logTextBox.AppendText("[$timestamp] " + (Get-T -Key "msg_done" -Language ([string]$event.language)) + "`r`n")
                            $deployRootForResult = if ([string]::IsNullOrWhiteSpace($deployRootTextBox.Text)) { $script:RootDir } else { [System.IO.Path]::GetFullPath($deployRootTextBox.Text.Trim()) }
                            Set-ResultAccessState -DeployRoot $deployRootForResult
                            $logTextBox.AppendText("[$timestamp] " + (Get-T -Key "log_dashboard_url" -Language ([string]$event.language)) + " " + $script:LastDashboardUrl + "`r`n")
                            if (-not [string]::IsNullOrWhiteSpace($script:LastGatewayToken)) {
                                $logTextBox.AppendText("[$timestamp] " + (Get-T -Key "log_gateway_token" -Language ([string]$event.language)) + " " + $script:LastGatewayToken + "`r`n")
                            }
                            try {
                                [void](Start-OpenClawGatewayForDeployRoot -DeployRoot $deployRootForResult -LogTextBox $logTextBox -Language ([string]$event.language))
                                Start-Process -FilePath $script:LastDashboardUrl | Out-Null
                                $logTextBox.AppendText("[$timestamp] " + (Get-T -Key "log_browser_launch" -Language ([string]$event.language)) + " " + $script:LastDashboardUrl + "`r`n")
                            }
                            catch {
                                $logTextBox.AppendText("[$timestamp] " + (Get-T -Key "log_browser_launch_failed" -Language ([string]$event.language)) + " " + (Get-ErrorMessage -ErrorObject $_) + "`r`n")
                            }
                            $logTextBox.SelectionStart = $logTextBox.TextLength
                            $logTextBox.ScrollToCaret()
                        }
                        else {
                            $failureLanguage = if ([string]::IsNullOrWhiteSpace([string]$event.language)) { $script:CurrentLanguage } else { [string]$event.language }
                            $failureText = Get-T -Key "status_failed_hint" -Language $failureLanguage
                            if (-not [string]::IsNullOrWhiteSpace([string]$event.error)) {
                                $failureText = $failureText + " " + [string]$event.error
                            }
                            $statusLabel.Text = $failureText
                            $timestamp = (Get-Date).ToString("HH:mm:ss")
                            $logTextBox.AppendText("[$timestamp] $failureText`r`n")
                            $logTextBox.SelectionStart = $logTextBox.TextLength
                            $logTextBox.ScrollToCaret()
                        }
                    }
                }
            }
            finally {
                $script:WorkerEventOffset = $stream.Position
                $reader.Dispose()
            }
        }
        finally {
            $stream.Dispose()
        }

        if ($script:WorkerProcess -and $script:WorkerProcess.HasExited -and -not $script:WorkerCompleted) {
            $pollTimer.Stop()
            $script:WorkerCompleted = $true
            & $setDeploymentUiState $false
            $statusLabel.Text = Get-T -Key "status_failed"
            $failureText = (Get-T -Key "status_failed") + " Worker exited before reporting completion. Check launcher-debug.log."
            $timestamp = (Get-Date).ToString("HH:mm:ss")
            $logTextBox.AppendText("[$timestamp] $failureText`r`n")
            $logTextBox.SelectionStart = $logTextBox.TextLength
            $logTextBox.ScrollToCaret()
            $progressBar.Value = 0
        }
    }
    catch {
        Write-DebugTrace ("Poll timer failed: " + (Get-ErrorMessage -ErrorObject $_))
    }
})

$startButton.Add_Click({
    if ($script:WorkerProcess -and -not $script:WorkerProcess.HasExited -and -not $script:WorkerCompleted) {
        return
    }

    $providerKey = Get-ProviderSelectionKey -DisplayText $providerComboBox.SelectedItem.ToString()
    $modelValue = Normalize-ModelId -ProviderKey $providerKey -Model $modelComboBox.Text
    $apiKeyValue = $keyTextBox.Text.Trim()
    $baseUrlValue = $baseUrlTextBox.Text.Trim()
    $deployRootValue = $deployRootTextBox.Text.Trim()

    if ($modelComboBox.Text -ne $modelValue) {
        $modelComboBox.Text = $modelValue
    }

    if ([string]::IsNullOrWhiteSpace($deployRootValue)) {
        $statusLabel.Text = Get-T -Key "status_failed_hint"
        $timestamp = (Get-Date).ToString("HH:mm:ss")
        $logTextBox.AppendText("[$timestamp] " + (Get-T -Key "msg_deploy_root") + "`r`n")
        $logTextBox.SelectionStart = $logTextBox.TextLength
        $logTextBox.ScrollToCaret()
        return
    }

    try {
        $deployRootValue = [System.IO.Path]::GetFullPath($deployRootValue)
    }
    catch {
        $statusLabel.Text = Get-T -Key "status_failed_hint"
        $timestamp = (Get-Date).ToString("HH:mm:ss")
        $logTextBox.AppendText("[$timestamp] " + (Get-T -Key "msg_deploy_root") + "`r`n")
        $logTextBox.SelectionStart = $logTextBox.TextLength
        $logTextBox.ScrollToCaret()
        return
    }

    $workspaceValue = Get-DefaultWorkspaceForRoot -RootPath $deployRootValue
    $workspaceTextBox.Text = $workspaceValue

    if ($providerKey -eq "Custom" -and [string]::IsNullOrWhiteSpace($baseUrlValue)) {
        $statusLabel.Text = Get-T -Key "status_failed_hint"
        $timestamp = (Get-Date).ToString("HH:mm:ss")
        $logTextBox.AppendText("[$timestamp] " + (Get-T -Key "msg_custom_base") + "`r`n")
        $logTextBox.SelectionStart = $logTextBox.TextLength
        $logTextBox.ScrollToCaret()
        return
    }

    & $setDeploymentUiState $true
    $progressBar.Value = 0
    $statusLabel.Text = Get-T -Key "status_starting"

    $job = @{
        ProviderKey = $providerKey
        Model = $modelValue
        ApiKey = $apiKeyValue
        BaseUrl = $baseUrlValue
        DeployRoot = $deployRootValue
        Workspace = $workspaceValue
        InstallDaemon = $installDaemonCheckBox.Checked
        CloneOfficialRepo = $cloneRepoCheckBox.Checked
        Language = $script:CurrentLanguage
    }

    try {
        $jobDownloadsDir = Join-Path $deployRootValue "downloads"
        Ensure-Directory -Path $jobDownloadsDir

        $jobFilePath = Join-Path $jobDownloadsDir ("worker-job-" + [Guid]::NewGuid().ToString("N") + ".json")
        $eventFilePath = [System.IO.Path]::ChangeExtension($jobFilePath, ".events.jsonl")

        if (Test-Path -LiteralPath $jobFilePath) {
            Remove-Item -LiteralPath $jobFilePath -Force
        }
        if (Test-Path -LiteralPath $eventFilePath) {
            Remove-Item -LiteralPath $eventFilePath -Force
        }

        Set-Content -LiteralPath $jobFilePath -Value (ConvertTo-JobJson -Job $job) -Encoding UTF8

        $script:WorkerJobFilePath = $jobFilePath
        $script:WorkerEventFilePath = $eventFilePath
        $script:WorkerEventOffset = 0
        $script:WorkerCompleted = $false

        $powerShellExe = Join-Path $PSHOME "powershell.exe"
        if (-not (Test-Path -LiteralPath $powerShellExe)) {
            throw "Unable to locate powershell.exe under $PSHOME"
        }

        $startInfo = New-Object System.Diagnostics.ProcessStartInfo
        $startInfo.FileName = $powerShellExe
        $startInfo.Arguments = ConvertTo-ProcessArgumentString -Arguments @(
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            $script:ScriptPath,
            "-WorkerMode",
            "-WorkerJobFile",
            $jobFilePath
        )
        $startInfo.WorkingDirectory = $script:RootDir
        $startInfo.UseShellExecute = $false
        $startInfo.CreateNoWindow = $true

        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $startInfo

        if (-not $process.Start()) {
            throw "Worker process did not start."
        }

        $script:WorkerProcess = $process
        Write-DebugTrace ("Started worker PID=" + $process.Id + "; job=" + $jobFilePath)
        $pollTimer.Start()
    }
    catch {
        $pollTimer.Stop()
        $script:WorkerProcess = $null
        $script:WorkerJobFilePath = $null
        $script:WorkerEventFilePath = $null
        $script:WorkerEventOffset = 0
        $script:WorkerCompleted = $true
        & $setDeploymentUiState $false

        $errorMessage = Get-ErrorMessage -ErrorObject $_
        $statusLabel.Text = Get-T -Key "status_failed_hint"
        $timestamp = (Get-Date).ToString("HH:mm:ss")
        $logTextBox.AppendText("[$timestamp] $errorMessage`r`n")
        $logTextBox.SelectionStart = $logTextBox.TextLength
        $logTextBox.ScrollToCaret()
        Write-DebugTrace ("Failed to start worker: " + $errorMessage)
    }
})

$form.Add_FormClosing({
    & $closeWorkerSafely
})

$null = $form.ShowDialog()
