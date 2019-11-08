NUM_AGENTS=4

up:
	# Initialize loop devices
	for idx in $$(seq 1 63); do \
		if [ -e /dev/loop$${idx} ]; then continue; fi; \
		sudo mknod /dev/loop$${idx} b 7 $${idx}; \
		sudo chown --reference=/dev/loop0 /dev/loop$${idx}; \
		sudo chmod --reference=/dev/loop0 /dev/loop$${idx}; \
	done

	docker-compose build --pull && \
	docker-compose up --remove-orphans -d --scale agent=$(NUM_AGENTS)

down:
	docker-compose down --remove-orphans

logs:
	docker-compose logs -f --tail=100
