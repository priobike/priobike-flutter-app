// to run this, you need to have deno installed (https://deno.land/)
// then run 'deno run -A websocket_dev_server.ts'

import {
  WebSocketClient,
  WebSocketServer,
} from "https://deno.land/x/websocket@v0.1.1/mod.ts";

import { Application, Router } from "https://deno.land/x/oak@v6.5.1/mod.ts";

const route_response = {
  "route": [
    {
      "lon": 13.728118389844894,
      "lat": 51.03063976569504,
      "alt": 140,
      "distanceToNextSignal": 52.01822561395096,
      "signalGroupId": "S-LSA/signalgroup1",
    },
    {
      "lon": 13.727832734584808,
      "lat": 51.0306212102986,
      "alt": 140,
      "distanceToNextSignal": 26.9392436950974,
      "signalGroupId": "S-LSA/signalgroup1",
    },
    {
      "lat": 51.030595907473284,
      "alt": 140,
      "lon": 13.72752159833908,
      "distanceToNextSignal": 0,
      "signalGroupId": "S-LSA/signalgroup1",
    },
    {
      "lon": 13.727286905050278,
      "lat": 51.030581569199484,
      "alt": 140,
      "distanceToNextSignal": 112.27155668547957,
      "signalGroupId": "S-LSA/signalgroup2",
    },
    {
      "lon": 13.727316409349442,
      "lat": 51.030455054826575,
      "alt": 140,
      "distanceToNextSignal": 85.81695442087573,
      "signalGroupId": "S-LSA/signalgroup2",
    },
    {
      "lon": 13.727347254753113,
      "lat": 51.03032769667572,
      "alt": 140,
      "distanceToNextSignal": 78.86404130832345,
      "signalGroupId": "S-LSA/signalgroup2",
    },
    {
      "lon": 13.727569878101349,
      "lat": 51.03033360070368,
      "alt": 140,
      "distanceToNextSignal": 58.37154223389783,
      "signalGroupId": "S-LSA/signalgroup2",
    },
    {
      "lon": 13.72785285115242,
      "lat": 51.030348782486456,
      "alt": 140,
      "distanceToNextSignal": 33.634276697692925,
      "signalGroupId": "S-LSA/signalgroup2",
    },
    {
      "lon": 13.728169351816177,
      "lat": 51.03036480769621,
      "alt": 140,
      "distanceToNextSignal": 8.845198090793144,
      "signalGroupId": "S-LSA/signalgroup2",
    },
    {
      "lat": 51.03039854496179,
      "alt": 140,
      "lon": 13.728181421756744,
      "distanceToNextSignal": 0,
      "signalGroupId": "S-LSA/signalgroup2",
    },
    {
      "lon": 13.728154599666595,
      "lat": 51.03061446287988,
      "alt": 140,
      "distanceToNextSignal": null,
      "signalGroupId": null,
    },
  ],
  "signalGroups": {
    "S-LSA/signalgroup1": {
      "id": "S-LSA/signalgroup1",
      "label": "POT Ampel 1",
      "position": {
        "lat": 51.030595907473284,
        "lon": 13.72752159833908,
      },
    },
    "S-LSA/signalgroup2": {
      "id": "S-LSA/signalgroup2",
      "label": "POT Ampel 2",
      "position": {
        "lat": 51.03039854496179,
        "lon": 13.728181421756744,
      },
    },
  },
  "distance": 260,
  "ascend": 32,
  "descend": 58,
  "estimatedArrival": 998867,
};

const wss = new WebSocketServer(8080);
let isNavigationActive = false;

wss.on("connection", function (ws: WebSocketClient) {
  console.log("someone connected over websockets");
  let timer: number;

  ws.on("message", function (data: string) {
    const message = JSON.parse(data);
    console.log(message);

    switch (message.method) {
      case "Navigation":
        isNavigationActive = message.params.active;

        if (!isNavigationActive && timer) clearInterval(timer);

        ws.send(
          JSON.stringify({
            jsonrpc: "2.0",
            result: { active: isNavigationActive },
            id: message.id,
          }),
        );
        break;

      case "PositionUpdate":
        if (!isNavigationActive) {
          timer = setInterval(() => {
            if (!ws.isClosed && isNavigationActive) {
              console.log("sending back mock recommendation...");
              ws.send(
                JSON.stringify({
                  jsonrpc: "2.0",
                  method: "RecommendationUpdate",
                  params: {
                    label: "Ampel " + Math.trunc(Math.random() * 10),
                    countdown: Math.trunc(Math.random() * 1000),
                    distance: Math.random() * 10000,
                    speedRec: Math.random() * 15,
                    speedDiff: (Math.random() * 10) - 5,
                    green: Math.random() > 0.5 ? true : false,
                    error: Math.random() > 0.5 ? true : false,
                    errorMessage: "",
                    snapPos: { "lat": 51.030453, "lon": 13.727501 },
                    navText: null,
                    navSign: 0,
                    navDist: 0.0,
                  },
                }),
              );
            }
          }, 1000);
        }
        break;
    }
  });

  ws.on("close", function () {
    console.log("someone disconnected");
  });

  ws.on("error", function (error) {
    console.log("error:", error);
  });
});

console.log("websocket server started. listening on port 8080");

const app = new Application();
const router = new Router();

router
  .post(
    "/authentication",
    async ({ request, response }: { request: any; response: any }) => {
      const body = await request.body();
      console.log("got authentication request:", await body.value);
      response.body = { sessionId: "00000000-0000-0000-0000-000000000000" };
    },
  )
  .post(
    "/getroute",
    async ({ request, response }: { request: any; response: any }) => {
      const body = await request.body();
      console.log("got route request:", await body.value);
      response.body = route_response;
    },
  );

app.use(router.routes());
app.use(router.allowedMethods());

console.log("http server started. listening on port 8000");
await app.listen("localhost:8000");
