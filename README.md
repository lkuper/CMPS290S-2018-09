Welcome to CMPS290S, fall 2018 edition!

For more information, read the [first-day-of-class course overview](course-overview.html), then check out the [reading list](readings.html).

## Blog posts

<ul>
  {% for post in site.posts %}
    <li>
      <a href="{{ post.url | prepend:site.baseurl }}">{{ post.title }}</a>
    </li>
  {% endfor %}
</ul>

