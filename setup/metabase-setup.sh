#!/bin/sh

echo "seting up $1"
# get deps
apk add curl jq
# get the wait-until script
curl -L https://raw.githubusercontent.com/nickjj/wait-until/v0.2.0/wait-until -o /usr/local/bin/wait-until && \
chmod +x /usr/local/bin/wait-until
# run the script and everything else
wait-until "echo 'Checking if Metabase is ready' && curl -s http://$1/api/health | grep -ioE 'ok'" 60 && \
if curl -s http://$1/api/session/properties | jq -r '."setup-token"' | grep -ioE "null"; then echo 'Instance already configured, exiting (or <v43)'; else \
echo 'Setting up the instance' && \
token=$(curl -s http://$1/api/session/properties | jq -r '."setup-token"') && \
echo 'Setup token fetched, now configuring with:' && \
echo "{'token':'$token','user':{'first_name':'a','last_name':'b','email':'a@b.com','site_name':'metabot1','password':'metabot1','password_confirm':'metabot1'},'database':null,'invite':null,'prefs':{'site_name':'metabot1','site_locale':'en','allow_tracking':'false'}}" > file.json && \
sed 's/'\''/\"/g' file.json > file2.json && \
cat file2.json && \
sessionToken=$(curl -s http://$1/api/setup -H 'Content-Type: application/json' --data-binary @file2.json | jq -r '.id') && echo ' < Admin session token, exiting' && \
# creating a postgres
curl -s -X POST http://$1/api/database -H 'Content-Type: application/json' --cookie "metabase.SESSION=$sessionToken" --data '{"engine":"mysql","name":"mariadb","details":{"host":"mariadb-data","port":"3306","dbname":"sample","user":"metabase","password":"metasample123","schema-filters-type":"all","ssl":false,"tunnel-enabled":false,"advanced-options":false},"is_full_sync":true}' &&
curl -s -X POST http://$1/api/database -H 'Content-Type: application/json' --cookie "metabase.SESSION=$sessionToken" --data '{"engine":"mysql","name":"mysql","details":{"host":"mysql-data","port":"3306","dbname":"sample","user":"metabase","password":"metasample123","schema-filters-type":"all","ssl":false,"tunnel-enabled":false,"advanced-options":false},"is_full_sync":true}' &&
curl -s -X POST http://$1/api/database -H 'Content-Type: application/json' --cookie "metabase.SESSION=$sessionToken" --data '{"engine":"mysql","name":"mariadb-ssh","details":{"host":"mariadb-data","dbname":"sample","user":"metabase","password":"metasample123","schema-filters-type":"all","ssl":false,"tunnel-enabled":true,"tunnel-host":"ssh-choke","tunnel-port":2222,"tunnel-user":"metabase","tunnel-auth-option":"ssh-key","tunnel-private-key":"-----BEGIN OPENSSH PRIVATE KEY-----\nb3BlbnNzaC1rZXktdjEAAAAACmFlczI1Ni1jdHIAAAAGYmNyeXB0AAAAGAAAABCUUjov89\na69l0fjxRMPj45AAAAEAAAAAEAAAAzAAAAC3NzaC1lZDI1NTE5AAAAINaVvzSukjVtGgdg\n7ejckHZ8PbbMif9lqk7Ws+1excxJAAAAoCQiHwFoeVomvkBtGlh+hQWleLNXTc3spMmzHA\niE4Pt00S3XIw2bhjISY/sasSNnSTPULujlBY3UbnCbR7BzHilmf43Q7/Bc575GutTJ0cnc\n7t6EAPhSl7lX7kXgLiHIf8RGrQuGlrTrfiGLhpojPEssV3GfBIzKiCd0VMxQmoEll2oIjJ\n+8JBM0XOdRtK80gb1oezAdOI1h4mjRfYUp95c=\n-----END OPENSSH PRIVATE KEY-----","tunnel-private-key-passphrase":"mysecretpassword","advanced-options":false},"is_full_sync":true}' &&
curl -s -X POST http://$1/api/database -H 'Content-Type: application/json' --cookie "metabase.SESSION=$sessionToken" --data '{"engine":"mysql","name":"mysql-ssh","details":{"host":"mysql-data","dbname":"sample","user":"metabase","password":"metasample123","schema-filters-type":"all","ssl":false,"tunnel-enabled":true,"tunnel-host":"ssh-choke","tunnel-port":2222,"tunnel-user":"metabase","tunnel-auth-option":"ssh-key","tunnel-private-key":"-----BEGIN OPENSSH PRIVATE KEY-----\nb3BlbnNzaC1rZXktdjEAAAAACmFlczI1Ni1jdHIAAAAGYmNyeXB0AAAAGAAAABCUUjov89\na69l0fjxRMPj45AAAAEAAAAAEAAAAzAAAAC3NzaC1lZDI1NTE5AAAAINaVvzSukjVtGgdg\n7ejckHZ8PbbMif9lqk7Ws+1excxJAAAAoCQiHwFoeVomvkBtGlh+hQWleLNXTc3spMmzHA\niE4Pt00S3XIw2bhjISY/sasSNnSTPULujlBY3UbnCbR7BzHilmf43Q7/Bc575GutTJ0cnc\n7t6EAPhSl7lX7kXgLiHIf8RGrQuGlrTrfiGLhpojPEssV3GfBIzKiCd0VMxQmoEll2oIjJ\n+8JBM0XOdRtK80gb1oezAdOI1h4mjRfYUp95c=\n-----END OPENSSH PRIVATE KEY-----","tunnel-private-key-passphrase":"mysecretpassword","advanced-options":false},"is_full_sync":true}' &&
curl -s -X DELETE http://$1/api/database/1 -H 'Content-Type: application/json' --cookie "metabase.SESSION=$sessionToken"; fi