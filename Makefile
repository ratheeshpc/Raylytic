start:
	echo "Cloning https://github.com/hapifhir/hapi-fhir-jpaserver-starter"
	git clone https://github.com/hapifhir/hapi-fhir-jpaserver-starter
	echo "Doing Build"
	cd hapi-fhir-jpaserver-starter ; sh build-docker-image.sh
	echo "Setting up docker-compose"
	wget https://github.com/docker/compose/releases/download/1.22.0/docker-compose-Linux-x86_64 -O /usr/local/bin/docker-compose
	chmod 755 /usr/local/bin/docker-compose
	echo "Starting Server in fg mode"
	docker-compose up -d
stop:
	echo "Stopping Server"
	docker-compose down
	rm -rf cd hapi-fhir-jpaserver-starter
start_bg:
	echo "Starting Server in background mode"

