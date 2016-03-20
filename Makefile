dep:
	gem build logstash-filter-cuahsi-service-name.gemspec && scp logstash-filter-cuahsi-service-name-2.1.0.gem upstream@ubuntulogging.cloudapp.net:~/upstream-cuahsi/logstash-plugins-dev/
