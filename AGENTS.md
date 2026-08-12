# AGENTS.md

High-signal workflow guide for OpenCode sessions on **Langchain4a**.
Every item is a fact an agent would likely miss without help.

## Project at a glance

- **Language:** Ada 2022 (tested with FSF GNAT 14.2.0; project pins `-gnat2022`). Root package identifier must be `Langchain4a` (PascalCase, case-insensitive).
- **Build system:** GNAT project `langchain4a.gpr`; package manager `alr`.
- **Output:** static library `lib/liblangchain4a.a` (Object_Dir `obj/`, Library_Dir `lib/`).
- **Stage:** early alpha (v0.1.0). `memory/` and `chains/` are stubs.
- **No CI / no `opencode.json` / no `.github`.** All verification is local: `alr build` + `./tests/run_tests.sh`.

## Build & test commands (in this order: build lib, then build+run tests)

```bash
alr build                          # build static lib (lib/liblangchain4a.a)
# or: gnatmake -P langchain4a.gpr

# quick single-file compile check (note exact -Isrc flags; gpr handles paths automatically)
gcc -c -gnat2022 -gnatwU -Isrc -Isrc/core -Isrc/llm -Isrc/memory -Isrc/chains \
    src/langchain4a.adb -o /dev/null

# build + run all 47 AUnit tests
./tests/run_tests.sh

# manual test build + run
alr exec -- gnatmake -P tests/tests.gpr
alr exec -- ./tests/bin/test_main        # tests.gpr Exec_Dir = ./bin
```

- Tests use AUnit, follow **AAA** + **Given_When_Then** naming, live in `tests/`.
- 47 tests across: `config_tests`, `openai_tests`, `openrouter_tests`, `net_json_tests`, `langchain4a_tests`.
- Suites are registered in `tests/test_suite.adb`; runner is `tests/test_main.adb`.
- `./tests/test_config.ini` is the fixture consumed by `config_tests`.
- Compiler switches are identical across projects: `-gnat2022 -g -gnatwU` (`tests.gpr` and `langchain4a.gpr` both enforce `-gnatwU` -> build fails on any warning).

## Secrets / local-only files (gitignored — never commit)

- `.env` — local env vars. **Currently present and contains a live OpenRouter key + a SOCKS5 proxy (`192.168.1.151:10808`).** `.env.example` is the template for new users.
- `config.ini`, `config.local` — local INI config; `config.ini.template` is the tracked template. `config.local` holds only the API key.
- `config/` dir (`config/langchain4a_config.ads/.gpr/.h`) — **Alire-generated; do not edit by hand.**
- Build artifacts: `obj/`, `lib/`, `*.ali`, `*.o`, `*.a`, `tests/obj/`, `tests/bin/`, `examples/obj/`.
  - Note: you will see stray `*.ali`/`*.o` in the repo root from prior ad-hoc builds; they are gitignored, but keep `git status` clean by building through the `.gpr`.

## Architecture wiring

- `Langchain4a.Core.LLM_Model` is the abstract tagged base (`Send_Prompt` abstract, `Get_Response` abstract) in `src/core/langchain4a-core.ads`.
- `Langchain4a.LLM.OpenAI.OpenAI_Client` derives from `LLM_Model` (`src/llm/langchain4a-llm-openai.ad[bs]`) — the base OpenAI-compatible client exposing `Configure`, `Toggle_Proxy`, `Send_Prompt`, `Get_Response`, `Build_Extra_Headers`, `Build_Request_Body`, `Store_Response`.
- `Langchain4a.LLM.OpenRouter.OpenRouter_Client` derives from `OpenAI_Client` and only overrides `Configure` + `Build_Extra_Headers` (injects `HTTP-Referer` + `X-Title`).
- HTTP lives in `src/net/`: `Proxy_Settings`, `HTTP_Response`, `Perform_Request` (SOCKS5 + TLS), and `Langchain4a.Net.JSON` (`Extract_Json_String`, `Extract_Json_Integer`).

## Source layout

```
src/
  langchain4a.ad[bs]            Initialize / Finalize / Version
  core/langchain4a-core.ads      LLM_Model (abstract), Prompt, LLM_Response
  core/langchain4a-core-config.ad[bs]  Configuration, Load_Config (INI), Load_From_Env (env)
  llm/langchain4a-llm.ads        LLM child package
  llm/langchain4a-llm-openai.ad[bs]     OpenAI_Client (base)
  llm/langchain4a-llm-openrouter.ad[bs] OpenRouter_Client (derives from OpenAI_Client)
  net/langchain4a-net.ad[bs]     Proxy_Settings, HTTP_Response, Perform_Request
  net/langchain4a-net-json.ad[bs]       Extract_Json_String, Extract_Json_Integer
  memory/langchain4a-memory.ad[bs]      Memory_Store (stub)
  chains/langchain4a-chains.ads          Chain (abstract)
examples/openrouter_hello.adb   end-to-end example (needs OPENROUTER_API_KEY).
```

## Run an example locally

`./run.sh` sources `.env` (if present) then `exec`s its arguments. To build then run the example:

```bash
alr exec -- gnatmake -P examples/openrouter_hello.gpr
./run.sh ./examples/openrouter_hello
```

## Conventions

- Indent 3 spaces; comments `--  ` (two spaces after `--`); prefer `and then`/`or else`.
- Naming: `Mixed_Case_With_Underscores`; files `langchain4a-*.ad[bs]`; subpackages map to subdirectories (`core/` -> `Langchain4a.Core`, etc.). Do not mix files across subdirs.
- Config loading: `Provider_Kind` is `(OpenRouter, OpenAI)`. New providers extend `Configuration` + `Load_Config`/`Load_From_Env`, reusing the shared `Set_Proxy_*` helpers in `langchain4a-core-config.adb` (SRP).

## Common tasks

### Add a new LLM provider
1. Add a variant to `Provider_Kind` in `src/core/langchain4a-core-config.ads`.
2. Add a config record field in `Configuration`.
3. Extend `Load_Config` / `Load_From_Env` in `src/core/langchain4a-core-config.adb` using the `Set_Proxy_*` helpers.
4. In `src/llm/`, create a client deriving from `OpenAI_Client` (OpenAI-compatible) and override `Build_Extra_Headers` for provider-specific headers. `Build_Request_Body` / `Store_Response` are public for testing/reuse.

### Add a chain type
Define in `src/chains/` deriving from `Langchain4a.Chains.Chain`; override `Run`.

### Add a test module
1. `tests/<module>_tests.ads`/`.adb`: fixture derived from `AUnit.Test_Fixtures.Test_Fixture`.
2. Procedures named `Given_<preconditions>_When_<action>_Then_<outcome>`; body uses `-- Arrange` / `-- Act` / `-- Assert`.
3. Export a `Suite` function built via `AUnit.Test_Caller`.
4. Register it in `tests/test_suite.adb` (add `with <Module>_Tests;` + `Add_Test`).

## Commits
Conventional Commits only: `feat|fix|refactor|ci|chore|docs` (+ optional scope). Format: `<type>[scope]: <description>`.
