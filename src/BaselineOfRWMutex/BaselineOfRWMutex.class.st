Class {
	#name : #BaselineOfRWMutex,
	#superclass : #BaselineOf,
	#category : #BaselineOfRWMutex
}

{ #category : #baselines }
BaselineOfRWMutex >> baseline: spec [
	<baseline>
	spec
		for: #pharo
		do: [ spec
				package: 'RWMutex';
				package: 'RWMutex-Tests' with: [ spec requires: #('RWMutex') ].

			spec
				group: 'Core' with: #(#RWMutex);
				group: 'Tests' with: #('RWMutex' #'RWMutex-Tests');
				group: 'default' with: #(#Core 'Tests') ]
]
