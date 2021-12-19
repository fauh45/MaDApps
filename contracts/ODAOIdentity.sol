// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ODAOToken.sol";

contract ODAOIdentity is Ownable {
    struct VerifyingMetadata {
        bool ongoing;
        string name;
        uint256 voteYes;
        uint256 voteNo;
        mapping(address => bool) voteValue;
        address[] voted;
        uint256 endDate;
    }

    struct SubIdentityMetadata {
        bool exist;
        string name;
    }

    struct IdentityMetadata {
        bool exist;
        string name;
        mapping(address => SubIdentityMetadata) subIdentity;
    }

    struct StakingMetadata {
        bool locked;
        uint256 amount;
    }

    event VerificationStart(address indexed starterOrgs, uint256 endDate);
    event VerificationEnd(address indexed starterOrgs, bool indexed verified);

    mapping(address => StakingMetadata) private stakeAmount;
    ODAOToken private token;

    uint256 public amountToStake;
    uint256 public verificationDuration;
    mapping(address => VerifyingMetadata) public verifying;
    mapping(address => IdentityMetadata) public verifiedIdentity;

    constructor(address _tokenAddress, uint256 _amountToStake) Ownable() {
        token = ODAOToken(_tokenAddress);
        amountToStake = _amountToStake;
        verificationDuration = 1 weeks + 3 days;
    }

    modifier verifiedOnly(address identity) {
        require(
            verifiedIdentity[identity].exist,
            "[Identity] Identity not verified"
        );
        _;
    }

    modifier hasStake(address verifier) {
        require(
            !stakeAmount[verifier].locked,
            "[Identity] Verifier staking are currently locked"
        );
        require(
            stakeAmount[verifier].amount >= amountToStake,
            "[Identity] Verifier balance are less than amount to stake"
        );
        _;
    }

    function changeAmountToStake(uint256 newAmountToStake) public onlyOwner {
        amountToStake = newAmountToStake;
    }

    function stake() public returns (bool) {
        require(
            token.transferFrom(msg.sender, address(this), amountToStake),
            "[Identity] Cannot stake amount set"
        );

        stakeAmount[msg.sender].amount = amountToStake;

        return true;
    }

    function startVerification(string memory _name) public returns (bool) {
        require(
            !verifying[msg.sender].ongoing,
            "[Identity] Already has ongoing verification"
        );
        require(
            !verifiedIdentity[msg.sender].exist,
            "[Identity] Identity already verified"
        );

        verifying[msg.sender].ongoing = true;
        verifying[msg.sender].name = _name;
        verifying[msg.sender].voteYes = 0;
        verifying[msg.sender].voteNo = 0;
        verifying[msg.sender].endDate = block.timestamp + verificationDuration;

        emit VerificationStart(msg.sender, verifying[msg.sender].endDate);

        return true;
    }

    function vote(address _identity, bool _verified)
        public
        hasStake(msg.sender)
        returns (bool)
    {
        require(
            verifying[_identity].ongoing,
            "[Identity] There's no ongoing verification"
        );

        verifying[_identity].voteValue[msg.sender] = _verified;
        verifying[_identity].voted.push(msg.sender);

        if (_verified) {
            verifying[_identity].voteYes += 1;
        } else {
            verifying[_identity].voteYes -= 1;
        }

        stakeAmount[msg.sender].locked = true;

        return true;
    }

    function endVote(address _identity) public returns (bool) {
        require(
            verifying[_identity].ongoing,
            "[Identity] There's no ongoing verification"
        );
        require(
            verifying[_identity].endDate <= block.timestamp,
            "[Identity] Verification end date have not reached yet"
        );

        verifying[_identity].ongoing = false;

        bool winningVote = verifying[_identity].voteYes >
            verifying[_identity].voteNo;
        uint256 winningVoteAmount;

        if (winningVote) {
            winningVoteAmount = verifying[_identity].voteYes;
        } else {
            winningVoteAmount = verifying[_identity].voteNo;
        }

        // Percentage on 18 decimals
        uint256 percentageToRemove = (winningVoteAmount /
            (verifying[_identity].voteYes + verifying[_identity].voteNo)) *
            1_000_000_000_000_000_000;
        uint256 allLoseTokenValue = 0;
        uint256 allWins = 0;

        for (uint256 i = 0; i < verifying[_identity].voted.length; i++) {
            if (
                winningVote !=
                verifying[_identity].voteValue[verifying[_identity].voted[i]]
            ) {
                uint256 amountLose = stakeAmount[verifying[_identity].voted[i]]
                    .amount * (percentageToRemove / 1_000_000_000_000_000_000);
                stakeAmount[verifying[_identity].voted[i]].amount -= amountLose;

                allLoseTokenValue += amountLose;
            } else {
                allWins += 1;
            }
        }

        uint256 eachWinner = allLoseTokenValue / allWins;

        for (uint256 i = 0; i < verifying[_identity].voted.length; i++) {
            if (
                winningVote ==
                verifying[_identity].voteValue[verifying[_identity].voted[i]]
            ) {
                stakeAmount[verifying[_identity].voted[i]].amount += eachWinner;
            }

            stakeAmount[verifying[_identity].voted[i]].locked = false;
        }

        verifiedIdentity[_identity].exist = true;
        verifiedIdentity[_identity].name = verifying[_identity].name;

        emit VerificationEnd(_identity, winningVote);

        return true;
    }

    function cashout() public returns (bool) {
        require(
            !stakeAmount[msg.sender].locked,
            "[Identity] Staking token are locked"
        );

        require(token.transfer(msg.sender, stakeAmount[msg.sender].amount));

        return true;
    }

    function addSubIdentity(address _identity, string memory _name)
        public
        verifiedOnly(msg.sender)
        returns (bool)
    {
        verifiedIdentity[msg.sender].subIdentity[_identity].exist = true;
        verifiedIdentity[msg.sender].subIdentity[_identity].name = _name;

        return true;
    }
}
