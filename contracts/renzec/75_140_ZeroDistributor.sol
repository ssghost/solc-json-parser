// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.8.0;

import "./25_140_IERC20.sol";
import "./76_140_MerkleProof.sol";
import { IMerkleDistributor } from "./77_140_IMerkleDistributor.sol";

contract ZeroDistributor is IMerkleDistributor {
  address public immutable override token;
  bytes32 public immutable override merkleRoot;
  address public immutable treasury;

  // This is a packed array of booleans.
  mapping(uint256 => uint256) private claimedBitMap;

  constructor(
    address token_,
    address treasury_,
    bytes32 merkleRoot_
  ) {
    token = token_;
    treasury = treasury_;
    merkleRoot = merkleRoot_;
  }

  function isClaimed(uint256 index) public view override returns (bool) {
    uint256 claimedWordIndex = index / 256;
    uint256 claimedBitIndex = index % 256;
    uint256 claimedWord = claimedBitMap[claimedWordIndex];
    uint256 mask = (1 << claimedBitIndex);
    return claimedWord & mask == mask;
  }

  function _setClaimed(uint256 index) private {
    uint256 claimedWordIndex = index / 256;
    uint256 claimedBitIndex = index % 256;
    claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
  }

  function claim(
    uint256 index,
    address account,
    uint256 amount,
    bytes32[] calldata merkleProof
  ) external override {
    require(!isClaimed(index), "MerkleDistributor: Drop already claimed.");

    // Verify the merkle proof.
    bytes32 node = keccak256(abi.encodePacked(index, account, amount));
    require(MerkleProof.verify(merkleProof, merkleRoot, node), "MerkleDistributor: Invalid proof.");

    // Mark it claimed and send the token.
    _setClaimed(index);
    require(IERC20(token).transferFrom(treasury, account, amount), "MerkleDistributor: Transfer failed.");

    emit Claimed(index, account, amount);
  }
}