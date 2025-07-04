# AWS_grocery/Dockerfile

FROM python:3.10-slim

# Set working directory
WORKDIR /app

# Copy the correct requirements file
COPY backend/requirements.txt .

# Install Python dependencies
RUN pip install -r requirements.txt

# Copy the backend code
COPY backend/ backend/

# Set the working dir to the backend code
WORKDIR /app/backend

# Start the Flask app
CMD ["python", "run.py"]
