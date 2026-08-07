# AGENTS.md

Contributor and agent workflow guide for **Langchain4a**.

## Project at a glance

- **Language:** Ada 2012 (GNAT-style identifiers use `Langchain4a` as the root package name)
- **Package manager:** Alire
- **Build system:** GNAT Project file (`langchain4a.gpr`)
- **Library kind:** Static (`liblangchain4a.a`)
- **Stage:** Early alpha (v0.1.0) -- most implementations are stubs

## Quick start

```bash
# Build
alr build
# or manually:
# gnatmake -P langchain4a.gpr

# Compile individual sources (useful for quick iteration):
gcc -c -gnat2012 -gnatwU -Isrc -Isrc/core -Isrc/llm -Isrc/memory -Isrc/chains \
    src/core/langchain4a-core-config.adb -o /dev/null
```

## Conventions

### Naming

| Context            | Convention                      | Example                          |
|--------------------|---------------------------------|----------------------------------|
| Package name       | `Langchain4a` (Ada identifier) | `package Langchain4a is`         |
| Sub-packages       | `Langchain4a.Core`, etc.       | `package Langchain4a.LLM is`     |
| File names         | `langchain4a-*.ad[bs]`          | `langchain4a-llm.ads`            |
| GNAT project file  | `langchain4a.gpr`               | `project Langchain4a is`         |
| Config units       | `Langchain4a_Config`            | in `config/langchain4a_config.*` |

Ada is case-insensitive for identifiers, but **always use `Langchain4a` (PascalCase)** for the root and sub-package names to keep grep/search results predictable.

### File layout

```
src/                    # All Ada source files
  langchain4a.ads       # Root package spec
  langchain4a.adb       # Root package body (Initialize/Finalize)
  core/                 # Base types + configuration
    langchain4a-core.ads
    langchain4a-core-config.ads / .adb
  llm/                  # LLM provider clients
    langchain4a-llm.ads / .adb
  memory/               # Memory stores
    langchain4a-memory.ads / .adb
  chains/               # Chain orchestration
    langchain4a-chains.ads
  net/                  # HTTP client with SOCKS5 + TLS
    langchain4a-net.ads / .adb
config/                 # Alire-generated config (do not edit by hand)
```

Do **not** mix files across subdirectories. Each subdirectory maps to a sub-package.

### Compilation flags

Defined in `langchain4a.gpr`:

- `-gnat2012`  -- Ada 2012 standard
- `-g`         -- Debug symbols
- `-gnatwU`    -- Treat elaboration warnings as errors

### Coding style

- Indent with 3 spaces (`gnatmake` default).
- Boolean operators: prefer `and then` / `or else` for short-circuit evaluation.
- Ada comments use `--  ` (two spaces after dashes).
- Follow RM-style naming: `Mixed_Case_With_Underscores`.

## Common tasks

### Add a new LLM provider

1. Add a new variant to `Provider_Kind` in `src/core/langchain4a-core-config.ads`.
2. Add a corresponding config record in `Configuration`.
3. Extend `Load_Config` / `Load_From_Env` in `ada_llm-core-config.adb`.
4. Create a new client type in `src/llm/`, deriving from `OpenAI_Client` if OpenAI-compatible.

### Add a chain type

1. Define the chain type in `src/chains/`.
2. Derive from `Langchain4a.Chains.Chain` or the existing abstract.
3. Override `Run`.

### Run a quick compile check

```bash
gcc -c -gnat2012 -gnatwU -Isrc -Isrc/core -Isrc/llm -Isrc/memory -Isrc/chains \
    src/langchain4a.adb -o /tmp/langchain4a.o
```

Exit code 0 = all good.

## Known limitations / TODOs

- `Memory_Store` is a null record with no-op procedures.
- `Chain.Run` is abstract with no concrete implementations.
- No test framework is integrated yet.

## Commit conventions

This project follows [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).

Format:

```
<type>[optional scope]: <description>

[optional body]
```

Types:

| Type         | Use                                           |
|--------------|-----------------------------------------------|
| `feat`       | New feature                                   |
| `fix`        | Bug fix                                       |
| `refactor`   | Code restructuring (no behavior change)       |
| `ci`         | CI/build pipeline changes                     |
| `chore`      | Maintenance (deps, config, tooling)           |
| `docs`       | Documentation only                            |
