//SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";

contract Kudu is ERC20PermitUpgradeable {
  function initialize() external initializer {
    __ERC20_init("Kudu", "KUDU");
    _mint(msg.sender, 10e6 * 10e18);
  }
}
