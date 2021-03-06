cflags{'-I $builddir/pkg/wayland/include'}

waylandproto('stable/xdg-shell/xdg-shell.xml',
	'include/xdg-shell-client-protocol.h',
	'include/xdg-shell-server-protocol.h',
	'xdg-shell-protocol.c'
)

waylandproto('unstable/idle-inhibit/idle-inhibit-unstable-v1.xml',
	'include/idle-inhibit-unstable-v1-client-protocol.h',
	'include/idle-inhibit-unstable-v1-server-protocol.h',
	'idle-inhibit-v1-protocol.c'
)

pkg.hdrs = {
	'$outdir/include/xdg-shell-client-protocol.h',
	'$outdir/include/xdg-shell-server-protocol.h',
	'$outdir/include/idle-inhibit-unstable-v1-client-protocol.h',
	'$outdir/include/idle-inhibit-unstable-v1-server-protocol.h',
}

fetch 'git'
