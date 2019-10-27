extern (C) int posix_spawnp(
        int* pid,
        immutable char* file,
        void *file_actions,
        void *attrp,
        immutable char** argv,
        char** envp);

extern (C) int waitpid(int pid, int* status, int options);

extern (C) char** environ;

extern (C) int getrusage(int who, RUsage* usage);

struct Timeval {
    long tv_sec;
    long tv_usec;
}

enum RUSAGE_CHILDREN = -1;

struct RUsage {
    Timeval ru_utime;
    Timeval ru_stime;
    long ru_maxrss;
    long ru_ixrss;
    long ru_idrss;
    long ru_isrss;
    long ru_minflt;
    long ru_majflt;
    long ru_nswap;
    long ru_inblock;
    long ru_oublock;
    long ru_msgsnd;
    long ru_msgrcv;
    long ru_nsignals;
    long ru_nvcsw;
    long ru_nivcsw;
}

void spawns(int times, string[] cmd) {
    import std.format: format;
    import std.string: toStringz;
    import std.exception: ErrnoException;

    immutable(char*)[] argv;
    int pid, status;

    foreach (arg; cmd) argv ~= toStringz(arg);
    argv ~= null;

    foreach (i; 0 .. times) {
        int ret;
        if (0 != (ret = posix_spawnp(&pid, argv[0], null, null, &argv[0], environ))) {
            throw new ErrnoException("posix_spawnp failed", ret);
        }
        waitpid(pid, &status, 0);
    }
}

void report(int times) {
    import std.stdio: stderr;

    RUsage usage;

    getrusage(RUSAGE_CHILDREN, &usage);
    stderr.writef(q"REPORT
User time      : %d s, %d us
System time    : %d s, %d us
Time           : %d ms (%.3f ms/per)
Max RSS        : %d kB
Page reclaims  : %d
Page faults    : %d
Block inputs   : %d
Block outputs  : %d
vol ctx switches   : %d
invol ctx switches : %d
REPORT",
        usage.ru_utime.tv_sec,
        usage.ru_utime.tv_usec,
        usage.ru_stime.tv_sec,
        usage.ru_stime.tv_usec,
        (((usage.ru_utime.tv_usec + usage.ru_stime.tv_usec)/1000) + ((usage.ru_utime.tv_sec + usage.ru_stime.tv_sec)*1000)),
        (((usage.ru_utime.tv_usec + usage.ru_stime.tv_usec)/1000.0) + ((usage.ru_utime.tv_sec + usage.ru_stime.tv_sec)*1000.0))/times,
        usage.ru_maxrss,
        usage.ru_minflt,
        usage.ru_majflt,
        usage.ru_inblock,
        usage.ru_oublock,
        usage.ru_nvcsw,
        usage.ru_nivcsw
    );
}

void main(string[] args) {
    import std.stdio: stderr;
    import core.stdc.stdlib: exit;
    import std.exception: ifThrown;
    import std.conv: to;

    void usage() {
        stderr.writeln("usage: ", args[0], " <#runs> <command> [<args> ...]");
        exit(1);
    }

    if (args.length < 3) usage();
    int count = to!int(args[1]).ifThrown(0);
    if (count < 1) usage();

    spawns(count, args[2 .. $]);
    report(count);
}
