#!/bin/bash

project_db=$1
id_for_delete=$2
delete_from=$3
usl=$4
#napisać warunki na sprawdzenie czy wszystkie zmienne sa

delete_by_id () {
    if [[ "$usl" == "usl" ]]; then
        orders_with_service=$(sqlite3 "$project_db" "SELECT ID, services_id, services_amount FROM Orders WHERE services_id LIKE '%;$id_for_delete;%' OR services_id LIKE '$id_for_delete;%' OR services_id LIKE '%;$id_for_delete' OR services_id = '$id_for_delete';")
        while IFS="|" read -r order_id services_id services_amount; do
            # Konwersja services_id i services_amount do tablic
            IFS=';' read -r -a ids <<< "$services_id"
            IFS=';' read -r -a amounts <<< "$services_amount"
            
            # Nowe listy bez usuniętej usługi
            new_ids=()
            new_amounts=()
            
            for i in "${!ids[@]}"; do
            # -ne - not equal, nie jest równy
                if [ "${ids[$i]}" -ne "$id_for_delete" ]; then
                    new_ids+=("${ids[$i]}")
                    new_amounts+=("${amounts[$i]}")
                fi
            done
            
            # Konwersja tablic z powrotem na ciągi
            new_services_id=$(IFS=';'; echo "${new_ids[*]}")
            new_services_amount=$(IFS=';'; echo "${new_amounts[*]}")
            # Aktualizacja zamówienia w bazie danych
            sqlite3 "$project_db" "UPDATE Orders SET services_id='$new_services_id', services_amount='$new_services_amount' WHERE ID=$order_id;"
            ./findInDB.sh "$project_db" "services_id" "null" $order_id "Orders"
        done <<< "$orders_with_service" #przekazywanie wartości zmiennej jako dane wejściowe do while
        sqlite3 "$project_db" "DELETE FROM $delete_from WHERE ID = $id_for_delete "

    elif [[ "$usl" == "cl" ]]; then
        orders_to_remove=$(sqlite3 "$project_db" "SELECT ID FROM Orders WHERE customer_id = $id_for_delete;")
        for order_id in $orders_to_remove; do
            sqlite3 "$project_db" "DELETE FROM Orders WHERE ID = $order_id;"
        done
        sqlite3 "$project_db" "DELETE FROM $delete_from WHERE ID = $id_for_delete "
    else
        sqlite3 "$project_db" "DELETE FROM $delete_from WHERE ID = $id_for_delete "
    fi
}

delete_by_id