// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Project.sol";

contract ProjectFactory {
  Project[] public projects;

  event CreatedProject(address projectAddress, address owner,
                    uint goal);
 
  function createProject(uint _goal) external {
    Project project = new Project(msg.sender, _goal);
    projects.push(project);
    emit CreatedProject(address(project), msg.sender, _goal);
  }
  
  function getProject(uint _index) external view returns(address _owner, address _projectaddr, uint _goal, uint _deadline){
    Project project = projects[_index];
    _owner = project.owner();
    _projectaddr = address(project);
    _goal = project.goal();
    _deadline = project.deadline();
  }

  function getProjects() public view returns(Project[] memory) {
      return projects;
  }

}