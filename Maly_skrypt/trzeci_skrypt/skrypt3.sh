#!/bin/bash -f

WYBOR=0
while [[ $WYBOR != "Koniec" && $WYBOR != "" ]]; do
    menu=("Nazwa_pliku" "Katalog" "Rozmiar" "Prawo" "Czas_modyfikacji" "Zawartość" "Szukaj" "Koniec")
    WYBOR=`zenity --list --column=Menu "${menu[@]}" --height 400 `
    case $WYBOR in
    "Nazwa_pliku") PLIK=`zenity --entry --title "Nazwa pliku" --text "Wpisz nazwę pliku"  --height 150 ` ;;
    "Katalog") KATALOG=`zenity --entry --title "Nazwa katalogu" --text "Wpisz nazwę katalogu"  --height 150 ` ;;
    "Rozmiar") ROZMIAR=`zenity --entry --title "Rozmiar" --text "Wpisz rozmiar pliku (- oznaca mniejsze niż, + oznacza większe niż)" --height 150 ` ;;
    "Prawo") PRAWO=`zenity --entry --title "Prawo" --text "Wpisz prawo szukanego pliku (np. 777)" --height 150 ` ;;
    "Czas_modyfikacji") MODYF=`zenity --entry --title "Czas modyfikacji" --text "Czas modyfikacji pliku (w ciągu ostatnich X zwykła liczba)" --height 150 ` ;;
    "Zawartość") ZAWARTOSC=`zenity --entry --title "Zawartość" --text "Jaka musi być zawartość pliku?" --height 150 ` ;;
    "Szukaj") 
     
    if [ -n "$KATALOG" ]; then
        DIR=" $KATALOG"
    else
        DIR=""
    fi
    
    if [ -n "$PLIK" ]; then
        NAME=" -name $PLIK"
    else
        NAME=""
    fi
    
    if [ -n "$ROZMIAR" ]; then
        SIZE=" -size $ROZMIAR"
    else 
        SIZE=""
    fi

    if [ -n "$PRAWO" ]; then
    	RULES=" -perm $PRAWO"
    else
        RULES=""
    fi
    
    if [ -n "$MODYF" ]; then
    	MOD=" -mtime -$MODYF"
    else
        MOD=""
    fi
    
    if [ -n "$ZAWARTOSC" ]; then
    	CONTENT=" -type f -exec grep -l $ZAWARTOSC {} ;"
    else
        CONTENT=""
    fi
    
echo ${DIR}${NAME}${SIZE}${MOD}${RULES}${CONTENT}

    find ${DIR}${NAME}${SIZE}${MOD}${RULES}${CONTENT} | zenity --text-info --height 400 --width 400 --title "Rezultat szukania" ;;
    "") zenity --info --title "Koniec" --text "Koniec programu" ;;
    "Koniec") zenity --info --title "Koniec" --text "Koniec programu" ;;
    
    *) zenity --error --text "Brak opcji wyboru" ;;
    esac
done

