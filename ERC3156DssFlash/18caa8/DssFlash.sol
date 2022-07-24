pragma solidity >= 0.5.0;

import "./IERC3156FlashLender.sol";
import "./IERC3156FlashBorrower.sol";
// import "./interface/IVatDaiFlashLoanReceiver.sol";
import "./VatAbstract.sol";
import "./DaiJoinAbstract.sol";
import "./DaiAbstract.sol";

// interface VatLike {
//     function dai(address) external view returns (uint256);
//     function move(address src, address dst, uint256 rad) external;
//     function heal(uint256 rad) external;
//     function suck(address,address,uint256) external;
// }

contract DssFlash  {

    // --- Auth ---
    function rely(address guy) external auth { wards[guy] = 1; emit Rely(guy); }
    function deny(address guy) external auth { wards[guy] = 0; emit Deny(guy); }
    mapping (address => uint256) public wards;
    modifier auth {
        require(wards[msg.sender] == 1, "DssFlash/not-authorized");
        _;
    }

    // --- Data ---
    VatAbstract public         vat;
    address public             vow;
    DaiJoinAbstract public     daiJoin;
    DaiAbstract public         dai;
    
    uint256 public                      line;       // Debt Ceiling  [wad]
    uint256 public                      toll;       // Fee           [wad]
    uint256 private                     locked;     // Reentrancy guard

    bytes32 public constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");
    bytes32 public constant CALLBACK_SUCCESS_VAT_DAI = keccak256("IVatDaiFlashLoanReceiver.onVatDaiFlashLoan");

    // --- Events ---
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event File(bytes32 indexed what, uint256 data);
    event File(bytes32 indexed what, address data);
    event FlashLoan(address indexed receiver, address token, uint256 amount, uint256 fee);
    event VatDaiFlashLoan(address indexed receiver, uint256 amount, uint256 fee);

    modifier lock {
        require(locked == 0, "DssFlash/reentrancy-guard");
        locked = 1;
        _;
        locked = 0;
    }

    // --- Math ---
    uint256 constant WAD = 10 ** 18;
    uint256 constant RAY = 10 ** 27;
    uint256 constant RAD = 10 ** 45;
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }
 

    // --- ERC 3156 Spec ---
    /// @notice postcondition resp == line && token == address(dai) || resp == 0
    function maxFlashLoan(address token  ) external view returns (uint256 resp) {
        if (token == address(dai) && locked == 0) {
            return line;
        } else {
            return 0;
        }
    }
    
    /// @notice postcondition token == address(dai)
    /// @notice postcondition resp == (amount * toll) / WAD
    function flashFee(  address token, uint256 amount ) external view returns (uint256 resp) {
        require(token == address(dai), "DssFlash/token-unsupported");

        return mul(amount, toll) / WAD;
    }

    /// @notice postcondition token == address(dai)
    /// @notice postcondition amount <= line
    /// @notice postcondition __verifier_old_address(token) == token
    /// @notice postcondition __verifier_old_uint(amount) == amount
    /// @notice postcondition resp
    function flashLoan(IERC3156FlashBorrower receiver,  address token, uint256 amount,  bytes calldata data
    ) external lock returns (bool resp) {
        require(token == address(dai), "DssFlash/token-unsupported");
        require(amount <= line, "DssFlash/ceiling-exceeded");

        uint256 rad = mul(amount, RAY);
        uint256 fee = mul(amount, toll) / WAD;
        uint256 total = add(amount, fee);

        vat.suck(address(this), address(this), rad);
        daiJoin.exit(address(receiver), amount);

        emit FlashLoan(address(receiver), token, amount, fee);

        require(
            receiver.onFlashLoan(msg.sender, token, amount, fee, data) == CALLBACK_SUCCESS,
            "DssFlash/callback-failed"
        );
        
        dai.transferFrom(address(receiver), address(this), total);
        daiJoin.join(address(this), total);
        vat.heal(rad);
        vat.move(address(this), vow, mul(fee, RAY));

        return true;
    }



    



  
}
