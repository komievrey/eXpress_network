#!/bin/bash

# Функции для каждого ключа
function use_ipv4() {
    echo "Используется IPv4"
}

function use_ipv6() {
    echo "Используется IPv6"
}

function allow_broadcast() {
    echo "Разрешено широковещательное вещание"
}

# Проверка переданных аргументов
for arg in "$@"; do
    case $arg in
        -4)
            use_ipv4
            ;;
        -6)
            use_ipv6
            ;;
        -b)
            allow_broadcast
            ;;
        *)
            echo "Неизвестный ключ: $arg"
            ;;
    esac
done



if [ "$nopass" = true ]; then
    echo "No password option selected."
    CheckSettingsNoPass
    CreateArchive
fi

if [ "$noarchive" = true ]; then
    echo "No archive option selected."
    
fi


if [ "$nopass" = false ] && [ "$noarchive" = false ]; then
    echo "No specific options selected; proceeding with default operations."
    CreateArchive
fi
