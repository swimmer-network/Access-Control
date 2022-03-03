pragma solidity 0.8.10;

interface IAccessControl{
    function getValidatorsSet() external view returns(address[] memory);
    function isValidator(address add) external view returns(bool);
    function numberOfActiveValidators() external view returns(uint);
}
