# ipa2itc

> dead simple iTunes Connect automated uploads

## Usage

### Best Case Scenario

```bash
$ ipa2itc -u user@server.com MyApp.ipa
```

In this scenario you already have your iTunes Connect password on your keychain.  OS X will ask you to give permission to `ipa2itc` to read it.

### Adding your iTunes Connect password to your keychain

If your iTunes Connect password is not in the keychain, or not in the right keychain (the iCloud keychain won’t work due to entitlements), you can add it with these steps:

1. Open the Keychain Access application from `/Applications/Utilities/Keychain Access.app`.
2. With the login keychain highlighted, click File->New Password Item from the menu.
3. Use the following settings for your password item:

**Keychain Item Name**: https://itunesconnect.apple.com<br />
**Account Name**: your iTunes Connect username<br />
**Password**: your iTunes Connect password

### Living Dangerously

If you for some reason can’t get your password into the keychain, or can’t get it into the right keychain in the case of continuous integration, you can always supply your password at the command line.  This is not recommended.

```bash
$ ipa2itc -u user@server.com -p yourpassword MyApp.ipa
```

## Installation

- Download the installer package.
- Run through the installer.
- Application binary will be installed to `/usr/local/bin/ipa2itc`.
- You may need to add `/usr/local/bin` to your path if it is not already present.

## How It Works

Like many other app uploader, `ipa2itc` relies on Apple’s `iTMSTransporter` binary buried in the Xcode package.  It finds the active version of Xcode using the `xcode-select` command line tool.  If it can’t find Xcode you may need to use `xcode-select` to choose the active version like this:

```bash
$ sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

`iTMSTransporter` needs a lot of information about your application before you can upload it.  `ipa2itc` finds all of this information for you by inspecting the `.ipa` package and looking information up directly on the iTunes Connect website.
