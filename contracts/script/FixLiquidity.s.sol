// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title FixLiquidity — Step-by-step scripts to add liquidity + swap
/// @dev Run each contract separately: Step1Approve, Step2Liquidity, Step3Swap

import "forge-std/Script.sol";
import {MockToken} from "../src/MockToken.sol";
import {IPoolManager} from "@v4-core/interfaces/IPoolManager.sol";
import {PoolSwapTest} from "@v4-core/test/PoolSwapTest.sol";
import {PoolModifyLiquidityTest} from "@v4-core/test/PoolModifyLiquidityTest.sol";
import {PoolKey} from "@v4-core/types/PoolKey.sol";
import {Currency} from "@v4-core/types/Currency.sol";
import {IHooks} from "@v4-core/interfaces/IHooks.sol";
import {TickMath} from "@v4-core/libraries/TickMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Shared constants
abstract contract MonadAddresses {
    address constant POOL_MANAGER = 0x4F992a229e3eBd64AC36137fa8750c8beA64929E;
    address constant SWAP_ROUTER = 0xfd1411e2e3ddfC0C68649d3FEb1bE50C6d599EBd;
    address constant LIQUIDITY_ROUTER = 0xae160d585c48b96f248Bd6f829f4432EFf9Eb49d;
    address constant HOOK = 0xA8d4D47a7Fb423bc5c7aAfaf0E22107F9e298188;
    address constant CLAW = 0xe523fc1cc80A6EF2f643895b556cf43A1f1bCF60;
    address constant ZUG = 0xF4437552a67d5FAAdD1A06aaa6db4466eB9Fa969;

    function _poolKey() internal pure returns (PoolKey memory) {
        address token0 = CLAW < ZUG ? CLAW : ZUG;
        address token1 = CLAW < ZUG ? ZUG : CLAW;
        return PoolKey({
            currency0: Currency.wrap(token0),
            currency1: Currency.wrap(token1),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(HOOK)
        });
    }
}

/// Step 1: Approve tokens to both routers
contract Step1Approve is Script, MonadAddresses {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address token0 = CLAW < ZUG ? CLAW : ZUG;
        address token1 = CLAW < ZUG ? ZUG : CLAW;

        vm.startBroadcast(pk);
        IERC20(token0).approve(LIQUIDITY_ROUTER, type(uint256).max);
        IERC20(token1).approve(LIQUIDITY_ROUTER, type(uint256).max);
        IERC20(token0).approve(SWAP_ROUTER, type(uint256).max);
        IERC20(token1).approve(SWAP_ROUTER, type(uint256).max);
        vm.stopBroadcast();

        console.log("All approvals set");
    }
}

/// Step 2: Add liquidity to the CLAW/ZUG pool
contract Step2Liquidity is Script, MonadAddresses {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        PoolKey memory poolKey = _poolKey();

        vm.startBroadcast(pk);
        PoolModifyLiquidityTest(LIQUIDITY_ROUTER).modifyLiquidity(
            poolKey,
            IPoolManager.ModifyLiquidityParams({
                tickLower: -600,
                tickUpper: 600,
                liquidityDelta: 1_000e18,
                salt: bytes32(0)
            }),
            bytes("")
        );
        vm.stopBroadcast();

        console.log("Liquidity added (1,000e18)");
    }
}

/// Step 3: Test swap through the pool
contract Step3Swap is Script, MonadAddresses {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        PoolKey memory poolKey = _poolKey();

        vm.startBroadcast(pk);
        PoolSwapTest(SWAP_ROUTER).swap(
            poolKey,
            IPoolManager.SwapParams({
                zeroForOne: true,
                amountSpecified: -10 ether,
                sqrtPriceLimitX96: TickMath.MIN_SQRT_PRICE + 1
            }),
            PoolSwapTest.TestSettings({
                takeClaims: false,
                settleUsingBurn: false
            }),
            bytes("")
        );
        vm.stopBroadcast();

        console.log("Swap completed (10 token0 -> token1)");
    }
}
