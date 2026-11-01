cartdata("marc_conduit_20261031_v1")
assert(dget(0)==4900 and dget(1)==5,"score survived process restart")
printh("PASS", "persistence_result.txt", true)
