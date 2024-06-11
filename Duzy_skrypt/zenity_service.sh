#!/bin/bash

project_db=$1
point_from_menu=$2
tmpfile="$3"

#[[ -s "$tmpfile" ]] sprawdza, czy plik istnieje i nie jest pusty
if [[ -s "$tmpfile" ]]; then
    read user_name user_password < "$tmpfile"
fi

errorWindow(){
    msg=$1
    zenity --error --text "$msg" &
}

infoWindow(){
    msg=$1
    zenity --info --text "$msg" &
}

services_window(){
    local rs=$(sqlite3 "$project_db" "SELECT '\"'|| name ||'\"' || '|' || price || '|' || ID FROM Services")
    IFS=$'\n' read -r -d '' -a services_array <<< "$rs"
    for service in "${services_array[@]}"; do
        # Rozdzielanie elementu na nazwę, cenę i ID
        IFS='|' read -r name price id <<< "$service"
        local zenity_list_data+=("$name" "$price" "$id")
    done

    zenity --height 350 --width 300 --list --title="Lista usług" \
        --column="Nazwa usługi" \
        --column="Cena" \
        --column="ID" \
        "${zenity_list_data[@]}" &
}

customers_window(){
    local rs=$(sqlite3 "$project_db" "SELECT '\"'|| name ||'\"' || '|' || '\"'|| surname ||'\"' || '|' || email || '|' || customer_group || '|' || ID FROM Customers")
    IFS=$'\n' read -r -d '' -a customers_arr <<< "$rs"
    for customer in "${customers_arr[@]}"; do
        # Rozdzielanie na name surname email customer_group id
        IFS='|' read -r name surname email customer_group id <<< "$customer"
        local zenity_list+=("$name" "$surname" "$email" "$customer_group" "$id")
    done

    zenity --height 500 --width 500 --list --title="Lista klientów" \
        --column="Name" \
        --column="Surname" \
        --column="Email" \
        --column="Group" \
        --column="ID" \
        "${zenity_list[@]}" &
}

orders_window(){
    local rs=$(sqlite3 "$project_db" "SELECT ID || '|' || '\"'|| status ||'\"' || '|' || total_cost || '|' || order_date || '|' || edit_date || '|' || customer_id || '|' || services_id || '|' || services_amount FROM Orders ")
    IFS=$'\n' read -r -d '' -a ords_arr <<< "$rs"
    for ord in "${ords_arr[@]}"; do
        # Rozdzielanie elementu 
        IFS='|' read -r ID status total_cost order_date edit_date customer_id services_id services_amount <<< "$ord"
        local zen_list+=($ID "$status" $total_cost $order_date $edit_date $customer_id $services_id $services_amount)
    done

    zenity --height 650 --width 650 --list --title="Lista zamówień" \
        --column="ID" \
        --column="Status" \
        --column="Total cost" \
        --column="Order date" \
        --column="Edit date" \
        --column="Customer id" \
        --column="Services id" \
        --column="Services amount" \
        "${zen_list[@]}" &
}

client_window(){ 
while [[ -z "$client_name" || -z "$client_surname" || -z "$client_phone" || -z "$client_address" || -z "$client_email" || -z "$client_group" ]]; do
        result=$(zenity --forms --title="Wprowadź dane klienta" \
        --text="Proszę wprowadzić dane klienta:" \
        --add-entry="Imię klienta:" \
        --add-entry="Nazwisko klienta:" \
        --add-entry="Numer komórkowy klienta:" \
        --add-entry="Address klienta:" \
        --add-entry="Email klienta:" \
        --add-entry="Grupa klienta:" \
        --separator="|")
        
        client_name=$(echo "$result" | cut -d '|' -f 1)
        client_surname=$(echo "$result" | cut -d '|' -f 2)
        client_phone=$(echo "$result" | cut -d '|' -f 3)
        client_address=$(echo "$result" | cut -d '|' -f 4)
        client_email=$(echo "$result" | cut -d '|' -f 5)
        client_group=$(echo "$result" | cut -d '|' -f 6)

        if [[ "$client_phone" =~ ^\+48[0-9]{9}$ ]]; then
            client_phone=$client_phone
        else
            errorWindow "Numer komórkowy jest niepoprawny. Upewnij się, że zaczyna się od +48 i ma 9 cyfr"
            client_phone=""
        fi
        if [[ -z "$client_group" ]]; then
            client_group="zwykły"
        fi

        #Nie wiem, wyrażenie regularne jest poprawne (na regex101.com działa), ale w bashu nie
        #więc zostawiam ten kod w komentarzu
        #client_address: (ul\.|al\.|pl\.)\s[a-zA-ZęóąśłżźćńĘÓĄŚŁŻŹĆŃ\s]+\s\d{1,4}\,\s[a-zA-ZęóąśłżźćńĘÓĄŚŁŻŹĆŃ\s]+\s\d{2}-\d{3}

        #if [[ "$client_address" =~ ^(ul\.|al\.|pl\.)\s[a-zA-ZęóąśłżźćńĘÓĄŚŁŻŹĆŃ\s]+\s\d{1,4}\,\s[a-zA-ZęóąśłżźćńĘÓĄŚŁŻŹĆŃ\s]+\s\d{2}-\d{3}$ ]]; then
        #    client_address=$client_address
            #\s oznacza dowolny znak biały
        #else
        #    errorWindow "Zły adres, wzór poprawnego adresu: 'ul. Świętojańska 20, Kraków 30-063'"
        #fi

        
        if [[ "$client_email" =~ ^[a-Z0-9]+(\.[a-z]+)*\@[a-z]+(\.[a-z]+)+$ ]]; then
            client_email=$client_email
        else
            errorWindow "Email jest niepoprawny. Upewnij się, czy jest poprawny"
            client_email=""
        fi
    done
    # Zwracanie zmodyfikowanych wartości jako ciąg rozdzielony spacjami
    echo "$client_name|$client_surname|$client_phone|$client_address|$client_email|$client_group"
}



case $point_from_menu in 
"0") {
    #dodawanie użytkownika
    while [[ -z "$user_name" || -z "$user_password" || "$user_password" == "false" ]]; do
        result=$(zenity --forms --title="Wprowadź dane użytkownika" \
        --text="Proszę wprowadzić dane użytkownika:" \
        --add-entry="Login:" \
        --add-entry="Hasło:" \
        --separator=" " \ )
        user_name=$(echo "$result" | cut -d ' ' -f 1)
        user_password=$(echo "$result" | cut -d ' ' -f 2)
    done
    ./genDB.sh "$project_db" "$user_name" "$user_password"
    res=$?
    if [[ "$res" -eq 0 ]]; then
        infoWindow "Jesteś zalogowany"
        user_password="true"
        echo "$user_name" "true" > "$tmpfile"
    else
        user_password="false"
        echo "$user_name" "false" > "$tmpfile"
        errorWindow "Złe hasło"
    fi 
    } ;;
"1") {
    #dodawanie usługi
    services_window
    service_name=""
    service_price=""
    while [[ -z "$service_name" || -z "$service_price" ]]; do
        result=$(zenity --forms --title="Wprowadź dane usługi" \
        --text="Proszę wprowadzić dane usługi:" \
        --add-entry="Nazwa usługi:" \
        --add-entry="Cena uslugi (np. 10.10):" \
        --separator="|")
        
        service_name=$(echo "$result" | cut -d '|' -f 1)
        service_price=$(echo "$result" | cut -d '|' -f 2)

        if [[ -z "$service_name" ]]; then
            errorWindow "service_name jest pusty, proszę spróbować jeszcze raz"
            service_name=""
        else 
            service_name=$service_name
        fi

        if [[ "$service_price" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
            service_price=$service_price
        else
            errorWindow "service_price nie poprawne wpisany, proszę spróbować jeszcze raz"
            service_price=""
        fi
    done

    ./addElementsToBD.sh "$project_db" "$service_name" "$service_price"
    };;
"2") {
    #edytowanie usługi
    services_window
    infoWindow "W tle otworzyło się okno z usługami"
    service_id=""
    new_price=""
    new_name=""
    while [[ -z "$service_id" ]]; do
        result=$(zenity --forms --title="Wprowadź nowe dane usługi" \
        --add-entry="Id usługi:" \
        --add-entry="Nowa nazwa usługi" \
        --add-entry="Nowa cena usługi:" \
        --separator="|" \ )
        service_id=$(echo "$result" | cut -d '|' -f 1)
        new_name=$(echo "$result" | cut -d '|' -f 2)
        new_price=$(echo "$result" | cut -d '|' -f 3)

        res=$(sqlite3 "$project_db" "SELECT * FROM Services WHERE ID=$service_id;")
        if [[ -n "$res" ]];then
            old_name=$(echo "$res" | cut -d '|' -f 2)
            old_price=$(echo "$res" | cut -d '|' -f 3)

            if [[ -z "$new_name" ]];then
                new_name=$old_name
            fi
            if [[ -z "$new_price" ]];then
                new_price=$old_price
            elif [[ "$new_price" =~ ^[0-9]+(\.[0-9]+)?$ ]];then
                new_price=$new_price
                infoWindow "Nowa cena została zapisana"
            else 
                new_price=$old_price
                errorWindow "Nowa cena pusta lub źle wpisana, nowa_cena=stara_cena"
            fi
            count=$(sqlite3 "$project_db" "SELECT COUNT(*) FROM Services WHERE name='$new_name'")
            if [[ $count -eq 0 ]];then
                sqlite3 "$project_db" "UPDATE Services SET name='$new_name', price=$new_price WHERE ID=$service_id;"
                infoWindow "Usługa została zmieniona"
            else
                errorWindow "Usługa z taką nazwą już istnieje, nic nie zmieniono"
            fi
        else errorWindow "Nie znaleziono usługi z takim ID"
        fi
    done
};;
"3") {
    #dodawanie klienta
    client_name=""
    client_surname=""
    client_phone=""
    client_address=""
    client_email=""
    client_group="zwykły"
      
    IFS='|' read -r client_name client_surname client_phone client_address client_email client_group <<< "$(client_window $client_name $client_surname $client_phone $client_address $client_email $client_group)"

    ./addElementsToBD.sh "$project_db" "$client_name" "$client_surname" " " "$client_phone" "$client_address" "$client_email" "$client_group" "null"
    res=$?
    if [[ "$res" -eq 0 ]]; then
        infoWindow "Klient został dodany"
    else
        errorWindow "Nie udało się dodać klienta"
    fi 
};;
"4") {
    #dodawanie zamówienia
    services_window;
    customers_window;

    infoWindow "W tle otworzyły się okna z informacją o usługach i o klientach"

    notes=""
    status=""
    order_date=""
    edit_date=""
    customer_id=""
    services_id=""
    services_amout=""

    while [[ -z "$status" || -z "$order_date" || -z "$edit_date" || -z "$customer_id" || -z "$services_id" || -z "$services_amount" ]]; do
        result=$(zenity --forms --title="Wprowadź dane zamówienia" \
        --text="Proszę wprowadzić dane zamówienia:" \
        --add-entry="Komentarze do zamówienia:" \
        --add-entry="Status zamówienia (np. złożone):" \
        --add-calendar="Data złożenia zamówienia:" \
        --add-calendar="Data edytowania zamówienia:" \
        --add-entry="ID klienta:" \
        --add-entry="ID usług (np. 1;2;3;4):" \
        --add-entry="Ilość usług (np. 2;3;4;5):" \
        --list-values="Opcja 1|Opcja 2|Opcja 3|Opcja 4" \
        --separator="|")

        notes=$(echo "$result" | cut -d '|' -f 1)
        status=$(echo "$result" | cut -d '|' -f 2)
        #zamiana dd.mm.yyyy na yyyy-mm-dd
        order_date=$(echo "$result" | cut -d '|' -f 3 | sed -E 's/([0-9]{2})\.([0-9]{2})\.([0-9]{4})/\3-\2-\1/' )
        edit_date=$(echo "$result" | cut -d '|' -f 4 | sed -E 's/([0-9]{2})\.([0-9]{2})\.([0-9]{4})/\3-\2-\1/')
        #s/ to samo co i zamienić
        #
        customer_id=$(echo "$result" | cut -d '|' -f 5)
        services_id=$(echo "$result" | cut -d '|' -f 6)
        services_amount=$(echo "$result" | cut -d '|' -f 7)

        if [[ "$customer_id" =~ ^[0-9]+$ ]]; then
            customer_id=$customer_id
        else
            errorWindow "Klient musi byc tylko jeden"
            customer_id=""
        fi

        if [[ "$services_id" =~ ^[0-9]+(;[0-9]+)*$ ]]; then
            services_id=$services_id
        else
            services_id=""
            errorWindow "services_id niepoprawne wpisane"
        fi

        if [[ "$services_amount" =~ ^[0-9]+(;[0-9]+)*$ ]]; then
            services_amount=$services_amount
        else
            services_amount=""
            errorWindow "services_amount niepoprawne wpisane"
        fi

        IFS=';' read -r -a services_id_array <<< "$services_id"
        IFS=';' read -r -a services_amount_array <<< "$services_amount"
        # #services_amount_array[@] zwraca liczbę elementów w tablicy
        if [[ ${#services_id_array[@]} -ne ${#services_amount_array[@]} ]]; then
            services_id=""
            services_amount=""
            errorWindow "Liczba ID usług musi być równa liczbie ilości usług"
        fi

        if [[ -z "$status" ]]; then
            status="złożony"
        fi

        # Konwertuję daty na format YYYYMMDD do porównania
        order_date_num=$(date -d "$order_date" +"%Y%m%d")
        edit_date_num=$(date -d "$edit_date" +"%Y%m%d")

        # Sprawdzam, czy data modyfikacji nie jest przed datą dodania
        if [ "$edit_date_num" -ge "$order_date_num" ]; then
            edit_date_num=$edit_date_num
        else
            if [[ -n "$status" && -n "$customer_id" && -n "$services_id" && -n "$services_amount"  ]]; then
                errorWindow "Data edytowania ("$edit_date") nie jest prawidłowa, wpisz daty ponownie"
                edit_date=""
                while [ -z "$edit_date" ]; do
                    res=$(zenity --forms --title="Wprowadź poprawne daty zamówienia" \
                    --text="Proszę wprowadzić poprawne daty zamówienia:" \
                    --add-calendar="Data złożenia zamówienia:" \
                    --add-calendar="Data edytowania zamówienia:" \
                    --separator="|")

                    order_date=$(echo "$res" | cut -d '|' -f 1 | sed -E 's/([0-9]{2})\.([0-9]{2})\.([0-9]{4})/\3-\2-\1/')
                    order_date_num=$(date -d "$order_date" +"%Y%m%d")
                    
                    edit_date=$(echo "$res" | cut -d '|' -f 2 | sed -E 's/([0-9]{2})\.([0-9]{2})\.([0-9]{4})/\3-\2-\1/')
                    edit_date_num=$(date -d "$edit_date" +"%Y%m%d")
                    if [ "$edit_date_num" -ge "$order_date_num" ]; then
                        edit_date=$edit_date
                    else
                        errorWindow "Data edytowania ("$edit_date") jest przed datą zamówienia ($order_date). Proszę spróbować ponownie."
                        edit_date=""
                    fi
                done
            fi
        fi
    done

    ./addElementsToBD.sh "$project_db" "$notes" "$status" "$order_date" "$edit_date" "$customer_id" "$services_amount" "$services_id" "true"
    res=$?
    if [[ "$res" -eq 0 ]]; then
        infoWindow "Zamówienie zostało dodane"
    else
        errorWindow "Nie udało się dodać zamówienia"
    fi 
};;
"5"){
    #edytowanie klienta
    infoWindow "W tle pojawiło się okno z klientami"
    customers_window

    client_name=""
    client_surname=""
    client_phone=""
    client_address=""
    client_email=""
    client_group="zwykły"

    result=$(zenity --forms --title="Wprowadź dane klienta" \
        --text="Proszę wprowadzić ID klienta:" \
        --add-entry="ID klienta:" \
        --separator="|")
        temp_id_customer=$(echo "$result" | cut -d '|' -f 1)
        if [[ -n "$temp_id_customer" ]]; then
            IFS='|' read -r client_name client_surname client_phone client_address client_email client_group <<< "$(client_window)"
            sqlite3 "$project_db" "UPDATE Customers SET name='$client_name', surname='$client_surname', phone_number='$client_phone', address='$client_address' , email='$client_email', customer_group='$client_group' WHERE ID=$temp_id_customer;"
            temp=$?
            if [[ $temp -eq 0 ]]; then
                infoWindow "Klient został zmieniony"
            else errorWindow "Błąd podczas edycji"
        fi
    else errorWindow "ID jest puste, cofam się"
    fi
    
   
};;
"6"){
    #usuniecie zamowienia
    orders_window
    infoWindow "W tle otworzyło się okno z zamówieniami"
    order_id=""
    while [[ -z "$order_id" ]]; do
        result=$(zenity --forms --title="Wprowadź id zamówienia" \
        --add-entry="Id zamówienia:" \
        --separator=" " \ )
        order_id=$(echo "$result" | cut -d ' ' -f 1)
    done
    ./deleteFromDB.sh "$project_db" $order_id "Orders"
};;
"7"){
    #usuniecie klienta oraz go zamówień
    customers_window
    infoWindow "W tle otworzyło się okno z klientami"
    customer_id=""
    while [[ -z "$customer_id" ]]; do
        result=$(zenity --forms --title="Wprowadź id klienta" \
        --add-entry="Id klienta:" \
        --separator=" " \ )
        customer_id=$(echo "$result" | cut -d ' ' -f 1)
    done
    ./deleteFromDB.sh "$project_db" $customer_id "Customers" "cl"
    customers_window
};;
"8"){
    #usuniecie uslugi
    services_window
    infoWindow "W tle otworzyło się okno z usługami"
    service_id=""
    while [[ -z "$service_id" ]]; do
        result=$(zenity --forms --title="Wprowadź id usługi" \
        --add-entry="Id usługi:" \
        --separator=" " \ )
        service_id=$(echo "$result" | cut -d ' ' -f 1)
    done
    ./deleteFromDB.sh "$project_db" $service_id "Services" "usl"
    
    temp=$?
    if [[ $temp -eq 0 ]];then
        infoWindow "Usługa usunięta"
    fi
};;
"9") {
    customers_window
};;
"10") {
    services_window
};;
"11") {
    orders_window
    services_window
    infoWindow "W tle otworzyło się okno z informacją o usługach"
};;

esac

