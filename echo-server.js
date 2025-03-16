// echo-server.js
const https = require("https");
const fs = require("fs");
const WebSocket = require("ws");

const port = 4001;

// Read your TLS certificate and key
const serverOptions = {
	key: fs.readFileSync("key.pem"),
	cert: fs.readFileSync("cert.pem"),
};

// Create an HTTPS server using the certificate and key
const httpsServer = https.createServer(serverOptions);

// Create the WebSocket server, binding it to the HTTPS server
const wss = new WebSocket.Server({ server: httpsServer });

httpsServer.listen(port, "0.0.0.0", () => {
	console.log(`TLS Echo server listening on port ${port}`);
});

wss.on("connection", (ws) => {
	console.log("Client connected");
	ws.on("message", (message) => {
		console.log(`Received: ${message}`);
		ws.send(`Echo: ${message}`);
	});
});

wss.on("error", (err) => {
	console.error("Server error:", err);
});
