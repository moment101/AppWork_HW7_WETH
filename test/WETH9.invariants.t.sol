// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/Weth9.sol";
import "./handlers/Handler.sol";

contract Weth9InvariantsTest is Test {
    WETH9 public weth;
    Handler public handler;

    function setUp() public {
        weth = new WETH9();
        handler = new Handler(weth);

        bytes4[] memory selectors = new bytes4[](6);
        selectors[0] = Handler.deposit.selector;
        selectors[1] = Handler.withdraw.selector;
        selectors[2] = Handler.sendFallback.selector;
        selectors[3] = Handler.approve.selector;
        selectors[4] = Handler.transfer.selector;
        selectors[5] = Handler.transferFrom.selector;

        targetSelector(
            FuzzSelector({addr: address(handler), selectors: selectors})
        );

        targetContract(address(handler));
    }

    // The sum of Handler's ETH balance plus the
    // WETH totalSupply() should always equal the
    // total ETH_SUPPLY
    function invariant_conservationOfETH() public {
        assertEq(
            handler.ETH_SUPPLY(),
            address(handler).balance + weth.totalSupply()
        );
    }

    // The WETH contract's Ether balance should always
    // equal the sum of all the individual deposits
    // minus all the individual withdraws
    function invariant_solvencyDeposits() public {
        assertEq(
            address(weth).balance,
            handler.ghost_depositSum() - handler.ghost_withdrawSum()
        );
    }

    // The WETH contract's Ether balance always be
    // at least as much as the sum of individual balances
    function invariant_solvencyBalances() public {
        uint256 sumOfBalances;
        address[] memory actors = handler.actors();
        for (uint256 i; i < actors.length; i++) {
            sumOfBalances += weth.balanceOf(actors[i]);
        }

        assertEq(address(weth).balance, sumOfBalances);
    }

    // No individual account balance can exceed the
    // WETH totalSupply()
    function invariant_depositorBalance() public {
        uint256 sumOfBalances;
        address[] memory actors = handler.actors();
        for (uint256 i; i < actors.length; i++) {
            sumOfBalances += weth.balanceOf(actors[i]);
        }

        for (uint256 i; i < actors.length; i++) {
            assertLe(weth.balanceOf(actors[i]), sumOfBalances);
        }
    }

    function invariant_callSummary() public view {
        handler.callSummary();
    }
}
