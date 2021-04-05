// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


contract Cifi_Token is ERC20,AccessControl,ERC20Burnable,Pausable{


  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

  constructor() public ERC20("Citizen.Finance:Ciphi", "CIFI") {
    _mint(msg.sender, 500000 * 10**18);
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(MINTER_ROLE, msg.sender);
    _setupRole(BURNER_ROLE, msg.sender);
  }
  
  
  
  function burn(uint256 amount) whenNotPaused() public override virtual {
        require(hasRole(BURNER_ROLE, msg.sender), "Caller is not a burner");
        _burn(_msgSender(), amount);
    }
    
    function mint(address account, uint256 amount) whenNotPaused() public virtual {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a burner");
        _mint(account,amount);
    }
    
    
    function transfer(address recipient, uint256 amount) whenNotPaused() public virtual override returns (bool) {
        super.transfer(recipient,amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) whenNotPaused() public virtual override returns (bool) {
        super.transferFrom(sender,recipient,amount);
        return true;
    }
    
    function pause() whenNotPaused() public virtual  {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
        super._pause();
        emit Paused(_msgSender());
    }
    
    function unpause() whenPaused() internal virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
        super._unpause();
        emit Unpaused(_msgSender());
    }
}


