#!/bin/sh
  
get_icon() {
    case $1 in
          01d) icon=" ";;
          01n) icon=" ";;
          02d) icon=" ";;
          02n) icon=" ";;
          03d) icon=" ";;
          03n) icon=" ";;
          04d) icon=" ";;
          04n) icon=" ";;
          09d) icon=" ";;
          09n) icon=" ";;
          10d) icon=" ";;
          10n) icon=" ";;
          11d) icon=" ";;
          11n) icon=" ";;
          13d) icon=" ";;
          13n) icon=" ";;
          50d) icon=" ";;
          50n) icon=" ";;
          *)   icon=" ";;
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

    echo "$(get_icon "$weather_icon")""$weather_temp$SYMBOL"
fi
