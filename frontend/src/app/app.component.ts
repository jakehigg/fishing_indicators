import { ChangeDetectionStrategy, Component, OnInit } from '@angular/core';
import { HttpClient, HttpClientModule } from '@angular/common/http'; // Import HttpClientModule
import { MatCardModule } from '@angular/material/card';
import { environment } from '../environments/environment'; // Make sure you have the API URL set in the environment file
import { WaterComponent } from './water.component';
import { CurrentWeatherComponent } from './current_weather.component';
import { ChartComponent } from './chart.component';
import { TideChartComponent } from './tide-chart.component';
@Component({
  selector: 'app-root',
  standalone: true,
  imports: [
    MatCardModule, 
    HttpClientModule, 
    WaterComponent, 
    CurrentWeatherComponent, 
    TideChartComponent
  ],
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.scss'],

})
export class AppComponent implements OnInit {
  title = 'find_frontend';
  locationData: { lat: number; long: number; accuracy: number } | null = null; // To store the current location

  constructor(private http: HttpClient) {}

  ngOnInit(): void {
    this.getLocation(); 
  }

  public getLocation() {
    navigator.geolocation.getCurrentPosition(
      (position) => {
        this.locationData = {
          lat: position.coords.latitude,
          long: position.coords.longitude,
          accuracy: position.coords.accuracy,
        };  
      },
      (error) => {
        console.error('Geolocation error:', error);
      }
    );
  }
}
