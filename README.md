# libohan-skills

我自己维护的 agent skills 集合。技能按桶组织，用符号链接安装到各个 agent harness。

## 安装

```bash
bash scripts/link-skills.sh
```

脚本把 `skills/` 下的每个技能链接到 `~/.claude/skills` 和 `~/.agents/skills`。新增、改名或删除技能后重跑一次即可。

## 技能

### Model-invoked

模型或人都能触发。

**engineering**

| 技能 | 说明 |
|---|---|
| [bug-fix-flow](skills/engineering/bug-fix-flow/SKILL.md) | 调研 → 方案 → 实现 → 验证，修复已约定行为失效的问题 |
| [feature-flow](skills/engineering/feature-flow/SKILL.md) | 需求对齐 → 设计 → 方案 → 实现 → 测试 → review，开发新功能 |
| [zentao-cli](skills/engineering/zentao-cli/SKILL.md) | 用 zentao 命令行查公司禅道的 bug / 需求 / 任务 / 人员 |

**productivity**

| 技能 | 说明 |
|---|---|
| [tavily-search](skills/productivity/tavily-search/SKILL.md) | 用 tvly 命令行搜索网络，返回 LLM 优化的结果 |

### User-invoked

只能由人输入名字触发。目前没有。

## 桶的推广级别

技能放在 `skills/<桶>/<技能名>/`。`engineering/` 和 `productivity/` 是推广桶，技能会出现在这个 README 里；`misc/`、`in-progress/`、`deprecated/` 不是推广桶，不会出现在这里。目前有 `engineering/` 和 `productivity/`。

完整约定见 [CLAUDE.md](CLAUDE.md)。
