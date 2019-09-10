# Monitor

A web application that collects the load averages of a system.

A live running instance of this app is running on Heroku: https://intense-wildwood-89922.herokuapp.com *

\* Note that the collection of load averages will be that of the Heroku dyno running the application.

## Running the application locally

### Easy method with Docker

With [Docker](https://www.docker.com) installed run:
```
$ docker-compose up
```

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser to run the application.

### Natively running the application

The following dependencies are required for the application:
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

### Appliaction Design and Decisions

See [docs/design](docs/design.md)
