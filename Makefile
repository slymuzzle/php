# Variables
PROJECTNAME=slymuzzle/php
TAG=UNDEF
ARCHS:=linux/amd64,linux/arm64
PHP_VERSION=$(shell echo "$(TAG)" | sed -e 's/-.*//')

.PHONY: all
all: build start test-main test-dev stop clean

build:
	if [ "$(TAG)" = "UNDEF" ]; then echo "Please provide a valid TAG" && exit 1; fi
	docker build --no-cache --pull -t $(PROJECTNAME):$(TAG) -f $(TAG)/Dockerfile --target main $(TAG)
	docker build --no-cache --pull -t $(PROJECTNAME):$(TAG)-dev -f $(TAG)/Dockerfile --target dev $(TAG)

buildx-and-push:
	docker buildx create --use
	docker buildx build --no-cache --platform $(ARCHS) --push -t $(PROJECTNAME):$(TAG) -f $(TAG)/Dockerfile --target main $(TAG)
	docker buildx build --no-cache --platform $(ARCHS) --push -t $(PROJECTNAME):$(TAG)-dev -f $(TAG)/Dockerfile --target dev $(TAG)
	docker buildx stop

start:
	if [ "$(TAG)" = "UNDEF" ]; then echo "please provide a valid TAG" && exit 1; fi
	docker run -d -p 8080:80 --name php_instance $(PROJECTNAME):$(TAG)
	docker run -d -p 8081:80 --name php_instance_dev $(PROJECTNAME):$(TAG)-dev

stop:
	docker stop -t0 php_instance || true
	docker rm php_instance || true
	docker stop -t0 php_instance_dev || true
	docker rm php_instance_dev || true

clean:
	if [ "$(TAG)" = "UNDEF" ]; then echo "please provide a valid TAG" && exit 1; fi
	rm -rf $(TAG)/s6-overlay || true
	docker rmi $(PROJECTNAME):$(TAG) || true
	docker rmi $(PROJECTNAME):$(TAG)-dev || true

test-main:
	if [ "$(TAG)" = "UNDEF" ]; then echo "please provide a valid TAG" && exit 1; fi
	docker exec -t php_instance php-fpm --version | grep -q "PHP $(PHP_VERSION)"
	docker exec -t php_instance php-fpm --version | grep "OPcache"
	docker exec -t php_instance sh -c "echo \"<?php echo ini_get('memory_limit');\" | php | grep 256M"
	wget -q localhost:8080 -O- | grep -q "PHP Version $(PHP_VERSION)"

test-dev:
	if [ "$(TAG)" = "UNDEF" ]; then echo "please provide a valid TAG" && exit 1; fi
	docker exec -t php_instance_dev php-fpm --version | grep -q "PHP $(PHP_VERSION)"
	docker exec -t php_instance_dev php-fpm --version | grep "OPcache"
	docker exec -t php_instance_dev sh -c "php -v | grep Xdebug"
	docker exec -t php_instance_dev composer --version
	docker exec -t php_instance_dev sh -c "echo \"<?php echo ini_get('memory_limit');\" | php | grep 1G"
	wget -q localhost:8080 -O- | grep -q "PHP Version $(PHP_VERSION)"
