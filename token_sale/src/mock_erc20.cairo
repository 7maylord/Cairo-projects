use starknet::{ContractAddress, get_caller_address};
use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess, Map, StoragePathEntry};

use crate::interfaces::ierc20::{IERC20Dispatcher, IERC20DispatcherTrait};

#[starknet::contract]
mod MockERC20 {
    use super::{IERC20Dispatcher, IERC20DispatcherTrait};
    use starknet::{ContractAddress, get_caller_address};
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess, Map, StoragePathEntry};

    #[storage]
    struct Storage {
        name: ByteArray,
        symbol: ByteArray,
        decimals: u8,
        total_supply: u256,
        balances: Map<ContractAddress, u256>,
        allowances: Map<(ContractAddress, ContractAddress), u256>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Transfer: Transfer,
        Approval: Approval,
    }

    #[derive(Drop, starknet::Event)]
    struct Transfer {
        #[key]
        from: ContractAddress,
        #[key]
        to: ContractAddress,
        value: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct Approval {
        #[key]
        owner: ContractAddress,
        #[key]
        spender: ContractAddress,
        value: u256,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        name: ByteArray,
        symbol: ByteArray,
        decimals: u8,
        initial_supply: u256,
        recipient: ContractAddress
    ) {
        self.name.write(name);
        self.symbol.write(symbol);
        self.decimals.write(decimals);
        self.total_supply.write(initial_supply);
        self.balances.entry(recipient).write(initial_supply);

        self.emit(Transfer {
            from: starknet::contract_address_const::<0>(),
            to: recipient,
            value: initial_supply
        });
    }

    #[abi(embed_v0)]
    impl ERC20Impl of IERC20<ContractState> {
        fn name(self: @ContractState) -> ByteArray {
            self.name.read()
        }

        fn symbol(self: @ContractState) -> ByteArray {
            self.symbol.read()
        }

        fn decimals(self: @ContractState) -> u8 {
            self.decimals.read()
        }

        fn total_supply(self: @ContractState) -> u256 {
            self.total_supply.read()
        }

        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            self.balances.entry(account).read()
        }

        fn allowance(self: @ContractState, owner: ContractAddress, spender: ContractAddress) -> u256 {
            self.allowances.entry((owner, spender)).read()
        }

        fn transfer(ref self: ContractState, recipient: ContractAddress, amount: u256) -> bool {
            let sender = get_caller_address();
            self._transfer(sender, recipient, amount);
            true
        }

        fn transfer_from(
            ref self: ContractState, 
            sender: ContractAddress, 
            recipient: ContractAddress, 
            amount: u256
        ) -> bool {
            let caller = get_caller_address();
            
            // Check allowance
            let current_allowance = self.allowances.entry((sender, caller)).read();
            assert(current_allowance >= amount, 'ERC20: insufficient allowance');
            
            // Update allowance
            self.allowances.entry((sender, caller)).write(current_allowance - amount);
            
            // Transfer tokens
            self._transfer(sender, recipient, amount);
            
            true
        }

        fn approve(ref self: ContractState, spender: ContractAddress, amount: u256) -> bool {
            let owner = get_caller_address();
            self.allowances.entry((owner, spender)).write(amount);
            
            self.emit(Approval { owner, spender, value: amount });
            true
        }

        // Testing helper functions
        fn mint(ref self: ContractState, recipient: ContractAddress, amount: u256) {
            let current_balance = self.balances.entry(recipient).read();
            self.balances.entry(recipient).write(current_balance + amount);
            
            let current_supply = self.total_supply.read();
            self.total_supply.write(current_supply + amount);
            
            self.emit(Transfer {
                from: starknet::contract_address_const::<0>(),
                to: recipient,
                value: amount
            });
        }

        fn burn(ref self: ContractState, account: ContractAddress, amount: u256) {
            let current_balance = self.balances.entry(account).read();
            assert(current_balance >= amount, 'ERC20: burn amount exceeds balance');
            
            self.balances.entry(account).write(current_balance - amount);
            
            let current_supply = self.total_supply.read();
            self.total_supply.write(current_supply - amount);
            
            self.emit(Transfer {
                from: account,
                to: starknet::contract_address_const::<0>(),
                value: amount
            });
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn _transfer(ref self: ContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256) {
            assert(!sender.is_zero(), 'ERC20: transfer from 0');
            assert(!recipient.is_zero(), 'ERC20: transfer to 0');
            
            let sender_balance = self.balances.entry(sender).read();
            assert(sender_balance >= amount, 'ERC20: insufficient balance');
            
            self.balances.entry(sender).write(sender_balance - amount);
            let recipient_balance = self.balances.entry(recipient).read();
            self.balances.entry(recipient).write(recipient_balance + amount);
            
            self.emit(Transfer { from: sender, to: recipient, value: amount });
        }
    }
}