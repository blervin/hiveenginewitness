const rp = require('request-promise');
var hive = require('@hiveio/hive-js');
var fs = require('fs');

// let heUrl = "http://my_local_he_witness_ip_address:5000/contracts";
let heUrl = "https://api.hive-engine.com/rpc/contracts";

var fromAccount = 'fromAccount';
var myAccount = 'myAccount';

var config = JSON.parse(fs.readFileSync("/var/nodejs/config_" + fromAccount + ".json"));
const activeKey = config.active_key;
const loopSeconds = 30;

var requestLoop = setInterval(function(){
	rp({
		url : heUrl,
		method : 'POST',
		body: {"jsonrpc": "2.0","method": "find","params": {"contract": "witnesses","table": "witnesses","query": {}},"id": 1},
		json : true
	}).then(function (response){
		var enabled = false;
		var results = response.result;
		var dateNow = new Date(Date.now());
		dateNow = dateNow.toString().split('+')[0];

		for(var results_i = 0; results_i < results.length; results_i++) {
			var result = results[results_i];
			if(result.account == myAccount){
				enabled = result.enabled;
			}
		}
		if(enabled == false){
			console.log('witness is not enabled');
			transfer(activeKey, fromAccount, myAccount, '0.007 HIVE', 'witness is not enabled');
		} else {
			console.log('witness enabled: ' + dateNow);
		}
	});
}, loopSeconds * 1000);

async function transfer(activeKey, from, to, amount, memo) {
	hive.broadcast.transfer(activeKey, from, to, amount, memo, function (err, response) {
		if (err) {
			console.log('Error sending transfer to @' + to + ' for: ' + amount + ', Error: ' + err);
			process.exit();
		} else {
			var trxId = response.id;
			console.log('Transfer to @' + to + ': ' +  amount + '\n' + ' at trx: ' + trxId);
		}
	});
}