FROM debian:11

ENV DEBIAN_FRONTEND=noninteractive

# This is a very simple image, but it allows us to ensure that the version
# of gnuplot that people use to execute our plot scripts matches the one we
# use, which, in practice, is not an obvious thing. Using a version that's
# too old might result in broken plots, and possibly the same the other way
# around

RUN apt install gnuplot
