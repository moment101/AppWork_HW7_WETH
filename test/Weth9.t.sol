// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/Weth9.sol";

contract Weth9Test is Test {
    WETH9 public weth9;

    address alice = address(1);
    address bob = address(2);
    address alex = address(3);

    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);
    event Deposit(address indexed dst, uint wad);
    event Withdrawal(address indexed src, uint wad);

    function setUp() public {
        weth9 = new WETH9();
        vm.deal(address(alice), 100 ether);
        vm.deal(address(bob), 100 ether);
        vm.deal(address(alex), 100 ether);
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        vm.label(alex, "Alex");
    }

    // 測項 1: deposit 應該將與 msg.value 相等的 ERC20 token mint 給 user
    function test_Deposit(uint256 amount) external {
        vm.assume(amount <= 100 * 10 ** 18);
        vm.prank(alice);
        weth9.deposit{value: amount}();
        uint expectedBalance = weth9.balanceOf(alice);
        assertEq(expectedBalance, amount, "Invalid balance after deposit");
    }

    // 測項 2: deposit 應該將 msg.value 的 ether 轉入合約
    function test_Deposit_ContractShouldReceiveETH(uint256 amount) external {
        vm.assume(amount <= 100 * 10 ** 18);
        uint beforeBalance = address(weth9).balance;
        vm.prank(alice);
        weth9.deposit{value: amount}();
        uint afterBalance = address(weth9).balance;
        assertEq(
            beforeBalance + amount,
            afterBalance,
            "Invalid ether balance after deposit"
        );
    }

    // 測項 3: deposit 應該要 emit Deposit event
    function test_DepositEventShouldEmit(uint256 amount) external {
        vm.assume(amount <= 100 * 10 ** 18);
        vm.expectEmit(true, false, false, true);
        emit Deposit(alice, amount);

        vm.prank(alice);
        weth9.deposit{value: amount}();
    }

    // 測項 4: withdraw 應該要 burn 掉與 input parameters 一樣的 erc20 token
    function test_WithdrawShouldBurnEqualWETH(
        uint256 depositAmount,
        uint withdrawAmount
    ) external {
        vm.assume(depositAmount <= 100 * 10 ** 18);
        vm.assume(withdrawAmount <= depositAmount);
        vm.startPrank(alice);
        weth9.deposit{value: depositAmount}();
        uint beforeWithdraw = address(weth9).balance;
        weth9.withdraw(withdrawAmount);
        uint afterWithdraw = address(weth9).balance;
        assertEq(beforeWithdraw - withdrawAmount, afterWithdraw);
    }

    // 測項 5: withdraw 應該將 burn 掉的 erc20 換成 ether 轉給 user
    function test_WithdrawShouldTransferBackToUser(
        uint256 depositAmount,
        uint withdrawAmount
    ) external {
        vm.assume(depositAmount <= 100 * 10 ** 18);
        vm.assume(withdrawAmount <= depositAmount);
        vm.startPrank(alice);

        weth9.deposit{value: depositAmount}();
        uint beforeWithdraw = alice.balance;
        weth9.withdraw(withdrawAmount);
        uint afterWithdraw = alice.balance;
        assertEq(beforeWithdraw + withdrawAmount, afterWithdraw);
    }

    // 測項 6: withdraw 應該要 emit Withdraw event
    function test_WithdrawEventShouldEmit(
        uint256 depositAmount,
        uint withdrawAmount
    ) external {
        vm.assume(depositAmount <= 100 * 10 ** 18);
        vm.assume(withdrawAmount <= depositAmount);
        vm.startPrank(alice);

        weth9.deposit{value: depositAmount}();
        vm.expectEmit(true, false, false, true);
        emit Withdrawal(alice, withdrawAmount);
        weth9.withdraw(withdrawAmount);
    }

    // 測項 7: transfer 應該要將 erc20 token 轉給別人
    function test_WETH_Transfer(
        uint256 depositAmount,
        uint transferAmount
    ) external {
        vm.assume(depositAmount <= 100 * 10 ** 18);
        vm.assume(transferAmount <= depositAmount);
        vm.startPrank(alice);

        weth9.deposit{value: depositAmount}();
        uint balanceOfBobBeforeTransfer = weth9.balanceOf(bob);
        weth9.transfer(bob, transferAmount);
        uint balanceOfBobAfterTransfer = weth9.balanceOf(bob);
        assertEq(
            balanceOfBobBeforeTransfer + transferAmount,
            balanceOfBobAfterTransfer
        );
    }

    // 測項 8: approve 應該要給他人 allowance
    function test_Approve(uint allowanceAmount) external {
        vm.prank(alice);
        weth9.approve(bob, allowanceAmount);
        uint queryAllowanceAmount = weth9.allowance(alice, bob);
        assertEq(queryAllowanceAmount, allowanceAmount);
    }

    // 測項 9: transferFrom 應該要可以使用他人的 allowance
    function test_TransFromAfterApprove(
        uint256 depositAmount,
        uint256 allowanceAmount,
        uint transferAmount
    ) external {
        vm.assume(depositAmount <= 100 * 10 ** 18);
        vm.assume(allowanceAmount <= depositAmount);
        vm.assume(transferAmount <= allowanceAmount);

        vm.startPrank(alice);
        weth9.deposit{value: depositAmount}();
        weth9.approve(bob, allowanceAmount);
        vm.stopPrank();

        uint alexBalanceBeforeTransfer = weth9.balanceOf(alex);
        vm.prank(bob);
        weth9.transferFrom(alice, alex, transferAmount);
        uint alexBalanceAfterTransfer = weth9.balanceOf(alex);
        assertEq(
            alexBalanceBeforeTransfer + transferAmount,
            alexBalanceAfterTransfer
        );
    }

    // 測項 10: transferFrom 後應該要減除用完的 allowance
    function test_TransFromShouldMinusAllowance(
        uint256 depositAmount,
        uint256 allowanceAmount,
        uint transferAmount
    ) external {
        vm.assume(depositAmount <= 100 * 10 ** 18);
        vm.assume(allowanceAmount <= depositAmount);
        vm.assume(transferAmount <= allowanceAmount);

        vm.startPrank(alice);
        weth9.deposit{value: depositAmount}();
        weth9.approve(bob, allowanceAmount);
        vm.stopPrank();

        uint bobAllowanceBeforeTransfer = weth9.allowance(alice, bob);
        vm.startPrank(bob);
        weth9.transferFrom(alice, alex, transferAmount);
        uint bobAllowanceAfterTransfer = weth9.allowance(alice, bob);
        assertEq(
            bobAllowanceBeforeTransfer - transferAmount,
            bobAllowanceAfterTransfer
        );
    }

    // 測項 11: Approval Event should emit
    function test_ApprovalEventShouldEmit(uint256 allowanceAmount) external {
        vm.expectEmit(true, true, false, true);
        emit Approval(alice, bob, allowanceAmount);

        vm.prank(alice);
        weth9.approve(bob, allowanceAmount);
    }

    // 測項 12: Transfer Event should emit
    function test_TransferEventShouldEmit(
        uint256 depositAmount,
        uint transferAmount
    ) external {
        vm.assume(depositAmount <= 100 * 10 ** 18);
        vm.assume(transferAmount <= depositAmount);
        vm.startPrank(alice);
        weth9.deposit{value: depositAmount}();

        vm.expectEmit(true, true, false, true);
        emit Transfer(alice, bob, transferAmount);
        weth9.transfer(bob, transferAmount);
    }

    // 測項 13: Fallback Can Receive ETH
    function test_FallBackCanReceiveETH(uint256 amount) external {
        vm.assume(amount <= 100 * 10 ** 18);
        vm.startPrank(alice);

        uint beforeDepositAmount = address(weth9).balance;
        (bool success, ) = address(weth9).call{value: amount}("0x1234");
        require(success);

        uint afterDepositAmount = address(weth9).balance;
        assertEq(beforeDepositAmount + amount, afterDepositAmount);
    }

    // 測項 14: 存款不足，無法提取
    function testFail_CannotWithdraw_notEnoughBalance(
        uint256 depositAmount,
        uint withdrawAmount
    ) external {
        vm.assume(depositAmount <= 100 * 10 ** 18);
        vm.assume(withdrawAmount > depositAmount);

        vm.startPrank(alice);
        weth9.deposit{value: depositAmount}();
        weth9.withdraw(withdrawAmount);
    }

    // 測項 15: 授權額度不足，無法提取
    function testFail_CannotTransferFrom_notEnoughAllowance(
        uint256 depositAmount,
        uint256 allowanceAmount,
        uint transferAmount
    ) external {
        vm.assume(depositAmount <= 100 * 10 ** 18);
        vm.assume(allowanceAmount <= depositAmount);
        vm.assume(transferAmount > allowanceAmount);
        vm.startPrank(alice);

        weth9.deposit{value: depositAmount}();
        weth9.approve(bob, allowanceAmount);
        vm.stopPrank();

        vm.startPrank(bob);
        weth9.transferFrom(alice, alex, transferAmount);
        vm.stopPrank();
    }

    // 測項 16: expectRevert
    function test_CannotWithdraw_notEnoughBalance() external {
        vm.startPrank(alice);
        vm.expectRevert(bytes("balance < amount"));
        weth9.withdraw(10);
    }
}
