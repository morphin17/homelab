ping:
	ansible all -i ./ansible/hosts.yml -m ping

galaxy:
	ansible-galaxy collection install -r ./ansible/requirements.yml

