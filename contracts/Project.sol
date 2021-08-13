// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

// import "@openzeppelin/contracts/access/Ownable.sol"; TODO to make use of this.

contract Project {
  // Storage
  uint constant public projectDuration = 30 days;
  uint constant public contributionLowerBound = 0.01 ether;
  uint constant public goalMinimum = 1 ether;

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
    require(msg.sender != address(0), "Not valid address");
    require(_goal >= goalMinimum, "goal did not reach minimum");
    owner = _owner;
    goal = _goal;
    deadline = block.timestamp + projectDuration;
    state = ProjectState.ongoing;

  }


  // events
  event CanceledProject(address projectAddress, address projectOwner);
  event Withdraw(address withdrawer, uint amount);
  event Contributed(address contributor, uint amount, uint mapValue, uint availableFunds);
  
  
  // evaluates the current state and check against the expected state
  function evaluateState() internal {
    if(state == ProjectState.ongoing) {
      if(availableFunds >= goal) {
          state = ProjectState.successful;
        } else if(block.timestamp > deadline) {
          state = ProjectState.failed;
        }
    }
  }

  modifier onlyOwner() {
    require(msg.sender == owner, 'Not the Owner');
    _;
  }

  // functions
  function contribute() 
      external payable {
    // check if the amount is atleast 0.01ETH
    // add to mapping
    evaluateState();
    require(state == ProjectState.ongoing, 'Project has ended, cannot contribute');
    require(msg.sender != address(0), "Not valid address");
    require(msg.value >= contributionLowerBound, "Minimum contribution amount 0.01 ETH");
    contributions[msg.sender] += msg.value;
    availableFunds += msg.value;
    emit Contributed(msg.sender, msg.value, contributions[msg.sender], availableFunds);
  }

  
  function cancelProject() external onlyOwner {
    // change state to failed
    evaluateState();
    require(state == ProjectState.ongoing, 'Project has ended, cannot cancel');
    state = ProjectState.failed;
    emit CanceledProject(address(this), owner);
    // return true; does return cost gas??
  }

  // validate endTime has passed and goal has been reached
  function ownerWithdraw(uint percentAmount) external onlyOwner returns (bool){
    // check if the amount is available and let owner withdraw.
    evaluateState();
    require(state == ProjectState.successful, 'Project is not successful');
    require(percentAmount <=100);
    uint amount = availableFunds * percentAmount / 100;
    availableFunds -= amount;
    (bool success, ) = msg.sender.call{value:amount}("");
    if(success) {
      emit Withdraw(msg.sender, amount);
    }
    require(success, 'fund transfer failed');
    return success;
  }
  
  function contributerWithdraw() external returns (bool){
    // let the caller withdraw the full amount
    evaluateState();
    require(state == ProjectState.failed, 'Project has not failed');
    require(contributions[msg.sender] > contributionLowerBound, 'Contributer has no funds');
    uint amount = contributions[msg.sender];
    availableFunds -=amount;
    contributions[msg.sender]=0;
    (bool success, ) = msg.sender.call{value:amount}("");
    if(success) {
      emit Withdraw(msg.sender, amount);
    }
    require(success, 'fund transfer failed');
    return success;
  }
}