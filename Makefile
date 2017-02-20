.DEFAULT_GOAL := help

install: heat-install	## Install factory

help: help	## Help


heat-install:
	bash -c "sh bin/heat.sh"

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'