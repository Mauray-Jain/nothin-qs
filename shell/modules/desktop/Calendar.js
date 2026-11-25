.pragma library

// month returns 6 weeks of 7 days (Monday first) for month 0..11 of year;
// days outside the month are 0.
function month(year, m) {
    const first = (new Date(year, m, 1).getDay() + 6) % 7 // Monday = 0
    const days = new Date(year, m + 1, 0).getDate()
    const weeks = []
    for (let w = 0; w < 6; w++) {
        const week = []
        for (let d = 0; d < 7; d++) {
            const n = w * 7 + d - first + 1
            week.push(n >= 1 && n <= days ? n : 0)
        }
        weeks.push(week)
    }
    return weeks
}
