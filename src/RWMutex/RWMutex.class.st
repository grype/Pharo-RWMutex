"
I am like Mutex that protects write access to a shared resource while granting read access to multiple requestors. Read and write access is mutually exclusive. That is, a write request will block new read requests and wait on existing read-critical processes to finish. Concurrent read requests will be granted if no write request is made or while there's already a write-citical process going.
"
Class {
	#name : #RWMutex,
	#superclass : #Object,
	#instVars : [
		'readCount',
		'readWait',
		'writeSemaphore',
		'readSemaphore',
		'mutex'
	],
	#classVars : [
		'MaxReaders'
	],
	#category : #RWMutex
}

{ #category : #'class initialization' }
RWMutex class >> initialize [
	MaxReaders := 1 << 30
]

{ #category : #initialization }
RWMutex >> initialize [
	super initialize.
	readCount := 0.
	readWait := 0.
	readSemaphore := Semaphore new.
	writeSemaphore := Semaphore new.
	mutex := Mutex new
]

{ #category : #'mutual exclusion' }
RWMutex >> readCritical: aBlock [
	| result r |

	"writer is pending"
	[ readCount := readCount + 1 ] valueUnpreemptively < 0
		ifTrue: [ readSemaphore wait ].
	result := aBlock value.
	(r := [ readCount := readCount - 1 ] valueUnpreemptively) < 0
		ifTrue: [ [ readWait := readWait - 1 ] valueUnpreemptively = 0
				ifTrue: [ writeSemaphore signal ] ].

	^ result
]

{ #category : #'mutual exclusion' }
RWMutex >> writeCritical: aBlock [
	| r |

	^ mutex
		critical: [ r := [ readCount := readCount - MaxReaders ] valueUnpreemptively
				+ MaxReaders.

			"wait for readers"
			(r ~= 0
				and: [ [ readWait := readWait + r ] valueUnpreemptively ~= 0 ])
				ifTrue: [ writeSemaphore wait ].
			aBlock value.
			r := [ readCount := readCount + MaxReaders ] valueUnpreemptively.
			1 to: r do: [ :i | readSemaphore signal ] ]
]
