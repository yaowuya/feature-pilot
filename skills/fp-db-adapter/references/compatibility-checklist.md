# 迁移报错定位清单

本清单用于“迁移报错定位”场景：用户提供错误日志后，从日志反推失败 migration 和失败 operation。没有日志时也可用于静态扫描，但结论必须标注为推断。

定位阶段只提出最小补丁方案，不创建或修改补丁；用户明确确认当前完整方案后才实施。

## 日志提取

优先从日志中提取：

```text
执行命令
DATABASE_TYPE
Applying <app_label>.<migration_name>
失败 SQL 或 operation
数据库错误码和错误消息
Python traceback 最后一段
```

常见判断：

- 日志出现 `Applying system_mgmt.0012_auto_...`，先打开 `system_mgmt/migrations/0012_auto_....py`。
- 日志出现 `ForeignKey`、`constraint`、`index`，优先看 `AddField`、`AlterField`、`AddIndex`。
- 日志出现字段长度、`varchar`、`CLOB`、`TEXT`，优先检查 `CharField` 到长文本字段的迁移及其 `CloneField` 实现。
- 日志出现语法错误、关键字、反引号，优先看 `RunSQL`、`db_column`、`db_table`。

## 建议搜索

```bash
rg -n "CreateModel|AddField|AlterField|RemoveField|RenameField|AddIndex|AlterUniqueTogether|RunSQL|RunPython|ForeignKey\\(|CharField\\(|TextField\\(|AutoField\\(|BigAutoField\\(" . -g "*/migrations/*.py" -g "migrate_patch/patches/**/*.py"
rg -n "`|\\bdesc\\b|\\bkey\\b|varchar|longtext|mediumtext|datetime\\(|json|JSONField|db_column|db_table" . -g "*/migrations/*.py" -g "migrate_patch/patches/**/*.py"
rg -n "DATABASE_TYPE|DATABASES|ENGINE|cw_cornerstone|dmPython|django-dmPython|app_desc" .
```

如果日志已经给出失败 app，先限定到失败 app：

```bash
rg -n "ForeignKey\\(|CharField\\(|RunSQL|RunPython" apps/<app_label>/migrations migrate_patch/patches
```

## 达梦重点

- 新增超长字段：当 operation 为首次 `CreateModel` 或 `AddField`、数据库中尚不存在该列，并且字段原计划使用 `CharField(max_length >= 2000)` 时，直接新增为 `TextField`。
- 存量字段转长文本：已有字段从 `CharField` 变更为 `TextField` 时，达梦替换 migration 中禁止使用 `migrations.AlterField(..., field=models.TextField(...))` 直接修改字段类型，必须使用 `cw_cornerstone.django.migrations.operations.fields.CloneField` 完成字段克隆和数据迁移。
- `CloneField` 语义：目标 `field` 使用 `models.TextField(...)`，并保留原字段的 `null`、`blank`、`default`、`verbose_name` 等业务语义；同时核对字段名、数据复制结果、索引、唯一约束、回滚和重复执行风险。
- 新建与存量边界：直接声明 `TextField` 的超长字段规则只适用于数据库中尚不存在该列的 `CreateModel` 或 `AddField`；已经存在的列从 `CharField` 转为 `TextField` 一律使用 `CloneField`。
- MySQL 反引号：`RunSQL` 中出现反引号时，改为达梦可执行 SQL。
- 关键字：`desc`、`key` 等名称需要显式处理，避免裸字段名进入 SQL。
- 表/模式名：schema 名包含中划线等特殊字符时，确认 settings 中 schema 配置与迁移生成 SQL 一致。
- `RunPython` 批量写入：长文本字段配合 `bulk_create`/`bulk_update` 可能失败，必要时改小批量或逐条保存。

## OceanBase 重点

- `AddField(ForeignKey)`：优先拆成普通字段添加 + `AlterField(ForeignKey)`。
- 约束创建顺序：外键、唯一约束、索引失败时，调整 operation 顺序，保留业务约束。
- 第三方 app migration：不要改包源码，使用 `migrate_patch/patches/oceanbase/<app>/`。
- 字符集：确认配置为 `utf8mb4`，避免中文或 emoji 数据在迁移后写入失败。

## 替换迁移原则

- 保留原 migration 的 `dependencies`。
- 保留业务字段名、verbose_name、null/blank/default、on_delete 等语义。
- 达梦中新建且 `max_length >= 2000` 的字段直接使用 `TextField`；已存在列的 `CharField` 到 `TextField` 类型转换必须使用 `CloneField`，不得退回 `AlterField`。方案和实施结果必须明确列出字段状态、阈值判断和对应 operation。
- 只改目标数据库不支持的字段类型、operation 顺序或 SQL 写法。
- 不为了通过迁移删除业务约束；如果确实需要移除 `db_constraint` 或索引，必须在输出中说明风险。
- 不重写无关 migration；一次报错只补一个或少数直接相关文件。

## 迁移历史与运行安全

- 先判断原 migration 是否可能已经执行，并在方案中给出证据。
- 不直接修改已执行的原始 migration；仅当项目认可的补丁机制明确要求替换时使用补丁，否则优先新增后续 migration。
- 评估 `RunPython` 的 `reverse_code`、幂等性、历史模型使用和重复执行结果。
- 评估 migration 的 `atomic` 行为、数据量、锁表范围和预计执行时间。
- 保留 `dependencies` 与业务语义。删除约束或改变迁移机制属于实质性方案漂移，必须停止并重新确认。

## 无日志时的处理

无日志时先输出需要用户补充的信息：

```text
目标数据库
执行命令
最后 80-150 行 traceback
包含 Applying app.migration 的片段
数据库错误码
```

用户暂时无法提供时，再做静态扫描，并把结果分为：

- 明确需要适配：已有项目模式或适配文档直接命中。
- 高风险待验证：可能在目标库失败，需要实连验证。
- 暂不修改：没有证据表明会失败。

## 分层验证

- **L1**：Python 语法、导入和 Django system check。
- **L2**：migration graph、`makemigrations --check` 和 `migrate --plan`。
- **L3**：全新适配时，对所选数据库执行空库全量迁移。
- **L4**：增量适配时，对所选数据库执行存量库增量迁移。
- **L5**：核心 CRUD、约束、中文/emoji、长文本、时间、JSON 和关键任务验证。
- **L6**：环境支持时执行失败恢复或回滚验证。

适配 `all` 时，达梦和 OceanBase 分别报告每个层级；无法执行的层级明确标记为未验证。

## 验证命令

静态验证：

```bash
python manage.py check
python manage.py makemigrations --check --dry-run
python manage.py migrate <app_label> --plan
```

目标库验证：

```bash
DATABASE_TYPE=dmsql python manage.py migrate <app_label>
DATABASE_TYPE=oceanbase python manage.py migrate <app_label>
```

没有目标库连接时，结论必须区分“静态通过”和“目标库未实连验证”。
