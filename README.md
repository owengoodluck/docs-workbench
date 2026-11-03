# docs-workbench

临时生成的设计文档、调研笔记与图表资料的统一工作台。

这里的东西**默认是过程产物，不是终稿**。写完即走、定稿即归档，是这个仓库的正常状态。

## 目录结构

| 路径 | 放什么 | 保留策略 |
| --- | --- | --- |
| `inbox/` | 还没想好放哪的临时投递区 | 30 天。到期未归位即删除 |
| `design/` | 设计文档，按主题建子目录 | 主题定稿后压缩结论，原文移入 `archive/` |
| `research/` | 调研、竞品对比、资料摘录 | 同上 |
| `archive/<年份>/` | 只读归档快照 | 永久。只允许 `git mv` 进入，不改内容 |
| `assets/` | 图片、PDF、pptx 等二进制；`assets/diagrams/` 放跨文档共享的图 | 跟随引用它的文档一起删除 |
| `templates/` | 文档骨架 | 不删，改模板请单独提交 |
| `scripts/` | 维护脚本 | — |

## 文件命名

```
YYYY-MM-DD-主题-类型.md
```

类型限定五种：`design`（方案设计）、`research`（调研）、`adr`（决策记录）、`spec`（规格）、`note`（随手笔记）。

例：

```
2026-11-03-支付链路重构-design.md
2026-11-05-对象存储选型-research.md
```

文件名以日期开头，`ls` 的顺序即时间顺序，批量清理和归档都不需要打开文件。

主题段可用中文或英文，但**同一个目录内保持一致**，不要中英混写。

`design/` 下按**主题**建目录，不按日期——同一主题的多个版本聚在一起才有用，日期信息已经在文件名里了。

```
design/
└── 支付链路重构/
    ├── 2026-11-03-整体方案-design.md
    ├── 2026-11-05-灰度策略-design.md
    └── diagrams/                    # 仅当图太复杂或被复用时
        └── 2026-11-03-时序.mmd
```

## 图表约定

**mermaid 图默认内联在 Markdown 里**，作为代码块直接写。它是文本，`git diff` 天然可读，改动一行连线在评审时看得见——这正是选 mermaid 而不是截图的原因。拆成独立文件再引用，会退回到「附件」的体验。

只有三种情况才拆成独立 `.mmd` 文件：

- 同一张图被 2 个以上文档引用（作单一源，渲染成 SVG 后各自引用）
- 图超过约 30 个节点，塞在正文里会打断阅读
- 需要脚本或 CI 批量渲染、校验语法

拆出来的 `.mmd` 放在**对应文档同目录的 `diagrams/` 下**，不要建顶层 `diagrams/`——文档目录改名时，相对路径会全部失效。

**渲染产物只提交 SVG，不提交 PNG。** SVG 是文本、能 diff、缩放不糊。放 `assets/diagrams/`，文件名与 `.mmd` 保持一致。

**语法只用稳定类型。** GitHub 内置的 Mermaid 版本通常低于本地，以下类型是安全的：

`flowchart` `sequenceDiagram` `stateDiagram-v2` `classDiagram` `erDiagram` `gantt` `pie` `journey`

以下较新的类型在 GitHub 上可能渲染失败、只剩代码块（本地预览正常，容易误判）：

`architecture-beta` `sankey-beta` `block-beta` `timeline` `quadrantChart` `xychart-beta`

drawio / excalidraw 的源文件（`.drawio` 是 XML、`.excalidraw` 是 JSON）也是文本，放 `assets/diagrams/` 正常入库即可；只有导出的位图才需要 LFS。

## 公开仓库注意事项

本仓库是公开的。mermaid 源码和 markdown 都是**纯文本，会被搜索引擎完整索引**——比截图危险得多。

提交前检查：

- 真实域名、内网地址 → 抽象成 `order-svc`、`internal-api`
- `erDiagram` 里的真实表名、字段名 → 脱敏
- 报障截图里的用户标识、订单号 → 打码或重绘
- 密钥、token、`.env` 已在 `.gitignore` 中排除，不要用 `git add -f` 绕过

## 维护

```bash
# 查看 inbox 里超过 30 天未归位的文件（只读，不删）
./scripts/cleanup-inbox.sh

# 确认无误后执行清理
./scripts/cleanup-inbox.sh --yes

# 自定义保留天数
DAYS=14 ./scripts/cleanup-inbox.sh
```

## 分支与协作

只用 `main` 单分支，不走 PR 流程。文档仓库上 PR 只会制造摩擦，然后被绕过。

需要评审时，在文档头部字段里标 `status: draft | review | approved` 即可。
