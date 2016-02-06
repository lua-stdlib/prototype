LDOC	= ldoc
LUA	= lua
MKDIR	= mkdir -p
SED	= sed
SPECL	= specl

VERSION	= 1.0

luadir	= lib/prototype
SOURCES =				\
	$(luadir)/_base.lua		\
	$(luadir)/container.lua		\
	$(luadir)/init.lua		\
	$(luadir)/list.lua		\
	$(luadir)/object.lua		\
	$(luadir)/set.lua		\
	$(luadir)/strbuf.lua		\
	$(luadir)/tree.lua		\
	$(luadir)/version.lua		\
	$(NOTHING_ELSE)


all: doc $(luadir)/version.lua


$(luadir)/version.lua: .FORCE
	@echo 'return "Prototype Object Libraries / $(VERSION)"' > '$@T';	\
	if cmp -s '$@' '$@T'; then						\
	    rm -f '$@T';							\
	else									\
	    echo 'echo "Prototype Object Libraries / $(VERSION)" > $@';		\
	    mv '$@T' '$@';							\
	fi

doc: doc/config.ld $(SOURCES)
	$(LDOC) -c doc/config.ld .

doc/config.ld: doc/config.ld.in
	$(SED) -e "s,@PACKAGE_VERSION@,$(VERSION)," '$<' > '$@'


CHECK_ENV = LUA=$(LUA)

check:
	LUA=$(LUA) $(SPECL) $(SPECL_OPTS) specs/*_spec.yaml


.FORCE: