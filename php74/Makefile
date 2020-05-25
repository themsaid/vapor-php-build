SHELL := /bin/bash

compiler: compiler.Dockerfile
	docker build -f ${PWD}/compiler.Dockerfile -t vapor/runtime/compiler:latest .

build: compiler
	docker build -f ${PWD}/php.Dockerfile -t vapor/runtime/php-74:latest $(shell helpers/buildArguments.php php74) .

build-extensions: compiler
	docker build -f ${PWD}/../extensions/imagick.Dockerfile -t vapor/runtime/imagick:latest .

distribute-extensions: build-extensions
	docker run --rm \
		--volume ${PWD}/../export:/export \
		vapor/runtime/imagick:latest

distribution: build
	docker run --rm \
		--env PHP_SHORT_VERSION=74 \
		--volume ${PWD}/runtime:/runtime:ro \
		--volume ${PWD}/../export:/export \
		--volume ${PWD}/export.sh:/export.sh:ro \
		vapor/runtime/php-74:latest \
		/export.sh
