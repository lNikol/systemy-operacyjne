#!/bin/bash -f

menu(){
    echo -e "\n"
    local LICZ=1
    for N in "Nazwa pliku" "Katalog" "Rozmiar" "Prawo" "Czas modyfikacji" "Zawartość" "Szukaj" "Koniec"; do
    echo "$LICZ. $N"
    LICZ=$[LICZ+1]
    done
}

WYBOR=0
while [[ $WYBOR != 8 && $WYBOR -lt 9 && $WYBOR -gt -1 ]]; do
    menu
    read WYBOR
    case $WYBOR in
    1) echo "Wpisz nazwę pliku"; read PLIK ;;
    2) echo "Wpisz nazwę katalogu"; read KATALOG ;;
    3) echo "Wpisz rozmiar pliku (- oznaca mniejsze niż, + oznacza większe niż)"; read ROZMIAR ;;
    4) echo "Wpisz prawo szukanego pliku (np. 777)"; read PRAWO ;;
    5) echo "Czas modyfikacji pliku (w ciągu ostatnich X zwykła liczba)"; read MODYF ;;
    6) echo "Jaka musi być zawartość pliku?"; read ZAWARTOSC ;;
    7) 
     
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
    echo -e "\n"
    echo ${DIR}${NAME}${SIZE}${MOD}${RULES}${CONTENT}
    find ${DIR}${NAME}${SIZE}${MOD}${RULES}${CONTENT} ;;
    8) echo "Koniec programu" ;;
    *) echo "Brak opcji wyboru" ;;
    esac
done

