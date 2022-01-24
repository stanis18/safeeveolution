// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.0;
// pragma solidity =0.5.16;

import './IUniswapV2ERC20.sol';
import './SafeMath.sol';

/// @notice  invariant  totalSupply_  ==  __verifier_sum_uint(balanceOf_)
contract UniswapV2ERC20 is IUniswapV2ERC20 {
    using SafeMath for uint;

    string public constant name_ = 'Uniswap V2';
    string public constant symbol_ = 'UNI-V2';
    uint8 public constant decimals_ = 18;
    uint  public totalSupply_;
    mapping (address => uint) public balanceOf_;
    mapping (address => mapping (address => uint)) public allowance_;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;

    constructor() public {
        uint chainId;
        assembly {
            chainId := chainid
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name_)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    /// @notice  emits  Transfer
    function _mint(address to, uint value) internal {
        totalSupply_ = totalSupply_.add(value);
        balanceOf_[to] = balanceOf_[to].add(value);
        emit Transfer(address(0), to, value);
    }

    /// @notice  emits  Transfer
    function _burn(address from, uint value) internal {
        balanceOf_[from] = balanceOf_[from].sub(value);
        totalSupply_ = totalSupply_.sub(value);
        emit Transfer(from, address(0), value);
    }

    /// @notice  emits  Approval
    function _approve(address owner, address spender, uint value) private {
        allowance_[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /// @notice  emits  Transfer
    function _transfer(address from, address to, uint value) private {
        balanceOf_[from] = balanceOf_[from].sub(value);
        balanceOf_[to] = balanceOf_[to].add(value);
        emit Transfer(from, to, value);
    }

    /// @notice  postcondition (allowance_[msg.sender ][ spender] ==  value  &&  success) || ( allowance_[msg.sender ][ spender] ==  __verifier_old_uint ( allowance_[msg.sender ][ spender] ) && !success )    
    /// @notice  emits  Approval
    function approve(address spender, uint value) external returns (bool success) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /// @notice  postcondition ( ( balanceOf_[msg.sender] ==  __verifier_old_uint (balanceOf_[msg.sender] ) - value  && msg.sender  != to ) ||   ( balanceOf_[msg.sender] ==  __verifier_old_uint ( balanceOf_[msg.sender]) && msg.sender  == to ) &&  success )   || !success
    /// @notice  postcondition ( ( balanceOf_[to] ==  __verifier_old_uint ( balanceOf_[to] ) + value  && msg.sender  != to ) ||   ( balanceOf_[to] ==  __verifier_old_uint ( balanceOf_[to] ) && msg.sender  == to ) &&  success )   || !success
    /// @notice  emits  Transfer 
    function transfer(address to, uint value) external returns (bool success) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /// @notice  postcondition ( ( balanceOf_[from] ==  __verifier_old_uint (balanceOf_[from] ) - value  &&  from  != to ) ||   ( balanceOf_[from] ==  __verifier_old_uint ( balanceOf_[from] ) &&  from== to ) &&  success )   || !success
    /// @notice  postcondition ( ( balanceOf_[to] ==  __verifier_old_uint ( balanceOf_[to] ) + value  &&  from  != to ) ||   ( balanceOf_[to] ==  __verifier_old_uint ( balanceOf_[to] ) &&  from  ==to ) &&  success )   || !success
    /// @notice  postcondition  (allowance_[from ][msg.sender] ==  __verifier_old_uint (allowance_[from ][msg.sender] ) - value && !success) || (allowance_[from ][msg.sender] ==  __verifier_old_uint (allowance_[from ][msg.sender] ) && !success)  ||  from  == msg.sender
    /// @notice  postcondition  allowance_[from ][msg.sender]  <= __verifier_old_uint (allowance_[from ][msg.sender] ) ||  from  == msg.sender
    /// @notice  emits  Transfer
    function transferFrom(address from, address to, uint value) external returns (bool success) {
        if (allowance_[from][msg.sender] != uint(-1)) {
            allowance_[from][msg.sender] = allowance_[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    /// @notice  emits  Approval
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'UniswapV2: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'UniswapV2: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}
