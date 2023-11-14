// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ISimpleSwap} from "./interface/ISimpleSwap.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SimpleSwap is ISimpleSwap, ERC20 {
    // Implement core logic here
    address public tokenA;
    address public tokenB;

    constructor(address tokenA_, address tokenB_) ERC20("LiquidityProvider", "LP") {
        require(tokenA_.code.length > 0, "SimpleSwap: TOKENA_IS_NOT_CONTRACT");
        require(tokenB_.code.length > 0, "SimpleSwap: TOKENB_IS_NOT_CONTRACT");
        require(tokenA_ != tokenB_, "SimpleSwap: TOKENA_TOKENB_IDENTICAL_ADDRESS");
        if (tokenA_ < tokenB_) {
            tokenA = tokenA_;
            tokenB = tokenB_;
        } else {
            tokenA = tokenB_;
            tokenB = tokenA_;
        }
    }

    function swap(address tokenIn, address tokenOut, uint256 amountIn) external returns (uint256 amountOut) {
        require(tokenIn == tokenA || tokenIn == tokenB, "SimpleSwap: INVALID_TOKEN_IN");
        require(tokenOut == tokenA || tokenOut == tokenB, "SimpleSwap: INVALID_TOKEN_OUT");
        require(tokenIn != tokenOut, "SimpleSwap: IDENTICAL_ADDRESS");
        require(amountIn > 0, "SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");

        amountOut = amountIn / 2;

        ERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        ERC20(tokenOut).transfer(msg.sender, amountOut);
        emit Swap(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
    }

    function addLiquidity(uint256 amountAIn, uint256 amountBIn)
        external
        returns (uint256 amountA, uint256 amountB, uint256 liquidity)
    {
        ERC20(tokenA).transferFrom(msg.sender, address(this), amountAIn);
        ERC20(tokenB).transferFrom(msg.sender, address(this), amountBIn);
        return (amountAIn, amountBIn, 0);
    }

    function removeLiquidity(uint256 liquidity) external returns (uint256 amountA, uint256 amountB) {
        return (0, 0);
    }

    function getReserves() external view returns (uint256 reserveA, uint256 reserveB) {
        reserveA = ERC20(tokenA).balanceOf(address(this));
        reserveB = ERC20(tokenB).balanceOf(address(this));
    }

    function getTokenA() external view returns (address) {
        return tokenA;
    }

    function getTokenB() external view returns (address) {
        return tokenB;
    }
}
