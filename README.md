# getrusage() wrapper
- known to work on Linux
- won't work on macOS due to `environ` handling
- won't work on Android/Termux due to `posix_spawnp`
- created as my simple "time for x in {1..100}; ..." benchmarks were a lot less pleasant on OpenBSD.

## build
```
make
```

## usage and examples
```
$ getr 1000 ./fizzbuzz >/dev/null
User time      : 0 s, 680224 us
System time    : 0 s, 801342 us
Time           : 1481 ms (1.482 ms/per)
Max RSS        : 6096 kB
Page reclaims  : 480526
Page faults    : 0
Block inputs   : 0
Block outputs  : 0
vol ctx switches   : 999
invol ctx switches : 31

$ getr 100 python3 -c ''
User time      : 1 s, 333495 us
System time    : 0 s, 294639 us
Time           : 1628 ms (16.281 ms/per)
Max RSS        : 8692 kB
Page reclaims  : 100143
Page faults    : 2
Block inputs   : 512
Block outputs  : 0
vol ctx switches   : 102
invol ctx switches : 14
```

## defects and room for improvement
- this version is lacking D-style documentation
- 'getr' is probably a poor name
