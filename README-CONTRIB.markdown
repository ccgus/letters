Contributing and Collaborating with GitHub
==========================================

This write-up is a step-by-step and general description of how to work with the Letters projects on GitHub, including submitting patches to others for changes, fixes and updates.


Getting the Code
----------------

If you just want to get the code from the master branch and see what it's doing, you can directly clone the git repository:

	`git clone git://github.com/ccgus/letters.git`

If you want to work on the code, making changes and submitting them back to the project, take the time to set up a GitHub account and then make a fork of the project. 

* log in with your own account to [http://github.com/](http://github.com/)
* navigate to [http://github.com/ccgus/letters](http://github.com/ccgus/letters)
* at the top of the page, there's a button that says "Fork" - press that.
* navigate to your own fork of the letters repository
* clone your copy of the repository to your local machine. For example, mine reads:

	`git clone git@github.com:heckj/letters.git`

Making a branch to do some work
-------------------------------

First off - make a branch for each different change, bugfix, or idea that you have that you're working on. Keeping those elements separate makes it *much* easier for other folks to import your changes in a consistent fashion. Once you have the code on your local machine, making a branch and working with it is very straightforward:

* `git checkout -b task-1-work`
* ... do work and 'git commit' your changes...
* `git push origin task-1-work` # this pushes your changes up to GitHub
* `git checkout -b task-1` # make a new branch that will contain all the various work elements as a single change
* `git merge --squash --no-commit task-1-work` # merge in that work...
* `git commit -m "Fixed #134 - added a great new feature"`
* `git push origin task-1`

Now your changes are available on the branch "task-1" as a single update that should be super-easy for someone else to pull and try.

Requesting a pull
-----------------

To ask someone to incorporate your changes, you can make a "pull request" from GitHub. To do that:

* navigate to your repo on github (something like [http://github.com/heckj/letters](http://github.com/heckj/letters))
* Under the menu "branches", select the branch you just pushed up into place.
* At the top of the page, click on "Pull Request"
	* you can put in a message and select the folks to whom you'd like to send the update

(there are some additional details at [http://github.com/guides/pull-requests](http://github.com/guides/pull-requests))

Pulling down someone else's pull request
----------------------------------------

You can retrieve someone's changes from their repo on GitHub and try them out without having to commit those changes to your own repository. Here's the general process. Assume that the user 'mailmonkey' was submitting a patch to you...

* cd to your letters repository
* `git remote add mailmonkey git://github.com/mailmonkey/letters.git`
the remote will stay with your repository, so you only ever need to do this once for each person from whom you'd like to accept a change.
* `git fetch mailmonkey`

you can check out the code at this point, see if it works, you like it, etc... Finally, you can merge it into your own tree:

* `git checkout master`
* `git merge mailmonkey/branchname`

and when you're done, push it back up to GitHub:

* `git push`

Fixing your update or change (refused merge)
--------------------------------------------

If you need to go back and make some more tweaks or changes to your update, you can go back to the original branch and keep on editing:

* `git checkout -b task-1-work`
* ... fix and git commit often ...
* `git push`
* `git branch -D task-1`
* `git checkout -b task-1`
* `git merge --squash --no-commit task-1-work`
* `git commit -m "Fixed #1 — added a great new feature"`
* `git push`
