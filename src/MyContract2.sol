// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract TestPractice {
    address public user1;
    address public user2;

    event Receive(address from, uint256 amount);
    event Send(address to, uint256 amount);

    constructor(address _user1, address _user2) {
        user1 = _user1;
        user2 = _user2;
    }

    function sendEther(address to, uint256 amount) external payable {
        require(msg.sender == user1 || msg.sender == user2);
        require(address(this).balance >= amount, "insufficient balance");

        (bool success, ) = to.call{value: amount}("");
        require(success, "transfer failed");

        emit Send(to, amount);
    }

    receive() external payable {
        emit Receive(msg.sender, msg.value);
    }
}
