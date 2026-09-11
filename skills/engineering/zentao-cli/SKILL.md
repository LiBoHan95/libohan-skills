---
name: zentao-cli
description: >-
  用公司禅道命令行工具 zentao 查 bug / 需求 / 任务 / 人员。当用户提到禅道、zentao、bug 编号（如 #18399）、
  bug 单、需求单、任务、复现步骤、截图、指派关系，或说「看看有什么 bug」「查一下这个单子」「我的待办/工作量」
  时使用。修 bug 前先取详情、需要 bug 的全公司范围或人员名单时也用它。
  写操作（resolve / activate / comment）会真实改动公司共享数据，执行前必须确认。
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
- **完整说明书永远以 `zentao doc` 为准**，本 skill 只是速查；遇到本文件没写的参数，跑 `zentao <子命令> --help` 或 `zentao doc`。

## 取数据约定

```bash
zentao list --format json          # 一律优先 --format json
zentao show 12345 --format json    # 单条详情
zentao show 1 2 3 --format json    # 批量，始终返回数组
```

- **不要解析默认的中文表格输出**，那是给人看的。`list` / `story` / `task` / `show` / `stats` / `search` / `team` 都支持 `--format json`。
- 单次调用约 0.5–1s；`--scope all` 例外，很慢。
- 字段含义不确定时先 `zentao schema`，别读 `zentao.py` 源码。

## 命令速查

| 命令 | 用途 |
| --- | --- |
| `zentao list` | bug 列表，`--scope` `--type` `--status` `--grep` `--product` `--sort` `--format` |
| `zentao story` | 需求列表（无 `--scope` / `--type`） |
| `zentao task` | 任务列表，`--sort` 多一个 `deadline` |
| `zentao show <id...> --type bug\|story\|task` | 详情：正文、附件、完整操作历史 |
| `zentao search <关键词>` | 跨 bug/需求/任务搜标题 |
| `zentao stats` | 我的工作量分布（按状态/严重程度/优先级/产品） |
| `zentao team` | 公司人员和岗位，`--dept` 按部门筛 |
| `zentao resolve` / `activate` / `comment` | **写操作**，见文末红线 |

`--type` 有两套含义，别混：在 `list` 里是**谁的 bug**（`assignedTo` 默认 / `openedBy` / `resolvedBy` / `closedBy`）；在 `show` / `search` / `stats` 里是**对象类型**（`bug` 默认 / `story` / `task`）。

## 范围：默认只看「我的」

**默认 `--scope mine` 只返回指派给我的，不是全公司。** 查不到别急着说「没有这个 bug」。

```bash
zentao list --scope unclosed --format json                   # 全公司未关闭的 bug
zentao list --scope unclosed --product 某产品 --format json   # 限定产品
zentao task --scope all --project 某项目 --format json        # 某项目全部任务
```

- `--scope`：`mine`（默认，全部状态）/ `unclosed`（全公司未关闭）/ `all`（全公司全部，很慢）。`story` 没有 `--scope`（禅道需求视图拿不到全量）。
- `--product` / `--project` 在 `unclosed` / `all` 下是范围选择器（名称部分匹配或 ID），能加就加。
- `--type` 只对 `mine` 有意义，跨范围用了会报错。

## 关键字段与坑

常用字段（`--format json` 每条约 61 个）：`id` / `title`（**任务用 `name`**）/ `status` / `severity` / `pri` / `type` / `productName` / `projectName` / `openedBy(Name)` / `assignedToName` / `resolvedBy` / `resolution` / `deadline` / `steps`（bug 正文 HTML）/ `url`（工具合成的网页地址）。

1. **空日期是 `"0000-00-00 00:00:00"`，不是 `null`** —— 判空用前缀匹配。
2. **任务标题字段是 `name`**，不是 `title`。
3. **bug 正文是 `steps`**（不是 `description`），HTML，图片是 `{文件名}` 占位符；要可点击的图片 URL 用 `zentao show <id>`（会展开，放在 `body`）。
4. **`pri` / `severity` 是字符串数字**（`"3"` 不是 `3`），比较前先转换。
5. **ID 不跨类型**：bug / 需求 / 任务的 ID 各自独立，同一数字是三个不同东西，`show` 必须靠 `--type` 区分。
6. **`module` 只有 ID**，没有名称映射。
7. **各命令 JSON 形状不同**：列表是数组；`show` 始终是数组（额外带 `body` / `actions`）；`stats` 是 `{"bug": {...}}`；`search` 是 `{"bug": [...], "story": [...], "task": [...]}`。

枚举对照（完整跑 `zentao schema`）：bug `status` = `active/resolved/closed`；bug `severity` = `1`致命/`2`严重/`3`一般/`4`轻微；`resolution` = `fixed/bydesign/duplicate/notrepro/postponed/willnotfix/external`；任务 `status` = `wait/doing/pause/done/cancel/closed`。

## 写操作红线

`resolve`（解决 bug）、`activate`（激活 bug）、`comment`（加备注）会**真实改动公司共享数据并可能给同事发通知**。

- **执行前必须先跟用户确认改哪些 id、改成什么、指派给谁**，批量前先用 `--dry-run` 预览。
- **`resolve` / `activate` 不要加 `--comment`**，只改状态和指派，备注留空。分支名和 commit 号留在 git 提交里就够了，不要往禅道写。
- `resolve` 的 `--assign` 留空时禅道会自动指派回创建者（提单人验证）。
- 提交后工具会重新拉状态校验，状态没变成预期值会报错。

只读操作（`status` / `schema` / `doc` / `list` / `story` / `task` / `show` / `stats` / `search` / `team`）随便跑。

## 配置

工具按优先级读：命令行参数 > `ZENTAO_URL` / `ZENTAO_ACCOUNT` / `ZENTAO_PASSWORD` 环境变量 > 文件常量 > `~/.config/zentao/config.json` > 上次登录的会话缓存（`~/.zentao_cookies.json`）。

- 三个参数属于**子命令**：`zentao status --url X`，不能写成 `zentao --url X status`。
- 会话失效且没有可用密码时，让用户把密码放进配置文件或环境变量，不要自己尝试登录。
