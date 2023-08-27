const fs = require('fs');

// Read the gas-report.txt file
fs.readFile('gas-report.txt', 'utf8', (err, data) => {
  if (err) {
    console.error('Error reading the file:', err);
    return;
  }

  // Split the file into lines
  const lines = data.split('\n');

  // Initialize empty arrays to hold the parsed lines for methods and deployments
  const parsedMethodLines = [];
  const parsedDeploymentLines = [];

  // Add the header to the Markdown tables
  parsedMethodLines.push('| Contract | Method | Min | Max | Avg | # calls | usd (avg) |');
  parsedMethodLines.push('|----------|--------|-----|-----|-----|---------|-----------|');

  parsedDeploymentLines.push('| Contract | Avg | % of limit | usd (avg) |');
  parsedDeploymentLines.push('|----------|-----|------------|-----------|');

  // Flag to indicate if we are in the Deployments section
  let inDeploymentsSection = false;

  // Loop through each line to parse it
  lines.forEach(line => {
    if (line.includes('Deployments')) {
      inDeploymentsSection = true;
    }

    if (!inDeploymentsSection) {
      const match = line.match(
        /(\w+)\s+·\s+(.+?)\s+·\s+(\d+|-)\s+·\s+(\d+|-)\s+·\s+(\d+|-)\s+·\s+(\d+|-)\s+·\s+(-|\d+)/,
      );
      if (match) {
        const [, contract, method, min, max, avg, calls, usd] = match;
        parsedMethodLines.push(`| ${contract} | ${method} | ${min} | ${max} | ${avg} | ${calls} | ${usd} |`);
      }
    } else {
      const match = line.match(/(\w+)\s+·\s+(\d+|-)\s+·\s+(\d+\.\d+ %|-)\s+·\s+(-|\d+)/);
      if (match) {
        const [, contract, avg, limit, usd] = match;
        parsedDeploymentLines.push(`| ${contract} | ${avg} | ${limit} | ${usd} |`);
      }
    }
  });

  // Combine the parsed content and write to md_gas_report.txt
  const combinedParsedLines = ['## Methods', ...parsedMethodLines, '## Deployments', ...parsedDeploymentLines];

  fs.writeFile('md_gas_report.txt', combinedParsedLines.join('\n'), err => {
    if (err) {
      console.error('Error writing the file:', err);
    }

    // Write the gas report to GitHub's Environment File to make it available for the next steps
    const envFilePath = process.env.GITHUB_ENV || '';
    if (envFilePath) {
      fs.appendFileSync(envFilePath, `GAS_REPORT=${combinedParsedLines.join('%0A')}\n`);
    }
  });
});
