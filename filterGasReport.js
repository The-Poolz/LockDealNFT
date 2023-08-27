const fs = require('fs');

// Read the existing report directly
const rawReport = fs.readFileSync('gasReporterOutput.json', 'utf-8');
const parsedReport = JSON.parse(rawReport);

let tableReadyData = {};

// Your filtering logic here
// For example:

tableReadyData.methods = parsedReport.methods.filter(method => method.numberOfCalls > 0 && method.gasData.length > 0);

tableReadyData.deployments = parsedReport.deployments.filter(
  deployment => deployment.gasData !== undefined && deployment.gasData.length > 0,
);

// Set this filtered data as an output variable for the next step
console.log(`::set-output name=filtered_report::${JSON.stringify(tableReadyData)}`);
