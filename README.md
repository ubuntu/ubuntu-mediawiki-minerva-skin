# Ubuntu Wiki MinervaNeue skin

The UbuntuMinervaNeue skin is a fork of the MinervaNeue MediaWiki skin,
customized for the Ubuntu Wiki. It is registered as `ubuntu-minerva` and
requires the [UbuntuWiki extension](https://github.com/ubuntu/ubuntu-mediawiki-extension)
for shared Ubuntu resources.

## Installation

Add the skin and extension to `composer.local.json`:

```json
{
	"repositories": [
		{
			"type": "vcs",
			"url": "https://github.com/ubuntu/ubuntu-mediawiki-minerva-skin.git"
		},
		{
			"type": "vcs",
			"url": "https://github.com/ubuntu/ubuntu-mediawiki-extension.git"
		}
	],
	"require": {
		"ubuntu/mediawiki-ubuntu-minerva-skin": "*@dev",
		"ubuntu/mediawiki-ubuntu-extension": "*@dev"
	}
}
```

Then run `composer update` and load both packages in `LocalSettings.php`:

```php
wfLoadExtension( 'UbuntuWiki' );
wfLoadSkin( 'UbuntuMinervaNeue' );
$wgDefaultSkin = 'ubuntu-minerva';
```

The skin is licensed under GPL-2.0-or-later.

## Development

Install the PHP and npm dependencies, then run the checks from the repository
root:

```sh
composer install
npm install
composer test
npm test
```
