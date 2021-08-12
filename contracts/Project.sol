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
    require(msg.value >= 0.01 ether, "Minimum contribution amount 0.01 ETH");
    contributions[msg.sender] = contributions[msg.sender].add(msg.value);
    availableFunds = availableFunds.add(msg.value);
    emit Contributed(msg.sender, msg.value, contributions[msg.sender], availableFunds);
  }

  
  function cancelProject() external onlyOwner returns(bool){
    // change state to failed
    evaluateState();
    require(state == ProjectState.ongoing, 'Project has ended, cannot cancel');
    state = ProjectState.failed;
    emit CanceledProject(address(this), owner);
    return true;
  }

  // validate endTime has passed and goal has been reached
  function ownerWithdraw(uint percentAmount) external onlyOwner returns (bool){
    // check if the amount is available and let owner withdraw.
    evaluateState();
    require(state == ProjectState.successful, 'Project is not successful');
    require(percentAmount>=0 && percentAmount <=100);
    uint amount = availableFunds.mul(percentAmount).div(100);
    availableFunds =  availableFunds.sub(amount);
    (bool success, ) = msg.sender.call{value:amount}("");
    if(success) {
      emit Withdraw(msg.sender, amount);
    }
    return success;
  }
  
  function contributerWithdraw() external returns (bool){
    // let the caller withdraw the full amount
    evaluateState();
    require(state == ProjectState.failed, 'Project has not failed');
    require(contributions[msg.sender]>0, 'Contributer has no funds');
    uint amount = contributions[msg.sender];
    availableFunds = availableFunds.sub(amount);
    contributions[msg.sender]=0;
    (bool success, ) = msg.sender.call{value:amount}("");
    if(success) {
      emit Withdraw(msg.sender, amount);
    }
    return success;
  }
}