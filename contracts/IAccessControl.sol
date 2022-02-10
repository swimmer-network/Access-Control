pragma solidity 0.8.10;

interface IAccessControl{
    function getNumberOfValidators() external view returns(uint);
    function getValidatorsSet() external view returns(address[] memory);
    function isValidator(address add) external view returns(bool);
}
