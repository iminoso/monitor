# Design

## Technologies

This application was built using:
* [Elixir](https://elixir-lang.org), a functional programming language built on top of Erlang
* [Phoenix](https://phoenixframework.org/), the Elixir web framework used to create the server
* [npm](https://www.npmjs.com/) with [Webpack](https://webpack.js.org) is used to compile the front end assets
* [Phoenix LiveView](https://github.com/phoenixframework/phoenix_live_view), an Elixir and JavaScript library that performs
client side updates using server side logic via WebSockets

## Main Design

When designing the application to stream system load info, I was deciding between using two options:

1. Use a standard web framework with an api. The api would include a GET endpoint that returns that
current system load. Render client side code for the browser, and **poll** the endpoint over a period.
2. Use a standard web framework, but instead of polling the api for system load information, use
**WebSockets**.

I decided to go with option 2, WebSockets. Given that the application is essentially a "real time" monitor that
displays system averages, a single connection can have advantages over multiple requests. With a
single connection to a client, there is less overhead to obtain data in this way instead of
continuously sending requests and receiving responses to process the streamed data.

## Elixir and Phoenix LiveView Background

I've been working with Elixir lately, so I decided to continue using it for this application. Phoenix
LiveView is a new and progressing library within the Elixir ecosystem that allows the client to directly
communicate with the server over WebSockets.

Phoenix LiveView works by first creating a long running generic server process that is used to
handle state (what is known as the *LiveView* process). This LiveView process is used to hold client
side state, and also contains markup templates to be rendered.

The LiveView process is associated with a route in the Phoenix web server and on fetch request,
renders the template to the client along with the initial state. The client then connects to the
LiveView process via WebSockets and opens a stateful connection.

![Phoenix LiveView](https://elixirschool.com/assets/live_view-6a1ff8ddee59b55d1ee0b72dc8d47c55e55bdcaf6b788cc65af31afec66836d3.png "Phoenix LiveView")

As the application is running, client side events can be handled through callback functions defined
in the template in the LiveView process. This allows the client to interactly directly with the server,
and as such no additional frontend library for state management (ie. React or Ember), is required.

## Design Walkthrough and Explanation

The main index page of the site is routed via the [router.ex](/lib/monitor_web/router.ex), which points
to the [page_controller.ex](lib/monitor_web/controllers/page_controller.ex).

Given the request, the page controller routes the request to LiveView process, [process_live.ex](lib/monitor_web/live/process_live.ex).

The LiveView process initializes the state `mount/2` function and renders the template back to the client.
Within the mount function, a timer function `tick()` is also called. The tick function is called every second
to calculate the system load information, provided util functions in [util.ex](lib/monitor/util.ex).

Some of main variables for initialized for state include:
* **`monitor_window_length`** - As the tick function is called to obtain system load every second, the monitor window
length is used to define the period, in seconds, in which to take the average and store a data point
for the log (default: 10 seconds)
* **`alert_window_length`** - The amount of the most recently logged data points to take to calculate
the average load (default: 12)
* **`alert_thresohld`** - If the average obtained from the alert window length of most recent data is greater
than this threshold value, trigger and store an alert (default: 95)

The logic for the determining the triggering of alerts is in [alert.ex](lib/monitor/alert.ex) and the
tests for this logic are found in [alert_test.exs](test/monitor/alert_test.exs).

## Visualization

As new system load information is loaded in the client via WebSockets, an SVG polyline chart is
rendered via the templated provided by the LiveView process. The polyline is adjusted in the viewbox
to be proportional to the load averages being streamed in.

In addition to the SVG polyline chart, a table with timestamp recordings of system load information is also displayed.
Most recent taken data is prepended to the top of the table.

Alerts are displayed via banners under the heading. If the alert recovers, a recovery tag is placed
on the recovered alert.

## Settings and Configuration

With default settings provided, the average load of the system will be displayed to the client every 10 seconds.
Given the alert window length, if the latest 120 seconds of process load data average is greater than 95%,
an alert will be triggered. Once the average in the window goes below 95%, a recovery alert will be displayed.

To configure and change this settings, such as displaying system load more quickly in 5 seconds, or changing
the alert window or threshold, open the settings panel in the top right of the application.

## Simulated Heavy Load

Within the menu settings, high load can also be simulated by selecting checkbox. Given the number or cpus
in the system, an equal number of running processes with infinte loops will be spawned to simulate heavy
cpu usage. Unchecking the box will kill the spawned processes.

## Potential Improvements to the Design

### Making the visualization interactable

One downside to using Phoenix LiveView is that it does not allow interoperability with JavaScript.
This was the reason for rendering the chart with vanilla SVG instead of a visualization library such
as D3. An improvement can be made to make this SVG chart visualization more interactable. This can
include clicking on the chart to render more information about the data point, or creating more
behaviour with events such as hover or key presses. Without the ability to use client side JavaScript
libraries with the templates though, this may be difficult to accomplish.

### Persisting recorded system load

With WebSockets, the system load information recorded will only exist in memory as the client connection
exists. The moment the browser closes or the client connection is closed, all system load data recorded
will no longer be available. This can be a problem is the user wants to see historical data, from prior
to opening the web application. In order to do this, a database can be used to store information. On page
load, a query to the stored information can be used to prepopulate system load with existing information.

### Mobile Friendly

Although the design is responsive, the chart is not mobile friendly as media query break points aren't provided
by the default design library. This means that the user must scroll horizontally on mobile to view chart
information.
