# Scoop Bucket for Fastskill

Install [fastskill](https://github.com/gofastskill/fastskill) via Scoop on Windows.

## Installation

### Option 1: Add Bucket (Recommended)

This method enables automatic updates via `scoop update`:

```powershell
scoop bucket add gofastskill https://github.com/gofastskill/scoop-bucket
scoop install fastskill
```

### Option 2: Direct Install (Single Line)

Install directly from the manifest URL without adding a bucket:

```powershell
scoop install https://raw.githubusercontent.com/gofastskill/scoop-bucket/main/bucket/fastskill.json
```

Note: This method does not track updates automatically.

## Usage

```powershell
fastskill --version
```

## Upgrading

```powershell
scoop update fastskill
```

## Uninstalling

```powershell
scoop uninstall fastskill
scoop bucket rm gofastskill
```

## Learn More

- [FastSkill GitHub](https://github.com/gofastskill)
- [FastSkill Documentation](https://docs.gofastskill.com/)
