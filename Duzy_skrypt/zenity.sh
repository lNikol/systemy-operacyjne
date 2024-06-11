#!/bin/bash

help(){
    punkt=$1
    case "$punkt" in 
    "1") echo "1. Dodawanie administratora/logowanie: Naciśnij, aby rozpocząć pracę, wpisując imię użytkownika i hasło." ;;
    "2") echo "2. Polecenia. Wpisz odpowiedni numer polecenia (np. 2.1)" ;;
    "2.1") echo "2.1 Dodawanie usługi: Dodaje nową usługę do bazy danych." ;;
    "2.2") echo "2.2 Edytowanie usługi: Edytuje istniejącą usługę w bazie danych. Trzeba wpisać ID usługi." ;;
    "2.3") echo "2.3 Dodawanie klienta: Dodaje nowego klienta do bazy danych. Trzeba wpisać go dane." ;;
    "2.4") echo "2.4 Dodawanie zamówienia: Dodaje nowe zamówienie do bazy danych. Trzeba wpisać ID klienta" ;;
    "2.5") echo "2.5 Edytowanie klienta: Edytuje dane istniejącego klienta po ID." ;;
    "2.6") echo "2.6 Usunięcie zamówienia: Usuwa istniejące zamówienie z bazy danych po ID zamówienia." ;;
    "2.7") echo "2.7 Usunięcie klienta: Usuwa istniejącego klienta z bazy danych po ID klienta." ;;
    "2.8") echo "2.8 Usunięcie usługi: Usuwa istniejącą usługę z bazy danych po ID usługi." ;;
    "2.9") echo "2.9 Pokazać klientów: Wyświetla listę wszystkich klientów." ;;
    "2.10") echo "2.10 Pokazać usługi: Wyświetla listę wszystkich usług." ;;
    "2.11") echo "2.11 Pokazać zamówienia: Wyświetla listę wszystkich zamówień." ;;
    "2.12") echo "2.12 Koniec: Kończy działanie programu." ;;
    *) echo "Nie napisana usługa do $punkt" ;;
    esac
}

temp=2
while getopts "h:v" OPT; do
    case "$OPT" in
        "h") argument=$OPTARG
            help "$argument"
            temp=0
            ;;
        "v") echo "1.5.0"; temp=0;;
        *) echo "Invalid option: -$OPT"
            temp=1
            exit 1 ;;
    esac
done

# Sprawdzenie, czy zostały podane jakiekolwiek opcje
if [ $temp != 2 ]; then
    exit 1
fi


WINDOW_SIZE=500
source ./zenity_service.sh
ZENITY_SCRIPT="./zenity_service.sh "
USER_NAME=""
USER_PASSWORD="false"
project_db="project.db"


polecenia(){
    if [[ "$USER_PASSWORD" == "true" ]]; then
        menu=("1. Dodawanie usługi" "2. Edytowanie usługi" "3. Dodawanie klienta" "4. Dodawanie zamówienia" "5. Edytowanie klienta" 
        "6. Usunięcie zamówienia" "7. Usunięcie klienta" "8. Usunięcie usługi" "9. Pokazać klientów" 
        "10. Pokazać usługi" "11. Pokazać zamówienia" "12. Koniec" )
        CHOICE=`zenity --list --column=Menu "${menu[@]}" --height $WINDOW_SIZE --width $WINDOW_SIZE`
        case $CHOICE in
            "1. Dodawanie usługi") $ZENITY_SCRIPT "$project_db" "1";;
            "2. Edytowanie usługi") $ZENITY_SCRIPT "$project_db" "2";;
            "3. Dodawanie klienta") $ZENITY_SCRIPT "$project_db" "3";;
            "4. Dodawanie zamówienia") $ZENITY_SCRIPT "$project_db" "4";;
            "5. Edytowanie klienta") $ZENITY_SCRIPT "$project_db" "5";;
            "6. Usunięcie zamówienia") $ZENITY_SCRIPT "$project_db" "6";;
            "7. Usunięcie klienta") $ZENITY_SCRIPT "$project_db" "7";;
            "8. Usunięcie usługi") $ZENITY_SCRIPT "$project_db" "8";;
            "9. Pokazać klientów") $ZENITY_SCRIPT "$project_db" "9";;
            "10. Pokazać usługi") $ZENITY_SCRIPT "$project_db" "10";;
            "11. Pokazać zamówienia") $ZENITY_SCRIPT "$project_db" "11";;
            "12. Koniec");;
        esac
    else
        errorWindow "Nie jesteś zalogowany, zaloguj się"
    fi
}

CHOICE=0
while [[ $CHOICE != "3. Koniec" ]]; do #&& $CHOICE != ""
    menu=("1. Dodawanie administratora/logowanie" "2. Polecenia" "3. Koniec" "4. Author: Nikolai Lavrinov 201302")
    CHOICE=`zenity --list --column=Menu "${menu[@]}" --height $WINDOW_SIZE --width $WINDOW_SIZE`

    case $CHOICE in
    "1. Dodawanie administratora/logowanie") {
        if [[ "$USER_PASSWORD" == "false" ]];then
        tmpfile=$(mktemp)
            while [[ "$USER_PASSWORD" != "true" ]]; do
                echo "$USER_NAME" "$USER_PASSWORD" > "$tmpfile"
                $ZENITY_SCRIPT "$project_db" "0" "$tmpfile"
                read USER_NAME USER_PASSWORD < "$tmpfile"
                if [[ "$USER_PASSWORD" == "true" ]]; then
                    temp="t"
                fi
            done
        fi
    };;
    "2. Polecenia") polecenia;;
    "3. Koniec");;
    *) echo $CHOICE ;;

    esac
done
