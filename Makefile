.PHONY: build mpkg

#------------------------------------------------------------------
# mpkg setting
#------------------------------------------------------------------
DRONE_BUILD_NUMBER ?= unknown
BUILD_NUMBER       ?= $(DRONE_BUILD_NUMBER)
VERSION            := 0.1.0-$(BUILD_NUMBER)
ARCH               ?= amd64
REPO_URL           ?= http://repo.isd.moxa.com/static/ThingsPro/Gateway/release/thingspro_v2.6/730
FRM_FILE           ?= thingspro_release-thingspro_v2.6_amd64_20190416-025459.frm
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
