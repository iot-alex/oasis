cflags{
	'-fwrapv',
	'-D NDEBUG',
	'-I $dir',
	'-I $srcdir/Include',
}

pkg.deps = {}
local libs = {}
local modules = load 'modules.lua'

if modules['_ctypes'] then
	cflags{'-I $builddir/pkg/libffi/include'}
	table.insert(pkg.deps, 'pkg/libffi/headers')
	table.insert(libs, 'libffi/libffi.a')
end
if modules['_hashlib'] or modules['_ssl'] then
	cflags{'-I $builddir/pkg/libressl/include'}
	table.insert(pkg.deps, 'pkg/libressl/headers')
	table.insert(libs, {
		'libressl/libssl.a',
		'libressl/libcrypto.a',
	})
end
if modules['pyexpat'] then
	cflags{'-I $builddir/pkg/expat/include'}
	table.insert(pkg.deps, 'pkg/expat/headers')
	table.insert(libs, 'expat/libexpat.a.d')
end
if modules['zlib'] then
	cflags{'-I $builddir/pkg/zlib/include'}
	table.insert(pkg.deps, 'pkg/zlib/headers')
	table.insert(libs, 'zlib/libz.a')
end

local sources = {}
sub('modules.ninja', function()
	-- snapshot $cflags in the subninja environment
	cflags{}

	for _, mod in pairs(modules) do
		if mod.core then
			for _, src in ipairs(mod) do
				sources[src] = true
			end
		else
			for _, src in ipairs(mod) do
				local obj = src..'.o'
				if not sources[obj] then
					cc('Modules/'..src)
					sources[obj] = true
				end
			end
		end
	end
end)
sources = table.keys(sources)

cflags{'-D Py_BUILD_CORE'}

rule('makesetup', 'lua $dir/makesetup.lua $dir/modules.lua <$in >$out.tmp && mv $out.tmp $out')
build('makesetup', '$outdir/config.c', {'$srcdir/Modules/config.c.in', '|', '$dir/makesetup.lua', '$dir/modules.lua'})

cc('Modules/getbuildinfo.c', nil, {
	cflags=[[$cflags -D 'DATE="Jun 26 2018"' -D 'TIME="23:11:05"']]
})
cc('Modules/getpath.c', nil, {
	cflags={
		'$cflags',
		[[-D 'PYTHONPATH=":plat-linux"']],
		[[-D 'PREFIX="/"']],
		[[-D 'EXEC_PREFIX="/"']],
		[[-D 'VERSION="3.7"']],
		[[-D 'VPATH=""']],
	},
})

local platform = 'linux'
local abiflags = ''
for line in iterlines('pyconfig.h', 1) do
	if line == '#define WITH_PYMALLOC 1' then
		abiflags = abiflags..'m'
	elseif line == '#define Py_DEBUG 1' then
		abiflags = abiflags..'d'
	end
end

cc('Python/getplatform.c', nil, {
	cflags=string.format([[$cflags -D 'PLATFORM="%s"']], platform),
})
cc('Python/sysmodule.c', nil, {
	cflags=string.format([[$cflags -D 'ABIFLAGS="%s"']], abiflags),
})

lib('libpython.a', {expand{'Modules/', sources}, paths[[
	Modules/(
		getbuildinfo.c.o
		getpath.c.o
		main.c
		gcmodule.c
	)
	Objects/(
		abstract.c
		accu.c
		boolobject.c
		bytes_methods.c
		bytearrayobject.c
		bytesobject.c
		call.c
		cellobject.c
		classobject.c
		codeobject.c
		complexobject.c
		descrobject.c
		enumobject.c
		exceptions.c
		genobject.c
		fileobject.c
		floatobject.c
		frameobject.c
		funcobject.c
		iterobject.c
		listobject.c
		longobject.c
		dictobject.c
		odictobject.c
		memoryobject.c
		methodobject.c
		moduleobject.c
		namespaceobject.c
		object.c
		obmalloc.c
		capsule.c
		rangeobject.c
		setobject.c
		sliceobject.c
		structseq.c
		tupleobject.c
		typeobject.c
		unicodeobject.c
		unicodectype.c
		weakrefobject.c
	)
	Parser/(
		acceler.c
		grammar1.c
		listnode.c
		node.c
		parser.c
		bitset.c
		metagrammar.c
		firstsets.c
		grammar.c
		pgen.c
		myreadline.c parsetok.c tokenizer.c
	)
	Python/(
		_warnings.c
		Python-ast.c
		asdl.c
		ast.c
		ast_opt.c
		ast_unparse.c
		bltinmodule.c
		ceval.c
		compile.c
		codecs.c
		dynamic_annotations.c
		errors.c
		frozenmain.c
		future.c
		getargs.c
		getcompiler.c
		getcopyright.c
		getplatform.c.o
		getversion.c
		graminit.c
		import.c
		importdl.c
		marshal.c
		modsupport.c
		mysnprintf.c
		mystrtoul.c
		pathconfig.c
		peephole.c
		pyarena.c
		pyctype.c
		pyfpe.c
		pyhash.c
		pylifecycle.c
		pymath.c
		pystate.c
		context.c
		hamt.c
		pythonrun.c
		pytime.c
		bootstrap_hash.c
		structmember.c
		symtable.c
		sysmodule.c.o
		thread.c
		traceback.c
		getopt.c
		pystrcmp.c
		pystrtod.c
		pystrhex.c
		dtoa.c
		formatter_unicode.c
		fileutils.c
		dynload_stub.c
		frozen.c
	)
	$outdir/config.c
]]})

exe('python', {'Programs/python.c', 'libpython.a', expand{'$builddir/pkg/', libs}})
file('bin/python3', '755', '$outdir/python')
sym('bin/python', 'python3')

for f in iterlines('pylibs.txt') do
	file('lib/python3.7/'..f, '644', '$srcdir/Lib/'..f)
end
file('lib/python3.7/_sysconfigdata_'..abiflags..'_'..platform..'_.py', '644', '$dir/lib/_sysconfigdata.py')
file('lib/python3.7/Makefile', '644', '$dir/lib/Makefile')
dir('lib/python3.7/lib-dynload', '755')

fetch 'curl'
