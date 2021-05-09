// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract Cifi_Token is ERC20, AccessControl, ERC20Burnable, Pausable {
    using SafeMath for uint256;

    uint256 internal  _maxAmountMintable = 500_000e18;


    constructor() ERC20("citizen finance", "CIFI") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier onlyAdminRole() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "!admin"
        );
        _;
    }

    function transferOwnership(address newOwner) public onlyAdminRole {
        revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(DEFAULT_ADMIN_ROLE, newOwner);
    }

    function burn(address _account, uint256 _amount) public onlyAdminRole {
        _maxAmountMintable = _maxAmountMintable.sub(_amount);
        super._burn(_account, _amount);
    }

    function mint(address _to, uint256 _amount) public onlyAdminRole whenNotPaused {
        require(ERC20.totalSupply().add(_amount) <= _maxAmountMintable, "Max mintable exceeded");
        super._mint(_to, _amount);
    }

    function pause() external onlyAdminRole {
        super._pause();
    }

    function unpause() external onlyAdminRole {
        super._unpause();
    }
}
