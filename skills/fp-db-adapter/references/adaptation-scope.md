# 信创适配分组检查矩阵

本文件用于全新或增量适配的只读审计。按下列十个分组和组内顺序逐项检查，一次完成全部扫描。路径仅为常见示例，应先按项目事实发现真实入口。

每项都使用 `SKILL.md` 定义的固定状态，并输出编号、证据、判断依据和处置结论。某分组不适用时也保留分组，逐项标记 `[不适用，跳过]`。适配范围为 `all` 时，达梦与 OceanBase 必须分别取证和判定。

## 1. 项目与适配模式识别

- **1.1 项目根目录和技术栈**：定位 Python、Django、settings 和环境配置加载入口，识别通用 Django、蓝鲸 SaaS、AutoOps 或其他实际类型。
- **1.2 Git 工作区**：记录与待扫描文件相关的未提交变更，后续不得覆盖用户已有修改。
- **1.3 适配类型**：根据数据库分支、补丁注册、补丁目录、backend/驱动和用户意图，判定全新或增量适配。
- **1.4 数据库范围**：根据用户目标、错误日志和现有缺口，判定 `dameng`、`oceanbase` 或 `all`。
- **1.5 验证条件**：确认达梦和 OceanBase 连接、凭据、测试环境及已有验证结果是否可用。

| 检查项 | 全新适配证据 | 增量适配证据 |
| --- | --- | --- |
| 数据库分支 | 所选目标数据库分支整体缺失 | 已存在达梦或 OceanBase 分支 |
| 补丁注册 | 没有迁移补丁机制 | 已注册 `cw_cornerstone.migrate_patch` 或等价机制 |
| 补丁目录 | 所选数据库补丁目录不存在 | 已有任一目标数据库补丁 |
| backend/驱动 | 所选数据库依赖整体缺失 | 已安装或声明目标 backend/驱动 |
| 用户意图 | 首次接入、新 SaaS、从未适配 | 补充、修复、升级、完善或审查 |
| migration 日志 | 尚未进行目标库迁移 | 已有适配后的目标库 migration 报错 |

已有目标数据库能力或修复语义是增量强证据。证据冲突时按增量处理；仍无法判断时标记 `[无法判断]`，只询问一个决定分支的关键问题。

## 2. Python 及系统依赖

- **2.1 Python 与 Django 版本**：从运行配置和锁定文件取证，检查目标 backend 的版本兼容范围。
- **2.2 `cw-cornerstone`**：检查声明版本、安装来源及项目现有版本约束；仅目录或声明存在不能证明运行时可用。
- **2.3 达梦依赖**：范围含达梦时，分别检查 `django-dmPython`、`dmPython` 和驱动所需系统库。
- **2.4 OceanBase 依赖**：范围含 OceanBase 时，检查项目选用的 OceanBase backend、MySQL 协议驱动及版本约束。
- **2.5 构建依赖**：检查 requirements、`pyproject.toml`、锁文件、镜像安装步骤和多架构系统包是否一致。

项目已有固定版本时优先沿用，不主动降级或改变依赖主版本。缺少运行或目标环境证据时标记 `[待验证]`。

## 3. 数据库驱动与后端适配

- **3.1 达梦驱动可用性**：范围含达梦时，检查驱动是否可导入、backend 是否存在并与 Django 版本匹配。
- **3.2 达梦 backend 注册**：检查实际执行路径是否使用 `cw_cornerstone.db.dameng.backend` 或项目已验证的等价实现。
- **3.3 OceanBase 驱动可用性**：范围含 OceanBase 时，检查协议驱动、backend 模块和版本兼容性。
- **3.4 OceanBase backend 注册**：检查实际执行路径是否使用 `cw_cornerstone.db.oceanbase.backend` 或项目已验证的等价实现。
- **3.5 backend 行为覆盖**：检查 introspection、schema editor、operations、features 和 compiler 等项目依赖能力是否由 backend 提供。

适配范围为 `all` 时，达梦与 OceanBase 分开输出；一方通过不得将另一方标记为已适配。

## 4. 数据库连接配置

- **4.1 数据库类型分支**：检查 `DATABASE_TYPE`、`DATABASES` 或等价路由是否覆盖所选范围，并保留 MySQL fallback。
- **4.2 达梦连接项**：检查 name、user、password、host、默认端口 `5236`、schema 和连接 options。
- **4.3 OceanBase 连接项**：检查 name、user、password、host、默认端口 `2881` 和 `OPTIONS.charset=utf8mb4`。
- **4.4 环境变量映射**：检查生产、测试和开发配置是否读取一致的目标库变量，并避免提交真实凭据。
- **4.5 平台变量兼容**：仅蓝鲸项目检查 `BKAPP_DB_*` 与项目保留的旧 `DB_*` fallback；普通 Django 项目标记不适用。
- **4.6 默认字段策略**：检查 `DEFAULT_AUTO_FIELD` 与目标库 migration 主键类型是否一致。

常见目标库变量为 `DMSQL_*` 和 `OCEANBASE_*`，但以项目约定为准。

## 5. Migration 兼容机制

- **5.1 补丁应用注册**：检查 `cw_cornerstone.migrate_patch` 或项目等价机制是否进入实际 `INSTALLED_APPS` 或启动路径。
- **5.2 达梦补丁路由**：范围含达梦时，检查 `migrate_patch/patches/dameng/<app_label>/<migration>.py` 或等价目录能被发现。
- **5.3 OceanBase 补丁路由**：范围含 OceanBase 时，检查 `migrate_patch/patches/oceanbase/<app_label>/<migration>.py` 或等价目录能被发现。
- **5.4 覆盖规则**：检查补丁文件名、app label、数据库类型和原 migration 的映射规则。
- **5.5 历史保护**：确认不会直接修改已执行原 migration；优先使用项目认可的补丁或后续 migration。

仅存在补丁目录不能证明补丁机制生效，应继续检查注册和实际加载路径。

## 6. 现有 Migration 文件

- **6.1 原 migration 清单**：扫描项目和相关第三方 app 的 migration，记录 `dependencies`、operations 和执行历史。
- **6.2 达梦字段与标识符**：检查超长 `CharField`、`AutoField`/`BigAutoField`、`desc`/`key` 等关键字和带反引号 SQL。
- **6.3 达梦数据迁移**：检查 `RunPython` 中的 `bulk_create`、`bulk_update`、长文本和 `select_related().order_by()` 风险。
- **6.4 OceanBase DDL 顺序**：检查 `AddField(ForeignKey)`、`AlterField`、外键、唯一约束和索引的 operation 顺序。
- **6.5 OceanBase 字符集与索引**：检查 `utf8mb4`、中文或 emoji、长文本和索引长度风险。
- **6.6 第三方 migration**：不得修改包源码；检查是否需要为 `django_celery_beat` 等建立目标库补丁。
- **6.7 补丁语义一致性**：补丁与原 migration 保持 `dependencies` 和业务语义，只调整目标库不支持的 operation。
- **6.8 数据与上线风险**：记录幂等、回滚、数据量、锁表和已执行 migration 风险。

涉及具体 migration 时，同时读取 `compatibility-checklist.md`。

## 7. ORM 查询与原生 SQL

- **7.1 原生 SQL 入口**：扫描 `raw()`、`cursor()`、`execute()`、`extra()` 和 SQL 文件。
- **7.2 Migration SQL**：扫描 `RunSQL` 和 `RunPython` 内拼接或执行的 SQL。
- **7.3 达梦 SQL 语法**：检查 MySQL 反引号、关键字、专属函数、分页和大小写或引号语义。
- **7.4 OceanBase SQL/DDL**：检查 MySQL 兼容模式之外的专属语法、DDL、约束和索引行为。
- **7.5 ORM 批处理**：检查 `bulk_create()`、`bulk_update()`、长文本和数据库不支持的返回行为。
- **7.6 ORM 组合查询**：检查复杂 `select_related()`、`order_by()`、聚合、锁和表达式在目标库的风险。

没有目标库实连证据时，兼容性风险应标记 `[待验证]`，不能仅因 ORM 能生成 SQL 就标记已适配。

## 8. 初始化、升级及运维脚本

- **8.1 初始化入口**：检查建库、建 schema、初始化数据和首次 migration 脚本。
- **8.2 升级入口**：检查发布前后 migration、数据修复、版本升级和回滚脚本。
- **8.3 运维命令**：检查管理命令、定时任务、备份恢复、巡检和健康检查中的数据库假设。
- **8.4 数据导入导出**：检查 SQL dump、CSV、编码、批量写入和主键或序列处理。
- **8.5 脚本幂等性**：检查重复执行、事务边界、失败恢复和大数据量影响。

项目不存在某类脚本时明确输出该项 `[不适用，跳过]`，不要静默省略整个分组。

## 9. 部署、镜像与环境配置

- **9.1 canonical 部署描述**：定位实际生效的 `app_desc.yaml`、Helm、Compose、Kubernetes 或平台配置。
- **9.2 多架构变体**：存在 `app_desc_arm.yaml`、`app_desc_x86.yaml` 或多架构镜像时，检查依赖和环境变量一致性。
- **9.3 镜像构建**：检查目标库驱动、系统库、wheel 来源和离线安装能力。
- **9.4 数据库增强服务**：仅实际使用蓝鲸或 AutoOps 平台能力时检查服务声明和绑定。
- **9.5 环境变量注入**：检查密钥来源、变量名称、默认值及生产或测试隔离。
- **9.6 发布顺序**：检查依赖安装、配置发布、migration 和应用启动的先后关系。

如果只有一个 canonical 配置，只修改该文件；不得凭空创建架构变体。

## 10. 测试和验证能力

- **10.1 静态与语法检查**：确认可执行 Python 编译、lint 或项目既有静态检查。
- **10.2 Django 检查**：确认可执行 `manage.py check` 及适用的数据库配置检查。
- **10.3 Migration 图与计划**：确认可检查 migration graph、冲突、`showmigrations` 和 `migrate --plan`。
- **10.4 达梦实连验证**：范围含达梦时，确认连接、建表或迁移和核心读写验证条件。
- **10.5 OceanBase 实连验证**：范围含 OceanBase 时，确认连接、建表或迁移和核心读写验证条件。
- **10.6 回归测试**：定位数据库相关单元、集成和核心业务读写测试。
- **10.7 不可执行项**：列出缺失凭据、网络、服务、数据或环境导致无法运行的验证。

静态检查、代码审查或 migration plan 不能代替目标数据库实连。适配范围为 `all` 时，10.4 和 10.5 分别输出结果。

## 范围与路由保护

- `dameng` 只检查和规划达梦专属项；OceanBase 专属项标记 `[不适用，跳过]`。
- `oceanbase` 只检查和规划 OceanBase 专属项；达梦专属项标记 `[不适用，跳过]`。
- `all` 分别检查达梦和 OceanBase；一方通过不能代表另一方通过。
- 保留 MySQL fallback，除非用户明确要求移除。
- 没有证据表明所选范围需要时，不新增数据库专属依赖、配置或补丁。
- 仅在代码或用户信息证明项目属于 AutoOps、蓝鲸 SaaS 或同类 `cw_cornerstone` 约定时，应用 `autoops-patterns.md`；普通 Django 项目不得套用固定版本、路径或平台变量。
- 不得自动扩展到人大金仓、瀚高、GaussDB 等未支持数据库。
