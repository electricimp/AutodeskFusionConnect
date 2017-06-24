# Autodesk Fusion Connect

This library allows your agent to support [Autodesk’s Fusion Connect](http://autodeskfusionconnect.com/), an enterprise IoT cloud service that helps manufacturers to connect, analyze, and manage their products.

**To add this library to your project, add** `#require "AutodeskFusionConnect.agent.lib.nut:3.0.0"` **to the top of your agent code**

## Class Usage

### Constructor: AutodeskFusionConnect(connectionString)

The AutodeskFusionConnect constructor takes one parameter: *connectionString* -
connection string for your account provided by Autodesk.
The string includes the protocol (http or https), host name and port.

```squirrel
#require "AutodeskFusionConnect.agent.lib.nut:3.0.0"

const CONNECTION_STRING = "https://comm-d.dev.fusionconnect.autodesk.com:49181";
fusionConnect <- AutodeskFusionConnect(CONNECTION_STRING);
```

## Class Methods

### sendMessage(*id, messageCode, payload[, callback]*)

This method sends a message to the Fusion Connect platform. It takes the following parameters:

| Parameter | Type | Default | Description |
| ----------| ---- | ------- | ----------- |
| *id* | String | None (Required) | Unique device identifier for the device submitting data. |
| *messageCode* | String | None (Required) | Unique message ‘code’ value that is used by device adapter to identify the correct message definition to be used when processing this message. This value will be defined when you create a “Device Profile” message in your application. This is not the “Device Profile” code value; it is the “Abstract message code” within the “Device Profile”. |
| *payload* | Table | None (Required) | The payload table to be sent to the Fusion Connect platform. Please see the table below for more details. |
| *callback* | Function | null | See below. |

The payload table contains the following entries:

| Entry | Type | Default | Description |
| ----------| ---- | ------- | ----------- |
| *value* | Table | None (Required) | The table with valued being sent to Autodesk. The keys in the table correspond to field values associated with the “Message” in the “Device Profile”. |
| *time* | String | None (Required) | [ISO 8601](https://www.iso.org/iso-8601-date-and-time-format.html) formatted event time value. Must be formatted with the `formatTimestamp` call. |
| *location* | Table | null | A optional table with `latitude` and `longitude` entries. |

&nbsp;<br>If a callback function is supplied to the `sendMessage` method, the
request will be made asynchronously and the callback will be executed upon
completion. The callback takes two parameters, *err* (an error message string)
and *data* (a table of response data). If no error is encountered the *err*
parameter will be `null`.

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

### openDirectiveListener(*id, timer, onMessageCallback[, onErrorCallback]*)

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

The Autodesk Fusion Connect platform uses [ISO 8601](https://www.iso.org/iso-8601-date-and-time-format.html) formatted timestamps. 
If no parameter is passed in, this method will return ISO 8601-formatted current time. 
If an epoch timestamp is passed in, this method will convert it into the preferred format.

```squirrel
local timestamp = fusionConnect.formatTimestamp();
```

## License

The Autodesk Fusion Connect library is licensed under [MIT License](LICENSE).
