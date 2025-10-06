// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {FundMe} from "../src/FundMe.sol";
import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFundMe is Script {
    function run() external returns (FundMe) {
        // Before startBroadcast -> not a real transaction
        HelperConfig helperConfig = new HelperConfig();
        address netUsdPriceFeed = helperConfig.activeNetworkConfig();

        // After startBroadcast -> a real transaction
        vm.startBroadcast();
        FundMe fundMe = new FundMe(netUsdPriceFeed);
        vm.stopBroadcast();
        return fundMe;
    }

    function printStorageData(address contractAddress) public view {
        for (uint256 i = 0; i < 10; i++) {
            bytes32 value = vm.load(contractAddress, bytes32(i));
            console.log("Value at location", i, ":");
            console.logBytes32(value);
        }
    }

    function printFirstArrayElement(address contractAddress) public view {
        bytes32 arrayStorageSlotLength = bytes32(uint256(2));
        bytes32 firstElementStorageSlot = keccak256(
            abi.encode(arrayStorageSlotLength)
        );
        bytes32 value = vm.load(contractAddress, firstElementStorageSlot);
        console.log("First element in array:");
        console.logBytes32(value);
    }
}
