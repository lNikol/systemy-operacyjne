#!/bin/bash

project_db=$1
to_find_1=$2 #notes, services_id lub inne
to_find_2=$3 #notes, services_id lub inne
id=$4
find_from=$5 #Orders for example
source ./zenity_service.sh
if [[ -z "$project_db" || -z $to_find_1 || -z $to_find_2 || -z $id || -z $find_from ]]; then
    errorWindow "Błąd: Brakujące argumenty."
    exit 1  # Zakończ skrypt z kodem wyjścia 1, oznaczającym niepowodzenie
fi

findElements() {
    # szukam wartosci w tablicy takich, ktore maja ; w środku (np a="a;d;a")
    elements=""
    #szukanie klientów po imieniu i nazwisku
    if [[ -n "$to_find_1" && -n "$to_find_2" && "$to_find_2" != "null" ]]; then
        elements=$(sqlite3 "$project_db" "SELECT * FROM Customers WHERE name = '$to_find_1' AND surname = '$to_find_2'")
        for el in "${elements[@]}"
        do
            echo $el
        done
    else
        elements=$(sqlite3 "$project_db" "SELECT $to_find_1 from $find_from WHERE ID = $id;")

        IFS=';' read -a elements_array <<< "$elements"
        # IFS to separator
        # -a robi tablicę
        price=0
        
        services_amount=$(sqlite3 "$project_db" "SELECT services_amount FROM Orders WHERE ID = $id ;")
        IFS=';' read -a amounts_array <<< "$services_amount"

        i=0
        for el in "${elements_array[@]}"
        do
        case "$to_find_1" in
            "services_id") {
                cost=$(sqlite3 "$project_db" "SELECT price FROM Services WHERE ID = $el;")
                amount=${amounts_array[$i]}
                
                # Calculate the price for the current service and add it to the total price
                service_cost=$(echo "$cost * $amount" | bc)
                price=$(echo "$price + $service_cost" | bc) #bc działa z liczbami zmiennoprzecinkowymi
            } ;;
            #liczenie ceny zamówienia na podstawie usług ^
        esac
        i=$((i+1))
        done
        sqlite3 "$project_db" "UPDATE Orders SET total_cost = $price WHERE ID = $id ; "
    fi
    # w zmiennych z ; nie pisac spacji po ;!
}

findElements;
