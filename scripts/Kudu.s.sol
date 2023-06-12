// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "forge-std/Script.sol";
import "../src/Kudu.sol";

/**
 * @dev From the root folder, execute the following command to deploy and verify the contract.
 * forge script scripts/Kudu.s.sol:Deploy --rpc-url <your_rpc_url> --etherscan-api-key <your_etherscan_api_key> --verify --broadcast -vvv
 */
contract Deploy is Script {
  function run() external {
    //Esto es la address publica
    address deployerPublicKey = vm.envAddress("PUBLIC_KEY");
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    vm.startBroadcast(deployerPrivateKey);

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
 * @dev From the root folder, execute the following command to upgrade and verify the contract.
 * forge script scripts/Kudu.s.sol:Deploy --rpc-url <your_rpc_url> --etherscan-api-key <your_etherscan_api_key> --verify --broadcast -vvv
 */
contract Upgrade is Script {
  function run() external {
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    address kuduProxyAddress = vm.envAddress("KUDU_PROXY_ADDRESS");
    vm.startBroadcast(deployerPrivateKey);

    Kudu logic = new Kudu();
    ITransparentUpgradeableProxy(kuduProxyAddress).upgradeTo(address(logic));

    vm.stopBroadcast();
    console.log("New implementation address: ", address(logic));
  }
}
