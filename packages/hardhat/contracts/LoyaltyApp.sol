// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LoyaltyApp is ERC721, Ownable {
    // Token details
    string private _tokenName;
    string private _tokenSymbol;

    // Minting variables
    uint256 private _tokenIdTracker;
    uint256 private _mintingCap;

    // Reward details
    mapping(uint256 => Reward) private _rewards;
    uint256 private _rewardCount;
    
    // Reward struct
    struct Reward {
        string name;
        string description;
        uint256 cost;
    }

    // Modifiers
    modifier onlyOwnerOrTokenOwner(uint256 tokenId) {
        require(msg.sender == owner() || ownerOf(tokenId) == msg.sender, "Unauthorized");
        _;
    }

    // Events
    event RewardAdded(uint256 id, string name, string description, uint256 cost);
    event RewardRedeemed(uint256 id, uint256 tokenId);

    constructor(string memory tokenName, string memory tokenSymbol, uint256 mintingCap) ERC721(tokenName, tokenSymbol) {
        _tokenName = tokenName;
        _tokenSymbol = tokenSymbol;
        _mintingCap = mintingCap;
    }

    // Mint a token
    function mint() external {
        require(_tokenIdTracker < _mintingCap, "Minting cap reached");
        _safeMint(msg.sender, _tokenIdTracker);
        _tokenIdTracker++;
    }

    // Get the token name
    function getTokenName() external view returns (string memory) {
        return _tokenName;
    }

    // Get the token symbol
    function getTokenSymbol() external view returns (string memory) {
        return _tokenSymbol;
    }

    // Add a reward that can be redeemed
    function addReward(string memory name, string memory description, uint256 cost) external onlyOwner {
        require(cost > 0, "Reward cost must be greater than zero");

        _rewards[_rewardCount] = Reward(name, description, cost);
        emit RewardAdded(_rewardCount, name, description, cost);

        _rewardCount++;
    }

    // Get the total number of rewards
    function getRewardCount() external view returns (uint256) {
        return _rewardCount;
    }

    // Get reward details by ID
    function getReward(uint256 id) external view returns (string memory, string memory, uint256) {
        Reward memory reward = _rewards[id];
        return (reward.name, reward.description, reward.cost);
    }

    // Redeem a reward by burning the token and transfer the ownership of reward to the caller
    function redeemReward(uint256 rewardId, uint256 tokenId) external {
        require(_exists(tokenId), "Token does not exist");
        require(rewardId < _rewardCount, "Invalid reward ID");

        Reward memory reward = _rewards[rewardId];
        require(ownerOf(tokenId) == msg.sender, "Caller is not the token owner");
        require(reward.cost > 0, "Reward does not exist");
        require(ERC20(address(this)).balanceOf(msg.sender) >= reward.cost, "Insufficient token balance");

        _burn(tokenId);
        ERC20(address(this)).transferFrom(msg.sender, owner(), reward.cost);

        emit RewardRedeemed(rewardId, tokenId);
    }
}