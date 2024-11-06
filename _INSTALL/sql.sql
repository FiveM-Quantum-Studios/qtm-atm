CREATE TABLE IF NOT EXISTS qtm_transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    identifier VARCHAR(50) NOT NULL,
    transaction_date DATE NOT NULL,
    transaction_type ENUM('Deposit', 'Withdraw') NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    UNIQUE KEY (identifier, transaction_date)
);

CREATE TABLE IF NOT EXISTS qtm_card_details (
    id INT AUTO_INCREMENT PRIMARY KEY,
    identifier VARCHAR(50) NOT NULL,
    long_num VARCHAR(19) NOT NULL,
    name VARCHAR(100) NOT NULL,
    expiry VARCHAR(5) NOT NULL,
    cvv VARCHAR(4) NOT NULL,
    correct_pin VARCHAR(4) NOT NULL,
    UNIQUE KEY (identifier)
);
