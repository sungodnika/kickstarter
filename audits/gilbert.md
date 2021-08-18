https://github.com/sungodnika/kickstarter

The following is a micro audit of git commit 6fa40279c246a0c9079b2c65901a05ecce751cf3

## issue-1

**[Medium]** Goal minimum is not checked

Project.sol:10 specifies a goal minimum

    uint constant public goalMinimum = 1 ether;

But the assignment on line 32 does not check for this minimum.

## issue-2

**[Code quality]** Lack of return value

ProjectFactory.sol's `createProject` function does not return a value. Consider returning the address of the new contract so other contracts can more easily interact with this one.

## issue-3

**[Code quality]** evaluateState called in every function

ProjectFactory.sol's `evaluateState` function is called in every other function. Consider making it a modifier so no one misinterprets where it can be written within those functions.

## Nitpicks

- Constants should conventionally be cased as `FOO_BAR` instead of `fooBar`
