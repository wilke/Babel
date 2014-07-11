TOP_DIR = ../..
TOOLS_DIR = $(TOP_DIR)/tools
DEPLOY_RUNTIME ?= /kb/runtime
TARGET ?= /kb/deployment
include $(TOOLS_DIR)/Makefile.common

SERVICE = communities_api
SERVICE_DIR = $(TARGET)/services/$(SERVICE)
SERVICE_URL = http://kbase.us/services/communities/1

# things needed for testing
TESTS = $(wildcard test/script-tests/test_*.t)

default: build-scripts

deploy: deploy-cfg deploy-client deploy-docs

deploy-all: deploy

all: deploy

clean:
	$(eval AUTO_SCRIPTS = $(wildcard api-scripts/*.pl))
	for ac in $(AUTO_SCRIPTS); do \
		base=`basename $$ac`; \
		rm -f api-scripts/$$base; \
		rm -f scripts/$$base; \
	done
	$(eval TOOL_SCRIPTS = $(wildcard tools/tools/bin/*))
	for tc in $(TOOL_SCRIPTS); do \
		base=`basename $$tc`; \
		rm -f scripts/$$base; \
	done
	$(eval TOOL_LIBS = $(wildcard tools/tools/lib/*))
	for tl in $(TOOL_LIBS); do \
		base=`basename $$tl`; \
		rm -f lib/$$base; \
	done
	-rm -rf tools
	-rm -f lib/C*
	-rm -f docs/C*
	@echo "All clean"

deploy-client: deploy-scripts | build-libs deploy-libs
	echo $(SRC_PERL)
	mkdir -p $(SERVICE_DIR)
	@echo "client tools deployed"

build-libs:
	api2js -url $(SERVICE_URL) -outfile docs/CommunitiesAPI.json
	definition2typedef -json docs/CommunitiesAPI.json -typedef docs/CommunitiesAPI.typedef -service CommunitiesAPI
	compile_typespec --impl CommunitiesAPI --js CommunitiesAPI --py CommunitiesAPI docs/CommunitiesAPI.typedef lib
	@echo "done building typespec libs"

build-scripts:
	@echo "retrieving API tools"
	-rm -rf tools
	git submodule init tools
	git submodule update tools
	cd tools; git pull origin master
	cp tools/tools/lib/* lib/.
	cp tools/tools/bin/mg-* scripts/.
	cp tools/tools/bin/jsonviewer.py scripts/mg-jsonviewer.py
	@echo "auto-generating API scripts"
	generate_commandline -template $(TOP_DIR)/template/communities.template -config config/commandline.conf -outdir api-scripts
	cp api-scripts/* scripts/.
	@echo "done building command line scripts"

build-docs:
	api2html -url $(SERVICE_URL) -site_name "Communities API" -outfile docs/Communities_API.html
	pod2html --infile=lib/CommunitiesAPIClient.pm --outfile=docs/CommunitiesAPI.html --title="Communities API Client"

deploy-docs: build-docs
	mkdir -p $(SERVICE_DIR)/webroot
	cp docs/*.html $(SERVICE_DIR)/webroot/.

test: test-client

test-client:
	for t in $(TESTS); do \
		echo $$t; \
		$(KB_RUNTIME)/bin/perl $$t; \
		if [ $$? -ne 0 ]; then \
			exit 1; \
		fi \
	done


include $(TOOLS_DIR)/Makefile.common.rules
