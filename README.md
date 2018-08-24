# CMPS290S, Fall 2018: Languages and Abstractions for Distributed Programming

_This page is a draft and subject to change._

Welcome to CMPS290S, fall 2018 edition!  This is a 5-unit graduate seminar course; the "S" stands for "systems".

Here's an "official" course description:

> This graduate seminar course explores the theory and practice of distributed programming from a programming languages perspective.  We will focus on programming models, language-level abstractions, and verification techniques that attempt to tame the many complexities of distributed systems: inevitable failures of the underlying hardware or network; communication latency resulting from the distance between nodes; the challenge of scaling to handle ever-larger amounts of work; and more.  Most of the work in the course will consist of reading classic and recent papers from the academic literature, writing short responses to the readings, and discussing them in class.  Furthermore, every participant in the class will contribute to a public group blog where we will share what we learn with a broader audience.

There's more than one reasonable way to approach a seminar course on languages and abstractions for distributed programming.  We could spend all our time on process calculi and only make a small dent in the literature.  Or we could spend all our time on large-scale distributed data processing and only make a small dent in the literature.  In this course, we will be focusing a lot of attention on [consistency models](https://en.wikipedia.org/wiki/Consistency_model) and language-based approaches to specifying, implementing, and verifying them.  Of course, we will only make a small dent in the literature.

## Prerequisites

Familiarity with (or willingness to learn) some basic PL concepts as applied to distributed systems.  An undergraduate programming languages course (or equivalent self-study) should suffice.

## Class meetings

  - MoWeFr 1:20-2:25pm, Porter Acad 241 (a [12m30s walk](https://taps.ucsc.edu/pdf/walking-map.pdf) from Science Hill)

We won't have a final exam.  I haven't decided what to do with our final exam time slot (8-11am on Wednesday, December 12) yet; perhaps it will be some kind of group social event to celebrate us all having survived the quarter.

## Grading

  - [Responses to readings](#readings-and-responses): 25%
  - Participation in discussion (online and in class): 20%
  - In-class [presentations](#presentations): 20%
  - [Class blog](#class-blog) posts: 35%
  
## Office hours

  - Wednesdays and Fridays, 11am-noon, Engineering 2 349B, or by appointment ([email me](mailto:lkuper@ucsc.edu))

## Readings and responses

One goal of this class is to equip you to conduct research on languages and abstractions for distributed programming by absorbing a lot of papers on the topic.  The [readings page](readings.md) has a list of possible readings.  Each participant in the class will write [responses](responses.md) to each reading.

_Free pass policy_: Because life throws unexpected challenges at each of us, you get four "free passes" to use during the quarter.  Using a free pass exempts you from having to submit a response for one reading.

## Presentations

Each participant in the class will present two or three readings (depending on how many people take the class) during the course of the quarter.  As a rough guideline, you should expect to do one or two presentations in October and one or two in November.  (You don't have to submit a response for readings that you're presenting.)

You'll have the opportunity to sign up to present particular readings.  (If you don't pick, I'll pick for you.)  More information and logistical details about presentations will be forthcoming.

## Class blog

As a grad student, I always dreaded having to do course projects.  In an ideal world, these projects were supposed to dovetail nicely with one's "real" research, or they were supposed to morph into "real" research within three months by some mysterious alchemical process involving lots of luck and suffering.  In practice, they usually ended up taking time away from real research, and they always ended up being hastily implemented and shoddily written up.

So, let's try something different.  Instead of a traditional course "project", **each participant in the class will write (and illustrate!) two posts for a public group blog aimed at a general technical audience.**  The goal is to create an artifact that will outlive the class and be valuable to the broader community.  Here's a non-exhaustive list of possibilities for blog posts:

  - *The research investigation*: Dig into one of the research questions that you identified while writing your [responses](responses.md) to the readings.  Carry out one concrete step toward answering that question that you identified in your response (which might involve writing code, taking measurements, writing proofs, and/or something else), and write about what you learned.  (Negative or inconclusive results are fine.)
  - *The literature survey*: Choose several (at least three, but no more than six or so) related readings that have something to do with the topic of the course, read them, and write a post surveying and analyzing them.  At most one of your selected readings should be one we're already covering in class.  The idea is to use something we read in class as a jumping-off point to go off on your own, explore the literature on a specific topic, and come back with new insights.  Good sources for papers include the related work sections of things we read for class, or the [further reading section of the readings page](readings.md#further-reading).
  - *The experience report*: Try out one or more of the systems discussed in the course readings, and report on your experience.  For this kind of post, you should expect to write code.  Aim higher than just "I got it to compile and run" -- ideally, you'll use the system to accomplish something, and report on what worked and what didn't.  In many cases, it will be appropriate to try to reproduce performance results from the reading.
  - *Run someone's research*: Choose a "lightweight language mechanization" tool, such as PLT Redex or K, and use it to mechanize and test a language or system model from one of the readings you did.  Report on what you learned from this process.  (There's a [good chance](https://eecs.northwestern.edu/~robby/lightweight-metatheory/popl2012-kcdeffmrtf.pdf) you'll find bugs or infelicities in the on-paper semantics.)

Will this be less work than a traditional course project?  No.  A blog post requires substantial work (reading, writing, editing, programming, debugging, thinking) -- expect each post to take about 30 hours of focused work, and scope the work appropriately.  Your two posts should be spaced out over the fall quarter: as a rough guideline, you should aim to finish one post during October and one during November.

You may want to do one 60-hour post instead of two 30-hour ones.  In that case, you should break it up into two chunks and publish them as "part one" and "part two".  You might not know something is a 60-hour project until you're in the middle of it, so play it by ear: if you put in 30 hours of focused work during October and you're still nowhere near done, then find a reasonable stopping point, call what you've done so far "part one", and then do "part two" in November.

Blog posts aimed at a general technical audience call for a different writing style than academic papers do, but that doesn't mean we won't hold them to a high standard of quality.  (If anything, we should be _more_ concerned about writing well.  Making the blog a pleasure to read will be a top priority.)  Therefore, in addition to writing your own posts for the blog, you will also serve as an _editor_ for two posts (other than your own).  The role of the editor is to help the writer do their best work -- by reading drafts, asking clarifying questions, spotting mistakes and rough spots, and giving constructive feedback.  Expect to spend at least ten hours on editing (at least five hours for each post on which you serve as editor).  We'll pair up editors with writers as the quarter proceeds, and when you're on the receiving end of feedback, you'll be expected to incorporate the editor's feedback and get a "go for launch" from them before the post can be published.  I'll contribute editing effort to each post as well, because I care and I want the blog to be awesome.

Each post will credit its author (and editor), and you're also welcome to cross-post your individual posts to your own blog if you have one.

You'll write your blog posts in Markdown format (with LaTeX support via MathJax if needed), and the blog will live in a GitHub repo and will be hosted on GitHub Pages.  More logistical details forthcoming.

## Academic honesty

This is a graduate seminar; you're expected and encouraged to discuss your work with others.  That said, everything you write for the class (paper summaries, blog posts, presentation slides, etc.)  must be your own original work.

Properly attribute any work that you use.  (More details forthcoming.)

## Similar courses

[Heather Miller's fall 2016 course at Northeastern on programming models for distributed computing](http://heather.miller.am/teaching/cs7680/) was structured similarly to this one and has some overlap in material.  There's also some overlap with the "programming models" part of [Peter Alvaro's winter 2016 edition of 290S](https://github.com/palvaro/CMPS290S-Winter16).
