# 仓库约定

这个仓库收纳我自己维护的 agent skills。规则写给 agent 执行，改动前先读一遍。

## 目录结构

技能放在 `skills/<桶>/<技能名>/`。桶按推广级别分：

- `engineering/`、`productivity/` 是**推广桶**，里面的技能必须出现在顶层 `README.md` 和桶自己的 `README.md` 里。
- `misc/`、`in-progress/`、`deprecated/` 不是推广桶，里面的技能**不得**出现在顶层 `README.md` 里。

推广桶目前有 `engineering/` 和 `productivity/`。需要新桶时再建目录和它的 `README.md`。

## 每个技能的结构

```
skills/<桶>/<技能名>/
  SKILL.md
  agents/openai.yaml     Codex 侧的展示元数据
  evals/evals.json       可选，评测用例
  references/ scripts/   可选，只放这个技能自己用的文件
```

共享参考文档放在拥有它的技能目录内。其他技能要用它，写「调用 Skill 工具」，不要写 `../other-skill/FILE.md` 这种跨目录引用。依赖要写清工具名，比如 `Call the Skill tool with "feature-flow"`，光在正文里丢一个 `/name` 命中率低。

## 调用方式必须二选一

- **User-invoked**：`SKILL.md` 里写 `disable-model-invocation: true`，同时在 `agents/openai.yaml` 里写 `policy.allow_implicit_invocation: false`。description 写成给人看的一行摘要，去掉「当用户说……」这类触发词。
- **Model-invoked**（默认）：不加上述字段。description 保留触发词，让自动调用能命中。

判断标准是「模型能不能自主地、有用地用到它」，不是「会不会被复用」。user-invoked 的技能永远不能被别的技能调用，任何情况下都不行。

## 改完必须同步

- 新增、改名、删除技能后：重跑 `bash scripts/link-skills.sh`。
- 每个技能名在 README 里必须链接到它的 `SKILL.md`。
- 推广桶的技能改了行为后，同步更新顶层 `README.md` 和桶 `README.md` 里的一行描述。

## 写作约定

- 正文用中文。
