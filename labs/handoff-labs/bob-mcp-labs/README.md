# Example MCP Servers with IBM Bob

Production-ready Model Context Protocol (MCP) server implementations demonstrating progressive complexity levels and real-world integration patterns.

## Prerequisites

Before you begin, ensure you have the following installed:

### Required
- **Python 3.8 or higher** - [Download Python](https://www.python.org/downloads/)
  - Check your version: `python --version` or `python3 --version`
  - On macOS/Linux, you may need to use `python3` instead of `python`
- **uv** (Fast Python package installer) - [Installation Guide](https://docs.astral.sh/uv/getting-started/installation/)
  - Check if installed: `uv --version`
  - uv is 10-100x faster than pip and provides better dependency resolution

### Optional (for specific examples)
- **FastAPI** - Required for Lab 05 (API to MCP)
  - Installed via `uv pip install -r requirements.txt` in the lab directory
  - Used for the example financial services API

## Overview

Five examples showcasing MCP server development with [FastMCP](https://github.com/jlowin/fastmcp):

| Example | Level | Focus | Transport | Deployment |
|---------|-------|-------|-----------|------------|
| [01-simple-calculator](./01-simple-calculator/) | Beginner | Single-file implementation, core concepts | stdio | Local |
| [02-structured-calculator](./02-structured-calculator/) | Intermediate | Package architecture, production patterns | stdio | Local |
| [03-file-operations](./03-file-operations/) | Intermediate | File system operations, security controls | stdio | Local |
| [04-database-operations](./04-database-operations/) | Intermediate | SQLite CRUD operations, schema management | stdio | Local |
| [05-api-to-mcp](./05-api-to-mcp/) | Advanced | API wrapping and native MCP conversion patterns | stdio | Local |


## Repository Structure

```
bob-mcp-labs/
├── 01-simple-calculator/      # Minimal single-file server
├── 02-structured-calculator/  # Modular package structure
├── 03-file-operations/        # File system operations
├── 04-database-operations/    # SQLite database management
└── 05-api-to-mcp/             # API wrapping and native MCP conversion
```

### Configuration Tips

- **Local vs Global**: Use `.bob/mcp.json` for project-specific servers, or configure globally in Bob's settings
- **Virtual Environments**: The `command` should point to the Python executable inside each lab's virtual environment
- **Windows Users**: Use Windows path format (e.g., `C:\\path\\to\\venv\\Scripts\\python.exe`)
- **Lab 05**: Uses `uv` for dependency management and demonstrates both wrapper and native MCP patterns

## Key Features

- **Progressive Complexity**: Start simple, scale to production
- **Best Practices**: Type hints, error handling, logging
- **Clear Documentation**: Focused on implementation details

## Requirements

- Python 3.8+
- uv

## Resources

- [MCP Specification](https://modelcontextprotocol.io)
- [FastMCP Documentation](https://github.com/jlowin/fastmcp)

## License

MIT
