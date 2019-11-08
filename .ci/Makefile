NUM_AGENTS=4

up:
	docker-compose build --pull && \
	docker-compose up --remove-orphans -d --scale agent=$(NUM_AGENTS)

down:
	docker-compose down --remove-orphans

logs:
	docker-compose logs -f --tail=100
