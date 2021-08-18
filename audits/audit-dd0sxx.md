# Audit by dd0sxx (Theo Telonis)

## Summary 
Great work! I was not able to find any high severity issues, and only one medium severity one. 

I liked that you kept you logic very clean and readable.

As far as testing, I think it would be cleaner and provide more coverage if you implemented **unit tests** in addition to the integreation and functional tests that you wrote.


## Project.sol

### High Priority

### Medium Priority
    * Line 93 contains a tautology
        * `require(percentAmount>=0 && percentAmount <=100);`
        * `percentAmount` is of type uint and will always be greater than or equal to 0
        
### Low Priority
    * Line 33 does not check if the value of owner is 0 or address 0
        * https://github.com/crytic/slither/wiki/Detector-Documentation#missing-zero-address-validation
        * I would reccommend using the contract `Ownable.sol` from the **OpenZepplin* library instead of writing custom owner logic

    * Line 107 checks if balance is greater than 0 instead of if balance is greater than `contributionLowerBound`
        * turn `require(contributions[msg.sender]>0` to `require(contributions[msg.sender] > contributionLowerBound`

    * contributionLowerBound (line 12) should be constant
    * goalMinimum (line 13) should be constant
    * projectDuration (line 11) should be constant

    * Unnecessary use of SafeMath library
        * Because this contract is using a Solidity version `>=0.8.0`, the SafeMath library is unnecessary. Removing it will reduce your dependency on third-party code and possibly reduce gas fees on deployment.

### Code Quality and Gas Optimizations
    * Line 36 `availableFunds = 0;` is redundant because uints have a default value of 0

    * I think it is a waste of gas to call evaluate state at the beginning of each function call. I believe you can update these values as they occur in other functions, instead of after the fact and check for the neccessary conditions in require statements.

    * I do not think cancelProject (line 79) needs to return a bool

    * instead of doing the math to allow for a percentage withdrawl (line 94), you could instead allow the owner to specify the amount they want to withdraw, which would save gas. You could then check to make sure they can't withdraw more than the amount of ether in `availableFunds`

    * there is a trailing comma on line 96 and 111. You can also include here the second retrun value of the call function: `bytes memory data`
        * `(bool success, bytes memory data) = msg.sender.call{value:amount}("");`



## ProjectFactory.sol

### High Priority

### Medium Priority

### Low Priority
    * getProjects (line 26) should be declared external instead of public

### Code Quality and Gas Optimizations

## testing

    ### Code Quality
        * `.connect(host)` is redundant code. `contract.method()` will use the host wallet by default

        * There should be tests which check the ether balance of each wallet to ensure that funds are being distributed properly. Currently the tests only check to see if events are emitted.
            * this also applies to general state e.g. checking if state = success or failure, verifying that availableFunds is accurate, etc
