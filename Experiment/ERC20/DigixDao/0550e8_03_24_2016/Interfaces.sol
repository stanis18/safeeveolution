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
  function getConfigAddress(bytes32 _key) public  returns (address val);

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

  struct User {
    bool locked;
    uint256 balance;
    uint256 badges;
    mapping (address => uint256) allowed;
  }

  mapping (address => User) users;
  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;
  mapping (address => bool) seller;

  address config;
  address owner;

  /// @return total amount of tokens
  uint256 public totalSupply;
  uint256 public totalBadges;

  /// @param _owner The address from which the balance will be retrieved
  /// @return The balance
  function balanceOf(address _owner) public returns (uint256 balance);

  /// @param _owner The address from which the badge count will be retrieved
  /// @return The badges count
  function badgesOf(address _owner) public returns (uint256 badge);

  /// @notice send `_value` tokens to `_to` from `msg.sender`
  /// @param _to The address of the recipient
  /// @param _value The amount of tokens to be transfered
  /// @return Whether the transfer was successful or not
  function transfer(address _to, uint256 _value) public returns (bool success);

  /// @notice send `_value` badges to `_to` from `msg.sender`
  /// @param _to The address of the recipient
  /// @param _value The amount of tokens to be transfered
  /// @return Whether the transfer was successful or not
  function sendBadge(address _to, uint256 _value) public returns (bool success);

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

  
  event SendBadge(address indexed _from, address indexed _to, uint256 _amount);

}

contract TokenSalesInterface {

  struct Info {
    uint256 startDate;
    uint256 periodTwo;
    uint256 periodThree;
    uint256 endDate;
    uint256 totalWei;
    uint256 totalCents;
    uint256 amount;
    uint256 goal;
  }

  struct Buyer {
    uint256 centsTotal;
    uint256 weiTotal;
    bool claimed;
  }

  Info saleInfo;

  address config;
  address owner;

  uint256 public ethToCents;

  mapping (address => Buyer) buyers;

  /// @notice Calculates the parts per billion 1⁄1,000,000,000 of `_a` to `_b`
  /// @param _a The antecedent
  /// @param _c The consequent
  /// @return Part per billion value
  function ppb(uint256 _a, uint256 _c) public  returns (uint256 b);

  function calcShare(uint256 _contrib, uint256 _total) public  returns (uint256 share);

  function weiToCents(uint256 _wei) public  returns (uint256 centsvalue);

  function purchase(address _user) public returns (bool success);

  function userInfo(address _user) public  returns (uint256 centstotal, uint256 weitotal, uint256 share, uint badges, bool claimed); 

  function myInfo() public  returns (uint256 centstotal, uint256 weitotal, uint256 share, uint badges, bool claimed); 

  function totalWei() public  returns (uint);

  function totalCents() public  returns (uint);

  function getSaleInfo() public  returns (uint256 startsale, uint256 two, uint256 three, uint256 endsale, uint256 totalwei, uint256 totalcents, uint256 amount, uint256 goal);

  function claim() public returns (bool success);

  function goalReached() public  returns (bool reached);

  function getPeriod() public  returns (uint saleperiod);

  function startDate() public  returns (uint date);
  
  function periodTwo() public  returns (uint date);

  function periodThree() public  returns (uint date);

  function endDate() public  returns (uint date);

  event Purchase(uint256 indexed _exchange, uint256 indexed _rate, uint256 indexed _cents);
  event Claim(address indexed _user, uint256 indexed _amount);

}

contract DAOInterface {

}


