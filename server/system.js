// We are using JavaScript to get system usage information through Node.js,
// as it's not possible directly in Lua.
const process = require('node:process')

const updateInterval = 5_000_000 // 5 seconds (in microseconds)

let currentCpuLoad = -1
let lastCpuUsage = process.cpuUsage()

setInterval(() => {
    const currentUsage = process.cpuUsage(lastCpuUsage)
    currentCpuLoad = (currentUsage.user + currentUsage.system) / updateInterval
    lastCpuUsage = currentUsage
}, updateInterval / 1000)

exports('systemUsage', () => {
    return {
        ram: process.memoryUsage.rss() / 1024 / 1024,
        cpu: currentCpuLoad.toFixed(2),
    }
})
