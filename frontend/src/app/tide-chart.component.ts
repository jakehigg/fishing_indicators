import { Component, ViewChild, ElementRef, OnChanges, SimpleChanges, Input, AfterViewInit, AfterViewChecked } from '@angular/core';
import { Chart } from 'chart.js/auto';
import { MatCardModule } from '@angular/material/card';
import { HttpClient, HttpClientModule } from '@angular/common/http';
import { CommonModule } from '@angular/common';
import { environment } from '../environments/environment'; 
import { convertUTCToLocalTime } from './_helpers';
import 'chartjs-adapter-moment';
interface WaterLevels {
  t: string;
  v: string;
}

interface PredictionRawData {
  predictions: WaterLevels[];
}

interface WaterLevelRawData {
  water_levels: WaterLevels[];
}

interface TideData {
  current_tide_cycle: string;
  next_tide_time: string;
  next_tide_v: string;
  station_name: string;
  predictions_data: PredictionRawData;
  water_level_data: WaterLevelRawData;
}

@Component({
  selector: 'tide-chart-component',
  standalone: true,
  imports: [MatCardModule, HttpClientModule, CommonModule],
  templateUrl: './tide-chart.component.html',
  styleUrls: ['./app.component.scss'],
})
export class TideChartComponent implements OnChanges, AfterViewChecked {
  @ViewChild('tideChart') chartRef!: ElementRef<HTMLCanvasElement>;
  @Input() locationData: { lat: number; long: number; accuracy: number } | null = null; 

  currentTideCycle: string = '';
  nextTideTime: string = '';
  nextTideV: string = '';
  stationName: string | null = null; 
  predictions: WaterLevels[] = [];
  water_level_data: WaterLevels[] = [];
  private chartInstance: Chart | null = null; 

  constructor(private http: HttpClient) {}

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['locationData'] && this.locationData) {
      if (!this.chartRef?.nativeElement) {
        console.error('Chart canvas not found');
        return;
      }
      this.getTides();  
      // Avoid re-creating the chart if it already exists
      if (!this.chartRef) {
        this.createChart();
      }
  
      
    }
  }

  ngAfterViewChecked() {
    if (this.chartRef?.nativeElement) {
      this.createChart();
    }
  }

  private getTides() {
    if (!this.locationData) return;
    const url = `${environment.apiUrl}/tide?lat=${this.locationData.lat}&long=${this.locationData.long}&accuracy=${this.locationData.accuracy}`;
    this.http.get<TideData>(url).subscribe({
      next: (response) => {
        this.currentTideCycle = response.current_tide_cycle;
        this.nextTideTime = convertUTCToLocalTime(response.next_tide_time);
        this.nextTideV = response.next_tide_v;
        this.stationName = response.station_name;
        this.predictions = response.predictions_data.predictions;
        this.water_level_data = response.water_level_data.water_levels;
        this.updateChart();
      },
      error: (err) => {
        console.error('Error fetching tide data:', err);
      }
    });
  }

  private createChart() {
    if (this.chartInstance) {
      return;
    }
    
    if (this.chartRef?.nativeElement) {
      this.chartInstance = new Chart(this.chartRef.nativeElement, {
        type: 'line',
        data: {
          labels: [ 
            new Date(0).getTime(),
            new Date(1).getTime(),
            new Date(2).getTime(),
            new Date(3).getTime(),
            new Date(4).getTime(),
            new Date(5).getTime(),
          ],
          datasets: [{
            label: 'Tide',
            data: [
            ],
            backgroundColor: 'rgba(255, 99, 132, 0.2)',
            borderColor: 'rgba(255, 99, 132, 1)',
            borderWidth: 1,
            tension: 0.4,
          },
          {
            label: 'Water Levels',
            data: [],
            backgroundColor: 'rgba(135, 99, 255, 0.2)',
            borderColor: 'rgb(102, 99, 255)',
            borderWidth: 1,
            tension: 0.4,
          },
        ]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          spanGaps: true,
          scales: {
            x: {
              type: 'time',
              time: {
                tooltipFormat: 'DD HH:mm',
                unit: 'hour',
                displayFormats: {
                  hour: 'DD HH:mm'
                }
              },
              title: {
                display: false,
                text: 'Date'
              },
              grid: {
                display: true,

              }
            },
            y: {
              beginAtZero: true
            }
          },
        }
      });
    }
  }

  private updateChart() {
    if (!this.chartRef?.nativeElement || !this.chartInstance) return;
  
    let allTimes = [
      ...this.predictions.map(p => convertUTCToLocalTime(p.t)), 
      ...this.water_level_data.map(w => convertUTCToLocalTime(w.t))
    ];
    allTimes = [...new Set(allTimes)].sort(); // Unique & sorted times
  
    const tideMap = new Map(this.predictions.map(p => [
      convertUTCToLocalTime(p.t), parseFloat(p.v)
    ]));
  
    const waterLevelMap = new Map(this.water_level_data.map(w => [
      convertUTCToLocalTime(w.t), parseFloat(w.v)
    ]));
  
    const tideValues = allTimes.map(time => tideMap.get(time) ?? null);
    const waterLevelValues = allTimes.map(time => waterLevelMap.get(time) ?? null);
  
    this.chartInstance.data.labels = allTimes;
    this.chartInstance.data.datasets[0].data = tideValues;
    this.chartInstance.data.datasets[1].data = waterLevelValues;


    this.chartInstance.update();
  }
  

}
