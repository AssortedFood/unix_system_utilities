# AI Instructions

## What This Repo Is

A personal collection of lightweight Bash utilities for developer workflows.

## Directory Pattern

```
unix_system_utilities/
├── .agent/           # AI instructions, plans
├── install.sh        # Interactive installer
├── lib/
│   └── common.sh     # Shared functions (colors, logging)
└── utilities/
    └── <name>/
        ├── main.sh           # Entry point (aliased)
        ├── deps.sh           # Optional: dependency install commands
        ├── completions.sh    # Optional: bash completions
        └── tests/            # BATS test suite
```

## When Working Here

1. Read `project_context.md` first - has current status
2. Follow patterns in existing utilities (summarise_project is a good reference)

## Before Push/PR

Update `project_context.md` with:
- What changed
- Current status of in-progress work
- Any new decisions

## Plans

Active plans live in `.agent/plans/`
