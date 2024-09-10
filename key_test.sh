#!/bin/bash

Help() {
    echo "Справка по использованию скрипта"
}

CheckSettingsNoPass() {
    echo "Выполняется CheckSettingsNoPass"
}

CreateArchive() {
    echo "Выполняется CreateArchive"
}

Start() {
    echo "Запуск без ключей"
}

# Проверка на использование -h с другими ключами
if [[ "$*" == *"-h"* && "$*" != "-h" ]]; then
    echo "Ключ -h не может использоваться с другими ключами"
    exit 1
fi

# Обработка ключей
if [[ "$*" == *"-np"* || "$*" == *"-npar"* || "$*" == *"-arnp"* ]]; then
    CheckSettingsNoPass
fi

for arg in "$@"; do
    case $arg in
        -h)
            Help
            ;;
        -np)
            # CheckSettingsNoPass уже выполнена
            ;;
        -ar)
            CreateArchive
            ;;
        -npar)
            CreateArchive
            ;;
        -arnp)
            CreateArchive
            ;;
        *)
            echo "Неизвестный ключ: $arg"
            ;;
    esac
done

# Если не переданы никакие ключи, запускаем Start
if [ $# -eq 0 ]; then
    Start
fi
