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
	oc rsh -n openshift-authentication \
        $$(oc get pod -n openshift-authentication | head -2 | tail -1 | cut -d" " -f1) \
        cat /run/secrets/kubernetes.io/serviceaccount/ca.crt > openshift/auth/ingress-ca.crt && \
        sudo apt-get install -y ca-certificates && \
        sudo cp openshift/auth/ingress-ca.crt /usr/local/share/ca-certificates && \
        sudo update-ca-certificates


configure-registry:
	oc apply -f image-registry-storage-pvc.yaml && \
    oc patch configs.imageregistry.operator.openshift.io cluster --type merge --patch '{"spec":{"managementState":"Managed"}}' && \
    oc patch config.imageregistry.operator.openshift.io/cluster --type=merge -p '{"spec":{"rolloutStrategy":"Recreate","replicas":1}}' && \
    oc patch configs.imageregistry.operator.openshift.io --type=merge -p '{"spec":{"storage":{"managementState": "Managed", "pvc": {"claim": "image-registry-storage"}}}}' && \
    oc patch configs.imageregistry.operator.openshift.io/cluster --patch '{"spec":{"defaultRoute":true}}' --type=merge && \
    HOST=$$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}') && \
    oc get secret -n openshift-ingress router-certs-default -o go-template='{{index .data "tls.crt"}}' | base64 -d | sudo tee /etc/pki/ca-trust/source/anchors/$${HOST}.crt  > /dev/null && \
    sudo update-ca-trust enable && \
    sudo podman login -u kubeadmin -p $(oc whoami -t) $HOST

attach-data-nics:
	cd clusters/lab; terraform apply -auto-approve -var 'attach_data_nics=true'
