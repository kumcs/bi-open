xTuple Open BI
==============
This repo contains the source for business intelligence server-side components of xTuple Open BI.  bi-open consists of:

* Pentaho Data Integration ETL processes to extract and load CRM data.
* Pentaho analysis schema definitions for CRM cubes.
* Pentaho extensions for single signon and OLAP multi-tenant support.
* Scripts for installing and starting/stopping the BI Server.

The build_bi.sh will download the Pentaho technologies from ErpBI Solutions (http://sourceforge.net/projects/erpbi/).  
ErpBI provides a pre-configured Pentaho installation with a BI server, reporting engine and PDI technology.
The script also install the above components in the BI server.  For more innformation on the script, see:
https://github.com/xtuple/xtuple/wiki/xTuple-Open-Business-Intelligence  
