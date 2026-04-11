#!/usr/bin/env python3
import json
import urllib.request
import datetime
import sys

try:
    loc = json.loads(urllib.request.urlopen('https://ipinfo.io/json', timeout=5).read())
    lat, lon = loc['loc'].split(',')
except Exception:
    lat, lon = '51.5074', '-0.1278'

url = (
    'https://api.open-meteo.com/v1/forecast'
    '?latitude=' + lat + '&longitude=' + lon +
    '&current=temperature_2m,apparent_temperature,relative_humidity_2m'
    ',wind_speed_10m,wind_direction_10m,weather_code'
    '&hourly=temperature_2m,weather_code'
    '&wind_speed_unit=kmh&timezone=auto&forecast_days=2'
)

try:
    d = json.loads(urllib.request.urlopen(url, timeout=10).read())
except Exception:
    sys.exit(1)

c = d['current']

wmo = {
    0: 'Clear sky', 1: 'Mainly clear', 2: 'Partly cloudy', 3: 'Overcast',
    45: 'Foggy', 48: 'Icy fog',
    51: 'Light drizzle', 53: 'Drizzle', 55: 'Heavy drizzle',
    61: 'Light rain', 63: 'Rain', 65: 'Heavy rain',
    71: 'Light snow', 73: 'Snow', 75: 'Heavy snow',
    80: 'Rain showers', 81: 'Showers', 82: 'Heavy showers',
    95: 'Thunderstorm', 96: 'Thunderstorm', 99: 'Thunderstorm',
}

desc = wmo.get(c['weather_code'], 'Cloudy')
dirs = ['N','NNE','NE','ENE','E','ESE','SE','SSE','S','SSW','SW','WSW','W','WNW','NW','NNW']
wdir = dirs[round(c['wind_direction_10m'] / 22.5) % 16]

print(round(c['temperature_2m']))
print(round(c['apparent_temperature']))
print(desc)
print(c['relative_humidity_2m'])
print(str(round(c['wind_speed_10m'])) + ' ' + wdir)

now = datetime.datetime.now()
times = d['hourly']['time']
temps = d['hourly']['temperature_2m']
codes = d['hourly']['weather_code']

future = [(i, t) for i, t in enumerate(times)
          if datetime.datetime.fromisoformat(t) >= now][:6]
for i, t in future:
    dt = datetime.datetime.fromisoformat(t)
    print(dt.strftime('%H:%M') + '|' + str(round(temps[i])) + '|' + wmo.get(codes[i], 'Cloudy'))
