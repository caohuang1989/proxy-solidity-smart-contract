//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Data.sol";

contract Vproxy is Data {
    address private _owner;
    
    address private _implementation;

    event UpdatenContractAddress(address indexed newContractAddress);

    constructor(address contractAddress) {
        _implementation = contractAddress;
        _owner = msg.sender;
        emit UpdatenContractAddress(contractAddress);
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Vproxy: Caller was not owner");
        _;
    }

    //@TODO diamond pattern
    fallback() external payable {
      // bool successCall = false;
      // bytes memory resData;
      // (successCall, resData) = _implementation.delegatecall(msg.data);
      // require(successCall, "Proxy: Internal call was failed");


      //https://blog.openzeppelin.com/proxy-patterns/
      
      address implementation = _implementation;
      
      require(_implementation != address(0), "Contract address is zero");
      require(msg.sender == _owner, "Vproxy: Caller was not owner");

      bytes memory data = msg.data;
      assembly {
        //forward call to logic contract
        let result := delegatecall(
            gas(),
            implementation,
            add(data, 0x20),
            mload(data),
            0,
            0
        )
        //retrieve return data
        let size := returndatasize()
        let ptr := mload(0x40)
        returndatacopy(ptr, 0, size)
        
        //forward return data back to caller
        switch result
          case 0 {
              revert(ptr, size)
          }
          default {
              return(ptr, size)
          }
      }
    }

    //@TODO: imporve this by using multisignature algorithm
    function updateContractAddress(address _newAddress) external onlyOwner {
        require(
            _newAddress != address(0),
            "Invalid address, failed to update addresss"
        );

        _implementation = _newAddress;
    }

    function getContractAddress() public view returns (address) {
        return _implementation;
    }

    function getOwner() public view returns (address) {
        return _owner;
    }

    function changeOwner(address _newOnwerAddress) public onlyOwner {
        _owner = _newOnwerAddress;
    }
}
