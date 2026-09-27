ping:
	ansible hardening -m ping

galaxy:
	ansible-galaxy collection install -r ./ansible/requirements.yml

list:
	ansible hardening --list-hosts

hardening:
	ansible-playbook ./ansible/playbooks/hardening.yml

hardening-check:
	ansible-playbook ./ansible/playbooks/hardening.yml --check --diff
