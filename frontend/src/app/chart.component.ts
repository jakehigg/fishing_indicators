import { Component, ViewChild, ElementRef, AfterViewInit } from '@angular/core';
import { Chart } from 'chart.js/auto';
import { MatCardModule } from '@angular/material/card';
import { HttpClientModule } from '@angular/common/http';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'chart-component',
  standalone: true,
  imports: [MatCardModule, HttpClientModule, CommonModule],
  templateUrl: './chart.component.html',
  styleUrls: ['./app.component.scss'],
})
export class ChartComponent implements AfterViewInit {
  @ViewChild('myChart') chartRef!: ElementRef<HTMLCanvasElement>;

  ngAfterViewInit() {
    if (!this.chartRef?.nativeElement) {
      console.error('Chart canvas not found');
      return;
    }

    new Chart(this.chartRef.nativeElement, {
      type: 'line',
      data: {
        labels: ['January', 'February', 'March', 'April', 'May', 'June', 'July'],
        datasets: [{
          label: 'My First dataset',
          data: [65, 59, 80, 81, 56, 55, 40],
          backgroundColor: 'rgba(255, 99, 132, 0.2)',
          borderColor: 'rgba(255, 99, 132, 1)',
          borderWidth: 1,
          tension: 0.4,
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          y: {
            beginAtZero: true
          }
        }
      }
    });
  }
}
