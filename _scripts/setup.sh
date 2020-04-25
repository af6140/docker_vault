## CONFIG LOCAL ENV
echo "[*] Config local environment..."
alias vault='docker-compose exec -T vault vault "$@"'
alias vault_term='docker-compose exec vault vault "$@"'
export VAULT_ADDR=http://127.0.0.1:8200

if [ ! -f ./_data/keys.txt ]; then    
    ## INIT VAULT
    echo "[*] Init vault..."
    vault operator init -address=${VAULT_ADDR} -format="table" > ./_data/keys.txt    
else 
    echo 'Existing ./_data/keys.txt'    
    echo 'Skip initializing'
fi
export VAULT_TOKEN=$(grep 'Initial Root Token:' ./_data/keys.txt | awk '{print substr($NF, 1, length($NF)-1)}')

sleep 3

## UNSEAL VAULT
echo "[*] Unseal vault..."
vault operator unseal -address=${VAULT_ADDR} $(grep 'Key 1:' ./_data/keys.txt | awk '{print $NF}')
sleep 2
echo "[*] Unseal vault... key2"
vault operator unseal -address=${VAULT_ADDR} $(grep 'Key 2:' ./_data/keys.txt | awk '{print $NF}')
sleep 2
echo "[*] Unseal vault... key3"
vault operator unseal -address=${VAULT_ADDR} $(grep 'Key 3:' ./_data/keys.txt | awk '{print $NF}')
sleep 2
echo "[*] Unseal finised"

## AUTH
echo "[*] Login... login --address=${VAULT_ADDR} token=${VAULT_TOKEN}"
#vault_term login -address=${VAULT_ADDR} token=${VAULT_TOKEN}

## CREATE USER
echo "[*] Create user... Remember to change the defaults!!"
vault auth enable  -address=${VAULT_ADDR} userpass
vault policy write -address=${VAULT_ADDR} admin ./config/admin.hcl
vault write -address=${VAULT_ADDR} auth/userpass/users/webui password=webui policies=admin

## CREATE BACKUP TOKEN
echo "[*] Create backup token..."
if [ ! $(grep -q 'backup_token' ./_data/keys.txt) ]; then
    vault token create -address=${VAULT_ADDR} -display-name="backup_token" | awk '/token/{i++}i==2' | awk '{print "backup_token: " $2}' >> ./_data/keys.txt
else 
    echo 'backup token exist'
fi

## MOUNTS
echo "[*] Creating new mount point..."
#vault mounts -address=${VAULT_ADDR}
#vault mount  -address=${VAULT_ADDR} -path=assessment -description="Secrets used in the assessment" generic
#vault write  -address=${VAULT_ADDR} assessment/server1_ad value1=name value2=pwd

## READ/WRITE
# $ vault write -address=${VAULT_ADDR} secret/api-key value=12345678
# $ vault read -address=${VAULT_ADDR} secret/api-key