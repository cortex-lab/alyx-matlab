# alyx-matlab

For installation, go through exampleScript.m. 

This package contains code for interacting with the Alyx database through MATLAB. The primary functions are found within +alyx directory. Add the alyx-matlab directory to your MATLAB path, and then invoke the functions using alyx.<function>

## Primary functions and their descriptions
* alyx.loginWindow(). This function creates an Alyx login token via a login window popup.
* alyx.getData(). This function gets data from the alyx database, via a REST API endpoint.
* alyx.putData(). Similar to getData() but instead posts data to the database.
* alyx.registerFile2(). This function registers a file located on a fileserver (in this case, 'zserver') to the database. Requires specifying an alyx session, dataset type, file format (see documentation)
*

## Prerequisites
* https://github.com/psexton/missing-http/releases/tag/missing-http-1.0.0
* https://uk.mathworks.com/matlabcentral/fileexchange/33381-jsonlab--a-toolbox-to-encode-decode-json-files
* passwordUI.m (found in helpers folder) if using alyx.loginWindow()
