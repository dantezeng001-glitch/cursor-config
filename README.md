# cursor-config

Cursor 的全局配置备份，核心是 rules + skills + plans。

## 目录说明

- `rules/` — 全局 Cursor rules（`.mdc` 文件），所有项目生效
- `skills/` — 用户自定义的 Agent Skills
- `skills-cursor/` — Cursor 内置/改造版技能
- `commands/` — 自定义斜杠命令（若有）

> `plans/` 目录含工作相关计划文档，为避免公司保密风险，**不入本仓库**。

## 换 PC 恢复步骤

```bash
# 1. 克隆到目标位置（注意是 C:\Users\<你的用户名>\.cursor）
cd $env:USERPROFILE
git clone <repo-url> .cursor-new

# 2. 如果 .cursor 已被 Cursor 创建过，先备份再替换
Move-Item .cursor .cursor.bak
Move-Item .cursor-new .cursor

# 3. 把 .cursor.bak 里的 projects/ plugins/ subagents/ 等运行时目录
#    合并回新的 .cursor（这些是本机状态，没入库）
```

## 不同步的是什么

- `projects/` 每个工作区的 agent-transcripts / terminals / mcps 缓存
- `plugins/` 插件缓存
- `subagents/`、`extensions/`、`ai-tracking/` 等运行时状态

这些都是 Cursor 自动生成的临时状态，无需云同步。详见 `.gitignore`。
