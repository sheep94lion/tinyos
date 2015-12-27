import sys, os

try:
	fsock = open("result.txt", "r");
	eachLineData = [];
	eachId = [];
	result = {};
	for eachLine in fsock:
		eachLineData = eachLine.split(' ')
		nodeID = int(eachLineData[0])
		seqN = int(eachLineData[1])

		if nodeID in result:
			node = result[nodeID]
			node['allPkt'] += seqN - node['lastSeq']
			if seqN > node['lastSeq'] :
				node['lostPkt'] += seqN - node['lastSeq'] - 1
			node['lastSeq'] = seqN
		else:
			result[nodeID] = {}
			node = result[nodeID]
			node['lastSeq'] = seqN
			node['lostPkt'] = 0
			node['allPkt'] = 1
except e:
	print("Can't open file result.txt")
	exit(0)

fsock.close()
for item in result:
	print("Node id : " + str(item))
	print("lost packets : " + str(result[item]['lostPkt']))
	print("all packets : " + str(result[item]['allPkt']))
	lostRate = round(result[item]['lostPkt']*100.0/result[item]['allPkt'], 2)
	print("lost rate : " + str(lostRate) + "%\n")