# Autodesk Fusion Contect

This library allows your agent to support [Autodesk’s Fusion Connect](http://autodeskfusionconnect.com/), an enterprise IoT cloud service that helps manufacturers to connect, analyze, and manage their products.

**To add this library to your project, add** `#require "AutodeskFusionConnect.class.nut:1.0.0"` **to the top of your agent code**

## Class Usage

### Constructor: AutodeskFusionConnect(*hostname, port[, https]*)

The AutodeskFusionConnect constructor takes two required parameters: the base *hostname* and *port* used for communication with Fusion Connect’s platform. These are provided to you by Autodesk.

The constructor also takes one optional boolean parameter, *https*. By default this is set to `false`. If your connection to Fusion Connect requires the HTTPS protocol, set this parameter to `true`.

```squirrel
#require "AutodeskFusionConnect.class.nut:1.0.0"

local hostname = "<YOUR_HOSTNAME>";
local port = <YOUR_TCP_PORT>;

fusionConnect <- AutodeskFusionConnect(hostname, port);
```

## Class Methods

### sendMessage(*id, messageCode[, values][, callback]*)

This method sends a message to the Fusion Connect platform. It takes the following parameters:

| Parameter | Type | Default | Description |
| ----------| ---- | ------- | ----------- |
| *id* | String | None (Required) | Unique device identifier for the device submitting data. |
| *messageCode* | String | None (Required) | Unique message ‘code’ value that is used by device adapter to identify the correct message definition to be used when processing this message. This value will be defined when you create a “Device Profile” message in your application. This is not the “Device Profile” code value; it is the “Abstract message code” within the “Device Profile”. |
| *values* | Table or array of tables | null | Data to be sent to Fusion Connect platform. The keys in the table correspond to field values associated with the “Message” in the “Device Profile”. |
| *callback* | Function | null | See below. |

&nbsp;<br>If a callback function is supplied, the request will be made asynchronously and the callback will be executed upon completion. The callback takes two parameters, *err* (an error message string) and *data* (a table of response data). If no error is encountered the *err* parameter will be `null`.

#### Example ####

```squirrel
local agentID = split(http.agenturl(), "/").pop();
local messageCode = "env_tail_data";

function printResponse(err, data) {
    if (err) {
        server.error(err);
    } else {
    	server.log("Request Successful");
    }
    server.log(http.jsonencode(data));
}

device.on("reading", function(reading) {
	server.log("Sending request to Autodesk");
    fusionConnect.sendMessage(agentID, messageCode, reading, printResponse);
});
```

#### openDirectiveListener(*id, timer, onMessageCallback[, onErrorCallback]*)

The Fusion Connect platform supports the sending of messages to the device. The device is responsible for checking for available directive messages by periodically submitting requests to the server. Use the *openDirectiveListener()* method to set up a directive request loop. When a directive request is made, if one or more messages are available then the *onMessageCallback* will be triggered for each waiting message.

*openDirectiveListener()* has the following parameters:

| Parameter | Type | Default | Description |
| ----------| ---- | ------- | ----------- |
| *id* | String | None (Required) | Unique device identifier for the device submitting data. |
| *timer* | Integer | None (Required) | The number of seconds to wait between directive requests. |
| *onMessageCallback* | Function | None (Required) | A function that will execute for each message. This function takes one parameter: a response table. See example below for table details. |
| *onErrorCallback* | Function | null | A function that will execute if the directive request is unsuccessful. This function takes two parameters: *err* (a string) and *response* (a table or raw response data). |

#### Example ####

```squirrel
local agentID = split(http.agenturl(), "/").pop();
local msgInterval = 60;    // Check for messages every 60s

function onMsg(response) {
	server.log(http.jsonencode(response));
	/* possible response log:
	   { "success": true,
	     "code": "env_tail_alert",
     	 "target": "szPc0sLYAqlu",
     	 "count": 1,
     	 "time": "2016-04-01T22:02:15Z",
     	 "values": { "alert" : "Temp_High", "temp": "32.6997", "timestamp": "2016-04-01T22:02:15Z" } }
	*/
}

function onErr(err, response) {
	server.error(err);
	// Possible error message: "Error: Missing 'target' value"

	server.log(http.jsonencode(response));
	// Possible response: { "success": false, "message": "Missing 'target' value" }
}

fusionConnect.openDirectiveListener(agentID, msgInterval, onMsg, onErr);
```

### formatTimestamp(*[epochTimestamp]*)

The Autodesk Fusion Connect platform uses XML 8601-formatted timestamps. If no parameter is passed in, this method will return a format recognized by the Autodesk Fusion Connect platform. If an epoch timestamp is passed in, this method will convert it into the preferred format.

```squirrel
local timestamp = fusionConnect.formatTimestamp();
```

## License

The Autodesk Fusion Contect library is licensed under [MIT License](https://github.com/electricimp/AutodeskFusion Contect/tree/master/LICENSE).
