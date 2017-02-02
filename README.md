xTuple Open BI
==============
This repo contains the source for business intelligence server-side components of xTuple Open BI.  bi-open consists of:

* Pentaho Data Integration ETL processes to extract and load CRM data.
* Pentaho analysis schema definitions for CRM cubes.
* Pentaho extensions for single signon and OLAP multi-tenant support.
* Scripts for installing and starting/stopping the BI Server.

The build_bi.sh will download the Pentaho technologies from ErpBI Solutions (http://sourceforge.net/projects/erpbi/).  
ErpBI provides a pre-configured Pentaho installation with a BI server, reporting engine and PDI technology.
The script also install the above components in the BI server. 
xTuple Open Business Intelligence is implemented by the following projects:

* [xTuple Open BI](https://github.com/xtuple/bi-open) provides the solution files implementing xTuple Business Intelligence.  The installation script also installs a pre-configured Pentaho installation with a business intelligence server, reporting engine and ETL technology (http://sourceforge.net/projects/erpbi/).
* [xTuple Open BI Extension](https://github.com/xtuple/xtuple-extensions/tree/master/source/bi-open) provides dashboard support for the xTuple Web Client.

Get xTuple Open BI
------------------
Clone the git repo xtuple/bi-open in the same path as your xtuple folder (from clone of xtuple/xtuple)

	git clone https://github.com/xtuple/bi-open

Clone the git repo xtuple/xtuple-extensions in the same path as your xtuple folder (from clone of xtuple/xtuple). 

	git clone https://github.com/xtuple/xtuple-extensions

Build xTuple Open BI Extension
------------------------------

	cd xtuple-extensions
	git submodule update --init --recursive
	sudo npm install
	sudo ../xtuple/scripts/build_app.js -e source/bi_open

Build xTuple Open BI
--------------------

An installation script (open-bi/scripts/build_bi.sh) is provided to install and configure Pentaho, build and install the xTuple Open BI Solution, extract the data needed to build analytic cubes and configure the xTuple Mobile Web Client to connect to the BI Server.  Settings are changed in the Mobile Web Client config.js to connect to the BI Server.

The install script will download a pre-configured Pentaho from ErpBI Solutions on sourceforge and will install 
in the same path as your xtuple folder.  So you will have a folder structure like:

	some-folder
		bi-open (clone from https://github.com/xtuple/bi-open)
		ErpBI (downloaded by install_bi from https://sourceforge.net/projects/erpbi)
		xtuple-extensions (clone from https://github.com/xtuple/xtuple-extensions)
		xtuple (clone from from https://github.com/xtuple/xtuple)
		
The build_bi.sh script has the following arguments:

**Steps to Run**

Specify the steps to run.  If not specified, all the steps will be run

	-e 	Install ErpBI.
		Download ErpBI, set permissions and generate keystore & truststore for SSL with self signed
		certificate.
	
	-b	Build BI solution.
		Build the BI solution and reports using Maven. Install by moving files to ErpBI.
		
	-l	Extract and load analytic data.
		Create erpbi database.  Extract data from xtuple database and load analytic data in erpbi database.
		
	-m	Prep the xTuple Mobile Client to connect to BI Server	
		Prepare mobile app to use the BI Server. Create keys for REST api used by single sign on.
		Update config.js.
**xTuple Database Definition**

Database used to extract data.

	-d  Database Name
		Name of the xtuple database used for the extract.  Default is "dev".

	-p  Database Port
		Port of the xtuple database used for the extract.  Default is "5432".

	-h  Database Host
		Host name of the xtuple database used for the extract.  Default is "localhost".

	-U  Database User Name
		User name to connect to the xtuple database used for the extract.  Default is "admin".

	-P  Database User Password
		User password to connect to the xtuple database used for the extract.  Default is "admin".
**Datamart Database Definition**

A datamart database named erpbi will be defined on this machine.  You can specify the port number.

	-o  Database Port
		Port of the erpbi database used for the data load.  Default is "5432".
**Options for Extracting and Loading Analytic Data**

	-u	Incremental Update
		Extract and load only the changes since the last ETL run.  Use as an option with the -l step.

	-t	Tenant name
		Unique tenant name for the xTuple Mobile Client.  Specify if multiple tenants will be loaded.  Default is "default".

	-x	Do not Create Analytic Schema
		Do not create the analytic schema in the erpbi database.  This is useful when loading tenant data in an existing database.  The default is to drop and create the analytic schema.

	-g  Geographic Data File
		File name for city coordinates.  Choices are democities.txt, uscities.txt and worldcities.txt.  Default is democities.txt.

**Connecting to BI Server**

To support dashboards you must be able to connect to the BI Server via http on port 8080.  To support analysis you must be able to connect to the BI via https on port 8443.  For https, you can supply a signed certificate and key or the install will generate a self-signed certificate.  Connection arguments are:

	-k  Key file
		Key file for SSL support.  

	-r  Certificate file
		Certificate file for SSL support.  If not supplied, a self-signed certificate will be generated.	
	
	-n  BI Server https host name
		https host name to connect to BI Server.  If a self signed certificate is generated, this is used
		for the certificate common name.  Default is host name.

	-N  BI Server http host name
		http host name to connect to BI Server.  Default is localhost.

**Other Options**
		
	-j  Java Home

	-c  Path to config file
		Path to config file.  Default is ../node-datasource/config.js

	-z  Path to ErpBI zip files
		If you have the latest version of the ErpBI files you avoid downloading the files using this argument.  If not specified, the files will be downloaded.

		
On some machines (e.g. Amazon EC2) your $USER and $HOME maybe be set to different users and you should sudo with the HOME option.

**Examples**

Install, build, load data and prep the xTuple Mobile Client using defaults:

	cd bi-open/scripts
	sudo -H sh build_bi.sh

Run load data step, using database "demo" on host "myserver".  Connect with user "administrator" and password "secret"

	cd bi-open/scripts
	sudo -H sh build_bi.sh -l -d demo -h host -U administrator -P secret

Load data for a tenant using the name "tenant2".  The -x option is used as this is an existing database.  Use "uscities.txt" for city coordinate data.

	cd xtuple/scripts
	sudo -H sh build_bi.sh -l -x -t tenant2 -g uscities.txt

Rebuild the BI Solution.  This useful when there are updates to https://github.com/xtuple/bi

	cd bi-open/scripts
	sudo -H sh build_bi.sh -b
	
Start & Stop BI Server
----------------------
Before starting the BI Server, check that there isn't a port conflict with the xTuple Mobile Client.  The port used by the Mobile Client is defined in "datasource: {port: xxxx}" in xtuple/node-datasource/config.js.  Make sure the port number is not 8443 as this will cause a conflict.

To start the BI server:

	cd bi-open/scripts
	sudo sh start_bi.sh

To stop the server:

	cd bi-open/scripts
	sudo sh stop_bi.sh	

Using BI in the xTuple Web Client
---------------------------------
If you are using a self-signed certificate, then the first time you use business intelligence in the xTuple Mobile Client you must accept the certificate.  You can accept the certificate by connecting directly to the BI server (e.g. https://commonname:8443 ).

You must also enable the bi extension in Setup > User Accounts.

BI Settings in config.js
------------------------
The connection to the BI Server is defined in the config.js with the following settings:

    biServer: {
      bihttphost: "localhost",
      bihttpport: 8080,
      bihttpshost: "localhost"
      bihttpsport: 8443,
      catalog: "xTuple",
      tenantname: "default",
      keyfile: "./lib/rest-keys/server.key"
    },
	
Setting Up BI Server on a Separate Machine
------------------------------------------
The install.sh script assumes that the xTuple Mobile Client and the BI Server will be on the same machine.  
If BI Server will be on a separate machine, then on the BI Server machine:

	git clone https://github.com/xtuple/bi-open
	cd bi-open/scripts
	sudo -H sh install_bi.sh (optional arguments)

On the machine running the xTuple Mobile Client, you must manually configure the Client to connect to the BI server.

Generate keys for single signon

	mkdir xtuple/node-datasource/lib/rest-keys
	cd xtuple/node-datasource/lib/rest-keys
	openssl genrsa -out server.key 1024
	openssl rsa -in server.key -pubout > server.pub
Edit xtuple/node-datasource/config.js:

	bihost: "biserverhost"	

SSL Support
-----------
The BI Server is configured for SSL on port 8443.  The install.sh script will generate a self signed
certificate or you can supply a signed certificate.  

Self signed certificates are considered a security risk and must be accepted in the browser.  After
connecting to xTuple Mobile Client accept the certificate.  You can then accept the certificate by connecting directly to the BI Server (e.g. https://commonname:8443 ).