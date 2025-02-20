//SPDX-License-Identifier:BUSL-1.1

pragma solidity 0.8.23;

interface IAssetFactory_write {
    // -----------------
    //    Write Functions
    // -----------------

    function sendTokenMintingOrder(
        address _tokenReceiver_1,
        address _tokenReceiver_2,
        uint256 _numberOfAssetShares,
        uint256 _alreadyMinted
    ) external returns (uint256, uint256);

    function withdraw() external;

    function withdrawTo(address payable _addr, uint256 _amount) external;

    function setAssetInstanceImplementation(address _implementation) external;

    function createAssetInstance(
        string calldata _nameOfAsset,
        string[] calldata _initialOwners,
        address[] calldata _shareholderAddress,
        uint24[] calldata _shares,
        bytes32 _assetHash
    ) external;
}
