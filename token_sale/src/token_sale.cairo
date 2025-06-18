#[starknet::contract]
mod TokenSale {
    use starknet::{ContractAddress, get_contract_address, get_caller_address, ClassHash};
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess, Map, StoragePathEntry};

    use crate::interfaces::itoken_sale::ITokenSale;
    use crate::interfaces::ierc20::{IERC20Dispatcher, IERC20DispatcherTrait};
    
    use openzeppelin::upgrades::upgradeable::UpgradeableComponent;
    use openzeppelin::access::ownable::OwnableComponent;

    component!(path: UpgradeableComponent, storage: anything, event: UpgradeableEvent);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;


    #[storage]
    struct Storage {
        accepted_payment_token: ContractAddress,
        token_price: Map<ContractAddress, u256>,
        tokens_available_for_sale: Map<ContractAddress, u256>,

        #[substorage(v0)]
        anything: UpgradeableComponent::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        TokenDeposited: TokenDeposited,
        TokenPurchased: TokenPurchased,
    }

    #[derive(Drop, starknet::Event)]
    struct TokenDeposited {
        #[key]
        token_address: ContractAddress,
        amount: u256,
        price: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct TokenPurchased {
        #[key]
        buyer: ContractAddress,
        #[key]
        token_address: ContractAddress,
        amount: u256,
        total_cost: u256,
    }


    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress, accepted_payment_token: ContractAddress) {
        self.ownable.initializer(owner);
        self.accepted_payment_token.write(accepted_payment_token);
    }

    #[abi(embed_v0)]
    impl TokenSaleImpl of ITokenSale<ContractState> {
        fn check_available_token(self: @ContractState, token_address: ContractAddress) -> u256 {
            let token = IERC20Dispatcher { contract_address: token_address };

            let this_address = get_contract_address();

            return token.balance_of(this_address);
        }

        
        fn deposit_token(ref self: ContractState, token_address: ContractAddress, amount: u256, token_price: u256) {
            self.ownable.assert_only_owner();

            let caller = get_caller_address();
            let this_contract = get_contract_address();

            let token = IERC20Dispatcher { contract_address: token_address };
            assert(token.balance_of(caller) > 0, 'insufficient balance');

            let transfer = token.transfer_from(caller, this_contract, amount);
            assert(transfer, 'transfer failed');

            let current_available = self.tokens_available_for_sale.entry(token_address).read();
            self.tokens_available_for_sale.entry(token_address).write(current_available + amount);
            self.token_price.entry(token_address).write(token_price);

            self.emit(TokenDeposited { token_address, amount, price: token_price });
        }

        fn buy_token(ref self: ContractState, token_address: ContractAddress, amount: u256) {
            assert(amount > 0, 'Amount must be greater than 0');
            
            let available_tokens = self.tokens_available_for_sale.entry(token_address).read();
            assert(available_tokens >= amount, 'Not enough tokens available');

            let buyer = get_caller_address();
            let token_price = self.token_price.entry(token_address).read();
            assert(token_price > 0, 'Token not available for sale');

            let total_cost = amount * token_price;

            let payment_token = IERC20Dispatcher { contract_address: self.accepted_payment_token.read() };
            let token_to_buy = IERC20Dispatcher { contract_address: token_address };
            
            let buyer_balance = payment_token.balance_of(buyer);
            assert(buyer_balance >= total_cost, 'Insufficient funds');

            // Transfer payment from buyer to contract
            let payment_success = payment_token.transfer_from(buyer, get_contract_address(), total_cost);
            assert(payment_success, 'Payment transfer failed');

            // Transfer tokens to buyer
            let token_success = token_to_buy.transfer(buyer, amount);
            assert(token_success, 'Token transfer failed');

            // Update available tokens
            self.tokens_available_for_sale.entry(token_address).write(available_tokens - amount);

            self.emit(TokenPurchased { buyer, token_address, amount, total_cost });
        }

        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.anything.upgrade(new_class_hash);
        }

        fn withdraw_token(ref self: ContractState) {
            self.ownable.assert_only_owner();
            let caller = get_caller_address();
            let this_contract = get_contract_address();
            let payment_token = IERC20Dispatcher {
                contract_address: self.accepted_payment_token.read(),
            };
            let contract_balance = payment_token.balance_of(this_contract);

            if contract_balance > 0 {
                payment_token.transfer(caller, contract_balance);
            }
        }
    }
}