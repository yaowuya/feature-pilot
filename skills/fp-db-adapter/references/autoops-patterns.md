# AutoOps 信创适配模式

仅在项目可由代码或用户信息确认是 AutoOps、蓝鲸 SaaS，或明确采用本参考中的 `cw_cornerstone` 约定时读取本文。固定依赖版本、配置路径、`BKAPP_*` 变量和 YAML 规则都是项目模式，不得无条件应用到普通 Django 项目；若目标项目已有不同约定，优先沿用项目事实并在方案中说明差异。

本参考用于 AutoOps 或类似蓝鲸 Django 项目。重点是复用项目已有的 `cw_cornerstone` 迁移补丁机制，不要直接大规模改原始 migration。做全新或增量适配审计时先读 `adaptation-scope.md`，再用本文确认 AutoOps 的具体落点。

## 已知依赖

AutoOps 当前使用：

```text
django-dmPython==3.1.7
dmPython==2.5.5
cw-cornerstone==0.7.2
```

`cw-cornerstone==0.7.2` 是默认版本，不代表当前最新版。审计和生成方案时不主动访问 pip 源或其他仓库查询新版本，也不要求用户提供仓库凭据。方案只需把版本作为确认项：说明项目当前版本及与默认版本的差异，并提示用户确认使用 `0.7.2` 或指定其他版本。未查询最新版不属于失败或 `[无法判断]`。版本确认前不得修改依赖；确认后评估所选版本与 Python、Django、达梦、OceanBase 和迁移补丁的兼容性，并按已确认方案实施和验证。

## 配置入口

项目通过 `settings.py` 加载 `config.<env>`。生产数据库选择位于 `config/prod.py`，通过 `DATABASE_TYPE` 分支控制。

典型分支如下：

```python
if DATABASE_TYPE == "oceanbase":
    DATABASES = {
        "default": {
            "ENGINE": "cw_cornerstone.db.oceanbase.backend",
            "NAME": os.getenv("BKAPP_DB_NAME", os.getenv("OCEANBASE_NAME", os.getenv("DB_NAME", ""))),
            "USER": os.getenv("BKAPP_DB_USERNAME", os.getenv("OCEANBASE_USER", os.getenv("DB_USERNAME", ""))),
            "PASSWORD": os.getenv("BKAPP_DB_PASSWORD", os.getenv("OCEANBASE_PASSWORD", os.getenv("DB_PASSWORD", ""))),
            "HOST": os.getenv("BKAPP_DB_HOST", os.getenv("OCEANBASE_HOST", os.getenv("DB_HOST", ""))),
            "PORT": os.getenv("BKAPP_DB_PORT", os.getenv("OCEANBASE_PORT", os.getenv("DB_PORT", 2881))),
            "OPTIONS": {"charset": "utf8mb4"},
        }
    }
elif DATABASE_TYPE == "dmsql":
    name = os.getenv("BKAPP_DB_NAME", os.getenv("DMSQL_NAME", os.getenv("DB_NAME", "")))
    DATABASES = {
        "default": {
            "ENGINE": "cw_cornerstone.db.dameng.backend",
            "NAME": name,
            "USER": os.getenv("BKAPP_DB_USERNAME", os.getenv("DMSQL_USER", os.getenv("DB_USERNAME", ""))),
            "PASSWORD": os.getenv("BKAPP_DB_PASSWORD", os.getenv("DMSQL_PASSWORD", os.getenv("DB_PASSWORD", ""))),
            "HOST": os.getenv("BKAPP_DB_HOST", os.getenv("DMSQL_HOST", os.getenv("DB_HOST", ""))),
            "PORT": os.getenv("BKAPP_DB_PORT", os.getenv("DMSQL_PORT", os.getenv("DB_PORT", 5236))),
            "OPTIONS": {"schema": f"`{name}`"},
        }
    }
```

默认 MySQL 分支应保留为 fallback，不要为了信创适配删除。

## 迁移补丁注册

`config/default.py` 中应将 `cw_cornerstone.migrate_patch` 插入到 `django.contrib.contenttypes` 之前：

```python
if "django.contrib.contenttypes" in INSTALLED_APPS:
    INSTALLED_APPS = list(INSTALLED_APPS)
    index = INSTALLED_APPS.index("django.contrib.contenttypes")
    INSTALLED_APPS.insert(index, "cw_cornerstone.migrate_patch")
INSTALLED_APPS = tuple(INSTALLED_APPS)
```

保持这个顺序，避免 Django 迁移发现阶段加载不到替换文件。

这个属于适配文档中的 `default` 文件适配内容，是迁移补丁能否生效的前置条件。

## 替换迁移目录

AutoOps 使用以下目录放数据库专属迁移：

```text
migrate_patch/patches/dameng/<app_label>/<migration>.py
migrate_patch/patches/oceanbase/<app_label>/<migration>.py
```

文件名必须与原始迁移完全一致，例如原始文件是：

```text
apps/system_mgmt/migrations/0012_auto_20240103_1111.py
```

则 OceanBase 替换文件应是：

```text
migrate_patch/patches/oceanbase/system_mgmt/0012_auto_20240103_1111.py
```

## 已观察到的补丁覆盖

达梦已有补丁 app：

```text
approval_mgmt, auto_plugin, baseline, component_framework,
django_celery_results, general_check, network_mgmt, notice_mgmt,
object_mgmt, patch_mgmt, plugin_mgmt, script_mgmt, source_apply,
system_mgmt, task_mgmt
```

OceanBase 已有补丁 app：

```text
approval_mgmt, django_celery_beat, source_apply, system_mgmt
```

新增补丁前先检查同 app 下是否已有相邻 migration，可直接复用其字段风格、`BigAutoField`/`AutoField` 选择、导入顺序和格式。

达梦 migration 的超长字段按字段是否已经存在分两类处理：

- 新增字段：`CreateModel` 或 `AddField` 创建数据库中尚不存在的列时，若原计划为 `CharField(max_length >= 2000)`，直接定义为 `TextField`。
- 存量字段：数据库中已经存在的字段从 `CharField` 变更为 `TextField` 时，不得使用 `migrations.AlterField` 直接改变类型，必须沿用项目的 `CloneField` operation。

存量字段转换示例：

```python
from django.db import migrations, models
from cw_cornerstone.django.migrations.operations.fields import CloneField


class Migration(migrations.Migration):
    operations = [
        CloneField(
            model_name="examplemodel",
            name="content",
            field=models.TextField(blank=True, null=True, verbose_name="内容"),
        ),
    ]
```

示例字段属性仅用于说明结构，实际补丁必须从原 migration 保留字段名、`null`、`blank`、`default`、`verbose_name` 等业务语义，并检查数据复制、索引、唯一约束、幂等和回滚风险。只有列尚不存在、operation 为 `CreateModel` 或 `AddField`，且原 `CharField.max_length >= 2000` 时，才按本规则直接使用 `TextField`。

如果是迁移报错定位，方案只覆盖日志命中的 app 和 migration；如果是全新或增量适配审计，按 `compatibility-checklist.md` 扫描高风险 migration。只有用户确认当前完整方案后，才逐个创建或修改补丁。

## 打包配置

适配文档提到蓝鲸 5.x 需要在 YAML 中配置增强服务。AutoOps 使用架构拆分文件：

```text
app_desc_arm.yaml
app_desc_x86.yaml
```

如果项目有统一 `app_desc.yaml`，同步统一文件；如果只有架构文件，两个文件都要同步数据库服务和环境变量配置。
