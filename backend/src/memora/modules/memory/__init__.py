"""Memory engine domain module.

Owns learner-concept memory state, scheduling decisions and due-selection
inputs. The engine under ``memora.modules.memory.engine`` is a pure library:
it performs no database access, reads no wall clock and draws no randomness,
so the same inputs and engine/policy versions always reproduce the same
decision (Task Table T11 acceptance gate).
"""
