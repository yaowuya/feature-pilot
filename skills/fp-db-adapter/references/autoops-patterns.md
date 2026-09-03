# AutoOps 信创适配模式

仅在项目可由代码或用户信息确认是 AutoOps、蓝鲸 SaaS，或明确采用本参考中的 `cw_cornerstone` 约定时读取本文。固定依赖版本、配置路径、`BKAPP_*` 变量和 YAML 规则都是项目模式，不得无条件应用到普通 Django 项目；若目标项目已有不同约定，优先沿用项目事实并在方案中说明差异。

本参考用于 AutoOps 或类似蓝鲸 Django 项目。重点是复用项目已有的 `cw_cornerstone` 迁移补丁机制，不要直接大规模改原始 migration。做全新或增量适配审计时先读 `adaptation-scope.md`，再用本文确认 AutoOps 的具体落点。

## 已知依赖

AutoOps 当前使用：

```text
django-dmPython==3.1.7
dmPython==2.5.5
cw-cornerstone==0.6.11
```

`cw-cornerstone==0.6.11` 是默认基线，不代表当前最新版。默认从 `https://bkrepo.cwoa.net/pypi/aiops/kingeye-pypi/simple` 查询 `cw-cornerstone` 的最新可用版本；若目标项目明确使用其他安装源，则以项目源为准并说明差异。方案记录软件源、查询时间、当前版本、最新版本和版本差异。查询应复用已有 pip 认证配置，严禁输出用户名、密码、Token 或含凭据 URL；遇到 `401` 或无法访问时标记 `[无法判断]`。早期适配文档提到 `0.6.9`，但不得回退；查到高于 `0.6.11` 的版本时，先评估 Python、Django、达梦、OceanBase 和迁移补丁兼容性，再把是否升级及验证方式写入方案。不得把默认基线写成最新版或猜测版本。

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

如果是迁移报错定位，方案只覆盖日志命中的 app 和 migration；如果是全新或增量适配审计，按 `compatibility-checklist.md` 扫描高风险 migration。只有用户确认当前完整方案后，才逐个创建或修改补丁。

## 打包配置

适配文档提到蓝鲸 5.x 需要在 YAML 中配置增强服务。AutoOps 使用架构拆分文件：

```text
app_desc_arm.yaml
app_desc_x86.yaml
```

如果项目有统一 `app_desc.yaml`，同步统一文件；如果只有架构文件，两个文件都要同步数据库服务和环境变量配置。
