// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import './Token.sol';


// Example of an LP pair token used in MasterChef
contract MyLittleTknLP is BEP20('MyLittleTkn-LP', 'MLTKN-LP') {
 /// @notice Creates `_amount` token to `_to`. May only be called by the owner (MasterChef).
 function mint(address _to, uint256 _amount) public onlyOwner {
 _mint(_to, _amount);

 }

}