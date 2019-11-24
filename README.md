# getrusage() wrapper
- known to work on Linux
- created as my simple "time for x in {1..100}; ..." benchmarks were a lot less pleasant on OpenBSD.

## build
```
make
```

## usage and examples
```
$ getr 1000 ./fizzbuzz >/dev/null
User time      : 1 s, 596007 us
System time    : 0 s, 806321 us
Time           : 2402 ms (2.402 ms/per)
Max RSS        : 6.6 MB
Page reclaims  : 308503
Page faults    : 0
Block inputs   : 0
Block outputs  : 0
vol ctx switches   : 999
invol ctx switches : 63

$ getr 100 python3 -c ''
User time      : 1 s, 338421 us
System time    : 0 s, 273103 us
Time           : 1611 ms (16.110 ms/per)
Max RSS        : 8.6 MB
Page reclaims  : 103173
Page faults    : 0
Block inputs   : 0
Block outputs  : 0
vol ctx switches   : 99
invol ctx switches : 19
```

## defects and room for improvement
- 'getr' is probably a poor name
