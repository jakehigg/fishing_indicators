from math import radians, sin, cos, sqrt, atan2
import requests


def get_closest_stations(lat, long, num_stations=5):
    url = "https://api.tidesandcurrents.noaa.gov/mdapi/prod/webapi/stations.json?type=waterlevels&expand=details"
    response = requests.get(url, timeout=5)
    station_list = []
    for item in response.json()["stations"]:
        station_list.append(
            {
                "state": item["state"],
                "station_id": item["id"],
                "station_name": item["name"],
                "lat": item["lat"],
                "long": item["lng"],
            }
        )

    for station in station_list:
        station["distance"] = haversine(lat, long, station["lat"], station["long"])

    closest_stations = sorted(station_list, key=lambda x: x["distance"])[:num_stations]

    # Print closest stations
    for station in closest_stations:
        print(
            f"Station ID: {station['station_id']}, Name: {station['station_name']}, "
            f"State: {station['state']}, Distance: {station['distance']:.2f} km"
        )

    return closest_stations


def haversine(lat1, lon1, lat2, lon2):
    """Calculate the great-circle distance in kilometers between two points."""
    earth_radius = 6371  # Earth's radius in km
    dlat = radians(lat2 - lat1)
    dlon = radians(lon2 - lon1)
    a = (
        sin(dlat / 2) ** 2
        + cos(radians(lat1)) * cos(radians(lat2)) * sin(dlon / 2) ** 2
    )
    c = 2 * atan2(sqrt(a), sqrt(1 - a))
    return earth_radius * c
