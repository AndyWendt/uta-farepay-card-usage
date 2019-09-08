# UTA Farepay Card Usage

![output](./docs/uta-usage.png)

## Installation

Need to make sure that the necessary requisites are installed: 

* https://github.com/vifreefly/kimuraframework#installation

## Credentials

Create a file, `~/.uta/secrets.yml`, that has the following contents: 

```yaml
username: uta-username
password: uta-password
```

## Running

To run while also seeing the browser execute: `HEADLESS=false ruby src/uta.rb`
