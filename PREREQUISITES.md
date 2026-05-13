# Workshop Prerequisites

## Universal (everyone)

- [Bob IDE](https://bob.ibm.com/docs/ide/getting-started/install-and-setup)
- [Git](https://git-scm.com/downloads)
- A terminal
- A modern web browser

## Morning Labs (everyone)

- Node (for bobshell)
- [BobShell](https://bob.ibm.com/docs/shell/getting-started/install-and-setup) (the `bob` CLI)
  - https://bob.ibm.com/docs/shell/getting-started/install-and-setup#using-the-command-palette
- [`uv`](https://docs.astral.sh/uv/getting-started/installation/) — single install, provides both `uv` and `uvx`

## App Team — Afternoon

- [Java 17](https://adoptium.net/temurin/releases/?version=17)
- [Maven](https://maven.apache.org/install.html)

## SRE Team — Afternoon

- [Java 17](https://adoptium.net/temurin/releases/?version=17)
- [Maven](https://maven.apache.org/install.html)

## Credentials (handed out by your instructor)

**Everyone:** Jira URL, Jira username, Jira API token

**SRE team:** Jenkins URL, Jenkins username + password, repo URL, GitHub PAT (if repo is private)

## Verify

```bash
git --version
bob --version
uv --version
java --version    # afternoon (both teams)
mvn --version     # afternoon (both teams)
```
