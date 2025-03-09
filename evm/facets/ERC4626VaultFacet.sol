// Ensure vault is not already initialized
if (address(vs.asset) != address(0)) {
    revert Errors.AlreadyInitialized();
} 