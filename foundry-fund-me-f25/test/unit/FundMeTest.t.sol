// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "src/FundMe.sol";
import {DeployFundMe} from "script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user"); // create a fake user for testing

    uint256 constant SEND_VALUE = 1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE); // give the fake user some ETH
    }

    function testMinimumUsdIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);

        console.log("Minimum USD is:", fundMe.MINIMUM_USD() / 1e18);
    }

    function testOwnerIsMsgSender() public view {
        assertEq(fundMe.getOwner(), msg.sender);

        console.log("Owner is:", fundMe.getOwner());
    }

    function testGetVersion() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);

        console.log("Version is:", version);
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert(); // the next line should revert
        fundMe.fund{value: 0}(); // send 0 value

        console.log("Fund failed when 0 value sent");
    }

    modifier funded() {
        vm.prank(USER); // the next tx will be sent by USER
        fundMe.fund{value: SEND_VALUE}(); // send 1 ETH
        _;
    }

    function testFundUpdatesFundedDataStructure() public funded {
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);

        console.log("Amount funded is:", amountFunded / SEND_VALUE, "ETH");
    }

    function testAddsFunderToArrayOfFunders() public funded {
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);

        console.log("Funder is:", funder);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();

        console.log("Only owner can withdraw");
    }

    function testWithdrawWithASingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance; // Owner has 1 ETH
        uint256 startingFundMeBalance = address(fundMe).balance; // FundMe has 2 ETH

        // Act
        vm.prank(fundMe.getOwner()); //
        fundMe.withdraw(); // Owner withdraws funds

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        ); // Owner should have 3 ETH now

        console.log("Withdraw with a single funder successful");
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (
            uint160 funder = startingFunderIndex;
            funder < numberOfFunders;
            funder++
        ) {
            hoax(address(funder), SEND_VALUE); // send value to the funder address
            fundMe.fund{value: SEND_VALUE}(); // 10 funders, each sending 1 ETH => 10 ETH
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance; 
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        // Assert

        uint256 endingOwnerBalance = fundMe.getOwner().balance; // Owner should have 10+ ETH now
        uint256 endingFundMeBalance = address(fundMe).balance; // FundMe should have 0 ETH now

        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );

        console.log("Withdraw from multiple funders successful");
    }

    function testWithdrawFromMultipleFunders() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (
            uint160 funder = startingFunderIndex;
            funder < numberOfFunders;
            funder++
        ) {
            hoax(address(funder), SEND_VALUE); // send value to the funder address
            fundMe.fund{value: SEND_VALUE}(); // 10 funders, each sending 1 ETH => 10 ETH
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance; 
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        // Assert

        uint256 endingOwnerBalance = fundMe.getOwner().balance; // Owner should have 10+ ETH now
        uint256 endingFundMeBalance = address(fundMe).balance; // FundMe should have 0 ETH now

        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );

        console.log("Withdraw from multiple funders successful");
    }
    
}