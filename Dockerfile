FROM bitwalker/alpine-elixir-phoenix:1.8.1

# Set exposed ports
EXPOSE 4000
ENV PORT=4000 MIX_ENV=dev

# Cache elixir deps
ADD mix.exs mix.lock ./
RUN mix do deps.get, deps.compile

# Same with npm deps
ADD assets/package.json assets/
RUN cd assets && \
    npm install

ADD . .

# Run frontend build, compile, and digest assets
RUN cd assets/ && \
    npm run deploy && \
    cd - && \
    mix do compile, phx.digest

USER root

CMD ["mix", "phx.server"]
