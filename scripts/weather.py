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

now = datetime.datetime.now()
now_tz = now.astimezone()

def mph_to_kmh(s):
    nums = [int(x) for x in s.split() if x.isdigit()]
    mph = sum(nums) / len(nums) if nums else 0
    return str(round(mph * 1.60934))

def try_nws():
    def nws_get(url):
        r = urllib.request.Request(url, headers={'User-Agent': 'weather.py'})
        return json.loads(urllib.request.urlopen(r, timeout=10).read())['properties']['periods']

    req = urllib.request.Request(f'https://api.weather.gov/points/{lat},{lon}', headers={'User-Agent': 'weather.py'})
    pts = json.loads(urllib.request.urlopen(req, timeout=10).read())['properties']
    hourly = nws_get(pts['forecastHourly'])
    daily_periods = nws_get(pts['forecast'])
    cur = hourly[0]

    print(cur['temperature'])
    print(cur['temperature'])  # no feels-like in NWS
    print(cur['shortForecast'])
    print(cur['relativeHumidity']['value'])
    print(mph_to_kmh(cur['windSpeed']) + ' ' + cur['windDirection'])

    future = [h for h in hourly if datetime.datetime.fromisoformat(h['startTime']) >= now_tz][:6]
    for h in future:
        dt = datetime.datetime.fromisoformat(h['startTime'])
        print(dt.strftime('%-I:%M %p') + '|' + str(h['temperature']) + '|' + h['shortForecast'])

    print('---DAILY---')
    days = {}
    for p in daily_periods:
        dt = datetime.datetime.fromisoformat(p['startTime'])
        key = dt.date()
        if key not in days: days[key] = {}
        if p['isDaytime']:
            days[key]['max'] = p['temperature']
            days[key]['desc'] = p['shortForecast']
        else:
            days[key]['min'] = p['temperature']
    for date, info in sorted(days.items()):
        if 'max' not in info or 'min' not in info: continue
        label = date.strftime('%a')
        if date == now.date(): label = 'Today'
        elif date == (now + datetime.timedelta(days=1)).date(): label = 'Tmrw'
        print(label + '|' + str(info['max']) + '|' + str(info['min']) + '|' + info['desc'] + '|' + str(date))

    print('---HOURLY-ALL---')
    for h in hourly:
        dt = datetime.datetime.fromisoformat(h['startTime'])
        print(str(dt.date()) + '|' + dt.strftime('%-I %p') + '|' + str(h['temperature']) + '|' + h['shortForecast'])

def try_openmeteo():
    url = (
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=' + lat + '&longitude=' + lon +
        '&current=temperature_2m,apparent_temperature,relative_humidity_2m'
        ',wind_speed_10m,wind_direction_10m,weather_code'
        '&hourly=temperature_2m,weather_code'
        '&daily=temperature_2m_max,temperature_2m_min,weather_code'
        '&temperature_unit=fahrenheit&wind_speed_unit=kmh&timezone=auto&forecast_days=7'
    )
    d = json.loads(urllib.request.urlopen(url, timeout=10).read())
    if 'current' not in d: raise ValueError("bad response")
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
    dirs = ['N','NNE','NE','ENE','E','ESE','SE','SSE','S','SSW','SW','WSW','W','WNW','NW','NNW']
    wdir = dirs[round(c['wind_direction_10m'] / 22.5) % 16]
    desc = wmo.get(c['weather_code'], 'Cloudy')

    print(round(c['temperature_2m']))
    print(round(c['apparent_temperature']))
    print(desc)
    print(c['relative_humidity_2m'])
    print(str(round(c['wind_speed_10m'])) + ' ' + wdir)

    times = d['hourly']['time']
    temps = d['hourly']['temperature_2m']
    codes = d['hourly']['weather_code']

    future = [(i, t) for i, t in enumerate(times)
              if datetime.datetime.fromisoformat(t) >= now][:6]
    for i, t in future:
        dt = datetime.datetime.fromisoformat(t)
        print(dt.strftime('%-I:%M %p') + '|' + str(round(temps[i])) + '|' + wmo.get(codes[i], 'Cloudy'))

    print('---DAILY---')
    daily = d.get('daily', {})
    for i, t in enumerate(daily.get('time', [])):
        dt = datetime.datetime.strptime(t, '%Y-%m-%d')
        day = dt.strftime('%a')
        if dt.date() == now.date(): day = 'Today'
        elif dt.date() == (now + datetime.timedelta(days=1)).date(): day = 'Tmrw'
        print(day + '|' + str(round(daily['temperature_2m_max'][i])) + '|' + str(round(daily['temperature_2m_min'][i])) + '|' + wmo.get(daily['weather_code'][i], 'Cloudy') + '|' + t)

    print('---HOURLY-ALL---')
    for i, t in enumerate(times):
        dt = datetime.datetime.fromisoformat(t)
        print(dt.strftime('%Y-%m-%d') + '|' + dt.strftime('%-I %p') + '|' + str(round(temps[i])) + '|' + wmo.get(codes[i], 'Cloudy'))

try:
    try_nws()
except Exception:
    try:
        try_openmeteo()
    except Exception:
        sys.exit(1)
