// to run this, you need to have deno installed (deno.land)
// then run 'deno run -A websocket_dev_server.ts'

import {
  WebSocket,
  WebSocketServer,
} from "https://deno.land/x/websocket@v0.0.6/mod.ts";

const wss = new WebSocketServer(8080);
wss.on("connection", function (ws: WebSocket) {
  console.log("someone connected");

  let timer = setInterval(() => {
    ws.send("ping" + Date());
  }, 1000);

  ws.on("message", function (message: string) {
    console.log("message:", message);
    ws.send(message);
  });

  ws.on("close", function () {
    console.log("someone disconnected");
    clearInterval(timer);
  });
});
