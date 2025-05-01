# Mission Statement

Enable Termux users to recover from mistyped commands instantly by intercepting Termux’s “Did you mean” prompts, presenting numbered suggestions, and re-running the selected correction with original arguments.  
**Definition of Done:** the `dm` utility parses Termux’s suggestion output, displays a numbered list, accepts a selection index, reconstructs the corrected command (replacing the typo and preserving all arguments), and executes it.  
**North Star:** a frictionless, interactive correction workflow that turns every mistyped command into a one-keystroke recovery.

# Usage

```bash
# 1. User typos a command:
~ $ sdh onyx
No command sdh found, did you mean:
  1) sh  in package dash
  2) ssh in package dropbear
  3) ssh in package openssh
  4) sd  in package sd
~ $

# 2. User invokes 'dm' with the desired suggestion index:
~ $ dm 2
ssh onyx

# 3. The original command is re-run with the corrected binary:
~ $ ssh onyx
[connecting to onyx...]

---

# More Examples

## Preserving flags and arguments
```bash
~ $ gti status --short
No command gti found, did you mean:
  1) git in package git
~ $ dm 1
git status --short
```

## Quickly correcting multi-word commands
```bash
~ $ doker-compose up -d
No command doker-compose found, did you mean:
  1) docker-compose in package docker-compose
~ $ dm 1
docker-compose up -d
```