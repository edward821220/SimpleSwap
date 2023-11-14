// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ISimpleSwap} from "./interface/ISimpleSwap.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import "forge-std/console2.sol";

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

    function swap(address tokenIn, address tokenOut, uint256 amountIn) external returns (uint256) {
        require(tokenIn == tokenA || tokenIn == tokenB, "SimpleSwap: INVALID_TOKEN_IN");
        require(tokenOut == tokenA || tokenOut == tokenB, "SimpleSwap: INVALID_TOKEN_OUT");
        require(tokenIn != tokenOut, "SimpleSwap: IDENTICAL_ADDRESS");
        require(amountIn > 0, "SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");
        uint256 amountOut = amountIn / 2;
        if (amountOut > balanceOf(address(this))) {
            amountOut = balanceOf(address(this));
        }
        ERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        ERC20(tokenOut).transfer(msg.sender, amountOut);
        emit Swap(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
        return amountOut;
    }

    function addLiquidity(uint256 amountAIn, uint256 amountBIn) external returns (uint256, uint256, uint256) {
        require(amountAIn > 0 && amountBIn > 0, "SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");
        uint256 amountA;
        uint256 amountB;
        uint256 liquidity;
        (uint256 reserveA, uint256 reserveB) = this.getReserves();
        // 如果是第一次添加流動性就直接用 amountIn 的量
        if (totalSupply() == 0) {
            amountA = amountAIn;
            amountB = amountBIn;
            liquidity = Math.sqrt(amountA * amountB);
        } else {
            if (amountAIn * reserveB == reserveA * amountBIn) {
                amountA = amountAIn;
                amountB = amountBIn;
            } else if (amountAIn * reserveB < reserveA * amountBIn) {
                amountA = amountAIn;
                amountB = amountAIn * reserveB / reserveA;
            } else if (amountAIn * reserveB > reserveA * amountBIn) {
                amountA = amountBIn * reserveA / reserveB;
                amountB = amountBIn;
            }
            uint256 liquidityA = (amountAIn * totalSupply()) / reserveA;
            uint256 liquidityB = (amountBIn * totalSupply()) / reserveB;
            liquidity = (liquidityA < liquidityB) ? liquidityA : liquidityB;
        }
        ERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        ERC20(tokenB).transferFrom(msg.sender, address(this), amountB);
        _mint(msg.sender, liquidity);
        emit AddLiquidity(msg.sender, amountA, amountB, liquidity);

        return (amountAIn, amountBIn, liquidity);
    }

    function removeLiquidity(uint256 liquidity) external returns (uint256 amountA, uint256 amountB) {
        require(liquidity > 0, "SimpleSwap: INSUFFICIENT_LIQUIDITY_BURNED");
        (uint256 reserveA, uint256 reserveB) = this.getReserves();
        amountA = reserveA * liquidity / totalSupply();
        amountB = reserveB * liquidity / totalSupply();
        ERC20(tokenA).transfer(msg.sender, amountA);
        ERC20(tokenB).transfer(msg.sender, amountB);

        this.transferFrom(msg.sender, address(this), liquidity);
        _burn(address(this), liquidity);
        emit RemoveLiquidity(msg.sender, liquidity, amountA, amountB);
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
