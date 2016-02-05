LDOC	= ldoc
LUA	= lua
MKDIR	= mkdir -p
SED	= sed
SPECL	= specl

luadir	= lib/std
SOURCES =				\
	$(luadir)/_base.lua		\
	$(luadir)/container.lua		\
	$(luadir)/list.lua		\
	$(luadir)/object.lua		\
	$(luadir)/set.lua		\
	$(luadir)/strbuf.lua		\
	$(luadir)/tree.lua		\
	$(luadir)/version.lua		\
	$(NOTHING_ELSE)


all: doc

doc: doc/config.ld $(SOURCES)
	$(LDOC) -c doc/config.ld .

doc/config.ld: doc/config.ld.in
	version=`LUA_PATH=$$(pwd)'/lib/?.lua;;' $(LUA) -e 'io.stdout:write(require"prototype.version")'`; \
	$(SED) -e "s,@PACKAGE_VERSION@,$$version," '$<' > '$@'


CHECK_ENV = LUA=$(LUA)

check:
	LUA=$(LUA) $(SPECL) $(SPECL_OPTS) specs/*_spec.yaml
