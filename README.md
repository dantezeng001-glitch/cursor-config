# cursor-config

个人 Cursor 全局配置备份，**仅同步 `rules/` 与 `skills/`**。

## 目录

- `rules/` — 全局 Cursor rules（`.mdc`），所有项目生效
- `skills/` — 用户自定义 Agent Skills

## 不入库

`plans/`、`projects/`、`plugins/`、`scripts/`、`skills-cursor/`（Cursor 内置技能）、`subagents/`、`extensions/`、`ai-tracking/` 等运行时文件、Cursor 自带内容、本地脚本一律不入库。`skills/` 下任何 `*.bak-*/` 命名的备份目录也会被忽略。

详见 `.gitignore`。

## 自动同步

本地 `scripts/auto-sync.ps1` 由 Windows 计划任务定时执行，commit 后 push 到 `origin/main`。该脚本本身不进入仓库（只在本机使用）。
