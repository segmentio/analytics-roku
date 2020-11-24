.PHONY: uatest
uatest: app cli
	sleep 2
	.scripts/e2e.sh
	cat uatest-results.txt | go-junit-report > report.xml
	junit-viewer --results==report.xml --port=8888

.PHONY: scenegraph-1.2
scenegraph-1.2:
	cd app; make scenegraph-1.2

# Run uatest on the SceneGraph 1.2 version of the test app
.PHONY: uatest-sg-1.2
uatest-sg-1.2: scenegraph-1.2 uatest

.PHONY: cli
cli:
	make -C cli

.PHONY: app
app:
	cd app; make install-app
