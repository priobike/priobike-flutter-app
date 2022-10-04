## Downloading offline mapbox tiles

Light Mode
```
docker run \
    -it \
    --rm \
    -v $PWD:/output/ \
    -w /output/ \
    ordnancesurvey/whalebrew-mbgl-offline \
        mbgl-offline \
        --north 53.748 \
        --south 53.3742 \
        --west 9.6329 \
        --east 9.6329 \
        --minZoom 0 \
        --maxZoom 20 \
        --style "mapbox://styles/snrmtths/cl77mab5k000214mkk26ewqqu" \
        --token "pk.eyJ1Ijoic25ybXR0aHMiLCJhIjoiY2w0ZWVlcWt5MDAwZjNjbW5nMHNvN3kwNiJ9.upoSvMqKIFe3V_zPt1KxmA" \
        --output "hamburg-light.db"
```

Dark Mode
```
docker run \
    -it \
    --rm \
    -v $PWD:/output/ \
    -w /output/ \
    ordnancesurvey/whalebrew-mbgl-offline \
        mbgl-offline \
        --north 53.748 \
        --south 53.3742 \
        --west 9.6329 \
        --east 9.6329 \
        --minZoom 0 \
        --maxZoom 20 \
        --style "mapbox://styles/mapbox/dark-v10" \
        --token "pk.eyJ1Ijoic25ybXR0aHMiLCJhIjoiY2w0ZWVlcWt5MDAwZjNjbW5nMHNvN3kwNiJ9.upoSvMqKIFe3V_zPt1KxmA" \
        --output "hamburg-dark.db"
```
