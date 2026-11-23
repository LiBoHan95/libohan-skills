---
name: zentao-cli
description: >-
  用公司禅道命令行工具 zentao 查 bug / 需求 / 任务 / 迭代 / 人员。当用户提到禅道、zentao、bug 编号（如 #18399）、
  bug 单、需求单、任务、迭代、复现步骤、截图、指派关系，或说「看看有什么 bug」「查一下这个单子」「我的待办/工作量」
  时使用。修 bug 前先取详情、需要 bug 的全公司范围或人员名单时也用它。
  写操作（提需求、建任务、resolve / activate / assign / 备注）会真实改动公司共享数据并给同事发通知，执行前必须确认。
metadata:
  required-tools: Bash 里可执行的 zentao CLI（~/.local/bin/zentao -> ~/dev/chandao/zentao.py）
---

# 禅道查询（zentao CLI）

公司禅道的唯一查询入口是 `zentao` 命令。账号没有禅道 API 权限，工具走**模拟网页登录 + 读取页面 `.json` 视图**，字段名沿用禅道的英文命名。

**别去猜 bug 内容，也别问用户要编号——直接查。** 只有写操作才需要停下来确认。

## 先确认入口和状态

```bash
zentao status          # 不带子命令时默认执行，只报告登录状态，不会自动重登
zentao doc             # 打印完整说明书（从任意目录都能跑，不需要登录）
zentao schema          # 枚举取值 + 字段说明（JSON，不需要登录/配置）
```

- `status` 显示「已登录且会话有效」→ 直接查。
- 「未登录」或「会话已失效」→ 需要用户提供密码（放 `~/.config/zentao/config.json` 或环境变量），会话失效时具体查询命令会自动重登。
- **完整说明书永远以 `zentao doc` 为准**，本 skill 只是速查；遇到本文件没写的参数，跑 `zentao <对象> <动作> --help` 或 `zentao doc`。

## 命令结构：两级

顶层是**对象**，第二级才是**动作**。旧的一级写法（`zentao list` / `zentao show` / `zentao resolve` / `zentao comment`）**已全部失效**，会报 `invalid choice`。

```bash
zentao status|schema|doc|login|stats|search|team|help    # 一级
zentao bug|story|task|iteration <动作>                    # 两级
```

| 对象 | 动作 |
| --- | --- |
| `bug` | `list` `show` `comment` `edit-comment` `resolve` `activate` `assign` |
| `story` | `list` `create` `show` `flow` `comment` `edit-comment` |
| `task` | `list` `show` `create` `edit` `start` `finish` `cancel` `activate` `comment` `edit-comment` |
| `iteration` | `list` `show` |

## 取数据约定

```bash
zentao bug show 18622 --format json      # 单条详情
zentao bug show 18622 18507 --format json  # 批量，始终返回数组
zentao bug list --format json            # 列表
```

- **不要解析默认的中文表格输出**，那是给人看的。列表类命令都支持 `--format json`（部分还支持 `csv`）；`show` 只有 `table|json`。
- 单次调用约 0.5–1s；`--scope all` 例外，很慢。
- 字段含义不确定时先 `zentao schema`，别读 `zentao.py` 源码。

## 命令速查

| 命令 | 用途与主要参数 |
| --- | --- |
| `zentao bug list` | `--type {assignedTo\|openedBy\|resolvedBy\|closedBy}` `--scope {mine\|unclosed\|all}` `--status` `--grep` `--product` `--project` `--sort {id\|pri\|severity\|openedDate}` `--all` `--full` |
| `zentao story list` | `--status` `--grep` `--product` `--sort {id\|pri\|openedDate}` `--all` `--full`（**没有 `--scope` / `--type`**） |
| `zentao story create` | **写操作**：提需求；`--project <迭代ID\|名称>` 直接建进迭代并自动关联（状态 active、阶段 projected），`--dry-run` 先预览 |
| `zentao task list` | `--status` `--grep` `--project` `--sort {id\|pri\|openedDate\|deadline}` `--scope {mine\|unclosed\|all}` `--all` `--full` |
| `zentao <对象> show <id...>` | 详情：正文、附件、完整操作历史（`actions`） |
| `zentao iteration list` | `--scope {undone\|all\|closed}` `--grep` `--full` |
| `zentao iteration show <ref>` | 迭代下的需求/任务/bug，`ref` 可传 `145` 或 `Sprint26.9.2`（部分匹配）；`--type [{story,task,bug}...]` `--status` `--grep` |
| `zentao search <关键词>` | 跨类型搜标题，`--type [{bug,story,task}...]` `--limit` `--full` |
| `zentao stats` | 我的工作量分布，`--type {bug\|story\|task}` |
| `zentao team` | 公司人员和岗位，`--dept` 按部门筛，`--grep` 按姓名/账号搜 |
| `zentao bug resolve\|activate\|assign` / `task start\|finish\|cancel\|activate` / `story flow` | **写操作**，见文末红线 |

**`--type` 在不同命令里含义完全不同**，别混：`bug list --type` 是**谁的 bug**（`assignedTo` 默认 / `openedBy` / `resolvedBy` / `closedBy`）；`search` / `iteration show` 的 `--type` 是**对象类型**。`show` 现在不再需要 `--type`，对象写在命令里。

## 范围：默认只看「我的」

**默认 `--scope mine` 只返回指派给我的，不是全公司。** 查不到别急着说「没有这个 bug」。

```bash
zentao bug list --scope unclosed --format json                  # 全公司未关闭的 bug
zentao bug list --scope unclosed --product 某产品 --format json   # 限定产品
zentao task list --scope all --project 某项目 --format json       # 某项目全部任务
```

- `--scope`：`mine`（默认，全部状态）/ `unclosed`（全公司未关闭）/ `all`（全公司全部，很慢）。`story list` 没有 `--scope`。
- `--product` / `--project` 在 `unclosed` / `all` 下是范围选择器（名称部分匹配或 ID），能加就加。
- `bug list --type` 只对 `mine` 有意义，跨范围用了会报错。
- 默认分页 20 条，`--all` 才不分页；`--format csv/json` 始终导出全部，不受分页影响。

## 关键字段与坑

常用字段（`--format json` 每条约 61 个）：`id` / `title`（**任务用 `name`**）/ `status` / `severity` / `pri` / `type` / `productName` / `projectName` / `openedBy(Name)` / `assignedToName` / `resolvedBy` / `resolution` / `deadline` / `steps`（bug 正文 HTML）/ `url`（工具合成的网页地址）/ `body`（`show` 独有的纯文本正文）/ `actions`（`show` 独有的操作历史字典，键是动作 ID）。

1. **空日期是 `"0000-00-00 00:00:00"`，不是 `null`** —— 判空用前缀匹配。
2. **任务标题字段是 `name`**，不是 `title`。
3. **bug 正文是 `steps`**（不是 `description`），HTML，图片是 `{文件名}` 占位符；要可点击的图片 URL 用 `zentao bug show <id>`（会展开，放在 `body`）。
4. **`pri` / `severity` 是字符串数字**（`"3"` 不是 `3`），比较前先转换。
5. **ID 不跨类型**：bug / 需求 / 任务的 ID 各自独立，同一数字是三个不同东西——所以对象必须写在命令里（`zentao bug show` vs `zentao task show`）。
6. **`module` 只有 ID**，没有名称映射。
7. **各命令 JSON 形状不同**：列表是数组；`show` 始终是数组（额外带 `body` / `actions`）；`stats` 是 `{"bug": {...}}`；`search` 是 `{"bug": [...], "story": [...], "task": [...]}`。
8. **`zentao search` 不可靠**：实测连标题里明明含关键词的需求都搜不到，所以「搜不到」不能当作「不存在」的证据。要判断某需求有没有任务，用 `zentao iteration show <ref> --type task --format json` 按 `story` 字段过滤。
9. **时间字段**形如 `2026-09-10 13:53:16`，可直接用来判断 bug 的新旧与是否被反复激活（历史里多次「解决→激活」说明修得不彻底）。
10. **`zentao task finish` 不带 `--consumed` 会被服务端拒**（「本次消耗」不能为 0）。此时是**半成功**：状态未流转，但随命令带的 `--assign` 已先行生效——补 `--consumed <n>` 重跑即可（参照同批任务的历史消耗值）。
11. **建任务/写操作都可能「假成功」**：命令回显成功但服务端没落库。**照旧要回读核对**，建完用 `zentao iteration show <ref> --type task --format json` 看条数/最大 id 有没有变。

## 写操作红线

`resolve`（解决 bug）、`activate`（激活 bug）、`assign`（改派）、`comment`（加备注）、任务状态流转、`story create` / `task create` 都会**真实改动公司共享数据并给同事发通知**。

- **需求要进迭代就用 `--project`，不要开浏览器**：`zentao story create --project <迭代ID|名称> --title "…"` 走迭代上下文建需求，服务端在同一次请求里写 `projectstory` 关联，状态直接 `active`、阶段 `projected`——不需要 `--no-review`。不带 `--project` 才落在产品下、默认是草稿；草稿当前账号关联不了（没有 `project-linkStory` 权限）。
- `iteration` 只有 `list` / `show`；把需求放进迭代用上面的 `story create --project`，不要以为得去网页端点「关联需求」。
- **执行前必须先跟用户确认改哪些 id、改成什么、指派给谁**，批量前先用 `--dry-run` 预览。
- **默认不写备注**：`resolve` / `activate` / `task finish` 这些**不要加 `--comment`**，只改状态和指派，备注留空。分支名和 commit 号留在 git 提交里就够了。
- 用户**明确要求写备注**时（「备注分支名」「写个备注」），走 `zentao-comment` 技能——那里有备注该怎么写的全部约定，包括先出草稿给用户确认。
- `resolve` 的 `--assign` 留空时禅道会自动指派回创建者（提单人验证）；`bug assign --to` 支持姓名部分匹配。
- 提交后工具会重新拉状态校验，状态没变成预期值会报错。

只读操作（`status` / `schema` / `doc` / `list` / `show` / `stats` / `search` / `team` / `iteration`）随便跑。

相关技能：需要写备注时调用 Skill 工具用 `zentao-comment`。

## 配置

工具按优先级读：命令行参数 > `ZENTAO_URL` / `ZENTAO_ACCOUNT` / `ZENTAO_PASSWORD` 环境变量 > 文件常量 > `~/.config/zentao/config.json` > 上次登录的会话缓存（`~/.zentao_cookies.json`）。

- 三个参数属于**子命令**：`zentao status --url X`，不能写成 `zentao --url X status`。
- 会话失效且没有可用密码时，让用户把密码放进配置文件或环境变量，不要自己尝试登录。
