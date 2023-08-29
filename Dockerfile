FROM python:3.11

RUN apt-get update && apt-get install -y libpq-dev
WORKDIR /usr/src/app
COPY requirements.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 5000
ENV PATH="/opt/venv/bin:$PATH"
CMD ["python", "app.py"]
