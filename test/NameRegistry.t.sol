// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {NameRegistry} from "../src/NameRegistry.sol";
import {vm} from "./Vm.sol";

contract NameRegistryTest {
    NameRegistry reg;
    address alice = address(0xA11CE);
    address bob = address(0xB0B);
    uint256 constant T0 = 1_700_000_000;

    function setUp() public {
        vm.warp(T0);
        reg = new NameRegistry(0.01 ether);
        vm.deal(alice, 1 ether);
        vm.deal(bob, 1 ether);
    }

    function test_RegisterResolveAndRefundExcess() public {
        vm.prank(alice);
        reg.register{value: 0.05 ether}("alice", 2);
        require(reg.resolve("alice") == alice, "resolves to owner");
        require(alice.balance == 1 ether - 0.02 ether, "excess refunded");
        vm.prank(alice);
        reg.setAddress("alice", address(0xCAFE));
        require(reg.resolve("alice") == address(0xCAFE), "custom address");
    }

    function test_NameValidation() public view {
        require(reg.valid("abc") && reg.valid("my-name-9"), "valid names");
        require(!reg.valid("ab") && !reg.valid("Abc") && !reg.valid("-abc") && !reg.valid("a_bc"), "invalid names");
    }

    function test_ExpiryGraceAndReRegistration() public {
        vm.prank(alice);
        reg.register{value: 0.01 ether}("vault", 1);
        vm.warp(T0 + 365 days + 1);
        require(reg.resolve("vault") == address(0), "expired names don't resolve");
        vm.prank(bob);
        vm.expectRevert(NameRegistry.Unavailable.selector);
        reg.register{value: 0.01 ether}("vault", 1);
        vm.warp(T0 + 365 days + 31 days);
        vm.prank(bob);
        reg.register{value: 0.01 ether}("vault", 1);
        require(reg.resolve("vault") == bob, "bob owns it after grace");
    }

    function test_RenewDuringGraceAndTransfer() public {
        vm.prank(alice);
        reg.register{value: 0.01 ether}("keep", 1);
        vm.warp(T0 + 365 days + 10 days);
        vm.prank(bob); // anyone can pay for renewal
        reg.renew{value: 0.01 ether}("keep", 1);
        require(reg.resolve("keep") == alice, "renewed");
        vm.prank(alice);
        reg.transfer("keep", bob);
        vm.prank(alice);
        vm.expectRevert(NameRegistry.NotOwner.selector);
        reg.setAddress("keep", alice);
    }

    function test_RevertWhen_Underpaid() public {
        vm.prank(alice);
        vm.expectRevert(NameRegistry.InsufficientPayment.selector);
        reg.register{value: 0.005 ether}("cheap", 1);
    }
}
