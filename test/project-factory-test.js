const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Project Factory Tests", function () {

    let host;
    let guest1;
    let guest2;

    let goal;
    let projectFactory; 
    let deployedProjectFactory;

    before(async function() {
        [host, guest1, guest2] = await ethers.getSigners();
        goal = ethers.utils.parseEther("1.1");
        projectFactory = await ethers.getContractFactory("ProjectFactory");

        deployedProjectFactory = await projectFactory.connect(host).deploy();
        await deployedProjectFactory.deployed();
    });


    it("test whether project gets created", async function () {
        // check contribution from a single user.
        let createProject = await deployedProjectFactory.connect(host).createProject(goal);

        let projects = await deployedProjectFactory.connect(host).getProjects();
        
        await expect(createProject)
        .to.emit(deployedProjectFactory, 'CreatedProject')
        .withArgs(projects[0], host.address, goal);


        createProject = await deployedProjectFactory.connect(guest1).createProject(goal);
        projects = await deployedProjectFactory.connect(host).getProjects();
        await expect(createProject)
        .to.emit(deployedProjectFactory, 'CreatedProject')
        .withArgs(projects[1], guest1.address, goal);
    });


});