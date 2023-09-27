
The kubectl commands below can be used to create a secret outside of the helm chart


### With included SQL pod
```
kubectl create secret generic custom-secret -n bitwarden\
    --from-literal=globalSettings__installation__id="e43fa955-8d18-4489-a828-afb201145e46" \
    --from-literal=globalSettings__installation__key="kp2msIQL62u3wotUiJDj" \
    --from-literal=globalSettings__mail__replyToEmail="testsecret@keithhubner.com" \
    --from-literal=globalSettings__mail__smtp__host="stmp.host" \
    --from-literal=globalSettings__mail__smtp__port="386" \
    --from-literal=globalSettings__mail__smtp__ssl="true" \
    --from-literal=globalSettings__yubico__clientId="REPLACE" \
    --from-literal=globalSettings__yubico__key="REPLACE" \
    --from-literal=SA_PASSWORD="REPLACE" 

```

### Bring your own SQL database
```
kubectl create secret generic custom-secret -n bitwarden\
    --from-literal=globalSettings__installation__id="e43fa955-8d18-4489-a828-afb201145e46" \
    --from-literal=globalSettings__installation__key="kp2msIQL62u3wotUiJDj" \
    --from-literal=globalSettings__mail__replyToEmail="testsecret@keithhubner.com" \
    --from-literal=globalSettings__mail__smtp__host="stmp.host" \
    --from-literal=globalSettings__mail__smtp__port="386" \
    --from-literal=globalSettings__mail__smtp__ssl="true" \
    --from-literal=globalSettings__sqlServer__connectionString="Data Source=tcp:<SERVERNAME>,1433;Initial Catalog=vault;Persist Security Info=False;User ID=<USER>;Password=<PASSWORD>;Multiple Active Result Sets=False;Connect Timeout=30;Encrypt=True;Trust Server Certificate=True" \
    --from-literal=globalSettings__yubico__clientId="REPLACE" \
    --from-literal=globalSettings__yubico__key="REPLACE" \

```