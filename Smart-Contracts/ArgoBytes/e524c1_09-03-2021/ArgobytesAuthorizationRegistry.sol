
pragma solidity >= 0.5.0;

interface IArgobytesAuthorizationRegistry {
    function canCall(
        address caller,
        address target,
        bytes4 sig
    ) external view returns (bool);

    function allow(
        address[] calldata senders,
        address target,
        bytes4 sig
    ) external;

    function deny(
        address[] calldata senders,
        address target,
        bytes4 sig
    ) external;
}

contract ArgobytesAuthorizationRegistry is IArgobytesAuthorizationRegistry{
    // key is from `createKey`
    mapping(bytes => bool) authorizations;

    function createKey(
        address proxy,
        address sender,
        address target,
        bytes4 sig
    ) internal pure returns (bytes memory key) {
        // encodePacked should be safe because address and bytes4 are fixed size types
        key = abi.encodePacked(proxy, sender, target, sig);
    }

    // TODO: i can see some use-cases for not hard coding msg.sender here, but we don't need it now
    function canCall(
        address sender,
        address target,
        bytes4 sig
    ) external  view returns (bool) {
        bytes memory key = createKey(msg.sender, sender, target, sig);

        return authorizations[key];
    }

    // SECURITY! If `target` is upgradable, the function at `sig` could be changed and a `sender` may be able to do something malicious!
    function allow(
        address[] calldata senders,
        address target,
        bytes4 sig
    ) external  {
        bytes memory key;

        for (uint256 i = 0; i < senders.length; i++) {
            key = createKey(msg.sender, senders[i], target, sig);

            authorizations[key] = true;
        }
    }

    function deny(
        address[] calldata senders,
        address target,
        bytes4 sig
    ) external  {
        bytes memory key;

        for (uint256 i = 0; i < senders.length; i++) {
            key = createKey(msg.sender, senders[i], target, sig);

            delete authorizations[key];
        }
    }
}
