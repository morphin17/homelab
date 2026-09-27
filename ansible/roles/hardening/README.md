# hardening

Базовая настройка сервера на Debian/Ubuntu: создание sudo-пользователя с SSH-ключом,
запрет root-логина и смена порта SSH, UFW с ограничением частоты подключений на порт SSH.

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

## После первого прогона

Роль меняет порт SSH и отключает вход под root, поэтому для дальнейшей работы Ansible
нужно переключить хост на нового пользователя и новый порт:

```yaml
ansible_user: charon
ansible_port: 2222
```

Без этого следующий запуск любого плейбука упрётся в `unreachable`. Для sudo по паролю
дополнительно нужен `ansible_become_password` (тоже из vault) или `NOPASSWD` в sudoers.
