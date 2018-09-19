# CMPS290S, Fall 2018: Languages and Abstractions for Distributed Programming

Welcome to CMPS290S, fall 2018 edition!  Here's an "official" course description:

> This graduate seminar course explores the theory and practice of distributed programming from a programming-languages perspective.  We will focus on programming models, language-level abstractions, and verification techniques that attempt to tame the many complexities of distributed systems: inevitable failures of the underlying hardware or network; communication latency resulting from the distance between nodes; the challenge of scaling to handle ever-larger amounts of work; and more.  Most of the work in the course will consist of reading classic and recent papers from the academic literature, writing short responses to the readings, and discussing them in class.  Furthermore, every participant in the class will contribute to a public group blog where we will share what we learn with a broader audience.

There's more than one reasonable way to approach a seminar course on languages and abstractions for distributed programming.  We could spend all our time on process calculi and only make a small dent in the literature.  Or we could spend all our time on large-scale distributed data processing and only make a small dent in the literature.  In this course, we will be focusing a lot of attention on [consistency models](https://en.wikipedia.org/wiki/Consistency_model) and language-based approaches to specifying, implementing, and verifying them.  Of course, we will only make a small dent in the literature.

For more information, read the [course overview](course-overview.html).

## Class blog

As a grad student, I always dreaded having to do course projects.  In an ideal world, these projects were supposed to dovetail nicely with one's "real" research, or they were supposed to morph into "real" research within three months by some mysterious alchemical process involving lots of luck and suffering.  In practice, they usually ended up taking time away from real research, and they always ended up being hastily implemented and shoddily written up.

So, let's try something different.  Instead of a traditional course project, **each participant in the class will write (and illustrate!) two posts for a public group blog aimed at a general technical audience.**  The goal is to create an artifact that will outlive the class and be valuable to the broader community.

### Blog posts

<ul>
  {% for post in site.posts %}
    <li>
      <a href="{{ post.url | prepend:site.baseurl }}">{{ post.title }}</a>
    </li>
  {% endfor %}
</ul>

