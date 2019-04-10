# deploy-freenas.sh

deploy-freenas.sh is a shell script to deploy TLS certificates to a FreeNAS server using the FreeNAS API.  This should ensure that the certificate data is properly stored in the configuration database, and that all appropriate services use this certificate.  It's intended to be called from a Let's Encrypt client like [acme.sh](https://github.com/Neilpang/acme.sh) after the certificate is issued, so that the entire process of issuance (or renewal) and deployment can be automated.

This project was remade from project deploy-freenas.py by danb35 due to the impossibility of using Python in the closed structure of the OPNsense system.

# Installation
This script can run on any machine running Bourne shell (all *nix systems, macOS; for Windows you need to install additional package, like [CygWin](https://www.cygwin.com/)) that has network access to your FreeNAS server, but in most cases it's best to run it directly on the FreeNAS box.  Change to a convenient directory and run `git clone https://github.com/Limych/deploy-freenas`

<p align="center">* * *</p>
I put a lot of work into making this repo available and updated to inspire and help others! I will be glad to receive thanks from you — it will give me new strength and add enthusiasm:
<p align="center"><a href="https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=UAGFL5L6M8RN2&item_name=[deploy-freenas]+Donation+for+a+big+barrel+of+coffee+:)&currency_code=EUR&source=url"><img alt="Buy Me a Coffe" src="https://raw.githubusercontent.com/Limych/HomeAssistantConfiguration/master/docs/images/donate-with-paypal.png"></a></p>

# Usage

There are now two ways to usage of this script:

## Usage as independent script

The relevant configuration takes place in the `deploy_config` file.  You can create this file either by copying `depoy_config.example` from this repository, or directly using your preferred text editor.  Its format is as follows:

```
[deploy]
password = YourReallySecureRootPassword
cert_fqdn = foo.bar.baz
connect_host = baz.bar.foo
verify = false
privkey_path = /some/other/path
fullchain_path = /some/other/other/path
protocol = https://
port = 443
```

Everything but the password is optional, and the defaults are documented in `depoy_config.example`.

Once you've prepared `deploy_config`, you can run `deploy_freenas.sh`.  The intended use is that it would be called by your ACME client after issuing a certificate.  With acme.sh, for example, you'd add `--deploy-hook "/path/to/deploy_freenas.sh"` to your command.

There is an optional parameter, `-c` or `--config`, that lets you specify the path to your configuration file. By default the script will try to use `deploy_config` in the script working directoy:

```
/path/to/deploy_freenas.sh --config /somewhere/else/deploy_config
```

## Usage as part of acme.sh

Install deployer to existing acme.sh installation by `install2acme.sh` script.

Then you can deploy certificates like with other [deploy hooks](https://github.com/Neilpang/acme.sh/wiki/deployhooks):
```bash
export FREENAS_PASSWORD="xxxxxxx"   # Required
export FREENAS_HOST="https://example.com:443"   # Optional. Default: "http://localhost:80"
acme.sh --deploy -d example.com --deploy-hook freenas
```
