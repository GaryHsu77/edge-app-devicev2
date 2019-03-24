.PHONY: build mpkg

#------------------------------------------------------------------
# mpkg setting
#------------------------------------------------------------------
DRONE_BUILD_NUMBER ?= unknown
BUILD_NUMBER       ?= $(DRONE_BUILD_NUMBER)
VERSION            := 0.1.0-$(BUILD_NUMBER)
ARCH                = armhf
LIB_VERSION         = arm-linux-gnueabihf
RUNTIME_BASE_ARCH   = arm32v7

#------------------------------------------------------------------

all: build mpkg

build:
	docker build \
		--add-host repo.isd.moxa.com:10.144.48.201 \
		-t docker.moxa.online/moxaisd/uc81xx-device:$(VERSION)-$(ARCH) \
		.

mpkg:
	tdk pack -e ARCH=$(ARCH) -e VERSION=$(VERSION) -w ./

clean:
