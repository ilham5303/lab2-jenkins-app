# Use a lightweight Python base image
FROM python:3.9-alpine

# Set the working directory in the container
WORKDIR /app

# Copy requirements.txt and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application code
COPY app.py .

# Command to run the application
CMD ["python", "app.py"]

