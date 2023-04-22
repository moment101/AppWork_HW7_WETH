// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/MyContract2.sol";

// 只有 user1 和 user2 才能 send
// Amount 應該小於這個合約的 balance
// 合約應該正確的轉錢給 user
// (optional) 應該 emit Send event

contract TestPracticeTest is Test {
    event Receive(address from, uint256 amount);
    event Send(address to, uint256 amount);

    TestPractice public testPractice;

    address alice;
    address bob;
    address alex;

    function setUp() public {
        alice = address(1);
        bob = address(2);
        alex = address(3);
        testPractice = new TestPractice(alice, bob);
        vm.deal(address(testPractice), 10 ether);
        assertEq(address(testPractice).balance, 10 ether);
    }

    function test_Only_user1_and_user2_send() public {
        console.log(address(testPractice).balance);

        vm.prank(alice);
        testPractice.sendEther(alex, 1 ether);

        vm.prank(bob);
        testPractice.sendEther(alex, 1 ether);

        vm.expectEmit(true, false, false, true);
        emit Send(bob, 1 ether);
        vm.prank(bob);
        testPractice.sendEther(bob, 1 ether);
    }

    function testFail_balanceNotEnough() external {
        vm.prank(alice);
        testPractice.sendEther(alex, 1000 ether);
    }

    function test_receiveEther() external {
        uint alexBalanceBefore = address(alex).balance;

        vm.prank(alice);
        testPractice.sendEther(alex, 2 ether);

        uint alexBalanceAfter = address(alex).balance;
        assertEq(alexBalanceBefore + 2 ether, alexBalanceAfter);
    }
}
