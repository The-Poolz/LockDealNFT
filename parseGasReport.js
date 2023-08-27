const fs = require('fs');

function parseGasReport(filePath) {
  const data = fs.readFileSync(filePath, 'utf8');
  const lines = data.split('\n');

  // Initialize Markdown table headers
  let mdTable = '| Contract | Method | Min | Max | Avg | # calls | usd (avg) |\n';
  mdTable += '|----------|--------|-----|-----|-----|---------|-----------|\n';

  lines.forEach(line => {
    // Parse each line and append to Markdown table
    // This is a simplified example; you may need to adjust the parsing logic
    const parts = line.split('·').map(part => part.trim());
    if (parts.length === 7) {
      mdTable += `| ${parts[0]} | ${parts[1]} | ${parts[2]} | ${parts[3]} | ${parts[4]} | ${parts[5]} | ${parts[6]} |\n`;
    }
  });

  return mdTable;
}

const mdTable = parseGasReport('gas-report.txt');
fs.writeFileSync('md_gas_report.txt', mdTable);
