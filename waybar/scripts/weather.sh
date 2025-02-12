#!/bin/sh
  
get_icon() {
    case $1 in

          01d) icon="<span font-size='large'></span>";;
          01n) icon="<span font-size='large'></span>";;
          02d) icon="<span font-size='large'></span>";;
          02n) icon="<span font-size='large'></span>";;
          03d) icon="<span font-size='large'></span>";;
          03n) icon="<span font-size='large'></span>";;
          04d) icon="<span font-size='large'></span>";;
          04n) icon="<span font-size='large'></span>";;
          09d) icon="<span font-size='large'></span>";;
          09n) icon="<span font-size='large'></span>";;
          10d) icon="<span font-size='large'></span>";;
          10n) icon="<span font-size='large'></span>";;
          11d) icon="<span font-size='large'></span>";;
          11n) icon="<span font-size='large'></span>";;
          13d) icon="<span font-size='large'></span>";;
          13n) icon="<span font-size='large'></span>";;
          50d) icon="<span font-size='large'></span>";;
          50n) icon="<span font-size='large'></span>";;
          *)   icon="<span font-size='large'></span>";;


    esac

    echo "$icon"
}

KEY=$(cat "$HOME"/.keys/openweather-api-key)
CITY=""
UNITS="metric"
SYMBOL="°"

location_lon=$(cat "$HOME/.keys/other/lon")
location_lat=$(cat "$HOME/.keys/other/lat")

API="https://api.openweathermap.org/data/2.5"

if [ "$CITY" != "" ]; then
    if [ "$CITY" -eq "$CITY" ] 2>/dev/null; then
        CITY_PARAM="id=$CITY"
    else
        CITY_PARAM="q=$CITY"
    fi

    weather=$(curl -sf "$API/weather?appid=$KEY&$CITY_PARAM&units=$UNITS")
else
    weather=$(curl -sf "$API/weather?appid=$KEY&lat=$location_lat&lon=$location_lon&units=$UNITS")
fi

if [ "$weather" != "" ]; then
    weather_temp=$(echo "$weather" | jq ".main.temp" | cut -d "." -f 1)
    weather_icon=$(echo "$weather" | jq -r ".weather[0].icon")

    echo "$(get_icon "$weather_icon")"" ""$weather_temp$SYMBOL"
fi
