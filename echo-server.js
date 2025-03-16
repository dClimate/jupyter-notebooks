// echo-server.js
const WebSocket = require("ws");

const port = 4001;
const server = new WebSocket.Server({ port }, () => {
	console.log(`Echo server listening on port ${port}`);
});

server.on("connection", (ws) => {
	console.log("Client connected");
	ws.on("message", (message) => {
		console.log(`Received: ${message}`);
		ws.send(`Echo: ${message}`);
	});
});

server.on("error", (err) => {
	console.error("Server error:", err);
});
