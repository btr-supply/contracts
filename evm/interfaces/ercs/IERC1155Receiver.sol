// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {IERC165} from "@interfaces/ercs/IERC165.sol";

interface IERC1155Receiver is IERC165 {
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data)
        external
        returns (bytes4);
    function onERC1155Received(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}
