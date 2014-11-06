#!/bin/sh
RUN_DIR=$(pwd)
LOG_FILE=$RUN_DIR/build_bi.log
mv $LOG_FILE $LOG_FILE.old
log() {
	echo $@
	echo $@ >> $LOG_FILE
}

varlog() {
	log $(eval "echo $1 = \$$1")
}

cdir() {
	cd $1
	log "Changing directory to $1"
}

RUNALL=true
BI_DIR=$RUN_DIR/..
XT_DIR=$RUN_DIR/../../xtuple
export BISERVER_HOME=$RUN_DIR/../../ErpBI
DATABASE=dev
DATABASEHOST=localhost
DATABASEUSER=admin
DATABASEPASSWORD=admin
DATABASEPORT=5432
DATABASELOADPORT=5432
DATABASESSL=
GETZIPS=Y
TENANT=default
CITIES=democities.txt
COMMONNAME=$(hostname)
HTTPNAME=localhost
CREATE=Y
INCREMENTAL=N

while getopts ":ieblmuxyzd:U:g:P:t:N:n:j:h:p:c:o:r:k:" opt; do
  case $opt in
    e)
      # Install ErpBI and configure
      RUNALL=
      DOWNLOAD=true
      ;;
    b)
      # Build BI solution and install
      RUNALL=
      RUN=true
      ;;
    l)
      # Extract and load analytic data into erpbi database
      RUNALL=
      LOAD=true
      ;;
    m)
      # Prep the Mobile Client to connect to BI Server
      RUNALL=
      PREP=true
      ;;
    d)
      # Set database name (for extract)
      DATABASE=$OPTARG
      ;;
    p)
      # Set database port (for extract)
      DATABASEPORT=$OPTARG
      ;;
    h)
      # Set database host name (for extract)
      DATABASEHOST=$OPTARG
      ;;
    U)
      # Set database user name (for extract)
      DATABASEUSER=$OPTARG
      ;;
    P)
      # Set database user password (for extract)
      DATABASEPASSWORD=$OPTARG
      ;;
    o)
      # Set database port (for load)
      DATABASELOADPORT=$OPTARG
      ;;	  
    y)
      # Set database ssl connect option (for extract)
      DATABASESSL="?ssl=true\&sslfactory=org.postgresql.ssl.NonValidatingFactory"
      ;;
    k)
      # Server key file for SSL
      SSLKEY=$OPTARG
      ;;
    r)
      # Server certificate file for SSL
      SSLCERT=$OPTARG
      ;;	  
    t)
      # Set tenant name
      TENANT=$OPTARG
      ;;
    g)
      # Geographic data file
      CITIES=$OPTARG
      ;;	  
    n)
      # Common name for self signed SSL certificate and https host connection
      COMMONNAME=$OPTARG
      ;;
    N)
      # http Host connection name 
      HTTPNAME=$OPTARG
      ;;
    c)
      # Path for config file
      CONFIGPATH=$OPTARG
      ;;
    u)
      # Incremental updates
      INCREMENTAL=Y
      ;;
    j)
      # Java home
      export JAVA_HOME=$OPTARG
      ;;
    x)
      # Do not create erpbi database schema
      CREATE=N
      ;;
    z)
      # Do not download Pentaho zip files
      GETZIPS=N
      ;;  
    \?)
      log "Invalid option: -"$OPTARG
      exit 1
      ;;
    :)
      log "Option -"$OPTARG" requires an argument."
      exit 1
      ;;
  esac
done

if [ $RUNALL ]
then
	DOWNLOAD=true
	RUN=true
	LOAD=true
	PREP=true
fi

if  [ "$INCREMENTAL" = "Y" ]
then
	CREATE=N
fi

if  [ "$GETZIPS" = "N" ]
then
	if   ! test -f ../../ErpBI.zip  
	then
		log ""
		log "####################################################################################"
		log "Sorry can't find ErpBI.zip
		log "####################################################################################"
		log ""
		exit 1
	fi
	if   ! test -f ../../biserver-ce.zip  
	then
		log ""
		log "####################################################################################"
		log "Sorry can't find biserver-ce.zip
		log "####################################################################################"
		log ""
		exit 1
	fi
	if   ! test -f ../../data-integration.zip  
	then
		log ""
		log "####################################################################################"
		log "Sorry can't find ../../data-integration.zip
		log "####################################################################################"
		log ""
		exit 1
	fi
fi

if  [ $CONFIGPATH ]
then
	if   ! test -f $CONFIGPATH  
	then
		log ""
		log "####################################################################################"
		log "Sorry can't find config file at "$CONFIGPATH
		log "####################################################################################"
		log ""
		exit 1
	fi
else
	CONFIGPATH=config.js
fi

if  [ $SSLKEY ]
then
	if  ! [ $SSLCERT ]
	then
		log ""
		log "####################################################################################"
		log "Sorry if SSL Key is specified, SSL certificate must be specified."
		log "####################################################################################"
		log ""
		exit 1
	fi
fi

if  [ $SSLCERT ]
then
	if  ! [ $SSLKEY ]
	then
		log ""
		log "####################################################################################"
		log "Sorry if SSL certificate is specified, the SSL key must be specified."
		log "####################################################################################"
		log ""
		exit 1
	fi
fi

install_packages () {
	log ""
	log "######################################################"
	log "Install prereqs."
	log "######################################################"
	log ""
	apt-get install -qy git openjdk-6-jdk maven2
	export JAVA_HOME=$(readlink -f /usr/bin/javac | sed "s:bin/javac::")	
	if  ! test -e $JAVA_HOME/bin/javac ;
	then
		log ""
		log "#############################################################"
		log "Sorry can not find javac.  Set Java Home with the -j argument"
		log "#############################################################"
		log ""
		exit 1
	fi
}

download_files () {
	log ""
	log "######################################################"
	log "Download ErpBI zip files, generate keystore "
	log "and truststore for SSL with self signed cert using    "
	log "common name "$COMMONNAME
	log "######################################################"
	log ""
	
	rm -rf ../../ErpBI	
	if  [ "$GETZIPS" = "Y" ]
	then
		rm  -f ../../ErpBI.zip
		wget http://sourceforge.net/projects/erpbi/files/bundles/ErpBI.zip/download -O  ../../ErpBI.zip -nv
		rm  -f ../../biserver-ce.zip
		wget http://sourceforge.net/projects/erpbi/files/bundles/biserver-ce.zip/download -O  ../../biserver-ce.zip -nv
		rm  -f ../../data-integration.zip
		wget http://sourceforge.net/projects/erpbi/files/bundles/data-integration.zip/download -O  ../../data-integration.zip -nv
	fi
	log ""
	log "######################################################"
	log "Unzipping ErpBI.zip"
	log "######################################################"
	log ""
	unzip -q ../../ErpBI.zip -d ../..
	log ""
	log "######################################################"
	log "Unzipping biserver-ce.zip"
	log "######################################################"
	log ""
	unzip -q ../../biserver-ce.zip -d ../../ErpBI
	log ""
	log "######################################################"
	log "Unzipping data-integration.zip"
	log "######################################################"
	log ""
	unzip -q ../../data-integration.zip -d ../../ErpBI

	cdir $BISERVER_HOME/biserver-ce/
	chmod 755 -R . 2>&1 | tee -a $LOG_FILE
	chown -R $USER .
	
	if  [ $SSLKEY ]
	then
		cp $SSLKEY $BISERVER_HOME/biserver-ce/ssl-keys
		cp $SSLCERT $BISERVER_HOME/biserver-ce/ssl-keys
		cdir $BISERVER_HOME/biserver-ce/ssl-keys
		rm cacerts.jks
		rm keystore_server.jks
		rm server.cer
		openssl pkcs12 -export -out server.pkcs12 -in $SSLCERT -inkey $SSLKEY -passout pass:changeit
		keytool -importkeystore -srcstorepass changeit -deststorepass changeit -srckeystore server.pkcs12 -srcstoretype PKCS12 -destkeystore keystore_server.jks -deststoretype JKS 
		keytool -export -alias 1 -file $SSLCERT -storepass changeit -keystore keystore_server.jks
		keytool -import -alias 1 -v -trustcacerts -file $SSLCERT -keypass changeit -storepass changeit -keystore cacerts.jks -noprompt	
	else
		cdir $BISERVER_HOME/biserver-ce/ssl-keys
		rm cacerts.jks
		rm keystore_server.jks
		rm server.cer
		keytool -genkey -alias tomcat -keyalg RSA -keypass changeit -storepass changeit -keystore keystore_server.jks -dname "cn="$COMMONNAME", ou=xTuple, o=xTuple, c=US"
		keytool -export -alias tomcat -file server.cer -storepass changeit -keystore keystore_server.jks
		keytool -import -alias tomcat -v -trustcacerts -file server.cer -keypass changeit -storepass changeit -keystore cacerts.jks -noprompt	
	fi
	
	#
	#  BI Server is set up to listen on 8443 for SSL.  We change to 8444 to not conflict with the app
	#	
	cdir $BISERVER_HOME/biserver-ce/tomcat/conf
	mv server.xml server.xml.sample
	cat server.xml.sample | \
	sed s/port=\"8443\"/port=\"8444\"/ \
	> server.xml  2>&1 | tee -a $LOG_FILE
	
	cdir $BISERVER_HOME/biserver-ce/tomcat/conf/Catalina/localhost
	mv pentaho.xml pentaho.xml.sample
	cat pentaho.xml.sample | \
	sed s/org.h2.Driver/org.postgresql.Driver/ | \
	sed s#jdbc:h2:../../../h2database/demomfg#jdbc:postgresql://localhost:5432/erpbi# \
	> pentaho.xml  2>&1 | tee -a $LOG_FILE
}

run_scripts() {
	log ""
	log "######################################################"
	log "Build BI solution and move to ErpBI at:               "
	log $BISERVER_HOME
	log "######################################################"
	log ""
	# 
	#  Running install goal and process-resource goal solved maven issue of not copying resources.  May now be fixed.
	#	
	cdir $BI_DIR/olap-schema
	mvn install 2>&1 | tee -a $LOG_FILE
	java -jar Saxon-HE-9.4.jar -s:src/erpi-tenant-xtuple.xml -xsl:style.xsl -o:target/erpi-schema.xml
	mvn process-resources 2>&1 | tee -a $LOG_FILE

	cdir ../pentaho-extensions/oauthsso
	mvn -q clean 2>&1 | tee -a $LOG_FILE
	mvn -q install 2>&1 | tee -a $LOG_FILE
	mvn -q process-resources 2>&1 | tee -a $LOG_FILE

	cdir ../dynschema
	mvn -q install 2>&1 | tee -a $LOG_FILE
	mvn -q process-resources 2>&1 | tee -a $LOG_FILE
	
	cdir ../utils
	mvn -q install 2>&1 | tee -a $LOG_FILE
	mvn -q process-resources 2>&1 | tee -a $LOG_FILE

	cdir ../../etl
	mvn -q install 2>&1 | tee -a $LOG_FILE
	mvn -q process-resources 2>&1 | tee -a $LOG_FILE
}

load_pentaho() {
	log ""
	log "######################################################"
	log "Extract data from "$DATABASE" on host "$DATABASEHOST 
	log "and load data into erpbi with tenant name " $TENANT
	log "######################################################"
	log ""
	createdb -U postgres -O admin erpbi 2>&1 | tee -a $LOG_FILE
	cdir $BISERVER_HOME/data-integration
	export KETTLE_HOME=properties/psg-linux
	
	PSGLOCATION=$(sudo find /usr/lib -name psql)
	if  ! [ $PSGLOCATION ]
	then
		log ""
		log "###########################################################################"
		log "Sorry we couldn't find psg which is needed by the ETL. Looking in /usr/lib "
		log "###########################################################################"
		log ""
		exit 1
	fi	
	
	mv $KETTLE_HOME/.kettle/kettle.properties $KETTLE_HOME/.kettle/kettle.properties.sample  2>&1 | tee -a $LOG_FILE
	cat $KETTLE_HOME/.kettle/kettle.properties.sample | \
	sed s'#erpi.source.url=.*#erpi.source.url=jdbc\:postgresql\://'$DATABASEHOST'\:'$DATABASEPORT'/'$DATABASE$DATABASESSL'#' | \
	sed s'#erpi.source.user=.*#erpi.source.user='$DATABASEUSER'#' | \
	sed s'#erpi.source.password.*#erpi.source.password='$DATABASEPASSWORD'#' | \
	sed s'#erpi.datamart.port.*#erpi.datamart.port='$DATABASELOADPORT'#' | \
	sed s'#erpi.datamart.url=.*#erpi.datamart.url=jdbc\:postgresql\://localhost\:'$DATABASELOADPORT'/erpbi#' | \
	sed s'#erpi.cities.file.*#erpi.cities.file='$CITIES'#' | \
	sed s'#erpi.tenant.id=.*#erpi.tenant.id='$TENANT'.'$DATABASE'#' | \
	#sed s'#erpi.tenant.id=.*#erpi.tenant.id='default.dev'#' |
	sed s'#erpi.datamart.create=.*#erpi.datamart.create='$CREATE'#' | \
	sed s'#erpi.loaderpath=.*#erpi.loaderpath='$PSGLOCATION'#' | \
	sed s'#erpi.incremental=.*#erpi.incremental='$INCREMENTAL'#' \
	> $KETTLE_HOME/.kettle/kettle.properties  2>&1 | tee -a $LOG_FILE
	
	# Set PGPASSWORD to stop psg from prompting for password.  In case pg_hba.conf does not have
	# local   all   all     trust 
	# to trust local socket connections
	export PGPASSWORD=$DATABASEPASSWORD	
	sh kitchenkh.sh -file=../ErpBI/ETL/JOBS/Load.kjb -level=Basic
}

prep_mobile() {
	log ""
	log "######################################################"
	log "Prepare mobile app to use the BI Server. Create keys  "
    log "for REST api used by single sign on.  Update config.js"
	log "######################################################"
	log ""
	if [ ! -d $XT_DIR/node-datasource/lib/rest-keys ]
    then
      mkdir $XT_DIR/node-datasource/lib/rest-keys
    fi
	cdir $XT_DIR/node-datasource/lib/rest-keys
	openssl genrsa -out server.key 1024 2>&1 | tee -a $LOG_FILE
	openssl rsa -in server.key -pubout > server.pub 2>&1 | tee -a $LOG_FILE
	
	#
	# Would be better to use a proper json parser if we could fish the json
	# out of the javascript in config.js.  This would fix the nested keys problem
	# and the problem of looking for quoted and unquoted keys.
	#	
	cdir $XT_DIR/node-datasource
	mv $CONFIGPATH $CONFIGPATH'.old' 2>&1 | tee -a $LOG_FILE
	cat $CONFIGPATH'.old' | \
	sed 's#\"restkeyfile\":.*#restkeyfile:\"./lib/rest-keys/server.key\",#' | \
	sed 's#restkeyfile:.*#restkeyfile:\"./lib/rest-keys/server.key\",#' | \
	sed 's#\"tenantname\":.*#tenantname:\"'$TENANT'",#' | \
	sed 's#tenantname:.*#tenantname:\"'$TENANT'",#' | \
	sed 's#\"bihttpsport\":.*#bihttpsport:443,#' | \
	sed 's#bihttpsport:.*#bihttpsport:443,#' | \
	sed 's#\"bihttpshost\":.*#bihttpshost:\"'$COMMONNAME'\",#' | \
	sed 's#bihttpshost:.*#bihttpshost:\"'$COMMONNAME'\",#' | \
	sed 's#\"bihttpport\":.*#bihttpport:8080,#' | \
	sed 's#bihttpport:.*#bihttpport:8080,#' | \
	sed 's#\"bihttphost\":.*#bihttphost:\"'$HTTPNAME'\",#' | \
	sed 's#bihttphost:.*#bihttphost:\"'$HTTPNAME'\",#' \
	> $CONFIGPATH
}

install_packages

if [ $? -ne 0 ]
then
	log "bad."
fi

if [ $DOWNLOAD ]
then
	download_files
fi

if [ $RUN ]
then
	run_scripts
fi

if [ $LOAD ]
then
	load_pentaho
fi

if [ $PREP ]
then
	prep_mobile
fi

log ""
log "######################################################"
log "                FINISED! READ ME                      "
log "If you use the self signed certificate created by this"
log "script you will need to accept the certificate in your"
log "browser.  Connect to https://"$COMMONNAME":8443"
log "######################################################"
log ""
