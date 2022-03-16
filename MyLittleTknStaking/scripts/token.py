#!/usr/bin/python3

from brownie import accounts, config, MyLittleToken


def main():
    account = accounts.add(config["wallets"]["from_key"])

    #deploy MyLittleToken BEP20 token
    mlt = MyLittleToken.deploy({"from": account}, publish_source = True)

    #deploy mock lptoken for MasterChef example
    lptkn = MyLittleTknLP.deploy({"from": account}, publish_source = True)

    #deploy MasterChef contract for MyLittleToken Staking
    mc = MltknMasterChef.deploy(mlt, account, account, 1e18, 0, {"from": account}, publish_source = True)

    #make MasterChef the owner of MyLittleToken so it can mint MLTKN as needed
    mlt.transferOwnership(mc, {"from": account})

    #mint MLTKN to MasterChef for use in harvesting reward
    mlt.mint(mc, 1e25, {"from": account})

    #mint lptkn to msg.sender to be used in MasterChef
    lptkn.mint(account, 1e23, {"from": account})

    #add pool for lptkn into MasterChef staking pools
    mc.add(100, lptkn, 10, True, {"from": account})

    #allow MasterChef to transfer lptkn into staking pool. Amount is 2e256-1 (max allowance)
    lptkn.approve(mc, 115792089237316195423570985008687907853269984665640564039457584007913129639935, {"from": account})

    #deposit lptkn into pool. Pool ID (pid) is 0 since only one pool at time of script
    mc.deposit(0, 1e19, {"from": account})

