// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import './Token.sol';


// MyLittleToken - currently without governance feature
contract MyLittleToken is BEP20('MyLittleToken', 'MLTKN') {
 /// @notice Creates `_amount` token to `_to`. May only be called by the owner (MasterChef).
 //seems odd that function being defined right up front
 function mint(address _to, uint256 _amount) public onlyOwner {
 _mint(_to, _amount);

 }

}