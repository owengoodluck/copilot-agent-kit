# Copilot Agent Kit（中文参考译本）

> 这是参考译文，**英文版 `../README.md` 为准**。本目录下任何文件都不参与安装、不会被 agent 读取。

往任意 git 仓库装一份 Copilot 配置：**一个事实文件 + 三个角色 agent**，让新需求按你现有的架构和写法落地。

跑在 VS Code 或 IntelliJ IDEA 的 Copilot 里。不需要云端 agent，不需要 CLI。

## 里面有什么

```
copilot-agent-kit/
├── README.md                  本文件——唯一需要读的文档
├── PROJECTS.md                多项目台账：装了哪些、什么版本、反复出什么问题
├── install.sh                 装 5 个文件；装前先查已有 agent；--prefix=
├── scan.sh                    只取确定事实，检测不到就写 none found，绝不编命令
├── dependency-cruiser.js      5 条规则；拷到项目根目录改名 .dependency-cruiser.js
├── templates/                 ← 只有这部分会被复制进项目
│   ├── AGENTS.md              事实层
│   └── .github/
│       ├── agents/{planner,implementer,reviewer}.agent.md
│       └── PULL_REQUEST_TEMPLATE.md
└── zh/                        中文参考译本；不安装，也不被任何 agent 读取
```

`templates/` 才是产品。其余都是机器或台账：你只运行 `scan.sh`、`install.sh`，偶尔翻一下
`PROJECTS.md`，这些都不用改。

## 30 秒理解

问题不是"agent 不够聪明"，是**它不知道你的项目长什么样**——于是编路径、发明目录、顺手重构。

解法不是写更长的 prompt，是**把事实和角色分开**：

| | 内容 | 每个项目 |
|---|---|---|
| 事实层 | `AGENTS.md`：技术栈、命令、目录地图、架构不变量、禁止事项 | 必须自己写 |
| 角色层 | `.github/agents/` 三个文件 | 原样复制，永不改 |

角色层正文只有一句关键要求：**先读 `AGENTS.md` 再动手**。所以一套 agent 用在你所有项目上，
架构变了只改一个文件，三个 agent 自动跟上。

## 装

```bash
./install.sh /path/to/your-project
```

装进去 5 个文件：`AGENTS.md`、3 个 agent、PR 模板。已有文件默认跳过，不会覆盖你改过的内容。
`--force` 只刷新角色层，**永远不会替换已经填过的 `AGENTS.md`**——那里面是两段手写内容，任何脚本都
重建不出来（要覆盖得显式加 `--force-facts`）。多项目升级角色层：`./install.sh <项目> --agents-only --force`。

**没有任何东西会自动填 `AGENTS.md`。** `install.sh` 原样拷模板（连带方括号），`scan.sh` 只把草稿
打到标准输出、从不写文件。这个分工是有意的：

| `AGENTS.md` 的部分 | 谁来做 | 为什么 |
|---|---|---|
| 技术栈、命令、禁改区、目录地图 | 你从 `scan.sh` 输出粘过来 | 机械可判，但候选命令仍需手动执行一次 |
| 架构不变量、禁止边界 | 你手写 | 代码里看不出来；猜错会误导所有 agent 数月 |

如果你一直没填，模板会刻意保持可识别：`planner` 会在回答开头声明"fact layer missing，以下内容
从代码推断"，而不是假装懂你的架构。

## 项目里已经有 agent 了怎么办

真实仓库基本都有：手写的 `plan` agent、`.cursor/rules`、`CLAUDE.md`、组织统一发布的 agent。
**不要上来就装。**冲突有两处，严重程度完全不同。

**事实层才是危险的。** 只要文件在，就都会被加载。两份都在写"约定"的文件不会合并——模型只按其中
一份走，而且你永远不会知道是哪一份。保留 `AGENTS.md` 为唯一正本，其余全部改成指针（`CLAUDE.md`
里就写一行"读 AGENTS.md"）。副本就是分叉，分叉必然漂移。

**角色层好办得多。** 每个角色，只允许一个权威：

| 情况 | 处置 |
|---|---|
| 旧的 agent 是你自己的、没人用 | 删掉。留一个备选等于每次靠猜 |
| 团队共有，别人和 CI 都在引用 | 原样别动；用 `--prefix=repo` 装成 `repo-planner` / `repo-implementer` / `repo-reviewer`，并在 AGENTS.md 的角色表里把两者都登记 |
| 职责不同、没有重叠 | 都留着，没什么要解决的 |
| 旧的确实比我们的好 | 删我们的。判断标准一直没变：它引用的路径是真的吗？ |
| 内置 Plan agent、组织/企业级 agent | 删不掉。在自己的 `description` 里写清差异（"bound to this repo's AGENTS.md"），不要去重复它们的活 |

绝对不要 `planner2`、`planner-new`、`my-planner`——选的时候这些名字不携带任何信息。
`repo-` 前缀说明的是"它跟别人有什么不同"。

`install.sh` 写文件之前会先把已有的 agent 列出来；`scan.sh` 第 3 节会列出找到的所有 agent 与指令
文件，以及各自看上去负责什么角色。

## 接入：四步，约 20 分钟

**第 1 步：扫描**

```bash
bash scan.sh /path/to/your-project > /tmp/facts.md
```

输出六节：技术栈与包管理器判定（**多锁文件共存会告警**，这是命令写错的头号原因）、候选命令
（从 `package.json` scripts、Makefile、CI 里提取）、已有约束配置、禁改区、目录地图，以及最后
**只能人来答的三个问题**。检测不到就写 "none found"，绝不编一条看起来合理的命令。

**第 2 步：粘进去，只手写两段**

粘贴前五节，并**逐条执行第 2 节的命令**——候选不等于可用（有些要先装依赖、起数据库）。

剩下两段只有你能写，因为代码里看不出来：

- **架构不变量**：谁能调谁，一句话。判断标准是"能不能被写成 lint 规则"。"代码要清晰"不合格，
  "依赖方向只允许 api → service → repo"合格。
- **禁止事项**：禁改目录（扫描器能认）+ 流程型禁令（不许改测试让 CI 过、不许自行加依赖）。

**第 3 步：验证真的被加载**

开新会话，问一个偏门问题，展开回答里的 **References**，看有没有出现 `AGENTS.md`。

**文件存在 ≠ 被加载。** 这步最常被跳过，跳过就等于没装。

**第 4 步：提交。** 本地立刻就生效，提交只为留档。

> IDE 自带的 `/init`（VS Code）或 Settings → GitHub Copilot → Customizations（IDEA）也能生成
> 草稿，但它**会编命令**。`scan.sh` 存在的意义就是只取确定的事实。两者可以一起用。

## 日常一轮

```
你写任务 → planner 出方案 → 你拍板 → implementer 实施 → reviewer 审查 → 你提交
```

- **写任务四段式**：改什么 / 改哪里（给路径）/ 什么算做完 / 怎么验证（具体命令）。缺一段就掉质量。
- **判 planner 是否真读懂仓库**：只看它引用的路径是否真实存在。
- **意见写成工单**：位置 + 现象 + 期望 + 不要动 X。别写"这里逻辑有点问题"，它会猜错再浪费一轮。
- **停手条件**：第 3 轮还在同一个问题上、diff 在涨而不是收敛、它开始改测试让 CI 变绿。

## 让规矩靠工具，不靠文档

写在文档里的规则，agent 会漏；能被工具拦住的规则，它漏不了。

`dependency-cruiser.js` 是复制即用的起点，五条通用规则（循环依赖、指向不存在文件的 import、
未声明的包、生产代码引 devDependencies、生产代码引测试文件）。拷到仓库根目录改名为
`.dependency-cruiser.js` 后用 `npx depcruise src --config .dependency-cruiser.js` 跑。

**落地顺序决定它能不能活下来**：先数现有违规 → **只把零违规的规则设成 `error`**，其余先 `warn`
记账 → 每两周升一条。一次全设 error，CI 立刻全红，你会关掉它，然后就死了。

设完**故意写一行违规 import，确认它真的报错**。

Python 用 `import-linter`，规则同理：先只开"分层禁止反向依赖""禁止跨包 import 内部模块"。

## 维护节奏

| 时机 | 动作 | 耗时 |
|---|---|---|
| 交接一个需求 | 看 reviewer 有没有抓到越界 | 0 |
| 同一句 review 意见出现第二次 | 写进 `AGENTS.md`，不要再口头说一遍 | 1 分钟 |
| 每月第一个周末 | 看 `PROJECTS.md` 的"fact layer updated"列，超一个月的重跑 `scan.sh` 核对 | 5 分钟 |
| 每季度 | 挑一个项目回归：路径是真的吗？埋的违规抓得到吗？ | 半小时 |

`PROJECTS.md` 放在 `install.sh` 旁边是有意的：**你最需要它的时候，正是要跑 `--agents-only`
升级命令的时候**，那时你一定在这个目录里。第三个项目开始就离不开了。

## v2 砍掉了什么

v1 有 39 个文件，现在 10 个（含中文参考 13 个）。砍的都是**要你维护、要你做决定**的部分：

| 砍掉 | 为什么 |
|---|---|
| 英文模板副本（13 文件） | 同一份规则维护两遍，必然漂移 |
| `copilot-instructions.md` | Copilot 原生读 `AGENTS.md`，两份是漂移风险 |
| `docs/architecture.md` + `docs/conventions.md` | 一次架构变更要改三个文件，实际只会改一个。合成一个，超两页再拆 |
| `karpathy.instructions.md` | 四条原则压成"工作纪律"四行 |
| `project-onboarder` agent | 已由 `scan.sh` + 你的 20 分钟替代，且它当初会自己编命令 |
| `test-writer` / `docs-keeper` agent | 职责并进 implementer 的"完成定义"，少一个"该选谁"的决定 |
| 两份 guides / 两份 starter README | 内容并进 README 和 `dependency-cruiser.js` 注释 |

**没砍的**：`scan.sh`（机器，不用读）、`dependency-cruiser.js`（实测过）、三个 agent、
`AGENTS.md` 的结构。

判断标准：**你每周要读、要改、要在其中做选择的文件，只有 `AGENTS.md` 一个。**
