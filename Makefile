.DEFAULT_GOAL := help

create: 			heat-create			## create factory
build-images: 		build-images		## build for images, please use argument : bundle=YOUR-BUNDLE-NAME
build-os:			build-os			## build for os, please us argument : os=YOUR-OS-NAME
help: 				help				## Help

heat-create:
	bash -c "sh bin/heat.sh"

build-images:
	./bin/build-images.sh ${bundle} ${fe}

build-os:
	./bin/build-os.sh ${os} ${fe}


help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'