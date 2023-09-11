const fs = require('fs');

// Read the content of the file
fs.readFile('gas-report.txt', 'utf8', (err, data) => {
  if (err) {
    console.error('Error reading the file:', err);
    return;
  }

  // Add backticks to the start and end of the content
  const modifiedContent = '```' + data + '```';

  // Write the modified content back to the file
  fs.writeFile('gas-report.txt', modifiedContent, 'utf8', (err) => {
    if (err) {
      console.error('Error writing to the file:', err);
    } else {
      console.log('Backticks added to the start and end of the file.');
    }
  });
});