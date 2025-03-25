from datetime import datetime, timedelta, timezone
import json
import requests
from utils import get_closest_stations
import numpy as np


def lambda_handler(event, context):
    # return get_water_temperature(station_id='8575512'), 200
    path = event.get("path", {})

    query_params = event.get("queryStringParameters", {})

    # Extract individual parameters
    lat = query_params.get("lat")
    long = query_params.get("long")
    station_id = query_params.get("station_id", None)
    if not station_id:
        station_list = get_closest_stations(float(lat), float(long))
        station_id = station_list[0]["station_id"]

    if path == "/water_temperature":
        temperature_conditions = get_water_temperature(station_id=station_id)
        return {"statusCode": 200, "body": json.dumps(temperature_conditions)}
    if path == "/tide":
        tide_conditions = get_tide(station_id=station_id)
        return {"statusCode": 200, "body": json.dumps(tide_conditions)}
    if path == "/weather":
        forecast_data = get_weather_forecast(lat=lat, long=long)
        weather_conditions = get_weather(forecast_data=forecast_data)
        return {"statusCode": 200, "body": json.dumps(weather_conditions)}

    return {"statusCode": 404, "body": json.dumps({"error": "Invalid path"})}


def get_water_temperature(station_id):
    current_date = datetime.now(tz=timezone.utc)
    current_date_string = current_date.strftime("%Y%m%d")
    url = (
        f"https://api.tidesandcurrents.noaa.gov/api/prod/datagetter?"
        f"product=water_temperature&begin_date={current_date_string}&"
        f"end_date={current_date_string}&station={station_id}&"
        "time_zone=GMT&units=english&interval=6&format=json&application=NOS.COOPS.TAC.PHYSOCEAN"
    )
    response = requests.get(url, timeout=5)
    trend = get_water_temperature_trend(response.json()["data"])
    api_response_data = response.json()["data"]
    api_response_metadata = response.json()["metadata"]
    api_response_datetimes = []
    for item in api_response_data:
        api_response_datetimes.append(
            datetime.strptime(item["t"], "%Y-%m-%d %H:%M").replace(tzinfo=timezone.utc)
        )
    closest = min(api_response_datetimes, key=lambda x: abs(x - current_date))
    conditions = {
        "station_id": station_id,
        "station_name": api_response_metadata["name"],
        "metric_time": closest.strftime("%Y-%m-%d %H:%M"),
        "current_water_temperature": api_response_data[
            api_response_datetimes.index(closest)
        ]["v"],
        "trend": trend,
    }
    return conditions


def get_water_temperature_trend(data, hours=3, threshold=0.2, avg_window=5):
    now = datetime.utcnow()
    time_limit = now - timedelta(hours=hours)

    recent_data = [
        entry
        for entry in data
        if datetime.strptime(entry["t"], "%Y-%m-%d %H:%M") >= time_limit
    ]

    if len(recent_data) < 2:
        return "Not enough data"

    recent_data.sort(key=lambda x: datetime.strptime(x["t"], "%Y-%m-%d %H:%M"))

    first_temps = [float(entry["v"]) for entry in recent_data[:avg_window]]
    last_temps = [float(entry["v"]) for entry in recent_data[-avg_window:]]

    first_avg = np.mean(first_temps)
    last_avg = np.mean(last_temps)

    if last_avg > first_avg + threshold:
        return "Rising"
    if last_avg < first_avg - threshold:
        return "Falling"

    return "Stable"


def get_tide(station_id):
    """
    Gets the current tide conditions using the NOAA API.
    Currently it only supports Annapolis, MD.
    Since the NOAA API uses local time we need to use the Annapolis, MD time zone.

    This function takes no parameters.

    Returns:
    dict: The current tide conditions.

    """
    url = "https://api.tidesandcurrents.noaa.gov/api/prod/datagetter"

    today = datetime.now(tz=timezone.utc).strftime("%Y%m%d")
    tomorrow = (datetime.now(tz=timezone.utc) + timedelta(days=2)).strftime("%Y%m%d")

    prediction_params = {
        "station": station_id,
        "product": "predictions",
        "datum": "MLLW",
        "time_zone": "GMT",
        "units": "english",
        "interval": "hilo",
        "begin_date": today,
        "end_date": tomorrow,
        "format": "json",
    }

    water_level_params = {
        "station": station_id,
        "product": "water_level",
        "datum": "MLLW",
        "time_zone": "GMT",
        "units": "english",
        "interval": "hilo",
        "begin_date": today,
        "end_date": tomorrow,
        "format": "json",
    }

    try:
        tide_data = requests.get(url, params=prediction_params, timeout=5).json()
        water_level_data = requests.get(
            url, params=water_level_params, timeout=5
        ).json()
    except requests.exceptions.RequestException as e:
        return {"error": f"Failed to retrieve tide data: {str(e)}"}

    if "error" in tide_data:
        return {"error": tide_data["error"]["message"]}

    cleaned_water_levels_retval = []
    for entry in tide_data["predictions"]:
        t = entry["t"]
        v = None
        for item in water_level_data["data"]:
            if (
                abs(
                    (
                        datetime.strptime(t, "%Y-%m-%d %H:%M")
                        - datetime.strptime(item["t"], "%Y-%m-%d %H:%M")
                    ).total_seconds()
                )
                < 300
            ):
                v = item["v"]
                break
        if v is None:
            print(f"Warning: No water level data found for {t}")
            continue

        cleaned_water_levels_retval.append(
            {
                "t": t,
                "v": v,
            }
        )

    tide_cycle_data = get_tide_cycle(tide_data["predictions"])

    return {
        "current_tide_cycle": tide_cycle_data["tide_cycle"],
        "next_tide_time": tide_cycle_data["next_tide_time"],
        "next_tide_v": tide_cycle_data["next_tide_v"],
        "current_water_level": water_level_data["data"][-1]["v"],
        "predictions_data": tide_data,
        "water_level_data": {"water_levels": water_level_data["data"]},
    }


def get_tide_cycle(predictions):
    current_time = datetime.now(tz=timezone.utc)
    next_tide = None
    for prediction in predictions:
        tide_time = datetime.strptime(prediction["t"], "%Y-%m-%d %H:%M").replace(
            tzinfo=timezone.utc
        )
        if tide_time > current_time:
            next_tide = prediction
            break

    tide_cycle = "Unk"
    if next_tide:
        if next_tide["type"] == "L":
            tide_cycle = "Falling"
        elif next_tide["type"] == "H" and next_tide["type"] == "H":
            tide_cycle = "Rising"

    return {
        "next_tide_time": datetime.strptime(next_tide["t"], "%Y-%m-%d %H:%M")
        .replace(tzinfo=timezone.utc)
        .strftime("%Y-%m-%d %H:%M"),
        "next_tide_v": next_tide["v"],
        "tide_cycle": tide_cycle,
    }


def get_weather_forecast(lat, long):
    """
    Fetch the current weather conditions for a given latitude and longitude using
    the National Weather Service (NWS) API.  Current Conditions are the current weather prediction
    for the current hour.

    Parameters:
    lat (float): The latitude for the location.
    long (float): The longitude for the location.

    Returns:
    dict: The current weather conditions for the given location.

    Raises:
    requests.exceptions.RequestException: If the request to the NWS API fails.
    json.JSONDecodeError: if the JSON response cannot be parsed.
    """

    # NWS API only accepts 4 decimal places for latitude and longitude
    new_lat = round(float(lat), 4)
    new_long = round(float(long), 4)

    try:
        gridpoint_url = f"https://api.weather.gov/points/{new_lat},{new_long}"
        gridpoint_response = requests.get(gridpoint_url, timeout=5)
        gridpoint_data = gridpoint_response.json()
    except requests.exceptions.RequestException as ex:
        return {"error": f"Failed to fetch grid coordinates: {ex}"}

    forecast_url = f"{gridpoint_data['properties']['forecast']}/hourly"

    try:
        forecast_response = requests.get(forecast_url, timeout=5)
    except requests.exceptions.RequestException as ex:
        return {"error": f"Failed to fetch forecast data: {ex}"}

    try:
        forecast_data = json.loads(forecast_response.text)
    except json.JSONDecodeError as ex:
        return {"error": f"Failed to parse forecast data: {ex}"}

    return forecast_data


def get_weather(forecast_data, hours=1):
    if hours == 1:
        for period in forecast_data["properties"]["periods"]:
            if datetime.fromisoformat(period["startTime"]).replace(
                tzinfo=timezone.utc
            ) <= datetime.now(tz=timezone.utc):
                if datetime.fromisoformat(period["endTime"]).replace(
                    tzinfo=timezone.utc
                ) > datetime.now(tz=timezone.utc):
                    current_conditions = period
                    break
    else:
        pass

    response_object = {
        "start_time": datetime.fromisoformat(current_conditions["startTime"])
        .replace(tzinfo=timezone.utc)
        .strftime("%Y-%m-%d %H:%M"),
        "end_time": datetime.fromisoformat(current_conditions["endTime"])
        .replace(tzinfo=timezone.utc)
        .strftime("%Y-%m-%d %H:%M"),
        "is_daytime": current_conditions["isDaytime"],
        "temperature": current_conditions["temperature"],
        "temperature_unit": current_conditions["temperatureUnit"],
        "temperature_trend": current_conditions.get("temperatureTrend", None),
        "precipitation_probability": current_conditions["probabilityOfPrecipitation"][
            "value"
        ],
        "wind_speed": current_conditions["windSpeed"],
        "wind_direction": current_conditions["windDirection"],
        "icon": current_conditions["icon"],
        "short_forecast": current_conditions["shortForecast"],
        "detailed_forecast": current_conditions["detailedForecast"],
    }

    return response_object
