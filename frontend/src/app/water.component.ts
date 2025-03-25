import { Component, OnChanges, SimpleChanges, Input } from '@angular/core';
import { HttpClient, HttpClientModule } from '@angular/common/http'; 
import { MatCardModule } from '@angular/material/card';
import { environment } from '../environments/environment'; 
import { CommonModule } from '@angular/common';
import { convertUTCToLocalTime } from './_helpers';

@Component({
  selector: 'water-component',
  standalone: true,
  imports: [MatCardModule, HttpClientModule, CommonModule],
  templateUrl: './water.component.html',
  styleUrls: ['./app.component.scss'],
})
export class WaterComponent implements OnChanges {
  @Input() locationData: { lat: number; long: number; accuracy: number } | null = null; 
  currentTideCycle: string | null = null; 
  currentWaterLevel: number | null = null; 
  nextTideTime: string | null = null; 
  nextTideV: number | null = null; 
  waterTemperature: number | null = null; 
  stationName: string | null = null; 
  waterTemperatureTimeStamp: string | null = null; 
  waterTemperatureTrend: string | null = null; 
  constructor(private http: HttpClient) {}

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['locationData']) {
  
      if (this.locationData) {
        this.getTides();
        this.getWaterTemperature();
      }
    }
  }

  private getTides() {
    if (!this.locationData) return;

    const url = `${environment.apiUrl}/tide?lat=${this.locationData.lat}&long=${this.locationData.long}&accuracy=${this.locationData.accuracy}`;
    this.http.get<{ current_water_level: number, current_tide_cycle: string; next_tide_time: string; next_tide_v: number }>(url).subscribe({
      next: (response) => {
        this.currentWaterLevel = response.current_water_level;
        this.currentTideCycle = response.current_tide_cycle;
        this.nextTideTime = convertUTCToLocalTime(response.next_tide_time);
        this.nextTideV = response.next_tide_v;
        
      },
      error: (err) => {
        console.error('Error fetching tide data:', err);
      }
    });
  }

  private getWaterTemperature() {
    if (!this.locationData) return;

    const url = `${environment.apiUrl}/water_temperature?lat=${this.locationData.lat}&long=${this.locationData.long}&accuracy=${this.locationData.accuracy}`;
    this.http.get<{ current_water_temperature: number, station_name: string, metric_time: string, trend: string }>(url).subscribe({
      next: (response) => {
        this.waterTemperature = response.current_water_temperature;
        this.stationName = response.station_name;
        this.waterTemperatureTimeStamp = convertUTCToLocalTime(response.metric_time);
        this.waterTemperatureTrend = response.trend;
      },
      error: (err) => {
        console.error('Error fetching water temperature:', err); 
      }
    });
  }

}
