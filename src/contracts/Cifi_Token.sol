// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract Cifi_Token is ERC20, AccessControl, ERC20Burnable, Pausable {
    using SafeMath for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    /// Constant token specific fields
    uint256 public _maxSupply = 0;
    uint256 internal _totalSupply = 0;

    // address to store multiSign contract address and counter to make sure the contract address is added only once
    uint8 public AuthoriseMultiSign = 0;

    //ddress public MULTI_SIGN_WALLET;
    //event validate(address sender, address MULTI_SIGN_WALLET);

    constructor() ERC20("Ciphi", "CIFI") {
        _maxSupply = 500000 * 10**18;
        // _mint(msg.sender, 500000 * 10**18);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // _setupRole(MINTER_ROLE, msg.sender);
        // _setupRole(BURNER_ROLE, msg.sender);
    }

    // modifier validMultiSignWallet() {
    //     emit validate(msg.sender, MULTI_SIGN_WALLET);
    //     require(
    //         msg.sender == MULTI_SIGN_WALLET,
    //         " Not a valid Multi sign wallet address. "
    //     );

    //     _;
    // }

    function transferOwnership(address newOwner) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not an admin"
        );
        grantRole(DEFAULT_ADMIN_ROLE, newOwner);
        revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // function to add multiSign wallet only once by admin
    // function addMultiSigWallet(address multiSig) public {
    //     require(
    //         hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
    //         "Caller is not an admin"
    //     );
    //     require(
    //         AuthoriseMultiSign == 0,
    //         "multi sign address can be added only once"
    //     );
    //     AuthoriseMultiSign++;
    //     MULTI_SIGN_WALLET = multiSig;
    //     _setupRole(MINTER_ROLE, multiSig);
    //     _setupRole(BURNER_ROLE, multiSig);
    // }

    function burn(uint256 amount)
        public
        virtual
        override
        whenNotPaused()
    //validMultiSignWallet
    {
        require(hasRole(BURNER_ROLE, msg.sender), "Caller is not a burner");
        uint256 newBurnSupply = _totalSupply.sub(amount * 10**18);
        require(newBurnSupply >= 0, "Can't burn more!");
        _totalSupply = _totalSupply.sub(amount * 10**18);
        _burn(_msgSender(), amount * 10**18);
    }

    function mint(address account, uint256 amount)
        public
        virtual
        whenNotPaused()
    //validMultiSignWallet
    {
        require(account != address(0), "ERC20: mint to the zero address");
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a burner");
        uint256 newMintSupply = _totalSupply.add(amount * 10**18);
        require(newMintSupply <= _maxSupply, "supply is max!");
        _totalSupply = _totalSupply.add(amount * 10**18);
        _mint(account, amount * 10**18);
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        whenNotPaused()
        returns (bool)
    {
        super.transfer(recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override whenNotPaused() returns (bool) {
        super.transferFrom(sender, recipient, amount);
        return true;
    }

    function pause() public virtual whenNotPaused() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not an admin"
        );
        super._pause();
        emit Paused(_msgSender());
    }

    function unpause() internal virtual whenPaused() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not an admin"
        );
        super._unpause();
        emit Unpaused(_msgSender());
    }
}
