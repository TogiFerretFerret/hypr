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
    '&daily=temperature_2m_max,temperature_2m_min,weather_code'
    '&temperature_unit=fahrenheit&wind_speed_unit=kmh&timezone=auto&forecast_days=7'
)

try:
    d = json.loads(urllib.request.urlopen(url, timeout=10).read())
    if 'current' not in d:
        raise ValueError("bad response")
except Exception:
    # fallback to wttr.in
    try:
        wttr_url = f'https://wttr.in/{lat},{lon}?format=j1'
        w = json.loads(urllib.request.urlopen(wttr_url, timeout=10).read())
        c = w['current_condition'][0]
        dirs = ['N','NNE','NE','ENE','E','ESE','SE','SSE','S','SSW','SW','WSW','W','WNW','NW','NNW']
        wdir = dirs[round(int(c['winddirDegree']) / 22.5) % 16]
        desc = c['weatherDesc'][0]['value']
        print(c['temp_F'])
        print(c['FeelsLikeF'])
        print(desc)
        print(c['humidity'])
        print(c['windspeedKmph'] + ' ' + wdir)
        # next 6 hours from today's hourly
        now = datetime.datetime.now()
        printed = 0
        for day in w['weather']:
            for h in day['hourly']:
                hhmm = h['time'].zfill(4)
                dt = datetime.datetime.strptime(day['date'] + ' ' + hhmm, '%Y-%m-%d %H%M')
                if dt >= now and printed < 6:
                    t = dt.strftime('%-I:%M %p')
                    print(t + '|' + h['tempF'] + '|' + h['weatherDesc'][0]['value'])
                    printed += 1
        print('---DAILY---')
        for day in w['weather']:
            dt = datetime.datetime.strptime(day['date'], '%Y-%m-%d')
            label = dt.strftime('%a')
            if dt.date() == now.date(): label = 'Today'
            elif dt.date() == (now + datetime.timedelta(days=1)).date(): label = 'Tmrw'
            ddesc = day['hourly'][4]['weatherDesc'][0]['value']
            print(label + '|' + day['maxtempF'] + '|' + day['mintempF'] + '|' + ddesc + '|' + day['date'])
        print('---HOURLY-ALL---')
        for day in w['weather']:
            for h in day['hourly']:
                hhmm = h['time'].zfill(4)
                dt = datetime.datetime.strptime(day['date'] + ' ' + hhmm, '%Y-%m-%d %H%M')
                print(day['date'] + '|' + dt.strftime('%-I %p') + '|' + h['tempF'] + '|' + h['weatherDesc'][0]['value'])
    except Exception:
        sys.exit(1)
    sys.exit(0)

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

# Today's remaining hourly (next 6 hours)
future = [(i, t) for i, t in enumerate(times)
          if datetime.datetime.fromisoformat(t) >= now][:6]
for i, t in future:
    dt = datetime.datetime.fromisoformat(t)
    print(dt.strftime('%-I:%M %p') + '|' + str(round(temps[i])) + '|' + wmo.get(codes[i], 'Cloudy'))

# Daily forecast (7 days)
print('---DAILY---')
daily = d.get('daily', {})
dtimes = daily.get('time', [])
dmaxs = daily.get('temperature_2m_max', [])
dmins = daily.get('temperature_2m_min', [])
dcodes = daily.get('weather_code', [])
for i, t in enumerate(dtimes):
    dt = datetime.datetime.strptime(t, '%Y-%m-%d')
    day = dt.strftime('%a')
    if dt.date() == now.date():
        day = 'Today'
    elif dt.date() == (now + datetime.timedelta(days=1)).date():
        day = 'Tmrw'
    print(day + '|' + str(round(dmaxs[i])) + '|' + str(round(dmins[i])) + '|' + wmo.get(dcodes[i], 'Cloudy') + '|' + t)

# All hourly data grouped by date (for drill-down)
print('---HOURLY-ALL---')
for i, t in enumerate(times):
    dt = datetime.datetime.fromisoformat(t)
    print(dt.strftime('%Y-%m-%d') + '|' + dt.strftime('%-I %p') + '|' + str(round(temps[i])) + '|' + wmo.get(codes[i], 'Cloudy'))
