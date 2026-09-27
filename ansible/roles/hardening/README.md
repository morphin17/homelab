# hardening

Базовая настройка сервера на Debian/Ubuntu: создание sudo-пользователя с SSH-ключом,
sudo без пароля, запрет root-логина и смена порта SSH, UFW с ограничением частоты
подключений на порт SSH. Завершается перезагрузкой хоста.

## Переменные

| Переменная        | Значение по умолчанию | Описание                                             |
| ----------------- | --------------------- | ---------------------------------------------------- |
| `user`            | `admin`               | Пользователь с sudo, которого создаёт роль            |
| `ssh_port`        | `22`                  | Порт, на который переводится SSH                      |
| `password`        | —                     | Пароль этого пользователя (в vault)                   |
| `password_salt`   | —                     | Соль для `password_hash` (в vault)                    |
| `copy_local_key`  | публичный ключ `~/.ssh/id_ed25519.pub` с машины, откуда запускается плейбук | Ключ для `authorized_key` |

## Запуск

Роль применяется к группе `hardening` из `inventory/hosts.yml` через `playbooks/hardening.yml`:

```bash
ansible-playbook ansible/playbooks/hardening.yml --limit <host> --check --diff
ansible-playbook ansible/playbooks/hardening.yml --limit <host>
```

## Перезагрузка в конце

Последние три задачи роли перезагружают хост (`async` + `systemctl reboot`), а затем
переподключаются уже на новом порту `ssh_port`: `set_fact` подменяет `ansible_port`
на время этого прогона, и `wait_for_connection` ждёт машину там. Поэтому отдельного
`ansible_port` в inventory для первого прогона не нужно — но в последующих запусках
порт в inventory должен совпадать с `ssh_port`, иначе Ansible просто не подключится.

Рестарт служб роль больше не делает: sshd и UFW подхватывают настройки при загрузке.
В режиме `--check` перезагрузка пропускается (иначе `make hardening-check` перезагружал
бы прод).

Проверить на сервере: `uptime -s` (время загрузки — должно быть только что) и
`ss -tlnp | grep sshd` (слушает порт из `ssh_port`).

## После первого прогона

Роль меняет порт SSH и отключает вход под root, поэтому для дальнейшей работы Ansible
нужно переключить хост на нового пользователя и новый порт:

```yaml
ansible_user: ansible
ansible_port: 2222  # должен совпадать с ssh_port группы hardening
```

Без этого следующий запуск любого плейбука упрётся в `unreachable`.

Роль кладёт `/etc/sudoers.d/90-<user>` с `NOPASSWD:ALL`. На настройку самого хоста это
влияет так: пока файла нет, `become: true` под этим пользователем требует пароль —
то есть первый прогон (и `--check`) запускается с `-K`/`ansible_become_password`, а все
последующие уже идут без пароля. Отдельных `ansible_become_password` для группы `hardening`
после этого можно не заводить.

```bash
ansible-playbook ansible/playbooks/hardening.yml --limit node1 --check --diff -K
ansible-playbook ansible/playbooks/hardening.yml --limit node1 -K
```

Проверить на сервере: `sudo -n true` (успех без запроса пароля) и
`sudo -l | grep NOPASSWD`. Откат — удалить файл: `sudo rm /etc/sudoers.d/90-<user>`.
