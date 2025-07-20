use std::collections::HashMap;
use std::io;


#[derive(Debug, Clone)]
pub struct Customer {
    pub id: u32,
    pub name: String,
    pub email: String,
    pub phone: String,
}

// Function to add a new customer
pub fn add_customer(customers: &mut HashMap<u32, Customer>, next_id: &mut u32) {
    println!("\n--- Add New Customer ---");
    
    // Get customer name
    println!("Enter customer name:");
    let mut name = String::new();
    io::stdin().read_line(&mut name).expect("Failed to read name");
    let name = name.trim().to_string();
    
    // Check if name is empty
    if name.is_empty() {
        println!("Error: Name cannot be empty!");
        return;
    }
    
    // Get customer email
    println!("Enter customer email:");
    let mut email = String::new();
    io::stdin().read_line(&mut email).expect("Failed to read email");
    let email = email.trim().to_string();
    
    // Basic email validation
    if !email.contains('@') || email.is_empty() {
        println!("Error: Please enter a valid email!");
        return;
    }
    
    // Check if email already exists
    for customer in customers.values() {
        if customer.email == email {
            println!("Error: Customer with this email already exists!");
            return;
        }
    }
    
    // Get customer phone
    println!("Enter customer phone:");
    let mut phone = String::new();
    io::stdin().read_line(&mut phone).expect("Failed to read phone");
    let phone = phone.trim().to_string();
    
    if phone.is_empty() {
        println!("Error: Phone cannot be empty!");
        return;
    }
    
    // Create new customer
    let customer = Customer {
        id: *next_id,
        name: name,
        email: email,
        phone: phone,
    };
    
    // Add customer to HashMap
    customers.insert(*next_id, customer);
    println!("Customer added successfully with ID: {}", *next_id);
    
    // Increment ID for next customer
    *next_id += 1;
}

// Function to view one customer
pub fn view_customer(customers: &HashMap<u32, Customer>) {
    println!("\n--- View Customer ---");
    
    if customers.is_empty() {
        println!("No customers found.");
        return;
    }

    println!("\nEnter customer ID to view:");
    let mut input = String::new();
    io::stdin().read_line(&mut input).expect("Failed to read input");
    
    let id: u32 = match input.trim().parse() {
        Ok(num) => num,
        Err(_) => {
            println!("Error: Please enter a valid number!");
            return;
        }
    };

    match customers.get(&id) {
        Some(customer) => {
            println!("Customer details:");
            println!("ID: {} | Name: {} | Email: {} | Phone: {}", 
                    customer.id, customer.name, customer.email, customer.phone);
        },
        None => {
            println!("Error: Customer with ID {} not found!", id);
        }
    }
}

// Function to view all customers
pub fn view_customers(customers: &HashMap<u32, Customer>) {
    println!("\n--- All Customers ---");
    
    if customers.is_empty() {
        println!("No customers found.");
        return;
    }
    
    // Convert HashMap values to Vec so we can sort them
    let mut customer_list: Vec<&Customer> = customers.values().collect();
    customer_list.sort_by(|a, b| a.id.cmp(&b.id));
    
    println!("Total customers: {}", customers.len());
    println!();
    
    // Print each customer
    for customer in customer_list {
        println!("ID: {} | Name: {} | Email: {} | Phone: {}", 
                customer.id, customer.name, customer.email, customer.phone);
    }
}

// Function to remove a customer
pub fn remove_customer(customers: &mut HashMap<u32, Customer>) {
    println!("\n--- Remove Customer ---");
    
    if customers.is_empty() {
        println!("No customers to remove.");
        return;
    }
    
    // Show all customers first
    view_customers(customers);
    
    println!("\nEnter customer ID to remove:");
    let mut input = String::new();
    io::stdin().read_line(&mut input).expect("Failed to read input");
    
    // Parse the ID
    let id: u32 = match input.trim().parse() {
        Ok(num) => num,
        Err(_) => {
            println!("Error: Please enter a valid number!");
            return;
        }
    };
    
    // Check if customer exists
    match customers.get(&id) {
        Some(customer) => {
            // Show customer details
            println!("Customer to remove:");
            println!("ID: {} | Name: {} | Email: {} | Phone: {}", 
                    customer.id, customer.name, customer.email, customer.phone);
            
            // Ask for confirmation
            println!("Are you sure? (y/n):");
            let mut confirm = String::new();
            io::stdin().read_line(&mut confirm).expect("Failed to read input");
            
            if confirm.trim().to_lowercase() == "y" {
                customers.remove(&id);
                println!("Customer removed successfully!");
            } else {
                println!("Remove cancelled.");
            }
        },
        None => {
            println!("Error: Customer with ID {} not found!", id);
        }
    }
}

// Function to edit a customer
pub fn edit_customer(customers: &mut HashMap<u32, Customer>) {
    println!("\n--- Edit Customer ---");
    
    if customers.is_empty() {
        println!("No customers to edit.");
        return;
    }
    
    // Show all customers first
    view_customers(customers);
    
    println!("\nEnter customer ID to edit:");
    let mut input = String::new();
    io::stdin().read_line(&mut input).expect("Failed to read input");
    
    // Parse the ID
    let id: u32 = match input.trim().parse() {
        Ok(num) => num,
        Err(_) => {
            println!("Error: Please enter a valid number!");
            return;
        }
    };
    
    // Check if customer exists and get a copy
    let original_customer = match customers.get(&id) {
        Some(customer) => customer.clone(),
        None => {
            println!("Error: Customer with ID {} not found!", id);
            return;
        }
    };
    
    // Show current customer info
    println!("Current customer details:");
    println!("ID: {} | Name: {} | Email: {} | Phone: {}", 
            original_customer.id, original_customer.name, 
            original_customer.email, original_customer.phone);
    
    // Create a new customer with the same ID for editing
    let mut new_customer = original_customer.clone();
    
    // Edit name
    println!("\nCurrent name: {}", new_customer.name);
    println!("Enter new name (press Enter to keep current):");
    let mut new_name = String::new();
    io::stdin().read_line(&mut new_name).expect("Failed to read input");
    if !new_name.trim().is_empty() {
        new_customer.name = new_name.trim().to_string();
    }
    
    // Edit email
    println!("Current email: {}", new_customer.email);
    println!("Enter new email (press Enter to keep current):");
    let mut new_email = String::new();
    io::stdin().read_line(&mut new_email).expect("Failed to read input");
    if !new_email.trim().is_empty() {
        // Basic email validation
        if !new_email.contains('@') {
            println!("Error: Please enter a valid email!");
            return;
        }
        
        // Check if email already exists (but not for current customer)
        for customer in customers.values() {
            if customer.email == new_email.trim() && customer.id != id {
                println!("Error: Another customer with this email already exists!");
                return;
            }
        }
        
        new_customer.email = new_email.trim().to_string();
    }
    
    // Edit phone
    println!("Current phone: {}", new_customer.phone);
    println!("Enter new phone (press Enter to keep current):");
    let mut new_phone = String::new();
    io::stdin().read_line(&mut new_phone).expect("Failed to read input");
    if !new_phone.trim().is_empty() {
        new_customer.phone = new_phone.trim().to_string();
    }
    
    // Show what will be changed
    println!("\n--- Review Changes ---");
    println!("Original:");
    println!("ID: {} | Name: {} | Email: {} | Phone: {}", 
            original_customer.id, original_customer.name, 
            original_customer.email, original_customer.phone);
    println!("Updated:");
    println!("ID: {} | Name: {} | Email: {} | Phone: {}", 
            new_customer.id, new_customer.name, 
            new_customer.email, new_customer.phone);
    
    // Ask to save changes
    println!("\nSave changes? (y/n):");
    let mut confirm = String::new();
    io::stdin().read_line(&mut confirm).expect("Failed to read input");
    
    if confirm.trim().to_lowercase() == "y" {
        customers.insert(id, new_customer);
        println!("Customer updated successfully!");
    } else {
        println!("Edit cancelled. No changes made.");
    }
}


// Function to run the main program
pub fn run_program() {
    println!("Welcome to Group 11's Customer Database!");
    
    // Using HashMap to store customers - key is ID, value is Customer
    let mut customers: HashMap<u32, Customer> = HashMap::new();
    let mut next_id = 1u32; // Counter for customer IDs
    
    // Main program loop
    loop {
        // Show the menu
        println!("\n--- Customer Database ---");
        println!("1. Add Customer");
        println!("2. View Customer");
        println!("3. View All Customers");
        println!("4. Remove Customer");
        println!("5. Edit Customer");
        println!("6. Quit");
        print!("Choose option: ");
        
        // Get user input
        let mut input = String::new();
        io::stdin().read_line(&mut input).expect("Failed to read input");
        let choice = input.trim();
        
        // Match the user's choice
        match choice {
            "1" => add_customer(&mut customers, &mut next_id),
            "2" => view_customer(&customers),
            "3" => view_customers(&customers),
            "4" => remove_customer(&mut customers),
            "5" => edit_customer(&mut customers),
            "6" => {
                println!("Goodbye!");
                break;
            },
            _ => println!("Invalid choice! Please try again."),
        }
    }
}
