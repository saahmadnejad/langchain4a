# Langchain4a

A [LangChain](https://python.langchain.com)-inspired library for building LLM-powered applications in [Ada](https://www.adaic.org/).

## Overview

Langchain4a brings the modular, composable architecture of LangChain to Ada, providing building blocks for working with large language models, chatbots, semantic chains, and memory stores. It is designed to mirror the familiar LangChain Python/JVM ecosystems while remaining idiomatic Ada.

The library is currently in **early alpha (v0.1.0)** -- most functionality is stubbed out. The roadmap includes real HTTP-based provider integrations, conversational memory, and concrete chain implementations.

## Architecture

```
langchain4a/
├── src/
│   ├── langchain4a.ad[bs]              # Top-level package: Initialize / Finalize
│   ├── core/
│   │   ├── langchain4a-core.ads         # Base types: Prompt, LLM_Response, LLM_Model (abstract)
│   │   └── langchain4a-core-config.ad[bs]  # Config loading (INI file + env vars)
│   ├── llm/
│   │   └── langchain4a-llm.ad[bs]       # Provider clients: OpenAI_Client (base), OpenRouter_Client
│   ├── memory/
│   │   └── langchain4a-memory.ad[bs]    # Memory_Store for conversation context
│   ├── chains/
│   │   └── langchain4a-chains.ads       # Chain (abstract) for orchestrating LLM ops
│   └── net/
│       ├── langchain4a-net.ad[bs]        # HTTP client with SOCKS5 proxy + TLS
│       └── langchain4a-net-json.ad[bs]  # JSON extraction utilities
├── config.ini.template                  # Example configuration file
├── langchain4a.gpr                      # GNAT project file
└── alire.toml                           # Alire package manifest
```

### Package hierarchy

```
Langchain4a
├── Langchain4a.Core
│   └── Langchain4a.Core.Config
├── Langchain4a.LLM
│   ├── LLM_Model          (abstract base, from Core)
│   ├── OpenAI_Client      (base OpenAI-compatible client)
│   └── OpenRouter_Client   (OpenRouter provider)
├── Langchain4a.Net
│   ├── Langchain4a.Net           (types: Proxy_Settings, HTTP_Response)
│   └── Langchain4a.Net.JSON      (JSON extraction utilities)
├── Langchain4a.Memory
└── Langchain4a.Chains
```

## Requirements

- Ada 2022 compiler (tested with FSF GNAT 14.2.0; project pins `-gnat2022`)
- Alire (recommended for dependency management)
- An [OpenRouter](https://openrouter.ai) API key for LLM requests

## Installation

### Using Alire

```bash
alr get langchain4a       # once published to the Alire community index
alr build
```

For local development:

```bash
alr build
```

### Manual build

```bash
gnatmake -P langchain4a.gpr
# or
gprbuild -P langchain4a.gpr
```

This builds a static library `liblangchain4a.a` in `lib/`.

## Configuration

### Option 1: Environment variables (recommended)

```bash
export OPENROUTER_API_KEY="sk-or-v1-..."
export OPENROUTER_ENDPOINT="https://openrouter.ai/api/v1"
export OPENROUTER_MODEL="openai/gpt-3.5-turbo"
export OPENROUTER_TEMPERATURE="0.7"
export OPENROUTER_MAX_TOKENS="1024"
```

### Option 2: INI file

```bash
cp config.ini.template config.ini
# edit config.ini
```

### SOCKS5 proxy

For environments where direct HTTPS access is restricted, configure a SOCKS5 proxy:

```bash
export PROXY_MODE=socks5
export PROXY_HOST=127.0.0.1
export PROXY_PORT=1080
```

Or in `config.ini`:

```ini
PROXY_MODE=socks5
PROXY_HOST=127.0.0.1
PROXY_PORT=1080
```

## Usage

```ada
with Langchain4a;
with Langchain4a.LLM;
with Langchain4a.Core.Config;

procedure Hello is
   Config : Langchain4a.Core.Config.Configuration;
   Client : Langchain4a.LLM.OpenRouter_Client;
begin
   Langchain4a.Initialize;

   Langchain4a.Core.Config.Load_From_Env(Config);
   Client.Configure(Config.OpenRouter_Cfg);
   Client.Send_Prompt("Hello from Ada!");
   declare
      Resp : constant Langchain4a.Core.LLM_Response := Client.Get_Response;
   begin
      Put_Line(To_String(Resp.Text));
   end;

   Langchain4a.Finalize;
end Hello;
```

## Using in Another Project

### With Alire (local path)

Add this to your `alire.toml`:

```toml
[[depends-on]]
langchain4a = { path = "../langchain4a" }
```

Then build:

```bash
alr build
```

### With Alire (published)

```bash
alr with langchain4a
alr build
```

### Manual GNAT project

Add this to your `.gpr` file:

```ada
with "langchain4a";
```

Then compile with the library's source directories in your include path:

```bash
gnatmake -P my_project.gpr \
  -Isrc -Isrc/core -Isrc/llm -Isrc/net \
  liblangchain4a.a
```

### Key source files

| File | Description |
|------|-------------|
| `src/langchain4a.ads` / `.adb` | Root package: `Initialize`, `Finalize`, `Version` |
| `src/core/langchain4a-core.ads` | Base types: `Prompt`, `LLM_Response`, `LLM_Model` (abstract) |
| `src/core/langchain4a-core-config.ad[bs]` | Config loading (INI + env vars, proxy settings) |
| `src/llm/langchain4a-llm-openai.ad[bs]` | `OpenAI_Client` — base OpenAI-compatible client |
| `src/llm/langchain4a-llm-openrouter.ad[bs]` | `OpenRouter_Client` — OpenRouter provider |
| `src/net/langchain4a-net.ad[bs]` | HTTP types + `Perform_Request` with SOCKS5/TLS |
| `src/net/langchain4a-net-json.ad[bs]` | `Extract_Json_String`, `Extract_Json_Integer` |

## Current Status

| Component          | Status       | Notes                                    |
|-------------------|--------------|------------------------------------------|
| Core types         | Implemented  | Prompt, LLM_Response, LLM_Model abstract |
| Config loading     | Implemented  | File + env var support                   |
| HTTP client        | Implemented  | `Langchain4a.Net` with SOCKS5 + TLS      |
| JSON utilities     | Implemented  | `Langchain4a.Net.JSON` extraction        |
| OpenRouter client  | Implemented  | Full HTTP API via `Langchain4a.Net`      |
| OpenAI client      | Implemented  | Base OpenAI-compatible client            |
| Memory store       | Stubbed      | No-op Store/Retrieve                     |
| Chains             | Stubbed      | Abstract base only                       |

## Development

### Building and testing

```bash
alr build              # Build the library
./tests/run_tests.sh   # Build and run all 47 tests
# Or manually:
alr exec -- gnatmake -P tests/tests.gpr
alr exec -- ./tests/bin/test_main
```

The test suite uses [AUnit](https://github.com/adacore/aunit) and is located in `tests/`.
All 47 tests follow the **Arrange-Act-Assert (AAA)** pattern with
**Given_When_Then** naming convention. See [AGENTS.md](AGENTS.md) for contributor workflow guidance.

### License

MIT -- see `alire.toml`.

## Contributing

### Commit messages

This project follows [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).
Commit messages should be formatted as:

```
<type>[optional scope]: <description>

[optional body]
```

| Type         | Use                                           |
|--------------|-----------------------------------------------|
| `feat`       | New feature                                   |
| `fix`        | Bug fix                                       |
| `refactor`   | Code restructuring (no behavior change)       |
| `ci`         | CI/build pipeline changes                     |
| `chore`      | Maintenance (deps, config, tooling)           |
| `docs`       | Documentation only                            |

See [AGENTS.md](AGENTS.md) for contributor workflow guidance.
