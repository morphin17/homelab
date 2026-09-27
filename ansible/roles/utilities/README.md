# utilities

Полезные утилиты для интерактивной работы на сервере.

| Утилита            | Откуда                                                          |
| ------------------ | --------------------------------------------------------------- |
| `neovim`           | apt                                                              |
| `tmux`             | apt                                                              |
| `net-tools`        | apt (`ifconfig`, `netstat`, `route`, …)                           |
| `xz-utils`         | apt — нужен apt-модулю для распаковки control-файла `.deb`        |
| `curl`, `tar`, `ca-certificates` | apt — зависимости установки lazydocker               |
| `lazydocker`       | официальный `install_update_linux.sh` → `/usr/local/bin/lazydocker` |
| `k9s`              | `.deb` с GitHub Releases → `apt` (URL через параметр `deb`)        |

`neovim` из apt — это версия из репозитория дистрибутива (в Ubuntu 24.04 — 0.9.5).
Если понадобится свежее, ставить нужно не apt-пакетом, а официальной сборкой с GitHub.

## Переменные

| Переменная                       | Значение по умолчанию            | Описание                                  |
| -------------------------------- | -------------------------------- | ----------------------------------------- |
| `utilities_packages`             | список из `defaults/main.yml`    | apt-пакеты, которые ставятся одной задачей |
| `lazydocker_bin_dir`             | `/usr/local/bin`                 | Каталог, куда ложится бинарь lazydocker   |
| `lazydocker_install_script_url`  | URL скрипта в репозитории lazydocker | Откуда качать install-скрипт          |
| `k9s_deb_url`                    | `…/k9s/releases/latest/download/k9s_linux_amd64.deb` | URL `.deb`-пакета k9s |

## Запуск

```bash
ansible-playbook ansible/playbooks/utilities.yml --limit node1 --check --diff
ansible-playbook ansible/playbooks/utilities.yml --limit node1
make utilities          # то же самое
make utilities-check    # то же с --check --diff
```

## lazydocker

Скрипт `install_update_linux.sh` — не модуль Ansible, а обычный bash-скрипт: он берёт
latest-релиз с GitHub и делает `install -Dm 755`. Два момента, из-за которых роль
выглядит не совсем так, как «curl … | bash» руками:

- **`environment: DIR: /usr/local/bin`.** В скрипте каталог установки берётся из
  `DIR="${DIR:-"$HOME/.local/bin"}"`, поэтому вместо установки в `~/.local/bin` и
  последующего `mv` мы сразу указываем целевой каталог. Иначе бинарь оказался бы в
  `/root/.local/bin` (роль работает через `become`) — каталоге, которого нет в `PATH`.
- **`set -o pipefail` + `executable: /bin/bash`.** Без `pipefail` упавший `curl`
  выглядел бы как успех: `bash` на пустом вводе читает пустой скрипт и выходит с кодом 0.
  `pipefail` в dash не поддерживается, поэтому команда выполняется через bash.
- **`creates: /usr/local/bin/lazydocker`** делает задачу идемпотентной — повторный
  прогон роли не ходит в сеть. Обновить lazydocker до свежего релиза:

```bash
rm /usr/local/bin/lazydocker && make utilities
```

Либо убрать `creates` из задачи — тогда каждый прогон будет тянуть latest-релиз
(и каждый прогон будет что-то «менять»).

## k9s

Ставится одной задачей `apt` с URL в параметре `deb`. Модуль сам делает то, что
руками делают тремя командами (`wget … && apt install ./… && rm …`):

- скачивает `.deb` во временный файл (в пути есть `://` — это триггер загрузки);
- ставит его через `dpkg`, подтягивая зависимости;
- удаляет скачанный файл во временном каталоге.

Задача идемпотентна: модуль читает версию из control-файла пакета и сравнивает её с
установленной — если совпадают, установка пропускается (`ok`, а не `changed`). Так как
в URL стоит `latest`, появление нового релиза k9s само по себе приведёт к установке
при следующем `make utilities`; версия не закреплена намеренно.

`xz-utils` в `utilities_packages` — не утилита для работы, а зависимость этого
способа установки: `python3-apt` распаковывает им `control.tar.xz` из `.deb`.
