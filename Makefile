tfinit:
	cd clusters/lab; terraform init

lab:
	./generate-configs.sh
	cd clusters/lab; terraform apply -auto-approve

nukelab:
	cd clusters/lab; terraform destroy	

remove-bootstrap-lab:
	cd clusters/lab; terraform apply -auto-approve -var 'bootstrap_complete=true'

wait-for-bootstrap:
	cd openshift; openshift-install wait-for bootstrap-complete --log-level debug

wait-for-install:
	cd openshift; openshift-install wait-for install-complete --log-level debug

check-install:
	oc --kubeconfig openshift/auth/kubeconfig get nodes && echo "" && \
	oc --kubeconfig openshift/auth/kubeconfig get co && echo "" && \
	oc --kubeconfig openshift/auth/kubeconfig get csr

# lazy because it auto approves CSRs - not production suitable!
lazy-install:
	oc --kubeconfig openshift/auth/kubeconfig get nodes && echo "" && \
	oc --kubeconfig openshift/auth/kubeconfig get co && echo "" && \
	oc --kubeconfig openshift/auth/kubeconfig get csr && \
	oc --kubeconfig openshift/auth/kubeconfig get csr -ojson | \
		jq -r '.items[] | select(.status == {} ) | .metadata.name' | \
		xargs oc --kubeconfig openshift/auth/kubeconfig adm certificate approve

get-co:
	oc --kubeconfig openshift/auth/kubeconfig get co

get-nodes:
	oc --kubeconfig openshift/auth/kubeconfig get nodes

get-csr:
	oc --kubeconfig openshift/auth/kubeconfig get csr

approve-csr:
	oc --kubeconfig openshift/auth/kubeconfig get csr -ojson | \
		jq -r '.items[] | select(.status == {} ) | .metadata.name' | \
		xargs oc --kubeconfig openshift/auth/kubeconfig adm certificate approve

import-ova:
	. ~/.govc/config && govc import.ova --folder=coreos --ds=Garage --name=coreos-template https://mirror.openshift.com/pub/openshift-v4/x86_64/dependencies/rhcos/4.10/4.10.37/rhcos-4.10.37-x86_64-vmware.x86_64.ova

remove-ova:
	. ~/.govc/config && govc vm.destroy coreos-template

kraken:
	docker run --name=kraken --net=host -v /Users/alex/git/ib/ocp4/openshift/auth/kubeconfig:/root/.kube/config -v /Users/alex/git/ib/ocp4/kraken/config/config.yaml:/root/kraken/config/config.yaml -d quay.io/openshift-scale/kraken:latest

import-ca:
	@echo "========= THIS WORKS ONLY ON UBUNTU LINUX, FOR OTHER OS INSTALL CERTIFICATE MANUALLY =========="
	oc rsh -n openshift-authentication \
        $$(oc get pod -n openshift-authentication | head -2 | tail -1 | cut -d" " -f1) \
        cat /run/secrets/kubernetes.io/serviceaccount/ca.crt > openshift/auth/ingress-ca.crt && \
        sudo apt-get install -y ca-certificates && \
        sudo cp openshift/auth/ingress-ca.crt /usr/local/share/ca-certificates && \
        sudo update-ca-certificates
	@echo "==============================================================================================="


configure-registry:
	@set -e
	@echo "Configuring registry"
	@oc login -u kubeadmin -p `cat openshift/auth/kubeadmin-password`

	@oc --kubeconfig openshift/auth/kubeconfig apply -f image-registry-storage-pvc.yaml
	@oc --kubeconfig openshift/auth/kubeconfig patch configs.imageregistry.operator.openshift.io cluster --type merge --patch '{"spec":{"managementState":"Managed"}}'
	@oc --kubeconfig openshift/auth/kubeconfig patch config.imageregistry.operator.openshift.io/cluster --type=merge -p '{"spec":{"rolloutStrategy":"Recreate","replicas":1}}'
	@oc --kubeconfig openshift/auth/kubeconfig patch configs.imageregistry.operator.openshift.io/cluster --patch '{"spec":{"defaultRoute":true}}' --type=merge
	@echo -e "=============================== EDIT THIS PART MANUALLY ============================="
	@echo "$ oc --kubeconfig openshift/auth/kubeconfig edit configs.imageregistry.operator.openshift.io"
	@echo -e "Edit the 'storage' to resemble this:\n\nstorage:\n  pvc:\n    claim:\n"
	@echo "====================================================================================="
	@read -p "Press Enter to continue" ans
	@HOST=$$(oc --kubeconfig openshift/auth/kubeconfig get route default-route -n openshift-image-registry --template='{{ .spec.host }}'); \
	if ! oc --kubeconfig openshift/auth/kubeconfig whoami -t > /dev/null; then \
		@echo "=============================== NEED TO LOG IN TO OPENSHIFT ========================="; \
		@LOGIN_ADDR=$$(oc --kubeconfig openshift/auth/kubeconfig get route -n openshift-authentication oauth-openshift --template='{{ .spec.host }}'); \
		@API_ADDR="https://api.$$(echo -n $$LOGIN_ADDR | awk '{sub(/.*.apps./,""); print}':6443)"; \
		@echo "Log in to https://$LOGIN_ADDR/oauth/token/request with username kubeadmin and password $$(cat openshift/kubeadmin-password) and paste it here, then press Enter"; \
		@read -p token ;\
		oc login --token="$$token" --server="$$API_ADDR" ;\
	fi ; \
	which podman >/dev/null && podman_cmd=podman || podman_cmd=docker; \
	sudo $$podman_cmd login --username kubeadmin --password $(oc --kubeconfig openshift/auth/kubeconfig whoami -t) "$$HOST" || echo "Podman not installed, cannot test!" ; \
	$$podman_cmd manifest inspect default-route-openshift-image-registry.apps.ocp410.coreos.lan/openshift/driver-toolkit >/dev/null || echo "Failed to find driver-buildkit"


attach-data-nics:
	cd clusters/lab; terraform apply -auto-approve -var 'attach_data_nics=true'
