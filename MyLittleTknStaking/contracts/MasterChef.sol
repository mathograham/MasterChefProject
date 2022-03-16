// SPDX-License-Identifier: GPL-3.0-or-later Or MIT




pragma solidity 0.6.12;


import './SafeMath.sol';
import './EverthingElse.sol';
import './SafeBEP20.sol';
import './MyLittleTkn.sol';





// MasterChef is the master of MyLittleToken. She can make MLTKN and she is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be relinquished eventually, in some kinda way.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MltknMasterChef is Ownable {
 using SafeMath for uint256;
 using SafeBEP20 for IBEP20;

 // Information for each user, including amount of LP tokens and
 struct UserInfo {
 uint256 amount; // How many LP tokens the user has provided.
 uint256 excludedReward; // Reward debt. See explanation below.
 //
 // We do some fancy math here. Basically, at any point in time, the amount of MLTKNs
 // entitled to a user but is pending to be distributed is:
 //
 // pending reward = (user.amount * pool.accMltknPerShare) - user.excludedReward
 // 
 // where user.excludedReward is the portion of accMltknPerShare that the user is not privvy to
 // because it was accumulated before the user entered the pool.
 // This is explained further in the deposit function section. 
 //
 // Whenever a user deposits or withdraws LP tokens to a pool, here's what happens:
 // 1. The pool's `accMltknPerShare` (and `lastRewardBlock`) gets updated.
 // 2. User receives the pending reward sent to his/her address.
 // 3. User's `amount` gets updated.
 // 4. User's `excludedReward` gets updated.
 }

 // Info of each pool.
 struct PoolInfo {
 IBEP20 lpToken; // Address of LP token contract.
 uint256 allocPoint; // How many allocation points assigned to this pool. Used to determine percent MLTKNs to send per block
 uint256 lastRewardBlock; // Last block number of MLTKN distribution.
 uint256 accMltknPerShare; // Total Accumulated MLTKNs per share in pool, times 1e12. See below.
 uint16 depositFeeBP; // Deposit fee in basis points
 }

 // The MLTKN TOKEN! Was: spirit. Update all after get rid of most 'spirit' words
 MyLittleToken public mltkn;
 // Dev address.
 address public devaddr;
 // MLTKNs tokens created per block.
 uint256 public mltknPerBlock;
 // Bonus muliplier for early mltkn makers.
 uint256 public constant BONUS_MULTIPLIER = 1;
 // Deposit Fee address
 address public feeAddress;

 // Info of each pool.
 PoolInfo[] public poolInfo;
 // Info of each user that stakes LP tokens. userInfo[which LP][which user]
 mapping (uint256 => mapping (address => UserInfo)) public userInfo;
 // Total allocation points. Must be the sum of all allocation points in all pools.
 uint256 public totalAllocPoint = 0;
 // The block number when mltkn mining starts.
 uint256 public startBlock;

 event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
 event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
 event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

 constructor(
 MyLittleToken _mltkn,
 address _devaddr,
 address _feeAddress,
 uint256 _mltknPerBlock,
 uint256 _startBlock
 ) public {
 mltkn = _mltkn;
 devaddr = _devaddr;
 feeAddress = _feeAddress;
 mltknPerBlock = _mltknPerBlock;
 startBlock = _startBlock;
 }

 // total number of pools in staking contract
 function poolLength() external view returns (uint256) {
 return poolInfo.length;
 }



 // Add a new lp to the pool. Can only be called by the owner.
 // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do. 

 function add(uint256 _allocPoint, IBEP20 _lpToken, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner {
 require(_depositFeeBP <= 10000, "add: invalid deposit fee basis points");
 if (_withUpdate) {
 massUpdatePools();
 }
 uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
 totalAllocPoint = totalAllocPoint.add(_allocPoint);
 poolInfo.push(PoolInfo({
 lpToken: _lpToken,
 allocPoint: _allocPoint,
 lastRewardBlock: lastRewardBlock,
 accMltknPerShare: 0,
 depositFeeBP: _depositFeeBP
 }));
 }



 // Update the given pool's MLTkn allocation point and deposit fee. Can only be called by the owner.
 function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner {
 require(_depositFeeBP <= 10000, "set: invalid deposit fee basis points");
 if (_withUpdate) {
 massUpdatePools();
 }
 totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
 poolInfo[_pid].allocPoint = _allocPoint;
 poolInfo[_pid].depositFeeBP = _depositFeeBP;
 }

 // Return reward multiplier over the given _from to _to block.
 function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
 return _to.sub(_from).mul(BONUS_MULTIPLIER);
 }

 // View function to see pending MLTkns on frontend.
 function pendingMltkn(uint256 _pid, address _user) external view returns (uint256) {
 PoolInfo storage pool = poolInfo[_pid];
 UserInfo storage user = userInfo[_pid][_user];
 uint256 accMltknPerShare = pool.accMltknPerShare;
 uint256 lpSupply = pool.lpToken.balanceOf(address(this));
 if (block.number > pool.lastRewardBlock && lpSupply != 0) {
 uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
 uint256 mltknReward = multiplier.mul(mltknPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
 accMltknPerShare = accMltknPerShare.add(mltknReward.mul(1e12).div(lpSupply));
 }
 return user.amount.mul(accMltknPerShare).div(1e12).sub(user.excludedReward);
 }

 // Update reward variables for all pools. Be careful of gas spending!
 function massUpdatePools() public {
 uint256 length = poolInfo.length;
 for (uint256 pid = 0; pid < length; ++pid) {
 updatePool(pid);
 }
 }

 // Update reward variables of the given pool to be up-to-date.
 function updatePool(uint256 _pid) public {
 PoolInfo storage pool = poolInfo[_pid];
 if (block.number <= pool.lastRewardBlock) {
 return;
 }
 uint256 lpSupply = pool.lpToken.balanceOf(address(this));
 if (lpSupply == 0 || pool.allocPoint == 0) {
 pool.lastRewardBlock = block.number;
 return;
 }
 uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
 uint256 mltknReward = multiplier.mul(mltknPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
 mltkn.mint(devaddr, mltknReward.div(10));
 mltkn.mint(address(this), mltknReward);
 pool.accMltknPerShare = pool.accMltknPerShare.add(mltknReward.mul(1e12).div(lpSupply));
 pool.lastRewardBlock = block.number;
 }

 // Deposit LP tokens to MasterChef for MLTKN allocation.
 // When a user deposits, first pool is updated and pending
 // rewards are transferred since previous rates should not be applied
 // to newly deposited amount
 function deposit(uint256 _pid, uint256 _amount) public {
 PoolInfo storage pool = poolInfo[_pid];
 UserInfo storage user = userInfo[_pid][msg.sender];
 updatePool(_pid);
 if (user.amount > 0) {
 uint256 pending = user.amount.mul(pool.accMltknPerShare).div(1e12).sub(user.excludedReward);
 if(pending > 0) {
 safeMltknTransfer(msg.sender, pending);
 }
 }
 if(_amount > 0) {
 pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
 if(pool.depositFeeBP > 0){
 uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
 pool.lpToken.safeTransfer(feeAddress, depositFee);
 user.amount = user.amount.add(_amount).sub(depositFee);
 }else{
 user.amount = user.amount.add(_amount);
 }
 }
 //at time of deposit, record accMltknPerShare so can be subtracted away from rewards later
 user.excludedReward = user.amount.mul(pool.accMltknPerShare).div(1e12);
 emit Deposit(msg.sender, _pid, _amount);
 }

 // Withdraw LP tokens from MasterChef.
 function withdraw(uint256 _pid, uint256 _amount) public {
 PoolInfo storage pool = poolInfo[_pid];
 UserInfo storage user = userInfo[_pid][msg.sender];
 require(user.amount >= _amount, "withdraw: withdrawal amount cannot exceed user pool balance");
 updatePool(_pid);
 uint256 pending = user.amount.mul(pool.accMltknPerShare).div(1e12).sub(user.excludedReward);
 if(pending > 0) {
 safeMltknTransfer(msg.sender, pending);
 }
 if(_amount > 0) {
 user.amount = user.amount.sub(_amount);
 pool.lpToken.safeTransfer(address(msg.sender), _amount);
 }
 user.excludedReward= user.amount.mul(pool.accMltknPerShare).div(1e12);
 emit Withdraw(msg.sender, _pid, _amount);
 }

 // Withdraw without caring about rewards. EMERGENCY ONLY.
 function emergencyWithdraw(uint256 _pid) public {
 PoolInfo storage pool = poolInfo[_pid];
 UserInfo storage user = userInfo[_pid][msg.sender];
 uint256 amount = user.amount;
 user.amount = 0;
 user.excludedReward = 0;
 pool.lpToken.safeTransfer(address(msg.sender), amount);
 emit EmergencyWithdraw(msg.sender, _pid, amount);
 }

 // Safe MLTKN transfer function, just in case if rounding error causes pool to not have enough MLTKNs.
 function safeMltknTransfer(address _to, uint256 _amount) internal {
 uint256 mltknBal = mltkn.balanceOf(address(this));
 if (_amount > mltknBal) {
 mltkn.transfer(_to, mltknBal);
 } else {
 mltkn.transfer(_to, _amount);
 }
 }

 // Update dev address by the previous dev.
 function dev(address _devaddr) public {
 require(msg.sender == devaddr, "dev: wut?");
 devaddr = _devaddr;
 }

 function setFeeAddress(address _feeAddress) public{
 require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
 feeAddress = _feeAddress;
 }

 //Pancake has to add hidden dummy pools inorder to alter the emission, here we make it simple and transparent to all.
 function updateEmissionRate(uint256 _mltknPerBlock) public onlyOwner {
 massUpdatePools();
 mltknPerBlock = _mltknPerBlock;
 }
}