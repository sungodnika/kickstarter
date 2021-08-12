// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

// import "@openzeppelin/contracts/access/Ownable.sol"; TODO to make use of this.
import '@openzeppelin/contracts/utils/math/SafeMath.sol';


contract Project {
  using SafeMath for uint;
  // Storage
  uint public projectDuration = 30 days;
  uint public contributionLowerBound = 0.01 ether;
  uint public goalMinimum = 1 ether;

  address public owner;
  uint public goal;
  uint public availableFunds;
  uint public deadline;

  mapping(address => uint) public contributions;

  enum ProjectState {
    ongoing,
    failed,
    successful
  }

  ProjectState state;

  //sets the owner to sender
  constructor(address _owner, uint _goal) {
    // set deadline and update owner and goal
    owner = _owner;
    goal = _goal;
    deadline = block.timestamp + projectDuration;
    availableFunds = 0;
    state = ProjectState.ongoing;

  }


  // events
  event CanceledProject(address projectAddress, address projectOwner);
  event Withdraw(address withdrawer, uint amount);
  event Contributed(address contributor, uint amount, uint availableFunds);
  
  
  // evaluates the current state and check against the expected state
  modifier evaluateState(ProjectState expectedState) {
    if(state == ProjectState.failed || state == ProjectState.successful) {
      require(state == expectedState);
    } else {
      if(availableFunds >= goal) {
          state = ProjectState.successful;
        } else if(block.timestamp > deadline) {
          state = ProjectState.failed;
        }
      require(state == expectedState);
    }
    _;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  // functions
  function contribute() 
      external payable evaluateState(ProjectState.ongoing) {
    // check if the amount is atleast 0.01ETH
    // add to mapping
    require(msg.sender != address(0), "Not valid address");
    require(msg.value == 0.01 ether, "Minimum contribution amount 0.01 ETH");
    contributions[msg.sender] = contributions[msg.sender].add(msg.value);
    availableFunds = availableFunds.add(msg.value);
    emit Contributed(msg.sender, msg.value, availableFunds);
  }

  
  function cancelProject() external onlyOwner evaluateState(ProjectState.ongoing) returns(bool){
    // change state to failed
    state = ProjectState.failed;
    emit CanceledProject(address(this), owner);
    return true;
  }

  // validate endTime has passed and goal has been reached
  function ownerWithdraw(uint amount) external onlyOwner 
    evaluateState(ProjectState.successful) returns (bool){
    // check if the amount is available and let owner withdraw.
    require(availableFunds >= amount);
    availableFunds =  availableFunds.sub(amount);
    (bool success, ) = msg.sender.call{value:amount}("");
    emit Withdraw(msg.sender, amount);
    return success;
  }
  
  function contributerWithdraw() external evaluateState(ProjectState.failed) returns (bool){
    // let the caller withdraw the full amount
    require(contributions[msg.sender]>0);
    uint amount = contributions[msg.sender];
    availableFunds = availableFunds.sub(amount);
    contributions[msg.sender]=0;
    (bool success, ) = msg.sender.call{value:amount}("");
    emit Withdraw(msg.sender, amount);
    return success;
  }
}