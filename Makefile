.PHONY: build mpkg

#------------------------------------------------------------------
# mpkg setting
#------------------------------------------------------------------
DRONE_BUILD_NUMBER ?= unknown
BUILD_NUMBER       ?= $(DRONE_BUILD_NUMBER)
VERSION            := 0.1.0-$(BUILD_NUMBER)
ARCH               ?= armhf
REPO_URL           ?= http://repo.moxa.online/static/ThingsPro/Gateway/unstable/XXX/
FRM_FILE           ?= thingspro_develop_ARCH_DATE.frm
#------------------------------------------------------------------

all: build mpkg

build:
	docker build \
		--build-arg REPO_URL=$(REPO_URL) \
		--build-arg FRM_FILE=$(FRM_FILE) \
		-t docker.moxa.online/moxaisd/device:$(VERSION)-$(ARCH) \
		.

mpkg:
	tdk pack -e ARCH=$(ARCH) -e VERSION=$(VERSION) -w ./

clean:
