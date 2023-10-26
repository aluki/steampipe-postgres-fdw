# Makefile

PLATFORM=$(shell uname)
DESTDIR=~/.steampipe/db/14.2.0

build: prebuild.go
	$(MAKE) -C ./fdw clean
	$(MAKE) -C ./fdw go
	$(MAKE) -C ./fdw
	$(MAKE) -C ./fdw inst
	
	rm -f prebuild.go

install:
	if test "$(DESTDIR)" = "~/.steampipe/db/14.2.0" ; then \
		cp ./build-$(PLATFORM)/steampipe_postgres_fdw--1.0.sql $(DESTDIR)/postgres/share/postgresql/extension/ ; \
		cp ./build-$(PLATFORM)/steampipe_postgres_fdw.control $(DESTDIR)/postgres/share/postgresql/extension/ ; \
		cp ./build-$(PLATFORM)/steampipe_postgres_fdw.so $(DESTDIR)/postgres/lib/postgresql/ ; \
	else \
		mkdir -p $(DESTDIR)/$(shell pg_config --pkglibdir) ; \
		cp ./build-$(PLATFORM)/steampipe_postgres_fdw.so $(DESTDIR)/$(shell pg_config --pkglibdir)/ ; \
		mkdir -p $(DESTDIR)/$(shell pg_config --sharedir)/extension ; \
		cp ./build-$(PLATFORM)/steampipe_postgres_fdw--1.0.sql $(DESTDIR)/$(shell pg_config --sharedir)/extension/ ; \
		cp ./build-$(PLATFORM)/steampipe_postgres_fdw.control $(DESTDIR)/$(shell pg_config --sharedir)/extension/ ; \
	fi

# make target to generate a go file containing the C includes containing bindings to the
# postgres functions
prebuild.go:
	# copy the template which contains the C includes
	# this is used to import the postgres bindings by the underlying C compiler
	cp prebuild.tmpl prebuild.go
	
	# set the GOOS in the template 
	sed -i.bak 's|OS_PLACEHOLDER|$(shell go env GOOS)|' prebuild.go
	
	# replace known placeholders with values from 'pg_config'
	sed -i.bak 's|INTERNAL_INCLUDE_PLACEHOLDER|$(shell pg_config --includedir)|' prebuild.go
	sed -i.bak 's|SERVER_INCLUDE_PLACEHOLDER|$(shell pg_config --includedir-server)|' prebuild.go
	sed -i.bak 's|DISCLAIMER|This is generated. Do not check this in to Git|' prebuild.go
	rm -f prebuild.go.bak

clean:
	$(MAKE) -C ./fdw clean
	rm -f prebuild.go
	rm -f steampipe_postgres_fdw.a
	rm -f steampipe_postgres_fdw.h

# Used to build the Darwin ARM binaries and upload to the github draft release.
# Usage: make release input="v1.7.2"
release:
	./scripts/upload_arm_asset.sh $(input)
