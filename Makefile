# Currently the eventgen git repo creates a broken docker image, using a customised version for now.
EVENTGEN_IMAGE ?= livehybrid/eventgen:x
HTTPD_IMAGE ?= httpd:2.4
DOCKER_HOST_IP ?= 10.72.0.1
BUNDLE_DIR = bundles

help: ## Show this help message.
	@echo 'usage: make [target] ...'
	@echo
	@echo 'targets:'
	@egrep '^(.+)\:\ ##\ (.+)' $(MAKEFILE_LIST) | column -t -c 2 -s ':#' | sed 's/^/  /'

guard-%:
	@ if [ "${${*}}" = "" ]; then \
		echo "Environment variable $* not set"; \
		exit 1; \
	fi

docker-pull: ## Pull docker image(s) used for eventgen
docker-pull:
	@docker pull $(EVENTGEN_IMAGE)
	@docker pull $(HTTPD_IMAGE)

docker-network:
	docker network create --attachable --driver bridge eg_network || true

nodes: ## Run <num> of eventgen nodes e.g. (make nodes num=5)
nodes: guard-num docker-pull docker-network
	@echo "Creating $(num) nodes"
	@number=1 ; while [[ $$number -le $(num) ]] ; do \
		echo Creating node $$number ; \
		docker kill eg_node$$number 2&>1 /dev/null true; \
		docker rm eg_node$$number  2&>1 /dev/null; \
		docker run --network eg_network --name eg_node$$number --link eg_controller:eg_controller --link eg_httpd:bundle_host -e REDIS_HOST=eg_controller -d -p 9500 $(EVENTGEN_IMAGE) server; \
		((number = number + 1)) ; \
	done

controller: docker-pull docker-network
controller: ## Create the eventgen controller (Runs on port 9500)
	@echo "Starting the eventgen controller"
	@docker kill eg_controller 2&>1 /dev/null || true
	@docker rm eg_controller 2&>1 /dev/null || true
	docker run --network eg_network --link eg_httpd:bundle_host --name eg_controller  -d -p 6379:6379 -p 9500:9500 $(EVENTGEN_IMAGE) controller
	@echo "http://localhost:9500"

httpd: docker-network docker-pull
	docker run -dit --name eg_httpd --network eg_network -p 9001:80 -v "$(shell pwd)":/usr/local/apache2/htdocs/ $(HTTPD_IMAGE)

eventgen-configure: ## Configure the controller with bundles in the ./bundles directory
eventgen-configure: $(BUNDLE_DIR)/*
	for file in $^ ; do \
		echo "Configuring: " $${file} ; \
  		curl --location --request POST 'http://localhost:9500/bundle'  --header 'Content-Type: application/json' --data-raw '{"url": "http://bundle_host/'$${file}'"}'; \
	done


eventgen-start: eventgen-configure
	@echo "Starting event generation"
	@curl --location --request POST 'http://localhost:9500/start'

eventgen-stop:
	@echo "Stopping eventgen processing"
	@curl --location --request POST 'http://localhost:9500/stop'

get-conf:
	@curl http://localhost:9500/conf

get-status:
	@curl http://localhost:9500/status

all: ## Make controller / nodes / static httpd with <num> nodes
all: guard-num docker-network httpd controller nodes

standalone:
	docker kill eg_standalone 2&>1 /dev/null || true
	docker rm eg_standalone 2&>1 /dev/null || true
	docker run --name eg_standalone  -d -p 9500:9500 $(EVENTGEN_IMAGE) standalone


down: ## Tear down the entire stack (controller / http / nodes
down: down-nodes down-controller down-httpd down-docker-network

down-docker-network:
	@docker network rm eg_network 2&>1 /dev/null || true

down-nodes:
	@docker kill $$(docker ps -a -q --filter name=eg_node --format="{{.Names}}") 2&>1 /dev/null || true
	@docker rm $$(docker ps -a -q --filter name=eg_node --format="{{.Names}}") 2&>1 /dev/null || true
	@echo Stopped EventGen Nodes

down-controller:
	@docker stop eg_controller 2&>1 /dev/null || true
	@docker rm eg_controller 2&>1 /dev/null || true
	@echo "Stopped EventGen Controller"

down-httpd:
	@docker stop eg_httpd 2&>1 /dev/null || true
	@docker rm eg_httpd 2&>1 /dev/null || true
	@echo "Stopped EventGen Static HTTP Server"

