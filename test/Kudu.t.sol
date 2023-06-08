//SPDX-License-Identifier: UNLICENSE

pragma solidity 0.8.19;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "forge-std/Test.sol";
import "../src/Kudu.sol";

contract KuduTest is Test {
    Kudu kudu;
    address constant vengarl = address(0x1);
    address constant lucatiel = address(0x2);
    address constant sif = address(0x3);
    //
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function setUp() public {
        Kudu _kudu = new Kudu();
        TransparentUpgradeableProxy _kuduProxy = new TransparentUpgradeableProxy(
                address(_kudu),
                address(vengarl),
                abi.encodeWithSignature("initialize()")
            );
        kudu = Kudu(address(_kuduProxy));
    }

    function test_getters() public {
        assertEq("Kudu", kudu.name());
        assertEq("KUDU", kudu.symbol());
        assertEq(18, kudu.decimals());
        assertEqUint(10e6 * 10e18, kudu.totalSupply());
    }

    function test_approvesAndAllowances(uint256 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount <= 2 ** 254 - 1);
        //
        assertEqUint(0, kudu.allowance(address(this), lucatiel));
        //
        vm.expectEmit();
        emit Approval(address(this), lucatiel, amount);
        assertTrue(kudu.approve(lucatiel, amount));
        assertEqUint(amount, kudu.allowance(address(this), lucatiel));
        //
        vm.expectEmit();
        emit Approval(address(this), lucatiel, amount + 10e2);
        assertTrue(kudu.increaseAllowance(lucatiel, 10e2));
        assertEqUint(amount + 10e2, kudu.allowance(address(this), lucatiel));
        //
        vm.expectEmit();
        emit Approval(address(this), lucatiel, amount + 10e1 * 9);
        assertTrue(kudu.decreaseAllowance(lucatiel, 10e1));
        assertEqUint(
            amount + 10e1 * 9,
            kudu.allowance(address(this), lucatiel)
        );
    }

    function test_transfersAndBalances(uint256 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount <= 10e6 * 10e18);
        //
        vm.expectEmit();
        emit Transfer(address(this), lucatiel, amount);
        assertTrue(kudu.transfer(lucatiel, amount));
        assertEqUint(amount, kudu.balanceOf(lucatiel));
        assertEqUint(10e6 * 10e18 - amount, kudu.balanceOf(address(this)));
        //
        assertEqUint(0, kudu.allowance(lucatiel, address(this)));
        vm.expectRevert(bytes("ERC20: insufficient allowance"));
        assertFalse(kudu.transferFrom(lucatiel, sif, amount));
        //
        vm.prank(lucatiel);
        assertTrue(kudu.approve(address(this), 2 ** 256 - 1));
        vm.expectEmit();
        emit Transfer(lucatiel, sif, amount);
        assertTrue(kudu.transferFrom(lucatiel, sif, amount));
    }
}
