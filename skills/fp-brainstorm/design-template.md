# Technical Design Output Template

Read this file only after the user confirms the selected approach and approves writing the reviewed design sections.

Use only sections relevant to the actual backend/frontend scope. Write through the canonical `design/00-index.md`, `design/backend.md`, and/or `design/frontend.md` entrypoints. When an end-specific design would exceed 500 lines, keep its stable entrypoint concise and put details in indexed numbered fragments. Do not create a combined root-level `design.md`, legacy `design-backend.md` / `design-frontend.md`, or an empty endpoint placeholder.

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

Append the exact Visual Source / component mapping / Visual Checks sections required by `SKILL.md` for frontend work.
