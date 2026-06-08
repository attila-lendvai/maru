---
name: test-design-review
description: Review tests for design quality using test design guidelines.
---

# Test Design Review

When invoked, review the specified tests (or the diff if none specified) against the guidelines in this document.

Important: use a SEPARATE AGENT which does not share your context.

For each violation found, show the offending code and suggest a fix. Group by guideline.

## Core Principle

Tests are executable specifications. A specification answers: "In scenario X, what should happen?"

## Specification Format

Good: "When the user submits an empty form, display a validation error."
Good: "When the API returns 500, show a graceful error message."
Good: "When no records exist, display 'No results found'."

Bad: "It works correctly." (What does 'correctly' mean?)
Bad: "It handles errors." (Which errors? How?)
Bad: "It validates input." (What validation? What happens on failure?)

## Test Behavior, Not Implementation Details

Bad:
```c
void test_tick_marks_position_blue(void) {
    World world = world_new(10, 10);
    world_tick(&world);
    assert_equal(world_color_at(&world, 5, 0), 0x0000FF);
}
```

Good:
```c
void test_when_particle_touches_cell_it_turns_cells_color(void) {
    World world = world_new(10, 10);
    uint32_t particle_color = world_particle_color(&world);
    Position pos = world_particle_position(&world);
    world_tick(&world);
    assert_equal(world_color_at(&world, pos.x, pos.y), particle_color);
}
```

## When Capturing Scenarios, Describe the Essence

Bad: `define-test test-elf/1 ()`
Good: `define-test elf/segment-header/parsing/valid-header ()`

## Avoid Arbitrariness

Avoid using `.first` or `.last` to retrieve items in tests. Use explicit queries.

## Make Assertions About What's Essential, Not What's Incidental

Only assert what matters. Don't assert things that are:
- Implied by other assertions
- Implementation details rather than behavior
- Just noise that makes the test longer without adding meaning

Bad:
```lisp
(define-test some-test ()
  (test-assert (success? result))
  (test-assert (= 42 (value result))))
```

If the value check fails, you already know it wasn't successful. The `success?` check adds nothing.

Good:
```lisp
(define-test some-test ()
  (test-assert (= 42 (value result))))
```

## Don't Mix Levels of Abstraction

Keep setup, action, and assertion phases clearly separated. Don't mix test infrastructure details with the essential behavior being tested.

## Avoid Forward Reference

Define values before they are referenced.

Bad:
```lisp
(define-test test-foo ()
  (let ((x (make-thing y)))
    (let ((y 42))
      ...)))
```

Better to define `y` before `x`.

## Assert on Observable Outcomes, Not Method Calls

When testing whether something happened (or didn't happen), assert on the observable end result rather than on whether a specific method was called. Mock-based assertions test means (was this method called?) rather than ends (did the thing actually happen?).

Bad:
```lisp
;; Testing that a specific function was called
(test-assert (function-was-called? some-function))
```

Good:
```lisp
;; Testing the observable outcome
(test-assert (= expected-count (count-items result)))
```

Stub only what you must (external services), and let the real code run so you can assert on real outcomes.

## Use an Arrange, Act, Assert Format

Structure tests clearly with setup (arrange), action (act), and verification (assert) phases.

## No Speculative Coding

Don't add unnecessary waits, retries, or complexity to tests without justification. Scrutinize such choices.

## Miscellaneous

- Never use `instance_variable_set` or equivalent hacks. If it seems like the only option, that's a sign of poor design.
- Don't use `described_class` or equivalent indirection - use the actual name.
- Don't use hacks to test private methods. If you need to test it, make it public.
