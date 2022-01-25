# xenial-database-container

This project builds a Docker image that matches the PostgreSQL and PostGIS
version that we have been using for our Python 3.5 unit tests.

Creation of this image was necessary to re-architect how the CircleCI build
runs - using containers instead of installing dependent projects into the test
suite's virtual environment.


## Use

This project build and pushes a Docker image to:

`137296740171.dkr.ecr.us-west-2.amazonaws.com/postgis-unittest`


## Construction

This image was made by backporting instructions and scripts from
the [PostgreSQL images in the docker-library project][1] and the
[PostGIS docker project][2].



[1]: https://github.com/docker-library/postgres
[2]: https://github.com/postgis/docker-postgis
