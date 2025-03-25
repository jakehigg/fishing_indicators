import { Component, OnChanges, SimpleChanges, Input } from '@angular/core';
import { HttpClient, HttpClientModule } from '@angular/common/http'; // Import HttpClientModule
import { MatCardModule } from '@angular/material/card';
import { environment } from '../environments/environment'; // Make sure you have the API URL set in the environment file
import { CommonModule } from '@angular/common';
import { convertUTCToLocalTime } from './_helpers';

@Component({
  selector: 'current-weather-component',
  standalone: true,
  imports: [MatCardModule, HttpClientModule, CommonModule], // Add HttpClientModule to the imports array
  templateUrl: './current_weather.component.html',
  styleUrls: ['./app.component.scss'],
})
export class CurrentWeatherComponent implements OnChanges {
  @Input() locationData: { lat: number; long: number; accuracy: number } | null = null; // To store the current location() position: { lat: number; long: number; accuracy: number } | null = null; // To store the current location
  startTime: string | null = null;
  endTime: string | null = null;
  isDaytime: boolean = false;
  temperature: number | null = null;
  temperatureUnit: string | null = null;
  temperatureTrend: string | null = null;
  precipitationProbability: number | null = null;
  windSpeed: string | null = null;
  windDirection: string | null = null;
  weatherIcon: string | null = null;
  shortForecast: string | null = null;
  detailedForecast: string | null = null;

  constructor(private http: HttpClient) {}

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['locationData']) {
  
      if (this.locationData) {
        this.getWeather();
      }
    }
  }

  private getWeather() {
    if (!this.locationData) return;


    const url = `${environment.apiUrl}/weather?lat=${this.locationData.lat}&long=${this.locationData.long}&accuracy=${this.locationData.accuracy}`;
    this.http.get<{ 
        current_tide_cycle: string, 
        next_tide_time: string, 
        next_tide_v: number,
        period_name: string,
        start_time: string,
        end_time: string,
        is_daytime: boolean,
        temperature: number,
        temperature_unit: string,
        temperature_trend: string,
        precipitation_probability: number,
        wind_speed: string,
        wind_direction: string,
        icon: string,
        short_forecast: string,
        detailed_forecast: string
    }>(url).subscribe({
        next: (response) => {
        this.isDaytime = response.is_daytime;
        this.temperature = response.temperature;
        this.temperatureUnit = response.temperature_unit;
        this.temperatureTrend = response.temperature_trend;
        this.precipitationProbability = response.precipitation_probability;
        this.windSpeed = response.wind_speed;
        this.windDirection = response.wind_direction;
        this.weatherIcon = response.icon;
        this.shortForecast = response.short_forecast;
        this.detailedForecast = response.detailed_forecast;
        },
        error: (err) => {
        console.error('Error fetching weather data:', err);
        }
    });
    }
    

}
