# eXpress_network
## eXpress CTS network diagnostic

Для запуска скрипта потребуется:
1. Права суперпользователя
2. Положить скрипт в любую директорию
3. Выдача прав и запуск:
- a. Сделать скрип исполняемым и запустить   
```bash
chmod +x cts_network.sh
cts_network.sh
```
- b. Запустить через bash
```bash
bash cts_network.sh
```
Данный скрипт работает только на voex, single или front+back CTS

Скрипт собирает данные о доступности сервисов, сетевого взаимодействия и настроек:

- Redis
- Postgres
- Kafka
- Etcd
- iptables
- ip route
- nslookup ccs_host
- Telnet до registry.public.express
- Telnet до ru.public.express (RTS)
- Netstat (ss)
- Данные о SSL
- Копирование settings.yaml
- voex_redis
- Доступность Janus


Доступны ключи:

-h : справка

-np : удаляет пароли из settings.yaml

-ar : создает архив в той директории откуда был запущен скрипт и удаляет временную директорию

Пример команды с параметрами:

```bash
cts_network.sh -h
cts_network.sh -npar
```
или
```bash
bash cts_network.sh -ar
bash cts_network.sh -arnp
```