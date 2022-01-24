/// @title DigixDAO Contract Interfaces

contract ConfigInterface {
  address public owner;
  mapping (address => bool) admins;
  mapping (bytes32 => address) addressMap;
  mapping (bytes32 => bool) boolMap;
  mapping (bytes32 => bytes32) bytesMap;
  mapping (bytes32 => uint256) uintMap;

  /// @notice setConfigAddress sets configuration `_key` to `_val` 
  /// @param _key The key name of the configuration.
  /// @param _val The value of the configuration.
  /// @return Whether the configuration setting was successful or not.
  function setConfigAddress(bytes32 _key, address _val) public returns (bool success);

  /// @notice setConfigBool sets configuration `_key` to `_val` 
  /// @param _key The key name of the configuration.
  /// @param _val The value of the configuration.
  /// @return Whether the configuration setting was successful or not.
  function setConfigBool(bytes32 _key, bool _val) public returns (bool success);

  /// @notice setConfigBytes sets configuration `_key` to `_val`
  /// @param _key The key name of the configuration.
  /// @param _val The value of the configuration.
  /// @return Whether the configuration setting was successful or not.
  function setConfigBytes(bytes32 _key, bytes32 _val) public returns (bool success);

  /// @notice setConfigUint `_key` to `_val`
  /// @param _key The key name of the configuration.
  /// @param _val The value of the configuration.
  /// @return Whether the configuration setting was successful or not.
  function setConfigUint(bytes32 _key, uint256 _val) public returns (bool success);

  /// @notice getConfigAddress gets configuration `_key`'s value
  /// @param _key The key name of the configuration.
  /// @return The configuration value 
  function getConfigAddress(bytes32 _key) public returns (address val);

  /// @notice getConfigBool gets configuration `_key`'s value
  /// @param _key The key name of the configuration.
  /// @return The configuration value 
  function getConfigBool(bytes32 _key) public returns (bool val);

  /// @notice getConfigBytes gets configuration `_key`'s value
  /// @param _key The key name of the configuration.
  /// @return The configuration value 
  function getConfigBytes(bytes32 _key) public returns (bytes32 val);

  /// @notice getConfigUint gets configuration `_key`'s value
  /// @param _key The key name of the configuration.
  /// @return The configuration value 
  function getConfigUint(bytes32 _key) public returns (uint256 val);

  /// @notice addAdmin sets `_admin` as configuration admin
  /// @return Whether the configuration setting was successful or not.  
  function addAdmin(address _admin) public returns (bool success);

  /// @notice removeAdmin removes  `_admin`'s rights
  /// @param _admin The key name of the configuration.
  /// @return Whether the configuration setting was successful or not.  
  function removeAdmin(address _admin) public returns (bool success);

}

contract TokenInterface {

  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;
  mapping (address => bool) seller;

  address config;
  address owner;
  address dao;
  address public badgeLedger;
  bool locked;

  /// @return total amount of tokens
  uint256 public totalSupply;

  /// @param _owner The address from which the balance will be retrieved
  /// @return The balance
  function balanceOf(address _owner) public returns (uint256 balance);

  /// @notice send `_value` tokens to `_to` from `msg.sender`
  /// @param _to The address of the recipient
  /// @param _value The amount of tokens to be transfered
  /// @return Whether the transfer was successful or not
  function transfer(address _to, uint256 _value) public returns (bool success);

  /// @notice send `_value` tokens to `_to` from `_from` on the condition it is approved by `_from`
  /// @param _from The address of the sender
  /// @param _to The address of the recipient
  /// @param _value The amount of tokens to be transfered
  /// @return Whether the transfer was successful or not
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

  /// @notice `msg.sender` approves `_spender` to spend `_value` tokens on its behalf
  /// @param _spender The address of the account able to transfer the tokens
  /// @param _value The amount of tokens to be approved for transfer
  /// @return Whether the approval was successful or not
  function approve(address _spender, uint256 _value) public returns (bool success);

  /// @param _owner The address of the account owning tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @return Amount of remaining tokens of _owner that _spender is allowed to spend
  function allowance(address _owner, address _spender) public returns (uint256 remaining);

  /// @notice mint `_amount` of tokens to `_owner`
  /// @param _owner The address of the account receiving the tokens
  /// @param _amount The amount of tokens to mint
  /// @return Whether or not minting was successful
  function mint(address _owner, uint256 _amount) public returns (bool success);

  /// @notice mintBadge Mint `_amount` badges to `_owner`
  /// @param _owner The address of the account receiving the tokens
  /// @param _amount The amount of tokens to mint
  /// @return Whether or not minting was successful
  function mintBadge(address _owner, uint256 _amount) public returns (bool success);

  function registerDao(address _dao) public returns (bool success);
  function registerSeller(address _tokensales) public returns (bool success);

  event Transfer(address indexed _from, address indexed _to, uint256 indexed _value);
  event Mint(address indexed _recipient, uint256 indexed _amount);
  event Approval(address indexed _owner, address indexed _spender, uint256 indexed _value);
}

contract TokenSalesInterface {

  struct SaleProxy {
    address payout;
    bool isProxy;
  }

  struct SaleStatus {
    bool founderClaim;
    uint256 releasedTokens;
    uint256 releasedBadges;
    uint256 claimers;
  }

  struct Info {
    uint256 totalWei;
    uint256 totalCents;
    uint256 realCents;
    uint256 amount;
  }

  struct SaleConfig {
    uint256 startDate;
    uint256 periodTwo;
    uint256 periodThree;
    uint256 endDate;
    uint256 goal;
    uint256 cap;
    uint256 badgeCost;
    uint256 founderAmount;
    address founderWallet;
  }

  struct Buyer {
    uint256 centsTotal;
    uint256 weiTotal;
    bool claimed;
  }

  Info saleInfo;
  SaleConfig saleConfig;
  SaleStatus saleStatus;

  address config;
  address owner;
  bool locked;

  uint256 public ethToCents;

  mapping (address => Buyer) buyers;
  mapping (address => SaleProxy) proxies;

  /// @notice Calculates the parts per billion 1⁄1,000,000,000 of `_a` to `_b`
  /// @param _a The antecedent
  /// @param _c The consequent
  /// @return Part per billion value
  function ppb(uint256 _a, uint256 _c) public  returns (uint256 b);


  /// @notice Calculates the share from `_total` based on `_contrib` 
  /// @param _contrib The contributed amount in USD
  /// @param _total The total amount raised in USD
  /// @return Total number of shares
  function calcShare(uint256 _contrib, uint256 _total) public  returns (uint256 share);

  /// @notice Calculates the current USD cents value of `_wei` 
  /// @param _wei the amount of wei
  /// @return The USD cents value
  function weiToCents(uint256 _wei) public  returns (uint256 centsvalue);

  function proxyPurchase(address _user) public returns (bool success);

  /// @notice Send msg.value purchase for _user.  
  /// @param _user The account to be credited
  /// @return Success if purchase was accepted
  function purchase(address _user, uint256 _amount) private returns (bool success);

  /// @notice Get crowdsale information for `_user`
  /// @param _user The account to be queried
  /// @return `centstotal` the total amount of USD cents contributed
  /// @return `weitotal` the total amount in wei contributed
  /// @return `share` the current token shares earned
  /// @return `badges` the number of proposer badges earned
  /// @return `claimed` is true if the tokens and badges have been claimed
  function userInfo(address _user) public  returns (uint256 centstotal, uint256 weitotal, uint256 share, uint badges, bool claimed); 

  /// @notice Get the crowdsale information from msg.sender (see userInfo)
  function myInfo() public  returns (uint256 centstotal, uint256 weitotal, uint256 share, uint badges, bool claimed); 

  /// @notice get the total amount of wei raised for the crowdsale
  /// @return The amount of wei raised
  function totalWei() public  returns (uint);

  /// @notice get the total USD value in cents raised for the crowdsale
  /// @return the amount USD cents
  function totalCents() public  returns (uint);

  /// @notice get the current crowdsale information
  /// @return `startsale` The unix timestamp for the start of the crowdsale and the first period modifier
  /// @return `two` The unix timestamp for the start of the second period modifier
  /// @return `three` The unix timestamp for the start of the third period modifier
  /// @return `endsale` The unix timestamp of the end of crowdsale
  /// @return `totalwei` The total amount of wei raised
  /// @return `totalcents` The total number of USD cents raised
  /// @return `amount` The amount of DGD tokens available for the crowdsale
  /// @return `goal` The USD value goal for the crowdsale
  /// @return `famount` Founders endowment
  /// @return `faddress` Founder wallet address
  /*function getSaleInfo() public  returns (uint256 startsale, uint256 two, uint256 three, uint256 endsale, uint256 totalwei, uint256 totalcents, uint256 amount, uint256 goal, uint256 famount, address faddress);*/

  function claimFor(address _user) public returns (bool success); 

  /// @notice Allows msg.sender to claim the DGD tokens and badges if the goal is reached or refunds the ETH contributed if goal is not reached at the end of the crowdsale
  function claim() public returns (bool success);

  function claimFounders() public returns (bool success);

  /// @notice See if the crowdsale goal has been reached
  function goalReached() public  returns (bool reached);

  /// @notice Get the current sale period
  /// @return `saleperiod` 0 = Outside of the crowdsale period, 1 = First reward period, 2 = Second reward period, 3 = Final crowdsale period.
  function getPeriod() public  returns (uint saleperiod);

  /// @notice Get the date for the start of the crowdsale
  /// @return `date` The unix timestamp for the start
  function startDate() public  returns (uint date);
  
  /// @notice Get the date for the second reward period of the crowdsale
  /// @return `date` The unix timestamp for the second period
  function periodTwo() public  returns (uint date);

  /// @notice Get the date for the final period of the crowdsale
  /// @return `date` The unix timestamp for the final period
  function periodThree() public  returns (uint date);

  /// @notice Get the date for the end of the crowdsale
  /// @return `date` The unix timestamp for the end of the crowdsale
  function endDate() public  returns (uint date);

  /// @notice Check if crowdsale has ended
  /// @return `ended` If the crowdsale has ended
  
  function isEnded() public  returns (bool ended);

  /// @notice Send raised funds from the crowdsale to the DAO
  /// @return `success` if the send succeeded
  function sendFunds() public returns (bool success);

  //function regProxy(address _payment, address _payout) returns (bool success);
  function regProxy(address _payout) public returns (bool success);

  function getProxy(address _payout) public returns (address proxy);
  
  function getPayout(address _proxy) public returns (address payout, bool isproxy);

  function unlock() public returns (bool success);

  function getSaleStatus() public  returns (bool fclaim, uint256 reltokens, uint256 relbadges, uint256 claimers);

  function getSaleInfo() public  returns (uint256 weiamount, uint256 cents, uint256 realcents, uint256 amount);

  function getSaleConfig() public  returns (uint256 start, uint256 two, uint256 three, uint256 end, uint256 goal, uint256 cap, uint256 badgecost, uint256 famount, address fwallet);
  
  event Purchase(uint256 indexed _exchange, uint256 indexed _rate, uint256 indexed _cents);
  event Claim(address indexed _user, uint256 indexed _amount, uint256 indexed _badges);

}




