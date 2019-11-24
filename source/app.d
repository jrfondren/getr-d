/++
    A POSIX application wrapping getrusage(2) for simple benchmarks.

    SYNOPSIS:
    `getr <#runs> <command> [<args> ...]`

    OUTPUT:
    ---
    $ getr 1000 ./fizzbuzz >/dev/null
    User time      : 0 s, 894347 us
    System time    : 0 s, 673832 us
    Time           : 1568.179 ms (1.568 ms/per)
    Max RSS        : 952 kB
    Page reclaims  : 239344
    Page faults    : 1
    Block inputs   : 0
    Block outputs  : 0
    vol ctx switches   : 0
    invol ctx switches : 1298
    ---

    DESCRIPTION:
    getr is a simple wrapper around the `getrusage`(2) syscall, which can be
    relied on for basic resource usage reports under Linux, OpenBSD, and macOS
    (among others). A child command is repeatedly spawned and waited for, and
    then a `RUSAGE_CHILDREN` report is generated. This program was created as
    the author was used to very simple bash loops to test performance, which
    was then found didn't work at all under ksh on OpenBSD.  getr is just as
    easy and just as simple.

    EXIT_STATUS:
    getr exits with status 1 if it fails to spawn a process, or if its own
    arguments aren't understood. It exits with status 0 in all other cases,
    including if the spawned program returns a nonzero exit status.

    EXAMPLES:
    `getr 1000 ./fizzbuzz > /dev/null`

    `fizzbuzz` is invoked 1000 times, with no arguments, and with getr's own
    (and therefore `fizzbuzz`'s) standard output piped to /dev/null. The
    resulting usage report would still be printed to standard error.

    `getr 100 rdmd -c ''`

    `rdmd` in PATH is asked, 100 times, to evaluate the empty string.

    SEE_ALSO:
    `getrusage`(2), `which`(1), `time`(1), `perf`(1), `valgrind`(1).
+/

module getr;

private:

extern (C) int getrusage(int who, RUsage* usage);

enum RUSAGE_CHILDREN = -1;

struct Timeval {
    long tv_sec;
    long tv_usec;
}

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

void report(int times) {
    import std.stdio : stderr;

    RUsage usage = void;

    getrusage(RUSAGE_CHILDREN, &usage);
    immutable long seconds = usage.ru_utime.tv_sec + usage.ru_stime.tv_sec,
        microseconds = usage.ru_utime.tv_usec + usage.ru_stime.tv_usec,
        milliseconds = seconds * 1000 + microseconds / 1000;
    immutable double ms_per = cast(double) milliseconds / cast(double) times;

    stderr.writef!q"REPORT
User time      : %d s, %d us
System time    : %d s, %d us
Time           : %d ms (%.3f ms/per)
Max RSS        : %s
Page reclaims  : %d
Page faults    : %d
Block inputs   : %d
Block outputs  : %d
vol ctx switches   : %d
invol ctx switches : %d
REPORT"(usage.ru_utime.tv_sec, usage.ru_utime.tv_usec,
            usage.ru_stime.tv_sec, usage.ru_stime.tv_usec, milliseconds, ms_per,
            readable_rss(cast(real) usage.ru_maxrss), usage.ru_minflt, usage.ru_majflt,
            usage.ru_inblock, usage.ru_oublock, usage.ru_nvcsw, usage.ru_nivcsw);
}

string readable_rss(real kb) {
    import std.format : format;

    if (kb < 1024.0)
        return format!"%.0f kB"(kb);
    else if (kb < 1024.0 * 1024.0)
        return format!"%.1f MB"(kb / 1024.0);
    else
        return format!"%.2f GB"(kb / (1024.0 * 1024.0));
}

void main(string[] args) {
    import std.stdio : stderr;
    import core.stdc.stdlib : exit;
    import std.exception : ifThrown;
    import std.conv : to;
    import std.process : spawnProcess, wait;

    void usage() {
        stderr.writeln("usage: ", args[0], " <#runs> <command> [<args> ...]");
        exit(1);
    }

    if (args.length < 3)
        usage();

    immutable int count = to!int(args[1]).ifThrown(0);

    if (count < 1)
        usage();

    foreach (i; 0 .. count) {
        wait(spawnProcess(args[2 .. $]));
    }

    report(count);
}
