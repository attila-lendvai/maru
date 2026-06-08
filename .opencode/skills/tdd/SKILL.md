---
name: tdd
description: Implement a change using test-driven development. Guides the specify-encode-fulfill workflow.
---

# Test-Driven Development

## Initial Specification

$ARGUMENTS

## The Specify-Encode-Fulfill Loop

I use something called "specify-encode-fulfill":

1. **Specify**: Come up with the specifications for what you want to build
2. **Encode**: Encode those specifications as automated tests (executable specifications)
3. **Fulfill**: Write the code to fulfill the specifications

At a finer grain:

1. Write a list of the specifications within scope of the current TDD session
2. Encode one item in the list as an automated test
3. Change the code *just barely enough* to *make the current test failure go away*. Avoid "speculative coding" - if we write more code than necessary to make the current test failure go away, we risk having code never exercised by any test
4. Optionally refactor, but not before committing the behavior change. Never mix behavior changes with refactoring
5. Until the list is empty, go back to #2

This follows Kent Beck's [Canon TDD](https://tidyfirst.substack.com/p/canon-tdd).

## Clarifying Specifications

Before writing tests, follow this loop:

1. Repeat my specifications back to me in your own words
2. Ask me to confirm your articulation is correct or explain how it's wrong
3. If confirmed, proceed to writing tests; otherwise use my response and go back to step 1

Specifications should take the form: "under scenario A, X happens; under scenario B, Y happens".

## Translating Specifications Into Tests

Each scenario should map to a test group. Tests should describe *what* happens in a scenario, not *that* it "works" or "handles" something.

Good test naming (Lisp style):
```lisp
(define-test evaluator/arithmetic/division/by-zero ()
  (test-assert (raises-error? (/ 1 0))))
```

Bad test naming:
```lisp
(define-test test-division-works ()
  (test-assert (= 5 (/ 10 2))))
```

What does "works" mean? The test should specify the exact expected behavior.

Good C-style test naming:
```c
void test_parser_handles_empty_input(void) {
    /* assert that parsing an empty string returns an empty AST */
}
```

Bad C-style test naming:
```c
void test_parser(void) {
    /* vague - what about the parser? */
}
```

## Workflow

1. I invoke /tdd with a draft specification
2. After back-and-forth, we agree on "final" specifications
3. See if we need to "clean the kitchen before we make dinner". Refer to the "Cleaning the Kitchen" section below.
4. You write just one test (per Canon TDD)
5. Show me the test and ask for approval before continuing
6. Write the application code, show it to me, and ask for approval before committing. Refer to the "Fulfilling Test Specifications" section below.
7. I provide a new specification and we start over from step 2

### Cleaning the Kitchen

Before you write a test, picture the test you're going to write and where you're going to put it. Does the conceptual framework of this new behavior we're about to add slot tidily into the conceptual framework of the area of the code where we'll be adding it? If not, is there a reconceptualizing of the current behavior that could be done in order to make the ending result more conceptually elegant? If such a reconceptualizing is called for, suggest it to the user. If the user approves, abandon the current change, get to a clean working state, and, on a new branch, perform a refactoring. "Clean the kitchen before you make dinner." Then pause and consult the user and we'll begin again.

### Fulfilling Test Specifications

When writing the application code to fulfill a certain specification, write ONLY ENOUGH CODE to make the current test failure go away. Never use "defensive coding". Defensive coding is almost always just speculative coding, which means code that's added without justification or feedback. Once you've written the test, invoke a separate subagent with the test-design-review skill to scrutinize your test code. Then invoke another subagent with the software-design-review skill to scrutinize your application code.

### Don't Be Sloppy

This kind of thinking is bad:

> That failure is pre-existing (unrelated to our change). Our new tests pass. Want me to commit?

We don't make dinner in a dirty kitchen. If we discover a pre-existing failure, the right move is to pause, stash our changes, fix the pre-existing failure, then resume.
