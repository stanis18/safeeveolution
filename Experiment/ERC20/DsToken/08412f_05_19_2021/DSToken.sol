/// token.sol -- ERC20 implementation with minting and burning

// Copyright (C) 2015, 2016, 2017  DappHub, LLC

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.0;
// pragma solidity >=0.4.23;

import "./math.sol";

/// @notice  invariant  totalSupply  ==  __verifier_sum_uint(balanceOf)
contract DSToken is DSMath {
    bool                                              public  stopped;
    uint256                                           public  totalSupply;
    mapping (address => uint256)                      public  balanceOf;
    mapping (address => mapping (address => uint256)) public  allowance;
    string                                            public  symbol;
    uint8                                             public  decimals = 18; // standard token precision. override to customize
    string                                            public  name = "";     // Optional token name


    constructor(string memory symbol_) public {
        symbol = symbol_;
    }

    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);
    event Mint(address indexed guy, uint wad);
    event Burn(address indexed guy, uint wad);
    event Stop();
    event Start();

    modifier stoppable {
        require(!stopped, "ds-stop-is-stopped");
        _;
    }

    /// @notice  emits  Approval
    function approve(address guy) external returns (bool) {
        return approve(guy, uint(-1));
    }

    /// @notice  postcondition (allowance[msg.sender ][ guy] ==  wad  &&  ok) || ( allowance[msg.sender ][ guy] ==  __verifier_old_uint ( allowance[msg.sender ][ guy] ) && !ok )    
    /// @notice  emits  Approval
    function approve(address guy, uint wad) public stoppable returns (bool ok) {
        allowance[msg.sender][guy] = wad;

        emit Approval(msg.sender, guy, wad);

        return true;
    }

    /// @notice  postcondition ( ( balanceOf[msg.sender] ==  __verifier_old_uint (balanceOf[msg.sender] ) - wad  && msg.sender  != dst ) ||   ( balanceOf[msg.sender] ==  __verifier_old_uint ( balanceOf[msg.sender]) && msg.sender  == dst ) &&  ok )   || !ok
    /// @notice  postcondition ( ( balanceOf[dst] ==  __verifier_old_uint ( balanceOf[dst] ) + wad  && msg.sender  != dst ) ||   ( balanceOf[dst] ==  __verifier_old_uint ( balanceOf[dst] ) && msg.sender  == dst ) &&  ok )   || !ok
    /// @notice  emits  Transfer 
    function transfer(address dst, uint wad) external returns (bool ok) {
        return transferFrom(msg.sender, dst, wad);
    }

    /// @notice  postcondition ( ( balanceOf[src] ==  __verifier_old_uint (balanceOf[src] ) - wad  &&  src  != dst ) ||   ( balanceOf[src] ==  __verifier_old_uint ( balanceOf[src] ) &&  src== dst ) &&  ok )   || !ok
    /// @notice  postcondition ( ( balanceOf[dst] ==  __verifier_old_uint ( balanceOf[dst] ) + wad  &&  src  != dst ) ||   ( balanceOf[dst] ==  __verifier_old_uint ( balanceOf[dst] ) &&  src  ==dst ) &&  ok )   || !ok
    /// @notice  postcondition ( allowance[src ][msg.sender] ==  __verifier_old_uint (allowance[src ][msg.sender] ) - wad && ok)  || ( allowance[src ][msg.sender] ==  __verifier_old_uint (allowance[src ][msg.sender] ) && !ok) || src  == msg.sender
    /// @notice  postcondition  allowance[src ][msg.sender]  <= __verifier_old_uint (allowance[src ][msg.sender] ) ||  src  == msg.sender
    /// @notice  emits  Transfer
    function transferFrom(address src, address dst, uint wad)
        public
        stoppable
        returns (bool ok)
    {
        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad, "ds-token-insufficient-approval");
            allowance[src][msg.sender] = sub(allowance[src][msg.sender], wad);
        }

        require(balanceOf[src] >= wad, "ds-token-insufficient-balance");
        balanceOf[src] = sub(balanceOf[src], wad);
        balanceOf[dst] = add(balanceOf[dst], wad);

        emit Transfer(src, dst, wad);

        return true;
    }

    /// @notice  emits  Transfer
    function push(address dst, uint wad) external {
        transferFrom(msg.sender, dst, wad);
    }

    /// @notice  emits  Transfer
    function pull(address src, uint wad) external {
        transferFrom(src, msg.sender, wad);
    }

    /// @notice  emits  Transfer
    function move(address src, address dst, uint wad) external {
        transferFrom(src, dst, wad);
    }

    /// @notice  emits  Mint
    function mint(uint wad) external {
        mint(msg.sender, wad);
    }

    /// @notice  emits  Burn
    function burn(uint wad) external {
        burn(msg.sender, wad);
    }

    /// @notice  emits  Mint
    function mint(address guy, uint wad) public stoppable {
        balanceOf[guy] = add(balanceOf[guy], wad);
        totalSupply = add(totalSupply, wad);
        emit Mint(guy, wad);
    }

    /// @notice  emits  Burn
    function burn(address guy, uint wad) public stoppable {
        if (guy != msg.sender && allowance[guy][msg.sender] != uint(-1)) {
            require(allowance[guy][msg.sender] >= wad, "ds-token-insufficient-approval");
            allowance[guy][msg.sender] = sub(allowance[guy][msg.sender], wad);
        }

        require(balanceOf[guy] >= wad, "ds-token-insufficient-balance");
        balanceOf[guy] = sub(balanceOf[guy], wad);
        totalSupply = sub(totalSupply, wad);
        emit Burn(guy, wad);
    }

    /// @notice  emits  Stop
    function stop() public  {
        stopped = true;
        emit Stop();
    }

    /// @notice  emits  Start
    function start() public  {
        stopped = false;
        emit Start();
    }


    function setName(string memory name_) public  {
        name = name_;
    }
}
