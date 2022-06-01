if [ -d "/data/teamcity_server/datadir/config" ] 
then
    echo "Configuring main node ..."
    echo "Shared configuration already created /data/teamcity_server/datadir/config. Starting..." 
else
    echo "/data/teamcity_server/datadir/config does not exists. Creating..."
    unzip -o /var/data/distr/tc-config.zip -d /data/teamcity_server/datadir/config
    echo "Configuring main node ..."
    echo "Database driver downloading ..."
    mkdir -p /data/teamcity_server/datadir/lib/jdbc
    curl https://jdbc.postgresql.org/download/postgresql-42.2.20.jar > /data/teamcity_server/datadir/lib/jdbc/postgresql-42.2.20.jar
    echo "S3 artifacts plugin downloading ..."
    mkdir /data/teamcity_server/datadir/plugins
    curl https://plugins.jetbrains.com/files/9623/76707/s3-artifact-storage.zip > /data/teamcity_server/datadir/plugins/s3-artifact-storage.zip
    echo "All components succesfully installed. Starting ..."
fi