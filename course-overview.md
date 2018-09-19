# CMPS290S, Fall 2018: Languages and Abstractions for Distributed Programming

Course overview

Friday, October 29, 2018

## Instructor

Hi, I'm [Lindsey Kuper](https://users.soe.ucsc.edu/~lkuper/)!

  - Email: <lkuper@ucsc.edu>
  - Office: Engineering 2, Room 349B
  - Office hours: Wednesdays and Fridays, 11am-noon, or by appointment ([email me](mailto:lkuper@ucsc.edu))
  - Research areas: Programming languages, distributed systems, parallelism, concurrency, verification

## A few essential details

  - 5-unit graduate seminar course (i.e., we read, present, and discuss research papers)
  - "S" in the course number stands for "systems", but don't read too much into it (we'll _mostly_ be reading papers from PL venues)
  - Class meets Mondays, Wednesdays, and Fridays, 1:20-2:25pm, Porter Acad 241 (in the Porter "D-Building", a [12m30s walk](https://taps.ucsc.edu/pdf/walking-map.pdf) from Science Hill)
  - No final exam, although you should save the time slot (8-11am on Wednesday, December 12) for a social event
  - Topic: Theory and practice of distributed programming from a programming-languages perspective
  - Particular emphasis on _consistency models_ and language-based approaches to specifying, implementing, and verifying them

## What I want you to do in this course

  - Become more comfortable with reading research papers (particularly PL papers, if you haven't read a lot of those)
  - Get a sense of how PL research and (distributed) systems research intersect
  - Identify some interesting research questions that fall in that intersection that you want to investigate, and start taking steps toward answering those questions
  - Hone your technical writing and presenting skills, especially for a non-specialist audience (i.e., blog readers)

## Topics we'll cover

  - The CAP theorem
  - Consistency models
  - Replicated data types
  - Verifying consistency
  - Languages and frameworks for distribution
  - Abstractions for configuration management

## Background you'll need

  - We'll be reading papers that formally define mathematical models of computer systems and then prove properties about those models; you should be familiar with this way of working
  - Although the ideas often aren't too complicated, there's a high notational overhead (i.e., lots of Greek letters) in many PL papers
    - _At a minimum_, you should be familiar with the concepts in Jeremy Siek's ["Crash Course on Notation in Programming Language Theory"](http://siek.blogspot.com/2012/07/crash-course-on-notation-in-programming.html) (take some time to read it and brush up on anything you're not familiar with already)
    - Ask questions early when you come across notation you don't understand (if you're confused, you're probably not the only one!)

## Readings and responses

  - One goal of this class is to equip you to conduct research on languages and abstractions for distributed programming by absorbing a lot of papers on the topic
  - Each participant in the class will write a [response](responses.html) to each reading
  - The [readings page](readings.html) has the current schedule of readings

_Free pass policy_: Because life throws unexpected challenges at each of us, you get four "free passes" to use during the quarter.  Using a free pass exempts you from having to submit a response for one reading.

## Response logistics

  - Responses should be written in Markdown format, with the filename `YYYY-MM-DD-cruzid.md`, and submitted to the `responses` directory of our GitHub repo as a pull request
  - Your first response is due Monday, so if you need help with GitHub, let me know ASAP

## Presentations

  - Each participant in the class will present two or three readings (depending on how many people take the class)
  - As a rough guideline, expect to do one or two presentations in October and one or two in November
  - Presentations should be about 35 minutes long, leaving 25 minutes for discussion
  - You do not have to submit a response for readings that you're presenting
  - You should request (by next Monday) particular readings you want to present (if you don't pick, I'll pick for you)

## Class blog

  - Each participant in the class will write (and illustrate!) two posts for a public group blog aimed at a general technical audience
  - The goal is to create an artifact that will outlive the class and be valuable to the broader community
  - You will also serve as an editor for two posts (other than your own)
    - Editors help by reading drafts, asking clarifying questions, spotting mistakes and rough spots, and giving constructive feedback
    - We'll pair up editors with writers as the quarter proceeds
  - I'll contribute editing effort to each post, too

## Possible blog post ideas (1)

  - *The research investigation*
    - Dig into one of the research questions that you identified while writing your [responses](responses.html) to the readings
    - Carry out one of the concrete steps that you identified toward answering it (which might involve writing code, taking measurements, writing proofs, and/or something else), and write about what you learned
    - Negative or inconclusive results are fine!
  - *The literature survey*
    - Choose several (at least three, but no more than six or so) related readings that have something to do with the topic of the course, read them, and write a post surveying and analyzing them
    - At most one of your selected readings should be one we're already covering in class
    - The idea is to use something we read in class as a jumping-off point to go off on your own, explore the literature on a specific topic, and come back with new insights
    - Good sources for papers include the related work sections of things we read for class, or the ["further reading" section of the readings page](readings.html#further-reading).

## Possible blog post ideas (2)

  - *The experience report*
    - Try out one or more of the systems discussed in the course readings, and report on your experience
    - For this kind of post, you should expect to write code
    - Aim higher than just "I got it to compile and run" -- ideally, you'll use the system to accomplish something, and report on what worked and what didn't
    - In many cases, it will be appropriate to try to reproduce performance results from the reading
  - *Run someone's research*
    - Choose a "lightweight language mechanization" tool, such as PLT Redex or K, and use it to mechanize and test a language or system model from one of the readings you did
    - Report on what you learned from this process
    - There's a [good chance](https://eecs.northwestern.edu/~robby/lightweight-metatheory/popl2012-kcdeffmrtf.pdf) you'll find bugs or infelicities in the on-paper semantics!

## Blog editing

  - Blog posts aimed at a general technical audience call for a different writing style than academic papers do, but that doesn't mean we won't hold them to a high standard of quality
    - If anything, we should be _more_ concerned about writing well -- making the blog a pleasure to read will be a top priority!
  - In addition to writing your own posts for the blog, you will also serve as an _editor_ for two posts (other than your own)
  - The role of the editor is to help the writer do their best work -- by reading drafts, asking clarifying questions, spotting mistakes and rough spots, and giving constructive feedback
  - Expect to spend at least ten hours on editing (at least five hours for each post on which you serve as editor)
  - When you're on the receiving end of feedback, you'll be expected to incorporate the editor's feedback and get a "go for launch" from them before the post can be published
  - I'll contribute editing effort to each post as well, because I care and I want the blog to be awesome

## Blog post time frame

  - A blog post requires substantial work (reading, writing, editing, programming, debugging, thinking)
  - Expect each post to take about 25 hours of focused work, and scope the work appropriately
  - As a rough guideline, you should be working on one post during October and the other one during November
  - More specifically, aim to work within the following time frame:
    - Monday, 10/29: Finished draft of first post; soliciting editor/instructor feedback
    - Monday, 11/12: Hard deadline to have first post published
    - Wednesday, 11/28: Finished draft of second post; soliciting editor/instructor feedback
    - Wednesday, 12/12: Hard deadline to have second post published

Note: You may want to do one 50-hour post instead of two 25-hour ones.  In that case, break it up into two chunks and publish them as "part one" and "part two".  You might not know something is a 50-hour project until you're in the middle of it, so play it by ear: if you put in 25 hours of focused work during October and you're still nowhere near done, then find a reasonable stopping point, call what you've done so far "part one", and then do the second part in November.

## More blog logistics

  - Each post will credit its author and editor, and you're also welcome to cross-post your individual posts to your own blog if you have one
  - Posts will be in Markdown format (with LaTeX support via MathJax if needed), and the blog will live in the course GitHub repo and will be generated and hosted via GitHub Pages
  - We're making the most of GitHub Pages' site generation automation (which uses Jekyll behind the scenes), so that all you have to do is write Markdown files

## Grading

  - Responses to readings: 25%
  - Participation in class discussion: 20%
  - In-class presentations: 20%
  - Class blog posts: 35%

As you can see, participation is a big part of your grade -- so do make an effort to come to class.  If you must miss class on a given day, you can make up for it somewhat by reading your classmates' reading responses on GitHub for that day and leaving thoughtful comments.  (This shouldn't be necessary if you do attend class, though.)

## Academic integrity

This is a graduate seminar; you're expected and encouraged to discuss your work with others. That said, everything you write for this course (paper summaries, blog posts, presentation materials, etc.) must be your own original work.

If you discuss the readings with other students, add a note to your summary giving the names of students you discussed them with.  These relationships should be symmetric: if student A discussed the reading with student B, then student B discussed the reading with student A, and each of them should name the other.

Properly attribute any work that you use.  For instance, if you use a figure that someone else created in one of your paper presentation, you should cite the original author.

## Similar courses

  - [Heather Miller's fall 2016 course at Northeastern on programming models for distributed computing](http://heather.miller.am/teaching/cs7680/) was structured similarly to this one and has some overlap in material.
  - There's also some overlap with the "programming models" part of [Peter Alvaro's winter 2016 edition of 290S](https://github.com/palvaro/CMPS290S-Winter16).

## To do

  - **By EOD today**: If you haven't yet done so, email me your GitHub username so I can add you to the course repo.
    - Once you have repo access, push an empty file called `2018-10-01-cruzid.md` to the `responses` directory, replacing `cruzid` with your CruzID.  When you write your response to the first reading assignment, you'll update this file.
    - If you need help using GitHub, let me know.
  - **By EOD today**: Look over the [list of readings](https://github.com/lkuper/CMPS290S-Fall-2018/blob/master/readings.md), pick 3-5 papers that you'd like to present, and email me your choices.  (If you don't pick, I'll pick for you.)
  - **For next Monday**: Read the first reading assignment ([Gilbert and Lynch](https://www.comp.nus.edu.sg/~gilbert/pubs/BrewersConjecture-SigAct.pdf)!) and submit your response (remember that [responses](https://github.com/lkuper/CMPS290S-Fall-2018/blob/master/responses.md) are due by 11am on the day of class)

## Questions?
