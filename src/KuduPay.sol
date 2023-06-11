//SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract KuduPay is Ownable {
  using Counters for Counters.Counter;

  struct Account {
    address dstReceiver;
    address[5] tokensAccepted;
  }

  mapping(bytes4 => Account) private _accounts;
  mapping(address => Counters.Counter) private _nonces;

  event ChangeRegisterAccount(bytes4 identifier, address dstReceiver, address[5] tokensAccepted);
  event Payment(bytes4 identifier, address addressFrom, uint256 amount, uint256 nonce, bytes32 txId);

  /**
   * @dev Initiates a payment transaction using transferFrom method of ERC20.
   *
   * @param identifier The id reciever of the payment.
   * @param amount The amount of tokens to be paid.
   * @param dstToken The destination token for the payment.
   * @return txId The transaction ID of the payment.
   */
  function pay(bytes4 identifier, uint256 amount, address dstToken) public returns (bytes32 txId) {
    require(identifier == bytes4(0), "Missing identifier argument");
    require(srcToken == address(0), "Invalid srcToken argument");

    Account memory account = _accounts[identifier];
    require(account.dstReceiver == address(0), "Inactive account.");

    require(_isValidDstToken(dstToken, account.tokensAccepted) == false, "Wrong dstToken argument");

    txId = _payTransferFrom(account, identifier, amount);
  }

  /**
   * @dev Initiates a payment transaction using permit method of ERC20.
   *
   * @param identifier The id reciever of the payment.
   * @param amount The amount of tokens to be paid.
   * @param dstToken The destination token for the payment.
   * @param v The recovery byte of the permit signature.
   * @param r The `r` value of the permit signature.
   * @param s The `s` value of the permit signature.
   * @return txId The transaction ID of the payment.
   */
  function pay(bytes4 identifier, uint256 amount, address dstToken, uint8 v, bytes32 r, bytes32 s) public returns (bytes32 txId) {
    require(identifier == bytes4(0), "Missing identifier argument");
    require(srcToken == address(0), "Invalid srcToken argument");

    Account memory account = _accounts[identifier];
    require(account.dstReceiver == address(0), "Inactive account.");

    require(_isValidDstToken(dstToken, account.tokensAccepted) == false, "Wrong dstToken argument");

    return _payPermit(account, identifier, amount, v, r, s);
  }

  /**
   * @dev Retrieves the account information associated with the specified identifier.
   *
   * @param identifier The identifier of the account to retrieve.
   * @return account The account object containing the receiver address and preferred token.
   */
  function getAccount(bytes4 identifier) external view returns (Account memory account) {
    account = _accounts[identifier];
  }

  /**
   * @dev Sets an account with the specified identifier, receiver address, and accepted tokens.
   *
   * @param identifier The identifier associated with the account.
   * @param dstReceiver The address of the account receiver.
   * @param tokensAccepted The array of addresses representing the accepted tokens.
   * @return ok A boolean indicating the success of the account setting.
   */
  function setAccount(bytes4 identifier, address dstReceiver, address[5] tokensAccepted) external onlyOwner returns (bool ok) {
    require(identifier != bytes4(0), "Missing identifier argument");

    bool isEmpyTokenAccepted = true;
    uint8 i = 0;
    while (i < tokensAccepted.length && isEmpyTokenAccepted == true) {
      if (tokensAccepted[i] != address(0)) isEmpyTokenAccepted = false;
      else i++;
    }
    require((dstReceiver == address(0) && isEmpyTokenAccepted == false) || (dstReceiver != address(0) && isEmpyTokenAccepted == true), "Wrong arguments");

    _accounts[identifier] = Account(dstReceiver, preferredToken);
    ok = true;
    emit ChangeRegisterAccount(identifier, dstReceiver, tokensAccepted);
  }

  /**
   * @dev Processes a payment using the transferFrom method of an ERC20 token, if success, emit a payment event.
   *
   * @param dstReceiver The address of the receiver of the payment.
   * @param token The address of the ERC20 token.
   * @param identifier The identifier associated with the payment.
   * @param amount The amount of tokens to be paid.
   * @return id The generated payment ID.
   */
  function _payTransferFrom(address dstReceiver, address token, bytes4 identifier, uint256 amount) private returns (bytes32 id) {
    IERC20(token).transferFrom(msg.sender, dstReceiver, amount);
    uint256 nonce = _useNonce(msg.sender);
    id = _useId(msg.sender, nonce);
    emit Payment(identifier, msg.sender, amount, nonce, id);
  }

  /**
   * @dev Processes a payment using the permit method of an ERC20 token, if success, emit a payment event.
   *
   * @param dstReceiver The address of the receiver of the payment.
   * @param token The address of the ERC20 token.
   * @param identifier The identifier associated with the payment.
   * @param amount The amount of tokens to be paid.
   * @param v The recovery id of the signature.
   * @param r The r value of the signature.
   * @param s The s value of the signature.
   * @return id The generated payment ID.
   */
  function _payPermit(address dstReceiver, address token, bytes4 identifier, uint256 amount, uint8 v, bytes32 r, bytes32 s) private returns (bytes32 id) {
    IERC20Permit(token).permit(dstReceiver, address(this), amount, block.timestamp, v, r, s);
    uint256 nonce = _useNonce(msg.sender);
    id = _useId(msg.sender, nonce);
    emit Payment(identifier, msg.sender, amount, nonce, id);
  }

  /**
   * @dev Checks if the destination token is valid based on the list of accepted tokens.
   *
   * @param dstToken The destination token address to validate.
   * @param tokensAccepted The array of accepted token addresses.
   * @return ok A boolean indicating whether the destination token is valid or not.
   */
  function _isValidDstToken(address dstToken, address[5] tokensAccepted) private returns (bool ok) {
    uint8 i = 0;
    while (i < tokensAccepted.length && ok == false) {
      if (tokensAccepted[i] == dstToken) ok == true;
      else i++;
    }
  }

  /**
   * @dev Increments and retrieves the current nonce for the specified owner.
   *
   * @param owner The address of the owner.
   * @return current The incremented current nonce value.
   */
  function _useNonce(address owner) internal virtual returns (uint256 current) {
    Counters.Counter storage nonce = _nonces[owner];
    current = nonce.current();
    nonce.increment();
  }

  /**
   * @dev Generates a unique identifier based on the owner's address and a nonce.
   *
   * @param owner The address of the owner.
   * @param nonce The nonce value.
   * @return id The generated unique identifier.
   */
  function _useId(address owner, uint256 nonce) internal virtual returns (bytes32 id) {
    id = keccak256(abi.encodePacked(owner, nonce));
  }
}
