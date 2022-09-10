pragma solidity >= 0.5.0;



interface ATokenLike {
    function underlying() external view returns (address);
    function transferUnderlyingTo(address, uint256) external;
}