# skills

Skills I use.

## Layout

```text
skills/
  alpha-humanizer/
    SKILL.md
    references/
  _template/
    SKILL.md
```

Each skill is just a folder. `SKILL.md` is required. Everything else is optional.

## Claude

Claude uses the folder form directly.

That means a skill is the directory containing `SKILL.md` plus any referenced files.

## Packaging

Packaging is optional. If you want a single-file export, use:

```bash
tools/package-skill.sh skills/alpha-humanizer
```

That creates a `.skill` bundle in `dist/`.
