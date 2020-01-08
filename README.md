# Pharo-RWMutex
Mutual Exclusion access to a shared resource between a single writer and multiple concurrent readers.

I am like **Mutex** that protects write access to a shared resource while granting read access to multiple requestors. Read and write access is mutually exclusive. That is, a write request will block new read requests and wait on existing read-critical processes to finish. Concurrent read requests will be granted until write access is requested.

### Example:

```smalltalk
mutex := RWMutex new.
[ mutex readCritical: [ ... ] ] fork.
[ mutex readCritical: [ ... ] ] fork.
[ mutex writeCritical: [ ... ] ] fork.
[ mutex writeCritical: [ ... ] ] fork.
[ mutex readCritical: [ ... ] ] fork.
```

The first forked process will lock write access. The second forked process will take place concurrently with the first. The third forked process will wait for the first two to complete before entering a critical write section, where subsequent write requests, such as the fourth forked process, will wait on it. The final forked process will take place after all of the other process had concluded.

# Installation

```smalltalk
Metacello new
  repository: 'github://grype/RWMutex/src';
  baseline: 'RWMutex';
  load.
```
