#!/bin/bash

project_db=$1
user_name=$2
user_password=$3
source ./zenity_service.sh

if ! test -f "$project_db"; then
   sqlite3 "$project_db" << EOF

    Create TABLE Users (
        ID INTEGER PRIMARY KEY, 
        name TEXT, 
        password TEXT,
        role TEXT
    );
    
    INSERT INTO Users (name, password, role) VALUES ('$user_name', '$user_password', 'Admin');

    CREATE TABLE Services (
        ID INTEGER PRIMARY KEY, 
        name TEXT NOT NULL,
        price REAL
    );    

    CREATE TABLE Customers (
        ID INTEGER PRIMARY KEY,
        name TEXT,
        surname TEXT,
        phone_number TEXT,
        address TEXT,
        email TEXT,
        customer_group TEXT
    );   

    CREATE TABLE Orders (
        ID INTEGER PRIMARY KEY,
        notes TEXT,
        status TEXT,
        order_date TEXT,
        edit_date TEXT,
        total_cost REAL,
        customer_id INTEGER,
        services_id TEXT,
        services_amount TEXT,
        FOREIGN KEY (customer_id) REFERENCES Customers(ID)
    );
EOF
exit 0
else
    result=$(sqlite3 "$project_db" "SELECT COUNT(*) FROM Users WHERE name='$user_name'")
    if [ "$result" -gt 0 ]; then
        isPassed=$(sqlite3 "$project_db" "SELECT * FROM Users WHERE name='$user_name' AND password='$user_password'")
        if [ -z "$isPassed" ]; then
            exit 1
        else 
            exit 0
        fi
    else
        sqlite3 "$project_db" "INSERT INTO Users (name, password, role) VALUES ('$user_name', '$user_password', 'Admin') ;"
        infoWindow "Użytkownik ($user_name) dodany do bazy danych"
        exit 0
    fi
    exit 1
fi

user_password=""