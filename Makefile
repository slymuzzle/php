# REPO:=slymuzzle/php
# DOCKER_RUN:=docker run --rm -v $(PWD):/var/www/app ${REPO}:${VERSION}
# DOCKER_RUN_DEV:=$(DOCKER_RUN)-dev
# ARCHS:=linux/amd64,linux/arm64
# S6TAG:=v1.22.1.0
#
# s6-overlay-init:
# 	mkdir -p ${VERSION}/s6-overlay
# 	wget -P /tmp https://github.com/just-containers/s6-overlay/releases/download/$(S6TAG)/s6-overlay-amd64.tar.gz
# 	gunzip -c /tmp/s6-overlay-amd64.tar.gz | tar -xf - -C ${VERSION}/s6-overlay
#
# build:
# 	make 
# 	docker buildx build --no-cache --platform $(ARCHS) -t $(REPO):${VERSION} --target main -f ${VERSION}/Dockerfile ${VERSION}/
# 	docker buildx build --no-cache --platform $(ARCHS) -t $(REPO):${VERSION}-dev --target dev -f ${VERSION}/Dockerfile ${VERSION}/
#
# run-detached:
# 	docker run --name php${VERSION} -d -v $(PWD):/app $(REPO):${VERSION}
# 	docker run --name php${VERSION}-dev -d -v $(PWD):/app $(REPO):${VERSION}-dev
#
# test-main:
# 	$(DOCKER_RUN) php -v
# 	$(DOCKER_RUN) sh -c "php -v | grep ${VERSION}"
# 	$(DOCKER_RUN) sh -c "php -v | grep OPcache"
# 	$(DOCKER_RUN) sh -c "php test/test.php | grep Success"
# 	$(DOCKER_RUN) sh -c "echo \"<?php echo ini_get('memory_limit');\" | php | grep 256M"
#
# test-dev:
# 	$(DOCKER_RUN_DEV) sh -c "php -v | grep Xdebug"
# 	$(DOCKER_RUN_DEV) composer --version
# 	$(DOCKER_RUN_DEV) sh -c "php test/test.php | grep Success"
# 	$(DOCKER_RUN_DEV) sh -c "echo \"<?php echo ini_get('memory_limit');\" | php | grep 1G"
#
# release:
# 	echo "Releasing: ${REPO}:${SEMVER}"
# 	echo "Releasing: ${REPO}:${SEMVER}-dev"
# 	echo "Releasing: ${REPO}:${VERSION}"
# 	echo "Releasing: ${REPO}:${VERSION}-dev"
# 	$(eval export SEMVER=$(shell docker run --rm -v $(PWD):/app ${REPO}:${VERSION} php -r "echo phpversion();"))
# 	docker buildx build --no-cache --platform $(ARCHS) --push -t $(REPO):${VERSION} --target main -f ${VERSION}/Dockerfile ${VERSION}/
# 	docker buildx build --no-cache --platform $(ARCHS) --push -t $(REPO):${VERSION}-dev --target dev -f ${VERSION}/Dockerfile ${VERSION}/
# 	docker buildx build --no-cache --platform $(ARCHS) --push -t $(REPO):${SEMVER} --target main -f ${VERSION}/Dockerfile ${VERSION}/
# 	docker buildx build --no-cache --platform $(ARCHS) --push -t $(REPO):${SEMVER}-dev --target dev -f ${VERSION}/Dockerfile ${VERSION}/
#
# test-all: test-all
# 	VERSION=8.1 make build
# 	VERSION=8.0 make build
# 	VERSION=7.4 make build
# 	VERSION=8.1 make test-main
# 	VERSION=8.0 make test-main
# 	VERSION=7.4 make test-main
# 	VERSION=8.1 make test-dev
# 	VERSION=8.0 make test-dev
# 	VERSION=7.4 make test-dev

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
