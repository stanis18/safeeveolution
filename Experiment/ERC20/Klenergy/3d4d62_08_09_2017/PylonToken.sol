// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.0;
// pragma solidity ^0.4.11;

import "./ConvertLib.sol";
import "./Ownable.sol";

// This is just a simple example of a coin-like contract.
// It is not standards compatible and cannot be expected to talk to other
// coin/token contracts. If you want to create a standards-compliant
// token, see: https://github.com/ConsenSys/Tokens. Cheers!


contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes memory _extraData) public; }

/// @notice  invariant  totalSupply  ==  __verifier_sum_uint(balances)
contract PylonToken is Ownable {
	/* Public variables of the token */
	string public standard = "Pylon Token - The first decentralized energy exchange platform powered by renewable energy";
  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;

    uint256 public buyPrice;
  uint256 public sellPrice;
  string public buyLock="open";
  string public sellLock="open";
  uint8 public panicLevel=30;
  uint256 public panicTime=60*2;
  uint256 public time;
  uint256 public lastBlock=block.number;
  uint256 public panicSellCounter;
  uint256 public panicBuyCounter;
  uint256 public panicWall;
  string public debug;

	uint public maxPercentage;
  uint public investmentOfferPeriodInMinutes;
  InvestmentOffer[] public investmentOffer;
  uint public numInvestmentOffers;

	mapping (address => bool) public frozenAccount;

	mapping (address => uint) balances;
	mapping (address => mapping (address => uint256)) public allowance;

	event Transfer(address indexed _from, address indexed _to, uint256 _value);

	/* This generates a public event on the blockchain that will notify clients */
  event FrozenFunds(address target, bool frozen);

  /* This notifies clients about the amount burnt */
  event Burn(address indexed _from, uint256 _value);

    /// @notice  emits  ChangeOfRules
	constructor(
		/*
    uint256 initialSupply=3000000000000000000000000,
    string tokenName = "Pylon Token",
    uint8 decimalUnits = 18,
    string tokenSymbol = "PYLNT",
		uint maxPercentage = 10,
    uint minutesForInvestment = 200,
		*/

  ) public {
		balances[tx.origin] = 3000000000000000000000000;
		totalSupply = 3000000000000000000000000;                        // Update total supply
    name = "Pylon Token";                                   // Set the name for display purposes
    symbol = "PYLNT";                               // Set the symbol for display purposes
    decimals = 18;
		maxPercentage = 10;
    uint minutesForInvestment = 200;

		changeInvestmentRules(maxPercentage, minutesForInvestment);

	}

    /// @notice  postcondition ( ( balances[msg.sender] ==  __verifier_old_uint (balances[msg.sender] ) - _value  && msg.sender  != _to ) ||   ( balances[msg.sender] ==  __verifier_old_uint ( balances[msg.sender]) && msg.sender  == _to ) &&  success )   || !success
    /// @notice  postcondition ( ( balances[_to] ==  __verifier_old_uint ( balances[_to] ) + _value  && msg.sender  != _to ) ||   ( balances[_to] ==  __verifier_old_uint ( balances[_to] ) && msg.sender  == _to ) &&  success )   || !success
    /// @notice  emits  Transfer
	function transfer(address _to, uint _value) public returns(bool success) {
		if (balances[msg.sender] < _value) revert();            // Check if the sender has enough
		if (balances[_to] + _value < balances[_to]) revert();   // Check for overflows
		if (frozenAccount[msg.sender]) revert();                // Check if frozen

		balances[msg.sender] -= _value;
		balances[_to] += _value;
		emit Transfer(msg.sender, _to, _value);

		return true;
	}

	function getBalanceInEth(address addr) public returns(uint){
		return ConvertLib.convert(getBalance(addr),2);
	}

	function getBalance(address addr) public returns(uint) {
		return balances[addr];
	}

	/* Allow another contract to spend some tokens in your behalf */
   /// @notice  postcondition (allowance[msg.sender ][ _spender] ==  _value  &&  success) || ( allowance[msg.sender ][ _spender] ==  __verifier_old_uint ( allowance[msg.sender ][ _spender] ) && !success )    
   // / @notice  emits  Approval  
  function approve(address _spender, uint256 _value) public
      onlyOwner
      returns (bool success) {
      allowance[msg.sender][_spender] = _value;
      return true;
  }

	/* Approve and then communicate the approved contract in a single tx */
    // / @notice  emits  Approval 
  function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public
      onlyOwner
      returns (bool success) {
      tokenRecipient spender = tokenRecipient(_spender);
      if (approve(_spender, _value)) {
          spender.receiveApproval(msg.sender, _value, address(this), _extraData);
          return true;
      }
  }

	/* A contract attempts to get the coins */
    /// @notice  postcondition ( ( balances[_from] ==  __verifier_old_uint (balances[_from] ) - _value  &&  _from  != _to ) ||   ( balances[_from] ==  __verifier_old_uint ( balances[_from] ) &&  _from== _to ) &&  success )   || !success
    /// @notice  postcondition ( ( balances[_to] ==  __verifier_old_uint ( balances[_to] ) + _value  &&  _from  != _to ) ||   ( balances[_to] ==  __verifier_old_uint ( balances[_to] ) &&  _from  ==_to ) &&  success )   || !success
    /// @notice  postcondition ( allowance[_from ][msg.sender] ==  __verifier_old_uint (allowance[_from ][msg.sender] ) - _value && success ) || ( allowance[_from ][msg.sender] ==  __verifier_old_uint (allowance[_from ][msg.sender] )  && !success ) || _from  == msg.sender
    /// @notice  postcondition  allowance[_from ][msg.sender]  <= __verifier_old_uint (allowance[_from ][msg.sender] ) ||  _from  == msg.sender
    /// @notice  emits  Transfer  
  function transferFrom(address _from, address _to, uint256 _value) public onlyOwner returns (bool success) {
			if (frozenAccount[_from]) revert();                        // Check if frozen
			if (balances[_from] < _value) revert();                 // Check if the sender has enough
      if (balances[_to] + _value < balances[_to]) revert();  // Check for overflows
      if (_value > allowance[_from][msg.sender]) revert();   // Check allowance

			balances[_from] -= _value;                          // Subtract from the sender
      balances[_to] += _value;                            // Add the same to the recipient
      allowance[_from][msg.sender] -= _value;

			emit Transfer(_from, _to, _value);

			return true;
  }

  /// @notice Remove `_value` tokens from the system irreversibly
  /// @param _value the amount of money to burn
   /// @notice  emits  Burn 
  function burn(uint256 _value) public onlyOwner returns (bool success) {
      require (balances[msg.sender] > _value);            // Check if the sender has enough
      balances[msg.sender] -= _value;                      // Subtract from the sender
      totalSupply -= _value;                                // Updates totalSupply
      emit Burn(msg.sender, _value);
      return true;
  }
    /// @notice  emits  Burn 
  function burnFrom(address _from, uint256 _value) public onlyOwner returns (bool success) {
      require(balances[_from] >= _value);                // Check if the targeted balance is enough
      require(_value <= allowance[_from][msg.sender]);    // Check allowance
      balances[_from] -= _value;                         // Subtract from the targeted balance
      allowance[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
      totalSupply -= _value;                              // Update totalSupply
      emit Burn(_from, _value);
      return true;
  }

	// Lock account for not allow transfers
    /// @notice  emits  FrozenFunds 
    function freezeAccount(address target, bool freeze) public onlyOwner {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    //set new lock parameters for buy or sale tokens
    function lock(string memory newBuyLock, string memory newSellLock,uint256 panicBuyCounterU,uint256 panicSellCounterU) public onlyOwner {
        buyLock = newBuyLock;
        sellLock = newSellLock;
        panicSellCounter=panicSellCounterU;
        panicBuyCounter=panicBuyCounterU;
    }

    //set panic level and panic time
    function setPanic(uint8 panicLevelU, uint256 panicTimeU) public onlyOwner {
        panicLevel=panicLevelU;
        panicTime=panicTimeU;
    }

    //Declare panic mode or not
    function panic(uint256 panicWallU) public onlyOwner {
        time=block.timestamp;

        //calculate the panic wall, this is the limit for buy or sell between specific panic time
        panicWallU=(totalSupply*panicLevel)/100;
        panicWall=panicWallU*buyPrice;

        //check if the panic counter is more than the panic wallet to close sell orders or buy orders
        if(panicBuyCounter>=(panicWallU*buyPrice)){
         buyLock = "close";
        }else{
            buyLock="open";
        }
        if(panicSellCounter>=(panicWallU*sellPrice)){
            sellLock = "close";
        }else{
            sellLock="open";
        }

    }

    //Declare logging events
    event LogDeposit(address sender, uint amount);
    event LogWithdrawal(address receiver, uint amount);
    event LogTransfer(address sender, address to, uint amount);

    /// @notice  emits  LogDeposit 
    function deposit() public payable returns(bool success) {
        // Check for overflows;
        if (address(this).balance + msg.value < address(this).balance) revert(); // Check for overflows

        //executes event to reflect the changes
        emit LogDeposit(msg.sender, msg.value);

        return true;
    }

    /// @notice  emits  LogWithdrawal 
    function withdraw(uint value) public onlyOwner {

        //send eth to owner address
        msg.sender.transfer(value);

        //executes event or register the changes
        emit LogWithdrawal(msg.sender, value);

    }

    event InvestmentOfferAdded(uint proposalID, address recipient, uint amount, string description);
    event Invested(uint proposalID, address investor, string justification);
    event ChangeOfRules(uint maxPercentageEvent, uint investmentOfferPeriodInMinutesEvent);

    struct InvestmentOffer {
        address recipient;
        uint amount;
        string description;
        uint investingDeadline;
        bool executed;
        bool investmentPassed;
        uint numberOfInvestments;
        uint currentAmount;
        bytes32 investmentHash;
        Offer[] offers;
        mapping (address => bool) invested;
    }

    struct Offer {
        bool inSupport;
        address investor;
        string justification;
    }

    /*change rules*/
     /// @notice  emits  ChangeOfRules 
    function changeInvestmentRules(
        uint maxPercentageForInvestments,
        uint minutesForInvestment
    ) public onlyOwner {
        maxPercentage = maxPercentageForInvestments;
        investmentOfferPeriodInMinutes = minutesForInvestment;

        emit ChangeOfRules(maxPercentage, investmentOfferPeriodInMinutes);
    }

    /* Function to create a new investment offer */
    ///@notice emits InvestmentOfferAdded
    function newInvestmentOffer(
        address beneficiary,
        uint etherAmount,
        string memory JobDescription,
        bytes memory transactionBytecode
    ) public
        onlyOwner
        returns (uint proposalID)
    {
        uint dec=decimals;

        proposalID = investmentOffer.length++;
        InvestmentOffer storage p2 = investmentOffer[proposalID];
        p2.recipient = beneficiary;
        p2.amount = etherAmount * (10**dec);
        p2.description = JobDescription;
        p2.investmentHash = keccak256(abi.encodePacked(beneficiary, etherAmount, transactionBytecode));
        p2.investingDeadline = now + investmentOfferPeriodInMinutes * 1 minutes;
        p2.executed = false;
        p2.investmentPassed = false;
        p2.numberOfInvestments = 0;
        emit InvestmentOfferAdded(proposalID, beneficiary, etherAmount, JobDescription);
        numInvestmentOffers = proposalID+1;

        return proposalID;
    }

    /* function to check if a investment offer code matches */
    function checkInvestmentOfferCode(
        uint investmentNumber,
        address beneficiary,
        uint etherAmount,
        bytes memory transactionBytecode
    )
        public
        returns (bool codeChecksOut)
    {
        InvestmentOffer storage p = investmentOffer[investmentNumber];
        return p.investmentHash == keccak256(abi.encodePacked(beneficiary, etherAmount, transactionBytecode));
    }

    /// @notice  emits  Transfer 
    /// @notice  emits  Invested 
    function invest(
        uint investmentNumber,
        string memory justificationText,
        address target
    )   public
        payable
        returns (uint voteID)
    {
        uint dec=decimals;
        uint maxP=maxPercentage;

        InvestmentOffer storage p = investmentOffer[investmentNumber];                  // Get the investment Offer
        if (msg.value >= (p.amount * (maxP / 100))) revert();    // Same or less investment than maximum percent
        if (p.amount <= (p.currentAmount + msg.value)) revert(); // Check if the investment is more than total offer
        if (p.invested[msg.sender] == true) revert();                        // If has already invested, cancel
        p.invested[msg.sender] = true;                                      // Set this investor as having invested
        p.numberOfInvestments++;

        uint amount = msg.value * (buyPrice / (10**dec));                // calculates the amount

        if (amount <= 0) revert();  //check amount overflow
        if (balances[target] + amount < balances[target]) revert(); // Check for overflows
        if (address(this).balance + msg.value < address(this).balance) revert(); // Check for overflows

        p.currentAmount += msg.value;       // Increase the investment amount
        balances[target] += amount;                   // Adds the amount to target balance
        totalSupply += amount;                        // Add amount to total supply

        emit Transfer(address(0), owner, amount);                   // Send tokens to contract
        emit Transfer(owner, target, amount);             // Send tokens to target address

        // Create a log of this event
        emit Invested(investmentNumber, msg.sender, justificationText);

        return p.numberOfInvestments;
    }

}
