# Challenge 2

## Notes

### Backend

* Since we're declaring psycopg2 as a dependency, we'll be using PostgreSQL as DB.
* Had to use Python3.7 because that was the current version of Python when Django 2.1.4 was released.
    * Also, the declared version of psycopg2 doesn't support Python3.8 or higher.
* Had to install/update the following packages in order to install the project requirements: `libgraphviz-dev libpq-dev gcc python3-dev musl-dev`. Those include common dependencies for python projects, PostgreSQL development libs, and Graphviz development libs (which is declared as a project dependency in this case).
* Everytime the server starts, we need to ensure that the migrations all always updated and the staticfiles collected, so we manage all that in the container entrypoint.
* This project have a static files folder declared `assets` that does not  exists, so we're creating it in the entrypoint.

### Frontend

### Compose file

* We're using v3.8 because we want to have all the features of that spec available
* Since the backend depends on the DB, we need to declare a dependency.
    * Also, it's not enough to wait for the DB container to start, we need to wait until the DB is created and ready to accept connections.