use starknet:: ContractAddress;

//This is how to create an interface for the contract
#[starknet::interface] 
pub trait ITestERC20<TContractState> {
    fn mint(ref self: TContractState, recipient: ContractAddress, amount: u256);
}

//This is the entry point of the contract and not the main function
#[starknet::contract] 
mod TestERC20 {
    use openzeppelin::token::erc20::{ERC20Component, ERC20HooksEmptyImpl}; /// this is how to use component in a starknet contract

    use starknet:: ContractAddress;

    component!(path: ERC20Component, storage: erc20, event: ERC20Event);    

    
    #[abi(embed_v0)]
    impl ERC20MixinImpl = ERC20Component::ERC20MixinImpl<ContractState>; /// this is how to implement the mixin functions of the component
    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>; /// this is how to implement the internal functions of the component

    

    #[storage]
    struct Storage{
        #[substorage(v0)]
        erc20: ERC20Component::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC20Event: ERC20Component::Event,
    }


    /// to make use of a constructor, we need three things which are
    /// 1. we need to import
    /// 2. we need to link the contract with the component
    /// 3. we need to embed the component in the contract; what embedding does is to make all the functions in the embeddable available in the contract
    /// And we embed in two ways; 
    /// - we embed the functions we want to be exposed externally
    /// -secondly, we embed functions such as internal functions that we want to use internally in the contract.
    #[constructor]
    fn constructor(ref self: ContractState){
        self.erc20.initializer("Tobtoken", "TBT");
    }

    #[abi(embed_v0)]
    impl TestERC20Impl of super::ITestERC20<ContractState> {
        fn mint(ref self: ContractState, recipient: ContractAddress, amount: u256) {
            self.erc20.mint(recipient, amount);
        }
    }
}