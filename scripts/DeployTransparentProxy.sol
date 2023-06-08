// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "forge-std/Script.sol";

// Import the logic contract that you would like to link to the proxy
import "../src/Kudu.sol";

contract DeployTransparentProxy is Script {
    function run() external {
        address deployerPublicKey = vm.envAddress("PUBLIC_KEY");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Instance the logic contract that you would like to link to the to the proxy
        Kudu logic = new Kudu();
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(logic),
            deployerPublicKey,
            abi.encodeWithSignature("initialize()")
        );
        vm.stopBroadcast();
        console.log("Implementation address: ", address(logic));
        console.log("Proxy address: ", address(proxy));
    }
}

/**
 * @dev execute the following command, to run the script from the root folder.
 * forge script scripts/DeployTransparentProxy.sol:DeployTransparentProxy --rpc-url <your_rpc_url> --broadcast -vvv
 */
