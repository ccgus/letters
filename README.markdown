Letters
=======

**Letters-Dev:** http://lists.ranchero.com/listinfo.cgi/letters-dev-ranchero.com<br/>
**irc:** freenode.net ##lettersapp

What you'll find here isn't actually Letters.  It's a prototype named "CrashyEmailApp" which, as you might have guessed, is going to crash when you build and run it.

**What this build is for**

It's for a bit of experimentation, and to act as a starting point.  It currently allows you to send plain text email, check your imap inbox, and crashes.

**TODO**

  - Pretty much everything
  - Message caching
  - Keychain support
  - Support for multiple accounts
  - Responding to messages
  - A sane cache store
  - Management of the server connections
  - Activity Monitor (you wanted to cancel something?)
  - Plugin API
  - A UI that doesn't make designers faint
  - Address Book integration for Mail.app-like recipient entry
  - Etc.

**Contributing**

Check out the file "README-CONTRIB.markdown" for how to use github to get the code, make changes, and submit them for inclusion.

**System Requirements**

a) One Macintosh Personal Microcomputer with at least one 64 bit Intel processor, running Mac OS X 10.7 or later.

<br/><br/><br/><br/>

Letters Vision Statement
========================

Letters is a lean and programmable IMAP email client, with plugin and automation APIs, designed for developers and power users.

**Problems Letters will solve**

Existing email clients are inadequate for many developers and power users.

Mail.app is self-evidently designed for home users. Gmail integrates well with Google services but not with the Mac OS X desktop. Mutt offers speed and customization but lacks basic features like graphics. Pine offers ease-of-use (compared to mutt) but less customization. Thunderbird presents a not-quite-Mac-like UI and integrates less-than-ideally with the Mac OS X desktop. Mailsmith does POP only.

**Workflow**

Developers and power users have diverse workflow needs.

While Mail offers its own to-dos system, power users often use more powerful applications. Developers may have needs like processing crash logs and bug reports in different ways, sending to different systems, some web-based and some not. Power users are likely to use BusyCal or Google Calendar instead of, or along with, iCal.

To further list examples would be to list trival examples — but that's the point. The workflow needs are often too small or specific to create as a feature for a general-purpose email client, but those needs are very important to teams and individuals.

The best way to handle this is to give power users and developers an email client that can be *programmed*, so that their email client can be a component of their workflow rather than just a silo for messages.

Programmability means a few specific things:

1. A usable automation interface, complete enough to not throw roadblocks.

2. A well-designed plugin API that allows for additions and modifications to the application and triggered actions.

3. A documented data storage format, for applications and workflows that need access to the email but not the app’s GUI.

**User Interface**

Though it’s very tempting to want to innovate in the area of email filing and display, and this is not discouraged, this is not as important as programmability.

Nevertheless, some simple user interface issues could be attended to without much trouble. Examples:

- Developers and power users tend to be very comfortable with the keyboard — the same people who like utility apps like LaunchBar and QuickSilver would like more keyboard control over filing messages and navigating mailboxes than Mail.app, for instance, provides.

- Developers tend to like to reply in-line rather than via top-posting, but Mail.app’s text editor and quoting system make that difficult: this is a relatively easy and valuable feature to do better.

- Developers and power users subscribe to mailing lists, yet many email clients have no built-in concept of a mailing list.

The common and simpler needs of developers and power users should be handled first, while innovation happens in plugins.

**Short sentences to inject into the DNA**

Lean. Do less but do it better. Enable creativity and customization via plugins. 

Leverage other work, other code: do not subscribe to Not Invented Here syndrome. Let yaks prowl the grounds unshaven. Process is distraction.

Strong and opinionated leadership is essential. Design by committee ensures mediocrity — at best.

This is a Mac app, dammit.
