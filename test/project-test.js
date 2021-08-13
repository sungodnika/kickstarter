const { expect } = require("chai");
const { ethers } = require("hardhat");
const { BigNumber } = ethers;

describe("Project Tests", function () {

    let host;
    let guest1;
    let guest2;

    let goal;
    let val;
    let project; 
    let deployedProject;
    
    beforeEach(async function() {
        [host, guest1, guest2] = await ethers.getSigners();
        goal = ethers.utils.parseEther("1.1");
        project = await ethers.getContractFactory("Project");

        deployedProject = await project.connect(host).deploy(host.getAddress(), goal);
        await deployedProject.deployed();

        val= ethers.utils.parseEther("0.02");
    });

    // Happy cases
    it("test whether a user is able to contribute", async function () {
        // check contribution from a single user.
        const contribute = await deployedProject.connect(guest1).contribute({ value: val });
        
        await expect(contribute)
        .to.emit(deployedProject, 'Contributed')
        .withArgs(guest1.address, BigNumber.from(val), BigNumber.from(val), BigNumber.from(val));
    }),
        // check contribution from a second user.

    it("test whether multiple users are able to contribute", async function () {
        let contribute = await deployedProject.connect(guest1).contribute({ value: val });
        contribute = await deployedProject.connect(guest2).contribute({ value: val });

        await expect(contribute)
        .to.emit(deployedProject, 'Contributed')
        .withArgs(guest2.address, BigNumber.from(val), BigNumber.from(val), BigNumber.from(val).mul(2));
    }),
    it("test whether multiple users including owner are able to contribute", async function () {
        let contribute = await deployedProject.connect(guest1).contribute({ value: val });

        // owner of the project contributes
        contribute = await deployedProject.connect(host).contribute({ value: val });
        
        await expect(contribute)
        .to.emit(deployedProject, 'Contributed')
        .withArgs(host.address, BigNumber.from(val), BigNumber.from(val), BigNumber.from(val).mul(2));


    }),

    it("test project success", async function () {
        const newVal = BigNumber.from(val).add(goal);
        let contribute = await deployedProject.connect(guest1).contribute({ value: newVal});

        // check whether contribution went through
        await expect(contribute)
        .to.emit(deployedProject, 'Contributed')
        .withArgs(guest1.address, BigNumber.from(newVal), BigNumber.from(newVal), BigNumber.from(newVal));

        // can contribute after project success
        await expect(deployedProject.connect(guest1).contribute({ value: val})).to.be.revertedWith('Project has ended, cannot contribute');

        let withdraw = await deployedProject.connect(host).ownerWithdraw(100);
        // console.log(withdraw);

        await expect(withdraw).to.emit(deployedProject, 'Withdraw').withArgs(host.address, BigNumber.from(newVal));
    });

    it("test project failure", async function () {

        let contribute = await deployedProject.connect(guest1).contribute({ value: val});

        // check whether contribution went through
        await expect(contribute)
        .to.emit(deployedProject, 'Contributed')
        .withArgs(guest1.address, BigNumber.from(val), BigNumber.from(val), BigNumber.from(val));

        contribute = await deployedProject.connect(host).cancelProject();

        await expect(contribute).to.emit(deployedProject, 'CanceledProject').withArgs(deployedProject.address, host.address);

        // can not contribute after project cancellation
        await expect(deployedProject.connect(guest1).contribute({ value: val})).to.be.revertedWith('Project has ended, cannot contribute');

        await expect(deployedProject.connect(host).contributerWithdraw()).to.be.revertedWith('Contributer has no funds');

        withdraw = deployedProject.connect(guest1).contributerWithdraw();

        await expect(withdraw).to.emit(deployedProject, 'Withdraw').withArgs(guest1.address, BigNumber.from(val));
    });


    // Testing failures



});