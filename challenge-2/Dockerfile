# Build React project
FROM node:8.17.0 as webpack

WORKDIR /code

COPY frontend/package.json frontend/package-lock.json frontend/yarn.lock /code/

RUN npm install

COPY frontend /code/

RUN npm run build

# Build Django project
FROM python:3.7

ENV PYTHONDONTWRITEBYTECODE=1

ENV PYTHONUNBUFFERED=1

WORKDIR /code

COPY backend/requirements.txt /code/

RUN apt-get update -y -qq && apt-get install -y -qq libgraphviz-dev libpq-dev gcc python3-dev musl-dev

RUN pip install -r requirements.txt

COPY backend /code/

# Copy React assets from previous step
COPY --from=webpack /assets /code/assets/

COPY --from=webpack /webpack-stats*.json /code/

EXPOSE 8000

ENTRYPOINT [ "./docker-entrypoint.sh" ]

CMD ["gunicorn", "backend.wsgi", "-b 0.0.0.0:8000", "-w 2"]