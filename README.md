# Monitor

A web application that collects the load averages of a system.

A live running instance of this app is running on Heroku: https://intense-wildwood-89922.herokuapp.com *

\* Note that the collection of load averages will be that of the Heroku dyno running the application.

## Running the application locally

There are two options for running the application locally:

### 1. Easy method with Docker

With [Docker](https://www.docker.com)\* installed run:
```
$ docker-compose up
```

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser to run the application.

\* Note that the system load tracked in the web application will be that of the process within the container.

### 2. Natively running the application

If you want to instead natively run the web applicaiton, the following dependencies are required
for the application:
```
elixir 1.8.1
erlang 20.1
nodejs 10.16.0
```

Using [asdf] version manager to install the dependencies provided in `.tool-versions`

```
$ asdf install
```

With the dependencies installed, compile and run the applicaiton:

```
$ mix do deps.get, deps.compile
$ npm --prefix ./assets install ./assets
$ mix phx.server
```

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser to run the application.

While natively setting up the application, tests can also be run using:

```
$ mix tests
```

## Web Application Design and Documentation

See [docs/design](docs/design.md).
