const fs = require('fs');

function calculateGasStatistics(gasData) {
  const maxGas = Math.max(...gasData);
  const minGas = Math.min(...gasData);
  const avgGas = gasData.reduce((acc, val) => acc + val, 0) / gasData.length;
  return { maxGas, minGas, avgGas };
}

try {
  // Read the existing report directly
  const rawReport = fs.readFileSync('gasReporterOutput.json', 'utf-8');
  const parsedReport = JSON.parse(rawReport);

  // Check if parsedReport and info property exist
  if (!parsedReport || !parsedReport.info) {
    console.error("Error: Missing 'info' property in JSON report.");
    process.exit(1);
  }

  // Extract the 'info' object for easier reference
  const reportInfo = parsedReport.info;

  let tableReadyData = {
    methods: [],
    deployments: [],
  };

  // Filter and aggregate method data
  if (reportInfo.methods) {
    tableReadyData.methods = reportInfo.methods
      .filter(method => method.numberOfCalls > 0 && method.gasData && method.gasData.length > 0)
      .map(method => {
        const stats = calculateGasStatistics(method.gasData);
        return {
          methodName: method.methodName,
          numberOfCalls: method.numberOfCalls,
          ...stats,
        };
      });
  } else {
    console.warn("Warning: 'methods' property is missing or empty.");
  }

  // Filter and aggregate deployment data
  if (reportInfo.deployments) {
    tableReadyData.deployments = reportInfo.deployments
      .filter(deployment => deployment.gasData && deployment.gasData.length > 0)
      .map(deployment => {
        const stats = calculateGasStatistics(deployment.gasData);
        return {
          deploymentName: deployment.deploymentName,
          ...stats,
        };
      });
  } else {
    console.warn("Warning: 'deployments' property is missing or empty.");
  }

  // Set this filtered data as an output variable for the next step
  console.log(`::set-output name=filtered_report::${JSON.stringify(tableReadyData)}`);

  // Save the filtered report to a new JSON file for local testing
  fs.writeFileSync('filteredGasReportOutput.json', JSON.stringify(tableReadyData, null, 2));

  console.log('Successfully filtered and aggregated the gas report.');
} catch (error) {
  console.error(`Error occurred: ${error}`);
  process.exit(1);
}
