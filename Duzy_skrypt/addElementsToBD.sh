#!/bin/bash

project_db=$1
name=$2 #service|customer name / notes
price=$3 #service price / customer surname / status
order_date=$4
phone=$5 #edit_date
address=$6 #customer_id
email=$7 #services_amount
group=$8 #services_id
order=$9
source ./zenity_service.sh


if [[ -z "$phone" ]]; then
    result=$(sqlite3 "$project_db" "SELECT COUNT(*) FROM Services WHERE name='$name'")
    if [ "$result" -gt 0 ]; then
        errorWindow "Usługa z taką nazwą ($name) już istnieje"
        exit 1
    else
        sqlite3 "$project_db" "INSERT INTO Services (name, price) VALUES ('$name', '$price')"
        infoWindow "Usługa ($name) dodana do bazy danych"
        exit 0
    fi
elif [[ "$order" != "null" ]]; then
    result=$(sqlite3 "$project_db" "SELECT COUNT(*) FROM Customers WHERE id='$address'")
    if [[ -n "$result" && "$result" -eq 1 ]]; then
        nowe_id=$(sqlite3 "$project_db" "INSERT INTO Orders (notes, status, order_date, edit_date, customer_id, services_amount, services_id) VALUES ('$name', '$price', '$order_date', '$phone', '$address', '$email', '$group'); SELECT last_insert_rowid();")
        ./findInDB.sh "$project_db" "services_id" "null" $nowe_id "Orders"
        exit 0
    else
        errorWindow "Brak klienta z ID=$address"
        exit 1
    fi
else
    sqlite3 "$project_db" "INSERT INTO Customers (name, surname, phone_number, address, email, customer_group) VALUES ('$name', '$price', '$phone', '$address', '$email', '$group')"
    exit 0
fi

exit 1
