ping:
	ansible hardening -m ping

galaxy:
	ansible-galaxy collection install -r ./ansible/requirements.yml

hardening:
	ansible-playbook ./ansible/playbooks/hardening.yml --ask-vault-pass

list:
	ansible hardening --list-hosts

headscale:
	ansible-playbook ./ansible/playbooks/headscale.yml --ask-vault-pass

headscale-acl:
	ansible-playbook ./ansible/playbooks/headscale-acl.yml --ask-vault-pass

utilities:
	ansible-playbook ./ansible/playbooks/utilities.yml --ask-vault-pass

k3s:
	ansible-playbook ./ansible/playbooks/k3s.yml --ask-vault-pass

vault: 
	ansible-vault edit ./ansible/inventory/group_vars/vault.yml

