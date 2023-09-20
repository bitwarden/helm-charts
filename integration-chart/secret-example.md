
The kubectl command below can be used to create a secret outside of the helm chart

```
kubectl create secret generic custom-secret -n bitwarden\
    --from-literal=globalSettings__installation__id="e43fa955-8d18-4489-a828-afb201145e46" \
    --from-literal=globalSettings__installation__key="kp2msIQL62u3wotUiJDj" \
    --from-literal=globalSettings__mail__replyToEmail="testsecret@keithhubner.com" \
    --from-literal=globalSettings__mail__smtp__host="stmp.host" \
    --from-literal=globalSettings__mail__smtp__port="386" \
    --from-literal=globalSettings__mail__smtp__ssl="true" \
    --from-literal=globalSettings__sqlServer__connectionString="Data Source=tcp:bitwarden-mssql,1433;Initial Catalog=vault;Persist Security Info=False;User ID=sa;Password=FE*dLh9%rLusb&5xDy;Multiple Active Result Sets=False;Connect Timeout=30;Encrypt=True;Trust Server Certificate=True" \
    --from-literal=globalSettings__yubico__clientId="REPLACE" \
    --from-literal=globalSettings__yubico__key="REPLACE" \
    --from-literal=SA_PASSWORD="FE*dLh9%rLusb&5xDy" 

```