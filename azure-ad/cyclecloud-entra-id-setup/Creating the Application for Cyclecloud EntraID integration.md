# Creating the Application for Cyclecloud EntraID integration

## Steps

- [Download this python script](./python/Create-CycleCloud-EntraID-Integration-Application.py)

- Change directory to the location of the downloaded script

- Create a python virtual environment
```bash
python -m venv entraid

# for Bash shell
./entraid/bin/activate

# for Powershell
.\entraid\Scripts\activate

```

- Install the required packages
```bash
python -m pip install msgraph-sdk azure-identity
```

Optionally, modify the Application's display name on the script, line #92

- Run the script
```bash
python Create-CycleCloud-EntraID-Integration-Application.py
```

# add post creation steps here