---
title: "Course overview"
layout: single
classes: wide
---

## What's this?

This is a first-day-of-class overview of the fall 2018 edition of CMPS290S ("Languages and Abstractions for Distributed Programming"), a graduate seminar course in the Computer Science and Engineering Department at the UC Santa Cruz Baskin School of Engineering.

## Instructor

Hi, I'm [Lindsey Kuper](https://users.soe.ucsc.edu/~lkuper/)!

  - Email: <lkuper@ucsc.edu>
  - Office location: Engineering 2, Room 349B
  - Office hours: Wednesdays and Fridays, 11am-noon, or by appointment ([email me](mailto:lkuper@ucsc.edu))
  - Research areas: Programming languages, distributed systems, parallelism, concurrency, verification

## A few essential details about the course

  - 5-unit graduate seminar course (i.e., a course where we read, present, and discuss research papers)
  - The "S" in the course number stands for "systems", but don't read too much into it (roughly half the papers we read will be from programming-languages venues)
  - Class meets Mondays, Wednesdays, and Fridays, 1:20-2:25pm, Porter Acad 241 (in the Porter "D-Building", a [12m30s walk](https://taps.ucsc.edu/pdf/walking-map.pdf) from Science Hill)
  - No final exam, although you should save the time slot (8-11am on Wednesday, December 12) for a social event
  - Course web page: <https://decomposition.al/CMPS290S-2018-09/>
  - Course GitHub repo: <https://github.com/lkuper/CMPS290S-2018-09/>
  - This document: <https://decomposition.al/CMPS290S-2018-09/course-overview.html>

## What's this course about?

Theory and practice of distributed programming from a programming-languages perspective.

Topics we'll spend significant time on:

  - The CAP trade-off
  - Consistency models
  - Replicated data types
  - Combining consistencies
  - Languages and frameworks for distribution
  - Abstractions for configuration management

The [readings page](https://decomposition.al/CMPS290S-2018-09/readings.html) has the current schedule of readings.

### "Official" course description

> This graduate seminar course explores the theory and practice of distributed programming from a programming-languages perspective.  We will focus on programming models, language-level abstractions, and verification techniques that attempt to tame the many complexities of distributed systems: inevitable failures of the underlying hardware or network; communication latency resulting from the distance between nodes; the challenge of scaling to handle ever-larger amounts of work; and more.  Most of the work in the course will consist of reading classic and recent papers from the academic literature, writing short responses to the readings, and discussing them in class.  Furthermore, every participant in the course will contribute to a public group blog where we will share what we learn with a broader audience.

There's more than one reasonable way to approach such a course.  We could spend all our time on process calculi and only make a small dent in the literature.  Or we could spend all our time on large-scale distributed data processing and only make a small dent in the literature.

In this course, we will be focusing a lot of attention on [consistency models](https://en.wikipedia.org/wiki/Consistency_model) and language-based approaches to specifying, implementing, and verifying them.  Of course, we will only make a small dent in the literature.

### In this course, you will:

  - Become more comfortable with reading research papers, perhaps especially PL papers.
  - Get a sense of how PL research and (distributed) systems research intersect.
  - Identify some interesting research questions that fall in that intersection that you want to investigate, and start taking steps toward answering those questions.
  - Hone your technical writing and presenting skills, both for a specialist (i.e., each other) and non-specialist (i.e., blog reader) audience.

## Background you'll need

We'll be reading a lot of papers that formally define mathematical models of computer systems, state properties about those models, and then prove those properties.

About half the papers we read will be what I'd classify as "PL papers".  Although the ideas often aren't too complicated, there's a high notational overhead in many PL papers, and there are a few standard concepts you'll want to be familiar with.

_At a minimum_, you should be familiar with the concepts in Jeremy Siek's ["Crash Course on Notation in Programming Language Theory"](http://siek.blogspot.com/2012/07/crash-course-on-notation-in-programming.html).  Take some time to read it next week and brush up on anything you're not familiar with already.

If you're not familiar with operational semantics of programming languages (or maybe even if you are!), watch [David Van Horn's excellent 45-minute tutorial video](https://www.youtube.com/watch?v=TU16mA5-i-g).

Ask questions early when you come across notation you don't understand.  If you're confused, you're probably not the only one!

## Reading and responding to papers

One goal of this course is to equip you to conduct research on languages and abstractions for distributed programming by absorbing a lot of papers on the topic.

One of the best ways to absorb reading material is to write about what you read.  So, each student in the course will write a short response to each reading.

### What goes in a response?

Responses should be in the ballpark of 500 words, which is about the minimum length that, say, a PLDI review should be.

But we'll be reading stuff that has (with a few possible exceptions) already been thoroughly peer-reviewed.  Your goal here is **not** to assess the quality of the papers.

Rather, your goal is to construct a rich mental map of existing work, which you will sooner or later be able to use as a foundation for your own research.

### How to structure your response

You can structure your response around the following questions:

  1. What's this paper about?  (Summarize the paper and its contributions in your own words.)
  2. What's one thing I learned?
  3. What's something I didn't understand?
  4. What's a research-level question I have after having read this paper?
  5. What's a concrete step I can take toward answering the research question?

A "research-level" question is something deeper than "What did the Greek letters on page 4 mean?" or "What's the baseline in Figure 6?"

It might be something like, "The problem this paper addresses reminds me of the X problem, which is similar in ways A and B, but different in way C.  Could this paper's approach, or something like it, be used to tackle X?"

### Further advice on how to read papers

Reading research papers is a skill that requires practice.  Attempting to plow right through from beginning to end is often not the most productive approach.  Here's some great [advice from Manuel Blum on how to read and study](http://www.cs.cmu.edu/~mblum/research/pdf/grad.html):

> Books are not scrolls.  
> Scrolls must be read like the Torah from one end to the other.  
> Books are random access -- a great innovation over scrolls.  
> Make use of this innovation! Do NOT feel obliged to read a book from beginning to end.  
> Permit yourself to open a book and start reading from anywhere.  
> In the case of mathematics or physics or anything especially hard, try to find something  
> anything that you can understand.  
> Read what you can.  
> Write in the margins. (You know how useful that can be.)  
> Next time you come back to that book, you'll be able to read more.  
> You can gradually learn extraordinarily hard things this way.

You may also be interested in time-tested paper-reading advice [from Michael Mitzenmacher](https://www.eecs.harvard.edu/~michaelm/postscripts/ReadPaper.pdf) and [from S. Keshav](http://blizzard.cs.uwaterloo.ca/keshav/home/Papers/data/07/paper-reading.pdf).

### Response logistics

Responses for each reading are due **by 11am on the day we discuss that reading in class** (see the [readings page](readings.md) for a schedule).  Late responses will not be accepted.

Responses should be written in Markdown format, with the filename `XXXX-response-YYYY-MM-DD.md`, and pushed to [the `responses` directory of the course GitHub repo](https://github.com/lkuper/CMPS290S-2018-09/tree/master/responses), where `XXXX` is a randomly generated unique ID number that I will provide to each of you today.  For example, if your ID number is 3954 and you're submitting a response to the reading assignment for October 19, that response will go in a file called `3954-response-2018-10-19.md`.

You do not have to submit a response for readings that you're presenting (more about presentations in a minute).

**Your first response is due Monday, so if you need help with GitHub or have questions about how this works, let me know ASAP!**

_Free pass policy_: Because life throws unexpected challenges at each of us, you get four "free passes" to use during the quarter.  Using a free pass exempts you from having to submit a response for one reading.  If you want to use one of your free passes, email me before the response is due.

## Presentations

Each student will present two or three readings in class (the number could vary depending on how many students take the course and how many guest speakers we end up getting).  As a rough guideline, expect to do one or two presentations in October and one or two in November.

Presentations should be about 35 minutes long, leaving about 25 minutes for discussion, which the presenter will lead.  If you're the presenter, it's a good idea to have some suggested discussion questions to kick things off.  (You do not need to have the answers!)

The presentation format is up to you, but I suggest using slides unless you're confident of your blackboard skills.  **You must email me a draft of your slides (or detailed notes, if not using slides) at least 24 hours before your presentation.**

These presentations do not need to be highly polished performances, like conference talks do.  Nevertheless, **take them seriously**.  Don't show up with sloppy or incomplete slides or notes, and practice your presentation.

**You must turn in a final copy of your slides or notes by EOD on the day you present**, either by emailing to me (if you'd prefer not to make your materials public), or by uploading to [the `presentations` directory in our course repo](https://github.com/lkuper/CMPS290S-2018-09/tree/master/presentations).

### Choosing topics to present

By next Monday, if you haven't done so yet, you should email me with a list of three to five [readings](https://decomposition.al/CMPS290S-2018-09/readings.html) you'd like to present.  I'll do my best to assign everyone the readings they want to present.

If you have trouble coming up with three to five readings you want to present, pick from the ["further reading" section](https://decomposition.al/CMPS290S-2018-09/readings.html#further-reading) instead; if there's enough interest in those, then we can promote them to the regular schedule.

### Advice on giving good talks

You're here to do research, and as Simon Peyton Jones says, "Research is communication."  Check out [his excellent advice](https://www.microsoft.com/en-us/research/academic-program/give-great-research-talk/) on how to give a great research talk; much of it is relevant for in-class presentations.

Michael Ernst has [lots of good advice](https://homes.cs.washington.edu/~mernst/advice/giving-talk.html), too, including some specifically on giving in-class presentations.

My most high-leverage tips:

  - Do the reading well in advance, and soak in it for a while.  **Give yourself time to be confused.**
  - Don't present everything that's in the paper.  Figure out what the big ideas are that you want to convey.  What did you find the most interesting and important?  What would you tell a good friend who asked you what the paper is about?

## Course blog

During the quarter, **each student in the course will write (and illustrate!) two posts** for the course blog, which will be a public group blog aimed at a general technical audience.

The goal is to create an artifact that will outlive the course and be valuable to the broader community.

You have lots of options for what to write about!

### Blog post idea: The research investigation

Dig into one of the research questions that you identify while writing your responses to the readings.

Carry out one of the concrete steps toward answering it (which might involve writing code, measuring performance, writing proofs, and/or something else), and write about what you learn.

Negative or inconclusive results are fine!

### Blog post idea: The literature survey

Choose several (at least three, but no more than six or so) related readings that have something to do with the topic of the course, read them, and write a post surveying and analyzing them.

At most one of your selected readings should be one we're already covering in class.  The idea is to use something we read in class as a jumping-off point to go off on your own, explore the literature on a specific topic, and come back with new insights.

Good sources of papers for a literature survey include the related work sections of things we read for class, or the ["further reading" section of the readings page](https://decomposition.al/CMPS290S-2018-09/readings.html#further-reading).

### Blog post idea: The experience report

Try out one or more of the systems discussed in the readings, and report on your experience.

For this kind of post, you should expect to write code.  Aim higher than just "I got it to compile and run" -- ideally, you'll use the system to accomplish something, and report on what worked and what didn't.

In many cases, it will be appropriate to try to reproduce performance results from the reading.

### Blog post idea: Run someone's research

Choose a "lightweight language mechanization" tool, such as [PLT Redex](https://redex.racket-lang.org/) or [the K framework](http://www.kframework.org/index.php/Main_Page), and use it to mechanize and test a language or system model from one of the readings you did.  Report on what you learn from this process.

There's a [good chance](https://eecs.northwestern.edu/~robby/lightweight-metatheory/popl2012-kcdeffmrtf.pdf) you'll find bugs or infelicities in the on-paper semantics!

### Blog post time frame

A blog post requires substantial work (reading, writing, editing, programming, debugging, thinking).  Expect each post to take about **30 hours** of focused work, and scope the work appropriately.

Warning: 30 hours isn't actually that much time -- don't aim too high!

Most of you will want to be working on one post during October and the other one during November.  More specifically, aim to work within the following time frame:

  - Monday, 10/29: Finished draft of first post; soliciting editor/instructor feedback
  - Monday, 11/12: Hard deadline to have first post published
  - Wednesday, 11/28: Finished draft of second post; soliciting editor/instructor feedback
  - Wednesday, 12/12: Hard deadline to have second post published

Note: You may want to do one 60-hour post instead of two 30-hour ones.  In that case, break it up into two chunks and publish them as "part one" and "part two".  You might not know something is a 60-hour project until you're in the middle of it, so play it by ear: if you put in 30 hours of focused work during October and you're still nowhere near "done", then find a reasonable checkpoint, call what you've done so far "part one", and then do the second part in November.

### Blog editing

Blog posts aimed at a general technical audience call for a different writing style than academic papers do, but that doesn't mean we won't hold them to a high standard of quality.

If anything, we should be _more_ concerned about writing well -- making the blog a pleasure to read will be a top priority!

In addition to writing your own posts for the blog, you will also serve as an _editor_ for two posts (other than your own).  The role of the editor is to help the writer do their best work -- by reading drafts, asking clarifying questions, spotting mistakes and rough spots, and giving constructive feedback.

Expect to spend at least **ten hours** on editing (at least five hours for each post on which you serve as editor).  When you're on the receiving end of feedback, you'll be expected to incorporate the editor's feedback and get a "go for launch" from them before the post can be published.

I'll contribute editing effort to each post as well, because I care and I want the blog to be awesome!

### Blogistics

  - Each post will credit its author and editor (unless you elect to remain anonymous), and you're also welcome to cross-post your individual posts to your own blog if you have one.
  - Posts will be in Markdown format (with LaTeX support via MathJax if needed), and the blog will live in the course GitHub repo and will be generated and hosted via GitHub Pages.
  - We'll be making the most of GitHub Pages' site generation automation (which uses Jekyll behind the scenes), so that all you have to do is write Markdown files.  You should not have to install Jekyll locally.
  - Draft posts will live in [the `_drafts` directory in our course repo](https://github.com/lkuper/CMPS290S-2018-09/tree/master/_drafts) until they're ready to go.  Feel free to start pushing ideas or notes to `_drafts` at any time.  These shouldn't have a date in the filename.
  - Published posts will live in [the `_posts` directory](https://github.com/lkuper/CMPS290S-2018-09/tree/master/_posts) and use the `YYYY-MM-DD-title.md` naming convention.

## Grading

  - Responses to readings: 25%
  - Participation in class discussion: 20%
  - In-class presentations: 20%
  - Course blog posts: 35%

As you can see, participation is a big part of your grade -- so make an effort to come to class.

If you must miss class on a given day, you can make up for it somewhat by reading your classmates' responses to that day's reading and leaving thoughtful comments on GitHub.  (This shouldn't be necessary if you attend class, though.)

## Academic integrity

This is a graduate seminar; you're expected and encouraged to discuss your work with others.

That said, **everything you write for this course (paper summaries, blog posts, presentation materials, code, etc.) must be your own original work.**

If you discuss a reading with others in order to write your response, add a note to your response giving the names of the people you discussed the reading with.

**Properly attribute any work that you use.**  For instance, if you make a slide that uses a figure created by someone else, then say so explicitly.

It is part of your job as a scholar to understand [what counts as plagiarism](https://guides.library.ucsc.edu/citesources/plagiarism), and make sure you avoid it.

## Similar courses

  - [Heather Miller's fall 2016 course at Northeastern on programming models for distributed computing](http://heather.miller.am/teaching/cs7680/) has some overlap in material with this course.
  - There's also some overlap with the "programming models" part of [Peter Alvaro's winter 2016 edition of 290S](https://github.com/palvaro/CMPS290S-Winter16).
  
## A note on accessibility

If you have a disability and you require accommodations to achieve equal access in this course, please submit your Accommodation Authorization Letter from the [Disability Resource Center (DRC)](https://drc.ucsc.edu/index.html) to me privately during my office hours or by appointment, preferably within the first two weeks of the quarter.  I am eager to discuss ways we can ensure your full participation in the course.

I encourage all students who may benefit from learning more about DRC services to [contact the DRC](https://drc.ucsc.edu/about/contact-us/index.html).
  
## A note on privacy

US federal law (specifically, FERPA) and UC policy restrict the disclosure of information from student records.  In order to comply with those policies and protect your privacy:

  - We're using the aforementioned random identifiers for response submissions, rather than CruzIDs or some other identification method that would make your identity publicly known.  No one knows your random ID other than you and me.
  - You need to use GitHub for this course; however, if you prefer to keep your participation in the course private, you are welcome to create a GitHub account solely for use in the course that doesn't reveal any personal information (for instance, with a randomly generated username).
  - You may opt out of contributing to the public blog.  (I'll set up a separate private blog for any students who opt out.)  Or you can choose to contribute to the public blog, but anonymously.

## To do

  - **Once you have course repo access**: Make sure that you are able to push to the repo.  One way to do this is by pushing an _empty file_ called `XXXX-response-2018-10-01.md` to the `responses` directory, replacing `XXXX` with your unique ID.  When you submit your response to the first reading assignment, you'll update this file.
  - **For Monday, October 1**: If you haven't yet done so, look over the [list of readings](https://decomposition.al/CMPS290S-2018-09/readings.html), pick 3-5 papers that you'd like to present, and email me your choices.  (If you don't pick, I'll pick for you.)
  - **For Monday, October 1**: Read the first reading assignment ([Gilbert and Lynch](https://www.comp.nus.edu.sg/~gilbert/pubs/BrewersConjecture-SigAct.pdf)!) and submit your response to the course repo (remember that [responses](https://decomposition.al/CMPS290S-2018-09/responses.html) are due by 11am on the day of class).
