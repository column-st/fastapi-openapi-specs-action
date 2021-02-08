FROM python:latest

LABEL maintainer="Felipe Faria <me@felipefaria.me>"

# Installs depedency.
RUN pip install fastapi pyyaml

# Adds entrypoint file.
ADD entrypoint.py /entrypoint.py

# Runs entrypoint on docker run.
ENTRYPOINT python /entrypoint.py
