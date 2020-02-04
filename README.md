# Alyx-MATLAB
![Custom badge](https://img.shields.io/endpoint.svg?url=https%3A%2F%2Fsilent-zebra-36.tunnel.datahub.at%2Fcoverage%2Falyx-matlab%2Fdev)
![Custom badge](https://img.shields.io/endpoint.svg?url=https%3A%2F%2Fsilent-zebra-36.tunnel.datahub.at%2Fstatus%2Falyx-matlab%2Fdev)

This repository contains a MATLAB class called Alyx, that facilitates RESTful POST and GET requests to an instance of the [Alyx database](http://alyx.readthedocs.io/en/latest/). 

## Getting started

Extensive instructions for using this package can be found in `docs/AlyxMatlabPrimer.m`.  See "deployment" for notes on how to deploy the project on a live system.

### Prerequisites
Alyx-MALTAB requires MATLAB 2016a or later.  The code and instructions for installing the actual database can be found on the [cortex-lab/Alyx](https://github.com/cortex-lab/Alyx) repository.

MATLAB's built-in functions urlread and urlwrite are not particularly informative when the server returns an error.  For debugging purposes, consider installing the latest release of the [missing-http toolbox](https://github.com/psexton/missing-http/releases) and using the http.jsonGet and http.jsonPost functions instead, as they return a status code ans the server's full response.

### Installing
To install the package simply clone the master branch on your computer, then in MATLAB add the main folder to the paths, along with the helpers subfolder:
```
cd alyx-matlab
savepath(pwd, fullfile(pwd, helpers));
```

To customise the database URL create a file called `+dat\paths.m`.  This file should a function with that returns a structure with a field called `databaseURL`.  The value of this field will be the default when a new Alyx object is instantiated.  A template of this paths file can be found [here](https://github.com/cortex-lab/Rigbox/blob/master/docs/setup/paths_template.m).

Once the paths are added you can read the help pages:
```
doc Alyx
```

Also, open the Alyx.m class definition file and change the BaseURL property to the URL of your Alyx database instance:
```
  properties
    % URL to the Alyx database
    BaseURL char = 'https://alyx.cortexlab.net'
    [...]
```

### Running tests

#### Logging in/out
To instantiate an instance of Alyx, call the constructor like so:
```
ai = Alyx;
```

When called with no arguments, a login window is automatically displayed.
To instantiate the object without immediately logging in, call it with
the first two arguments empty.  NB: The inputs are the Username and
Token.
```
ai = Alyx('','');
```

To log in use the login method.  Upon success, this sets the Token
property with a token from Alyx.  To determine whether you're logged in,
use the IsLoggedIn property. After logging in the object automatically
flushes any posts in the queue (more later). NB: Alyx is not a handle
class, so make sure you assign the output to itself.
```
ai.IsLoggedIn % false
ai = ai.login;

ai.IsLoggedIn % true
ai = ai.logout;

ai.IsLoggedIn % false
```

#### Using endpoints to GET data
You can use the getData method to retrieve data directly from the
specified endpoint.  For instance to retrieve session data:
```
sessions = ai.getData('sessions'); % NB: Don't run this line, it will be very slow!
```

The data are return as a struct.  The second output argument is the
server status code.  For a full list of status codes and their meanings:
```
doc matlab.net.http.StatusCode
```

To use any URL queries, just add them the endpoint string in the standard
URL format:
```
sessions = ai.getData('sessions?type=Base&subject=test');
```

For more info:
```
doc webread
```

The query options are set on the server side.  You can find which options
are availible for each endpoint by vising the endpoint URL, but be warned
it is slow to load as you are running a GET within the browser.  NB: Not
all endpoints have a GET options, again see the DJANGO API page
e.g.
```
HTTP 200 OK % HTTP version
Allow: GET, PUT, PATCH, DELETE, HEAD, OPTIONS % Methods allowed
Content-Type: application/json % Post using Alyx.jsonPost
Vary: Accept
```

#### Posting data
POST requests (those that create new records on Alyx) can be made with
the postData method.  Upon success postData returns the created record.

Let's create a new session:
```
d = struct;
d.subject = 'test';
d.procedures = {'Behavior training/tasks'};
d.narrative = 'test session';
d.start_time = ai.datestr(now); % date in Alyx format
d.type = 'Base';
d.parent_session = ai.SessionURL;
d.number = 1;

[subsession, statusCode] = ai.postData('sessions', d)
```

The postData method uses the jsonPost method, which in turn uses the
built in MATLAB function webwrite.  More info:
```
doc Alyx.jsonPost
doc webwrite
```

#### Debugging with http.jsonPost
Unfortunately, the MATLAB built in http interface functions are limited
in terms of debugging, as they don't directly return the server's
responses upon failure.  Status codes must be extracted from the error
message bodies, and the full reponse of the server is usually not
returned.  In order to debug your Alyx posts, you can use the missing
http package's jsonPost function instead.  See line 47 of
Alyx.flushQueue:
```
opentoline(which('flushQueue'),47,1)
```

#### MySQL queries
One can also interact with Alyx through connection to the underlying
MySQL database.  This currently isn't really supported by the alyx-matlab
package and isn't encouraged.  More information:
```
open openAlyxSQL.m
doc alyx.expFilePath
```

Further details can be found in the accompanying [Examples script](https://github.com/cortex-lab/alyx-matlab/blob/alyx-as-class/Examples.m).

## Deployment
For use with [Rigbox](https://github.com/cortex-lab/Rigbox), use the submodule that comes with the Rigbox repository and follow the documentation there.

## Built With
* [dirPlus](https://uk.mathworks.com/matlabcentral/fileexchange/60716-dirplus) - Used for registering files
* [MD5 in MATLAB](https://uk.mathworks.com/matlabcentral/fileexchange/7919-md5-in-matlab) - For checksums (no longer used)

## Authors
This code is maintained and developed by a number of people at [CortexLab](https://www.ucl.ac.uk/cortexlab).  See [contributors](https://github.com/cortex-lab/alyx-matlab/graphs/contributors) list for more info.
