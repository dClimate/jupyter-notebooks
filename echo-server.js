// echo-server.js
const http = require("http");
const WebSocket = require("ws");

// Use Railway’s assigned port or default to 80.
const port = process.env.PORT || 80;

// Create an HTTP server that can also handle upgrade requests.
const server = http.createServer((req, res) => {
	res.writeHead(200, { "Content-Type": "text/plain" });
	res.end("Hello, this is an HTTP server that supports WebSocket upgrades.");
});

server.listen(port, "0.0.0.0", () => {
	console.log(`HTTP/WebSocket server listening on port ${port}`);
});

// Bind the WebSocket server to the same HTTP server.
const wss = new WebSocket.Server({ server });

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
