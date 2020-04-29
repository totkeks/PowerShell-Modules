# PowerShell Module Starter

This is a simple template for a PowerShell module, based on a couple of [blog](https://mikefrobbins.com/2013/07/04/how-to-create-powershell-script-modules-and-module-manifests/) [posts](http://ramblingcookiemonster.github.io/Building-A-PowerShell-Module/) I found on the internet.
The [official documentation](https://docs.microsoft.com/en-us/powershell/scripting/developer/module/writing-a-windows-powershell-module?view=powershell-7) is also very helpful.

## Creating your own module

* Fork or clone the repository
* Replace `StarterModule` with your own module name
* Find the `TODO:`s inside the files
  * RootModule name
  * Module GUID
  * Author name
  * Copyright statement in manifest (`.psd1`)
  * Copyright statement in `LICENSE` (if you want to publish it on GitHub and/or [PowerShell Gallery](https://www.powershellgallery.com))
* Add private and public functions
* Place module inside one of `$env:PSModulePath`
* Run `Import-Module <YourModule>`
* ???
* Profit
