---
layout: post
title:  "Running a blog with iPad"
date:   2021-01-01
show_in_homepage: false
draft: true
tags: [Blogging]
---

For some years now, I have this blog and I quite like writing my thoughts and sharing my experience. After a parenthesis on Medium, I decided that I want to be the owner of my content, so I started experimenting with different solutions and ideas. After founding the “perfect” tech architecture (I know, I’m lying. There isn’t the perfect solution and probably the future me will refactor and (over)re-engineer the current solution), I started to seek the “perfect” writing setup. And I think that I’ve found it, and in this article I want to share it.

## A bit about tech architecture

Before speaking about the setup, I want to spend some words about the tech stack. The site is built with [Hugo](https://gohugo.io/), one of the most popular static site generator. It is a powerful tool that let you have a website up and running in just a few minutes.
With Hugo, you can write articles or content with Markdown and then Markdown pages are automatically transformed into HTML and CSS pages when you build the website. But how Hugo works is not the topic of this article, so if you are interested to know a bit more, I suggest you to give a look to the [documentation](https://gohugo.io/documentation/).

As mentioned above, the final output of Hugo is a static website and there are many (also free) solutions to host a static website. For example [GitHub Pages](https://pages.github.com/) or [Netlify](https://www.netlify.com/) or [Firebase Hosting](https://firebase.google.com/docs/hosting). Personally, I’ve always used GitHub Pages and I’m still using it.

For handling the publications, I have setup a little GitHub action (you can give a look to it [on my GitHub](https://github.com/prof18/marcogomiero.com/blob/master/.github/workflows/gh-pages.yml)) that builds that website and push all the changes to a special branch reserved for GitHub Pages. And this action is triggered every time I push something on the master branch. 

And that’s it for tech stack. It was a quick but necessary overview to better introduce you in the context but if you have any kind of question, feel free to drop a comment below or tweet me [@marcoGomier](https://twitter.com/marcoGomier). 

## Writing Setup

My main machine is a 15” MacBook and it is fantastic for my day to day job. But after using it for writing some posts, I discovered that a 15” machine is way too heavy, big and overkill just for blogging. 

When I’m writing something, I like to stay outside in the courtyard, sitting in the deckchair or in the hammock or in a simple chair. And when the weather does not allow it, I prefer to stay in the couch or in bed rather than in my work setup. And in all of these scenarios, my MacBook is too uncomfortable to use. So I started to think about alternatives. 

First of all, I tried to resurrect my old Asus T100HA with a lightweight Linux distro, but at the end there was an issue with the sleep and the battery was not at his glory anymore. So, after some thinking, I realized that the machine that I was looking for, can be an **iPad**. Because for blogging I don’t need a big screen and power but I only need a reliable and comfortable machine, with a decent autonomy. 

After some research, I found out that the best compromise between my needs and my budget was the **iPad Air 3** (I made this choice back in May 2020. If it was today, I will choose the new iPad Air 4). And, for the keyboard, I decided to go with the [Logitech Combo Touch](https://www.logitech.com/en-us/products/ipad-keyboards/combo-touch.html).

{{< figure src="/img/blogging-ipad/ipad-overview.jpeg" link="/img/blogging-ipad/ipad-overview.jpeg">}}

To be honest, I quickly fell in love with the Logitech solution. With this keyboard-cover you will transform the iPad into a notebook. With the kickstand, you can tilt the iPad up to 40 degrees. Then you have a very good trackpad (better than some Window notebook!), a row of function keys (brightness and volume controls, home button, lock button, spotlight, etc) and backlit keys. 

{{< figure src="/img/blogging-ipad/keyboard-detail.jpeg" link="/img/blogging-ipad/keyboard-detail.jpeg" >}}

Then only compromise is the fact that it makes the iPad a bit heavier and thicker. 


### Applications

As I mentioned above, the website is stored in a git repository and I manage all ”the git lifecycle” through [Working Copy](https://apps.apple.com/it/app/working-copy-git-client/id896694807?l=en) that I think it is the best git client that you can find in the AppStore. 

{{< figure src="/img/blogging-ipad/working-copy-screen.png"  link="/img/blogging-ipad/working-copy-screen.png" caption=“Working Copy”>}}

With Working Copy you can browse the content of the repo but you can also make edits with a built in editor that has also syntax highlighting. But the feature that made me choose this client, is the support of the File iOs app, so the repositories can be seen from other apps as well. 

{{< figure src="/img/blogging-ipad/working-copy-files-app.png"  link="/img/blogging-ipad/working-copy-files-app.png" caption=“iOs File app” >}}

So in this way I can open and edit an article directly from my favorite Markdown editor that is (for the time being) [MWeb](https://apps.apple.com/it/app/mweb-powerful-markdown-app/id1183407767?l=en) (I know, it’s a weird name).

{{< figure src="/img/blogging-ipad/mweb-screen.png" link=“/img/blogging-ipad/mweb-screen.png” caption=“MWeb” >}}

I like it because it provides themes, a powerful preview, an useful toolbar with plenty of quick actions and lots of keyboard shortcuts. 

In the past I’ve used [Pretext](https://apps.apple.com/it/app/pretext/id1347707000?l=en) that is “more basilar”. In the future, I would like to try [iA Writer](https://apps.apple.com/it/app/ia-writer/id775737172?l=en) but it is quite expensive and I don’t know if it worths the investment (maybe if there is a demo or a trial version I can make a decision).  

And that’s it! I write an article in MWeb and when I finish it, I publish it to the master branch of the Github repo throught Working Client. Then, the GitHub Action is triggered and the article is live.

Bonus. If I have to edit or prepare an image for an article (like the ones below), I use [Pixelmator](https://apps.apple.com/it/app/pixelmator/id924695435?l=en), a very good image editor fo iOs. 

{{< figure src="/img/blogging-ipad/pixelmator-screen.png"  link="/img/blogging-ipad/pixelmator-screen.png" caption=“Pixelmator” >}}

### Automations

After writing some articles, I’ve discovered that there are some boring activities to achieve on iPad, like creating a new article, adding a new image for an article, etc. So, during one of the “its-blogging-time-but-i-dont-want-to-write” sessions (procrastination FTW) I decided to automate some of these boring things. 

#### Add an image to an article

To add an image on Hugo 


{{< figure src="/img/blogging-ipad/new-image-shortcut.png"  link="/img/blogging-ipad/new-image-shortcut.png" caption=“iOs shortcut to move an image from the camera roll to the repo of the site and generate the Hugo shortcode” >}}


{{< youtube MdSv-PwC5N8 >}}



#### Create a new article draft


{{< figure src="/img/blogging-ipad/new-article-draft-shortcut.png"  link="/img/blogging-ipad/new-article-draft-shortcut.png" caption=“iOs shortcut to create a new article draft with some metadata” >}}


{{< youtube v18imNIwgyc >}}




And that’s how I write in my blog. If you have any kind of suggestions about app, accessories, whatever, feel free to drop a comment below or tweet me [@marcoGomier](https://twitter.com/marcoGomier). 