// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.0;
// pragma solidity ^0.6.2;

import "./IERC165.sol";

/**
    @title ERC-1155 Multi Token Standard basic interface
    @dev See https://eips.ethereum.org/EIPS/eip-1155
 */
interface IERC1155 {
  

    function balanceOf(address account, uint256 id) external view  returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view  returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external ;

    function isApprovedForAll(address account, address operator) external view  returns (bool);

    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes calldata data) external ;

    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external ;
}
