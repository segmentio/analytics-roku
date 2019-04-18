APPNAME = segment_uatest
IMPORTS =

APPSROOT = .
include $(APPSROOT)/app.mk

.PHONY: app
app: copy-library segment-config lint

.PHONY: install-app
install-app: home app install

.PHONY: segment-config
segment-config:
	@if ! grep -q "analytics_write_key" manifest ; then echo "analytics_write_key=$(SEGMENT_WRITE_KEY)" >> manifest ; fi

# Make SceneGraph 1.2 version of the uatest app
.PHONY: scenegraph-1.2
scenegraph-1.2:
	@if ! grep -q "rsg_version=1.2" manifest ; then echo "rsg_version=1.2" >> manifest ; fi

.PHONY: copy-library
copy-library:
	cd ../../.. ; make library
	rm -rf SegmentAnalytics
	unzip ../../../SegmentAnalytics.zip
	mkdir -p components/analytics
	mkdir -p source/analytics
	mv SegmentAnalytics/components/analytics/* components/analytics/
	mv SegmentAnalytics/source/analytics/*  source/analytics
	rm -rf SegmentAnalytics

.PHONY: lint
lint:
	brsc --skip-package yes

# Sometimes the Roku stream stick crashes when side loading the app while it's in
# screen saving mode. To avoid that, we send a Home button keypress event, which
# seems to be a reliable workaround.
.PHONY: home
home:
	@echo "Forcing roku to main menu screen $(ROKU_DEV_TARGET)..."
	curl -s -S -d '' http://$(ROKU_DEV_TARGET):8060/keypress/home
	sleep 2
