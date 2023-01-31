install.packages("data.table")
install.packages("dplyr")
# Configuration failed because libcurl was not found. Try installing:
#  * deb: libcurl4-openssl-dev (Debian, Ubuntu, etc)
#  * rpm: libcurl-devel (Fedora, CentOS, RHEL)
#  * csw: libcurl_dev (Solaris)
install.packages("plotly")
install.packages("purrr")
# Configure could not find suitable mysql/mariadb client library. Try installing:
#  * deb: libmariadbclient-dev (Debian, Ubuntu)
#  * rpm: mariadb-connector-c-devel | mariadb-devel | mysql-devel (Fedora, CentOS, RHEL)
#  * csw: mysql56_dev (Solaris)
#  * brew: mariadb-connector-c (OSX)
install.packages("RMariaDB") # Minimum version 1.1.0, needed to support using server time zone
install.packages("rv")
install.packages("tidyquant")
