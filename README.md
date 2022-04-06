# 💡 couchbase-syncgateway
An example of running Couchbase Server and Couchbase Sync Gateway in Docker using docker-compose. This repository is mainly to help OAF devs to quickly setup their local environment while trynig to run our legacy Mobile-Sync-Gateway v2 (MSG2) services. It also uses current MSG2 sync-function that expects either `replicator` or `sync_daemon` role.

## Installation
Install test-coverage by running npm.
```
npm install
```
### Sync function
While developing, I added a bash-function for the Sync Gateway which parses the sync-function from a separate file and puts it in the JSON configuration, to be used by the Sync Gateway.

## Usage
1. Start the server-container and the sync-gateway-container. The sync-gateway-container will during startup wait for
the configuration of the server-container. During the first startup, the initialization of the cluster will be performed
and the bucket will be created and then Indices realted to `offline-reads` i.e `PRIMARY` , `adv_DISTINCT_channels_syncTs`

        docker-compose up
2. Check whether the Couchbase Sync Gateway started properly by accessing the REST API from the web browser.

        http://localhost:4984
3. The response of the Couchbase Sync Gateway should be comparable to the example below.

        {"couchdb":"Welcome","vendor":{"name":"Couchbase Sync Gateway","version":"2.8"},"version":"Couchbase Sync Gateway/2.8.3(12;e54a627) CE"}

## Testing
The Mocha test-framework has been used for covering the Sync Gateway configuration with tests.
```
npm test
```

OutPut: 
```
> couchbase-sync-gateway@1.0.0 test
> mocha

  Sync function
    ✓ Creating a document should not give an error (98ms)


  1 passing (245ms)
```
