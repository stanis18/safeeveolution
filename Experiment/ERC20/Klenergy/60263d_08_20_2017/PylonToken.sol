// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.0;
// pragma solidity ^0.4.2;

//Declare owned , structure to admin functions only by the owner
contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) revert();
        _;
    }

    //transfer owner property
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

//Standard token ERC20 structure declaration

//
contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes memory _extraData)  public; }

contract token {
    /* Public variables of the token */
    string public standard = "Pylon Token - The first decentralized energy exchange platform powered by renewable energy";
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor(
        uint256 initialSupply,
        string memory tokenName,
        uint8 decimalUnits,
        string memory tokenSymbol

        ) public {
        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
        totalSupply = initialSupply;                        // Update total supply
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = decimalUnits;                            // Amount of decimals for display purposes

    }

    /* Send coins */
    /// @notice  postcondition ( ( balanceOf[msg.sender] ==  __verifier_old_uint (balanceOf[msg.sender] ) - _value  && msg.sender  != _to ) ||   ( balanceOf[msg.sender] ==  __verifier_old_uint ( balanceOf[msg.sender]) && msg.sender  == _to ) &&  success )   || !success
    /// @notice  postcondition ( ( balanceOf[_to] ==  __verifier_old_uint ( balanceOf[_to] ) + _value  && msg.sender  != _to ) ||   ( balanceOf[_to] ==  __verifier_old_uint ( balanceOf[_to] ) && msg.sender  == _to ) &&  success )   || !success
    /// @notice  emits  Transfer
    function transfer(address _to, uint256 _value) public {
        if (balanceOf[msg.sender] < _value) revert();           // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) revert(); // Check for overflows

        balanceOf[msg.sender] -= _value;                     // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        emit Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }

    /* Allow another contract to spend some tokens in your behalf */
    /// @notice  postcondition (allowance[msg.sender ][ _spender] ==  _value  &&  success) || ( allowance[msg.sender ][ _spender] ==  __verifier_old_uint ( allowance[msg.sender ][ _spender] ) && !success )    
    /// @notice  emits  Approval  
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /* Approve and then communicate the approved contract in a single tx */
    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }

    /* A contract attempts to get the coins */
    /// @notice  postcondition ( ( balanceOf[_from] ==  __verifier_old_uint (balanceOf[_from] ) - _value  &&  _from  != _to ) ||   ( balanceOf[_from] ==  __verifier_old_uint ( balanceOf[_from] ) &&  _from== _to ) &&  success )   || !success
    /// @notice  postcondition ( ( balanceOf[_to] ==  __verifier_old_uint ( balanceOf[_to] ) + _value  &&  _from  != _to ) ||   ( balanceOf[_to] ==  __verifier_old_uint ( balanceOf[_to] ) &&  _from  ==_to ) &&  success )   || !success
    /// @notice  postcondition ( allowance[_from ][msg.sender] ==  __verifier_old_uint (allowance[_from ][msg.sender] ) - _value && success ) || ( allowance[_from ][msg.sender] ==  __verifier_old_uint (allowance[_from ][msg.sender] )  && !success ) || _from  == msg.sender
    /// @notice  postcondition  allowance[_from ][msg.sender]  <= __verifier_old_uint (allowance[_from ][msg.sender] ) ||  _from  == msg.sender
    /// @notice  emits  Transfer 
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (balanceOf[_from] < _value) revert();                 // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();  // Check for overflows
        if (_value > allowance[_from][msg.sender]) revert();   // Check allowance
        balanceOf[_from] -= _value;                          // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

   
}

/// @notice  invariant  totalSupply  ==  __verifier_sum_uint(balanceOf)
contract PYLON is owned, token {

    //Declare public contract variables

    uint256 public buyPrice=174000000000000000000;
    uint256 public sellPrice=168000000000000000000;
    string public buyLock="open";
    string public sellLock="open";
    uint8 public spread=5;
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

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    ///@notice emits ChangeOfRules
    constructor(
        uint256 initialSupply,
        string memory tokenName,
        uint8 decimalUnits,
        string memory tokenSymbol,
        uint maxPercentage,
        uint minutesForInvestment,
        address congressLeader
    ) public token (initialSupply, tokenName, decimalUnits, tokenSymbol) {
        changeInvestmentRules(maxPercentage, minutesForInvestment);
        if (congressLeader != address(0)) owner = congressLeader;

    }

    /* Send coins */
    /// @notice  postcondition ( ( balanceOf[msg.sender] ==  __verifier_old_uint (balanceOf[msg.sender] ) - _value  && msg.sender  != _to ) ||   ( balanceOf[msg.sender] ==  __verifier_old_uint ( balanceOf[msg.sender]) && msg.sender  == _to ) &&  success )   || !success
    /// @notice  postcondition ( ( balanceOf[_to] ==  __verifier_old_uint ( balanceOf[_to] ) + _value  && msg.sender  != _to ) ||   ( balanceOf[_to] ==  __verifier_old_uint ( balanceOf[_to] ) && msg.sender  == _to ) &&  success )   || !success
    /// @notice  emits  Transfer
    function transfer(address _to, uint256 _value) public {
        if (balanceOf[msg.sender] < _value) revert();           // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) revert(); // Check for overflows
        if (frozenAccount[msg.sender]) revert();                // Check if frozen
        balanceOf[msg.sender] -= _value;                     // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        emit Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
        if(msg.sender.balance<minBalanceForAccounts)
        sell((minBalanceForAccounts-msg.sender.balance)/sellPrice); // refill the balance of the sender

    }

    //Set min balance of tokens to have in account
    uint minBalanceForAccounts;

    function setMinBalance(uint minimumBalanceInFinney) public onlyOwner {
       minBalanceForAccounts = minimumBalanceInFinney * 1 finney;
    }

    /* A contract attempts to get the coins */
    /// @notice  postcondition ( ( balanceOf[_from] ==  __verifier_old_uint (balanceOf[_from] ) - _value  &&  _from  != _to ) ||   ( balanceOf[_from] ==  __verifier_old_uint ( balanceOf[_from] ) &&  _from== _to ) &&  success )   || !success
    /// @notice  postcondition ( ( balanceOf[_to] ==  __verifier_old_uint ( balanceOf[_to] ) + _value  &&  _from  != _to ) ||   ( balanceOf[_to] ==  __verifier_old_uint ( balanceOf[_to] ) &&  _from  ==_to ) &&  success )   || !success
    /// @notice  postcondition  allowance[_from ][msg.sender] ==  __verifier_old_uint (allowance[_from ][msg.sender] ) - _value  ||  _from  == msg.sender
    /// @notice  postcondition  allowance[_from ][msg.sender]  <= __verifier_old_uint (allowance[_from ][msg.sender] ) ||  _from  == msg.sender
    /// @notice  emits  Transfer 
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (frozenAccount[_from]) revert();                        // Check if frozen
        if (balanceOf[_from] < _value) revert();                 // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();  // Check for overflows
        if (_value > allowance[_from][msg.sender]) revert();   // Check allowance
        balanceOf[_from] -= _value;                          // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
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

    //set a fix spreat between sell and buy orders
    function setSpread(uint8 Spread) public onlyOwner {
        spread=Spread;
    }

    //set panic level and panic time
    function setPanic(uint8 panicLevelU, uint256 panicTimeU) public onlyOwner {
        panicLevel=panicLevelU;
        panicTime=panicTimeU;
    }

    //Declare panic mode or not
    function panic(uint256 panicWallU) public{
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
    event LogBuy(address receiver, uint amount);
    event LogTransfer(address sender, address to, uint amount);

    function status(uint256 sellAmount, uint256 buyAmount) public {

        //stablish the buy price & sell price with the spread configured in the contract
        buyPrice=(address(this).balance/totalSupply)*100000000;
        sellPrice=buyPrice+(buyPrice*spread)/100;

        //add to the panic counter the amount of sell or buy
        panicBuyCounter=panicBuyCounter+buyAmount;
        panicSellCounter=panicSellCounter+sellAmount;

        //get the block numer to compare with the last block
        uint reset=block.number;

        //compare if happends enougth time between the last and the current block with the contract configuration
        if((reset-lastBlock)>=(panicTime/15)){
        //if the time is more than the panic time we reset the counter for the next checks
        panicBuyCounter=0+buyAmount;
        panicSellCounter=0+sellAmount;
        //aisgn the new last block
        lastBlock=block.number;
        }

        //activate or desactivae panic mode
        panic(0);
    }

    /// @notice  emits  Transfer
    function buy() public payable {

        //exetute if is allowed by the contract rules
        if(keccak256(abi.encodePacked(buyLock))!=keccak256("close")){
            if (frozenAccount[msg.sender]) revert();                        // Check if frozen

            if (msg.sender.balance < msg.value) revert();                 // Check if the sender has enought eth to buy
            if (msg.sender.balance + msg.value < msg.sender.balance) revert(); //check for overflows

            uint dec=decimals;
            uint amount = msg.value * (buyPrice / (10**dec));                // calculates the amount

            if (amount <= 0) revert();  //check amount overflow
            if (balanceOf[msg.sender] + amount < balanceOf[msg.sender]) revert(); // Check for overflows
            if (balanceOf[address(this)] < amount) revert();            // checks if it has enough to sell

            balanceOf[address(this)] -= amount;                         // subtracts amount from seller's balance
            balanceOf[msg.sender] += amount;                   // adds the amount to buyer's balance

            emit Transfer(address(this), msg.sender, amount);         //send the tokens to the sendedr
            //update status variables of the contract
            status(0,msg.value);
        }else{
          revert();
        }

    }


    /// @notice  emits  LogDeposit
    function deposit() public payable returns(bool success) {
        // Check for overflows;
        if (address(this).balance + msg.value < address(this).balance) revert(); // Check for overflows

        //executes event to reflect the changes
        emit LogDeposit(msg.sender, msg.value);

        //update contract status
         status(0, msg.value);
        return true;
    }

    /// @notice  emits  LogWithdrawal
    function withdraw(uint value) public onlyOwner {

        //send eth to owner address
        msg.sender.transfer(value);

        //executes event or register the changes
        emit LogWithdrawal(msg.sender, value);
        status( value,0);

    }

    /// @notice  emits Transfer
    function sell(uint256 amount) public {

        //exetute if is allowed by the contract rules
        if(keccak256(abi.encodePacked(sellLock))!=keccak256(abi.encodePacked("close"))){

          if (frozenAccount[msg.sender]) revert();                        // Check if frozen
          if (balanceOf[address(this)] + amount < balanceOf[address(this)]) revert(); // Check for overflows
          if (balanceOf[msg.sender] < amount ) revert();        // checks if the sender has enough to sell

          balanceOf[msg.sender] -= amount;                   // subtracts the amount from seller's balance
          balanceOf[address(this)] += amount;                         // adds the amount to owner's balance
          // Sends ether to the seller. It's important
          if (!msg.sender.send(amount * sellPrice)) {
              revert();                                         // to do this last to avoid recursion attacks
          } else {
               // executes an event reflecting on the change
               emit Transfer(msg.sender, address(this), amount);
               //update contract status
               status(amount*sellPrice,0);
          }
        }else{ revert(); }
    }

    event InvestmentOfferAdded(uint proposalID, address recipient, uint amount, string description);
    event Invested(uint proposalID, address investor, string justification);
    event ChangeOfRules(uint maxPercentage, uint investmentOfferPeriodInMinutes);

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
    /// @notice  emits ChangeOfRules
    function changeInvestmentRules(
        uint maxPercentageForInvestments,
        uint minutesForInvestment
    ) public onlyOwner {
        maxPercentage = maxPercentageForInvestments;
        investmentOfferPeriodInMinutes = minutesForInvestment;

        emit ChangeOfRules(maxPercentage, investmentOfferPeriodInMinutes);
    }

    /* Function to create a new investment offer */
    /// @notice  emits InvestmentOfferAdded
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
        InvestmentOffer memory p  = investmentOffer[investmentNumber];
        return p.investmentHash == keccak256(abi.encodePacked(beneficiary, etherAmount, transactionBytecode));
    }

    /// @notice  emits Transfer
    /// @notice  emits Invested
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
        if (p.amount <= (p.currentAmount + msg.value)) revert(); // Check if the investment is more than total offer
        if (p.invested[msg.sender] == true) revert();                        // If has already invested, cancel
        p.invested[msg.sender] = true;                                      // Set this investor as having invested
        p.numberOfInvestments++;

        uint amount = msg.value * (buyPrice / (10**dec));                // calculates the amount

        if (amount <= 0) revert();  //check amount overflow
        if (balanceOf[target] + amount < balanceOf[target]) revert(); // Check for overflows
        if (address(this).balance + msg.value < address(this).balance) revert(); // Check for overflows

        p.currentAmount += msg.value;       // Increase the investment amount
        balanceOf[target] += amount;                   // Adds the amount to target balance
        totalSupply += amount;                        // Add amount to total supply

        emit Transfer(address(0), owner, amount);                   // Send tokens to contract
        emit Transfer(owner, target, amount);             // Send tokens to target address

        // Create a log of this event
        emit Invested(investmentNumber, msg.sender, justificationText);
        //update contract status
        status(0, msg.value);
        return p.numberOfInvestments;
    }

}
