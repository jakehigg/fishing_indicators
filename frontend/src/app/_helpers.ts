export function convertUTCToLocalTime(utcTime: string): string {
    // Convert "2025-03-01 12:42" to ISO format
    const utcDate = new Date(utcTime.replace(' ', 'T') + 'Z');
  
    // Format as "MM/DD/YY HH:MM" without timezone
    return utcDate.toLocaleString(undefined, {
    //   year: '2-digit',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      hour12: false, // Use 24-hour format, remove if you want AM/PM
    }).replace(',', ''); // Remove comma between date and time
  }
  

  export function convertUTCToLocalTimeShort(utcTime: string): string {
    // Convert "2025-03-01 12:42" to ISO format
    const utcDate = new Date(utcTime.replace(' ', 'T') + 'Z');
  
    // Format as "MM/DD/YY HH:MM" without timezone
    return utcDate.toLocaleString(undefined, {
    //   year: '2-digit',
      // month: '2-digit',
      //dayOfWeek: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      hour12: false, // Use 24-hour format, remove if you want AM/PM
    }).replace(',', ''); // Remove comma between date and time
  }
  