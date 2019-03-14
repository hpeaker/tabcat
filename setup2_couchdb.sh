#!/usr/bin/env bash

# Bash script to set up Couch DB for Tabcat
# Expects COUCHDB_URL environment variable to be set to point to Couch DB URL. E.g. http://127.0.0.1:5984

CONFIG_URL=$COUCHDB_URL/_node/_local/_config
HTTPD_AUTH_SECTION=$CONFIG_URL/couch_httpd_auth
UUIDS_SECTION=$CONFIG_URL/uuids
ADMINS_SECTION=$CONFIG_URL/admins
USERS_SECTION=$COUCHDB_URL/_users
HTTPD_SECTION=$CONFIG_URL/httpd

#echo "Creating admin user ..."
#echo "Please enter Admin user's id:"
#read ADMIN_USER
#echo "Please enter Admin user's password:"
#read -s ADMIN_PASSWORD
#curl -X PUT $ADMINS_SECTION/$ADMIN_USER -d '"'$ADMIN_PASSWORD'"'

AUTH_STRING=$ADMIN

# Create required databases
curl -u $AUTH_STRING -X PUT $USERS_SECTION
curl -u $AUTH_STRING -X PUT $COUCHDB_URL/_replicator
curl -u $AUTH_STRING -X PUT $COUCHDB_URL/_global_changes

echo "Creating tabcat user ..."
TABCAT_PASSWORD=$(cat /dev/urandom | env LC_CTYPE=C tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
curl -u $AUTH_STRING --header "Content-Type: application/json" -X PUT $USERS_SECTION/org.couchdb.user:tabcat -d '{"name":"tabcat", "password": "'$TABCAT_PASSWORD'", "type": "user", "roles": []}'
echo $TABCAT_PASSWORD > .tabcat_password

#adding sandbox user by default
curl -u $AUTH_STRING --header "Content-Type: application/json" -X PUT $USERS_SECTION/org.couchdb.user:s@ndbox -d '{"name":"s@ndbox", "password": "s@ndbox", "type": "user", "roles": []}'

echo "Please enter database user's email address:"
read USER_EMAIL

for db in tabcat tabcat-data
do
    echo "Creating '$db' database with correct permissions..."
    curl -u $AUTH_STRING --header "Content-Type: application/json" -X PUT $COUCHDB_URL/$db
done

#the tabcat database needs an empty members section
curl -u $AUTH_STRING --header "Content-Type: application/json" -X PUT $COUCHDB_URL/tabcat/_security -d '{"admins":{"names":["tabcat"],"roles":["admins"]}}'
curl -u $AUTH_STRING --header "Content-Type: application/json" -X PUT $COUCHDB_URL/tabcat-data/_security -d '{"admins":{"names":["tabcat"],"roles":["admins"]},"members":{"names":["'$USER_EMAIL'", "s@ndbox"]}}'

echo "Configuring couch_httpd_auth ..."
curl -u $AUTH_STRING --header "Content-Type: application/json" -X PUT $HTTPD_AUTH_SECTION/allow_persistent_cookies -d '"true"'
curl -u $AUTH_STRING --header "Content-Type: application/json" -X PUT $HTTPD_AUTH_SECTION/timeout -d '"3600"'

echo "Configuring httpd ..."
curl -u $AUTH_STRING --header "Content-Type: application/json" -X PUT $HTTPD_SECTION/bind_address -d '"0.0.0.0"'

echo "Configuring uuids ..."
curl -u $AUTH_STRING --header "Content-Type: application/json" -X PUT $UUIDS_SECTION/algorithm -d '"random"'
