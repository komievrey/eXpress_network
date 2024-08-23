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
Данный скрипт работает только на single или front+back CTS

Сприпт собирает данные о доступности сервисов и сетевого взаимодействия и настроек:

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
- Даннные о SSL
- Копирование settings.yaml
- voex_redis
- Доступность Janus


Доступны ключи:

--help / -h : справка

--nopass / -np : сирает пароли из settings.yaml

--noarchive / -na : не создает архив

Пример команды с ключем:

```bash
cts_network.sh --nopass
```
или
```bash
bash cts_network.sh --help
```