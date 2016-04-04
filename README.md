# Autodesk SeeControl

This library integrates with [Autodesk's SeeControl platform](https://cloudx.seecontrol.com), an enterprise IoT cloud service that helps manufacturers to connect, analyze, and manage their products.

**To add AutodeskSeeControl to your project, add** `#require "AutodeskSeeControl.class.nut:1.0.0"` **to the top of your agent/device code**

## Class Usage

#### Constructor: AutodeskSeeControl(*hostname, tcp_port*)

The AutodeskSeeControl constructor takes two required parameters: the base *hostname* and *port* used for communication with SeeControl's platform.  These are provided to you by AutoDesk.  

```squirrel
local hostname = "<YOUR_HOSTNAME_HERE>";
local TCP_Port = <YOUR_TCP_PORT>;

adSeeControl <- AutodeskSeeControl(hostname, TCP_Port);
```

#### sendMessage(*id, message_code, [values, callback]*)

The *sendMessage* method sends a message to the SeeControl platform.  

| Parameter | Type | Default | Description |
| ----------| ---- | ------- | ----------- |
| id | string | N/A | Required : Unique device identifier for the device submitting data |
| message_code | string | N/A | Required : Unique message ‘code’ value that is used by device adapter to identify the correct message definition to be used when processing this message.  This value will be defined when you create a “Device Profile” message in your application. This is not the “Device Profile” code value.  It is the "Abstract message code" within the “Device Profile”. | 
| values | table or array of tables | null | Optional : Data to be sent to SeeControl platform.  The keys in the table correspond to field values associated with the "Message" in the "Device Profile". |
| callback | function | null | Optional : see note |

**NOTE:** If a callback function is supplied, the request will be made asynchronously and the callback will be executed upon completion. The callback takes two parameters, err (a string) and response data (a table).  If no error is encountered the err parameter will be null.  Alternatively, if no callback is supplied, the request will be made synchronously, and the method will return a Squirrel table with two fields: err and data.

**Synchronous Example:**

```squirrel
local agentID = split(http.agenturl(), "/").pop();
local message_code = "env_tail_data";

function printResponse(err, data) {
    if(err) {
        server.error(err);
    } else {
    	server.log("Request Successful");
    }
    server.log(http.jsonencode(data));
}

device.on("reading", function(reading) {
	server.log("Sending Request to Autodesk");
    local response = adSeeControl.sendMessage(agentID, message_code, reading);
    printResponse(response.err, response.data);
});
```

**Asynchronous Example:**

```squirrel
local agentID = split(http.agenturl(), "/").pop();
local message_code = "env_tail_data";

function printResponse(err, data) {
    if(err) {
        server.error(err);
    } else {
    	server.log("Request Successful");
    }
    server.log(http.jsonencode(data));
}

device.on("reading", function(reading) {
	server.log("Sending Request to Autodesk");
    adSeeControl.sendMessage(agentID, message_code, reading, printResponse);
});
```


#### openDirectiveListener(*id, timer, onMessageCallback, [onErrorCallback]*)

The SeeControl platform supports the sending of messages to the device. The device is responsible for checking for available directive messages by periodically submitting directive requests to the server. Use the *openDirectiveListener* method to set up the directive request loop. When a directive request is made if message(s) are available the *onMessageCallback* will be triggered for each waiting message.  

| Parameter | Type | Default | Description |
| ----------| ---- | ------- | ----------- |
| id | string | N/A | Required : Unique device identifier for the device submitting data |
| timer | integer | N/A | Required : The number of seconds to wait between directive requests |
| onMessageCallback | function | N/A | Required : A function that will execute for each message.  This function takes one parameter - a response table. See example below for table details. |
| onErrorCallback | function | null | Optional : A function that will execute if the directive request is unsuccessful.  This function takes two parameters - err (a string) and response (a table or raw response data). | 


**Example Code:**

```squirrel
local agentID = split(http.agenturl(), "/").pop();
local timer = 60; // check for messages every 60sec

function onMsg(res) {
	server.log(http.jsonencode(res));
	/* possible response log - 
	   { "success": true, 
	     "code": "env_tail_alert", 
     	 "target": "szPc0sLYAqlu", 
     	 "count": 1, 
     	 "time": "2016-04-01T22:02:15Z", 
     	 "values": { "alert" : "Temp_High", "temp": "32.6997", "timestamp": "2016-04-01T22:02:15Z" } }
	*/
}

function onErr(err, res) {
	server.error(err); 
	// possible error log - "Error: Missing 'target' value"
	
	server.log(http.jsonencode(res)); 
	// possible response log - { "success": false, "message": "Missing 'target' value" }
}

adSeeControl.openDirectiveListener(agentID, timer, onMsg, onErr);
```

#### formatTimestamp(*epoch_timestamp*)

The Autodesk SeeControl platform uses XML 8601 formated timestamps.  Use this function to convert Electric Imp's Epoch timestamp to a format recognized by the Autodesk SeeControl platform.

```squirrel
local timestamp = adSeeControl.formatTimestamp(time());
```

## License
The Autodesk SeeControl class is licensed under [MIT License](https://github.com/electricimp/AutodeskSeeControl/tree/master/LICENSE).
