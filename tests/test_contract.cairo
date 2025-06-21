use starknet::ContractAddress;

use snforge_std::{declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address, stop_cheat_caller_address};
use starknet::contract_address::contract_address_const;


//Cairo automatically creates a dispatcher for the contract.
// Creating an interface for ERC20 contract.
// No need importing the dispatcher, as we are using the interface directly.
#[starknet::interface]
pub trait IERC20PlusMint<TContractState> {
    // ERC20 functions
    fn total_supply(self: @TContractState) -> u256;
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
    fn allowance(self: @TContractState, owner: ContractAddress, spender: ContractAddress) -> u256;
    fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u256) -> bool;
    fn transfer_from( ref self: TContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256) -> bool;
    fn approve(ref self: TContractState, spender: ContractAddress, amount: u256) -> bool;


    fn name(self: @TContractState) -> ByteArray;
    fn symbol(self: @TContractState) -> ByteArray;
    fn decimals(self: @TContractState) -> u8;

    fn mint(ref self: TContractState, recipient: ContractAddress, amount: u256);
}


fn deploy_contract(name: ByteArray) -> ContractAddress {
    let contract = declare(name).unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@ArrayTrait::new()).unwrap();
    contract_address
}

#[test]
fn test_constructor() {
    let contract_address = deploy_contract("TestERC20");
    let erc20_token = IERC20PlusMintDispatcher { contract_address };

    let name = erc20_token.name();
    let symbol = erc20_token.symbol();

    assert(name == "Tobtoken", 'Wrong token name');
    assert(symbol == "TBT", 'Wrong token symbol');
}

#[test]
fn test_total_supply() {
    let contract_address = deploy_contract("TestERC20");
    let erc20_token = IERC20PlusMintDispatcher { contract_address };

    let token_decimal = erc20_token.decimals();
    let token_recipient: ContractAddress = contract_address_const::<0x123456711>();
    let mint_amount = 1000_u256 * token_decimal.into();

    let balance_before_mint = erc20_token.balance_of(token_recipient);
    
    erc20_token.mint(token_recipient, mint_amount);

    let balance_after_mint = erc20_token.balance_of(token_recipient);

    let total_supply = erc20_token.total_supply();

    assert(balance_before_mint == 0, 'wrong balance before mint');
    assert(total_supply == mint_amount, 'wrong supply');
    assert(balance_after_mint == total_supply, 'wrong balance after mint');
    assert(balance_after_mint == mint_amount, 'wrong balance after mint');
}

#[test]
fn test_approval() {
    let contract_address = deploy_contract("TestERC20");
    let erc20_token = IERC20PlusMintDispatcher { contract_address };

    let token_decimal = erc20_token.decimals();
    let mint_amount = 1000_u256 * token_decimal.into();
    let appproval_amount = 100_u256 * token_decimal.into();

    let owner: ContractAddress = 0x07ab19dfcc6981ad7beba769a71a2d1cdd52b3d8a1484637bbb79f18a170cd51.try_into().unwrap();
    let recipient: ContractAddress = 0x03af13f04C618e7824b80b61e141F5b7aeDB07F5CCe3aD16Dbd8A4BE333A3Ffa.try_into().unwrap();

    erc20_token.mint(owner, mint_amount);
    assert(erc20_token.balance_of(owner) == mint_amount, 'mint failed');

    //make owner the caller of the contract
    start_cheat_caller_address(contract_address, owner);
    erc20_token.approve(recipient, appproval_amount);
    stop_cheat_caller_address(contract_address);
    
    assert(erc20_token.allowance(owner, recipient) > 0, 'wrong approval value');
    assert(erc20_token.allowance(owner, recipient) == appproval_amount, 'approval failed');

}

