# 信创适配范围

本文件用于全新或增量适配的只读审计。先按项目事实发现入口，再形成方案；下列路径只是常见示例，不要求每个项目都具备相同结构。

## 项目识别

先识别并记录证据：

- Python、Django 版本及通用 settings、环境配置加载入口。
- 实际依赖入口，如 `requirements*.txt`、`pyproject.toml` 和锁文件。
- 当前数据库 backend、`DATABASE_TYPE`、`DATABASES`、`INSTALLED_APPS` 与 `DEFAULT_AUTO_FIELD`。
- 原始 migration、迁移补丁和部署描述文件所在目录。
- 与待扫描文件相关的 Git 未提交变更；不得覆盖用户已有修改。
- 达梦和 OceanBase 连接是否可用，以及已有验证结果。

根据代码和用户信息将项目识别为通用 Django、蓝鲸 SaaS、AutoOps 或其他实际类型。只有确认是蓝鲸或 AutoOps 时才应用其平台变量、固定路径和版本模式。

## 适配类型证据矩阵

| 检查项 | 全新适配证据 | 增量适配证据 |
| --- | --- | --- |
| 数据库分支 | 所选目标数据库分支整体缺失 | 已存在达梦或 OceanBase 分支 |
| 补丁注册 | 没有迁移补丁机制 | 已注册 `cw_cornerstone.migrate_patch` 或等价机制 |
| 补丁目录 | 所选数据库补丁目录不存在 | 已有任一目标数据库补丁 |
| backend/驱动 | 所选数据库依赖整体缺失 | 已安装或声明目标 backend/驱动 |
| 用户意图 | 首次接入、新 SaaS、从未适配 | 补充、修复、升级、完善或审查 |
| migration 日志 | 尚未进行目标库迁移 | 已有适配后的目标库 migration 报错 |

已有目标数据库能力或修复语义属于增量强证据。证据冲突时按增量适配处理，以保护已有迁移历史；证据仍不足时只询问一个决定分支的问题。

## 范围控制与发现分级

- `dameng` 只检查和规划达梦相关内容。
- `oceanbase` 只检查和规划 OceanBase 相关内容。
- `all` 分别检查达梦与 OceanBase；一方通过不能代表另一方通过。
- 保留 MySQL fallback，除非用户明确要求移除。
- 没有证据表明所选范围需要时，不新增数据库专属依赖、配置或补丁。

每项发现标记为：

- **明确需要修改**：项目事实或已验证的不兼容直接支持修改。
- **高风险待验证**：存在可信风险，但需要目标库实连确认。
- **暂不修改**：没有证据支持改动。

## 一、项目基础配置

常见检查文件：

```text
config/default.py
settings.py
config/prod.py
config/dev.py
config/stag.py
requirements.txt
app_desc.yaml
app_desc_arm.yaml
app_desc_x86.yaml
```

适配内容：

- 在 `default` 通用配置中注册 `cw_cornerstone.migrate_patch`。
- 确认 `DEFAULT_AUTO_FIELD`，避免迁移补丁里主键类型漂移。
- 保留原 MySQL 配置作为 fallback。
- 按已选范围新增或确认 `DATABASE_TYPE` 分支：`dameng` 处理 `dmsql`，`oceanbase` 处理 `oceanbase`，`all` 才同时处理两者。
- 同步生产、测试或开发环境所需数据库环境变量。

## 二、依赖适配

达梦需要：

```text
django-dmPython
dmPython
```

达梦和 OceanBase 迁移补丁机制需要：

```text
cw-cornerstone
```

处理原则：

- 项目已有固定版本时优先沿用项目版本。
- 只在缺失时新增依赖，不主动降级。
- 更新依赖后检查是否需要同步构建镜像或包配置。

## 三、数据库配置适配

达梦：

- backend 使用 `cw_cornerstone.db.dameng.backend`。
- 默认端口通常是 `5236`。
- schema 需要显式配置，库名/模式名包含特殊字符时尤其要注意。
- 环境变量常见前缀：`DMSQL_NAME`、`DMSQL_USER`、`DMSQL_PASSWORD`、`DMSQL_HOST`、`DMSQL_PORT`。

OceanBase：

- backend 使用 `cw_cornerstone.db.oceanbase.backend`。
- 默认端口通常是 `2881`。
- `OPTIONS` 中保持 `charset: utf8mb4`。
- 环境变量常见前缀：`OCEANBASE_NAME`、`OCEANBASE_USER`、`OCEANBASE_PASSWORD`、`OCEANBASE_HOST`、`OCEANBASE_PORT`。

仅蓝鲸项目检查平台变量：

- 同时兼容 `BKAPP_DB_NAME`、`BKAPP_DB_USERNAME`、`BKAPP_DB_PASSWORD`、`BKAPP_DB_HOST`、`BKAPP_DB_PORT`。
- 如果项目仍兼容旧变量，保留 `DB_NAME`、`DB_USERNAME`、`DB_PASSWORD`、`DB_HOST`、`DB_PORT` fallback。

## 四、迁移文件适配

补丁目录：

```text
migrate_patch/patches/dameng/<app_label>/<migration>.py
migrate_patch/patches/oceanbase/<app_label>/<migration>.py
```

通用规则：

- 文件名与原 migration 完全一致。
- `dependencies` 与原 migration 保持一致。
- 只改目标数据库不支持的 operation。
- 第三方 app migration 不改包源码，只放补丁目录。

达梦小项：

- `CharField` 超长：改 `TextField` 或使用 `CloneField`。
- `RunSQL`：移除 MySQL 反引号。
- 关键字：处理 `desc`、`key` 等字段名或列名。
- 自增字段：确认 `AutoField`、`BigAutoField` 与项目默认一致。
- `bulk_create`/`bulk_update`：长文本数据迁移时加 fallback。
- `select_related + order_by`：如果在数据迁移中触发达梦 SQL 问题，去掉非必要 `select_related`。

OceanBase 小项：

- `AddField(ForeignKey)`：拆成普通字段添加再 `AlterField`。
- 外键/唯一约束/索引：必要时调整 operation 顺序。
- 字符集：涉及中文、emoji、长文本时确认 `utf8mb4`。
- 第三方 app：如 `django_celery_beat` 使用补丁替换。

## 五、SQL 与 ORM 适配

优先扫描：

```text
raw()
cursor()
execute()
extra()
RunSQL
RunPython
bulk_create()
bulk_update()
select_related().order_by()
```

达梦重点：

- 不使用 MySQL 反引号。
- 关键字加引号或改字段映射。
- 避免 MySQL 专属函数直接进入 SQL。

OceanBase 重点：

- 多数查询可按 MySQL 思路处理，但 DDL、外键和约束顺序要实测。
- 保留字符集和索引长度相关配置。

## 六、包配置适配

蓝鲸 5.x 或多架构包需要同步：

```text
app_desc.yaml
app_desc_arm.yaml
app_desc_x86.yaml
```

检查点：

- 数据库增强服务配置。
- 达梦/OceanBase 环境变量。
- x86 与 arm 文件保持一致。
- 如果只有一个 canonical YAML，只改 canonical 文件。
