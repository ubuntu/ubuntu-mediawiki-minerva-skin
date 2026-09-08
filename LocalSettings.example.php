<?php
# See https://www.mediawiki.org/wiki/Manual:Configuration_settings

if (!defined('MEDIAWIKI')) {
    exit;
}

$wgSitename = "Ubuntu Wiki";
$wgServer = "http://localhost:" . (getenv('UBUNTU_MINERVA_PORT') ?: '8082');
$wgScriptPath = "";
$wgResourceBasePath = $wgScriptPath;
$wgLanguageCode = "en";
$wgLocaltimezone = "UTC";

$wgDBtype = "mysql";
$wgDBserver = "db";
$wgDBname = "mediawiki";
$wgDBuser = "mediawiki";
$wgDBpassword = "mediawiki";

$wgSecretKey = "change-me";
$wgUpgradeKey = "change-me";

$wgEnableUploads = false;
$wgUseInstantCommons = true;

wfLoadExtension('UbuntuWiki');
wfLoadSkin('UbuntuMinervaNeue');
$wgDefaultSkin = 'ubuntu-minerva';

$wgLogos = [
    '1x' => "$wgResourceBasePath/extensions/UbuntuWiki/resources/images/Tag-CoF-Orange-Digital.svg",
    'icon' => "$wgResourceBasePath/extensions/UbuntuWiki/resources/images/Tag-CoF-Orange-Digital.svg",
];

unset($wgFooterIcons['poweredby']);

$wgUbuntuCookieConsentEnabled = true;
$wgUbuntuGTMContainerID = '';

wfLoadExtension('ParserFunctions');
wfLoadExtension('SyntaxHighlight_GeSHi');
wfLoadExtension('TemplateData');

$wgShowExceptionDetails = true;
