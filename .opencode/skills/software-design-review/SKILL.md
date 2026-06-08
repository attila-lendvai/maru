---
name: software-design-review
description: Review application code for design quality using established software design principles.
---

# Software Design Review

When invoked, unless otherwise directed, follow these steps:

1. Unless otherwise specified, set your scope to the diff between the current branch and master/main.
2. Grab the first principle in this document, announce to the user that you're looking for violations of it, and look for violations.
3. For the worst 1-3 offenses of that principle, suggest fixes. DO NOT SKIP ANY PRINCIPLES!
4. Ask the user whether they would like to move onto other principles.
5. If not, suggest more fixes, and if so, restart from #1.

Always remember the following design principles:
- No Hacks, No Workarounds
- Don't Be Stupid, Lazy or Dishonest
- Don't Repeat Yourself (DRY)
- Dependency Inversion (all entities should only depend on entities equally or more abstract than themselves)
- No Epicycles
- No Broken Windows
- Modularity and Loose Coupling
- Cohesion

Whenever possible, favor a declarative style over an imperative style.

## No Hacks, No Workarounds

Bad — parsing a config file with string manipulation instead of using the proper parser:
```c
char *key = strtok(buffer, "=");
char *val = strtok(NULL, "\n");
```

Good — use the proper config parsing function:
```c
config_get(settings, "key");
```

## No Speculative Coding

Don't write application code which is not strictly needed in order to satisfy an existing test.

## Avoid Abbreviation

Bad: `usr`, `cnt`, `tmp`
Good: `user`, `count`, `temporary`

Exceptions are abbreviations that are already part of everyone's vocabulary, such as URL, CPU, etc.

## Be Strictly Consistent with Naming

Don't switch between "run" and "test_suite_run" or "snapshot_history" and "history" for the same concept.

Bad:
```c
TestSuiteRun *last_run = repository_test_suite_runs(repo)->first;
```

Is it a "run" or is it a "test suite run"?

Good:
```c
TestSuiteRun *last_test_suite_run = repository_test_suite_runs(repo)->first;
```

## Call Things What They Are

Bad:
```c
int retry = 0;
retry++;
if (retry < 3) ...
```

The number is not a "retry", it's a "retry_count".

Good:
```c
#define MAX_RETRIES 3
int retry_count = 0;
retry_count++;
if (retry_count < MAX_RETRIES) ...
```

## Dependency Inversion Principle

Concrete details should not leak into abstract layers. If a parameter is only relevant some of the time, it shouldn't be on the general function.

Bad — a generic function has deletion-specific logic:
```c
void list_action_submit(ListAction *action) {
    // Deletion-specific behavior in a generic function — DIP violation.
    if (action->has_item_id) {
        list_remove_item(action->item_id);
    }
    dispatch_event("list:updating");
}
```

The concrete deletion behavior should live in its own function, not in the abstract list action function.

## One Definition, One File

Each function or type should go in its own appropriately named file.

## Favor Pure Functions

Avoid writing functions which have side effects when a pure function would work.

## Name Functions for What They Return, Not What They Do

"What they do" is imperative. "What they return" is declarative.

Bad: `rendered_buffer()` (describes what it does)
Good: `buffer_with_cells()` (describes what it returns)

## No Magic Numbers

Bad:
```c
if (retry_count < 3) ...
```

Good:
```c
#define MAX_RETRIES 3
if (retry_count < MAX_RETRIES) ...
```

## No Premature Optimization

Don't assign a contrivantly-named temp var just to avoid calling a function multiple times.

Bad:
```c
int to_dispatch_count = count_dispatchable(cluster);
for (int i = 0; i < to_dispatch_count; i++) ...
```

Good:
```c
for (int i = 0; i < count_dispatchable(cluster); i++) ...
```

## Keep Functions Focused

Each function should do one thing. If a function has multiple responsibilities, split it.

## No Speculative Generalizations

Don't create abstractions for things that only have one use case "in case we need it later."
