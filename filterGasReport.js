const fs = require('fs');

// Read and process the JSON file
fs.readFile('gasReporterOutput.json', 'utf8', (err, data) => {
  if (err) {
    console.error('Error reading the file:', err);
    return;
  }

  let dataObj;
  try {
    dataObj = JSON.parse(data);
  } catch (parseError) {
    console.error('Error parsing JSON:', parseError);
    return;
  }

  const methods = dataObj.info.methods;
  const contractGasInfo = [];

  for (const [methodKey, methodValue] of Object.entries(methods)) {
    const { contract, method, gasData, numberOfCalls } = methodValue;

    let averageGas = 0,
      minGas = Infinity,
      maxGas = 0;
    if (gasData.length > 0) {
      const totalGas = gasData.reduce((acc, curr) => {
        minGas = Math.min(minGas, curr);
        maxGas = Math.max(maxGas, curr);
        return acc + curr;
      }, 0);

      averageGas = totalGas / gasData.length;
    }

    const existingContract = contractGasInfo.find(info => info.contract === contract);

    if (existingContract) {
      existingContract.methods.push({ method, averageGas, minGas, maxGas, numberOfCalls });
    } else {
      contractGasInfo.push({
        contract,
        methods: [{ method, averageGas, minGas, maxGas, numberOfCalls }],
      });
    }
  }

  console.log(contractGasInfo);
});
