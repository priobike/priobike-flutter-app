type Message = {
  id: string;
  type:
    | "hello"
    | "start"
    | "stop"
    | "routerequest"
    | "routeresponse"
    | "position"
    | "recommendation"
    | "goodbye";
  payload: null | RouteRequest | Position | Recommendation;
};

type RouteRequest = {
  fromLat: number;
  fromLon: number;
  toLat: number;
  toLon: number;
};

type Position = {
  lat: number;
  lon: number;
  speed: number;
};

type Recommendation = {
  label: string;
  countdown: string;
  distance: number;
  speedRec: number;
  speedDiff: number;
  isGreen: boolean;
  error: boolean;
  errorMessage: string;
};
