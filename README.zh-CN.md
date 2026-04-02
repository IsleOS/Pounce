<div align="center">

```
        ██          ██
      ██░░██      ██░░██
      ██░░░░██████░░░░██
      ██░░░░░░░░░░░░░░██
      ██░░░░██░░░░██░░░░██
    ██░░░░░░░░░░░░░░░░░░░░██
    ██░░░░░░░░░░██░░░░░░░░██
      ██░░░░░░░░░░░░░░░░██
        ██░░░░░░░░░░░░██
          ████████████
```

# CodeIsland

**你的 AI 代理住在刘海里。**

[![Release](https://img.shields.io/github/v/release/xmqywx/CodeIsland?style=flat-square&color=4ADE80)](https://github.com/xmqywx/CodeIsland/releases)
[![macOS](https://img.shields.io/badge/macOS-14%2B-black?style=flat-square&logo=apple)](https://github.com/xmqywx/CodeIsland/releases)
[![License](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](LICENSE.md)

[English](README.md) | 中文

</div>

---

一款原生 macOS 应用，将你的 MacBook 刘海变成 AI 编码代理的实时控制面板。监控会话、审批权限、跳转终端、和你的 Claude Code 宠物互动 — 无需离开当前工作流。

## 功能特性

### 灵动岛刘海

收起状态一眼掌握全局：

- **动画宠物** — 你的 Claude Code `/buddy` 宠物渲染为 16x16 像素画，带波浪/消散/重组动画
- **项目名 + 状态** — 按状态着色（青色=工作中，琥珀色=等待审批，绿色=完成，紫色=思考中）
- **会话数量** — `×3` 角标显示活跃会话数
- **像素猫模式** — 可切换显示手绘像素猫或宠物 emoji 动画

### 会话列表

展开刘海查看所有 Claude Code 会话：

- **像素猫头** — 每个会话前显示状态表情（眨眼、眼球转动、完成时爱心眼、出错时 X 眼）
- **自动识别终端** — 显示 Ghostty、Warp、iTerm2、cmux、Terminal、VS Code、Cursor 等
- **任务标题** — 显示你的第一条消息或 Claude 的摘要，不再只是文件夹名
- **运行时长** — 每个会话运行了多久
- **金色跳转按钮** — 点击跳到对应终端标签页（通过 cmux/Ghostty AppleScript）
- **发光圆点 + 渐变分割线** — 极简干净的设计
- **悬停效果** — 行高亮 + 终端图标变金色

### Claude Code 宠物集成

与 Claude Code 的 `/buddy` 伙伴系统完整集成：

- **精确属性** — 物种、稀有度、眼型、帽子、闪光状态和全部 5 项属性（调试、耐心、混乱、智慧、毒舌），使用与 Claude Code 完全相同的 Bun.hash + Mulberry32 算法计算
- **动态盐值检测** — 从 Claude Code 二进制文件中读取实际盐值，支持修改过的安装（兼容 any-buddy）
- **ASCII 精灵动画** — 全部 18 种宠物物种渲染为动画 ASCII 艺术，带空闲动画序列（眨眼、抖动），与 Claude Code 终端中显示完全一致
- **宠物卡片** — 左右布局：左侧 ASCII 精灵 + 名字，右侧 ASCII 属性条 `[████████░░]` + 性格描述
- **稀有度星级** — ★ 普通 到 ★★★★★ 传说，带颜色编码
- **18 种物种** — 鸭子、鹅、果冻、猫、龙、章鱼、猫头鹰、企鹅、乌龟、蜗牛、幽灵、六角恐龙、水豚、仙人掌、机器人、兔子、蘑菇、胖猫

### 权限审批

直接在刘海中审批 Claude Code 的权限请求：

- **代码差异预览** — 允许前查看具体改动（绿色/红色行高亮）
- **文件路径** — 警告图标 + 工具名 + 被修改的文件
- **拒绝/允许按钮** — 带键盘快捷键提示
- **基于 Hook 协议** — 通过 Unix socket 发送响应，无需切换终端

### 像素猫伙伴

手绘像素猫，6 种动画状态：

| 状态 | 表情 |
|------|------|
| 空闲 | 黑色眼睛，每 90 帧温柔眨眼 |
| 工作中 | 眼球左/中/右移动（阅读代码） |
| 需要你 | 眼睛 + 右耳抖动 |
| 思考中 | 闭眼，鼻子呼吸 |
| 出错 | 红色 X 眼 |
| 完成 | 绿色爱心眼 + 绿色调叠加 |

### 8-bit 音效系统

每个事件的芯片音乐提醒：

| 事件 | 默认 |
|------|------|
| 会话开始 | 开启 |
| 开始处理 | 关闭 |
| 需要审批 | 开启 |
| 审批通过 | 开启 |
| 审批拒绝 | 开启 |
| 会话完成 | 开启 |
| 出错 | 开启 |
| 上下文压缩 | 关闭 |

每个声音可单独开关。支持全局静音和音量控制。

### 项目分组

在平铺列表和项目分组视图之间切换：

- 按工作目录自动分组
- 可折叠的项目标题，显示活跃数量
- V 形图标展开/折叠

## 设置选项

| 设置 | 说明 |
|------|------|
| **屏幕** | 选择哪个显示器显示刘海（自动、内置或指定显示器） |
| **通知声音** | 选择提醒音风格 |
| **按项目分组** | 切换平铺列表和项目分组显示 |
| **像素猫模式** | 刘海图标切换：像素猫 或 宠物 emoji 动画 |
| **语言** | 自动（跟随系统） / English / 中文 |
| **开机启动** | 登录时自动启动 CodeIsland |
| **钩子** | 安装/卸载 Claude Code 钩子到 `~/.claude/settings.json` |
| **辅助功能** | 授予辅助功能权限以聚焦终端窗口 |

## 终端支持

CodeIsland 从进程树中自动检测你的终端：

| 终端 | 检测 | 跳转标签页 |
|------|------|-----------|
| cmux | 自动 | AppleScript（按工作目录匹配） |
| Ghostty | 自动 | AppleScript（按工作目录匹配） |
| Warp | 自动 | 仅激活（无标签页 API） |
| iTerm2 | 自动 | AppleScript |
| Terminal.app | 自动 | 激活 |
| Alacritty | 自动 | 激活 |
| Kitty | 自动 | 激活 |
| WezTerm | 自动 | 激活 |
| VS Code | 自动 | 激活 |
| Cursor | 自动 | 激活 |
| Zed | 自动 | 激活 |

## 安装

从 [Releases](https://github.com/xmqywx/CodeIsland/releases) 下载最新 `.dmg`，打开后拖到应用程序文件夹。

> **macOS 门禁提示：** 如果看到"Code Island 已损坏，无法打开"，在终端中运行：
> ```bash
> xattr -cr /Applications/Code\ Island.app
> ```
> 这会移除未签名应用的隔离标记。

### 从源码构建

```bash
git clone https://github.com/xmqywx/CodeIsland.git
cd CodeIsland
xcodebuild -project ClaudeIsland.xcodeproj -scheme ClaudeIsland \
  -configuration Release CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
  DEVELOPMENT_TEAM="" build
```

### 系统要求

- macOS 14+（Sonoma）
- 带刘海的 MacBook（外接显示器使用浮动模式）
- [Bun](https://bun.sh) 用于精确计算宠物属性（可选，缺少时回退到基本信息）

## 工作原理

1. **零配置** — 首次启动时，CodeIsland 自动将钩子安装到 `~/.claude/settings.json`
2. **钩子事件** — Python 脚本（`codeisland-state.py`）通过 Unix socket（`/tmp/codeisland.sock`）发送会话状态
3. **权限审批** — 对于 `PermissionRequest` 事件，socket 保持打开直到你点击允许/拒绝，然后将决定发回给 Claude Code
4. **宠物数据** — 从 `~/.claude.json` 读取名字/性格，用 Bun 运行 `buddy-bones.js` 获取精确的物种/稀有度/属性
5. **终端跳转** — 使用 AppleScript 通过匹配工作目录找到并聚焦正确的终端标签页

## 致谢

基于 [Claude Island](https://github.com/farouqaldori/claude-island)（作者 farouqaldori）改造。重构了像素猫动画、宠物集成、cmux 支持、国际化和极简发光点设计。

## 许可证

MIT
