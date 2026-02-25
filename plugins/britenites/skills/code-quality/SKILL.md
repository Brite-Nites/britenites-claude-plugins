---
name: code-quality
description: ESLint, Prettier, Ruff, mypy, and TypeScript strict mode configuration patterns. Use when setting up linting, formatting, or code quality tooling for a new project, reviewing existing configs, generating config files, or adding lint steps to CI. Triggers on tasks involving ESLint, Prettier, Ruff, mypy, Black, code style, linting, formatting, or code quality enforcement.
user-invocable: true
---

# Code Quality Enforcement

Canonical configuration patterns for JavaScript/TypeScript and Python code quality tooling. Auto-detect project type, generate config files, and integrate with CI.

## When to Use This Skill

- Setting up linting and formatting for a new project
- Reviewing or upgrading existing code quality configs
- Generating ESLint, Prettier, Ruff, or mypy configuration files
- Adding lint/format steps to GitHub Actions CI
- Diagnosing why a linter isn't catching issues (wrong config, missing rules)
- Migrating from legacy tooling (TSLint → ESLint, Black/flake8/isort → Ruff)

## Auto-Detection

Identify the project stack from these markers before generating configs:

| Marker file | Stack | Tools to configure |
|---|---|---|
| `package.json` | JavaScript/TypeScript | ESLint, Prettier |
| `tsconfig.json` | TypeScript (additional) | TypeScript strict mode, `tsc --noEmit` |
| `pyproject.toml` | Python | Ruff, mypy |
| `setup.py` or `setup.cfg` | Python (legacy) | Ruff, mypy |
| Both `package.json` + `pyproject.toml` | Full-stack | All of the above |

When auto-detecting, check for existing configs first (`.eslintrc*`, `eslint.config.*`, `.prettierrc*`, `[tool.ruff]` in pyproject.toml) — upgrade rather than overwrite.

---

## JavaScript/TypeScript Stack

### ESLint (Flat Config — v9+)

Use `eslint.config.mjs` (flat config). Legacy `.eslintrc.*` is deprecated as of ESLint v9.

```js
// eslint.config.mjs
import js from "@eslint/js";
import tseslint from "typescript-eslint";
import prettierConfig from "eslint-config-prettier";

export default tseslint.config(
  js.configs.recommended,
  tseslint.configs.strictTypeChecked,
  tseslint.configs.stylisticTypeChecked,
  {
    languageOptions: {
      parserOptions: {
        projectService: true,
        tsconfigRootDir: import.meta.dirname,
      },
    },
  },
  {
    rules: {
      "@typescript-eslint/no-unused-vars": [
        "error",
        { argsIgnorePattern: "^_", varsIgnorePattern: "^_" },
      ],
      "@typescript-eslint/consistent-type-imports": "error",
      "@typescript-eslint/no-import-type-side-effects": "error",
    },
  },
  prettierConfig,
  {
    ignores: ["node_modules/", "dist/", ".next/", "coverage/"],
  },
);
```

**For JS-only projects** (no TypeScript), drop `tseslint` and use:

```js
// eslint.config.mjs
import js from "@eslint/js";

export default [
  js.configs.recommended,
  {
    rules: {
      "no-unused-vars": ["error", { argsIgnorePattern: "^_" }],
    },
  },
  { ignores: ["node_modules/", "dist/"] },
];
```

**Next.js projects** — use `eslint-config-next` with `FlatCompat` (the Next.js config still uses legacy format internally):

```js
// eslint.config.mjs
import js from "@eslint/js";
import tseslint from "typescript-eslint";
import prettierConfig from "eslint-config-prettier";
import { FlatCompat } from "@eslint/eslintrc";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const compat = new FlatCompat({ baseDirectory: __dirname });

export default tseslint.config(
  js.configs.recommended,
  tseslint.configs.strictTypeChecked,
  ...compat.extends("next/core-web-vitals"),
  // ... rules, prettierConfig, ignores
);
```

Install: `npm install -D eslint @eslint/js typescript-eslint eslint-config-prettier prettier eslint-config-next @eslint/eslintrc`

### Prettier

```json
{
  "semi": true,
  "singleQuote": false,
  "tabWidth": 2,
  "trailingComma": "all",
  "printWidth": 100,
  "bracketSpacing": true,
  "arrowParens": "always"
}
```

`.prettierignore` (uses `.gitignore` syntax):

```gitignore
node_modules/
dist/
.next/
coverage/
pnpm-lock.yaml
```

To avoid ESLint/Prettier conflicts, install `eslint-config-prettier` and add it as the last config entry before `ignores` (see the ESLint template above where `prettierConfig` is already included).

### TypeScript Strict Mode

Key `tsconfig.json` strict settings — enable all of these:

```jsonc
{
  "compilerOptions": {
    "strict": true,                    // Enables all strict flags below
    "noUncheckedIndexedAccess": true,  // Array/object index returns T | undefined
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "forceConsistentCasingInFileNames": true,
    "exactOptionalPropertyTypes": true
  }
}
```

`strict: true` enables: `strictNullChecks`, `strictFunctionTypes`, `strictBindCallApply`, `strictPropertyInitialization`, `noImplicitAny`, `noImplicitThis`, `alwaysStrict`, `useUnknownInCatchVariables`.

---

## Python Stack

### Ruff (Linting + Formatting)

Ruff replaces flake8, isort, Black, pyupgrade, and more. Single tool for both linting and formatting.

```toml
# pyproject.toml
[tool.ruff]
target-version = "py312"
line-length = 120

[tool.ruff.lint]
select = [
  "E",    # pycodestyle errors
  "W",    # pycodestyle warnings
  "F",    # pyflakes
  "I",    # isort
  "B",    # flake8-bugbear
  "C4",   # flake8-comprehensions
  "UP",   # pyupgrade
  "SIM",  # flake8-simplify
  "TCH",  # flake8-type-checking
  "RUF",  # ruff-specific rules
]
ignore = [
  "E501",  # line length (handled by formatter)
]

[tool.ruff.lint.isort]
known-first-party = ["your_package"]  # REPLACE with your actual package name

[tool.ruff.format]
quote-style = "double"
indent-style = "space"
```

Commands: `ruff check --fix .` (lint), `ruff format .` (format).

**Migration from Black/flake8/isort**: Ruff is a drop-in replacement. Remove legacy configs (`.flake8`, `.isort.cfg`, `pyproject.toml [tool.black]`) and consolidate into `[tool.ruff]`.

### mypy (Strict Type Checking)

```toml
# pyproject.toml
[tool.mypy]
python_version = "3.12"
strict = true               # enables disallow_untyped_defs, no_implicit_optional, warn_return_any, etc.
warn_unused_ignores = true   # included in strict since mypy 1.0 — explicit here for clarity
```

For **incremental adoption** on existing codebases, start with per-module overrides:

```toml
[tool.mypy]
python_version = "3.12"
warn_return_any = true

[[tool.mypy.overrides]]
module = "your_package.core.*"
strict = true

[[tool.mypy.overrides]]
module = "your_package.legacy.*"
ignore_errors = true
```

### Black (Legacy)

> **Prefer Ruff** for new projects. Black is only needed for teams already using it. Ruff's formatter is Black-compatible.

```toml
# pyproject.toml (if still using Black)
[tool.black]
line-length = 120
target-version = ["py312"]
```

---

## CI Integration

### GitHub Actions — JS/TS

Pin actions to commit SHAs to prevent supply chain attacks. Add `permissions: contents: read` for least privilege.

```yaml
# .github/workflows/lint.yml
name: Lint
on: [push, pull_request]
permissions:
  contents: read
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v4.2.2
      - uses: actions/setup-node@49933ea5288caeca8642d1e84afbd3f7d6820020  # v4.4.0
        with:
          node-version-file: ".nvmrc"  # or node-version: "22"
          cache: "npm"
      - run: npm ci
      - run: npx --no-install eslint --max-warnings 0 .
      - run: npx --no-install prettier --check .
      - run: if [ -f tsconfig.json ]; then npx --no-install tsc --noEmit; fi
```

### GitHub Actions — Python

```yaml
# .github/workflows/lint.yml
name: Lint
on: [push, pull_request]
permissions:
  contents: read
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v4.2.2
      - uses: actions/setup-python@0b93645e9fea7318ecaed2b359559ac225c90a2f  # v5.3.0
        with:
          python-version: "3.12"
          cache: "pip"
      - run: pip install -r requirements-dev.txt  # ruff, mypy pinned
      - run: ruff check .
      - run: ruff format --check .
      - run: mypy --ignore-missing-imports .  # remove flag once type stubs are installed
```

### GitHub Actions — Full-Stack (Combined)

```yaml
name: Code Quality
on: [push, pull_request]
permissions:
  contents: read
jobs:
  lint-js:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v4.2.2
      - uses: actions/setup-node@49933ea5288caeca8642d1e84afbd3f7d6820020  # v4.4.0
        with:
          node-version-file: ".nvmrc"
          cache: "npm"
      - run: npm ci
      - run: npx --no-install eslint --max-warnings 0 .
      - run: npx --no-install prettier --check .
      - run: if [ -f tsconfig.json ]; then npx --no-install tsc --noEmit; fi

  lint-python:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v4.2.2
      - uses: actions/setup-python@0b93645e9fea7318ecaed2b359559ac225c90a2f  # v5.3.0
        with:
          python-version: "3.12"
          cache: "pip"
      - run: pip install -r requirements-dev.txt
      - run: ruff check .
      - run: ruff format --check .
      - run: mypy --ignore-missing-imports .
```

---

## Config Generation Workflow

When generating configs for a project, follow this order:

1. **Detect stack** — check marker files (see Auto-Detection table)
2. **Check existing configs** — don't overwrite; upgrade or merge
3. **Install dependencies** — add dev dependencies for the detected stack
4. **Generate config files** — use the templates above, customizing `known-first-party`, `ignores`, and project-specific rules
5. **Add CI workflow** — generate the appropriate GitHub Actions lint job
6. **Add npm/pyproject scripts** — e.g., `"lint": "eslint ."`, `"format": "prettier --write ."`
7. **Verify** — run the linters to confirm zero false positives on the existing codebase

### Package Installation Commands

**JS/TS** (npm):
```bash
npm install -D eslint @eslint/js typescript-eslint eslint-config-prettier prettier  # versions pinned in package.json
```

**Python** (pip/uv):
```bash
pip install ruff mypy  # pin in requirements-dev.txt: ruff==0.11.x mypy==1.15.x
```
