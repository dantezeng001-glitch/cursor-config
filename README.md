# cursor-config

Cursor 全局配置备份，核心是 rules + skills。

## 目录

- `rules/` — 全局 Cursor rules（`.mdc`），所有项目生效
- `skills/` — 用户自定义 Agent Skills
- `skills-cursor/` — Cursor 内置/改造版技能
- `commands/` — 自定义斜杠命令（若有）
- `scripts/` — 自动同步脚本（`auto-sync.ps1`、`install-auto-sync.ps1`）

`plans/`、`projects/`、`plugins/`、`subagents/`、`extensions/`、`ai-tracking/` 等运行时或工作内容一律不入库，详见 `.gitignore`。
