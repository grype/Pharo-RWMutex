Class {
	#name : #RWMutexTests,
	#superclass : #TestCase,
	#category : #'RWMutex-Tests'
}

{ #category : #tests }
RWMutexTests >> testReadCritical [
	| mutex readCount |

	mutex := RWMutex new.
	readCount := 0.
	[ mutex readCritical: [ readCount := readCount + 1 ] ] fork.
	[ mutex
		readCritical: [ self
				assert: readCount = 1
				description: 'read-critical block should have changed the value' ] ]
		fork
]

{ #category : #tests }
RWMutexTests >> testReadCritical2 [
	| mutex readCount |

	mutex := RWMutex new.
	readCount := 0.
	[ mutex readCritical: [ readCount := readCount + 2 ] ] fork.
	[ mutex readCritical: [ readCount := readCount + 1 ] ]
		forkAt: Processor activePriority - 1.
	[ self
		assert: readCount = 2
		description: 'Higher priority process should have change value first' ]
		forkAt: Processor activePriority - 1.

	self assert: readCount = 0 description: 'Invalid initial count'.
	(Delay forMilliseconds: 100) wait.
	self assert: readCount = 3 description: 'Invalid final count'
]

{ #category : #tests }
RWMutexTests >> testReadRead [
	| mutex readCount |

	"1 -> 2. -> 1."
	mutex := RWMutex new.
	readCount := 0.
	
	"1. Start delayed read"
	[ mutex
		readCritical: [ (Delay forMilliseconds: 1) wait.
			self
				assert: readCount = 2
				description: 'Second read should happen before the first delayed read'.
			readCount := readCount + 1 ] ] fork.

	"2. Start second read"
	[ mutex
		readCritical: [ self assert: readCount = 0 description: 'Unexpected read happened'.
			readCount := readCount + 2 ] ] fork.

	self
		assert: readCount = 0
		description: 'Read count changed prematurely'.
	(Delay forMilliseconds: 100) wait.
	self
		assert: readCount = 3
		description: 'Both reads should have happened'
]

{ #category : #tests }
RWMutexTests >> testReadWrite [
	| mutex readCount writeCount |

	mutex := RWMutex new.
	readCount := 0.
	writeCount := 0.
	"Start delayed read process"
	[ mutex
		readCritical: [ (Delay forMilliseconds: 1) wait.
			readCount := readCount + 1 ] ] fork.

	"Write should wait for initial read to complete"
	[ mutex
		writeCritical: [ self
				assert: readCount = 1
				description: 'There should have been a read before a write'.
			writeCount := writeCount + 1 ] ] fork.

	self
		assert: readCount = 0
		description: 'Read count changed prematurely'.
	self
		assert: writeCount = 0
		description: 'Write count changed prematurely'.

	(Delay forMilliseconds: 100) wait.
	self assert: readCount = 1 description: 'Did not read as expected'
]

{ #category : #tests }
RWMutexTests >> testReadWriteRead [
	| mutex readCount writeCount |

	mutex := RWMutex new.
	readCount := 0.
	writeCount := 0.

	"1. Start delayed read process"
	[ mutex
		readCritical: [ 
			(Delay forMilliseconds: 10) wait.
			readCount := readCount + 2 ] ] fork.

	"2. Write should wait for initial read to complete"
	[ mutex
		writeCritical: [ 
			self
				assert: readCount = 2
				description: 'Read count should have changed once before write'.
			writeCount := writeCount + 1 ] ] fork.

	"3. Next read should wait for write to complete"
	[ mutex readCritical: [ 
		self assert: writeCount = 1 description: 'Write count should have increased'.
		readCount := readCount + 1 ] ] fork.

	self
		assert: readCount = 0
		description: 'Read count changed prematurely'.
	self
		assert: writeCount = 0
		description: 'Write count changed prematurely'.

	(Delay forMilliseconds: 100) wait.
	self assert: readCount = 3 description: 'Did not read as expected'.
	self assert: writeCount = 1 description: 'Did not write as expected'
]

{ #category : #tests }
RWMutexTests >> testWriteCritical [
	| mutex writeCount |

	mutex := RWMutex new.
	writeCount := 0.
	[ mutex
		writeCritical: [ (Delay forMilliseconds: 1) wait.
			writeCount := writeCount + 1 ] ] fork.
	[ mutex
		writeCritical: [ self
				assert: writeCount = 1
				description: 'read-critical block should have changed the value' ] ]
		fork
]

{ #category : #tests }
RWMutexTests >> testWriteRead [
	| mutex writeCount readCount |

	mutex := RWMutex new.
	writeCount := 0.
	readCount := 0.

	"1. Start delayed write"
	[ mutex
		writeCritical: [ (Delay forMilliseconds: 10) wait.
			writeCount := writeCount + 1 ] ] fork.

	[ mutex
		readCritical: [ self
				assert: writeCount = 1
				description: 'Performed read before write finished'.
			readCount := readCount + 1 ] ] fork.

	self
		assert: writeCount = 0
		description: 'Write count changed prematurely'.

	(Delay forMilliseconds: 100) wait.
	self assert: writeCount = 1 description: 'Expected write to finish'.
	self assert: readCount = 1 description: 'Expected read to finish'
]

{ #category : #tests }
RWMutexTests >> testWriteWrite [
	| mutex writeCount |

	mutex := RWMutex new.
	writeCount := 0.
	[ mutex
		writeCritical: [ (Delay forMilliseconds: 1) wait.
			self
				assert: writeCount = 0
				description:
					'No other writes should have taken place while initial write has not completed'.
			writeCount := writeCount + 1 ] ] fork.

	[ mutex
		writeCritical: [ self
				assert: writeCount = 1
				description: 'Second write did not wait for first write to finish'.
			writeCount := writeCount + 1 ] ] fork.

	self
		assert: writeCount = 0
		description: 'Write count changed prematurely'.
	(Delay forMilliseconds: 10) wait.
	self assert: writeCount = 2 description: 'Expected two writes'
]
