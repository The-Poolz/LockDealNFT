const fs = require('fs');

// Read the gas-report.txt file
fs.readFile('gas-report.txt', 'utf8', (err, data) => {
  if (err) {
    console.error('Error reading the file:', err);
    return;
  }

  // Split the file into lines
  const lines = data.split('\n');

  // Initialize an empty array to hold the parsed lines
  const parsedLines = [];

  // Add the header to the Markdown table
  parsedLines.push('| Contract | Method | Min | Max | Avg | # calls | usd (avg) |');
  parsedLines.push('|----------|--------|-----|-----|-----|---------|-----------|');

  // Loop through each line to parse it
  lines.forEach(line => {
    const match = line.match(/(\w+)\s+·\s+(.+?)\s+·\s+(\d+|-)\s+·\s+(\d+|-)\s+·\s+(\d+|-)\s+·\s+(\d+|-)\s+·\s+(-|\d+)/);
    if (match) {
      const [, contract, method, min, max, avg, calls, usd] = match;
      parsedLines.push(`| ${contract} | ${method} | ${min} | ${max} | ${avg} | ${calls} | ${usd} |`);
    }
  });

  // Write the parsed content to md_gas_report.txt
  fs.writeFile('md_gas_report.txt', parsedLines.join('\n'), err => {
    if (err) {
      console.error('Error writing the file:', err);
    }
  });
});
