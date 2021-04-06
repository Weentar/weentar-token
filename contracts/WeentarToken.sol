pragma solidity 0.8.1;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";

contract WeentarToken is ERC20, Ownable {

    constructor( uint256 maxSupply) ERC20("Weentar Token", "$WNTR") {
        _mint(owner(), maxSupply);
    }

    function getOwner() public view returns (address){
        return owner();
    }

}