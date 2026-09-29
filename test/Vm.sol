// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// Subset of Foundry cheatcodes, so the tests run without forge-std.
interface Vm {
    function prank(address) external;
    function deal(address, uint256) external;
    function warp(uint256) external;
    function expectRevert(bytes4) external;
    function expectRevert(bytes calldata) external;
}

Vm constant vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
