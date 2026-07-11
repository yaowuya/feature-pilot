# Technical Design Output Template

Read this file only after the user confirms the selected approach and approves writing the reviewed design sections.

Apply `../_shared/artifact-layout.md` as the normative layout contract. Use only sections relevant to the actual backend/frontend scope, and select each end's mutually exclusive form before writing:

- Small: `design/backend.md` or `design/frontend.md` owns the complete end design; do not create the corresponding end directory.
- Split: `design/backend/00-index.md` or `design/frontend/00-index.md` owns the `| Order | File | Kind | Owns |` manifest and links semantically divided numbered fragments; do not create the corresponding end `.md` file.

Choose split form for multiple independently readable features, subsystems, page areas, or ownership domains. Every index and fragment must stay within both hard fallback limits: **500 lines** and **30,000 characters**. `design/00-index.md` links directly to the form selected for each actual end. The chosen end entry directly owns either the complete small design or the split fragment manifest; no stable summary sits beside a split directory. Do not create a combined root-level `design.md`, legacy `design-backend.md` / `design-frontend.md`, an empty endpoint placeholder, or both forms for one end.

Keep `design/00-index.md` metadata-only and use this exact end-map section/table. The optional navigation lines may only link to the listed canonical entries; requirements, contracts, decisions, or design body sections belong in the selected end artifact.

```markdown
# <功能描述> Design Index

## Canonical End Entrypoints

| End | Canonical entrypoint | Mode |
| --- | --- | --- |
| Backend | `design/backend.md` | small |
| Frontend | `design/frontend/00-index.md` | split |
```

```markdown
# <功能描述> — 技术方案设计

## 第一部分：架构决策

### 决策 1：[主题]
- **选择**：[用户确认的选择]
- **理由**：[依据]

### 决策 2：[主题]
- **选择**：[用户确认的选择]
- **理由**：[依据]

## 第二部分：技术方案详述

### 后端模块设计

（新建/修改目录与文件职责；仅后端范围。）

### 数据模型

（字段、类型、用途、现有模型基类与关联规则；仅数据范围。）

### API 接口

（路由、方法、请求/响应、错误、权限；仅 API 范围。）

### 业务逻辑要点

（状态机、联动、异步、外部调用、失败处理。）

### 前端设计（仅 UI 范围）

#### 页面/视图
（页面路径、入口和导航。）

#### 组件
（复用/新建组件与布局层级。）

#### API 模块
（现有客户端封装位置和契约。）

#### 路由
（路由与权限守卫。）

#### 状态管理
（沿用当前项目的 store/composable/hook/context 或局部状态。）
```

For frontend work, place the exact Visual Source / component mapping / Visual Checks sections required by `SKILL.md` together in exactly one detailed owner: `design/frontend.md` in small form or one manifest-listed detail fragment in split form. The split index records ownership only and does not duplicate those sections.
