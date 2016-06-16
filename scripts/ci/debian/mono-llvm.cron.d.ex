#
# Regular cron jobs for the mono-llvm package
#
0 4	* * *	root	[ -x /usr/bin/mono-llvm_maintenance ] && /usr/bin/mono-llvm_maintenance
