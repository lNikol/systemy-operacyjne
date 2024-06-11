#!/bin/bash

project_db=$1
to_update=$2 #notes lub inne, lub id zamówienia
id=$3
update_from=$4
value_for_update=$5 #new value for edit orders status
operation=$6
order_id=$7
services_amount_op=$8

updateCost() {
    editDate="[$(date +'%Y-%m-%d %H:%M:%S')]:"
    
    case "$operation" in
    "+") sqlite3 "$project_db" "UPDATE $update_from SET $to_update = $to_update + $value_for_update WHERE ID = $id" ;;
    "-") sqlite3 "$project_db" "UPDATE $update_from SET $to_update = $to_update - $value_for_update WHERE ID = $id" ;;
    "/") sqlite3 "$project_db" "UPDATE $update_from SET $to_update = $to_update / $value_for_update WHERE ID = $id" ;;
    "*") sqlite3 "$project_db" "UPDATE $update_from SET $to_update = $to_update * $value_for_update WHERE ID = $id" ;;
    "text") sqlite3 "$project_db" "UPDATE $update_from SET $to_update = $to_update || ';$value_for_update' WHERE ID = $id" ;; 
    "status") sqlite3 "$project_db" "UPDATE $update_from SET $to_update = '$value_for_update' " ;;
    "services_amount") {
        services_id=$(sqlite3 "$project_db" "SELECT services_id FROM Orders WHERE ID = $id ;")
        service_index=$(echo "$services_id" | awk -v num="$order_id" -F ';' '{for(i=1;i<=NF;i++) if($i==num) print i-1}')
        
        # NF - Number of Fields
        # -v - value
        # -F ';' - separator
        # tutaj awk działa w następujący sposób:
        # i to index liczby z np 1;2;3, gdzie najpierw działa separator ;
        # później przechodzi przez np 1 2 3, czyli nowy łańcuch znaków bez ;
        # później sprawdza index liczby z tego łańcucha
        # i dodaje do service_index
        # potem niżej robi dokładnie to samo ale tylko dla services_amount

        if [ -z "$service_index" ]; then
            echo "Zamówienie z takim ID nie zostało znalezione"
            exit 1
        else {
            services_amount=$(sqlite3 "$project_db" "SELECT services_amount FROM Orders WHERE ID = $id ;")
            new_services_amount=$(echo "$services_amount" | awk -v idx="$service_index" -v value="$value_for_update" -v op="$services_amount_op" -F ';' '{
                for(i=1;i<=NF;i++){
                    if(i-1==idx) {
                        if(op == "+") {
                            updated_value = $i + value
                        } else if(op == "-") {
                            updated_value = ($i - value>=0)?$i - value:$i;
                        } else if(op == "*") {
                            updated_value = $i * value
                        } else if(op == "/") {
                            updated_value = ($i!=0 && value!=0)? $i / value:$i;
                        } else {
                            updated_value = $i  # Default case if operation is not recognized
                        }
                        printf("%s%s", updated_value, (i<NF?";":""))
                    } else {
                        printf("%s%s", $i, (i<NF?";":""))
                    }
                }
            }')
            sqlite3 "$project_db" "UPDATE Orders SET services_amount = '$new_services_amount' WHERE ID = $id ;"
            operation="+"
            ./findInDB.sh "$project_db" "services_id" "null" $id $update_from
        }
        fi
    };;
    "services_remove") {
        services_id=$(sqlite3 "$project_db" "SELECT services_id FROM Orders WHERE ID = $id ;")
        service_index=$(echo "$services_id" | awk -v num="$order_id" -F ';' '{for(i=1;i<=NF;i++) if($i==num) print i-1}')

        if [ -z "$service_index" ]; then
            errorWindow "Zamówienie z takim ID nie zostało znalezione"
            exit 1
        else {
            services_amount=$(sqlite3 "$project_db" "SELECT services_amount FROM Orders WHERE ID = $id ;")
            #tutaj awk wypisuje wszystkie usługi, oprócz usługi, które chcę usunąć
            new_services_amount=$(echo "$services_amount" | awk -v idx="$service_index" -F ';' '{
                for(i=1;i<=NF;i++){
                    if(i-1!=idx) {
                        printf("%s%s", $i, (i<NF?";":""))
                    }
                }
            }')
            new_services_id=$(echo "$services_id" | awk -v idx="$service_index" -F ';' '{
                for(i=1;i<=NF;i++){
                    if(i-1!=idx) {
                        printf("%s%s", $i, (i<NF?";":""))
                    }
                }
            }')
            length=$(expr length "$new_services_amount")
            symbol=${new_services_amount:length-1:1}
            if [ "$symbol" == ";" ]; then
                new_services_amount="${new_services_amount:0:length-1}"
            fi
            
            length=$(expr length "$new_services_id")
            symbol=${new_services_id:length-1:1}
            if [ "$symbol" == ";" ]; then
                new_services_id="${new_services_id:0:length-1}"
            fi

            sqlite3 "$project_db" "UPDATE Orders SET services_amount = '$new_services_amount', services_id = '$new_services_id' WHERE ID = $id;"
            ./findInDB.sh "$project_db" "services_id" "null" $id $update_from
        }
        fi
    } ;;
    esac
}


updateCost;
