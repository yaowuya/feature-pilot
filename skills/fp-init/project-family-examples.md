# Labelled Project-Family Examples

Read this file only when the small read-only detection pass finds a plausible project-family signal. Labelled examples are opt-in target-project drafts, never public defaults.

## Canway / CW

High-confidence signals may include:

- root/repository names such as `canway`, `cw`, `auto-ops`, or `aoc`;
- docs mentioning 嘉为, Canway, CW, AOC, 蓝鲸, or BlueKing;
- packages such as `@canway/*`, `@canway/cw-magic-vue`, `@canway/cw-user-selector`, `auto-ops-platform`, or `cw-auto-ops`;
- `manage.py` plus `ui/package.json` in a matching application;
- existing FeaturePilot settings that already name these conventions.

Use only small safe signals. Never scan secrets, env values, production data, or dependency trees. Low confidence means continue generic init silently. Positive detection permits only a question, never automatic adoption.

Ask:

```markdown
检测到当前项目可能是 Canway/CW 项目。是否采用 `examples/canway-cw/fp-docs/settings/` 作为可编辑的项目设置草稿？

1. 全部采用 — 创建缺失的 agent/frontend/backend/prototype-style 文件。
2. 选择文件 — 只采用指定文件。
3. 先看摘要 — 展示后端、前端、UI、UX、原型风格要点。
4. 跳过 — 继续普通 `/fp-init`。
```

On approval, copy only selected missing files. Ask separately before each overwrite and recommend skipping existing files. Record adoption in the final report, then continue optional settings/discovery.

| Requested area | Target settings file |
|---|---|
| 后端规范 | `settings/backend.md` |
| 前端规范 | `settings/frontend.md` |
| UI / UX 规范 | relevant sections of `settings/frontend.md` |
| 原型视觉风格 | `settings/prototype-style.md` |
