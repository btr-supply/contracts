# TODO - Implementation Plan

## Testing and Documentation ([PENDING])
   1. Add unit and integration tests for the new single-sided deposit and withdrawal functionality.
   2. Add tests for the ratio-based fee adjustment mechanism.
   3. Update documentation to explain single-sided flows (done for user.md, but additional documentation may be needed).
   4. Document the ratio-based fee mechanism in user.md and protected.md.
   5. **ADD**: Test standalone DEX adapter integration and view function static calls.

## Code Style and Documentation ([MODERATE])
   1. Ensure all function, event and error parameters start with underscore "_" across ./evm/src codebase and ./evm/interfaces.
   2. Ensure all files are documented with concise NatSpec.
   3. Ensure inline comments are only at the end of lines and only for complex code.
