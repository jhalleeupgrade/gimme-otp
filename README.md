# What is this
The goal of this repo is to offer an easier way to fetch an OTP when doing manual testing.

## Functionality offered by each scripts
- Fetch the most recent OTP (any loginID)
- Fetch the most recent OTP for a specific loginID

## How-to
Each script is able to connect to the proper environments to fetch the required data and call the required APIs.

in the same directory as the script, a `credentials.json` file with following content is needed:

```
...
    "main": {
        "dbname": "main",
        "user": "readonly",
        "password": "Q7YCmEY2s8RQuG6k",
        "host": "main.cxhkcqtr9ke6.us-west-2.rds.amazonaws.com",
        "port": "5432",
        "decrypt_url": "https://api-private.kube.usw2.ondemand.upgrade.com/api/qa/v1/crypto/decrypt"
    },
    ...
```

*Note that for ondemand env, the scripts rely on a proper kubectl setup on the local workstation (already installed and configured to point to a specific stack)*

### gimme-otp.sh
Meant to be quick and simple and easier to use from any workstation.
Please make sure that `jq` is already installed (`brew install jq`)

`./gimme-me.sh ondemand by-login --login-id 8748257`
or
`./gimme-me.sh ondemand recent`

### gimme-otp.py
Meant to evolve better and be easier to maintain. The caveat is that installation is a bit more redious at the moment (need to install python, manage the proper dependencies, etc).

Once installation is done:

`python gimme-me.py ondemand by-login --login-id 8748257`
or
`python gimme-me.py ondemand recent`