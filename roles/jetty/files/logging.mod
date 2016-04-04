#
# Jetty Logging Module
#   Output Managed by Logback
#

[name]
logging

[depend]
resources

[lib]
lib/logging/*.jar

[files]
logs/
http://central.maven.org/maven2/org/slf4j/slf4j-api/1.7.16/slf4j-api-1.7.16.jar|lib/logging/slf4j-api-1.7.16.jar
http://central.maven.org/maven2/ch/qos/logback/logback-core/1.1.5/logback-core-1.1.5.jar|lib/logging/logback-core-1.1.5.jar
http://central.maven.org/maven2/ch/qos/logback/logback-classic/1.1.5/logback-classic-1.1.5.jar|lib/logging/logback-classic-1.1.5.jar
https://raw.githubusercontent.com/jetty-project/logging-modules/master/logback/logback.xml|resources/logback.xml
https://raw.githubusercontent.com/jetty-project/logging-modules/master/logback/jetty-logging.properties|resources/jetty-logging.properties
