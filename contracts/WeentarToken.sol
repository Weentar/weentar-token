pragma solidity 0.8.1;

import "./BEP20.sol";

contract WeentarToken is BEP20 {

    constructor(uint256 initalSupply) BEP20("Weentar Token", "WTR", 18) {
        _mint(owner(), initalSupply);
    }

}