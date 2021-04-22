alias cp='cp -i'
alias mv='mv -i'
alias vi='vim'
alias curl-status-code='curl --silent --output /dev/null --write-out "%{http_code}\n"'
alias config-dump='kubectl exec $(kubectl get pod --selector istio=ingressgateway --namespace istio-system --output jsonpath={.items..metadata.name}) --namespace istio-system -- curl --silent "http://localhost:15000/config_dump" | jq --sort-keys'

