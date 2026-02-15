// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title DeployMonad
/// @notice Deploys the full ClawBack P2P system on Monad Testnet from scratch
/// @dev Deploys: PoolManager, helpers, mock tokens, hook (CREATE2), initializes pool
///
/// DEPLOY COMMAND (Monad requires --legacy gas + high gas limit):
///   forge script script/DeployMonad.s.sol --tc DeployMonad --rpc-url monad_testnet --broadcast --slow --legacy --gas-limit 1000000 -vvv
///
/// After deploy, run FixLiquidity.s.sol steps separately:
///   forge script script/FixLiquidity.s.sol --tc Step1Approve --rpc-url monad_testnet --broadcast --slow --legacy -vvv
///   cast send <LIQUIDITY_ROUTER> "modifyLiquidity(...)" ... --legacy --gas-limit 1000000
///   cast send <SWAP_ROUTER> "swap(...)" ... --legacy --gas-limit 1000000

import "forge-std/Script.sol";
import {Claw2ClawHook} from "../src/Claw2ClawHook.sol";
import {MockToken} from "../src/MockToken.sol";
import {PoolManager} from "@v4-core/PoolManager.sol";
import {IPoolManager} from "@v4-core/interfaces/IPoolManager.sol";
import {PoolSwapTest} from "@v4-core/test/PoolSwapTest.sol";
import {PoolModifyLiquidityTest} from "@v4-core/test/PoolModifyLiquidityTest.sol";
import {PoolKey} from "@v4-core/types/PoolKey.sol";
import {Currency} from "@v4-core/types/Currency.sol";
import {IHooks} from "@v4-core/interfaces/IHooks.sol";
import {TickMath} from "@v4-core/libraries/TickMath.sol";

/// @dev Minimal CREATE2 deployer proxy
contract Create2Deployer {
    function deploy(bytes memory code, bytes32 salt) external returns (address addr) {
        assembly {
            addr := create2(0, add(code, 0x20), mload(code), salt)
        }
        require(addr != address(0), "CREATE2 failed");
    }
}

contract DeployMonad is Script {
    uint160 constant FLAG_MASK = 0x3FFF;
    // Uniswap v4 hook flag bits (from Hooks.sol):
    //   BEFORE_SWAP       = 1 << 7  = 0x0080
    //   AFTER_SWAP        = 1 << 6  = 0x0040
    //   BEFORE_SWAP_RETURNS_DELTA = 1 << 3 = 0x0008
    uint160 constant REQUIRED_FLAGS_VAL = 0x00C8; // 0x0080 | 0x0040 | 0x0008

    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);

        console.log("=== ClawBack Monad Testnet Deployment ===");
        console.log("Deployer:", deployer);

        vm.startBroadcast(deployerKey);

        // --- 1. Deploy Uniswap v4 PoolManager ---
        PoolManager poolManager = new PoolManager(deployer);
        console.log("PoolManager:", address(poolManager));

        // --- 2. Deploy test helper routers ---
        PoolSwapTest swapRouter = new PoolSwapTest(IPoolManager(address(poolManager)));
        console.log("PoolSwapTest (SWAP_ROUTER):", address(swapRouter));

        PoolModifyLiquidityTest liquidityRouter = new PoolModifyLiquidityTest(IPoolManager(address(poolManager)));
        console.log("PoolModifyLiquidityTest:", address(liquidityRouter));

        // --- 3. Deploy Mock Tokens ---
        MockToken claw = new MockToken("Claw Token", "CLAW", 18);
        console.log("CLAW Token:", address(claw));

        MockToken zug = new MockToken("Zug Gold", "ZUG", 18);
        console.log("ZUG Token:", address(zug));

        // Mint tokens for testing
        claw.mint(deployer, 1_000_000 ether);
        zug.mint(deployer, 1_000_000 ether);

        // --- 4. Deploy CREATE2 factory + mine salt + deploy hook ---
        Create2Deployer factory = new Create2Deployer();
        console.log("CREATE2 Factory:", address(factory));

        bytes memory creationCode = abi.encodePacked(
            type(Claw2ClawHook).creationCode,
            abi.encode(deployer, address(poolManager))
        );
        bytes32 initCodeHash = keccak256(creationCode);

        // Mine salt for correct hook flag bits
        bytes32 salt;
        bool found;
        for (uint256 i = 0; i < 500_000; i++) {
            address predicted = address(uint160(uint256(keccak256(abi.encodePacked(
                bytes1(0xff),
                address(factory),
                bytes32(i),
                initCodeHash
            )))));
            if ((uint160(predicted) & FLAG_MASK) == REQUIRED_FLAGS_VAL) {
                salt = bytes32(i);
                found = true;
                console.log("Found salt:", i);
                console.log("Predicted hook address:", predicted);
                break;
            }
        }
        require(found, "Salt not found in 500k iterations");

        address hookAddr = factory.deploy(creationCode, salt);
        console.log("ClawBack Hook:", hookAddr);
        require(uint160(hookAddr) & FLAG_MASK == REQUIRED_FLAGS_VAL, "Flag mismatch");

        Claw2ClawHook hook = Claw2ClawHook(hookAddr);

        // --- 5. Whitelist deployer + routers as bots ---
        hook.addBot(deployer);
        hook.addBot(address(swapRouter));
        hook.addBot(address(liquidityRouter));
        console.log("Bots whitelisted (deployer + routers)");

        // --- 6. Initialize pool (CLAW/ZUG) ---
        address token0;
        address token1;
        if (address(claw) < address(zug)) {
            token0 = address(claw);
            token1 = address(zug);
        } else {
            token0 = address(zug);
            token1 = address(claw);
        }

        PoolKey memory poolKey = PoolKey({
            currency0: Currency.wrap(token0),
            currency1: Currency.wrap(token1),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(hookAddr)
        });

        uint160 sqrtPriceX96 = 79228162514264337593543950336; // 1:1
        poolManager.initialize(poolKey, sqrtPriceX96);
        console.log("Pool initialized (1:1 price)");

        // --- 7. Add liquidity ---
        MockToken(token0).approve(address(liquidityRouter), type(uint256).max);
        MockToken(token1).approve(address(liquidityRouter), type(uint256).max);

        liquidityRouter.modifyLiquidity(
            poolKey,
            IPoolManager.ModifyLiquidityParams({
                tickLower: -600,
                tickUpper: 600,
                liquidityDelta: 100_000e18,
                salt: bytes32(0)
            }),
            bytes("")
        );
        console.log("Liquidity added (100k each side)");

        // --- 8. Test swap ---
        MockToken(token0).approve(address(swapRouter), type(uint256).max);
        MockToken(token1).approve(address(swapRouter), type(uint256).max);

        swapRouter.swap(
            poolKey,
            IPoolManager.SwapParams({
                zeroForOne: true,
                amountSpecified: -1000 ether,
                sqrtPriceLimitX96: TickMath.MIN_SQRT_PRICE + 1
            }),
            PoolSwapTest.TestSettings({
                takeClaims: false,
                settleUsingBurn: false
            }),
            bytes("")
        );
        console.log("Test swap completed!");

        vm.stopBroadcast();

        // --- Summary ---
        console.log("");
        console.log("========================================");
        console.log("  DEPLOYMENT COMPLETE - COPY TO .env:");
        console.log("========================================");
        console.log("POOL_MANAGER_ADDRESS=", address(poolManager));
        console.log("SWAP_ROUTER_ADDRESS=", address(swapRouter));
        console.log("HOOK_ADDRESS=", hookAddr);
        console.log("========================================");
    }
}
