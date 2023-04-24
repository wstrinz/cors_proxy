FROM ruby:3.2.1

# Set the working directory
WORKDIR /app

# Copy the Gemfile and Gemfile.lock into the container
COPY Gemfile Gemfile.lock ./

# Install the gems
RUN bundle install

# Copy the rest of the application into the container
COPY . .

# Expose the port that the proxy server will run on
EXPOSE 8080

# Start the proxy server
CMD ["ruby", "proxy_server.rb"]
