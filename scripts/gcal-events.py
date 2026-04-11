#!/usr/bin/env python3
"""Fetch upcoming events from an ICS feed and print as simple text."""
import sys
from datetime import datetime, timedelta, date, timezone
from pathlib import Path
import urllib.request

URL_FILE = Path.home() / ".config" / "calendar-url"
if not URL_FILE.exists():
    sys.exit(0)

url = URL_FILE.read_text().strip()
if not url:
    sys.exit(0)

try:
    with urllib.request.urlopen(url, timeout=10) as r:
        ics = r.read().decode("utf-8", errors="replace")
except Exception:
    sys.exit(0)

# Local aware current time
now = datetime.now().astimezone()
today = now.date()
window = today + timedelta(days=14)

events = []
in_event = False
summary = ""
dtstart = None
dtend = None
all_day = False

def parse_date(raw):
    try:
        if raw.endswith("Z"):
            return datetime.strptime(raw[:15], "%Y%m%dT%H%M%S").replace(tzinfo=timezone.utc).astimezone()
        else:
            return datetime.strptime(raw[:15], "%Y%m%dT%H%M%S").astimezone()
    except ValueError:
        return None

for line in ics.replace("\r\n ", "").replace("\r\n\t", "").split("\r\n"):
    if line == "BEGIN:VEVENT":
        in_event = True
        summary = ""
        dtstart = None
        dtend = None
        all_day = False
    elif line == "END:VEVENT":
        if in_event and dtstart and summary:
            is_past = False
            if isinstance(dtstart, datetime):
                # For timed events, use DTEND if available, else DTSTART
                # (Assuming 0 duration if no DTEND)
                end_time = dtend if dtend else dtstart
                if end_time < now:
                    is_past = True
            else:
                # For all-day events, DTEND is the day AFTER the event ends (exclusive)
                # If DTEND is today, it ended at 00:00 today.
                # If DTEND is missing, we assume it's just one day (today).
                if dtend:
                    if dtend <= today:
                        is_past = True
                elif dtstart < today:
                    is_past = True
            
            if not is_past:
                d = dtstart.date() if isinstance(dtstart, datetime) else dtstart
                if d <= window:
                    events.append((dtstart, summary, all_day))
        in_event = False
    elif in_event:
        if line.startswith("SUMMARY:"):
            summary = line[8:].strip()
        elif line.startswith("DTSTART;VALUE=DATE:"):
            try:
                dtstart = datetime.strptime(line.split(":")[-1][:8], "%Y%m%d").date()
                all_day = True
            except ValueError: pass
        elif line.startswith("DTSTART"):
            dtstart = parse_date(line.split(":")[-1])
            all_day = False
        elif line.startswith("DTEND;VALUE=DATE:"):
            try:
                dtend = datetime.strptime(line.split(":")[-1][:8], "%Y%m%d").date()
            except ValueError: pass
        elif line.startswith("DTEND"):
            dtend = parse_date(line.split(":")[-1])

def get_dt_for_sort(e):
    dt = e[0]
    if isinstance(dt, datetime): return dt
    return datetime.combine(dt, datetime.min.time()).astimezone()

events.sort(key=get_dt_for_sort)

for dt, summ, ad in events[:8]:
    if ad:
        d = dt if isinstance(dt, date) else dt.date()
        prefix = "Today" if d == today else ("Tomorrow" if d == today + timedelta(days=1) else d.strftime("%b %d"))
        print(f"{prefix}|{summ}")
    else:
        if isinstance(dt, datetime):
            if dt.date() == today:
                prefix = dt.strftime("%H:%M")
            elif dt.date() == today + timedelta(days=1):
                prefix = "Tmrw " + dt.strftime("%H:%M")
            else:
                prefix = dt.strftime("%b %d %H:%M")
        else:
            prefix = str(dt)
        print(f"{prefix}|{summ}")
