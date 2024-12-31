# What is this
The goal of this repo is to offer an easier way to fetch an OTP when doing manual testing.

## Functionalities offered
- Fetch the most recent OTP (any loginID)
- Fetch the most recent OTP for a specific loginID

## How-to
The program is able to connect to the proper environments to fetch the required data and call the required APIs.

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

### Installation
Meant to be quick and simple to use from any workstation.

#### Prerequisistes
- pip
- A working kubectl setup pointing for your stack (for ondemand usage only)
### Step by step
1) Install pyinstaller `pip install pyinstaller`
2) Clone the project, `cd` to the root.
3) create the `credentials.json` in the project folder.
4) Run `pyinstaller --add-data "credentials.json:." --onedir gimme-otp.py`
5) Make the executable part of your $PATH by adding a symlink. 
    E.g. `sudo ln -s /Users/jhallee/code/poc/otp-me/dist/gimme-otp/gimme-otp /usr/local/bin`

### usage
The first time running the cmd after building the executable will take a few seconds more at boot.

`gimme-otp ondemand by-login --login-id 8748257`

or

`python gimme-otp ondemand recent`