// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

/**
 * @notice A Chainlink VRF consumer which uses randomness to allow for decentralized CoinFlips. Requires LINK to function.
 * @dev This is only an example implementation and not necessarily suitable for mainnet.
 */
 
contract COINFLIPS is VRFConsumerBase{
    enum Status {
        OPEN, CLOSED, IN_PROGRESS
    }
    
    enum Flip {
        HEADS, TAILS
    }

    struct CoinFlip {
        uint id;
        uint bet;
        Flip player_one_choice;
        Status status;
        address payable player_one;
        address payable player_two;
        address payable winner;
    }

    CoinFlip[] public CoinFlips;

    bool public contractLocked;

    bytes32 private s_keyHash;
    uint256 private s_fee;
    uint private current_flip_in_progress;

    event FlipCreated(uint indexed flipId, uint indexed bet_amount);
    event FlipCompleted(uint indexed flipId, address indexed winner);

    constructor() // Meant for Rinkeby Testnet
        VRFConsumerBase(0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, 0x01BE23585060835E02B77ef475b0Cc51aA1e0709)
    {
        s_keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
        s_fee = 100000000000000000;
        contractLocked = false;
    }

    function createFlip(Flip _bettingOn) public payable {
        require(msg.value >= 100000000000000000, "Minimum of 0.1 ETH to create a coin flip"); 
        CoinFlips.push(CoinFlip(CoinFlips.length, msg.value, _bettingOn, Status.OPEN, payable(msg.sender), payable(0), payable(0)));
        emit FlipCreated(CoinFlips.length, msg.value);
    }

    function flip(uint _flipId) public payable returns (bytes32 requestId) {
        require(contractLocked == false, "Contract is temporary locked due to on-going CoinFlip.");
        require(LINK.balanceOf(address(this)) >= s_fee, "Not enough LINK to pay fee");
        require(CoinFlips[_flipId].status == Status.OPEN, "CoinFlip must be open");
        require(msg.value == CoinFlips[_flipId].bet, "Must match the bet amount");
        CoinFlips[_flipId].status = Status.IN_PROGRESS;
        CoinFlips[_flipId].player_two = payable(msg.sender);
        current_flip_in_progress = _flipId;
        contractLocked = true;
        requestId = requestRandomness(s_keyHash, s_fee);
        return requestId;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint256 random = (randomness % 2) + 1; 
        if (random == 1) {
            address payable _player_one = CoinFlips[current_flip_in_progress].player_one;
            CoinFlips[current_flip_in_progress].winner = _player_one;
            _player_one.transfer(CoinFlips[current_flip_in_progress].bet * 2);
            CoinFlips[current_flip_in_progress].status = Status.CLOSED;
            contractLocked = false;
            emit FlipCompleted(current_flip_in_progress, _player_one);
        } else if (random == 2) {
            address payable _player_two = CoinFlips[current_flip_in_progress].player_two;
            CoinFlips[current_flip_in_progress].winner = _player_two;
            _player_two.transfer(CoinFlips[current_flip_in_progress].bet * 2);
            CoinFlips[current_flip_in_progress].status = Status.CLOSED;
            contractLocked = false;
            emit FlipCompleted(current_flip_in_progress, _player_two);
        }
    }

}
