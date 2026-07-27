---
layout: post
title: "Code review comments are the rules you forgot to write down"
description: "How to automatically keep AGENTS.md and AI instructions in shape, using PR review history"
date: 2026-07-27
show_in_homepage: true
---

If you work with AI agents, you have an instruction file (and if you don't, you should!) usually called `AGENTS.md` (with `CLAUDE.md` symlinked to it, because standards are hard to follow). 
This Markdown file is automatically added to the AI context, and it should contain all the guidelines for the project and everything that the agent should be aware of. For example, how to build the project, styling, conventions, and anything else that should be known to achieve the best possible result.

Like every piece of documentation, this file requires maintenance because projects evolve and you might *discover* new things while working on them over time. And when documentation requires maintenance, laziness always kicks in. 

The great news is that AI can also be used to automate this process, and with this article I want to share a workflow I use to keep instructions updated using comments from previous Pull Requests.

## Pull Request reviews are documentation

Pull Requests (PR in the rest of the article) are the perfect place where violations of the project's conventions, style, and way of working get raised. Every correction made by the reviewer becomes evidence of a gap: an unwritten rule the project follows, invisible to a machine (or a new teammate).

An agent can be prompted to check all the recent PRs, read all the comments, and find all the corrections that have been made because something didn't follow the project's conventions. For each of these corrections, the agent can then check if the project rules could have prevented that. If not, it can propose an addition to the rules to make sure this won't happen in the future.

The prompt is pretty straightforward; here's what I used, for reference:

> can you thorught all the recent prs, let's say for the past months and check every review comment and see if the review comments was because something was done in a way that's now common and don't follow the rule of the porject. if so, check if this could have been caught by the project rules. if not, tell me why and what and propose some changes that we can do in the project rules so you can get that easily

(Yes, the prompt has grammar mistakes and isn't polished, clean English. The model gets the intent; re-reading for grammar and for making the prompt look like an "Oxford essay" is wasted time. **Don't polish prompts!**)

The agent will probably start writing some throwaway code (Python in my case) to fetch the PRs' comments in batches and analyze them. After a bit, an updated `AGENTS.md` file will be ready to review.

## Automate everything

With this little trick, you can have self-evolving instructions that will make AI agents keep respecting your preferred conventions. 

At this point, after running this operation the first time, you can ask the AI agent to create a [skill](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview) so the next time, prompting is not required. And this entire task can be automated to run (even in the cloud) weekly, monthly, or at whatever cadence suits the project's velocity. 

This way, the work done by AI is reviewed and commented on, and the comments fed back into the instructions to make AI work better next time.

Use AI to improve AI!